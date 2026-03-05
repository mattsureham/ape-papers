# ============================================================================
# 04_robustness.R — Robustness checks and additional specifications
# APEP-0525: Tax Borders and the Rich
# ============================================================================

source("00_packages.R")

df <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
df <- df[!is.na(high_share) & total_returns >= 10]

# ============================================================================
# 1. BANDWIDTH SENSITIVITY
# ============================================================================

cat("\n--- 1. Bandwidth Sensitivity ---\n")

bw_results <- list()
for (bw in c(5, 10, 15, 20, 30, 50)) {
  df_bw <- df[abs(dist_to_border_km) <= bw]
  if (nrow(df_bw) < 200) next

  m <- feols(high_share ~ high_tax_side * dist_to_border_km | pair_year,
             data = df_bw, cluster = ~zipcode)

  bw_results[[as.character(bw)]] <- data.table(
    bandwidth_km = bw,
    estimate = coef(m)["high_tax_side"],
    se = se(m)["high_tax_side"],
    n_obs = nobs(m),
    n_zips = uniqueN(df_bw$zipcode)
  )
  cat("  BW =", bw, "km: coef =", round(coef(m)["high_tax_side"], 5),
      " SE =", round(se(m)["high_tax_side"], 5), " N =", nobs(m), "\n")
}

bw_dt <- rbindlist(bw_results)
bw_dt[, ci_lower := estimate - 1.96 * se]
bw_dt[, ci_upper := estimate + 1.96 * se]
fwrite(bw_dt, file.path(DATA_DIR, "bandwidth_sensitivity.csv"))

# ============================================================================
# 2. DONUT DESIGN — Exclude ZIPs very close to border
# ============================================================================

cat("\n--- 2. Donut Design ---\n")

donut_results <- list()
for (hole in c(0, 1, 2, 3, 5)) {
  df_donut <- df[abs(dist_to_border_km) > hole & abs(dist_to_border_km) <= 30]
  if (nrow(df_donut) < 200) next

  m <- feols(high_share ~ high_tax_side * dist_to_border_km | pair_year,
             data = df_donut, cluster = ~zipcode)

  donut_results[[as.character(hole)]] <- data.table(
    donut_km = hole,
    estimate = coef(m)["high_tax_side"],
    se = se(m)["high_tax_side"],
    n_obs = nobs(m)
  )
  cat("  Donut =", hole, "km: coef =", round(coef(m)["high_tax_side"], 5),
      " SE =", round(se(m)["high_tax_side"], 5), "\n")
}

donut_dt <- rbindlist(donut_results)
donut_dt[, ci_lower := estimate - 1.96 * se]
donut_dt[, ci_upper := estimate + 1.96 * se]
fwrite(donut_dt, file.path(DATA_DIR, "donut_sensitivity.csv"))

# ============================================================================
# 3. POLYNOMIAL ORDER SENSITIVITY
# ============================================================================

cat("\n--- 3. Polynomial Order Sensitivity ---\n")

df30 <- df[abs(dist_to_border_km) <= 30]

poly_results <- list()
for (p_order in 1:3) {
  m <- feols(high_share ~ high_tax_side * poly(dist_to_border_km, p_order, raw = TRUE) | pair_year,
             data = df30, cluster = ~zipcode)

  poly_results[[as.character(p_order)]] <- data.table(
    poly_order = p_order,
    estimate = coef(m)["high_tax_side"],
    se = se(m)["high_tax_side"],
    n_obs = nobs(m)
  )
  cat("  Order", p_order, ": coef =", round(coef(m)["high_tax_side"], 5),
      " SE =", round(se(m)["high_tax_side"], 5), "\n")
}

poly_dt <- rbindlist(poly_results)
fwrite(poly_dt, file.path(DATA_DIR, "polynomial_sensitivity.csv"))

# ============================================================================
# 4. MSA-ONLY SUBSAMPLE — Within-metro sorting
# ============================================================================

cat("\n--- 4. MSA-Only Subsample ---\n")

# Focus on metro border pairs where both sides are in the same MSA
# NJ-PA (Philadelphia), OR-WA (Portland-Vancouver), NY-CT (NYC metro)
metro_pairs <- c(1, 2, 5)  # NJ-PA, NY-CT, OR-WA

df_metro <- df[pair_id %in% metro_pairs & abs(dist_to_border_km) <= 30]

if (nrow(df_metro) > 200) {
  m_metro <- feols(high_share ~ high_tax_side * dist_to_border_km | pair_year,
                   data = df_metro, cluster = ~zipcode)
  cat("Metro-only RDD:\n")
  cat("  coef =", round(coef(m_metro)["high_tax_side"], 5),
      " SE =", round(se(m_metro)["high_tax_side"], 5),
      " N =", nobs(m_metro), "\n")

  metro_result <- data.table(
    subsample = "Metro border pairs only",
    estimate = coef(m_metro)["high_tax_side"],
    se = se(m_metro)["high_tax_side"],
    n_obs = nobs(m_metro)
  )
  fwrite(metro_result, file.path(DATA_DIR, "metro_only_results.csv"))
}

# ============================================================================
# 5. IRS SUPPRESSION SENSITIVITY
# ============================================================================

cat("\n--- 5. IRS Suppression Sensitivity ---\n")

# Drop ZIPs with any suppressed income categories
df_nosup <- df[suppressed == FALSE & abs(dist_to_border_km) <= 30]

if (nrow(df_nosup) > 200) {
  m_nosup <- feols(high_share ~ high_tax_side * dist_to_border_km | pair_year,
                   data = df_nosup, cluster = ~zipcode)
  cat("No-suppression RDD:\n")
  cat("  coef =", round(coef(m_nosup)["high_tax_side"], 5),
      " SE =", round(se(m_nosup)["high_tax_side"], 5),
      " N =", nobs(m_nosup), "\n")

  sup_result <- data.table(
    check = c("Full sample (30km)", "Drop suppressed ZIPs"),
    estimate = c(coef(feols(high_share ~ high_tax_side * dist_to_border_km | pair_year,
                            data = df[abs(dist_to_border_km) <= 30], cluster = ~zipcode))["high_tax_side"],
                 coef(m_nosup)["high_tax_side"]),
    se = c(se(feols(high_share ~ high_tax_side * dist_to_border_km | pair_year,
                    data = df[abs(dist_to_border_km) <= 30], cluster = ~zipcode))["high_tax_side"],
           se(m_nosup)["high_tax_side"])
  )
  fwrite(sup_result, file.path(DATA_DIR, "suppression_sensitivity.csv"))
}

# ============================================================================
# 6. COVARIATE BALANCE at the border
# ============================================================================

cat("\n--- 6. Covariate Balance ---\n")

# Test whether total returns (population proxy) and total AGI are balanced
balance_results <- list()
for (outcome_var in c("total_returns", "log_total_returns")) {
  df30 <- df[abs(dist_to_border_km) <= 30]
  m_bal <- feols(as.formula(paste(outcome_var, "~ high_tax_side * dist_to_border_km | pair_year")),
                 data = df30, cluster = ~zipcode)
  balance_results[[outcome_var]] <- data.table(
    covariate = outcome_var,
    estimate = coef(m_bal)["high_tax_side"],
    se = se(m_bal)["high_tax_side"],
    p_value = fixest::pvalue(m_bal)["high_tax_side"]
  )
  cat("  ", outcome_var, ": coef =", round(coef(m_bal)["high_tax_side"], 3),
      " p =", round(fixest::pvalue(m_bal)["high_tax_side"], 3), "\n")
}

balance_dt <- rbindlist(balance_results)
fwrite(balance_dt, file.path(DATA_DIR, "covariate_balance.csv"))

# ============================================================================
# 7. TRIPLE-DIFFERENCE: Pre-SALT vs Post-SALT × High-Tax Side × Income
# ============================================================================

cat("\n--- 7. Triple-Difference (Income × Side × Post-SALT) ---\n")

# Reshape to have high_share and low_share as stacked outcomes
df_stack <- rbindlist(list(
  df[, .(zipcode, year, pair_id, pair_year, dist_to_border_km, high_tax_side,
         post_salt, share = high_share, income_group = "High ($200K+)")],
  df[, .(zipcode, year, pair_id, pair_year, dist_to_border_km, high_tax_side,
         post_salt, share = low_share, income_group = "Low (<$50K)")]
))

df_stack[, high_income := as.integer(income_group == "High ($200K+)")]
df_stack30 <- df_stack[abs(dist_to_border_km) <= 30]

ddd_model <- feols(share ~ high_tax_side * high_income * post_salt +
                     dist_to_border_km * high_tax_side +
                     dist_to_border_km * high_income |
                     pair_year + zipcode,
                   data = df_stack30, cluster = ~zipcode)
cat("Triple-difference model:\n")
summary(ddd_model)

ddd_result <- data.table(
  term = names(coef(ddd_model)),
  estimate = coef(ddd_model),
  se = se(ddd_model),
  p_value = fixest::pvalue(ddd_model)
)
fwrite(ddd_result, file.path(DATA_DIR, "triple_diff_results.csv"))

# Save DDD model metadata
ddd_meta <- data.table(
  n_obs = nobs(ddd_model),
  n_clusters = length(unique(df_stack30$zipcode)),
  n_zip_fe = fixest::fixef(ddd_model, sorted = TRUE)$zipcode |> length(),
  n_pair_year_fe = fixest::fixef(ddd_model, sorted = TRUE)$pair_year |> length()
)
fwrite(ddd_meta, file.path(DATA_DIR, "triple_diff_meta.csv"))

# ============================================================================
# 8. WELFARE: Revenue elasticity of migration
# ============================================================================

cat("\n--- 8. Welfare: Revenue Elasticity ---\n")

# Compute the migration elasticity following Kleven-Landais-Saez (2014)
# The key parameter is d(share_high) / d(1 - tax_rate)

# Average tax differential across border pairs
avg_tax_diff <- df[, mean(tax_differential, na.rm = TRUE)] / 100  # Convert to proportion

# Main RDD estimate (change in high-income share at border)
main_est <- fread(file.path(DATA_DIR, "rdd_main_results.csv"))
tau <- main_est[outcome == "high_share", estimate]

# Baseline high-income share on low-tax side
base_share <- df[high_tax_side == 0, mean(high_share, na.rm = TRUE)]

# Elasticity: (% change in population share) / (% change in net-of-tax rate)
if (avg_tax_diff > 0 & base_share > 0) {
  pct_change_share <- tau / base_share
  pct_change_net_rate <- avg_tax_diff  # Approximate
  elasticity <- pct_change_share / pct_change_net_rate

  welfare <- data.table(
    parameter = c("tau (RDD estimate)", "base_share (low-tax side)",
                  "avg_tax_differential", "pct_change_share",
                  "migration_elasticity"),
    value = c(tau, base_share, avg_tax_diff, pct_change_share, elasticity)
  )
  fwrite(welfare, file.path(DATA_DIR, "welfare_estimates.csv"))
  cat("Migration elasticity:", round(elasticity, 3), "\n")
  print(welfare)
}

# ============================================================================
# 9. POOLED RDD EXCLUDING NJ-PA
# ============================================================================

cat("\n--- 9. Pooled RDD Excluding NJ-PA ---\n")

# NJ-PA has very small effective N (30) and dominates the pooled estimate
# Run pooled nonparametric RDD without NJ-PA pair
df_exnjpa <- df[pair_id != 1]  # pair_id 1 = NJ-PA
cat("Excluding NJ-PA: N =", nrow(df_exnjpa), "\n")

rdd_exnjpa <- tryCatch(
  rdrobust(
    y = df_exnjpa$high_share,
    x = df_exnjpa$dist_to_border_km,
    c = 0, kernel = "triangular", bwselect = "mserd",
    cluster = df_exnjpa$zipcode
  ),
  error = function(e) { cat("  Failed:", e$message, "\n"); NULL }
)

if (!is.null(rdd_exnjpa)) {
  exnjpa_result <- data.table(
    specification = "Pooled excl. NJ-PA",
    estimate = rdd_exnjpa$coef[1],
    se_robust = rdd_exnjpa$se[3],
    bw = rdd_exnjpa$bws[1, 1],
    n_eff_left = rdd_exnjpa$N_h[1],
    n_eff_right = rdd_exnjpa$N_h[2],
    p_value = rdd_exnjpa$pv[3]
  )
  fwrite(exnjpa_result, file.path(DATA_DIR, "pooled_excl_njpa.csv"))
  cat("  Estimate:", round(rdd_exnjpa$coef[1], 4),
      " SE:", round(rdd_exnjpa$se[3], 4),
      " p:", round(rdd_exnjpa$pv[3], 4), "\n")
}

# ============================================================================
# 10. DDD EVENT STUDY — Income × Border Side × Year
# ============================================================================

cat("\n--- 10. DDD Event Study (Income × Side × Year) ---\n")

# Stack high and low income shares
df_stack_es <- rbindlist(list(
  df[, .(zipcode, year, pair_id, pair_year, dist_to_border_km, high_tax_side,
         share = high_share, income_group = "High")],
  df[, .(zipcode, year, pair_id, pair_year, dist_to_border_km, high_tax_side,
         share = low_share, income_group = "Low")]
))
df_stack_es[, high_income := as.integer(income_group == "High")]
df_stack_es30 <- df_stack_es[abs(dist_to_border_km) <= 30]

# Create the triple interaction variable
df_stack_es30[, hts_hi := high_tax_side * high_income]

# Event study: year × (high_tax_side × high_income) (base: 2017)
# MUST include year × high_income to absorb national trends in income composition
ddd_es <- feols(share ~ i(year, hts_hi, ref = 2017) +
                  i(year, high_income, ref = 2017) +
                  high_tax_side * high_income +
                  dist_to_border_km * high_tax_side +
                  dist_to_border_km * high_income |
                  pair_year + zipcode,
                data = df_stack_es30, cluster = ~zipcode)
cat("DDD event study model:\n")
summary(ddd_es)

# Extract DDD event study coefficients
ddd_es_coefs <- as.data.table(coeftable(ddd_es), keep.rownames = TRUE)
ddd_es_coefs <- ddd_es_coefs[grepl("^year::", rn) & grepl("hts_hi", rn)]
ddd_es_coefs[, year := as.integer(gsub("year::(\\d+):hts_hi", "\\1", rn))]
ddd_es_coefs <- ddd_es_coefs[!is.na(year)]
setnames(ddd_es_coefs, c("rn", "estimate", "se", "t_stat", "p_value", "year"))

# Add base year
ddd_es_coefs <- rbind(
  ddd_es_coefs,
  data.table(rn = "base", estimate = 0, se = 0, t_stat = NA, p_value = NA, year = 2017)
)
setorder(ddd_es_coefs, year)
ddd_es_coefs[, ci_lower := estimate - 1.96 * se]
ddd_es_coefs[, ci_upper := estimate + 1.96 * se]

fwrite(ddd_es_coefs, file.path(DATA_DIR, "ddd_event_study_coefs.csv"))
cat("DDD event study coefficients saved\n")
print(ddd_es_coefs[, .(year, estimate, se, p_value)])

# Pre-trends test: joint significance of pre-2018 coefficients
pre_coefs <- ddd_es_coefs[year < 2017 & year != 2017]
if (nrow(pre_coefs) > 0) {
  # F-test for joint significance of pre-period coefficients
  pre_years <- pre_coefs$year
  pre_terms <- paste0("year::", pre_years, ":hts_hi")
  pre_test <- tryCatch({
    wald(ddd_es, pre_terms)
  }, error = function(e) {
    cat("  Wald test error:", e$message, "\n")
    NULL
  })
  if (!is.null(pre_test)) {
    cat("Pre-trends joint F-test p-value:", pre_test$p, "\n")
    pre_test_result <- data.table(
      test = "Joint pre-trends (DDD)",
      f_stat = pre_test$stat,
      p_value = pre_test$p,
      df1 = pre_test$df1,
      df2 = pre_test$df2
    )
    fwrite(pre_test_result, file.path(DATA_DIR, "ddd_pretrends_test.csv"))
  }
}

# ============================================================================
# 11. BORDER-PAIR CLUSTERED SEs for Triple-Diff
# ============================================================================

cat("\n--- 11. Border-Pair Clustered SEs ---\n")

df_stack_bp <- rbindlist(list(
  df[, .(zipcode, year, pair_id, pair_year, dist_to_border_km, high_tax_side,
         post_salt, share = high_share, income_group = "High")],
  df[, .(zipcode, year, pair_id, pair_year, dist_to_border_km, high_tax_side,
         post_salt, share = low_share, income_group = "Low")]
))
df_stack_bp[, high_income := as.integer(income_group == "High")]
df_stack_bp30 <- df_stack_bp[abs(dist_to_border_km) <= 30]

# Same DDD model, but clustered at border-pair level
ddd_bp <- feols(share ~ high_tax_side * high_income * post_salt +
                  dist_to_border_km * high_tax_side +
                  dist_to_border_km * high_income |
                  pair_year + zipcode,
                data = df_stack_bp30, cluster = ~pair_id)

# Save comparison
ddd_zip <- feols(share ~ high_tax_side * high_income * post_salt +
                   dist_to_border_km * high_tax_side +
                   dist_to_border_km * high_income |
                   pair_year + zipcode,
                 data = df_stack_bp30, cluster = ~zipcode)

triple_term <- "high_tax_side:high_income:post_salt"
bp_compare <- data.table(
  clustering = c("ZIP code", "Border pair"),
  estimate = c(coef(ddd_zip)[triple_term], coef(ddd_bp)[triple_term]),
  se = c(se(ddd_zip)[triple_term], se(ddd_bp)[triple_term]),
  p_value = c(fixest::pvalue(ddd_zip)[triple_term], fixest::pvalue(ddd_bp)[triple_term]),
  n_clusters = c(length(unique(df_stack_bp30$zipcode)), length(unique(df_stack_bp30$pair_id)))
)
fwrite(bp_compare, file.path(DATA_DIR, "ddd_clustering_comparison.csv"))
cat("Clustering comparison:\n")
print(bp_compare)

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
