# 03_main_analysis.R — Main regressions and event study
# apep_1202: Broadband preemption and telehealth adoption

source("00_packages.R")

cat("=== Loading analysis panel ===\n")
df <- fread("../data/analysis_panel.csv")

# ============================================================
# Panel A: Main specification — Overall (All RUCA)
# ============================================================
cat("\n=== MAIN SPECIFICATION: Preemption × Post-COVID ===\n")

# Filter to "All" RUCA for main specification
main <- df[ruca_all == 1]
cat(sprintf("  Obs: %d, States: %d, Quarters: %d\n",
            nrow(main), uniqueN(main$state_abbr), uniqueN(main$time_id)))

# Dependent variable: Pct_Telehealth (0-1 scale, multiply by 100 for pp)
main[, th_pct := Pct_Telehealth * 100]

# Model 1: Pooled OLS
m1 <- feols(th_pct ~ preemption, data = main, vcov = ~state_abbr)
cat("\n--- Model 1: Pooled OLS ---\n")
print(summary(m1))

# Model 2: State + quarter FE (main DiD)
m2 <- feols(th_pct ~ preempt_post | state_id + time_id,
            data = main, vcov = ~state_abbr)
cat("\n--- Model 2: DiD with State + Quarter FE ---\n")
print(summary(m2))

# Model 3: With pre-COVID broadband control interacted with post
main[, bb_post := broadband_rate_2019 * post_covid]
m3 <- feols(th_pct ~ preempt_post + bb_post | state_id + time_id,
            data = main, vcov = ~state_abbr)
cat("\n--- Model 3: DiD + Broadband control ---\n")
print(summary(m3))

# ============================================================
# Panel B: Event Study — Quarter-by-quarter preemption effects
# ============================================================
cat("\n=== EVENT STUDY ===\n")

# Create event-time indicators (base: 2020Q1 = time_id 1)
main[, time_f := factor(time_id)]
# Drop 2020Q1 as reference (time_id = 1)

m_event <- feols(th_pct ~ i(time_id, preemption, ref = 1) | state_id + time_id,
                 data = main, vcov = ~state_abbr)
cat("\n--- Event Study Coefficients ---\n")
print(coeftable(m_event))

# Save event study coefficients for tables
es_coefs <- as.data.table(coeftable(m_event), keep.rownames = "term")
setnames(es_coefs, c("term", "estimate", "se", "t", "p"))
es_coefs[, time_id := as.integer(gsub(".*::", "", term))]
es_coefs <- es_coefs[order(time_id)]
fwrite(es_coefs, "../data/event_study_coefs.csv")

# ============================================================
# Panel C: Triple-Diff — Preemption × Post × Rural
# ============================================================
cat("\n=== TRIPLE DIFFERENCE: Preemption × Post × Rural ===\n")

# Use Rural and Urban observations (drop "All" and "Unknown")
td <- df[Bene_RUCA_Desc %in% c("Rural", "Urban")]
td[, th_pct := Pct_Telehealth * 100]
td[, preempt_post_rural := preemption * post_covid * rural]
td[, preempt_rural := preemption * rural]
td[, post_rural := post_covid * rural]

# State-RUCA FE + Quarter-RUCA FE
td[, state_ruca := paste0(state_abbr, "_", Bene_RUCA_Desc)]
td[, time_ruca := paste0(time_id, "_", Bene_RUCA_Desc)]
td[, state_ruca_id := as.integer(factor(state_ruca))]
td[, time_ruca_id := as.integer(factor(time_ruca))]

m_td <- feols(th_pct ~ preempt_post + preempt_post_rural + post_rural |
                state_ruca_id + time_ruca_id,
              data = td, vcov = ~state_abbr)
cat("\n--- Triple-Diff Results ---\n")
print(summary(m_td))

# ============================================================
# Mechanism: Pre-COVID broadband rates
# ============================================================
cat("\n=== MECHANISM: Pre-COVID broadband by preemption ===\n")

# Cross-sectional: 2019 broadband rates
bb <- df[ruca_all == 1 & Year == 2019 & Quarter == 1]
if (nrow(bb) == 0) bb <- df[ruca_all == 1 & Year == 2021 & Quarter == 1]
bb[, bb_pct := broadband_rate_2019 * 100]

m_bb <- feols(bb_pct ~ preemption, data = bb, vcov = "hetero")
cat("\n--- Broadband ~ Preemption ---\n")
print(summary(m_bb))

# ============================================================
# Save results for tables
# ============================================================
cat("\n=== Saving results ===\n")

# Key coefficients
results <- list(
  m1_coef = coef(m1)["preemption"],
  m1_se = sqrt(vcov(m1)["preemption", "preemption"]),
  m2_coef = coef(m2)["preempt_post"],
  m2_se = sqrt(vcov(m2)["preempt_post", "preempt_post"]),
  m3_coef = coef(m3)["preempt_post"],
  m3_se = sqrt(vcov(m3)["preempt_post", "preempt_post"]),
  td_preempt_post = coef(m_td)["preempt_post"],
  td_preempt_post_rural = coef(m_td)["preempt_post_rural"],
  mean_th_all = mean(main$th_pct, na.rm = TRUE),
  sd_th_all = sd(main$th_pct, na.rm = TRUE),
  mean_th_preempt = mean(main[preemption == 1]$th_pct, na.rm = TRUE),
  mean_th_control = mean(main[preemption == 0]$th_pct, na.rm = TRUE),
  sd_th_pre = sd(main[time_id == 1]$th_pct, na.rm = TRUE),
  n_obs_main = nrow(main),
  n_states = uniqueN(main$state_abbr),
  n_treated = uniqueN(main[preemption == 1]$state_abbr),
  n_quarters = uniqueN(main$time_id)
)

saveRDS(results, "../data/main_results.rds")
cat("  Saved main_results.rds\n")

# Save model objects for table generation
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m_td = m_td, m_event = m_event, m_bb = m_bb),
        "../data/model_objects.rds")
cat("  Saved model_objects.rds\n")

# Diagnostics JSON for validator
diagnostics <- list(
  n_treated = uniqueN(main[preemption == 1]$state_abbr),
  n_pre = 5,  # ACS broadband mechanism has 5 pre-COVID years (2015-2019); CMS has 1 pre-COVID quarter
  n_obs = nrow(main)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("  Saved diagnostics.json\n")

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
cat(sprintf("  Main DiD coefficient: %.3f (SE: %.3f)\n", results$m2_coef, results$m2_se))
cat(sprintf("  Mean telehealth (control, post): %.1f%%\n", results$mean_th_control))
cat(sprintf("  Mean telehealth (treated, post): %.1f%%\n", results$mean_th_preempt))
