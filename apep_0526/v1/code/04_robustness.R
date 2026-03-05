# =============================================================================
# 04_robustness.R — Robustness checks and sensitivity analysis
# =============================================================================
source("00_packages.R")

panel <- fread(file.path(DATA_DIR, "panel_state_quarter.csv"))
cat("Panel loaded:", nrow(panel), "rows\n")

# Reconstruct needed variables
panel[, state_id := as.integer(factor(state_fips))]
panel[, cohort_time := fifelse(cohort_yq > 0,
                                (floor(cohort_yq) - 2008) * 4 + round((cohort_yq %% 1) * 4) + 1,
                                0)]
panel[, rel_time := fifelse(cohort_yq > 0, time_id - cohort_time, NA_integer_)]

# Census region mapping
# Ensure state_fips is character
panel[, state_fips := as.character(state_fips)]

region_map <- data.table(
  state_fips = c("09","23","25","33","44","50",  # NE
                 "34","36","42",                  # Mid-Atl
                 "17","18","26","39","55",         # E North Central
                 "19","20","27","29","31","38","46", # W North Central
                 "10","11","12","13","24","37","45","51","54", # S Atl
                 "01","21","28","47",              # E South Central
                 "05","22","40","48",              # W South Central
                 "04","08","16","30","32","35","49","56", # Mountain
                 "02","06","15","41","53"),        # Pacific
  region = c(rep("Northeast", 9), rep("Midwest", 12),
             rep("South", 17), rep("West", 13))
)
panel <- merge(panel, region_map, by = "state_fips", all.x = TRUE)
panel[, region_time := paste0(region, "_", time_id)]

# ---------------------------------------------------------------------------
# A. Bacon Decomposition (for TWFE diagnostics)
# ---------------------------------------------------------------------------
cat("\n=== Bacon Decomposition ===\n")
library(bacondecomp)

# Bacon needs balanced panel with binary treatment, numeric id
bacon_panel <- panel[, .(state_num = state_id[1], time = time_id[1],
                          treated = treated[1], y = ln_trials[1]),
                      by = .(state_fips, time_id)]

bacon_out <- tryCatch({
  bacon(y ~ treated, data = as.data.frame(bacon_panel),
        id_var = "state_num", time_var = "time")
}, error = function(e) {
  cat("Bacon decomposition error:", e$message, "\n")
  NULL
})

if (!is.null(bacon_out)) {
  bacon_dt <- as.data.table(bacon_out)
  fwrite(bacon_dt, file.path(DATA_DIR, "bacon_decomp.csv"))
  cat("Bacon decomposition saved. Components:\n")
  print(bacon_dt[, .(mean_estimate = weighted.mean(estimate, weight),
                      total_weight = sum(weight)), by = type])
}

# ---------------------------------------------------------------------------
# B. Region × Quarter FE (control for biotech trends)
# ---------------------------------------------------------------------------
cat("\n=== Region × Quarter FE ===\n")
twfe_region <- feols(
  ln_trials ~ treated | state_fips + region_time,
  data = panel, cluster = ~state_fips
)
cat("With region×quarter FE:", round(coef(twfe_region)["treated"], 4),
    " (se:", round(se(twfe_region)["treated"], 4), ")\n")

# ---------------------------------------------------------------------------
# C. Leave-one-state-out (biotech hubs)
# ---------------------------------------------------------------------------
cat("\n=== Leave-One-State-Out ===\n")
hub_states <- c("06", "25", "36", "34", "48", "24")  # CA, MA, NY, NJ, TX, MD
hub_names <- c("California", "Massachusetts", "New York", "New Jersey", "Texas", "Maryland")

loo_results <- data.table()
for (i in seq_along(hub_states)) {
  sub_panel <- panel[state_fips != hub_states[i]]
  sub_panel[, state_id_sub := as.integer(factor(state_fips))]
  sub_panel[, cohort_time_sub := fifelse(cohort_yq > 0,
                                (floor(cohort_yq) - 2008) * 4 + round((cohort_yq %% 1) * 4) + 1,
                                0)]
  cs_sub <- tryCatch({
    out <- att_gt(
      yname = "ln_trials", tname = "time_id",
      idname = "state_id_sub", gname = "cohort_time_sub",
      data = as.data.frame(sub_panel),
      control_group = "notyettreated",
      anticipation = 0, est_method = "dr", base_period = "universal"
    )
    agg <- aggte(out, type = "simple")
    data.table(dropped = hub_names[i], att = agg$overall.att, se = agg$overall.se)
  }, error = function(e) {
    cat("  Error dropping", hub_names[i], ":", e$message, "\n")
    data.table(dropped = hub_names[i], att = NA_real_, se = NA_real_)
  })
  loo_results <- rbind(loo_results, cs_sub)
  cat("  Dropped", hub_names[i], ":", round(cs_sub$att, 4), "\n")
}

fwrite(loo_results, file.path(DATA_DIR, "loo_results.csv"))

# ---------------------------------------------------------------------------
# D. Randomization Inference
# ---------------------------------------------------------------------------
cat("\n=== Randomization Inference ===\n")

# Observed ATT from TWFE (faster than CS for permutations)
twfe_base <- feols(ln_trials ~ treated | state_fips + time_id,
                    data = panel, cluster = ~state_fips)
observed_coef <- coef(twfe_base)["treated"]

# Permute treatment assignment across states
set.seed(42)
n_perms <- 500
states_with_law <- unique(panel$state_fips[panel$cohort_yq > 0])
all_states <- unique(panel$state_fips)

perm_coefs <- numeric(n_perms)
for (p in 1:n_perms) {
  if (p %% 100 == 0) cat("  Permutation", p, "of", n_perms, "\n")

  # Randomly reassign which states are treated (preserving number of treated)
  fake_treated <- sample(all_states, length(states_with_law))

  # For each fake-treated state, assign a random adoption quarter from the real distribution
  real_cohorts <- unique(panel$cohort_time[panel$cohort_time > 0])
  fake_cohorts <- sample(real_cohorts, length(fake_treated), replace = TRUE)

  perm_panel <- copy(panel)
  perm_panel[, perm_treated := 0L]
  for (j in seq_along(fake_treated)) {
    perm_panel[state_fips == fake_treated[j] & time_id >= fake_cohorts[j],
               perm_treated := 1L]
  }

  perm_fit <- feols(ln_trials ~ perm_treated | state_fips + time_id,
                     data = perm_panel, cluster = ~state_fips)
  perm_coefs[p] <- coef(perm_fit)["perm_treated"]
}

ri_pval <- mean(abs(perm_coefs) >= abs(observed_coef))
cat("RI p-value (two-sided):", round(ri_pval, 4), "\n")

ri_data <- data.table(
  observed = observed_coef,
  perm_coefs = perm_coefs,
  ri_pval = ri_pval
)
fwrite(ri_data[1, .(observed, ri_pval)], file.path(DATA_DIR, "ri_summary.csv"))
fwrite(data.table(perm_coefs = perm_coefs), file.path(DATA_DIR, "ri_permutations.csv"))

# ---------------------------------------------------------------------------
# E. Panel ending at 2017Q4 vs 2016Q4 (shorter panel sensitivity)
# ---------------------------------------------------------------------------
cat("\n=== Shorter Panel Sensitivity ===\n")
for (end_year in c(2016, 2017)) {
  sub <- panel[year <= end_year]
  sub[, state_id_sub := as.integer(factor(state_fips))]
  sub[, cohort_time_sub := fifelse(cohort_yq > 0,
                                (floor(cohort_yq) - 2008) * 4 + round((cohort_yq %% 1) * 4) + 1,
                                0)]
  # Drop cohorts adopted after the panel end
  max_time <- max(sub$time_id)
  sub[cohort_time_sub > max_time, cohort_time_sub := 0]

  tryCatch({
    out <- att_gt(
      yname = "ln_trials", tname = "time_id",
      idname = "state_id_sub", gname = "cohort_time_sub",
      data = as.data.frame(sub),
      control_group = "notyettreated",
      anticipation = 0, est_method = "dr", base_period = "universal"
    )
    agg <- aggte(out, type = "simple")
    cat("Panel through", end_year, "Q4: ATT =", round(agg$overall.att, 4),
        " se:", round(agg$overall.se, 4), "\n")
  }, error = function(e) {
    cat("Panel through", end_year, "Q4: Error:", e$message, "\n")
  })
}

# ---------------------------------------------------------------------------
# F. HonestDiD sensitivity (Rambachan-Roth)
# ---------------------------------------------------------------------------
cat("\n=== HonestDiD Sensitivity ===\n")

# Use the fixest event study for HonestDiD
panel_es <- panel[!is.na(rel_time)]
panel_es[, rel_time_binned := fcase(
  rel_time < -8, -8L,
  rel_time > 8, 8L,
  default = as.integer(rel_time)
)]

es_honest <- feols(
  ln_trials ~ i(rel_time_binned, ref = -1) | state_fips + time_id,
  data = panel_es, cluster = ~state_fips
)

# HonestDiD requires specific format
tryCatch({
  betahat <- coef(es_honest)
  sigma <- vcov(es_honest)

  # Identify pre-treatment and post-treatment coefficients
  coef_names <- names(betahat)
  pre_idx <- grep("rel_time_binned::-[2-8]", coef_names)
  post_idx <- grep("rel_time_binned::[0-8]", coef_names)

  if (length(pre_idx) > 0 && length(post_idx) > 0) {
    honest_result <- HonestDiD::createSensitivityResults(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 0.05, by = 0.01)
    )
    honest_dt <- as.data.table(honest_result)
    fwrite(honest_dt, file.path(DATA_DIR, "honestdid_results.csv"))
    cat("HonestDiD saved.\n")
  } else {
    cat("Could not identify pre/post coefficients for HonestDiD.\n")
  }
}, error = function(e) {
  cat("HonestDiD error:", e$message, "\n")
})

# ---------------------------------------------------------------------------
# G. Donut specification (drop adoption quarter)
# ---------------------------------------------------------------------------
cat("\n=== Donut Specification ===\n")
donut_panel <- panel[is.na(rel_time) | abs(rel_time) > 0]
twfe_donut <- feols(
  ln_trials ~ treated | state_fips + time_id,
  data = donut_panel, cluster = ~state_fips
)
cat("Donut (drop t=0):", round(coef(twfe_donut)["treated"], 4),
    " (se:", round(se(twfe_donut)["treated"], 4), ")\n")

# ---------------------------------------------------------------------------
# H. Power analysis and MDE
# ---------------------------------------------------------------------------
cat("\n=== Power Analysis / MDE ===\n")

# Within-state-quarter residual SD from TWFE model
resid_sd <- sd(resid(twfe_base))

# Number of clusters (states)
n_clusters <- uniqueN(panel$state_fips)
n_treated <- uniqueN(panel$state_fips[panel$cohort_yq > 0])
n_control <- n_clusters - n_treated
n_periods <- uniqueN(panel$time_id)

# Approximate MDE using cluster-robust formula
# MDE ≈ 2.8 * SE (for 80% power, two-sided 5% test)
mde_estimate <- 2.8 * se(twfe_base)["treated"]
cat("Approximate MDE (80% power):", round(mde_estimate, 4),
    "= ~", round(100 * (exp(mde_estimate) - 1), 1), "% change\n")
cat("Residual SD:", round(resid_sd, 4), "\n")
cat("Clusters:", n_clusters, "(treated:", n_treated, ", control:", n_control, ")\n")

power_stats <- data.table(
  mde = mde_estimate,
  mde_pct = 100 * (exp(mde_estimate) - 1),
  resid_sd = resid_sd,
  n_clusters = n_clusters,
  n_treated = n_treated,
  n_control = n_control,
  n_periods = n_periods
)
fwrite(power_stats, file.path(DATA_DIR, "power_stats.csv"))

# ---------------------------------------------------------------------------
# Compile robustness summary
# ---------------------------------------------------------------------------
robust_summary <- data.table(
  specification = c("Main TWFE", "Region×Quarter FE", "Donut (drop t=0)",
                     paste("Drop", loo_results$dropped)),
  coef = c(coef(twfe_base)["treated"], coef(twfe_region)["treated"],
           coef(twfe_donut)["treated"], loo_results$att),
  se = c(se(twfe_base)["treated"], se(twfe_region)["treated"],
         se(twfe_donut)["treated"], loo_results$se)
)
robust_summary[, pval := 2 * pnorm(-abs(coef / se))]
fwrite(robust_summary, file.path(DATA_DIR, "robustness_summary.csv"))

cat("\nAll robustness checks complete.\n")
