# =============================================================================
# 01_fetch_data.R — Fetch QWI data from Azure
# APEP Working Paper apep_0800
# =============================================================================

source("00_packages.R")

# Force-load Azure connection string from .env (bash source truncates at semicolons)
env_path <- normalizePath(file.path("..", "..", "..", "..", ".env"), mustWork = FALSE)
env_lines <- readLines(env_path, warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (startsWith(line, "AZURE_STORAGE_CONNECTION_STRING=")) {
    val <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    val <- gsub('^["\']|["\']$', '', val)
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    break
  }
}

source("../../../../scripts/lib/azure_data.R")

con <- apep_azure_connect()

# ---------------------------------------------------------------------------
# Fetch QWI race-by-industry data for NAICS 52 (Finance) and NAICS 11 (Ag)
# County × quarter × race panel, 2002–2018
# Race: A1 = White, A2 = Black; Ethnicity: A0 = All
# ---------------------------------------------------------------------------
cat("Fetching NAICS 52 (Finance) data from Azure...\n")

qwi_52 <- dbGetQuery(con, "
  SELECT geography, year, quarter, race, ethnicity, industry,
         Emp, EmpEnd, EmpS, HirA, HirN, Sep, EarnS, EarnHirNS,
         TurnOvrS, geo_level
  FROM 'az://derived/qwi/rh/ns/*.parquet'
  WHERE industry = '52'
    AND geo_level = 'C'
    AND race IN ('A1', 'A2')
    AND ethnicity = 'A0'
    AND year BETWEEN 2002 AND 2018
")
cat(sprintf("NAICS 52: %d rows fetched.\n", nrow(qwi_52)))
stopifnot("No NAICS 52 data fetched" = nrow(qwi_52) > 0)

cat("Fetching NAICS 11 (Agriculture) placebo data...\n")

qwi_11 <- dbGetQuery(con, "
  SELECT geography, year, quarter, race, ethnicity, industry,
         Emp, EmpEnd, EmpS, HirA, HirN, Sep, EarnS, EarnHirNS,
         TurnOvrS, geo_level
  FROM 'az://derived/qwi/rh/ns/*.parquet'
  WHERE industry = '11'
    AND geo_level = 'C'
    AND race IN ('A1', 'A2')
    AND ethnicity = 'A0'
    AND year BETWEEN 2002 AND 2018
")
cat(sprintf("NAICS 11: %d rows fetched.\n", nrow(qwi_11)))
stopifnot("No NAICS 11 data fetched" = nrow(qwi_11) > 0)

apep_azure_disconnect(con)

# ---------------------------------------------------------------------------
# Combine and validate
# ---------------------------------------------------------------------------
df_raw <- bind_rows(qwi_52, qwi_11)

cat(sprintf("\nTotal rows: %s\n", format(nrow(df_raw), big.mark = ",")))
cat("\nIndustry breakdown:\n")
print(table(df_raw$industry))
cat("\nRace breakdown:\n")
print(table(df_raw$race))
cat(sprintf("\nYear range: %d - %d\n", min(df_raw$year), max(df_raw$year)))
cat(sprintf("Counties: %d\n", n_distinct(df_raw$geography)))

# Save raw data
arrow::write_parquet(df_raw, "../data/qwi_raw.parquet")
cat(sprintf("\nSaved %s rows to data/qwi_raw.parquet\n",
            format(nrow(df_raw), big.mark = ",")))
