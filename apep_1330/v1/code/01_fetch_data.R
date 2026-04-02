# =============================================================================
# 01_fetch_data.R — Fetch IPEDS data from local DuckDB
# =============================================================================

source("00_packages.R")

ipeds_path <- normalizePath("../../../../data/ipeds/ipeds.duckdb")
stopifnot("IPEDS DuckDB not found" = file.exists(ipeds_path))

con <- dbConnect(duckdb())
dbExecute(con, sprintf("ATTACH '%s' AS ipeds (READ_ONLY)", ipeds_path))

# --- 1. Institutional directory (HD) ---
hd <- dbGetQuery(con, "
  SELECT unitid, year, institution_name, state, region, sector, control,
         hloffer, instcat, longitude, latitude, county_name, county_fips
  FROM ipeds.hd
  WHERE year BETWEEN 2015 AND 2022
    AND control = 1
    AND sector IN (1, 2, 4, 5)
")
cat(sprintf("HD: %d rows, %d institutions\n", nrow(hd), length(unique(hd$unitid))))

# --- 2. Finance (F1A) ---
# f1a01=total rev, f1a04=tuition rev, f1a05=federal operating grants,
# f1a06=state operating grants, f1a14=federal nonoperating grants,
# f1a15=state appropriations (nonoperating), f1a18=other nonoperating rev
f1a <- dbGetQuery(con, "
  SELECT unitid, year, f1a01, f1a04, f1a05, f1a06, f1a14, f1a15, f1a18,
         f1a31
  FROM ipeds.f1a
  WHERE year BETWEEN 2015 AND 2022
")
cat(sprintf("F1A (finance): %d rows\n", nrow(f1a)))

# --- 3. Student Financial Aid (SFA) ---
sfa <- dbGetQuery(con, "
  SELECT unitid, year, scugrad, scugffn, pgrnt_n, pgrnt_a, pgrnt_t,
         agrnt_n, agrnt_a, agrnt_t, igrnt_n, igrnt_a, igrnt_t,
         loan_n, loan_a,
         npis412, npis422, npis432, npis442, npis452
  FROM ipeds.sfa
  WHERE year BETWEEN 2015 AND 2022
")
cat(sprintf("SFA (financial aid): %d rows\n", nrow(sfa)))

# --- 4. Tuition (IC_AY) ---
ic_ay <- dbGetQuery(con, "
  SELECT unitid, year, tuition_in_state, tuition_out_state, fee2, fee3
  FROM ipeds.ic_ay
  WHERE year BETWEEN 2015 AND 2022
")
cat(sprintf("IC_AY (tuition): %d rows\n", nrow(ic_ay)))

# --- 5. Enrollment (EFFY — 12-month unduplicated) ---
effy <- dbGetQuery(con, "
  SELECT unitid, year, efytotlt, efytotlm, efytotlw
  FROM ipeds.effy
  WHERE year BETWEEN 2015 AND 2022
    AND lstudy = 999
")
cat(sprintf("EFFY (enrollment): %d rows\n", nrow(effy)))

# --- 6. Completions (C_A) ---
c_a <- dbGetQuery(con, "
  SELECT unitid, year,
         SUM(ctotalt) as ctotalt,
         SUM(ctotalm) as ctotalm,
         SUM(ctotalw) as ctotalw
  FROM ipeds.c_a
  WHERE year BETWEEN 2015 AND 2022
    AND major_number = 1
    AND cipcode = '99'
  GROUP BY unitid, year
")
cat(sprintf("C_A (completions): %d rows\n", nrow(c_a)))

dbDisconnect(con, shutdown = TRUE)

# --- Save raw data ---
saveRDS(hd, "../data/hd_raw.rds")
saveRDS(f1a, "../data/f1a_raw.rds")
saveRDS(sfa, "../data/sfa_raw.rds")
saveRDS(ic_ay, "../data/ic_ay_raw.rds")
saveRDS(effy, "../data/effy_raw.rds")
saveRDS(c_a, "../data/c_a_raw.rds")

cat("All IPEDS data fetched and saved.\n")
