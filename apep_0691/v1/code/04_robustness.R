## 04_robustness.R — Robustness checks and additional analysis
## APEP-0691: Sugar Tax Without Sticker Shock

source("00_packages.R")

dental  <- fread("../data/dental_panel.csv")
obesity <- fread("../data/obesity_panel.csv")
copd    <- fread("../data/copd_panel.csv")
imd     <- fread("../data/imd_scores.csv")

# Treatment coding
dental[, post_reform := as.integer(year >= 2018)]
dental[, year_factor := factor(year)]

obesity[, post_announce := as.integer(year >= 2016)]
obesity[, post_implement := as.integer(year >= 2018)]
obesity[, year_factor := factor(year)]

copd[, post_announce := as.integer(year >= 2016)]
copd[, post_implement := as.integer(year >= 2018)]
copd[, year_factor := factor(year)]

# ============================================================================
# R1: Summary statistics by deprivation quintile
# ============================================================================

cat("=== R1: Summary statistics ===\n\n")

cat("--- Dental decay by IMD quintile (pre-SDIL: 2007-2014) ---\n")
dental_pre <- dental[year <= 2014]
print(dental_pre[, .(
  mean_decay = round(mean(value, na.rm = TRUE), 1),
  sd_decay = round(sd(value, na.rm = TRUE), 1),
  n_obs = .N
), by = imd_quintile][order(imd_quintile)])

cat("\n--- Dental decay by IMD quintile (post-SDIL: 2018-2023) ---\n")
dental_post <- dental[year >= 2018]
print(dental_post[, .(
  mean_decay = round(mean(value, na.rm = TRUE), 1),
  sd_decay = round(sd(value, na.rm = TRUE), 1),
  n_obs = .N
), by = imd_quintile][order(imd_quintile)])

cat("\n--- Pre-post change in dental decay by quintile ---\n")
dental_change <- merge(
  dental[year <= 2014, .(pre_mean = mean(value, na.rm = TRUE)), by = imd_quintile],
  dental[year >= 2018, .(post_mean = mean(value, na.rm = TRUE)), by = imd_quintile],
  by = "imd_quintile"
)
dental_change[, change := round(post_mean - pre_mean, 2)]
dental_change[, pct_change := round(100 * change / pre_mean, 1)]
print(dental_change[order(imd_quintile)])

cat("\n--- Obesity by IMD quintile (pre: 2006-2015, post: 2016-2024) ---\n")
obesity_change <- merge(
  obesity[year <= 2015, .(pre_mean = mean(value, na.rm = TRUE)), by = imd_quintile],
  obesity[year >= 2016, .(post_mean = mean(value, na.rm = TRUE)), by = imd_quintile],
  by = "imd_quintile"
)
obesity_change[, change := round(post_mean - pre_mean, 2)]
obesity_change[, pct_change := round(100 * change / pre_mean, 1)]
print(obesity_change[order(imd_quintile)])

# ============================================================================
# R2: Dental — alternative treatment timing (2021+ for full biological effect)
# ============================================================================

cat("\n=== R2: Dental — full biological exposure (2021+) ===\n")

dental[, post_full := as.integer(year >= 2021)]

m_dental_full <- feols(
  value ~ post_full:imd_std | area_code + year_factor,
  data = dental,
  cluster = ~area_code
)
summary(m_dental_full)

# ============================================================================
# R3: Obesity — excluding COVID year (2020/21)
# ============================================================================

cat("\n=== R3: Obesity — excluding COVID year ===\n")

obesity_nocovid <- obesity[year != 2020]

m_obesity_nocovid <- feols(
  value ~ post_announce:imd_std | area_code + year_factor,
  data = obesity_nocovid,
  cluster = ~area_code
)
summary(m_obesity_nocovid)

# Three-period, no COVID
m_obesity_nocovid_3 <- feols(
  value ~ post_announce:imd_std + post_implement:imd_std | area_code + year_factor,
  data = obesity_nocovid,
  cluster = ~area_code
)
summary(m_obesity_nocovid_3)

# ============================================================================
# R4: Dental — linear pre-trend control
# ============================================================================

cat("\n=== R4: Dental — linear pre-trend control ===\n")

dental[, trend := year - 2014]
dental[, trend_imd := trend * imd_std]

m_dental_trend <- feols(
  value ~ post_reform:imd_std + trend_imd | area_code + year_factor,
  data = dental,
  cluster = ~area_code
)
summary(m_dental_trend)

# ============================================================================
# R5: Obesity — linear pre-trend control
# ============================================================================

cat("\n=== R5: Obesity — linear pre-trend control ===\n")

obesity[, trend := year - 2015]
obesity[, trend_imd := trend * imd_std]

m_obesity_trend <- feols(
  value ~ post_announce:imd_std + trend_imd | area_code + year_factor,
  data = obesity,
  cluster = ~area_code
)
summary(m_obesity_trend)

# ============================================================================
# R6: COPD — excluding COVID years (2020+)
# ============================================================================

cat("\n=== R6: COPD — pre-COVID only (2010-2019) ===\n")

copd_precovid <- copd[year <= 2019]

m_copd_precovid <- feols(
  value ~ post_announce:imd_std + post_implement:imd_std | area_code + year_factor,
  data = copd_precovid,
  cluster = ~area_code
)
summary(m_copd_precovid)

# ============================================================================
# R7: National-level trends (raw means across all LAs)
# ============================================================================

cat("\n=== R7: National-level trends ===\n")

cat("\nDental decay (national mean by wave):\n")
print(dental[, .(
  mean = round(mean(value, na.rm = TRUE), 1),
  median = round(median(value, na.rm = TRUE), 1),
  n = .N
), by = year][order(year)])

cat("\nObesity (national mean by year):\n")
print(obesity[, .(
  mean = round(mean(value, na.rm = TRUE), 2),
  median = round(median(value, na.rm = TRUE), 2),
  n = .N
), by = year][order(year)])

# ============================================================================
# Save robustness results
# ============================================================================

rob_results <- list(
  dental_full_bio = m_dental_full,
  obesity_nocovid = m_obesity_nocovid,
  obesity_nocovid_3 = m_obesity_nocovid_3,
  dental_trend = m_dental_trend,
  obesity_trend = m_obesity_trend,
  copd_precovid = m_copd_precovid,
  dental_change = dental_change,
  obesity_change = obesity_change
)

saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n=== All robustness checks complete ===\n")
