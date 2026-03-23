## 04_robustness.R — Robustness checks for smart motorway analysis

args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
if (length(script_path) > 0) script_dir <- dirname(normalizePath(script_path)) else script_dir <- getwd()
source(file.path(script_dir, "00_packages.R"))
setwd(dirname(script_dir))

cat("=== Load data ===\n")
panel <- fread("data/analysis_panel.csv")
panel[, unit_id_num := as.integer(as.factor(unit_id))]
results <- readRDS("data/main_results.rds")

cat("\n=== ROBUSTNESS 1: Wild cluster bootstrap (small cluster count) ===\n")

# 32 clusters is borderline for cluster-robust SEs
# Wild cluster bootstrap provides better inference
twfe_model <- feols(rate_total ~ treated | unit_id_num + year,
                     data = panel, cluster = ~unit_id_num)

boot_result <- tryCatch({
  boottest(twfe_model, param = "treated", clustid = "unit_id_num",
           B = 9999, type = "webb", impose_null = TRUE)
}, error = function(e) {
  cat("  Wild bootstrap failed:", e$message, "\n")
  NULL
})

if (!is.null(boot_result)) {
  cat(sprintf("  Wild bootstrap p-value: %.4f\n", boot_result$p_val))
  cat(sprintf("  Wild bootstrap CI: [%.3f, %.3f]\n",
              boot_result$conf_int[1], boot_result$conf_int[2]))
  results$wild_boot_pval <- boot_result$p_val
  results$wild_boot_ci <- boot_result$conf_int
}

cat("\n=== ROBUSTNESS 2: Donut-hole (exclude conversion year) ===\n")

# Exclude the first year of smart conversion (construction disruption)
panel_donut <- panel[!(treated == 1 & year == open_year)]
cat(sprintf("  Observations dropped: %d\n", nrow(panel) - nrow(panel_donut)))

twfe_donut <- feols(rate_total ~ treated | unit_id_num + year,
                     data = panel_donut, cluster = ~unit_id_num)
cat("  TWFE (donut-hole):\n")
cat(sprintf("    Coef: %.3f (SE %.3f, p=%.4f)\n",
            coef(twfe_donut)["treated"], se(twfe_donut)["treated"],
            pvalue(twfe_donut)["treated"]))
results$twfe_donut <- list(
  coef = coef(twfe_donut)["treated"],
  se = se(twfe_donut)["treated"],
  pval = pvalue(twfe_donut)["treated"]
)

cat("\n=== ROBUSTNESS 3: Poisson model (count outcome) ===\n")

# Since collision counts are non-negative integers, Poisson may be more appropriate
pois <- fepois(n_collisions ~ treated | unit_id_num + year,
               data = panel, cluster = ~unit_id_num)
cat("  Poisson FE result:\n")
print(summary(pois))
results$poisson <- list(
  coef = coef(pois)["treated"],
  se = se(pois)["treated"],
  pval = pvalue(pois)["treated"]
)

cat("\n=== ROBUSTNESS 4: Pre-2020 sample (exclude COVID years) ===\n")

panel_precovid <- panel[year <= 2019]
twfe_precovid <- feols(rate_total ~ treated | unit_id_num + year,
                        data = panel_precovid, cluster = ~unit_id_num)
cat(sprintf("  TWFE (pre-COVID): %.3f (SE %.3f, p=%.4f)\n",
            coef(twfe_precovid)["treated"], se(twfe_precovid)["treated"],
            pvalue(twfe_precovid)["treated"]))
results$twfe_precovid <- list(
  coef = coef(twfe_precovid)["treated"],
  se = se(twfe_precovid)["treated"],
  pval = pvalue(twfe_precovid)["treated"]
)

cat("\n=== ROBUSTNESS 5: Leave-one-out (drop each treated section) ===\n")

treated_units <- unique(panel[cohort > 0]$unit_id)
loo_results <- list()

for (drop_unit in treated_units) {
  panel_loo <- panel[unit_id != drop_unit]
  panel_loo[, uid_loo := as.integer(as.factor(unit_id))]
  twfe_loo <- feols(rate_total ~ treated | uid_loo + year,
                     data = panel_loo, cluster = ~uid_loo)
  loo_results[[drop_unit]] <- coef(twfe_loo)["treated"]
}

loo_dt <- data.table(
  dropped_unit = names(loo_results),
  coef = unlist(loo_results)
)
cat("  Leave-one-out coefficients:\n")
print(loo_dt)
cat(sprintf("  Range: [%.3f, %.3f]\n", min(loo_dt$coef), max(loo_dt$coef)))
fwrite(loo_dt, "data/leave_one_out.csv")
results$loo_range <- c(min(loo_dt$coef), max(loo_dt$coef))

cat("\n=== ROBUSTNESS 6: Collision severity composition ===\n")

# Test whether smart motorways change severity composition (conditional on collision)
# Share of collisions that are KSI
panel[, share_ks := fifelse(n_collisions > 0, (n_fatal + n_serious) / n_collisions, NA_real_)]
twfe_share <- feols(share_ks ~ treated | unit_id_num + year,
                     data = panel[!is.na(share_ks)], cluster = ~unit_id_num)
cat(sprintf("  KSI share: %.4f (SE %.4f, p=%.4f)\n",
            coef(twfe_share)["treated"], se(twfe_share)["treated"],
            pvalue(twfe_share)["treated"]))
results$severity_composition <- list(
  coef = coef(twfe_share)["treated"],
  se = se(twfe_share)["treated"],
  pval = pvalue(twfe_share)["treated"]
)

# Save all results
saveRDS(results, "data/main_results.rds")

cat("\n=== Robustness checks complete ===\n")
