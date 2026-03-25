## 01_fetch_data.R — Fetch WFP food prices for Lebanon
## Source: HDX (Humanitarian Data Exchange)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ---- 1. Download WFP food prices for Lebanon ----
wfp_url <- "https://data.humdata.org/dataset/db0b4fb1-ce11-458e-94e0-3342365a117a/resource/772bc34e-1327-4ada-b2eb-e72020a546f2/download/wfp_food_prices_lbn.csv"
markets_url <- "https://data.humdata.org/dataset/db0b4fb1-ce11-458e-94e0-3342365a117a/resource/550ffa46-24da-4e1f-9cd4-9ea3256632c7/download/wfp_markets_lbn.csv"

wfp_file <- file.path(data_dir, "wfp_food_prices_lbn.csv")
markets_file <- file.path(data_dir, "wfp_markets_lbn.csv")

if (!file.exists(wfp_file)) {
  cat("Downloading WFP food prices for Lebanon...\n")
  download.file(wfp_url, wfp_file, mode = "wb", quiet = FALSE)
}
if (!file.exists(markets_file)) {
  cat("Downloading WFP markets for Lebanon...\n")
  download.file(markets_url, markets_file, mode = "wb", quiet = FALSE)
}

# Load and validate
dt <- fread(wfp_file)
cat(sprintf("WFP data loaded: %d rows, %d columns\n", nrow(dt), ncol(dt)))
cat(sprintf("Markets: %d unique\n", uniqueN(dt$market)))
cat(sprintf("Commodities: %d unique\n", uniqueN(dt$commodity)))
cat(sprintf("Date range: %s to %s\n", min(dt$date), max(dt$date)))

stopifnot(nrow(dt) > 10000)
stopifnot(uniqueN(dt$market) >= 20)

# ---- 2. Market geocoding ----
# Try WFP markets file first (has lat/lon)
mkt_dt <- fread(markets_file)
cat(sprintf("\nWFP markets file: %d rows, columns: %s\n", nrow(mkt_dt), paste(names(mkt_dt), collapse = ", ")))

# Beirut port coordinates (approximate location of the explosion)
beirut_port <- c(lon = 35.5185, lat = 33.9010)

# Tripoli port coordinates
tripoli_port <- c(lon = 35.8306, lat = 34.4500)

# Extract unique markets from price data
markets <- unique(dt[, .(admin1, market)])
cat(sprintf("\n%d unique markets in price data:\n", nrow(markets)))

# Merge with WFP markets file on market name
# WFP markets file may use different column names - adapt
if ("latitude" %in% names(mkt_dt) && "longitude" %in% names(mkt_dt)) {
  mkt_coords <- mkt_dt[, .(market = market, lat = latitude, long = longitude)]
} else if ("lat" %in% names(mkt_dt) && "lon" %in% names(mkt_dt)) {
  mkt_coords <- mkt_dt[, .(market = market, lat = lat, long = lon)]
} else {
  cat("Markets file columns:", paste(names(mkt_dt), collapse = ", "), "\n")
  mkt_coords <- data.table(market = character(0), lat = numeric(0), long = numeric(0))
}

geo_dt <- merge(markets, mkt_coords, by = "market", all.x = TRUE)
n_coded <- sum(!is.na(geo_dt$lat))
cat(sprintf("Matched from WFP markets file: %d / %d\n", n_coded, nrow(geo_dt)))

# For unmatched markets, use tidygeocoder
if (n_coded < nrow(geo_dt)) {
  unmatched <- geo_dt[is.na(lat)]
  unmatched[, query := paste0(market, ", ", admin1, ", Lebanon")]
  cat(sprintf("\nGeocoding %d unmatched markets via OSM Nominatim...\n", nrow(unmatched)))
  geo_results <- tidygeocoder::geocode(
    as.data.frame(unmatched[, .(query)]),
    address = query, method = "osm", verbose = FALSE
  )
  geo_res <- as.data.table(geo_results)
  unmatched[, `:=`(lat = geo_res$lat, long = geo_res$long)]
  geo_dt[is.na(lat), `:=`(lat = unmatched$lat, long = unmatched$long)]
}

n_coded <- sum(!is.na(geo_dt$lat))
cat(sprintf("After geocoding: %d / %d\n", n_coded, nrow(geo_dt)))

# Final fallbacks: governorate centroids
gov_centroids <- data.table(
  admin1 = c("Akkar", "Baalbek-El Hermel", "Beirut", "Bekaa", "El Nabatieh",
             "Keserwan-Jbeil", "Mount Lebanon", "North Lebanon", "South Lebanon"),
  lat_fb = c(34.55, 34.20, 33.89, 33.85, 33.38, 34.05, 33.85, 34.40, 33.30),
  lon_fb = c(36.20, 36.30, 35.50, 35.90, 35.50, 35.70, 35.60, 35.85, 35.40)
)

geo_dt <- merge(geo_dt, gov_centroids, by = "admin1", all.x = TRUE)
geo_dt[is.na(lat), `:=`(lat = lat_fb, long = lon_fb)]

n_final <- sum(!is.na(geo_dt$lat))
cat(sprintf("After fallbacks: %d / %d markets geocoded\n", n_final, nrow(geo_dt)))
stopifnot(n_final == nrow(geo_dt))

# ---- 3. Compute distances to ports ----
geo_dt[, dist_beirut_km := geosphere::distHaversine(
  cbind(long, lat),
  matrix(c(beirut_port["lon"], beirut_port["lat"]), ncol = 2, nrow = .N, byrow = TRUE)
) / 1000]

geo_dt[, dist_tripoli_km := geosphere::distHaversine(
  cbind(long, lat),
  matrix(c(tripoli_port["lon"], tripoli_port["lat"]), ncol = 2, nrow = .N, byrow = TRUE)
) / 1000]

# Treatment intensity: Beirut proximity (higher = more dependent on Beirut port)
# = dist_tripoli / (dist_beirut + dist_tripoli)
# Markets close to Beirut get high values; markets close to Tripoli get low values
geo_dt[, beirut_proximity := dist_tripoli_km / (dist_beirut_km + dist_tripoli_km)]

cat("\nMarket distances and treatment intensity:\n")
print(geo_dt[, .(market, admin1, dist_beirut_km = round(dist_beirut_km, 1),
                 dist_tripoli_km = round(dist_tripoli_km, 1),
                 beirut_proximity = round(beirut_proximity, 3))][order(-beirut_proximity)])

# Save market data
fwrite(geo_dt[, .(admin1, market, lat, long, dist_beirut_km, dist_tripoli_km, beirut_proximity)],
       file.path(data_dir, "markets_geocoded.csv"))

# ---- 4. Save raw data summary ----
summary_list <- list(
  n_rows = nrow(dt),
  n_markets = uniqueN(dt$market),
  n_commodities = uniqueN(dt$commodity),
  date_min = as.character(min(dt$date)),
  date_max = as.character(max(dt$date)),
  n_geocoded = n_final,
  markets_geocoded = geo_dt[, .(market, admin1, dist_beirut_km, dist_tripoli_km, beirut_proximity)]
)

write_json(summary_list, file.path(data_dir, "fetch_summary.json"), auto_unbox = TRUE, pretty = TRUE)
cat("\nData fetch complete. Summary saved to data/fetch_summary.json\n")
