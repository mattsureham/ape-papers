## 03_main_analysis.R — Examiner leniency IV regressions
## apep_0534: Green Patent Examiner Leniency IV

source("00_packages.R")

dt <- fread(file.path(DATA_DIR, "analysis_dataset.csv"))
cat("Loaded analysis dataset:", format(nrow(dt), big.mark = ","), "observations\n")

# ── Standardize leniency for interpretability ───────────────────────────
dt[, leniency_std := (loo_leniency - mean(loo_leniency, na.rm = TRUE)) /
     sd(loo_leniency, na.rm = TRUE)]

# ── 1. BALANCE TEST ─────────────────────────────────────────────────────
# Examiner leniency should not predict application characteristics
# conditional on art-unit × filing-year FE
cat("\n=== BALANCE TESTS ===\n")

# Log-transform skewed variables
dt[, log_claims := log1p(num_claims)]
dt[, log_bwd_cite := log1p(bwd_citations)]

balance_vars <- c("log_claims", "log_bwd_cite")

balance_results <- list()
for (v in balance_vars) {
  if (v %in% names(dt) && sum(!is.na(dt[[v]])) > 100) {
    m <- feols(as.formula(paste(v, "~ leniency_std | au_fy")),
               data = dt, vcov = ~examiner_id)
    cat(sprintf("  %s ~ leniency: coef = %.4f, se = %.4f, p = %.4f\n",
                v, coef(m)["leniency_std"],
                sqrt(vcov(m)["leniency_std", "leniency_std"]),
                fixest::pvalue(m)["leniency_std"]))
    balance_results[[v]] <- m
  }
}

# Joint F-test
if (length(balance_vars) >= 2) {
  joint <- feols(leniency_std ~ log_claims + log_bwd_cite | au_fy,
                 data = dt, vcov = ~examiner_id)
  cat(sprintf("  Joint F-test (balance): F = %.2f, p = %.4f\n",
              fitstat(joint, "f")$f$stat, fitstat(joint, "f")$f$p))
}

fwrite(data.table(
  variable = names(balance_results),
  coef = sapply(balance_results, function(m) coef(m)["leniency_std"]),
  se = sapply(balance_results, function(m) sqrt(vcov(m)["leniency_std", "leniency_std"])),
  p = sapply(balance_results, function(m) fixest::pvalue(m)["leniency_std"])
), file.path(DATA_DIR, "balance_test.csv"))

# ── 2. REDUCED FORM: Examiner Leniency → Follow-on Innovation ──────────
cat("\n=== REDUCED FORM REGRESSIONS ===\n")

# Main specification: Follow-on Y02 patents ~ Examiner leniency | FE
outcomes <- c("followon_3yr", "followon_5yr", "followon_10yr",
              "fwd_citations", "n_citing_states")
outcomes <- outcomes[outcomes %in% names(dt)]

# Log-transform count outcomes for semi-elasticity
for (v in outcomes) dt[, paste0("log_", v) := log1p(get(v))]

rf_results <- list()
for (v in outcomes) {
  logv <- paste0("log_", v)
  if (sum(!is.na(dt[[logv]])) < 100) next

  # Baseline: no controls
  m0 <- feols(as.formula(paste(logv, "~ leniency_std | au_fy")),
              data = dt, vcov = ~examiner_id)

  # With application controls
  m1 <- feols(as.formula(paste(logv, "~ leniency_std + log_claims + log_bwd_cite | au_fy")),
              data = dt, vcov = ~examiner_id)

  # With domain × year FE
  m2 <- feols(as.formula(paste(logv, "~ leniency_std + log_claims + log_bwd_cite | au_fy + y02_domain^filing_year")),
              data = dt, vcov = ~examiner_id)

  rf_results[[v]] <- list(baseline = m0, controlled = m1, saturated = m2)

  cat(sprintf("\n  %s:\n", v))
  cat(sprintf("    Baseline:    coef = %.4f (%.4f), p = %.4f\n",
              coef(m0)["leniency_std"],
              sqrt(vcov(m0)["leniency_std", "leniency_std"]),
              fixest::pvalue(m0)["leniency_std"]))
  cat(sprintf("    Controlled:  coef = %.4f (%.4f), p = %.4f\n",
              coef(m1)["leniency_std"],
              sqrt(vcov(m1)["leniency_std", "leniency_std"]),
              fixest::pvalue(m1)["leniency_std"]))
  cat(sprintf("    Saturated:   coef = %.4f (%.4f), p = %.4f\n",
              coef(m2)["leniency_std"],
              sqrt(vcov(m2)["leniency_std", "leniency_std"]),
              fixest::pvalue(m2)["leniency_std"]))
}

# ── 3. HETEROGENEITY BY Y02 DOMAIN ─────────────────────────────────────
cat("\n=== HETEROGENEITY BY TECHNOLOGY DOMAIN ===\n")

hetero_results <- list()
for (dom in unique(dt$y02_domain)) {
  sub <- dt[y02_domain == dom]
  if (nrow(sub) < 200) next

  m <- feols(log_followon_5yr ~ leniency_std + log_claims + log_bwd_cite | au_fy,
             data = sub, vcov = ~examiner_id)
  hetero_results[[dom]] <- m
  cat(sprintf("  %s (n=%s): coef = %.4f (%.4f)\n",
              dom, format(nrow(sub), big.mark = ","),
              coef(m)["leniency_std"],
              sqrt(vcov(m)["leniency_std", "leniency_std"])))
}

# ── 4. HETEROGENEITY BY APPLICANT TYPE ──────────────────────────────────
cat("\n=== HETEROGENEITY BY APPLICANT TYPE ===\n")

if ("assignee_type" %in% names(dt) && sum(!is.na(dt$assignee_type)) > 500) {
  for (atype in unique(na.omit(dt$assignee_type))) {
    sub <- dt[assignee_type == atype]
    if (nrow(sub) < 200) next

    m <- feols(log_followon_5yr ~ leniency_std + log_claims + log_bwd_cite | au_fy,
               data = sub, vcov = ~examiner_id)
    cat(sprintf("  Type %s (n=%s): coef = %.4f (%.4f)\n",
                atype, format(nrow(sub), big.mark = ","),
                coef(m)["leniency_std"],
                sqrt(vcov(m)["leniency_std", "leniency_std"])))
  }
}

# ── 5. TEMPORAL HETEROGENEITY ───────────────────────────────────────────
cat("\n=== TEMPORAL HETEROGENEITY ===\n")

dt[, era := fcase(
  filing_year <= 2005, "2001-2005",
  filing_year <= 2010, "2006-2010",
  filing_year <= 2015, "2011-2015",
  default = "2016-2018"
)]

era_results <- list()
for (e in unique(dt$era)) {
  sub <- dt[era == e]
  if (nrow(sub) < 200) next

  m <- feols(log_followon_5yr ~ leniency_std + log_claims + log_bwd_cite | au_fy,
             data = sub, vcov = ~examiner_id)
  era_results[[e]] <- m
  cat(sprintf("  %s (n=%s): coef = %.4f (%.4f)\n",
              e, format(nrow(sub), big.mark = ","),
              coef(m)["leniency_std"],
              sqrt(vcov(m)["leniency_std", "leniency_std"])))
}

# ── 6. PATENT SCOPE IV (intensive margin) ──────────────────────────────
cat("\n=== PATENT SCOPE IV: Leniency → Claims → Follow-on ===\n")

# First stage: Leniency → Number of claims
fs <- feols(log_claims ~ leniency_std | au_fy,
            data = dt, vcov = ~examiner_id)
fs_f <- (coef(fs)["leniency_std"] / sqrt(vcov(fs)["leniency_std", "leniency_std"]))^2
cat(sprintf("  First stage (claims): coef = %.4f (%.4f), F = %.1f\n",
            coef(fs)["leniency_std"],
            sqrt(vcov(fs)["leniency_std", "leniency_std"]),
            fs_f))

# IV: Claims → Follow-on (instrumented by leniency)
if (sum(!is.na(dt$log_followon_5yr)) > 100) {
  iv <- feols(log_followon_5yr ~ log_bwd_cite | au_fy | log_claims ~ leniency_std,
              data = dt, vcov = ~examiner_id)
  cat(sprintf("  IV (claims → follow-on): coef = %.4f (%.4f)\n",
              coef(iv)["fit_log_claims"],
              sqrt(vcov(iv)["fit_log_claims", "fit_log_claims"])))
}

# ── Save all results ────────────────────────────────────────────────────
cat("\n=== Saving results ===\n")

# Main results table
main_res <- data.table(
  outcome = character(),
  spec = character(),
  coef = numeric(),
  se = numeric(),
  p = numeric(),
  n = integer()
)

for (v in names(rf_results)) {
  for (s in names(rf_results[[v]])) {
    m <- rf_results[[v]][[s]]
    main_res <- rbind(main_res, data.table(
      outcome = v, spec = s,
      coef = coef(m)["leniency_std"],
      se = sqrt(vcov(m)["leniency_std", "leniency_std"]),
      p = fixest::pvalue(m)["leniency_std"],
      n = nobs(m)
    ))
  }
}
fwrite(main_res, file.path(DATA_DIR, "main_results.csv"))

# Heterogeneity results
hetero_res <- data.table(
  domain = names(hetero_results),
  coef = sapply(hetero_results, function(m) coef(m)["leniency_std"]),
  se = sapply(hetero_results, function(m) sqrt(vcov(m)["leniency_std", "leniency_std"])),
  n = sapply(hetero_results, nobs)
)
fwrite(hetero_res, file.path(DATA_DIR, "heterogeneity_domain.csv"))

# Era results
era_res <- data.table(
  era = names(era_results),
  coef = sapply(era_results, function(m) coef(m)["leniency_std"]),
  se = sapply(era_results, function(m) sqrt(vcov(m)["leniency_std", "leniency_std"])),
  n = sapply(era_results, nobs)
)
fwrite(era_res, file.path(DATA_DIR, "heterogeneity_era.csv"))

cat("\nMain analysis complete.\n")
