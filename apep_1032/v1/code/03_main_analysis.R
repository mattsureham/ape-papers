## 03_main_analysis.R — Primary DiD estimation
## APEP-1032: The Deterrence Gap

source("00_packages.R")

analysis <- readRDS("../data/fdic_analysis.rds")
cat("Analysis sample:", nrow(analysis), "bank-quarters,",
    n_distinct(analysis$CERT), "banks\n")

# ═══════════════════════════════════════════════════════════════════════════════
# 1. MAIN DiD: Noncurrent Loan Ratio
# ═══════════════════════════════════════════════════════════════════════════════

# Static DiD
m1 <- feols(ncl_ratio ~ treat_post | CERT + time_q,
            data = analysis, cluster = ~CERT)

cat("\n=== Main DiD: Noncurrent Loan Ratio ===\n")
summary(m1)

# ═══════════════════════════════════════════════════════════════════════════════
# 2. EVENT STUDY
# ═══════════════════════════════════════════════════════════════════════════════

# Event study — omit event_time = -1 (2018Q2, last pre-treatment quarter)
m_es <- feols(ncl_ratio ~ i(event_time, treat, ref = -1) | CERT + time_q,
              data = analysis, cluster = ~CERT)

cat("\n=== Event Study: Noncurrent Loan Ratio ===\n")
summary(m_es)

# Save event study coefficients for table
es_coefs <- as.data.frame(coeftable(m_es))
es_coefs$event_time <- as.integer(gsub("event_time::", "", gsub(":treat", "", rownames(es_coefs))))
saveRDS(es_coefs, "../data/event_study_coefs.rds")

# ═══════════════════════════════════════════════════════════════════════════════
# 3. ADDITIONAL OUTCOMES
# ═══════════════════════════════════════════════════════════════════════════════

# Net charge-off ratio
m2 <- feols(nco_ratio ~ treat_post | CERT + time_q,
            data = analysis, cluster = ~CERT)

# Tier 1 capital ratio
m3 <- feols(tier1_ratio ~ treat_post | CERT + time_q,
            data = analysis, cluster = ~CERT)

# CRE loan share
m4 <- feols(cre_share ~ treat_post | CERT + time_q,
            data = analysis, cluster = ~CERT)

# C&I loan share
m5 <- feols(ci_share ~ treat_post | CERT + time_q,
            data = analysis, cluster = ~CERT)

# Log assets (growth)
m6 <- feols(log_asset ~ treat_post | CERT + time_q,
            data = analysis, cluster = ~CERT)

cat("\n=== All Outcomes Summary ===\n")
cat(sprintf("%-25s  Coef=%8.4f  SE=%8.4f  p=%6.4f\n",
            "Noncurrent loan ratio", coef(m1), se(m1), pvalue(m1)))
cat(sprintf("%-25s  Coef=%8.4f  SE=%8.4f  p=%6.4f\n",
            "Net charge-off ratio", coef(m2), se(m2), pvalue(m2)))
cat(sprintf("%-25s  Coef=%8.4f  SE=%8.4f  p=%6.4f\n",
            "Tier 1 capital ratio", coef(m3), se(m3), pvalue(m3)))
cat(sprintf("%-25s  Coef=%8.4f  SE=%8.4f  p=%6.4f\n",
            "CRE loan share", coef(m4), se(m4), pvalue(m4)))
cat(sprintf("%-25s  Coef=%8.4f  SE=%8.4f  p=%6.4f\n",
            "C&I loan share", coef(m5), se(m5), pvalue(m5)))
cat(sprintf("%-25s  Coef=%8.4f  SE=%8.4f  p=%6.4f\n",
            "Log assets", coef(m6), se(m6), pvalue(m6)))

# ═══════════════════════════════════════════════════════════════════════════════
# 4. SAVE MODELS AND DIAGNOSTICS
# ═══════════════════════════════════════════════════════════════════════════════

models <- list(
  ncl = m1, nco = m2, tier1 = m3,
  cre = m4, ci = m5, log_asset = m6,
  event_study = m_es
)
saveRDS(models, "../data/models_main.rds")

# Diagnostics for validator
n_treated <- analysis %>% filter(treat == 1) %>% distinct(CERT) %>% nrow()
n_pre <- analysis %>% filter(post == 0) %>% distinct(time_q) %>% nrow()
n_obs <- nrow(analysis)

diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated, n_pre, n_obs))

# Pre-trend test: joint F-test of pre-treatment event-study coefficients
pre_coefs <- es_coefs %>% filter(event_time < -1)
if (nrow(pre_coefs) > 0) {
  # Wald test for joint significance of pre-treatment coefficients
  pre_names <- rownames(es_coefs)[es_coefs$event_time < -1]
  wt <- wald(m_es, pre_names)
  cat(sprintf("\nPre-trend F-test: F=%.2f, p=%.4f\n", wt$stat, wt$p))
  diag$pretrend_F <- wt$stat
  diag$pretrend_p <- wt$p
  jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
}

# Pre-treatment SD of primary outcome (for SDE calculation)
pre_sd <- analysis %>%
  filter(post == 0) %>%
  summarise(sd_ncl = sd(ncl_ratio, na.rm = TRUE)) %>%
  pull(sd_ncl)

cat(sprintf("\nPre-treatment SD of noncurrent loan ratio: %.4f\n", pre_sd))
diag$sd_ncl_pre <- pre_sd
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n✓ Main analysis complete.\n")
