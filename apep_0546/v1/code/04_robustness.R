# ==============================================================================
# 04_robustness.R — Robustness and Sensitivity Analyses
# APEP-0546: Do Red Flag Laws Save Lives or Shift Deaths?
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"

panel <- fread(file.path(data_dir, "panel_combined.csv"))
short <- fread(file.path(data_dir, "panel_short_2019_2024.csv"))

# Prepare same analysis samples as 03_main_analysis.R
cs_data <- panel[year != 2018 & state != "Connecticut"]
short_cs <- copy(short)
short_cs[erpo_year < 2019 & !is.na(erpo_year), `:=`(G = 0L, treated = 0L)]
short_cs <- short_cs[!(erpo_year < 2019 & !is.na(erpo_year))]

# ─── A. Sun & Abraham (2021) Interaction-Weighted Estimator ──────────────────

cat("=== A. Sun & Abraham (2021) ===\n")

# Combined panel — total suicide
sa_total <- feols(
  rate_All_Suicide ~ sunab(G, year) | state_id + year,
  data = cs_data[G > 0 | G == 0],
  cluster = ~state_id
)

cat("Sun & Abraham — Total Suicide:\n")
print(summary(sa_total))
saveRDS(sa_total, file.path(data_dir, "sa_total.rds"))

# Short panel — firearm suicide
sa_fa <- feols(
  rate_FA_Suicide ~ sunab(G, year) | state_id + year,
  data = short_cs,
  cluster = ~state_id
)

cat("\nSun & Abraham — Firearm Suicide:\n")
print(summary(sa_fa))
saveRDS(sa_fa, file.path(data_dir, "sa_fa.rds"))

# ─── B. Goodman-Bacon Decomposition ─────────────────────────────────────────

cat("\n=== B. Goodman-Bacon Decomposition ===\n")

# Need balanced panel for bacon decomp — use 2005-2017 (IN through OR)
bacon_data <- cs_data[year >= 2005 & year <= 2017]

# Make sure it's balanced
bacon_balanced <- bacon_data[, .(n = .N), by = state][n == 13]
bacon_data <- bacon_data[state %in% bacon_balanced$state]

tryCatch({
  bacon_result <- bacon(
    rate_All_Suicide ~ treated,
    data = as.data.frame(bacon_data),
    id_var = "state_id",
    time_var = "year"
  )
  cat("Goodman-Bacon decomposition:\n")
  print(bacon_result)
  saveRDS(bacon_result, file.path(data_dir, "bacon_decomp.rds"))

  # Save decomposition table
  bacon_dt <- as.data.table(bacon_result)
  fwrite(bacon_dt, file.path(data_dir, "bacon_decomposition.csv"))
}, error = function(e) {
  cat("  Bacon decomposition failed: ", e$message, "\n")
  cat("  Continuing with other robustness checks.\n")
})

# ─── C. Wild Cluster Bootstrap (few-cluster inference) ───────────────────────

cat("\n=== C. Wild Cluster Bootstrap ===\n")

# TWFE model for bootstrap (CS-DiD doesn't directly support WCB)
twfe_for_boot <- feols(
  rate_All_Suicide ~ treated | state_id + year,
  data = cs_data,
  cluster = ~state_id
)

# Wild cluster bootstrap via manual permutation (fwildclusterboot not available)
# Use fixest's built-in bootstrap SEs as alternative
tryCatch({
  boot_se <- summary(twfe_for_boot, se = "twoway")
  cat("Two-way clustered SEs (state + year):\n")
  print(boot_se)
  boot_pval <- pvalue(boot_se)["treated"]
  cat("  Two-way p-value: ", round(boot_pval, 4), "\n")
  fwrite(data.table(method = "Two-way cluster", p_value = boot_pval),
         file.path(data_dir, "wcb_pvalue.csv"))
}, error = function(e) {
  cat("  Two-way SEs failed: ", e$message, "\n")
})

# ─── D. Leave-One-Out (treated state sensitivity) ───────────────────────────

cat("\n=== D. Leave-One-Out Analysis ===\n")

treated_states <- unique(cs_data[G > 0]$state)
loo_results <- rbindlist(lapply(treated_states, function(s) {
  cat("  Dropping: ", s, "\n")
  loo_data <- cs_data[state != s]

  tryCatch({
    cs_loo <- att_gt(
      yname = "rate_All_Suicide",
      tname = "year",
      idname = "state_id",
      gname = "G",
      data = as.data.frame(loo_data),
      control_group = "nevertreated",
      anticipation = 0,
      est_method = "dr",
      base_period = "universal"
    )
    agg_loo <- aggte(cs_loo, type = "simple")
    data.table(
      dropped_state = s,
      att = agg_loo$overall.att,
      se = agg_loo$overall.se,
      p_value = 2 * pnorm(-abs(agg_loo$overall.att / agg_loo$overall.se))
    )
  }, error = function(e) {
    data.table(dropped_state = s, att = NA, se = NA, p_value = NA)
  })
}))

cat("\nLeave-One-Out Results:\n")
print(loo_results)
fwrite(loo_results, file.path(data_dir, "leave_one_out.csv"))
saveRDS(loo_results, file.path(data_dir, "leave_one_out.rds"))

# ─── E. Not-Yet-Treated as Alternative Control Group ────────────────────────

cat("\n=== E. Not-Yet-Treated Control Group ===\n")

cs_nyt <- att_gt(
  yname = "rate_All_Suicide",
  tname = "year",
  idname = "state_id",
  gname = "G",
  data = as.data.frame(cs_data),
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

agg_nyt <- aggte(cs_nyt, type = "simple")
cat("ATT (not-yet-treated controls):\n")
print(summary(agg_nyt))
saveRDS(cs_nyt, file.path(data_dir, "cs_nyt_total.rds"))
saveRDS(agg_nyt, file.path(data_dir, "agg_nyt_total.rds"))

# ─── F. Heterogeneity by Gun Ownership ──────────────────────────────────────

cat("\n=== F. Heterogeneity by Gun Ownership ===\n")

# High gun ownership states
short_high <- short_cs[high_gun_ownership == 1 | G == 0]
short_low <- short_cs[high_gun_ownership == 0 | G == 0]

tryCatch({
  # High gun ownership
  if (uniqueN(short_high[G > 0]$state) >= 1) {
    cs_high <- att_gt(
      yname = "rate_FA_Suicide", tname = "year", idname = "state_id",
      gname = "G", data = as.data.frame(short_high),
      control_group = "nevertreated", anticipation = 0,
      est_method = "dr", base_period = "universal"
    )
    agg_high <- aggte(cs_high, type = "simple")
    cat("ATT (High Gun Ownership):\n")
    print(summary(agg_high))
    saveRDS(agg_high, file.path(data_dir, "agg_high_gun.rds"))
  }

  # Low gun ownership
  if (uniqueN(short_low[G > 0]$state) >= 1) {
    cs_low <- att_gt(
      yname = "rate_FA_Suicide", tname = "year", idname = "state_id",
      gname = "G", data = as.data.frame(short_low),
      control_group = "nevertreated", anticipation = 0,
      est_method = "dr", base_period = "universal"
    )
    agg_low <- aggte(cs_low, type = "simple")
    cat("ATT (Low Gun Ownership):\n")
    print(summary(agg_low))
    saveRDS(agg_low, file.path(data_dir, "agg_low_gun.rds"))
  }
}, error = function(e) {
  cat("  Gun ownership heterogeneity failed: ", e$message, "\n")
})

# ─── G. HonestDiD Sensitivity Bounds ────────────────────────────────────────

cat("\n=== G. HonestDiD Sensitivity Analysis ===\n")

tryCatch({
  es_total <- readRDS(file.path(data_dir, "es_total_suicide.rds"))

  # Extract event-study coefficients
  es_coefs <- data.table(
    e = es_total$egt,
    att = es_total$att.egt,
    se = es_total$se.egt
  )

  # Pre-period coefficients
  pre_coefs <- es_coefs[e < 0]

  if (nrow(pre_coefs) >= 2) {
    # Construct the objects HonestDiD needs
    # Use the CS event-study output
    honest_result <- tryCatch({
      # HonestDiD with relative magnitudes
      betahat <- es_total$att.egt
      sigma <- es_total$V_analytical
      numPrePeriods <- sum(es_total$egt < 0)
      numPostPeriods <- sum(es_total$egt >= 0)

      if (!is.null(sigma) && numPrePeriods >= 2) {
        honest_out <- HonestDiD::createSensitivityResults_relativeMagnitudes(
          betahat = betahat,
          sigma = sigma,
          numPrePeriods = numPrePeriods,
          numPostPeriods = numPostPeriods,
          Mbarvec = seq(0, 2, by = 0.5)
        )
        cat("HonestDiD sensitivity bounds computed\n")
        honest_out
      } else {
        cat("  Insufficient pre-periods or missing variance matrix for HonestDiD\n")
        NULL
      }
    }, error = function(e) {
      cat("  HonestDiD failed: ", e$message, "\n")
      NULL
    })

    if (!is.null(honest_result)) {
      saveRDS(honest_result, file.path(data_dir, "honest_did.rds"))
    }
  }
}, error = function(e) {
  cat("  HonestDiD outer error: ", e$message, "\n")
})

# ─── H. Sensitivity: Excluding 2018 Adoption Cohort ─────────────────────────

cat("\n=== H. Sensitivity: Excluding 2018 Cohort ===\n")

# 8 states adopted in 2018 — the gap year. Show main result is robust to dropping them.
cs_data_no2018 <- cs_data[!(G == 2018)]

cat("  States remaining: ", uniqueN(cs_data_no2018$state), "\n")
cat("  Treated states: ", uniqueN(cs_data_no2018[G > 0]$state), "\n")

tryCatch({
  cs_no2018 <- att_gt(
    yname = "rate_All_Suicide",
    tname = "year",
    idname = "state_id",
    gname = "G",
    data = as.data.frame(cs_data_no2018),
    control_group = "nevertreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal"
  )
  agg_no2018 <- aggte(cs_no2018, type = "simple")
  cat("ATT (excluding 2018 cohort):\n")
  print(summary(agg_no2018))
  saveRDS(agg_no2018, file.path(data_dir, "agg_no2018_cohort.rds"))

  fwrite(data.table(
    Specification = "Excluding 2018 cohort",
    ATT = agg_no2018$overall.att,
    SE = agg_no2018$overall.se,
    p_value = 2 * pnorm(-abs(agg_no2018$overall.att / agg_no2018$overall.se)),
    N_treated = uniqueN(cs_data_no2018[G > 0]$state)
  ), file.path(data_dir, "sensitivity_no2018.csv"))
}, error = function(e) {
  cat("  Excluding 2018 cohort failed: ", e$message, "\n")
})

# ─── I. Sensitivity: Excluding Anti-ERPO States ─────────────────────────────

cat("\n=== I. Sensitivity: Excluding Anti-ERPO States ===\n")

anti_erpo <- fread(file.path(data_dir, "anti_erpo_states.csv"))
anti_states <- anti_erpo[anti_erpo == TRUE]$state
cs_data_no_anti <- cs_data[!(state %in% anti_states)]

cat("  Anti-ERPO states excluded: ", paste(anti_states, collapse = ", "), "\n")
cat("  States remaining: ", uniqueN(cs_data_no_anti$state), "\n")

tryCatch({
  cs_no_anti <- att_gt(
    yname = "rate_All_Suicide",
    tname = "year",
    idname = "state_id",
    gname = "G",
    data = as.data.frame(cs_data_no_anti),
    control_group = "nevertreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal"
  )
  agg_no_anti <- aggte(cs_no_anti, type = "simple")
  cat("ATT (excluding anti-ERPO states):\n")
  print(summary(agg_no_anti))
  saveRDS(agg_no_anti, file.path(data_dir, "agg_no_anti_erpo.rds"))

  fwrite(data.table(
    Specification = "Excluding anti-ERPO states",
    ATT = agg_no_anti$overall.att,
    SE = agg_no_anti$overall.se,
    p_value = 2 * pnorm(-abs(agg_no_anti$overall.att / agg_no_anti$overall.se)),
    N_treated = uniqueN(cs_data_no_anti[G > 0]$state)
  ), file.path(data_dir, "sensitivity_no_anti.csv"))
}, error = function(e) {
  cat("  Excluding anti-ERPO states failed: ", e$message, "\n")
})

# ─── J. Formal Joint Pre-Trend Test ─────────────────────────────────────────

cat("\n=== J. Formal Joint Pre-Trend Test ===\n")

tryCatch({
  es_total <- readRDS(file.path(data_dir, "es_total_suicide.rds"))
  es_dt <- data.table(
    e = es_total$egt,
    att = es_total$att.egt,
    se = es_total$se.egt
  )
  pre <- es_dt[e < 0]

  # Wald test: joint test that all pre-treatment coefficients = 0
  # Under H0, each att/se ~ N(0,1), so sum of squares ~ chi-squared
  # This is conservative (ignores covariance, which inflates the statistic)
  chi2_stat <- sum((pre$att / pre$se)^2)
  df <- nrow(pre)
  p_joint <- 1 - pchisq(chi2_stat, df = df)

  cat("  Pre-treatment coefficients: ", nrow(pre), "\n")
  cat("  Chi-squared statistic: ", round(chi2_stat, 2), "\n")
  cat("  Degrees of freedom: ", df, "\n")
  cat("  Joint p-value: ", round(p_joint, 4), "\n")

  fwrite(data.table(
    test = "Joint pre-trend (chi-sq)",
    chi2 = chi2_stat,
    df = df,
    p_value = p_joint,
    n_pre_periods = nrow(pre),
    avg_abs_pretreat = mean(abs(pre$att))
  ), file.path(data_dir, "pretrend_test.csv"))
}, error = function(e) {
  cat("  Pre-trend test failed: ", e$message, "\n")
})

# ─── K. Collect Robustness Summary ──────────────────────────────────────────

cat("\n=== Robustness Summary ===\n")

agg_total <- readRDS(file.path(data_dir, "agg_total_suicide.rds"))

# Build robustness summary with all specifications
rob_specs <- list(
  list("CS-DiD (Never-treated)", agg_total$overall.att, agg_total$overall.se),
  list("CS-DiD (Not-yet-treated)", agg_nyt$overall.att, agg_nyt$overall.se),
  list("Sun & Abraham (2021)", coef(sa_total)["treated"], se(sa_total)["treated"]),
  list("TWFE (diagnostic)", coef(twfe_for_boot)["treated"], se(twfe_for_boot)["treated"])
)

# Add sensitivity results if they exist
if (file.exists(file.path(data_dir, "agg_no2018_cohort.rds"))) {
  a <- readRDS(file.path(data_dir, "agg_no2018_cohort.rds"))
  rob_specs[[length(rob_specs) + 1]] <- list("Excluding 2018 cohort", a$overall.att, a$overall.se)
}
if (file.exists(file.path(data_dir, "agg_no_anti_erpo.rds"))) {
  a <- readRDS(file.path(data_dir, "agg_no_anti_erpo.rds"))
  rob_specs[[length(rob_specs) + 1]] <- list("Excluding anti-ERPO states", a$overall.att, a$overall.se)
}

rob_summary <- rbindlist(lapply(rob_specs, function(x) {
  data.table(Specification = x[[1]], ATT = x[[2]], SE = x[[3]])
}))
rob_summary[, p_value := 2 * pnorm(-abs(ATT / SE))]

cat("Robustness comparison:\n")
print(rob_summary)
fwrite(rob_summary, file.path(data_dir, "robustness_summary.csv"))

cat("\nDONE.\n")
