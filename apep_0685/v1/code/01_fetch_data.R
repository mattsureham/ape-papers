# 01_fetch_data.R — Fetch ECCC GHGRP facility-level emissions data
# apep_0685: Canada carbon pricing backstop

source("00_packages.R")

cat("=== Fetching ECCC GHGRP data ===\n")

# ECCC GHGRP — facility-level GHG reporting
# Facilities reporting >= 10 kt CO2e per year
ghgrp_url <- "https://data-donnees.az.ec.gc.ca/api/file?path=%2Fsubstances%2Fmonitor%2Fgreenhouse-gas-reporting-program-ghgrp-facility-greenhouse-gas-ghg-data%2FPDGES-GHGRP-GHGEmissionsGES-2004-Present.csv"

ghgrp_file <- "../data/ghgrp_raw.csv"

if (!file.exists(ghgrp_file) || file.size(ghgrp_file) < 100000) {
  cat("Downloading GHGRP data with curl (R download.file fails on redirect)...\n")
  status <- system2("curl", args = c("-sL", shQuote(ghgrp_url), "-o", ghgrp_file), stdout = TRUE, stderr = TRUE)
  cat(sprintf("Download complete. File size: %s bytes\n", file.size(ghgrp_file)))
}

# Read and validate
ghgrp <- fread(ghgrp_file, encoding = "Latin-1")
cat(sprintf("GHGRP rows: %d\n", nrow(ghgrp)))
cat(sprintf("GHGRP columns: %d\n", ncol(ghgrp)))

# Simplify column names (bilingual headers are long)
orig_names <- names(ghgrp)
cat("Original column names (first 10):\n")
print(head(orig_names, 10))

# Check year column — it has a bilingual name
year_col <- grep("Reference Year", names(ghgrp), value = TRUE)[1]
prov_col <- grep("Province", names(ghgrp), value = TRUE)[1]
cat(sprintf("Year column: %s\n", year_col))
cat(sprintf("Province column: %s\n", prov_col))

cat(sprintf("Year range: %d - %d\n",
            min(ghgrp[[year_col]], na.rm = TRUE),
            max(ghgrp[[year_col]], na.rm = TRUE)))

# Check province distribution (latest year)
cat("\nFacilities by province (latest year):\n")
latest <- ghgrp[ghgrp[[year_col]] == max(ghgrp[[year_col]], na.rm = TRUE), ]
print(table(latest[[prov_col]]))

stopifnot("GHGRP data must have >10000 rows" = nrow(ghgrp) > 10000)

# Save raw version
saveRDS(ghgrp, "../data/ghgrp_raw.rds")
cat("GHGRP data saved to data/ghgrp_raw.rds\n")

# === Fetch FRED WTI oil prices ===
cat("\n=== Fetching WTI oil prices from FRED ===\n")

fred_key <- Sys.getenv("FRED_API_KEY")
if (fred_key == "") stop("FRED_API_KEY not set in .env")

wti_url <- sprintf(
  "https://api.stlouisfed.org/fred/series/observations?series_id=DCOILWTICO&api_key=%s&file_type=json&observation_start=2004-01-01&observation_end=2023-12-31",
  fred_key
)

wti_resp <- jsonlite::fromJSON(wti_url)
wti_raw <- wti_resp$observations

wti <- wti_raw |>
  mutate(
    date = as.Date(date),
    price = as.numeric(value),
    year = lubridate::year(date)
  ) |>
  filter(!is.na(price)) |>
  group_by(year) |>
  summarise(wti_annual = mean(price, na.rm = TRUE), .groups = "drop")

cat(sprintf("WTI annual prices: %d years\n", nrow(wti)))
stopifnot("WTI must cover 2004-2023" = all(2004:2023 %in% wti$year))

saveRDS(wti, "../data/wti_prices.rds")
cat("WTI data saved.\n")

cat("\n=== Data fetch complete ===\n")
