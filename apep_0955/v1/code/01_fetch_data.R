# 01_fetch_data.R — Fetch MLP panel from Azure + USDA NASS cotton data
# apep_0955: AAA Cotton Acreage Reduction and Black Sharecropper Children

source("00_packages.R")

# ---- Cotton South states (FIPS codes) ----
cotton_states <- c(1, 5, 13, 22, 28, 45, 48)  # AL, AR, GA, LA, MS, SC, TX

# ============================================================================
# STEP 1: Query MLP 1930-1940-1950 panel from Azure
# ============================================================================
cat("Connecting to Azure...\n")
con <- apep_azure_connect()

# Query Black farm children in cotton South, age 0-17 in 1930
cat("Querying MLP panel for Black farm children in cotton South...\n")
mlp_query <- sprintf("
SELECT
  histid_1930 AS histid,
  serial_1930,
  relate_1930,
  age_1930,
  sex_1930,
  race_1930,
  farm_1930,
  statefip_1930,
  countyicp_1930,
  occscore_1930,
  educ_1940,
  educ_1950,
  occscore_1940,
  occscore_1950,
  incwage_1940,
  incwage_1950,
  farm_1940,
  farm_1950,
  mover_30_40,
  mover_40_50,
  statefip_1940,
  statefip_1950
FROM 'az://derived/mlp_panel/linked_1930_1940_1950.parquet'
WHERE race_1930 = 2
  AND farm_1930 = 2
  AND age_1930 BETWEEN 0 AND 17
  AND statefip_1930 IN (%s)
", paste(cotton_states, collapse = ", "))

mlp_black <- dbGetQuery(con, mlp_query)
cat("Black farm children sample:", nrow(mlp_black), "observations\n")
stopifnot(nrow(mlp_black) > 100000)

# Also query White farm children for placebo comparison
cat("Querying White farm children for placebo comparison...\n")
mlp_white_query <- sprintf("
SELECT
  histid_1930 AS histid,
  serial_1930,
  relate_1930,
  age_1930,
  sex_1930,
  race_1930,
  farm_1930,
  statefip_1930,
  countyicp_1930,
  educ_1940,
  educ_1950,
  occscore_1940,
  occscore_1950,
  incwage_1940,
  incwage_1950,
  farm_1940,
  farm_1950,
  mover_30_40,
  mover_40_50
FROM 'az://derived/mlp_panel/linked_1930_1940_1950.parquet'
WHERE race_1930 = 1
  AND farm_1930 = 2
  AND age_1930 BETWEEN 0 AND 17
  AND statefip_1930 IN (%s)
", paste(cotton_states, collapse = ", "))

mlp_white <- dbGetQuery(con, mlp_white_query)
cat("White farm children sample:", nrow(mlp_white), "observations\n")

# ============================================================================
# STEP 2: Compute county-level cotton intensity from census aggregates
# ============================================================================
# Use share of Black farm population in each county as cotton intensity proxy
# In the cotton South, Black farm households were overwhelmingly in cotton production

cat("Computing county-level cotton intensity measures...\n")
county_query <- sprintf("
SELECT
  statefip_1930,
  countyicp_1930,
  COUNT(*) as total_pop,
  SUM(CASE WHEN race_1930 = 2 AND farm_1930 = 2 THEN 1 ELSE 0 END) as black_farm_pop,
  SUM(CASE WHEN farm_1930 = 2 THEN 1 ELSE 0 END) as farm_pop,
  SUM(CASE WHEN race_1930 = 2 THEN 1 ELSE 0 END) as black_pop,
  AVG(CASE WHEN race_1930 = 2 AND farm_1930 = 2 AND age_1930 >= 18 THEN occscore_1940 END) as adult_black_farm_occscore40
FROM 'az://derived/mlp_panel/linked_1930_1940_1950.parquet'
WHERE statefip_1930 IN (%s)
  AND age_1930 BETWEEN 0 AND 65
GROUP BY statefip_1930, countyicp_1930
HAVING COUNT(*) >= 100
", paste(cotton_states, collapse = ", "))

county_stats <- dbGetQuery(con, county_query)
cat("County-level stats:", nrow(county_stats), "counties\n")

apep_azure_disconnect(con)

# ============================================================================
# STEP 3: Try USDA NASS for historical county cotton acreage
# ============================================================================
cat("Attempting USDA NASS API for 1929 county cotton acreage...\n")

nass_key <- Sys.getenv("USDA_NASS_API_KEY", "")
if (nchar(nass_key) == 0) {
  # Try from .env
  env_file <- "../../../../.env"
  if (file.exists(env_file)) {
    lines <- readLines(env_file, warn = FALSE)
    for (line in lines) {
      if (grepl("^USDA_NASS", line)) {
        val <- sub("^[^=]+=", "", line)
        val <- gsub('["\']', '', val)
        nass_key <- trimws(val)
      }
    }
  }
}

nass_cotton <- NULL
if (nchar(nass_key) > 5) {
  # Try Census of Agriculture 1929 county-level cotton
  nass_url <- paste0(
    "https://quickstats.nass.usda.gov/api/api_GET/",
    "?key=", nass_key,
    "&commodity_desc=COTTON",
    "&statisticcat_desc=AREA HARVESTED",
    "&agg_level_desc=COUNTY",
    "&year=1929",
    "&source_desc=CENSUS"
  )

  tryCatch({
    resp <- httr::GET(nass_url, httr::timeout(30))
    if (httr::status_code(resp) == 200) {
      content <- httr::content(resp, as = "text", encoding = "UTF-8")
      json_data <- fromJSON(content)
      if (!is.null(json_data$data) && nrow(json_data$data) > 0) {
        nass_cotton <- as.data.table(json_data$data)
        cat("USDA NASS: Got", nrow(nass_cotton), "county cotton records for 1929\n")
      } else {
        cat("USDA NASS: No county-level 1929 cotton data available\n")
      }
    } else {
      cat("USDA NASS: API returned status", httr::status_code(resp), "\n")
    }
  }, error = function(e) {
    cat("USDA NASS: API error:", e$message, "\n")
  })

  # If 1929 not available, try broader year range
  if (is.null(nass_cotton)) {
    nass_url2 <- paste0(
      "https://quickstats.nass.usda.gov/api/api_GET/",
      "?key=", nass_key,
      "&commodity_desc=COTTON",
      "&statisticcat_desc=AREA PLANTED",
      "&agg_level_desc=COUNTY",
      "&year__GE=1924&year__LE=1935",
      "&source_desc=CENSUS"
    )
    tryCatch({
      resp2 <- httr::GET(nass_url2, httr::timeout(30))
      if (httr::status_code(resp2) == 200) {
        content2 <- httr::content(resp2, as = "text", encoding = "UTF-8")
        json_data2 <- fromJSON(content2)
        if (!is.null(json_data2$data) && nrow(json_data2$data) > 0) {
          nass_cotton <- as.data.table(json_data2$data)
          cat("USDA NASS: Got", nrow(nass_cotton), "county cotton records (1924-1935)\n")
        }
      }
    }, error = function(e) {
      cat("USDA NASS fallback: API error:", e$message, "\n")
    })
  }
}

# ============================================================================
# STEP 4: Construct AAA treatment from available data
# ============================================================================

# Construct county-level cotton intensity
county_dt <- as.data.table(county_stats)
county_dt[, black_farm_share := black_farm_pop / total_pop]
county_dt[, farm_share := farm_pop / total_pop]
county_dt[, black_share := black_pop / total_pop]

if (!is.null(nass_cotton) && nrow(nass_cotton) > 0) {
  cat("Using USDA NASS county cotton acreage as treatment variable\n")
  # Process NASS data and merge with county stats
  nass_cotton[, cotton_acres := as.numeric(gsub(",", "", Value))]
  nass_cotton[, state_fips := as.integer(state_fips_code)]
  nass_cotton[, county_fips := as.integer(county_code)]

  # Merge NASS cotton data with county stats
  # Note: NASS uses standard FIPS; MLP uses ICPSR county codes
  # We'll use state-level cotton intensity as a fallback mapping
  state_cotton <- nass_cotton[, .(total_cotton_acres = sum(cotton_acres, na.rm = TRUE)),
                               by = .(state_fips, year)]
  cat("State-level cotton acreage available for", nrow(state_cotton), "state-years\n")

  # Merge state cotton with county data
  county_dt <- merge(county_dt, state_cotton[year == min(year),
    .(statefip_1930 = state_fips, state_cotton_acres = total_cotton_acres)],
    by = "statefip_1930", all.x = TRUE)

  if (any(!is.na(county_dt$state_cotton_acres))) {
    # Use state cotton × county farm share as treatment intensity
    county_dt[, aaa_intensity := black_farm_share * state_cotton_acres / max(state_cotton_acres, na.rm = TRUE)]
    cat("Treatment: NASS cotton × county Black farm share\n")
  } else {
    county_dt[, aaa_intensity := black_farm_share]
    cat("Treatment: county-level Black farm share (NASS merge failed)\n")
  }
} else {
  cat("USDA NASS unavailable. Using county Black farm share as cotton intensity proxy.\n")
  cat("In the cotton South, Black farm = cotton production.\n")
  county_dt[, aaa_intensity := black_farm_share]
}

# Standardize treatment to mean 0, SD 1
county_dt[, aaa_intensity_z := (aaa_intensity - mean(aaa_intensity, na.rm = TRUE)) /
            sd(aaa_intensity, na.rm = TRUE)]

cat("\nTreatment variable summary:\n")
print(summary(county_dt$aaa_intensity))
cat("N counties:", nrow(county_dt), "\n")
cat("Treatment SD:", sd(county_dt$aaa_intensity, na.rm = TRUE), "\n")

# ============================================================================
# STEP 5: Save raw data
# ============================================================================
saveRDS(mlp_black, "../data/mlp_black_children.rds")
saveRDS(mlp_white, "../data/mlp_white_children.rds")
saveRDS(county_dt, "../data/county_treatment.rds")

cat("\nData saved successfully:\n")
cat("  mlp_black_children.rds:", nrow(mlp_black), "rows\n")
cat("  mlp_white_children.rds:", nrow(mlp_white), "rows\n")
cat("  county_treatment.rds:", nrow(county_dt), "rows\n")
