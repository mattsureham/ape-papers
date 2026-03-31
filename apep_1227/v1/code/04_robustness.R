# =============================================================================
# 04_robustness.R — Robustness checks
# =============================================================================

source("00_packages.R")

dt <- readRDS("../data/analysis_panel.rds")
load("../data/model_objects.RData")

cat("=== ROBUSTNESS CHECKS ===\n")

licensed_dt <- dt[licensed == 1]

# ===================================================================
# 1. EARLY vs LATE ADOPTERS
# ===================================================================

cat("\n--- Early adopters (2019-2020) vs Late (2021-2023) ---\n")

# Restrict to early adopters only (more post-treatment data)
early_dt <- licensed_dt[treat_year %in% c(2019, 2020) | treated_state == 0]
m_early <- feols(log_earn ~ treat_post_hisp + treat_post + post_hisp |
                   state_fips^ethnicity + cal_q^ethnicity + state_fips^cal_q,
                 data = early_dt,
                 cluster = ~state_fips)
cat(sprintf("Early adopters DDD: %.4f (SE: %.4f, p: %.3f)\n",
    coef(m_early)["treat_post_hisp"],
    se(m_early)["treat_post_hisp"],
    pvalue(m_early)["treat_post_hisp"]))

# Late adopters only
late_dt <- licensed_dt[treat_year %in% c(2021, 2022, 2023) | treated_state == 0]
m_late <- feols(log_earn ~ treat_post_hisp + treat_post + post_hisp |
                  state_fips^ethnicity + cal_q^ethnicity + state_fips^cal_q,
                data = late_dt,
                cluster = ~state_fips)
cat(sprintf("Late adopters DDD: %.4f (SE: %.4f, p: %.3f)\n",
    coef(m_late)["treat_post_hisp"],
    se(m_late)["treat_post_hisp"],
    pvalue(m_late)["treat_post_hisp"]))

# ===================================================================
# 2. WILD CLUSTER BOOTSTRAP (few-cluster inference)
# ===================================================================

cat("\n--- Wild Cluster Bootstrap ---\n")

# WCB for the main DDD
tryCatch({
  # Need to handle the FE model properly for fwildclusterboot
  # Use feols without multi-way FE for bootstrap compatibility
  m_wcb_base <- feols(log_earn ~ treat_post_hisp + treat_post + post_hisp |
                        state_fips + ethnicity + cal_q,
                      data = licensed_dt,
                      cluster = ~state_fips)

  boot_result <- boottest(m_wcb_base,
                          clustid = ~state_fips,
                          param = "treat_post_hisp",
                          B = 9999,
                          type = "webb")
  cat(sprintf("WCB p-value: %.3f\n", boot_result$p_val))
  cat(sprintf("WCB 95%% CI: [%.4f, %.4f]\n",
      boot_result$conf_int[1], boot_result$conf_int[2]))
}, error = function(e) {
  cat("WCB error:", e$message, "\n")
  cat("Skipping WCB — reporting standard clustered SEs.\n")
})

# ===================================================================
# 3. LEAVE-ONE-STATE-OUT (Jackknife)
# ===================================================================

cat("\n--- Leave-One-State-Out ---\n")

treated_states <- unique(dt[treated_state == 1, state_fips])
loo_coefs <- numeric(length(treated_states))

for (i in seq_along(treated_states)) {
  loo_dt <- licensed_dt[state_fips != treated_states[i]]
  m_loo <- feols(log_earn ~ treat_post_hisp + treat_post + post_hisp |
                   state_fips^ethnicity + cal_q^ethnicity + state_fips^cal_q,
                 data = loo_dt,
                 cluster = ~state_fips)
  loo_coefs[i] <- coef(m_loo)["treat_post_hisp"]
}

cat(sprintf("LOO range: [%.4f, %.4f]\n", min(loo_coefs), max(loo_coefs)))
cat(sprintf("LOO mean: %.4f (full sample: %.4f)\n",
    mean(loo_coefs), coef(m1)["treat_post_hisp"]))
cat(sprintf("No single state drives the result: %s\n",
    ifelse(all(sign(loo_coefs) == sign(coef(m1)["treat_post_hisp"])),
           "TRUE (all same sign)", "FALSE (sign changes)")))

# ===================================================================
# 4. ALTERNATIVE CLUSTERING
# ===================================================================

cat("\n--- Alternative Clustering ---\n")

# Cluster at state × industry
m_si_cluster <- feols(log_earn ~ treat_post_hisp + treat_post + post_hisp |
                        state_fips^ethnicity + cal_q^ethnicity + state_fips^cal_q,
                      data = licensed_dt,
                      cluster = ~state_fips + industry)
cat(sprintf("State × Industry clustering: %.4f (SE: %.4f, p: %.3f)\n",
    coef(m_si_cluster)["treat_post_hisp"],
    se(m_si_cluster)["treat_post_hisp"],
    pvalue(m_si_cluster)["treat_post_hisp"]))

# ===================================================================
# 5. PRE-PERIOD PLACEBO TEST
# ===================================================================

cat("\n--- Pre-Period Placebo (fake treatment 2 years early) ---\n")

# Shift treatment back by 2 years
placebo_dt <- copy(licensed_dt)
placebo_dt[, fake_treat_yq := treat_yq - 2]
placebo_dt[, fake_post := as.integer(yq >= fake_treat_yq)]
# Keep only pre-actual-treatment data
placebo_dt <- placebo_dt[yq < treat_yq | treated_state == 0]
placebo_dt[, fake_treat_post_hisp := fake_post * treated_state * hispanic]

m_placebo <- feols(log_earn ~ fake_treat_post_hisp |
                     state_fips^ethnicity + cal_q^ethnicity + state_fips^cal_q,
                   data = placebo_dt,
                   cluster = ~state_fips)
cat(sprintf("Placebo DDD: %.4f (SE: %.4f, p: %.3f)\n",
    coef(m_placebo)["fake_treat_post_hisp"],
    se(m_placebo)["fake_treat_post_hisp"],
    pvalue(m_placebo)["fake_treat_post_hisp"]))

# ===================================================================
# 6. DYNAMIC EFFECTS — AGGREGATE POST-PERIOD
# ===================================================================

cat("\n--- Dynamic Effects: Early vs Late Post ---\n")

# Split post-treatment into early (0-7 quarters) and late (8+ quarters)
licensed_dt[, post_early := as.integer(treated_state == 1 & event_time >= 0 & event_time <= 7)]
licensed_dt[, post_late := as.integer(treated_state == 1 & event_time > 7)]
licensed_dt[is.na(post_early), post_early := 0]
licensed_dt[is.na(post_late), post_late := 0]

m_dynamic <- feols(log_earn ~ post_early:hispanic + post_late:hispanic +
                     post_early + post_late |
                     state_fips^ethnicity + cal_q^ethnicity + state_fips^cal_q,
                   data = licensed_dt,
                   cluster = ~state_fips)
cat("Dynamic DDD:\n")
summary(m_dynamic)

# ===================================================================
# SAVE ROBUSTNESS MODELS
# ===================================================================

save(m_early, m_late, m_placebo, m_dynamic, loo_coefs,
     file = "../data/robustness_objects.RData")

cat("\nRobustness checks complete.\n")
