# =============================================================================
# 01_fetch_data.R — Fetch QWI data from Azure for film tax credit analysis
# =============================================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

con <- apep_azure_connect()

# ---------------------------------------------------------------------------
# 1. Fetch NAICS 3-digit data by race/ethnicity (rh) for all states
#    Filter to industry = "512" (Motion Picture and Sound Recording)
# ---------------------------------------------------------------------------
cat("Fetching QWI race/ethnicity x NAICS 3-digit data...\n")

qwi_rh <- dbGetQuery(con, "
  SELECT *
  FROM 'az://derived/qwi/rh/n3/*.parquet'
  WHERE industry = '512'
")

cat(sprintf("  Race/ethnicity data: %d rows, %d states\n",
            nrow(qwi_rh), n_distinct(qwi_rh$geography %/% 1000)))

# Also fetch total employment (all industries) for normalization
cat("Fetching total employment by state-quarter...\n")

qwi_total <- dbGetQuery(con, "
  SELECT geography, year, quarter, sex, agegrp, race, ethnicity,
         SUM(Emp) as total_emp, SUM(EmpEnd) as total_emp_end,
         SUM(HirA) as total_hira, SUM(Sep) as total_sep
  FROM 'az://derived/qwi/rh/n3/*.parquet'
  GROUP BY geography, year, quarter, sex, agegrp, race, ethnicity
")

cat(sprintf("  Total employment data: %d rows\n", nrow(qwi_total)))

# ---------------------------------------------------------------------------
# 2. Fetch placebo sectors — AGGREGATE in DuckDB to avoid memory limits
#    NAICS 71 = Arts/Entertainment, 52 = Finance, 31-33 = Manufacturing
# ---------------------------------------------------------------------------
cat("Fetching placebo sector data (aggregated)...\n")

# Aggregate to state-quarter-sector level in DuckDB
qwi_placebo <- dbGetQuery(con, "
  SELECT
    CAST(geography / 1000 AS INTEGER) AS state_fips,
    year, quarter,
    CASE
      WHEN industry IN ('711','712','713') THEN 'Arts'
      WHEN industry IN ('521','522','523','524') THEN 'Finance'
      ELSE 'Manufacturing'
    END AS sector,
    SUM(Emp) AS emp,
    SUM(HirA) AS hira,
    SUM(Sep) AS sep
  FROM 'az://derived/qwi/rh/n3/*.parquet'
  WHERE industry IN ('711', '712', '713', '521', '522', '523', '524',
                     '311', '312', '313', '314', '315', '316', '321', '322',
                     '323', '324', '325', '326', '327', '331', '332', '333',
                     '334', '335', '336', '337', '339')
  GROUP BY state_fips, year, quarter, sector
")

cat(sprintf("  Placebo sectors (aggregated): %d rows\n", nrow(qwi_placebo)))

# ---------------------------------------------------------------------------
# 3. Also fetch sex-by-age breakdown for NAICS 512
# ---------------------------------------------------------------------------
cat("Fetching sex x age data for NAICS 512...\n")

qwi_sa <- dbGetQuery(con, "
  SELECT *
  FROM 'az://derived/qwi/sa/n3/*.parquet'
  WHERE industry = '512'
")

cat(sprintf("  Sex x age data: %d rows\n", nrow(qwi_sa)))

apep_azure_disconnect(con)

# ---------------------------------------------------------------------------
# 4. Save fetched data
# ---------------------------------------------------------------------------
saveRDS(qwi_rh, "../data/qwi_rh_512.rds")
saveRDS(qwi_total, "../data/qwi_total_rh.rds")
saveRDS(qwi_placebo, "../data/qwi_placebo_agg.rds")
saveRDS(qwi_sa, "../data/qwi_sa_512.rds")

cat("Data saved to ../data/\n")
cat(sprintf("NAICS 512 race data: %d rows\n", nrow(qwi_rh)))
cat(sprintf("Total employment: %d rows\n", nrow(qwi_total)))
cat(sprintf("Placebo sectors (aggregated): %d rows\n", nrow(qwi_placebo)))

# Validate: no empty datasets
stopifnot("QWI race data is empty" = nrow(qwi_rh) > 0)
stopifnot("Total employment data is empty" = nrow(qwi_total) > 0)
stopifnot("Placebo data is empty" = nrow(qwi_placebo) > 0)

cat("01_fetch_data.R complete.\n")
