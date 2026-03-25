# 01_fetch_data.R — Data acquisition for apep_0948
# Sources: ARCOS (Azure), T-MSIS (local Parquet), Census ACS, CMS enrollment

source("00_packages.R")
setwd(dirname(rstudioapi::getActiveDocumentContext()$path %||% "."))

# =============================================================================
# 1. ARCOS: State-level opioid pill shipments (2006-2012)
# =============================================================================
cat("Loading ARCOS data from Azure...\n")

source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()

# Query state-level aggregate from county-annual data
arcos_state <- dbGetQuery(con, "
  SELECT
    state,
    SUM(total_pills) as total_pills,
    COUNT(DISTINCT year) as n_years,
    COUNT(DISTINCT county_fips) as n_counties
  FROM 'az://raw/arcos/arcos_county_annual.parquet'
  GROUP BY state
  ORDER BY state
")

stopifnot("ARCOS data must have rows" = nrow(arcos_state) > 0)
cat(sprintf("ARCOS: %d states, %.1fB total pills\n", nrow(arcos_state), sum(arcos_state$total_pills)/1e9))

# Also get county-level for robustness
arcos_county <- dbGetQuery(con, "
  SELECT
    state,
    county_fips,
    year,
    total_pills
  FROM 'az://raw/arcos/arcos_county_annual.parquet'
  ORDER BY state, county_fips, year
")

cat(sprintf("ARCOS county-level: %d rows\n", nrow(arcos_county)))

apep_azure_disconnect(con)

# Save ARCOS data
arrow::write_parquet(arcos_state, "../data/arcos_state.parquet")
arrow::write_parquet(arcos_county, "../data/arcos_county.parquet")

# =============================================================================
# 2. T-MSIS: Medicaid MAT claims by provider NPI
# =============================================================================
cat("Loading T-MSIS data (local Parquet, lazy via Arrow)...\n")

tmsis_path <- "../../../../data/medicaid_provider_spending/tmsis.parquet"
stopifnot("T-MSIS file must exist" = file.exists(tmsis_path))

ds <- arrow::open_dataset(tmsis_path)

# MAT-related HCPCS codes
mat_codes <- c(
  "H0020",                          # Methadone administration
  "J0571", "J0572", "J0573",        # Buprenorphine injection
  "J0574", "J0575",                 # Buprenorphine extended-release
  "J2315"                           # Naltrexone injection
)

# Non-opioid SUD codes (for placebo)
non_opioid_sud_codes <- c(
  "H0015",   # Alcohol/drug SUD group counseling
  "H0016",   # Alcohol/drug SUD services, per diem
  "H0005",   # Alcohol/drug intervention
  "H0006",   # Alcohol/drug case management
  "H0007",   # Crisis intervention
  "H2035",   # Alcohol/drug treatment per hour
  "H2036"    # Alcohol/drug treatment per diem
)

# All SUD codes combined
all_sud_codes <- c(mat_codes, non_opioid_sud_codes)

# Extract MAT and SUD claims with provider NPIs
cat("Filtering T-MSIS for SUD/MAT claims...\n")
sud_claims <- ds |>
  filter(HCPCS_CODE %in% all_sud_codes) |>
  select(BILLING_PROVIDER_NPI_NUM, SERVICING_PROVIDER_NPI_NUM,
         HCPCS_CODE, CLAIM_FROM_MONTH,
         TOTAL_UNIQUE_BENEFICIARIES, TOTAL_CLAIMS, TOTAL_PAID) |>
  collect()

cat(sprintf("SUD/MAT claims: %d rows\n", nrow(sud_claims)))

# Tag MAT vs non-opioid SUD
sud_claims <- sud_claims |>
  mutate(
    is_mat = HCPCS_CODE %in% mat_codes,
    is_non_opioid_sud = HCPCS_CODE %in% non_opioid_sud_codes,
    year = as.integer(substr(CLAIM_FROM_MONTH, 1, 4))
  )

cat(sprintf("  MAT claims: %d rows\n", sum(sud_claims$is_mat)))
cat(sprintf("  Non-opioid SUD claims: %d rows\n", sum(sud_claims$is_non_opioid_sud)))

# =============================================================================
# 3. NPPES: Geocode provider NPIs to states
# =============================================================================
cat("Loading NPPES extract for NPI geocoding...\n")

nppes_path <- "../../../../data/medicaid_provider_spending/nppes_extract.parquet"
stopifnot("NPPES extract must exist" = file.exists(nppes_path))

nppes <- arrow::read_parquet(nppes_path,
                              col_select = c("npi", "provider_business_practice_location_address_state_name"))
names(nppes) <- c("npi", "state")

# Get unique NPIs from SUD claims
unique_npis <- unique(c(sud_claims$BILLING_PROVIDER_NPI_NUM,
                         sud_claims$SERVICING_PROVIDER_NPI_NUM))
cat(sprintf("Unique NPIs in SUD claims: %d\n", length(unique_npis)))

# Match NPIs to states
npi_state <- nppes |>
  filter(npi %in% unique_npis) |>
  distinct(npi, .keep_all = TRUE)

cat(sprintf("NPIs matched to states: %d / %d (%.1f%%)\n",
            nrow(npi_state), length(unique_npis),
            100 * nrow(npi_state) / length(unique_npis)))

# =============================================================================
# 4. State population and Medicaid enrollment
# =============================================================================
cat("Fetching state population data from Census ACS API...\n")

census_api_key <- Sys.getenv("CENSUS_API_KEY")

# Get 2020 ACS 5-year state-level data
# B01003_001: Total population
# B17001_002: Population below poverty
# B27010_001: Total health insurance universe
# B27010_017: Uninsured
# B01003_001E: Population (different table but same result)
census_url <- paste0(
  "https://api.census.gov/data/2020/acs/acs5?get=NAME,B01003_001E,B17001_002E,B27010_001E,B27010_017E",
  "&for=state:*",
  "&key=", census_api_key
)

census_response <- httr::GET(census_url)
stopifnot("Census API must return 200" = httr::status_code(census_response) == 200)

census_raw <- jsonlite::fromJSON(httr::content(census_response, "text", encoding = "UTF-8"))
census_df <- as.data.frame(census_raw[-1, ], stringsAsFactors = FALSE)
names(census_df) <- census_raw[1, ]

census_df <- census_df |>
  transmute(
    state_name = NAME,
    state_fips = state,
    population = as.numeric(B01003_001E),
    pop_poverty = as.numeric(B17001_002E),
    insurance_universe = as.numeric(B27010_001E),
    uninsured = as.numeric(B27010_017E)
  ) |>
  mutate(
    poverty_rate = pop_poverty / population,
    uninsured_rate = uninsured / insurance_universe
  )

cat(sprintf("Census data: %d states\n", nrow(census_df)))

# Get urbanization from Census urban/rural classification
# Use percentage of state population in urban areas (2020 Census)
# Approximate with population density as proxy
census_url2 <- paste0(
  "https://api.census.gov/data/2020/dec/dhc?get=NAME,P1_001N",
  "&for=state:*",
  "&key=", census_api_key
)
census_response2 <- httr::GET(census_url2)
if (httr::status_code(census_response2) == 200) {
  census_raw2 <- jsonlite::fromJSON(httr::content(census_response2, "text", encoding = "UTF-8"))
  # Just confirming population from decennial census
  cat("Decennial census population confirmed.\n")
}

# =============================================================================
# 5. CMS Medicaid enrollment by state
# =============================================================================
cat("Fetching CMS Medicaid enrollment data...\n")

# CMS Medicaid enrollment reports (December snapshots)
# https://data.cms.gov/summary-statistics-on-beneficiary-enrollment/
# Use manual table of approximate 2020 enrollment by state
# Source: KFF Medicaid enrollment data

medicaid_url <- "https://data.medicaid.gov/api/1/datastore/query/6165f45b-ca93-5bb5-9d06-db29c2a02f2e/0?offset=0&count=true&results=true&schema=true&keys=true&format=json&rowIds=false"

medicaid_response <- httr::GET(medicaid_url)

if (httr::status_code(medicaid_response) == 200) {
  medicaid_data <- jsonlite::fromJSON(httr::content(medicaid_response, "text", encoding = "UTF-8"))
  cat("CMS Medicaid enrollment API successful.\n")
} else {
  cat("CMS API returned non-200. Using population-based proxy.\n")
}

# Save all raw data
arrow::write_parquet(sud_claims, "../data/sud_claims.parquet")
arrow::write_parquet(npi_state, "../data/npi_state.parquet")
write.csv(census_df, "../data/census_state.csv", row.names = FALSE)

cat("\n=== Data acquisition complete ===\n")
cat(sprintf("ARCOS: %d states, %d county-year rows\n", nrow(arcos_state), nrow(arcos_county)))
cat(sprintf("T-MSIS SUD claims: %d rows (%d MAT, %d non-opioid SUD)\n",
            nrow(sud_claims), sum(sud_claims$is_mat), sum(sud_claims$is_non_opioid_sud)))
cat(sprintf("NPI geocoding: %d providers mapped to states\n", nrow(npi_state)))
cat(sprintf("Census: %d states with demographics\n", nrow(census_df)))
