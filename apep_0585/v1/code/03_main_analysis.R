## 03_main_analysis.R — Primary regressions
## APEP-0585: EU Medical Device Regulation (MDR) and Innovation

source("00_packages.R")

data_dir <- "../data/"

panel <- fread(paste0(data_dir, "panel_production_with_intensity.csv"))

# ============================================================================
# 1) PRIMARY DiD: C325 vs Control Sectors within EU Countries
# ============================================================================

cat("=== Primary DiD: Industry-level within EU ===\n")

# Filter to EU countries with C325 data
eu_panel <- panel[is_eu == TRUE & balanced == TRUE]

cat("  Panel: ", nrow(eu_panel), " obs, ",
    n_distinct(eu_panel$geo), " EU countries, ",
    n_distinct(eu_panel$nace), " sectors\n")

# Treatment: is_meddev × post_mdr
eu_panel[, treat := as.integer(is_meddev & post_mdr)]

# Model 1: Basic DiD with country-sector and year FE
m1 <- feols(prod_index ~ treat |
              country_sector + year,
            data = eu_panel,
            cluster = "geo")

# Model 2: Country-sector and country-year FE (preferred — absorbs all country shocks)
m2 <- feols(prod_index ~ treat |
              country_sector + geo^year,
            data = eu_panel,
            cluster = "geo")

# Model 3: Add sector-specific linear trends
eu_panel[, nace_num := as.integer(factor(nace))]
m3 <- feols(prod_index ~ treat + i(nace, year, ref = "C325") |
              country_sector + geo^year,
            data = eu_panel,
            cluster = "geo")

cat("\n--- Main DiD Results ---\n")
etable(m1, m2, m3,
       headers = c("Sector-Year FE", "Country-Year FE", "Full FE"),
       se.below = TRUE)


# ============================================================================
# 2) EVENT STUDY: Year-by-Year Effects
# ============================================================================

cat("\n=== Event Study ===\n")

# Create event-time dummies (reference: 2020, last pre-treatment year)
eu_panel[, event_time_f := factor(event_time)]
eu_panel[, event_time_f := relevel(event_time_f, ref = "-1")]  # 2020

# Interaction: is_meddev × year dummies
m_es <- feols(prod_index ~ i(event_time, is_meddev, ref = -1) |
                country_sector + geo^year,
              data = eu_panel,
              cluster = "geo")

cat("\n--- Event Study Coefficients ---\n")
summary(m_es)

# Save event study results
es_coefs <- as.data.frame(coeftable(m_es))
es_coefs$term <- rownames(es_coefs)
fwrite(es_coefs, paste0(data_dir, "event_study_coefs.csv"))


# ============================================================================
# 3) DDD: Including Non-EU Countries (Turkey as Placebo)
# ============================================================================

cat("\n=== DDD: EU vs Non-EU × C325 vs Control × Post ===\n")

# Use full panel including Turkey
full_panel <- panel[balanced == TRUE]

# Treatment: EU × C325 × post-2021
full_panel[, treat_ddd := as.integer(is_eu & is_meddev & post_mdr)]
full_panel[, eu_meddev := as.integer(is_eu & is_meddev)]
full_panel[, eu_post := as.integer(is_eu & post_mdr)]
full_panel[, meddev_post := as.integer(is_meddev & post_mdr)]

# DDD with triple interaction
# country_sector + geo^year absorbs country-time; treat_ddd varies across EU/non-EU × sector × time
m_ddd <- feols(prod_index ~ treat_ddd + meddev_post |
                 country_sector + geo^year,
               data = full_panel,
               cluster = "geo")

cat("\n--- DDD Results ---\n")
summary(m_ddd)

# Save DDD coefficients
ddd_coefs <- as.data.frame(coeftable(m_ddd))
ddd_coefs$term <- rownames(ddd_coefs)
fwrite(ddd_coefs, paste0(data_dir, "ddd_coefs.csv"))


# ============================================================================
# 4) HETEROGENEITY BY TREATMENT INTENSITY
# ============================================================================

cat("\n=== Heterogeneity: Treatment Intensity ===\n")

# Use continuous treatment intensity (% higher-risk devices in EUDAMED)
eu_panel[, treat_intense := is_meddev * post_mdr * mdr_exposure / 100]

m_intensity <- feols(prod_index ~ treat_intense |
                       country_sector + geo^year + nace^year,
                     data = eu_panel[is_eu == TRUE],
                     cluster = "geo")

cat("\n--- Intensity Results ---\n")
summary(m_intensity)


# ============================================================================
# 5) MECHANISM: EUDAMED Device Status by Risk Class
# ============================================================================

cat("\n=== Mechanism: Device Status Distribution ===\n")

eud_status <- fread(paste0(data_dir, "eudamed_status_by_risk.csv"))

# Higher risk classes should have more non-active devices if MDR is binding
status_pivot <- dcast(eud_status, risk_class_clean ~ device_status_clean, value.var = "n", fill = 0)
status_pivot[, total := rowSums(.SD, na.rm = TRUE), .SDcols = setdiff(names(status_pivot), "risk_class_clean")]

# Calculate on-the-market share
if ("on-the-market" %in% names(status_pivot)) {
  status_pivot[, pct_on_market := `on-the-market` / total * 100]
  cat("\n  On-the-market share by risk class:\n")
  print(status_pivot[, .(risk_class_clean, total, pct_on_market)])
}

fwrite(status_pivot, paste0(data_dir, "mechanism_device_status.csv"))


# ============================================================================
# 6) SAVE ALL REGRESSION RESULTS
# ============================================================================

cat("\n=== Saving regression results ===\n")

# Main results table
main_results <- data.frame(
  model = c("DiD: Year FE", "DiD: Country-Year FE", "DiD: Sector Trends", "DDD"),
  coefficient = c(coef(m1)["treat"], coef(m2)["treat"], coef(m3)["treat"],
                  coef(m_ddd)["treat_ddd"]),
  se = c(se(m1)["treat"], se(m2)["treat"], se(m3)["treat"],
         se(m_ddd)["treat_ddd"]),
  pvalue = c(fixest::pvalue(m1)["treat"], fixest::pvalue(m2)["treat"], fixest::pvalue(m3)["treat"],
             fixest::pvalue(m_ddd)["treat_ddd"]),
  n_obs = c(nobs(m1), nobs(m2), nobs(m3), nobs(m_ddd))
)

main_results$ci_low <- main_results$coefficient - 1.96 * main_results$se
main_results$ci_high <- main_results$coefficient + 1.96 * main_results$se

cat("\n--- Summary of Main Results ---\n")
print(main_results)

fwrite(main_results, paste0(data_dir, "main_results.csv"))

# Save models for table generation
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m_ddd = m_ddd, m_es = m_es,
             m_intensity = m_intensity),
        paste0(data_dir, "regression_models.rds"))

cat("\nMain analysis complete.\n")
