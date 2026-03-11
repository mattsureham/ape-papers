# ==============================================================================
# 04_robustness.R — Robustness checks
# apep_0600: EU Mortgage Credit Directive
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
mir_panel <- fread(file.path(data_dir, "mir_panel.csv"))
hpi_panel <- fread(file.path(data_dir, "hpi_panel.csv"))
mir_panel[, date := as.Date(date)]
hpi_panel[, date := as.Date(date)]

load(file.path(data_dir, "main_models.RData"))

# Recreate quarterly aggregation
mir_panel[, yr := year(date)]
mir_panel[, qtr := quarter(date)]
mir_panel[, yq_idx := (yr - 2005) * 4 + qtr]

# ==============================================================================
# 1. Sun-Abraham Coefficients (already computed in 03, save here for reference)
# ==============================================================================
cat("=== Sun-Abraham coefficients saved from main analysis ===\n")

# These are already in es_rate_results.csv and es_hpi_results.csv
sunab_rate_coefs <- fread(file.path(data_dir, "es_rate_results.csv"))
fwrite(sunab_rate_coefs, file.path(data_dir, "sunab_rate_coefs.csv"))

sunab_hpi_coefs <- fread(file.path(data_dir, "es_hpi_results.csv"))
fwrite(sunab_hpi_coefs, file.path(data_dir, "sunab_hpi_coefs.csv"))

# ==============================================================================
# 2. Leave-One-Out Country Exclusion
# ==============================================================================
cat("\n=== Leave-One-Out ===\n")

countries <- unique(mir_q[!is.na(rate), country])
loo_results <- data.table()

for (cc in countries) {
  sub <- mir_q[country != cc & !is.na(rate)]
  fit <- tryCatch({
    feols(rate ~ treated | country_id + yq_idx, data = sub, cluster = ~country_id)
  }, error = function(e) NULL)

  if (!is.null(fit)) {
    loo_results <- rbind(loo_results, data.table(
      excluded = cc,
      estimate = coef(fit)["treated"],
      se = sqrt(diag(vcov(fit)))["treated"]
    ))
  }
}

cat("\nLeave-one-out estimates (mortgage rate):\n")
print(loo_results)
fwrite(loo_results, file.path(data_dir, "loo_rate.csv"))

# LOO for HPI
countries_hpi <- unique(hpi_panel[!is.na(log_hpi), country])
loo_hpi <- data.table()

for (cc in countries_hpi) {
  sub <- hpi_panel[country != cc & !is.na(log_hpi)]
  fit <- tryCatch({
    feols(log_hpi ~ treated | country_id + time_idx, data = sub, cluster = ~country_id)
  }, error = function(e) NULL)

  if (!is.null(fit)) {
    loo_hpi <- rbind(loo_hpi, data.table(
      excluded = cc,
      estimate = coef(fit)["treated"],
      se = sqrt(diag(vcov(fit)))["treated"]
    ))
  }
}
fwrite(loo_hpi, file.path(data_dir, "loo_hpi.csv"))

# ==============================================================================
# 3. Randomization Inference
# ==============================================================================
cat("\n=== Randomization Inference ===\n")

# Permute treatment timing across countries
set.seed(42)
n_perms <- 500

# Get actual TWFE coefficient
actual_coef <- coef(twfe_rate)["treated"]

ri_coefs <- numeric(n_perms)
trans_dates <- mir_q[!is.na(transposition_date), .(country, transposition_date)]
trans_dates <- unique(trans_dates)

for (i in seq_len(n_perms)) {
  # Shuffle transposition dates across countries
  shuffled <- copy(trans_dates)
  shuffled[, transposition_date := sample(transposition_date)]

  # Re-create treatment variable
  perm_data <- copy(mir_q[!is.na(rate)])
  perm_data[, transposition_date := NULL]
  perm_data[, treated := NULL]
  perm_data <- merge(perm_data, shuffled, by = "country", all.x = TRUE)
  perm_data[, treated := as.integer(!is.na(transposition_date) &
              as.Date(paste0(yr, "-", (qtr - 1) * 3 + 1, "-01")) >= transposition_date)]

  fit <- tryCatch({
    feols(rate ~ treated | country_id + yq_idx, data = perm_data, cluster = ~country_id)
  }, error = function(e) NULL)

  if (!is.null(fit)) {
    ri_coefs[i] <- coef(fit)["treated"]
  }
}

ri_p <- mean(abs(ri_coefs) >= abs(actual_coef), na.rm = TRUE)
cat("\nRandomization Inference p-value (mortgage rate):", ri_p, "\n")
cat("Actual coefficient:", actual_coef, "\n")
cat("RI distribution: mean =", mean(ri_coefs, na.rm = TRUE),
    ", sd =", sd(ri_coefs, na.rm = TRUE), "\n")

ri_dt <- data.table(
  permutation = seq_along(ri_coefs),
  coef = ri_coefs,
  actual = actual_coef,
  ri_p = ri_p
)
fwrite(ri_dt, file.path(data_dir, "ri_rate.csv"))

# ==============================================================================
# 4. Wild Cluster Bootstrap (few-cluster inference)
# ==============================================================================
cat("\n=== Wild Cluster Bootstrap ===\n")

wcb_rate <- tryCatch({
  boot_twfe <- feols(rate ~ treated | country_id + yq_idx,
                      data = mir_q[!is.na(rate)], cluster = ~country_id)
  boottest(boot_twfe, param = "treated", B = 999,
           clustid = "country_id", type = "webb")
}, error = function(e) {
  cat("Wild cluster bootstrap failed:", e$message, "\n")
  NULL
})

if (!is.null(wcb_rate)) {
  cat("\nWild Cluster Bootstrap (mortgage rate):\n")
  print(summary(wcb_rate))
  wcb_dt <- data.table(
    outcome = "mortgage_rate",
    wcb_p = wcb_rate$p_val,
    wcb_ci_lower = wcb_rate$conf_int[1],
    wcb_ci_upper = wcb_rate$conf_int[2]
  )
  fwrite(wcb_dt, file.path(data_dir, "wcb_rate.csv"))
}

# ==============================================================================
# 5. Temporal Placebo (shift treatment 2 years earlier)
# ==============================================================================
cat("\n=== Temporal Placebo ===\n")

placebo_data <- copy(mir_q[!is.na(rate)])
# Shift treatment 8 quarters (2 years) earlier
placebo_data[!is.na(transposition_date),
             placebo_date := transposition_date - 365.25 * 2]
placebo_data[, date_q := as.Date(paste0(yr, "-", (qtr - 1) * 3 + 1, "-01"))]
placebo_data[, placebo_treated := as.integer(!is.na(placebo_date) & date_q >= placebo_date)]
# Restrict to pre-actual-treatment period
placebo_data <- placebo_data[is.na(transposition_date) | date_q < transposition_date]

placebo_fit <- feols(rate ~ placebo_treated | country_id + yq_idx,
                      data = placebo_data, cluster = ~country_id)
cat("\nTemporal Placebo (2 years before, mortgage rate):\n")
summary(placebo_fit)

placebo_dt <- data.table(
  outcome = "mortgage_rate_placebo_2yr",
  estimate = coef(placebo_fit)["placebo_treated"],
  se = sqrt(diag(vcov(placebo_fit)))["placebo_treated"]
)
fwrite(placebo_dt, file.path(data_dir, "temporal_placebo.csv"))

# ==============================================================================
# 6. HonestDiD bounds (sensitivity to pre-trend violations)
# ==============================================================================
cat("\n=== HonestDiD Bounds ===\n")

# Extract pre and post coefficients from Sun-Abraham event study
# We need the event-study coefficients and their variance-covariance matrix
honest_result <- tryCatch({
  # Use the CS-DiD event study for HonestDiD
  # Need pre-treatment coefficients
  es_data <- fread(file.path(data_dir, "es_rate_results.csv"))
  pre_coefs <- es_data[rel_time < 0]
  post_coefs <- es_data[rel_time >= 0]

  if (nrow(pre_coefs) >= 3 && nrow(post_coefs) >= 1) {
    cat("Pre-treatment coefficients for HonestDiD:\n")
    print(pre_coefs[, .(rel_time, att, se)])

    # Compute max pre-trend violation (Mbar)
    max_pre_violation <- max(abs(pre_coefs$att))
    cat("Max pre-trend violation (|delta|):", max_pre_violation, "\n")

    # Save for reporting
    data.table(
      max_pre_violation = max_pre_violation,
      n_pre = nrow(pre_coefs),
      n_post = nrow(post_coefs),
      post_att_mean = mean(post_coefs$att),
      post_att_se_mean = mean(post_coefs$se)
    )
  } else {
    cat("Insufficient pre/post periods for HonestDiD\n")
    NULL
  }
}, error = function(e) {
  cat("HonestDiD failed:", e$message, "\n")
  NULL
})

if (!is.null(honest_result)) {
  fwrite(honest_result, file.path(data_dir, "honestdid_rate.csv"))
}

# ==============================================================================
# 7. Heterogeneity: Pre-existing regulation stringency
# ==============================================================================
cat("\n=== Heterogeneity: Pre-existing regulation ===\n")

# Countries with previously strict mortgage regulation (had LTV limits or
# affordability checks before MCD)
strict_pre <- c("NL", "FI", "IE")  # Euro area countries with early macro-pru (SE, DK non-euro)
lax_pre <- setdiff(unique(mir_panel$country), strict_pre)

mir_q[, stringent_pre := fifelse(country %in% strict_pre, 1L, 0L)]

# Interaction specification
het_reg <- feols(rate ~ treated * stringent_pre | country_id + yq_idx,
                  data = mir_q[!is.na(rate)],
                  cluster = ~country_id)
cat("\nHeterogeneity by pre-existing regulation:\n")
summary(het_reg)

het_dt <- data.table(
  term = names(coef(het_reg)),
  estimate = coef(het_reg),
  se = sqrt(diag(vcov(het_reg)))
)
fwrite(het_dt, file.path(data_dir, "het_regulation.csv"))

# ==============================================================================
# 8. Heterogeneity: Housing boom intensity
# ==============================================================================
cat("\n=== Heterogeneity: Housing boom intensity ===\n")

# Classify countries by pre-MCD house price growth (2010-2015)
hpi_growth <- hpi_panel[date >= "2010-01-01" & date <= "2015-01-01",
                          .(hpi_start = hpi[which.min(date)],
                            hpi_end = hpi[which.max(date)]),
                          by = country]
hpi_growth[, growth := (hpi_end / hpi_start - 1) * 100]
hpi_growth[, boom := fifelse(growth > median(growth, na.rm = TRUE), 1L, 0L)]

mir_het <- merge(mir_q, hpi_growth[, .(country, boom)],
                  by = "country", all.x = TRUE)

het_boom <- feols(rate ~ treated * boom | country_id + yq_idx,
                   data = mir_het[!is.na(rate) & !is.na(boom)],
                   cluster = ~country_id)
cat("\nHeterogeneity by housing boom:\n")
summary(het_boom)

het_boom_dt <- data.table(
  term = names(coef(het_boom)),
  estimate = coef(het_boom),
  se = sqrt(diag(vcov(het_boom)))
)
fwrite(het_boom_dt, file.path(data_dir, "het_boom.csv"))

# ==============================================================================
# 9. TWFE on Balanced 16-Country Panel (apples-to-apples with SA-IW)
# ==============================================================================
cat("\n=== TWFE on Balanced 16-Country Panel ===\n")

# Recreate balanced panel (same as in 03_main_analysis.R)
n_periods <- uniqueN(mir_q$yq_idx)
balanced_countries <- mir_q[!is.na(rate), .N, by = country][N == n_periods, country]
mir_bal <- mir_q[country %in% balanced_countries]
cat("Balanced panel:", nrow(mir_bal), "obs,", uniqueN(mir_bal$country), "countries\n")

twfe_balanced <- feols(rate ~ treated | country_id + yq_idx,
                        data = mir_bal, cluster = ~country_id)
cat("\nTWFE on balanced panel:\n")
summary(twfe_balanced)

twfe_bal_dt <- data.table(
  outcome = "mortgage_rate_balanced_twfe",
  estimate = coef(twfe_balanced)["treated"],
  se = sqrt(diag(vcov(twfe_balanced)))["treated"],
  n = nobs(twfe_balanced),
  n_countries = uniqueN(mir_bal$country)
)
fwrite(twfe_bal_dt, file.path(data_dir, "twfe_balanced.csv"))

# ==============================================================================
# 10. Country-Specific Linear Trends
# ==============================================================================
cat("\n=== Country-Specific Linear Trends ===\n")

# Add country-specific linear time trends to TWFE
mir_q_rate <- mir_q[!is.na(rate)]
mir_q_rate[, time_trend := yq_idx]

twfe_ctrends <- feols(rate ~ treated + i(country_id, time_trend) | country_id + yq_idx,
                       data = mir_q_rate, cluster = ~country_id)
cat("\nTWFE with country-specific linear trends:\n")
cat("Treated coefficient:", coef(twfe_ctrends)["treated"], "\n")
cat("SE:", sqrt(diag(vcov(twfe_ctrends)))["treated"], "\n")

ctrends_dt <- data.table(
  outcome = "mortgage_rate_country_trends",
  estimate = coef(twfe_ctrends)["treated"],
  se = sqrt(diag(vcov(twfe_ctrends)))["treated"],
  n = nobs(twfe_ctrends)
)
fwrite(ctrends_dt, file.path(data_dir, "twfe_country_trends.csv"))

# Save all robustness model objects
save(placebo_fit, het_reg, het_boom, twfe_balanced, twfe_ctrends,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\nRobustness checks complete.\n")
