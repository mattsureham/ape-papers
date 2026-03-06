# ==============================================================================
# 04_robustness.R — Robustness Checks
# APEP apep_0536: FTTH, Polarization, and Misinformation in France
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

# ==============================================================================
# 1. Presidential Elections Only (cleanest comparison)
# ==============================================================================

cat("=== 1. Presidential Elections Only ===\n")

pres_panel <- panel[election_type == "pres"]
cat("  Presidential obs:", nrow(pres_panel), "\n")

twfe_pres <- feols(
  antisystem_share ~ ftth_coverage | dept_id + election_id,
  data = pres_panel,
  cluster = ~dept_code
)
cat("  TWFE (pres only):", sprintf("%.4f (%.4f), p=%.3f",
    coef(twfe_pres)[1], se(twfe_pres)[1], fixest::pvalue(twfe_pres)[1]), "\n")

# ==============================================================================
# 2. European Elections Only
# ==============================================================================

cat("\n=== 2. European Elections Only ===\n")

euro_panel <- panel[election_type == "euro"]
cat("  European obs:", nrow(euro_panel), "\n")

twfe_euro <- feols(
  antisystem_share ~ ftth_coverage | dept_id + election_id,
  data = euro_panel,
  cluster = ~dept_code
)
cat("  TWFE (euro only):", sprintf("%.4f (%.4f), p=%.3f",
    coef(twfe_euro)[1], se(twfe_euro)[1], fixest::pvalue(twfe_euro)[1]), "\n")

# ==============================================================================
# 3. Alternative Treatment Thresholds
# ==============================================================================

cat("\n=== 3. Alternative Treatment Thresholds ===\n")

for (thresh in c("treated_25", "treated_50", "treated_75")) {
  fml <- as.formula(paste("antisystem_share ~", thresh, "| dept_id + election_id"))
  mod <- feols(fml, data = panel, cluster = ~dept_code)
  cat("  ", thresh, ":", sprintf("%.4f (%.4f), p=%.3f",
      coef(mod)[1], se(mod)[1], fixest::pvalue(mod)[1]), "\n")
}

# ==============================================================================
# 4. Election-Type × Time FE (absorb type-specific trends)
# ==============================================================================

cat("\n=== 4. Election-Type × Time FE ===\n")

panel[, type_year := paste(election_type, election_year, sep = "_")]
panel[, type_year_id := as.integer(factor(type_year))]

twfe_typefe <- feols(
  antisystem_share ~ ftth_coverage | dept_id + type_year_id,
  data = panel,
  cluster = ~dept_code
)
cat("  TWFE with type×year FE:", sprintf("%.4f (%.4f), p=%.3f",
    coef(twfe_typefe)[1], se(twfe_typefe)[1], fixest::pvalue(twfe_typefe)[1]), "\n")

# ==============================================================================
# 5. Placebo: Pensioner-Oriented Outcomes
# ==============================================================================

cat("\n=== 5. Placebo Tests ===\n")

# Placebo 1: Blank/null share should not respond to broadband
twfe_placebo_blank <- feols(
  blank_null_share ~ ftth_coverage | dept_id + election_id,
  data = panel,
  cluster = ~dept_code
)
cat("  Placebo (blank/null share):", sprintf("%.4f (%.4f), p=%.3f",
    coef(twfe_placebo_blank)[1], se(twfe_placebo_blank)[1],
    fixest::pvalue(twfe_placebo_blank)[1]), "\n")

# Placebo 2: Pre-FTTH period trends
# Check if FTTH-fast departments already had different trends before 2017
pre_panel <- panel[election_year < 2017]
# Assign "future FTTH speed" — coverage in 2022 as a cross-sectional predictor
ftth_2022 <- fread(file.path(data_dir, "ftth_dept_quarter.csv"))[
  year == 2022 & quarter == 2, .(dept_code, future_ftth = ftth_coverage)]
pre_panel <- merge(pre_panel, ftth_2022, by = "dept_code", all.x = TRUE)

# Regress pre-FTTH anti-system on future FTTH × time
pre_panel[, year_c := election_year - 2007]
placebo_pretrend <- feols(
  antisystem_share ~ future_ftth:year_c | dept_id + election_id,
  data = pre_panel,
  cluster = ~dept_code
)
cat("  Placebo (future FTTH × pre-period time):", sprintf("%.4f (%.4f), p=%.3f",
    coef(placebo_pretrend)[1], se(placebo_pretrend)[1],
    fixest::pvalue(placebo_pretrend)[1]), "\n")

# ==============================================================================
# 6. Controlling for Unemployment
# ==============================================================================

cat("\n=== 6. With Unemployment Controls ===\n")

if ("unemployment_rate" %in% names(panel)) {
  twfe_unemp <- feols(
    antisystem_share ~ ftth_coverage + unemployment_rate | dept_id + election_id,
    data = panel[!is.na(unemployment_rate)],
    cluster = ~dept_code
  )
  cat("  TWFE with unemployment:", sprintf("%.4f (%.4f), p=%.3f",
      coef(twfe_unemp)["ftth_coverage"], se(twfe_unemp)["ftth_coverage"],
      fixest::pvalue(twfe_unemp)["ftth_coverage"]), "\n")
} else {
  cat("  Unemployment data not available.\n")
}

# ==============================================================================
# 7. Leave-One-Department-Out Jackknife
# ==============================================================================

cat("\n=== 7. Jackknife ===\n")

jack_estimates <- numeric(uniqueN(panel$dept_code))
dept_list <- unique(panel$dept_code)
for (i in seq_along(dept_list)) {
  jack_data <- panel[dept_code != dept_list[i]]
  jack_mod <- feols(antisystem_share ~ ftth_coverage | dept_id + election_id,
                    data = jack_data, cluster = ~dept_code)
  jack_estimates[i] <- coef(jack_mod)[1]
}

cat("  Jackknife range: [", sprintf("%.4f", min(jack_estimates)),
    ",", sprintf("%.4f", max(jack_estimates)), "]\n")
cat("  Full sample estimate:", sprintf("%.4f", coef(feols(
  antisystem_share ~ ftth_coverage | dept_id + election_id,
  data = panel, cluster = ~dept_code))[1]), "\n")

jack_dt <- data.table(dept_dropped = dept_list, estimate = jack_estimates)
fwrite(jack_dt, file.path(data_dir, "jackknife_results.csv"))

# ==============================================================================
# 8. Collect All Robustness Results
# ==============================================================================

cat("\n=== Collecting robustness results ===\n")

# Re-estimate models for collecting results with SEs
mod_baseline <- feols(antisystem_share ~ ftth_coverage | dept_id + election_id, panel, cluster=~dept_code)
mod_t25 <- feols(antisystem_share ~ treated_25 | dept_id + election_id, panel, cluster=~dept_code)
mod_t50 <- feols(antisystem_share ~ treated_50 | dept_id + election_id, panel, cluster=~dept_code)
mod_t75 <- feols(antisystem_share ~ treated_75 | dept_id + election_id, panel, cluster=~dept_code)

# Collect results with SEs and p-values
specs <- list(
  list("Baseline (all elections)", mod_baseline),
  list("Presidential only", twfe_pres),
  list("European only", twfe_euro),
  list("Treated $>$25\\%", mod_t25),
  list("Treated $>$50\\%", mod_t50),
  list("Treated $>$75\\%", mod_t75),
  list("Election-type $\\times$ year FE", twfe_typefe),
  list("Placebo: blank/null", twfe_placebo_blank),
  list("Placebo: pre-trend", placebo_pretrend)
)

robustness <- rbindlist(lapply(specs, function(s) {
  data.table(
    specification = s[[1]],
    estimate = coef(s[[2]])[1],
    se = se(s[[2]])[1],
    pvalue = fixest::pvalue(s[[2]])[1],
    n_obs = nobs(s[[2]])
  )
}))

fwrite(robustness, file.path(data_dir, "robustness_results.csv"))

cat("\n04_robustness.R complete.\n")
