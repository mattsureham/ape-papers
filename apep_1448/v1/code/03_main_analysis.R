# 03_main_analysis.R — RDD at the 3.75 star rating threshold
# apep_1448: Medicare Advantage Quality Bonus RDD

source("00_packages.R")

data_dir <- "../data"
panel <- read_csv(file.path(data_dir, "panel_star_ratings.csv"), show_col_types = FALSE)

cat(sprintf("Panel: %d observations, %d years\n", nrow(panel), length(unique(panel$year))))
cat(sprintf("Near threshold (3.25-4.25): %d\n", sum(panel$summary_score >= 3.25 & panel$summary_score <= 4.25)))

# ============================================================================
# 1. McCrary Density Test — is there bunching at 3.75?
# ============================================================================

cat("\n=== McCrary Density Test ===\n")
mccrary <- rddensity(panel$summary_score, c = 3.75)
cat(sprintf("McCrary test p-value: %.4f\n", mccrary$test$p_jk))
cat(sprintf("  T-statistic: %.3f\n", mccrary$test$t_jk))
cat("Interpretation: %s\n",
    ifelse(mccrary$test$p_jk > 0.10, "No evidence of manipulation (good)",
           "Possible bunching — investigate"))

# Save McCrary results
mccrary_results <- list(
  p_value = mccrary$test$p_jk,
  t_stat = mccrary$test$t_jk,
  interpretation = ifelse(mccrary$test$p_jk > 0.10, "no_manipulation", "possible_bunching")
)

# ============================================================================
# 2. Main RDD — Effect of crossing 3.75 threshold on star rating
# ============================================================================

cat("\n=== Main RDD: First Stage (Summary Score → 4+ Star Rating) ===\n")

# First stage: does crossing 3.75 predict getting 4+ star rating?
first_stage <- rdrobust(
  y = panel$star_4plus,
  x = panel$summary_score,
  c = 3.75,
  kernel = "triangular",
  bwselect = "mserd"
)
summary(first_stage)

cat(sprintf("\nFirst stage jump: %.3f (SE: %.3f)\n",
            first_stage$coef[1], first_stage$se[1]))
cat(sprintf("Bandwidth: %.3f\n", first_stage$bws[1,1]))
cat(sprintf("Effective N: %d left, %d right\n",
            first_stage$N_h[1], first_stage$N_h[2]))

# ============================================================================
# 3. RDD on Outcomes — what happens to plans that get 4+ stars?
# ============================================================================
# Since we don't have PBP benefit data merged yet, we examine:
# (a) Whether summary_score distribution shows a jump in density
# (b) Year-over-year score changes (do plans near threshold improve?)

# Examine the "regression to the mean" / "ratchet" effect:
# Plans just below 3.75 in year t — do they improve more in year t+1?

cat("\n=== Score Dynamics Near Threshold ===\n")

# Create lagged panel
panel_sorted <- panel %>%
  arrange(contract_id, year) %>%
  group_by(contract_id) %>%
  mutate(
    score_lead = lead(summary_score),
    score_change = score_lead - summary_score,
    partc_lead = lead(partc_stars)
  ) %>%
  ungroup()

# RDD on score change: do plans just below improve more?
panel_dynamics <- panel_sorted %>%
  filter(!is.na(score_change))

if (nrow(panel_dynamics) > 100) {
  rdd_dynamics <- rdrobust(
    y = panel_dynamics$score_change,
    x = panel_dynamics$summary_score,
    c = 3.75,
    kernel = "triangular",
    bwselect = "mserd"
  )
  cat("\nRDD on next-year score change:\n")
  summary(rdd_dynamics)
}

# ============================================================================
# 4. RDD on enrollment (using contract-level enrollment data)
# ============================================================================
# We can proxy enrollment effects using the number of plan offerings
# But the main story is about the threshold effect itself

# ============================================================================
# 5. Placebo Tests
# ============================================================================

cat("\n=== Placebo Tests at Non-Bonus Thresholds ===\n")

# Placebo at 2.75 (no bonus at 3.0 vs 2.5)
placebo_275 <- rdrobust(
  y = as.integer(panel$partc_stars >= 3),
  x = panel$summary_score,
  c = 2.75,
  kernel = "triangular",
  bwselect = "mserd"
)
cat(sprintf("Placebo at 2.75: coef=%.3f, p=%.3f\n",
            placebo_275$coef[1], placebo_275$pv[1]))

# Placebo at 4.25 (no additional bonus at 4.5 vs 4.0 — both get bonus)
panel_high <- panel %>% filter(summary_score >= 3.5)
placebo_425 <- rdrobust(
  y = as.integer(panel_high$partc_stars >= 4.5),
  x = panel_high$summary_score,
  c = 4.25,
  kernel = "triangular",
  bwselect = "mserd"
)
cat(sprintf("Placebo at 4.25: coef=%.3f, p=%.3f\n",
            placebo_425$coef[1], placebo_425$pv[1]))

# ============================================================================
# 6. Bandwidth Sensitivity
# ============================================================================

cat("\n=== Bandwidth Sensitivity ===\n")
bandwidths <- c(0.10, 0.15, 0.20, 0.25, 0.30, 0.40, 0.50)
bw_results <- data.frame(
  bandwidth = numeric(),
  coef = numeric(),
  se = numeric(),
  pvalue = numeric(),
  n_left = numeric(),
  n_right = numeric()
)

for (bw in bandwidths) {
  rdd_bw <- tryCatch(
    rdrobust(
      y = panel$star_4plus,
      x = panel$summary_score,
      c = 3.75,
      h = bw,
      kernel = "triangular"
    ),
    error = function(e) NULL
  )

  if (!is.null(rdd_bw)) {
    bw_results <- rbind(bw_results, data.frame(
      bandwidth = bw,
      coef = rdd_bw$coef[1],
      se = rdd_bw$se[1],
      pvalue = rdd_bw$pv[1],
      n_left = rdd_bw$N_h[1],
      n_right = rdd_bw$N_h[2]
    ))
  }
}

print(bw_results)

# ============================================================================
# 7. Covariate Balance
# ============================================================================

cat("\n=== Covariate Balance Test ===\n")

# Test whether organization type jumps at threshold
panel <- panel %>%
  mutate(is_local = as.integer(grepl("Local", org_type, ignore.case = TRUE)))

cov_test <- rdrobust(
  y = panel$is_local,
  x = panel$summary_score,
  c = 3.75,
  kernel = "triangular",
  bwselect = "mserd"
)
cat(sprintf("Covariate balance (Local CCP indicator): coef=%.3f, p=%.3f\n",
            cov_test$coef[1], cov_test$pv[1]))

# ============================================================================
# 8. Save diagnostics for validation
# ============================================================================

# Count treated units for diagnostics
n_above <- sum(panel$summary_score >= 3.75 & panel$summary_score <= 3.75 + first_stage$bws[1,1])
n_below <- sum(panel$summary_score < 3.75 & panel$summary_score >= 3.75 - first_stage$bws[1,1])

diagnostics <- list(
  n_treated = n_above,
  n_pre = length(unique(panel$year[panel$year <= 2020])),
  n_obs = nrow(panel),
  n_contracts = length(unique(panel$contract_id)),
  n_years = length(unique(panel$year)),
  mccrary_pvalue = mccrary$test$p_jk,
  first_stage_coef = first_stage$coef[1],
  first_stage_se = first_stage$se[1],
  optimal_bandwidth = first_stage$bws[1,1],
  n_near_threshold = sum(panel$summary_score >= 3.25 & panel$summary_score <= 4.25)
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat(sprintf("\nDiagnostics saved to %s\n", file.path(data_dir, "diagnostics.json")))

# ============================================================================
# 9. Save main results for tables
# ============================================================================

results <- list(
  first_stage = list(
    coef = first_stage$coef[1],
    se = first_stage$se[1],
    pvalue = first_stage$pv[1],
    bw = first_stage$bws[1,1],
    n_left = first_stage$N_h[1],
    n_right = first_stage$N_h[2]
  ),
  mccrary = mccrary_results,
  bandwidth_sensitivity = bw_results,
  dynamics = if (exists("rdd_dynamics")) list(
    coef = rdd_dynamics$coef[1],
    se = rdd_dynamics$se[1],
    pvalue = rdd_dynamics$pv[1]
  ) else NULL,
  placebo_275 = list(coef = placebo_275$coef[1], pvalue = placebo_275$pv[1]),
  placebo_425 = list(coef = placebo_425$coef[1], pvalue = placebo_425$pv[1])
)

write_json(results, file.path(data_dir, "rdd_results.json"), auto_unbox = TRUE)
cat("Results saved.\n")
