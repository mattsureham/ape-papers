# ==============================================================================
# APEP-0509: MGNREGA, Input Substitution, and Crop-Specific Productivity
# 04_robustness.R — Robustness checks and sensitivity analysis
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
crop_long <- readRDS(file.path(data_dir, "crop_panel.rds"))
agg_panel <- readRDS(file.path(data_dir, "agg_panel.rds"))
wage_panel <- readRDS(file.path(data_dir, "wage_panel.rds"))
fert_panel <- readRDS(file.path(data_dir, "fert_panel.rds"))
baseline <- readRDS(file.path(data_dir, "baseline.rds"))

rob_results <- list()

# ==============================================================================
# 1. Pre-trend tests (joint F-test)
# ==============================================================================
cat("=== Pre-trend tests ===\n")

# For each main crop, test joint significance of pre-treatment coefficients
main_crops <- c("RICE", "WHEAT", "COTTON", "SUGARCANE",
                "MAIZE", "SORGHUM", "CHICKPEA", "GROUNDNUT")

pretrend_tests <- list()
for (crop_name in main_crops) {
  dt <- crop_long[crop == crop_name]
  if (nrow(dt) < 100) next

  fit <- tryCatch(
    feols(log_yield ~ sunab(first_treat_year, year) | dist_code + year,
          data = dt, cluster = ~state_code),
    error = function(e) NULL
  )

  if (is.null(fit)) next

  # Extract pre-treatment coefficients
  coef_names <- names(coef(fit))
  pre_coefs <- grep("year::-[0-9]", coef_names, value = TRUE)
  # Exclude reference period
  pre_coefs <- pre_coefs[!grepl("::-1$", pre_coefs)]

  if (length(pre_coefs) > 0) {
    # Joint Wald test
    wt <- tryCatch(wald(fit, pre_coefs), error = function(e) NULL)
    if (!is.null(wt)) {
      pretrend_tests[[crop_name]] <- list(
        f_stat = wt$stat,
        p_value = wt$p,
        n_pre_coefs = length(pre_coefs)
      )
      cat(sprintf("  %s: F(%d) = %.2f, p = %.4f %s\n",
                  crop_name, length(pre_coefs), wt$stat, wt$p,
                  ifelse(wt$p > 0.10, "(PASS)", "(WARNING)")))
    }
  }
}
rob_results$pretrend_tests <- pretrend_tests

# ==============================================================================
# 2. State × Year Fixed Effects
# ==============================================================================
cat("\n=== State × Year FE ===\n")

rob_sxyr <- list()
for (crop_name in main_crops) {
  dt <- crop_long[crop == crop_name]
  if (nrow(dt) < 100) next

  fit <- tryCatch(
    feols(log_yield ~ post | dist_code + state_code^year,
          data = dt, cluster = ~state_code),
    error = function(e) NULL
  )
  if (!is.null(fit)) {
    rob_sxyr[[crop_name]] <- fit
    cat(sprintf("  %s: β(post) = %.4f (%.4f)\n",
                crop_name, coef(fit)["post"], se(fit)["post"]))
  }
}
rob_results$state_x_year <- rob_sxyr

# ==============================================================================
# 3. Spatial spillover check: exclude border districts
# ==============================================================================
cat("\n=== Spatial spillover check ===\n")

# Identify Phase I border districts using lat/lon
# A district in Phase II/III is a "border" district if it is within
# ~1 degree (approx 100km) of a Phase I district
phase1_coords <- baseline[mgnrega_phase == 1, .(lat, lon)]
phase23_dists <- baseline[mgnrega_phase > 1]

# Compute minimum distance to any Phase I district
phase23_dists[, min_dist_to_p1 := {
  sapply(1:.N, function(i) {
    dists <- sqrt((lat[i] - phase1_coords$lat)^2 +
                  (lon[i] - phase1_coords$lon)^2)
    min(dists, na.rm = TRUE)
  })
}]

# Exclude districts within 1 degree of Phase I (buffer zone)
buffer_dists <- phase23_dists[min_dist_to_p1 < 1.0, dist_code]
cat(sprintf("  Excluding %d Phase II/III districts near Phase I borders\n",
            length(buffer_dists)))

# Re-run main spec excluding buffer districts
crop_noborder <- crop_long[!(dist_code %in% buffer_dists)]
rob_noborder <- list()
for (crop_name in c("RICE", "WHEAT", "COTTON", "SUGARCANE")) {
  dt <- crop_noborder[crop == crop_name]
  if (nrow(dt) < 100) next
  fit <- tryCatch(
    feols(log_yield ~ post | dist_code + year,
          data = dt, cluster = ~state_code),
    error = function(e) NULL
  )
  if (!is.null(fit)) {
    rob_noborder[[crop_name]] <- fit
  }
}
rob_results$no_border <- rob_noborder

# ==============================================================================
# 4. Balanced panel (districts with complete data all years)
# ==============================================================================
cat("\n=== Balanced panel ===\n")

# For each crop, find districts with data in all 18 years (2000-2017)
rob_balanced <- list()
rob_balanced_static <- list()
for (crop_name in c("RICE", "WHEAT", "COTTON", "SUGARCANE")) {
  dt <- crop_long[crop == crop_name]
  # Crop-specific balanced panel: districts with this crop in all 18 years
  crop_complete <- dt[, .(n_years = .N), by = dist_code][n_years == 18, dist_code]
  dt_bal <- dt[dist_code %in% crop_complete]
  cat(sprintf("  %s balanced: %d / %d districts, %d obs\n",
              crop_name, length(crop_complete),
              length(unique(dt$dist_code)), nrow(dt_bal)))
  if (nrow(dt_bal) < 100) next
  fit <- tryCatch(
    feols(log_yield ~ sunab(first_treat_year, year) | dist_code + year,
          data = dt_bal, cluster = ~state_code),
    error = function(e) NULL
  )
  if (!is.null(fit)) rob_balanced[[crop_name]] <- fit
  # Also static for robustness table comparability
  fit_static <- tryCatch(
    feols(log_yield ~ post | dist_code + year,
          data = dt_bal, cluster = ~state_code),
    error = function(e) NULL
  )
  if (!is.null(fit_static)) rob_balanced_static[[crop_name]] <- fit_static
}
rob_results$balanced <- rob_balanced
rob_results$balanced_static <- rob_balanced_static

# ==============================================================================
# 5. Alternative clustering: district-level
# ==============================================================================
cat("\n=== District-level clustering ===\n")

rob_dist_cluster <- list()
for (crop_name in c("RICE", "WHEAT", "COTTON", "SUGARCANE")) {
  dt <- crop_long[crop == crop_name]
  if (nrow(dt) < 100) next
  fit <- tryCatch(
    feols(log_yield ~ post | dist_code + year,
          data = dt, cluster = ~dist_code),
    error = function(e) NULL
  )
  if (!is.null(fit)) rob_dist_cluster[[crop_name]] <- fit
}
rob_results$dist_cluster <- rob_dist_cluster

# ==============================================================================
# 6. Heterogeneity: by baseline backwardness
# ==============================================================================
cat("\n=== Heterogeneity: above/below median backwardness ===\n")

median_backward <- median(baseline$backwardness_index, na.rm = TRUE)
crop_long[, high_backward := backwardness_index > median_backward]

rob_het_backward <- list()
for (hb in c(TRUE, FALSE)) {
  dt <- crop_long[high_backward == hb & crop %in% c("RICE", "WHEAT")]
  if (nrow(dt) < 100) next
  fit <- tryCatch(
    feols(log_yield ~ post | dist_code + year,
          data = dt, cluster = ~state_code),
    error = function(e) NULL
  )
  if (!is.null(fit)) rob_het_backward[[paste0("backward_", hb)]] <- fit
}
rob_results$het_backward <- rob_het_backward

# ==============================================================================
# 7. HonestDiD sensitivity (for aggregate yields)
# ==============================================================================
cat("\n=== HonestDiD sensitivity ===\n")

agg_es <- feols(
  log_avg_yield ~ sunab(first_treat_year, year) | dist_code + year,
  data = agg_panel,
  cluster = ~state_code
)

honest_result <- tryCatch({
  # Extract coefficients and variance-covariance matrix
  betahat <- coef(agg_es)
  sigma <- vcov(agg_es)

  # Identify pre and post periods
  coef_names <- names(betahat)
  pre_idx <- grep("year::-[0-9]", coef_names)
  post_idx <- grep("year::[0-9]", coef_names)

  if (length(pre_idx) > 1 && length(post_idx) > 0) {
    # Run HonestDiD
    honest <- HonestDiD::createSensitivityResults(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 0.05, by = 0.01),
      alpha = 0.05
    )
    cat("  HonestDiD results:\n")
    print(honest)
    honest
  } else {
    cat("  Insufficient pre/post coefficients for HonestDiD.\n")
    NULL
  }
}, error = function(e) {
  cat("  HonestDiD failed:", e$message, "\n")
  NULL
})
rob_results$honest_did <- honest_result

# ==============================================================================
# 8. Callaway & Sant'Anna (2021) estimator
# ==============================================================================
cat("\n=== Callaway & Sant'Anna estimator ===\n")

# Prepare data for did::att_gt()
# Note: did package expects specific column names
for (crop_name in c("RICE", "WHEAT")) {
  cat(sprintf("\n--- CS-DiD: %s ---\n", crop_name))
  dt <- crop_long[crop == crop_name]

  # did::att_gt requires: yname, tname, idname, gname
  cs_dt <- dt[, .(id = dist_code, time = year, g = first_treat_year,
                   y = log_yield, state = state_code)]
  cs_dt <- cs_dt[!is.na(y)]

  cs_result <- tryCatch({
    out <- att_gt(
      yname = "y",
      tname = "time",
      idname = "id",
      gname = "g",
      data = as.data.frame(cs_dt),
      control_group = "notyettreated",
      base_period = "universal",
      clustervars = "state"
    )
    agg_out <- aggte(out, type = "dynamic")
    cat(sprintf("  CS-DiD aggregate ATT for %s:\n", crop_name))
    summary(agg_out)
    rob_results[[paste0("cs_did_", tolower(crop_name))]] <- agg_out
    agg_out
  }, error = function(e) {
    cat("  CS-DiD error:", e$message, "\n")
    NULL
  })
}

# ==============================================================================
# 9. Save robustness results
# ==============================================================================
cat("\n=== Saving robustness results ===\n")
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))
cat("All robustness results saved.\n")
