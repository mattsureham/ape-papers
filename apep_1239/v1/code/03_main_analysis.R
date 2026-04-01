# 03_main_analysis.R — apep_1239: Swiss NFA Reform
# Main DiD estimation: NFA transfer intensity and inter-cantonal migration

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE)

panel <- readRDS(paste0(data_dir, "analysis_panel.rds"))

cat("=== MAIN ANALYSIS: NFA and Inter-Cantonal Migration ===\n\n")

# ============================================================
# MODEL 1: Baseline continuous-treatment DiD
# Y_ct = a_c + g_t + beta * (TransferIntensity_c * Post_t) + e_ct
# ============================================================

cat("--- Model 1: Baseline DiD (continuous treatment) ---\n")
m1 <- feols(
  net_migration_rate ~ treat_cont | canton_f + year_f,
  data = panel,
  cluster = ~canton_f
)
summary(m1)

cat("\n--- Model 2: With canton-specific linear trends ---\n")
m2 <- feols(
  net_migration_rate ~ treat_cont | canton_f + year_f + canton_f[year],
  data = panel,
  cluster = ~canton_f
)
summary(m2)

# ============================================================
# MODEL 3: In-migration rate (decomposition)
# ============================================================

cat("\n--- Model 3: In-migration rate ---\n")
m3 <- feols(
  in_migration_rate ~ treat_cont | canton_f + year_f,
  data = panel,
  cluster = ~canton_f
)
summary(m3)

# ============================================================
# MODEL 4: Log population (stock rather than flow)
# ============================================================

cat("\n--- Model 4: Log population ---\n")
m4 <- feols(
  log_pop ~ treat_cont | canton_f + year_f,
  data = panel,
  cluster = ~canton_f
)
summary(m4)

# ============================================================
# MODEL 5: Binary treatment (recipient vs payer)
# ============================================================

cat("\n--- Model 5: Binary treatment (recipient dummy) ---\n")
m5 <- feols(
  net_migration_rate ~ i(post, is_recipient, ref = 0) | canton_f + year_f,
  data = panel,
  cluster = ~canton_f
)
summary(m5)

# ============================================================
# EVENT STUDY: Year-by-year coefficients
# ============================================================

cat("\n--- Event Study: Continuous treatment intensity ---\n")
es1 <- feols(
  net_migration_rate ~ i(event_time, transfer_intensity, ref = -1) | canton_f + year_f,
  data = panel,
  cluster = ~canton_f
)
summary(es1)

# Check pre-trends: joint test of pre-period coefficients
pre_coefs <- coef(es1)[grepl("event_time::-[2-9]|event_time::-[1-9][0-9]", names(coef(es1)))]
cat(sprintf("\nPre-trend coefficients (should be ~0):\n"))
print(pre_coefs)

# F-test for joint significance of pre-period
pre_test <- wald(es1, "event_time::-")
cat(sprintf("\nJoint pre-trend test: F=%.2f, p=%.4f\n", pre_test$stat, pre_test$p))

# ============================================================
# EVENT STUDY: Binary treatment
# ============================================================

cat("\n--- Event Study: Binary treatment (recipient vs others) ---\n")
es2 <- feols(
  net_migration_rate ~ i(event_time, is_recipient, ref = -1) | canton_f + year_f,
  data = panel,
  cluster = ~canton_f
)
summary(es2)

# ============================================================
# DIAGNOSTICS: Write to JSON
# ============================================================

# In continuous-treatment DiD, all units receive some treatment intensity
# n_treated = all cantons with non-zero transfer intensity (26/26)
diagnostics <- list(
  n_treated = n_distinct(panel$canton_code),
  n_pre = length(unique(panel$year[panel$year < 2008])),
  n_obs = nrow(panel),
  n_cantons = n_distinct(panel$canton_code),
  n_years = n_distinct(panel$year),
  n_recipients = sum(panel$nfa_status == "recipient") / n_distinct(panel$year),
  n_payers = sum(panel$nfa_status == "payer") / n_distinct(panel$year),
  pre_trend_f = pre_test$stat,
  pre_trend_p = pre_test$p,
  main_coef = coef(m1)["treat_cont"],
  main_se = se(m1)["treat_cont"],
  main_pval = pvalue(m1)["treat_cont"]
)

jsonlite::write_json(diagnostics, paste0(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat(sprintf("\nDiagnostics saved: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

# Save models for later use
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
             es1 = es1, es2 = es2),
        paste0(data_dir, "models.rds"))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
