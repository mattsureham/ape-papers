# =============================================================================
# 04_robustness.R — Robustness checks and wild cluster bootstrap
# apep_0643: PFL Border County Pairs
# =============================================================================

source("00_packages.R")

stacked_all <- readRDS("../data/stacked_all.rds")
results <- readRDS("../data/main_results.rds")

female_all <- stacked_all %>%
  filter(sex == 2) %>%
  mutate(
    pfl = treated * post,
    pair_wave = paste0(pair_id, "_", wave),
    time_wave = paste0(yq_str, "_", wave),
    ln_emp = ifelse(Emp > 0, log(Emp), NA_real_),
    ln_earn = ifelse(EarnS > 0, log(EarnS), NA_real_),
    ln_hir = ifelse(HirA > 0, log(HirA), NA_real_),
    ln_sep = ifelse(Sep > 0, log(Sep), NA_real_),
    hire_rate = ifelse(Emp > 0, HirA / Emp, NA_real_),
    sep_rate = ifelse(Emp > 0, Sep / Emp, NA_real_)
  )

# ---- WILD CLUSTER BOOTSTRAP ----
cat("=== WILD CLUSTER BOOTSTRAP (few-cluster inference) ===\n\n")

# Main specification with wild cluster bootstrap
# Few clusters (5-7 states) → WCB is essential
m_main <- feols(ln_emp ~ pfl | pair_wave + time_wave,
                data = female_all, cluster = ~state_fips)

# Wild cluster bootstrap using fwildclusterboot
wcb_emp <- tryCatch({
  boot_result <- boottest(
    m_main,
    param = "pfl",
    clustid = ~state_fips,
    B = 9999,
    type = "webb"  # Webb weights for few clusters
  )
  cat(sprintf("WCB (ln_emp): p-value = %.4f, CI = [%.4f, %.4f]\n",
              boot_result$p_val,
              boot_result$conf_int[1],
              boot_result$conf_int[2]))
  boot_result
}, error = function(e) {
  cat(sprintf("WCB failed: %s\n", e$message))
  NULL
})

# WCB for earnings
m_earn <- feols(ln_earn ~ pfl | pair_wave + time_wave,
                data = female_all, cluster = ~state_fips)

wcb_earn <- tryCatch({
  boot_result <- boottest(
    m_earn,
    param = "pfl",
    clustid = ~state_fips,
    B = 9999,
    type = "webb"
  )
  cat(sprintf("WCB (ln_earn): p-value = %.4f, CI = [%.4f, %.4f]\n",
              boot_result$p_val,
              boot_result$conf_int[1],
              boot_result$conf_int[2]))
  boot_result
}, error = function(e) {
  cat(sprintf("WCB for earnings failed: %s\n", e$message))
  NULL
})

# ---- LEAVE-ONE-WAVE-OUT ----
cat("\n=== LEAVE-ONE-WAVE-OUT ===\n\n")

loo_results <- list()
for (drop_wave in c("NJ", "NY", "WA")) {
  loo_data <- female_all %>% filter(wave != drop_wave)
  if (nrow(loo_data) > 100) {
    m_loo <- feols(ln_emp ~ pfl | pair_wave + time_wave,
                   data = loo_data, cluster = ~state_fips)
    loo_results[[drop_wave]] <- m_loo
    cat(sprintf("Drop %s: coef = %.4f, se = %.4f, N = %d\n",
                drop_wave, coef(m_loo)["pfl"], se(m_loo)["pfl"], nobs(m_loo)))
  }
}

# ---- ALTERNATIVE CLUSTERING ----
cat("\n=== ALTERNATIVE CLUSTERING ===\n\n")

# Cluster at county-pair level
m_pair_cluster <- feols(ln_emp ~ pfl | pair_wave + time_wave,
                        data = female_all, cluster = ~pair_wave)
cat(sprintf("Pair-clustered: coef = %.4f, se = %.4f\n",
            coef(m_pair_cluster)["pfl"], se(m_pair_cluster)["pfl"]))

# Cluster at county level
m_county_cluster <- feols(ln_emp ~ pfl | pair_wave + time_wave,
                          data = female_all, cluster = ~fips)
cat(sprintf("County-clustered: coef = %.4f, se = %.4f\n",
            coef(m_county_cluster)["pfl"], se(m_county_cluster)["pfl"]))

# ---- PRE-TREND F-TEST ----
cat("\n=== PRE-TREND F-TEST ===\n\n")

# Test joint significance of pre-treatment event-time coefficients
female_all <- female_all %>%
  mutate(
    et_binned = case_when(
      event_time <= -9 ~ -9L,
      event_time >= 13 ~ 13L,
      TRUE ~ as.integer(event_time)
    )
  )

es_model <- feols(ln_emp ~ i(et_binned, treated, ref = -1) | pair_wave + time_wave,
                  data = female_all, cluster = ~state_fips)

# Extract pre-treatment coefficients
pre_coefs <- coef(es_model)[grep("et_binned::-[2-9]|et_binned::-1[0-9]", names(coef(es_model)))]
cat(sprintf("Pre-treatment coefficients (N=%d):\n", length(pre_coefs)))
for (nm in names(pre_coefs)) {
  cat(sprintf("  %s: %.4f\n", nm, pre_coefs[nm]))
}

# F-test for joint significance of pre-treatment coefficients
pre_wald <- tryCatch({
  wald(es_model, keep = "et_binned::-")
}, error = function(e) {
  cat(sprintf("Wald test error: %s\n", e$message))
  NULL
})
if (!is.null(pre_wald)) {
  cat(sprintf("\nJoint F-test of pre-trends: F = %.2f, p = %.4f\n",
              pre_wald$stat, pre_wald$p))
}

# ---- ALTERNATIVE WINDOW LENGTHS ----
cat("\n=== ALTERNATIVE WINDOWS ===\n\n")

for (max_post in c(8, 12, 16)) {
  for (max_pre in c(8, 12)) {
    window_data <- female_all %>%
      filter(event_time >= -max_pre & event_time <= max_post)
    m_window <- feols(ln_emp ~ pfl | pair_wave + time_wave,
                      data = window_data, cluster = ~state_fips)
    cat(sprintf("Window [-%d, +%d]: coef = %.4f, se = %.4f, N = %d\n",
                max_pre, max_post,
                coef(m_window)["pfl"], se(m_window)["pfl"], nobs(m_window)))
  }
}

# ---- SAVE ROBUSTNESS RESULTS ----
robustness <- list(
  wcb_emp = wcb_emp,
  wcb_earn = wcb_earn,
  loo = loo_results,
  pair_cluster = m_pair_cluster,
  county_cluster = m_county_cluster,
  pre_wald = pre_wald,
  es_model = es_model
)

saveRDS(robustness, "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
