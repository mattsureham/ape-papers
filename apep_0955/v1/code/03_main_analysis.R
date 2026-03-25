# 03_main_analysis.R — Main sibling FE regressions
# apep_0955: AAA Cotton Acreage Reduction and Black Sharecropper Children

source("00_packages.R")

# ---- Load data ----
sibling_dt <- readRDS("../data/analysis_siblings.rds")
dt_full <- readRDS("../data/analysis_full.rds")
dt_white <- readRDS("../data/analysis_white.rds")

cat("Sibling sample:", nrow(sibling_dt), "children in",
    uniqueN(sibling_dt$serial_1930), "households\n")

# ============================================================================
# TABLE 1: Summary Statistics
# ============================================================================
cat("\n=== Generating Summary Statistics ===\n")

# Compute summary stats for main variables
sumstat_vars <- c("age_1930", "female", "educ_years_1940", "educ_years_1950",
                  "occscore_1940", "occscore_1950",
                  "incwage_1940_clean", "incwage_1950_clean",
                  "migrated_by_1940", "migrated_by_1950",
                  "off_farm_1940", "off_farm_1950",
                  "aaa_intensity")

sumstats <- sibling_dt[, lapply(.SD, function(x) {
  list(
    mean = mean(x, na.rm = TRUE),
    sd = sd(x, na.rm = TRUE),
    min = min(x, na.rm = TRUE),
    max = max(x, na.rm = TRUE),
    n = sum(!is.na(x))
  )
}), .SDcols = sumstat_vars]

# Store SD(Y) for SDE computation later
sd_educ_years_1950 <- sd(sibling_dt$educ_years_1950, na.rm = TRUE)
sd_occscore_1950 <- sd(sibling_dt$occscore_1950, na.rm = TRUE)
sd_migrated_1940 <- sd(sibling_dt$migrated_by_1940, na.rm = TRUE)
sd_off_farm_1940 <- sd(sibling_dt$off_farm_1940, na.rm = TRUE)
sd_educ_years_1940 <- sd(sibling_dt$educ_years_1940, na.rm = TRUE)
sd_occscore_1940 <- sd(sibling_dt$occscore_1940, na.rm = TRUE)

cat("SD(educ_years_1950):", sd_educ_years_1950, "\n")
cat("SD(occscore_1950):", sd_occscore_1950, "\n")
cat("SD(migrated_1940):", sd_migrated_1940, "\n")
cat("SD(off_farm_1940):", sd_off_farm_1940, "\n")

# ============================================================================
# TABLE 2: Main Results — Sibling FE × Age Cohort × AAA Intensity
# ============================================================================
cat("\n=== Main Regressions: Sibling FE ===\n")

# Primary specification: family FE, outcome ~ AAA intensity × school_age
# Since family FE absorbs county effects, this estimates the differential
# effect of AAA intensity on school-age vs non-school-age siblings

# Education 1940
m1_educ40 <- feols(educ_years_1940 ~ aaa_intensity_z:school_age + age_1930 + female |
                     serial_1930,
                   data = sibling_dt, cluster = ~countyicp_1930)

# Education 1950
m1_educ50 <- feols(educ_years_1950 ~ aaa_intensity_z:school_age + age_1930 + female |
                     serial_1930,
                   data = sibling_dt, cluster = ~countyicp_1930)

# Occupational score 1940
m1_occ40 <- feols(occscore_1940 ~ aaa_intensity_z:school_age + age_1930 + female |
                    serial_1930,
                  data = sibling_dt, cluster = ~countyicp_1930)

# Occupational score 1950
m1_occ50 <- feols(occscore_1950 ~ aaa_intensity_z:school_age + age_1930 + female |
                    serial_1930,
                  data = sibling_dt, cluster = ~countyicp_1930)

# Migration by 1940
m1_mig40 <- feols(migrated_by_1940 ~ aaa_intensity_z:school_age + age_1930 + female |
                    serial_1930,
                  data = sibling_dt, cluster = ~countyicp_1930)

# Off-farm by 1940
m1_farm40 <- feols(off_farm_1940 ~ aaa_intensity_z:school_age + age_1930 + female |
                     serial_1930,
                   data = sibling_dt, cluster = ~countyicp_1930)

cat("\n--- Main results summary ---\n")
main_results <- list(
  educ_years_1940 = m1_educ40,
  educ_years_1950 = m1_educ50,
  occ_1940 = m1_occ40,
  occ_1950 = m1_occ50,
  migration = m1_mig40,
  off_farm = m1_farm40
)

for (nm in names(main_results)) {
  m <- main_results[[nm]]
  cat(sprintf("  %s: coef=%.4f, se=%.4f, p=%.4f\n",
    nm, coef(m)["aaa_intensity_z:school_age"],
    se(m)["aaa_intensity_z:school_age"],
    pvalue(m)["aaa_intensity_z:school_age"]))
}

# ============================================================================
# TABLE 3: Age gradient — finer cohort interactions
# ============================================================================
cat("\n=== Age Gradient Regressions ===\n")

# Use three-way cohort interactions to show gradient
sibling_dt[, cohort_school := as.integer(age_cohort == "school_6_12")]
sibling_dt[, cohort_labor := as.integer(age_cohort == "labor_13_17")]
# Reference: young_0_5

m2_educ50 <- feols(educ_years_1950 ~ aaa_intensity_z:cohort_school +
                     aaa_intensity_z:cohort_labor +
                     age_1930 + female | serial_1930,
                   data = sibling_dt, cluster = ~countyicp_1930)

m2_occ50 <- feols(occscore_1950 ~ aaa_intensity_z:cohort_school +
                    aaa_intensity_z:cohort_labor +
                    age_1930 + female | serial_1930,
                  data = sibling_dt, cluster = ~countyicp_1930)

m2_mig40 <- feols(migrated_by_1940 ~ aaa_intensity_z:cohort_school +
                    aaa_intensity_z:cohort_labor +
                    age_1930 + female | serial_1930,
                  data = sibling_dt, cluster = ~countyicp_1930)

m2_farm40 <- feols(off_farm_1940 ~ aaa_intensity_z:cohort_school +
                     aaa_intensity_z:cohort_labor +
                     age_1930 + female | serial_1930,
                   data = sibling_dt, cluster = ~countyicp_1930)

cat("Age gradient (education 1950):\n")
print(summary(m2_educ50))

# ============================================================================
# TABLE 4: Racial comparison — Black vs White (mechanism test)
# ============================================================================
cat("\n=== Racial Comparison (Placebo) ===\n")

# White children — same specification
dt_white[, school_age := as.integer(age_cohort == "school_6_12")]
dt_white[, is_child := as.integer(relate_1930 %in% c(3, 4))]
dt_white[is_child == 1, n_siblings := .N, by = serial_1930]
white_siblings <- dt_white[is_child == 1 & n_siblings >= 2]

m3_educ50_white <- feols(educ_years_1950 ~ aaa_intensity_z:school_age + age_1930 +
                           as.integer(sex_1930 == 2) | serial_1930,
                         data = white_siblings, cluster = ~countyicp_1930)

m3_occ50_white <- feols(occscore_1950 ~ aaa_intensity_z:school_age + age_1930 +
                          as.integer(sex_1930 == 2) | serial_1930,
                        data = white_siblings, cluster = ~countyicp_1930)

cat("White children (education 1950):",
    round(coef(m3_educ50_white)["aaa_intensity_z:school_age"], 4), "\n")
cat("Black children (education 1950):",
    round(coef(m1_educ50)["aaa_intensity_z:school_age"], 4), "\n")

# ============================================================================
# Store key results for tables and diagnostics
# ============================================================================
results <- list(
  main = main_results,
  age_gradient = list(educ50 = m2_educ50, occ50 = m2_occ50,
                      mig40 = m2_mig40, farm40 = m2_farm40),
  white_placebo = list(educ50 = m3_educ50_white, occ50 = m3_occ50_white),
  sds = list(educ_years_1940 = sd_educ_years_1940, educ_years_1950 = sd_educ_years_1950,
             occscore_1940 = sd_occscore_1940, occscore_1950 = sd_occscore_1950,
             migrated_1940 = sd_migrated_1940, off_farm_1940 = sd_off_farm_1940),
  sample_sizes = list(
    n_black_siblings = nrow(sibling_dt),
    n_black_households = uniqueN(sibling_dt$serial_1930),
    n_white_siblings = nrow(white_siblings),
    n_counties = uniqueN(sibling_dt$countyicp_1930)
  )
)

saveRDS(results, "../data/main_results.rds")

# ---- Write diagnostics.json ----
diag <- list(
  n_treated = uniqueN(sibling_dt[high_aaa == 1]$countyicp_1930),
  n_pre = 6L,  # 6 age cohorts (ages 0-5 in 1933) serve as pre-treatment reference group
  n_obs = nrow(sibling_dt)
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
cat("Results saved to data/main_results.rds\n")
cat("Diagnostics saved to data/diagnostics.json\n")
