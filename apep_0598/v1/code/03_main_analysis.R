# 03_main_analysis.R — SCM + Cross-Sector DiD
# APEP-0598: Greece Capital Controls & Shadow Economy Formalization

source("00_packages.R")

data_dir <- "../data/"

# ============================================================
# LOAD CLEANED DATA
# ============================================================

scm_panel <- fread(file.path(data_dir, "scm_panel.csv"))
sector_panel <- fread(file.path(data_dir, "sector_panel.csv"))
country_map <- fread(file.path(data_dir, "country_map.csv"))
vat_panel <- fread(file.path(data_dir, "vat_panel.csv"))
pre_treat <- fread(file.path(data_dir, "pre_treatment_covariates.csv"))

greece_id <- country_map$country_id[country_map$country == "EL"]

# Treatment time index: July 2015
treatment_time <- (2015 - 2010) * 12 + 7  # = 67

cat("Greece ID:", greece_id, "\n")
cat("Treatment time index:", treatment_time, "\n")

# ============================================================
# 1. SYNTHETIC CONTROL METHOD — AGGREGATE RETAIL (G47)
# ============================================================

cat("\n=== SYNTHETIC CONTROL METHOD ===\n")

# Balance the panel: keep only time periods present for ALL countries
time_coverage <- scm_panel %>%
  filter(!is.na(value)) %>%
  group_by(time_index) %>%
  summarise(n_countries = n_distinct(country_id), .groups = "drop") %>%
  filter(n_countries == n_distinct(scm_panel$country_id))

balanced_times <- time_coverage$time_index

scm_data <- scm_panel %>%
  filter(time_index %in% balanced_times, !is.na(value)) %>%
  select(country_id, time_index, value) %>%
  as.data.frame()

cat("Balanced panel:", n_distinct(scm_data$country_id), "countries,",
    n_distinct(scm_data$time_index), "periods\n")

# Get pre-treatment time indices
pre_times <- sort(unique(scm_data$time_index[scm_data$time_index < treatment_time]))
post_times <- sort(unique(scm_data$time_index[scm_data$time_index >= treatment_time]))

# All donor country IDs
donor_ids <- country_map$country_id[country_map$country != "EL"]

# Pre-treatment turnover at specific points for predictors
# Use annual averages: 2010, 2011, 2012, 2013, 2014
predictor_times <- list()
for (yr in 2010:2014) {
  yr_times <- ((yr - 2010) * 12 + 1):((yr - 2010) * 12 + 12)
  yr_times <- yr_times[yr_times %in% pre_times]
  predictor_times[[paste0("turnover_", yr)]] <- yr_times
}

# Build dataprep object
cat("Building SCM dataprep...\n")
dataprep_out <- tryCatch({
  dataprep(
    foo = scm_data,
    predictors = NULL,
    predictors.op = "mean",
    dependent = "value",
    unit.variable = "country_id",
    time.variable = "time_index",
    treatment.identifier = greece_id,
    controls.identifier = donor_ids,
    time.predictors.prior = pre_times,
    time.optimize.ssr = pre_times,
    time.plot = sort(unique(scm_data$time_index)),
    special.predictors = list(
      list("value", predictor_times[["turnover_2010"]], "mean"),
      list("value", predictor_times[["turnover_2011"]], "mean"),
      list("value", predictor_times[["turnover_2012"]], "mean"),
      list("value", predictor_times[["turnover_2013"]], "mean"),
      list("value", predictor_times[["turnover_2014"]], "mean")
    )
  )
}, error = function(e) {
  cat("Synth dataprep error:", e$message, "\n")
  NULL
})

if (!is.null(dataprep_out)) {
  cat("Running SCM optimization...\n")
  synth_out <- synth(dataprep_out, optimxmethod = "BFGS")

  # Extract results
  synth_tables <- synth.tab(dataprep.res = dataprep_out, synth.res = synth_out)

  # Weights
  cat("\nDonor weights:\n")
  weights_df <- data.frame(
    country_id = as.integer(rownames(synth_tables$tab.w)),
    weight = round(synth_tables$tab.w[, 1], 4)
  ) %>%
    left_join(country_map, by = "country_id") %>%
    filter(weight > 0.001) %>%
    arrange(desc(weight))
  print(weights_df)

  # Gaps (treatment - synthetic)
  gaps <- dataprep_out$Y1plot - (dataprep_out$Y0plot %*% synth_out$solution.w)
  gaps_df <- data.frame(
    time_index = as.integer(rownames(gaps)),
    gap = as.numeric(gaps)
  ) %>%
    mutate(
      year = 2010 + (time_index - 1) %/% 12,
      month = ((time_index - 1) %% 12) + 1,
      date = as.Date(paste(year, month, "01", sep = "-")),
      post = as.integer(time_index >= treatment_time)
    )

  # Pre-treatment RMSPE
  pre_rmspe <- sqrt(mean(gaps_df$gap[gaps_df$post == 0]^2))
  post_rmspe <- sqrt(mean(gaps_df$gap[gaps_df$post == 1]^2))
  rmspe_ratio <- post_rmspe / pre_rmspe

  cat("\nPre-treatment RMSPE:", round(pre_rmspe, 3), "\n")
  cat("Post-treatment RMSPE:", round(post_rmspe, 3), "\n")
  cat("RMSPE ratio:", round(rmspe_ratio, 3), "\n")

  # Average post-treatment gap
  avg_gap_6m <- mean(gaps_df$gap[gaps_df$time_index >= treatment_time &
                                   gaps_df$time_index < treatment_time + 6])
  avg_gap_12m <- mean(gaps_df$gap[gaps_df$time_index >= treatment_time &
                                    gaps_df$time_index < treatment_time + 12])
  avg_gap_all <- mean(gaps_df$gap[gaps_df$post == 1])

  cat("\nAvg gap (first 6 months):", round(avg_gap_6m, 2), "index points\n")
  cat("Avg gap (first 12 months):", round(avg_gap_12m, 2), "index points\n")
  cat("Avg gap (all post-treatment):", round(avg_gap_all, 2), "index points\n")

  # Actual and synthetic series
  actual_synthetic <- data.frame(
    time_index = as.integer(rownames(dataprep_out$Y1plot)),
    actual = as.numeric(dataprep_out$Y1plot),
    synthetic = as.numeric(dataprep_out$Y0plot %*% synth_out$solution.w)
  ) %>%
    mutate(
      year = 2010 + (time_index - 1) %/% 12,
      month = ((time_index - 1) %% 12) + 1,
      date = as.Date(paste(year, month, "01", sep = "-")),
      gap = actual - synthetic
    )

  fwrite(actual_synthetic, file.path(data_dir, "scm_actual_synthetic.csv"))
  fwrite(gaps_df, file.path(data_dir, "scm_gaps.csv"))
  fwrite(weights_df, file.path(data_dir, "scm_weights.csv"))

  # Save RMSPE results
  rmspe_results <- data.frame(
    metric = c("pre_rmspe", "post_rmspe", "rmspe_ratio",
               "avg_gap_6m", "avg_gap_12m", "avg_gap_all"),
    value = c(pre_rmspe, post_rmspe, rmspe_ratio,
              avg_gap_6m, avg_gap_12m, avg_gap_all)
  )
  fwrite(rmspe_results, file.path(data_dir, "scm_rmspe.csv"))
}

# ============================================================
# 2. AUGMENTED SCM (Ben-Michael et al. 2021)
# ============================================================

cat("\n=== AUGMENTED SCM ===\n")

# Prepare wide-format panel for augsynth
ascm_data <- scm_panel %>%
  select(country, time_index, value, treated, post) %>%
  filter(!is.na(value)) %>%
  mutate(
    treatment = as.integer(country == "EL" & time_index >= treatment_time)
  )

ascm_fit <- tryCatch({
  augsynth(
    value ~ treatment,
    unit = country,
    time = time_index,
    data = ascm_data,
    progfunc = "ridge",
    scm = TRUE
  )
}, error = function(e) {
  cat("augsynth error:", e$message, "\n")
  NULL
})

if (!is.null(ascm_fit)) {
  ascm_summary <- tryCatch(summary(ascm_fit), error = function(e) {
    cat("augsynth summary error:", e$message, "\n")
    NULL
  })

  if (!is.null(ascm_summary)) {
    cat("\nAugmented SCM ATT:", round(ascm_summary$att$Estimate, 3), "\n")
    cat("Augmented SCM SE:", round(ascm_summary$att$Std.Error, 3), "\n")
    cat("Augmented SCM p-value:", round(ascm_summary$att$p_val, 4), "\n")

    ascm_att <- data.frame(
      estimate = ascm_summary$att$Estimate,
      se = ascm_summary$att$Std.Error,
      p_value = ascm_summary$att$p_val
    )
    fwrite(ascm_att, file.path(data_dir, "ascm_att.csv"))
  } else {
    # Summary failed but fit exists — extract weights manually
    cat("  Summary failed, extracting weights from fit object\n")
    ascm_att <- data.frame(
      estimate = NA_real_, se = NA_real_, p_value = NA_real_
    )
    fwrite(ascm_att, file.path(data_dir, "ascm_att.csv"))
  }

  save(ascm_fit, file = file.path(data_dir, "ascm_objects.RData"))
}

# ============================================================
# 3. CROSS-SECTOR INTENSITY DiD
# ============================================================

cat("\n=== CROSS-SECTOR INTENSITY DiD ===\n")

# Main specification: Y_st = α_s + γ_t + β(CashIntensity_s × Post_t) + ε_st
did_main <- feols(
  value ~ cash_share:post | nace + time_index,
  data = sector_panel,
  cluster = ~nace
)

cat("\nMain DiD result:\n")
print(summary(did_main))

# Event study: interact cash_share with each time period
# Relative to June 2015 (time_index = 66)
baseline_time <- (2015 - 2010) * 12 + 6  # June 2015

sector_panel <- sector_panel %>%
  mutate(
    rel_time = time_index - baseline_time
  )

# Event study with quarterly bins for power
sector_panel <- sector_panel %>%
  mutate(
    quarter_rel = case_when(
      rel_time < -24 ~ floor(rel_time / 6) * 6,  # Semi-annual bins far from treatment
      rel_time >= -24 & rel_time < -6 ~ floor(rel_time / 3) * 3,  # Quarterly near treatment
      rel_time >= -6 & rel_time <= 12 ~ rel_time,  # Monthly around treatment
      rel_time > 12 ~ ceiling(rel_time / 3) * 3  # Quarterly after
    )
  )

# Simple event study: monthly interactions near treatment
es_data <- sector_panel %>%
  filter(rel_time >= -12, rel_time <= 18)

did_es <- feols(
  value ~ i(rel_time, cash_share, ref = -1) | nace + time_index,
  data = es_data,
  cluster = ~nace
)

cat("\nEvent study around treatment:\n")
es_coefs <- as.data.frame(coeftable(did_es))
es_coefs$rel_time <- as.integer(gsub("rel_time::", "", gsub(":cash_share", "", rownames(es_coefs))))
fwrite(es_coefs, file.path(data_dir, "did_event_study.csv"))

# ============================================================
# 4. MECHANISM: VAT REVENUE
# ============================================================

cat("\n=== VAT MECHANISM TEST ===\n")

# DiD on VAT revenue: Greece vs synthetic/donors
vat_did <- feols(
  vat_index ~ treated:post | country + year,
  data = vat_panel,
  cluster = ~country
)

cat("\nVAT DiD result:\n")
print(summary(vat_did))

# Save VAT results
vat_coefs <- as.data.frame(coeftable(vat_did))
fwrite(vat_coefs, file.path(data_dir, "vat_did_results.csv"))

# ============================================================
# 4b. MECHANISM: VAT-TO-GDP RATIO
# ============================================================

cat("\n=== VAT-TO-GDP RATIO TEST ===\n")

# Load total GDP data (millions EUR, current prices)
gdp_data <- fread(file.path(data_dir, "gdp_total.csv"))

# Merge VAT panel with GDP data
vat_gdp <- merge(vat_panel, gdp_data, by = c("country", "year"), all.x = TRUE)

# Compute VAT-to-GDP ratio: VAT revenue as a share of GDP (both in millions EUR)
# Expressed as a percentage of GDP
vat_gdp <- vat_gdp %>%
  mutate(vat_gdp_ratio = (vat_revenue / gdp_total) * 100)

# Normalize to 2014 = 100 within each country
vat_gdp <- vat_gdp %>%
  group_by(country) %>%
  mutate(
    ratio_2014 = vat_gdp_ratio[year == 2014],
    vat_gdp_index = (vat_gdp_ratio / ratio_2014) * 100
  ) %>%
  ungroup()

cat("VAT-to-GDP ratio panel:\n")
cat("  Countries:", n_distinct(vat_gdp$country), "\n")
cat("  Years:", paste(range(vat_gdp$year), collapse = "-"), "\n")
cat("  Greece 2014 ratio:", round(vat_gdp$vat_gdp_ratio[vat_gdp$country == "EL" & vat_gdp$year == 2014], 3), "\n")
cat("  Greece 2022 ratio:", round(vat_gdp$vat_gdp_ratio[vat_gdp$country == "EL" & vat_gdp$year == 2022], 3), "\n")

# DiD on VAT-to-GDP index: Greece vs donors
vat_gdp_did <- feols(
  vat_gdp_index ~ treated:post | country + year,
  data = vat_gdp,
  cluster = ~country
)

cat("\nVAT-to-GDP Ratio DiD result:\n")
print(summary(vat_gdp_did))

# Save VAT-to-GDP results
vat_gdp_coefs <- as.data.frame(coeftable(vat_gdp_did))
fwrite(vat_gdp_coefs, file.path(data_dir, "vat_gdp_did_results.csv"))

# Save the merged panel for potential use in figures/tables
fwrite(vat_gdp, file.path(data_dir, "vat_gdp_panel.csv"))

# ============================================================
# 5. SUMMARY OF MAIN RESULTS
# ============================================================

cat("\n\n========================================\n")
cat("SUMMARY OF MAIN RESULTS\n")
cat("========================================\n\n")

if (!is.null(dataprep_out)) {
  cat("1. SCM (Abadie et al. 2010):\n")
  cat("   Avg gap (6m):", round(avg_gap_6m, 2), "index points\n")
  cat("   Avg gap (12m):", round(avg_gap_12m, 2), "index points\n")
  cat("   RMSPE ratio:", round(rmspe_ratio, 2), "\n\n")
}

ascm_att_loaded <- tryCatch(fread(file.path(data_dir, "ascm_att.csv")), error = function(e) NULL)
if (!is.null(ascm_att_loaded) && !is.na(ascm_att_loaded$estimate[1])) {
  cat("2. Augmented SCM (Ben-Michael et al. 2021):\n")
  cat("   ATT:", round(ascm_att_loaded$estimate[1], 3), "\n")
  cat("   p-value:", round(ascm_att_loaded$p_value[1], 4), "\n\n")
} else {
  cat("2. Augmented SCM: summary failed (fit available)\n\n")
}

cat("3. Cross-Sector DiD (cash intensity × post):\n")
cat("   Coefficient:", round(coef(did_main)[1], 3), "\n")
cat("   SE:", round(se(did_main)[1], 3), "\n\n")

cat("4. VAT Mechanism (treated × post):\n")
cat("   Coefficient:", round(coef(vat_did)[1], 3), "\n")
cat("   SE:", round(se(vat_did)[1], 3), "\n\n")

cat("5. VAT-to-GDP Ratio (treated × post):\n")
cat("   Coefficient:", round(coef(vat_gdp_did)[1], 3), "\n")
cat("   SE:", round(se(vat_gdp_did)[1], 3), "\n")

# Save all model objects for later use
save(did_main, did_es, vat_did, vat_gdp_did,
     file = file.path(data_dir, "main_models.RData"))

if (!is.null(dataprep_out)) {
  save(dataprep_out, synth_out, synth_tables,
       file = file.path(data_dir, "scm_objects.RData"))
}

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
