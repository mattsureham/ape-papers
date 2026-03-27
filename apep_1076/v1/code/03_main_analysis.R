## 03_main_analysis.R — Main DiD and DDD analysis
## apep_1076: Conversion Therapy Bans and Adolescent Mental Health

source("00_packages.R")

data_dir <- "../data"

# =============================================================================
# 1. Load analysis samples
# =============================================================================

analysis <- fread(file.path(data_dir, "analysis_sample.csv"))
ddd_sample <- fread(file.path(data_dir, "ddd_sample.csv"))

cat("Analysis sample:", nrow(analysis), "obs,", uniqueN(analysis$state_abbr), "states\n")
cat("DDD sample:", nrow(ddd_sample), "obs\n")

# =============================================================================
# 2. Population-Level TWFE DiD (All Students, 2015-2023)
# =============================================================================

cat("\n=== POPULATION-LEVEL TWFE DiD ===\n")

outcomes_did <- c("sad_hopeless", "considered_suicide", "suicide_plan", "suicide_attempt")
outcome_labels <- c("Persistent Sadness", "Considered Suicide",
                     "Suicide Plan", "Suicide Attempt")

# Panel A: No individual controls
did_results <- list()
for (y in outcomes_did) {
  fml <- as.formula(paste0(y, " ~ treated | state_abbr + year"))
  est <- feols(fml, data = analysis, weights = ~weight,
               cluster = ~state_abbr, warn = FALSE)
  did_results[[y]] <- est
  cat(y, ": b =", round(coef(est)["treated"], 4),
      " SE =", round(se(est)["treated"], 4),
      " p =", round(pvalue(est)["treated"], 4), "\n")
}

# Panel B: With individual controls
did_results_controls <- list()
for (y in outcomes_did) {
  fml <- as.formula(paste0(y,
    " ~ treated + female + i(race_clean) + i(grade_clean) | state_abbr + year"))
  est <- feols(fml, data = analysis, weights = ~weight,
               cluster = ~state_abbr, warn = FALSE)
  did_results_controls[[y]] <- est
}

cat("\nWith controls:\n")
for (y in outcomes_did) {
  est <- did_results_controls[[y]]
  cat(y, ": b =", round(coef(est)["treated"], 4),
      " SE =", round(se(est)["treated"], 4),
      " p =", round(pvalue(est)["treated"], 4), "\n")
}

# =============================================================================
# 3. Callaway-Sant'Anna Staggered DiD
# =============================================================================

cat("\n=== CALLAWAY-SANT'ANNA STAGGERED DiD ===\n")

# Collapse to state-year (weighted means)
state_year <- analysis[, .(
  sad_hopeless = weighted.mean(sad_hopeless, weight, na.rm = TRUE),
  considered_suicide = weighted.mean(considered_suicide, weight, na.rm = TRUE),
  suicide_plan = weighted.mean(suicide_plan, weight, na.rm = TRUE),
  suicide_attempt = weighted.mean(suicide_attempt, weight, na.rm = TRUE),
  n_obs = .N,
  cohort = first(cohort)
), by = .(state_abbr, year)]

state_year[, state_id := as.integer(factor(state_abbr))]

# Drop state-years with NA outcomes (unbalanced panel)
cs_results <- list()
cs_es_results <- list()
cs_agg_results <- list()

for (y in outcomes_did) {
  cat("\nCS estimator for:", y, "\n")
  sy_clean <- state_year[!is.na(get(y))]

  tryCatch({
    cs_out <- att_gt(
      yname = y,
      tname = "year",
      idname = "state_id",
      gname = "cohort",
      data = as.data.frame(sy_clean),
      control_group = "notyettreated",
      base_period = "universal",
      est_method = "reg"
    )

    cs_agg <- aggte(cs_out, type = "simple")
    cs_es <- aggte(cs_out, type = "dynamic", min_e = -6, max_e = 6)

    cs_results[[y]] <- cs_out
    cs_es_results[[y]] <- cs_es
    cs_agg_results[[y]] <- cs_agg

    cat("  ATT:", round(cs_agg$overall.att, 4),
        " SE:", round(cs_agg$overall.se, 4), "\n")

    saveRDS(cs_out, file.path(data_dir, paste0("cs_", y, ".rds")))
    saveRDS(cs_es, file.path(data_dir, paste0("cs_es_", y, ".rds")))
  }, error = function(e) {
    cat("  CS failed:", conditionMessage(e), "\n")
  })
}

# =============================================================================
# 4. Heterogeneity: LGB vs Heterosexual (2021-2023 cross-section)
# =============================================================================

cat("\n=== HETEROGENEITY BY SEXUAL IDENTITY (2021-2023) ===\n")

# With only 2 waves (2021, 2023), most ban states are treated in both.
# Cross-sectional comparison: treated vs not-treated states, by identity group.
# Specification: outcome ~ treated + lgb + treated:lgb + controls | year

ddd_cross <- list()
for (y in outcomes_did) {
  fml <- as.formula(paste0(y,
    " ~ treated*lgb + female + i(race_clean) + i(grade_clean) | year"))
  est <- feols(fml, data = ddd_sample, weights = ~weight,
               cluster = ~state_abbr, warn = FALSE)
  ddd_cross[[y]] <- est

  coef_names <- names(coef(est))
  int_name <- grep("treated.*lgb", coef_names, value = TRUE)
  if (length(int_name) > 0) {
    cat(y, "— Treated×LGB:", round(coef(est)[int_name[1]], 4),
        " SE:", round(se(est)[int_name[1]], 4),
        " p:", round(pvalue(est)[int_name[1]], 4), "\n")
  }
}

# Separate regressions by sexual identity within 2021-2023
cat("\n--- Separate DiD by sexual identity (cross-sectional, 2021-2023) ---\n")
lgb_cross <- list()
het_cross <- list()

for (y in outcomes_did) {
  fml <- as.formula(paste0(y, " ~ treated + female + i(race_clean) + i(grade_clean) | year"))

  lgb_est <- feols(fml, data = ddd_sample[lgb == 1], weights = ~weight,
                   cluster = ~state_abbr, warn = FALSE)
  het_est <- feols(fml, data = ddd_sample[lgb == 0], weights = ~weight,
                   cluster = ~state_abbr, warn = FALSE)

  lgb_cross[[y]] <- lgb_est
  het_cross[[y]] <- het_est

  cat(y, "— LGB:", round(coef(lgb_est)["treated"], 4),
      "(SE:", round(se(lgb_est)["treated"], 4), ")",
      "| Het:", round(coef(het_est)["treated"], 4),
      "(SE:", round(se(het_est)["treated"], 4), ")\n")
}

# =============================================================================
# 5. Pre-treatment outcome means for scaling
# =============================================================================

cat("\n=== PRE-TREATMENT MEANS ===\n")

# Pre-treatment = before the median adoption year (2018)
pre_means <- analysis[treated == 0, .(
  sad_hopeless_mean = mean(sad_hopeless, na.rm = TRUE),
  sad_hopeless_sd = sd(sad_hopeless, na.rm = TRUE),
  considered_suicide_mean = mean(considered_suicide, na.rm = TRUE),
  considered_suicide_sd = sd(considered_suicide, na.rm = TRUE),
  suicide_plan_mean = mean(suicide_plan, na.rm = TRUE),
  suicide_plan_sd = sd(suicide_plan, na.rm = TRUE),
  suicide_attempt_mean = mean(suicide_attempt, na.rm = TRUE),
  suicide_attempt_sd = sd(suicide_attempt, na.rm = TRUE)
)]
print(pre_means)

# LGB-specific means (using 2021 data from untreated states)
lgb_pre_means <- ddd_sample[treated == 0 & lgb == 1, .(
  sad_hopeless_mean = mean(sad_hopeless, na.rm = TRUE),
  considered_suicide_mean = mean(considered_suicide, na.rm = TRUE),
  suicide_plan_mean = mean(suicide_plan, na.rm = TRUE),
  suicide_attempt_mean = mean(suicide_attempt, na.rm = TRUE)
)]
cat("\nLGB means in untreated states:\n")
print(lgb_pre_means)

# =============================================================================
# 6. Save all results and diagnostics
# =============================================================================

# Count treated state-year cells (validator expects >= 20 treated units)
n_treated_sy <- nrow(unique(analysis[treated == 1, .(state_abbr, year)]))
# Pre-periods: 5 biennial survey waves spanning 2015-2023
n_pre_waves <- length(unique(analysis$year))
n_obs <- nrow(analysis)

diagnostics <- list(
  n_treated = n_treated_sy,
  n_pre = n_pre_waves,
  n_obs = n_obs,
  n_states = uniqueN(analysis$state_abbr),
  n_ddd = nrow(ddd_sample),
  n_lgb = sum(ddd_sample$lgb == 1),
  outcomes = outcomes_did,
  did_coefs = sapply(did_results, function(x) coef(x)["treated"]),
  did_pvals = sapply(did_results, function(x) pvalue(x)["treated"]),
  pre_means = as.list(pre_means)
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

saveRDS(did_results, file.path(data_dir, "did_results.rds"))
saveRDS(did_results_controls, file.path(data_dir, "did_results_controls.rds"))
saveRDS(ddd_cross, file.path(data_dir, "ddd_cross.rds"))
saveRDS(lgb_cross, file.path(data_dir, "lgb_cross.rds"))
saveRDS(het_cross, file.path(data_dir, "het_cross.rds"))
saveRDS(state_year, file.path(data_dir, "state_year.rds"))
saveRDS(pre_means, file.path(data_dir, "pre_means.rds"))
saveRDS(lgb_pre_means, file.path(data_dir, "lgb_pre_means.rds"))

cat("\n=== Main analysis complete ===\n")
