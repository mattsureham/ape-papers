# 04_robustness.R — Robustness checks
# apep_1202: Broadband preemption and telehealth adoption

source("00_packages.R")

cat("=== Loading analysis panel ===\n")
df <- fread("../data/analysis_panel.csv")
main <- df[ruca_all == 1]
main[, th_pct := Pct_Telehealth * 100]
results <- readRDS("../data/main_results.rds")

# ============================================================
# 1. Leave-one-out (jackknife) across treated states
# ============================================================
cat("\n=== ROBUSTNESS 1: Leave-one-out treated states ===\n")

treated_states <- unique(main[preemption == 1]$state_abbr)
loo_coefs <- numeric(length(treated_states))
names(loo_coefs) <- treated_states

for (i in seq_along(treated_states)) {
  st <- treated_states[i]
  sub <- main[state_abbr != st]
  m <- feols(th_pct ~ preempt_post | state_id + time_id, data = sub, vcov = ~state_abbr)
  loo_coefs[i] <- coef(m)["preempt_post"]
}

cat(sprintf("  Main estimate: %.3f\n", results$m2_coef))
cat(sprintf("  LOO range: [%.3f, %.3f]\n", min(loo_coefs), max(loo_coefs)))
cat(sprintf("  LOO mean: %.3f\n", mean(loo_coefs)))
cat(sprintf("  Most influential state: %s (drops to %.3f)\n",
            names(which.max(abs(loo_coefs - results$m2_coef))),
            loo_coefs[which.max(abs(loo_coefs - results$m2_coef))]))

loo_dt <- data.table(state = treated_states, coef = loo_coefs)
fwrite(loo_dt, "../data/loo_results.csv")

# ============================================================
# 2. Placebo: exclude early-adopters (pre-2005 laws)
# ============================================================
cat("\n=== ROBUSTNESS 2: Exclude early adopters ===\n")

states_info <- fread("../data/state_preemption.csv")
states_info[, state_fips := as.character(state_fips)]
early_adopters <- states_info[preemption_year < 2005]$state_abbr
cat(sprintf("  Early adopters (pre-2005): %s\n", paste(early_adopters, collapse = ", ")))

main_no_early <- main[!(state_abbr %in% early_adopters)]
m_no_early <- feols(th_pct ~ preempt_post | state_id + time_id,
                    data = main_no_early, vcov = ~state_abbr)
cat(sprintf("  Without early adopters: %.3f (SE: %.3f, p: %.3f)\n",
            coef(m_no_early)["preempt_post"],
            sqrt(vcov(m_no_early)["preempt_post", "preempt_post"]),
            pvalue(m_no_early)["preempt_post"]))

# ============================================================
# 3. Controls for confounders: Medicaid expansion, telehealth parity
# ============================================================
cat("\n=== ROBUSTNESS 3: Additional controls ===\n")

# Medicaid expansion states (ACA, as of Jan 2020)
# Source: KFF. States that expanded Medicaid under ACA by 2020
medicaid_expanded <- c("AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "HI",
                       "ID", "IL", "IN", "IA", "KY", "LA", "ME", "MD", "MA",
                       "MI", "MN", "MT", "NE", "NV", "NH", "NJ", "NM", "NY",
                       "ND", "OH", "OK", "OR", "PA", "RI", "UT", "VA", "VT",
                       "WA", "WV", "WI")

main[, medicaid_exp := fifelse(state_abbr %in% medicaid_expanded, 1L, 0L)]
main[, med_exp_post := medicaid_exp * post_covid]

m_controls <- feols(th_pct ~ preempt_post + med_exp_post | state_id + time_id,
                    data = main, vcov = ~state_abbr)
cat(sprintf("  With Medicaid expansion control: %.3f (SE: %.3f)\n",
            coef(m_controls)["preempt_post"],
            sqrt(vcov(m_controls)["preempt_post", "preempt_post"])))

# ============================================================
# 4. Pre-COVID balance test (2019 ACS broadband & demographics)
# ============================================================
cat("\n=== ROBUSTNESS 4: Pre-COVID balance ===\n")

balance <- main[time_id == 1, .(state_abbr, preemption, broadband_rate_2019,
                                 med_income, pct_college)]
balance <- unique(balance, by = "state_abbr")

cat("  Broadband rate:\n")
print(balance[, .(mean = mean(broadband_rate_2019, na.rm = TRUE),
                   sd = sd(broadband_rate_2019, na.rm = TRUE)), by = preemption])

cat("  Median income:\n")
print(balance[, .(mean = mean(med_income, na.rm = TRUE),
                   sd = sd(med_income, na.rm = TRUE)), by = preemption])

cat("  College rate:\n")
print(balance[, .(mean = mean(pct_college, na.rm = TRUE),
                   sd = sd(pct_college, na.rm = TRUE)), by = preemption])

# T-tests for balance
tt_bb <- t.test(broadband_rate_2019 ~ preemption, data = balance)
tt_inc <- t.test(med_income ~ preemption, data = balance)
tt_col <- t.test(pct_college ~ preemption, data = balance)
cat(sprintf("\n  Balance p-values: broadband=%.3f, income=%.3f, college=%.3f\n",
            tt_bb$p.value, tt_inc$p.value, tt_col$p.value))

# ============================================================
# 5. Acute vs sustained phase
# ============================================================
cat("\n=== ROBUSTNESS 5: Acute vs sustained effects ===\n")

# Acute: 2020Q2-2021Q4 (time_id 2-8)
# Sustained: 2022Q1+ (time_id 9+)
main[, acute := fifelse(time_id >= 2 & time_id <= 8, 1L, 0L)]
main[, sustained := fifelse(time_id >= 9, 1L, 0L)]
main[, preempt_acute := preemption * acute]
main[, preempt_sustained := preemption * sustained]

m_phase <- feols(th_pct ~ preempt_acute + preempt_sustained | state_id + time_id,
                 data = main, vcov = ~state_abbr)
cat("  Phase-specific effects:\n")
print(summary(m_phase))

# ============================================================
# 6. Wild cluster bootstrap (few-cluster robustness)
# ============================================================
cat("\n=== ROBUSTNESS 6: Wild cluster bootstrap ===\n")

# Using fixest's built-in bootstrap
# Note: 50 state clusters is enough for standard CRSEs, but bootstrap adds reassurance
m2_boot <- feols(th_pct ~ preempt_post | state_id + time_id,
                 data = main, vcov = ~state_abbr)

# Manual wild bootstrap via fwildclusterboot if available
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  boot_res <- fwildclusterboot::boottest(m2_boot, param = "preempt_post",
                                          B = 999, clustid = ~state_abbr,
                                          type = "webb")
  cat(sprintf("  Bootstrap p-value: %.4f\n", boot_res$p_val))
  cat(sprintf("  Bootstrap 95%% CI: [%.3f, %.3f]\n",
              boot_res$conf_int[1], boot_res$conf_int[2]))
} else {
  cat("  fwildclusterboot not available; using standard cluster SEs (50 clusters is adequate)\n")
}

# ============================================================
# Save robustness results
# ============================================================
cat("\n=== Saving robustness results ===\n")

rob_results <- list(
  loo_range = range(loo_coefs),
  loo_mean = mean(loo_coefs),
  no_early_coef = coef(m_no_early)["preempt_post"],
  no_early_se = sqrt(vcov(m_no_early)["preempt_post", "preempt_post"]),
  controls_coef = coef(m_controls)["preempt_post"],
  controls_se = sqrt(vcov(m_controls)["preempt_post", "preempt_post"]),
  acute_coef = coef(m_phase)["preempt_acute"],
  acute_se = sqrt(vcov(m_phase)["preempt_acute", "preempt_acute"]),
  sustained_coef = coef(m_phase)["preempt_sustained"],
  sustained_se = sqrt(vcov(m_phase)["preempt_sustained", "preempt_sustained"]),
  balance_p_broadband = tt_bb$p.value,
  balance_p_income = tt_inc$p.value,
  balance_p_college = tt_col$p.value
)

# ============================================================
# 7. ACS broadband pre-trend analysis (2015-2019)
# ============================================================
cat("\n=== ROBUSTNESS 7: ACS broadband pre-trends ===\n")

acs_internet <- fread("../data/acs_internet.csv")
states_info[, state_fips := as.character(state_fips)]
acs_internet[, state_fips := substr(GEOID, 1, 2)]
acs_internet <- merge(acs_internet, states_info[, .(state_fips, state_abbr, preemption)],
                      by = "state_fips", all.x = TRUE)
acs_internet <- acs_internet[!is.na(state_abbr) & !is.na(broadbandE) & !is.na(total_hhE)]
acs_internet[, bb_rate := broadbandE / total_hhE * 100]

# Pre-COVID broadband panel (2015-2019)
acs_pre <- acs_internet[year <= 2019 & year >= 2015]
acs_pre[, state_id := as.integer(factor(state_abbr))]

# Event study: preemption × year interaction (ref: 2015)
m_acs_es <- feols(bb_rate ~ i(year, preemption, ref = 2015) | state_id + year,
                  data = acs_pre, vcov = ~state_abbr)
cat("  ACS broadband event study (2015-2019):\n")
print(coeftable(m_acs_es))

# Save results
rob_results$acs_pretrend <- as.list(coeftable(m_acs_es))

saveRDS(rob_results, "../data/robustness_results.rds")
saveRDS(list(m_no_early = m_no_early, m_controls = m_controls, m_phase = m_phase),
        "../data/robustness_models.rds")
cat("  Saved robustness_results.rds and robustness_models.rds\n")

cat("\n=== ROBUSTNESS COMPLETE ===\n")
