# 02_clean_data.R — Construct analysis variables and sibling sample
# apep_0955: AAA Cotton Acreage Reduction and Black Sharecropper Children

source("00_packages.R")

# ---- Load data ----
mlp_black <- readRDS("../data/mlp_black_children.rds")
mlp_white <- readRDS("../data/mlp_white_children.rds")
county_dt <- readRDS("../data/county_treatment.rds")

dt <- as.data.table(mlp_black)
dt_white <- as.data.table(mlp_white)

cat("Black children sample:", nrow(dt), "\n")
cat("White children sample:", nrow(dt_white), "\n")

# --- Helper: Recode IPUMS EDUC categorical to approximate years of schooling ---
educ_to_years <- function(x) {
  fcase(
    x == 0,  0,     # No schooling
    x == 1,  2,     # Nursery to grade 4 (midpoint)
    x == 2,  6.5,   # Grade 5-8 (midpoint)
    x == 3,  9,     # Grade 9
    x == 4,  10,    # Grade 10
    x == 5,  11,    # Grade 11
    x == 6,  12,    # Grade 12
    x == 7,  13,    # 1 year college
    x == 8,  14,    # 2 years college
    x == 9,  15,    # 3 years college
    x == 10, 16,    # 4 years college
    x == 11, 17,    # 5+ years college
    x == 99, NA_real_,
    default = NA_real_
  )
}

# ============================================================================
# STEP 1: Define age cohort at AAA implementation (1933)
# ============================================================================
# Child's age in 1933 = age_1930 + 3
dt[, age_1933 := age_1930 + 3L]

# Age cohort classification
# Young (0-5 in 1933): not yet school-age, potentially protected
# School-age (6-12 in 1933): critical educational investment period disrupted
# Labor-age (13-17 in 1933): past school, entering labor market
dt[, age_cohort := fcase(
  age_1933 <= 5,  "young_0_5",
  age_1933 <= 12, "school_6_12",
  age_1933 <= 17, "labor_13_17",
  default = NA_character_
)]

# Binary: school-age indicator (primary treatment group)
dt[, school_age := as.integer(age_cohort == "school_6_12")]

# Continuous age at AAA for finer-grained analysis
dt[, age_at_aaa := age_1933]

cat("Age cohort distribution:\n")
print(dt[, .N, by = age_cohort])

# Same for white children
dt_white[, age_1933 := age_1930 + 3L]
dt_white[, age_cohort := fcase(
  age_1933 <= 5,  "young_0_5",
  age_1933 <= 12, "school_6_12",
  age_1933 <= 17, "labor_13_17",
  default = NA_character_
)]
dt_white[, school_age := as.integer(age_cohort == "school_6_12")]

# Education recoding for white children too
dt_white[, educ_years_1940 := educ_to_years(educ_1940)]
dt_white[, educ_years_1950 := educ_to_years(educ_1950)]

# ============================================================================
# STEP 2: Merge county-level treatment
# ============================================================================
dt <- merge(dt, county_dt[, .(statefip_1930, countyicp_1930, aaa_intensity,
                                aaa_intensity_z, black_farm_share, farm_share)],
            by = c("statefip_1930", "countyicp_1930"), all.x = TRUE)

dt_white <- merge(dt_white, county_dt[, .(statefip_1930, countyicp_1930, aaa_intensity,
                                            aaa_intensity_z, black_farm_share, farm_share)],
                  by = c("statefip_1930", "countyicp_1930"), all.x = TRUE)

cat("\nMerge rates:\n")
cat("  Black children with treatment:", mean(!is.na(dt$aaa_intensity)), "\n")
cat("  White children with treatment:", mean(!is.na(dt_white$aaa_intensity)), "\n")

# Drop observations without treatment data
dt <- dt[!is.na(aaa_intensity)]
dt_white <- dt_white[!is.na(aaa_intensity)]

# ============================================================================
# STEP 3: Construct outcome variables
# ============================================================================

dt[, educ_years_1940 := educ_to_years(educ_1940)]
dt[, educ_years_1950 := educ_to_years(educ_1950)]

# educ_1950 has 82% zeros — likely a data limitation in 1950 census linkage
# Create binary "any schooling" for 1950 as more robust measure
dt[educ_1950 != 99, any_school_1950 := as.integer(educ_1950 > 0)]

cat("Education 1940 (years, excl missing):",
    mean(dt$educ_years_1940, na.rm = TRUE), "SD:",
    sd(dt$educ_years_1940, na.rm = TRUE), "\n")
cat("Education 1950 (years, excl missing):",
    mean(dt$educ_years_1950, na.rm = TRUE), "SD:",
    sd(dt$educ_years_1950, na.rm = TRUE), "\n")
cat("Any schooling 1950:", mean(dt$any_school_1950, na.rm = TRUE), "\n")

# --- Income ---
dt[, incwage_1940_clean := fifelse(incwage_1940 > 0 & incwage_1940 < 999998,
                                    incwage_1940, NA_real_)]
dt[, incwage_1950_clean := fifelse(incwage_1950 > 0 & incwage_1950 < 999998,
                                    incwage_1950, NA_real_)]

# Winsorize at 99th percentile
p99_40 <- quantile(dt$incwage_1940_clean, 0.99, na.rm = TRUE)
p99_50 <- quantile(dt$incwage_1950_clean, 0.99, na.rm = TRUE)
dt[incwage_1940_clean > p99_40, incwage_1940_clean := p99_40]
dt[incwage_1950_clean > p99_50, incwage_1950_clean := p99_50]

# Log income
dt[, log_inc_1940 := log(incwage_1940_clean + 1)]
dt[, log_inc_1950 := log(incwage_1950_clean + 1)]

# --- Migration and farm transition ---
dt[, migrated_by_1940 := as.integer(mover_30_40 == 1)]
dt[, migrated_by_1950 := as.integer(mover_40_50 == 1 | mover_30_40 == 1)]
dt[, off_farm_1940 := as.integer(farm_1940 != 2)]
dt[, off_farm_1950 := as.integer(farm_1950 != 2)]

# Sex indicator
dt[, female := as.integer(sex_1930 == 2)]

# ============================================================================
# STEP 4: Identify sibling groups (children in same 1930 household)
# ============================================================================
# Siblings = children (relate_1930 in [3,4] = child of head) in same serial_1930
dt[, is_child := as.integer(relate_1930 %in% c(3, 4))]

# Count children per household
dt[is_child == 1, n_siblings := .N, by = serial_1930]

# Sibling FE sample: households with 2+ linked children
sibling_dt <- dt[is_child == 1 & n_siblings >= 2]

cat("\n=== Sibling sample construction ===\n")
cat("All Black farm children:", nrow(dt), "\n")
cat("Children of head:", sum(dt$is_child == 1), "\n")
cat("In households with 2+ siblings:", nrow(sibling_dt), "\n")
cat("Unique households:", uniqueN(sibling_dt$serial_1930), "\n")

# Verify age variation within families
sibling_dt[, age_range := max(age_1930) - min(age_1930), by = serial_1930]
sibling_dt[, has_age_variation := as.integer(age_range > 0)]
cat("Households with age variation:", mean(sibling_dt$has_age_variation[!duplicated(sibling_dt$serial_1930)]), "\n")

# Need variation in age cohort within family for identification
sibling_dt[, n_cohorts := uniqueN(age_cohort), by = serial_1930]
sibling_cross_cohort <- sibling_dt[n_cohorts >= 2]
cat("Siblings spanning 2+ age cohorts:", nrow(sibling_cross_cohort), "\n")
cat("Households spanning 2+ cohorts:", uniqueN(sibling_cross_cohort$serial_1930), "\n")

# ============================================================================
# STEP 5: High vs low AAA intensity county classification (for heterogeneity)
# ============================================================================
median_intensity <- median(county_dt$aaa_intensity, na.rm = TRUE)
dt[, high_aaa := as.integer(aaa_intensity > median_intensity)]
sibling_dt[, high_aaa := as.integer(aaa_intensity > median_intensity)]

# Tercile splits
county_dt[, aaa_tercile := cut(aaa_intensity,
  breaks = quantile(aaa_intensity, c(0, 1/3, 2/3, 1), na.rm = TRUE),
  labels = c("low", "mid", "high"), include.lowest = TRUE)]

dt <- merge(dt, county_dt[, .(statefip_1930, countyicp_1930, aaa_tercile)],
            by = c("statefip_1930", "countyicp_1930"), all.x = TRUE)
sibling_dt <- merge(sibling_dt, county_dt[, .(statefip_1930, countyicp_1930, aaa_tercile)],
                     by = c("statefip_1930", "countyicp_1930"), all.x = TRUE)

# ============================================================================
# STEP 6: Summary statistics
# ============================================================================
cat("\n=== Summary Statistics (Sibling Sample) ===\n")
cat("\nOutcomes by age cohort:\n")
print(sibling_dt[, .(
  n = .N,
  educ_years_1940 = mean(educ_years_1940, na.rm = TRUE),
  occscore_1930 = mean(occscore_1930, na.rm = TRUE),
  occscore_1940 = mean(occscore_1940, na.rm = TRUE),
  occscore_1950 = mean(occscore_1950, na.rm = TRUE),
  migrated_1940 = mean(migrated_by_1940, na.rm = TRUE),
  off_farm_1940 = mean(off_farm_1940, na.rm = TRUE)
), by = age_cohort])

cat("\nTreatment variation across counties:\n")
print(summary(county_dt$aaa_intensity))

# ============================================================================
# STEP 7: Save analysis datasets
# ============================================================================
saveRDS(dt, "../data/analysis_full.rds")
saveRDS(sibling_dt, "../data/analysis_siblings.rds")
saveRDS(sibling_cross_cohort, "../data/analysis_siblings_cross_cohort.rds")
saveRDS(dt_white, "../data/analysis_white.rds")

cat("\nAnalysis datasets saved:\n")
cat("  analysis_full.rds:", nrow(dt), "rows\n")
cat("  analysis_siblings.rds:", nrow(sibling_dt), "rows\n")
cat("  analysis_siblings_cross_cohort.rds:", nrow(sibling_cross_cohort), "rows\n")
cat("  analysis_white.rds:", nrow(dt_white), "rows\n")
