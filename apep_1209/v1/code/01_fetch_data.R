## 01_fetch_data.R — Fetch dispensary locations, property sales, crime data
## apep_1209: Cannabis dispensary lotteries and property values

source("00_packages.R")

cat("=== Step 1: Fetch Illinois adult-use dispensary data ===\n")

## ---------------------------------------------------------------
## 1A. Dispensary locations from IDFPR Socrata API
## ---------------------------------------------------------------
dispensary_url <- paste0(
  "https://data.illinois.gov/resource/pzzh-kp68.json",
  "?$where=description=%27REGISTERED%20ADULT%20USE%20CANNABIS%20DISPENSING%20ORGANIZATION%27",
  "%20AND%20license_status=%27ACTIVE%27",
  "&$limit=500"
)

cat("Fetching adult-use dispensary licenses from IDFPR...\n")
resp <- httr::GET(dispensary_url, httr::timeout(60))
if (httr::status_code(resp) != 200) {
  stop("FATAL: Cannot fetch dispensary data. HTTP ", httr::status_code(resp))
}
dispensary_raw <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
cat("  Downloaded", nrow(dispensary_raw), "active dispensary records\n")
if (nrow(dispensary_raw) < 50) stop("FATAL: Too few dispensary records")

dispensary_cook <- dispensary_raw[toupper(dispensary_raw$county) == "COOK", ]
cat("  Cook County:", nrow(dispensary_cook), "\n")
saveRDS(dispensary_raw, "../data/dispensary_raw.rds")
saveRDS(dispensary_cook, "../data/dispensary_cook.rds")

## ---------------------------------------------------------------
## 1B. Geocode dispensaries via ZCTA centroids
## ---------------------------------------------------------------
cat("\n=== Step 1B: Geocode dispensaries ===\n")

if (!requireNamespace("tigris", quietly = TRUE)) {
  install.packages("tigris", repos = "https://cloud.r-project.org")
}
library(tigris)
options(tigris_use_cache = TRUE)

il_zctas <- tryCatch(zctas(year = 2020, state = "17"), error = function(e) {
  cat("  State-level failed, trying national...\n")
  z <- zctas(year = 2020)
  z[grepl("^6[0-2]", z$ZCTA5CE20), ]
})

zcta_centroids <- sf::st_centroid(il_zctas)
zcta_coords <- data.frame(
  zip = zcta_centroids$ZCTA5CE20,
  lon = sf::st_coordinates(zcta_centroids)[, 1],
  lat = sf::st_coordinates(zcta_centroids)[, 2],
  stringsAsFactors = FALSE
)
cat("  ZCTA centroids:", nrow(zcta_coords), "\n")

dispensary_cook$zip5 <- substr(gsub("[^0-9]", "", dispensary_cook$zip), 1, 5)
dispensary_cook <- merge(dispensary_cook, zcta_coords, by.x = "zip5", by.y = "zip", all.x = TRUE)
cat("  Geocoded:", sum(!is.na(dispensary_cook$lat)), "of", nrow(dispensary_cook), "\n")
if (sum(!is.na(dispensary_cook$lat)) < 10) stop("FATAL: Too few geocoded dispensaries")
saveRDS(dispensary_cook, "../data/dispensary_geocoded.rds")

## ---------------------------------------------------------------
## 1C. Cook County property sales — TWO datasets
## Old (5pge-nu6u): 2013-2019, HAS coordinates
## New (wvhk-k5uv): 1971-2026, NO coordinates
## Strategy: build PIN-to-coord lookup from old, join to new
## ---------------------------------------------------------------
cat("\n=== Step 2: Fetch Cook County property sales ===\n")

# 2a. Fetch old dataset for PIN-to-coordinate lookup (2018-2019)
cat("  Fetching PIN coordinates from old dataset (5pge-nu6u, ~575K records)...\n")
old_sales <- list()
for (offset in seq(0, 600000, 50000)) {
  url <- paste0(
    "https://datacatalog.cookcountyil.gov/resource/5pge-nu6u.json",
    "?$select=pin,centroid_x,centroid_y",
    "&$where=centroid_x%20IS%20NOT%20NULL",
    "&$limit=50000&$offset=", offset
  )
  resp <- httr::GET(url, httr::timeout(120))
  if (httr::status_code(resp) != 200) break
  batch <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
  if (nrow(batch) == 0) break
  old_sales <- c(old_sales, list(batch))
  if ((offset / 50000) %% 4 == 0) cat("    Offset", offset, ":", nrow(batch), "records\n")
  Sys.sleep(0.3)
}
pin_coords <- data.table::rbindlist(old_sales)
pin_coords[, centroid_x := as.numeric(centroid_x)]
pin_coords[, centroid_y := as.numeric(centroid_y)]
# Deduplicate: one row per PIN
pin_coords <- pin_coords[!is.na(centroid_x), .(centroid_x = mean(centroid_x),
                                                 centroid_y = mean(centroid_y)), by = pin]
cat("  PIN coordinate lookup:", nrow(pin_coords), "unique PINs\n")

# 2b. Fetch new sales dataset (wvhk-k5uv) year by year, 2019-2025
cat("  Fetching recent sales (wvhk-k5uv, 2019-2025)...\n")
all_sales <- list()
for (yr in 2019:2025) {
  url <- paste0(
    "https://datacatalog.cookcountyil.gov/resource/wvhk-k5uv.json",
    "?$where=sale_date>=%27", yr, "-01-01%27",
    "%20AND%20sale_date<%27", yr + 1, "-01-01%27",
    "%20AND%20sale_price>10000",
    "%20AND%20sale_price<5000000",
    "&$limit=50000&$order=sale_date%20ASC"
  )
  resp <- httr::GET(url, httr::timeout(180))
  if (httr::status_code(resp) != 200) {
    cat("    Year", yr, ": HTTP", httr::status_code(resp), "\n")
    next
  }
  batch <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
  cat("    Year", yr, ":", nrow(batch), "records\n")
  if (nrow(batch) > 0) all_sales[[as.character(yr)]] <- batch
  Sys.sleep(0.5)
}

sales_df <- data.table::rbindlist(all_sales, fill = TRUE)
cat("  Total recent sales:", nrow(sales_df), "\n")
if (nrow(sales_df) < 5000) stop("FATAL: Insufficient sales data")

# 2c. Join coordinates
sales_df <- merge(sales_df, pin_coords, by = "pin", all.x = TRUE)
cat("  Sales with coordinates:", sum(!is.na(sales_df$centroid_x)), "of", nrow(sales_df), "\n")

saveRDS(sales_df, "../data/cook_sales_raw.rds")
saveRDS(pin_coords, "../data/pin_coords.rds")
cat("  Saved cook_sales_raw.rds and pin_coords.rds\n")

## ---------------------------------------------------------------
## 1D. Chicago crime data year by year
## ---------------------------------------------------------------
cat("\n=== Step 3: Fetch Chicago crime data ===\n")

all_crime <- list()
for (yr in 2019:2025) {
  url <- paste0(
    "https://data.cityofchicago.org/resource/ijzp-q8t2.json",
    "?$where=date>=%27", yr, "-01-01%27",
    "%20AND%20date<%27", yr + 1, "-01-01%27",
    "%20AND%20latitude%20IS%20NOT%20NULL",
    "&$limit=50000&$order=date%20ASC",
    "&$select=id,date,primary_type,description,latitude,longitude,community_area,ward"
  )
  resp <- httr::GET(url, httr::timeout(180))
  if (httr::status_code(resp) != 200) next
  batch <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
  cat("  Year", yr, ":", nrow(batch), "crime records\n")
  if (nrow(batch) > 0) all_crime[[as.character(yr)]] <- batch
  Sys.sleep(0.5)
}

crime_df <- data.table::rbindlist(all_crime, fill = TRUE)
cat("  Total crime records:", nrow(crime_df), "\n")
if (nrow(crime_df) < 5000) stop("FATAL: Insufficient crime data")
saveRDS(crime_df, "../data/chi_crime_raw.rds")

## ---------------------------------------------------------------
## 1E. Census ACS demographics
## ---------------------------------------------------------------
cat("\n=== Step 4: Fetch ACS demographics ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
chi_zips <- dispensary_cook$zip5[!is.na(dispensary_cook$zip5)]
chi_zips <- unique(chi_zips)
acs_zip_list <- paste(unique(c(chi_zips, sprintf("%05d", 60601:60699))), collapse = ",")

acs_url <- paste0(
  "https://api.census.gov/data/2022/acs/acs5",
  "?get=NAME,B19013_001E,B01003_001E,B25077_001E,B25003_002E,B25003_001E,B02001_002E,B02001_001E,B01002_001E",
  "&for=zip%20code%20tabulation%20area:", acs_zip_list
)
if (nchar(census_key) > 0) acs_url <- paste0(acs_url, "&key=", census_key)

resp_acs <- httr::GET(acs_url, httr::timeout(60))
if (httr::status_code(resp_acs) != 200) stop("FATAL: ACS fetch failed")
acs_raw <- jsonlite::fromJSON(httr::content(resp_acs, as = "text", encoding = "UTF-8"))
acs_df <- as.data.frame(acs_raw[-1, ], stringsAsFactors = FALSE)
names(acs_df) <- acs_raw[1, ]
names(acs_df)[names(acs_df) == "B19013_001E"] <- "median_income"
names(acs_df)[names(acs_df) == "B01003_001E"] <- "total_pop"
names(acs_df)[names(acs_df) == "B25077_001E"] <- "median_home_value"
names(acs_df)[names(acs_df) == "B25003_002E"] <- "owner_occupied"
names(acs_df)[names(acs_df) == "B25003_001E"] <- "total_housing"
names(acs_df)[names(acs_df) == "B02001_002E"] <- "white_pop"
names(acs_df)[names(acs_df) == "B02001_001E"] <- "total_race"
names(acs_df)[names(acs_df) == "B01002_001E"] <- "median_age"
names(acs_df)[names(acs_df) == "zip code tabulation area"] <- "zcta"

for (v in c("median_income","total_pop","median_home_value","owner_occupied",
            "total_housing","white_pop","total_race","median_age")) {
  acs_df[[v]] <- as.numeric(acs_df[[v]])
}
saveRDS(acs_df, "../data/acs_zcta.rds")
cat("  ACS ZCTAs:", nrow(acs_df), "\n")

cat("\n=== Data fetch complete ===\n")
cat("Files:", paste(list.files("../data"), collapse = ", "), "\n")
