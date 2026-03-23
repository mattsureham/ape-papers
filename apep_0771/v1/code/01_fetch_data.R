# ==============================================================================
# 01_fetch_data.R — Data Acquisition from Azure
# Paper: When the Campus Goes Dark (apep_0771)
# ==============================================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

con <- apep_azure_connect()

# ---- 1. IPEDS: Identify for-profit closures by county ----
cat("Attaching IPEDS DuckDB...\n")
dbExecute(con, "ATTACH 'az://raw/ipeds/ipeds.duckdb' AS ipeds (READ_ONLY);")

cat("Querying IPEDS for for-profit institutions...\n")
ipeds_closures <- dbGetQuery(con, "
  SELECT unitid, institution_name AS instnm, city, state AS stabbr,
         fips_state AS state_fips, county_fips, sector, deathyr,
         close_date AS closedat, currently_active AS cyactive,
         longitude AS longitud, latitude, year
  FROM ipeds.hd
  WHERE sector IN (3, 6, 9)
")
cat(sprintf("  IPEDS for-profit institution-years: %d rows\n", nrow(ipeds_closures)))
stopifnot(nrow(ipeds_closures) > 0)

# ---- 2. IPEDS: Enrollment (for intensity measure) ----
cat("Querying IPEDS for enrollment data...\n")
ipeds_enrollment <- dbGetQuery(con, "
  SELECT unitid, year, efytotlt AS total_enrollment
  FROM ipeds.effy
  WHERE efytotlt IS NOT NULL AND efytotlt > 0
")
cat(sprintf("  IPEDS enrollment records: %d rows\n", nrow(ipeds_enrollment)))

dbExecute(con, "DETACH ipeds;")

# ---- 3. QWI: County x Quarter x NAICS Sector employment ----
cat("Querying QWI for county x quarter x sector employment...\n")

qwi_raw <- dbGetQuery(con, "
  SELECT geography, year, quarter, industry,
         \"Emp\" AS emp, \"EmpEnd\" AS emp_end,
         \"HirA\" AS hir_a, \"HirN\" AS hir_n,
         \"Sep\" AS sep, \"EarnS\" AS earn_s,
         \"FrmJbGn\" AS frm_jb_gn, \"FrmJbLs\" AS frm_jb_ls
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE sex = '0' AND agegrp = 'A00'
    AND industry IN ('61', '62', '72', '00')
    AND year BETWEEN 2008 AND 2022
")
cat(sprintf("  QWI records: %d rows\n", nrow(qwi_raw)))

stopifnot(nrow(qwi_raw) > 0)
stopifnot(all(c("geography", "year", "quarter", "industry", "emp") %in% names(qwi_raw)))

apep_azure_disconnect(con)

# ---- 4. Save raw data ----
saveRDS(ipeds_closures, "../data/ipeds_closures_raw.rds")
saveRDS(ipeds_enrollment, "../data/ipeds_enrollment_raw.rds")
saveRDS(qwi_raw, "../data/qwi_raw.rds")

cat("Data fetch complete. Files saved to data/\n")
cat(sprintf("  IPEDS closures: %.1f MB\n", file.size("../data/ipeds_closures_raw.rds") / 1e6))
cat(sprintf("  IPEDS enrollment: %.1f MB\n", file.size("../data/ipeds_enrollment_raw.rds") / 1e6))
cat(sprintf("  QWI: %.1f MB\n", file.size("../data/qwi_raw.rds") / 1e6))
