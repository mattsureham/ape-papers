## =============================================================================
## 04_robustness.R — Robustness checks and sensitivity analyses
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
panel_nozfu <- fread(file.path(data_dir, "panel_nozfu.csv"))
panel_main <- fread(file.path(data_dir, "panel_main.csv"))

## ---- 1. Placebo timing test ----
cat("=== Placebo Timing Tests ===\n")

# Test 1: Assign treatment at 2012 (3 years before actual)
panel_placebo12 <- panel_nozfu[year <= 2014]
panel_placebo12[, post_placebo := as.integer(year >= 2012)]

did_placebo12 <- feols(n_firms_created ~ lost_status:post_placebo | zus_id + year,
                       data = panel_placebo12, cluster = ~zus_id)

# Test 2: Assign treatment at 2013
panel_placebo13 <- panel_nozfu[year <= 2014]
panel_placebo13[, post_placebo := as.integer(year >= 2013)]

did_placebo13 <- feols(n_firms_created ~ lost_status:post_placebo | zus_id + year,
                       data = panel_placebo13, cluster = ~zus_id)

cat("Placebo timing results:\n")
etable(did_placebo12, did_placebo13,
       headers = c("Placebo 2012", "Placebo 2013"))

placebo_results <- data.table(
  test = c("Placebo 2012", "Placebo 2013"),
  coef = c(coef(did_placebo12)["lost_status:post_placebo"],
           coef(did_placebo13)["lost_status:post_placebo"]),
  se = c(se(did_placebo12)["lost_status:post_placebo"],
         se(did_placebo13)["lost_status:post_placebo"]),
  pval = c(pvalue(did_placebo12)["lost_status:post_placebo"],
           pvalue(did_placebo13)["lost_status:post_placebo"])
)
fwrite(placebo_results, file.path(data_dir, "placebo_timing.csv"))

## ---- 2. Entropy balancing ----
cat("\n=== Entropy Balancing ===\n")

# Pre-treatment characteristics for balancing
pre_chars <- panel_nozfu[year %in% 2010:2014, .(
  mean_firms = mean(n_firms_created),
  sd_firms = sd(n_firms_created),
  trend_firms = tryCatch(coef(lm(n_firms_created ~ year))[2], error = function(e) 0)
), by = .(zus_id, lost_status)]

# Manual entropy balancing using IPW approach
# Since ebalance package is unavailable, use a propensity score weighting approach
tryCatch({
  # Logistic regression for treatment probability
  ps_model <- glm(lost_status ~ mean_firms + sd_firms + trend_firms,
                   data = pre_chars, family = binomial)
  pre_chars[, ps := predict(ps_model, type = "response")]

  # IPW weights: 1 for treated, ps/(1-ps) for control
  pre_chars[, eb_weight := fifelse(lost_status == 1, 1, ps / (1 - ps))]
  pre_chars[eb_weight > 10, eb_weight := 10]  # Trim extreme weights

  # Merge weights to panel
  panel_eb <- merge(panel_nozfu,
                    pre_chars[, .(zus_id, eb_weight)],
                    by = "zus_id", all.x = TRUE)
  panel_eb[is.na(eb_weight), eb_weight := 1]

  # Weighted DiD
  did_eb <- feols(n_firms_created ~ lost_status:post | zus_id + year,
                  data = panel_eb, weights = ~eb_weight, cluster = ~zus_id)

  cat("IPW-weighted DiD:\n")
  summary(did_eb)

  eb_result <- data.table(
    method = "IPW Weighted",
    coef = coef(did_eb)["lost_status:post"],
    se = se(did_eb)["lost_status:post"],
    pval = pvalue(did_eb)["lost_status:post"]
  )
  fwrite(eb_result, file.path(data_dir, "entropy_balance_result.csv"))
}, error = function(e) {
  cat("IPW weighting failed:", e$message, "\n")
  cat("Proceeding without reweighting.\n")
})

## ---- 3. Alternative overlap thresholds ----
cat("\n=== Sensitivity to Overlap Thresholds ===\n")

zus_dt <- fread(file.path(data_dir, "zus_treatment_status.csv"))
panel_full <- fread(file.path(data_dir, "panel_full.csv"))

# Our treatment is based on qpv_share (fraction of ZUS communes with QPV)
# Since it's binary in most cases (0 or 1), threshold sensitivity is limited
# Instead, we vary: which ZUS to include based on number of communes
threshold_results <- list()

# Vary the kept-status threshold (require more/fewer QPV communes)
for (kept_thresh in c(0.30, 0.50, 0.70, 1.0)) {
  zus_alt <- copy(zus_dt)
  zus_alt[, status_alt := fcase(
    qpv_share == 0, "lost",
    qpv_share >= kept_thresh, "kept",
    default = "ambiguous"
  )]

  panel_alt <- merge(panel_full[, .(zus_id, year, n_firms_created, post, log_firms, rel_year)],
                     zus_alt[, .(zus_id = code_zus, status_alt, is_zfu)],
                     by = "zus_id", all.x = TRUE)
  panel_alt <- panel_alt[status_alt %in% c("lost", "kept") & is_zfu == FALSE]
  panel_alt[, lost_status := as.integer(status_alt == "lost")]

  n_lost <- panel_alt[lost_status == 1, uniqueN(zus_id)]
  n_kept <- panel_alt[lost_status == 0, uniqueN(zus_id)]

  if (n_lost >= 10 && n_kept >= 10) {
    tryCatch({
      m <- feols(n_firms_created ~ lost_status:post | zus_id + year,
                 data = panel_alt, cluster = ~zus_id)
      threshold_results[[length(threshold_results) + 1]] <- data.table(
        lost_threshold = 0,
        kept_threshold = kept_thresh,
        n_lost = n_lost,
        n_kept = n_kept,
        coef = coef(m)["lost_status:post"],
        se = se(m)["lost_status:post"],
        pval = pvalue(m)["lost_status:post"]
      )
    }, error = function(e) NULL)
  }
}

if (length(threshold_results) > 0) {
  threshold_dt <- rbindlist(threshold_results)
  cat("\nThreshold sensitivity:\n")
  print(threshold_dt)
  fwrite(threshold_dt, file.path(data_dir, "threshold_sensitivity.csv"))
}

## ---- 4. Heterogeneity by region ----
cat("\n=== Regional Heterogeneity ===\n")

# Extract department from ZUS code (first 2 digits)
panel_nozfu[, dept := substr(zus_id, 1, 2)]

# Ile-de-France vs rest
idf_depts <- c("75", "77", "78", "91", "92", "93", "94", "95")
panel_nozfu[, idf := as.integer(dept %in% idf_depts)]

# Check if there are IDF observations
cat("IDF neighborhoods:", panel_nozfu[idf == 1, uniqueN(zus_id)], "\n")
cat("Non-IDF neighborhoods:", panel_nozfu[idf == 0, uniqueN(zus_id)], "\n")

if (panel_nozfu[idf == 1, uniqueN(zus_id)] > 5 &&
    panel_nozfu[idf == 0, uniqueN(zus_id)] > 5) {
  did_idf <- feols(n_firms_created ~ lost_status:post:i(idf) | zus_id + year,
                   data = panel_nozfu, cluster = ~zus_id)

  cat("\nIle-de-France heterogeneity:\n")
  summary(did_idf)
} else {
  cat("Insufficient IDF variation for heterogeneity analysis.\n")
}

## ---- 5. Dynamic effects by period ----
cat("\n=== Short-run vs. Long-run Effects ===\n")

panel_nozfu[, `:=`(
  post_short = as.integer(year %in% 2015:2017),
  post_medium = as.integer(year %in% 2018:2020),
  post_long = as.integer(year %in% 2021:2024)
)]

did_dynamic <- feols(n_firms_created ~ lost_status:post_short +
                       lost_status:post_medium + lost_status:post_long | zus_id + year,
                     data = panel_nozfu, cluster = ~zus_id)

cat("\nDynamic effects:\n")
summary(did_dynamic)

dynamic_results <- data.table(
  period = c("Short (2015-17)", "Medium (2018-20)", "Long (2021-24)"),
  coef = coef(did_dynamic)[grep("lost_status", names(coef(did_dynamic)))],
  se = se(did_dynamic)[grep("lost_status", names(se(did_dynamic)))],
  pval = pvalue(did_dynamic)[grep("lost_status", names(pvalue(did_dynamic)))]
)
fwrite(dynamic_results, file.path(data_dir, "dynamic_effects.csv"))

## ---- 6. HonestDiD sensitivity ----
cat("\n=== HonestDiD Sensitivity Analysis ===\n")

tryCatch({
  models <- readRDS(file.path(data_dir, "models.rds"))
  es <- models$es_main

  # Extract beta and sigma for HonestDiD
  beta_hat <- coef(es)
  sigma_hat <- vcov(es)

  # Identify pre and post indices
  coef_names <- names(beta_hat)
  pre_idx <- grep("rel_year::-[2-9]:lost_status", coef_names)
  post_idx <- grep("rel_year::[0-9]:lost_status", coef_names)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    honest_result <- HonestDiD::createSensitivityResults(
      betahat = beta_hat,
      sigma = sigma_hat,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 0.5, by = 0.1)
    )
    cat("HonestDiD sensitivity computed.\n")
    fwrite(as.data.table(honest_result), file.path(data_dir, "honest_did_results.csv"))
  } else {
    cat("Insufficient pre/post periods for HonestDiD.\n")
  }
}, error = function(e) {
  cat("HonestDiD failed:", e$message, "\n")
  cat("This is non-fatal; proceeding.\n")
})

## ---- 7. Power / MDE calculation ----
cat("\n=== Minimum Detectable Effect ===\n")

pre_stats <- panel_nozfu[year %in% 2010:2014 & lost_status == 0, .(
  mean_outcome = mean(n_firms_created),
  sd_outcome = sd(n_firms_created)
)]

n_treated <- panel_nozfu[lost_status == 1, uniqueN(zus_id)]
n_control <- panel_nozfu[lost_status == 0, uniqueN(zus_id)]
n_years_post <- 10

# MDE formula: 2.8 * sigma / sqrt(N_treat * T_post)
mde <- 2.8 * pre_stats$sd_outcome / sqrt(n_treated * n_years_post)
mde_pct <- round(100 * mde / pre_stats$mean_outcome, 1)

cat("MDE (80% power, 5% sig):", round(mde, 2), "firms\n")
cat("As % of control mean:", mde_pct, "%\n")

fwrite(data.table(
  mde_level = round(mde, 2),
  control_mean = round(pre_stats$mean_outcome, 2),
  mde_pct = mde_pct,
  n_treated = n_treated,
  n_control = n_control,
  n_post_years = n_years_post
), file.path(data_dir, "power_mde.csv"))

cat("\nRobustness checks complete.\n")
