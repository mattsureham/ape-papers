# =============================================================================
# 03_main_analysis.R — Primary regressions
# apep_0894: CFPB Payday Lending Rule and Credit-Sector Labor Markets
# =============================================================================

source("00_packages.R")

df <- readRDS("../data/panel_522.rds")
pre_sds <- readRDS("../data/pre_sds.rds")

# --- 1. Summary statistics -------------------------------------------------

cat("=== Summary Statistics ===\n")
cat(sprintf("Counties: %d\n", n_distinct(df$fips)))
cat(sprintf("Quarters: %d (%s to %s)\n",
            n_distinct(df$cal_quarter), min(df$period), max(df$period)))
cat(sprintf("County-quarters: %d\n", nrow(df)))

# Treatment intensity distribution
treat_summary <- df %>%
  distinct(fips, payday_density) %>%
  summarise(
    n_counties = n(),
    n_with_payday = sum(payday_density > 0),
    mean_density = mean(payday_density),
    sd_density = sd(payday_density),
    p25 = quantile(payday_density, 0.25),
    p75 = quantile(payday_density, 0.75),
    max_density = max(payday_density)
  )
print(treat_summary)

# --- 2. Main DiD: Continuous treatment intensity ---------------------------
# Y_ct = α_c + γ_t + β₁(Density × Post_compliance) + β₂(Density × Post_rescission) + ε_ct

cat("\n=== Main DiD: Continuous Treatment Intensity ===\n")

# Employment
m1_emp <- feols(
  ln_emp ~ payday_density:post_compliance + payday_density:post_rescission |
    fips + cal_quarter,
  data = df, cluster = ~state_fips
)

# New hires
m1_hire <- feols(
  ln_hire ~ payday_density:post_compliance + payday_density:post_rescission |
    fips + cal_quarter,
  data = df, cluster = ~state_fips
)

# Separations
m1_sep <- feols(
  ln_sep ~ payday_density:post_compliance + payday_density:post_rescission |
    fips + cal_quarter,
  data = df, cluster = ~state_fips
)

# Earnings
m1_earn <- feols(
  ln_earn ~ payday_density:post_compliance + payday_density:post_rescission |
    fips + cal_quarter,
  data = df, cluster = ~state_fips
)

cat("\n--- Employment ---\n")
summary(m1_emp)
cat("\n--- New Hires ---\n")
summary(m1_hire)
cat("\n--- Separations ---\n")
summary(m1_sep)
cat("\n--- Earnings ---\n")
summary(m1_earn)

# --- 3. Event Study -------------------------------------------------------

cat("\n=== Event Study ===\n")

# Bin endpoints: lump event_time < -8 and > 8
df <- df %>%
  mutate(
    event_time_binned = pmax(pmin(event_time, 8), -8)
  )

# Event study for employment
es_emp <- feols(
  ln_emp ~ i(event_time_binned, payday_density, ref = -1) |
    fips + cal_quarter,
  data = df, cluster = ~state_fips
)

# Event study for new hires
es_hire <- feols(
  ln_hire ~ i(event_time_binned, payday_density, ref = -1) |
    fips + cal_quarter,
  data = df, cluster = ~state_fips
)

cat("\n--- Event Study: Employment ---\n")
summary(es_emp)

# --- 4. Clean pre-period test (pre-2019Q3 only) ---------------------------

cat("\n=== Pre-compliance Only (2014Q1 - 2019Q2): Trend Test ===\n")

df_pre <- df %>% filter(cal_quarter < 23)

# Test: Does density predict employment trends pre-compliance?
trend_test <- feols(
  ln_emp ~ payday_density:i(year) | fips + cal_quarter,
  data = df_pre, cluster = ~state_fips
)
cat("Pre-trend test (density × year):\n")
summary(trend_test)

# --- 5. Save results for tables -------------------------------------------

results <- list(
  m1_emp = m1_emp,
  m1_hire = m1_hire,
  m1_sep = m1_sep,
  m1_earn = m1_earn,
  es_emp = es_emp,
  es_hire = es_hire,
  treat_summary = treat_summary,
  pre_sds = pre_sds
)

saveRDS(results, "../data/main_results.rds")

# --- 6. Diagnostics for validate_v1.py ------------------------------------

n_treated <- df %>%
  filter(payday_density > 0) %>%
  distinct(fips) %>%
  nrow()

n_pre <- df %>%
  filter(post_compliance == 0) %>%
  distinct(cal_quarter) %>%
  nrow()

jsonlite::write_json(
  list(
    n_treated = n_treated,
    n_pre = n_pre,
    n_obs = nrow(df)
  ),
  "../data/diagnostics.json",
  auto_unbox = TRUE
)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, nrow(df)))
cat("Main analysis complete.\n")
