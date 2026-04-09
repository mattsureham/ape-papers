## 01_fetch_data.R — Load T-MSIS buprenorphine data + NPPES + HRSA HPSA
## apep_1446: X-waiver elimination and buprenorphine desert entry

source("00_packages.R")

## ---- Paths ----
SHARED_DATA <- file.path("..", "..", "..", "..", "data", "medicaid_provider_spending")
DATA <- "../data"
dir.create(DATA, showWarnings = FALSE, recursive = TRUE)

## ---- 1. Verify T-MSIS ----
tmsis_path <- file.path(SHARED_DATA, "tmsis.parquet")
if (!file.exists(tmsis_path)) {
  stop("T-MSIS Parquet not found at: ", tmsis_path,
       "\nDownload from: https://opendata.hhs.gov/datasets/medicaid-provider-spending/")
}

cat("Opening T-MSIS Parquet (lazy)...\n")
tmsis_ds <- open_dataset(tmsis_path)
cat(sprintf("Schema: %s\n", paste(names(tmsis_ds), collapse = ", ")))

## ---- 2. Extract buprenorphine J-code claims ----
# Buprenorphine injectable J-codes: J0571-J0575
bup_codes <- c("J0571", "J0572", "J0573", "J0574", "J0575")

cat("Filtering buprenorphine J-codes...\n")
bup_raw <- tmsis_ds |>
  filter(HCPCS_CODE %in% bup_codes) |>
  select(BILLING_PROVIDER_NPI_NUM, SERVICING_PROVIDER_NPI_NUM,
         HCPCS_CODE, CLAIM_FROM_MONTH,
         TOTAL_UNIQUE_BENEFICIARIES, TOTAL_CLAIMS, TOTAL_PAID) |>
  collect()

setDT(bup_raw)
cat(sprintf("Buprenorphine claims: %s rows\n", format(nrow(bup_raw), big.mark = ",")))

# Parse month
bup_raw[, ym := as.Date(paste0(CLAIM_FROM_MONTH, "-01"))]
bup_raw[, year := year(ym)]
bup_raw[, month := month(ym)]
bup_raw[, ym_num := year * 12 + month]

# Use servicing NPI where available, else billing NPI
bup_raw[, provider_npi := fifelse(
  !is.na(SERVICING_PROVIDER_NPI_NUM) & SERVICING_PROVIDER_NPI_NUM != "",
  SERVICING_PROVIDER_NPI_NUM,
  BILLING_PROVIDER_NPI_NUM
)]

cat(sprintf("Unique provider NPIs: %d\n", uniqueN(bup_raw$provider_npi)))
cat(sprintf("Date range: %s to %s\n", min(bup_raw$ym), max(bup_raw$ym)))

## ---- 3. Load NPPES ----
nppes_path <- file.path(SHARED_DATA, "nppes_extract.parquet")
if (!file.exists(nppes_path)) {
  stop("NPPES extract not found at: ", nppes_path,
       "\nRun a prior paper's 01_fetch_data.R or build from bulk CSV.")
}

cat("Loading NPPES extract...\n")
nppes <- as.data.table(read_parquet(nppes_path))
nppes[, npi := as.character(npi)]
cat(sprintf("NPPES: %s providers\n", format(nrow(nppes), big.mark = ",")))

# ZIP to 5-digit
if (!"zip5" %in% names(nppes)) {
  nppes[, zip5 := substr(gsub("[^0-9]", "", zip), 1, 5)]
}

## ---- 4. ZIP-to-county crosswalk ----
xwalk_path <- file.path(DATA, "zip_county_crosswalk.csv")
if (!file.exists(xwalk_path)) {
  cat("Downloading ZIP-to-county crosswalk from HUD...\n")
  # Use Census ZCTA-to-County relationship file
  xwalk_url <- "https://www2.census.gov/geo/docs/maps-data/data/rel2020/zcta520/tab20_zcta520_county20_natl.txt"
  resp <- GET(xwalk_url, write_disk(xwalk_path, overwrite = TRUE))
  if (resp$status_code != 200) {
    stop("Failed to download ZIP-county crosswalk: HTTP ", resp$status_code)
  }
}

xwalk <- fread(xwalk_path)
cat(sprintf("Crosswalk: %d rows\n", nrow(xwalk)))

# The Census file has GEOID_ZCTA5_20 and GEOID_COUNTY_20
# Map ZIP5 to county FIPS (take county with largest population overlap)
if ("GEOID_ZCTA5_20" %in% names(xwalk)) {
  xwalk[, zip5 := as.character(GEOID_ZCTA5_20)]
  xwalk[, county_fips := as.character(GEOID_COUNTY_20)]
  # Keep the county with largest area/population overlap per ZIP
  if ("AREALAND_PART" %in% names(xwalk)) {
    xwalk <- xwalk[order(-AREALAND_PART), .SD[1], by = zip5]
  } else {
    xwalk <- xwalk[, .SD[1], by = zip5]
  }
  xwalk <- xwalk[, .(zip5, county_fips)]
} else {
  # Fallback: try common column names
  zip_col <- grep("zip|zcta", names(xwalk), ignore.case = TRUE, value = TRUE)[1]
  county_col <- grep("county|fips", names(xwalk), ignore.case = TRUE, value = TRUE)[1]
  if (is.na(zip_col) || is.na(county_col)) stop("Cannot parse crosswalk columns: ", paste(names(xwalk), collapse = ", "))
  setnames(xwalk, c(zip_col, county_col), c("zip5", "county_fips"))
  xwalk[, zip5 := as.character(zip5)]
  xwalk[, county_fips := as.character(county_fips)]
  xwalk <- xwalk[, .SD[1], by = zip5]
  xwalk <- xwalk[, .(zip5, county_fips)]
}

# Pad FIPS to 5 digits
xwalk[, county_fips := str_pad(county_fips, 5, pad = "0")]
cat(sprintf("Unique ZIPs mapped: %d\n", nrow(xwalk)))

## ---- 5. Map providers to counties ----
npi_county <- merge(
  nppes[, .(npi, zip5, state)],
  xwalk,
  by = "zip5",
  all.x = FALSE
)
cat(sprintf("NPIs with county assignment: %d\n", nrow(npi_county)))

## ---- 6. HRSA HPSA data ----
hpsa_path <- file.path(DATA, "hpsa_mh.csv")
if (!file.exists(hpsa_path)) {
  cat("Downloading HRSA HPSA mental health shortage area data...\n")
  hpsa_url <- "https://data.hrsa.gov/DataDownload/DD_Files/BCD_HPSA_FCT_DET_MH.csv"
  resp <- GET(hpsa_url, write_disk(hpsa_path, overwrite = TRUE))
  if (resp$status_code != 200) {
    # Try alternative URL
    hpsa_url2 <- "https://data.hrsa.gov/data/download?data=hpsa-mh"
    resp <- GET(hpsa_url2, write_disk(hpsa_path, overwrite = TRUE))
    if (resp$status_code != 200) {
      cat("WARNING: HRSA HPSA download failed. Will use T-MSIS-based desert definition only.\n")
    }
  }
}

hpsa_counties <- character(0)
if (file.exists(hpsa_path) && file.size(hpsa_path) > 100) {
  hpsa <- fread(hpsa_path, fill = TRUE)
  cat(sprintf("HPSA raw rows: %d\n", nrow(hpsa)))
  # Extract county FIPS from HPSA data
  fips_col <- grep("fips|county.*code|geo", names(hpsa), ignore.case = TRUE, value = TRUE)
  if (length(fips_col) > 0) {
    hpsa_counties <- unique(as.character(hpsa[[fips_col[1]]]))
    hpsa_counties <- str_pad(hpsa_counties[nchar(hpsa_counties) == 5], 5, pad = "0")
    cat(sprintf("HPSA MH shortage counties: %d\n", length(hpsa_counties)))
  }
}

## ---- 7. Save intermediate data ----
write_parquet(bup_raw, file.path(DATA, "bup_claims.parquet"))
write_parquet(npi_county, file.path(DATA, "npi_county.parquet"))
saveRDS(hpsa_counties, file.path(DATA, "hpsa_mh_counties.rds"))

cat("\n=== DATA FETCH COMPLETE ===\n")
cat(sprintf("Buprenorphine claims: %s\n", format(nrow(bup_raw), big.mark = ",")))
cat(sprintf("Provider NPIs: %d\n", uniqueN(bup_raw$provider_npi)))
cat(sprintf("NPIs with county: %d\n", nrow(npi_county)))
cat(sprintf("HPSA MH counties: %d\n", length(hpsa_counties)))
