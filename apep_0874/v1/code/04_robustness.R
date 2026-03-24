# ============================================================
# 04_robustness.R — Robustness checks
# apep_0874: Feeding the Supply Side
# ============================================================

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "panel.rds"))

cat("=== Robustness Checks ===\n")

# ----------------------------------------------------------
# 1. Pre-trends test (joint F-test of pre-period coefficients)
# ----------------------------------------------------------
cat("\n=== Pre-Trends Test ===\n")

results <- readRDS(file.path(data_dir, "main_results.rds"))
es <- results$es_count

# Extract pre-period coefficients
es_coefs <- coef(es)
pre_coefs <- es_coefs[grepl("rel_time_binned::-[2-8]", names(es_coefs))]
cat("  Pre-period coefficients:\n")
print(pre_coefs)

# Joint F-test of pre-period coefficients
pre_vars <- names(pre_coefs)
if (length(pre_vars) > 0) {
  pre_test <- wald(es, keep = pre_vars)
  cat("  Joint F-test p-value:", pre_test$p, "\n")
}

# ----------------------------------------------------------
# 2. Placebo treatment date (2019Q4 instead of 2021Q4)
# ----------------------------------------------------------
cat("\n=== Placebo Treatment Date (2019Q4) ===\n")

# Use only pre-TFP data (2016-2021Q3)
panel_pre <- panel[post_tfp == 0]
placebo_time <- (2019 - 2016) * 4 + 4  # 2019Q4
panel_pre[, post_placebo := as.integer(time_id >= placebo_time)]
panel_pre[, did_placebo := treatment_intensity * post_placebo]

m_placebo_count <- feols(new_auths ~ did_placebo + ea_active | fips + time_id,
                          data = panel_pre, cluster = ~fips)
cat("  Placebo count:\n")
print(summary(m_placebo_count))

m_placebo_rate <- feols(auth_rate ~ did_placebo + ea_active | fips + time_id,
                         data = panel_pre[!is.na(auth_rate)], cluster = ~fips)
cat("  Placebo rate:\n")
print(summary(m_placebo_rate))

# ----------------------------------------------------------
# 3. Exclude early EA opt-out states
# ----------------------------------------------------------
cat("\n=== Excluding Early EA Opt-Out States ===\n")

panel_no_early <- panel[early_optout == FALSE | is.na(early_optout)]
cat("  Counties after exclusion:", uniqueN(panel_no_early$fips), "\n")

m_no_early_count <- feols(new_auths ~ did_continuous + ea_active | fips + time_id,
                           data = panel_no_early, cluster = ~fips)
cat("  Count (no early opt-out):\n")
print(summary(m_no_early_count))

m_no_early_rate <- feols(auth_rate ~ did_continuous + ea_active | fips + time_id,
                          data = panel_no_early[!is.na(auth_rate)], cluster = ~fips)
cat("  Rate (no early opt-out):\n")
print(summary(m_no_early_rate))

# ----------------------------------------------------------
# 4. Post-EA period only (2023Q2+)
# ----------------------------------------------------------
cat("\n=== Post-EA Period Only (2023Q2+) ===\n")

# After all EA ended (March 2023), only TFP persists
panel_post_ea <- panel[year > 2023 | (year == 2023 & quarter >= 2)]
panel_post_ea_full <- rbind(
  panel[post_tfp == 0],  # Pre-TFP
  panel_post_ea           # Post-EA
)
# Re-define post to ensure it's correct
panel_post_ea_full[, post_clean := as.integer(year > 2023 | (year == 2023 & quarter >= 2))]
panel_post_ea_full[, did_clean := treatment_intensity * post_clean]

if (uniqueN(panel_post_ea_full$fips) >= 20 && sum(panel_post_ea_full$post_clean) > 0) {
  m_post_ea_count <- feols(new_auths ~ did_clean | fips + time_id,
                            data = panel_post_ea_full, cluster = ~fips)
  cat("  Count (post-EA clean):\n")
  print(summary(m_post_ea_count))

  m_post_ea_rate <- feols(auth_rate ~ did_clean | fips + time_id,
                           data = panel_post_ea_full[!is.na(auth_rate)], cluster = ~fips)
  cat("  Rate (post-EA clean):\n")
  print(summary(m_post_ea_rate))
} else {
  cat("  Insufficient data for post-EA analysis.\n")
  m_post_ea_count <- NULL
  m_post_ea_rate <- NULL
}

# ----------------------------------------------------------
# 5. Alternative treatment: poverty rate
# ----------------------------------------------------------
cat("\n=== Alternative Treatment: Poverty Rate ===\n")

panel[, did_poverty := poverty_rate * post_tfp * 36.24]

m_poverty_count <- feols(new_auths ~ did_poverty + ea_active | fips + time_id,
                          data = panel, cluster = ~fips)
cat("  Count (poverty treatment):\n")
print(summary(m_poverty_count))

m_poverty_rate <- feols(auth_rate ~ did_poverty + ea_active | fips + time_id,
                         data = panel[!is.na(auth_rate)], cluster = ~fips)
cat("  Rate (poverty treatment):\n")
print(summary(m_poverty_rate))

# ----------------------------------------------------------
# 6. Population-weighted regression
# ----------------------------------------------------------
cat("\n=== Population-Weighted ===\n")

m_wt_count <- feols(new_auths ~ did_continuous + ea_active | fips + time_id,
                     data = panel, weights = ~population, cluster = ~fips)
cat("  Count (weighted):\n")
print(summary(m_wt_count))

m_wt_rate <- feols(auth_rate ~ did_continuous + ea_active | fips + time_id,
                    data = panel[!is.na(auth_rate)], weights = ~population, cluster = ~fips)
cat("  Rate (weighted):\n")
print(summary(m_wt_rate))

# ----------------------------------------------------------
# 7. Save robustness results
# ----------------------------------------------------------
cat("\n=== Saving Robustness Results ===\n")

robust_results <- list(
  placebo_count = m_placebo_count,
  placebo_rate = m_placebo_rate,
  no_early_count = m_no_early_count,
  no_early_rate = m_no_early_rate,
  post_ea_count = m_post_ea_count,
  post_ea_rate = m_post_ea_rate,
  poverty_count = m_poverty_count,
  poverty_rate = m_poverty_rate,
  weighted_count = m_wt_count,
  weighted_rate = m_wt_rate
)

saveRDS(robust_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness Complete ===\n")
