# =============================================================================
# 01_fetch_data.R — Fetch IPEDS data from local DuckDB (downloaded from Azure)
# APEP Paper apep_0794: Testing Without Tests
# =============================================================================

source("00_packages.R")

db_path <- "../data/ipeds.duckdb"
stopifnot(file.exists(db_path))

con <- dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
cat("Connected to IPEDS DuckDB.\n")

# List available tables
tables <- dbListTables(con)
cat("Available tables:", paste(tables, collapse = ", "), "\n")

# ---- 1. Admissions data (adm) -----------------------------------------------
cat("Fetching admissions data...\n")
adm <- dbGetQuery(con, "
  SELECT *
  FROM adm
  WHERE year >= 2014 AND year <= 2023
")
cat(sprintf("  adm: %d rows, %d cols\n", nrow(adm), ncol(adm)))
if (nrow(adm) == 0) stop("FATAL: adm table returned 0 rows.")

# ---- 2. Enrollment by race (ef_a) -------------------------------------------
cat("Fetching enrollment by race...\n")
ef <- dbGetQuery(con, "
  SELECT *
  FROM ef_a
  WHERE year >= 2014 AND year <= 2023
")
cat(sprintf("  ef_a: %d rows, %d cols\n", nrow(ef), ncol(ef)))
if (nrow(ef) == 0) stop("FATAL: ef_a table returned 0 rows.")

# ---- 3. Student financial aid (sfa) -----------------------------------------
cat("Fetching financial aid data...\n")
sfa <- dbGetQuery(con, "
  SELECT *
  FROM sfa
  WHERE year >= 2014 AND year <= 2023
")
cat(sprintf("  sfa: %d rows, %d cols\n", nrow(sfa), ncol(sfa)))
if (nrow(sfa) == 0) stop("FATAL: sfa table returned 0 rows.")

# ---- 4. Institutional characteristics (ic) -----------------------------------
cat("Fetching institutional characteristics...\n")
ic <- dbGetQuery(con, "
  SELECT *
  FROM ic
  WHERE year >= 2014 AND year <= 2023
")
cat(sprintf("  ic: %d rows, %d cols\n", nrow(ic), ncol(ic)))
if (nrow(ic) == 0) stop("FATAL: ic table returned 0 rows.")

# ---- 5. HD (institutional directory) ----------------------------------------
cat("Fetching institutional directory...\n")
hd <- dbGetQuery(con, "
  SELECT *
  FROM hd
  WHERE year >= 2014 AND year <= 2023
")
cat(sprintf("  hd: %d rows, %d cols\n", nrow(hd), ncol(hd)))
if (nrow(hd) == 0) stop("FATAL: hd table returned 0 rows.")

dbDisconnect(con, shutdown = TRUE)

# ---- Save raw data -----------------------------------------------------------
saveRDS(adm, "../data/adm_raw.rds")
saveRDS(ef,  "../data/ef_raw.rds")
saveRDS(sfa, "../data/sfa_raw.rds")
saveRDS(ic,  "../data/ic_raw.rds")
saveRDS(hd,  "../data/hd_raw.rds")

cat("All data saved to ../data/\n")
