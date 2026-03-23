## 01_fetch_data.R — Fetch QWI race panel from Azure + CBP from Census API
## APEP apep_0831: Section 232 Tariffs and the Racial Wage Gap

source("00_packages.R")

cat("=== Step 1: Load QWI Race-Hispanic panel from Azure ===\n")

## Force-load Azure connection string from .env (shell may truncate at semicolons)
env_file <- "../../../../.env"
env_lines <- readLines(env_file, warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (startsWith(line, "AZURE_STORAGE_CONNECTION_STRING=")) {
    val <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    val <- gsub('^["\'](.*)["\']+$', "\\1", val)
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    cat("Azure connection string loaded:", nchar(val), "chars\n")
    break
  }
}

library(DBI)
library(duckdb)
source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()

## First, discover the column names in the RH panel
cat("Discovering column names...\n")
cols <- dbGetQuery(con, "SELECT * FROM 'az://derived/qwi/rh/ns/*.parquet' LIMIT 5")
cat("Columns:", paste(names(cols), collapse = ", "), "\n")
print(head(cols))

## Query: manufacturing sector, 2015-2020, race A1 (White) and A2 (Black)
## The RH panel has columns: geography, year, quarter, race, ethnicity, industry,
## ownercode, Emp, EarnS, HirA, Sep, EmpEnd, etc.
cat("\nQuerying QWI race-Hispanic data from Azure...\n")

qwi_query <- "
SELECT
  geography,
  year,
  quarter,
  race,
  ethnicity,
  industry,
  \"Emp\" AS emp,
  \"EarnS\" AS earn,
  \"HirA\" AS hires,
  \"Sep\" AS seps,
  \"EmpEnd\" AS empend
FROM 'az://derived/qwi/rh/ns/*.parquet'
WHERE year BETWEEN 2015 AND 2020
  AND race IN ('A1', 'A2')
  AND ownercode = 'A05'
"

qwi_raw <- dbGetQuery(con, qwi_query)
cat(sprintf("QWI rows loaded: %s\n", format(nrow(qwi_raw), big.mark = ",")))

stopifnot("QWI data is empty — Azure query returned no rows" = nrow(qwi_raw) > 0)
stopifnot("QWI must have both A1 and A2 races" = all(c("A1", "A2") %in% qwi_raw$race))

## Check data quality
cat("\nRace distribution:\n")
print(table(qwi_raw$race))
cat("\nYear distribution:\n")
print(table(qwi_raw$year))
cat("\nIndustry codes present:\n")
print(sort(unique(qwi_raw$industry)))

## Also try 4-digit NAICS (n4) if available
cat("\n--- Checking 4-digit NAICS availability ---\n")
n4_check <- tryCatch({
  dbGetQuery(con, "
    SELECT industry, COUNT(*) as n
    FROM 'az://derived/qwi/rh/n4/*.parquet'
    WHERE year = 2017 AND quarter = 1 AND race = 'A1'
      AND industry LIKE '33%'
      AND ownercode = 'A05'
    GROUP BY industry
    ORDER BY industry
    LIMIT 20
  ")
}, error = function(e) {
  cat("4-digit NAICS (n4) not available:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(n4_check) && nrow(n4_check) > 0) {
  cat("4-digit NAICS available! Industries:\n")
  print(n4_check)

  ## Fetch 4-digit manufacturing data
  qwi_n4_query <- "
  SELECT
    geography,
    year,
    quarter,
    race,
    ethnicity,
    industry,
    \"Emp\" AS emp,
    \"EarnS\" AS earn,
    \"HirA\" AS hires,
    \"Sep\" AS seps
  FROM 'az://derived/qwi/rh/n4/*.parquet'
  WHERE year BETWEEN 2015 AND 2020
    AND race IN ('A1', 'A2')
    AND industry LIKE '33%'
    AND ownercode = 'A05'
  "
  qwi_n4 <- dbGetQuery(con, qwi_n4_query)
  cat(sprintf("QWI 4-digit mfg rows: %s\n", format(nrow(qwi_n4), big.mark = ",")))
  saveRDS(qwi_n4, "../data/qwi_mfg_n4.rds")
} else {
  cat("Using sector-level (ns) data only.\n")
}

apep_azure_disconnect(con)

## ========================================================
cat("\n=== Step 2: Fetch County Business Patterns 2016 ===\n")

## Get employment by county × NAICS for treatment intensity construction
## NAICS 3310 (Primary metals) and 3320 (Fabricated metal products) are Section 232 protected
## NAICS 31-33 (all manufacturing) for total manufacturing employment

census_key <- Sys.getenv("CENSUS_API_KEY")
key_param <- ifelse(nchar(census_key) > 0, paste0("&key=", census_key), "")

## Function to fetch CBP data per state to avoid 204 errors
## CBP 2016 uses NAICS2012 variable names
fetch_cbp <- function(naics_code) {
  cat(sprintf("Fetching CBP for NAICS %s...\n", naics_code))
  all_results <- list()
  fips_states <- sprintf("%02d", c(1:2, 4:6, 8:13, 15:42, 44:51, 53:56))

  for (st in fips_states) {
    url <- sprintf(
      "https://api.census.gov/data/2016/cbp?get=EMP,ESTAB,PAYANN&for=county:*&in=state:%s&NAICS2012=%s%s",
      st, naics_code, key_param
    )
    resp <- httr::GET(url, httr::timeout(60))
    if (httr::status_code(resp) == 200) {
      raw <- httr::content(resp, as = "text", encoding = "UTF-8")
      if (nchar(raw) > 10) {
        parsed <- jsonlite::fromJSON(raw)
        if (nrow(parsed) > 1) {
          df <- as.data.frame(parsed[-1, , drop = FALSE], stringsAsFactors = FALSE)
          names(df) <- parsed[1, ]
          all_results[[length(all_results) + 1]] <- df
        }
      }
    }
    Sys.sleep(0.05)  # rate limit
  }

  result <- bind_rows(all_results)
  result$EMP <- as.numeric(result$EMP)
  result$ESTAB <- as.numeric(result$ESTAB)
  result$PAYANN <- as.numeric(result$PAYANN)
  result$fips <- paste0(result$state, result$county)
  result$naics <- naics_code
  cat(sprintf("  Got %d county records\n", nrow(result)))
  return(result)
}

## Fetch protected industries (3-digit NAICS codes in CBP 2016)
cbp_331 <- fetch_cbp("331")   # Primary metals (tariff beneficiaries)
cbp_332 <- fetch_cbp("332")   # Fabricated metal products
cbp_mfg <- fetch_cbp("31-33") # All manufacturing

cat(sprintf("CBP 331 rows: %d\n", nrow(cbp_331)))
cat(sprintf("CBP 332 rows: %d\n", nrow(cbp_332)))
cat(sprintf("CBP manufacturing rows: %d\n", nrow(cbp_mfg)))

stopifnot("CBP 331 data is empty" = nrow(cbp_331) > 0)
stopifnot("CBP manufacturing data is empty" = nrow(cbp_mfg) > 0)

## Construct treatment intensity: share of county manufacturing employment in protected sectors
protected <- bind_rows(cbp_331, cbp_332) %>%
  group_by(fips) %>%
  summarise(emp_protected = sum(EMP, na.rm = TRUE), .groups = "drop")

mfg_total <- cbp_mfg %>%
  select(fips, emp_mfg = EMP)

treatment <- left_join(mfg_total, protected, by = "fips") %>%
  mutate(
    emp_protected = replace_na(emp_protected, 0),
    exposure = ifelse(emp_mfg > 0, emp_protected / emp_mfg, 0),
    emp_mfg = as.numeric(emp_mfg)
  )

cat(sprintf("\nTreatment intensity constructed for %d counties\n", nrow(treatment)))
cat("\nExposure distribution:\n")
print(summary(treatment$exposure))

## ========================================================
cat("\n=== Step 3: Save data ===\n")

saveRDS(qwi_raw, "../data/qwi_manufacturing.rds")
saveRDS(treatment, "../data/treatment_exposure.rds")
saveRDS(cbp_331, "../data/cbp_331.rds")
saveRDS(cbp_332, "../data/cbp_332.rds")
saveRDS(cbp_mfg, "../data/cbp_mfg.rds")

cat("Data saved.\n")
cat("Done.\n")
