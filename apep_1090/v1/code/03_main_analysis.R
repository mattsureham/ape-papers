## 03_main_analysis.R — Main DiD regressions
## apep_1090: The Compliance Trap

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel_balanced.rds"))

cat("Panel: ", nrow(panel), "obs,", n_distinct(panel$fips), "counties\n")
cat("Years:", sort(unique(panel$year)), "\n")

# ============================================================
# 1. Standardize treatment variable
# ============================================================
# Standardize CS share for interpretability (1 SD increase)
panel <- panel %>%
  mutate(
    cs_share_std = (cs_share - mean(cs_share, na.rm = TRUE)) / sd(cs_share, na.rm = TRUE),
    snap_rate_pct = snap_rate * 100,  # Percentage points
    poverty_rate_pct = poverty_rate * 100
  )

cat("CS share SD:", round(sd(panel$cs_share, na.rm = TRUE), 4), "\n")
cat("SNAP rate mean:", round(mean(panel$snap_rate_pct, na.rm = TRUE), 2), "pp\n")
cat("SNAP rate SD:", round(sd(panel$snap_rate_pct, na.rm = TRUE), 2), "pp\n")

# Pre-treatment SD of SNAP rate (for SDE calculation)
pre_sd_snap <- panel %>%
  filter(year <= 2017) %>%
  pull(snap_rate_pct) %>%
  sd(na.rm = TRUE)
cat("Pre-treatment SNAP rate SD:", round(pre_sd_snap, 4), "pp\n")

# ============================================================
# 2. Main DiD: SNAP rate ~ CS share × Post
# ============================================================
cat("\n=== Main DiD Regressions ===\n")

# Specification 1: Basic DiD (county + year FE)
m1 <- feols(
  snap_rate_pct ~ cs_share_std:post | fips + year,
  data = panel,
  cluster = ~ state_fips
)

# Specification 2: Add poverty rate as control
m2 <- feols(
  snap_rate_pct ~ cs_share_std:post + poverty_rate_pct | fips + year,
  data = panel,
  cluster = ~ state_fips
)

# Specification 3: State-by-year FE (absorbs state-level SNAP policy changes)
m3 <- feols(
  snap_rate_pct ~ cs_share_std:post | fips + state_fips^year,
  data = panel,
  cluster = ~ state_fips
)

# Specification 4: Using post_2018 (includes transition year)
m4 <- feols(
  snap_rate_pct ~ cs_share_std:post_2018 | fips + state_fips^year,
  data = panel,
  cluster = ~ state_fips
)

cat("Main results:\n")
etable(m1, m2, m3, m4,
       headers = c("(1) Basic", "(2) + Poverty", "(3) State×Year", "(4) Post≥2018"),
       se.below = TRUE)

# ============================================================
# 3. Event Study
# ============================================================
cat("\n=== Event Study ===\n")

# Create year interactions (base year = 2017, the last pre-treatment year)
panel <- panel %>%
  mutate(
    event_year = factor(year, levels = c(2017, 2013, 2014, 2015, 2016, 2018, 2019, 2020, 2021, 2022))
  )

es <- feols(
  snap_rate_pct ~ i(year, cs_share_std, ref = 2017) | fips + state_fips^year,
  data = panel,
  cluster = ~ state_fips
)

cat("Event study coefficients:\n")
print(coeftable(es))

# Save event study results for tables
es_coefs <- as.data.frame(coeftable(es))
es_coefs$year <- as.integer(gsub("year::", "", gsub(":cs_share_std", "", rownames(es_coefs))))
saveRDS(es_coefs, file.path(data_dir, "event_study_coefs.rds"))

# ============================================================
# 4. Placebo: Poverty rate as outcome
# ============================================================
cat("\n=== Placebo: Poverty Rate ===\n")

# If our treatment proxy (CS share) drives SNAP through food access,
# it should NOT predict poverty rate changes (which have different determinants)
placebo_pov <- feols(
  poverty_rate_pct ~ cs_share_std:post | fips + state_fips^year,
  data = panel,
  cluster = ~ state_fips
)

cat("Placebo (poverty):\n")
etable(placebo_pov, se.below = TRUE)

# ============================================================
# 5. Save key results and diagnostics
# ============================================================

# Main coefficient and SE
main_coef <- coef(m3)[["cs_share_std:post"]]
main_se <- se(m3)[["cs_share_std:post"]]

cat("\n=== KEY RESULT ===\n")
cat("Main estimate (State×Year FE):", round(main_coef, 4), "pp\n")
cat("SE (clustered at state):", round(main_se, 4), "\n")
cat("t-stat:", round(main_coef / main_se, 2), "\n")
cat("SDE:", round(main_coef / pre_sd_snap, 4), "\n")

# Diagnostics for validator
n_treated_above_median <- panel %>%
  filter(cs_share > median(cs_share, na.rm = TRUE)) %>%
  pull(fips) %>%
  n_distinct()

diagnostics <- list(
  n_treated = n_treated_above_median,
  n_pre = 5L,  # 2013, 2014, 2015, 2016, 2017
  n_obs = nrow(panel),
  n_counties = n_distinct(panel$fips),
  pre_sd_snap_rate = pre_sd_snap,
  main_coef = main_coef,
  main_se = main_se,
  sde = main_coef / pre_sd_snap
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)
cat("\nDiagnostics saved to diagnostics.json\n")

# Save all models for table generation
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4,
             es = es, placebo_pov = placebo_pov),
        file.path(data_dir, "main_models.rds"))

cat("\n=== Main analysis complete ===\n")
