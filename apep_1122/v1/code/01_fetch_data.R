# =============================================================================
# 01_fetch_data.R — Fetch QWI education panel from Azure + steel prices from FRED
# =============================================================================

source("00_packages.R")

# Force re-read Azure connection string from .env (shell may truncate at semicolons)
Sys.unsetenv("AZURE_STORAGE_CONNECTION_STRING")
source("../../../../scripts/lib/azure_data.R")

# =============================================================================
# 1. QWI Education × 3-digit NAICS from Azure
# =============================================================================
con <- apep_azure_connect()

# Target industries: downstream steel-using manufacturing
# NAICS 332 (Fabricated Metals), 333 (Machinery), 336 (Transportation Equipment)
# Also grab all manufacturing (31-33) for exposure construction
# Panel: 2015Q1 - 2019Q4 (pre-COVID cutoff)

cat("Fetching QWI se/n3 data from Azure...\n")

# Fetch downstream industries (332, 333, 336) + all manufacturing for exposure
qwi_raw <- apep_azure_query(con, "
  SELECT
    geography, geo_level, industry, education, sex,
    year, quarter,
    Emp, EmpS, HirA, HirAS, Sep, SepS,
    EarnBeg, sEarnBeg, EarnS,
    FrmJbGn, FrmJbGnS, FrmJbLs, FrmJbLsS
  FROM 'az://derived/qwi/se/n3/*.parquet'
  WHERE geo_level = 'S'
    AND sex = 0
    AND year BETWEEN 2013 AND 2019
    AND industry IN ('332', '333', '336', '311', '312', '313',
                     '314', '315', '316', '321', '322', '323',
                     '324', '325', '326', '327', '331', '334',
                     '335', '337', '339')
")

cat("QWI rows fetched:", nrow(qwi_raw), "\n")
stopifnot("QWI data is empty" = nrow(qwi_raw) > 0)

# Also fetch county-level for downstream industries (for county exposure)
cat("Fetching county-level QWI for exposure construction...\n")

qwi_county <- apep_azure_query(con, "
  SELECT
    geography, geo_level, industry, education, sex,
    year, quarter,
    Emp, EmpS, HirA, Sep, EarnBeg, EarnS,
    FrmJbGn, FrmJbLs
  FROM 'az://derived/qwi/se/n3/*.parquet'
  WHERE geo_level = 'C'
    AND sex = 0
    AND year BETWEEN 2013 AND 2019
    AND industry IN ('332', '333', '336', '311', '312', '313',
                     '314', '315', '316', '321', '322', '323',
                     '324', '325', '326', '327', '331', '334',
                     '335', '337', '339')
")

cat("County QWI rows fetched:", nrow(qwi_county), "\n")
stopifnot("County QWI data is empty" = nrow(qwi_county) > 0)

apep_azure_disconnect(con)

# =============================================================================
# 2. Steel prices from FRED
# =============================================================================
cat("Fetching steel PPI from FRED...\n")
fredr_set_key(Sys.getenv("FRED_API_KEY"))

steel_ppi <- fredr(
  series_id = "WPU1017",
  observation_start = as.Date("2013-01-01"),
  observation_end = as.Date("2020-01-01"),
  frequency = "q"
)

cat("Steel PPI observations:", nrow(steel_ppi), "\n")
stopifnot("Steel PPI data is empty" = nrow(steel_ppi) > 0)

# =============================================================================
# 3. Save raw data
# =============================================================================
saveRDS(qwi_raw, "../data/qwi_state_mfg.rds")
saveRDS(qwi_county, "../data/qwi_county_mfg.rds")
saveRDS(steel_ppi, "../data/steel_ppi.rds")

cat("Data saved to data/ directory.\n")
cat("State-level QWI:", nrow(qwi_raw), "rows\n")
cat("County-level QWI:", nrow(qwi_county), "rows\n")
cat("Steel PPI:", nrow(steel_ppi), "rows\n")
