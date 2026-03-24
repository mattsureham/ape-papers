## 03_main_analysis.R — Triple-Difference and Callaway-Sant'Anna estimates
## Estimates effect of universal free school meals on household food security

library(data.table)
library(fixest)
library(did)
library(jsonlite)

# Set working directory to paper root (parent of code/)
paper_dir <- tryCatch(
  normalizePath(file.path(dirname(sys.frame(1)$ofile), ".."), mustWork = FALSE),
  error = function(e) normalizePath(file.path(getwd(), ".."), mustWork = FALSE)
)
if (dir.exists(paper_dir)) setwd(paper_dir)
datadir <- "data"

cat("=== Main Analysis: Universal Free School Meals ===\n")

# ── Load data ────────────────────────────────────────────────────
df <- fread(file.path(datadir, "analysis_data.csv"))
cat(sprintf("Loaded %s household observations\n", format(nrow(df), big.mark = ",")))

# ── Pre-treatment descriptive statistics ─────────────────────────
cat("\n--- Pre-treatment (2019) summary ---\n")
pre <- df[year == 2019]
cat(sprintf("Food insecurity rate: %.1f%%\n", 100 * weighted.mean(pre$food_insecure, pre$wt)))
cat(sprintf("Very low food security: %.1f%%\n", 100 * weighted.mean(pre$very_low_fs, pre$wt)))
cat(sprintf("SNAP receipt rate: %.1f%%\n", 100 * weighted.mean(pre$snap_receipt, pre$wt, na.rm = TRUE)))
cat(sprintf("Pct with school-age children: %.1f%%\n", 100 * mean(pre$has_school_age)))

# Standard deviation of outcome (for SDE calculation)
sd_fi_pre <- sd(df[year <= 2021]$food_insecure)
sd_vlfs_pre <- sd(df[year <= 2021]$very_low_fs)
cat(sprintf("SD(food_insecure) pre-treatment: %.4f\n", sd_fi_pre))
cat(sprintf("SD(very_low_fs) pre-treatment: %.4f\n", sd_vlfs_pre))

# ── SPECIFICATION 1: Basic Triple-Difference ─────────────────────
cat("\n=== Specification 1: Basic DDD (state FE + year FE) ===\n")

# Need explicit two-way interactions for the DDD
df[, treat_x_post := treat_state * post]
df[, school_x_post := has_school_age * post]
df[, treat_x_school := treat_state * has_school_age]

# LPM with state and year FE, clustered at state level
m1_fi <- feols(food_insecure ~ treat_x_school_x_post + treat_x_post +
                 school_x_post + treat_x_school |
                 GESTFIPS + year,
               data = df, weights = ~wt, cluster = ~GESTFIPS)

m1_vlfs <- feols(very_low_fs ~ treat_x_school_x_post + treat_x_post +
                   school_x_post + treat_x_school |
                   GESTFIPS + year,
                 data = df, weights = ~wt, cluster = ~GESTFIPS)

m1_snap <- feols(snap_receipt ~ treat_x_school_x_post + treat_x_post +
                   school_x_post + treat_x_school |
                   GESTFIPS + year,
                 data = df, weights = ~wt, cluster = ~GESTFIPS)

cat("\nDDD — Food Insecurity:\n")
print(summary(m1_fi))
cat("\nDDD — Very Low Food Security:\n")
print(summary(m1_vlfs))
cat("\nDDD — SNAP Receipt:\n")
print(summary(m1_snap))

# ── SPECIFICATION 2: Saturated DDD (state×year FE) ──────────────
cat("\n=== Specification 2: Saturated DDD (state×year FE) ===\n")

# State×year FE absorbs treat_x_post; state×schoolage absorbs treat_x_school
# Only identifies the triple interaction + schoolage×year variation
df[, state_school := paste(GESTFIPS, has_school_age, sep = "_")]

m2_fi <- feols(food_insecure ~ treat_x_school_x_post + school_x_post |
                 GESTFIPS^year + state_school,
               data = df, weights = ~wt, cluster = ~GESTFIPS)

m2_vlfs <- feols(very_low_fs ~ treat_x_school_x_post + school_x_post |
                   GESTFIPS^year + state_school,
                 data = df, weights = ~wt, cluster = ~GESTFIPS)

m2_snap <- feols(snap_receipt ~ treat_x_school_x_post + school_x_post |
                   GESTFIPS^year + state_school,
                 data = df, weights = ~wt, cluster = ~GESTFIPS)

cat("\nSaturated DDD — Food Insecurity:\n")
print(summary(m2_fi))
cat("\nSaturated DDD — Very Low Food Security:\n")
print(summary(m2_vlfs))

# ── SPECIFICATION 3: DDD with individual controls ────────────────
cat("\n=== Specification 3: DDD with controls ===\n")

m3_fi <- feols(food_insecure ~ treat_x_school_x_post + treat_x_post +
                 school_x_post + treat_x_school +
                 age_ref + female_ref + hhsize + low_income +
                 single_parent + metro |
                 GESTFIPS + year + educ_cat + race_eth,
               data = df, weights = ~wt, cluster = ~GESTFIPS)

cat("\nDDD with controls — Food Insecurity:\n")
print(summary(m3_fi))

# ── SPECIFICATION 4: State-level Callaway-Sant'Anna ──────────────
cat("\n=== Specification 4: Callaway-Sant'Anna (state-level) ===\n")

# Create state-year panel for HH with school-age children
state_panel <- df[has_school_age == 1, .(
  food_insecure = weighted.mean(food_insecure, wt),
  very_low_fs = weighted.mean(very_low_fs, wt),
  snap_receipt = weighted.mean(snap_receipt, wt, na.rm = TRUE),
  n_hh = .N
), by = .(GESTFIPS, year, first_treat)]

# Balance the panel (ensure all state×year combos exist)
states <- unique(state_panel$GESTFIPS)
years <- unique(state_panel$year)
full_grid <- CJ(GESTFIPS = states, year = years)
state_panel <- merge(full_grid, state_panel, by = c("GESTFIPS", "year"), all.x = TRUE)

# Fill first_treat for states missing some years
state_panel[, first_treat := max(first_treat, na.rm = TRUE), by = GESTFIPS]
state_panel[is.infinite(first_treat), first_treat := 0]

# Drop states with missing outcome (incomplete panel)
complete_states <- state_panel[, .(n_years = sum(!is.na(food_insecure))), by = GESTFIPS]
complete_states <- complete_states[n_years == length(years)]$GESTFIPS
state_panel <- state_panel[GESTFIPS %in% complete_states]

cat(sprintf("State panel: %d states × %d years = %d obs\n",
            uniqueN(state_panel$GESTFIPS), length(years), nrow(state_panel)))
cat(sprintf("Treated states: %d | Never-treated: %d\n",
            sum(unique(state_panel[, .(GESTFIPS, first_treat)])$first_treat > 0),
            sum(unique(state_panel[, .(GESTFIPS, first_treat)])$first_treat == 0)))

# Assign numeric state ID
state_panel[, state_id := as.numeric(as.factor(GESTFIPS))]

# CS-DiD
cs_fi <- tryCatch(
  att_gt(
    yname = "food_insecure",
    tname = "year",
    idname = "state_id",
    gname = "first_treat",
    data = as.data.frame(state_panel),
    control_group = "nevertreated",
    base_period = "universal"
  ),
  error = function(e) {
    cat(sprintf("  CS-DiD error: %s\n", e$message))
    NULL
  }
)

if (!is.null(cs_fi)) {
  cat("\nCS-DiD Group-Time ATT:\n")
  print(summary(cs_fi))

  cs_agg <- aggte(cs_fi, type = "simple")
  cat(sprintf("\nCS-DiD Overall ATT: %.4f (SE: %.4f)\n", cs_agg$overall.att, cs_agg$overall.se))

  # Dynamic aggregation (event study)
  cs_dyn <- aggte(cs_fi, type = "dynamic")
  cat("\nCS-DiD Event Study:\n")
  print(summary(cs_dyn))

  # Save for table construction
  cs_results <- list(
    overall_att = cs_agg$overall.att,
    overall_se = cs_agg$overall.se,
    dynamic = data.table(
      event_time = cs_dyn$egt,
      att = cs_dyn$att.egt,
      se = cs_dyn$se.egt
    )
  )
  saveRDS(cs_results, file.path(datadir, "cs_results.rds"))
}

# ── SPECIFICATION 5: Event study (household-level DDD) ───────────
cat("\n=== Specification 5: Event Study DDD ===\n")

# For treated states, event time relative to their treatment year
# Cohort 1 (2022): event_time = year - 2022
# Cohort 2 (2023): event_time = year - 2023
# Control: never-treated → use year dummies
df[, event_time := fifelse(
  first_treat > 0,
  year - first_treat,
  NA_integer_
)]

# Create year-specific DDD indicators
for (y in unique(df$year)) {
  varname <- paste0("ddd_", y)
  df[, (varname) := as.integer(treat_state == 1 & has_school_age == 1 & year == y)]
}

# Event study: interact treatment×schoolage with year dummies
# Reference year: 2019
m5_fi <- feols(food_insecure ~ i(year, treat_x_school, ref = 2019) +
                 treat_x_post + school_x_post |
                 GESTFIPS + year,
               data = df, weights = ~wt, cluster = ~GESTFIPS)

cat("\nEvent Study DDD — Food Insecurity:\n")
print(summary(m5_fi))

# Save event study coefficients
es_coefs <- as.data.table(coeftable(m5_fi))
es_coefs[, term := rownames(coeftable(m5_fi))]
es_coefs <- es_coefs[grepl("year.*treat_x_school", term)]
saveRDS(es_coefs, file.path(datadir, "event_study_coefs.rds"))

# ── Save all model objects ───────────────────────────────────────
models <- list(
  m1_fi = m1_fi, m1_vlfs = m1_vlfs, m1_snap = m1_snap,
  m2_fi = m2_fi, m2_vlfs = m2_vlfs, m2_snap = m2_snap,
  m3_fi = m3_fi,
  m5_fi = m5_fi,
  sd_fi_pre = sd_fi_pre,
  sd_vlfs_pre = sd_vlfs_pre
)
saveRDS(models, file.path(datadir, "main_models.rds"))

# ── Diagnostics for validator ────────────────────────────────────
n_treated_states <- uniqueN(df[treat_state == 1]$GESTFIPS)
n_pre <- length(unique(df[year < 2022]$year))  # years before first treatment
n_obs <- nrow(df)

diagnostics <- list(
  n_treated = n_treated_states,
  n_pre = n_pre,
  n_obs = n_obs,
  n_clusters = uniqueN(df$GESTFIPS),
  outcome_sd = sd_fi_pre,
  ddd_coef = coef(m2_fi)["treat_x_school_x_post"],
  ddd_se = se(m2_fi)["treat_x_school_x_post"]
)
write_json(diagnostics, file.path(datadir, "diagnostics.json"), auto_unbox = TRUE)

cat(sprintf("\nDiagnostics saved. n_treated=%d, n_pre=%d, n_obs=%s\n",
            n_treated_states, n_pre, format(n_obs, big.mark = ",")))

cat("\n=== Main analysis complete ===\n")
