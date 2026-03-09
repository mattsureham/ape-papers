## ============================================================
## 03_main_analysis.R — Synthetic Control + Industry DiD
## apep_0554: Can Shorter Workweeks Save Fertility?
## ============================================================

source("00_packages.R")

panel <- fread(file.path(data_dir, "scm_panel.csv"))
kor_ind <- fread(file.path(data_dir, "korea_industry_panel.csv"))

## Treatment year
T0 <- 2018

## ============================================================
## 1. SYNTHETIC CONTROL — Average Weekly Hours (First Stage)
## ============================================================

cat("=== SCM: Average Weekly Hours (First Stage) ===\n")

## Prepare data for Synth package
hours_df <- panel[!is.na(mean_weekly_hours) & !is.na(tfr),
                  .(country_id, iso3, year, mean_weekly_hours, tfr,
                    gdp_pc, flfp, unemp)]

## Need balanced panel for Synth — keep countries with data 2005-2023
balanced_countries <- hours_df[, .(n = .N, min_yr = min(year), max_yr = max(year)),
                               by = iso3][n >= 17 & min_yr <= 2006 & max_yr >= 2022]
hours_bal <- hours_df[iso3 %in% balanced_countries$iso3]

## Re-create numeric IDs for balanced panel
hours_bal[, unit := as.integer(factor(iso3))]
kor_unit <- hours_bal[iso3 == "KOR", unique(unit)]
donor_units <- hours_bal[iso3 != "KOR", unique(unit)]

cat("Balanced panel:", uniqueN(hours_bal$iso3), "countries,",
    uniqueN(hours_bal$year), "years\n")
cat("Korea unit:", kor_unit, "\n")
cat("Donor units:", length(donor_units), "\n")

## Synth for hours
hours_for_synth <- as.data.frame(hours_bal[, .(unit, year, mean_weekly_hours,
                                                gdp_pc, flfp, unemp)])

tryCatch({
  dataprep_hours <- dataprep(
    foo = hours_for_synth,
    predictors = c("gdp_pc", "flfp", "unemp"),
    predictors.op = "mean",
    time.predictors.prior = 2005:(T0 - 1),
    dependent = "mean_weekly_hours",
    unit.variable = "unit",
    time.variable = "year",
    treatment.identifier = kor_unit,
    controls.identifier = donor_units,
    time.optimize.ssr = 2005:(T0 - 1),
    time.plot = 2005:2023
  )

  synth_hours <- synth(dataprep_hours, optimxmethod = "BFGS")

  ## Extract synthetic control values
  synth_hours_vals <- dataprep_hours$Y0plot %*% synth_hours$solution.w
  actual_hours_vals <- dataprep_hours$Y1plot

  hours_scm_results <- data.table(
    year = 2005:2023,
    actual = as.numeric(actual_hours_vals),
    synthetic = as.numeric(synth_hours_vals)
  )
  hours_scm_results[, gap := actual - synthetic]

  ## Donor weights
  hours_weights <- data.table(
    iso3 = hours_bal[unit %in% donor_units, unique(iso3)][order(hours_bal[unit %in% donor_units, unique(iso3)])],
    weight = as.numeric(synth_hours$solution.w)
  )
  hours_weights <- hours_weights[weight > 0.01][order(-weight)]

  cat("\nSCM Hours — Top donor weights:\n")
  print(hours_weights)

  cat("\nPre-treatment MSPE:", mean(hours_scm_results[year < T0, gap^2]), "\n")
  cat("Post-treatment gap (2018):", hours_scm_results[year == 2018, gap], "\n")
  cat("Post-treatment gap (2019):", hours_scm_results[year == 2019, gap], "\n")
  cat("Post-treatment gap (2023):", hours_scm_results[year == 2023, gap], "\n")

  fwrite(hours_scm_results, file.path(data_dir, "scm_hours_results.csv"))
  fwrite(hours_weights, file.path(data_dir, "scm_hours_weights.csv"))
}, error = function(e) {
  cat("SCM for hours failed:", e$message, "\n")
  cat("Proceeding with simple DiD instead.\n")

  ## Fallback: simple pre-post comparison
  hours_scm_results <- panel[iso3 == "KOR" & !is.na(mean_weekly_hours),
                             .(year, actual = mean_weekly_hours)]
  ## Mean of donors
  donor_mean <- panel[iso3 != "KOR" & !is.na(mean_weekly_hours),
                      .(synthetic = mean(mean_weekly_hours)),
                      by = year]
  hours_scm_results <- merge(hours_scm_results, donor_mean, by = "year")
  hours_scm_results[, gap := actual - synthetic]
  fwrite(hours_scm_results, file.path(data_dir, "scm_hours_results.csv"))
})

## ============================================================
## 2. SYNTHETIC CONTROL — Total Fertility Rate (Main Outcome)
## ============================================================

cat("\n=== SCM: Total Fertility Rate (Main Outcome) ===\n")

tfr_for_synth <- as.data.frame(hours_bal[, .(unit, year, tfr, gdp_pc, flfp, unemp)])

tryCatch({
  dataprep_tfr <- dataprep(
    foo = tfr_for_synth,
    predictors = c("gdp_pc", "flfp", "unemp"),
    predictors.op = "mean",
    time.predictors.prior = 2005:(T0 - 1),
    dependent = "tfr",
    unit.variable = "unit",
    time.variable = "year",
    treatment.identifier = kor_unit,
    controls.identifier = donor_units,
    time.optimize.ssr = 2005:(T0 - 1),
    time.plot = 2005:2023
  )

  synth_tfr <- synth(dataprep_tfr, optimxmethod = "BFGS")

  tfr_scm_results <- data.table(
    year = 2005:2023,
    actual = as.numeric(dataprep_tfr$Y1plot),
    synthetic = as.numeric(dataprep_tfr$Y0plot %*% synth_tfr$solution.w)
  )
  tfr_scm_results[, gap := actual - synthetic]

  tfr_weights <- data.table(
    iso3 = hours_bal[unit %in% donor_units, unique(iso3)][order(hours_bal[unit %in% donor_units, unique(iso3)])],
    weight = as.numeric(synth_tfr$solution.w)
  )
  tfr_weights <- tfr_weights[weight > 0.01][order(-weight)]

  cat("\nSCM TFR — Top donor weights:\n")
  print(tfr_weights)

  cat("\nPre-treatment MSPE:", mean(tfr_scm_results[year < T0, gap^2]), "\n")
  cat("Post-treatment gap (2018):", tfr_scm_results[year == 2018, gap], "\n")
  cat("Post-treatment gap (2019):", tfr_scm_results[year == 2019, gap], "\n")
  cat("Post-treatment gap (2023):", tfr_scm_results[year == 2023, gap], "\n")

  fwrite(tfr_scm_results, file.path(data_dir, "scm_tfr_results.csv"))
  fwrite(tfr_weights, file.path(data_dir, "scm_tfr_weights.csv"))
}, error = function(e) {
  cat("SCM for TFR failed:", e$message, "\n")

  ## Fallback: simple comparison
  tfr_scm_results <- panel[iso3 == "KOR" & !is.na(tfr),
                           .(year, actual = tfr)]
  donor_mean <- panel[iso3 != "KOR" & !is.na(tfr),
                      .(synthetic = mean(tfr, na.rm = TRUE)),
                      by = year]
  tfr_scm_results <- merge(tfr_scm_results, donor_mean, by = "year")
  tfr_scm_results[, gap := actual - synthetic]
  fwrite(tfr_scm_results, file.path(data_dir, "scm_tfr_results.csv"))
})

## ============================================================
## 3. SYNTHETIC CONTROL — Crude Birth Rate
## ============================================================

cat("\n=== SCM: Crude Birth Rate ===\n")

## Reload panel for CBR (may need to re-merge)
panel_full <- fread(file.path(data_dir, "scm_panel.csv"))
if (!"cbr" %in% names(panel_full) || all(is.na(panel_full$cbr))) {
  wb_raw <- fread(file.path(data_dir, "wb_oecd_panel.csv"))
  if ("cbr" %in% names(wb_raw)) {
    panel_full <- merge(panel_full[, setdiff(names(panel_full), "cbr"), with = FALSE],
                        wb_raw[, .(iso3 = iso2, year, cbr)],
                        by = c("iso3", "year"), all.x = TRUE)
  }
}
hours_bal_cbr <- panel_full[iso3 %in% unique(hours_bal$iso3) & !is.na(cbr)]
hours_bal_cbr[, unit := as.integer(factor(iso3))]
cbr_for_synth <- as.data.frame(hours_bal_cbr[, .(unit, year, cbr, gdp_pc, flfp, unemp)])

tryCatch({
  dataprep_cbr <- dataprep(
    foo = cbr_for_synth,
    predictors = c("gdp_pc", "flfp", "unemp"),
    predictors.op = "mean",
    time.predictors.prior = 2005:(T0 - 1),
    dependent = "cbr",
    unit.variable = "unit",
    time.variable = "year",
    treatment.identifier = hours_bal_cbr[iso3 == "KOR", unique(unit)],
    controls.identifier = hours_bal_cbr[iso3 != "KOR", unique(unit)],
    time.optimize.ssr = 2005:(T0 - 1),
    time.plot = 2005:2023
  )

  synth_cbr <- synth(dataprep_cbr, optimxmethod = "BFGS")

  cbr_scm_results <- data.table(
    year = 2005:2023,
    actual = as.numeric(dataprep_cbr$Y1plot),
    synthetic = as.numeric(dataprep_cbr$Y0plot %*% synth_cbr$solution.w)
  )
  cbr_scm_results[, gap := actual - synthetic]

  fwrite(cbr_scm_results, file.path(data_dir, "scm_cbr_results.csv"))
  cat("Post-treatment gap (2019):", cbr_scm_results[year == 2019, gap], "\n")
}, error = function(e) {
  cat("SCM for CBR failed:", e$message, "\n")
  cbr_scm_results <- panel[iso3 == "KOR" & !is.na(cbr), .(year, actual = cbr)]
  donor_mean <- panel[iso3 != "KOR" & !is.na(cbr),
                      .(synthetic = mean(cbr, na.rm = TRUE)), by = year]
  cbr_scm_results <- merge(cbr_scm_results, donor_mean, by = "year")
  cbr_scm_results[, gap := actual - synthetic]
  fwrite(cbr_scm_results, file.path(data_dir, "scm_cbr_results.csv"))
})

## ============================================================
## 4. INDUSTRY-LEVEL DiD (Within-Korea First Stage)
## ============================================================

cat("\n=== Industry-Level DiD: Hours Reduction by Sector ===\n")

## Main specification: industry FE + year FE
## Treatment intensity = baseline hours above 40
## Industries with higher baseline hours should see larger reductions

ind_did <- feols(hours ~ treatment_intensity:post | industry + year,
                 data = kor_ind[!is.na(hours) & !is.na(treatment_intensity)],
                 cluster = ~industry)
cat("\nIndustry DiD (continuous treatment):\n")
print(summary(ind_did))

## Alternative: binary treatment (above/below median baseline hours)
median_intensity <- kor_ind[, median(unique(baseline_hours), na.rm = TRUE)]
kor_ind[, high_overtime := as.integer(baseline_hours > median_intensity)]

ind_did_binary <- feols(hours ~ high_overtime:post | industry + year,
                        data = kor_ind[!is.na(hours)],
                        cluster = ~industry)
cat("\nIndustry DiD (binary, above-median baseline hours):\n")
print(summary(ind_did_binary))

## Event study specification
kor_ind[, event_time := year - T0]
kor_ind[, event_time_f := factor(event_time)]
kor_ind[, event_time_f := relevel(event_time_f, ref = "-1")]

ind_es <- feols(hours ~ i(event_time_f, treatment_intensity, ref = "-1") | industry + year,
                data = kor_ind[!is.na(hours) & !is.na(treatment_intensity) &
                               abs(event_time) <= 5],
                cluster = ~industry)
cat("\nIndustry event study:\n")
print(summary(ind_es))

## ============================================================
## 5. CROSS-COUNTRY DiD (Panel Regression)
## ============================================================

cat("\n=== Cross-Country Panel DiD ===\n")

## Simple DiD: Korea × Post
did_hours <- feols(mean_weekly_hours ~ treated:post | iso3 + year,
                   data = panel[!is.na(mean_weekly_hours) & year >= 2005],
                   cluster = ~iso3)
cat("\nCross-country DiD — Hours:\n")
print(summary(did_hours))

did_tfr <- feols(tfr ~ treated:post | iso3 + year,
                 data = panel[!is.na(tfr) & year >= 2005],
                 cluster = ~iso3)
cat("\nCross-country DiD — TFR:\n")
print(summary(did_tfr))

## Event study
panel[, event_time := ifelse(iso3 == "KOR", year - T0, NA_integer_)]
panel[iso3 != "KOR", event_time := 0]  # controls don't have event time
panel[, rel_year := year - T0]

## Korea event study (relative to OECD mean)
kor_vs_oecd <- panel[year >= 2005 & !is.na(tfr) & !is.na(mean_weekly_hours),
                     .(kor_tfr = tfr[iso3 == "KOR"],
                       oecd_tfr = mean(tfr[iso3 != "KOR"], na.rm = TRUE),
                       kor_hours = mean_weekly_hours[iso3 == "KOR"],
                       oecd_hours = mean(mean_weekly_hours[iso3 != "KOR"], na.rm = TRUE)),
                     by = year]
kor_vs_oecd[, tfr_gap := kor_tfr - oecd_tfr]
kor_vs_oecd[, hours_gap := kor_hours - oecd_hours]

cat("\nKorea vs OECD mean (selected years):\n")
print(kor_vs_oecd[year %in% c(2010, 2015, 2017, 2018, 2019, 2020, 2023)])

fwrite(kor_vs_oecd, file.path(data_dir, "korea_vs_oecd.csv"))

## ============================================================
## 6. Save regression results
## ============================================================

## Summary statistics
sumstats <- panel[year >= 2005 & !is.na(tfr),
                  .(mean_tfr = mean(tfr, na.rm = TRUE),
                    sd_tfr = sd(tfr, na.rm = TRUE),
                    mean_hours = mean(mean_weekly_hours, na.rm = TRUE),
                    sd_hours = sd(mean_weekly_hours, na.rm = TRUE),
                    mean_gdp = mean(gdp_pc, na.rm = TRUE),
                    mean_flfp = mean(flfp, na.rm = TRUE),
                    N = .N),
                  by = .(Group = ifelse(iso3 == "KOR", "Korea", "OECD Donors"))]
cat("\nSummary statistics:\n")
print(sumstats)
fwrite(sumstats, file.path(data_dir, "summary_stats.csv"))

## Industry DiD coefficients for tables
ind_coefs <- data.table(
  model = c("Continuous treatment", "Binary treatment"),
  coefficient = c(coef(ind_did)["treatment_intensity:post"],
                  coef(ind_did_binary)["high_overtime:post"]),
  se = c(se(ind_did)["treatment_intensity:post"],
         se(ind_did_binary)["high_overtime:post"]),
  pvalue = c(pvalue(ind_did)["treatment_intensity:post"],
             pvalue(ind_did_binary)["high_overtime:post"])
)
fwrite(ind_coefs, file.path(data_dir, "industry_did_coefs.csv"))

## Cross-country DiD coefficients
cc_coefs <- data.table(
  outcome = c("Weekly hours", "TFR"),
  coefficient = c(coef(did_hours)["treated:post"], coef(did_tfr)["treated:post"]),
  se = c(se(did_hours)["treated:post"], se(did_tfr)["treated:post"]),
  pvalue = c(pvalue(did_hours)["treated:post"], pvalue(did_tfr)["treated:post"])
)
fwrite(cc_coefs, file.path(data_dir, "crosscountry_did_coefs.csv"))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
