# 04_robustness.R — Robustness checks
# apep_0890: Craigslist Entry and Local Journalism Employment

source("00_packages.R")
setwd(file.path(getwd(), "..", "data"))

panel <- readRDS("panel_clean.rds")
results <- readRDS("results_main.rds")

# Prepare annual panel (same as main analysis)
panel_annual <- panel %>%
  group_by(fips, year, state_fips, g, treated_ever) %>%
  summarise(
    emp = mean(emp, na.rm = TRUE),
    ln_emp = mean(ln_emp, na.rm = TRUE),
    hir_n = mean(hir_n, na.rm = TRUE),
    sep = mean(sep, na.rm = TRUE),
    earn_s = mean(earn_s, na.rm = TRUE),
    .groups = "drop"
  )

# =============================================================================
# 1. Sun-Abraham estimator (via fixest)
# =============================================================================
cat("=== Sun-Abraham (fixest::sunab) ===\n")

# sunab requires a treatment cohort variable (0 = never treated becomes large number)
panel_annual <- panel_annual %>%
  mutate(
    cohort = ifelse(g == 0, 10000L, g),
    rel_year = year - cohort
  )

sa_out <- feols(
  ln_emp ~ sunab(cohort, year) | fips + year,
  data = panel_annual,
  cluster = ~state_fips
)
cat("Sun-Abraham overall ATT:\n")
print(summary(sa_out, agg = "ATT"))

# =============================================================================
# 2. CS-DiD with never-treated only as control group
# =============================================================================
cat("\n=== CS-DiD: Never-treated control group ===\n")
cs_never <- att_gt(
  yname = "ln_emp",
  tname = "year",
  idname = "fips",
  gname = "g",
  data = panel_annual,
  control_group = "nevertreated",
  clustervars = "state_fips",
  base_period = "universal"
)
cs_never_agg <- aggte(cs_never, type = "simple")
cat("Never-treated ATT:\n")
summary(cs_never_agg)

# =============================================================================
# 3. Placebo test: Utilities (NAICS 221) should NOT be affected
# =============================================================================
cat("\n=== Placebo: Utilities (NAICS 221) ===\n")
placebo <- readRDS("panel_placebo.rds")
placebo <- placebo %>%
  filter(year >= 2001, year <= 2015)

# Filter valid counties
placebo_valid <- placebo %>%
  group_by(fips) %>%
  filter(sum(emp > 0, na.rm = TRUE) >= 8) %>%
  ungroup()

placebo_annual <- placebo_valid %>%
  mutate(
    ln_emp = log(emp + 1),
    state_fips = as.integer(fips %/% 1000),
    g = ifelse(treated_ever, cl_entry_year, 0L)
  ) %>%
  group_by(fips, year, state_fips, g, treated_ever) %>%
  summarise(ln_emp = mean(ln_emp, na.rm = TRUE), .groups = "drop")

cs_placebo <- tryCatch({
  att_gt(
    yname = "ln_emp",
    tname = "year",
    idname = "fips",
    gname = "g",
    data = placebo_annual,
    control_group = "notyettreated",
    clustervars = "state_fips",
    base_period = "universal"
  )
}, error = function(e) {
  cat("Placebo CS-DiD failed:", e$message, "\n")
  NULL
})

if (!is.null(cs_placebo)) {
  cs_placebo_agg <- aggte(cs_placebo, type = "simple")
  cat("Placebo (Utilities) ATT:\n")
  summary(cs_placebo_agg)
} else {
  cs_placebo_agg <- NULL
}

# =============================================================================
# 4. Leave-one-cohort-out
# =============================================================================
cat("\n=== Leave-one-cohort-out ===\n")
cohorts <- sort(unique(panel_annual$g[panel_annual$g > 0]))
loco_results <- list()

for (cohort_drop in cohorts) {
  panel_loco <- panel_annual %>%
    filter(g != cohort_drop)

  cs_loco <- tryCatch({
    cs_tmp <- att_gt(
      yname = "ln_emp",
      tname = "year",
      idname = "fips",
      gname = "g",
      data = panel_loco,
      control_group = "notyettreated",
      clustervars = "state_fips",
      base_period = "universal"
    )
    aggte(cs_tmp, type = "simple")
  }, error = function(e) NULL)

  if (!is.null(cs_loco)) {
    loco_results[[as.character(cohort_drop)]] <- data.frame(
      dropped_cohort = cohort_drop,
      att = cs_loco$overall.att,
      se = cs_loco$overall.se
    )
    cat("  Drop", cohort_drop, ": ATT =", round(cs_loco$overall.att, 4),
        "(SE =", round(cs_loco$overall.se, 4), ")\n")
  }
}
loco_df <- bind_rows(loco_results)

# =============================================================================
# 5. HonestDiD sensitivity (Rambachan-Roth bounds)
# =============================================================================
cat("\n=== HonestDiD Sensitivity ===\n")
honest_result <- tryCatch({
  cs_dynamic <- results$cs_dynamic

  # Extract event-study coefficients and variance
  es_betas <- cs_dynamic$att.egt
  es_se <- cs_dynamic$se.egt
  es_e <- cs_dynamic$egt

  # Pre-treatment indices
  pre_idx <- which(es_e < 0)
  post_idx <- which(es_e >= 0)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    # Construct the variance-covariance matrix
    n_coefs <- length(es_betas)
    V <- diag(es_se^2)

    # Run HonestDiD with relative magnitudes approach
    honest_out <- HonestDiD::createSensitivityResults(
      betahat = es_betas,
      sigma = V,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 2, by = 0.5)
    )
    cat("HonestDiD bounds computed.\n")
    print(honest_out)
    honest_out
  } else {
    cat("Insufficient pre/post periods for HonestDiD.\n")
    NULL
  }
}, error = function(e) {
  cat("HonestDiD failed:", e$message, "\n")
  NULL
})

# =============================================================================
# 6. Save robustness results
# =============================================================================
# Extract Sun-Abraham coefficients (model object doesn't serialize well)
sa_summary <- summary(sa_out, agg = "ATT")
sa_coefs <- list(
  coef = sa_summary$coeftable[1, 1],
  se = sa_summary$coeftable[1, 2],
  pval = sa_summary$coeftable[1, 4]
)

robustness <- list(
  sa_coefs = sa_coefs,
  cs_never_agg = cs_never_agg,
  cs_placebo_agg = cs_placebo_agg,
  loco_df = loco_df,
  honest_result = honest_result
)
saveRDS(robustness, "results_robustness.rds")
cat("\nRobustness results saved.\n")
