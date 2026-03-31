# 04_robustness.R — Robustness checks for Moldova banking crisis
# apep_1213

source("00_packages.R")

load("../data/main_results.RData")  # panel_est, results

cat("=== Robustness Checks ===\n")

# ============================================================
# 1. Wild cluster bootstrap (35 clusters)
# ============================================================
cat("\n--- Wild cluster bootstrap ---\n")

# Main spec: log_emp ~ bem_dep_z_post | raion_code + year_f
m_main <- feols(log_emp ~ bem_dep_z_post | raion_code + year_f,
                data = panel_est, cluster = ~raion_code)

boot_result <- tryCatch({
  boottest(m_main, param = "bem_dep_z_post",
           B = 9999, clustid = "raion_code",
           type = "webb")
}, error = function(e) {
  cat(sprintf("  Bootstrap failed: %s\n", e$message))
  NULL
})

if (!is.null(boot_result)) {
  cat(sprintf("  Wild cluster bootstrap p-value: %.4f\n", boot_result$p_val))
  cat(sprintf("  Bootstrap CI: [%.4f, %.4f]\n", boot_result$conf_int[1], boot_result$conf_int[2]))
} else {
  cat("  Wild cluster bootstrap could not be computed\n")
}

# Also bootstrap the region×year FE spec
panel_est[, region_year := paste0(region, "_", year)]
m_region <- feols(log_emp ~ bem_dep_z_post | raion_code + region_year,
                  data = panel_est, cluster = ~raion_code)

boot_region <- tryCatch({
  boottest(m_region, param = "bem_dep_z_post",
           B = 9999, clustid = "raion_code",
           type = "webb")
}, error = function(e) {
  cat(sprintf("  Bootstrap (region×year) failed: %s\n", e$message))
  NULL
})

if (!is.null(boot_region)) {
  cat(sprintf("  Region×Year bootstrap p-value: %.4f\n", boot_region$p_val))
  cat(sprintf("  Bootstrap CI: [%.4f, %.4f]\n", boot_region$conf_int[1], boot_region$conf_int[2]))
}

# ============================================================
# 2. Leave-one-out: drop each raion in turn
# ============================================================
cat("\n--- Leave-one-out jackknife ---\n")

raions <- unique(panel_est$raion_code)
loo_coefs <- numeric(length(raions))

for (i in seq_along(raions)) {
  sub <- panel_est[raion_code != raions[i]]
  sub[, region_year := paste0(region, "_", year)]
  m_loo <- feols(log_emp ~ bem_dep_z_post | raion_code + region_year,
                 data = sub, cluster = ~raion_code)
  loo_coefs[i] <- coef(m_loo)["bem_dep_z_post"]
}

loo_dt <- data.table(
  raion_code = raions,
  coef = loo_coefs
)
loo_dt <- merge(loo_dt, unique(panel_est[, .(raion_code, raion_name)]), by = "raion_code")

cat(sprintf("  Full-sample coefficient: %.4f\n", coef(m_region)["bem_dep_z_post"]))
cat(sprintf("  LOO range: [%.4f, %.4f]\n", min(loo_coefs), max(loo_coefs)))
cat(sprintf("  Most influential drop: %s (coef=%.4f)\n",
    loo_dt[which.max(abs(coef - coef(m_region)["bem_dep_z_post"])), raion_name],
    loo_dt[which.max(abs(coef - coef(m_region)["bem_dep_z_post"])), coef]))

# ============================================================
# 3. Excluding Chisinau (capital dominates economy)
# ============================================================
cat("\n--- Excluding Chisinau ---\n")

panel_nocap <- panel_est[raion_name != "Chisinau"]
panel_nocap[, region_year := paste0(region, "_", year)]

m_nocap <- feols(log_emp ~ bem_dep_z_post | raion_code + region_year,
                 data = panel_nocap, cluster = ~raion_code)

cat(sprintf("  Without Chisinau: %.4f (SE: %.4f, p: %.4f)\n",
    coef(m_nocap)[1], se(m_nocap)[1], pvalue(m_nocap)[1]))

# ============================================================
# 4. Excluding Chisinau and Balti (both municipalities)
# ============================================================
cat("\n--- Excluding municipalities (Chisinau + Balti) ---\n")

panel_nomunic <- panel_est[is_municipality == FALSE]
panel_nomunic[, region_year := paste0(region, "_", year)]

m_nomunic <- feols(log_emp ~ bem_dep_z_post | raion_code + region_year,
                   data = panel_nomunic, cluster = ~raion_code)

cat(sprintf("  Without municipalities: %.4f (SE: %.4f, p: %.4f)\n",
    coef(m_nomunic)[1], se(m_nomunic)[1], pvalue(m_nomunic)[1]))

# ============================================================
# 5. Shorter pre-period (2010-2024) — cleaner pre-trends
# ============================================================
cat("\n--- Shorter pre-period (2010-2024) ---\n")

panel_short <- panel_est[year >= 2010]
panel_short[, region_year := paste0(region, "_", year)]

m_short <- feols(log_emp ~ bem_dep_z_post | raion_code + region_year,
                 data = panel_short, cluster = ~raion_code)

cat(sprintf("  Short pre-period: %.4f (SE: %.4f, p: %.4f)\n",
    coef(m_short)[1], se(m_short)[1], pvalue(m_short)[1]))

# Event study with short pre-period
m_event_short <- feols(log_emp ~ i(year, bem_dep_z, ref = 2014) | raion_code + region_year,
                       data = panel_short, cluster = ~raion_code)

# Pre-trend test for short window
pre_short_names <- names(coef(m_event_short))[grepl("201[0-3]", names(coef(m_event_short)))]
if (length(pre_short_names) > 0) {
  pre_test_short <- wald(m_event_short, keep = pre_short_names)
  cat(sprintf("  Pre-trend test (2010-2013): F = %.3f, p = %.4f\n",
      pre_test_short$stat, pre_test_short$p))
}

# ============================================================
# 6. Placebo: Randomization inference (permute treatment across raions)
# ============================================================
cat("\n--- Placebo: Randomization inference ---\n")

set.seed(20261400)
n_perms <- 1000
perm_coefs <- numeric(n_perms)
raion_ids <- unique(panel_est$raion_code)
actual_treat <- unique(panel_est[, .(raion_code, bem_dep_z)])

for (p in seq_len(n_perms)) {
  perm_map <- data.table(
    raion_code = raion_ids,
    perm_treat = sample(actual_treat$bem_dep_z)
  )
  perm_data <- merge(panel_est[, .(raion_code, year, log_emp, post, year_f, region_year)],
    perm_map, by = "raion_code")
  perm_data[, perm_treat_post := perm_treat * post]
  m_perm <- feols(log_emp ~ perm_treat_post | raion_code + year_f,
                  data = perm_data, cluster = ~raion_code)
  perm_coefs[p] <- coef(m_perm)["perm_treat_post"]
}

actual_coef <- coef(m_main)["bem_dep_z_post"]
ri_pvalue <- mean(abs(perm_coefs) >= abs(actual_coef))
cat(sprintf("  Actual coefficient: %.4f\n", actual_coef))
cat(sprintf("  RI p-value (two-sided): %.4f\n", ri_pvalue))
cat(sprintf("  Permutation dist: mean=%.4f, sd=%.4f\n", mean(perm_coefs), sd(perm_coefs)))

# ============================================================
# 7. Save robustness results
# ============================================================
robust_results <- list(
  wild_boot = boot_result,
  wild_boot_region = boot_region,
  loo = loo_dt,
  no_chisinau = m_nocap,
  no_municipalities = m_nomunic,
  short_pre = m_short,
  event_short = m_event_short,
  ri_pvalue = ri_pvalue,
  perm_coefs = perm_coefs
)

save(robust_results, file = "../data/robustness_results.RData")
cat("\nRobustness checks complete.\n")
