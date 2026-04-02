## 03_main_analysis.R — V2 Main Analysis
## Structure: NY-only primary → Pooled secondary → Mechanism decomposition

source("00_packages.R")

panel_did <- readRDS("../data/panel_did.rds")

cat("=== V2 Main Analysis: Endogenous Regulatory Metrics ===\n")
cat(sprintf("Panel: %d obs, %d facilities, %d states\n",
            nrow(panel_did), uniqueN(panel_did$ccn), uniqueN(panel_did$state)))

# ================================================================
# 1. FIRST STAGE: Mandates → Staffing (Cross-sectional + Panel)
# ================================================================
cat("\n=== 1. First Stage: Mandates → Staffing ===\n")

# 1a. Cross-sectional (as in V1)
fac_level <- panel_did[, .(
  state = state[1], hprd_total = hprd_total[1], hprd_rn = hprd_rn[1],
  hprd_cna = hprd_cna[1], beds = beds[1], urban = urban[1],
  own_cat = fcase(
    grepl("For profit", ownership[1], ignore.case = TRUE), "for_profit",
    grepl("Non profit", ownership[1], ignore.case = TRUE), "nonprofit",
    default = "other"
  ),
  in_chain = in_chain[1], mandate_year = mandate_year[1]
), by = ccn]
fac_level[, has_mandate := as.integer(!is.na(mandate_year))]

# Region map
region_map <- data.table(
  state = c("CT","ME","MA","NH","RI","VT","NJ","NY","PA",
            "IL","IN","MI","OH","WI","IA","KS","MN","MO","NE","ND","SD",
            "DE","FL","GA","MD","NC","SC","VA","DC","WV","AL","KY","MS","TN","AR","LA","OK","TX",
            "AZ","CO","ID","MT","NV","NM","UT","WY","AK","CA","HI","OR","WA"),
  region = c(rep("NE",9), rep("MW",12), rep("SO",17), rep("WE",13))
)
fac_level <- merge(fac_level, region_map, by = "state", all.x = TRUE)

fs_xs <- feols(hprd_total ~ has_mandate + beds + urban + i(own_cat) + in_chain | region,
               data = fac_level, vcov = ~state)
cat("Cross-sectional first stage:\n")
print(summary(fs_xs))

# 1b. Panel first stage (V2 new): within-facility variation over time
# Use deficiency panel: mandate adoption should correlate with staffing changes
# Since we have cross-sectional staffing, we use the treated*post interaction
# as evidence that mandated states have higher staffing in post vs pre period
# This is indirect but uses within-state variation
panel_did_state <- panel_did[, .(
  mean_def = mean(n_deficiencies),
  mean_hprd = mean(hprd_total, na.rm = TRUE),
  n_fac = uniqueN(ccn)
), by = .(state, survey_year, cohort, treated)]

# State-year panel: mandate → average deficiencies (reduced form)
cat("\nState-year reduced form (states with mandate vs without):\n")
rf_state <- feols(mean_def ~ treated | state + survey_year,
                  data = panel_did_state[n_fac >= 10], vcov = ~state)
print(summary(rf_state))

# Store first stage results
fs_coef <- coef(fs_xs)["has_mandate"]
fs_se <- sqrt(vcov(fs_xs)["has_mandate", "has_mandate"])
fs_sd_y <- sd(fac_level$hprd_total, na.rm = TRUE)

# ================================================================
# 2. PRIMARY SPECIFICATION: NY-Only (Cleanest Cohort)
# ================================================================
cat("\n=== 2. Primary: NY-Only Specification ===\n")

# NY Safe Staffing Act (Jan 2022): 3.5 HPRD total, 2.2 CNA floor
# Clean because: single sharp adoption date, long pre-period (2017-2021),
# no contemporaneous mandate changes in never-treated states
ny_panel <- panel_did[state == "NY" | cohort == 0]
ny_panel[, ny_post := as.integer(state == "NY" & survey_year >= 2022)]
ny_panel[, rel_year := fifelse(state == "NY", survey_year - 2022L, NA_integer_)]

cat(sprintf("NY panel: %d obs, %d NY facilities, %d control facilities\n",
            nrow(ny_panel), uniqueN(ny_panel$ccn[ny_panel$state == "NY"]),
            uniqueN(ny_panel$ccn[ny_panel$state != "NY"])))

# NY TWFE
ny_twfe <- feols(n_deficiencies ~ ny_post | ccn + survey_year,
                 data = ny_panel, vcov = ~state)
cat("\nNY primary specification (total deficiencies):\n")
print(summary(ny_twfe))

# NY by detection mode (V2 core result)
ny_obs <- feols(n_observation ~ ny_post | ccn + survey_year,
                data = ny_panel, vcov = ~state)
ny_doc <- feols(n_documentation ~ ny_post | ccn + survey_year,
                data = ny_panel, vcov = ~state)
ny_rpt <- feols(n_report ~ ny_post | ccn + survey_year,
                data = ny_panel, vcov = ~state)
ny_infect <- feols(n_infection ~ ny_post | ccn + survey_year,
                   data = ny_panel, vcov = ~state)

cat("\nNY by detection mode:\n")
cat(sprintf("  Observation: %.3f (%.3f)\n", coef(ny_obs)["ny_post"],
            sqrt(vcov(ny_obs)["ny_post", "ny_post"])))
cat(sprintf("  Documentation: %.3f (%.3f)\n", coef(ny_doc)["ny_post"],
            sqrt(vcov(ny_doc)["ny_post", "ny_post"])))
cat(sprintf("  Report: %.3f (%.3f)\n", coef(ny_rpt)["ny_post"],
            sqrt(vcov(ny_rpt)["ny_post", "ny_post"])))
cat(sprintf("  Infection: %.3f (%.3f)\n", coef(ny_infect)["ny_post"],
            sqrt(vcov(ny_infect)["ny_post", "ny_post"])))

# NY by severity
ny_low <- feols(n_low_severity ~ ny_post | ccn + survey_year,
                data = ny_panel, vcov = ~state)
ny_high <- feols(n_high_severity ~ ny_post | ccn + survey_year,
                 data = ny_panel, vcov = ~state)

cat("\nNY by severity:\n")
cat(sprintf("  Low severity (A-F): %.3f (%.3f)\n", coef(ny_low)["ny_post"],
            sqrt(vcov(ny_low)["ny_post", "ny_post"])))
cat(sprintf("  High severity (G-L): %.3f (%.3f)\n", coef(ny_high)["ny_post"],
            sqrt(vcov(ny_high)["ny_post", "ny_post"])))

# NY event study
ny_es_data <- ny_panel[state == "NY" | cohort == 0]
ny_es_data[, rel_y := fifelse(state == "NY", survey_year - 2022L, -1000L)]
# Keep balanced window
ny_es_data <- ny_es_data[abs(rel_y) <= 4 | rel_y == -1000]

# Event study: NY vs never-treated controls
# All facilities get relative year centered on NY mandate (2022)
ny_es_data2 <- ny_panel[TRUE]
ny_es_data2[, rel_yr := survey_year - 2022L]
ny_es_data2[, ny_treat := as.integer(state == "NY")]
ny_es_data2 <- ny_es_data2[abs(rel_yr) <= 4]

ny_es <- tryCatch({
  feols(n_deficiencies ~ i(rel_yr, ny_treat, ref = -1) | ccn + survey_year,
        data = ny_es_data2, vcov = ~state)
}, error = function(e) {
  cat("NY event study error:", e$message, "\n")
  NULL
})
if (!is.null(ny_es)) {
  cat("\nNY event study:\n")
  print(summary(ny_es))
}

# ================================================================
# 3. POOLED SPECIFICATION: All 6 States (Secondary)
# ================================================================
cat("\n=== 3. Pooled: All 6 Treatment States ===\n")

# TWFE
pooled_twfe <- feols(n_deficiencies ~ treated | ccn + survey_year,
                     data = panel_did, vcov = ~state)
cat("Pooled TWFE:\n")
print(summary(pooled_twfe))

# Callaway-Sant'Anna
cs_yearly <- panel_did[, .(
  n_deficiencies = sum(n_deficiencies),
  n_observation = sum(n_observation),
  n_documentation = sum(n_documentation),
  n_report = sum(n_report),
  n_infection = sum(n_infection),
  n_low_severity = sum(n_low_severity),
  n_high_severity = sum(n_high_severity),
  n_standard = sum(n_standard),
  n_complaint = sum(n_complaint),
  has_severe = max(has_severe),
  n_surveys = .N
), by = .(ccn, state, survey_year, cohort, beds, urban)]
cs_yearly[, fac_id := as.integer(factor(ccn))]

# Keep facilities with >= 3 years
fac_years <- cs_yearly[, .(n_years = uniqueN(survey_year)), by = fac_id]
cs_yearly <- cs_yearly[fac_id %in% fac_years[n_years >= 3]$fac_id]

cat(sprintf("CS-DiD panel: %d facility-years, %d facilities\n",
            nrow(cs_yearly), uniqueN(cs_yearly$fac_id)))

cs_out <- tryCatch({
  att_gt(yname = "n_deficiencies", tname = "survey_year",
         idname = "fac_id", gname = "cohort",
         data = as.data.frame(cs_yearly),
         control_group = "notyettreated",
         allow_unbalanced_panel = TRUE, base_period = "universal")
}, error = function(e) { cat("CS-DiD error:", e$message, "\n"); NULL })

if (!is.null(cs_out)) {
  cs_agg <- aggte(cs_out, type = "simple")
  cat("\nCallaway-Sant'Anna ATT:\n")
  print(summary(cs_agg))

  cs_dynamic <- aggte(cs_out, type = "dynamic", min_e = -4, max_e = 4)
  cat("\nCS-DiD event study:\n")
  print(summary(cs_dynamic))

  saveRDS(cs_out, "../data/cs_did_results.rds")
  saveRDS(cs_dynamic, "../data/cs_dynamic.rds")
}

# Pooled by detection mode
pooled_obs <- feols(n_observation ~ treated | ccn + survey_year,
                    data = panel_did, vcov = ~state)
pooled_doc <- feols(n_documentation ~ treated | ccn + survey_year,
                    data = panel_did, vcov = ~state)
pooled_rpt <- feols(n_report ~ treated | ccn + survey_year,
                    data = panel_did, vcov = ~state)
pooled_infect <- feols(n_infection ~ treated | ccn + survey_year,
                       data = panel_did, vcov = ~state)

cat("\nPooled by detection mode:\n")
cat(sprintf("  Observation: %.3f (%.3f)\n", coef(pooled_obs)["treated"],
            sqrt(vcov(pooled_obs)["treated", "treated"])))
cat(sprintf("  Documentation: %.3f (%.3f)\n", coef(pooled_doc)["treated"],
            sqrt(vcov(pooled_doc)["treated", "treated"])))
cat(sprintf("  Report: %.3f (%.3f)\n", coef(pooled_rpt)["treated"],
            sqrt(vcov(pooled_rpt)["treated", "treated"])))
cat(sprintf("  Infection: %.3f (%.3f)\n", coef(pooled_infect)["treated"],
            sqrt(vcov(pooled_infect)["treated", "treated"])))

# ================================================================
# 4. HETEROGENEITY
# ================================================================
cat("\n=== 4. Heterogeneity ===\n")

# By ownership (using pooled)
het_fp <- feols(n_deficiencies ~ treated | ccn + survey_year,
                data = panel_did[own_cat == "for_profit"], vcov = ~state)
het_np <- feols(n_deficiencies ~ treated | ccn + survey_year,
                data = panel_did[own_cat == "nonprofit"], vcov = ~state)

cat(sprintf("For-profit: %.3f (%.3f)\n", coef(het_fp)["treated"],
            sqrt(vcov(het_fp)["treated", "treated"])))
cat(sprintf("Nonprofit: %.3f (%.3f)\n", coef(het_np)["treated"],
            sqrt(vcov(het_np)["treated", "treated"])))

# By size
het_small <- feols(n_deficiencies ~ treated | ccn + survey_year,
                   data = panel_did[size_cat == "small"], vcov = ~state)
het_large <- feols(n_deficiencies ~ treated | ccn + survey_year,
                   data = panel_did[size_cat == "large"], vcov = ~state)

cat(sprintf("Small (≤60 beds): %.3f (%.3f)\n", coef(het_small)["treated"],
            sqrt(vcov(het_small)["treated", "treated"])))
cat(sprintf("Large (>120 beds): %.3f (%.3f)\n", coef(het_large)["treated"],
            sqrt(vcov(het_large)["treated", "treated"])))

# ================================================================
# 5. DIAGNOSTICS
# ================================================================
cat("\n=== 5. Diagnostics ===\n")

diagnostics <- list(
  n_treated_facilities = uniqueN(panel_did$ccn[panel_did$treated == 1]),
  n_control_facilities = uniqueN(panel_did$ccn[panel_did$treated == 0]),
  n_obs = nrow(panel_did),
  n_facilities = uniqueN(panel_did$ccn),
  n_states = uniqueN(panel_did$state),
  n_treatment_states = 6L,
  n_treatment_cohorts = length(unique(panel_did$cohort[panel_did$cohort > 0])),
  year_range = paste(range(panel_did$survey_year), collapse = "-"),
  mean_def_control = round(mean(panel_did$n_deficiencies[panel_did$treated == 0]), 2),
  mean_def_treated = round(mean(panel_did$n_deficiencies[panel_did$treated == 1]), 2),
  ny_n_facilities = uniqueN(panel_did$ccn[panel_did$state == "NY"]),
  ny_pre_years = 5L  # 2017-2021
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("Diagnostics:\n")
str(diagnostics)

# ================================================================
# 6. Save all models
# ================================================================
results <- list(
  ny = list(
    twfe = ny_twfe, obs = ny_obs, doc = ny_doc, rpt = ny_rpt,
    infect = ny_infect, low = ny_low, high = ny_high, es = ny_es
  ),
  pooled = list(
    twfe = pooled_twfe, obs = pooled_obs, doc = pooled_doc,
    rpt = pooled_rpt, infect = pooled_infect
  ),
  het = list(fp = het_fp, np = het_np, small = het_small, large = het_large),
  first_stage = list(xs = fs_xs),
  diagnostics = diagnostics
)

saveRDS(results, "../data/results_v2.rds")
saveRDS(cs_yearly, "../data/cs_yearly.rds")

cat("\n=== Main analysis complete ===\n")
