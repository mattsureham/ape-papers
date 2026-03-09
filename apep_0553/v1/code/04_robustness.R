## 04_robustness.R — Robustness checks and diagnostics
## apep_0553: Do Export Controls Have Teeth?

source("00_packages.R")

DATA_DIR <- "../data"
TABLE_DIR <- "../tables"

## ============================================================
## Load data
## ============================================================

panel <- fread(file.path(DATA_DIR, "panel_hs6.csv"))
has_control <- any(panel$role == "control")
if (has_control) {
  analysis <- panel[role %in% c("transit", "control")]
} else {
  analysis <- panel[role == "transit"]
}

cat("Analysis sample:", nrow(analysis), "rows\n")
cat("Design:", ifelse(has_control, "DDD (transit + control)", "DD (transit only)"), "\n")

# Pre-compute interaction terms
analysis[, is_chpl_num := as.integer(is_chpl)]
analysis[, is_transit_num := as.integer(is_transit)]
analysis[, chpl_post := is_chpl_num * post_sanctions]
analysis[, chpl_post_chpl := is_chpl_num * post_chpl]
analysis[, transit_post := is_transit_num * post_sanctions]
analysis[, transit_chpl_post := is_transit_num * is_chpl_num * post_sanctions]
analysis[, transit_chpl_postchpl := is_transit_num * is_chpl_num * post_chpl]
analysis[, hs2_year := paste0(hs2, "_", year)]

## ============================================================
## 1. PRE-TRENDS / EVENT STUDY
## ============================================================

cat("\n=== EVENT STUDY ===\n")

# Create year dummies relative to sanctions (2022)
analysis[, event_year := year - 2022]

# Event study: year-by-year coefficients
if (has_control) {
  es_model <- feols(log_trade ~ i(event_year, transit_chpl_post, ref = -1) +
                      i(event_year, transit_post, ref = -1) |
                      cp + pt + ct,
                    data = analysis, cluster = ~reporter_code)
  es_coefs <- as.data.table(coeftable(es_model), keep.rownames = "term")
  es_chpl <- es_coefs[grepl("transit_chpl", term)]
  es_chpl[, event_year := as.numeric(gsub(".*event_year::(-?\\d+):.*", "\\1", term))]
} else {
  # DD: CHPL × Year interactions using i() with numeric
  es_model <- feols(log_trade ~ i(event_year, is_chpl_num, ref = -1) |
                      cp + ct,
                    data = analysis, cluster = ~hs6)
  es_coefs <- as.data.table(coeftable(es_model), keep.rownames = "term")
  es_chpl <- es_coefs[grepl("is_chpl_num", term)]
  es_chpl[, event_year := as.numeric(gsub(".*event_year::(-?\\d+):.*", "\\1", term))]
}

cat("Event study model estimated.\n")
setnames(es_chpl, c("Estimate", "Std. Error"), c("estimate", "se"), skip_absent = TRUE)
if (!"estimate" %in% names(es_chpl)) {
  nms <- names(es_chpl)
  setnames(es_chpl, nms[2], "estimate")
  setnames(es_chpl, nms[3], "se")
}
es_chpl[, ci_lower := estimate - 1.96 * se]
es_chpl[, ci_upper := estimate + 1.96 * se]

fwrite(es_chpl, file.path(DATA_DIR, "event_study_coefs.csv"))

# Pre-trends F-test
pre_coefs <- es_chpl[event_year < 0]
if (nrow(pre_coefs) > 0) {
  f_stat <- sum(pre_coefs$estimate^2 / pre_coefs$se^2) / nrow(pre_coefs)
  p_val <- pf(f_stat, nrow(pre_coefs), es_model$nobs - length(coef(es_model)),
              lower.tail = FALSE)
  cat(sprintf("Pre-trends F-test: F = %.2f, p = %.4f\n", f_stat, p_val))
  cat(ifelse(p_val > 0.05, "PASS: No significant pre-trends\n",
             "WARNING: Significant pre-trends detected\n"))
}

## ============================================================
## 2. LEAVE-ONE-COUNTRY-OUT
## ============================================================

cat("\n=== LEAVE-ONE-OUT (TRANSIT COUNTRIES) ===\n")

transit_codes <- unique(analysis[is_transit == TRUE]$reporter_code)

loo_results <- lapply(transit_codes, function(drop_code) {
  drop_name <- unique(analysis[reporter_code == drop_code]$reporter_name)
  if (length(drop_name) == 0 || is.na(drop_name[1])) drop_name <- as.character(drop_code)

  m <- tryCatch({
    if (has_control) {
      feols(log_trade ~ transit_post + transit_chpl_post + transit_chpl_postchpl |
              cp + pt + ct,
            data = analysis[reporter_code != drop_code],
            cluster = ~reporter_code)
    } else {
      feols(log_trade ~ chpl_post + chpl_post_chpl |
              cp + ct + hs2_year,
            data = analysis[reporter_code != drop_code],
            cluster = ~hs6)
    }
  }, error = function(e) NULL)

  if (is.null(m)) return(NULL)

  ct <- as.data.table(coeftable(m), keep.rownames = "term")

  # Extract both coefficients
  if (has_control) {
    post_row <- ct[term == "transit_chpl_post"]
    chpl_row <- ct[term == "transit_chpl_postchpl"]
  } else {
    post_row <- ct[term == "chpl_post"]
    chpl_row <- ct[term == "chpl_post_chpl"]
  }
  if (nrow(post_row) == 0 || nrow(chpl_row) == 0) return(NULL)

  data.table(
    dropped = drop_name[1],
    dropped_code = drop_code,
    beta1_est = post_row[[2]][1],
    beta1_se = post_row[[3]][1],
    beta2_est = chpl_row[[2]][1],
    beta2_se = chpl_row[[3]][1],
    n_obs = m$nobs
  )
})

loo_dt <- rbindlist(loo_results[!sapply(loo_results, is.null)])
if (nrow(loo_dt) > 0) {
  cat("Leave-one-out results:\n")
  print(loo_dt[, .(dropped,
                    beta1 = round(beta1_est, 3), se1 = round(beta1_se, 3),
                    beta2 = round(beta2_est, 3), se2 = round(beta2_se, 3))])
  fwrite(loo_dt, file.path(DATA_DIR, "leave_one_out.csv"))
}

## ============================================================
## 3. PRODUCT DISPLACEMENT TEST
## ============================================================

cat("\n=== PRODUCT DISPLACEMENT TEST ===\n")

# Did non-CHPL products in the same HS2 chapters spike after CHPL?
# If enforcement just pushed rerouting to close substitutes, we should
# see non-CHPL products in ch 84/85/88/90 increase for transit countries

if (has_control) {
  disp_model <- feols(log_trade ~ transit_post |
                        cp + pt + ct,
                      data = analysis[is_chpl == FALSE & hs2 %in% c("84", "85", "88", "90")],
                      cluster = ~reporter_code)
} else {
  # Non-CHPL products only: post_sanctions captures the effect on non-CHPL products
  disp_model <- feols(log_trade ~ post_sanctions + post_chpl |
                        cp,
                      data = analysis[is_chpl == FALSE & hs2 %in% c("84", "85", "88", "90")],
                      cluster = ~hs6)
}

cat("Displacement test (non-CHPL products, same chapters):\n")
print(summary(disp_model))

disp_coefs <- as.data.table(coeftable(disp_model), keep.rownames = "term")
fwrite(disp_coefs, file.path(DATA_DIR, "displacement_test.csv"))

## ============================================================
## 4. INTENSIVE MARGIN (positive trade only)
## ============================================================

cat("\n=== INTENSIVE MARGIN ===\n")

if (has_control) {
  m_intensive <- feols(log_trade ~ transit_post + transit_chpl_post + transit_chpl_postchpl |
                         cp + pt + ct,
                       data = analysis[fob_value > 0],
                       cluster = ~reporter_code)
} else {
  m_intensive <- feols(log_trade ~ chpl_post + chpl_post_chpl |
                         cp + ct + hs2_year,
                       data = analysis[fob_value > 0],
                       cluster = ~hs6)
}

cat("Intensive margin (positive trade only):\n")
print(summary(m_intensive))

## ============================================================
## 5. ALTERNATIVE CONTROL GROUPS
## ============================================================

cat("\n=== ALTERNATIVE CONTROLS ===\n")

# Drop largest transit country — test if results driven by single country
largest_transit <- analysis[is_transit == TRUE, .(total = sum(fob_value)), by = reporter_code]
setorder(largest_transit, -total)
drop_code <- largest_transit$reporter_code[1]
drop_name <- unique(analysis[reporter_code == drop_code]$reporter_name)[1]
cat(sprintf("Dropping largest transit country: %s (code %d)\n", drop_name, drop_code))

if (has_control) {
  m_no_largest <- feols(log_trade ~ transit_post + transit_chpl_post + transit_chpl_postchpl |
                       cp + pt + ct,
                     data = analysis[reporter_code != drop_code],
                     cluster = ~reporter_code)
} else {
  m_no_largest <- feols(log_trade ~ chpl_post + chpl_post_chpl |
                       cp + ct + hs2_year,
                     data = analysis[reporter_code != drop_code],
                     cluster = ~hs6)
}

cat(sprintf("Without %s:\n", drop_name))
ct_no_largest <- as.data.table(coeftable(m_no_largest), keep.rownames = "term")
print(ct_no_largest)

## ============================================================
## 6. COUNTRY-LEVEL AGGREGATION
## ============================================================

cat("\n=== COUNTRY-LEVEL DDD ===\n")

country_panel <- fread(file.path(DATA_DIR, "panel_country.csv"))
# Filter out rows with blank reporter_name (data artifact)
country_panel <- country_panel[reporter_name != ""]
if (has_control) {
  country_analysis <- country_panel[role %in% c("transit", "control")]
  country_analysis[, is_transit_num := as.integer(is_transit)]
  country_analysis[, is_chpl_num := as.integer(is_chpl)]
  country_analysis[, transit_post := is_transit_num * post_sanctions]
  country_analysis[, transit_chpl_post := is_transit_num * is_chpl_num * post_sanctions]
  country_analysis[, transit_chpl_postchpl := is_transit_num * is_chpl_num * post_chpl]
  m_country <- feols(log_total ~ transit_post + transit_chpl_post + transit_chpl_postchpl |
                       reporter_code^is_chpl + is_chpl^year + reporter_code^year,
                     data = country_analysis,
                     cluster = ~reporter_code)
} else {
  country_analysis <- country_panel[role == "transit"]
  country_analysis[, is_chpl_num := as.integer(is_chpl)]
  country_analysis[, chpl_post := is_chpl_num * post_sanctions]
  country_analysis[, chpl_post_chpl := is_chpl_num * post_chpl]
  m_country <- feols(log_total ~ chpl_post + chpl_post_chpl |
                       reporter_code^is_chpl + reporter_code^year,
                     data = country_analysis,
                     cluster = ~reporter_code)
}

cat("Country-level results:\n")
print(summary(m_country))

## ============================================================
## 7. PPML ESTIMATION
## ============================================================

cat("\n=== PPML (POISSON PSEUDO-MAXIMUM LIKELIHOOD) ===\n")

if (has_control) {
  m_ppml <- fepois(fob_value ~ transit_post + transit_chpl_post + transit_chpl_postchpl |
                     cp + ct,
                   data = analysis, cluster = ~reporter_code)
} else {
  m_ppml <- fepois(fob_value ~ chpl_post + chpl_post_chpl |
                     cp + ct,
                   data = analysis, cluster = ~hs6)
}

cat("PPML results:\n")
print(summary(m_ppml))

ppml_coefs <- as.data.table(coeftable(m_ppml), keep.rownames = "term")

## ============================================================
## 8. WILD CLUSTER BOOTSTRAP
## ============================================================

cat("\n=== WILD CLUSTER BOOTSTRAP ===\n")

# Re-estimate main model for bootstrap
if (has_control) {
  m_main <- feols(log_trade ~ transit_post + transit_chpl_post + transit_chpl_postchpl |
                    cp + ct,
                  data = analysis, cluster = ~reporter_code)
  boot_param <- "transit_chpl_postchpl"
  boot_cluster <- "reporter_code"
} else {
  m_main <- feols(log_trade ~ chpl_post + chpl_post_chpl |
                    cp + ct + hs2_year,
                  data = analysis, cluster = ~hs6)
  boot_param <- "chpl_post_chpl"
  boot_cluster <- "hs6"
}

boot_result <- tryCatch({
  boottest(m_main, param = boot_param, clustid = c(boot_cluster),
           B = 9999, type = "rademacher", impose_null = TRUE)
}, error = function(e) {
  cat("Wild bootstrap attempt 1 failed:", e$message, "\n")
  # Try alternative: use the model without absorbed FEs
  tryCatch({
    # Re-estimate with explicit dummies for clustering compatibility
    m_alt <- feols(log_trade ~ chpl_post + chpl_post_chpl |
                     cp + ct + hs2_year,
                   data = analysis, vcov = "hetero")
    boottest(m_alt, param = boot_param, clustid = c(boot_cluster),
             B = 9999, type = "rademacher", impose_null = TRUE)
  }, error = function(e2) {
    cat("Wild bootstrap attempt 2 failed:", e2$message, "\n")
    NULL
  })
})

if (!is.null(boot_result)) {
  cat(sprintf("Wild cluster bootstrap for %s:\n", boot_param))
  cat(sprintf("  Point estimate: %.3f\n", boot_result$point_estimate))
  cat(sprintf("  Bootstrap p-value: %.4f\n", boot_result$p_val))
  cat(sprintf("  Bootstrap CI: [%.3f, %.3f]\n",
              boot_result$conf_int[1], boot_result$conf_int[2]))

  # Also bootstrap the rerouting coefficient
  boot_param2 <- ifelse(has_control, "transit_chpl_post", "chpl_post")
  boot_result2 <- tryCatch({
    boottest(m_main, param = boot_param2, clustid = boot_cluster,
             B = 9999, type = "webb", impose_null = TRUE)
  }, error = function(e) NULL)

  if (!is.null(boot_result2)) {
    cat(sprintf("\nWild cluster bootstrap for %s:\n", boot_param2))
    cat(sprintf("  Point estimate: %.3f\n", boot_result2$point_estimate))
    cat(sprintf("  Bootstrap p-value: %.4f\n", boot_result2$p_val))
    cat(sprintf("  Bootstrap CI: [%.3f, %.3f]\n",
                boot_result2$conf_int[1], boot_result2$conf_int[2]))
  }

  # Save bootstrap results
  boot_df <- data.table(
    parameter = c(boot_param, boot_param2),
    estimate = c(boot_result$point_estimate,
                 ifelse(!is.null(boot_result2), boot_result2$point_estimate, NA)),
    boot_p = c(boot_result$p_val,
               ifelse(!is.null(boot_result2), boot_result2$p_val, NA)),
    boot_ci_lo = c(boot_result$conf_int[1],
                   ifelse(!is.null(boot_result2), boot_result2$conf_int[1], NA)),
    boot_ci_hi = c(boot_result$conf_int[2],
                   ifelse(!is.null(boot_result2), boot_result2$conf_int[2], NA))
  )
  fwrite(boot_df, file.path(DATA_DIR, "wild_bootstrap.csv"))
}

## ============================================================
## 9. PERMUTATION / RANDOMIZATION INFERENCE
## ============================================================

cat("\n=== PERMUTATION INFERENCE ===\n")

# Randomly reassign CHPL status among the 42 products 1000 times
# Under H0: CHPL designation is irrelevant → β₂ should be ~0
set.seed(20260309)
n_perms <- 1000
product_list <- unique(analysis$hs6)
n_chpl <- sum(unique(analysis[, .(hs6, is_chpl)])[, is_chpl])

perm_beta2 <- numeric(n_perms)
for (i in seq_len(n_perms)) {
  fake_chpl <- sample(product_list, n_chpl)
  analysis[, fake_is_chpl := as.integer(hs6 %in% fake_chpl)]
  analysis[, fake_chpl_post := fake_is_chpl * post_sanctions]
  analysis[, fake_chpl_post_chpl := fake_is_chpl * post_chpl]

  m_perm <- tryCatch({
    feols(log_trade ~ fake_chpl_post + fake_chpl_post_chpl |
            cp + ct + hs2_year,
          data = analysis, cluster = ~hs6)
  }, error = function(e) NULL)

  if (!is.null(m_perm)) {
    ct_perm <- as.data.table(coeftable(m_perm), keep.rownames = "term")
    row2 <- ct_perm[term == "fake_chpl_post_chpl"]
    perm_beta2[i] <- if (nrow(row2) > 0) row2[[2]][1] else NA
  } else {
    perm_beta2[i] <- NA
  }

  if (i %% 100 == 0) cat(sprintf("  Permutation %d/%d\n", i, n_perms))
}

# Remove NAs
perm_beta2 <- perm_beta2[!is.na(perm_beta2)]

# Actual β₂
actual_ct <- as.data.table(coeftable(m_main), keep.rownames = "term")
actual_beta2 <- actual_ct[term == boot_param][[2]][1]

# Two-sided permutation p-value
perm_p <- mean(abs(perm_beta2) >= abs(actual_beta2))
cat(sprintf("Actual β₂: %.3f\n", actual_beta2))
cat(sprintf("Permutation distribution: mean=%.3f, sd=%.3f\n",
            mean(perm_beta2), sd(perm_beta2)))
cat(sprintf("Permutation p-value (two-sided): %.4f\n", perm_p))
cat(sprintf("Rank of actual β₂: %d / %d\n",
            sum(perm_beta2 <= actual_beta2), length(perm_beta2)))

# Save permutation results
perm_df <- data.table(
  actual_beta2 = actual_beta2,
  perm_mean = mean(perm_beta2),
  perm_sd = sd(perm_beta2),
  perm_p_twosided = perm_p,
  n_permutations = length(perm_beta2)
)
fwrite(perm_df, file.path(DATA_DIR, "permutation_inference.csv"))
fwrite(data.table(perm_beta2 = perm_beta2), file.path(DATA_DIR, "permutation_distribution.csv"))

# Clean up temporary columns
analysis[, c("fake_is_chpl", "fake_chpl_post", "fake_chpl_post_chpl") := NULL]

## ============================================================
## Save all robustness results
## ============================================================

robust_coefs <- rbindlist(list(
  data.table(model = "intensive", as.data.table(coeftable(m_intensive), keep.rownames = "term")),
  data.table(model = "no_largest", ct_no_largest),
  data.table(model = "country_level", as.data.table(coeftable(m_country), keep.rownames = "term")),
  data.table(model = "ppml", ppml_coefs)
), fill = TRUE)

fwrite(robust_coefs, file.path(DATA_DIR, "robustness_coefs.csv"))

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
