# ==============================================================================
# 02_clean_data.R — Construct analysis variables
# ==============================================================================

source("00_packages.R")

cat("Loading raw panel data...\n")
df <- arrow::read_parquet("../data/mlp_panel_raw.parquet")
setDT(df)

cat(sprintf("Raw panel: %s rows\n", format(nrow(df), big.mark = ",")))

# --------------------------------------------------------------------------
# Define treatment variables
# --------------------------------------------------------------------------

# Non-participating states (refused Sheppard-Towner funds):
# Massachusetts (25), Connecticut (09), Illinois (17)
non_participant_fips <- c(9L, 17L, 25L)

# Use birth place (bpl_1930) for treatment assignment
# IPUMS BPL codes for US states match FIPS codes for values 1-56
df[, participant := fifelse(bpl_1930 %in% non_participant_fips, 0L, 1L)]

# Exposed cohorts: born 1922-1928 (during Sheppard-Towner)
# Pre-treatment: born 1912-1921
# Post-treatment: born 1929-1932
df[, cohort_group := fcase(
  birthyr >= 1912 & birthyr <= 1921, "pre",
  birthyr >= 1922 & birthyr <= 1928, "exposed",
  birthyr >= 1929 & birthyr <= 1932, "post",
  default = "other"
)]

# Binary exposed indicator
df[, exposed := fifelse(birthyr >= 1922 & birthyr <= 1928, 1L, 0L)]

# DDD interaction
df[, ddd := participant * exposed]

# --------------------------------------------------------------------------
# Clean outcome variables
# --------------------------------------------------------------------------

# Wage income 1950: IPUMS codes 999999 (N/A) and 999998 (missing) as NA
# Also 1000000 is the topcode
df[incwage_1950 >= 999998, incwage_1950 := NA_real_]
df[incwage_1950 == 0, incwage_1950 := NA_real_]  # zero wages = not in labor force

# Education 1950: IPUMS educ codes
# 0=N/A, 1=none/preschool, 2=grade 1-4, 3=grade 5-8, 4=grade 9,
# 5=grade 10, 6=grade 11, 7=HS diploma/grade 12, 8=1yr college,
# 9=2yr college, 10=3yr college, 11=4yr college, 12=5+yr college
# Convert to approximate years
educ_to_years <- c(
  `0` = NA_real_, `1` = 0, `2` = 2.5, `3` = 6.5, `4` = 9, `5` = 10,
  `6` = 11, `7` = 12, `8` = 13, `9` = 14, `10` = 15, `11` = 16, `12` = 17
)
df[, educ_years := educ_to_years[as.character(educ_1950)]]

# Occupational income score 1950
df[occscore_1950 == 0, occscore_1950 := NA_real_]

# Employment status: 1 = employed
df[, employed_1950 := fifelse(empstat_1950 == 1, 1L, 0L)]

# Log wage
df[, log_wage := log(incwage_1950)]

# Rural: farm_1930 == 2 means farm residence
df[, rural_1930 := fifelse(farm_1930 == 2, 1L, 0L)]

# --------------------------------------------------------------------------
# Sample restrictions
# --------------------------------------------------------------------------

# Keep birth years 1900-1932
df <- df[birthyr >= 1900 & birthyr <= 1932]

# Keep US-born only (bpl < 100 in IPUMS)
df <- df[bpl_1930 < 100]

# Drop if missing birth state
df <- df[!is.na(bpl_1930)]

# Race indicators
df[, white := fifelse(race_1930 == 1, 1L, 0L)]
df[, black := fifelse(race_1930 == 2, 1L, 0L)]
df[, male := fifelse(sex_1930 == 1, 1L, 0L)]

# Married in 1950
df[, married_1950 := fifelse(marst_1950 %in% c(1, 2), 1L, 0L)]

cat(sprintf("Analysis sample: %s rows\n", format(nrow(df), big.mark = ",")))
cat(sprintf("  Participant states: %s\n", format(sum(df$participant == 1), big.mark = ",")))
cat(sprintf("  Non-participant states: %s\n", format(sum(df$participant == 0), big.mark = ",")))
cat(sprintf("  Exposed cohort: %s\n", format(sum(df$exposed == 1), big.mark = ",")))
cat(sprintf("  Pre-treatment cohort: %s\n", format(sum(df$cohort_group == "pre"), big.mark = ",")))
cat(sprintf("  Valid wage obs: %s\n", format(sum(!is.na(df$incwage_1950)), big.mark = ",")))

# Save analysis dataset
arrow::write_parquet(df, "../data/analysis_sample.parquet")
cat("Saved to data/analysis_sample.parquet\n")
