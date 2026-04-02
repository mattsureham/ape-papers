# ==============================================================================
# 04_robustness.R — Robustness checks and falsification
# ==============================================================================

source("00_packages.R")

qwi <- readRDS("../data/analysis_total.rds")
qwi[, state_fips := substr(fips, 1, 2)]
qwi[, ln_emp := log(private_emp + 1)]

# ==============================================================================
# 1. Alternative exposure: 2010 QCEW instead of 2012
# ==============================================================================
cat("=== Robustness 1: Alternative exposure year (2010) ===\n")
qwi[, treat_shutdown_alt := fed_share_2010 * shutdown]
rob1 <- feols(ln_emp ~ treat_shutdown_alt | fips + time_id,
              data = qwi[!is.na(fed_share_2010)], cluster = ~state_fips)
cat(sprintf("Alt exposure: coef = %.4f, se = %.4f\n",
            coef(rob1)["treat_shutdown_alt"], se(rob1)["treat_shutdown_alt"]))

# ==============================================================================
# 2. Excluding DC and Virginia (highest federal shares)
# ==============================================================================
cat("\n=== Robustness 2: Excluding DC + Virginia ===\n")
rob2 <- feols(ln_emp ~ treat_shutdown | fips + time_id,
              data = qwi[!state_fips %in% c("11", "51")], cluster = ~state_fips)
cat(sprintf("Excl DC+VA: coef = %.4f, se = %.4f\n",
            coef(rob2)["treat_shutdown"], se(rob2)["treat_shutdown"]))

# ==============================================================================
# 3. Wild cluster bootstrap (51 state clusters)
# ==============================================================================
cat("\n=== Robustness 3: Wild cluster bootstrap ===\n")
# Using fwildclusterboot for wild bootstrap p-values
boot_model <- feols(ln_emp ~ treat_shutdown | fips + time_id,
                    data = qwi, cluster = ~state_fips)
tryCatch({
  boot_res <- boottest(boot_model, param = "treat_shutdown",
                       B = 999, clustid = qwi$state_fips,
                       type = "webb")
  cat(sprintf("Wild bootstrap p-value: %.4f\n", boot_res$p_val))
  cat(sprintf("Bootstrap CI: [%.4f, %.4f]\n", boot_res$conf_int[1], boot_res$conf_int[2]))
  saveRDS(boot_res, "../data/boot_results.rds")
}, error = function(e) {
  cat(sprintf("Wild bootstrap failed: %s\n", e$message))
  cat("Falling back to standard clustered SEs.\n")
})

# ==============================================================================
# 4. Separations (mirror image test)
# ==============================================================================
cat("\n=== Robustness 4: Separations ===\n")
qwi[, ln_sep := log(private_sep + 1)]
rob4 <- feols(ln_sep ~ treat_shutdown | fips + time_id,
              data = qwi, cluster = ~state_fips)
cat(sprintf("Separations: coef = %.4f, se = %.4f\n",
            coef(rob4)["treat_shutdown"], se(rob4)["treat_shutdown"]))

# ==============================================================================
# 5. Placebo shutdown: 2016Q4 (no actual shutdown)
# ==============================================================================
cat("\n=== Robustness 5: Placebo shutdown (2016Q4) ===\n")
qwi[, placebo_shutdown := as.integer(year == 2016 & quarter == 4)]
qwi[, treat_placebo := fed_share * placebo_shutdown]
rob5 <- feols(ln_emp ~ treat_placebo | fips + time_id,
              data = qwi, cluster = ~state_fips)
cat(sprintf("Placebo 2016Q4: coef = %.4f, se = %.4f\n",
            coef(rob5)["treat_placebo"], se(rob5)["treat_placebo"]))

# ==============================================================================
# 6. Dose-response: 35-day vs 16-day
# ==============================================================================
cat("\n=== Robustness 6: Dose-response ===\n")
qwi[, treat_2013 := fed_share * shutdown_2013]
qwi[, treat_2019 := fed_share * shutdown_2019]
rob6 <- feols(ln_emp ~ treat_2013 + treat_2019 | fips + time_id,
              data = qwi, cluster = ~state_fips)
cat(sprintf("2013 (16-day): coef = %.4f, se = %.4f\n",
            coef(rob6)["treat_2013"], se(rob6)["treat_2013"]))
cat(sprintf("2019 (35-day): coef = %.4f, se = %.4f\n",
            coef(rob6)["treat_2019"], se(rob6)["treat_2019"]))
ratio <- coef(rob6)["treat_2019"] / coef(rob6)["treat_2013"]
cat(sprintf("Ratio (2019/2013): %.2f (predicted ~2.19 = 35/16)\n", ratio))

# ==============================================================================
# Save all robustness models
# ==============================================================================
rob_models <- list(
  alt_exposure = rob1,
  excl_dc_va = rob2,
  separations = rob4,
  placebo = rob5,
  dose_response = rob6
)
saveRDS(rob_models, "../data/robustness_models.rds")
cat("\nAll robustness models saved.\n")
