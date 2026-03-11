## 04_robustness.R — Robustness checks
## apep_0594: Spain's 2022 Temporary Contract Ban

source("00_packages.R")

cat("=== Robustness Checks ===\n")

# Load data
dt <- fread(file.path(data_dir, "analysis_panel.csv"))
dt[, region_f := as.factor(region)]
dt[, time_f := as.factor(time_num)]
dt[, log_total := log(wage_earners_total)]

# =============================================================================
# 1. WILD CLUSTER BOOTSTRAP (address 19 clusters)
# =============================================================================

cat("\n--- Wild Cluster Bootstrap ---\n")

m1 <- feols(temp_share ~ treat | region_f + time_f,
            data = dt, cluster = ~region_f)

# Wild cluster bootstrap — use region_id to avoid encoding issues
dt[, region_id := as.character(as.integer(as.factor(region)))]
dt[, region_id_f := as.factor(region_id)]
m1_boot <- feols(temp_share ~ treat | region_id_f + time_f,
                 data = dt, cluster = ~region_id_f)

set.seed(42)
boot_result <- tryCatch({
  boottest(m1_boot, param = "treat", clustid = "region_id_f",
           B = 9999, type = "webb")
}, error = function(e) {
  cat("  Bootstrap error:", e$message, "\n")
  NULL
})

if (!is.null(boot_result)) {
  cat("Wild bootstrap p-value:", boot_result$p_val, "\n")
  cat("Bootstrap CI:", boot_result$conf_int, "\n")
}

# Same for permanent share
m2 <- feols(perm_share ~ treat | region_f + time_f,
            data = dt, cluster = ~region_f)
m2_boot <- feols(perm_share ~ treat | region_id_f + time_f,
                 data = dt, cluster = ~region_id_f)

boot_perm <- tryCatch({
  boottest(m2_boot, param = "treat", clustid = "region_id_f",
           B = 9999, type = "webb")
}, error = function(e) {
  cat("  Perm bootstrap error:", e$message, "\n")
  NULL
})

if (!is.null(boot_perm)) {
  cat("Perm share bootstrap p-value:", boot_perm$p_val, "\n")
}

# Employment
m3 <- feols(log_total ~ treat | region_f + time_f,
            data = dt, cluster = ~region_f)
m3_boot <- feols(log_total ~ treat | region_id_f + time_f,
                 data = dt, cluster = ~region_id_f)

boot_emp <- tryCatch({
  boottest(m3_boot, param = "treat", clustid = "region_id_f",
           B = 9999, type = "webb")
}, error = function(e) {
  cat("  Emp bootstrap error:", e$message, "\n")
  NULL
})

if (!is.null(boot_emp)) {
  cat("Employment bootstrap p-value:", boot_emp$p_val, "\n")
}

# Save bootstrap results — use fixest::pvalue explicitly to avoid scales conflict
boot_results <- data.table(
  outcome = c("Temporary Share", "Permanent Share", "Log Employment"),
  crse_pval = c(fixest::pvalue(m1)["treat"], fixest::pvalue(m2)["treat"],
                fixest::pvalue(m3)["treat"]),
  boot_pval = c(
    if (!is.null(boot_result)) boot_result$p_val else NA_real_,
    if (!is.null(boot_perm)) boot_perm$p_val else NA_real_,
    if (!is.null(boot_emp)) boot_emp$p_val else NA_real_
  )
)

fwrite(boot_results, file.path(data_dir, "bootstrap_results.csv"))

# =============================================================================
# 2. RANDOMIZATION INFERENCE: Permute treatment intensity
# =============================================================================

cat("\n--- Randomization Inference ---\n")

set.seed(123)
n_perms <- 1000
observed_beta <- coef(m1)["treat"]

ri_betas <- numeric(n_perms)
regions <- unique(dt$region)

for (p in seq_len(n_perms)) {
  # Shuffle pre_temp_share across regions
  perm_shares <- sample(unique(dt$pre_temp_share))
  perm_map <- setNames(perm_shares, regions)
  dt_perm <- copy(dt)
  dt_perm[, pre_temp_share_perm := perm_map[region]]
  dt_perm[, treat_perm := pre_temp_share_perm * post]

  m_perm <- feols(temp_share ~ treat_perm | region_f + time_f,
                  data = dt_perm, warn = FALSE)
  ri_betas[p] <- coef(m_perm)["treat_perm"]
}

ri_pvalue <- mean(abs(ri_betas) >= abs(observed_beta))
cat("RI p-value (two-sided):", ri_pvalue, "\n")
cat("RI quantiles:", quantile(ri_betas, c(0.025, 0.5, 0.975)), "\n")

ri_results <- data.table(
  observed_beta = observed_beta,
  ri_pvalue = ri_pvalue,
  ri_mean = mean(ri_betas),
  ri_sd = sd(ri_betas),
  ri_q025 = quantile(ri_betas, 0.025),
  ri_q975 = quantile(ri_betas, 0.975)
)
fwrite(ri_results, file.path(data_dir, "ri_results.csv"))

# Save RI distribution for figure
fwrite(data.table(beta = ri_betas), file.path(data_dir, "ri_distribution.csv"))

# =============================================================================
# 3. LEAVE-ONE-OUT: Drop each region
# =============================================================================

cat("\n--- Leave-One-Out ---\n")

loo_results <- lapply(regions, function(r) {
  dt_loo <- dt[region != r]
  m_loo <- feols(temp_share ~ treat | region_f + time_f,
                 data = dt_loo, cluster = ~region_f)
  data.table(
    dropped_region = r,
    beta = coef(m_loo)["treat"],
    se = se(m_loo)["treat"],
    n_obs = m_loo$nobs
  )
})
loo_dt <- rbindlist(loo_results)
loo_dt[, ci_lo := beta - 1.96 * se]
loo_dt[, ci_hi := beta + 1.96 * se]

cat("LOO range:", round(range(loo_dt$beta), 4), "\n")
print(loo_dt[order(beta)])

fwrite(loo_dt, file.path(data_dir, "loo_results.csv"))

# =============================================================================
# 4. PLACEBO OUTCOME: Self-employment (shouldn't be affected)
# =============================================================================

cat("\n--- Placebo: Employment rate (if available) ---\n")

if ("employment" %in% names(dt) && sum(!is.na(dt$employment)) > 100) {
  m_placebo <- feols(employment ~ treat | region_f + time_f,
                     data = dt, cluster = ~region_f)
  cat("Placebo (employment rate) beta:", coef(m_placebo)["treat"],
      "SE:", se(m_placebo)["treat"],
      "p:", pvalue(m_placebo)["treat"], "\n")
} else {
  cat("Employment rate not available for placebo test\n")
}

# =============================================================================
# 5. ALTERNATIVE TREATMENT WINDOWS
# =============================================================================

cat("\n--- Alternative treatment windows ---\n")

# Test with 2022Q1 as treatment start (reform announced Dec 2021)
dt[, post_early := as.integer(year >= 2022)]
dt[, treat_early := pre_temp_share * post_early]
m_early <- feols(temp_share ~ treat_early | region_f + time_f,
                 data = dt, cluster = ~region_f)
cat("Early treatment (2022Q1):", round(coef(m_early)["treat_early"], 4),
    "SE:", round(se(m_early)["treat_early"], 4), "\n")

# Test with 2022Q3 as treatment start (allow adjustment)
dt[, post_late := as.integer(year > 2022 | (year == 2022 & quarter >= 3))]
dt[, treat_late := pre_temp_share * post_late]
m_late <- feols(temp_share ~ treat_late | region_f + time_f,
                data = dt, cluster = ~region_f)
cat("Late treatment (2022Q3):", round(coef(m_late)["treat_late"], 4),
    "SE:", round(se(m_late)["treat_late"], 4), "\n")

# =============================================================================
# 6. SHORTER PRE-PERIOD (exclude pre-2016 for COVID-free comparison)
# =============================================================================

cat("\n--- Shorter pre-period (2016+) ---\n")

dt_short <- dt[year >= 2016]
m_short <- feols(temp_share ~ treat | region_f + time_f,
                 data = dt_short, cluster = ~region_f)
cat("Short pre-period beta:", round(coef(m_short)["treat"], 4),
    "SE:", round(se(m_short)["treat"], 4), "\n")

# =============================================================================
# 7. POPULATION-WEIGHTED REGRESSION
# =============================================================================

cat("\n--- Population-weighted ---\n")

m_weighted <- feols(temp_share ~ treat | region_f + time_f,
                    data = dt, cluster = ~region_f,
                    weights = ~pre_total)
cat("Weighted beta:", round(coef(m_weighted)["treat"], 4),
    "SE:", round(se(m_weighted)["treat"], 4), "\n")

# Save all robustness results
alt_specs <- data.table(
  specification = c("Baseline", "Early treatment (2022Q1)",
                    "Late treatment (2022Q3)", "Short pre-period (2016+)",
                    "Population-weighted"),
  beta = c(coef(m1)["treat"], coef(m_early)["treat_early"],
           coef(m_late)["treat_late"], coef(m_short)["treat"],
           coef(m_weighted)["treat"]),
  se = c(se(m1)["treat"], se(m_early)["treat_early"],
         se(m_late)["treat_late"], se(m_short)["treat"],
         se(m_weighted)["treat"]),
  n = c(m1$nobs, m_early$nobs, m_late$nobs, m_short$nobs, m_weighted$nobs)
)
alt_specs[, ci_lo := beta - 1.96 * se]
alt_specs[, ci_hi := beta + 1.96 * se]

cat("\nAlternative specifications:\n")
print(alt_specs)

fwrite(alt_specs, file.path(data_dir, "robustness_alt_specs.csv"))

# Save weighted model for use in main results table
save(m_weighted, file = file.path(data_dir, "weighted_model.RData"))

# =============================================================================
# 8. REGION-SPECIFIC LINEAR TRENDS
# =============================================================================

cat("\n--- Region-specific linear trends ---\n")

dt[, trend := time_num]
m_trends <- feols(temp_share ~ treat + i(region_f, trend) | region_f + time_f,
                  data = dt, cluster = ~region_f)
cat("With region trends: beta =", round(coef(m_trends)["treat"], 4),
    "SE =", round(se(m_trends)["treat"], 4), "\n")

# =============================================================================
# 9. EXCLUDE COVID QUARTERS (2020-2021)
# =============================================================================

cat("\n--- Excluding COVID quarters ---\n")

dt_nocovid <- dt[!(year %in% c(2020, 2021))]
m_nocovid <- feols(temp_share ~ treat | region_f + time_f,
                   data = dt_nocovid, cluster = ~region_f)
cat("Excluding 2020-2021: beta =", round(coef(m_nocovid)["treat"], 4),
    "SE =", round(se(m_nocovid)["treat"], 4),
    "N =", m_nocovid$nobs, "\n")

# =============================================================================
# 10. WILD BOOTSTRAP FOR WEIGHTED SPECIFICATION
# =============================================================================

cat("\n--- Wild bootstrap for weighted spec ---\n")

m_weighted_boot <- feols(temp_share ~ treat | region_id_f + time_f,
                         data = dt, cluster = ~region_id_f,
                         weights = ~pre_total)

set.seed(42)
boot_weighted <- tryCatch({
  boottest(m_weighted_boot, param = "treat", clustid = "region_id_f",
           B = 9999, type = "webb", engine = "R")
}, error = function(e) {
  cat("Bootstrap error:", e$message, "\n")
  NULL
})

if (!is.null(boot_weighted)) {
  cat("Weighted bootstrap p-value:", round(boot_weighted$p_val, 3), "\n")
} else {
  cat("Weighted bootstrap failed\n")
}

# Update alt_specs with new robustness checks
new_specs <- data.table(
  specification = c("Region-specific trends", "Exclude COVID (2020-21)"),
  beta = c(coef(m_trends)["treat"], coef(m_nocovid)["treat"]),
  se = c(se(m_trends)["treat"], se(m_nocovid)["treat"]),
  n = c(m_trends$nobs, m_nocovid$nobs)
)
new_specs[, ci_lo := beta - 1.96 * se]
new_specs[, ci_hi := beta + 1.96 * se]

alt_specs <- rbind(alt_specs, new_specs)
fwrite(alt_specs, file.path(data_dir, "robustness_alt_specs.csv"))

# Save weighted bootstrap p-value
boot_weighted_pval <- if (!is.null(boot_weighted)) boot_weighted$p_val else NA
fwrite(data.table(boot_pval = boot_weighted_pval),
       file.path(data_dir, "weighted_bootstrap.csv"))

cat("\n=== Robustness checks complete ===\n")
