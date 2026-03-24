## 04_robustness.R — Robustness checks and placebos
source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")

cat("=== Robustness Checks ===\n")

## ------------------------------------------------------------------
## 1. Placebo: Low-income brackets (should NOT respond to SALT)
## ------------------------------------------------------------------
cat("\n--- Placebo: SALT effect on brackets 1-3 (Under $50K) ---\n")

df_low <- df[agi_bracket <= 3]
m_placebo <- feols(
  net_mig_rate ~ i(high_salt, post_salt) | statefips + year,
  data = df_low,
  cluster = ~statefips
)
cat("SALT × Post for low-income brackets:", round(coef(m_placebo), 5), "\n")
summary(m_placebo)

## ------------------------------------------------------------------
## 2. Pre-trend test: Event study for bracket 7 ($200K+)
## ------------------------------------------------------------------
cat("\n--- Pre-trend Event Study: Bracket 7 in High-SALT States ---\n")

df7 <- df[agi_bracket == 7]
# Create relative-to-SALT-cap time
df7[, rel_salt := year - 2018]
df7[, rel_salt_f := factor(rel_salt)]

m_es <- feols(
  net_mig_rate ~ i(rel_salt_f, high_salt, ref = "-1") | statefips + year,
  data = df7,
  cluster = ~statefips
)
cat("Event study coefficients:\n")
summary(m_es)

## ------------------------------------------------------------------
## 3. Alternative clustering: state-bracket
## ------------------------------------------------------------------
cat("\n--- Alternative Clustering: State-Bracket ---\n")

m_alt_cluster <- feols(
  net_mig_rate ~ high_salt_post + high_post + i(high_salt, post_salt) + i(high_income, high_salt) |
    state_bracket + year_bracket + state_year,
  data = df,
  cluster = ~state_bracket
)
cat("Triple-diff with state×bracket clustering:\n")
summary(m_alt_cluster)

## ------------------------------------------------------------------
## 4. Exclude top 3 SALT states (NY, NJ, CT) — robustness to outliers
## ------------------------------------------------------------------
cat("\n--- Excluding NY, NJ, CT ---\n")

df_no_top3 <- df[!statefips %in% c(36, 34, 9)]
m_no_top3 <- feols(
  net_mig_rate ~ high_salt_post + high_post + i(high_salt, post_salt) + i(high_income, high_salt) |
    state_bracket + year_bracket + state_year,
  data = df_no_top3,
  cluster = ~statefips
)
cat("Triple-diff excluding NY/NJ/CT:\n")
summary(m_no_top3)

## ------------------------------------------------------------------
## 5. COVID sensitivity: exclude 2020-2021
## ------------------------------------------------------------------
cat("\n--- Excluding 2020-2021 (COVID) ---\n")

df_no_covid <- df[!year %in% c(2020, 2021)]
m_no_covid <- feols(
  net_mig_rate ~ high_salt_post + high_post + i(high_salt, post_salt) + i(high_income, high_salt) |
    state_bracket + year_bracket + state_year,
  data = df_no_covid,
  cluster = ~statefips
)
cat("Triple-diff excluding 2020-2021:\n")
summary(m_no_covid)

## ------------------------------------------------------------------
## 6. AGI-weighted migration (dollar magnitudes)
## ------------------------------------------------------------------
cat("\n--- AGI-Weighted Net Migration ---\n")

if ("net_agi_rate" %in% names(df)) {
  m_agi <- feols(
    net_agi_rate ~ high_salt_post + high_post + i(high_salt, post_salt) + i(high_income, high_salt) |
      state_bracket + year_bracket + state_year,
    data = df,
    cluster = ~statefips
  )
  cat("AGI-weighted triple-diff:\n")
  summary(m_agi)
} else {
  cat("  AGI flow data not available for all years — skipping\n")
  m_agi <- NULL
}

## ------------------------------------------------------------------
## Save robustness results
## ------------------------------------------------------------------
saveRDS(list(
  m_placebo = m_placebo,
  m_es = m_es,
  m_alt_cluster = m_alt_cluster,
  m_no_top3 = m_no_top3,
  m_no_covid = m_no_covid,
  m_agi = m_agi
), "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
