# =============================================================================
# 01_fetch_data.R — Fetch IPEDS + QWI data from Azure
# =============================================================================

source("00_packages.R")

# Fix: read Azure connection string directly from .env (bash truncates at semicolons)
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (startsWith(line, "AZURE_STORAGE_CONNECTION_STRING=")) {
    val <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    val <- gsub('^["\'](.*)["\']$', "\\1", val)
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    break
  }
}

con <- apep_azure_connect()

# ---- IPEDS: Attach local DuckDB copy ----
message("Attaching IPEDS DuckDB (local copy)...")
ipeds_con <- DBI::dbConnect(duckdb::duckdb(), dbdir = "../data/ipeds.duckdb", read_only = TRUE)

# ---- 1. IPEDS: Identify HBCU institutions and their counties ----
message("Fetching HBCU institution directory from IPEDS...")
hbcu_dir <- DBI::dbGetQuery(ipeds_con, "
  SELECT unitid, institution_name, state, county_fips, control, hbcu
  FROM hd
  WHERE hbcu = 1 AND year = 2010
")
stopifnot("No HBCU data returned" = nrow(hbcu_dir) > 0)
message(sprintf("  Found %d HBCU institutions in %d unique counties",
                nrow(hbcu_dir), n_distinct(hbcu_dir$county_fips)))

# ---- 2. IPEDS: Enrollment by HBCU institution (2005-2020) ----
message("Fetching HBCU enrollment trends (effy)...")
hbcu_enroll <- DBI::dbGetQuery(ipeds_con, "
  SELECT e.unitid, e.year, e.efytotlt, e.efytotlm, e.efytotlw
  FROM effy e
  JOIN hd h ON e.unitid = h.unitid AND e.year = h.year
  WHERE h.hbcu = 1 AND e.effylev = 1 AND e.year BETWEEN 2005 AND 2020
")
stopifnot("No enrollment data" = nrow(hbcu_enroll) > 0)
message(sprintf("  Enrollment data: %d institution-year obs", nrow(hbcu_enroll)))

# ---- 3. IPEDS: Institutional employment (eap) ----
message("Fetching HBCU institutional employment (eap)...")
hbcu_emp <- DBI::dbGetQuery(ipeds_con, "
  SELECT e.unitid, e.year, e.eaptot
  FROM eap e
  JOIN hd h ON e.unitid = h.unitid AND e.year = h.year
  WHERE h.hbcu = 1 AND e.year BETWEEN 2005 AND 2020
")

DBI::dbDisconnect(ipeds_con, shutdown = TRUE)
message(sprintf("  Employment data: %d institution-year obs", nrow(hbcu_emp)))

# ---- 4. Get county-year HBCU enrollment totals for treatment construction ----
hbcu_county_enroll <- hbcu_enroll %>%
  left_join(hbcu_dir %>% select(unitid, county_fips, state), by = "unitid") %>%
  filter(!is.na(county_fips) & county_fips != "") %>%
  group_by(county_fips, year) %>%
  summarize(
    hbcu_enrollment = sum(efytotlt, na.rm = TRUE),
    n_hbcus = n_distinct(unitid),
    .groups = "drop"
  )

message(sprintf("  County-year enrollment: %d obs, %d counties",
                nrow(hbcu_county_enroll), n_distinct(hbcu_county_enroll$county_fips)))

# ---- 5. QWI: Fetch county-quarter employment for all states ----
message("Fetching QWI data from Azure (all states, wildcard)...")

qwi_raw <- DBI::dbGetQuery(con, "
  SELECT geography, year, quarter, industry,
         Emp, EarnS, HirA, Sep
  FROM 'az://derived/qwi/rh/ns/*.parquet'
  WHERE industry IN ('00', '61', '72', '44-45', '11', '21')
    AND sex = '0' AND agegrp = 'A00'
    AND year BETWEEN 2005 AND 2020
    AND geo_level = 'C'
    AND ownercode = 'A05'
")

message(sprintf("  QWI data: %d county-quarter-industry obs", nrow(qwi_raw)))
stopifnot("QWI data is empty" = nrow(qwi_raw) > 0)

# ---- 6. Save raw data ----
saveRDS(hbcu_dir, "../data/hbcu_directory.rds")
saveRDS(hbcu_enroll, "../data/hbcu_enrollment.rds")
saveRDS(hbcu_emp, "../data/hbcu_inst_employment.rds")
saveRDS(hbcu_county_enroll, "../data/hbcu_county_enrollment.rds")
saveRDS(qwi_raw, "../data/qwi_raw.rds")

apep_azure_disconnect(con)
message("Data fetch complete. Files saved to data/")
