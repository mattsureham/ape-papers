## 01_fetch_data.R — Data acquisition from Eurostat
## apep_0723: EU Youth Employment Initiative RDD
## REAL DATA ONLY — no simulated fallbacks

source("00_packages.R")

# ============================================================
# 1. YOUTH UNEMPLOYMENT RATE — RUNNING VARIABLE
#    yth_empl_110: Youth unemployment by NUTS2, ages 15-24
# ============================================================

cat("Fetching youth unemployment rate (yth_empl_110) from Eurostat...\n")

yth_unemp_raw <- tryCatch({
  df <- eurostat::get_eurostat("yth_empl_110", time_format = "num")
  if (is.null(df) || nrow(df) == 0) stop("No data returned from yth_empl_110")
  df
}, error = function(e) {
  stop(sprintf("FATAL: Could not fetch yth_empl_110 from Eurostat: %s", e$message))
})

cat(sprintf("yth_empl_110 rows: %d\n", nrow(yth_unemp_raw)))
cat(sprintf("Variables: %s\n", paste(names(yth_unemp_raw), collapse=", ")))
cat(sprintf("Time range: %s\n", paste(range(yth_unemp_raw$TIME_PERIOD, na.rm=TRUE), collapse=" to ")))
cat(sprintf("Geo codes sample: %s\n", paste(head(unique(yth_unemp_raw$geo), 10), collapse=", ")))

saveRDS(yth_unemp_raw, "../data/yth_unemp_raw.rds")
cat("Youth unemployment raw data saved.\n")

# ============================================================
# 2. NEET RATE — PRIMARY OUTCOME
#    edat_lfse_22: Young people neither in employment, education or training
#    Ages 18-24, by NUTS2 region
# ============================================================

cat("\nFetching NEET rate (edat_lfse_22) from Eurostat...\n")

neet_raw <- tryCatch({
  df <- eurostat::get_eurostat("edat_lfse_22", time_format = "num")
  if (is.null(df) || nrow(df) == 0) stop("No data returned from edat_lfse_22")
  df
}, error = function(e) {
  stop(sprintf("FATAL: Could not fetch edat_lfse_22 from Eurostat: %s", e$message))
})

cat(sprintf("edat_lfse_22 rows: %d\n", nrow(neet_raw)))
cat(sprintf("Variables: %s\n", paste(names(neet_raw), collapse=", ")))
cat(sprintf("Time range: %s\n", paste(range(neet_raw$TIME_PERIOD, na.rm=TRUE), collapse=" to ")))

saveRDS(neet_raw, "../data/neet_raw.rds")
cat("NEET raw data saved.\n")

# ============================================================
# 3. YOUTH EMPLOYMENT RATE — SECONDARY OUTCOME
#    lfst_r_lfe2emprt: Employment rates by NUTS2, sex, age, time
#    Ages 15-24
# ============================================================

cat("\nFetching employment rate (lfst_r_lfe2emprt) from Eurostat...\n")

emp_rate_raw <- tryCatch({
  df <- eurostat::get_eurostat("lfst_r_lfe2emprt", time_format = "num")
  if (is.null(df) || nrow(df) == 0) stop("No data returned from lfst_r_lfe2emprt")
  df
}, error = function(e) {
  stop(sprintf("FATAL: Could not fetch lfst_r_lfe2emprt from Eurostat: %s", e$message))
})

cat(sprintf("lfst_r_lfe2emprt rows: %d\n", nrow(emp_rate_raw)))
cat(sprintf("Variables: %s\n", paste(names(emp_rate_raw), collapse=", ")))
cat(sprintf("Time range: %s\n", paste(range(emp_rate_raw$TIME_PERIOD, na.rm=TRUE), collapse=" to ")))

saveRDS(emp_rate_raw, "../data/emp_rate_raw.rds")
cat("Employment rate raw data saved.\n")

# ============================================================
# 4. EARLY SCHOOL LEAVING — SECONDARY OUTCOME
#    edat_lfse_16: Early leavers from education and training by NUTS2
# ============================================================

cat("\nFetching early school leaving rate (edat_lfse_16) from Eurostat...\n")

esl_raw <- tryCatch({
  df <- eurostat::get_eurostat("edat_lfse_16", time_format = "num")
  if (is.null(df) || nrow(df) == 0) stop("No data returned from edat_lfse_16")
  df
}, error = function(e) {
  stop(sprintf("FATAL: Could not fetch edat_lfse_16 from Eurostat: %s", e$message))
})

cat(sprintf("edat_lfse_16 rows: %d\n", nrow(esl_raw)))
cat(sprintf("Variables: %s\n", paste(names(esl_raw), collapse=", ")))
cat(sprintf("Time range: %s\n", paste(range(esl_raw$TIME_PERIOD, na.rm=TRUE), collapse=" to ")))

saveRDS(esl_raw, "../data/esl_raw.rds")
cat("Early school leaving raw data saved.\n")

# ============================================================
# 5. VALIDATION
# ============================================================

cat("\n=== DATA FETCH SUMMARY ===\n")
cat(sprintf("Youth unemployment (yth_empl_110): %d rows, %d geo codes\n",
            nrow(yth_unemp_raw), length(unique(yth_unemp_raw$geo))))
cat(sprintf("NEET rate (edat_lfse_22): %d rows, %d geo codes\n",
            nrow(neet_raw), length(unique(neet_raw$geo))))
cat(sprintf("Employment rate (lfst_r_lfe2emprt): %d rows, %d geo codes\n",
            nrow(emp_rate_raw), length(unique(emp_rate_raw$geo))))
cat(sprintf("Early school leaving (edat_lfse_16): %d rows, %d geo codes\n",
            nrow(esl_raw), length(unique(esl_raw$geo))))

# Check that 2012 unemployment data is present (needed for running variable)
unemp_2012_check <- yth_unemp_raw %>% filter(TIME_PERIOD == 2012)
cat(sprintf("\n2012 youth unemployment obs: %d geo codes\n", length(unique(unemp_2012_check$geo))))

if (nrow(unemp_2012_check) == 0) {
  stop("FATAL: No 2012 youth unemployment data found — running variable cannot be constructed")
}

cat("\nData fetch complete.\n")
