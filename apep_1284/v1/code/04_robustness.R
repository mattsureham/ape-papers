# 04_robustness.R — Robustness checks
# APEP-1284: BLM Lottery Leases and Western County Economies

source("00_packages.R")

DATA_DIR <- "../data"
load(file.path(DATA_DIR, "models.RData"))

cat("=== Robustness Checks ===\n\n")

# ============================================================
# 1. ALTERNATIVE CLUSTERING (county level)
# ============================================================
cat("--- Clustering at county level ---\n")
m_r1 <- feols(log_pc_income ~ lottery_share:post_era |
                fips + year, data = analysis[is.finite(log_pc_income)],
              cluster = ~fips)
summary(m_r1)

# ============================================================
# 2. CONLEY STANDARD ERRORS (spatial HAC)
# ============================================================
cat("\n--- Conley spatial SEs (not available; showing state + county two-way) ---\n")
m_r2 <- feols(log_pc_income ~ lottery_share:post_era |
                fips + year, data = analysis[is.finite(log_pc_income)],
              cluster = ~state + fips)
summary(m_r2)

# ============================================================
# 3. DROP EACH STATE (leave-one-out)
# ============================================================
cat("\n--- Leave-one-state-out ---\n")
states <- unique(analysis$state)
loo_results <- data.table(
  state_dropped = character(),
  coef = numeric(),
  se = numeric()
)

for (s in states) {
  sub <- analysis[state != s & is.finite(log_pc_income)]
  if (nrow(sub) < 100) next
  m <- feols(log_pc_income ~ lottery_share:post_era | fips + year,
             data = sub, cluster = ~state)
  loo_results <- rbind(loo_results, data.table(
    state_dropped = s,
    coef = coef(m)["lottery_share:post_era"],
    se = se(m)["lottery_share:post_era"]
  ))
}
print(loo_results[order(coef)])
cat(sprintf("LOO coef range: [%.4f, %.4f]\n",
            min(loo_results$coef), max(loo_results$coef)))

# ============================================================
# 4. DIFFERENT LOTTERY SHARE MEASURES
# ============================================================
cat("\n--- Alternative treatment: lottery share of all leases (incl. competitive) ---\n")
m_r4 <- feols(log_pc_income ~ lottery_share_all:post_era |
                fips + year, data = analysis[is.finite(log_pc_income)],
              cluster = ~state)
summary(m_r4)

# ============================================================
# 5. TERCILE ANALYSIS
# ============================================================
cat("\n--- Tercile analysis ---\n")
analysis[, lottery_tercile := fcase(
  lottery_share == 0, "none",
  lottery_share <= quantile(lottery_share[lottery_share > 0], 1/3), "low",
  lottery_share <= quantile(lottery_share[lottery_share > 0], 2/3), "mid",
  default = "high"
)]
analysis[, lottery_tercile := factor(lottery_tercile, levels = c("low", "none", "mid", "high"))]

m_r5 <- feols(log_pc_income ~ lottery_tercile:post_era |
                fips + year, data = analysis[is.finite(log_pc_income)],
              cluster = ~state)
summary(m_r5)

# Population
cat("\n--- Population robustness ---\n")
m_r6_pop <- feols(log_pop ~ lottery_share:post_era |
                    fips + year, data = analysis[is.finite(log_pop)],
                  cluster = ~fips)
summary(m_r6_pop)

# ============================================================
# 6. PLACEBO: EAST OF THE 100TH MERIDIAN
# ============================================================
cat("\n--- Placebo: Counties with zero lottery leases (within Western states) ---\n")
# Use counties with competitive-only leases (lottery_share = 0) as placebo
county_leases_copy <- copy(county_leases)
county_leases_copy[, has_any_leases := total_all_acres > 0]
county_leases_copy[, has_competitive_only := competitive_acres > 0 & lottery_acres == 0]

analysis[, has_competitive_only := fips %in% county_leases_copy[has_competitive_only == TRUE]$fips]
cat(sprintf("Counties with competitive-only leases: %d\n",
            sum(analysis[year == 1990]$has_competitive_only)))

# Among counties with leases, does having lottery leases matter?
m_placebo <- feols(log_pc_income ~ I(lottery_acres > 0):post_era |
                     fips + year,
                   data = analysis[is.finite(log_pc_income) & total_all_acres > 0],
                   cluster = ~state)
summary(m_placebo)

# ============================================================
# 7. SAVE ROBUSTNESS MODELS
# ============================================================
save(m_r1, m_r2, loo_results, m_r4, m_r5, m_r6_pop, m_placebo,
     file = file.path(DATA_DIR, "robustness_models.RData"))

cat("\n=== Robustness checks complete ===\n")
