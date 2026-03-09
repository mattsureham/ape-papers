## =============================================================================
## 03_main_analysis.R — Primary identification: DDD and staggered DiD
## =============================================================================

source("00_packages.R")

data_dir <- "../data/"
state_dow   <- fread(file.path(data_dir, "state_dow_month_panel.csv"))
state_month <- fread(file.path(data_dir, "state_month_panel.csv"))
state_year  <- fread(file.path(data_dir, "state_year_panel.csv"))

state_month[, treat_date := as.Date(treat_date)]
state_year[, treat_date := as.Date(treat_date)]

cat("=== MAIN ANALYSIS ===\n\n")

## -----------------------------------------------------------------------------
## 1. TRIPLE-DIFFERENCE: Legal × Sunday × NFL Season
## -----------------------------------------------------------------------------

cat("--- Triple-Difference (DDD) ---\n")

# DDD: alcohol_crashes ~ Legal × Sunday × NFL_season
# With state×DOW, DOW×time, state×time FE

# Panel: state × day-of-week × year-month
ddd1 <- feols(
  alcohol_crashes ~ legal_x_sunday_x_nfl + legal_x_sunday + treated * nfl_season |
    state_dow + time_id^dow + state_fips^time_id,
  data = state_dow,
  cluster = ~state_fips
)

cat("DDD Model 1: Legal × Sunday × NFL Season\n")
print(summary(ddd1))

# DDD placebo: non-alcohol crashes (should be null)
ddd_placebo <- feols(
  non_alc_crashes ~ legal_x_sunday_x_nfl + legal_x_sunday + treated * nfl_season |
    state_dow + time_id^dow + state_fips^time_id,
  data = state_dow,
  cluster = ~state_fips
)

cat("\nDDD Placebo (Non-alcohol crashes):\n")
print(summary(ddd_placebo))

# DDD nighttime only
ddd_night <- feols(
  night_alc ~ legal_x_sunday_x_nfl + legal_x_sunday + treated * nfl_season |
    state_dow + time_id^dow + state_fips^time_id,
  data = state_dow,
  cluster = ~state_fips
)

cat("\nDDD Nighttime Alcohol Crashes:\n")
print(summary(ddd_night))

## -----------------------------------------------------------------------------
## 2. DD (Sunday effect only, ignoring NFL season)
## -----------------------------------------------------------------------------

cat("\n--- Double-Difference (DD): Legal × Sunday ---\n")

dd1 <- feols(
  alcohol_crashes ~ legal_x_sunday + treated |
    state_dow + time_id^dow + state_fips^time_id,
  data = state_dow,
  cluster = ~state_fips
)

cat("DD Model: Legal × Sunday\n")
print(summary(dd1))

## -----------------------------------------------------------------------------
## 3. STAGGERED DiD: State × Month (Callaway-Sant'Anna)
## -----------------------------------------------------------------------------

cat("\n--- Callaway-Sant'Anna Staggered DiD ---\n")

# Prepare data for did::att_gt
sm <- copy(state_month)
sm[, state_id := as.integer(as.factor(state_fips))]

# CS requires: panel data with numeric id, time, group (0 for never-treated)
cs_out <- tryCatch({
  att_gt(
    yname = "alc_rate",
    tname = "time_id",
    idname = "state_id",
    gname = "g",
    data = as.data.frame(sm),
    control_group = "nevertreated",
    est_method = "dr",
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS att_gt failed:", e$message, "\n")
  cat("Trying with reg estimator...\n")
  tryCatch({
    att_gt(
      yname = "alc_rate",
      tname = "time_id",
      idname = "state_id",
      gname = "g",
      data = as.data.frame(sm),
      control_group = "nevertreated",
      est_method = "reg",
      base_period = "universal"
    )
  }, error = function(e2) {
    cat("CS att_gt also failed with reg:", e2$message, "\n")
    NULL
  })
})

if (!is.null(cs_out)) {
  cat("\nCS-DiD ATT summary:\n")
  cs_agg <- aggte(cs_out, type = "simple")
  print(summary(cs_agg))

  # Event study aggregation
  cs_es <- aggte(cs_out, type = "dynamic", min_e = -24, max_e = 24)
  cat("\nCS Event Study:\n")
  print(summary(cs_es))

  # Save CS results
  cs_es_df <- data.table(
    event_time = cs_es$egt,
    att = cs_es$att.egt,
    se = cs_es$se.egt,
    ci_lower = cs_es$att.egt - 1.96 * cs_es$se.egt,
    ci_upper = cs_es$att.egt + 1.96 * cs_es$se.egt
  )
  fwrite(cs_es_df, file.path(data_dir, "cs_event_study.csv"))
}

## -----------------------------------------------------------------------------
## 4. TWFE (for comparison/Goodman-Bacon)
## -----------------------------------------------------------------------------

cat("\n--- TWFE (for comparison) ---\n")

# Annual TWFE
twfe_annual <- feols(
  alc_rate ~ treated | state_fips + YEAR,
  data = state_year,
  cluster = ~state_fips
)

cat("TWFE Annual:\n")
print(summary(twfe_annual))

# TWFE placebo: non-alcohol crash rate
twfe_placebo <- feols(
  non_alc_rate ~ treated | state_fips + YEAR,
  data = state_year,
  cluster = ~state_fips
)

cat("\nTWFE Placebo (non-alcohol rate):\n")
print(summary(twfe_placebo))

# Monthly TWFE
twfe_monthly <- feols(
  alc_rate ~ treated | state_fips + time_id,
  data = state_month,
  cluster = ~state_fips
)

cat("\nTWFE Monthly:\n")
print(summary(twfe_monthly))

## -----------------------------------------------------------------------------
## 5. Event study (fixest)
## -----------------------------------------------------------------------------

cat("\n--- Event Study (fixest) ---\n")

# Create relative time variable
state_month[, rel_month := fifelse(
  is.na(treat_date), NA_integer_,
  as.integer(difftime(as.Date(sprintf("%d-%02d-15", YEAR, MONTH)),
                       treat_date, units = "days") / 30.44)
)]

# Bin endpoints
state_month[, rel_month_binned := pmax(pmin(rel_month, 24L), -24L)]

# Event study with fixest (never-treated as reference)
es_fixest <- feols(
  alc_rate ~ i(rel_month_binned, ever_treated, ref = -1) |
    state_fips + time_id,
  data = state_month[!is.na(rel_month) | ever_treated == 0],
  cluster = ~state_fips
)

cat("Event Study (fixest):\n")
print(summary(es_fixest))

# Extract event study coefficients
es_coefs <- as.data.table(coeftable(es_fixest), keep.rownames = TRUE)
setnames(es_coefs, c("term", "estimate", "se", "t", "p"))
es_coefs[, event_time := as.integer(gsub(".*::(-?\\d+):.*", "\\1", term))]
es_coefs <- es_coefs[!is.na(event_time)]
es_coefs[, `:=`(
  ci_lower = estimate - 1.96 * se,
  ci_upper = estimate + 1.96 * se
)]
fwrite(es_coefs, file.path(data_dir, "fixest_event_study.csv"))

# Pre-trend joint test
pre_coefs <- es_coefs[event_time < -1]
if (nrow(pre_coefs) > 0) {
  pre_f <- wald(es_fixest,
                paste0("rel_month_binned::", pre_coefs$event_time, ":ever_treated"))
  cat(sprintf("\nJoint pre-trend test: F = %.2f, p = %.4f\n",
              pre_f$stat, pre_f$p))
}

## -----------------------------------------------------------------------------
## 6. Save main results
## -----------------------------------------------------------------------------

# Collect main estimates for tables
main_results <- data.table(
  model = c("DDD (Legal×Sunday×NFL)", "DDD Placebo (non-alc)",
            "DDD Nighttime", "DD (Legal×Sunday)",
            "TWFE Annual", "TWFE Placebo", "TWFE Monthly"),
  coef = c(coef(ddd1)["legal_x_sunday_x_nfl"],
           coef(ddd_placebo)["legal_x_sunday_x_nfl"],
           coef(ddd_night)["legal_x_sunday_x_nfl"],
           coef(dd1)["legal_x_sunday"],
           coef(twfe_annual)["treated"],
           coef(twfe_placebo)["treated"],
           coef(twfe_monthly)["treated"]),
  se = c(se(ddd1)["legal_x_sunday_x_nfl"],
         se(ddd_placebo)["legal_x_sunday_x_nfl"],
         se(ddd_night)["legal_x_sunday_x_nfl"],
         se(dd1)["legal_x_sunday"],
         se(twfe_annual)["treated"],
         se(twfe_placebo)["treated"],
         se(twfe_monthly)["treated"]),
  N = c(nobs(ddd1), nobs(ddd_placebo), nobs(ddd_night), nobs(dd1),
        nobs(twfe_annual), nobs(twfe_placebo), nobs(twfe_monthly))
)

main_results[, `:=`(
  t_stat = coef / se,
  p_value = 2 * pnorm(-abs(coef / se)),
  stars = fifelse(2 * pnorm(-abs(coef / se)) < 0.01, "***",
           fifelse(2 * pnorm(-abs(coef / se)) < 0.05, "**",
            fifelse(2 * pnorm(-abs(coef / se)) < 0.10, "*", "")))
)]

fwrite(main_results, file.path(data_dir, "main_results.csv"))

cat("\n=== MAIN RESULTS SUMMARY ===\n")
print(main_results[, .(model, coef = round(coef, 4), se = round(se, 4),
                        t = round(t_stat, 2), stars, N)])

# Save model objects for table generation
save(ddd1, ddd_placebo, ddd_night, dd1,
     twfe_annual, twfe_placebo, twfe_monthly,
     es_fixest,
     file = file.path(data_dir, "main_models.RData"))

if (!is.null(cs_out)) {
  save(cs_out, cs_agg, cs_es, file = file.path(data_dir, "cs_models.RData"))
}

cat("\nMain analysis complete. Models saved to data/main_models.RData\n")
