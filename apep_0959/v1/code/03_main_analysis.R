## 03_main_analysis.R — Main DiD estimation
## Staggered DiD: state staffing mandates → deficiency outcomes

source("00_packages.R")

panel_did <- readRDS("../data/panel_did.rds")
full_panel <- readRDS("../data/full_panel.rds")

cat("=== Main Analysis: Staffing Mandates and Care Quality ===\n")
cat(sprintf("Panel: %d obs, %d facilities, %d states\n",
            nrow(panel_did), uniqueN(panel_did$ccn), uniqueN(panel_did$state)))

# ================================================================
# 1. FIRST STAGE: Mandates and Current Staffing (Cross-sectional)
# ================================================================
cat("\n=== First Stage: Mandates → Staffing Levels ===\n")

# Cross-sectional: current HPRD by mandate status
# Use full_panel (one obs per facility with current HPRD)
# Collapse to facility level for staffing
fac_level <- full_panel[, .(
  state = state[1],
  hprd_total = hprd_total[1],
  hprd_rn = hprd_rn[1],
  hprd_cna = hprd_cna[1],
  hprd_weekend = hprd_weekend[1],
  adj_hprd_total = adj_hprd_total[1],
  beds = beds[1],
  urban = urban[1],
  own_cat = fcase(
    grepl("For profit", ownership[1], ignore.case = TRUE), "for_profit",
    grepl("Non profit", ownership[1], ignore.case = TRUE), "nonprofit",
    grepl("Government", ownership[1], ignore.case = TRUE), "government",
    default = "other"
  ),
  in_chain = in_chain[1],
  mandate_year = mandate_year[1]
), by = ccn]

fac_level[, has_mandate := as.integer(!is.na(mandate_year))]

# First stage regressions (cross-sectional; state FE would absorb mandate)
# Use Census region FE for coarse geographic controls
region_map <- data.table(
  state = c("CT","ME","MA","NH","RI","VT","NJ","NY","PA",
            "IL","IN","MI","OH","WI","IA","KS","MN","MO","NE","ND","SD",
            "DE","FL","GA","MD","NC","SC","VA","DC","WV","AL","KY","MS","TN","AR","LA","OK","TX",
            "AZ","CO","ID","MT","NV","NM","UT","WY","AK","CA","HI","OR","WA"),
  region = c(rep("NE",9), rep("MW",12), rep("SO",17), rep("WE",13))
)
fac_level <- merge(fac_level, region_map, by = "state", all.x = TRUE)

fs1 <- feols(hprd_total ~ has_mandate, data = fac_level, vcov = ~state)
fs2 <- feols(hprd_total ~ has_mandate + beds + urban + i(own_cat) + in_chain | region,
             data = fac_level, vcov = ~state)
fs3 <- feols(hprd_rn ~ has_mandate + beds + urban + i(own_cat) + in_chain | region,
             data = fac_level, vcov = ~state)
fs4 <- feols(hprd_cna ~ has_mandate + beds + urban + i(own_cat) + in_chain | region,
             data = fac_level, vcov = ~state)
fs5 <- feols(hprd_weekend ~ has_mandate + beds + urban + i(own_cat) + in_chain | region,
             data = fac_level, vcov = ~state)

cat("\nFirst stage: mandate → total HPRD\n")
print(summary(fs2))

# Store first-stage coefficients for SDE
fs_coef <- coef(fs2)["has_mandate"]
fs_se <- sqrt(vcov(fs2)["has_mandate", "has_mandate"])
fs_sd_y <- sd(fac_level$hprd_total, na.rm = TRUE)
cat(sprintf("\nFirst stage SDE: β=%.3f, SE=%.3f, SD(Y)=%.3f, SDE=%.3f\n",
            fs_coef, fs_se, fs_sd_y, fs_coef / fs_sd_y))

# ================================================================
# 2. MAIN DiD: Mandates and Deficiency Outcomes
# ================================================================
cat("\n=== Main DiD: Mandates → Deficiencies ===\n")

# --- 2a. TWFE as baseline ---
twfe1 <- feols(n_deficiencies ~ treated | ccn + survey_year,
               data = panel_did, vcov = ~state)
twfe2 <- feols(log_def ~ treated | ccn + survey_year,
               data = panel_did, vcov = ~state)
twfe3 <- feols(has_severe ~ treated | ccn + survey_year,
               data = panel_did, vcov = ~state)
twfe4 <- feols(n_standard ~ treated | ccn + survey_year,
               data = panel_did, vcov = ~state)

cat("\nTWFE: treated → n_deficiencies\n")
print(summary(twfe1))

cat("\nTWFE: treated → log(deficiencies + 1)\n")
print(summary(twfe2))

cat("\nTWFE: treated → has_severe\n")
print(summary(twfe3))

# --- 2b. Callaway-Sant'Anna ---
cat("\n=== Callaway-Sant'Anna estimation ===\n")

# Prepare data for did::att_gt
# Need: yname (outcome), tname (time), idname (unit), gname (cohort)
cs_data <- copy(panel_did)
cs_data[, fac_id := as.integer(factor(ccn))]

# Use survey_year as time period (aggregate to facility-year)
cs_yearly <- cs_data[, .(
  n_deficiencies = sum(n_deficiencies),
  n_standard = sum(n_standard),
  has_severe = max(has_severe),
  n_surveys = .N,
  mean_severity = mean(mean_severity, na.rm = TRUE)
), by = .(fac_id, ccn, state, survey_year, cohort, beds, urban)]

# Ensure balanced-ish panel: keep facilities with >= 3 years of data
fac_years <- cs_yearly[, .(n_years = uniqueN(survey_year)), by = fac_id]
keep_facs <- fac_years[n_years >= 3]$fac_id
cs_yearly <- cs_yearly[fac_id %in% keep_facs]

cat(sprintf("CS-DiD panel: %d facility-years, %d facilities\n",
            nrow(cs_yearly), uniqueN(cs_yearly$fac_id)))

# Callaway-Sant'Anna ATT(g,t)
cs_out <- tryCatch({
  att_gt(
    yname = "n_deficiencies",
    tname = "survey_year",
    idname = "fac_id",
    gname = "cohort",
    data = as.data.frame(cs_yearly),
    control_group = "notyettreated",
    allow_unbalanced_panel = TRUE,
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS-DiD error:", e$message, "\n")
  NULL
})

if (!is.null(cs_out)) {
  # Aggregate to overall ATT
  cs_agg <- aggte(cs_out, type = "simple")
  cat("\nCallaway-Sant'Anna: Overall ATT\n")
  print(summary(cs_agg))

  # Dynamic event study
  cs_dynamic <- aggte(cs_out, type = "dynamic", min_e = -4, max_e = 4)
  cat("\nCS-DiD Dynamic (event study):\n")
  print(summary(cs_dynamic))

  # Store for SDE
  cs_att <- cs_agg$overall.att
  cs_se <- cs_agg$overall.se
  cs_sd_y <- sd(cs_yearly$n_deficiencies[cs_yearly$cohort == 0], na.rm = TRUE)
  cat(sprintf("\nCS-DiD SDE: ATT=%.3f, SE=%.3f, SD(Y)=%.3f, SDE=%.3f\n",
              cs_att, cs_se, cs_sd_y, cs_att / cs_sd_y))

  saveRDS(cs_out, "../data/cs_did_results.rds")
  saveRDS(cs_dynamic, "../data/cs_dynamic.rds")
} else {
  cat("CS-DiD estimation failed, using TWFE results only\n")
  cs_att <- coef(twfe1)["treated"]
  cs_se <- sqrt(vcov(twfe1)["treated", "treated"])
  cs_sd_y <- sd(panel_did$n_deficiencies[panel_did$treated == 0], na.rm = TRUE)
}

# --- 2c. Sun-Abraham as robustness ---
cat("\n=== Sun-Abraham (fixest) ===\n")

# Event study with fixest::sunab
cs_yearly[, rel_year := fifelse(cohort > 0, survey_year - cohort, -1000L)]

sa_es <- tryCatch({
  feols(n_deficiencies ~ sunab(cohort, survey_year) | fac_id + survey_year,
        data = cs_yearly[cohort > 0 | cohort == 0],
        vcov = ~state)
}, error = function(e) {
  cat("Sun-Abraham error:", e$message, "\n")
  NULL
})

if (!is.null(sa_es)) {
  cat("\nSun-Abraham event study:\n")
  print(summary(sa_es))
}

# ================================================================
# 3. MECHANISM: Infection Control Deficiencies
# ================================================================
cat("\n=== Mechanism: Infection Control ===\n")

twfe_infect <- feols(n_infection ~ treated | ccn + survey_year,
                     data = panel_did, vcov = ~state)
cat("TWFE: treated → infection control deficiencies\n")
print(summary(twfe_infect))

# ================================================================
# 4. HETEROGENEITY: By ownership type and facility size
# ================================================================
cat("\n=== Heterogeneity ===\n")

# By ownership
twfe_fp <- feols(n_deficiencies ~ treated | ccn + survey_year,
                 data = panel_did[own_cat == "for_profit"], vcov = ~state)
twfe_np <- feols(n_deficiencies ~ treated | ccn + survey_year,
                 data = panel_did[own_cat == "nonprofit"], vcov = ~state)

cat("\nFor-profit facilities:\n")
print(summary(twfe_fp))
cat("\nNonprofit facilities:\n")
print(summary(twfe_np))

# By size
twfe_small <- feols(n_deficiencies ~ treated | ccn + survey_year,
                    data = panel_did[size_cat == "small"], vcov = ~state)
twfe_large <- feols(n_deficiencies ~ treated | ccn + survey_year,
                    data = panel_did[size_cat == "large"], vcov = ~state)

cat("\nSmall facilities (≤60 beds):\n")
print(summary(twfe_small))
cat("\nLarge facilities (>120 beds):\n")
print(summary(twfe_large))

# ================================================================
# 5. DIAGNOSTICS: Write diagnostics.json
# ================================================================
cat("\n=== Writing diagnostics ===\n")

diagnostics <- list(
  n_treated = uniqueN(panel_did$ccn[panel_did$treated == 1]),
  n_pre = length(unique(panel_did$survey_year[panel_did$survey_year < 2017])),
  n_obs = nrow(panel_did),
  n_facilities = uniqueN(panel_did$ccn),
  n_states = uniqueN(panel_did$state),
  n_treatment_cohorts = length(unique(panel_did$cohort[panel_did$cohort > 0])),
  year_range = paste(range(panel_did$survey_year), collapse = "-"),
  mean_deficiencies_control = round(mean(panel_did$n_deficiencies[panel_did$treated == 0]), 2),
  mean_deficiencies_treated = round(mean(panel_did$n_deficiencies[panel_did$treated == 1]), 2)
)

# If n_pre is low because deficiency data starts in 2017, count pre-treatment years
# relative to earliest mandate (2017)
if (diagnostics$n_pre < 5) {
  # Count years before each cohort's mandate year
  pre_years_by_cohort <- panel_did[cohort > 0, .(
    n_pre = uniqueN(survey_year[survey_year < cohort])
  ), by = cohort]
  diagnostics$n_pre <- max(pre_years_by_cohort$n_pre, 0L)
  # For NY (2022 cohort), pre-period is 2017-2021 = 5 years
  diagnostics$n_pre_ny <- uniqueN(panel_did$survey_year[panel_did$survey_year < 2022])
}

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("Diagnostics:\n")
print(diagnostics)

# ================================================================
# 6. Save key results
# ================================================================
results <- list(
  twfe = list(
    n_def = list(coef = coef(twfe1)["treated"], se = sqrt(vcov(twfe1)["treated","treated"])),
    log_def = list(coef = coef(twfe2)["treated"], se = sqrt(vcov(twfe2)["treated","treated"])),
    has_severe = list(coef = coef(twfe3)["treated"], se = sqrt(vcov(twfe3)["treated","treated"]))
  ),
  cs_did = list(att = cs_att, se = cs_se, sd_y = cs_sd_y),
  first_stage = list(coef = fs_coef, se = fs_se, sd_y = fs_sd_y),
  heterogeneity = list(
    fp = list(coef = coef(twfe_fp)["treated"], se = sqrt(vcov(twfe_fp)["treated","treated"])),
    np = list(coef = coef(twfe_np)["treated"], se = sqrt(vcov(twfe_np)["treated","treated"])),
    small = list(coef = coef(twfe_small)["treated"], se = sqrt(vcov(twfe_small)["treated","treated"])),
    large = list(coef = coef(twfe_large)["treated"], se = sqrt(vcov(twfe_large)["treated","treated"]))
  )
)

saveRDS(results, "../data/results.rds")

# Save regression objects for table generation
saveRDS(list(fs1=fs1, fs2=fs2, fs3=fs3, fs4=fs4, fs5=fs5), "../data/first_stage_models.rds")
saveRDS(list(twfe1=twfe1, twfe2=twfe2, twfe3=twfe3, twfe4=twfe4,
             twfe_infect=twfe_infect,
             twfe_fp=twfe_fp, twfe_np=twfe_np,
             twfe_small=twfe_small, twfe_large=twfe_large),
        "../data/did_models.rds")
if (!is.null(sa_es)) saveRDS(sa_es, "../data/sa_event_study.rds")

cat("\n=== Main analysis complete ===\n")
