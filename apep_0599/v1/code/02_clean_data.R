# ============================================================================
# 02_clean_data.R — Data cleaning and panel construction
# Denmark's 2013 Disability Pension Reform (apep_0599)
#
# Inputs:  ../data/auk01_raw.csv, auk01_sex_raw.csv, folk1c_raw.csv,
#          ras200_raw.csv, indkp111_raw.csv
# Outputs: ../data/panel_benefits.csv, panel_employment.csv,
#          panel_national.csv, summary_stats.csv
# ============================================================================

source("00_packages.R")

DATA_DIR <- "../data"

cat("=== 02_clean_data.R: Loading raw data ===\n")

# ============================================================================
# 1. READ RAW DATA
# ============================================================================

# AUK01: Benefits by municipality x benefit type x age x quarter
# Columns: OMRÅDE, YDELSESTYPE, KØN, ALDER, TID, INDHOLD, benefit_code, benefit_label
auk01 <- fread(file.path(DATA_DIR, "auk01_raw.csv"), encoding = "UTF-8")
cat(sprintf("  AUK01:     %d rows, %d cols\n", nrow(auk01), ncol(auk01)))

# AUK01 by sex: Same structure + sex_code (M/K)
# Columns: OMRÅDE, YDELSESTYPE, KØN, ALDER, TID, INDHOLD, benefit_code, sex_code
auk01_sex <- fread(file.path(DATA_DIR, "auk01_sex_raw.csv"), encoding = "UTF-8")
cat(sprintf("  AUK01 sex: %d rows, %d cols\n", nrow(auk01_sex), ncol(auk01_sex)))

# FOLK1C: Population by municipality x age x quarter
# Columns: OMRÅDE, KØN, ALDER, HERKOMST, TID, INDHOLD
folk1c <- fread(file.path(DATA_DIR, "folk1c_raw.csv"), encoding = "UTF-8")
cat(sprintf("  FOLK1C:    %d rows, %d cols\n", nrow(folk1c), ncol(folk1c)))

# RAS200: Employment rate by municipality x age x year
# Columns: OMRÅDE, HERKOMST, ALDER, KØN, BEREGNING, TID, INDHOLD
ras200 <- fread(file.path(DATA_DIR, "ras200_raw.csv"), encoding = "UTF-8")
cat(sprintf("  RAS200:    %d rows, %d cols\n", nrow(ras200), ncol(ras200)))

# INDKP111: Income by region x age x year
# Columns: REGLAND, ENHED, KOEN, ALDER1, INDKOMSTTYPE, TID, INDHOLD
indkp111 <- fread(file.path(DATA_DIR, "indkp111_raw.csv"), encoding = "UTF-8")
cat(sprintf("  INDKP111:  %d rows, %d cols\n", nrow(indkp111), ncol(indkp111)))

# ============================================================================
# 2. RENAME COLUMNS TO STANDARD ENGLISH
# ============================================================================

cat("\n--- Renaming columns ---\n")

# AUK01: OMRÅDE -> municipality, YDELSESTYPE -> benefit_type_name,
#         KØN -> sex, ALDER -> age, TID -> time, INDHOLD -> value
setnames(auk01, c("OMRÅDE", "YDELSESTYPE", "KØN", "ALDER", "TID", "INDHOLD",
                   "benefit_code", "benefit_label"),
         c("municipality", "benefit_type_name", "sex", "age", "time", "value",
           "benefit_code", "benefit_label"))

setnames(auk01_sex, c("OMRÅDE", "YDELSESTYPE", "KØN", "ALDER", "TID", "INDHOLD",
                       "benefit_code", "sex_code"),
         c("municipality", "benefit_type_name", "sex_name", "age", "time", "value",
           "benefit_code", "sex_code"))

# FOLK1C: OMRÅDE -> municipality, KØN -> sex, ALDER -> age,
#          HERKOMST -> origin, TID -> time, INDHOLD -> population
setnames(folk1c, c("OMRÅDE", "KØN", "ALDER", "HERKOMST", "TID", "INDHOLD"),
         c("municipality", "sex", "age", "origin", "time", "population"))

# RAS200: OMRÅDE -> municipality, HERKOMST -> origin, ALDER -> age,
#          KØN -> sex, BEREGNING -> measure, TID -> time, INDHOLD -> emp_rate
setnames(ras200, c("OMRÅDE", "HERKOMST", "ALDER", "KØN", "BEREGNING", "TID", "INDHOLD"),
         c("municipality", "origin", "age", "sex", "measure", "time", "emp_rate"))

# INDKP111: REGLAND -> region, ENHED -> unit, KOEN -> sex,
#            ALDER1 -> age, INDKOMSTTYPE -> income_type, TID -> time, INDHOLD -> income
setnames(indkp111, c("REGLAND", "ENHED", "KOEN", "ALDER1", "INDKOMSTTYPE", "TID", "INDHOLD"),
         c("region", "unit", "sex", "age", "income_type", "time", "income"))

# ============================================================================
# 3. PARSE TIME VARIABLES
# ============================================================================

cat("\n--- Parsing time variables ---\n")

# AUK01 / FOLK1C: quarters like "2007Q1", "2008Q2"
parse_quarter <- function(dt, time_col = "time") {
  dt[, year := as.integer(substr(get(time_col), 1, 4))]
  dt[, quarter := as.integer(substr(get(time_col), 6, 6))]
  # Numeric time: year + (quarter - 1) / 4  (useful for event-time)
  dt[, yq := year + (quarter - 1L) / 4]
  invisible(dt)
}

parse_quarter(auk01)
parse_quarter(auk01_sex)
parse_quarter(folk1c)

# RAS200 / INDKP111: annual — TID is just "2008", "2009", etc.
ras200[, year := as.integer(time)]
indkp111[, year := as.integer(time)]

cat(sprintf("  AUK01 year range:     %d-%d\n", min(auk01$year), max(auk01$year)))
cat(sprintf("  FOLK1C year range:    %d-%d\n", min(folk1c$year), max(folk1c$year)))
cat(sprintf("  RAS200 year range:    %d-%d\n", min(ras200$year), max(ras200$year)))
cat(sprintf("  INDKP111 year range:  %d-%d\n", min(indkp111$year), max(indkp111$year)))

# ============================================================================
# 4. FILTER TO MUNICIPALITIES (drop aggregates)
# ============================================================================

cat("\n--- Filtering to municipalities ---\n")

# Define aggregate region patterns to exclude
aggregate_patterns <- "^(All Denmark|Region |Province |Abroad|Christiansø)"

# Filter each dataset
n_before <- nrow(auk01)
auk01 <- auk01[!grepl(aggregate_patterns, municipality)]
cat(sprintf("  AUK01:  %d -> %d rows (dropped %d aggregate rows)\n",
            n_before, nrow(auk01), n_before - nrow(auk01)))

n_before <- nrow(auk01_sex)
auk01_sex <- auk01_sex[!grepl(aggregate_patterns, municipality)]
cat(sprintf("  AUK01 sex: %d -> %d rows\n", n_before, nrow(auk01_sex)))

n_before <- nrow(folk1c)
folk1c <- folk1c[!grepl(aggregate_patterns, municipality)]
cat(sprintf("  FOLK1C: %d -> %d rows\n", n_before, nrow(folk1c)))

n_before <- nrow(ras200)
ras200 <- ras200[!grepl(aggregate_patterns, municipality)]
cat(sprintf("  RAS200: %d -> %d rows\n", n_before, nrow(ras200)))

# INDKP111 is region-level (provinces/regions) — keep for national analysis
# but filter to just "All Denmark" for national-level income trends
indkp111_national <- indkp111[region == "All Denmark"]
cat(sprintf("  INDKP111 national: %d rows\n", nrow(indkp111_national)))

# Verify municipality count
n_muni <- length(unique(auk01$municipality))
cat(sprintf("\n  Unique municipalities in AUK01:  %d\n", n_muni))
cat(sprintf("  Unique municipalities in FOLK1C: %d\n",
            length(unique(folk1c$municipality))))
cat(sprintf("  Unique municipalities in RAS200: %d\n",
            length(unique(ras200$municipality))))

stopifnot("Expected 98-99 municipalities" = n_muni >= 98 & n_muni <= 100)

# ============================================================================
# 5. CREATE AGE GROUP CATEGORIES
# ============================================================================

cat("\n--- Creating age group variables ---\n")

# Map 5-year age bands to treatment groups
age_to_treat <- data.table(
  age = c("25-29 years", "30-34 years", "35-39 years",
          "40-44 years", "45-49 years",
          "50-54 years", "55-59 years"),
  treat_group = c(rep("High (25-39)", 3),
                  rep("Moderate (40-49)", 2),
                  rep("Control (50-59)", 2))
)

# Binary young indicator: 1 for 25-39, 0 for 50-59, NA for 40-49
age_to_treat[, young := fifelse(treat_group == "High (25-39)", 1L,
                                fifelse(treat_group == "Control (50-59)", 0L, NA_integer_))]

# Factor ordering for plots
age_to_treat[, treat_group := factor(treat_group,
                                     levels = c("High (25-39)", "Moderate (40-49)",
                                                "Control (50-59)"))]

# Merge into all datasets
auk01 <- merge(auk01, age_to_treat, by = "age", all.x = TRUE)
auk01_sex <- merge(auk01_sex, age_to_treat, by = "age", all.x = TRUE)
folk1c <- merge(folk1c, age_to_treat, by = "age", all.x = TRUE)
ras200 <- merge(ras200, age_to_treat, by = "age", all.x = TRUE)
indkp111_national <- merge(indkp111_national, age_to_treat,
                           by.x = "age", by.y = "age", all.x = TRUE)

# Drop any rows with unmatched age groups (e.g., "Total")
auk01 <- auk01[!is.na(treat_group)]
auk01_sex <- auk01_sex[!is.na(treat_group)]
folk1c <- folk1c[!is.na(treat_group)]
ras200 <- ras200[!is.na(treat_group)]
indkp111_national <- indkp111_national[!is.na(treat_group)]

cat(sprintf("  AUK01 after age filter:  %d rows\n", nrow(auk01)))
cat(sprintf("  FOLK1C after age filter: %d rows\n", nrow(folk1c)))

# ============================================================================
# 6. CREATE POST-REFORM AND EVENT TIME VARIABLES
# ============================================================================

cat("\n--- Creating post-reform and event time variables ---\n")

# Post indicator: 1 for quarters >= 2013Q1
auk01[, post := as.integer(year > 2013 | (year == 2013 & quarter >= 1))]
auk01_sex[, post := as.integer(year > 2013 | (year == 2013 & quarter >= 1))]
folk1c[, post := as.integer(year > 2013 | (year == 2013 & quarter >= 1))]

# Event time: quarters relative to 2013Q1 (= 0)
# 2012Q4 = -1, 2013Q1 = 0, 2013Q2 = 1, etc.
reform_yq <- 2013 + 0/4  # 2013Q1 = 2013.00
auk01[, event_time := as.integer(round((yq - reform_yq) * 4))]
auk01_sex[, event_time := as.integer(round((yq - reform_yq) * 4))]
folk1c[, event_time := as.integer(round((yq - reform_yq) * 4))]

# For annual data: years relative to 2013
ras200[, post := as.integer(year >= 2013)]
ras200[, event_time := year - 2013L]

indkp111_national[, post := as.integer(year >= 2013)]
indkp111_national[, event_time := year - 2013L]

cat(sprintf("  Event time range (quarterly): %d to %d\n",
            min(auk01$event_time), max(auk01$event_time)))
cat(sprintf("  Event time range (annual):    %d to %d\n",
            min(ras200$event_time), max(ras200$event_time)))

# Verify post coding
stopifnot(auk01[time == "2012Q4", unique(post)] == 0L)
stopifnot(auk01[time == "2013Q1", unique(post)] == 1L)
stopifnot(auk01[time == "2012Q4", unique(event_time)] == -1L)
stopifnot(auk01[time == "2013Q1", unique(event_time)] == 0L)

# ============================================================================
# 7. ENSURE NUMERIC VALUES
# ============================================================================

cat("\n--- Ensuring numeric values ---\n")

# AUK01 value (benefit recipients count)
auk01[, value := as.numeric(value)]
auk01_sex[, value := as.numeric(value)]

# FOLK1C population
folk1c[, population := as.numeric(population)]

# RAS200 employment rate
ras200[, emp_rate := as.numeric(emp_rate)]

# INDKP111 income
indkp111_national[, income := as.numeric(income)]

# Check for NAs introduced by coercion
n_na_auk <- sum(is.na(auk01$value))
n_na_pop <- sum(is.na(folk1c$population))
n_na_emp <- sum(is.na(ras200$emp_rate))
cat(sprintf("  NAs in AUK01 value:     %d\n", n_na_auk))
cat(sprintf("  NAs in FOLK1C pop:      %d\n", n_na_pop))
cat(sprintf("  NAs in RAS200 emp_rate: %d\n", n_na_emp))

# ============================================================================
# 8. MERGE BENEFITS WITH POPULATION -> RATES PER 1000
# ============================================================================

cat("\n--- Merging benefits with population data ---\n")

# Population: municipality x age x quarter (FOLK1C starts 2008Q1)
pop <- folk1c[, .(municipality, age, time, year, quarter, population)]

# Benefits: municipality x age x quarter x benefit_code
# Merge on municipality + age + time
panel <- merge(auk01, pop,
               by = c("municipality", "age", "time", "year", "quarter"),
               all.x = TRUE)

cat(sprintf("  Merged panel: %d rows\n", nrow(panel)))
cat(sprintf("  Rows with missing population: %d\n", sum(is.na(panel$population))))

# Drop rows before 2008 (FOLK1C starts 2008Q1) where population is missing
panel <- panel[!is.na(population)]
cat(sprintf("  Panel after dropping pre-2008: %d rows\n", nrow(panel)))

# Compute rate per 1000 population
panel[, rate_per_1000 := (value / population) * 1000]

# Check for infinite or NA rates (population = 0 edge case)
panel[population == 0, rate_per_1000 := NA_real_]
cat(sprintf("  Rows with NA rate: %d\n", sum(is.na(panel$rate_per_1000))))

# ============================================================================
# 9. CREATE HIGH BASELINE DISABILITY MUNICIPALITY INDICATOR (DDD)
# ============================================================================

cat("\n--- Computing baseline disability rates for DDD ---\n")

# Baseline period: 2008-2012 (pre-reform)
# Focus: disability pension (FP) for 25-39 year olds (high-intensity group)
baseline_dp <- panel[benefit_code == "FP" & treat_group == "High (25-39)" &
                       year >= 2008 & year <= 2012,
                     .(mean_dp_rate = mean(rate_per_1000, na.rm = TRUE)),
                     by = .(municipality)]

# Median baseline disability rate
median_dp <- median(baseline_dp$mean_dp_rate, na.rm = TRUE)
cat(sprintf("  Median baseline DP rate (25-39, 2008-2012): %.2f per 1000\n", median_dp))

# Binary indicator: above-median baseline disability pension rate
baseline_dp[, high_base_dp := as.integer(mean_dp_rate > median_dp)]
cat(sprintf("  High baseline DP municipalities: %d\n", sum(baseline_dp$high_base_dp)))
cat(sprintf("  Low baseline DP municipalities:  %d\n", sum(1L - baseline_dp$high_base_dp)))

# Merge into panel
panel <- merge(panel, baseline_dp[, .(municipality, mean_dp_rate, high_base_dp)],
               by = "municipality", all.x = TRUE)

# ============================================================================
# 10. RESHAPE TO WIDE FORMAT FOR BENEFIT TYPES
# ============================================================================

cat("\n--- Creating wide-format benefit panel ---\n")

# Keep key columns and cast benefit rates wide
panel_long <- panel[, .(municipality, age, time, year, quarter, yq,
                         treat_group, young, post, event_time,
                         benefit_code, value, population, rate_per_1000,
                         high_base_dp, mean_dp_rate)]

# Wide format: one row per municipality x age x quarter
# with separate columns for each benefit type rate
panel_wide <- dcast(panel_long,
                    municipality + age + time + year + quarter + yq +
                      treat_group + young + post + event_time +
                      population + high_base_dp + mean_dp_rate ~
                      benefit_code,
                    value.var = c("rate_per_1000", "value"),
                    fun.aggregate = mean, fill = NA_real_)

# Rename rate columns for clarity
rate_cols <- grep("^rate_per_1000_", names(panel_wide), value = TRUE)
new_rate_names <- gsub("^rate_per_1000_", "rate_", tolower(rate_cols))
setnames(panel_wide, rate_cols, new_rate_names)

# Rename count columns
count_cols <- grep("^value_", names(panel_wide), value = TRUE)
new_count_names <- gsub("^value_", "n_", tolower(count_cols))
setnames(panel_wide, count_cols, new_count_names)

cat(sprintf("  Wide panel: %d rows, %d columns\n", nrow(panel_wide), ncol(panel_wide)))

# ============================================================================
# 11. CLEAN EMPLOYMENT PANEL
# ============================================================================

cat("\n--- Cleaning employment panel ---\n")

# RAS200 already filtered to municipalities
panel_emp <- ras200[, .(municipality, age, year, emp_rate, treat_group, young,
                         post, event_time)]

# Merge in baseline DP indicator for DDD with employment
panel_emp <- merge(panel_emp,
                   baseline_dp[, .(municipality, high_base_dp, mean_dp_rate)],
                   by = "municipality", all.x = TRUE)

cat(sprintf("  Employment panel: %d rows\n", nrow(panel_emp)))

# ============================================================================
# 12. CREATE NATIONAL-LEVEL PANEL (age x quarter, collapsed across municipalities)
# ============================================================================

cat("\n--- Creating national-level panel ---\n")

# Aggregate benefits across municipalities by age x quarter x benefit type
national <- panel_long[, .(total_recipients = sum(value, na.rm = TRUE),
                           total_pop = sum(population, na.rm = TRUE)),
                       by = .(age, time, year, quarter, yq, treat_group, young,
                              post, event_time, benefit_code)]

national[, rate_per_1000 := (total_recipients / total_pop) * 1000]

# Wide format
national_wide <- dcast(national,
                       age + time + year + quarter + yq +
                         treat_group + young + post + event_time ~
                         benefit_code,
                       value.var = c("rate_per_1000", "total_recipients", "total_pop"),
                       fun.aggregate = mean, fill = NA_real_)

# Rename rate columns
rate_cols_nat <- grep("^rate_per_1000_", names(national_wide), value = TRUE)
new_rate_nat <- gsub("^rate_per_1000_", "rate_", tolower(rate_cols_nat))
setnames(national_wide, rate_cols_nat, new_rate_nat)

# Take just one total_pop column (they are identical across benefit types)
pop_cols <- grep("^total_pop_", names(national_wide), value = TRUE)
if (length(pop_cols) > 0) {
  national_wide[, total_pop := get(pop_cols[1])]
  national_wide[, (pop_cols) := NULL]
}

# Rename recipient count columns
recip_cols <- grep("^total_recipients_", names(national_wide), value = TRUE)
new_recip_names <- gsub("^total_recipients_", "n_", tolower(recip_cols))
setnames(national_wide, recip_cols, new_recip_names)

cat(sprintf("  National panel: %d rows, %d columns\n",
            nrow(national_wide), ncol(national_wide)))

# ============================================================================
# 13. SUMMARY STATISTICS
# ============================================================================

cat("\n--- Computing summary statistics ---\n")

# Pre-reform period (2008-2012) means by treatment group
pre_reform <- panel_long[year >= 2008 & year <= 2012 & benefit_code == "FP"]

summary_by_group <- pre_reform[, .(
  mean_dp_rate = mean(rate_per_1000, na.rm = TRUE),
  sd_dp_rate = sd(rate_per_1000, na.rm = TRUE),
  mean_pop = mean(population, na.rm = TRUE),
  n_obs = .N,
  n_muni = uniqueN(municipality)
), by = .(treat_group)]

# Add flex job rates
pre_flex <- panel_long[year >= 2008 & year <= 2012 & benefit_code == "FL"]
flex_by_group <- pre_flex[, .(mean_flex_rate = mean(rate_per_1000, na.rm = TRUE),
                              sd_flex_rate = sd(rate_per_1000, na.rm = TRUE)),
                          by = .(treat_group)]

summary_by_group <- merge(summary_by_group, flex_by_group, by = "treat_group")

# Add cash benefits
pre_cash <- panel_long[year >= 2008 & year <= 2012 & benefit_code == "KH"]
cash_by_group <- pre_cash[, .(mean_cash_rate = mean(rate_per_1000, na.rm = TRUE),
                              sd_cash_rate = sd(rate_per_1000, na.rm = TRUE)),
                          by = .(treat_group)]

summary_by_group <- merge(summary_by_group, cash_by_group, by = "treat_group")

# Add employment rates (pre-reform)
pre_emp <- panel_emp[year >= 2008 & year <= 2012]
emp_by_group <- pre_emp[, .(mean_emp_rate = mean(emp_rate, na.rm = TRUE),
                            sd_emp_rate = sd(emp_rate, na.rm = TRUE)),
                        by = .(treat_group)]

summary_by_group <- merge(summary_by_group, emp_by_group, by = "treat_group")

# Also compute high_base_dp vs low split
summary_ddd <- pre_reform[!is.na(high_base_dp),
                          .(mean_dp_rate = mean(rate_per_1000, na.rm = TRUE),
                            sd_dp_rate = sd(rate_per_1000, na.rm = TRUE),
                            n_muni = uniqueN(municipality)),
                          by = .(treat_group, high_base_dp)]

cat("\nPre-reform summary by treatment group:\n")
print(summary_by_group)
cat("\nPre-reform summary by treatment group x baseline DP:\n")
print(summary_ddd)

# ============================================================================
# 14. SAVE CLEANED PANELS
# ============================================================================

cat("\n--- Saving cleaned datasets ---\n")

# panel_benefits.csv: municipality x age x quarter with rates per 1000
fwrite(panel_wide, file.path(DATA_DIR, "panel_benefits.csv"))
cat(sprintf("  panel_benefits.csv: %d rows, %d cols\n",
            nrow(panel_wide), ncol(panel_wide)))

# panel_employment.csv: municipality x age x year with employment rates
fwrite(panel_emp, file.path(DATA_DIR, "panel_employment.csv"))
cat(sprintf("  panel_employment.csv: %d rows, %d cols\n",
            nrow(panel_emp), ncol(panel_emp)))

# panel_national.csv: national age x quarter aggregates
fwrite(national_wide, file.path(DATA_DIR, "panel_national.csv"))
cat(sprintf("  panel_national.csv: %d rows, %d cols\n",
            nrow(national_wide), ncol(national_wide)))

# summary_stats.csv
fwrite(summary_by_group, file.path(DATA_DIR, "summary_stats.csv"))
cat(sprintf("  summary_stats.csv: %d rows\n", nrow(summary_by_group)))

# ============================================================================
# 15. FINAL VALIDATION
# ============================================================================

cat("\n=== Final Validation ===\n")

# Check panel structure
stopifnot("Panel has 98 municipalities" =
            uniqueN(panel_wide$municipality) == 98)
stopifnot("Panel has 7 age groups" =
            uniqueN(panel_wide$age) == 7)
stopifnot("Panel has 3 treatment groups" =
            uniqueN(panel_wide$treat_group) == 3)
stopifnot("Event time 0 = 2013Q1" =
            panel_wide[event_time == 0, unique(time)] == "2013Q1")
stopifnot("Post = 0 before reform" =
            all(panel_wide[time == "2012Q4", post] == 0))
stopifnot("Post = 1 at reform" =
            all(panel_wide[time == "2013Q1", post] == 1))
stopifnot("high_base_dp is binary" =
            all(panel_wide$high_base_dp %in% c(0L, 1L)))
stopifnot("DP rate is non-negative" =
            all(panel_wide$rate_fp >= 0, na.rm = TRUE))

# Summary
cat(sprintf("\n  Panel dimensions:   %d muni x %d ages x %d quarters = %d obs\n",
            uniqueN(panel_wide$municipality),
            uniqueN(panel_wide$age),
            uniqueN(panel_wide$time),
            nrow(panel_wide)))
cat(sprintf("  Time coverage:      %s to %s\n",
            min(panel_wide$time), max(panel_wide$time)))
cat(sprintf("  Benefit types:      %s\n",
            paste(grep("^rate_", names(panel_wide), value = TRUE), collapse = ", ")))
cat(sprintf("  Employment panel:   %d obs (%d muni x %d ages x %d years)\n",
            nrow(panel_emp),
            uniqueN(panel_emp$municipality),
            uniqueN(panel_emp$age),
            uniqueN(panel_emp$year)))
cat(sprintf("  National panel:     %d obs\n", nrow(national_wide)))

cat("\n02_clean_data.R complete.\n")
