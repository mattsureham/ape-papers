# =============================================================================
# 04_robustness.R — Robustness checks
# apep_0965: EU Retaliatory Tariffs and US County Employment
# =============================================================================

source("00_packages.R")

panel <- fread("../data/county_panel_balanced.csv")
panel[, yq_factor := factor(paste0(year, "Q", quarter))]
panel[, fips := factor(fips)]

results <- readRDS("../data/main_results.rds")

# ---------------------------------------------------------------------------
# 1. HonestDiD: Sensitivity to pre-trend violations
# ---------------------------------------------------------------------------

message("=== HonestDiD Sensitivity Analysis ===")

es_emp <- results$es_emp

# Extract event study for HonestDiD
beta_hat <- coef(es_emp)
sigma_hat <- vcov(es_emp)

# Identify pre and post periods from coefficient names
coef_names <- names(beta_hat)
pre_idx <- grep("rel_time::-", coef_names)
post_idx <- grep("rel_time::[0-9]", coef_names)

if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
  honest_result <- tryCatch({
    HonestDiD::createSensitivityResults(
      betahat = beta_hat,
      sigma = sigma_hat,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 0.05, by = 0.01)
    )
  }, error = function(e) {
    message("HonestDiD failed: ", e$message)
    NULL
  })

  if (!is.null(honest_result)) {
    message("HonestDiD bounds computed successfully.")
    saveRDS(honest_result, "../data/honest_did_results.rds")
  }
}

# ---------------------------------------------------------------------------
# 2. Placebo timing: Treatment at 2017Q1 instead of 2018Q3
# ---------------------------------------------------------------------------

message("=== Placebo Timing Test ===")

panel_placebo <- copy(panel)
panel_placebo[, post_placebo := as.integer(year > 2017 | (year == 2017 & quarter >= 1))]

# Only use pre-treatment period for this test (2015Q1–2018Q2)
panel_placebo_pre <- panel_placebo[year < 2018 | (year == 2018 & quarter < 3)]

placebo_emp <- feols(log_emp ~ exposure_share:post_placebo | fips + yq_factor,
                     data = panel_placebo_pre, cluster = ~state_fips)

message(sprintf("Placebo (2017Q1): β = %.4f (SE = %.4f), p = %.4f",
                coef(placebo_emp), se(placebo_emp), pvalue(placebo_emp)))

# ---------------------------------------------------------------------------
# 3. Leave-one-industry-out
# ---------------------------------------------------------------------------

message("=== Leave-One-Industry-Out ===")

ind_2017q4 <- fread("../data/industry_2017q4.csv")
exposure_data <- fread("../data/county_exposure.csv")
targeted <- c("312", "331", "336")

loo_results <- list()

for (drop_ind in targeted) {
  kept <- setdiff(targeted, drop_ind)

  # Recompute exposure without dropped industry
  county_kept <- ind_2017q4[industry_code %in% kept,
    .(targeted_emp = sum(emp, na.rm = TRUE)), by = fips]

  exp_loo <- merge(exposure_data[, .(fips, total_mfg_emp)],
                   county_kept, by = "fips", all.x = TRUE)
  exp_loo[is.na(targeted_emp), targeted_emp := 0]
  exp_loo[, exposure_share_loo := targeted_emp / total_mfg_emp]
  exp_loo[is.na(exposure_share_loo), exposure_share_loo := 0]

  # Merge with panel (ensure fips types match)
  exp_loo[, fips := as.integer(fips)]
  panel_int <- copy(panel)
  panel_int[, fips := as.integer(as.character(fips))]
  panel_loo <- merge(panel_int, exp_loo[, .(fips, exposure_share_loo)],
                     by = "fips", all.x = TRUE)
  panel_loo[is.na(exposure_share_loo), exposure_share_loo := 0]
  panel_loo[, fips := factor(fips)]

  loo_mod <- feols(log_emp ~ exposure_share_loo:post | fips + yq_factor,
                   data = panel_loo, cluster = ~state_fips)

  loo_results[[drop_ind]] <- list(
    dropped = drop_ind,
    beta = as.numeric(coef(loo_mod)),
    se = as.numeric(se(loo_mod)),
    p = as.numeric(pvalue(loo_mod))
  )

  message(sprintf("  Drop NAICS %s: β = %.4f (SE = %.4f), p = %.4f",
                  drop_ind, coef(loo_mod), se(loo_mod), pvalue(loo_mod)))
}

# ---------------------------------------------------------------------------
# 4. Binary treatment (high exposure vs. none)
# ---------------------------------------------------------------------------

message("=== Binary Treatment ===")

panel[, high_exposure := as.integer(exposure_share > 0.05)]

binary_emp <- feols(log_emp ~ high_exposure:post | fips + yq_factor,
                    data = panel, cluster = ~state_fips)

message(sprintf("Binary (>5%%): β = %.4f (SE = %.4f), p = %.4f",
                coef(binary_emp), se(binary_emp), pvalue(binary_emp)))

# ---------------------------------------------------------------------------
# 5. Wild cluster bootstrap (for inference robustness with 51 clusters)
# ---------------------------------------------------------------------------

message("=== Wild Cluster Bootstrap ===")

wcb_result <- tryCatch({
  # Use fixest's built-in bootstrap
  boot_emp <- feols(log_emp ~ exposure_share:post | fips + yq_factor,
                    data = panel, cluster = ~state_fips)

  # Get bootstrapped p-value via fwildclusterboot if available
  if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
    boot_res <- fwildclusterboot::boottest(
      boot_emp,
      param = "exposure_share:post",
      clustid = ~state_fips,
      B = 999
    )
    message(sprintf("  WCB p-value: %.4f", boot_res$p_val))
    list(p_wcb = boot_res$p_val)
  } else {
    message("  fwildclusterboot not available, skipping")
    NULL
  }
}, error = function(e) {
  message("  WCB failed: ", e$message)
  NULL
})

# ---------------------------------------------------------------------------
# Save all robustness results
# ---------------------------------------------------------------------------

robustness <- list(
  placebo = list(
    beta = as.numeric(coef(placebo_emp)),
    se = as.numeric(se(placebo_emp)),
    p = as.numeric(pvalue(placebo_emp))
  ),
  loo = loo_results,
  binary = list(
    beta = as.numeric(coef(binary_emp)),
    se = as.numeric(se(binary_emp)),
    p = as.numeric(pvalue(binary_emp))
  ),
  wcb = wcb_result,
  binary_model = binary_emp,
  placebo_model = placebo_emp
)

saveRDS(robustness, "../data/robustness_results.rds")
message("Saved robustness results.")
