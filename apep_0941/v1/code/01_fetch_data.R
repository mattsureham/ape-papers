# =============================================================================
# 01_fetch_data.R — Fetch IPEDS data from local DuckDB
# =============================================================================

source("00_packages.R")

# Connect to local IPEDS DuckDB
ipeds_path <- "../../../../data/ipeds/ipeds.duckdb"
stopifnot("IPEDS DuckDB not found" = file.exists(ipeds_path))

con <- dbConnect(duckdb::duckdb(), dbdir = ipeds_path, read_only = TRUE)
cat("Connected to IPEDS DuckDB\n")

# ---------------------------------------------------------------------------
# 1. Institutional directory (HD) — 2010-2022
# ---------------------------------------------------------------------------
hd <- dbGetQuery(con, "
  SELECT unitid, year, institution_name, city, state,
         fips_state,
         CAST(county_fips AS INTEGER) AS county_fips,
         sector, control, level, close_date
  FROM hd
  WHERE year BETWEEN 2010 AND 2022
")
cat("HD table:", nrow(hd), "rows\n")
stopifnot(nrow(hd) > 50000)

# ---------------------------------------------------------------------------
# 2. Enrollment by race (EF_A) — 2010-2022, undergrad total
# ---------------------------------------------------------------------------
ef <- dbGetQuery(con, "
  SELECT unitid, year,
         eftotlt, eftotlm, eftotlw,
         efbkaat, efhispt, efwhitt,
         efasiat, efaiant, efnhpit, ef2mort,
         efunknt, efnralt
  FROM ef_a
  WHERE year BETWEEN 2010 AND 2022
    AND efalevel = 1
")
cat("EF_A table:", nrow(ef), "rows\n")
stopifnot(nrow(ef) > 40000)

# ---------------------------------------------------------------------------
# 3. Validate data
# ---------------------------------------------------------------------------
fp_sectors <- hd %>%
  filter(year == 2015, control == 3) %>%
  count(sector) %>%
  arrange(desc(n))
cat("\nFor-profit sectors in 2015:\n")
print(fp_sectors)

fp_2015 <- hd %>% filter(year == 2015, control == 3) %>% pull(unitid)
fp_2018 <- hd %>% filter(year == 2018, control == 3) %>% pull(unitid)
closed <- setdiff(fp_2015, fp_2018)
cat("\nFor-profit institutions in 2015:", length(fp_2015), "\n")
cat("For-profit institutions in 2018:", length(fp_2018), "\n")
cat("Closed between 2015-2018:", length(closed), "\n")

cc_count <- hd %>% filter(year == 2016, sector == 4) %>% nrow()
cat("Community colleges in 2016:", cc_count, "\n")
stopifnot(cc_count > 800)

# ---------------------------------------------------------------------------
# 4. Save raw data
# ---------------------------------------------------------------------------
saveRDS(hd, "../data/hd_raw.rds")
saveRDS(ef, "../data/ef_raw.rds")

dbDisconnect(con, shutdown = TRUE)
cat("\nData saved to data/hd_raw.rds and data/ef_raw.rds\n")
