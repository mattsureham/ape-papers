## 04_robustness.R — Robustness checks
## apep_1222: When the Mine Money Stops

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "regression_results.rds"))

## ---- 1. Wild Cluster Bootstrap ----
cat("Running wild cluster bootstrap for main specification...\n")

# Main specification for bootstrap
did_main <- feols(log_total ~ mining:post | cve_mun + year,
                  data = panel, cluster = ~state_code)

# Wild cluster bootstrap (Webb weights, 999 iterations)
set.seed(42)
boot_result <- tryCatch({
  boottest(did_main, param = "mining:post",
           clustid = ~state_code,
           B = 999, type = "webb")
}, error = function(e) {
  message("  Wild bootstrap failed: ", e$message)
  message("  Falling back to standard clustered SEs.")
  NULL
})

if (!is.null(boot_result)) {
  cat(sprintf("  Bootstrap p-value: %.4f\n", boot_result$p_val))
  cat(sprintf("  Bootstrap CI: [%.4f, %.4f]\n",
              boot_result$conf_int[1], boot_result$conf_int[2]))
  results$boot_main <- boot_result
}

## ---- 2. Leave-One-State-Out ----
cat("Running leave-one-state-out analysis...\n")
states <- unique(panel$state_code)
loso_coefs <- numeric(length(states))
names(loso_coefs) <- states

for (i in seq_along(states)) {
  sub <- panel[state_code != states[i]]
  fit <- feols(log_total ~ mining:post | cve_mun + year,
               data = sub, cluster = ~state_code)
  loso_coefs[i] <- coef(fit)[[1]]
}
cat(sprintf("  LOSO range: [%.4f, %.4f], mean: %.4f\n",
            min(loso_coefs), max(loso_coefs), mean(loso_coefs)))

results$loso_coefs <- loso_coefs

## ---- 3. Dose-Response (Allocation Intensity) ----
cat("Running dose-response analysis...\n")

# High vs low allocation (above/below median among treated)
median_alloc <- median(panel[mining == 1 & allocation_2017 > 0]$allocation_2017)
panel[, high_mining := as.integer(allocation_2017 > median_alloc)]
panel[, low_mining := as.integer(mining == 1 & allocation_2017 <= median_alloc)]

did_dose <- feols(log_total ~ high_mining:post + low_mining:post | cve_mun + year,
                  data = panel, cluster = ~state_code)

cat("Dose-response results:\n")
summary(did_dose)
results$did_dose <- did_dose

## ---- 4. Placebo: Pre-Treatment Period ----
cat("Running placebo test (fake treatment at 2018)...\n")
panel_pre <- panel[year <= 2019]
panel_pre[, fake_post := as.integer(year >= 2018)]

did_placebo <- feols(log_total ~ mining:fake_post | cve_mun + year,
                     data = panel_pre, cluster = ~state_code)
cat(sprintf("  Placebo effect: %.4f (p = %.4f)\n",
            coef(did_placebo)[[1]], pvalue(did_placebo)[[1]]))
results$did_placebo <- did_placebo

## ---- 5. Crime-Type Heterogeneity (already in main, but detail) ----
cat("Summarizing crime-type heterogeneity...\n")
crime_het <- data.frame(
  outcome = c("Total Crime", "Homicide", "Robbery", "Extortion", "Domestic Violence"),
  coef = c(coef(results$did_total)[[1]],
           coef(results$did_homicide)[[1]],
           coef(results$did_robbery)[[1]],
           coef(results$did_extortion)[[1]],
           coef(results$did_dv)[[1]]),
  se = c(se(results$did_total)[[1]],
         se(results$did_homicide)[[1]],
         se(results$did_robbery)[[1]],
         se(results$did_extortion)[[1]],
         se(results$did_dv)[[1]]),
  pval = c(pvalue(results$did_total)[[1]],
           pvalue(results$did_homicide)[[1]],
           pvalue(results$did_robbery)[[1]],
           pvalue(results$did_extortion)[[1]],
           pvalue(results$did_dv)[[1]])
)
print(crime_het)
results$crime_het <- crime_het

## ---- Save updated results ----
saveRDS(results, file.path(data_dir, "regression_results.rds"))
cat("\nRobustness checks complete. Results updated.\n")
