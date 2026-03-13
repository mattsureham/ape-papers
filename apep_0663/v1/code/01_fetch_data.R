# =============================================================================
# 01_fetch_data.R — Fetch QWI data from Azure for apep_0663
# =============================================================================

source("00_packages.R")

# ---- Connect to Azure --------------------------------------------------------
con <- apep_azure_connect()

# ---- Fetch QWI sex×education data (state level) -----------------------------
# We aggregate county-level data to state level for the main analysis.
# Columns: geography (FIPS county), year, quarter, industry, sex, education,
#          Emp, HirA, HirN, Sep, EarnS, FrmJbGn, FrmJbLs, TurnOvrS, etc.

cat("Fetching QWI sex×education data (all states, NAICS sectors)...\n")
cat("This queries ~123M rows from Azure Parquet files.\n")

# Query state-level aggregates directly via SQL for efficiency
# geography is 5-digit FIPS county code; state = first 2 digits (or 1 for single-digit)
# We aggregate to state × quarter × industry × education
qwi_se <- dbGetQuery(con, "
  SELECT
    CAST(FLOOR(geography / 1000) AS INTEGER) AS statefip,
    year,
    quarter,
    industry,
    education,
    SUM(Emp) AS Emp,
    SUM(EmpEnd) AS EmpEnd,
    SUM(HirA) AS HirA,
    SUM(HirN) AS HirN,
    SUM(Sep) AS Sep,
    SUM(FrmJbGn) AS FrmJbGn,
    SUM(FrmJbLs) AS FrmJbLs,
    SUM(EarnS * EmpS) / NULLIF(SUM(EmpS), 0) AS EarnS_wtd,
    SUM(EmpS) AS EmpS
  FROM 'az://derived/qwi/se/ns/*.parquet'
  WHERE sex = 0
    AND year BETWEEN 2010 AND 2019
    AND education IN ('E1', 'E2', 'E3', 'E4', 'E5')
    AND industry != '00'
    AND Emp IS NOT NULL
  GROUP BY statefip, year, quarter, industry, education
")

cat(sprintf("Fetched %s state×quarter×industry×education rows.\n", format(nrow(qwi_se), big.mark = ",")))

stopifnot("No data returned from Azure" = nrow(qwi_se) > 0)
stopifnot("Missing state FIPS" = all(!is.na(qwi_se$statefip)))

# ---- Save raw data -----------------------------------------------------------
saveRDS(qwi_se, "../data/qwi_se_state.rds")
cat("Saved QWI sex×education state-level data.\n")

# ---- Disconnect --------------------------------------------------------------
apep_azure_disconnect(con)
cat("Data fetch complete.\n")
