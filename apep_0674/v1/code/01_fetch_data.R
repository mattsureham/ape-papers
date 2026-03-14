## ============================================================
## 01_fetch_data.R — Extract IPEDS data from local DuckDB
## apep_0674: PBF and the Cream-Skimming Margin
## ============================================================

source("00_packages.R")

## ---- Connect to IPEDS DuckDB ----
ipeds_path <- file.path(here::here(), "data", "ipeds", "ipeds.duckdb")
stopifnot("IPEDS DuckDB not found" = file.exists(ipeds_path))

con <- dbConnect(duckdb::duckdb(), dbdir = ipeds_path, read_only = TRUE)
cat("Connected to IPEDS DuckDB\n")

## ---- 1. Institutional characteristics (hd) ----
hd <- dbGetQuery(con, "
  SELECT unitid, institution_name, state, sector, control,
         carnegie, c18basic, instcat, longitude, latitude, year
  FROM hd
  WHERE sector IN (1, 2, 3, 4, 5, 6, 7, 8)
")
cat("HD table:", nrow(hd), "rows\n")

## ---- 2. Completions by institution-year (c_a) ----
## Bachelor's degrees: award_level = 5, major_number = 1
comp <- dbGetQuery(con, "
  SELECT unitid, year, cipcode, award_level, major_number,
         ctotalt, ctotalm, ctotalw,
         cbkaat, chispt, cwhitt
  FROM c_a
  WHERE award_level = 5 AND major_number = 1
")
cat("Completions (bachelor's):", nrow(comp), "rows\n")

## ---- 3. Graduation rates (gr200) ----
gr <- dbGetQuery(con, "
  SELECT unitid, year, baac150, bagr150, baac200, bagr200
  FROM gr200
  WHERE bagr150 IS NOT NULL
")
cat("Graduation rates:", nrow(gr), "rows\n")

## ---- 4. Financial aid (sfa) — Pell grants ----
sfa <- dbGetQuery(con, "
  SELECT unitid, year,
         upgrntn, upgrntp, scugffn,
         uagrntn, uagrntp
  FROM sfa
")
cat("Student financial aid:", nrow(sfa), "rows\n")

## ---- 5. Enrollment by race/gender (ef_a) ----
efa <- dbGetQuery(con, "
  SELECT unitid, year, efalevel, line, section,
         eftotlt, eftotlm, eftotlw,
         efbkaat, efhispt, efwhitt, efasiat
  FROM ef_a
")
cat("Fall enrollment (ef_a):", nrow(efa), "rows\n")

## ---- 6. 12-month enrollment (effy) ----
effy <- dbGetQuery(con, "
  SELECT unitid, year, effylev, efytotlt, efytotlm, efytotlw
  FROM effy
")
cat("12-month enrollment (effy):", nrow(effy), "rows\n")

## ---- Disconnect ----
dbDisconnect(con, shutdown = TRUE)

## ---- Save extracted data ----
save(hd, comp, gr, sfa, efa, effy, file = "../data/ipeds_raw.RData")
cat("Saved all extracted data to data/ipeds_raw.RData\n")
