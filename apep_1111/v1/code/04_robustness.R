# 04_robustness.R — Robustness Checks
# FEMA Risk Rating 2.0 and Residential Construction

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))

# Standardize treatment
panel <- panel %>%
  mutate(
    claims_std = (claims_per_1000 - mean(claims_per_1000, na.rm = TRUE)) /
                  sd(claims_per_1000, na.rm = TRUE),
    paid_std = (paid_per_capita - mean(paid_per_capita, na.rm = TRUE)) /
                sd(paid_per_capita, na.rm = TRUE),
    event_time = year - 2021
  )

# ============================================================================
# Table 4: Robustness Checks
# ============================================================================
cat("=== Robustness Checks ===\n")

# R1: Alternative treatment — paid per capita
r1 <- feols(log_total_units ~ post:paid_std |
              fips + state_fips^year,
            data = panel,
            cluster = ~state_fips)

# R2: Drop COVID years (2020-2021)
r2 <- feols(log_total_units ~ post:claims_std |
              fips + state_fips^year,
            data = panel %>% filter(!(year %in% c(2020, 2021))),
            cluster = ~state_fips)

# R3: Only counties with meaningful NFIP presence (≥50 total claims)
r3 <- feols(log_total_units ~ post:claims_std |
              fips + state_fips^year,
            data = panel %>% filter(total_claims >= 50),
            cluster = ~state_fips)

# R4: Binary treatment — high vs low exposure
r4 <- feols(log_total_units ~ post:high_exposure |
              fips + state_fips^year,
            data = panel,
            cluster = ~state_fips)

# R5: Level outcome (total_units) instead of log
r5 <- feols(total_units ~ post:claims_std |
              fips + state_fips^year,
            data = panel,
            cluster = ~state_fips)

# R6: Permits per capita
if ("permits_per_1000" %in% names(panel)) {
  r6 <- feols(permits_per_1000 ~ post:claims_std |
                fips + state_fips^year,
              data = panel %>% filter(!is.na(permits_per_1000)),
              cluster = ~state_fips)
} else {
  r6 <- r5
}

cat("\n--- R1: Alternative treatment (paid per capita) ---\n")
cat(sprintf("  Coef: %.4f, SE: %.4f\n", coef(r1)[1], se(r1)[1]))

cat("\n--- R2: Drop COVID years ---\n")
cat(sprintf("  Coef: %.4f, SE: %.4f\n", coef(r2)[1], se(r2)[1]))

cat("\n--- R3: Counties with ≥50 claims ---\n")
cat(sprintf("  Coef: %.4f, SE: %.4f\n", coef(r3)[1], se(r3)[1]))

cat("\n--- R4: Binary treatment (top quintile) ---\n")
cat(sprintf("  Coef: %.4f, SE: %.4f\n", coef(r4)[1], se(r4)[1]))

# Export robustness table
etable(r1, r2, r3, r4, r5,
       tex = TRUE,
       file = file.path(tables_dir, "tab4_robustness.tex"),
       title = "Robustness: Alternative Specifications",
       dict = c(
         "log_total_units" = "Log Permits",
         "total_units" = "Permits (Level)",
         "permits_per_1000" = "Permits/1000",
         "post:paid_std" = "Post $\\times$ Paid/Cap",
         "paid_std:post" = "Post $\\times$ Paid/Cap",
         "post:claims_std" = "Post $\\times$ Flood Exp.",
         "claims_std:post" = "Post $\\times$ Flood Exp.",
         "post:high_exposure" = "Post $\\times$ High Exp.",
         "high_exposure:post" = "Post $\\times$ High Exp."
       ),
       label = "tab:robustness",
       headers = c("Alt. Treatment", "Drop COVID", "$\\geq$50 Claims",
                    "Binary Treat.", "Level DV"),
       style.tex = style.tex("aer"),
       notes = paste0(
         "All models include county and state$\\times$year fixed effects. ",
         "Column 1 uses cumulative paid claims per capita as treatment intensity. ",
         "Column 2 drops 2020--2021 (COVID). ",
         "Column 3 restricts to counties with $\\geq$50 historical NFIP claims. ",
         "Column 4 uses binary high-exposure indicator (top quintile). ",
         "Column 5 uses permit levels instead of logs. ",
         "Standard errors clustered by state. ",
         "$^{*}$ $p<0.10$, $^{**}$ $p<0.05$, $^{***}$ $p<0.01$."
       ),
       replace = TRUE
)

# ============================================================================
# Placebo: Test with pre-period fake treatment
# ============================================================================
cat("\n=== Placebo Test: Fake Treatment in 2017 ===\n")

placebo_panel <- panel %>%
  filter(year <= 2019) %>%
  mutate(fake_post = as.integer(year >= 2017))

placebo_m <- feols(log_total_units ~ fake_post:claims_std |
                     fips + state_fips^year,
                   data = placebo_panel,
                   cluster = ~state_fips)

cat(sprintf("Placebo coefficient: %.4f (SE: %.4f, p: %.4f)\n",
            coef(placebo_m)[1], se(placebo_m)[1], pvalue(placebo_m)[1]))

# ============================================================================
# HonestDiD Sensitivity Analysis
# ============================================================================
cat("\n=== HonestDiD Sensitivity Analysis ===\n")

# Re-run event study for HonestDiD
es_for_honest <- feols(
  log_total_units ~ i(event_time, claims_std, ref = 0) |
    fips + state_fips^year,
  data = panel,
  cluster = ~state_fips
)

# Extract coefficients and vcov for HonestDiD
tryCatch({
  es_coef_names <- names(coef(es_for_honest))
  pre_indices <- grep("event_time::-", es_coef_names)
  post_indices <- grep("event_time::[1-9]", es_coef_names)

  if (length(pre_indices) > 0 && length(post_indices) > 0) {
    beta_hat <- coef(es_for_honest)
    sigma_hat <- vcov(es_for_honest)

    # HonestDiD: smoothness restriction (Delta^SD)
    honest_result <- HonestDiD::createSensitivityResults(
      betahat = beta_hat,
      sigma = sigma_hat,
      numPrePeriods = length(pre_indices),
      numPostPeriods = length(post_indices),
      Mvec = seq(0, 0.05, by = 0.01),
      alpha = 0.05
    )

    cat("HonestDiD sensitivity (Delta^SD):\n")
    print(honest_result)

    saveRDS(honest_result, file.path(data_dir, "honest_did_results.rds"))
  } else {
    cat("Not enough pre/post periods for HonestDiD\n")
  }
}, error = function(e) {
  cat(sprintf("HonestDiD failed: %s\n", e$message))
  cat("Proceeding without sensitivity analysis.\n")
})

# Save robustness results
rob_results <- list(
  alt_treatment_coef = coef(r1)[1],
  drop_covid_coef = coef(r2)[1],
  high_claims_coef = coef(r3)[1],
  binary_coef = coef(r4)[1],
  level_coef = coef(r5)[1],
  placebo_coef = coef(placebo_m)[1],
  placebo_pval = pvalue(placebo_m)[1]
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
