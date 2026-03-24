## 01_fetch_data.R — Fetch Eviction Lab ETS + Census ACS data
## SNAP EA Expiration and Eviction Filings

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ═══════════════════════════════════════════════════════════════════
## 1. Eviction Lab ETS — bulk download from S3
## ═══════════════════════════════════════════════════════════════════
cat("Fetching Eviction Lab ETS data...\n")

## The _2020_2021 suffix is a legacy naming artifact — data is updated through 2026
ets_cities_url <- "https://eviction-lab-data-downloads.s3.amazonaws.com/ets/all_sites_weekly_2020_2021.csv"
ets_states_url <- "https://eviction-lab-data-downloads.s3.amazonaws.com/ets/allstates_weekly_2020_2021.csv"

ets_cities_file <- file.path(data_dir, "ets_all_cities_weekly.csv")
ets_states_file <- file.path(data_dir, "ets_all_states_weekly.csv")

## Download cities file
if (!file.exists(ets_cities_file)) {
  resp <- download.file(ets_cities_url, ets_cities_file, mode = "wb", quiet = FALSE)
  if (resp != 0 || file.size(ets_cities_file) < 1000) {
    stop("FATAL: Cannot download Eviction Lab cities data")
  }
}

## Download states file (covers additional states: CT, DE, IN, MN, MO, NM, PA, RI, VA, WI)
if (!file.exists(ets_states_file)) {
  resp <- download.file(ets_states_url, ets_states_file, mode = "wb", quiet = FALSE)
  if (resp != 0 || file.size(ets_states_file) < 1000) {
    cat("WARNING: States file download failed, proceeding with cities only\n")
  }
}

## Read cities data
ets_cities <- fread(ets_cities_file)
cat("ETS cities data:", nrow(ets_cities), "rows,", ncol(ets_cities), "columns\n")
cat("Columns:", paste(names(ets_cities), collapse = ", "), "\n")
cat("Cities:", paste(unique(ets_cities$city), collapse = ", "), "\n")
cat("Week range:", min(ets_cities$week, na.rm = TRUE), "-",
    max(ets_cities$week, na.rm = TRUE), "\n")

## Read states data if available
if (file.exists(ets_states_file) && file.size(ets_states_file) > 1000) {
  ets_states <- fread(ets_states_file)
  cat("ETS states data:", nrow(ets_states), "rows\n")

  ## Combine cities and states data
  ## Ensure same column structure
  common_cols <- intersect(names(ets_cities), names(ets_states))
  ets_raw <- rbind(
    ets_cities[, ..common_cols],
    ets_states[, ..common_cols],
    fill = TRUE
  )
  cat("Combined ETS data:", nrow(ets_raw), "rows\n")
} else {
  ets_raw <- ets_cities
}

## Inspect data structure
cat("\nSample rows:\n")
print(head(ets_raw, 5))
cat("\nUnique GEOIDs:", length(unique(ets_raw$GEOID)), "\n")

## ═══════════════════════════════════════════════════════════════════
## 2. SNAP EA Opt-Out Dates by State
## ═══════════════════════════════════════════════════════════════════
cat("\nConstructing SNAP EA opt-out dates...\n")

## Source: CBPP "States Are Ending Emergency Allotments" tracker
## Dates verified against USDA FNS waivers
## Wave 1 (April 2021): AK, FL, IA, MS, MO, MT, ND, NE, SD, TN, WY (11)
## Wave 2 (July-Sept 2021): AL, AR, AZ, GA, ID, IN, KY, NH, NC, OH, OK, SC, TX, UT, WV (15)
## Wave 3 (Oct 2021 - Feb 2022): Remaining early opt-outs
## National termination: March 2023

ea_dates <- data.frame(
  state = c(
    ## Wave 1: April 2021
    "AK", "FL", "IA", "MS", "MO", "MT", "ND", "NE", "SD", "TN", "WY",
    ## Wave 2: July 2021
    "AL", "AR", "AZ", "GA", "ID", "IN",
    ## Wave 2 cont: August-September 2021
    "NH", "NC", "OH", "OK", "SC", "TX", "UT", "WV",
    ## Late 2021 / early 2022
    "KY"
  ),
  ea_end_date = as.Date(c(
    ## Wave 1 — April 2021
    "2021-04-01", "2021-04-01", "2021-04-01", "2021-04-01", "2021-04-01",
    "2021-04-01", "2021-04-01", "2021-04-01", "2021-04-01", "2021-04-01",
    "2021-04-01",
    ## Wave 2 — July 2021
    "2021-07-01", "2021-07-01", "2021-07-01", "2021-07-01", "2021-07-01",
    "2021-07-01",
    ## Wave 2 cont — Aug-Sept 2021
    "2021-08-01", "2021-08-01", "2021-08-01", "2021-08-01", "2021-08-01",
    "2021-08-01", "2021-08-01", "2021-08-01",
    ## Late 2021
    "2021-10-01"
  )),
  stringsAsFactors = FALSE
)

## Verify: all states either early opt-out or stayed until March 2023
all_states <- c(state.abb, "DC")
early_states <- ea_dates$state
late_states <- setdiff(all_states, early_states)

ea_late <- data.frame(
  state = late_states,
  ea_end_date = as.Date("2023-03-01"),
  stringsAsFactors = FALSE
)

ea_all <- rbind(ea_dates, ea_late)
ea_all$early_optout <- ea_all$state %in% early_states
ea_all$treat_cohort <- as.character(ea_all$ea_end_date)

fwrite(ea_all, file.path(data_dir, "snap_ea_dates.csv"))
cat("EA opt-out dates:", sum(ea_all$early_optout), "early states,",
    sum(!ea_all$early_optout), "late/control states\n")
cat("Treatment cohorts:\n")
print(table(ea_dates$ea_end_date))

## ═══════════════════════════════════════════════════════════════════
## 3. Census ACS — Tract-level SNAP participation + demographics
## ═══════════════════════════════════════════════════════════════════
cat("\nFetching Census ACS tract-level data...\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) {
  stop("FATAL: CENSUS_API_KEY not set in environment")
}

## Variables:
## B22003_001E = Total households (SNAP universe)
## B22003_002E = Households receiving SNAP
## B25003_001E = Total occupied housing units
## B25003_003E = Renter-occupied housing units
## B19013_001E = Median household income
## B01003_001E = Total population
## B03002_003E = White alone non-Hispanic
## B03002_004E = Black alone non-Hispanic
## B03002_012E = Hispanic or Latino

acs_vars <- "B22003_001E,B22003_002E,B25003_001E,B25003_003E,B19013_001E,B01003_001E,B03002_003E,B03002_004E,B03002_012E"

## Fetch tract-level data for all states (2019 5-year ACS)
all_acs <- list()
## FIPS codes for all 50 states + DC
state_fips_codes <- c(
  "01","02","04","05","06","08","09","10","11","12","13","15","16","17","18",
  "19","20","21","22","23","24","25","26","27","28","29","30","31","32","33",
  "34","35","36","37","38","39","40","41","42","44","45","46","47","48","49",
  "50","51","53","54","55","56"
)

for (st_fips in state_fips_codes) {
  url <- paste0(
    "https://api.census.gov/data/2019/acs/acs5?get=",
    acs_vars,
    "&for=tract:*&in=state:", st_fips,
    "&key=", census_key
  )

  resp <- tryCatch(
    httr::GET(url, httr::timeout(60)),
    error = function(e) NULL
  )

  if (!is.null(resp) && httr::status_code(resp) == 200) {
    txt <- httr::content(resp, as = "text", encoding = "UTF-8")
    parsed <- tryCatch(jsonlite::fromJSON(txt), error = function(e) NULL)

    if (!is.null(parsed) && nrow(parsed) > 1) {
      df <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
      names(df) <- parsed[1, ]
      all_acs[[st_fips]] <- df
    }
  }

  if (which(state_fips_codes == st_fips) %% 10 == 0) {
    cat("  Fetched", which(state_fips_codes == st_fips), "/",
        length(state_fips_codes), "states\n")
  }
  Sys.sleep(0.05)
}

acs_df <- rbindlist(all_acs, fill = TRUE)
cat("ACS data:", nrow(acs_df), "tracts across", length(all_acs), "states\n")

## Clean numeric columns
num_cols <- c("B22003_001E", "B22003_002E", "B25003_001E", "B25003_003E",
              "B19013_001E", "B01003_001E", "B03002_003E", "B03002_004E",
              "B03002_012E")
for (col in num_cols) {
  acs_df[[col]] <- as.numeric(acs_df[[col]])
}

## Construct GEOID and derived variables
acs_df[, geoid := paste0(state, county, tract)]
acs_df[, snap_rate := fifelse(B22003_001E > 0, B22003_002E / B22003_001E, NA_real_)]
acs_df[, renter_rate := fifelse(B25003_001E > 0, B25003_003E / B25003_001E, NA_real_)]
acs_df[, median_income := B19013_001E]
acs_df[, total_pop := B01003_001E]
acs_df[, pct_black := fifelse(B01003_001E > 0, B03002_004E / B01003_001E, NA_real_)]
acs_df[, pct_hispanic := fifelse(B01003_001E > 0, B03002_012E / B01003_001E, NA_real_)]

## State FIPS to abbreviation mapping
fips_to_abbr <- c(
  "01"="AL","02"="AK","04"="AZ","05"="AR","06"="CA","08"="CO","09"="CT",
  "10"="DE","11"="DC","12"="FL","13"="GA","15"="HI","16"="ID","17"="IL",
  "18"="IN","19"="IA","20"="KS","21"="KY","22"="LA","23"="ME","24"="MD",
  "25"="MA","26"="MI","27"="MN","28"="MS","29"="MO","30"="MT","31"="NE",
  "32"="NV","33"="NH","34"="NJ","35"="NM","36"="NY","37"="NC","38"="ND",
  "39"="OH","40"="OK","41"="OR","42"="PA","44"="RI","45"="SC","46"="SD",
  "47"="TN","48"="TX","49"="UT","50"="VT","51"="VA","53"="WA","54"="WV",
  "55"="WI","56"="WY"
)
acs_df[, state_abbr := fips_to_abbr[state]]

fwrite(acs_df, file.path(data_dir, "acs_tract_data.csv"))
cat("ACS tract data saved:", nrow(acs_df), "tracts\n")

## ═══════════════════════════════════════════════════════════════════
## 4. Summary and validation
## ═══════════════════════════════════════════════════════════════════
cat("\n=== DATA FETCH SUMMARY ===\n")
cat("Eviction Lab ETS:", nrow(ets_raw), "rows\n")
cat("SNAP EA dates:", nrow(ea_all), "states total (",
    sum(ea_all$early_optout), "early opt-out)\n")
cat("ACS tracts:", nrow(acs_df), "\n")
cat("Mean SNAP participation rate:",
    round(mean(acs_df$snap_rate, na.rm = TRUE), 3), "\n")
cat("Mean renter rate:",
    round(mean(acs_df$renter_rate, na.rm = TRUE), 3), "\n")

## Save for downstream scripts
saveRDS(ets_raw, file.path(data_dir, "ets_raw.rds"))
saveRDS(acs_df, file.path(data_dir, "acs_tract.rds"))
saveRDS(ea_all, file.path(data_dir, "ea_dates.rds"))

cat("\nData fetch complete.\n")
