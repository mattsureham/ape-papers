## 01_fetch_data.R — Fetch SPC tornado data, IEM verification, Census data
## apep_0863: The Forecaster Lottery

library(data.table)
library(httr)
library(jsonlite)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) > 0) setwd(file.path(script_dir, ".."))
cat("Working directory:", getwd(), "\n")

dir.create("data", recursive = TRUE, showWarnings = FALSE)

## ============================================================
## 1. SPC Tornado Data (1950-2023 + annual files)
## ============================================================
## Storm Prediction Center maintains the canonical US tornado dataset
## with county FIPS, EF-scale, casualties, path, WFO (post-2006)

cat("Fetching SPC tornado data...\n")

# Main historical file: 1950-2023
main_url <- "https://www.spc.noaa.gov/wcm/data/1950-2023_actual_tornadoes.csv"
main_file <- "data/spc_tornadoes_1950_2023.csv"

if (!file.exists(main_file)) {
  cat("Downloading 1950-2023 tornado data...\n")
  resp <- GET(main_url, write_disk(main_file, overwrite = TRUE), timeout(120))
  stopifnot("Failed to download SPC tornado data" = status_code(resp) == 200)
}

torn_main <- fread(main_file, fill = TRUE)
cat("Main file rows:", nrow(torn_main), "\n")
cat("Columns:", paste(names(torn_main), collapse = ", "), "\n")

# Also try to get 2024 and 2025 annual files
for (y in 2024:2025) {
  yfile <- sprintf("data/spc_tornadoes_%d.csv", y)
  if (!file.exists(yfile)) {
    yurl <- sprintf("https://www.spc.noaa.gov/wcm/data/%d_torn.csv", y)
    resp <- GET(yurl, write_disk(yfile, overwrite = TRUE), timeout(60))
    if (status_code(resp) == 200 && file.size(yfile) > 100) {
      cat("Downloaded", y, "tornado data\n")
    } else {
      file.remove(yfile)
      cat("No", y, "data available yet\n")
    }
  }
}

# Combine all data
all_torn <- list(torn_main)
for (y in 2024:2025) {
  yfile <- sprintf("data/spc_tornadoes_%d.csv", y)
  if (file.exists(yfile)) {
    dt <- fread(yfile, fill = TRUE)
    all_torn[[length(all_torn) + 1]] <- dt
  }
}

tornadoes <- rbindlist(all_torn, fill = TRUE)
cat("Total tornado records:", nrow(tornadoes), "\n")

# Identify columns - SPC format varies; inspect what we have
cat("Column names:", paste(names(tornadoes)[1:min(20, ncol(tornadoes))], collapse = ", "), "\n")

# SPC data typically has: om, yr, mo, dy, date, time, tz, st, stf, stn, mag,
# inj, fat, loss, closs, slat, slon, elat, elon, len, wid, ns, sn, sg, f1-f4, fc
# OR newer format with different column names

# Standardize column names (handle both old and new SPC formats)
cn <- tolower(names(tornadoes))
names(tornadoes) <- cn

# Check for key columns
has_yr <- "yr" %in% cn
has_year <- "year" %in% cn
cat("Has 'yr':", has_yr, "Has 'year':", has_year, "\n")

# Create standardized year column
if (has_yr) {
  tornadoes[, year := as.integer(yr)]
} else if (has_year) {
  tornadoes[, year := as.integer(year)]
} else if ("date" %in% cn) {
  tornadoes[, year := as.integer(substr(as.character(date), 1, 4))]
}

cat("Year range:", range(tornadoes$year, na.rm = TRUE), "\n")

# Filter to 2008+ (WFO assignments are stable post-modernization)
tornadoes <- tornadoes[year >= 2008]
cat("Tornado events 2008+:", nrow(tornadoes), "\n")

# Standardize key variables
# State FIPS
if ("stf" %in% cn) tornadoes[, state_fips := sprintf("%02d", as.integer(stf))]
if ("st" %in% cn) tornadoes[, state := st]

# County FIPS (SPC uses f1, f2, f3, f4 for FIPS of counties hit)
# f1 = first county FIPS code
if ("f1" %in% cn) {
  tornadoes[, county_fips_raw := as.integer(f1)]
} else if ("stn" %in% cn) {
  tornadoes[, county_fips_raw := as.integer(stn)]
}

# Build 5-digit FIPS
if ("state_fips" %in% names(tornadoes) & "county_fips_raw" %in% names(tornadoes)) {
  tornadoes[, county_fips := sprintf("%03d", county_fips_raw)]
  tornadoes[, fips := paste0(state_fips, county_fips)]
}

# Casualties
if ("inj" %in% cn) tornadoes[, injuries := as.integer(inj)]
if ("fat" %in% cn) tornadoes[, deaths := as.integer(fat)]
tornadoes[, casualties := injuries + deaths]

# EF/F scale magnitude
if ("mag" %in% cn) tornadoes[, ef_scale := as.integer(mag)]

# Path dimensions
if ("len" %in% cn) tornadoes[, path_length := as.numeric(len)]
if ("wid" %in% cn) tornadoes[, path_width := as.numeric(wid)]

# Coordinates
if ("slat" %in% cn) tornadoes[, begin_lat := as.numeric(slat)]
if ("slon" %in% cn) tornadoes[, begin_lon := as.numeric(slon)]
if ("elat" %in% cn) tornadoes[, end_lat := as.numeric(elat)]
if ("elon" %in% cn) tornadoes[, end_lon := as.numeric(elon)]

# Property loss (in millions for SPC data)
if ("loss" %in% cn) tornadoes[, damage_property := as.numeric(loss)]

# Filter: valid FIPS, valid coordinates
tornadoes <- tornadoes[!is.na(fips) & fips != "00000" & county_fips_raw > 0]
tornadoes <- tornadoes[!is.na(begin_lat) & begin_lat != 0]

cat("After cleaning:", nrow(tornadoes), "events\n")
cat("Unique states:", uniqueN(tornadoes$state_fips), "\n")
cat("Unique counties:", uniqueN(tornadoes$fips), "\n")
cat("Events with casualties:", sum(tornadoes$casualties > 0, na.rm = TRUE), "\n")
cat("Total deaths:", sum(tornadoes$deaths, na.rm = TRUE), "\n")
cat("Total injuries:", sum(tornadoes$injuries, na.rm = TRUE), "\n")

fwrite(tornadoes, "data/tornadoes_raw.csv")
cat("Saved data/tornadoes_raw.csv\n")


## ============================================================
## 2. County-to-WFO mapping
## ============================================================
## Download NWS CWA shapefile and build county-WFO crosswalk
## Since SPC data doesn't have WFO codes, we need the CWA boundaries

cat("\nBuilding county-to-WFO mapping...\n")

# NWS publishes CWA boundaries as shapefiles
# Try multiple sources
cwa_urls <- c(
  "https://www.weather.gov/source/gis/Shapefiles/County/c_05mr24.zip",  # county warning areas
  "https://www.weather.gov/source/gis/Shapefiles/WSOM/w_05mr24.zip"   # WFO areas
)

# Also try to use NOAA's zone-to-WFO mapping
# The NWS maintains a zone-county-WFO crosswalk
zone_url <- "https://www.weather.gov/source/gis/Shapefiles/County/bp05mr24.dbx"

# Alternative: use the UGC (Universal Geographic Code) zone file
# which maps counties to WFOs
ugc_url <- "https://mesonet.agron.iastate.edu/data/gis/nws_ugc.json"
cat("Trying IEM UGC mapping...\n")
ugc_resp <- GET(ugc_url, timeout(60))

if (status_code(ugc_resp) == 200) {
  ugc_json <- content(ugc_resp, "text", encoding = "UTF-8")
  ugc_data <- fromJSON(ugc_json)
  # This gives us county/zone to WFO mapping
  if ("features" %in% names(ugc_data)) {
    props <- rbindlist(lapply(ugc_data$features$properties, as.list), fill = TRUE)
    # Filter to county-based UGC codes (start with state FIPS + "C")
    county_wfo <- props[grepl("C", ugc, fixed = TRUE)]
    cat("UGC county-WFO records:", nrow(county_wfo), "\n")
    fwrite(county_wfo, "data/ugc_county_wfo.csv")
  }
} else {
  cat("UGC mapping not available, trying alternative...\n")
}

# Alternative approach: use NWS county warning zone file
cwz_url <- "https://www.weather.gov/source/gis/Shapefiles/County/c_05mr24.zip"
cwz_file <- "data/nws_counties.zip"
if (!file.exists(cwz_file)) {
  resp <- GET(cwz_url, write_disk(cwz_file, overwrite = TRUE), timeout(120))
  if (status_code(resp) == 200) {
    unzip(cwz_file, exdir = "data/nws_counties")
    cat("Downloaded NWS county shapefile\n")
  } else {
    cat("Could not download NWS county shapefile (status:", status_code(resp), ")\n")
  }
}

# Try loading the shapefile if it exists
shp_files <- list.files("data/nws_counties", pattern = "\\.shp$", full.names = TRUE)
if (length(shp_files) > 0) {
  library(sf)
  nws_counties <- st_read(shp_files[1], quiet = TRUE)
  cat("NWS county shapefile loaded:", nrow(nws_counties), "features\n")
  cat("Columns:", paste(names(nws_counties), collapse = ", "), "\n")

  # Extract county-WFO mapping
  nws_dt <- as.data.table(st_drop_geometry(nws_counties))
  # Typical columns: STATE, CWA, COUNTYNAME, FIPS, FE_AREA, LON, LAT
  if ("CWA" %in% names(nws_dt) && "FIPS" %in% names(nws_dt)) {
    county_wfo_map <- nws_dt[, .(fips = FIPS, wfo = CWA, state = STATE,
                                  county_name = COUNTYNAME,
                                  lon = as.numeric(LON), lat = as.numeric(LAT))]
    county_wfo_map <- unique(county_wfo_map[!is.na(fips) & fips != ""])
    cat("County-WFO mappings:", nrow(county_wfo_map), "\n")
    cat("Unique WFOs:", uniqueN(county_wfo_map$wfo), "\n")
    fwrite(county_wfo_map, "data/county_wfo_map.csv")
    cat("Saved data/county_wfo_map.csv\n")
  }
}


## ============================================================
## 3. County adjacency data (Census)
## ============================================================
cat("\nFetching county adjacency data...\n")

adj_url <- "https://www2.census.gov/geo/docs/reference/county_adjacency2023.txt"
adj_resp <- GET(adj_url, timeout(60))

if (status_code(adj_resp) != 200) {
  # Try older URL
  adj_url <- "https://www2.census.gov/geo/docs/reference/county_adjacency.txt"
  adj_resp <- GET(adj_url, timeout(60))
}

if (status_code(adj_resp) == 200) {
  adj_raw <- content(adj_resp, "text", encoding = "UTF-8")
  writeLines(adj_raw, "data/county_adjacency.txt")
  cat("Saved data/county_adjacency.txt\n")
} else {
  cat("WARNING: Could not fetch adjacency file (status:", status_code(adj_resp), ")\n")
  cat("Will construct adjacency from shapefile spatial relationships.\n")
}


## ============================================================
## 4. IEM Cow API — WFO tornado warning verification
## ============================================================
cat("\nFetching IEM verification data...\n")

# Get WFOs from our county-WFO mapping
if (exists("county_wfo_map")) {
  wfos <- sort(unique(county_wfo_map$wfo))
} else {
  # Fallback: common CONUS WFOs
  wfos <- c("ABQ","ABR","AKQ","ALY","AMA","APX","ARX","BGM","BIS","BMX",
            "BOI","BOU","BOX","BRO","BTV","BUF","BYZ","CAE","CAR","CHS",
            "CLE","CRP","CTP","CYS","DDC","DLH","DMX","DTX","DVN","EAX",
            "EKA","EPZ","EWX","FFC","FGF","FGZ","FSD","FWD","GGW","GID",
            "GJT","GLD","GRB","GRR","GSP","GYX","HFO","HGX","HNX","HUN",
            "ICT","ILM","ILN","ILX","IND","IWX","JAN","JAX","JKL","KEY",
            "LBF","LCH","LIX","LKN","LMK","LOT","LOX","LSX","LUB","LWX",
            "LZK","MAF","MEG","MFL","MFR","MHX","MKX","MLB","MOB","MPX",
            "MQT","MRX","MSO","MTR","OAX","OHX","OKX","OTX","OUN","PAH",
            "PBZ","PDT","PHI","PIH","PQR","PSR","PUB","RAH","REV","RIW",
            "RLX","RNK","SEW","SGF","SGX","SHV","SJT","SLC","STO","TAE",
            "TBW","TFX","TOP","TSA","TWC","UNR","VEF")
}
cat("WFOs to query:", length(wfos), "\n")

years_iem <- 2008:2025
iem_results <- list()
n_fetched <- 0

for (w in wfos) {
  for (y in years_iem) {
    url <- sprintf(
      "https://mesonet.agron.iastate.edu/api/1/cow.json?wfo=%s&begints=%d-01-01T00:00Z&endts=%d-12-31T23:59Z&phenomena=TO&lsrtype=TO",
      w, y, y
    )

    resp <- tryCatch(GET(url, timeout(30)), error = function(e) NULL)
    if (is.null(resp) || status_code(resp) != 200) next

    json <- tryCatch(content(resp, "parsed"), error = function(e) NULL)
    if (is.null(json) || is.null(json$stats)) next

    s <- json$stats
    # Extract numeric values safely
    get_num <- function(x) if (is.null(x) || length(x) == 0) NA_real_ else as.numeric(x)
    get_int <- function(x) if (is.null(x) || length(x) == 0) 0L else as.integer(x)

    iem_results[[length(iem_results) + 1]] <- data.table(
      wfo = w,
      year = y,
      avg_leadtime = get_num(s$avg_leadtime),
      pod = get_num(s$POD),
      far = get_num(s$FAR),
      csi = get_num(s$CSI),
      n_events = get_int(s$events_verified),
      n_warnings = get_int(s$warned)
    )
    n_fetched <- n_fetched + 1
  }

  if (n_fetched %% 100 == 0) cat("  Fetched", n_fetched, "WFO-year records...\n")
  Sys.sleep(0.05)  # Be polite to API
}

iem <- rbindlist(iem_results, fill = TRUE)
cat("IEM records:", nrow(iem), "\n")
cat("WFO-years with lead time data:", nrow(iem[!is.na(avg_leadtime)]), "\n")

fwrite(iem, "data/iem_verification.csv")
cat("Saved data/iem_verification.csv\n")


## ============================================================
## 5. Census county population data
## ============================================================
cat("\nFetching Census county population...\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
pop_data <- list()

for (y in c(2010, 2015, 2020)) {
  url <- sprintf(
    "https://api.census.gov/data/%d/acs/acs5?get=B01003_001E,B25024_010E,NAME&for=county:*&key=%s",
    y, census_key
  )
  resp <- GET(url, timeout(60))
  if (status_code(resp) == 200) {
    parsed <- fromJSON(content(resp, "text"))
    dt <- as.data.table(parsed[-1, , drop = FALSE])
    setnames(dt, c("population", "mobile_homes", "name", "state_fips", "county_fips"))
    dt[, year := y]
    dt[, fips := paste0(state_fips, county_fips)]
    dt[, population := as.numeric(population)]
    dt[, mobile_homes := as.numeric(mobile_homes)]
    pop_data[[length(pop_data) + 1]] <- dt
    cat("  ACS", y, ":", nrow(dt), "counties\n")
  } else {
    cat("  ACS", y, ": failed (status", status_code(resp), ")\n")
  }
}

if (length(pop_data) > 0) {
  pop <- rbindlist(pop_data, fill = TRUE)
  fwrite(pop, "data/census_population.csv")
  cat("Saved data/census_population.csv\n")
} else {
  cat("WARNING: No Census data fetched\n")
}


## ============================================================
## Summary
## ============================================================
cat("\n=== DATA FETCH SUMMARY ===\n")
cat("Tornado events (2008+):", nrow(tornadoes), "\n")
cat("IEM verification records:", nrow(iem), "\n")
if (exists("county_wfo_map")) cat("County-WFO mappings:", nrow(county_wfo_map), "\n")
if (exists("pop")) cat("Census population records:", nrow(pop), "\n")
cat("========================\n")
