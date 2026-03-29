source("00_packages.R")

# Load saved data from fetch
npi_geo <- fread("../data/npi_geocoded.csv")
mat_claims <- fread("../data/mat_claims_raw.csv")
sud_placebo <- fread("../data/sud_placebo_raw.csv")
cat(sprintf("NPI geocoded: %d, MAT claims: %d, SUD placebo: %d\n",
            nrow(npi_geo), nrow(mat_claims), nrow(sud_placebo)))

# Download and parse Census ZCTA-county crosswalk properly
cat("Downloading and parsing ZIP-county crosswalk...\n")
zip_url <- "https://www2.census.gov/geo/docs/maps-data/data/rel2020/zcta520/tab20_zcta520_county20_natl.txt"
tmp <- tempfile(fileext = ".txt")
download.file(zip_url, tmp, quiet = TRUE)

# Read as all character to avoid NA issues
zc_raw <- fread(tmp, sep = "|", colClasses = "character")
cat(sprintf("Raw crosswalk: %d rows\n", nrow(zc_raw)))

# Filter to rows with valid ZCTA
zc <- zc_raw[nchar(GEOID_ZCTA5_20) > 0 & GEOID_ZCTA5_20 != ""]
cat(sprintf("Rows with valid ZCTA: %d\n", nrow(zc)))

# Keep primary county for each ZCTA (largest land area overlap)
zc[, area := as.numeric(AREALAND_PART)]
zc <- zc[order(-area), .SD[1], by = GEOID_ZCTA5_20]
zc[, zip5 := sprintf("%05s", GEOID_ZCTA5_20)]
zc[, county_fips := sprintf("%05s", GEOID_COUNTY_20)]
cat(sprintf("Unique ZCTAs: %d\n", uniqueN(zc$zip5)))

# Match NPI ZIP to county
npi_geo[, zip5 := sprintf("%05s", postal_code)]
npi_county <- merge(npi_geo, zc[, .(zip5, county_fips)], by = "zip5", all.x = TRUE)
match_rate <- mean(!is.na(npi_county$county_fips))
cat(sprintf("NPI-to-county match: %.1f%% (%d of %d)\n",
            match_rate * 100, sum(!is.na(npi_county$county_fips)), nrow(npi_county)))

fwrite(npi_county, "../data/npi_county_geocoded.csv")

# Aggregate T-MSIS to county level
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

# SUD placebo
sud_geo <- merge(sud_placebo, npi_county[, .(npi, county_fips)], by = "npi", all.x = TRUE)
sud_county <- sud_geo[!is.na(county_fips), .(
  sud_placebo_claims = sum(claims, na.rm = TRUE),
  sud_placebo_beneficiaries = sum(beneficiaries, na.rm = TRUE),
  n_months_sud = uniqueN(month)
), by = .(county_fips5 = county_fips)]
sud_county[, sud_claims_per_month := sud_placebo_claims / n_months_sud]
fwrite(sud_county, "../data/tmsis_county_sud_placebo.csv")
cat(sprintf("SUD placebo counties: %d\n", nrow(sud_county)))

cat("\n=== FIX COMPLETE ===\n")
