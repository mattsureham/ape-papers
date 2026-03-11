## 04_robustness.R — Robustness checks
## APEP-0596: Panama Canal Drought and US Port Trade Diversion

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, date := as.Date(date)]

cat(sprintf("Analysis panel: %s rows, %d ports\n",
            format(nrow(panel), big.mark = ","), uniqueN(panel$PORT)))

# ============================================================
# 1. WILD CLUSTER BOOTSTRAP (few-cluster inference)
# ============================================================

cat("\n=== Wild Cluster Bootstrap ===\n")

# Main specification
m_main <- feols(log_imports ~ treatment | PORT + year_month,
                data = panel, cluster = ~PORT)

# Manual wild cluster bootstrap (Rademacher weights)
set.seed(123)
n_boot <- 999
true_t <- coef(m_main)["treatment"] / se(m_main)["treatment"]

# Get cluster IDs
clusters <- unique(panel$PORT)
n_clusters <- length(clusters)

# Demean Y within port and year-month (to get restricted residuals)
panel[, resid_main := log_imports - fitted(m_main)]

boot_t_stats <- numeric(n_boot)
for (b in 1:n_boot) {
  if (b %% 200 == 0) cat(sprintf("  Bootstrap %d/%d\n", b, n_boot))

  # Rademacher weights by cluster
  weights <- sample(c(-1, 1), n_clusters, replace = TRUE)
  names(weights) <- clusters

  # Create wild bootstrap Y
  panel[, boot_y := fitted(m_main) + resid_main * weights[PORT]]

  # Re-estimate
  m_boot <- tryCatch(
    feols(boot_y ~ treatment | PORT + year_month,
          data = panel, cluster = ~PORT),
    error = function(e) NULL
  )

  if (!is.null(m_boot)) {
    boot_t_stats[b] <- coef(m_boot)["treatment"] / se(m_boot)["treatment"]
  } else {
    boot_t_stats[b] <- NA
  }
}
panel[, c("resid_main", "boot_y") := NULL]

boot_t_stats <- boot_t_stats[!is.na(boot_t_stats)]
boot_pval <- mean(abs(boot_t_stats) >= abs(true_t))

# Bootstrap confidence interval (percentile method on t-stats)
boot_ci_low <- coef(m_main)["treatment"] -
  quantile(boot_t_stats, 0.975) * se(m_main)["treatment"]
boot_ci_high <- coef(m_main)["treatment"] -
  quantile(boot_t_stats, 0.025) * se(m_main)["treatment"]

cat(sprintf("Wild cluster bootstrap p-value: %.4f\n", boot_pval))
cat(sprintf("Bootstrap CI: [%.4f, %.4f]\n", boot_ci_low, boot_ci_high))

boot_summary <- data.table(
  test = "Wild Cluster Bootstrap",
  coef = coef(m_main)["treatment"],
  se_cluster = se(m_main)["treatment"],
  p_boot = boot_pval,
  ci_boot_low = boot_ci_low,
  ci_boot_high = boot_ci_high
)
fwrite(boot_summary, file.path(data_dir, "bootstrap_results.csv"))

# ============================================================
# 2. RANDOMIZATION INFERENCE
# ============================================================

cat("\n=== Randomization Inference ===\n")

# Permute canal_share across ports
set.seed(42)
n_perms <- 999
true_coef <- coef(m_main)["treatment"]

# Get port-level canal shares
port_shares <- unique(panel[, .(PORT, canal_share)])
perm_coefs <- numeric(n_perms)

for (i in 1:n_perms) {
  if (i %% 100 == 0) cat(sprintf("  Permutation %d/%d\n", i, n_perms))

  # Shuffle canal shares across ports
  shuffled <- copy(port_shares)
  shuffled[, canal_share_perm := sample(canal_share)]

  panel_perm <- merge(panel, shuffled[, .(PORT, canal_share_perm)], by = "PORT")
  panel_perm[, treatment_perm := canal_share_perm * drought_intensity]

  m_perm <- feols(log_imports ~ treatment_perm | PORT + year_month,
                  data = panel_perm, cluster = ~PORT)

  perm_coefs[i] <- coef(m_perm)["treatment_perm"]
}

ri_pval <- mean(abs(perm_coefs) >= abs(true_coef))
cat(sprintf("Randomization Inference p-value: %.4f\n", ri_pval))
cat(sprintf("True coefficient: %.4f\n", true_coef))
cat(sprintf("Permutation distribution: mean=%.4f, sd=%.4f\n",
            mean(perm_coefs), sd(perm_coefs)))

ri_data <- data.table(perm_coef = perm_coefs)
ri_data[, true_coef := true_coef]
fwrite(ri_data, file.path(data_dir, "ri_permutation_coefs.csv"))

ri_summary <- data.table(
  test = "Randomization Inference",
  true_coef = true_coef,
  ri_pval = ri_pval,
  n_perms = n_perms,
  perm_mean = mean(perm_coefs),
  perm_sd = sd(perm_coefs)
)
fwrite(ri_summary, file.path(data_dir, "ri_summary.csv"))

# ============================================================
# 3. LEAVE-ONE-OUT
# ============================================================

cat("\n=== Leave-One-Out ===\n")

ports <- unique(panel$PORT)
loo_results <- data.table(
  excluded_port = character(),
  excluded_port_name = character(),
  coef = numeric(),
  se = numeric()
)

for (p in ports) {
  m_loo <- feols(log_imports ~ treatment | PORT + year_month,
                 data = panel[PORT != p], cluster = ~PORT)

  port_name <- panel[PORT == p, first(PORT_NAME)]
  loo_results <- rbind(loo_results, data.table(
    excluded_port = p,
    excluded_port_name = port_name,
    coef = coef(m_loo)["treatment"],
    se = se(m_loo)["treatment"]
  ))
}

cat(sprintf("LOO coefficient range: [%.4f, %.4f]\n",
            min(loo_results$coef), max(loo_results$coef)))
cat(sprintf("Full-sample coefficient: %.4f\n", true_coef))

fwrite(loo_results, file.path(data_dir, "loo_results.csv"))

# ============================================================
# 4. PLACEBO TIMING TEST
# ============================================================

cat("\n=== Placebo Timing Test ===\n")

# Fake treatment: July 2021 – August 2022 (same duration as actual drought)
panel[, placebo_drought := fifelse(
  year_month >= "2021-07" & year_month <= "2022-08", 1L, 0L)]
panel[, placebo_treatment := canal_share * placebo_drought]

# Only use pre-actual-drought data
panel_pre <- panel[year_month < "2023-07"]

m_placebo <- feols(log_imports ~ placebo_treatment | PORT + year_month,
                   data = panel_pre, cluster = ~PORT)

cat("Placebo timing test (should be null):\n")
summary(m_placebo)

placebo_results <- data.table(
  test = "Placebo Timing (2021-2022)",
  coef = coef(m_placebo)["placebo_treatment"],
  se = se(m_placebo)["placebo_treatment"],
  pval = 2 * pnorm(-abs(coef(m_placebo)["placebo_treatment"] /
                          se(m_placebo)["placebo_treatment"])),
  n = m_placebo$nobs
)
fwrite(placebo_results, file.path(data_dir, "placebo_results.csv"))

# ============================================================
# 5. EUROPEAN ORIGIN PLACEBO
# ============================================================

cat("\n=== European Origin Placebo ===\n")

# European imports should NOT be differentially affected by Canal share
m_euro_placebo <- feols(log_euro_imports ~ treatment | PORT + year_month,
                        data = panel, cluster = ~PORT)

cat("European imports placebo (should be null):\n")
summary(m_euro_placebo)

euro_placebo <- data.table(
  test = "European Origin Placebo",
  coef = coef(m_euro_placebo)["treatment"],
  se = se(m_euro_placebo)["treatment"],
  pval = 2 * pnorm(-abs(coef(m_euro_placebo)["treatment"] /
                          se(m_euro_placebo)["treatment"])),
  n = m_euro_placebo$nobs
)

# ============================================================
# 6. ALTERNATIVE SPECIFICATIONS
# ============================================================

cat("\n=== Alternative Specifications ===\n")

# A. Levels instead of logs
m_levels <- feols(total_imports ~ treatment | PORT + year_month,
                  data = panel, cluster = ~PORT)

# B. Port × calendar-month FE (absorbs seasonality by port)
m_season <- feols(log_imports ~ treatment | PORT^month + year_month,
                  data = panel, cluster = ~PORT)

# C. Exclude 2020 COVID year
m_nocovid <- feols(log_imports ~ treatment | PORT + year_month,
                   data = panel[year != 2020], cluster = ~PORT)

# D. Port-specific linear trends
panel[, port_trend := time_idx]
m_trends <- feols(log_imports ~ treatment | PORT + year_month + PORT[port_trend],
                  data = panel, cluster = ~PORT)

# E. Binary treatment (high vs low Canal share × drought)
m_binary <- feols(log_imports ~ i(high_canal, drought_intensity) | PORT + year_month,
                  data = panel, cluster = ~PORT)

alt_results <- data.table(
  spec = c("Levels", "Port x Month FE", "Excl. COVID",
           "Port Trends", "Binary Treatment"),
  coef = c(coef(m_levels)["treatment"],
           coef(m_season)["treatment"],
           coef(m_nocovid)["treatment"],
           coef(m_trends)["treatment"],
           coef(m_binary)[1]),
  se = c(se(m_levels)["treatment"],
         se(m_season)["treatment"],
         se(m_nocovid)["treatment"],
         se(m_trends)["treatment"],
         se(m_binary)[1])
)
alt_results[, pval := 2 * pnorm(-abs(coef / se))]

fwrite(alt_results, file.path(data_dir, "alt_spec_results.csv"))
fwrite(euro_placebo, file.path(data_dir, "euro_placebo_results.csv"))

# ============================================================
# 7. HOUTHI CRISIS CONTROL
# ============================================================

cat("\n=== Houthi Red Sea Crisis Control ===\n")

# Houthi attacks began Nov 2023 — primarily affect Europe-Asia routes
# Test: exclude Nov 2023 onward and re-estimate on just July-Oct 2023
panel_pre_houthi <- panel[year_month < "2023-11" | year_month > "2024-02"]

m_houthi <- feols(log_imports ~ treatment | PORT + year_month,
                  data = panel_pre_houthi, cluster = ~PORT)

cat("Excluding Houthi overlap months (Nov 2023 - Feb 2024):\n")
summary(m_houthi)

# ============================================================
# 8. JOINT PRE-TREND F-TEST
# ============================================================

cat("\n=== Joint Pre-Trend F-Test ===\n")

# Load event study model from main analysis
load(file.path(data_dir, "main_models.RData"))

# Get pre-treatment coefficients from event study
es_coefs_all <- coef(es_model)
es_names <- names(es_coefs_all)

# Pre-treatment coefficients: event_time < 0 (excluding reference period -1)
pre_coefs_idx <- grep("::-[0-9]+:", es_names)
pre_coef_names <- es_names[pre_coefs_idx]
n_pre <- length(pre_coef_names)

cat(sprintf("  Number of pre-treatment coefficients: %d\n", n_pre))

# Joint Wald test of pre-treatment coefficients = 0
if (n_pre > 0) {
  wald_result <- wald(es_model, pre_coef_names)
  f_stat <- wald_result$stat
  f_pval <- wald_result$p
  f_df1 <- wald_result$df1
  f_df2 <- wald_result$df2

  cat(sprintf("  Joint F-test: F(%d, %d) = %.4f, p = %.4f\n",
              f_df1, f_df2, f_stat, f_pval))

  pretrend_test <- data.table(
    test = "Joint pre-trend F-test",
    f_stat = f_stat,
    p_value = f_pval,
    df1 = f_df1,
    df2 = f_df2,
    n_pre_coefs = n_pre,
    result = ifelse(f_pval < 0.05, "Reject (pre-trends detected)",
                    "Fail to reject (no systematic pre-trends)")
  )
  fwrite(pretrend_test, file.path(data_dir, "pretrend_ftest.csv"))
}

# ============================================================
# 9. MINIMUM DETECTABLE EFFECT (MDE)
# ============================================================

cat("\n=== Minimum Detectable Effect ===\n")

# MDE = 2.8 * SE (for 80% power at 5% significance, two-sided)
se_main_coef <- se(m_main)["treatment"]
mde_raw <- 2.8 * se_main_coef

cat(sprintf("  SE of treatment coefficient: %.4f\n", se_main_coef))
cat(sprintf("  MDE (raw coefficient): %.4f\n", mde_raw))

# Translate MDE to economically meaningful contrast:
# Effect of going from 25th to 75th percentile Canal share at peak drought
canal_shares <- unique(panel[, .(PORT, canal_share)])$canal_share
p25_share <- quantile(canal_shares, 0.25)
p75_share <- quantile(canal_shares, 0.75)
iqr_share <- p75_share - p25_share
peak_drought <- max(panel$drought_intensity, na.rm = TRUE)

# Treatment contrast = (p75 - p25) * peak_drought
treatment_contrast <- iqr_share * peak_drought
implied_effect_at_contrast <- coef(m_main)["treatment"] * treatment_contrast
implied_mde_at_contrast <- mde_raw * treatment_contrast
implied_ci_low <- (coef(m_main)["treatment"] - 1.96 * se_main_coef) * treatment_contrast
implied_ci_high <- (coef(m_main)["treatment"] + 1.96 * se_main_coef) * treatment_contrast

# Convert to percentage: exp(x) - 1 ≈ x for small x
cat(sprintf("  Treatment contrast (IQR share × peak drought): %.4f\n", treatment_contrast))
cat(sprintf("  Implied effect at IQR/peak: %.4f log points (%.1f%%)\n",
            implied_effect_at_contrast, 100 * (exp(implied_effect_at_contrast) - 1)))
cat(sprintf("  MDE at IQR/peak: %.4f log points (%.1f%%)\n",
            implied_mde_at_contrast, 100 * (exp(implied_mde_at_contrast) - 1)))
cat(sprintf("  95%% CI at IQR/peak: [%.4f, %.4f] log points\n",
            implied_ci_low, implied_ci_high))
cat(sprintf("  95%% CI at IQR/peak: [%.1f%%, %.1f%%]\n",
            100 * (exp(implied_ci_low) - 1), 100 * (exp(implied_ci_high) - 1)))

mde_results <- data.table(
  se_treatment = se_main_coef,
  mde_raw = mde_raw,
  p25_canal_share = p25_share,
  p75_canal_share = p75_share,
  iqr_canal_share = iqr_share,
  peak_drought_intensity = peak_drought,
  treatment_contrast = treatment_contrast,
  implied_effect = implied_effect_at_contrast,
  implied_mde = implied_mde_at_contrast,
  ci_low = implied_ci_low,
  ci_high = implied_ci_high,
  ci_low_pct = 100 * (exp(implied_ci_low) - 1),
  ci_high_pct = 100 * (exp(implied_ci_high) - 1)
)
fwrite(mde_results, file.path(data_dir, "mde_results.csv"))

# ============================================================
# 10. WINSORIZED SPECIFICATION (medium-port anomaly)
# ============================================================

cat("\n=== Winsorized Specification ===\n")

# Winsorize log_imports at 1st and 99th percentiles
q01 <- quantile(panel$log_imports, 0.01, na.rm = TRUE)
q99 <- quantile(panel$log_imports, 0.99, na.rm = TRUE)
panel[, log_imports_wins := pmin(pmax(log_imports, q01), q99)]

m_wins <- feols(log_imports_wins ~ treatment | PORT + year_month,
                data = panel, cluster = ~PORT)

cat("Winsorized specification:\n")
summary(m_wins)

wins_results <- data.table(
  spec = "Winsorized (1st/99th pctile)",
  coef = coef(m_wins)["treatment"],
  se = se(m_wins)["treatment"],
  pval = 2 * pnorm(-abs(coef(m_wins)["treatment"] / se(m_wins)["treatment"])),
  n = m_wins$nobs
)
fwrite(wins_results, file.path(data_dir, "winsorized_results.csv"))

# ============================================================
# 11. Save all robustness model objects
# ============================================================

save(m_main, m_placebo, m_euro_placebo,
     m_levels, m_season, m_nocovid, m_trends, m_binary, m_houthi,
     m_wins,
     loo_results,
     file = file.path(data_dir, "robustness_models.RData"))

# Compile all robustness results
all_robust <- rbind(
  boot_summary[, .(test, coef, pval = p_boot)],
  ri_summary[, .(test, coef = true_coef, pval = ri_pval)],
  placebo_results[, .(test, coef, pval)],
  euro_placebo[, .(test, coef, pval)],
  fill = TRUE
)
fwrite(all_robust, file.path(data_dir, "all_robustness_summary.csv"))

cat("\n=== Robustness checks complete ===\n")
