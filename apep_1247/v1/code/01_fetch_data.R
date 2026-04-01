# =============================================================================
# 01_fetch_data.R — Fetch IPEDS enrollment + financial aid data
# ARRA Pell Grant expansion and racial enrollment at community colleges
# =============================================================================

source("00_packages.R")

# ---- 1. Connect to existing IPEDS DuckDB ----
ipeds_path <- "../../../apep_1237/v1/data/ipeds.duckdb"
if (!file.exists(ipeds_path)) {
  candidates <- c("../../../apep_0859/v1/data/ipeds.duckdb",
                   "../../../apep_0858/v1/data/ipeds.duckdb",
                   "../../../apep_0794/v1/data/ipeds.duckdb")
  for (cand in candidates) if (file.exists(cand)) { ipeds_path <- cand; break }
}
stopifnot("IPEDS DuckDB not found" = file.exists(ipeds_path))
message("Using IPEDS DuckDB: ", ipeds_path)

ipeds_con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ipeds_path, read_only = TRUE)

# ---- 2. Institutional directory ----
message("Fetching 2-year public institutions...")
inst_dir <- DBI::dbGetQuery(ipeds_con, "
  SELECT DISTINCT unitid, institution_name, state, county_fips, sector, hbcu
  FROM hd
  WHERE sector IN (4, 5)
    AND year = 2008
")
message(sprintf("  %d institutions in 2-year public sector (2008 snapshot)", nrow(inst_dir)))

# ---- 3. Enrollment by race — harmonized across IPEDS race reporting change ----
# Pre-2008: fyrace03 (Black NH), fyrace06 (Hispanic), fyrace07 (White NH)
# 2008-2010: dveybkt (derived Black), dveyhst (derived Hispanic), dveywht (derived White)
# 2011+: efybkaat (Black), efyhispt (Hispanic), efywhitt (White)

message("Fetching enrollment (harmonized across race reporting change)...")

# Pre-2008 (old race categories)
enroll_pre <- DBI::dbGetQuery(ipeds_con, "
  SELECT e.unitid, e.year,
         e.fyrace15 AS enroll_total,
         e.fyrace03 AS enroll_black,
         e.fyrace06 AS enroll_hisp,
         e.fyrace07 AS enroll_white
  FROM effy e
  JOIN hd h ON e.unitid = h.unitid AND e.year = h.year
  WHERE h.sector IN (4, 5)
    AND e.effylev = 1
    AND e.year BETWEEN 2002 AND 2007
")

# 2008-2010 (transition: use derived bridged estimates)
enroll_trans <- DBI::dbGetQuery(ipeds_con, "
  SELECT e.unitid, e.year,
         e.efytotlt AS enroll_total,
         e.dveybkt AS enroll_black,
         e.dveyhst AS enroll_hisp,
         e.dveywht AS enroll_white
  FROM effy e
  JOIN hd h ON e.unitid = h.unitid AND e.year = h.year
  WHERE h.sector IN (4, 5)
    AND e.effylev = 1
    AND e.year BETWEEN 2008 AND 2010
")

# 2011-2015 (new race categories)
enroll_post <- DBI::dbGetQuery(ipeds_con, "
  SELECT e.unitid, e.year,
         e.efytotlt AS enroll_total,
         e.efybkaat AS enroll_black,
         e.efyhispt AS enroll_hisp,
         e.efywhitt AS enroll_white
  FROM effy e
  JOIN hd h ON e.unitid = h.unitid AND e.year = h.year
  WHERE h.sector IN (4, 5)
    AND e.effylev = 1
    AND e.year BETWEEN 2011 AND 2015
")

enrollment_raw <- rbind(enroll_pre, enroll_trans, enroll_post)
message(sprintf("  Enrollment: %d obs across %d-%d, %d institutions",
                nrow(enrollment_raw), min(enrollment_raw$year), max(enrollment_raw$year),
                length(unique(enrollment_raw$unitid))))

# ---- 4. Student Financial Aid (Pell) ----
message("Fetching SFA/Pell data...")
sfa_raw <- DBI::dbGetQuery(ipeds_con, "
  SELECT s.unitid, s.year,
         s.upgrntp AS pell_n,
         s.upgrntt AS pell_total,
         s.scugrad AS sfa_undergrad,
         s.fgrnt_p AS pct_fed_grant,
         s.pgrnt_p AS pct_pell
  FROM sfa s
  JOIN hd h ON s.unitid = h.unitid AND s.year = h.year
  WHERE h.sector IN (4, 5)
    AND s.year BETWEEN 2002 AND 2015
")
message(sprintf("  SFA: %d obs", nrow(sfa_raw)))

DBI::dbDisconnect(ipeds_con, shutdown = TRUE)

# ---- 5. Save ----
saveRDS(inst_dir, "../data/inst_directory.rds")
saveRDS(enrollment_raw, "../data/enrollment_raw.rds")
saveRDS(sfa_raw, "../data/sfa_raw.rds")

message("\n=== Data Fetch Summary ===")
message(sprintf("Institutions: %d", nrow(inst_dir)))
message(sprintf("Enrollment obs: %d (%d-%d)", nrow(enrollment_raw),
                min(enrollment_raw$year), max(enrollment_raw$year)))
message(sprintf("SFA obs: %d", nrow(sfa_raw)))
