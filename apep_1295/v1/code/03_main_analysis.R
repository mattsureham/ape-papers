# 03_main_analysis.R — Main DiD analysis
# APEP Paper apep_1292: Sunshine Through the Alps

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. Load data
# ============================================================
panel <- fread(file.path(data_dir, "panel_main.csv"))
cat("Panel:", nrow(panel), "obs,", uniqueN(panel$L_REP_CTY), "countries,",
    uniqueN(panel$unit_id), "country-position pairs\n")

# Ensure proper types
panel[, L_REP_CTY := as.character(L_REP_CTY)]
panel[, unit_id := as.character(unit_id)]
panel[, country_id := as.integer(factor(L_REP_CTY))]
panel[, time_period := as.integer((year - 2000) * 4 + qtr_num)]

# ============================================================
# 2. Descriptive statistics
# ============================================================
cat("\n=== Descriptive Statistics ===\n")

# Pre-treatment summary by group
pre_summ <- panel[treated == 0, .(
  mean_value = mean(value_usd, na.rm = TRUE),
  sd_value = sd(value_usd, na.rm = TRUE),
  median_value = median(value_usd, na.rm = TRUE),
  n_obs = .N
), by = .(aeoi_group, L_POSITION)]
cat("Pre-treatment values by group and position:\n")
print(pre_summ)

# Pre-treatment SD (for SDE)
sd_y_pre <- panel[treated == 0, sd(log_position, na.rm = TRUE)]
cat("\nPre-treatment SD(log position):", round(sd_y_pre, 4), "\n")

# ============================================================
# 3. Main specification: Pooled TWFE
# ============================================================
cat("\n=== Pooled TWFE (Claims + Liabilities) ===\n")

twfe_pooled <- feols(
  log_position ~ treated | unit_id + time_period,
  data = panel,
  cluster = ~L_REP_CTY
)
cat("Pooled TWFE:\n")
print(summary(twfe_pooled))

# ============================================================
# 4. Claims-only TWFE
# ============================================================
cat("\n=== Claims-Only TWFE ===\n")

panel_claims <- panel[L_POSITION == "C"]
twfe_claims <- feols(
  log_position ~ treated | unit_id + time_period,
  data = panel_claims,
  cluster = ~L_REP_CTY
)
cat("Claims TWFE:\n")
print(summary(twfe_claims))

# ============================================================
# 5. Liabilities-only TWFE
# ============================================================
cat("\n=== Liabilities-Only TWFE ===\n")

panel_liab <- panel[L_POSITION == "L"]
twfe_liab <- feols(
  log_position ~ treated | unit_id + time_period,
  data = panel_liab,
  cluster = ~L_REP_CTY
)
cat("Liabilities TWFE:\n")
print(summary(twfe_liab))

# ============================================================
# 6. Sun-Abraham (heterogeneity-robust staggered DiD) — pooled
# ============================================================
cat("\n=== Sun-Abraham Estimator (Pooled) ===\n")

sa_est <- feols(
  log_position ~ sunab(first_treat_sa, time_period) | unit_id + time_period,
  data = panel,
  cluster = ~L_REP_CTY
)
cat("Sun-Abraham (pooled):\n")
print(summary(sa_est))

# Aggregate ATT
sa_agg <- summary(sa_est, agg = "ATT")
cat("\nSun-Abraham ATT:\n")
print(sa_agg)

# ============================================================
# 7. EU-only subsample (cleanest identification)
# ============================================================
cat("\n=== EU/EEA Subsample ===\n")

panel_eu <- panel[aeoi_group %in% c("EU_2017", "CRS_2018", "CRS_2020")]
eu_twfe <- feols(
  log_position ~ treated | unit_id + time_period,
  data = panel_eu,
  cluster = ~L_REP_CTY
)
cat("EU subsample TWFE:\n")
print(summary(eu_twfe))

# ============================================================
# 8. Event study coefficients
# ============================================================
cat("\n=== Event Study ===\n")

sa_coefs <- as.data.frame(coeftable(sa_est))
sa_coefs$term <- rownames(sa_coefs)
sa_coefs <- sa_coefs[grepl("time_period::", sa_coefs$term), ]
sa_coefs$event_time <- as.numeric(gsub(".*::(-?[0-9]+)$", "\\1", sa_coefs$term))
sa_coefs <- sa_coefs[order(sa_coefs$event_time), ]

es_data <- data.frame(
  event_time = sa_coefs$event_time,
  estimate = sa_coefs$Estimate,
  se = sa_coefs$`Std. Error`,
  ci_low = sa_coefs$Estimate - 1.96 * sa_coefs$`Std. Error`,
  ci_high = sa_coefs$Estimate + 1.96 * sa_coefs$`Std. Error`
)
fwrite(es_data, file.path(data_dir, "event_study_coefs.csv"))

# ============================================================
# 9. Wild cluster bootstrap (for pooled TWFE)
# ============================================================
cat("\n=== Wild Cluster Bootstrap ===\n")

boot_result <- tryCatch({
  boottest(
    twfe_pooled,
    param = "treated",
    clustid = "L_REP_CTY",
    B = 9999,
    type = "webb"
  )
}, error = function(e) {
  cat("Bootstrap error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(boot_result)) {
  cat("Wild cluster bootstrap results:\n")
  print(summary(boot_result))
  boot_pval <- boot_result$p_val
  boot_ci <- c(boot_result$conf_int[1], boot_result$conf_int[2])
  cat("Bootstrap p-value:", round(boot_pval, 4), "\n")
} else {
  boot_pval <- NA
  boot_ci <- c(NA, NA)
}

# ============================================================
# 10. Save diagnostics and results
# ============================================================
diagnostics <- list(
  n_treated = uniqueN(panel[treated == 1]$L_REP_CTY),
  n_pre = length(unique(panel[treated == 0 & aeoi_group == "EU_2017"]$time_period)),
  n_obs = nrow(panel),
  n_countries = uniqueN(panel$L_REP_CTY),
  n_unit_pairs = uniqueN(panel$unit_id),
  n_quarters = uniqueN(panel$time_period),
  twfe_coef = coef(twfe_pooled)["treated"],
  twfe_se = se(twfe_pooled)["treated"],
  twfe_pval = pvalue(twfe_pooled)["treated"],
  sa_att_coef = coef(sa_agg)["ATT"],
  sd_y_pre = sd_y_pre,
  boot_pval = boot_pval
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")

results <- list(
  pooled_twfe = list(
    coef = coef(twfe_pooled)["treated"],
    se = se(twfe_pooled)["treated"],
    pval = pvalue(twfe_pooled)["treated"],
    n = nobs(twfe_pooled),
    r2 = r2(twfe_pooled, "ar2"),
    n_countries = uniqueN(panel$L_REP_CTY),
    n_pairs = uniqueN(panel$unit_id)
  ),
  claims_twfe = list(
    coef = coef(twfe_claims)["treated"],
    se = se(twfe_claims)["treated"],
    pval = pvalue(twfe_claims)["treated"],
    n = nobs(twfe_claims),
    r2 = r2(twfe_claims, "ar2"),
    n_countries = uniqueN(panel_claims$L_REP_CTY)
  ),
  liab_twfe = list(
    coef = coef(twfe_liab)["treated"],
    se = se(twfe_liab)["treated"],
    pval = pvalue(twfe_liab)["treated"],
    n = nobs(twfe_liab),
    r2 = r2(twfe_liab, "ar2"),
    n_countries = uniqueN(panel_liab$L_REP_CTY)
  ),
  sunab = list(
    att_coef = coef(sa_agg)["ATT"],
    att_se = se(sa_agg)["ATT"]
  ),
  eu_twfe = list(
    coef = coef(eu_twfe)["treated"],
    se = se(eu_twfe)["treated"],
    pval = pvalue(eu_twfe)["treated"],
    n = nobs(eu_twfe),
    r2 = r2(eu_twfe, "ar2"),
    n_countries = uniqueN(panel_eu$L_REP_CTY)
  ),
  sd_y_pre = sd_y_pre,
  boot_pval = boot_pval,
  boot_ci_low = boot_ci[1],
  boot_ci_high = boot_ci[2]
)

saveRDS(results, file.path(data_dir, "main_results.rds"))
cat("Main results saved.\n")

cat("\n=== Main analysis complete ===\n")
