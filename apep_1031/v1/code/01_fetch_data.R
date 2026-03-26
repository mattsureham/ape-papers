# =============================================================================
# 01_fetch_data.R — Fetch QWI data from Azure
# apep_1031: Kitchen Table Capitalism
# =============================================================================

source("00_packages.R")

# Force-load Azure connection string from .env (bash truncates at semicolons)
env_lines <- readLines("../../../../.env", warn = FALSE)
az_line <- grep("^AZURE_STORAGE_CONNECTION_STRING=", env_lines, value = TRUE)
if (length(az_line) > 0) {
  az_val <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", az_line[1])
  az_val <- gsub('^["\'](.*)["\']$', "\\1", az_val)
  Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = az_val)
}

source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()

# --- Query 1: NAICS 3-digit for Food Manufacturing (311) and Food Services (722)
# Use sex×age demographic for heterogeneity
# Aggregate to state level (sum across counties within state)
cat("Fetching NAICS 3-digit QWI (311, 722) from Azure...\n")

df_food <- dbGetQuery(con, "
  SELECT
    CAST(FLOOR(geography / 1000) AS INTEGER) AS state_fips,
    year,
    quarter,
    industry,
    sex,
    agegrp,
    SUM(Emp) AS Emp,
    SUM(EmpEnd) AS EmpEnd,
    SUM(HirA) AS HirA,
    SUM(HirN) AS HirN,
    SUM(Sep) AS Sep,
    SUM(FrmJbGn) AS FrmJbGn,
    SUM(FrmJbLs) AS FrmJbLs,
    SUM(EarnS) AS EarnS_total,
    COUNT(*) AS n_counties
  FROM 'az://derived/qwi/sa/n3/*.parquet'
  WHERE industry IN ('311', '722')
    AND year >= 2005
    AND sex = '0'
    AND agegrp = 'A00'
  GROUP BY 1,2,3,4,5,6
")

cat(sprintf("  Food industries: %d rows\n", nrow(df_food)))
stopifnot(nrow(df_food) > 0)

# --- Query 2: NAICS sector level for Manufacturing overall (31-33)
# This is the placebo sector
cat("Fetching NAICS sector QWI (31-33 Manufacturing) from Azure...\n")

df_mfg <- dbGetQuery(con, "
  SELECT
    CAST(FLOOR(geography / 1000) AS INTEGER) AS state_fips,
    year,
    quarter,
    industry,
    sex,
    agegrp,
    SUM(Emp) AS Emp,
    SUM(EmpEnd) AS EmpEnd,
    SUM(HirA) AS HirA,
    SUM(HirN) AS HirN,
    SUM(Sep) AS Sep,
    SUM(FrmJbGn) AS FrmJbGn,
    SUM(FrmJbLs) AS FrmJbLs,
    SUM(EarnS) AS EarnS_total,
    COUNT(*) AS n_counties
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE industry = '31-33'
    AND year >= 2005
    AND sex = '0'
    AND agegrp = 'A00'
  GROUP BY 1,2,3,4,5,6
")

cat(sprintf("  Manufacturing: %d rows\n", nrow(df_mfg)))
stopifnot(nrow(df_mfg) > 0)

# --- Query 3: Sex-specific data for heterogeneity (NAICS 722 only)
cat("Fetching sex-specific QWI for NAICS 722...\n")

df_sex <- dbGetQuery(con, "
  SELECT
    CAST(FLOOR(geography / 1000) AS INTEGER) AS state_fips,
    year,
    quarter,
    industry,
    sex,
    agegrp,
    SUM(Emp) AS Emp,
    SUM(FrmJbGn) AS FrmJbGn,
    SUM(EarnS) AS EarnS_total,
    COUNT(*) AS n_counties
  FROM 'az://derived/qwi/sa/n3/*.parquet'
  WHERE industry = '722'
    AND year >= 2005
    AND sex IN ('1', '2')
    AND agegrp = 'A00'
  GROUP BY 1,2,3,4,5,6
")

cat(sprintf("  Sex-specific: %d rows\n", nrow(df_sex)))

apep_azure_disconnect(con)

# --- Save raw data
saveRDS(df_food, "../data/qwi_food_raw.rds")
saveRDS(df_mfg, "../data/qwi_mfg_raw.rds")
saveRDS(df_sex, "../data/qwi_sex_raw.rds")

cat("Data fetched and saved successfully.\n")
cat(sprintf("  States: %d\n", n_distinct(df_food$state_fips)))
cat(sprintf("  Years: %d-%d\n", min(df_food$year), max(df_food$year)))
cat(sprintf("  Industries: %s\n", paste(unique(df_food$industry), collapse = ", ")))
