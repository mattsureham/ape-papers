## 04_robustness.R — Robustness checks and placebo tests
## apep_0736: Who Counts the Dead?

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
pair_panel <- readRDS(file.path(data_dir, "pair_panel.rds"))

# Restrict to coroner vs ME
panel_cm <- panel %>% filter(is_coroner == 1 | is_me == 1)

# ─────────────────────────────────────────────────────────────────────
# Robustness 1: Balance test — demographics should not differ at border
# ─────────────────────────────────────────────────────────────────────
cat("=== Balance Test (2019 cross-section) ===\n")

pair_cs <- pair_panel %>%
  filter(is_coroner == 1 | is_me == 1) %>%
  filter(year == 2019)

bal_pop <- feols(log_pop ~ is_coroner | pair_id, data = pair_cs)
bal_pov <- feols(pct_poverty ~ is_coroner | pair_id, data = pair_cs)
bal_blk <- feols(pct_black ~ is_coroner | pair_id, data = pair_cs)
bal_inc <- feols(median_income ~ is_coroner | pair_id, data = pair_cs)

cat("Balance at border (pair FE, 2019):\n")
cat(sprintf("  log(pop):    coef=%.3f, t=%.2f\n", coef(bal_pop), coef(bal_pop)/se(bal_pop)))
cat(sprintf("  pct_poverty: coef=%.3f, t=%.2f\n", coef(bal_pov), coef(bal_pov)/se(bal_pov)))
cat(sprintf("  pct_black:   coef=%.3f, t=%.2f\n", coef(bal_blk), coef(bal_blk)/se(bal_blk)))
cat(sprintf("  median_inc:  coef=%.0f, t=%.2f\n", coef(bal_inc), coef(bal_inc)/se(bal_inc)))

# ─────────────────────────────────────────────────────────────────────
# Robustness 2: Urban/rural heterogeneity
# ─────────────────────────────────────────────────────────────────────
cat("\n=== Heterogeneity by Urbanicity ===\n")

panel_cm <- panel_cm %>%
  mutate(is_rural = urban_rural %in% c("Noncore", "Micropolitan"))

m_rural <- feols(od_rate ~ is_coroner + log_pop + pct_poverty + pct_black + pct_white |
                   state_fips + year,
                 data = filter(panel_cm, is_rural), cluster = ~state_fips)

m_urban <- feols(od_rate ~ is_coroner + log_pop + pct_poverty + pct_black + pct_white |
                   state_fips + year,
                 data = filter(panel_cm, !is_rural), cluster = ~state_fips)

cat(sprintf("Rural counties:  coef=%.3f (SE=%.3f), p=%.4f\n",
            coef(m_rural)["is_coroner"], se(m_rural)["is_coroner"],
            pvalue(m_rural)["is_coroner"]))
cat(sprintf("Urban counties:  coef=%.3f (SE=%.3f), p=%.4f\n",
            coef(m_urban)["is_coroner"], se(m_urban)["is_coroner"],
            pvalue(m_urban)["is_coroner"]))

# ─────────────────────────────────────────────────────────────────────
# Robustness 3: State-by-year FE (absorb all state-level time-varying confounders)
# ─────────────────────────────────────────────────────────────────────
cat("\n=== State × Year FE ===\n")

m_sxy <- feols(od_rate ~ is_coroner + log_pop + pct_poverty + pct_black + pct_white |
                 state_fips^year, data = panel_cm, cluster = ~state_fips)

cat(sprintf("State×Year FE: coef=%.3f (SE=%.3f), p=%.4f\n",
            coef(m_sxy)["is_coroner"], se(m_sxy)["is_coroner"],
            pvalue(m_sxy)["is_coroner"]))

# ─────────────────────────────────────────────────────────────────────
# Robustness 4: Weighted by population
# ─────────────────────────────────────────────────────────────────────
cat("\n=== Population-Weighted ===\n")

m_wt <- feols(od_rate ~ is_coroner + log_pop + pct_poverty + pct_black + pct_white |
                state_fips + year, data = panel_cm, cluster = ~state_fips,
              weights = ~population)

cat(sprintf("Pop-weighted: coef=%.3f (SE=%.3f), p=%.4f\n",
            coef(m_wt)["is_coroner"], se(m_wt)["is_coroner"],
            pvalue(m_wt)["is_coroner"]))

# ─────────────────────────────────────────────────────────────────────
# Robustness 5: Randomization Inference (permute coroner assignment within state)
# ─────────────────────────────────────────────────────────────────────
cat("\n=== Randomization Inference ===\n")

# Cross-section for RI (2019)
cs_2019 <- panel_cm %>% filter(year == 2019) %>% filter(!is.na(log_pop) & !is.na(pct_poverty))

# Observed test statistic
m_obs <- feols(od_rate ~ is_coroner + log_pop + pct_poverty + pct_black + pct_white |
                 state_fips, data = cs_2019)
obs_t <- coef(m_obs)["is_coroner"] / se(m_obs)["is_coroner"]

set.seed(42)
n_perm <- 1000
perm_t <- numeric(n_perm)

for (i in seq_len(n_perm)) {
  cs_perm <- cs_2019 %>%
    group_by(state_fips) %>%
    mutate(is_coroner_perm = sample(is_coroner)) %>%
    ungroup()

  m_perm <- feols(od_rate ~ is_coroner_perm + log_pop + pct_poverty + pct_black + pct_white |
                    state_fips, data = cs_perm)
  perm_t[i] <- coef(m_perm)["is_coroner_perm"] / se(m_perm)["is_coroner_perm"]
}

ri_pvalue <- mean(abs(perm_t) >= abs(obs_t))
cat(sprintf("RI p-value (two-sided, 1000 permutations): %.4f\n", ri_pvalue))
cat(sprintf("Observed t = %.3f, RI 95th percentile = %.3f\n",
            obs_t, quantile(abs(perm_t), 0.95)))

# ─────────────────────────────────────────────────────────────────────
# Robustness 6: Welfare calculation — national undercount
# ─────────────────────────────────────────────────────────────────────
cat("\n=== National Undercount Estimate ===\n")

# Population in coroner counties (2019)
coroner_pop_2019 <- panel_cm %>%
  filter(year == 2019, is_coroner == 1) %>%
  summarise(total_pop = sum(population, na.rm = TRUE)) %>%
  pull(total_pop)

# Preferred estimate: state + year FE + controls (m1b from main analysis)
results <- readRDS(file.path(data_dir, "main_results.rds"))
gap_estimate <- abs(coef(results$m1b)["is_coroner"])  # deaths per 100K
gap_se <- se(results$m1b)["is_coroner"]

annual_undercount <- gap_estimate * coroner_pop_2019 / 100000
undercount_lo <- (gap_estimate - 1.96 * gap_se) * coroner_pop_2019 / 100000
undercount_hi <- (gap_estimate + 1.96 * gap_se) * coroner_pop_2019 / 100000

cat(sprintf("Coroner county population (2019): %s\n", format(coroner_pop_2019, big.mark = ",")))
cat(sprintf("Detection gap: %.2f per 100K (SE=%.2f)\n", gap_estimate, gap_se))
cat(sprintf("Estimated annual undercount: %.0f deaths (95%% CI: %.0f to %.0f)\n",
            annual_undercount, undercount_lo, undercount_hi))

# ─────────────────────────────────────────────────────────────────────
# Save robustness results
# ─────────────────────────────────────────────────────────────────────
robustness <- list(
  balance = list(pop = bal_pop, pov = bal_pov, blk = bal_blk, inc = bal_inc),
  rural = m_rural, urban = m_urban,
  state_year_fe = m_sxy, pop_weighted = m_wt,
  ri_pvalue = ri_pvalue, ri_obs_t = obs_t, ri_perm_t = perm_t,
  undercount = list(
    pop = coroner_pop_2019, gap = gap_estimate, gap_se = gap_se,
    annual = annual_undercount, lo = undercount_lo, hi = undercount_hi
  )
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
