# 04_robustness.R — Robustness checks for TRI decomposition
# (1) Alternative counterfactual rates, (2) Within-facility tests, (3) State heterogeneity

library(data.table)

if (requireNamespace("here", quietly = TRUE)) setwd(here::here()) else setwd(dirname(dirname(sys.frame(1)$ofile)))

dt <- fread("data/analysis_panel.csv")
counts <- readRDS("data/decomposition.rds")
results <- readRDS("data/main_results.rds")

cat("=== ROBUSTNESS CHECKS ===\n\n")

# -----------------------------------------------------------------
# 1. Alternative counterfactual growth rates
# -----------------------------------------------------------------
cat("--- Alternative counterfactual rates ---\n")

# Baseline: -1.32% per year (from 1995-1997 CAGR)
# Alt 1: 0% growth (flat counterfactual)
# Alt 2: Use 1987-1997 CAGR
# Alt 3: Use 1994-1997 CAGR

# 1987-1997 CAGR
rate_long <- (counts[year == 1997, total_forms] / counts[year == 1987, total_forms])^(1/10) - 1
cat("1987-1997 CAGR:", round(rate_long * 100, 2), "%\n")

# 1994-1997 CAGR (from aggregate counts)
rate_short <- (counts[year == 1997, total_forms] / counts[year == 1994, total_forms])^(1/3) - 1
cat("1994-1997 CAGR:", round(rate_short * 100, 2), "%\n")

# Compute new-entrant share in 1998 under each rate
cf_base <- counts[year == 1997, total_forms] * (1 + results$annual_rate)
cf_flat <- counts[year == 1997, total_forms]  # 0% growth
cf_long <- counts[year == 1997, total_forms] * (1 + rate_long)
cf_short <- counts[year == 1997, total_forms] * (1 + rate_short)

total_1998 <- counts[year == 1998, total_forms]

rob_rates <- data.table(
  Rate = c("Baseline (1995-1997 CAGR)", "Flat (0% growth)",
           "Long-run (1987-1997)", "Short-run (1994-1997)"),
  Annual_Rate_Pct = round(c(results$annual_rate, 0, rate_long, rate_short) * 100, 2),
  CF_1998 = round(c(cf_base, cf_flat, cf_long, cf_short)),
  New_Entrant_1998 = round(total_1998 - c(cf_base, cf_flat, cf_long, cf_short)),
  Pct_New = round((total_1998 - c(cf_base, cf_flat, cf_long, cf_short)) / total_1998 * 100, 1)
)

cat("\nAlternative decompositions for 1998:\n")
print(rob_rates)

# -----------------------------------------------------------------
# 2. State-level heterogeneity
# -----------------------------------------------------------------
cat("\n--- State-level heterogeneity ---\n")

# Top reporting states vs others
state_forms <- dt[year == 1997, .(forms_97 = sum(n_chemicals), n_fac = uniqueN(tri_facility_id)),
                  by = state_abbr][order(-forms_97)]

cat("Top 10 states by 1997 forms:\n")
print(state_forms[1:10])

# High vs low reporting states
median_forms <- median(state_forms$forms_97)
state_forms[, high_state := forms_97 >= median_forms]

dt <- merge(dt, state_forms[, .(state_abbr, high_state)], by = "state_abbr", all.x = TRUE)

# Within-facility change by state group
paired <- readRDS("data/paired_analysis.rds")
paired_state <- merge(paired,
                      unique(dt[, .(tri_facility_id, state_abbr, high_state)]),
                      by = "tri_facility_id")

het_high <- paired_state[high_state == TRUE,
                         .(mean_change = mean(change), sd_change = sd(change), n = .N)]
het_low <- paired_state[high_state == FALSE,
                        .(mean_change = mean(change), sd_change = sd(change), n = .N)]

cat("\nHigh-reporting states: mean change =", round(het_high$mean_change, 3),
    "SD =", round(het_high$sd_change, 3), "N =", het_high$n, "\n")
cat("Low-reporting states: mean change =", round(het_low$mean_change, 3),
    "SD =", round(het_low$sd_change, 3), "N =", het_low$n, "\n")

# -----------------------------------------------------------------
# 3. Save robustness results
# -----------------------------------------------------------------
saveRDS(rob_rates, "data/robustness_rates.rds")
saveRDS(list(high = het_high, low = het_low), "data/het_results.rds")

# Update diagnostics
diag <- list(
  n_treated = round(mean(rob_rates$New_Entrant_1998)),
  n_pre = length(unique(dt[year < 1998]$year)),
  n_obs = nrow(dt)
)
jsonlite::write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== ROBUSTNESS COMPLETE ===\n")
