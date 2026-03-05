## ============================================================
## 03_main_analysis.R — Primary regressions
## apep_0522: Flood Re and English Property Values
## ============================================================

source("00_packages.R")

# Increase memory limit for large fixed-effect models
invisible(utils::memory.limit(size = NA))  # Check current limit

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
cat(sprintf("Analysis panel: %s rows\n", format(nrow(panel), big.mark = ",")))

# Force garbage collection before heavy computations
gc()

## -------------------------------------------------------
## 1. Main DiD: Flood Risk × Post Flood Re
## -------------------------------------------------------

cat("\n=== SPECIFICATION 1: Main DiD ===\n")

# Baseline: postcode sector FE + year-quarter FE
m1_base <- feols(
  ln_price ~ flood_risk_high:post_floodre +
    i(property_type) + i(duration) + new_build |
    postcode_sector + year_quarter_str,
  data = panel,
  cluster = ~la_code
)
cat("Model 1 (base):\n")
summary(m1_base)

# With LA × year FE for local trends
m1_layr <- feols(
  ln_price ~ flood_risk_high:post_floodre +
    i(property_type) + i(duration) + new_build |
    postcode_sector + year_quarter_str + la_code^year,
  data = panel,
  cluster = ~la_code
)
cat("\nModel 1 (LA × year FE):\n")
summary(m1_layr)

## -------------------------------------------------------
## 2. Event Study: Dynamic treatment effects
## -------------------------------------------------------

cat("\n=== SPECIFICATION 2: Event Study ===\n")

# Create relative year factor (base = -1, i.e., 2015)
panel[, rel_year_f := factor(rel_year)]

# Use a narrower window and free memory from spec 1
gc()

m2_es <- feols(
  ln_price ~ i(rel_year, flood_risk_high, ref = -1) +
    i(property_type) + i(duration) + new_build |
    postcode_sector + year_quarter_str,
  data = panel[year >= 2012 & year <= 2024],
  cluster = ~la_code
)
cat("Event study:\n")
summary(m2_es)

# Save event study coefficients
es_coefs <- as.data.table(broom::tidy(m2_es, conf.int = TRUE))
es_coefs <- es_coefs[grepl("rel_year", term)]
es_coefs[, rel_year := as.integer(str_extract(term, "-?[0-9]+"))]
fwrite(es_coefs, file.path(data_dir, "event_study_coefs.csv"))

## -------------------------------------------------------
## 3. Triple-Diff: Flood Risk × Post × Eligible
## -------------------------------------------------------

cat("\n=== SPECIFICATION 3: Triple-Diff ===\n")

# Restrict to properties with known eligibility
panel_elig <- panel[eligibility %in% c("eligible", "ineligible")]
cat(sprintf("Triple-diff sample: %s rows\n",
            format(nrow(panel_elig), big.mark = ",")))

m3_ddd <- feols(
  ln_price ~ flood_risk_high:post_floodre:eligible +
    flood_risk_high:post_floodre +
    flood_risk_high:eligible +
    post_floodre:eligible +
    i(property_type) + i(duration) |
    postcode_sector + year_quarter_str,
  data = panel_elig,
  cluster = ~la_code
)
cat("Triple-diff (DDD):\n")
summary(m3_ddd)

## -------------------------------------------------------
## 4. Dose-Response by Flood Risk Band
## -------------------------------------------------------

cat("\n=== SPECIFICATION 4: Dose-Response ===\n")

# Create ordered flood risk variable
panel[, flood_dose := fcase(
  flood_risk_band == "High" | flood_risk_band == "HIGH", 3L,
  flood_risk_band == "Medium" | flood_risk_band == "MEDIUM", 2L,
  flood_risk_band == "Low" | flood_risk_band == "LOW", 1L,
  default = 0L
)]

m4_dose <- feols(
  ln_price ~ i(flood_dose, post_floodre, ref = 0) +
    i(property_type) + i(duration) + new_build |
    postcode_sector + year_quarter_str,
  data = panel,
  cluster = ~la_code
)
cat("Dose-response:\n")
summary(m4_dose)

# Save dose coefficients
dose_coefs <- as.data.table(broom::tidy(m4_dose, conf.int = TRUE))
dose_coefs <- dose_coefs[grepl("flood_dose", term)]
fwrite(dose_coefs, file.path(data_dir, "dose_response_coefs.csv"))

## -------------------------------------------------------
## 5. Volume (Extensive Margin) — Transaction Counts
## -------------------------------------------------------

cat("\n=== SPECIFICATION 5: Transaction Volume ===\n")

# Aggregate to postcode-sector × year-quarter
vol_panel <- panel[, .(
  n_transactions = .N,
  mean_price = mean(price)
), by = .(postcode_sector, year_quarter_str, year, quarter,
          flood_risk_high, post_floodre, la_code)]

m5_vol <- feols(
  log(n_transactions + 1) ~ flood_risk_high:post_floodre |
    postcode_sector + year_quarter_str,
  data = vol_panel,
  cluster = ~la_code
)
cat("Volume (extensive margin):\n")
summary(m5_vol)

# Save volume data
fwrite(vol_panel, file.path(data_dir, "volume_panel.csv"))

## -------------------------------------------------------
## 6. Repeat Sales (within-property)
## -------------------------------------------------------

cat("\n=== SPECIFICATION 6: Repeat Sales ===\n")

# Identify properties with multiple transactions
prop_counts <- panel[, .N, by = property_id]
repeat_props <- prop_counts[N >= 2, property_id]
panel_repeat <- panel[property_id %in% repeat_props]
cat(sprintf("Repeat sales: %s transactions from %s properties\n",
            format(nrow(panel_repeat), big.mark = ","),
            format(length(repeat_props), big.mark = ",")))

if (nrow(panel_repeat) > 1000) {
  m6_repeat <- feols(
    ln_price ~ flood_risk_high:post_floodre +
      i(property_type) + i(duration) + new_build |
      property_id + year_quarter_str,
    data = panel_repeat,
    cluster = ~la_code
  )
  cat("Repeat sales (property FE):\n")
  summary(m6_repeat)
} else {
  cat("Insufficient repeat sales for property FE estimation\n")
}

## -------------------------------------------------------
## 7. Save all model results
## -------------------------------------------------------

results <- list(
  m1_base = m1_base,
  m1_layr = m1_layr,
  m2_es = m2_es,
  m3_ddd = m3_ddd,
  m4_dose = m4_dose,
  m5_vol = m5_vol
)
if (exists("m6_repeat")) results$m6_repeat <- m6_repeat

saveRDS(results, file.path(data_dir, "main_results.rds"))

# Export key coefficients as CSV for figures
main_coefs <- data.table(
  model = c("DiD (base)", "DiD (LA×year)", "Triple-Diff",
            "Volume"),
  coefficient = c(
    coef(m1_base)["flood_risk_high:post_floodre"],
    coef(m1_layr)["flood_risk_high:post_floodre"],
    coef(m3_ddd)["flood_risk_high:post_floodre:eligible"],
    coef(m5_vol)["flood_risk_high:post_floodre"]
  ),
  se = c(
    se(m1_base)["flood_risk_high:post_floodre"],
    se(m1_layr)["flood_risk_high:post_floodre"],
    se(m3_ddd)["flood_risk_high:post_floodre:eligible"],
    se(m5_vol)["flood_risk_high:post_floodre"]
  )
)
main_coefs[, pct_effect := 100 * (exp(coefficient) - 1)]
main_coefs[, ci_lo := coefficient - 1.96 * se]
main_coefs[, ci_hi := coefficient + 1.96 * se]

fwrite(main_coefs, file.path(data_dir, "main_coefficients.csv"))

# Export DDD full interaction coefficients for Table 2
int_terms <- grep("flood_risk_high|post_floodre|eligible", names(coef(m3_ddd)), value = TRUE)
ddd_coefs <- data.table(
  term = int_terms,
  estimate = unname(coef(m3_ddd)[int_terms]),
  se = unname(se(m3_ddd)[int_terms])
)
fwrite(ddd_coefs, file.path(data_dir, "ddd_full_coefficients.csv"))

cat("\n=== ALL MAIN RESULTS SAVED ===\n")
print(main_coefs)
