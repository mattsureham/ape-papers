## =============================================================================
## 04_robustness.R — apep_0590
## Placebo, HonestDiD, dose-response, leave-one-out, Bacon decomposition
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "clean_panel.csv"))
cat("Loaded clean panel:", nrow(panel), "rows\n")

# =============================================================================
# 1) Placebo Treatment at 2015 (4 years before actual treatment)
# =============================================================================
cat("\n=== Placebo Test: Fake Treatment at 2015 ===\n")

# Use only pre-treatment data (2001-2018)
# Assign fake treatment at 2015 to units that were actually treated
panel_placebo <- panel[year <= 2018]
panel_placebo[, first_treat_placebo := fifelse(
  first_treat > 0,
  first_treat - 4,  # Shift treatment 4 years earlier
  0L
)]

# Ensure placebo treatment is still within sample period
panel_placebo <- panel_placebo[first_treat_placebo >= 2005 | first_treat_placebo == 0]

set.seed(20240310)
cs_placebo <- tryCatch({
  att_gt(
    yname = "asinh_loss",
    tname = "year",
    idname = "muni_id",
    gname = "first_treat_placebo",
    data = as.data.frame(panel_placebo),
    control_group = "nevertreated",
    est_method = "dr",
    bstrap = TRUE, biters = 1000
  )
}, error = function(e) {
  cat("Placebo CS-DiD error:", e$message, "\n")
  NULL
})

if (!is.null(cs_placebo)) {
  agg_placebo <- aggte(cs_placebo, type = "simple")
  cat("Placebo ATT:", round(agg_placebo$overall.att, 4),
      "SE:", round(agg_placebo$overall.se, 4),
      "p:", round(2 * pnorm(-abs(agg_placebo$overall.att / agg_placebo$overall.se)), 3), "\n")

  agg_placebo_dyn <- aggte(cs_placebo, type = "dynamic", min_e = -6, max_e = 3)
  placebo_es <- data.frame(
    event_time = agg_placebo_dyn$egt,
    att = agg_placebo_dyn$att.egt,
    se = agg_placebo_dyn$se.egt,
    ci_lower = agg_placebo_dyn$att.egt - 1.96 * agg_placebo_dyn$se.egt,
    ci_upper = agg_placebo_dyn$att.egt + 1.96 * agg_placebo_dyn$se.egt
  )
  fwrite(placebo_es, file.path(data_dir, "placebo_event_study.csv"))

  placebo_summary <- data.frame(
    test = "Placebo (t-4)",
    att = agg_placebo$overall.att,
    se = agg_placebo$overall.se,
    pvalue = 2 * pnorm(-abs(agg_placebo$overall.att / agg_placebo$overall.se))
  )
  fwrite(placebo_summary, file.path(data_dir, "placebo_summary.csv"))
}

# =============================================================================
# 2) Rambachan-Roth HonestDiD Sensitivity Analysis
# =============================================================================
cat("\n=== HonestDiD Sensitivity Analysis ===\n")

cs_result <- readRDS(file.path(data_dir, "cs_result_asinh.rds"))
agg_dynamic <- aggte(cs_result, type = "dynamic", min_e = -10, max_e = 5)

# HonestDiD requires event study coefficients + VCV
# Use the CS-DiD result directly via honest_did wrapper
honest_results <- tryCatch({
  # Get dynamic aggregation with explicit bounds
  e_times <- agg_dynamic$egt
  pre_idx <- which(e_times < -1)  # exclude -1 (reference)
  post_idx <- which(e_times >= 0)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    betahat <- agg_dynamic$att.egt
    # Construct VCV from the did object — use influence function if V is degenerate
    sigma <- tryCatch({
      V <- agg_dynamic$V
      if (is.null(V) || !is.matrix(V) || any(dim(V) == 0)) {
        # Fall back to diagonal VCV from SEs
        diag(agg_dynamic$se.egt^2)
      } else {
        V
      }
    }, error = function(e) diag(agg_dynamic$se.egt^2))

    honest_rm <- HonestDiD::createSensitivityResults_relativeMagnitudes(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mbarvec = seq(0, 2, by = 0.5),
      l_vec = basisVector(index = 1, size = length(post_idx))
    )

    cat("HonestDiD relative magnitudes results:\n")
    print(honest_rm)
    fwrite(as.data.frame(honest_rm), file.path(data_dir, "honest_did_rm.csv"))
    honest_rm
  } else {
    cat("Insufficient pre/post periods for HonestDiD.\n")
    NULL
  }
}, error = function(e) {
  cat("HonestDiD error:", e$message, "\n")
  NULL
})

# =============================================================================
# 3) Leave-One-State-Out
# =============================================================================
cat("\n=== Leave-One-State-Out ===\n")

treated_states <- unique(panel[first_treat > 0, NAME_1])
loo_results <- list()

for (state in treated_states) {
  sub <- panel[NAME_1 != state]

  set.seed(20240310)
  cs_loo <- tryCatch({
    att_gt(
      yname = "asinh_loss",
      tname = "year",
      idname = "muni_id",
      gname = "first_treat",
      data = as.data.frame(sub),
      control_group = "nevertreated",
      est_method = "dr",
      bstrap = TRUE, biters = 200
    )
  }, error = function(e) NULL)

  if (!is.null(cs_loo)) {
    agg_loo <- aggte(cs_loo, type = "simple")
    loo_results[[state]] <- data.frame(
      excluded_state = state,
      att = agg_loo$overall.att,
      se = agg_loo$overall.se
    )
    cat("  Excl.", state, ": ATT =", round(agg_loo$overall.att, 4), "\n")
  }
}

loo_df <- do.call(rbind, loo_results)
fwrite(loo_df, file.path(data_dir, "leave_one_state_out.csv"))

cat("Leave-one-out range:",
    round(min(loo_df$att), 4), "to", round(max(loo_df$att), 4), "\n")

# =============================================================================
# 4) Goodman-Bacon Decomposition
# =============================================================================
cat("\n=== Goodman-Bacon Decomposition ===\n")

# Bacon decomposition shows which 2x2 comparisons drive TWFE
# Need balanced panel with binary treatment
bacon_data <- panel[, .(
  asinh_loss = asinh_loss[1],
  treated = treated[1],
  year = year[1],
  muni_id = muni_id[1]
), by = .(GID_2, year)]

bacon_result <- tryCatch({
  bacon(asinh_loss ~ treated, data = as.data.frame(panel),
        id_var = "muni_id", time_var = "year")
}, error = function(e) {
  cat("Bacon decomposition error:", e$message, "\n")
  NULL
})

if (!is.null(bacon_result)) {
  bacon_df <- as.data.frame(bacon_result)
  fwrite(bacon_df, file.path(data_dir, "bacon_decomposition.csv"))

  # Summarize by comparison type
  bacon_summary <- bacon_df %>%
    group_by(type) %>%
    summarise(
      n_comparisons = n(),
      mean_estimate = mean(estimate),
      total_weight = sum(weight),
      .groups = "drop"
    )
  cat("Bacon decomposition summary:\n")
  print(bacon_summary)
  fwrite(bacon_summary, file.path(data_dir, "bacon_summary.csv"))
}

# =============================================================================
# 5) Not-Yet-Treated as Alternative Control Group
# =============================================================================
cat("\n=== Not-Yet-Treated Control Group ===\n")

set.seed(20240310)
cs_nyt <- tryCatch({
  att_gt(
    yname = "asinh_loss",
    tname = "year",
    idname = "muni_id",
    gname = "first_treat",
    data = as.data.frame(panel),
    control_group = "notyettreated",
    est_method = "dr",
    bstrap = TRUE, biters = 1000
  )
}, error = function(e) {
  cat("Not-yet-treated error:", e$message, "\n")
  NULL
})

if (!is.null(cs_nyt)) {
  agg_nyt <- aggte(cs_nyt, type = "simple")
  cat("ATT (not-yet-treated):", round(agg_nyt$overall.att, 4),
      "SE:", round(agg_nyt$overall.se, 4), "\n")

  agg_nyt_dyn <- aggte(cs_nyt, type = "dynamic", min_e = -10, max_e = 5)
  nyt_es <- data.frame(
    event_time = agg_nyt_dyn$egt,
    att = agg_nyt_dyn$att.egt,
    se = agg_nyt_dyn$se.egt,
    ci_lower = agg_nyt_dyn$att.egt - 1.96 * agg_nyt_dyn$se.egt,
    ci_upper = agg_nyt_dyn$att.egt + 1.96 * agg_nyt_dyn$se.egt
  )
  fwrite(nyt_es, file.path(data_dir, "event_study_nyt.csv"))

  nyt_summary <- data.frame(
    control_group = "Not-yet-treated",
    att = agg_nyt$overall.att,
    se = agg_nyt$overall.se
  )
  fwrite(nyt_summary, file.path(data_dir, "nyt_summary.csv"))
}

# =============================================================================
# 6) Pre-Trend Test (Joint F-test of Pre-Treatment Coefficients)
# =============================================================================
cat("\n=== Pre-Trend Test ===\n")

agg_dynamic <- aggte(cs_result, type = "dynamic", min_e = -10, max_e = 5)
e_times <- agg_dynamic$egt
pre_idx <- which(e_times < 0)
pre_atts <- agg_dynamic$att.egt[pre_idx]
pre_ses <- agg_dynamic$se.egt[pre_idx]

# Wald test: H0: all pre-treatment ATTs = 0
if (length(pre_idx) >= 2) {
  V_full <- tryCatch({
    V <- agg_dynamic$V
    if (is.null(V) || !is.matrix(V) || any(dim(V) == 0)) {
      diag(agg_dynamic$se.egt^2)
    } else {
      V
    }
  }, error = function(e) diag(agg_dynamic$se.egt^2))

  V_pre <- V_full[pre_idx, pre_idx, drop = FALSE]

  tryCatch({
    det_v <- det(V_pre)
    if (is.finite(det_v) && det_v > 1e-20) {
      wald_stat <- as.numeric(t(pre_atts) %*% solve(V_pre) %*% pre_atts)
      wald_df <- length(pre_idx)
      wald_pval <- 1 - pchisq(wald_stat, df = wald_df)

      cat("Pre-trend Wald test: chi2(", wald_df, ") =", round(wald_stat, 2),
          ", p =", round(wald_pval, 3), "\n")

      pretrend_test <- data.frame(
        test = "Pre-trend Wald",
        statistic = wald_stat,
        df = wald_df,
        pvalue = wald_pval
      )
      fwrite(pretrend_test, file.path(data_dir, "pretrend_test.csv"))
    } else {
      cat("Pre-trend VCV matrix is near-singular, using simple t-tests instead.\n")
      # Individual t-tests as fallback
      pre_t_stats <- pre_atts / pre_ses
      pre_p_vals <- 2 * pnorm(-abs(pre_t_stats))
      cat("Individual pre-treatment p-values:\n")
      print(data.frame(e = e_times[pre_idx], att = round(pre_atts, 4),
                        se = round(pre_ses, 4), p = round(pre_p_vals, 3)))
    }
  }, error = function(e) {
    cat("Pre-trend Wald test error:", e$message, "\n")
  })
}

# =============================================================================
# Compile All Robustness Results
# =============================================================================

main_results <- fread(file.path(data_dir, "main_results_summary.csv"))

robustness_summary <- data.frame(
  specification = c(
    "Main (CS-DiD, never-treated)",
    "Not-yet-treated controls",
    "TWFE",
    "Placebo (t-4)"
  ),
  estimate = c(
    main_results[specification == "CS-DiD asinh(loss)", estimate],
    ifelse(!is.null(cs_nyt), agg_nyt$overall.att, NA),
    main_results[specification == "TWFE asinh(loss)", estimate],
    ifelse(!is.null(cs_placebo), agg_placebo$overall.att, NA)
  ),
  se = c(
    main_results[specification == "CS-DiD asinh(loss)", se],
    ifelse(!is.null(cs_nyt), agg_nyt$overall.se, NA),
    main_results[specification == "TWFE asinh(loss)", se],
    ifelse(!is.null(cs_placebo), agg_placebo$overall.se, NA)
  )
)

fwrite(robustness_summary, file.path(data_dir, "robustness_summary.csv"))

cat("\nAll robustness checks complete.\n")
