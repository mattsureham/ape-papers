# 03_main_analysis.R — Main estimation and mechanism tests
# apep_0582: The Resilience Puzzle — European Manufacturing and the Russian Gas Shock

source("00_packages.R")

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, date := as.Date(date)]

cat("Panel loaded:", nrow(panel), "obs,",
    uniqueN(panel$geo), "countries,",
    uniqueN(panel$nace), "sectors\n")

# ============================================================================
# 1. MAIN SPECIFICATION: Triple-interaction DiD
# ============================================================================
cat("\n=== MAIN SPECIFICATION ===\n")

# Specification 1: Basic triple interaction with two-way FE
m1 <- feols(log_prod ~ exposure:post |
              cs_id + ym,
            data = panel,
            cluster = ~geo)

# Specification 2: Add country × time FE (absorb country-level macro shocks)
m2 <- feols(log_prod ~ exposure:post |
              cs_id + ct_id,
            data = panel,
            cluster = ~geo)

# Specification 3: Full triple FE (preferred specification)
m3 <- feols(log_prod ~ exposure:post |
              cs_id + ct_id + st_id,
            data = panel,
            cluster = ~geo)

# Specification 4: Allow treatment to vary with subsidy intensity
m4 <- feols(log_prod ~ exposure:post + exposure:post:high_subsidy |
              cs_id + ct_id + st_id,
            data = panel,
            cluster = ~geo)

cat("\n--- Main Results ---\n")
etable(m1, m2, m3, m4,
       headers = c("Two-way FE", "Country×Time FE", "Triple FE (Preferred)", "Subsidy Interaction"),
       se.below = TRUE, signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1))

# Save main results
main_results <- data.table(
  spec = c("Two-way FE", "Country×Time FE", "Triple FE", "Subsidy Interaction"),
  coef_exposure_post = c(coef(m1)["exposure:post"], coef(m2)["exposure:post"],
                          coef(m3)["exposure:post"], coef(m4)["exposure:post"]),
  se = c(se(m1)["exposure:post"], se(m2)["exposure:post"],
         se(m3)["exposure:post"], se(m4)["exposure:post"]),
  t_stat = c(tstat(m1)["exposure:post"], tstat(m2)["exposure:post"],
             tstat(m3)["exposure:post"], tstat(m4)["exposure:post"]),
  n_obs = c(nobs(m1), nobs(m2), nobs(m3), nobs(m4)),
  n_countries = panel[, uniqueN(geo)],
  n_sectors = panel[, uniqueN(nace)]
)

# Add subsidy interaction coefficient if available
if ("exposure:post:high_subsidy" %in% names(coef(m4))) {
  main_results[spec == "Subsidy Interaction",
               `:=`(coef_subsidy_interaction = coef(m4)["exposure:post:high_subsidy"],
                    se_subsidy = se(m4)["exposure:post:high_subsidy"])]
}

fwrite(main_results, file.path(data_dir, "main_results.csv"))
cat("\nMain results saved.\n")

# ============================================================================
# 2. EVENT STUDY — Monthly coefficients
# ============================================================================
cat("\n=== EVENT STUDY ===\n")

# Create relative time variable (months since March 2022)
panel[, rel_month := as.integer(difftime(date, as.Date("2022-03-01"), units = "days")) %/% 30]

# Bin extreme pre/post periods
panel[, rel_month_binned := pmax(pmin(rel_month, 24), -36)]

# Event study with triple FE
es <- feols(log_prod ~ i(rel_month_binned, exposure, ref = -1) |
              cs_id + ct_id + st_id,
            data = panel,
            cluster = ~geo)

# Extract event study coefficients
# fixest i() creates names like "rel_month_binned::-36:exposure" or similar
coef_names <- names(coef(es))
# Parse the relative month from the coefficient names
rel_months_raw <- gsub(".*::", "", coef_names)
rel_months_raw <- gsub(":.*", "", rel_months_raw)
es_coefs <- data.table(
  rel_month = as.integer(rel_months_raw),
  coef = as.numeric(coef(es)),
  se = as.numeric(se(es))
)
# Remove rows that failed to parse
es_coefs <- es_coefs[!is.na(rel_month)]
es_coefs[, ci_lo := coef - 1.96 * se]
es_coefs[, ci_hi := coef + 1.96 * se]

fwrite(es_coefs, file.path(data_dir, "event_study_coefs.csv"))
cat("Event study coefficients saved:", nrow(es_coefs), "periods\n")

# Pre-trend F-test
pre_coefs <- es_coefs[rel_month < -1]
if (nrow(pre_coefs) > 0) {
  pre_f <- sum((pre_coefs$coef / pre_coefs$se)^2) / nrow(pre_coefs)
  pre_p <- pf(pre_f, nrow(pre_coefs), nobs(es) - length(coef(es)), lower.tail = FALSE)
  cat("Pre-trend F-test: F =", round(pre_f, 3), ", p =", round(pre_p, 4), "\n")
  fwrite(data.table(f_stat = pre_f, p_value = pre_p, n_pre_periods = nrow(pre_coefs)),
         file.path(data_dir, "pretrend_test.csv"))
}

# ============================================================================
# 3. MECHANISM 1: FISCAL SHIELD — Subsidy interaction
# ============================================================================
cat("\n=== MECHANISM 1: FISCAL SHIELD ===\n")

# Continuous subsidy interaction
m_subsidy_cont <- feols(log_prod ~ exposure:post + exposure:post:subsidy_pct_gdp |
                          cs_id + ct_id + st_id,
                        data = panel,
                        cluster = ~geo)

cat("Subsidy interaction (continuous):\n")
summary(m_subsidy_cont)

# Triple interaction: exposure × post × subsidy
# If subsidy ATTENUATES the effect, the coefficient on the triple interaction should be POSITIVE
# (offsetting the negative exposure × post effect)
fiscal_results <- data.table(
  mechanism = "Fiscal shield",
  coef_main = coef(m_subsidy_cont)["exposure:post"],
  se_main = se(m_subsidy_cont)["exposure:post"],
  coef_interaction = coef(m_subsidy_cont)["exposure:post:subsidy_pct_gdp"],
  se_interaction = se(m_subsidy_cont)["exposure:post:subsidy_pct_gdp"]
)

fwrite(fiscal_results, file.path(data_dir, "fiscal_shield_results.csv"))

# ============================================================================
# 4. MECHANISM 2: COST PASS-THROUGH — Producer prices
# ============================================================================
cat("\n=== MECHANISM 2: COST PASS-THROUGH ===\n")

if (sum(!is.na(panel$log_ppi)) > 1000) {
  m_ppi <- feols(log_ppi ~ exposure:post |
                   cs_id + ct_id + st_id,
                 data = panel[!is.na(log_ppi)],
                 cluster = ~geo)

  cat("Producer price effect:\n")
  summary(m_ppi)

  ppi_results <- data.table(
    outcome = "log_ppi",
    coef = coef(m_ppi)["exposure:post"],
    se = se(m_ppi)["exposure:post"],
    n_obs = nobs(m_ppi)
  )
  fwrite(ppi_results, file.path(data_dir, "ppi_results.csv"))
} else {
  cat("Insufficient PPI data for mechanism test.\n")
  ppi_results <- data.table(outcome = "log_ppi", coef = NA, se = NA, n_obs = 0)
  fwrite(ppi_results, file.path(data_dir, "ppi_results.csv"))
}

# ============================================================================
# 5. MECHANISM 3: HETEROGENEITY BY GAS INTENSITY TERCILE
# ============================================================================
cat("\n=== HETEROGENEITY BY GAS INTENSITY ===\n")

# Split sectors into high/medium/low gas intensity
sector_gas <- unique(panel[, .(nace, gas_intensity, sector_name)])
sector_gas[, intensity_group := cut(gas_intensity,
                                     breaks = quantile(gas_intensity, probs = c(0, 1/3, 2/3, 1)),
                                     labels = c("Low", "Medium", "High"),
                                     include.lowest = TRUE)]
panel <- merge(panel, sector_gas[, .(nace, intensity_group)], by = "nace", all.x = TRUE)

# Estimate by intensity group
het_results <- list()
for (grp in c("Low", "Medium", "High")) {
  sub <- panel[intensity_group == grp]
  if (nrow(sub) < 100) next
  m_grp <- tryCatch(
    feols(log_prod ~ russian_gas_share:post |
            cs_id + ym,
          data = sub,
          cluster = ~geo),
    error = function(e) { cat("  Heterogeneity", grp, "failed:", e$message, "\n"); NULL }
  )
  if (!is.null(m_grp) && "russian_gas_share:post" %in% names(coef(m_grp))) {
    het_results[[grp]] <- data.table(
      intensity_group = grp,
      coef = coef(m_grp)["russian_gas_share:post"],
      se = se(m_grp)["russian_gas_share:post"],
      n_obs = nobs(m_grp),
      n_sectors = sub[, uniqueN(nace)]
    )
  }
}

het_dt <- rbindlist(het_results)
if (nrow(het_dt) == 0) {
  cat("WARNING: Heterogeneity by intensity failed. Creating placeholder.\n")
  het_dt <- data.table(intensity_group = c("Low", "Medium", "High"),
                        coef = NA_real_, se = NA_real_, n_obs = 0, n_sectors = 0)
}
fwrite(het_dt, file.path(data_dir, "heterogeneity_intensity.csv"))
cat("Heterogeneity results:\n")
print(het_dt)

# ============================================================================
# 6. DESCRIPTIVE: Raw production trends by exposure group
# ============================================================================
cat("\n=== DESCRIPTIVE TRENDS ===\n")

# Create exposure groups
panel[, exposure_group := cut(russian_gas_share,
                               breaks = c(-Inf, 0.15, 0.40, Inf),
                               labels = c("Low (<15%)", "Medium (15-40%)", "High (>40%)"))]

# Mean production by exposure group × month
trends <- panel[, .(mean_prod = mean(prod_index, na.rm = TRUE),
                     sd_prod = sd(prod_index, na.rm = TRUE),
                     n = .N),
                 by = .(date, exposure_group)]

fwrite(trends, file.path(data_dir, "production_trends.csv"))

# Gas-intensive sectors only
trends_gas <- panel[gas_intensity > 0.5,
                     .(mean_prod = mean(prod_index, na.rm = TRUE),
                       sd_prod = sd(prod_index, na.rm = TRUE),
                       n = .N),
                     by = .(date, exposure_group)]

fwrite(trends_gas, file.path(data_dir, "production_trends_gas_intensive.csv"))

cat("\nAll main analyses completed.\n")
cat("Output files in:", data_dir, "\n")
