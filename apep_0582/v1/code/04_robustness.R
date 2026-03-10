# 04_robustness.R — Robustness checks and sensitivity analysis
# apep_0582: The Resilience Puzzle — European Manufacturing and the Russian Gas Shock

source("00_packages.R")

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, date := as.Date(date)]

cat("Panel loaded:", nrow(panel), "obs\n")

# ============================================================================
# 1. LEAVE-ONE-OUT — Drop each country and re-estimate
# ============================================================================
cat("\n=== LEAVE-ONE-OUT ===\n")

countries <- unique(panel$geo)
loo_results <- list()

for (ctry in countries) {
  m_loo <- tryCatch(
    feols(log_prod ~ exposure:post |
            cs_id + ct_id + st_id,
          data = panel[geo != ctry],
          cluster = ~geo),
    error = function(e) NULL
  )
  if (!is.null(m_loo)) {
    loo_results[[ctry]] <- data.table(
      dropped_country = ctry,
      coef = coef(m_loo)["exposure:post"],
      se = se(m_loo)["exposure:post"],
      t_stat = tstat(m_loo)["exposure:post"],
      n_obs = nobs(m_loo)
    )
  }
}

loo_dt <- rbindlist(loo_results)
fwrite(loo_dt, file.path(data_dir, "leave_one_out.csv"))
cat("LOO range: [", round(min(loo_dt$coef), 4), ",", round(max(loo_dt$coef), 4), "]\n")
cat("LOO t-stat range: [", round(min(loo_dt$t_stat), 3), ",", round(max(loo_dt$t_stat), 3), "]\n")
cat("Most influential country (dropping changes coef most):\n")
# Load main coefficient for comparison
main_res <- fread(file.path(data_dir, "main_results.csv"))
main_coef <- main_res[spec == "Triple FE", coef_exposure_post]
loo_dt[, coef_change := abs(coef - main_coef)]
print(loo_dt[order(-coef_change)][1:5])

# ============================================================================
# 2. WILD CLUSTER BOOTSTRAP
# ============================================================================
cat("\n=== WILD CLUSTER BOOTSTRAP ===\n")

m_main <- feols(log_prod ~ exposure:post |
                  cs_id + ct_id + st_id,
                data = panel,
                cluster = ~geo)

# Wild cluster bootstrap using fwildclusterboot
boot_result <- tryCatch({
  boottest(m_main, param = "exposure:post",
           B = 999, clustid = "geo",
           type = "webb", impose_null = TRUE)
}, error = function(e) {
  cat("  Wild cluster bootstrap failed:", e$message, "\n")
  cat("  Trying with Rademacher weights...\n")
  tryCatch(
    boottest(m_main, param = "exposure:post",
             B = 999, clustid = "geo",
             type = "rademacher", impose_null = TRUE),
    error = function(e2) {
      cat("  Both bootstrap methods failed:", e2$message, "\n")
      NULL
    }
  )
})

if (!is.null(boot_result)) {
  boot_p <- pvalue(boot_result)
  boot_ci <- boot_result$conf_int
  cat("Wild cluster bootstrap p-value:", round(boot_p, 4), "\n")
  cat("Bootstrap 95% CI:", round(boot_ci, 4), "\n")
  fwrite(data.table(
    p_value = boot_p,
    ci_lo = boot_ci[1],
    ci_hi = boot_ci[2],
    B = 999
  ), file.path(data_dir, "wild_bootstrap.csv"))
} else {
  cat("WARNING: Wild cluster bootstrap could not be computed.\n")
  fwrite(data.table(p_value = NA, ci_lo = NA, ci_hi = NA, B = NA),
         file.path(data_dir, "wild_bootstrap.csv"))
}

# ============================================================================
# 3. RANDOMIZATION INFERENCE — Permute gas shares across countries
# ============================================================================
cat("\n=== RANDOMIZATION INFERENCE ===\n")

set.seed(42)
n_perms <- 500
actual_coef <- coef(m_main)["exposure:post"]

# Get unique country-level gas shares
country_shares <- unique(panel[, .(geo, russian_gas_share)])

perm_coefs <- numeric(n_perms)

for (p in seq_len(n_perms)) {
  if (p %% 50 == 0) cat("  Permutation", p, "/", n_perms, "\n")

  # Shuffle gas shares across countries
  shuffled <- copy(country_shares)
  shuffled[, russian_gas_share_perm := sample(russian_gas_share)]

  panel_perm <- merge(panel, shuffled[, .(geo, russian_gas_share_perm)],
                       by = "geo", all.x = TRUE)
  panel_perm[, exposure_perm := russian_gas_share_perm * gas_intensity]

  m_perm <- tryCatch(
    feols(log_prod ~ exposure_perm:post |
            cs_id + ct_id + st_id,
          data = panel_perm,
          cluster = ~geo),
    error = function(e) NULL
  )

  if (!is.null(m_perm)) {
    perm_coefs[p] <- coef(m_perm)["exposure_perm:post"]
  } else {
    perm_coefs[p] <- NA
  }
}

perm_coefs_clean <- perm_coefs[!is.na(perm_coefs)]
ri_p <- mean(abs(perm_coefs_clean) >= abs(actual_coef))

cat("RI p-value (two-sided):", round(ri_p, 4), "\n")
cat("Actual coefficient:", round(actual_coef, 4), "\n")
cat("Permutation distribution: mean =", round(mean(perm_coefs_clean), 4),
    ", sd =", round(sd(perm_coefs_clean), 4), "\n")

fwrite(data.table(
  actual_coef = actual_coef,
  ri_p_value = ri_p,
  n_perms = length(perm_coefs_clean),
  perm_mean = mean(perm_coefs_clean),
  perm_sd = sd(perm_coefs_clean)
), file.path(data_dir, "randomization_inference.csv"))

# Save full permutation distribution for plotting
fwrite(data.table(perm_coef = perm_coefs_clean),
       file.path(data_dir, "ri_distribution.csv"))

# ============================================================================
# 4. PLACEBO TESTS — Pre-invasion fake treatment dates
# ============================================================================
cat("\n=== PLACEBO TESTS ===\n")

placebo_dates <- as.Date(c("2019-03-01", "2020-03-01", "2021-01-01"))
placebo_results <- list()

for (pdate in placebo_dates) {
  pdate <- as.Date(pdate, origin = "1970-01-01")
  # Restrict sample to before actual treatment
  panel_pre <- panel[date < as.Date("2022-03-01")]
  panel_pre[, post_placebo := as.integer(date >= pdate)]
  panel_pre[, treatment_placebo := exposure * post_placebo]

  m_placebo <- tryCatch(
    feols(log_prod ~ exposure:post_placebo |
            cs_id + ct_id + st_id,
          data = panel_pre,
          cluster = ~geo),
    error = function(e) NULL
  )

  if (!is.null(m_placebo)) {
    placebo_results[[as.character(pdate)]] <- data.table(
      placebo_date = as.character(pdate),
      coef = coef(m_placebo)["exposure:post_placebo"],
      se = se(m_placebo)["exposure:post_placebo"],
      t_stat = tstat(m_placebo)["exposure:post_placebo"],
      n_obs = nobs(m_placebo)
    )
  }
}

placebo_dt <- rbindlist(placebo_results)
fwrite(placebo_dt, file.path(data_dir, "placebo_tests.csv"))
cat("Placebo results:\n")
print(placebo_dt)

# ============================================================================
# 5. ALTERNATIVE POST DATES — Escalation timing
# ============================================================================
cat("\n=== ALTERNATIVE POST DATES ===\n")

alt_dates <- as.Date(c("2022-02-24", "2022-06-01", "2022-09-01", "2022-10-01"))
alt_results <- list()

for (adate in alt_dates) {
  adate <- as.Date(adate, origin = "1970-01-01")
  panel[, post_alt := as.integer(date >= adate)]

  m_alt <- tryCatch(
    feols(log_prod ~ exposure:post_alt |
            cs_id + ct_id + st_id,
          data = panel,
          cluster = ~geo),
    error = function(e) NULL
  )

  if (!is.null(m_alt)) {
    alt_results[[as.character(adate)]] <- data.table(
      post_date = as.character(adate),
      coef = coef(m_alt)["exposure:post_alt"],
      se = se(m_alt)["exposure:post_alt"],
      t_stat = tstat(m_alt)["exposure:post_alt"],
      n_obs = nobs(m_alt)
    )
  }
}

alt_dt <- rbindlist(alt_results)
fwrite(alt_dt, file.path(data_dir, "alternative_post_dates.csv"))
cat("Alternative post-date results:\n")
print(alt_dt)

# ============================================================================
# 6. BINARY TREATMENT — Above/below median gas share
# ============================================================================
cat("\n=== BINARY TREATMENT ===\n")

med_gas <- median(unique(panel$russian_gas_share), na.rm = TRUE)
panel[, high_gas := as.integer(russian_gas_share > med_gas)]
panel[, high_gas_intensity := as.integer(gas_intensity > median(gas_intensity))]

m_binary <- feols(log_prod ~ high_gas:high_gas_intensity:post |
                    cs_id + ct_id + st_id,
                  data = panel,
                  cluster = ~geo)

cat("Binary treatment result:\n")
summary(m_binary)

fwrite(data.table(
  coef = coef(m_binary),
  se = se(m_binary),
  name = names(coef(m_binary))
), file.path(data_dir, "binary_treatment.csv"))

# ============================================================================
# 7. EXCLUDE COVID PERIOD
# ============================================================================
cat("\n=== EXCLUDE COVID PERIOD ===\n")

m_no_covid <- feols(log_prod ~ exposure:post |
                      cs_id + ct_id + st_id,
                    data = panel[!(date >= as.Date("2020-03-01") & date <= as.Date("2021-06-30"))],
                    cluster = ~geo)

cat("Excluding Mar 2020 - Jun 2021:\n")
summary(m_no_covid)

fwrite(data.table(
  spec = "Exclude COVID",
  coef = coef(m_no_covid)["exposure:post"],
  se = se(m_no_covid)["exposure:post"],
  t_stat = tstat(m_no_covid)["exposure:post"],
  n_obs = nobs(m_no_covid)
), file.path(data_dir, "exclude_covid.csv"))

cat("\nAll robustness checks completed.\n")
