## 01_fetch_data.R — Download SEWIK accident data from Zenodo
## APEP paper apep_1001: Poland Sunday Trading Ban and Traffic Accidents

source("00_packages.R")

cat("=== Fetching SEWIK accident data from Zenodo ===\n")

# Download incidents.csv from Zenodo record 15731344
incidents_url <- "https://zenodo.org/api/records/15731344/files/incidents.csv/content"
dest_file <- "../data/incidents.csv"

if (!file.exists(dest_file)) {
  cat("Downloading incidents.csv from Zenodo...\n")
  download.file(incidents_url, destfile = dest_file, mode = "wb", quiet = FALSE)
  cat("Download complete.\n")
} else {
  cat("incidents.csv already exists, skipping download.\n")
}

# Validate download
stopifnot("Download failed: incidents.csv does not exist" = file.exists(dest_file))
file_size <- file.info(dest_file)$size
cat(sprintf("File size: %.1f MB\n", file_size / 1024^2))
stopifnot("File too small — download likely failed" = file_size > 1e6)

# Read and validate
incidents <- fread(dest_file, encoding = "UTF-8")
cat(sprintf("Loaded %d records with %d columns\n", nrow(incidents), ncol(incidents)))
cat(sprintf("Columns: %s\n", paste(names(incidents), collapse = ", ")))

# Basic validation
stopifnot("Missing datetime column" = "datetime" %in% names(incidents))
stopifnot("Missing voivodeship column" = "voivodeship" %in% names(incidents))
stopifnot("Too few records — expected ~88K+" = nrow(incidents) > 50000)

# Check date range
incidents[, datetime_parsed := as.POSIXct(datetime, format = "%Y-%m-%d %H:%M:%S")]
date_range <- range(as.Date(incidents$datetime_parsed), na.rm = TRUE)
cat(sprintf("Date range: %s to %s\n", date_range[1], date_range[2]))

# Check voivodeships
voivodeships <- unique(incidents$voivodeship)
cat(sprintf("Voivodeships: %d (%s)\n", length(voivodeships),
            paste(head(sort(voivodeships), 5), collapse = ", ")))
stopifnot("Expected 16 voivodeships" = length(voivodeships) >= 14)

cat("\n=== SEWIK data fetch complete ===\n")

# Also download weather data (for controls)
weather_url <- "https://zenodo.org/api/records/15731344/files/weather-data.csv/content"
weather_dest <- "../data/weather.csv"

if (!file.exists(weather_dest)) {
  cat("Downloading weather-data.csv from Zenodo...\n")
  download.file(weather_url, destfile = weather_dest, mode = "wb", quiet = FALSE)
  cat("Weather data download complete.\n")
} else {
  cat("weather-data.csv already exists.\n")
}

cat("=== All data fetched successfully ===\n")
