# 03_main_analysis.R — Main DiD analysis for 5AMLD
# apep_0895: Does AML Regulation Actually Detect Money Laundering?

source("00_packages.R")

panel <- fread("data/analysis_panel.csv")

# ===========================================================================
# 1. Treatment rollout visualization (save for paper)
# ===========================================================================
message("=== Treatment Rollout ===")
rollout <- panel[year == min(year) & treat_year > 0, .(geo, treat_year)]
rollout <- rollout[order(treat_year, geo)]
print(rollout)

# Cohort sizes
message("\nCohort sizes:")
print(panel[year == min(year), .N, by = treat_year][order(treat_year)])

# ===========================================================================
# 2. Callaway-Sant'Anna: Main specification
# ===========================================================================
message("\n=== Callaway-Sant'Anna: Log ML Offences ===")

# Ensure the data has no missing outcomes for CS estimator
cs_data <- panel[!is.na(log_ml)]
message("CS data: ", nrow(cs_data), " obs, ", uniqueN(cs_data$geo), " countries")
message("Treatment years: ", paste(sort(unique(cs_data[treat_year > 0, treat_year])), collapse = ", "))

# Main specification: log(ML offences + 1)
cs_main <- att_gt(
  yname = "log_ml",
  tname = "year",
  idname = "country_id",
  gname = "treat_year",
  data = as.data.frame(cs_data),
  control_group = "notyettreated",
  base_period = "universal",
  est_method = "reg"
)

message("\nGroup-time ATTs:")
summary(cs_main)

# Aggregate: overall ATT
agg_main <- aggte(cs_main, type = "simple")
message("\nOverall ATT (simple):")
summary(agg_main)

# Event study aggregation
es_main <- aggte(cs_main, type = "dynamic")
message("\nEvent study ATTs:")
summary(es_main)

# ===========================================================================
# 3. Alternative specification: ML rate per 100k
# ===========================================================================
message("\n=== CS: ML Rate per 100k ===")

cs_data_rate <- panel[!is.na(ml_rate)]
if (nrow(cs_data_rate) > 0 && uniqueN(cs_data_rate$geo) >= 10) {
  cs_rate <- att_gt(
    yname = "ml_rate",
    tname = "year",
    idname = "country_id",
    gname = "treat_year",
    data = as.data.frame(cs_data_rate),
    control_group = "notyettreated",
    base_period = "universal",
    est_method = "reg"
  )
  agg_rate <- aggte(cs_rate, type = "simple")
  es_rate <- aggte(cs_rate, type = "dynamic")
  message("Overall ATT (rate):")
  summary(agg_rate)
} else {
  message("Insufficient rate data — skipping rate specification")
  cs_rate <- NULL
  agg_rate <- NULL
  es_rate <- NULL
}

# ===========================================================================
# 4. TWFE comparison (for discussion of bias)
# ===========================================================================
message("\n=== TWFE Comparison ===")

twfe_log <- feols(log_ml ~ treated | geo + year, data = panel, cluster = ~geo)
message("TWFE (log ML):")
print(summary(twfe_log))

twfe_rate <- feols(ml_rate ~ treated | geo + year, data = panel[!is.na(ml_rate)],
                   cluster = ~geo)
message("TWFE (ML rate):")
print(summary(twfe_rate))

# ===========================================================================
# 5. Secondary outcomes
# ===========================================================================
message("\n=== Secondary Outcomes ===")

# House price index
cs_hpi_data <- panel[!is.na(hpi)]
if (nrow(cs_hpi_data) > 0 && uniqueN(cs_hpi_data$geo) >= 10) {
  cs_hpi <- att_gt(
    yname = "hpi",
    tname = "year",
    idname = "country_id",
    gname = "treat_year",
    data = as.data.frame(cs_hpi_data),
    control_group = "notyettreated",
    base_period = "universal",
    est_method = "reg"
  )
  agg_hpi <- aggte(cs_hpi, type = "simple")
  message("HPI ATT:")
  summary(agg_hpi)
} else {
  agg_hpi <- NULL
  message("Insufficient HPI data")
}

# Financial sector employment
cs_femp_data <- panel[!is.na(log_fin_emp)]
if (nrow(cs_femp_data) > 0 && uniqueN(cs_femp_data$geo) >= 10) {
  cs_femp <- att_gt(
    yname = "log_fin_emp",
    tname = "year",
    idname = "country_id",
    gname = "treat_year",
    data = as.data.frame(cs_femp_data),
    control_group = "notyettreated",
    base_period = "universal",
    est_method = "reg"
  )
  agg_femp <- aggte(cs_femp, type = "simple")
  message("Financial employment ATT:")
  summary(agg_femp)
} else {
  agg_femp <- NULL
  message("Insufficient financial employment data")
}

# ===========================================================================
# 6. Save results
# ===========================================================================
results <- list(
  cs_main = cs_main,
  agg_main = agg_main,
  es_main = es_main,
  cs_rate = cs_rate,
  agg_rate = agg_rate,
  es_rate = es_rate,
  twfe_log = twfe_log,
  twfe_rate = twfe_rate,
  agg_hpi = agg_hpi,
  agg_femp = agg_femp
)

saveRDS(results, "data/main_results.rds")

# ===========================================================================
# 7. Diagnostics for validator
# ===========================================================================
diag <- list(
  n_treated = uniqueN(panel[treat_year > 0, geo]),
  n_pre = length(unique(panel[year < min(panel[treat_year > 0 & treat_year > 0, treat_year]), year])),
  n_obs = nrow(panel[!is.na(log_ml)])
)

jsonlite::write_json(diag, "data/diagnostics.json", auto_unbox = TRUE)
message("\nDiagnostics: ", toJSON(diag, auto_unbox = TRUE))

message("\n=== Main analysis complete ===")
