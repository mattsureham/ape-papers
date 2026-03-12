# =============================================================================
# 01_fetch_data.R — Fetch employment data from Azure QWI + FRED oil prices
# apep_0605: Asymmetric Resource Curse in US Shale Counties
# =============================================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

# =============================================================================
# 1. SHALE COUNTY CROSSWALK
# =============================================================================
# Counties overlying major shale plays, based on EIA Drilling Productivity
# Report regions and established literature (Feyrer et al. 2017 AER;
# Allcott & Keniston 2018 ReStud; Bartik et al. 2019).
#
# Treatment timing = first year of significant horizontal drilling production
# in each play, from EIA data.
# =============================================================================

shale_crosswalk <- data.table(
  fips = character(),
  play = character(),
  first_treat = integer()
)

# Barnett Shale, TX (first significant production ~2003)
barnett_fips <- c("48439","48251","48497","48121","48367","48221",
                  "48425","48143","48363","48237","48337","48077",
                  "48093","48429","48225")
shale_crosswalk <- rbind(shale_crosswalk,
  data.table(fips = barnett_fips, play = "Barnett", first_treat = 2003L))

# Bakken, ND/MT (first ~2006)
bakken_fips <- c(
  # ND
  "38105","38053","38061","38025","38023","38013","38089","38007",
  "38033","38011","38057","38087","38055",
  # MT
  "30083","30085","30091","30021","30025","30109"
)
shale_crosswalk <- rbind(shale_crosswalk,
  data.table(fips = bakken_fips, play = "Bakken", first_treat = 2006L))

# Marcellus/Utica, PA/WV/OH (first ~2008)
marcellus_fips <- c(
  # PA
  "42015","42117","42115","42081","42113","42125","42059","42051",
  "42129","42063","42083","42033","42105","42023",
  # WV
  "54051","54103","54095","54017","54033","54085","54041","54097",
  "54001","54049","54077","54061","54035",
  # OH
  "39013","39111","39067","39019","39029","39081","39121","39059",
  "39127","39157"
)
shale_crosswalk <- rbind(shale_crosswalk,
  data.table(fips = marcellus_fips, play = "Marcellus", first_treat = 2008L))

# Haynesville, LA/TX (first ~2008)
haynesville_fips <- c(
  # LA
  "22017","22031","22081","22015","22085","22069",
  # TX
  "48203","48365","48419","48401","48073"
)
shale_crosswalk <- rbind(shale_crosswalk,
  data.table(fips = haynesville_fips, play = "Haynesville", first_treat = 2008L))

# Eagle Ford, TX (first ~2010)
eagleford_fips <- c("48479","48283","48127","48255","48123","48177",
                    "48311","48297","48013","48493","48163","48091",
                    "48325","48149","48285","48507")
shale_crosswalk <- rbind(shale_crosswalk,
  data.table(fips = eagleford_fips, play = "Eagle Ford", first_treat = 2010L))

# Permian Basin tight oil, TX/NM (horizontal revolution ~2010)
permian_fips <- c(
  # TX
  "48329","48317","48227","48173","48383","48461","48301","48495",
  "48135","48003","48103","48475","48389","48109","48371","48243",
  "48165","48431",
  # NM
  "35025","35015"
)
shale_crosswalk <- rbind(shale_crosswalk,
  data.table(fips = permian_fips, play = "Permian", first_treat = 2010L))

# Niobrara, CO/WY (first ~2010)
niobrara_fips <- c("08123","08057","56021","56015","56031")
shale_crosswalk <- rbind(shale_crosswalk,
  data.table(fips = niobrara_fips, play = "Niobrara", first_treat = 2010L))

cat("Shale crosswalk:", nrow(shale_crosswalk), "counties across",
    length(unique(shale_crosswalk$play)), "plays\n")
cat("Treatment cohorts:\n")
print(table(shale_crosswalk$play, shale_crosswalk$first_treat))

# =============================================================================
# 2. QUERY QWI FROM AZURE
# =============================================================================

con <- apep_azure_connect()

# Query: county-year total and mining employment (aggregated from quarterly)
# Run entirely inside DuckDB for memory efficiency on 8GB RAM
# Files use lowercase state abbreviations: az://derived/qwi/sa/ns/al.parquet
# geography is BIGINT (e.g., 1001 for FIPS 01001)
# industry '00' = all industries; '21' = mining; '23' = construction
# sex = 0 = all; agegrp = 'A00' = all ages
cat("\nQuerying QWI (all states, county-year aggregation)...\n")

qwi_data <- DBI::dbGetQuery(con, "
  SELECT
    LPAD(CAST(geography AS VARCHAR), 5, '0') AS fips,
    CAST(year AS INTEGER) AS year,
    industry,
    AVG(Emp) AS avg_emp,
    AVG(EmpEnd) AS avg_emp_end,
    AVG(EarnS) AS avg_earnings,
    AVG(FrmJbGn) AS avg_job_creation,
    AVG(FrmJbLs) AS avg_job_destruction,
    AVG(HirA) AS avg_hires,
    AVG(Sep) AS avg_separations
  FROM 'az://derived/qwi/sa/ns/*.parquet'
  WHERE sex = 0
    AND agegrp = 'A00'
    AND year BETWEEN 2001 AND 2023
    AND industry IN ('00', '21', '23')
    AND geo_level = 'C'
  GROUP BY geography, year, industry
  ORDER BY geography, year, industry
")

cat("QWI data fetched:", nrow(qwi_data), "rows\n")
cat("Industries in data:", paste(sort(unique(qwi_data$industry)), collapse=", "), "\n")
cat("Years:", min(qwi_data$year), "-", max(qwi_data$year), "\n")
cat("Counties:", length(unique(qwi_data$fips)), "\n")

apep_azure_disconnect(con)

# =============================================================================
# 3. FETCH OIL PRICES FROM FRED
# =============================================================================

fred_key <- Sys.getenv("FRED_API_KEY", "")
if (nchar(fred_key) == 0) {
  stop("FRED_API_KEY not set in .env")
}

# WTI crude oil annual average
cat("\nFetching WTI crude oil prices from FRED...\n")
fred_url <- paste0(
  "https://api.stlouisfed.org/fred/series/observations?",
  "series_id=DCOILWTICO&api_key=", fred_key,
  "&file_type=json&observation_start=2000-01-01&observation_end=2024-01-01",
  "&frequency=a&aggregation_method=avg"
)

resp <- httr::GET(fred_url)
if (httr::status_code(resp) != 200) {
  stop("FRED API request failed with status ", httr::status_code(resp))
}
fred_json <- httr::content(resp, as = "text", encoding = "UTF-8")
fred_data <- jsonlite::fromJSON(fred_json)$observations

oil_prices <- data.table(
  year = as.integer(substr(fred_data$date, 1, 4)),
  wti_price = as.numeric(fred_data$value)
)
oil_prices <- oil_prices[!is.na(wti_price)]

cat("Oil price data:", nrow(oil_prices), "years\n")
cat("Price range: $", min(oil_prices$wti_price), "- $", max(oil_prices$wti_price), "\n")

# =============================================================================
# 4. SAVE RAW DATA
# =============================================================================

setDT(qwi_data)
fwrite(qwi_data, "../data/qwi_county_year.csv")
fwrite(shale_crosswalk, "../data/shale_crosswalk.csv")
fwrite(oil_prices, "../data/oil_prices.csv")

cat("\nData saved to data/ directory.\n")
cat("  qwi_county_year.csv:", nrow(qwi_data), "rows\n")
cat("  shale_crosswalk.csv:", nrow(shale_crosswalk), "rows\n")
cat("  oil_prices.csv:", nrow(oil_prices), "rows\n")
