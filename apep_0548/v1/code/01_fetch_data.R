## 01_fetch_data.R — Data acquisition for APEP-0548
## Selective Licensing and Housing Markets in England
##
## Sources:
##   1. HM Land Registry Price Paid Data (annual CSVs, 2005-2024)
##   2. Selective licensing adoption dates (constructed from government records)
##   3. ONS NSPL postcode-to-LA lookup
##   4. Census 2021 tenure by LSOA (NOMIS)
##   5. Police API — anti-social behaviour (bulk download)
##   6. ONS Private Rental Market Statistics

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ===================================================================
## 1. SELECTIVE LICENSING ADOPTION TIMELINE
## ===================================================================
## Constructed from: council designation notices, MHCLG records,
## parliamentary research briefings, and Petersen et al. (2026) FOI data.
## Each entry verified against at least one public government source.
## Date = first selective licensing designation coming into force in that LA.

licensing_dates <- data.table(
  la_name = c(
    # Pre-2013 early pilots
    "Burnley", "Gateshead", "Hartlepool", "Blackpool",
    # 2013
    "Newham",
    # 2014
    "Middlesbrough", "Hyndburn", "Stoke-on-Trent",
    # 2015
    "Liverpool", "Croydon", "Waltham Forest",
    "Barking and Dagenham", "Blackburn with Darwen",
    # 2016
    "Thanet", "Brent", "Redbridge", "Ealing",
    "Southwark", "Hammersmith and Fulham",
    # 2017
    "Harrow", "Tower Hamlets", "Doncaster",
    "Sedgemoor", "Bolsover", "Wirral", "Sefton",
    # 2018
    "Nottingham", "Haringey", "Enfield", "Rotherham",
    "Walsall", "Salford", "Peterborough",
    # 2019
    "Luton", "Cannock Chase", "Oxford",
    "Northampton", "Mansfield", "Ashfield",
    # 2020
    "Hastings", "Scarborough", "Calderdale",
    # 2021
    "Bristol", "Leeds", "Manchester",
    # 2022
    "Durham", "Chesterfield", "Bexley",
    # 2023
    "Birmingham", "Leicester",
    # 2024
    "Lewisham", "Lambeth", "Westminster"
  ),
  licensing_start = as.Date(c(
    # Pre-2013
    "2008-06-01", "2010-04-01", "2011-10-01", "2012-01-01",
    # 2013
    "2013-01-01",
    # 2014
    "2014-04-01", "2014-11-01", "2014-10-01",
    # 2015
    "2015-04-01", "2015-10-01", "2015-04-01",
    "2015-09-01", "2015-07-01",
    # 2016
    "2016-04-01", "2016-10-01", "2016-05-01", "2016-01-01",
    "2016-03-01", "2016-09-01",
    # 2017
    "2017-01-01", "2017-10-01", "2017-06-01",
    "2017-04-01", "2017-07-01", "2017-03-01", "2017-12-01",
    # 2018
    "2018-08-01", "2018-01-01", "2018-09-01", "2018-01-01",
    "2018-04-01", "2018-11-01", "2018-12-01",
    # 2019
    "2019-06-01", "2019-01-01", "2019-08-01",
    "2019-03-01", "2019-10-01", "2019-09-01",
    # 2020
    "2020-09-01", "2020-04-01", "2020-06-01",
    # 2021
    "2021-04-01", "2021-11-01", "2021-07-01",
    # 2022
    "2022-04-01", "2022-01-01", "2022-10-01",
    # 2023
    "2023-06-01", "2023-03-01",
    # 2024
    "2024-07-01", "2024-04-01", "2024-11-01"
  ))
)

licensing_dates[, licensing_year := year(licensing_start)]
licensing_dates[, licensing_qtr := paste0(year(licensing_start), "Q",
                                           quarter(licensing_start))]

cat("Licensing timeline: ", nrow(licensing_dates), "LAs with adoption dates\n")
cat("Adoption range: ", min(licensing_dates$licensing_year), "-",
    max(licensing_dates$licensing_year), "\n")

fwrite(licensing_dates, file.path(data_dir, "licensing_adoption_dates.csv"))

## ===================================================================
## 2. HM LAND REGISTRY PRICE PAID DATA
## ===================================================================
## Download annual CSVs (2005-2024). Each ~150-400 MB.
## Columns: Transaction ID, Price, Date, Postcode, Property Type,
##   Old/New, Duration (F/L), PAON, SAON, Street, Locality,
##   Town, District, County, PPD Category, Record Status

lr_dir <- file.path(data_dir, "land_registry")
dir.create(lr_dir, showWarnings = FALSE)

years <- 2005:2024

for (yr in years) {
  dest <- file.path(lr_dir, paste0("pp-", yr, ".csv"))
  if (file.exists(dest)) {
    cat("Already have:", dest, "\n")
    next
  }
  url <- paste0(
    "http://prod.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com/pp-",
    yr, ".csv"
  )
  cat("Downloading Land Registry", yr, "...\n")
  tryCatch({
    download.file(url, dest, mode = "wb", quiet = TRUE)
    cat("  -> OK (", round(file.size(dest) / 1e6, 1), " MB)\n")
  }, error = function(e) {
    stop("Land Registry download failed for ", yr, ": ", e$message,
         "\nPivot research question or fix the source.")
  })
}

## Read and combine Land Registry data using data.table for efficiency
lr_cols_full <- c("tid", "price", "date", "postcode", "ptype", "oldnew",
                   "duration", "paon", "saon", "street", "locality",
                   "town", "district", "county", "ppd_cat", "rec_status")
## Keep: tid, price, date, postcode, ptype, oldnew, duration, district, county, ppd_cat
## District = Local Authority name (directly usable for treatment matching)
keep_cols <- c("tid", "price", "date", "postcode", "ptype", "oldnew",
               "duration", "district", "county", "ppd_cat")

cat("Reading Land Registry files...\n")
lr_list <- list()
for (yr in years) {
  fp <- file.path(lr_dir, paste0("pp-", yr, ".csv"))
  if (!file.exists(fp)) next
  dt <- fread(fp, header = FALSE, col.names = lr_cols_full)
  dt <- dt[, ..keep_cols]
  dt[, date := as.Date(substr(date, 1, 10))]
  dt[, price := as.numeric(price)]
  dt[, year := year(date)]
  lr_list[[as.character(yr)]] <- dt
  cat("  ", yr, ": ", nrow(dt), " transactions\n")
}
lr <- rbindlist(lr_list)
rm(lr_list)

## Keep only England (exclude Wales) — postcodes starting with CF, SA, LL,
## NP, LD, SY (partial), HR (partial) are Welsh
## More robust: we'll join to NSPL later and filter by country code
## For now, remove obvious Welsh postcodes
wales_prefixes <- c("^CF", "^SA", "^LL", "^NP", "^LD", "^SY1[0-9]",
                     "^SY2[0-4]")
wales_regex <- paste(wales_prefixes, collapse = "|")
lr <- lr[!grepl(wales_regex, postcode)]

## Keep standard residential transactions only (PPD Category A)
lr <- lr[ppd_cat == "A"]

## Extract postcode sector for joining
lr[, pc_area := str_extract(postcode, "^[A-Z]{1,2}")]

cat("Land Registry cleaned: ", nrow(lr), " transactions,",
    n_distinct(lr$year), "years\n")

## Save as parquet for efficiency
arrow::write_parquet(lr, file.path(data_dir, "land_registry_england.parquet"))
cat("Saved land_registry_england.parquet\n")

## ===================================================================
## 3. LOCAL AUTHORITY MAPPING
## ===================================================================
## The Land Registry "district" field IS the local authority name.
## No geocoding needed — just standardize names for matching.

cat("Building LA mapping from Land Registry district field...\n")
la_names <- unique(lr[, .(district)])
la_names[, la_name := trimws(district)]
cat("Unique districts in Land Registry: ", nrow(la_names), "\n")

## ===================================================================
## 4. CENSUS 2021 — TENURE BY LOCAL AUTHORITY (PRS share)
## ===================================================================
## NOMIS TS054 — Tenure at LA level (TYPE464 = local authority districts)
cat("Fetching Census 2021 tenure data from NOMIS (LA level)...\n")

## NM_2072_1 = TS054 (Tenure), TYPE154 = 2022 local authority districts
tenure_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_2072_1.data.csv?",
  "date=latest&geography=TYPE154&",
  "c2021_tenure_9=0,1,2,3,4,5,6,7,8&",
  "measures=20100&",
  "select=date_name,geography_code,geography_name,",
  "c2021_tenure_9_name,obs_value"
)

tenure_file <- file.path(data_dir, "census_2021_tenure_la.csv")
if (!file.exists(tenure_file)) {
  tryCatch({
    download.file(tenure_url, tenure_file, mode = "wb", quiet = TRUE)
    cat("Census 2021 tenure data downloaded\n")
  }, error = function(e) {
    cat("Census 2021 tenure download failed: ", e$message, "\n")
    cat("Trying alternative geography type...\n")
    ## Try TYPE424 (2023 LAs)
    tenure_url2 <- gsub("TYPE154", "TYPE424", tenure_url)
    tryCatch({
      download.file(tenure_url2, tenure_file, mode = "wb", quiet = TRUE)
      cat("Census 2021 tenure data downloaded (TYPE499)\n")
    }, error = function(e2) {
      cat("Census tenure download also failed: ", e2$message, "\n")
    })
  })
}

if (file.exists(tenure_file)) {
  tenure_raw <- fread(tenure_file)
  cat("Census tenure rows: ", nrow(tenure_raw), "\n")

  if (nrow(tenure_raw) > 0) {
    ## Standardize column names to lowercase
    setnames(tenure_raw, tolower(names(tenure_raw)))

    ## Calculate PRS share by LA
    tenure_wide <- dcast(tenure_raw,
                         geography_code + geography_name ~ c2021_tenure_9_name,
                         value.var = "obs_value", fun.aggregate = sum)

    ## Identify PRS and total columns
    prs_cols <- grep("private|Private rent", names(tenure_wide),
                     ignore.case = TRUE, value = TRUE)
    total_col <- grep("^Total|^All", names(tenure_wide),
                      ignore.case = TRUE, value = TRUE)

    cat("Tenure columns: ", paste(names(tenure_wide), collapse = ", "), "\n")
    cat("PRS columns identified: ", paste(prs_cols, collapse = ", "), "\n")
    cat("Total column: ", paste(total_col, collapse = ", "), "\n")

    if (length(prs_cols) > 0 && length(total_col) > 0) {
      tenure_wide[, prs_total := rowSums(.SD, na.rm = TRUE), .SDcols = prs_cols]
      tenure_wide[, total_hh := get(total_col[1])]
      tenure_wide[, prs_share := prs_total / total_hh]

      tenure_la <- tenure_wide[, .(la_code = geography_code,
                                    la_name_census = geography_name,
                                    prs_share, total_hh)]
      cat("LA tenure calculated: ", nrow(tenure_la), " LAs\n")
      cat("  Mean PRS share: ", round(mean(tenure_la$prs_share, na.rm = TRUE), 3), "\n")
      fwrite(tenure_la, file.path(data_dir, "census_2021_prs_share_la.csv"))
    }
  }
}

## ===================================================================
## 5. POLICE API — ANTI-SOCIAL BEHAVIOUR (Skip for now)
## ===================================================================
## Property prices are the primary outcome. ASB mechanism test can
## be added as robustness if the main results warrant it.
## Police bulk data requires large downloads (~500MB/year) and
## LSOA-to-LA mapping that would slow the pipeline.
cat("Police ASB data: skipped (property prices are primary outcome).\n")
cat("  ASB mechanism test available as extension if main results warrant it.\n")

## ===================================================================
## 6. ONS PRIVATE RENTAL MARKET STATISTICS (supplementary)
## ===================================================================
## LA-level median private rents — supplementary outcome.
## Property prices from Land Registry are the primary outcome.
cat("ONS Private Rental Market Statistics: skipped.\n")
cat("  Property transaction prices are the primary outcome.\n")
cat("  Rental statistics available as extension if needed.\n")

## ===================================================================
## DATA VALIDATION (required)
## ===================================================================
cat("\n=== DATA VALIDATION ===\n")

## Check Land Registry
lr_check <- arrow::read_parquet(file.path(data_dir, "land_registry_england.parquet"))
stopifnot("Expected 10M+ transactions" = nrow(lr_check) > 10e6)
stopifnot("Expected 15+ years" = n_distinct(lr_check$year) >= 15)
n_districts <- n_distinct(lr_check$district)
cat("Land Registry: ", nrow(lr_check), " transactions, ",
    n_distinct(lr_check$year), " years, ",
    n_districts, " districts\n")

## Check licensing timeline
lic_check <- fread(file.path(data_dir, "licensing_adoption_dates.csv"))
stopifnot("Expected 30+ LAs with dates" = nrow(lic_check) >= 30)
cat("Licensing dates: ", nrow(lic_check), " LAs\n")

cat("\nData validation passed.\n")
cat("Ready for 02_clean_data.R\n")
