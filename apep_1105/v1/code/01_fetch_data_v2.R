# =============================================================================
# 01_fetch_data_v2.R — Complete data pipeline (fixes FIPS + ZIP crosswalk bugs)
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
    BUYER_STATE as state_abb,
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
cat(sprintf("ARCOS: %d county-state pairs\n", nrow(arcos_county)))

# --- FIPS crosswalk ---
if (!requireNamespace("tigris", quietly = TRUE)) install.packages("tigris")
fips_df <- as.data.table(tigris::fips_codes)
# tigris has: state (abbreviation), state_code, state_name, county_code, county
fips_df[, fips := paste0(state_code, county_code)]
fips_df[, county_clean := toupper(gsub(
  " County$| Parish$| Borough$| Census Area$| Municipality$| city$| City and Borough$| City$| Municipio$",
  "", county))]

# Match on state abbreviation + cleaned county name
arcos_county[, county_match := toupper(gsub("[.]", "", county_name))]
arcos_fips <- merge(
  arcos_county,
  fips_df[, .(state_abb = state, county_clean, fips)],
  by.x = c("state_abb", "county_match"),
  by.y = c("state_abb", "county_clean"),
  all.x = TRUE
)

match_rate <- mean(!is.na(arcos_fips$fips))
cat(sprintf("FIPS match rate: %.1f%% (%d of %d)\n",
            match_rate * 100, sum(!is.na(arcos_fips$fips)), nrow(arcos_fips)))

# Handle unmatched via common substitutions
if (any(is.na(arcos_fips$fips))) {
  unmatched_idx <- which(is.na(arcos_fips$fips))
  for (i in unmatched_idx) {
    st <- arcos_fips$state_abb[i]
    cn <- arcos_fips$county_match[i]
    variants <- unique(c(
      cn,
      gsub("^ST ", "SAINT ", cn),
      gsub("SAINT ", "ST ", cn),
      gsub("DEKALB", "DE KALB", cn),
      gsub("DE KALB", "DEKALB", cn),
      gsub("DESOTO", "DE SOTO", cn),
      gsub("DE SOTO", "DESOTO", cn),
      gsub("LAPORTE", "LA PORTE", cn),
      gsub("LA PORTE", "LAPORTE", cn),
      gsub("LASALLE", "LA SALLE", cn),
      gsub("LA SALLE", "LASALLE", cn),
      gsub("OBRIEN", "O'BRIEN", cn),
      gsub("O BRIEN", "O'BRIEN", cn),
      gsub("MC ", "MC", cn),
      gsub("MC([A-Z])", "MC \\1", cn)
    ))
    for (v in variants[-1]) {
      match_row <- fips_df[state == st & county_clean == v]
      if (nrow(match_row) > 0) {
        arcos_fips$fips[i] <- match_row$fips[1]
        break
      }
    }
  }
  match_rate2 <- mean(!is.na(arcos_fips$fips))
  cat(sprintf("After fuzzy matching: %.1f%% (%d of %d)\n",
              match_rate2 * 100, sum(!is.na(arcos_fips$fips)), nrow(arcos_fips)))
}

arcos_final <- arcos_fips[!is.na(fips) & total_pills > 100000]
arcos_final[, pills_per_transaction := total_pills / n_transactions]
cat(sprintf("Final ARCOS: %d counties with FIPS and >100K pills\n", nrow(arcos_final)))
fwrite(arcos_final, "../data/arcos_county_hcp_share.csv")

# =============================================================================
# 2. T-MSIS: MAT and SUD claims
# =============================================================================
cat("\nFetching T-MSIS MAT claims...\n")
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
cat(sprintf("T-MSIS MAT: %d rows, %d unique NPIs\n", nrow(mat_claims), uniqueN(mat_claims$npi)))

# Save immediately to protect against downstream crashes
fwrite(mat_claims, "../data/mat_claims_raw.csv")

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
fwrite(sud_placebo, "../data/sud_placebo_raw.csv")
cat(sprintf("SUD placebo: %d rows\n", nrow(sud_placebo)))

dbDisconnect(con, shutdown = TRUE)

# =============================================================================
# 3. NPI Geocoding
# =============================================================================
cat("\nGeocoding MAT provider NPIs via NPPES API...\n")
all_npis <- unique(c(mat_claims$npi, sud_placebo$npi))
cat(sprintf("Unique NPIs: %d\n", length(all_npis)))

geocode_npi_batch <- function(npis) {
  results <- list()
  for (npi in npis) {
    url <- sprintf("https://npiregistry.cms.hhs.gov/api/?number=%s&version=2.1", npi)
    resp <- tryCatch({
      r <- httr::GET(url, httr::timeout(10))
      if (httr::status_code(r) == 200) {
        d <- httr::content(r, as = "parsed")
        if (d$result_count > 0) {
          loc <- d$results[[1]]$addresses[[1]]
          data.table(npi = npi, state = loc$state, city = loc$city,
                     postal_code = substr(loc$postal_code, 1, 5))
        } else NULL
      } else NULL
    }, error = function(e) NULL)
    if (!is.null(resp)) results[[length(results) + 1]] <- resp
  }
  rbindlist(results, fill = TRUE)
}

npi_results <- list()
batch_size <- 50
for (i in seq(1, length(all_npis), by = batch_size)) {
  batch <- all_npis[i:min(i + batch_size - 1, length(all_npis))]
  res <- geocode_npi_batch(batch)
  if (nrow(res) > 0) npi_results[[length(npi_results) + 1]] <- res
  if (i %% 500 == 1) cat(sprintf("  %d / %d\n", min(i + batch_size - 1, length(all_npis)), length(all_npis)))
  Sys.sleep(0.05)
}
npi_geo <- rbindlist(npi_results, fill = TRUE)
cat(sprintf("Geocoded: %d of %d (%.1f%%)\n", nrow(npi_geo), length(all_npis),
            nrow(npi_geo)/length(all_npis)*100))
fwrite(npi_geo, "../data/npi_geocoded.csv")

# =============================================================================
# 4. ZIP-to-county crosswalk
# =============================================================================
cat("\nBuilding ZIP-to-county crosswalk...\n")
zip_url <- "https://www2.census.gov/geo/docs/maps-data/data/rel2020/zcta520/tab20_zcta520_county20_natl.txt"
tmp <- tempfile(fileext = ".txt")
download.file(zip_url, tmp, quiet = TRUE)
zc_raw <- fread(tmp, sep = "|")
cat(sprintf("ZIP crosswalk: %d rows, columns: %s\n", nrow(zc_raw), paste(names(zc_raw), collapse=", ")))

# Identify the ZCTA and county FIPS columns
zcta_col <- grep("ZCTA", names(zc_raw), value = TRUE)[1]
county_col <- grep("COUNTY", names(zc_raw), value = TRUE)[1]
area_col <- grep("AREALAND_PART", names(zc_raw), value = TRUE)

if (!is.null(zcta_col) && !is.null(county_col)) {
  zc <- zc_raw[, .SD, .SDcols = c(zcta_col, county_col, area_col)]
  setnames(zc, c(zcta_col, county_col), c("zcta", "county_geoid"))
  if (length(area_col) > 0) {
    setnames(zc, area_col[1], "area")
    zc <- zc[order(-area), .SD[1], by = zcta]
  } else {
    zc <- zc[, .SD[1], by = zcta]
  }
  zc[, zip5 := sprintf("%05d", as.integer(zcta))]
  zc[, county_fips := sprintf("%05d", as.integer(county_geoid))]
} else {
  # Fallback: first two columns
  setnames(zc_raw, 1:2, c("zcta", "county_geoid"))
  zc <- zc_raw[, .SD[1], by = zcta]
  zc[, zip5 := sprintf("%05d", as.integer(zcta))]
  zc[, county_fips := sprintf("%05d", as.integer(county_geoid))]
}

cat(sprintf("Unique ZCTAs: %d\n", uniqueN(zc$zip5)))

# Merge NPIs with counties
npi_geo[, zip5 := sprintf("%05s", postal_code)]
npi_county <- merge(npi_geo, zc[, .(zip5, county_fips)], by = "zip5", all.x = TRUE)
county_match_rate <- mean(!is.na(npi_county$county_fips))
cat(sprintf("NPI-to-county match: %.1f%%\n", county_match_rate * 100))
fwrite(npi_county, "../data/npi_county_geocoded.csv")

# =============================================================================
# 5. Aggregate T-MSIS to county level
# =============================================================================
cat("\nAggregating T-MSIS to county level...\n")

mat_geo <- merge(mat_claims, npi_county[, .(npi, county_fips)], by = "npi", all.x = TRUE)
mat_geo <- mat_geo[!is.na(county_fips)]
cat(sprintf("MAT claims with county: %d of %d (%.1f%%)\n",
            nrow(mat_geo), nrow(mat_claims), nrow(mat_geo)/nrow(mat_claims)*100))

mat_county <- mat_geo[, .(
  total_mat_claims = sum(claims, na.rm = TRUE),
  total_mat_beneficiaries = sum(beneficiaries, na.rm = TRUE),
  total_mat_paid = sum(paid, na.rm = TRUE),
  n_months = uniqueN(month),
  n_providers = uniqueN(npi),
  methadone_claims = sum(claims[HCPCS_CODE == "H0020"], na.rm = TRUE),
  buprenorphine_claims = sum(claims[HCPCS_CODE %in% paste0("J057", 1:5)], na.rm = TRUE),
  naltrexone_claims = sum(claims[HCPCS_CODE == "J2315"], na.rm = TRUE)
), by = .(county_fips5 = county_fips)]
mat_county[, mat_claims_per_month := total_mat_claims / n_months]
mat_county[, mat_beneficiaries_per_month := total_mat_beneficiaries / n_months]
fwrite(mat_county, "../data/tmsis_county_mat.csv")
cat(sprintf("MAT counties: %d\n", nrow(mat_county)))

sud_geo <- merge(sud_placebo, npi_county[, .(npi, county_fips)], by = "npi", all.x = TRUE)
sud_county <- sud_geo[!is.na(county_fips), .(
  sud_placebo_claims = sum(claims, na.rm = TRUE),
  sud_placebo_beneficiaries = sum(beneficiaries, na.rm = TRUE),
  n_months_sud = uniqueN(month)
), by = .(county_fips5 = county_fips)]
sud_county[, sud_claims_per_month := sud_placebo_claims / n_months_sud]
fwrite(sud_county, "../data/tmsis_county_sud_placebo.csv")

# =============================================================================
# 6. Census controls
# =============================================================================
cat("\nFetching Census ACS controls...\n")
census_key <- Sys.getenv("CENSUS_API_KEY")
acs_url <- sprintf(
  "https://api.census.gov/data/2019/acs/acs5?get=B01003_001E,B17001_002E,B17001_001E,B02001_003E,B03001_003E,B01002_001E&for=county:*&key=%s",
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
acs_df[, poverty_rate := as.numeric(B17001_002E) / as.numeric(B17001_001E)]
acs_df[, pct_black := as.numeric(B02001_003E) / population]
acs_df[, pct_hispanic := as.numeric(B03001_003E) / population]
acs_df[, median_age := as.numeric(B01002_001E)]
county_controls <- acs_df[, .(fips, population, poverty_rate, pct_black, pct_hispanic, median_age)]
county_controls[, urban_code := ifelse(population > 50000, 1, ifelse(population > 10000, 3, 5))]
fwrite(county_controls, "../data/county_controls.csv")
cat(sprintf("Census controls: %d counties\n", nrow(county_controls)))

cat("\n=== DATA FETCH COMPLETE ===\n")
cat("Files:\n")
for (f in list.files("../data/", pattern = "\\.csv$")) {
  sz <- file.size(file.path("../data/", f))
  cat(sprintf("  %s (%s)\n", f, format(sz, big.mark=",")))
}
