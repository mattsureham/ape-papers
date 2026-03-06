## 04_robustness.R — Robustness checks
## apep_0534: Green Patent Examiner Leniency IV

source("00_packages.R")

dt <- fread(file.path(DATA_DIR, "analysis_dataset.csv"))

# Standardize
dt[, leniency_std := (loo_leniency - mean(loo_leniency, na.rm = TRUE)) /
     sd(loo_leniency, na.rm = TRUE)]
dt[, log_claims := log1p(num_claims)]
dt[, log_bwd_cite := log1p(bwd_citations)]
for (v in c("followon_3yr", "followon_5yr", "followon_10yr", "fwd_citations"))
  dt[, paste0("log_", v) := log1p(get(v))]

cat("=== ROBUSTNESS CHECKS ===\n")

# ── 1. POISSON MODEL (counts, not logs) ────────────────────────────────
cat("\n--- Poisson specification ---\n")

m_pois <- fepois(followon_5yr ~ leniency_std + log_claims + log_bwd_cite | au_fy,
                 data = dt, vcov = ~examiner_id)
cat(sprintf("  Poisson (follow-on 5yr): coef = %.4f (%.4f)\n",
            coef(m_pois)["leniency_std"],
            sqrt(vcov(m_pois)["leniency_std", "leniency_std"])))

# ── 2. DROP SINGLETON ART UNITS ─────────────────────────────────────────
cat("\n--- Drop small art-unit-year cells ---\n")

au_size <- dt[, .N, by = au_fy]
large_cells <- au_size[N >= 20]$au_fy
dt_large <- dt[au_fy %in% large_cells]

m_large <- feols(log_followon_5yr ~ leniency_std + log_claims + log_bwd_cite | au_fy,
                 data = dt_large, vcov = ~examiner_id)
cat(sprintf("  Large cells only (N>=20): coef = %.4f (%.4f), n = %d\n",
            coef(m_large)["leniency_std"],
            sqrt(vcov(m_large)["leniency_std", "leniency_std"]),
            nobs(m_large)))

# ── 3. EXAMINER-LEVEL CLUSTERING ───────────────────────────────────────
cat("\n--- Different clustering levels ---\n")

m_exam <- feols(log_followon_5yr ~ leniency_std + log_claims + log_bwd_cite | au_fy,
                data = dt, vcov = ~examiner_id)
m_au <- feols(log_followon_5yr ~ leniency_std + log_claims + log_bwd_cite | au_fy,
              data = dt, vcov = ~art_unit)
m_aufy <- feols(log_followon_5yr ~ leniency_std + log_claims + log_bwd_cite | au_fy,
                data = dt, vcov = ~au_fy)

se_exam <- sqrt(vcov(m_exam)["leniency_std", "leniency_std"])
se_au   <- sqrt(vcov(m_au)["leniency_std", "leniency_std"])
se_aufy <- sqrt(vcov(m_aufy)["leniency_std", "leniency_std"])

cat(sprintf("  Cluster examiner: se = %.4f\n", se_exam))
cat(sprintf("  Cluster art unit: se = %.4f\n", se_au))
cat(sprintf("  Cluster AU x year: se = %.4f\n", se_aufy))

# ── 4. MONOTONICITY TEST ───────────────────────────────────────────────
cat("\n--- Monotonicity: examiner leniency quintiles ---\n")

dt[, leniency_quintile := cut(loo_leniency,
                               breaks = quantile(loo_leniency, probs = seq(0, 1, 0.2), na.rm = TRUE),
                               labels = paste0("Q", 1:5), include.lowest = TRUE)]

mono <- dt[, .(mean_followon = mean(followon_5yr, na.rm = TRUE),
               mean_claims = mean(num_claims, na.rm = TRUE),
               mean_fwd_cite = mean(fwd_citations, na.rm = TRUE),
               n = .N),
           by = leniency_quintile][order(leniency_quintile)]
cat("Leniency quintile -> mean follow-on (5yr):\n")
print(mono)

fwrite(mono, file.path(DATA_DIR, "monotonicity.csv"))

# ── 5. WINSORIZED OUTCOMES ──────────────────────────────────────────────
cat("\n--- Winsorized at 99th percentile ---\n")

dt[, followon_5yr_w := pmin(followon_5yr, quantile(followon_5yr, 0.99, na.rm = TRUE))]
dt[, log_followon_5yr_w := log1p(followon_5yr_w)]

m_win <- feols(log_followon_5yr_w ~ leniency_std + log_claims + log_bwd_cite | au_fy,
               data = dt, vcov = ~examiner_id)
cat(sprintf("  Winsorized: coef = %.4f (%.4f)\n",
            coef(m_win)["leniency_std"],
            sqrt(vcov(m_win)["leniency_std", "leniency_std"])))

# ── 6. PLACEBO: Forward citations as outcome ────────────────────────────
cat("\n--- Placebo: Non-Y02 forward citations ---\n")
# If leniency predicts general citations similarly, it's not green-specific
m_fwd <- feols(log_fwd_citations ~ leniency_std + log_claims + log_bwd_cite | au_fy,
               data = dt, vcov = ~examiner_id)
cat(sprintf("  Forward citations: coef = %.4f (%.4f)\n",
            coef(m_fwd)["leniency_std"],
            sqrt(vcov(m_fwd)["leniency_std", "leniency_std"])))

# ── 7. RESTRICT TO EXAMINERS WITH 10+ PATENTS ──────────────────────────
cat("\n--- Restrict to experienced examiners (10+ patents) ---\n")

dt[, exam_n := .N, by = examiner_id]
m_exp <- feols(log_followon_5yr ~ leniency_std + log_claims + log_bwd_cite | au_fy,
               data = dt[exam_n >= 10], vcov = ~examiner_id)
cat(sprintf("  Experienced examiners: coef = %.4f (%.4f), n = %d\n",
            coef(m_exp)["leniency_std"],
            sqrt(vcov(m_exp)["leniency_std", "leniency_std"]),
            nobs(m_exp)))

# ── 8. ALTERNATIVE OUTCOME: 3-YEAR AND 10-YEAR ─────────────────────────
cat("\n--- Alternative outcome horizons ---\n")

m_3yr <- feols(log_followon_3yr ~ leniency_std + log_claims + log_bwd_cite | au_fy,
               data = dt, vcov = ~examiner_id)
m_10yr <- feols(log_followon_10yr ~ leniency_std + log_claims + log_bwd_cite | au_fy,
                data = dt, vcov = ~examiner_id)

cat(sprintf("  3-year: coef = %.4f (%.4f)\n",
            coef(m_3yr)["leniency_std"],
            sqrt(vcov(m_3yr)["leniency_std", "leniency_std"])))
cat(sprintf("  10-year: coef = %.4f (%.4f)\n",
            coef(m_10yr)["leniency_std"],
            sqrt(vcov(m_10yr)["leniency_std", "leniency_std"])))

# ── Save robustness results ────────────────────────────────────────────
rob <- data.table(
  test = c("Poisson", "Large_cells", "Cluster_AU", "Winsorized",
           "Experienced_examiners", "3yr_horizon", "10yr_horizon"),
  coef = c(
    coef(m_pois)["leniency_std"],
    coef(m_large)["leniency_std"],
    coef(m_au)["leniency_std"],
    coef(m_win)["leniency_std"],
    coef(m_exp)["leniency_std"],
    coef(m_3yr)["leniency_std"],
    coef(m_10yr)["leniency_std"]
  ),
  se = c(
    sqrt(vcov(m_pois)["leniency_std", "leniency_std"]),
    sqrt(vcov(m_large)["leniency_std", "leniency_std"]),
    sqrt(vcov(m_au)["leniency_std", "leniency_std"]),
    sqrt(vcov(m_win)["leniency_std", "leniency_std"]),
    sqrt(vcov(m_exp)["leniency_std", "leniency_std"]),
    sqrt(vcov(m_3yr)["leniency_std", "leniency_std"]),
    sqrt(vcov(m_10yr)["leniency_std", "leniency_std"])
  )
)
fwrite(rob, file.path(DATA_DIR, "robustness_results.csv"))

cat("\nRobustness checks complete.\n")
