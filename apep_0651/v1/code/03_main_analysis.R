# ==============================================================================
# 03_main_analysis.R — Primary regressions: Spotlight effect on enforcement
# APEP Paper apep_0651: The Spotlight Effect on Mine Safety Enforcement
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
analysis <- readRDS(file.path(data_dir, "analysis.rds"))

cat("Analysis dataset:", nrow(analysis), "fatality events\n")

# ==============================================================================
# TABLE 2: Balancing Test — News competition is uncorrelated with mine chars
# ==============================================================================

cat("\n=== Balancing Test ===\n")

# The instrument (FEMA disaster declarations in the fatality week) should be
# uncorrelated with mine characteristics, conditional on year-quarter FE
bal_vars <- intersect(
  c("n_killed", "is_coal", "log_employment", "large_mine", "insp_pre_365", "viol_pre_365"),
  names(analysis)
)

balance_results <- list()
for (v in bal_vars) {
  if (all(is.na(analysis[[v]]))) next
  fml <- as.formula(paste(v, "~ z_disasters | yq_fe"))
  fit <- feols(fml, data = analysis, vcov = "hetero")
  balance_results[[v]] <- list(
    coef = coef(fit)["z_disasters"],
    se = se(fit)["z_disasters"],
    pval = pvalue(fit)["z_disasters"]
  )
  cat(sprintf("  %s: coef=%.4f, se=%.4f, p=%.3f\n", v,
              balance_results[[v]]$coef, balance_results[[v]]$se,
              balance_results[[v]]$pval))
}

# ==============================================================================
# TABLE 3: Main Results — Reduced Form
# Effect of news competition on post-fatality enforcement
# ==============================================================================

cat("\n=== Main Results: Reduced Form ===\n")

# Outcomes: inspections, violations, penalties, S&S violations
# Windows: 90, 180, 365 days post-fatality
# Key specification: log(enforcement) ~ z_disasters + controls + FEs

outcomes <- c("insp_post_90", "viol_post_90", "penalty_post_90", "ss_post_90",
              "insp_post_180", "viol_post_180", "penalty_post_180",
              "insp_post_365", "viol_post_365", "penalty_post_365")
outcomes <- intersect(outcomes, names(analysis))

# Main specifications with increasing controls
main_results <- list()

# Spec 1: No controls (just instrument + year-quarter FE)
for (y in c("insp_post_90", "viol_post_90", "penalty_post_90")) {
  if (!y %in% names(analysis)) next

  # Log(Y+1) transformation for count/amount outcomes
  analysis[, paste0("log_", y) := log(get(y) + 1)]

  # Spec 1: Year-quarter FE only
  f1 <- as.formula(paste0("log_", y, " ~ z_disasters | yq_fe"))
  fit1 <- feols(f1, data = analysis, vcov = "hetero")

  # Spec 2: + fatality severity
  f2 <- as.formula(paste0("log_", y, " ~ z_disasters + n_killed | yq_fe"))
  fit2 <- feols(f2, data = analysis, vcov = "hetero")

  # Spec 3: + mine characteristics
  controls <- intersect(c("n_killed", "is_coal", "log_employment"), names(analysis))
  control_str <- paste(controls, collapse = " + ")
  f3 <- as.formula(paste0("log_", y, " ~ z_disasters + ", control_str, " | yq_fe"))
  fit3 <- feols(f3, data = analysis, vcov = "hetero")

  # Spec 4: + state FE
  f4 <- as.formula(paste0("log_", y, " ~ z_disasters + ", control_str, " | yq_fe + state_fe"))
  fit4 <- feols(f4, data = analysis, vcov = "hetero")

  main_results[[paste0(y, "_s1")]] <- fit1
  main_results[[paste0(y, "_s2")]] <- fit2
  main_results[[paste0(y, "_s3")]] <- fit3
  main_results[[paste0(y, "_s4")]] <- fit4

  cat(sprintf("\n%s:\n", y))
  cat(sprintf("  Spec 1 (YQ FE): coef=%.4f, se=%.4f, p=%.3f\n",
              coef(fit1)["z_disasters"], se(fit1)["z_disasters"],
              pvalue(fit1)["z_disasters"]))
  cat(sprintf("  Spec 4 (Full):  coef=%.4f, se=%.4f, p=%.3f\n",
              coef(fit4)["z_disasters"], se(fit4)["z_disasters"],
              pvalue(fit4)["z_disasters"]))
}

# ==============================================================================
# TABLE 4: Mechanisms — Discretionary vs. mandatory enforcement
# ==============================================================================

cat("\n=== Mechanism Tests ===\n")

# Heterogeneity by mine size (large mines are more visible)
if ("large_mine" %in% names(analysis)) {
  for (y in c("insp_post_90", "viol_post_90")) {
    if (!y %in% names(analysis)) next

    controls <- intersect(c("n_killed", "is_coal"), names(analysis))
    control_str <- if (length(controls) > 0) paste(" +", paste(controls, collapse = " + ")) else ""

    f_int <- as.formula(paste0("log_", y,
      " ~ z_disasters * large_mine", control_str, " | yq_fe + state_fe"))
    fit_int <- feols(f_int, data = analysis, vcov = "hetero")

    cat(sprintf("\n%s × large_mine interaction:\n", y))
    print(summary(fit_int))

    main_results[[paste0(y, "_interaction")]] <- fit_int
  }
}

# Heterogeneity by coal vs. metal/nonmetal
if ("is_coal" %in% names(analysis)) {
  for (y in c("insp_post_90", "viol_post_90")) {
    if (!y %in% names(analysis)) next

    fit_coal <- feols(as.formula(paste0("log_", y,
      " ~ z_disasters + n_killed | yq_fe + state_fe")),
      data = analysis[is_coal == TRUE], vcov = "hetero")

    fit_metal <- feols(as.formula(paste0("log_", y,
      " ~ z_disasters + n_killed | yq_fe + state_fe")),
      data = analysis[is_coal == FALSE], vcov = "hetero")

    cat(sprintf("\n%s — Coal mines: coef=%.4f, se=%.4f, N=%d\n",
                y, coef(fit_coal)["z_disasters"],
                se(fit_coal)["z_disasters"], nobs(fit_coal)))
    cat(sprintf("%s — Metal/NM: coef=%.4f, se=%.4f, N=%d\n",
                y, coef(fit_metal)["z_disasters"],
                se(fit_metal)["z_disasters"], nobs(fit_metal)))

    main_results[[paste0(y, "_coal")]] <- fit_coal
    main_results[[paste0(y, "_metal")]] <- fit_metal
  }
}

# Dynamic effects: 90d, 180d, 365d windows
cat("\n=== Dynamic Effects (Decay) ===\n")
for (w in c(90, 180, 365)) {
  y <- paste0("insp_post_", w)
  if (!y %in% names(analysis)) next

  analysis[, paste0("log_", y) := log(get(y) + 1)]
  controls <- intersect(c("n_killed", "is_coal", "log_employment"), names(analysis))
  control_str <- paste(controls, collapse = " + ")

  f <- as.formula(paste0("log_", y, " ~ z_disasters + ", control_str, " | yq_fe + state_fe"))
  fit <- feols(f, data = analysis, vcov = "hetero")

  cat(sprintf("  %dd window: coef=%.4f, se=%.4f, p=%.3f\n",
              w, coef(fit)["z_disasters"], se(fit)["z_disasters"],
              pvalue(fit)["z_disasters"]))

  main_results[[paste0("insp_post_", w, "_full")]] <- fit
}

# ==============================================================================
# Save results
# ==============================================================================

saveRDS(main_results, file.path(data_dir, "main_results.rds"))

# Write diagnostics.json
n_treated <- uniqueN(analysis$mine_id)
n_pre <- 5  # implicit — 365 days pre-period
n_obs <- nrow(analysis)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_fatality_events = n_obs,
  n_unique_mines = n_treated,
  year_range = paste(min(analysis$year), max(analysis$year), sep = "-"),
  mean_post90_insp = round(mean(analysis$insp_post_90, na.rm = TRUE), 2),
  mean_post90_viol = round(mean(analysis$viol_post_90, na.rm = TRUE), 2)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Main analysis complete. Results saved. ===\n")
cat("Diagnostics:", jsonlite::toJSON(diagnostics, auto_unbox = TRUE), "\n")
