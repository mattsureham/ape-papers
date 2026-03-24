## 04_robustness.R — Robustness checks for apep_0882

library(tidyverse)
library(data.table)
library(fixest)
library(fwildclusterboot)
library(jsonlite)

data_dir <- file.path(dirname(getwd()), "data")
panel <- fread(file.path(data_dir, "panel.csv"))
panel[, fips := as.character(fips)]
panel[, state_fips := as.character(state_fips)]

results <- readRDS(file.path(data_dir, "main_results.rds"))

cat("=== 1. Wild Cluster Bootstrap (Main DiD) ===\n")

# Binary treatment DiD
did_binary <- results$did_binary

# Wild cluster bootstrap with Rademacher weights
set.seed(42)
boot_result <- tryCatch({
  boottest(
    did_binary,
    param = "has_oil_x_boom",
    clustid = ~state_fips,
    B = 9999,
    type = "rademacher"
  )
}, error = function(e) {
  cat("  Bootstrap error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(boot_result)) {
  cat("  WCB p-value (boom):", boot_result$p_val, "\n")
  cat("  WCB 95% CI:", boot_result$conf_int, "\n")
}

boot_bust <- tryCatch({
  boottest(
    did_binary,
    param = "has_oil_x_bust",
    clustid = ~state_fips,
    B = 9999,
    type = "rademacher"
  )
}, error = function(e) {
  cat("  Bootstrap error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(boot_bust)) {
  cat("  WCB p-value (bust):", boot_bust$p_val, "\n")
  cat("  WCB 95% CI:", boot_bust$conf_int, "\n")
}


cat("\n=== 2. State-Specific Linear Trends ===\n")

# Add state-specific linear trends to absorb different slope trends
did_trends <- feols(
  drug_od_rate ~ has_oil_x_boom + has_oil_x_bust | fips + year + state_fips[year],
  data = panel,
  cluster = ~state_fips
)

cat("With state-specific trends:\n")
print(coeftable(did_trends))


cat("\n=== 3. Leave-One-State-Out ===\n")

# Drop each state and re-estimate to check for influential states
states <- unique(panel$state_fips)
loo_results <- list()

for (st in states) {
  mod <- feols(
    drug_od_rate ~ has_oil_x_boom + has_oil_x_bust | fips + year,
    data = panel[state_fips != st],
    cluster = ~state_fips
  )
  loo_results[[st]] <- data.table(
    dropped_state = st,
    boom_coef = coef(mod)["has_oil_x_boom"],
    bust_coef = coef(mod)["has_oil_x_bust"],
    boom_se = se(mod)["has_oil_x_boom"],
    bust_se = se(mod)["has_oil_x_bust"]
  )
}

loo_df <- rbindlist(loo_results)
cat("  Leave-one-out boom coef range:", round(range(loo_df$boom_coef), 3), "\n")
cat("  Leave-one-out bust coef range:", round(range(loo_df$bust_coef), 3), "\n")
cat("  Baseline: boom =", round(coef(results$did_binary)["has_oil_x_boom"], 3),
    ", bust =", round(coef(results$did_binary)["has_oil_x_bust"], 3), "\n")

# Identify most influential state
cat("  Most influential (boom):",
    loo_df$dropped_state[which.max(abs(loo_df$boom_coef - coef(results$did_binary)["has_oil_x_boom"]))], "\n")


cat("\n=== 4. Alternative Treatment Definitions ===\n")

# 4a: Top decile of oil establishments
estab_p90 <- quantile(panel$avg_estab_211[panel$has_oil == 1], 0.9, na.rm = TRUE)
panel[, top_oil := as.integer(avg_estab_211 >= estab_p90 & has_oil == 1)]
panel[, top_x_boom := top_oil * boom]
panel[, top_x_bust := top_oil * bust]

did_top <- feols(
  drug_od_rate ~ top_x_boom + top_x_bust | fips + year,
  data = panel, cluster = ~state_fips
)
cat("Top 10% oil counties:\n")
print(coeftable(did_top))

# 4b: Non-zero employment only (counties where CBP reports actual employment)
panel[, has_emp := as.integer(oil_share > 0)]
panel[, emp_x_boom := has_emp * boom]
panel[, emp_x_bust := has_emp * bust]

did_emp <- feols(
  drug_od_rate ~ emp_x_boom + emp_x_bust | fips + year,
  data = panel, cluster = ~state_fips
)
cat("\nCounties with non-zero oil employment:\n")
print(coeftable(did_emp))


cat("\n=== 5. Placebo: Population as Outcome ===\n")

# If oil exposure affects population through migration, this should show up
panel[, log_pop := log(population)]

did_pop <- feols(
  log_pop ~ has_oil_x_boom + has_oil_x_bust | fips + year,
  data = panel, cluster = ~state_fips
)
cat("Population placebo:\n")
print(coeftable(did_pop))

# First stage: does oil exposure predict employment booms?
# Use oil price × oil share as continuous treatment
panel[, oil_price_x_share := log_wti * oil_share]
panel[, oil_price_x_has := log_wti * has_oil]

fs <- feols(
  log_pop ~ oil_price_x_has | fips + year,
  data = panel, cluster = ~state_fips
)
cat("\nOil price × has_oil → log(pop):\n")
print(coeftable(fs))


cat("\n=== 6. Heterogeneity: Pre-boom Drug Rate Quintiles ===\n")

preboom_rate <- panel[year <= 2004, .(preboom_drug = mean(drug_od_rate)), by = fips]
preboom_rate[, quintile := cut(preboom_drug,
  breaks = quantile(preboom_drug, probs = 0:5/5, na.rm = TRUE),
  labels = paste0("Q", 1:5), include.lowest = TRUE)]

panel <- merge(panel, preboom_rate[, .(fips, quintile)], by = "fips", all.x = TRUE)

for (q in paste0("Q", 1:5)) {
  mod <- feols(
    drug_od_rate ~ has_oil_x_boom + has_oil_x_bust | fips + year,
    data = panel[quintile == q],
    cluster = ~state_fips
  )
  cat(sprintf("  %s: Boom=%.3f (%.3f), Bust=%.3f (%.3f)\n",
              q, coef(mod)[1], se(mod)[1], coef(mod)[2], se(mod)[2]))
}


cat("\n=== 7. Triple-Diff Robustness: With State Trends ===\n")

# Re-estimate triple-diff with state-specific trends
panel[, oil_boom_highdrug := has_oil * boom * high_drug]
panel[, oil_bust_highdrug := has_oil * bust * high_drug]
panel[, oil_boom2 := has_oil * boom]
panel[, oil_bust2 := has_oil * bust]
panel[, drug_boom2 := high_drug * boom]
panel[, drug_bust2 := high_drug * bust]

did_triple_trend <- feols(
  drug_od_rate ~ oil_boom2 + oil_bust2 + drug_boom2 + drug_bust2 +
    oil_boom_highdrug + oil_bust_highdrug | fips + year + state_fips[year],
  data = panel,
  cluster = ~state_fips
)

cat("Triple-diff with state trends:\n")
print(coeftable(did_triple_trend))


cat("\n=== 8. MDE Calculations ===\n")

# Minimum Detectable Effect at alpha=0.05, power=0.80
mde_factor <- 2.8  # approx z_alpha/2 + z_beta for 80% power
se_boom <- se(results$did_binary)["has_oil_x_boom"]
se_bust <- se(results$did_binary)["has_oil_x_bust"]

preboom_mean <- panel[year <= 2004, mean(drug_od_rate, na.rm = TRUE)]
preboom_sd <- panel[year <= 2004, sd(drug_od_rate, na.rm = TRUE)]

cat(sprintf("  Pre-boom mean drug OD rate: %.2f per 100K\n", preboom_mean))
cat(sprintf("  Pre-boom SD: %.2f\n", preboom_sd))
cat(sprintf("  MDE (boom): %.3f per 100K (%.1f%% of mean, %.1f%% of SD)\n",
            mde_factor * se_boom, 100 * mde_factor * se_boom / preboom_mean,
            100 * mde_factor * se_boom / preboom_sd))
cat(sprintf("  MDE (bust): %.3f per 100K (%.1f%% of mean, %.1f%% of SD)\n",
            mde_factor * se_bust, 100 * mde_factor * se_bust / preboom_mean,
            100 * mde_factor * se_bust / preboom_sd))


cat("\n=== 9. Save Robustness Results ===\n")

rob_results <- list(
  wcb_boom = boot_result,
  wcb_bust = boot_bust,
  did_trends = did_trends,
  loo = loo_df,
  did_top = did_top,
  did_emp = did_emp,
  did_pop = did_pop,
  did_triple_trend = did_triple_trend
)

saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
