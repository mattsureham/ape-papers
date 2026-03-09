# =============================================================================
# 04_robustness.R — Robustness Checks and Sensitivity Analysis
# APEP Paper apep_0547: No-Fault Eviction Abolition and Private Rental Supply
# =============================================================================

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, ym := as.Date(ym)]
panel[, log_price := log(mean_price)]
panel[, log_cat_a := log(n_cat_a + 1)]
panel[, log_cat_b := log(n_cat_b + 1)]
panel[, log_detached := log(n_detached + 1)]
panel[, log_flat := log(n_flat + 1)]

cat("Loaded panel:", nrow(panel), "rows,", uniqueN(panel$la), "LAs\n")

# =============================================================================
# 1. BORDER-COUNTY SUBSAMPLE
# =============================================================================
cat("\n=== 1. Border-County Subsample ===\n")

border_panel <- panel[border == 1]
cat("Border panel:", nrow(border_panel), "rows,", uniqueN(border_panel$la), "LAs\n")
cat("  Wales:", uniqueN(border_panel[wales == 1, la]), "LAs\n")
cat("  England (border):", uniqueN(border_panel[wales == 0, la]), "LAs\n")

m_border <- feols(log_n ~ treated | la_id + ym_id, data = border_panel,
                  cluster = ~la_id)
cat("\nBorder subsample DiD:\n")
print(summary(m_border))

# Event study on border sample
es_border <- feols(log_n ~ i(t_rel, wales, ref = -1) | la_id + ym_id,
                   data = border_panel[t_rel >= -24 & t_rel <= 24],
                   cluster = ~la_id)

es_border_coefs <- as.data.table(coeftable(es_border))
es_border_coefs[, term := rownames(coeftable(es_border))]
es_border_coefs[, t := as.integer(str_extract(term, "-?\\d+"))]
es_border_coefs <- es_border_coefs[!is.na(t)]
setnames(es_border_coefs, c("estimate", "se", "t_stat", "p_value", "term", "t"))
es_border_coefs <- rbind(es_border_coefs,
                          data.table(estimate = 0, se = 0, t_stat = NA, p_value = NA,
                                     term = "ref", t = -1))
setorder(es_border_coefs, t)
fwrite(es_border_coefs, file.path(data_dir, "es_border_coefs.csv"))

# =============================================================================
# 2. EXCLUDE SECOND-HOME LAs
# =============================================================================
cat("\n=== 2. Exclude Second-Home LAs ===\n")

no_sh_panel <- panel[second_home_la == 0]
m_no_sh <- feols(log_n ~ treated | la_id + ym_id, data = no_sh_panel,
                 cluster = ~la_id)
cat("\nExcluding second-home LAs:\n")
print(summary(m_no_sh))

# =============================================================================
# 3. PERMUTATION INFERENCE
# =============================================================================
cat("\n=== 3. Permutation Inference ===\n")

# Randomly assign "treatment" to 22 of all LAs, re-estimate 1000 times
set.seed(42)
n_perms <- 1000
all_las <- unique(panel$la)
n_treat <- 22  # Same as actual treatment

# Get actual treatment effect
actual_beta <- coef(feols(log_n ~ treated | la_id + ym_id, data = panel,
                          cluster = ~la_id))["treated"]

perm_betas <- numeric(n_perms)
cat("Running", n_perms, "permutations...\n")

for (i in seq_len(n_perms)) {
  if (i %% 100 == 0) cat("  Permutation", i, "/", n_perms, "\n")

  # Random assignment
  fake_treat <- sample(all_las, n_treat)
  panel[, perm_wales := as.integer(la %in% fake_treat)]
  panel[, perm_treated := perm_wales * post]

  # Estimate
  perm_fit <- tryCatch(
    feols(log_n ~ perm_treated | la_id + ym_id, data = panel, cluster = ~la_id),
    error = function(e) NULL
  )

  if (!is.null(perm_fit)) {
    perm_betas[i] <- coef(perm_fit)["perm_treated"]
  } else {
    perm_betas[i] <- NA
  }
}

# Remove failed permutations
perm_betas <- perm_betas[!is.na(perm_betas)]

# Exact p-value
perm_p <- mean(abs(perm_betas) >= abs(actual_beta))
cat("\nPermutation inference:\n")
cat("  Actual beta:", round(actual_beta, 4), "\n")
cat("  Mean permuted beta:", round(mean(perm_betas), 4), "\n")
cat("  SD permuted beta:", round(sd(perm_betas), 4), "\n")
cat("  Exact p-value (two-sided):", round(perm_p, 4), "\n")

# Save permutation distribution
perm_dist <- data.table(beta = perm_betas)
perm_dist[, actual := actual_beta]
fwrite(perm_dist, file.path(data_dir, "permutation_distribution.csv"))

# Clean up temporary columns
panel[, c("perm_wales", "perm_treated") := NULL]

# =============================================================================
# 4. LEAVE-ONE-OUT (Welsh LAs)
# =============================================================================
cat("\n=== 4. Leave-One-Out ===\n")

welsh_la_list <- unique(panel[wales == 1, la])
loo_results <- data.table(
  dropped_la = character(0),
  estimate = numeric(0),
  se = numeric(0)
)

for (dropped in welsh_la_list) {
  loo_panel <- panel[la != dropped]
  loo_fit <- feols(log_n ~ treated | la_id + ym_id, data = loo_panel,
                   cluster = ~la_id)
  loo_results <- rbind(loo_results,
                        data.table(dropped_la = dropped,
                                   estimate = coef(loo_fit)["treated"],
                                   se = se(loo_fit)["treated"]))
}

cat("\nLeave-one-out results:\n")
cat("  Range of estimates:", round(min(loo_results$estimate), 4), "to",
    round(max(loo_results$estimate), 4), "\n")
cat("  Full-sample estimate:", round(actual_beta, 4), "\n")
cat("  Max deviation:", round(max(abs(loo_results$estimate - actual_beta)), 4), "\n")

fwrite(loo_results, file.path(data_dir, "leave_one_out.csv"))

# =============================================================================
# 5. WILD CLUSTER BOOTSTRAP
# =============================================================================
cat("\n=== 5. Wild Cluster Bootstrap ===\n")

# Use fwildclusterboot for valid inference with few clusters
m_for_boot <- feols(log_n ~ treated | la_id + ym_id, data = panel,
                    cluster = ~la_id)

tryCatch({
  set.seed(2024)
  boot_result <- boottest(m_for_boot, param = "treated",
                           B = 999, clustid = "la_id",
                           type = "webb")
  cat("\nWild cluster bootstrap (Webb weights):\n")
  cat("  Point estimate:", round(boot_result$point_estimate, 4), "\n")
  cat("  95% CI:", round(boot_result$conf_int[1], 4), "to",
      round(boot_result$conf_int[2], 4), "\n")
  cat("  Bootstrap p-value:", round(boot_result$p_val, 4), "\n")

  boot_summary <- data.table(
    estimate = boot_result$point_estimate,
    ci_lo = boot_result$conf_int[1],
    ci_hi = boot_result$conf_int[2],
    p_value = boot_result$p_val
  )
  fwrite(boot_summary, file.path(data_dir, "wild_bootstrap.csv"))
}, error = function(e) {
  cat("Wild bootstrap failed:", e$message, "\n")
  cat("Proceeding without bootstrap results.\n")
})

# =============================================================================
# 6. ANTICIPATION TEST
# =============================================================================
cat("\n=== 6. Anticipation Test ===\n")

# Exclude June-November 2022 (implementation date announced June 2022)
no_antic_panel <- panel[ym < as.Date("2022-06-01") | ym >= as.Date("2022-12-01")]
m_no_antic <- feols(log_n ~ treated | la_id + ym_id, data = no_antic_panel,
                    cluster = ~la_id)
cat("\nExcluding anticipation window (Jun-Nov 2022):\n")
print(summary(m_no_antic))

# =============================================================================
# 7. RAMBACHAN-ROTH SENSITIVITY
# =============================================================================
cat("\n=== 7. Rambachan-Roth Sensitivity ===\n")

tryCatch({
  # Get the event study for HonestDiD
  # Need pre and post coefficients
  es_for_honest <- feols(log_n ~ i(t_rel, wales, ref = -1) | la_id + ym_id,
                          data = panel[t_rel >= -12 & t_rel <= 24],
                          cluster = ~la_id)

  # Extract beta and sigma
  es_honest_coefs <- coeftable(es_for_honest)
  beta_hat <- es_honest_coefs[, 1]
  sigma_hat <- vcov(es_for_honest)

  # Identify pre and post periods
  coef_names <- rownames(es_honest_coefs)
  pre_idx <- grep("::-[2-9]$|::-1[0-2]$", coef_names)
  post_idx <- grep("::[0-9]$|::[1-2][0-9]$", coef_names)

  if (length(pre_idx) > 1 && length(post_idx) > 0) {
    # HonestDiD requires at least 2 pre-periods
    l_vec <- basisVector(index = 1, size = length(post_idx))

    honest_result <- createSensitivityResults(
      betahat = beta_hat,
      sigma = sigma_hat,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 0.05, by = 0.01),
      l_vec = l_vec
    )

    cat("Rambachan-Roth bounds (first post-period):\n")
    print(honest_result)

    honest_dt <- as.data.table(honest_result)
    fwrite(honest_dt, file.path(data_dir, "rambachan_roth.csv"))
  } else {
    cat("Insufficient pre/post periods for HonestDiD.\n")
  }
}, error = function(e) {
  cat("HonestDiD analysis failed:", e$message, "\n")
  cat("Proceeding without sensitivity bounds.\n")
})

# =============================================================================
# 8. SAVE ALL ROBUSTNESS RESULTS
# =============================================================================
cat("\n=== Saving Robustness Results ===\n")

rob_summary <- data.table(
  test = c("Full sample", "Border counties only", "Excl. second-home LAs",
           "Excl. anticipation window",
           "Permutation p-value", "Wild bootstrap p-value"),
  estimate = c(
    actual_beta,
    coef(m_border)["treated"],
    coef(m_no_sh)["treated"],
    coef(m_no_antic)["treated"],
    actual_beta,
    actual_beta
  ),
  se = c(
    se(feols(log_n ~ treated | la_id + ym_id, data = panel, cluster = ~la_id))["treated"],
    se(m_border)["treated"],
    se(m_no_sh)["treated"],
    se(m_no_antic)["treated"],
    NA_real_,
    NA_real_
  ),
  p_value = c(
    fixest::pvalue(feols(log_n ~ treated | la_id + ym_id, data = panel, cluster = ~la_id))["treated"],
    fixest::pvalue(m_border)["treated"],
    fixest::pvalue(m_no_sh)["treated"],
    fixest::pvalue(m_no_antic)["treated"],
    perm_p,
    NA_real_
  )
)

# Try to add bootstrap p-value
if (file.exists(file.path(data_dir, "wild_bootstrap.csv"))) {
  boot_res <- fread(file.path(data_dir, "wild_bootstrap.csv"))
  rob_summary[test == "Wild bootstrap p-value", p_value := boot_res$p_value]
}

fwrite(rob_summary, file.path(data_dir, "robustness_summary.csv"))
cat("\nRobustness summary:\n")
print(rob_summary)

cat("\n=== Robustness analysis complete ===\n")
