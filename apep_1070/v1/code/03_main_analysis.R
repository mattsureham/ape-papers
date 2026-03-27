# =============================================================================
# 03_main_analysis.R — Triple-difference estimation
# apep_1070: H-2A Guestworker Expansion and Farm Worker Displacement
# =============================================================================

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")

cat(sprintf("Analysis panel: %d rows, %d counties, years %d-%d\n",
            nrow(df), n_distinct(df$county_fips),
            min(df$year), max(df$year)))

# ---------------------------------------------------------------------------
# 1. Triple-difference: county × quarter × ethnicity
# ---------------------------------------------------------------------------
# Y_{c,q,e} = β (ln_h2a × hispanic) + FE(county_eth) + FE(quarter_eth) + FE(state_quarter) + ε
#
# β captures: how much more (or less) Hispanic employment in agriculture changes
# in counties with greater H-2A expansion, relative to non-Hispanic workers
# in the same counties and Hispanic workers in low-H-2A counties.

# Filter to observations with non-missing outcomes
df_emp <- df %>% filter(!is.na(emp) & emp > 0)
df_earn <- df %>% filter(!is.na(earnings) & earnings > 0)
df_sep <- df %>% filter(!is.na(separations) & separations > 0)
df_hire <- df %>% filter(!is.na(hires) & hires > 0)

cat(sprintf("\nUsable obs - Emp: %d, Earnings: %d, Sep: %d, Hires: %d\n",
            nrow(df_emp), nrow(df_earn), nrow(df_sep), nrow(df_hire)))

# Main DDD specification
# Using fixest for speed with high-dimensional FEs
# Cluster at county level (treatment varies at county-year)

cat("\n=== MAIN DDD RESULTS ===\n\n")

# Employment (log)
m1_emp <- feols(
  log(emp) ~ ln_h2a:i(hispanic) |
    county_eth + quarter_eth + state_quarter,
  data = df_emp,
  cluster = ~county_fips
)

cat("--- Employment (log) ---\n")
summary(m1_emp)

# Earnings (log)
m1_earn <- feols(
  log(earnings) ~ ln_h2a:i(hispanic) |
    county_eth + quarter_eth + state_quarter,
  data = df_earn,
  cluster = ~county_fips
)

cat("\n--- Earnings (log) ---\n")
summary(m1_earn)

# Separations (log)
m1_sep <- feols(
  log(separations) ~ ln_h2a:i(hispanic) |
    county_eth + quarter_eth + state_quarter,
  data = df_sep,
  cluster = ~county_fips
)

cat("\n--- Separations (log) ---\n")
summary(m1_sep)

# Hires (log)
m1_hire <- feols(
  log(hires) ~ ln_h2a:i(hispanic) |
    county_eth + quarter_eth + state_quarter,
  data = df_hire,
  cluster = ~county_fips
)

cat("\n--- Hires (log) ---\n")
summary(m1_hire)

# ---------------------------------------------------------------------------
# 2. Store coefficients for tables
# ---------------------------------------------------------------------------
results_main <- list(
  emp = m1_emp,
  earn = m1_earn,
  sep = m1_sep,
  hire = m1_hire
)

saveRDS(results_main, "../data/results_main.rds")

# ---------------------------------------------------------------------------
# 3. Event study — binned by H-2A expansion periods
# ---------------------------------------------------------------------------
# Since H-2A data covers FY2018-2023 (pre-2018 = 0 by construction),
# we create period bins around the treatment window

df_emp <- df_emp %>%
  mutate(
    period = case_when(
      year <= 2014 ~ 1L,  # Pre (reference)
      year <= 2017 ~ 2L,  # Pre-treatment / minimal H-2A
      year <= 2019 ~ 3L,  # Early expansion (2018-2019)
      year <= 2021 ~ 4L,  # Mid expansion (2020-2021)
      TRUE ~ 5L            # Peak expansion (2022-2023)
    )
  )

# Period × ln_h2a interaction (DDD within each period)
m_event <- feols(
  log(emp) ~ i(period, ln_h2a, ref = 1):hispanic |
    county_eth + quarter_eth + state_quarter,
  data = df_emp,
  cluster = ~county_fips
)

cat("\n=== EVENT STUDY (Period-binned DDD) ===\n")
summary(m_event)

saveRDS(m_event, "../data/results_event.rds")

# ---------------------------------------------------------------------------
# 4. Bartik IV specification
# ---------------------------------------------------------------------------
cat("\n=== BARTIK IV RESULTS ===\n\n")

# IV: instrument ln_h2a with ln_bartik (shift-share)
m_iv_emp <- feols(
  log(emp) ~ 1 | county_eth + quarter_eth + state_quarter |
    ln_h2a:i(hispanic) ~ ln_bartik:i(hispanic),
  data = df_emp,
  cluster = ~county_fips
)

cat("--- IV: Employment (log) ---\n")
summary(m_iv_emp)

m_iv_earn <- feols(
  log(earnings) ~ 1 | county_eth + quarter_eth + state_quarter |
    ln_h2a:i(hispanic) ~ ln_bartik:i(hispanic),
  data = df_earn,
  cluster = ~county_fips
)

cat("\n--- IV: Earnings (log) ---\n")
summary(m_iv_earn)

results_iv <- list(
  emp = m_iv_emp,
  earn = m_iv_earn
)
saveRDS(results_iv, "../data/results_iv.rds")

# ---------------------------------------------------------------------------
# 5. Summary stats for the paper
# ---------------------------------------------------------------------------
cat("\n=== KEY SUMMARY STATISTICS ===\n")

# Pre-treatment SDs for SDE computation
# Use pre-H2A period (2010-2017, before DOL data begins) for outcome SDs
# and full-period SD for treatment intensity
pre_period <- df %>% filter(year <= 2017)

pre_sd <- pre_period %>%
  filter(!is.na(emp) & emp > 0) %>%
  summarise(
    sd_ln_emp = sd(log(emp), na.rm = TRUE),
    sd_ln_earn = sd(log(earnings), na.rm = TRUE),
    sd_ln_sep = sd(log(separations[separations > 0]), na.rm = TRUE),
    sd_ln_hire = sd(log(hires[hires > 0]), na.rm = TRUE),
    n_pre = n()
  )

# Treatment SD from post-period (when treatment varies)
post_period <- df %>% filter(year >= 2018 & hispanic == 1 & !is.na(emp) & emp > 0)
pre_sd$sd_ln_h2a <- sd(post_period$ln_h2a, na.rm = TRUE)

cat("Pre-treatment (2010-2013) SDs:\n")
print(pre_sd)

# Treatment intensity stats
cat("\nTreatment intensity (ln H-2A) for Hispanic obs:\n")
df %>%
  filter(hispanic == 1 & !is.na(emp)) %>%
  summarise(
    mean_ln_h2a = mean(ln_h2a),
    sd_ln_h2a = sd(ln_h2a),
    p25 = quantile(ln_h2a, 0.25),
    p50 = quantile(ln_h2a, 0.50),
    p75 = quantile(ln_h2a, 0.75)
  ) %>%
  print()

# County-level treatment classification
n_treated <- df %>%
  filter(year >= 2014) %>%
  group_by(county_fips) %>%
  summarise(ever_h2a = max(h2a_positions) > 0) %>%
  summarise(
    treated = sum(ever_h2a),
    control = sum(!ever_h2a)
  )
cat(sprintf("\nCounties: %d treated (any H-2A), %d control (never H-2A)\n",
            n_treated$treated, n_treated$control))

# Save diagnostics
diag <- list(
  n_treated = as.integer(n_treated$treated),
  n_pre = length(unique(df$year[df$year <= 2017])),
  n_obs = nrow(df_emp),
  n_counties = n_distinct(df$county_fips),
  years = paste(min(df$year), max(df$year), sep = "-")
)

jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics saved to data/diagnostics.json\n")

# Save pre-treatment SDs for SDE table
saveRDS(pre_sd, "../data/pre_treatment_sd.rds")

cat("\nMain analysis complete.\n")
