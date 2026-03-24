## 03_main_analysis.R — RDD and panel regressions
## apep_0865: Last Call for Competition

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

cat("=== Main Analysis ===\n")
cat(sprintf("Panel: %d county-years, %d counties\n",
            nrow(panel), length(unique(panel$fips))))

# ============================================================
# 1. RDD: Effect of crossing the population threshold
# ============================================================
cat("\n--- RDD Analysis ---\n")

# Running variable: distance to NEAREST threshold crossing
# For each county-year, compute how far the population is from
# the nearest 7,500 increment boundary
panel[, rv_mod := POP %% 7500]
panel[, rv_centered := rv_mod - 3750]  # Center at midpoint: [-3750, 3750]
# Positive values = closer to upper threshold (about to gain license)
# But we want: distance to the NEXT threshold crossing (upward)
# rv_mod close to 0 or 7500 means near a boundary

# Better RDD running variable: fractional distance to next threshold
panel[, rv := (POP %% 7500) / 7500]  # 0 to 1: 0 = just crossed, 1 = far from next
# Treatment: just crossed a threshold = rv close to 0
# The discontinuity is at rv = 0 (population is exact multiple of 7500)

# Alternative: use the total new licenses as quasi-continuous treatment
# More interpretable: compare counties that just barely got a new license
# vs. those that just barely didn't

# Year-over-year population growth modular distance
# For the RDD, use the year-over-year crossing indicator
# Running variable = population growth needed to hit next license threshold
panel[, pop_to_next := next_threshold - POP]

# RDD sample: county-years near a threshold crossing
rdd_bw <- 2000  # Bandwidth: +/- 2000 residents from threshold
panel[, rdd_sample := abs(pop_to_next) <= rdd_bw | (gained_license == 1 & pop_to_next <= 0)]

# For crossed counties, the "distance" is negative (already past)
# Recalculate: distance from the threshold they just crossed
panel[, prev_threshold := licenses_entitled * 7500]
panel[, dist_from_crossed := POP - prev_threshold]  # 0-7499 for counties that just crossed
panel[, rv_rdd := fifelse(gained_license == 1, dist_from_crossed, -pop_to_next)]
# Negative = below threshold; positive = above (just crossed)

# RDD estimation using rdrobust
rdd_data <- panel[!is.na(emp_drink) & !is.na(rv_rdd) & is.finite(rv_rdd)]

if (nrow(rdd_data[rv_rdd > -5000 & rv_rdd < 10000]) > 50) {
  cat("Running rdrobust for drinking-place employment...\n")

  rdd_emp <- rdrobust(
    y = rdd_data$emp_drink,
    x = rdd_data$rv_rdd,
    c = 0,
    kernel = "triangular",
    all = TRUE
  )
  cat("\nRDD: Drinking-place employment\n")
  summary(rdd_emp)

  # Store RDD results
  rdd_coef_emp <- rdd_emp$coef[1]  # Conventional
  rdd_se_emp <- rdd_emp$se[3]      # Robust
  rdd_bw_emp <- rdd_emp$bws[1, 1]  # Bandwidth

  rdd_estabs <- rdrobust(
    y = rdd_data$estabs_drink,
    x = rdd_data$rv_rdd,
    c = 0,
    kernel = "triangular",
    all = TRUE
  )
  cat("\nRDD: Drinking-place establishments\n")
  summary(rdd_estabs)

  rdd_coef_estabs <- rdd_estabs$coef[1]
  rdd_se_estabs <- rdd_estabs$se[3]
} else {
  cat("WARNING: Insufficient observations near RDD threshold.\n")
  cat("Proceeding with panel regression approach.\n")
  rdd_coef_emp <- NA
  rdd_se_emp <- NA
  rdd_coef_estabs <- NA
  rdd_se_estabs <- NA
}

# McCrary density test
cat("\nMcCrary density test...\n")
density_test <- tryCatch(
  rddensity(rdd_data$rv_rdd, c = 0),
  error = function(e) {
    cat(sprintf("  Density test failed: %s\n", e$message))
    NULL
  }
)
if (!is.null(density_test)) {
  cat(sprintf("  T-statistic: %.3f, p-value: %.3f\n",
              density_test$test$t_jk, density_test$test$p_jk))
}

# ============================================================
# 2. Panel FE: Effect of new license allocations
# ============================================================
cat("\n--- Panel Fixed Effects ---\n")

# Main specification: county + year FE
# Y_ct = beta * NewLicenses_ct + delta_c + theta_t + epsilon_ct
panel[, fips_f := as.factor(fips)]
panel[, year_f := as.factor(year)]

# Drinking-place employment
m1 <- feols(emp_drink ~ new_licenses_yr | fips_f + year_f,
            data = panel[!is.na(emp_drink)],
            cluster = ~fips_f)
cat("\nModel 1: Drinking-place employment ~ new licenses (County + Year FE)\n")
summary(m1)

# Drinking-place establishments
m2 <- feols(estabs_drink ~ new_licenses_yr | fips_f + year_f,
            data = panel[!is.na(estabs_drink)],
            cluster = ~fips_f)
cat("\nModel 2: Drinking-place establishments ~ new licenses\n")
summary(m2)

# Log employment
m3 <- feols(log_emp_drink ~ new_licenses_yr | fips_f + year_f,
            data = panel[!is.na(log_emp_drink) & is.finite(log_emp_drink)],
            cluster = ~fips_f)
cat("\nModel 3: Log drinking-place employment ~ new licenses\n")
summary(m3)

# Per capita employment
m4 <- feols(emp_drink_pc ~ new_licenses_yr | fips_f + year_f,
            data = panel[!is.na(emp_drink_pc)],
            cluster = ~fips_f)
cat("\nModel 4: Drinking-place employment per 10K ~ new licenses\n")
summary(m4)

# Placebo: Restaurant employment (not subject to quota licenses)
m5 <- feols(emp_rest ~ new_licenses_yr | fips_f + year_f,
            data = panel[!is.na(emp_rest)],
            cluster = ~fips_f)
cat("\nModel 5 (Placebo): Restaurant employment ~ new licenses\n")
summary(m5)

# Weekly wages
m6 <- feols(wage_drink ~ new_licenses_yr | fips_f + year_f,
            data = panel[!is.na(wage_drink)],
            cluster = ~fips_f)
cat("\nModel 6: Drinking-place average weekly wage ~ new licenses\n")
summary(m6)

# ============================================================
# 3. Cumulative licenses (stock vs flow)
# ============================================================
cat("\n--- Cumulative license stock ---\n")

m7 <- feols(emp_drink ~ new_licenses_cumul | fips_f + year_f,
            data = panel[!is.na(emp_drink)],
            cluster = ~fips_f)
cat("\nModel 7: Drinking-place employment ~ cumulative new licenses\n")
summary(m7)

m8 <- feols(estabs_drink ~ new_licenses_cumul | fips_f + year_f,
            data = panel[!is.na(estabs_drink)],
            cluster = ~fips_f)
cat("\nModel 8: Drinking-place establishments ~ cumulative new licenses\n")
summary(m8)

# ============================================================
# 4. Save results for tables
# ============================================================
save(m1, m2, m3, m4, m5, m6, m7, m8,
     rdd_coef_emp, rdd_se_emp, rdd_coef_estabs, rdd_se_estabs,
     density_test,
     file = file.path(data_dir, "main_results.RData"))

# Write diagnostics
n_treated <- length(unique(panel$fips[panel$gained_license == 1]))
n_pre <- length(unique(panel$year[panel$year < 2015]))
n_obs <- nrow(panel[!is.na(emp_drink)])

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_counties = length(unique(panel$fips)),
  n_years = length(unique(panel$year)),
  mean_emp_drink = mean(panel$emp_drink, na.rm = TRUE),
  sd_emp_drink = sd(panel$emp_drink, na.rm = TRUE),
  mean_estabs_drink = mean(panel$estabs_drink, na.rm = TRUE),
  sd_estabs_drink = sd(panel$estabs_drink, na.rm = TRUE)
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
cat(sprintf("Treated counties: %d\n", n_treated))
cat(sprintf("Pre-periods: %d\n", n_pre))
cat(sprintf("Observations: %d\n", n_obs))
