## 02_clean_data.R — Build county-level analysis dataset
source("00_packages.R")

data_dir <- "../data"

cat("=== Loading data ===\n")
airports <- fread(file.path(data_dir, "airports.csv"))
airports <- airports[iso_country == "US"]
cbp <- fread(file.path(data_dir, "cbp_2019.csv"))
pop <- fread(file.path(data_dir, "county_pop.csv"))
gaz <- fread(file.path(data_dir, "county_gazetteer.txt"))
wwii <- fread(file.path(data_dir, "wwii_airfields_v2.csv"))
pop_hist <- fread(file.path(data_dir, "pop_1940.csv"))

cat("Airports:", nrow(airports), "\n")
cat("CBP:", nrow(cbp), "\n")
cat("WWII airfields:", nrow(wwii), "| with coords:", sum(!is.na(wwii$lat)), "\n")

## ================================================================
## Step 1: Clean gazetteer — county centroids
## ================================================================
gaz[, fips := sprintf("%05d", as.integer(GEOID))]
gaz[, county_lat := as.numeric(gsub("[+]", "", INTPTLAT))]
gaz[, county_lon := as.numeric(gsub("[+]", "", INTPTLONG))]
gaz_clean <- gaz[, .(fips, county_lat, county_lon,
                      land_sqmi = as.numeric(ALAND_SQMI))]
gaz_clean <- gaz_clean[!is.na(county_lat) & !is.na(county_lon)]
cat("County centroids:", nrow(gaz_clean), "\n")

## ================================================================
## Step 2: Match WWII airfields to counties (spatial)
## ================================================================
cat("\n=== Matching WWII airfields to counties ===\n")

## Keep only airfields with valid coordinates
wwii_geo <- wwii[!is.na(lat) & !is.na(lon) & lat > 20 & lat < 72 & lon > -180 & lon < -60]
cat("WWII airfields with valid coords:", nrow(wwii_geo), "\n")

## For each airfield, find the nearest county centroid
## Using geosphere::distGeo for accurate great-circle distances
match_to_county <- function(af_lat, af_lon, county_dt) {
  dists <- geosphere::distGeo(
    cbind(af_lon, af_lat),
    cbind(county_dt$county_lon, county_dt$county_lat)
  )
  idx <- which.min(dists)
  data.table(fips = county_dt$fips[idx], dist_km = dists[idx] / 1000)
}

cat("Matching airfields to counties...\n")
matched <- rbindlist(lapply(seq_len(nrow(wwii_geo)), function(i) {
  res <- match_to_county(wwii_geo$lat[i], wwii_geo$lon[i], gaz_clean)
  res[, airfield_name := wwii_geo$name[i]]
  res[, airfield_state := wwii_geo$state[i]]
  res
}))
cat("Matched:", nrow(matched), "airfields to counties\n")
cat("Median distance to county centroid:", round(median(matched$dist_km), 1), "km\n")

## County-level instrument: count of WWII airfields
county_wwii <- matched[, .(
  n_wwii_airfields = .N,
  has_wwii_airfield = 1L
), by = fips]

cat("Counties with WWII airfield:", nrow(county_wwii), "\n")

## ================================================================
## Step 3: Match current airports to counties
## ================================================================
cat("\n=== Matching current airports to counties ===\n")

## Filter to open, public airports (not heliports, seaplane bases, or closed)
open_airports <- airports[type %in% c("small_airport", "medium_airport", "large_airport")]
open_airports <- open_airports[!is.na(latitude_deg) & !is.na(longitude_deg)]
open_airports <- open_airports[latitude_deg > 20 & latitude_deg < 72 & longitude_deg > -180 & longitude_deg < -60]
cat("Open airports:", nrow(open_airports), "\n")
cat("  Large:", sum(open_airports$type == "large_airport"), "\n")
cat("  Medium:", sum(open_airports$type == "medium_airport"), "\n")
cat("  Small:", sum(open_airports$type == "small_airport"), "\n")

## Match each airport to nearest county centroid
cat("Matching airports to counties...\n")
apt_matched <- rbindlist(lapply(seq_len(nrow(open_airports)), function(i) {
  dists <- geosphere::distGeo(
    cbind(open_airports$longitude_deg[i], open_airports$latitude_deg[i]),
    cbind(gaz_clean$county_lon, gaz_clean$county_lat)
  )
  idx <- which.min(dists)
  data.table(
    fips = gaz_clean$fips[idx],
    airport_type = open_airports$type[i],
    airport_ident = open_airports$ident[i]
  )
}))

## County-level airport counts and treatment variable
county_airports <- apt_matched[, .(
  n_airports = .N,
  n_large = sum(airport_type == "large_airport"),
  n_medium = sum(airport_type == "medium_airport"),
  n_small = sum(airport_type == "small_airport"),
  has_airport = 1L,
  has_med_large = as.integer(any(airport_type %in% c("medium_airport", "large_airport")))
), by = fips]

cat("Counties with any airport:", nrow(county_airports), "\n")
cat("Counties with medium/large:", sum(county_airports$has_med_large), "\n")

## ================================================================
## Step 4: Merge everything at county level
## ================================================================
cat("\n=== Building analysis dataset ===\n")

## Start with CBP
county <- copy(cbp)
county[, fips := sprintf("%05s", fips)]

## Population
pop[, fips := sprintf("%05s", fips)]
county <- merge(county, pop[, .(fips, population)], by = "fips", all.x = TRUE)

## Gazetteer
county <- merge(county, gaz_clean, by = "fips", all.x = TRUE)

## WWII instrument
county <- merge(county, county_wwii, by = "fips", all.x = TRUE)
county[is.na(n_wwii_airfields), n_wwii_airfields := 0]
county[is.na(has_wwii_airfield), has_wwii_airfield := 0L]

## Current airports (treatment)
county <- merge(county, county_airports, by = "fips", all.x = TRUE)
county[is.na(n_airports), n_airports := 0]
county[is.na(has_airport), has_airport := 0L]
county[is.na(has_med_large), has_med_large := 0L]
county[is.na(n_large), n_large := 0]
county[is.na(n_medium), n_medium := 0]
county[is.na(n_small), n_small := 0]

## Historical population
pop_hist[, fips := sprintf("%05s", fips)]
county <- merge(county, pop_hist, by = "fips", all.x = TRUE)

## State FIPS and census division
county[, state_fips := substr(fips, 1, 2)]

div_map <- data.table(
  state_fips = c("09","23","25","33","44","50",
                 "34","36","42",
                 "17","18","26","39","55",
                 "19","20","27","29","31","38","46",
                 "10","11","12","13","24","37","45","51","54",
                 "01","21","28","47",
                 "05","22","40","48",
                 "04","08","16","30","32","35","49","56",
                 "02","06","15","41","53"),
  division = c(rep(1,6), rep(2,3), rep(3,5), rep(4,7), rep(5,9),
               rep(6,4), rep(7,4), rep(8,8), rep(9,5))
)
county <- merge(county, div_map, by = "state_fips", all.x = TRUE)

## Drop territories and missing data
county <- county[!is.na(division) & !is.na(county_lat) & !is.na(county_lon)]
county <- county[emp_total > 0 & !is.na(population)]

## Create derived variables
county[, log_pop := log(population)]
county[, log_emp_total := log(emp_total)]
county[, log_emp_mfg := log(pmax(emp_mfg, 1))]
county[, log_emp_svc := log(pmax(emp_svc, 1))]
county[, log_emp_ret := log(pmax(emp_ret, 1))]
county[, mfg_share := emp_mfg / emp_total]
county[, svc_share := emp_svc / emp_total]
county[, ret_share := emp_ret / emp_total]
county[, log_land_area := log(pmax(land_sqmi, 0.1))]
county[, log_pop_hist := log(pmax(pop_2010, 1))]
county[, pop_density := population / pmax(land_sqmi, 0.1)]
county[, log_pop_density := log(pmax(pop_density, 0.01))]

## Latitude/longitude controls (capture climate/terrain proxies)
county[, lat_sq := county_lat^2]
county[, lon_sq := county_lon^2]

cat("\n=== Final Dataset ===\n")
cat("Total counties:", nrow(county), "\n")
cat("Counties with WWII airfield:", sum(county$has_wwii_airfield), "\n")
cat("Counties with any airport:", sum(county$has_airport), "\n")
cat("Counties with medium/large airport:", sum(county$has_med_large), "\n")
cat("\nKey statistics:\n")
cat("  Mean mfg share:", round(mean(county$mfg_share, na.rm = TRUE), 4), "\n")
cat("  SD mfg share:", round(sd(county$mfg_share, na.rm = TRUE), 4), "\n")
cat("  Mean mfg emp:", round(mean(county$emp_mfg, na.rm = TRUE), 0), "\n")
cat("  Mean has_wwii:", round(mean(county$has_wwii_airfield), 3), "\n")
cat("  Mean has_airport:", round(mean(county$has_airport), 3), "\n")
cat("  Mean has_med_large:", round(mean(county$has_med_large), 3), "\n")

## Save
fwrite(county, file.path(data_dir, "analysis_county.csv"))
cat("\nAnalysis dataset saved:", nrow(county), "counties\n")
