# =============================================================================
# 04_robustness.R — Robustness checks and placebo tests
# apep_0605: Asymmetric Resource Curse in US Shale Counties
# =============================================================================

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
panel[, fips := sprintf("%05s", as.character(fips))]
panel[, state_fips := substr(fips, 1, 2)]

load("../data/main_results.RData")

# =============================================================================
# 1. HONESTDID SENSITIVITY ANALYSIS
# =============================================================================

cat("=== HonestDiD Sensitivity Analysis ===\n")

# Extract event study for HonestDiD
# Need original betahat and sigma from CS-DiD
honest_result <- tryCatch({
  # Use the dynamic aggregation results
  betahat <- es_total$att.egt
  sigma <- diag(es_total$se.egt^2)  # Approximate (diagonal) variance

  # Identify pre and post periods
  pre_idx <- which(es_total$egt < 0)
  post_idx <- which(es_total$egt >= 0)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    l_vec <- rep(0, length(betahat))
    # Average post-treatment effect
    l_vec[post_idx] <- 1 / length(post_idx)

    # Relative magnitudes: bound on post-treatment deviation relative to
    # max pre-treatment deviation
    Mbars <- seq(0, 2, by = 0.5)
    honest_res <- HonestDiD::createSensitivityResults_relativeMagnitudes(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mbarvec = Mbars,
      l_vec = l_vec[post_idx]
    )
    cat("HonestDiD bounds computed\n")
    print(honest_res)
    honest_res
  } else {
    cat("Not enough pre/post periods for HonestDiD\n")
    NULL
  }
}, error = function(e) {
  cat("HonestDiD failed:", e$message, "\n")
  NULL
})

# =============================================================================
# 2. PLACEBO OUTCOME: Non-mining employment (mechanism test)
# =============================================================================

cat("\n=== Placebo / Mechanism: Non-mining Employment ===\n")

# If fracking only affects mining directly, non-mining should show smaller/no
# immediate effect but potential Dutch disease or multiplier effects

# Already estimated in main analysis — report here for comparison
cat("Non-mining ATT:", round(agg_nonmining$overall.att, 4),
    "(SE:", round(agg_nonmining$overall.se, 4), ")\n")

# =============================================================================
# 3. ALTERNATIVE CONTROL GROUP: Not-yet-treated
# =============================================================================

cat("\n=== Alternative Control: Not-Yet-Treated ===\n")

cs_nyt <- tryCatch({
  att_gt(
    yname = "log_total_emp",
    tname = "year",
    idname = "county_id",
    gname = "first_treat",
    data = as.data.frame(panel),
    control_group = "notyettreated",
    base_period = "universal",
    clustervars = "state_fips",
    print_details = FALSE
  )
}, error = function(e) {
  cat("Not-yet-treated CS failed:", e$message, "\n")
  NULL
})

if (!is.null(cs_nyt)) {
  agg_nyt <- aggte(cs_nyt, type = "simple")
  cat("ATT (not-yet-treated):", round(agg_nyt$overall.att, 4),
      "(SE:", round(agg_nyt$overall.se, 4), ")\n")
  es_nyt <- aggte(cs_nyt, type = "dynamic", min_e = -10, max_e = 15)
}

# =============================================================================
# 4. EXCLUDING EACH PLAY (leave-one-out)
# =============================================================================

cat("\n=== Leave-One-Out by Play ===\n")

plays <- unique(panel[shale == 1]$play)
loo_results <- data.table()

for (p in plays) {
  cat("  Excluding:", p, "...")
  panel_loo <- panel[play != p | shale == 0]

  cs_loo <- tryCatch({
    att_gt(
      yname = "log_total_emp",
      tname = "year",
      idname = "county_id",
      gname = "first_treat",
      data = as.data.frame(panel_loo),
      control_group = "nevertreated",
      base_period = "universal",
      clustervars = "state_fips",
      print_details = FALSE
    )
  }, error = function(e) {
    cat(" failed:", e$message, "\n")
    NULL
  })

  if (!is.null(cs_loo)) {
    agg_loo <- aggte(cs_loo, type = "simple")
    loo_results <- rbind(loo_results, data.table(
      excluded_play = p,
      att = agg_loo$overall.att,
      se = agg_loo$overall.se,
      n_treated = uniqueN(panel_loo[shale == 1]$fips)
    ))
    cat(" ATT =", round(agg_loo$overall.att, 4), "\n")
  }
}

cat("\nLeave-one-out results:\n")
print(loo_results)

# =============================================================================
# 5. ALTERNATIVE TREATMENT TIMING (+/- 2 years)
# =============================================================================

cat("\n=== Sensitivity to Treatment Timing ===\n")

for (shift in c(-2, 2)) {
  cat("  Shift =", shift, "years...")
  panel_shift <- copy(panel)
  panel_shift[first_treat > 0, first_treat := first_treat + shift]

  cs_shift <- tryCatch({
    att_gt(
      yname = "log_total_emp",
      tname = "year",
      idname = "county_id",
      gname = "first_treat",
      data = as.data.frame(panel_shift),
      control_group = "nevertreated",
      base_period = "universal",
      clustervars = "state_fips",
      print_details = FALSE
    )
  }, error = function(e) {
    cat(" failed:", e$message, "\n")
    NULL
  })

  if (!is.null(cs_shift)) {
    agg_shift <- aggte(cs_shift, type = "simple")
    cat(" ATT =", round(agg_shift$overall.att, 4),
        "(SE:", round(agg_shift$overall.se, 4), ")\n")
  }
}

# =============================================================================
# 6. WILD CLUSTER BOOTSTRAP (for robustness of inference)
# =============================================================================

cat("\n=== Wild Cluster Bootstrap ===\n")

# State-level clustering with only ~30 states having shale counties
# Use fwildclusterboot if available, otherwise skip
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)

  panel[, post_treat := as.integer(first_treat > 0 & year >= first_treat)]
  wcb_fit <- feols(log_total_emp ~ post_treat | county_id + year,
                   data = panel, cluster = ~state_fips)

  wcb_result <- tryCatch({
    boottest(wcb_fit, param = "post_treat", B = 999,
             clustid = ~state_fips, type = "webb")
  }, error = function(e) {
    cat("WCB failed:", e$message, "\n")
    NULL
  })

  if (!is.null(wcb_result)) {
    cat("WCB p-value:", round(wcb_result$p_val, 4), "\n")
  }
} else {
  cat("fwildclusterboot not available — skipping WCB\n")
}

# =============================================================================
# 7. SAVE ROBUSTNESS RESULTS
# =============================================================================

rob_results <- list(
  loo = loo_results,
  honest = if (exists("honest_result")) honest_result else NULL,
  nyt_att = if (exists("agg_nyt")) agg_nyt$overall.att else NA
)

save(rob_results, loo_results, honest_result,
     file = "../data/robustness_results.RData")

cat("\nRobustness checks complete.\n")
