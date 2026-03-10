# ==============================================================================
# 02_clean_data.R — Variable construction and sample definition
# apep_0586: Winning the Peace
# ==============================================================================

source("00_packages.R")

panel <- fread("../data/panel_raw.csv")
state_ag <- fread("../data/state_instrument.csv")

cat("Loaded", nrow(panel), "records\n")

# ------------------------------------------------------------------------------
# 1. Define cohort groups
# ------------------------------------------------------------------------------

panel[, cohort_group := fcase(
  birth_year >= 1915 & birth_year <= 1922, "draft_eligible",
  birth_year >= 1905 & birth_year <= 1914, "older_control",
  birth_year >= 1895 & birth_year <= 1904, "age_placebo"
)]

panel[, draft_eligible := as.integer(cohort_group == "draft_eligible")]

cat("Cohort distribution:\n")
print(panel[, .N, by = cohort_group][order(cohort_group)])

# ------------------------------------------------------------------------------
# 2. Clean outcome variables
# ------------------------------------------------------------------------------

# Occupational score: already coded 0-80+ in IPUMS
# Code 0 = no occupation reported; keep as is for now, will handle in analysis

# Wage income: IPUMS codes 999998 = N/A, 999999 = top-coded
# Set missing/top-coded to NA for analysis
panel[, incwage_1940_clean := fifelse(
  incwage_1940 > 0 & incwage_1940 < 999998, incwage_1940, NA_real_
)]
panel[, incwage_1950_clean := fifelse(
  incwage_1950 > 0 & incwage_1950 < 999998, incwage_1950, NA_real_
)]

# Log wages (for those with positive earnings)
panel[, log_incwage_1940 := log(incwage_1940_clean)]
panel[, log_incwage_1950 := log(incwage_1950_clean)]

# Education: educ_1940 is IPUMS EDUC code (0-11 categories)
# educ_1950 appears to be coded differently (mean ~0.82 suggests binary?)
# Let's check the distribution
cat("\nEduc 1940 distribution:\n")
print(panel[, .N, by = educ_1940][order(educ_1940)])
cat("\nEduc 1950 distribution:\n")
print(panel[, .N, by = educ_1950][order(educ_1950)])

# Convert IPUMS EDUC codes to approximate years of schooling
educ_to_years <- function(educ) {
  fcase(
    educ == 0, 0,    # N/A or no schooling
    educ == 1, 0,    # None or preschool
    educ == 2, 4,    # Grade 1-4
    educ == 3, 6,    # Grade 5-6
    educ == 4, 8,    # Grade 7-8
    educ == 5, 9,    # Grade 9
    educ == 6, 10,   # Grade 10
    educ == 7, 11,   # Grade 11
    educ == 8, 12,   # Grade 12 / HS diploma
    educ == 9, 13,   # 1 year college
    educ == 10, 14,  # 2 years college
    educ == 11, 16,  # 4+ years college
    default = NA_real_
  )
}

panel[, educ_years_1940 := educ_to_years(educ_1940)]

# For 1950, check if it's the same coding scheme
# If it's binary (0/1), it might be "currently attending school" rather than attainment
# We'll handle this in the analysis

# Create education dummy: any college (educ >= 9 in IPUMS coding = 1+ year college)
panel[, any_college_1940 := as.integer(educ_1940 >= 9)]

# Attempt to code educ_1950 similarly if same scheme
panel[, educ_years_1950 := educ_to_years(educ_1950)]
panel[, any_college_1950 := as.integer(educ_1950 >= 9)]

# If educ_1950 is mostly 0/1, it's probably school attendance, not attainment
if (mean(panel$educ_1950 %in% c(0, 1), na.rm = TRUE) > 0.9) {
  cat("\nNOTE: educ_1950 appears to be school attendance (binary), not attainment\n")
  panel[, in_school_1950 := as.integer(educ_1950 >= 1)]
}

# ------------------------------------------------------------------------------
# 3. Construct outcome differences (1940→1950 and 1930→1940)
# ------------------------------------------------------------------------------

# Primary outcome: change in occupational score
panel[, delta_occscore_40_50 := occscore_1950 - occscore_1940]
panel[, delta_occscore_30_40 := occscore_1940 - occscore_1930]

# SEI changes
panel[, delta_sei := sei_1940 - sei_1930]  # Only have SEI for 1930 and 1940

# Occupation upgrading: moved to higher occscore
panel[, occ_upgraded_40_50 := as.integer(occscore_1950 > occscore_1940)]
panel[, occ_upgraded_30_40 := as.integer(occscore_1940 > occscore_1930)]

# Log wage change (conditional on positive wages in both periods)
panel[, delta_log_wage := log_incwage_1950 - log_incwage_1940]

# Moved out of agriculture (1940→1950)
panel[, in_ag_1940 := as.integer(ind1950_1940 >= 105 & ind1950_1940 <= 126)]
panel[, in_ag_1950 := as.integer(ind1950_1950 >= 105 & ind1950_1950 <= 126)]
panel[, left_ag := as.integer(in_ag_1940 == 1 & in_ag_1950 == 0)]

# Moved into manufacturing
panel[, in_mfg_1940 := as.integer(ind1950_1940 >= 306 & ind1950_1940 <= 499)]
panel[, in_mfg_1950 := as.integer(ind1950_1950 >= 306 & ind1950_1950 <= 499)]
panel[, entered_mfg := as.integer(in_mfg_1940 == 0 & in_mfg_1950 == 1)]

# ------------------------------------------------------------------------------
# 4. Pre-war controls
# ------------------------------------------------------------------------------

# Race indicators
panel[, white := as.integer(race_1940 == 1)]
panel[, black := as.integer(race_1940 == 2)]

# Native-born indicator
panel[, native_born := as.integer(nativity_1940 <= 3)]

# Married indicator
panel[, married_1940 := as.integer(marst_1940 <= 2)]

# Farm residence
panel[, farm_1940_d := as.integer(farm_1940 == 2)]  # IPUMS farm=2 is farm

# Employed
panel[, employed_1940 := as.integer(empstat_1940 == 1)]

# Pre-war occupation quintiles (among those with occscore > 0)
panel[occscore_1940 > 0, occ_quintile_1940 := cut(
  occscore_1940,
  breaks = quantile(occscore_1940, probs = seq(0, 1, 0.2), na.rm = TRUE),
  labels = paste0("Q", 1:5),
  include.lowest = TRUE
)]

# State of birth (for fixed effects or controls)
panel[, bpl_state := fifelse(bpl_1940 <= 56, bpl_1940, NA_integer_)]

# ------------------------------------------------------------------------------
# 5. Merge state-level instrument
# ------------------------------------------------------------------------------

setnames(state_ag, "statefip", "statefip_1940")
panel <- merge(panel, state_ag[, .(statefip_1940, ag_share, mfg_share,
                                    mob_exposure, mob_exposure_std)],
               by = "statefip_1940", all.x = TRUE)

# Key interaction: mobilization exposure × draft eligible
panel[, mob_x_draft := mob_exposure_std * draft_eligible]

cat("\nMerge result:", sum(!is.na(panel$mob_exposure)), "of", nrow(panel),
    "matched to state instrument\n")

# ------------------------------------------------------------------------------
# 6. Analysis sample restrictions
# ------------------------------------------------------------------------------

# Keep men with valid state and cohort group
analysis <- panel[!is.na(mob_exposure) & !is.na(cohort_group)]

cat("\nAnalysis sample:", nrow(analysis), "observations\n")
cat("  Draft eligible:", sum(analysis$draft_eligible == 1), "\n")
cat("  Older control:", sum(analysis$cohort_group == "older_control"), "\n")
cat("  Age placebo:", sum(analysis$cohort_group == "age_placebo"), "\n")
cat("  States:", length(unique(analysis$statefip_1940)), "\n")

# ------------------------------------------------------------------------------
# 7. Save cleaned data
# ------------------------------------------------------------------------------

fwrite(analysis, "../data/analysis_sample.csv")

# Summary statistics for table
sumstats <- analysis[, .(
  n = .N,
  mean_occscore_1930 = mean(occscore_1930, na.rm = TRUE),
  sd_occscore_1930 = sd(occscore_1930, na.rm = TRUE),
  mean_occscore_1940 = mean(occscore_1940, na.rm = TRUE),
  sd_occscore_1940 = sd(occscore_1940, na.rm = TRUE),
  mean_occscore_1950 = mean(occscore_1950, na.rm = TRUE),
  sd_occscore_1950 = sd(occscore_1950, na.rm = TRUE),
  mean_delta_occ_40_50 = mean(delta_occscore_40_50, na.rm = TRUE),
  sd_delta_occ_40_50 = sd(delta_occscore_40_50, na.rm = TRUE),
  mean_delta_occ_30_40 = mean(delta_occscore_30_40, na.rm = TRUE),
  sd_delta_occ_30_40 = sd(delta_occscore_30_40, na.rm = TRUE),
  mean_educ_years_1940 = mean(educ_years_1940, na.rm = TRUE),
  sd_educ_years_1940 = sd(educ_years_1940, na.rm = TRUE),
  mean_incwage_1940 = mean(incwage_1940_clean, na.rm = TRUE),
  sd_incwage_1940 = sd(incwage_1940_clean, na.rm = TRUE),
  mean_incwage_1950 = mean(incwage_1950_clean, na.rm = TRUE),
  sd_incwage_1950 = sd(incwage_1950_clean, na.rm = TRUE),
  pct_white = mean(white, na.rm = TRUE) * 100,
  pct_married = mean(married_1940, na.rm = TRUE) * 100,
  pct_farm = mean(farm_1940_d, na.rm = TRUE) * 100,
  pct_in_ag = mean(in_ag_1940, na.rm = TRUE) * 100,
  pct_native = mean(native_born, na.rm = TRUE) * 100,
  pct_mover = mean(mover_40_50, na.rm = TRUE) * 100,
  mean_ag_share = mean(ag_share, na.rm = TRUE),
  mean_mob_exposure = mean(mob_exposure, na.rm = TRUE)
), by = cohort_group]

fwrite(sumstats, "../data/summary_stats.csv")
cat("\nSummary statistics by cohort group saved.\n")
print(sumstats[, .(cohort_group, n, mean_occscore_1940, mean_delta_occ_40_50,
                    mean_educ_years_1940, pct_white, pct_farm)])
