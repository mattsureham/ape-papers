## 04_robustness.R — Robustness checks
## apep_1315: The Forever Chemical Discount

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

## ---- 0. Rebuild balanced panel ----
panel <- panel[is.finite(hpi) & hpi > 0]
panel[, log_hpi := log(hpi)]
panel <- panel[order(zip5, year)]
panel[, hpi_growth := c(NA, diff(log_hpi)), by = zip5]

zip_counts <- panel[, .N, by = zip5]
balanced_zips <- zip_counts[N == 11, zip5]
panel_bal <- panel[zip5 %in% balanced_zips]

panel_bal[, event_time := year - 2024]
panel_bal[, max_pfas_ppt := pmax(max_pfoa_ppt, max_pfos_ppt)]
panel_bal[, log_pfas := log(max_pfas_ppt + 1)]
panel_bal[, `:=`(
  post_noprior = post * no_prior_mcl,
  treat_noprior = treat * no_prior_mcl,
  treat_post = treat * post
)]

## ---- 1. Placebo test: 2020 fake treatment ----
cat("Running placebo test (2020 fake treatment)...\n")
panel_pre <- panel_bal[year <= 2022]
panel_pre[, `:=`(
  fake_post = as.integer(year >= 2020),
  fake_treat_post = as.integer(treat == 1 & year >= 2020)
)]

placebo_2020 <- feols(
  log_hpi ~ fake_treat_post | zip5 + year,
  data = panel_pre,
  cluster = ~state
)
cat("Placebo 2020:\n")
print(summary(placebo_2020))

## ---- 2. Matched sample (CEM) ----
cat("\nRunning coarsened exact matching...\n")

# Pre-treatment characteristics for matching
pre_chars <- panel_bal[year == 2023, .(
  zip5, treat, state, log_hpi,
  max_pfas_ppt,
  prior_state_mcl
)]

# Match on pre-treatment HPI level (coarsened into quartiles)
pre_chars[, hpi_q := cut(log_hpi, breaks = quantile(log_hpi, probs = 0:4/4, na.rm = TRUE),
                          include.lowest = TRUE, labels = FALSE)]

# CEM via MatchIt
m_out <- matchit(
  treat ~ hpi_q,
  data = pre_chars[!is.na(hpi_q)],
  method = "cem"
)

matched_zips <- pre_chars[!is.na(hpi_q)][as.logical(m_out$weights > 0), zip5]
panel_matched <- panel_bal[zip5 %in% matched_zips]

cat("Matched sample: ", uniqueN(panel_matched$zip5), " ZIPs\n")
cat("  Treated:", uniqueN(panel_matched$zip5[panel_matched$treat == 1]), "\n")
cat("  Control:", uniqueN(panel_matched$zip5[panel_matched$treat == 0]), "\n")

did_matched <- feols(
  log_hpi ~ treat_post | zip5 + year,
  data = panel_matched,
  cluster = ~state
)
cat("Matched DiD:\n")
print(summary(did_matched))

## ---- 3. Excluding top contamination ZIPs (known sites) ----
cat("\nExcluding top-decile contamination ZIPs...\n")
top_decile <- quantile(panel_bal$max_pfas_ppt[panel_bal$treat == 1], 0.90, na.rm = TRUE)
panel_no_extreme <- panel_bal[max_pfas_ppt <= top_decile | treat == 0]

did_no_extreme <- feols(
  log_hpi ~ treat_post | zip5 + year,
  data = panel_no_extreme,
  cluster = ~state
)
cat("Excluding extreme contamination:\n")
print(summary(did_no_extreme))

## ---- 4. State × year fixed effects ----
cat("\nState × year fixed effects...\n")
panel_bal[, state_year := paste0(state, "_", year)]

did_state_year <- feols(
  log_hpi ~ treat_post | zip5 + state^year,
  data = panel_bal,
  cluster = ~state
)
cat("State × year FE:\n")
print(summary(did_state_year))

## ---- 5. HonestDiD sensitivity analysis ----
cat("\nHonestDiD sensitivity analysis...\n")

# Re-estimate event study for HonestDiD
es_for_honest <- feols(
  log_hpi ~ i(event_time, treat, ref = -1) | zip5 + year,
  data = panel_bal,
  cluster = ~state
)

# Extract beta and sigma for HonestDiD
beta_hat <- coef(es_for_honest)
sigma_hat <- vcov(es_for_honest)

# Identify pre and post coefficients
coef_names <- names(beta_hat)
pre_idx <- grep("event_time::-[0-9]+:treat", coef_names)
post_idx <- grep("event_time::0:treat", coef_names)

if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
  tryCatch({
    honest_result <- HonestDiD::createSensitivityResults(
      betahat = beta_hat[c(pre_idx, post_idx)],
      sigma = sigma_hat[c(pre_idx, post_idx), c(pre_idx, post_idx)],
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 0.05, by = 0.01)
    )
    cat("HonestDiD bounds (smoothness restriction):\n")
    print(honest_result)
    saveRDS(honest_result, file.path(data_dir, "honest_did_results.rds"))
  }, error = function(e) {
    cat("HonestDiD error:", conditionMessage(e), "\n")
    cat("Proceeding without HonestDiD bounds.\n")
  })
} else {
  cat("Insufficient pre/post periods for HonestDiD.\n")
}

## ---- 6. Wild cluster bootstrap (few-cluster robustness) ----
cat("\nWild cluster bootstrap...\n")
tryCatch({
  if (!requireNamespace("fwildclusterboot", quietly = TRUE)) {
    install.packages("fwildclusterboot", repos = "https://cloud.r-project.org")
  }
  library(fwildclusterboot)
  boot_result <- boottest(
    feols(log_hpi ~ treat_post | zip5 + year, data = panel_bal),
    param = "treat_post",
    clustid = ~state,
    B = 999,
    type = "rademacher"
  )
  cat("Wild cluster bootstrap:\n")
  print(summary(boot_result))
  saveRDS(boot_result, file.path(data_dir, "wild_bootstrap.rds"))
}, error = function(e) {
  cat("Bootstrap unavailable:", conditionMessage(e), "\n")
  cat("Reporting alternative: ZIP-clustered SEs instead.\n")
  did_zip <- feols(log_hpi ~ treat_post | zip5 + year, data = panel_bal, cluster = ~zip5)
  cat("ZIP-clustered: coef =", coef(did_zip)["treat_post"],
      "SE =", se(did_zip)["treat_post"],
      "p =", pvalue(did_zip)["treat_post"], "\n")
})

## ---- 7. Save all robustness results ----
rob_results <- list(
  placebo_2020 = placebo_2020,
  did_matched = did_matched,
  did_no_extreme = did_no_extreme,
  did_state_year = did_state_year
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\nRobustness checks complete.\n")
