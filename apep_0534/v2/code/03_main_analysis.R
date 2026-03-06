## 03_main_analysis.R — First stage, reduced form, and IV regressions
## apep_0534 v2: Green Patent Examiner Leniency IV (Application-Level)
##
## KEY CHANGES FROM v1:
## - Proper first stage: examiner grant rate → application granted
## - Application-level sample (grants + abandonments)
## - Citations promoted to main analysis
## - Multiple clustering approaches

source("00_packages.R")

dt <- fread(file.path(DATA_DIR, "analysis_dataset.csv"))
cat("Loaded analysis dataset:", format(nrow(dt), big.mark = ","), "observations\n")
cat("  Granted:", format(sum(dt$granted), big.mark = ","), "\n")
cat("  Abandoned:", format(sum(1 - dt$granted), big.mark = ","), "\n")

# ── Standardize instrument for interpretability ──────────────────────────
dt[, grant_rate_std := (loo_grant_rate_i - mean(loo_grant_rate_i, na.rm = TRUE)) /
     sd(loo_grant_rate_i, na.rm = TRUE)]

# Log-transform count outcomes
dt[, log_claims := log1p(num_claims)]
dt[, log_bwd_cite := log1p(bwd_citations)]
for (v in c("followon_3yr", "followon_5yr", "followon_10yr", "fwd_citations"))
  dt[, paste0("log_", v) := log1p(get(v))]

# ── 1. BALANCE TESTS ────────────────────────────────────────────────────
cat("\n=== BALANCE TESTS ===\n")

# ── 1A. FULL-SAMPLE balance: pre-treatment covariates observable for ALL applications
cat("--- Full-sample balance (pre-treatment covariates) ---\n")

# small_entity_indicator is observable for ALL applications from PatEx
# NOTE: small_entity has zero within-cell variation (absorbed by AU×FY FE)
# So we test cross-sectionally without FE, and note the limitation
dt[, small_entity := as.numeric(small_entity_indicator == "1" | small_entity_indicator == "TRUE")]

# Cross-sectional balance: examiner grant rate should not predict small entity status
# (within AU × filing year, this is a constant — so this is a cross-cell test)
fullsample_balance <- list()
m_se <- tryCatch(
  feols(small_entity ~ grant_rate_std | filing_year, data = dt, vcov = ~examiner_id),
  error = function(e) NULL
)
if (!is.null(m_se)) {
  cat(sprintf("  small_entity ~ grant_rate (filing-year FE): coef = %.4f, se = %.4f, p = %.4f\n",
              coef(m_se)["grant_rate_std"],
              sqrt(vcov(m_se)["grant_rate_std", "grant_rate_std"]),
              fixest::pvalue(m_se)["grant_rate_std"]))
  fullsample_balance[["small_entity"]] <- m_se
}

# Also test: does examiner grant rate predict CPC subclass assignment?
# Number of unique subclasses per AU×FY as a measure of sorting
dt[, n_subclass_in_cell := uniqueN(cpc_subclass), by = au_fy]
cat(sprintf("  Mean unique CPC subclasses per AU×FY cell: %.1f\n",
            mean(dt$n_subclass_in_cell)))

# ── 1B. Grants-only balance: claims and citations (post-treatment for abandonments)
cat("\n--- Grants-only balance (claims, citations) ---\n")

dt_granted <- dt[granted == 1]
dt_granted[, grant_rate_std_g := (loo_grant_rate_i - mean(loo_grant_rate_i, na.rm = TRUE)) /
             sd(loo_grant_rate_i, na.rm = TRUE)]

balance_vars <- c("log_claims", "log_bwd_cite")
balance_vars <- balance_vars[balance_vars %in% names(dt_granted)]

grantsonly_balance <- list()
for (v in balance_vars) {
  if (sum(!is.na(dt_granted[[v]])) > 100) {
    m <- feols(as.formula(paste(v, "~ grant_rate_std_g | au_fy")),
               data = dt_granted, vcov = ~examiner_id)
    cat(sprintf("  %s ~ grant_rate (grants only): coef = %.4f, se = %.4f, p = %.4f\n",
                v, coef(m)["grant_rate_std_g"],
                sqrt(vcov(m)["grant_rate_std_g", "grant_rate_std_g"]),
                fixest::pvalue(m)["grant_rate_std_g"]))
    grantsonly_balance[[v]] <- m
  }
}

# Save both sets
all_balance <- data.table()
for (v in names(fullsample_balance)) {
  m <- fullsample_balance[[v]]
  all_balance <- rbind(all_balance, data.table(
    variable = v, sample = "full",
    coef = coef(m)["grant_rate_std"],
    se = sqrt(vcov(m)["grant_rate_std", "grant_rate_std"]),
    p = fixest::pvalue(m)["grant_rate_std"],
    n = nobs(m)
  ))
}
for (v in names(grantsonly_balance)) {
  m <- grantsonly_balance[[v]]
  all_balance <- rbind(all_balance, data.table(
    variable = v, sample = "grants_only",
    coef = coef(m)["grant_rate_std_g"],
    se = sqrt(vcov(m)["grant_rate_std_g", "grant_rate_std_g"]),
    p = fixest::pvalue(m)["grant_rate_std_g"],
    n = nobs(m)
  ))
}
fwrite(all_balance, file.path(DATA_DIR, "balance_test.csv"))
rm(dt_granted)

# ── 2. FIRST STAGE: Examiner Grant Rate → Application Granted ───────────
cat("\n=== FIRST STAGE ===\n")
cat("Z = examiner LOO grant rate → D = application granted\n\n")

# (1) Baseline: just instrument + FE
fs0 <- feols(granted ~ grant_rate_std | au_fy,
             data = dt, vcov = ~examiner_id)

# (2) With controls
fs1 <- feols(granted ~ grant_rate_std + log_claims + log_bwd_cite | au_fy,
             data = dt, vcov = ~examiner_id)

# (3) Saturated: domain × year FE
fs2 <- feols(granted ~ grant_rate_std + log_claims + log_bwd_cite | au_fy + y02_domain^filing_year,
             data = dt, vcov = ~examiner_id)

for (m_name in c("fs0", "fs1", "fs2")) {
  m <- get(m_name)
  f_stat <- (coef(m)["grant_rate_std"] / sqrt(vcov(m)["grant_rate_std", "grant_rate_std"]))^2
  cat(sprintf("  %s: coef = %.4f (%.4f), F = %.1f, n = %s\n",
              m_name, coef(m)["grant_rate_std"],
              sqrt(vcov(m)["grant_rate_std", "grant_rate_std"]),
              f_stat, format(nobs(m), big.mark = ",")))
}

# ── 3. REDUCED FORM: Examiner Grant Rate → Follow-on Innovation ─────────
cat("\n=== REDUCED FORM REGRESSIONS ===\n")

outcomes <- c("followon_3yr", "followon_5yr", "followon_10yr",
              "fwd_citations")
outcomes <- outcomes[outcomes %in% names(dt)]

rf_results <- list()
for (v in outcomes) {
  logv <- paste0("log_", v)
  if (sum(!is.na(dt[[logv]])) < 100) next

  # Baseline
  m0 <- feols(as.formula(paste(logv, "~ grant_rate_std | au_fy")),
              data = dt, vcov = ~examiner_id)
  # With controls
  m1 <- feols(as.formula(paste(logv, "~ grant_rate_std + log_claims + log_bwd_cite | au_fy")),
              data = dt, vcov = ~examiner_id)
  # Saturated
  m2 <- feols(as.formula(paste(logv, "~ grant_rate_std + log_claims + log_bwd_cite | au_fy + y02_domain^filing_year")),
              data = dt, vcov = ~examiner_id)

  rf_results[[v]] <- list(baseline = m0, controlled = m1, saturated = m2)

  cat(sprintf("\n  %s:\n", v))
  for (s in c("baseline", "controlled", "saturated")) {
    m <- rf_results[[v]][[s]]
    cat(sprintf("    %-12s: coef = %.4f (%.4f), p = %.4f\n",
                s, coef(m)["grant_rate_std"],
                sqrt(vcov(m)["grant_rate_std", "grant_rate_std"]),
                fixest::pvalue(m)["grant_rate_std"]))
  }
}

# ── 4. IV: Examiner Grant Rate → Granted → Follow-on ────────────────────
cat("\n=== IV REGRESSIONS ===\n")
cat("Z = examiner grant rate, D = granted, Y = follow-on/citations\n\n")

iv_results <- list()
for (v in c("followon_5yr", "fwd_citations")) {
  logv <- paste0("log_", v)
  if (sum(!is.na(dt[[logv]])) < 100) next

  iv <- feols(as.formula(paste(logv, "~ log_claims + log_bwd_cite | au_fy | granted ~ grant_rate_std")),
              data = dt, vcov = ~examiner_id)
  iv_results[[v]] <- iv

  cat(sprintf("  IV (%s): coef = %.4f (%.4f), p = %.4f\n",
              v, coef(iv)["fit_granted"],
              sqrt(vcov(iv)["fit_granted", "fit_granted"]),
              fixest::pvalue(iv)["fit_granted"]))
}

# ── 5. HETEROGENEITY BY Y02 DOMAIN ──────────────────────────────────────
cat("\n=== HETEROGENEITY BY TECHNOLOGY DOMAIN ===\n")

# Use forward citations for domain heterogeneity (follow-on is a subclass-level
# aggregate that is absorbed by au_fy FE in most domain subsamples)
hetero_results <- list()
for (dom in unique(dt$y02_domain)) {
  sub <- dt[y02_domain == dom]
  if (nrow(sub) < 200) next

  m <- feols(log_fwd_citations ~ grant_rate_std + log_claims + log_bwd_cite | au_fy,
             data = sub, vcov = ~examiner_id)
  hetero_results[[dom]] <- m
  cat(sprintf("  %s (n=%s): coef = %.4f (%.4f)\n",
              dom, format(nrow(sub), big.mark = ","),
              coef(m)["grant_rate_std"],
              sqrt(vcov(m)["grant_rate_std", "grant_rate_std"])))
}

# ── 6. TEMPORAL HETEROGENEITY ────────────────────────────────────────────
cat("\n=== TEMPORAL HETEROGENEITY ===\n")

dt[, era := fcase(
  filing_year <= 2004, "2001-2004",
  filing_year <= 2008, "2005-2008",
  filing_year <= 2012, "2009-2012",
  default = NA_character_
)]

era_results <- list()
for (e in unique(na.omit(dt$era))) {
  sub <- dt[era == e]
  if (nrow(sub) < 200) next

  m <- feols(log_followon_5yr ~ grant_rate_std + log_claims + log_bwd_cite | au_fy,
             data = sub, vcov = ~examiner_id)
  era_results[[e]] <- m
  cat(sprintf("  %s (n=%s): coef = %.4f (%.4f)\n",
              e, format(nrow(sub), big.mark = ","),
              coef(m)["grant_rate_std"],
              sqrt(vcov(m)["grant_rate_std", "grant_rate_std"])))
}

# ── 7. INFERENCE: MULTIPLE CLUSTERING APPROACHES ────────────────────────
cat("\n=== CLUSTERING COMPARISON ===\n")

# Use baseline specification WITHOUT controls (consistent with primary spec)
m_base <- feols(log_followon_5yr ~ grant_rate_std | au_fy,
                data = dt)

# Cluster at examiner level (primary)
m_exam <- feols(log_followon_5yr ~ grant_rate_std | au_fy,
                data = dt, vcov = ~examiner_id)
# Two-way: examiner × CPC subclass
m_2way <- feols(log_followon_5yr ~ grant_rate_std | au_fy,
                data = dt, vcov = ~examiner_id + cpc_subclass)
# Art unit level
m_au <- feols(log_followon_5yr ~ grant_rate_std | au_fy,
              data = dt, vcov = ~examiner_art_unit)

se_exam <- sqrt(vcov(m_exam)["grant_rate_std", "grant_rate_std"])
se_2way <- sqrt(vcov(m_2way)["grant_rate_std", "grant_rate_std"])
se_au   <- sqrt(vcov(m_au)["grant_rate_std", "grant_rate_std"])

cat(sprintf("  Cluster examiner:       se = %.4f\n", se_exam))
cat(sprintf("  Two-way (exam × CPC):   se = %.4f\n", se_2way))
cat(sprintf("  Cluster art unit:       se = %.4f\n", se_au))

# ── 8. COLLAPSED SUBCLASS × FILING-YEAR ANALYSIS (Primary) ────────────
cat("\n=== COLLAPSED: CPC SUBCLASS × FILING YEAR ===\n")
cat("This is the level at which the follow-on outcome genuinely varies.\n")

dt_sub <- dt[, .(
  followon_5yr = followon_5yr[1],  # same for all obs in cell
  mean_grant_rate = mean(loo_grant_rate_i, na.rm = TRUE),
  mean_claims = mean(num_claims, na.rm = TRUE),
  mean_bwd_cite = mean(bwd_citations, na.rm = TRUE),
  mean_granted = mean(granted),
  n_apps = .N,
  n_examiners = uniqueN(examiner_id),
  y02_domain = y02_domain[1]
), by = .(cpc_subclass, filing_year)]

dt_sub[, log_followon_5yr := log1p(followon_5yr)]
dt_sub[, grant_rate_std_sub := (mean_grant_rate - mean(mean_grant_rate)) / sd(mean_grant_rate)]
dt_sub[, log_claims_sub := log1p(mean_claims)]
dt_sub[, log_bwd_sub := log1p(mean_bwd_cite)]

cat(sprintf("  Unique subclass × filing-year cells: %d\n", nrow(dt_sub)))
cat(sprintf("  Mean applications per cell: %.1f\n", mean(dt_sub$n_apps)))

# Uncontrolled (primary collapsed)
m_sub_0 <- feols(log_followon_5yr ~ grant_rate_std_sub | filing_year,
                 data = dt_sub[n_apps >= 5], weights = ~n_apps)

# With year FE only (no controls)
m_sub_1 <- feols(log_followon_5yr ~ grant_rate_std_sub | cpc_subclass + filing_year,
                 data = dt_sub[n_apps >= 5], weights = ~n_apps)

# With controls
m_sub_2 <- feols(log_followon_5yr ~ grant_rate_std_sub + log_claims_sub + log_bwd_sub | cpc_subclass + filing_year,
                 data = dt_sub[n_apps >= 5], weights = ~n_apps)

for (m_name in c("m_sub_0", "m_sub_1", "m_sub_2")) {
  m <- get(m_name)
  cat(sprintf("  %s: coef = %.4f (%.4f), p = %.4f, n = %d\n",
              m_name, coef(m)["grant_rate_std_sub"],
              sqrt(vcov(m)["grant_rate_std_sub", "grant_rate_std_sub"]),
              fixest::pvalue(m)["grant_rate_std_sub"],
              nobs(m)))
}

# Save collapsed results
collapsed_res <- data.table(
  spec = c("year_fe_only", "subclass_year_fe", "subclass_year_fe_controls"),
  coef = c(coef(m_sub_0)["grant_rate_std_sub"],
           coef(m_sub_1)["grant_rate_std_sub"],
           coef(m_sub_2)["grant_rate_std_sub"]),
  se = c(sqrt(vcov(m_sub_0)["grant_rate_std_sub", "grant_rate_std_sub"]),
         sqrt(vcov(m_sub_1)["grant_rate_std_sub", "grant_rate_std_sub"]),
         sqrt(vcov(m_sub_2)["grant_rate_std_sub", "grant_rate_std_sub"])),
  n = c(nobs(m_sub_0), nobs(m_sub_1), nobs(m_sub_2)),
  n_cells = nrow(dt_sub[n_apps >= 5])
)
fwrite(collapsed_res, file.path(DATA_DIR, "collapsed_subclass_results.csv"))

# ── 9. ADDITIONAL CLUSTERING: CPC subclass × filing-year ─────────────
cat("\n=== ADDITIONAL CLUSTERING ===\n")

# CPC subclass-level clustering (outcome varies at this level)
dt[, subclass_fy := paste0(cpc_subclass, "_", filing_year)]
m_subcl <- feols(log_followon_5yr ~ grant_rate_std | au_fy,
                 data = dt, vcov = ~subclass_fy)
se_subcl <- sqrt(vcov(m_subcl)["grant_rate_std", "grant_rate_std"])
cat(sprintf("  Cluster CPC subclass × year: se = %.4f\n", se_subcl))

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
      coef = coef(m)["grant_rate_std"],
      se = sqrt(vcov(m)["grant_rate_std", "grant_rate_std"]),
      p = fixest::pvalue(m)["grant_rate_std"],
      n = nobs(m)
    ))
  }
}
fwrite(main_res, file.path(DATA_DIR, "main_results.csv"))

# First stage results
fs_res <- data.table(
  spec = c("baseline", "controlled", "saturated"),
  coef = c(coef(fs0)["grant_rate_std"], coef(fs1)["grant_rate_std"], coef(fs2)["grant_rate_std"]),
  se = c(sqrt(vcov(fs0)["grant_rate_std", "grant_rate_std"]),
         sqrt(vcov(fs1)["grant_rate_std", "grant_rate_std"]),
         sqrt(vcov(fs2)["grant_rate_std", "grant_rate_std"])),
  f_stat = c(
    (coef(fs0)["grant_rate_std"] / sqrt(vcov(fs0)["grant_rate_std", "grant_rate_std"]))^2,
    (coef(fs1)["grant_rate_std"] / sqrt(vcov(fs1)["grant_rate_std", "grant_rate_std"]))^2,
    (coef(fs2)["grant_rate_std"] / sqrt(vcov(fs2)["grant_rate_std", "grant_rate_std"]))^2
  ),
  n = c(nobs(fs0), nobs(fs1), nobs(fs2))
)
fwrite(fs_res, file.path(DATA_DIR, "first_stage_results.csv"))

# IV results
if (length(iv_results) > 0) {
  iv_res <- data.table(
    outcome = names(iv_results),
    coef = sapply(iv_results, function(m) coef(m)["fit_granted"]),
    se = sapply(iv_results, function(m) sqrt(vcov(m)["fit_granted", "fit_granted"])),
    n = sapply(iv_results, nobs)
  )
  fwrite(iv_res, file.path(DATA_DIR, "iv_results.csv"))
}

# Heterogeneity results
hetero_res <- data.table(
  domain = names(hetero_results),
  coef = sapply(hetero_results, function(m) coef(m)["grant_rate_std"]),
  se = sapply(hetero_results, function(m) sqrt(vcov(m)["grant_rate_std", "grant_rate_std"])),
  n = sapply(hetero_results, nobs)
)
fwrite(hetero_res, file.path(DATA_DIR, "heterogeneity_domain.csv"))

# Era results
if (length(era_results) > 0) {
  era_res <- data.table(
    era = names(era_results),
    coef = sapply(era_results, function(m) coef(m)["grant_rate_std"]),
    se = sapply(era_results, function(m) sqrt(vcov(m)["grant_rate_std", "grant_rate_std"])),
    n = sapply(era_results, nobs)
  )
  fwrite(era_res, file.path(DATA_DIR, "heterogeneity_era.csv"))
}

# Clustering comparison (now includes CPC subclass × year)
cluster_res <- data.table(
  cluster = c("Examiner", "Two-way (Exam x CPC)", "Art Unit", "CPC Subclass x Year"),
  coef = coef(m_exam)["grant_rate_std"],
  se = c(se_exam, se_2way, se_au, se_subcl)
)
fwrite(cluster_res, file.path(DATA_DIR, "clustering_comparison.csv"))

# Save model objects for table generation
saveRDS(list(
  first_stage = list(fs0 = fs0, fs1 = fs1, fs2 = fs2),
  reduced_form = rf_results,
  iv = iv_results,
  heterogeneity = hetero_results,
  era = era_results,
  clustering = list(exam = m_exam, twoway = m_2way, au = m_au, subcl = m_subcl),
  collapsed = list(m_sub_0 = m_sub_0, m_sub_1 = m_sub_1, m_sub_2 = m_sub_2),
  balance_full = fullsample_balance,
  balance_grants = grantsonly_balance
), file.path(DATA_DIR, "model_objects.rds"))

cat("\nMain analysis complete.\n")
