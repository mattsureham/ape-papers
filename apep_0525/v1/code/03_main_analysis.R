# ============================================================================
# 03_main_analysis.R — Primary RDD and event study estimates
# APEP-0525: Tax Borders and the Rich
# ============================================================================

source("00_packages.R")

df <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
cat("Analysis panel loaded:", nrow(df), "rows\n")

# Remove suppressed ZIPs and missing outcomes
df <- df[!is.na(high_share) & total_returns >= 10]

# ============================================================================
# 1. CROSS-SECTIONAL RDD — Pooled boundary discontinuity
# ============================================================================

cat("\n--- 1. Pooled Boundary Discontinuity ---\n")

# Main outcome: share of $200K+ returns
# Running variable: distance to border (negative = high-tax side)
# Use rdrobust for optimal bandwidth selection

# Pool all border pairs and years
rdd_main <- rdrobust(
  y = df$high_share,
  x = df$dist_to_border_km,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd",
  cluster = df$zipcode
)
cat("\nPooled RDD (high-income share):\n")
summary(rdd_main)

# Save main RDD result
rdd_result <- data.table(
  outcome = "high_share",
  estimate = rdd_main$coef[1],
  se_robust = rdd_main$se[3],
  ci_lower = rdd_main$ci[3, 1],
  ci_upper = rdd_main$ci[3, 2],
  bw_left = rdd_main$bws[1, 1],
  bw_right = rdd_main$bws[1, 2],
  n_left = rdd_main$N[1],
  n_right = rdd_main$N[2],
  n_eff_left = rdd_main$N_h[1],
  n_eff_right = rdd_main$N_h[2],
  p_value = rdd_main$pv[3]
)

# Placebo: low-income share
rdd_placebo <- rdrobust(
  y = df$low_share,
  x = df$dist_to_border_km,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd",
  cluster = df$zipcode
)
cat("\nPlacebo RDD (low-income share):\n")
summary(rdd_placebo)

rdd_placebo_result <- data.table(
  outcome = "low_share",
  estimate = rdd_placebo$coef[1],
  se_robust = rdd_placebo$se[3],
  ci_lower = rdd_placebo$ci[3, 1],
  ci_upper = rdd_placebo$ci[3, 2],
  bw_left = rdd_placebo$bws[1, 1],
  bw_right = rdd_placebo$bws[1, 2],
  n_left = rdd_placebo$N[1],
  n_right = rdd_placebo$N[2],
  n_eff_left = rdd_placebo$N_h[1],
  n_eff_right = rdd_placebo$N_h[2],
  p_value = rdd_placebo$pv[3]
)

rdd_results <- rbind(rdd_result, rdd_placebo_result)
fwrite(rdd_results, file.path(DATA_DIR, "rdd_main_results.csv"))

# ============================================================================
# 2. PARAMETRIC RDD — with border-pair × year FE
# ============================================================================

cat("\n--- 2. Parametric RDD with FE ---\n")

# Linear distance polynomial
m1 <- feols(high_share ~ high_tax_side * dist_to_border_km | pair_year,
            data = df, cluster = ~zipcode)

# Quadratic distance polynomial
m2 <- feols(high_share ~ high_tax_side * poly(dist_to_border_km, 2, raw = TRUE) | pair_year,
            data = df, cluster = ~zipcode)

# Restrict to optimal bandwidth from rdrobust
opt_bw <- max(rdd_main$bws[1, 1], rdd_main$bws[1, 2])
df_bw <- df[abs(dist_to_border_km) <= opt_bw]

m3 <- feols(high_share ~ high_tax_side * dist_to_border_km | pair_year,
            data = df_bw, cluster = ~zipcode)

# Placebo: low-income share
m4 <- feols(low_share ~ high_tax_side * dist_to_border_km | pair_year,
            data = df, cluster = ~zipcode)

# Mid-income share
m5 <- feols(mid_share ~ high_tax_side * dist_to_border_km | pair_year,
            data = df, cluster = ~zipcode)

# Log high-income returns
m6 <- feols(log_high_returns ~ high_tax_side * dist_to_border_km | pair_year,
            data = df, cluster = ~zipcode)

parametric_results <- data.table(
  model = c("Linear (50km)", "Quadratic (50km)", paste0("Linear (", round(opt_bw, 0), "km)"),
            "Placebo: Low-inc", "Placebo: Mid-inc", "Log high returns"),
  outcome = c("high_share", "high_share", "high_share", "low_share", "mid_share", "log_high_returns"),
  estimate = c(coef(m1)["high_tax_side"], coef(m2)["high_tax_side"],
               coef(m3)["high_tax_side"], coef(m4)["high_tax_side"],
               coef(m5)["high_tax_side"], coef(m6)["high_tax_side"]),
  se = c(se(m1)["high_tax_side"], se(m2)["high_tax_side"],
         se(m3)["high_tax_side"], se(m4)["high_tax_side"],
         se(m5)["high_tax_side"], se(m6)["high_tax_side"]),
  n_obs = c(nobs(m1), nobs(m2), nobs(m3), nobs(m4), nobs(m5), nobs(m6))
)

fwrite(parametric_results, file.path(DATA_DIR, "parametric_rdd_results.csv"))
cat("Parametric results saved\n")
print(parametric_results)

# ============================================================================
# 3. EVENT STUDY — SALT cap interaction with border discontinuity
# ============================================================================

cat("\n--- 3. Event Study: SALT Cap × Border Discontinuity ---\n")

# Create year × high_tax_side interactions (base: 2017)
df[, year_factor := factor(year)]
df[, year_factor := relevel(year_factor, ref = "2017")]

es_model <- feols(high_share ~ i(year, high_tax_side, ref = 2017) * dist_to_border_km |
                    pair_year,
                  data = df[abs(dist_to_border_km) <= 30],
                  cluster = ~zipcode)
cat("\nEvent study model:\n")
summary(es_model)

# Extract event study coefficients
es_coefs <- as.data.table(coeftable(es_model), keep.rownames = TRUE)
es_coefs <- es_coefs[grepl("^year::", rn) & !grepl("dist_to_border", rn)]
es_coefs[, year := as.integer(gsub("year::(\\d+):high_tax_side", "\\1", rn))]
es_coefs <- es_coefs[!is.na(year)]
setnames(es_coefs, c("rn", "estimate", "se", "t_stat", "p_value", "year"))

# Add 2017 base year
es_coefs <- rbind(
  es_coefs,
  data.table(rn = "base", estimate = 0, se = 0, t_stat = NA, p_value = NA, year = 2017)
)
setorder(es_coefs, year)

es_coefs[, ci_lower := estimate - 1.96 * se]
es_coefs[, ci_upper := estimate + 1.96 * se]

fwrite(es_coefs, file.path(DATA_DIR, "event_study_coefs.csv"))
cat("Event study coefficients saved\n")
print(es_coefs[, .(year, estimate, se, p_value)])

# ============================================================================
# 4. PERIOD-SPECIFIC RDD — Pre-SALT vs Post-SALT vs COVID
# ============================================================================

cat("\n--- 4. Period-Specific RDD ---\n")

period_results <- list()
for (per in c("Pre-SALT", "Post-SALT/Pre-COVID", "COVID")) {
  df_per <- df[period == per]
  if (nrow(df_per) < 100) next

  rdd_per <- tryCatch(
    rdrobust(y = df_per$high_share, x = df_per$dist_to_border_km, c = 0,
             kernel = "triangular", bwselect = "mserd", cluster = df_per$zipcode),
    error = function(e) {
      cat("  RDD failed for period", per, ":", e$message, "\n")
      NULL
    }
  )

  if (!is.null(rdd_per)) {
    period_results[[per]] <- data.table(
      period = per,
      estimate = rdd_per$coef[1],
      se_robust = rdd_per$se[3],
      ci_lower = rdd_per$ci[3, 1],
      ci_upper = rdd_per$ci[3, 2],
      bw = rdd_per$bws[1, 1],
      n_eff = rdd_per$N_h[1] + rdd_per$N_h[2],
      p_value = rdd_per$pv[3]
    )
    cat("  ", per, ": tau =", round(rdd_per$coef[1], 4),
        " (SE =", round(rdd_per$se[3], 4), ")\n")
  }
}

period_dt <- rbindlist(period_results)
fwrite(period_dt, file.path(DATA_DIR, "period_rdd_results.csv"))

# ============================================================================
# 5. HETEROGENEITY — By border pair
# ============================================================================

cat("\n--- 5. Border-Pair Heterogeneity ---\n")

pair_results <- list()
for (pid in unique(df$pair_id)) {
  df_p <- df[pair_id == pid]
  pl <- df_p$pair_label[1]
  if (nrow(df_p) < 200) next

  rdd_p <- tryCatch(
    rdrobust(y = df_p$high_share, x = df_p$dist_to_border_km, c = 0,
             kernel = "triangular", bwselect = "mserd", cluster = df_p$zipcode),
    error = function(e) NULL
  )

  if (!is.null(rdd_p)) {
    td <- df_p$tax_differential[1]
    pair_results[[as.character(pid)]] <- data.table(
      pair_id = pid,
      pair_label = pl,
      tax_diff = td,
      estimate = rdd_p$coef[1],
      se_robust = rdd_p$se[3],
      p_value = rdd_p$pv[3],
      bw = rdd_p$bws[1, 1],
      n_eff = rdd_p$N_h[1] + rdd_p$N_h[2]
    )
    cat("  ", pl, "(diff=", round(td, 1), "pp): tau =", round(rdd_p$coef[1], 4),
        " (SE =", round(rdd_p$se[3], 4), ")\n")
  }
}

pair_dt <- rbindlist(pair_results)
fwrite(pair_dt, file.path(DATA_DIR, "pair_rdd_results.csv"))

# ============================================================================
# 6. McCrary density test
# ============================================================================

cat("\n--- 6. McCrary Density Test ---\n")

# Use rddensity package
zip_unique <- df[!duplicated(zipcode), .(zipcode, dist_to_border_km)]
density_test <- rddensity(zip_unique$dist_to_border_km, c = 0)
cat("McCrary density test:\n")
summary(density_test)

density_result <- data.table(
  test = "McCrary density (ZIP centroids)",
  t_stat = density_test$test$t_jk,
  p_value = density_test$test$p_jk,
  n_left = density_test$N[1],
  n_right = density_test$N[2]
)
fwrite(density_result, file.path(DATA_DIR, "mccrary_test.csv"))

# ============================================================================
# 7. Summary statistics
# ============================================================================

cat("\n--- 7. Summary Statistics ---\n")

# By side of border
summ_stats <- df[, .(
  n_zip_years = .N,
  n_zips = uniqueN(zipcode),
  mean_total_returns = mean(total_returns, na.rm = TRUE),
  mean_high_share = mean(high_share, na.rm = TRUE),
  sd_high_share = sd(high_share, na.rm = TRUE),
  mean_high_returns = mean(high_returns, na.rm = TRUE),
  mean_low_share = mean(low_share, na.rm = TRUE),
  mean_avg_agi_high = mean(avg_agi_high, na.rm = TRUE),
  mean_dist_km = mean(abs(dist_to_border_km), na.rm = TRUE),
  pct_suppressed = mean(suppressed, na.rm = TRUE)
), by = .(side = fifelse(high_tax_side == 1, "High-Tax Side", "Low-Tax Side"))]

fwrite(summ_stats, file.path(DATA_DIR, "summary_stats.csv"))
print(summ_stats)

# By period
period_stats <- df[, .(
  mean_high_share = mean(high_share, na.rm = TRUE),
  mean_high_returns = mean(high_returns, na.rm = TRUE),
  n_obs = .N
), by = .(period, side = fifelse(high_tax_side == 1, "High-Tax", "Low-Tax"))]
setorder(period_stats, period, side)

fwrite(period_stats, file.path(DATA_DIR, "period_summary_stats.csv"))
print(period_stats)

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
