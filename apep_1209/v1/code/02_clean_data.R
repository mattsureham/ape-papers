## 02_clean_data.R — Clean and merge data, compute distances
## apep_1209: Cannabis dispensary lotteries and property values

source("00_packages.R")

cat("=== Loading raw data ===\n")
dispensary <- readRDS("../data/dispensary_geocoded.rds")
sales <- as.data.table(readRDS("../data/cook_sales_raw.rds"))
crime <- as.data.table(readRDS("../data/chi_crime_raw.rds"))
acs <- as.data.table(readRDS("../data/acs_zcta.rds"))

## ---------------------------------------------------------------
## 2A. Clean dispensary data
## ---------------------------------------------------------------
cat("\n=== Cleaning dispensary data ===\n")

dispensary$open_date <- as.Date(dispensary$original_issue_date, format = "%m/%d/%Y")
dispensary$disp_id <- seq_len(nrow(dispensary))
dispensary$lat <- as.numeric(dispensary$lat)
dispensary$lon <- as.numeric(dispensary$lon)
dispensary$lottery_era <- dispensary$open_date >= as.Date("2021-07-01")

disp_clean <- dispensary[!is.na(dispensary$lat), c("disp_id","business_name","businessdba",
  "city","zip5","county","open_date","lat","lon","license_number","lottery_era")]

cat("  Total dispensaries:", nrow(disp_clean), "\n")
cat("  Pre-lottery (before 2021-07):", sum(!disp_clean$lottery_era, na.rm = TRUE), "\n")
cat("  Lottery era (2021-07+):", sum(disp_clean$lottery_era, na.rm = TRUE), "\n")
cat("  Open date range:", as.character(min(disp_clean$open_date, na.rm=TRUE)), "to",
    as.character(max(disp_clean$open_date, na.rm=TRUE)), "\n")

## ---------------------------------------------------------------
## 2B. Clean property sales
## ---------------------------------------------------------------
cat("\n=== Cleaning property sales ===\n")

sales[, sale_price := as.numeric(sale_price)]
sales[, sale_date := as.Date(substr(sale_date, 1, 10))]
sales[, sale_year := year(sale_date)]
sales[, sale_quarter := quarter(sale_date)]
sales[, sale_yq := paste0(sale_year, "Q", sale_quarter)]
sales[, log_price := log(sale_price)]
sales[, centroid_x := as.numeric(centroid_x)]
sales[, centroid_y := as.numeric(centroid_y)]

# Filter to valid sales with coordinates
sales_geo <- sales[!is.na(centroid_x) & !is.na(centroid_y) &
                   !is.na(sale_price) & sale_price > 10000 & sale_price < 5000000]

cat("  Total sales:", nrow(sales), "\n")
cat("  Geocoded sales:", nrow(sales_geo), "\n")
cat("  Year range:", min(sales_geo$sale_year), "-", max(sales_geo$sale_year), "\n")
cat("  Sales by year:\n")
print(table(sales_geo$sale_year))

## ---------------------------------------------------------------
## 2C. Compute distances to dispensaries
## ---------------------------------------------------------------
cat("\n=== Computing distances ===\n")

# centroid_x = longitude, centroid_y = latitude (already WGS84)
sales_geo[, prop_lon := centroid_x]
sales_geo[, prop_lat := centroid_y]

cat("  Lat range:", round(min(sales_geo$prop_lat), 2), "-", round(max(sales_geo$prop_lat), 2), "\n")
cat("  Lon range:", round(min(sales_geo$prop_lon), 2), "-", round(max(sales_geo$prop_lon), 2), "\n")

# Haversine distance in miles
haversine <- function(lat1, lon1, lat2, lon2) {
  R <- 3958.8
  dlat <- (lat2 - lat1) * pi / 180
  dlon <- (lon2 - lon1) * pi / 180
  a <- sin(dlat/2)^2 + cos(lat1*pi/180) * cos(lat2*pi/180) * sin(dlon/2)^2
  2 * R * asin(sqrt(a))
}

# Find nearest dispensary for each sale
disp_mat <- as.data.frame(disp_clean[, c("disp_id","lat","lon","open_date","lottery_era")])
n_sales <- nrow(sales_geo)
n_disp <- nrow(disp_mat)

cat("  Computing", n_sales, "x", n_disp, "distance pairs...\n")

dist_nearest <- rep(Inf, n_sales)
nearest_id <- integer(n_sales)
nearest_date <- rep(as.Date(NA), n_sales)
nearest_lottery <- logical(n_sales)

for (j in seq_len(n_disp)) {
  d <- haversine(sales_geo$prop_lat, sales_geo$prop_lon,
                 disp_mat$lat[j], disp_mat$lon[j])
  better <- d < dist_nearest
  dist_nearest[better] <- d[better]
  nearest_id[better] <- disp_mat$disp_id[j]
  nearest_date[better] <- disp_mat$open_date[j]
  nearest_lottery[better] <- disp_mat$lottery_era[j]
}

sales_geo[, dist_nearest := dist_nearest]
sales_geo[, nearest_disp_id := nearest_id]
sales_geo[, nearest_open_date := as.Date(nearest_date, origin = "1970-01-01")]
sales_geo[, nearest_lottery := nearest_lottery]

cat("  Distance summary (miles):\n")
print(summary(sales_geo$dist_nearest))

## ---------------------------------------------------------------
## 2D. Create treatment variables
## ---------------------------------------------------------------
cat("\n=== Creating treatment variables ===\n")

# Distance rings
sales_geo[, near_025 := as.integer(dist_nearest <= 0.25)]
sales_geo[, near_050 := as.integer(dist_nearest <= 0.50)]
sales_geo[, ring_025_050 := as.integer(dist_nearest > 0.25 & dist_nearest <= 0.50)]
sales_geo[, ring_050_100 := as.integer(dist_nearest > 0.50 & dist_nearest <= 1.00)]
sales_geo[, ring_100_150 := as.integer(dist_nearest > 1.00 & dist_nearest <= 1.50)]
sales_geo[, far := as.integer(dist_nearest > 1.50)]

# Post-opening indicator
sales_geo[, post_open := as.integer(sale_date >= nearest_open_date)]

# DiD treatment
sales_geo[, treat_025 := near_025 * post_open]
sales_geo[, treat_050 := near_050 * post_open]

# Event time (quarters relative to opening)
sales_geo[, event_days := as.numeric(sale_date - nearest_open_date)]
sales_geo[, event_quarter := floor(event_days / 91.25)]

# Winsorize event_quarter for event study
sales_geo[, event_q_bin := pmax(-8, pmin(8, event_quarter))]

# Dispensary-cluster identifier (for FE)
sales_geo[, disp_cluster := nearest_disp_id]

# Year-quarter FE
sales_geo[, yq := as.factor(sale_yq)]

cat("  Treatment counts:\n")
cat("    Within 0.25mi:", sum(sales_geo$near_025), "\n")
cat("    Within 0.50mi:", sum(sales_geo$near_050), "\n")
cat("    Post-opening:", sum(sales_geo$post_open), "\n")
cat("    Treated (0.25mi x post):", sum(sales_geo$treat_025), "\n")
cat("    Treated (0.50mi x post):", sum(sales_geo$treat_050), "\n")

## ---------------------------------------------------------------
## 2E. Clean crime data
## ---------------------------------------------------------------
cat("\n=== Cleaning crime data ===\n")

crime[, date := as.Date(substr(date, 1, 10))]
crime[, year := year(date)]
crime[, quarter := quarter(date)]
crime[, yq := paste0(year, "Q", quarter)]
crime[, lat := as.numeric(latitude)]
crime[, lon := as.numeric(longitude)]

crime[, crime_cat := fcase(
  primary_type %in% c("NARCOTICS","OTHER NARCOTIC VIOLATION"), "drug",
  primary_type %in% c("THEFT","BURGLARY","MOTOR VEHICLE THEFT","ROBBERY"), "property",
  primary_type %in% c("BATTERY","ASSAULT","HOMICIDE","CRIMINAL SEXUAL ASSAULT"), "violent",
  primary_type %in% c("CRIMINAL DAMAGE","CRIMINAL TRESPASS"), "disorder",
  default = "other"
)]

cat("  Crime records:", nrow(crime), "\n")
cat("  Year range:", min(crime$year, na.rm=TRUE), "-", max(crime$year, na.rm=TRUE), "\n")
cat("  Categories:\n")
print(table(crime$crime_cat))

# Compute distance to nearest dispensary for each crime
cat("  Computing crime distances (subsample for speed)...\n")
crime_geo <- crime[!is.na(lat) & !is.na(lon)]

# For crime, aggregate to community_area x quarter level for regression
# This avoids computing millions of individual distances
crime_agg <- crime_geo[, .(
  total_crime = .N,
  drug_crime = sum(crime_cat == "drug"),
  property_crime = sum(crime_cat == "property"),
  violent_crime = sum(crime_cat == "violent"),
  disorder_crime = sum(crime_cat == "disorder")
), by = .(community_area, year, quarter, yq)]

cat("  Crime panel: ", nrow(crime_agg), " community_area x quarter cells\n")

## ---------------------------------------------------------------
## 2F. Clean ACS data
## ---------------------------------------------------------------
cat("\n=== Cleaning ACS ===\n")
for (v in c("median_income","total_pop","median_home_value","owner_occupied",
            "total_housing","white_pop","total_race","median_age")) {
  acs[[v]] <- as.numeric(acs[[v]])
}
acs[, pct_owner := owner_occupied / total_housing * 100]
acs[, pct_white := white_pop / total_race * 100]
cat("  ACS ZCTAs:", nrow(acs), "\n")

## ---------------------------------------------------------------
## 2G. Save
## ---------------------------------------------------------------
cat("\n=== Saving cleaned data ===\n")
saveRDS(sales_geo, "../data/sales_clean.rds")
saveRDS(disp_clean, "../data/dispensary_clean.rds")
saveRDS(crime_agg, "../data/crime_panel.rds")
saveRDS(crime_geo, "../data/crime_geo.rds")
saveRDS(acs, "../data/acs_clean.rds")

cat("\n=== Final Data Summary ===\n")
cat("  Dispensaries:", nrow(disp_clean), "(", sum(disp_clean$lottery_era, na.rm=TRUE), "lottery era)\n")
cat("  Property sales:", nrow(sales_geo), "\n")
cat("  Treated sales (0.50mi x post):", sum(sales_geo$treat_050), "\n")
cat("  Crime panel cells:", nrow(crime_agg), "\n")
cat("  ACS ZCTAs:", nrow(acs), "\n")
