# =============================================================================
# 04_robustness.R — Robustness checks and heterogeneity
# apep_1105: Treatment Dividend of Supply-Side Opioid Restrictions
# =============================================================================
source("00_packages.R")

df <- fread("../data/analysis_dataset.csv")
load("../data/models.RData")

cat("=== Robustness Checks ===\n")

# =============================================================================
# 1. Nonlinearity: HCP share quintiles
# =============================================================================
cat("\n--- Quintile specification ---\n")
m_quint <- feols(mat_rate ~ hcp_quintile + log_pop + poverty_rate + pct_black +
                   pct_hispanic + median_age + pills_per_cap + urban | state_fips,
                 data = df, vcov = ~state_fips)
cat("Quintile coefficients:\n")
print(summary(m_quint))

# =============================================================================
# 2. Leave-one-state-out jackknife
# =============================================================================
cat("\n--- Leave-one-state-out jackknife ---\n")
states <- unique(df$state_fips)
jack_coefs <- numeric(length(states))
for (i in seq_along(states)) {
  m_jack <- feols(mat_rate ~ hcp_share + log_pop + poverty_rate + pct_black +
                    pct_hispanic + median_age + pills_per_cap + urban | state_fips,
                  data = df[state_fips != states[i]], vcov = ~state_fips)
  jack_coefs[i] <- coef(m_jack)["hcp_share"]
}
cat(sprintf("Jackknife: mean=%.4f, sd=%.4f, min=%.4f, max=%.4f\n",
            mean(jack_coefs), sd(jack_coefs), min(jack_coefs), max(jack_coefs)))
cat(sprintf("Main estimate: %.4f\n", coef(m4)["hcp_share"]))
cat(sprintf("Jackknife range: [%.4f, %.4f] — all same sign: %s\n",
            min(jack_coefs), max(jack_coefs),
            ifelse(all(sign(jack_coefs) == sign(jack_coefs[1])), "YES", "NO")))

# =============================================================================
# 3. Donut analysis (drop extreme HCP share counties)
# =============================================================================
cat("\n--- Donut analysis ---\n")
df[, hcp_decile := cut(hcp_share,
                       breaks = quantile(hcp_share, probs = seq(0, 1, 0.1), na.rm = TRUE),
                       labels = 1:10, include.lowest = TRUE)]
df[, hcp_decile := as.integer(hcp_decile)]

# Drop bottom and top decile
m_donut <- feols(mat_rate ~ hcp_share + log_pop + poverty_rate + pct_black +
                   pct_hispanic + median_age + pills_per_cap + urban | state_fips,
                 data = df[hcp_decile >= 2 & hcp_decile <= 9], vcov = ~state_fips)
cat("Donut (drop extreme deciles):\n")
cat(sprintf("  β=%.4f (se=%.4f), N=%d\n",
            coef(m_donut)["hcp_share"],
            sqrt(vcov(m_donut)["hcp_share", "hcp_share"]),
            nobs(m_donut)))

# =============================================================================
# 4. Population-weighted regression
# =============================================================================
cat("\n--- Population-weighted ---\n")
m_wt <- feols(mat_rate ~ hcp_share + log_pop + poverty_rate + pct_black +
                pct_hispanic + median_age + pills_per_cap + urban | state_fips,
              data = df, weights = ~population, vcov = ~state_fips)
cat(sprintf("Weighted: β=%.4f (se=%.4f)\n",
            coef(m_wt)["hcp_share"],
            sqrt(vcov(m_wt)["hcp_share", "hcp_share"])))

# =============================================================================
# 5. Heterogeneity: Urban vs Rural
# =============================================================================
cat("\n--- Urban vs Rural heterogeneity ---\n")
m_urban <- feols(mat_rate ~ hcp_share + log_pop + poverty_rate + pct_black +
                   pct_hispanic + median_age + pills_per_cap | state_fips,
                 data = df[urban == 1], vcov = ~state_fips)
m_rural <- feols(mat_rate ~ hcp_share + log_pop + poverty_rate + pct_black +
                   pct_hispanic + median_age + pills_per_cap | state_fips,
                 data = df[urban == 0], vcov = ~state_fips)
cat(sprintf("Urban:  β=%.4f (se=%.4f), N=%d\n",
            coef(m_urban)["hcp_share"],
            sqrt(vcov(m_urban)["hcp_share", "hcp_share"]),
            nobs(m_urban)))
cat(sprintf("Rural:  β=%.4f (se=%.4f), N=%d\n",
            coef(m_rural)["hcp_share"],
            sqrt(vcov(m_rural)["hcp_share", "hcp_share"]),
            nobs(m_rural)))

# =============================================================================
# 6. Heterogeneity: High vs Low poverty
# =============================================================================
cat("\n--- Poverty heterogeneity ---\n")
med_pov <- median(df$poverty_rate, na.rm = TRUE)
m_hipov <- feols(mat_rate ~ hcp_share + log_pop + pct_black + pct_hispanic +
                   median_age + pills_per_cap + urban | state_fips,
                 data = df[poverty_rate >= med_pov], vcov = ~state_fips)
m_lopov <- feols(mat_rate ~ hcp_share + log_pop + pct_black + pct_hispanic +
                   median_age + pills_per_cap + urban | state_fips,
                 data = df[poverty_rate < med_pov], vcov = ~state_fips)
cat(sprintf("High poverty: β=%.4f (se=%.4f), N=%d\n",
            coef(m_hipov)["hcp_share"],
            sqrt(vcov(m_hipov)["hcp_share", "hcp_share"]),
            nobs(m_hipov)))
cat(sprintf("Low poverty:  β=%.4f (se=%.4f), N=%d\n",
            coef(m_lopov)["hcp_share"],
            sqrt(vcov(m_lopov)["hcp_share", "hcp_share"]),
            nobs(m_lopov)))

# =============================================================================
# Save robustness models
# =============================================================================
save(m_quint, m_donut, m_wt, m_urban, m_rural, m_hipov, m_lopov,
     jack_coefs,
     file = "../data/robustness_models.RData")

cat("\n=== ROBUSTNESS COMPLETE ===\n")
