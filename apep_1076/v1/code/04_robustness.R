## 04_robustness.R — Robustness checks and event study
## apep_1076: Conversion Therapy Bans and Adolescent Mental Health

source("00_packages.R")

data_dir <- "../data"

analysis <- fread(file.path(data_dir, "analysis_sample.csv"))
state_year <- readRDS(file.path(data_dir, "state_year.rds"))

outcomes <- c("sad_hopeless", "considered_suicide", "suicide_plan", "suicide_attempt")

# =============================================================================
# 1. Callaway-Sant'Anna with na.rm = TRUE
# =============================================================================

cat("\n=== CALLAWAY-SANT'ANNA (FIXED) ===\n")

cs_results <- list()
cs_es_results <- list()

for (y in outcomes) {
  cat("\nCS estimator for:", y, "\n")
  sy_clean <- state_year[!is.na(get(y)) & is.finite(get(y))]

  # Ensure balanced-ish panel: keep state-years with data
  tryCatch({
    cs_out <- att_gt(
      yname = y,
      tname = "year",
      idname = "state_id",
      gname = "cohort",
      data = as.data.frame(sy_clean),
      control_group = "notyettreated",
      base_period = "universal",
      est_method = "reg",
      allow_unbalanced_panel = TRUE
    )

    cs_agg <- aggte(cs_out, type = "simple")
    cat("  ATT:", round(cs_agg$overall.att, 4),
        " SE:", round(cs_agg$overall.se, 4), "\n")

    cs_es <- aggte(cs_out, type = "dynamic", min_e = -4, max_e = 6)

    cs_results[[y]] <- list(gt = cs_out, agg = cs_agg)
    cs_es_results[[y]] <- cs_es

    saveRDS(cs_es, file.path(data_dir, paste0("cs_es_", y, ".rds")))
  }, error = function(e) {
    cat("  CS error:", conditionMessage(e), "\n")
  })
}

# =============================================================================
# 2. TWFE Event Study (relative time to treatment)
# =============================================================================

cat("\n=== TWFE EVENT STUDY ===\n")

# Create event time relative to ban year
analysis[, rel_time := fifelse(is.finite(ban_year),
                                as.integer(year - ban_year),
                                NA_integer_)]

# Bin extremes
analysis[rel_time < -6, rel_time := -6L]
analysis[rel_time > 8, rel_time := 8L]

# Never-treated states: assign a ref category that will be absorbed
# fixest's i() with ref argument handles this cleanly

es_results <- list()
for (y in outcomes) {
  cat("\nEvent study for:", y, "\n")

  # Only use treated states (never-treated have no meaningful event time)
  treated_data <- analysis[is.finite(ban_year)]

  fml <- as.formula(paste0(y,
    " ~ i(rel_time, ref = -2) + female + i(race_clean) + i(grade_clean) | state_abbr + year"))

  est <- feols(fml, data = treated_data, weights = ~weight,
               cluster = ~state_abbr, warn = FALSE)

  es_results[[y]] <- est
}

saveRDS(es_results, file.path(data_dir, "es_results.rds"))

# =============================================================================
# 3. Placebo: Bullying outcomes (should NOT be affected by bans)
# =============================================================================

cat("\n=== PLACEBO: BULLYING OUTCOMES ===\n")

# Conversion therapy bans should not directly affect bullying rates
# If we see effects on bullying, it suggests confounding
ddd_sample <- fread(file.path(data_dir, "ddd_sample.csv"))

for (y in c("bullied_school", "bullied_electronic")) {
  fml <- as.formula(paste0(y,
    " ~ treated + female + i(race_clean) + i(grade_clean) | state_abbr + year"))
  est <- feols(fml, data = analysis, weights = ~weight,
               cluster = ~state_abbr, warn = FALSE)
  cat(y, ": b =", round(coef(est)["treated"], 4),
      " SE =", round(se(est)["treated"], 4),
      " p =", round(pvalue(est)["treated"], 4), "\n")
}

# =============================================================================
# 4. Heterogeneity by sex
# =============================================================================

cat("\n=== HETEROGENEITY BY SEX ===\n")

for (y in outcomes) {
  fml_f <- as.formula(paste0(y, " ~ treated + i(race_clean) + i(grade_clean) | state_abbr + year"))
  fml_m <- fml_f

  est_f <- feols(fml_f, data = analysis[female == 1], weights = ~weight,
                 cluster = ~state_abbr, warn = FALSE)
  est_m <- feols(fml_m, data = analysis[female == 0], weights = ~weight,
                 cluster = ~state_abbr, warn = FALSE)

  cat(y, "— Female:", round(coef(est_f)["treated"], 4),
      "(p =", round(pvalue(est_f)["treated"], 4), ")",
      "| Male:", round(coef(est_m)["treated"], 4),
      "(p =", round(pvalue(est_m)["treated"], 4), ")\n")
}

# =============================================================================
# 5. Drop early adopters (CA, NJ with limited pre-periods)
# =============================================================================

cat("\n=== SENSITIVITY: DROP EARLY ADOPTERS ===\n")

analysis_late <- analysis[!(state_abbr %in% c("CA", "NJ"))]

for (y in outcomes) {
  fml <- as.formula(paste0(y,
    " ~ treated + female + i(race_clean) + i(grade_clean) | state_abbr + year"))
  est <- feols(fml, data = analysis_late, weights = ~weight,
               cluster = ~state_abbr, warn = FALSE)
  cat(y, ": b =", round(coef(est)["treated"], 4),
      " SE =", round(se(est)["treated"], 4),
      " p =", round(pvalue(est)["treated"], 4), "\n")
}

# =============================================================================
# 6. Leave-one-out: drop each treated state
# =============================================================================

cat("\n=== LEAVE-ONE-OUT (treated states) ===\n")

treated_states <- unique(analysis[treated == 1, state_abbr])
loo_results <- data.table()

y <- "sad_hopeless"  # Primary outcome
for (st in treated_states) {
  fml <- as.formula(paste0(y, " ~ treated | state_abbr + year"))
  est <- feols(fml, data = analysis[state_abbr != st], weights = ~weight,
               cluster = ~state_abbr, warn = FALSE)
  loo_results <- rbind(loo_results, data.table(
    dropped = st,
    coef = coef(est)["treated"],
    se = se(est)["treated"]
  ))
}

cat("Sad/hopeless — Leave-one-out range:\n")
cat("  Min:", round(min(loo_results$coef), 4),
    " Max:", round(max(loo_results$coef), 4),
    " (Full sample: -0.025)\n")
print(loo_results[order(coef)])

saveRDS(loo_results, file.path(data_dir, "loo_results.rds"))

cat("\n=== Robustness checks complete ===\n")
