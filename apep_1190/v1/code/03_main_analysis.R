## 03_main_analysis.R — Main regressions
## apep_1190: Grocery Store Exits and Birth Outcomes

source("00_packages.R")
data_dir <- "../data"

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, fips := sprintf("%05d", as.integer(fips))]

cat(sprintf("Panel loaded: %d obs, %d counties\n", nrow(panel), uniqueN(panel$fips)))

# Keep only rows with non-missing LBW
analysis <- panel[!is.na(lbw_rate)]
cat(sprintf("With LBW data: %d obs, %d counties\n", nrow(analysis), uniqueN(analysis$fips)))

# ============================================================================
# 1. OLS: COUNTY FE + YEAR FE
# ============================================================================
cat("\n=== OLS Regressions ===\n")

# Scale LBW rate to percentage points for interpretability
analysis[, lbw_pct := lbw_rate * 100]
analysis[, log_estab := log(estab + 1)]
analysis[, estab_per_10k := estab / (total_pop / 10000)]

# Main spec: LBW ~ log(grocery establishments) | county + year FE
m1 <- feols(lbw_pct ~ log_estab | fips + year, data = analysis,
            cluster = ~fips)

# With controls
m2 <- feols(lbw_pct ~ log_estab + poverty_rate + log(med_income) |
              fips + year, data = analysis,
            cluster = ~fips)

# Establishments per capita
m3 <- feols(lbw_pct ~ estab_per_10k | fips + year, data = analysis,
            cluster = ~fips)

# With controls
m4 <- feols(lbw_pct ~ estab_per_10k + poverty_rate + log(med_income) |
              fips + year, data = analysis,
            cluster = ~fips)

cat("OLS results:\n")
etable(m1, m2, m3, m4,
       headers = c("log(estab)", "+ controls", "estab/10K", "+ controls"),
       se.below = TRUE)

# ============================================================================
# 2. IV: CHAIN BANKRUPTCY SHOCKS
# ============================================================================
cat("\n=== IV Regressions (Chain Bankruptcy Shocks) ===\n")

# First stage: log(establishments) ~ chain_shocks_cumulative
fs1 <- feols(log_estab ~ chain_shocks_cumulative | fips + year,
             data = analysis, cluster = ~fips)
cat("\nFirst stage (chain shocks → log establishments):\n")
summary(fs1)

# IV regression
iv1 <- feols(lbw_pct ~ 1 | fips + year |
               log_estab ~ chain_shocks_cumulative,
             data = analysis, cluster = ~fips)

# IV with controls
iv2 <- feols(lbw_pct ~ poverty_rate + log(med_income) | fips + year |
               log_estab ~ chain_shocks_cumulative,
             data = analysis, cluster = ~fips)

# IV: any_chain_post as instrument
iv3 <- feols(lbw_pct ~ 1 | fips + year |
               log_estab ~ any_chain_post,
             data = analysis, cluster = ~fips)

cat("IV results:\n")
etable(iv1, iv2, iv3,
       headers = c("IV: cumulative", "IV + controls", "IV: any post"),
       se.below = TRUE)

# ============================================================================
# 3. REDUCED FORM
# ============================================================================
cat("\n=== Reduced Form ===\n")

rf1 <- feols(lbw_pct ~ chain_shocks_cumulative | fips + year,
             data = analysis, cluster = ~fips)
rf2 <- feols(lbw_pct ~ any_chain_post | fips + year,
             data = analysis, cluster = ~fips)

cat("Reduced form (chain shocks → LBW):\n")
etable(rf1, rf2, headers = c("Cumulative shocks", "Any post"), se.below = TRUE)

# ============================================================================
# 4. HETEROGENEITY
# ============================================================================
cat("\n=== Heterogeneity ===\n")

# By poverty level (above/below median)
analysis[, high_poverty := poverty_rate > median(poverty_rate, na.rm = TRUE)]

het_low <- feols(lbw_pct ~ log_estab | fips + year,
                  data = analysis[high_poverty == FALSE],
                  cluster = ~fips)
het_high <- feols(lbw_pct ~ log_estab | fips + year,
                   data = analysis[high_poverty == TRUE],
                   cluster = ~fips)

cat("Heterogeneity by poverty:\n")
etable(het_low, het_high,
       headers = c("Low poverty", "High poverty"),
       se.below = TRUE)

# By urbanicity (population)
analysis[, urban := total_pop > 100000]

het_rural <- feols(lbw_pct ~ log_estab | fips + year,
                    data = analysis[urban == FALSE],
                    cluster = ~fips)
het_urban <- feols(lbw_pct ~ log_estab | fips + year,
                    data = analysis[urban == TRUE],
                    cluster = ~fips)

cat("Heterogeneity by urbanicity:\n")
etable(het_rural, het_urban,
       headers = c("Rural/suburban", "Urban"),
       se.below = TRUE)

# ============================================================================
# 5. SECONDARY OUTCOMES
# ============================================================================
cat("\n=== Secondary Outcomes ===\n")

# Infant mortality
if (sum(!is.na(analysis$infant_mort_rate)) > 100) {
  sec1 <- feols(infant_mort_rate ~ log_estab | fips + year,
                data = analysis[!is.na(infant_mort_rate)],
                cluster = ~fips)
  cat("Infant mortality:\n")
  summary(sec1)
}

# Teen births
if (sum(!is.na(analysis$teen_birth_rate)) > 100) {
  sec2 <- feols(teen_birth_rate ~ log_estab | fips + year,
                data = analysis[!is.na(teen_birth_rate)],
                cluster = ~fips)
  cat("\nTeen birth rate:\n")
  summary(sec2)
}

# Premature death
if (sum(!is.na(analysis$premature_death_rate)) > 100) {
  sec3 <- feols(premature_death_rate ~ log_estab | fips + year,
                data = analysis[!is.na(premature_death_rate)],
                cluster = ~fips)
  cat("\nPremature death rate:\n")
  summary(sec3)
}

# ============================================================================
# 6. SAVE DIAGNOSTICS
# ============================================================================
n_treated <- uniqueN(analysis$fips[analysis$treated == TRUE])
n_pre <- length(unique(analysis$year[analysis$year < 2015]))
n_obs <- nrow(analysis)

diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_counties = uniqueN(analysis$fips),
  years = paste(range(analysis$year), collapse = "-"),
  mean_lbw = round(mean(analysis$lbw_pct, na.rm = TRUE), 3),
  sd_lbw = round(sd(analysis$lbw_pct, na.rm = TRUE), 3),
  mean_estab = round(mean(analysis$estab, na.rm = TRUE), 1),
  sd_estab = round(sd(analysis$estab, na.rm = TRUE), 1),
  ols_coef = round(coef(m1)[1], 4),
  ols_se = round(se(m1)[1], 4),
  iv_coef = round(coef(iv1)[1], 4),
  iv_se = round(se(iv1)[1], 4),
  first_stage_f = round(fitstat(iv1, "ivf")$ivf$stat, 1)
)

jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"),
                      auto_unbox = TRUE, pretty = TRUE)

cat(sprintf("\n=== Diagnostics saved ===\n"))
cat(sprintf("N treated: %d, N pre: %d, N obs: %d\n",
            n_treated, n_pre, n_obs))
cat(sprintf("OLS coef: %.4f (%.4f)\n", diag$ols_coef, diag$ols_se))
cat(sprintf("IV coef: %.4f (%.4f)\n", diag$iv_coef, diag$iv_se))
cat(sprintf("First-stage F: %.1f\n", diag$first_stage_f))

# Save key objects for table generation
save(m1, m2, m3, m4, iv1, iv2, iv3, rf1, rf2, fs1,
     het_low, het_high, het_rural, het_urban,
     analysis, diag,
     file = file.path(data_dir, "main_results.RData"))
