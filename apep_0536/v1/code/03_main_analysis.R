# ==============================================================================
# 03_main_analysis.R — Main DiD Analysis
# APEP apep_0536: FTTH, Polarization, and Misinformation in France
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

cat("=== Analysis Panel ===\n")
cat("  Obs:", nrow(panel), "| Depts:", uniqueN(panel$dept_code),
    "| Elections:", uniqueN(panel$id_election), "\n")

# ==============================================================================
# 1. TWFE Baseline (for comparison — known to be biased with staggered timing)
# ==============================================================================

cat("\n=== 1. TWFE Baseline ===\n")

# Primary outcome: anti-system vote share (% of registered voters)
# Continuous treatment: FTTH coverage rate
twfe_continuous <- feols(
  antisystem_share ~ ftth_coverage | dept_id + election_id,
  data = panel,
  cluster = ~dept_code
)

# Binary treatment: crossed 50% threshold
twfe_binary_50 <- feols(
  antisystem_share ~ treated_50 | dept_id + election_id,
  data = panel,
  cluster = ~dept_code
)

# Secondary outcomes
twfe_turnout <- feols(
  turnout ~ ftth_coverage | dept_id + election_id,
  data = panel,
  cluster = ~dept_code
)

twfe_blank <- feols(
  blank_null_share ~ ftth_coverage | dept_id + election_id,
  data = panel,
  cluster = ~dept_code
)

cat("TWFE Results (continuous treatment):\n")
cat("  Anti-system share:", sprintf("%.4f (%.4f), p=%.3f",
    coef(twfe_continuous)[1], se(twfe_continuous)[1], fixest::pvalue(twfe_continuous)[1]), "\n")
cat("  Turnout:", sprintf("%.4f (%.4f), p=%.3f",
    coef(twfe_turnout)[1], se(twfe_turnout)[1], fixest::pvalue(twfe_turnout)[1]), "\n")
cat("  Blank/null:", sprintf("%.4f (%.4f), p=%.3f",
    coef(twfe_blank)[1], se(twfe_blank)[1], fixest::pvalue(twfe_blank)[1]), "\n")

# Save TWFE results
twfe_results <- data.table(
  outcome = c("antisystem_share", "antisystem_share", "turnout", "blank_null_share"),
  treatment = c("ftth_coverage", "treated_50", "ftth_coverage", "ftth_coverage"),
  estimate = c(coef(twfe_continuous)[1], coef(twfe_binary_50)[1],
               coef(twfe_turnout)[1], coef(twfe_blank)[1]),
  se = c(se(twfe_continuous)[1], se(twfe_binary_50)[1],
         se(twfe_turnout)[1], se(twfe_blank)[1]),
  pvalue = c(fixest::pvalue(twfe_continuous)[1], fixest::pvalue(twfe_binary_50)[1],
             fixest::pvalue(twfe_turnout)[1], fixest::pvalue(twfe_blank)[1]),
  n_obs = c(nobs(twfe_continuous), nobs(twfe_binary_50),
            nobs(twfe_turnout), nobs(twfe_blank)),
  estimator = "TWFE"
)
fwrite(twfe_results, file.path(data_dir, "twfe_results.csv"))

# ==============================================================================
# 2. Callaway-Sant'Anna (CS-DiD) — Heterogeneity-Robust
# ==============================================================================

cat("\n=== 2. Callaway-Sant'Anna DiD ===\n")

# CS-DiD requires: unit ID, time period (numeric), cohort (first treatment period), outcome
# Treatment: binary crossing of 50% FTTH coverage threshold
# Cohort: election_year when department first has >50% coverage

# Create period variable (election ordering)
election_order <- data.table(
  id_election = c("1999_euro_t1", "2002_pres_t1", "2004_euro_t1", "2007_pres_t1",
                   "2009_euro_t1", "2012_pres_t1", "2014_euro_t1", "2017_pres_t1",
                   "2019_euro_t1", "2022_pres_t1", "2024_euro_t1"),
  period = 1:11
)
panel <- merge(panel, election_order, by = "id_election", all.x = TRUE)

# Cohort: first election period where dept has >50% coverage
panel[, cohort_period := NA_integer_]
for (i in 1:nrow(election_order)) {
  eid <- election_order$id_election[i]
  pid <- election_order$period[i]
  treated_depts <- panel[id_election == eid & treated_50 == 1 & is.na(cohort_period), dept_code]
  panel[dept_code %in% treated_depts & is.na(cohort_period), cohort_period := pid]
}
# Never-treated departments get cohort = 0 (convention for did package)
panel[is.na(cohort_period), cohort_period := 0L]

cat("  Cohort distribution:\n")
print(panel[, .N, by = cohort_period][order(cohort_period)])

# Run CS-DiD
cs_result <- tryCatch({
  att_gt(
    yname = "antisystem_share",
    tname = "period",
    idname = "dept_id",
    gname = "cohort_period",
    data = as.data.frame(panel),
    control_group = "notyettreated",
    base_period = "varying"
  )
}, error = function(e) {
  cat("  CS-DiD failed:", e$message, "\n")
  cat("  Trying with never-treated control group...\n")
  att_gt(
    yname = "antisystem_share",
    tname = "period",
    idname = "dept_id",
    gname = "cohort_period",
    data = as.data.frame(panel),
    control_group = "nevertreated",
    base_period = "varying"
  )
})

# Aggregate to overall ATT
cs_agg <- aggte(cs_result, type = "simple")
cat("\n  CS-DiD Overall ATT:\n")
cat("  Estimate:", sprintf("%.4f", cs_agg$overall.att), "\n")
cat("  SE:", sprintf("%.4f", cs_agg$overall.se), "\n")
cat("  95% CI: [", sprintf("%.4f", cs_agg$overall.att - 1.96 * cs_agg$overall.se),
    ",", sprintf("%.4f", cs_agg$overall.att + 1.96 * cs_agg$overall.se), "]\n")

# Event-study aggregation
cs_es <- aggte(cs_result, type = "dynamic")
cat("\n  CS-DiD Event-Study Coefficients:\n")
es_data <- data.table(
  event_time = cs_es$egt,
  estimate = cs_es$att.egt,
  se = cs_es$se.egt,
  ci_lower = cs_es$att.egt - 1.96 * cs_es$se.egt,
  ci_upper = cs_es$att.egt + 1.96 * cs_es$se.egt
)
print(es_data)
fwrite(es_data, file.path(data_dir, "cs_event_study.csv"))

# Save CS aggregate results
cs_results <- data.table(
  outcome = "antisystem_share",
  treatment = "treated_50",
  estimate = cs_agg$overall.att,
  se = cs_agg$overall.se,
  ci_lower = cs_agg$overall.att - 1.96 * cs_agg$overall.se,
  ci_upper = cs_agg$overall.att + 1.96 * cs_agg$overall.se,
  estimator = "CS-DiD"
)
fwrite(cs_results, file.path(data_dir, "cs_did_results.csv"))

# ==============================================================================
# 3. CS-DiD for Secondary Outcomes
# ==============================================================================

cat("\n=== 3. Secondary Outcomes (CS-DiD) ===\n")

secondary_outcomes <- c("turnout", "blank_null_share", "antisystem_share_expr")
secondary_results <- list()

for (outcome_var in secondary_outcomes) {
  cat("  Running CS-DiD for:", outcome_var, "...\n")
  cs_sec <- tryCatch({
    att_gt(
      yname = outcome_var,
      tname = "period",
      idname = "dept_id",
      gname = "cohort_period",
      data = as.data.frame(panel),
      control_group = "notyettreated",
      base_period = "varying"
    )
  }, error = function(e) {
    cat("    Failed:", e$message, "\n")
    NULL
  })

  if (!is.null(cs_sec)) {
    agg <- aggte(cs_sec, type = "simple")
    cat("    ATT:", sprintf("%.4f (%.4f)", agg$overall.att, agg$overall.se), "\n")

    secondary_results[[outcome_var]] <- data.table(
      outcome = outcome_var,
      estimate = agg$overall.att,
      se = agg$overall.se,
      ci_lower = agg$overall.att - 1.96 * agg$overall.se,
      ci_upper = agg$overall.att + 1.96 * agg$overall.se,
      estimator = "CS-DiD"
    )

    # Event study for each
    es_sec <- aggte(cs_sec, type = "dynamic")
    es_sec_data <- data.table(
      event_time = es_sec$egt,
      estimate = es_sec$att.egt,
      se = es_sec$se.egt
    )
    fwrite(es_sec_data, file.path(data_dir, paste0("cs_es_", outcome_var, ".csv")))
  }
}

if (length(secondary_results) > 0) {
  secondary_dt <- rbindlist(secondary_results)
  fwrite(secondary_dt, file.path(data_dir, "cs_secondary_results.csv"))
}

# ==============================================================================
# 4. Sun-Abraham (SA) Estimator — Robustness
# ==============================================================================

cat("\n=== 4. Sun-Abraham Estimator ===\n")

# SA requires: cohort variable and interaction with relative time
# Use fixest::sunab()
panel[, cohort_sa := fifelse(cohort_period == 0, NA_real_, as.numeric(cohort_period))]

sa_result <- tryCatch({
  feols(
    antisystem_share ~ sunab(cohort_sa, period) | dept_id + period,
    data = panel,
    cluster = ~dept_code
  )
}, error = function(e) {
  cat("  Sun-Abraham failed:", e$message, "\n")
  NULL
})

if (!is.null(sa_result)) {
  cat("  Sun-Abraham results:\n")
  sa_agg <- summary(sa_result, agg = "ATT")
  print(sa_agg)

  # Extract event-study coefficients
  sa_coefs <- as.data.table(coeftable(sa_result))
  sa_coefs[, event_time := as.numeric(gsub(".*::(-?[0-9]+)$", "\\1", rownames(coeftable(sa_result))))]
  fwrite(sa_coefs, file.path(data_dir, "sa_event_study.csv"))
}

# ==============================================================================
# 5. Balance Test: Pre-treatment characteristics vs rollout timing
# ==============================================================================

cat("\n=== 5. Balance Tests ===\n")

# Test: do baseline (2012) political outcomes predict FTTH rollout speed?
baseline_2012 <- panel[id_election == "2012_pres_t1",
  .(dept_code, baseline_antisystem = antisystem_share,
    baseline_turnout = turnout)]

# Merge with FTTH coverage at 2022 (as measure of cumulative rollout)
ftth_2022 <- fread(file.path(data_dir, "ftth_dept_quarter.csv"))
ftth_2022_q2 <- ftth_2022[year == 2022 & quarter == 2,
  .(dept_code, ftth_2022 = ftth_coverage)]

balance_data <- merge(baseline_2012, ftth_2022_q2, by = "dept_code")

# Regression: does 2012 anti-system predict 2022 FTTH coverage?
balance_reg1 <- lm(ftth_2022 ~ baseline_antisystem, data = balance_data)
balance_reg2 <- lm(ftth_2022 ~ baseline_turnout, data = balance_data)
balance_reg3 <- lm(ftth_2022 ~ baseline_antisystem + baseline_turnout, data = balance_data)

cat("  Balance test: 2012 anti-system → 2022 FTTH coverage\n")
cat("    Coefficient:", sprintf("%.4f (%.4f), p=%.3f",
    coef(balance_reg1)[2], summary(balance_reg1)$coefficients[2, 2],
    summary(balance_reg1)$coefficients[2, 4]), "\n")
cat("  Balance test: 2012 turnout → 2022 FTTH coverage\n")
cat("    Coefficient:", sprintf("%.4f (%.4f), p=%.3f",
    coef(balance_reg2)[2], summary(balance_reg2)$coefficients[2, 2],
    summary(balance_reg2)$coefficients[2, 4]), "\n")

balance_results <- data.table(
  predictor = c("baseline_antisystem", "baseline_turnout", "baseline_antisystem (joint)", "baseline_turnout (joint)"),
  outcome = "ftth_2022",
  estimate = c(coef(balance_reg1)[2], coef(balance_reg2)[2],
               coef(balance_reg3)[2], coef(balance_reg3)[3]),
  se = c(summary(balance_reg1)$coefficients[2, 2],
         summary(balance_reg2)$coefficients[2, 2],
         summary(balance_reg3)$coefficients[2, 2],
         summary(balance_reg3)$coefficients[3, 2]),
  pvalue = c(summary(balance_reg1)$coefficients[2, 4],
             summary(balance_reg2)$coefficients[2, 4],
             summary(balance_reg3)$coefficients[2, 4],
             summary(balance_reg3)$coefficients[3, 4]),
  r_squared = c(summary(balance_reg1)$r.squared, summary(balance_reg2)$r.squared,
                summary(balance_reg3)$r.squared, summary(balance_reg3)$r.squared)
)
fwrite(balance_results, file.path(data_dir, "balance_test_results.csv"))

# ==============================================================================
# 6. Heterogeneity Analysis
# ==============================================================================

cat("\n=== 6. Heterogeneity Analysis ===\n")

# Heterogeneity by baseline characteristics
# Use dept-level characteristics that are time-invariant

# A. Rural vs Urban: use premises_total from 2022 FTTH data (available for all depts)
ftth_2022_premises <- fread(file.path(data_dir, "ftth_dept_quarter.csv"))[
  year == 2022 & quarter == 2, .(dept_code, premises_total_2022 = premises_total)]
panel <- merge(panel, ftth_2022_premises, by = "dept_code", all.x = TRUE)
median_premises <- median(panel$premises_total_2022, na.rm = TRUE)
panel[, is_rural := as.integer(premises_total_2022 < median_premises)]

# B. Baseline anti-system (2012 level)
panel <- merge(panel, baseline_2012[, .(dept_code, baseline_antisystem)],
               by = "dept_code", all.x = TRUE)
median_antisys <- median(panel$baseline_antisystem, na.rm = TRUE)
panel[, high_baseline_antisystem := as.integer(baseline_antisystem > median_antisys)]

# Run heterogeneous TWFE (interaction with time-invariant characteristics)
het_rural <- feols(
  antisystem_share ~ ftth_coverage + ftth_coverage:i(is_rural) | dept_id + election_id,
  data = panel[!is.na(is_rural)],
  cluster = ~dept_code
)

het_baseline <- feols(
  antisystem_share ~ ftth_coverage + ftth_coverage:i(high_baseline_antisystem) | dept_id + election_id,
  data = panel[!is.na(high_baseline_antisystem)],
  cluster = ~dept_code
)

cat("  Heterogeneity by rurality:\n")
print(coeftable(het_rural))

cat("  Heterogeneity by baseline anti-system:\n")
print(coeftable(het_baseline))

het_results <- rbind(
  data.table(
    specification = "Rural interaction",
    term = rownames(coeftable(het_rural)),
    estimate = coef(het_rural),
    se = se(het_rural),
    pvalue = fixest::pvalue(het_rural)
  ),
  data.table(
    specification = "Baseline antisystem interaction",
    term = rownames(coeftable(het_baseline)),
    estimate = coef(het_baseline),
    se = se(het_baseline),
    pvalue = fixest::pvalue(het_baseline)
  )
)
fwrite(het_results, file.path(data_dir, "heterogeneity_results.csv"))

# Save updated panel
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))

cat("\n03_main_analysis.R complete.\n")
