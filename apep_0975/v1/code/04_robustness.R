## 04_robustness.R — Robustness checks
## apep_0975: European Investigation Order and Crime Deterrence

source("00_packages.R")
setwd(file.path(dirname(getwd())))

panel <- fread("data/analysis_panel.csv")
cs_results <- readRDS("data/cs_results.rds")

cat("=== Robustness Checks ===\n\n")

robustness <- list()

# ===========================================================================
# 1. Exclude COVID years (2020-2022)
# ===========================================================================
cat("--- 1. Exclude COVID (2020-2022) ---\n")

panel_pre_covid <- panel[year <= 2019]

covid_results <- list()
for (cat_code in c("ICCS0701", "ICCS0601", "ICCS0502")) {
  cat_label <- panel[iccs == cat_code, unique(crime_label)]
  sub <- panel_pre_covid[iccs == cat_code & !is.na(rate)]

  twfe <- feols(log_rate ~ treated | geo + year, data = sub, cluster = ~geo)
  covid_results[[cat_code]] <- twfe
  cat(sprintf("  %s (pre-COVID): β = %.4f (SE = %.4f)\n",
              cat_label, coef(twfe)["treated"], se(twfe)["treated"]))
}
robustness$pre_covid <- covid_results

# ===========================================================================
# 2. Cluster-robust inference check (fixest cluster SE already applied)
# ===========================================================================
cat("\n--- 2. Cluster-Robust SE Comparison ---\n")

# Compare standard SE vs clustered SE
for (cat_code in c("ICCS0701", "ICCS0601", "ICCS0502")) {
  cat_label <- panel[iccs == cat_code, unique(crime_label)]
  sub <- panel[iccs == cat_code & !is.na(rate)]

  twfe_iid <- feols(log_rate ~ treated | geo + year, data = sub)
  twfe_cl  <- feols(log_rate ~ treated | geo + year, data = sub, cluster = ~geo)

  cat(sprintf("  %s: IID SE=%.4f, Cluster SE=%.4f (ratio=%.2f)\n",
              cat_label, se(twfe_iid)["treated"], se(twfe_cl)["treated"],
              se(twfe_cl)["treated"] / se(twfe_iid)["treated"]))
}

# ===========================================================================
# 3. Leave-one-out (drop each country)
# ===========================================================================
cat("\n--- 3. Leave-One-Out ---\n")

loo_results <- list()
for (cat_code in c("ICCS0701")) {  # Just fraud for brevity
  cat_label <- "Fraud"
  countries <- unique(panel[iccs == cat_code, geo])
  loo_coefs <- numeric(length(countries))
  names(loo_coefs) <- countries

  for (i in seq_along(countries)) {
    sub <- panel[iccs == cat_code & geo != countries[i] & !is.na(rate)]
    twfe <- feols(log_rate ~ treated | geo + year, data = sub, cluster = ~geo)
    loo_coefs[i] <- coef(twfe)["treated"]
  }

  loo_results[[cat_code]] <- loo_coefs
  cat(sprintf("  %s LOO range: [%.4f, %.4f] (baseline: %.4f)\n",
              cat_label, min(loo_coefs), max(loo_coefs),
              coef(feols(log_rate ~ treated | geo + year,
                         data = panel[iccs == cat_code & !is.na(rate)],
                         cluster = ~geo))["treated"]))
}
robustness$loo <- loo_results

# ===========================================================================
# 4. Alternative treatment timing (1-year lag)
# ===========================================================================
cat("\n--- 4. Lagged treatment (1-year delay) ---\n")

panel_lag <- copy(panel)
panel_lag[first_treat > 0, first_treat := first_treat + 1L]
panel_lag[, treated := fifelse(first_treat > 0 & year >= first_treat, 1L, 0L)]

lag_results <- list()
for (cat_code in c("ICCS0701", "ICCS0601", "ICCS0502")) {
  cat_label <- panel[iccs == cat_code, unique(crime_label)]
  sub <- panel_lag[iccs == cat_code & !is.na(rate)]

  twfe <- feols(log_rate ~ treated | geo + year, data = sub, cluster = ~geo)
  lag_results[[cat_code]] <- twfe
  cat(sprintf("  %s (1yr lag): β = %.4f (SE = %.4f)\n",
              cat_label, coef(twfe)["treated"], se(twfe)["treated"]))
}
robustness$lagged <- lag_results

# ===========================================================================
# 5. Levels (rate per 100k) instead of log
# ===========================================================================
cat("\n--- 5. Levels specification ---\n")

level_results <- list()
for (cat_code in c("ICCS0701", "ICCS0601", "ICCS0502")) {
  cat_label <- panel[iccs == cat_code, unique(crime_label)]
  sub <- panel[iccs == cat_code & !is.na(rate)]

  twfe <- feols(rate ~ treated | geo + year, data = sub, cluster = ~geo)
  level_results[[cat_code]] <- twfe
  cat(sprintf("  %s (levels): β = %.2f (SE = %.2f)\n",
              cat_label, coef(twfe)["treated"], se(twfe)["treated"]))
}
robustness$levels <- level_results

# ===========================================================================
# 6. Randomization inference
# ===========================================================================
cat("\n--- 6. Randomization Inference ---\n")

set.seed(42)
n_perms <- 500
fraud_sub <- panel[iccs == "ICCS0701" & !is.na(rate)]
actual_twfe <- feols(log_rate ~ treated | geo + year, data = fraud_sub, cluster = ~geo)
actual_coef <- coef(actual_twfe)["treated"]

# Get unique country-treatment pairs
country_treats <- unique(fraud_sub[, .(geo, first_treat)])
n_treated_ct <- sum(country_treats$first_treat > 0)

perm_coefs <- numeric(n_perms)
for (p in 1:n_perms) {
  # Randomly assign treatment years
  perm_treats <- copy(country_treats)
  perm_treats[, first_treat_perm := sample(first_treat)]  # permute treatment status
  perm_data <- merge(fraud_sub[, !c("first_treat", "treated"), with = FALSE],
                     perm_treats[, .(geo, first_treat = first_treat_perm)],
                     by = "geo")
  perm_data[, treated := fifelse(first_treat > 0 & year >= first_treat, 1L, 0L)]

  perm_twfe <- feols(log_rate ~ treated | geo + year, data = perm_data, cluster = ~geo)
  perm_coefs[p] <- coef(perm_twfe)["treated"]
}

ri_p <- mean(abs(perm_coefs) >= abs(actual_coef))
cat(sprintf("  Fraud RI p-value (500 perms): %.4f\n", ri_p))
cat(sprintf("  Actual coef: %.4f, Perm mean: %.4f, Perm SD: %.4f\n",
            actual_coef, mean(perm_coefs), sd(perm_coefs)))

robustness$ri <- list(
  actual = actual_coef,
  perm_coefs = perm_coefs,
  p_value = ri_p
)

# ===========================================================================
# Save
# ===========================================================================
saveRDS(robustness, "data/robustness_results.rds")
cat("\nRobustness checks complete.\n")
