# =============================================================================
# 01_fetch_data.R — Fetch ARCOS, T-MSIS, NPPES, and CDC WONDER data
# apep_1105: Treatment Dividend of Supply-Side Opioid Restrictions
# =============================================================================
source("00_packages.R")

# --- Azure connection ---
con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure; LOAD azure;")
cs <- Sys.getenv("AZURE_STORAGE_CONNECTION_STRING")
stopifnot("Azure connection string too short" = nchar(cs) > 50)
dbExecute(con, sprintf("CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '%s');", cs))
cat("Connected to Azure\n")

# =============================================================================
# 1. ARCOS: County-level HCP share (2006–2012)
# =============================================================================
cat("Fetching ARCOS county-level drug shares...\n")
arcos_county <- dbGetQuery(con, "
  SELECT
    BUYER_STATE as state,
    BUYER_COUNTY as county_name,
    SUM(CASE WHEN DRUG_NAME='HYDROCODONE' THEN DOSAGE_UNIT ELSE 0 END) as hcp_pills,
    SUM(CASE WHEN DRUG_NAME='OXYCODONE' THEN DOSAGE_UNIT ELSE 0 END) as oxy_pills,
    SUM(DOSAGE_UNIT) as total_pills,
    COUNT(*) as n_transactions
  FROM 'az://raw/arcos/arcos_transactions.parquet'
  GROUP BY BUYER_STATE, BUYER_COUNTY
")
arcos_county <- as.data.table(arcos_county)
arcos_county[, hcp_share := hcp_pills / total_pills]
arcos_county[, pills_per_transaction := total_pills / n_transactions]

cat(sprintf("ARCOS: %d county-state pairs, total pills: %.1fB\n",
            nrow(arcos_county), sum(arcos_county$total_pills) / 1e9))
cat(sprintf("HCP share: mean=%.3f, sd=%.3f, min=%.3f, max=%.3f\n",
            mean(arcos_county$hcp_share, na.rm=TRUE),
            sd(arcos_county$hcp_share, na.rm=TRUE),
            min(arcos_county$hcp_share, na.rm=TRUE),
            max(arcos_county$hcp_share, na.rm=TRUE)))

# --- FIPS crosswalk: county names to FIPS codes ---
# Use tigris fips_codes for matching
if (!requireNamespace("tigris", quietly = TRUE)) install.packages("tigris")
fips_df <- as.data.table(tigris::fips_codes)
fips_df[, fips := paste0(state_code, county_code)]
fips_df[, county_upper := toupper(gsub(" County$| Parish$| Borough$| Census Area$| Municipality$| city$", "",
                                        county))]
fips_df[, state_upper := state]

# ARCOS county names are uppercase; match to FIPS
arcos_county[, county_clean := gsub("\\.", "", toupper(county_name))]
# State abbreviation to state name mapping
state_map <- unique(fips_df[, .(state_upper = state, state_abb = state_code)])
# Actually fips_codes has state as full name, and state_code as 2-digit FIPS
# ARCOS BUYER_STATE is 2-letter abbreviation
# tigris has state_code (2-digit FIPS) and state (full name)
# Let's use a simpler mapping
state_abb_map <- data.table(
  abb = state.abb,
  name = state.name
)
# Add DC, PR, GU, VI
state_abb_map <- rbind(state_abb_map, data.table(
  abb = c("DC", "PR", "GU", "VI", "MP", "AS"),
  name = c("District of Columbia", "Puerto Rico", "Guam", "Virgin Islands",
           "Northern Mariana Islands", "American Samoa")
))

arcos_county <- merge(arcos_county, state_abb_map, by.x = "state", by.y = "abb", all.x = TRUE)
fips_df[, state_name := state]

# Merge ARCOS with FIPS
arcos_fips <- merge(
  arcos_county,
  fips_df[, .(state_name = state, county_upper, fips, county_code, state_code)],
  by.x = c("name", "county_clean"),
  by.y = c("state_name", "county_upper"),
  all.x = TRUE
)

# Check match rate
match_rate <- mean(!is.na(arcos_fips$fips))
cat(sprintf("FIPS match rate: %.1f%% (%d of %d)\n",
            match_rate * 100, sum(!is.na(arcos_fips$fips)), nrow(arcos_fips)))

# Keep matched counties with meaningful volume
arcos_final <- arcos_fips[!is.na(fips) & total_pills > 100000]
cat(sprintf("After filtering: %d counties with FIPS and >100K pills\n", nrow(arcos_final)))

# Save
fwrite(arcos_final, "../data/arcos_county_hcp_share.csv")
cat("Saved arcos_county_hcp_share.csv\n")

# =============================================================================
# 2. T-MSIS: County-level MAT utilization (2018–2024)
# =============================================================================
cat("\nFetching T-MSIS MAT claims...\n")

# First get all MAT provider NPIs and their claims
mat_claims <- dbGetQuery(con, "
  SELECT
    BILLING_PROVIDER_NPI_NUM as npi,
    HCPCS_CODE,
    CLAIM_FROM_MONTH as month,
    TOTAL_CLAIMS as claims,
    TOTAL_UNIQUE_BENEFICIARIES as beneficiaries,
    TOTAL_PAID as paid
  FROM 'az://raw/medicaid/tmsis.parquet'
  WHERE HCPCS_CODE IN ('H0020', 'J0571', 'J0572', 'J0573', 'J0574', 'J0575', 'J2315')
")
mat_claims <- as.data.table(mat_claims)
cat(sprintf("T-MSIS MAT claims: %d rows, %d unique NPIs\n",
            nrow(mat_claims), uniqueN(mat_claims$npi)))

# Also get non-opioid SUD treatment (placebo outcomes)
sud_placebo <- dbGetQuery(con, "
  SELECT
    BILLING_PROVIDER_NPI_NUM as npi,
    HCPCS_CODE,
    CLAIM_FROM_MONTH as month,
    TOTAL_CLAIMS as claims,
    TOTAL_UNIQUE_BENEFICIARIES as beneficiaries
  FROM 'az://raw/medicaid/tmsis.parquet'
  WHERE HCPCS_CODE IN ('H0015', 'H0016')
")
sud_placebo <- as.data.table(sud_placebo)
cat(sprintf("SUD placebo claims: %d rows\n", nrow(sud_placebo)))

dbDisconnect(con, shutdown = TRUE)

# =============================================================================
# 3. NPPES: Geocode provider NPIs to counties
# =============================================================================
cat("\nGeocoding MAT provider NPIs via NPPES bulk download...\n")

# Get unique NPIs from MAT + placebo
all_npis <- unique(c(mat_claims$npi, sud_placebo$npi))
cat(sprintf("Total unique NPIs to geocode: %d\n", length(all_npis)))

# Use NPPES API for geocoding (batch)
geocode_npi <- function(npi_batch) {
  results <- list()
  for (npi in npi_batch) {
    url <- sprintf("https://npiregistry.cms.hhs.gov/api/?number=%s&version=2.1", npi)
    resp <- tryCatch({
      r <- httr::GET(url, httr::timeout(10))
      if (httr::status_code(r) == 200) {
        d <- httr::content(r, as = "parsed")
        if (d$result_count > 0) {
          loc <- d$results[[1]]$addresses[[1]]
          data.table(
            npi = npi,
            state = loc$state,
            city = loc$city,
            postal_code = substr(loc$postal_code, 1, 5)
          )
        } else NULL
      } else NULL
    }, error = function(e) NULL)
    if (!is.null(resp)) results[[length(results) + 1]] <- resp
  }
  rbindlist(results, fill = TRUE)
}

# Geocode in batches of 50 with rate limiting
cat("Geocoding via NPPES API (this takes ~5-10 minutes)...\n")
batch_size <- 50
npi_geo_results <- list()
for (i in seq(1, length(all_npis), by = batch_size)) {
  batch <- all_npis[i:min(i + batch_size - 1, length(all_npis))]
  res <- geocode_npi(batch)
  if (nrow(res) > 0) npi_geo_results[[length(npi_geo_results) + 1]] <- res
  if (i %% 500 == 1) cat(sprintf("  Geocoded %d / %d NPIs\n", min(i + batch_size - 1, length(all_npis)), length(all_npis)))
  Sys.sleep(0.1)  # Rate limit
}
npi_geo <- rbindlist(npi_geo_results, fill = TRUE)
cat(sprintf("Geocoded %d of %d NPIs (%.1f%%)\n",
            nrow(npi_geo), length(all_npis), nrow(npi_geo) / length(all_npis) * 100))

# Map ZIP to county FIPS using HUD USPS ZIP crosswalk or census
# Simple approach: use ZIP-to-county crosswalk
# Fetch HUD crosswalk
cat("Fetching ZIP-to-county crosswalk...\n")
zip_county_url <- "https://www2.census.gov/geo/docs/maps-data/data/rel2020/zcta520/tab20_zcta520_county20_natl.txt"
zip_county <- tryCatch({
  tmp <- tempfile(fileext = ".txt")
  download.file(zip_county_url, tmp, quiet = TRUE)
  fread(tmp, sep = "|")
}, error = function(e) {
  cat("Census crosswalk failed, trying alternative...\n")
  # Alternative: simple ZIP prefix mapping
  NULL
})

if (!is.null(zip_county)) {
  # Census crosswalk has ZCTA and county GEOID
  setnames(zip_county, c("GEOID_ZCTA_5_20", "GEOID_COUNTY_20"), c("zcta", "county_fips"), skip_absent = TRUE)
  # Keep primary county for each ZIP (highest AREALAND overlap)
  if ("AREALAND_PART" %in% names(zip_county)) {
    zip_county <- zip_county[order(-AREALAND_PART), .SD[1], by = zcta]
  }
  zip_county[, zip5 := sprintf("%05d", as.integer(zcta))]
  zip_county[, county_fips5 := sprintf("%05d", as.integer(county_fips))]

  # Merge NPI geocodes with county FIPS
  npi_geo[, zip5 := sprintf("%05s", postal_code)]
  npi_county <- merge(npi_geo, zip_county[, .(zip5, county_fips5)], by = "zip5", all.x = TRUE)

  match_rate_county <- mean(!is.na(npi_county$county_fips5))
  cat(sprintf("ZIP-to-county match rate: %.1f%%\n", match_rate_county * 100))
} else {
  # Fallback: use state-level only
  cat("WARNING: ZIP-to-county crosswalk unavailable. Using state-level aggregation.\n")
  npi_county <- npi_geo
  npi_county[, county_fips5 := NA_character_]
}

# Save geocoded NPIs
fwrite(npi_county, "../data/npi_county_geocoded.csv")

# =============================================================================
# 4. Aggregate T-MSIS to county level
# =============================================================================
cat("\nAggregating T-MSIS to county level...\n")

# Merge MAT claims with county
mat_claims_geo <- merge(mat_claims, npi_county[, .(npi, county_fips5, state)],
                        by = "npi", all.x = TRUE)

# Drop unmatched
mat_geo <- mat_claims_geo[!is.na(county_fips5)]
cat(sprintf("MAT claims with county FIPS: %d of %d (%.1f%%)\n",
            nrow(mat_geo), nrow(mat_claims), nrow(mat_geo) / nrow(mat_claims) * 100))

# County-level totals (averaged across months)
mat_county <- mat_geo[, .(
  total_mat_claims = sum(claims, na.rm = TRUE),
  total_mat_beneficiaries = sum(beneficiaries, na.rm = TRUE),
  total_mat_paid = sum(paid, na.rm = TRUE),
  n_months = uniqueN(month),
  n_providers = uniqueN(npi),
  # By modality
  methadone_claims = sum(claims[HCPCS_CODE == "H0020"], na.rm = TRUE),
  buprenorphine_claims = sum(claims[HCPCS_CODE %in% c("J0571", "J0572", "J0573", "J0574", "J0575")], na.rm = TRUE),
  naltrexone_claims = sum(claims[HCPCS_CODE == "J2315"], na.rm = TRUE)
), by = county_fips5]

# Monthly averages
mat_county[, mat_claims_per_month := total_mat_claims / n_months]
mat_county[, mat_beneficiaries_per_month := total_mat_beneficiaries / n_months]

cat(sprintf("MAT county dataset: %d counties\n", nrow(mat_county)))

# Same for placebo SUD
sud_placebo_geo <- merge(sud_placebo, npi_county[, .(npi, county_fips5)],
                         by = "npi", all.x = TRUE)
sud_county <- sud_placebo_geo[!is.na(county_fips5), .(
  sud_placebo_claims = sum(claims, na.rm = TRUE),
  sud_placebo_beneficiaries = sum(beneficiaries, na.rm = TRUE),
  n_months_sud = uniqueN(month)
), by = county_fips5]
sud_county[, sud_claims_per_month := sud_placebo_claims / n_months_sud]

# Save
fwrite(mat_county, "../data/tmsis_county_mat.csv")
fwrite(sud_county, "../data/tmsis_county_sud_placebo.csv")

# =============================================================================
# 5. County controls from Census API
# =============================================================================
cat("\nFetching county controls from Census ACS...\n")
census_key <- Sys.getenv("CENSUS_API_KEY")

# ACS 5-year 2019 (pre-COVID, post-rescheduling)
acs_url <- sprintf(
  "https://api.census.gov/data/2019/acs/acs5?get=B01003_001E,B17001_002E,B17001_001E,B02001_003E,B03001_003E,B01002_001E,B01003_001E&for=county:*&key=%s",
  census_key
)
acs_resp <- httr::GET(acs_url)
stopifnot("Census API failed" = httr::status_code(acs_resp) == 200)
acs_raw <- httr::content(acs_resp, as = "text")
acs_mat <- jsonlite::fromJSON(acs_raw)
acs_df <- as.data.table(acs_mat[-1, ])
setnames(acs_df, acs_mat[1, ])
acs_df[, fips := paste0(state, county)]
acs_df[, population := as.numeric(B01003_001E)]
acs_df[, pov_count := as.numeric(B17001_002E)]
acs_df[, pov_universe := as.numeric(B17001_001E)]
acs_df[, poverty_rate := pov_count / pov_universe]
acs_df[, black_pop := as.numeric(B02001_003E)]
acs_df[, pct_black := black_pop / population]
acs_df[, hispanic_pop := as.numeric(B03001_003E)]
acs_df[, pct_hispanic := hispanic_pop / population]
acs_df[, median_age := as.numeric(B01002_001E)]

# Urban-rural from NCHS
cat("Fetching urban-rural classification...\n")
nchs_url <- "https://www.cdc.gov/nchs/data/data_acces_files/NCHSURCodes2013.xlsx"
nchs_file <- tempfile(fileext = ".xlsx")
tryCatch({
  download.file(nchs_url, nchs_file, mode = "wb", quiet = TRUE)
  if (requireNamespace("readxl", quietly = TRUE)) {
    nchs <- as.data.table(readxl::read_excel(nchs_file))
    setnames(nchs, c("FIPS code", "2013 code"), c("fips", "urban_code"), skip_absent = TRUE)
  } else {
    nchs <- NULL
  }
}, error = function(e) {
  cat("NCHS download failed, using population as urbanicity proxy\n")
  nchs <<- NULL
})

# Combine controls
county_controls <- acs_df[, .(fips, population, poverty_rate, pct_black, pct_hispanic, median_age)]
if (!is.null(nchs) && "fips" %in% names(nchs)) {
  nchs[, fips := sprintf("%05d", as.integer(fips))]
  county_controls <- merge(county_controls, nchs[, .(fips, urban_code)], by = "fips", all.x = TRUE)
} else {
  county_controls[, urban_code := ifelse(population > 50000, 1, ifelse(population > 10000, 3, 5))]
}

fwrite(county_controls, "../data/county_controls.csv")
cat(sprintf("County controls: %d counties\n", nrow(county_controls)))

# =============================================================================
# 6. CDC WONDER: County opioid overdose deaths
# =============================================================================
cat("\nFetching CDC WONDER overdose mortality data...\n")
# CDC WONDER doesn't have a simple REST API; use pre-built county-level mortality
# from CDC's published datasets
# Drug overdose death rates by county (2020 vintage)
wonder_url <- "https://data.cdc.gov/api/views/p56q-lrp4/rows.csv?accessType=DOWNLOAD"
wonder_file <- tempfile(fileext = ".csv")
tryCatch({
  download.file(wonder_url, wonder_file, quiet = TRUE)
  wonder <- fread(wonder_file)
  cat(sprintf("CDC overdose data: %d rows\n", nrow(wonder)))
  fwrite(wonder, "../data/cdc_overdose_county.csv")
}, error = function(e) {
  cat("CDC WONDER download failed:", e$message, "\n")
  cat("Will proceed with T-MSIS outcome only\n")
})

cat("\n=== DATA FETCH COMPLETE ===\n")
cat("Files in data/:\n")
cat(paste(list.files("../data/"), collapse = "\n"), "\n")
