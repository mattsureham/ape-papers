# =============================================================================
# 04_robustness.R — Robustness checks and placebo tests
# apep_0894: CFPB Payday Lending Rule and Credit-Sector Labor Markets
# =============================================================================

source("00_packages.R")

df <- readRDS("../data/panel_522.rds")
df_523 <- readRDS("../data/panel_523.rds")

# Add event time binning (consistent with main analysis)
df <- df %>%
  mutate(event_time_binned = pmax(pmin(event_time, 8), -8))

# --- 1. Placebo: NAICS 523 (Securities/Investments) -----------------------
# Securities firms should NOT be affected by the payday lending rule.

cat("=== Placebo: NAICS 523 (Securities/Investments) ===\n")

# The 523 panel already has payday_density and time vars from the merged dataset.
# Just add ln_emp for the regression.
df_523 <- df_523 %>%
  mutate(ln_emp = log(pmax(EmpEnd, 1)))

placebo_securities <- feols(
  ln_emp ~ payday_density:post_compliance + payday_density:post_rescission |
    fips + cal_quarter,
  data = df_523, cluster = ~state_fips
)

cat("Placebo (securities — should be null):\n")
summary(placebo_securities)

# --- 2. Binary treatment (top quartile vs bottom half) --------------------

cat("\n=== Binary Treatment: Top Quartile vs Bottom Half ===\n")

df_binary <- df %>%
  filter(density_quartile %in% c("Q4_top", "Q0_none", "Q1_low"))

m_binary <- feols(
  ln_emp ~ high_density:post_compliance + high_density:post_rescission |
    fips + cal_quarter,
  data = df_binary, cluster = ~state_fips
)
summary(m_binary)

# --- 3. Leave-one-state-out -----------------------------------------------

cat("\n=== Leave-One-State-Out Sensitivity ===\n")

states <- unique(df$state_fips)
loso_coefs <- tibble(
  state_dropped = character(),
  coef_compliance = numeric(),
  se_compliance = numeric()
)

for (s in states) {
  m_tmp <- feols(
    ln_emp ~ payday_density:post_compliance + payday_density:post_rescission |
      fips + cal_quarter,
    data = df %>% filter(state_fips != s),
    cluster = ~state_fips
  )
  ct <- coeftable(m_tmp)
  loso_coefs <- bind_rows(loso_coefs, tibble(
    state_dropped = s,
    coef_compliance = ct[1, "Estimate"],
    se_compliance = ct[1, "Std. Error"]
  ))
}

cat(sprintf("LOSO range: [%.4f, %.4f]\n",
            min(loso_coefs$coef_compliance),
            max(loso_coefs$coef_compliance)))

# --- 4. Pre-compliance only window (exclude COVID entirely) ----------------

cat("\n=== Clean Window: 2014Q1 - 2019Q4 (No COVID) ===\n")

df_clean <- df %>% filter(year <= 2019)

m_clean <- feols(
  ln_emp ~ payday_density:post_compliance |
    fips + cal_quarter,
  data = df_clean, cluster = ~state_fips
)
summary(m_clean)

# --- 5. Alternative treatment: extensive margin (any payday = 1) ----------

cat("\n=== Extensive Margin: Any Payday Presence ===\n")

m_extensive <- feols(
  ln_emp ~ any_payday:post_compliance + any_payday:post_rescission |
    fips + cal_quarter,
  data = df, cluster = ~state_fips
)
summary(m_extensive)

# --- 6. Restricted sample: only counties with payday presence --------------

cat("\n=== Restricted: Counties with Payday Presence Only ===\n")

df_payday_only <- df %>% filter(payday_density > 0)

m_payday_only <- feols(
  ln_emp ~ payday_density:post_compliance + payday_density:post_rescission |
    fips + cal_quarter,
  data = df_payday_only, cluster = ~state_fips
)
summary(m_payday_only)

# Clean window, payday-only counties
df_payday_clean <- df_payday_only %>% filter(year <= 2019)
m_payday_clean <- feols(
  ln_emp ~ payday_density:post_compliance |
    fips + cal_quarter,
  data = df_payday_clean, cluster = ~state_fips
)

cat("\nPayday-only, pre-COVID:\n")
summary(m_payday_clean)

# --- 7. Minimum Detectable Effect -----------------------------------------

cat("\n=== Power / MDE Calculation ===\n")

# MDE = 2.8 * SE (for 80% power at 5% significance, two-sided)
se_clean <- coeftable(m_clean)[1, "Std. Error"]
mde_clean <- 2.8 * se_clean
cat(sprintf("Clean window SE: %.4f\n", se_clean))
cat(sprintf("MDE (80%% power): %.4f log points = %.1f%% per unit density\n",
            mde_clean, 100 * (exp(mde_clean) - 1)))

# In context: mean payday density among payday counties
mean_density_payday <- mean(df$payday_density[df$payday_density > 0], na.rm = TRUE)
cat(sprintf("Mean density (payday counties): %.3f\n", mean_density_payday))
cat(sprintf("Implied MDE at mean density: %.1f%% employment change\n",
            100 * (exp(mde_clean * mean_density_payday) - 1)))

# --- 8. Save robustness results -------------------------------------------

robustness <- list(
  placebo_bank = placebo_securities,
  binary_did = m_binary,
  loso = loso_coefs,
  clean_window = m_clean,
  extensive_margin = m_extensive,
  payday_only = m_payday_only,
  payday_clean = m_payday_clean,
  mde_clean = mde_clean
)

saveRDS(robustness, "../data/robustness_results.rds")
cat("\nRobustness checks complete.\n")
