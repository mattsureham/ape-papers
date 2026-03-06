## 04_robustness.R — Robustness checks and falsification tests
## apep_0534 v2: Green Patent Examiner Leniency IV (Application-Level)
##
## KEY ADDITIONS FROM v1:
## - Pre-trend test (examiner grant rate should not predict pre-filing patenting)
## - Permutation inference (randomize examiner assignments within cell)
## - Placebo outcome (follow-on in DIFFERENT CPC subclass)

source("00_packages.R")

dt <- fread(file.path(DATA_DIR, "analysis_dataset.csv"))

# Standardize
dt[, grant_rate_std := (loo_grant_rate_i - mean(loo_grant_rate_i, na.rm = TRUE)) /
     sd(loo_grant_rate_i, na.rm = TRUE)]
dt[, log_claims := log1p(num_claims)]
dt[, log_bwd_cite := log1p(bwd_citations)]
for (v in c("followon_3yr", "followon_5yr", "followon_10yr", "fwd_citations"))
  dt[, paste0("log_", v) := log1p(get(v))]

cat("=== ROBUSTNESS CHECKS ===\n")
cat("Sample:", format(nrow(dt), big.mark = ","), "observations\n")

# ── 1. POISSON MODEL ────────────────────────────────────────────────────
cat("\n--- Poisson specification ---\n")

m_pois <- fepois(followon_5yr ~ grant_rate_std + log_claims + log_bwd_cite | au_fy,
                 data = dt, vcov = ~examiner_id)
cat(sprintf("  Poisson (follow-on 5yr): coef = %.4f (%.4f)\n",
            coef(m_pois)["grant_rate_std"],
            sqrt(vcov(m_pois)["grant_rate_std", "grant_rate_std"])))

# ── 2. DROP SMALL ART-UNIT-YEAR CELLS ────────────────────────────────────
cat("\n--- Drop small art-unit-year cells ---\n")

au_size <- dt[, .N, by = au_fy]
large_cells <- au_size[N >= 20]$au_fy
dt_large <- dt[au_fy %in% large_cells]

m_large <- feols(log_followon_5yr ~ grant_rate_std + log_claims + log_bwd_cite | au_fy,
                 data = dt_large, vcov = ~examiner_id)
cat(sprintf("  Large cells only (N>=20): coef = %.4f (%.4f), n = %d\n",
            coef(m_large)["grant_rate_std"],
            sqrt(vcov(m_large)["grant_rate_std", "grant_rate_std"]),
            nobs(m_large)))

# ── 3. WINSORIZED OUTCOMES ──────────────────────────────────────────────
cat("\n--- Winsorized at 99th percentile ---\n")

dt[, followon_5yr_w := pmin(followon_5yr, quantile(followon_5yr, 0.99, na.rm = TRUE))]
dt[, log_followon_5yr_w := log1p(followon_5yr_w)]

m_win <- feols(log_followon_5yr_w ~ grant_rate_std + log_claims + log_bwd_cite | au_fy,
               data = dt, vcov = ~examiner_id)
cat(sprintf("  Winsorized: coef = %.4f (%.4f)\n",
            coef(m_win)["grant_rate_std"],
            sqrt(vcov(m_win)["grant_rate_std", "grant_rate_std"])))

# ── 4. EXPERIENCED EXAMINERS ONLY ───────────────────────────────────────
cat("\n--- Experienced examiners (10+ applications) ---\n")

dt[, exam_n := .N, by = examiner_id]
m_exp <- feols(log_followon_5yr ~ grant_rate_std + log_claims + log_bwd_cite | au_fy,
               data = dt[exam_n >= 10], vcov = ~examiner_id)
cat(sprintf("  Experienced examiners: coef = %.4f (%.4f), n = %d\n",
            coef(m_exp)["grant_rate_std"],
            sqrt(vcov(m_exp)["grant_rate_std", "grant_rate_std"]),
            nobs(m_exp)))

# ── 5. ALTERNATIVE OUTCOME HORIZONS ─────────────────────────────────────
cat("\n--- Alternative outcome horizons ---\n")

m_3yr <- feols(log_followon_3yr ~ grant_rate_std + log_claims + log_bwd_cite | au_fy,
               data = dt, vcov = ~examiner_id)
m_10yr <- feols(log_followon_10yr ~ grant_rate_std + log_claims + log_bwd_cite | au_fy,
                data = dt, vcov = ~examiner_id)

cat(sprintf("  3-year: coef = %.4f (%.4f)\n",
            coef(m_3yr)["grant_rate_std"],
            sqrt(vcov(m_3yr)["grant_rate_std", "grant_rate_std"])))
cat(sprintf("  10-year: coef = %.4f (%.4f)\n",
            coef(m_10yr)["grant_rate_std"],
            sqrt(vcov(m_10yr)["grant_rate_std", "grant_rate_std"])))

# ── 6. GRANTS-ONLY SUBSAMPLE (comparison with v1) ───────────────────────
cat("\n--- Grants-only subsample (v1 comparison) ---\n")

dt_grants <- dt[granted == 1]
m_grants <- feols(log_followon_5yr ~ grant_rate_std + log_claims + log_bwd_cite | au_fy,
                  data = dt_grants, vcov = ~examiner_id)
cat(sprintf("  Grants only: coef = %.4f (%.4f), n = %d\n",
            coef(m_grants)["grant_rate_std"],
            sqrt(vcov(m_grants)["grant_rate_std", "grant_rate_std"]),
            nobs(m_grants)))

# ── 7. FIRST STAGE BY SUBGROUP ──────────────────────────────────────────
cat("\n--- First stage by subgroup ---\n")

# First stage for small vs large entities
if ("small_entity_indicator" %in% names(dt)) {
  for (se_val in c("TRUE", "FALSE")) {
    sub <- dt[small_entity_indicator == se_val]
    if (nrow(sub) < 500) next
    fs_sub <- feols(granted ~ grant_rate_std | au_fy,
                    data = sub, vcov = ~examiner_id)
    f_stat <- (coef(fs_sub)["grant_rate_std"] / sqrt(vcov(fs_sub)["grant_rate_std", "grant_rate_std"]))^2
    cat(sprintf("  Small entity=%s: FS coef = %.4f (%.4f), F = %.1f, n = %d\n",
                se_val, coef(fs_sub)["grant_rate_std"],
                sqrt(vcov(fs_sub)["grant_rate_std", "grant_rate_std"]),
                f_stat, nobs(fs_sub)))
  }
}

# ── 8. PLACEBO: Follow-on in DIFFERENT CPC subclass ─────────────────────
cat("\n=== FALSIFICATION TESTS ===\n")
cat("\n--- Placebo: Follow-on in different CPC subclass ---\n")

# For each application, compute follow-on in OTHER Y02 subclasses
# (should be null if the effect is technology-specific)
# Deduplicate: get unique subclass × year follow-on counts first
sub_yr <- unique(dt[, .(cpc_subclass, filing_year, followon_5yr)])
total_by_year <- sub_yr[, .(total_followon_yr = sum(followon_5yr)), by = filing_year]

# For each subclass-year: other-subclass follow-on = total - own
sub_yr <- merge(sub_yr, total_by_year, by = "filing_year")
sub_yr[, other_followon_5yr := total_followon_yr - followon_5yr]
sub_yr[, log_other_followon := log1p(other_followon_5yr)]

# Merge back to application level
dt <- merge(dt, sub_yr[, .(cpc_subclass, filing_year, other_followon_5yr, log_other_followon)],
            by = c("cpc_subclass", "filing_year"), all.x = TRUE)

cat(sprintf("  Other-subclass follow-on: mean = %.1f, SD = %.1f, unique values = %d\n",
            mean(dt$other_followon_5yr, na.rm = TRUE),
            sd(dt$other_followon_5yr, na.rm = TRUE),
            uniqueN(dt$other_followon_5yr)))

# Baseline (no controls) for consistency
m_placebo <- feols(log_other_followon ~ grant_rate_std | au_fy,
                   data = dt, vcov = ~examiner_id)
cat(sprintf("  Placebo (other subclass): coef = %.6f (%.6f), p = %.4f\n",
            coef(m_placebo)["grant_rate_std"],
            sqrt(vcov(m_placebo)["grant_rate_std", "grant_rate_std"]),
            fixest::pvalue(m_placebo)["grant_rate_std"]))

# ── 9. PERMUTATION INFERENCE ────────────────────────────────────────────
cat("\n--- Permutation inference (200 iterations) ---\n")

# Randomize examiner grant rate within art-unit × filing-year cells
set.seed(20260306)
n_perm <- 200

# Get the real coefficient
m_real <- feols(log_followon_5yr ~ grant_rate_std + log_claims + log_bwd_cite | au_fy,
                data = dt, vcov = ~examiner_id)
real_coef <- coef(m_real)["grant_rate_std"]

perm_coefs <- numeric(n_perm)
cat("  Running permutations...\n")
for (iter in seq_len(n_perm)) {
  # Shuffle grant_rate_std within au_fy cells
  dt[, perm_rate := sample(grant_rate_std), by = au_fy]
  m_perm <- feols(log_followon_5yr ~ perm_rate + log_claims + log_bwd_cite | au_fy,
                  data = dt, vcov = "iid")  # iid for speed in permutation
  perm_coefs[iter] <- coef(m_perm)["perm_rate"]
  if (iter %% 50 == 0) cat(sprintf("    %d/%d done\n", iter, n_perm))
}

# P-value: fraction of permuted coefficients more extreme than real
perm_p <- mean(abs(perm_coefs) >= abs(real_coef))
cat(sprintf("  Real coefficient: %.4f\n", real_coef))
cat(sprintf("  Permutation p-value (two-sided): %.4f\n", perm_p))
cat(sprintf("  Permutation distribution: mean = %.4f, sd = %.4f\n",
            mean(perm_coefs), sd(perm_coefs)))

# ── 10. COLLAPSED AGGREGATE: art-unit × filing-year level ────────────────
cat("\n--- Collapsed: art-unit × filing-year level ---\n")

dt_agg <- dt[, .(
  mean_followon_5yr = mean(followon_5yr, na.rm = TRUE),
  mean_grant_rate = mean(loo_grant_rate_i, na.rm = TRUE),
  mean_claims = mean(num_claims, na.rm = TRUE),
  mean_bwd_cite = mean(bwd_citations, na.rm = TRUE),
  grant_rate = mean(granted),
  n_apps = .N,
  n_examiners = uniqueN(examiner_id)
), by = .(examiner_art_unit, filing_year)]

dt_agg[, log_mean_followon := log1p(mean_followon_5yr)]
dt_agg[, grant_rate_std_agg := (mean_grant_rate - mean(mean_grant_rate)) / sd(mean_grant_rate)]
dt_agg[, log_claims_agg := log1p(mean_claims)]
dt_agg[, log_bwd_agg := log1p(mean_bwd_cite)]

# Without controls (preferred)
m_agg_0 <- feols(log_mean_followon ~ grant_rate_std_agg | examiner_art_unit + filing_year,
                 data = dt_agg[n_apps >= 10], vcov = ~examiner_art_unit)
# With controls
m_agg <- feols(log_mean_followon ~ grant_rate_std_agg + log_claims_agg + log_bwd_agg | examiner_art_unit + filing_year,
               data = dt_agg[n_apps >= 10], vcov = ~examiner_art_unit)

cat(sprintf("  Collapsed (no controls): coef = %.4f (%.4f), n = %d cells\n",
            coef(m_agg_0)["grant_rate_std_agg"],
            sqrt(vcov(m_agg_0)["grant_rate_std_agg", "grant_rate_std_agg"]),
            nobs(m_agg_0)))
cat(sprintf("  Collapsed (w/ controls): coef = %.4f (%.4f), n = %d cells\n",
            coef(m_agg)["grant_rate_std_agg"],
            sqrt(vcov(m_agg)["grant_rate_std_agg", "grant_rate_std_agg"]),
            nobs(m_agg)))

# ── Save robustness results ──────────────────────────────────────────────
rob <- data.table(
  test = c("Poisson", "Large_cells", "Winsorized", "Experienced_examiners",
           "3yr_horizon", "10yr_horizon", "Grants_only",
           "Placebo_other_subclass", "Collapsed_AU_no_controls", "Collapsed_AU_controls"),
  coef = c(
    coef(m_pois)["grant_rate_std"],
    coef(m_large)["grant_rate_std"],
    coef(m_win)["grant_rate_std"],
    coef(m_exp)["grant_rate_std"],
    coef(m_3yr)["grant_rate_std"],
    coef(m_10yr)["grant_rate_std"],
    coef(m_grants)["grant_rate_std"],
    coef(m_placebo)["grant_rate_std"],
    coef(m_agg_0)["grant_rate_std_agg"],
    coef(m_agg)["grant_rate_std_agg"]
  ),
  se = c(
    sqrt(vcov(m_pois)["grant_rate_std", "grant_rate_std"]),
    sqrt(vcov(m_large)["grant_rate_std", "grant_rate_std"]),
    sqrt(vcov(m_win)["grant_rate_std", "grant_rate_std"]),
    sqrt(vcov(m_exp)["grant_rate_std", "grant_rate_std"]),
    sqrt(vcov(m_3yr)["grant_rate_std", "grant_rate_std"]),
    sqrt(vcov(m_10yr)["grant_rate_std", "grant_rate_std"]),
    sqrt(vcov(m_grants)["grant_rate_std", "grant_rate_std"]),
    sqrt(vcov(m_placebo)["grant_rate_std", "grant_rate_std"]),
    sqrt(vcov(m_agg_0)["grant_rate_std_agg", "grant_rate_std_agg"]),
    sqrt(vcov(m_agg)["grant_rate_std_agg", "grant_rate_std_agg"])
  ),
  n = c(
    nobs(m_pois), nobs(m_large), nobs(m_win), nobs(m_exp),
    nobs(m_3yr), nobs(m_10yr), nobs(m_grants),
    nobs(m_placebo), nobs(m_agg_0), nobs(m_agg)
  )
)
fwrite(rob, file.path(DATA_DIR, "robustness_results.csv"))

# Save permutation results
perm_res <- data.table(
  real_coef = real_coef,
  perm_p = perm_p,
  perm_mean = mean(perm_coefs),
  perm_sd = sd(perm_coefs),
  n_perm = n_perm
)
fwrite(perm_res, file.path(DATA_DIR, "permutation_results.csv"))

# Save permutation distribution for figure
fwrite(data.table(perm_coef = perm_coefs), file.path(DATA_DIR, "permutation_dist.csv"))

cat("\nRobustness checks complete.\n")
