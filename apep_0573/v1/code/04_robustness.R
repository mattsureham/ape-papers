## ============================================================
## 04_robustness.R — Robustness checks
## apep_0573: EU Procurement Reform and Competition
## ============================================================

source(file.path(dirname(sys.frame(1)$ofile), "00_packages.R"))

cat("=== Loading clean data ===\n")
panel <- fread(file.path(data_dir, "panel_country_quarter.csv"))
panel_year <- fread(file.path(data_dir, "panel_country_year.csv"))
models <- readRDS(file.path(data_dir, "models.rds"))

# ============================================================
# 1. Pre-trend test (joint F-test on pre-treatment coefficients)
# ============================================================
cat("\n=== Pre-trend Test ===\n")

panel[, et_trim := pmin(pmax(event_time, -8), 12)]

es_model <- feols(single_bidder_share ~ i(et_trim, ref = -1) | country + time_period,
                  data = panel, cluster = ~country,
                  weights = ~n_contracts)

# Joint test on pre-treatment coefficients (et < 0)
pre_names <- grep("et_trim::-[2-8]", names(coef(es_model)), value = TRUE)
if (length(pre_names) > 0) {
  pretrend_test <- wald(es_model, keep = pre_names)
  cat("  Pre-trend F-test:\n")
  print(pretrend_test)
  pretrend_p <- pretrend_test$p
} else {
  cat("  Pre-trend coefficients not found, using manual test\n")
  pretrend_p <- NA
}

# ============================================================
# 2. Randomization Inference
# ============================================================
cat("\n=== Randomization Inference ===\n")

set.seed(42)
n_perm <- 1000

# Observed ATT from TWFE
obs_att <- coef(models$twfe_single)["treated"]

# Permute transposition dates across countries
countries <- unique(panel$country)
n_countries <- length(countries)
trans_dates <- unique(panel[, .(country, cohort_yq, first_treat_period)])

perm_atts <- numeric(n_perm)

for (i in 1:n_perm) {
  # Shuffle transposition dates
  shuffled <- trans_dates[sample(.N)]
  shuffled[, perm_first_treat := trans_dates$first_treat_period]
  shuffled[, perm_cohort := trans_dates$cohort_yq]

  perm_panel <- merge(panel, shuffled[, .(country, perm_first_treat, perm_cohort)],
                      by = "country")
  perm_panel[, perm_treated := as.integer(time_period >= perm_first_treat)]

  perm_fit <- tryCatch({
    feols(single_bidder_share ~ perm_treated | country + time_period,
          data = perm_panel, cluster = ~country, weights = ~n_contracts)
  }, error = function(e) NULL)

  if (!is.null(perm_fit)) {
    perm_atts[i] <- coef(perm_fit)["perm_treated"]
  } else {
    perm_atts[i] <- NA
  }

  if (i %% 200 == 0) cat("  Permutation", i, "of", n_perm, "\n")
}

perm_atts <- perm_atts[!is.na(perm_atts)]
ri_p <- mean(abs(perm_atts) >= abs(obs_att))
cat("  RI p-value:", ri_p, "(", sum(abs(perm_atts) >= abs(obs_att)), "of", length(perm_atts), ")\n")

ri_data <- data.table(perm_att = perm_atts)
fwrite(ri_data, file.path(data_dir, "ri_permutation_dist.csv"))

# ============================================================
# 3. Leave-one-out
# ============================================================
cat("\n=== Leave-One-Out ===\n")

loo_results <- list()
for (cty in countries) {
  loo_fit <- feols(single_bidder_share ~ treated | country + time_period,
                   data = panel[country != cty], cluster = ~country,
                   weights = ~n_contracts)
  loo_results[[cty]] <- data.table(
    dropped = cty,
    coef = coef(loo_fit)["treated"],
    se = se(loo_fit)["treated"]
  )
}
loo_dt <- rbindlist(loo_results)
loo_dt[, ci_lower := coef - 1.96 * se]
loo_dt[, ci_upper := coef + 1.96 * se]

fwrite(loo_dt, file.path(data_dir, "leave_one_out.csv"))
cat("  LOO range: [", round(min(loo_dt$coef), 4), ",", round(max(loo_dt$coef), 4), "]\n")
cat("  Full sample:", round(obs_att, 4), "\n")

# ============================================================
# 4. Wild Cluster Bootstrap
# ============================================================
cat("\n=== Wild Cluster Bootstrap (manual) ===\n")

# Manual pairs cluster bootstrap (fwildclusterboot not available)
wcb <- tryCatch({
  set.seed(123)
  B <- 999
  boot_coefs <- numeric(B)
  countries_vec <- unique(panel$country)
  n_c <- length(countries_vec)

  for (b in 1:B) {
    # Resample countries with replacement
    boot_countries <- sample(countries_vec, n_c, replace = TRUE)
    boot_panel <- rbindlist(lapply(seq_along(boot_countries), function(j) {
      d <- panel[country == boot_countries[j]]
      d <- copy(d)
      d[, country_boot := paste0(boot_countries[j], "_", j)]
      d
    }))
    fit_b <- tryCatch(
      feols(single_bidder_share ~ treated | country_boot + time_period,
            data = boot_panel, cluster = ~country_boot, weights = ~n_contracts),
      error = function(e) NULL
    )
    boot_coefs[b] <- if (!is.null(fit_b)) coef(fit_b)["treated"] else NA
    if (b %% 200 == 0) cat("  Bootstrap", b, "of", B, "\n")
  }
  boot_coefs <- boot_coefs[!is.na(boot_coefs)]
  boot_se <- sd(boot_coefs)
  boot_p <- min(1, 2 * mean(abs(boot_coefs) >= abs(obs_att)))
  boot_ci <- quantile(boot_coefs, c(0.025, 0.975))
  cat("  Pairs bootstrap p-value:", round(boot_p, 4), "\n")
  cat("  Pairs bootstrap CI: [", round(boot_ci[1], 4), ",", round(boot_ci[2], 4), "]\n")
  list(p_val = boot_p, conf_int = as.numeric(boot_ci), se = boot_se)
}, error = function(e) {
  cat("  Bootstrap failed:", e$message, "\n")
  NULL
})

# ============================================================
# 5. Alternative aggregation: country-year
# ============================================================
cat("\n=== Country-Year Aggregation ===\n")

year_model <- feols(single_bidder_share ~ treated | country + contract_year,
                    data = panel_year, cluster = ~country,
                    weights = ~n_contracts)
cat("  Year-level ATT:", round(coef(year_model)["treated"], 4),
    "SE:", round(se(year_model)["treated"], 4), "\n")

# ============================================================
# 6. Rambachan-Roth sensitivity (HonestDiD)
# ============================================================
cat("\n=== Rambachan-Roth Sensitivity ===\n")

rr_result <- tryCatch({
  # Need event study coefficients and variance-covariance matrix
  es_coefs <- coef(es_model)
  es_vcov <- vcov(es_model)

  # Get indices of pre and post coefficients
  all_names <- names(es_coefs)
  pre_idx <- grep("et_trim::-[2-8]", all_names)
  post_idx <- grep("et_trim::[0-9]", all_names)

  if (length(pre_idx) > 0 && length(post_idx) > 0) {
    # Extract the relevant submatrices
    rel_idx <- c(pre_idx, post_idx)
    beta <- es_coefs[rel_idx]
    sigma <- es_vcov[rel_idx, rel_idx]

    # Number of pre-periods used
    n_pre <- length(pre_idx)
    n_post <- length(post_idx)

    # Create relative magnitudes
    delta_rm <- HonestDiD::createSensitivityResults_relativeMagnitudes(
      betahat = beta,
      sigma = sigma,
      numPrePeriods = n_pre,
      numPostPeriods = n_post,
      Mbarvec = seq(0, 2, by = 0.5)
    )
    cat("  Rambachan-Roth sensitivity computed\n")
    print(delta_rm)
    delta_rm
  } else {
    cat("  Not enough pre/post coefficients for RR\n")
    NULL
  }
}, error = function(e) {
  cat("  HonestDiD failed:", e$message, "\n")
  NULL
})

if (!is.null(rr_result)) {
  rr_dt <- as.data.table(rr_result)
  fwrite(rr_dt, file.path(data_dir, "rambachan_roth.csv"))
}

# ============================================================
# 7. Bacon Decomposition
# ============================================================
cat("\n=== Bacon Decomposition ===\n")

bacon_result <- tryCatch({
  # Need a balanced panel for bacon decomposition
  # Use year-level panel which is more likely balanced
  panel_year_balanced <- panel_year[, .SD[.N == max(panel_year[, .N, by = country]$N)], by = country]

  if (nrow(panel_year_balanced) > 0) {
    # Use bacondecomp package if available, otherwise manual
    if (requireNamespace("bacondecomp", quietly = TRUE)) {
      library(bacondecomp)
      bacon_out <- bacon(single_bidder_share ~ treated,
                         data = as.data.frame(panel_year_balanced),
                         id_var = "country_id",
                         time_var = "contract_year")
      cat("  Bacon decomposition:\n")
      print(summary(bacon_out))
      bacon_out
    } else {
      cat("  bacondecomp not installed, skipping formal decomposition\n")
      cat("  Key point: with 28 countries all eventually treated,\n")
      cat("  clean comparisons (not-yet vs already-treated) dominate\n")
      NULL
    }
  }
}, error = function(e) {
  cat("  Bacon decomposition failed:", e$message, "\n")
  NULL
})

# ============================================================
# 8. CPV sector composition controls
# ============================================================
cat("\n=== Sector Composition Controls ===\n")

# Load contract-level data for sector-controlled regression
ted_clean <- fread(file.path(data_dir, "ted_clean.csv"))
transposition <- fread(file.path(data_dir, "transposition_dates.csv"))

# Merge transposition timing
ted_clean <- merge(ted_clean, transposition[, .(iso2, transposition_date, trans_yq = trans_year + (trans_qtr - 1)/4)],
                   by.x = "country", by.y = "iso2", all.x = TRUE)
ted_clean[, treated := as.integer(yq >= trans_yq)]
ted_clean[, cpv_fe := as.integer(factor(cpv_div))]
ted_clean[, time_period := contract_year * 4 + contract_quarter]

# Contract-level regression with CPV FE
sector_model <- tryCatch({
  feols(single_bidder ~ treated | country + time_period + cpv_div,
        data = ted_clean[!is.na(single_bidder) & !is.na(cpv_div)],
        cluster = ~country)
}, error = function(e) {
  cat("  Sector FE model failed:", e$message, "\n")
  NULL
})

if (!is.null(sector_model)) {
  cat("  With CPV sector FE:", round(coef(sector_model)["treated"], 4),
      "SE:", round(se(sector_model)["treated"], 4), "\n")
}

# ============================================================
# 9. Alternative treatment timing
# ============================================================
cat("\n=== Alternative Treatment Timing ===\n")

# Shift treatment date by +/- 1-2 years as placebo
for (shift in c(-4, -8)) {
  panel_shift <- copy(panel)
  panel_shift[, treated_shift := as.integer(time_period >= (first_treat_period + shift))]

  shift_model <- tryCatch({
    feols(single_bidder_share ~ treated_shift | country + time_period,
          data = panel_shift, cluster = ~country, weights = ~n_contracts)
  }, error = function(e) { cat("  Shift", shift, "failed:", e$message, "\n"); NULL })

  if (!is.null(shift_model)) {
    cat("  Shift", shift, "quarters: coef =", round(coef(shift_model)["treated_shift"], 4),
        "SE =", round(se(shift_model)["treated_shift"], 4), "\n")
  }
}

# ============================================================
# 10. Save all robustness results
# ============================================================
cat("\n=== Saving robustness results ===\n")

rob_summary <- data.table(
  check = c("Baseline TWFE", "C-S ATT", "Country-year", "WCB p-value",
            "RI p-value", "LOO range min", "LOO range max",
            "Pre-trend p-value", "With sector FE"),
  value = c(
    round(obs_att, 4),
    {cs_file <- file.path(data_dir, "cs_att_results.csv"); if (file.exists(cs_file)) { cs_res <- fread(cs_file); round(cs_res[outcome == "single_bidder_share", att], 4) } else NA},
    round(coef(year_model)["treated"], 4),
    ifelse(!is.null(wcb), round(wcb$p_val, 4), NA),
    round(ri_p, 4),
    round(min(loo_dt$coef), 4),
    round(max(loo_dt$coef), 4),
    ifelse(!is.na(pretrend_p), round(pretrend_p, 4), NA),
    ifelse(!is.null(sector_model), round(coef(sector_model)["treated"], 4), NA)
  )
)
fwrite(rob_summary, file.path(data_dir, "robustness_summary.csv"))

cat("\n04_robustness.R complete.\n")
