# ==============================================================================
# 01_fetch_data.R — Extract IPEDS data from DuckDB
# Paper: The Admissions Illusion (apep_1113)
# ==============================================================================

source("00_packages.R")

# Connect to IPEDS DuckDB
db_path <- file.path("..", "..", "..", "..", "data", "ipeds", "ipeds.duckdb")
stopifnot("IPEDS DuckDB not found" = file.exists(db_path))
con <- dbConnect(duckdb(), db_path, read_only = TRUE)

cat("Connected to IPEDS DuckDB\n")

# --- 1. Enrollment by race (12-month unduplicated headcount) ---
# effylev = 2: undergraduate; lstudy = 1: undergraduate level
enroll <- dbGetQuery(con, "
  SELECT unitid, year,
    efytotlt AS total_enroll,
    efybkaat AS black_enroll,
    efyhispt AS hispanic_enroll,
    efyasiat AS asian_enroll,
    efywhitt AS white_enroll,
    efyaiant AS aian_enroll,
    efynhpit AS nhpi_enroll,
    efy2mort AS two_more_enroll,
    efyunknt AS unknown_enroll,
    efynralt AS nonres_enroll
  FROM effy
  WHERE effylev = 2 AND lstudy = 1
    AND year BETWEEN 2017 AND 2024
")

cat(sprintf("Enrollment: %d rows, %d institutions, years %d-%d\n",
    nrow(enroll), n_distinct(enroll$unitid),
    min(enroll$year), max(enroll$year)))

# --- 2. Admission rates (for treatment intensity) ---
admit <- dbGetQuery(con, "
  SELECT unitid, year,
    institution_name,
    state,
    admit_rate_pct,
    applicants_total,
    admissions_total,
    enrolled_total
  FROM v_admission_rates
  WHERE year BETWEEN 2019 AND 2023
")

cat(sprintf("Admission rates: %d rows, %d institutions\n",
    nrow(admit), n_distinct(admit$unitid)))

# --- 3. Institution characteristics ---
hd <- dbGetQuery(con, "
  SELECT DISTINCT unitid, institution_name, state, sector, control,
    hbcu, tribal, instcat
  FROM hd
  WHERE year = (SELECT MAX(year) FROM hd)
")

cat(sprintf("Institution characteristics: %d institutions\n", nrow(hd)))

dbDisconnect(con, shutdown = TRUE)

# --- Validate data ---
stopifnot("No enrollment data" = nrow(enroll) > 0)
stopifnot("No admission data" = nrow(admit) > 0)
stopifnot("No HD data" = nrow(hd) > 0)
stopifnot("Enrollment missing 2024" = 2024 %in% enroll$year)

# Save raw extracts
saveRDS(enroll, "../data/enroll_raw.rds")
saveRDS(admit, "../data/admit_raw.rds")
saveRDS(hd, "../data/hd_raw.rds")

cat("Data extraction complete. Files saved to data/\n")
