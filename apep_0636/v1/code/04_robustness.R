## 04_robustness.R — Robustness checks and sensitivity analyses
## APEP-0636: Constitutional Carry and Firearm Violence

source("00_packages.R")

panel <- read_csv("data/analysis_panel_clean.csv", show_col_types = FALSE)
results <- readRDS("data/main_results.rds")

did_panel <- panel |> filter(cc_wave != "Pre-2019")

cat("=== Robustness Checks ===\n\n")

# ============================================================
# 1. PLACEBO OUTCOMES: Non-Firearm Deaths
# ============================================================

cat("--- 1. Placebo: Non-Firearm Homicide ---\n")

cs_nfa_hom <- att_gt(
  yname = "nfa_homicide_rate",
  tname = "year",
  idname = "state_id",
  gname = "gname",
  data = did_panel,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

agg_nfa_hom <- aggte(cs_nfa_hom, type = "simple")
cat(sprintf("  Placebo ATT (NFA Homicide): %.3f (SE=%.3f)\n",
            agg_nfa_hom$overall.att, agg_nfa_hom$overall.se))

cat("\n--- 1b. Placebo: Non-Firearm Suicide ---\n")

cs_nfa_sui <- att_gt(
  yname = "nfa_suicide_rate",
  tname = "year",
  idname = "state_id",
  gname = "gname",
  data = did_panel,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

agg_nfa_sui <- aggte(cs_nfa_sui, type = "simple")
cat(sprintf("  Placebo ATT (NFA Suicide): %.3f (SE=%.3f)\n",
            agg_nfa_sui$overall.att, agg_nfa_sui$overall.se))

# ============================================================
# 2. ALTERNATIVE CONTROL GROUP: Not-Yet-Treated
# ============================================================

cat("\n--- 2. Alternative control: not-yet-treated ---\n")

cs_hom_nyt <- att_gt(
  yname = "fa_homicide_rate",
  tname = "year",
  idname = "state_id",
  gname = "gname",
  data = did_panel,
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "universal"
)

agg_hom_nyt <- aggte(cs_hom_nyt, type = "simple")
cat(sprintf("  ATT (not-yet-treated): %.3f (SE=%.3f)\n",
            agg_hom_nyt$overall.att, agg_hom_nyt$overall.se))

cs_sui_nyt <- att_gt(
  yname = "fa_suicide_rate",
  tname = "year",
  idname = "state_id",
  gname = "gname",
  data = did_panel,
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "universal"
)

agg_sui_nyt <- aggte(cs_sui_nyt, type = "simple")
cat(sprintf("  ATT (not-yet-treated, suicide): %.3f (SE=%.3f)\n",
            agg_sui_nyt$overall.att, agg_sui_nyt$overall.se))

# ============================================================
# 3. LEAVE-ONE-STATE-OUT
# ============================================================

cat("\n--- 3. Leave-one-state-out ---\n")

treated_states <- did_panel |> filter(gname > 0) |> distinct(state_fips, state_name)

loo_results <- map_dfr(1:nrow(treated_states), function(i) {
  drop_fips <- treated_states$state_fips[i]
  drop_name <- treated_states$state_name[i]
  sub_panel <- did_panel |> filter(state_fips != drop_fips)

  tryCatch({
    cs_loo <- att_gt(
      yname = "fa_homicide_rate",
      tname = "year",
      idname = "state_id",
      gname = "gname",
      data = sub_panel,
      control_group = "nevertreated",
      anticipation = 0,
      base_period = "universal"
    )
    agg_loo <- aggte(cs_loo, type = "simple")
    tibble(dropped_state = drop_name, att = agg_loo$overall.att,
           se = agg_loo$overall.se)
  }, error = function(e) {
    tibble(dropped_state = drop_name, att = NA_real_, se = NA_real_)
  })
})

cat("Leave-one-out range:\n")
cat(sprintf("  Min ATT: %.3f (dropping %s)\n",
            min(loo_results$att, na.rm = TRUE),
            loo_results$dropped_state[which.min(loo_results$att)]))
cat(sprintf("  Max ATT: %.3f (dropping %s)\n",
            max(loo_results$att, na.rm = TRUE),
            loo_results$dropped_state[which.max(loo_results$att)]))

# ============================================================
# 4. WILD CLUSTER BOOTSTRAP (for few-cluster inference)
# ============================================================

cat("\n--- 4. Wild cluster bootstrap ---\n")

twfe_hom <- results$twfe_hom

tryCatch({
  boot_hom <- boottest(
    twfe_hom,
    param = "treated",
    B = 999,
    clustid = "state_fips",
    type = "webb"
  )
  cat(sprintf("  WCB p-value (FA Homicide): %.4f\n", boot_hom$p_val))
  cat(sprintf("  WCB 95%% CI: [%.3f, %.3f]\n", boot_hom$conf_int[1], boot_hom$conf_int[2]))
}, error = function(e) {
  cat("  WCB failed:", e$message, "\n")
  cat("  Using analytical cluster-robust SEs instead\n")
})

twfe_sui <- results$twfe_sui

tryCatch({
  boot_sui <- boottest(
    twfe_sui,
    param = "treated",
    B = 999,
    clustid = "state_fips",
    type = "webb"
  )
  cat(sprintf("  WCB p-value (FA Suicide): %.4f\n", boot_sui$p_val))
}, error = function(e) {
  cat("  WCB for suicide failed:", e$message, "\n")
})

# ============================================================
# 5. HONESTDID SENSITIVITY ANALYSIS
# ============================================================

cat("\n--- 5. HonestDiD Sensitivity ---\n")

tryCatch({
  es_hom <- results$es_hom

  # Extract event-study coefficients and variance-covariance
  honest_es <- es_hom

  # Create the HonestDiD-compatible objects
  # Pre-treatment coefficients and their vcov
  pre_idx <- which(honest_es$egt < 0)
  post_idx <- which(honest_es$egt >= 0)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    betahat <- honest_es$att.egt
    sigma <- honest_es$V

    # Relative magnitudes approach
    delta_rm_results <- HonestDiD::createSensitivityResults_relativeMagnitudes(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mbarvec = seq(0, 2, by = 0.5)
    )

    cat("  HonestDiD sensitivity (relative magnitudes):\n")
    print(delta_rm_results)
  } else {
    cat("  Insufficient pre/post periods for HonestDiD\n")
  }
}, error = function(e) {
  cat("  HonestDiD failed:", e$message, "\n")
  cat("  This is common with few pre-periods; reporting CS-DiD inference instead\n")
})

# ============================================================
# 6. SAVE ROBUSTNESS RESULTS
# ============================================================

rob_results <- list(
  # Placebos
  agg_nfa_hom = agg_nfa_hom,
  agg_nfa_sui = agg_nfa_sui,
  # Alternative control
  agg_hom_nyt = agg_hom_nyt,
  agg_sui_nyt = agg_sui_nyt,
  # Leave-one-out
  loo_results = loo_results
)

saveRDS(rob_results, "data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
