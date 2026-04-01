# =============================================================================
# 04_robustness.R — Robustness checks
# Minimum Wages and the Racial Hiring Gap (apep_1277)
# =============================================================================

source("00_packages.R")
data_dir <- "../data/"

analysis_state <- readRDS(paste0(data_dir, "analysis_state.rds"))
analysis_county <- readRDS(paste0(data_dir, "analysis_county.rds"))
analysis_industry <- readRDS(paste0(data_dir, "analysis_industry.rds"))

tables_dir <- "../tables/"

# =============================================================================
# 1. Placebo: High-wage industries (NAICS 54, 52) — MW shouldn't bind
# =============================================================================
cat("Running placebo: high-wage industries...\n")

placebo_highwage <- feols(
  log_hires ~ black:post | state_fips^race + time_id,
  data = analysis_industry %>% filter(industry %in% c("54", "52")),
  cluster = ~state_fips
)
cat("Placebo (professional services + finance):\n")
print(coeftable(placebo_highwage))

# =============================================================================
# 2. Alternative: Employment (not just hires)
# =============================================================================
cat("\nRunning with log employment as outcome...\n")

emp_ddd <- feols(
  log(pmax(emp, 1)) ~ black:post:high_bite + black:post + black:high_bite + post:high_bite |
    county_fips^race + time_id,
  data = analysis_county,
  cluster = ~state_fips
)
cat("Employment DDD:\n")
print(coeftable(emp_ddd))

# =============================================================================
# 3. Leave-one-out state analysis
# =============================================================================
cat("\nRunning leave-one-out state analysis...\n")

# Main DDD coefficient from full sample for reference
ddd_full <- feols(
  log_hires ~ black:post:high_bite + black:post + black:high_bite + post:high_bite |
    county_fips^race + time_id,
  data = analysis_county,
  cluster = ~state_fips
)

# Get the triple interaction coefficient name
coef_names <- names(coef(ddd_full))
triple_name <- grep("black.*post.*high_bite|high_bite.*post.*black", coef_names, value = TRUE)[1]

loo_results <- data.frame(
  excluded_state = character(),
  coef = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

treated_states <- unique(analysis_county$state_fips[analysis_county$first_treat_time > 0])

for (st in treated_states) {
  loo_fit <- tryCatch({
    feols(
      log_hires ~ black:post:high_bite + black:post + black:high_bite + post:high_bite |
        county_fips^race + time_id,
      data = analysis_county %>% filter(state_fips != st),
      cluster = ~state_fips
    )
  }, error = function(e) NULL)

  if (!is.null(loo_fit) && !is.null(triple_name) && triple_name %in% names(coef(loo_fit))) {
    loo_results <- rbind(loo_results, data.frame(
      excluded_state = st,
      coef = coef(loo_fit)[triple_name],
      se = se(loo_fit)[triple_name],
      stringsAsFactors = FALSE
    ))
  }
}

cat("Leave-one-out: DDD triple interaction\n")
cat(sprintf("  Full sample: %.4f\n", coef(ddd_full)[triple_name]))
cat(sprintf("  LOO range: [%.4f, %.4f]\n", min(loo_results$coef), max(loo_results$coef)))
cat(sprintf("  LOO mean: %.4f\n", mean(loo_results$coef)))

# =============================================================================
# 4. State-level trends robustness
# =============================================================================
cat("\nRunning with state-specific linear trends...\n")

trends_ddd <- tryCatch({
  feols(
    log_hires ~ black:post:high_bite + black:post + black:high_bite + post:high_bite |
      county_fips^race + time_id + state_fips[time_id],
    data = analysis_county,
    cluster = ~state_fips
  )
}, error = function(e) {
  cat("  State trends model failed:", e$message, "\n")
  NULL
})

if (!is.null(trends_ddd)) {
  cat("State trends DDD:\n")
  print(coeftable(trends_ddd))
}

# =============================================================================
# Save robustness results
# =============================================================================
saveRDS(list(
  placebo = placebo_highwage,
  emp_ddd = emp_ddd,
  loo = loo_results,
  trends = trends_ddd,
  ddd_full = ddd_full
), paste0(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
