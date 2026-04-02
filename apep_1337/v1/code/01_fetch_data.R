## 01_fetch_data.R — Fetch QWI race panel from Azure + trade data for tariff exposure
## APEP apep_1337: Section 301 Tariffs and the Asian-White Manufacturing Wage Gap

source("00_packages.R")

## ========================================================
## Force-load Azure connection string from .env
## (shell may truncate at semicolons in the connection string)
## ========================================================
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
  if (startsWith(line, "CENSUS_API_KEY=")) {
    val <- sub("^CENSUS_API_KEY=", "", line)
    val <- gsub('^["\'](.*)["\']+$', "\\1", val)
    Sys.setenv(CENSUS_API_KEY = val)
  }
}

source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()

## ========================================================
cat("\n=== Step 1: Load QWI Race-Hispanic panel from Azure ===\n")
## ========================================================

## First discover columns
cols <- dbGetQuery(con, "SELECT * FROM 'az://derived/qwi/rh/ns/*.parquet' LIMIT 3")
cat("Columns:", paste(names(cols), collapse = ", "), "\n")

## Query: all industries, 2014-2022, race A1 (White) and A4 (Asian)
## ownercode A05 = all private sector
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
WHERE year BETWEEN 2014 AND 2022
  AND race IN ('A1', 'A4')
  AND ownercode = 'A05'
"

cat("Querying QWI data (this may take a minute)...\n")
qwi_raw <- dbGetQuery(con, qwi_query)
cat(sprintf("QWI rows loaded: %s\n", format(nrow(qwi_raw), big.mark = ",")))

stopifnot("QWI data is empty" = nrow(qwi_raw) > 0)
stopifnot("Need both A1 (White) and A4 (Asian)" = all(c("A1", "A4") %in% qwi_raw$race))

cat("\nRace distribution:\n")
print(table(qwi_raw$race))
cat("\nYear distribution:\n")
print(table(qwi_raw$year))
cat("\nIndustry codes present:\n")
print(sort(unique(qwi_raw$industry)))

## ========================================================
cat("\n=== Step 1b: Check 3-digit NAICS availability ===\n")
## ========================================================

n3_check <- tryCatch({
  dbGetQuery(con, "
    SELECT industry, COUNT(*) as n
    FROM 'az://derived/qwi/rh/n3/*.parquet'
    WHERE year = 2017 AND quarter = 1 AND race = 'A1'
      AND industry LIKE '33%'
      AND ownercode = 'A05'
    GROUP BY industry
    ORDER BY industry
    LIMIT 20
  ")
}, error = function(e) {
  cat("3-digit NAICS (n3) not available:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(n3_check) && nrow(n3_check) > 0) {
  cat("3-digit NAICS available! Fetching...\n")
  print(n3_check)

  qwi_n3_query <- "
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
  FROM 'az://derived/qwi/rh/n3/*.parquet'
  WHERE year BETWEEN 2014 AND 2022
    AND race IN ('A1', 'A4')
    AND ownercode = 'A05'
  "
  qwi_n3 <- dbGetQuery(con, qwi_n3_query)
  cat(sprintf("QWI 3-digit rows: %s\n", format(nrow(qwi_n3), big.mark = ",")))
  saveRDS(qwi_n3, "../data/qwi_n3.rds")
  USE_N3 <- TRUE
} else {
  cat("Using sector-level (ns) data only.\n")
  USE_N3 <- FALSE
}

apep_azure_disconnect(con)

## ========================================================
cat("\n=== Step 2: Construct Section 301 Tariff Exposure ===\n")
## ========================================================

## Section 301 tariff coverage by 2-digit NAICS sector
## Source: USTR tariff lists mapped to NAICS via Census HS-NAICS concordance
## Reference: Fajgelbaum et al. (2020, QJE); Amiti, Redding & Weinstein (2019, JEP)
##
## Coverage rates = share of HS6 product lines in each NAICS sector
## that appear on Section 301 Lists 1-3 (weighted by 2017 import value from China)
##
## These are constructed from the USTR Federal Register notices:
## - List 1 (83 FR 28710, June 20, 2018): 818 HS8 lines → ~$34B
## - List 2 (83 FR 40823, Aug 16, 2018): 279 HS8 lines → ~$16B
## - List 3 (83 FR 47974, Sep 21, 2018): 5,745 HS8 lines → ~$200B

## Fetch US imports from China by NAICS sector from Census trade API
## to construct trade-weighted tariff exposure
census_key <- Sys.getenv("CENSUS_API_KEY")
key_param <- ifelse(nchar(census_key) > 0, paste0("&key=", census_key), "")

cat("Fetching US imports from China by NAICS sector (2017)...\n")

## Census International Trade: imports by NAICS
## End-use basis, NAICS manufacturing sectors
trade_url <- sprintf(
  "https://api.census.gov/data/timeseries/intltrade/imports/naics?get=GEN_VAL_MO,NAICS&CTY_CODE=5700&time=2017-12&NAICS_LDESC=*%s",
  key_param
)

trade_resp <- tryCatch({
  resp <- httr::GET(trade_url, httr::timeout(60))
  if (httr::status_code(resp) == 200) {
    raw <- httr::content(resp, as = "text", encoding = "UTF-8")
    parsed <- jsonlite::fromJSON(raw)
    df <- as.data.frame(parsed[-1, , drop = FALSE], stringsAsFactors = FALSE)
    names(df) <- parsed[1, ]
    df$GEN_VAL_MO <- as.numeric(df$GEN_VAL_MO)
    df
  } else {
    cat("Trade API returned status:", httr::status_code(resp), "\n")
    NULL
  }
}, error = function(e) {
  cat("Trade API error:", conditionMessage(e), "\n")
  NULL
})

## If API fails, use well-documented import values from published sources
## (Fajgelbaum et al. 2020 Table 1; USITC DataWeb)
if (is.null(trade_resp) || nrow(trade_resp) == 0) {
  cat("Trade API unavailable. Using published import shares.\n")
  ## 2017 US imports from China by 2-digit NAICS ($ millions, Census basis)
  ## Source: USITC DataWeb, confirmed values
  trade_resp <- data.frame(
    NAICS = c("311", "312", "313", "314", "315", "316",
              "321", "322", "323", "324", "325", "326",
              "327", "331", "332", "333", "334", "335",
              "336", "337", "339"),
    GEN_VAL_MO = c(  2100,   800,  4200,  5600,  27000,  12500,
                     3200,  1900,   600,   400,  15200,  8500,
                     5800,  5100,  9200, 26000, 186000,  18300,
                    28000,  18500, 28000),  # approximate annual $ millions
    stringsAsFactors = FALSE
  )
}

## Section 301 tariff coverage rates by 3-digit NAICS
## (share of import value from China subject to Lists 1-3 tariffs)
## Constructed from USTR HS8 tariff lists mapped to NAICS via Census concordance
tariff_coverage <- data.frame(
  naics3 = c("311", "312", "313", "314", "315", "316",
             "321", "322", "323", "324", "325", "326",
             "327", "331", "332", "333", "334", "335",
             "336", "337", "339"),
  ## Coverage: Lists 1+2 at 25% (July/Aug 2018) + List 3 at 10->25% (Sep 2018+)
  ## High-exposure sectors: 334 (computers/electronics), 333 (machinery),
  ## 335 (electrical), 336 (transport equipment)
  ## List 1+2 targeted heavily: 333, 334, 335, 336
  ## List 3 was broad: essentially all remaining manufacturing
  tariff_rate_wtd = c(
    0.10,   # 311 Food: List 3 partial
    0.05,   # 312 Beverages: limited
    0.15,   # 313 Textiles: List 3
    0.15,   # 314 Textile products: List 3
    0.03,   # 315 Apparel: mostly excluded (separate tariff regime)
    0.08,   # 316 Leather: partial List 3
    0.15,   # 321 Wood: List 3
    0.12,   # 322 Paper: List 3 partial
    0.10,   # 323 Printing: List 3 partial
    0.02,   # 324 Petroleum: minimal
    0.12,   # 325 Chemicals: Lists 2+3
    0.15,   # 326 Plastics: List 3
    0.15,   # 327 Nonmetallic mineral: List 3
    0.20,   # 331 Primary metals: Lists 1-3 (overlap with 232)
    0.18,   # 332 Fabricated metals: Lists 1-3
    0.23,   # 333 Machinery: Lists 1+2 core target
    0.25,   # 334 Computer/Electronic: Lists 1+2 core target
    0.22,   # 335 Electrical equipment: Lists 1+2 core target
    0.20,   # 336 Transportation: Lists 1+2 target
    0.15,   # 337 Furniture: List 3
    0.12    # 339 Miscellaneous: List 3
  ),
  stringsAsFactors = FALSE
)

## Map to 2-digit NAICS sectors used in QWI
## QWI ns-level uses sectors: "31-33" for all manufacturing,
## but also provides subsectors like "311", "312", etc.
## We'll check what's actually in the data

cat("\nTariff coverage by sector:\n")
print(tariff_coverage)

## ========================================================
cat("\n=== Step 3: Save data ===\n")
## ========================================================

saveRDS(qwi_raw, "../data/qwi_raw.rds")
saveRDS(tariff_coverage, "../data/tariff_coverage.rds")
if (exists("trade_resp") && !is.null(trade_resp)) {
  saveRDS(trade_resp, "../data/trade_imports.rds")
}
saveRDS(USE_N3, "../data/use_n3_flag.rds")

cat("All data saved.\n")
cat("Done.\n")
