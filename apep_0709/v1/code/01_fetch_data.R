# 01_fetch_data.R — Fetch WFP food prices and UCDP conflict events
# apep_0709: Markets Under Fire

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. WFP Global Food Prices — Burkina Faso
# ============================================================
cat("Fetching WFP food price data for Burkina Faso...\n")

# HDX HAPI (Humanitarian API) — food prices for BFA
# Using the CSV export from HDX
wfp_urls <- c(
  "https://data.humdata.org/dataset/bfd82e1f-0296-48a8-ac28-c11e028be5ed/resource/0eca67d6-e297-4f5e-9132-7dc42891b749/download/wfp_food_prices_bfa.csv",
  "https://data.humdata.org/dataset/wfp-food-prices-for-burkina-faso/resource/15280a4f-ea33-415b-a320-e8b64e09a768/download/wfp_food_prices_bfa.csv"
)

wfp_file <- file.path(data_dir, "wfp_food_prices_bfa.csv")

if (!file.exists(wfp_file)) {
  downloaded <- FALSE
  for (url in wfp_urls) {
    cat(sprintf("  Trying: %s\n", substr(url, 1, 80)))
    resp <- httr::GET(url, httr::write_disk(wfp_file, overwrite = TRUE),
                      httr::timeout(120))
    if (httr::status_code(resp) == 200) {
      downloaded <- TRUE
      cat("  Downloaded WFP data.\n")
      break
    }
  }
  stopifnot("WFP download failed from all URLs" = downloaded)
} else {
  cat("  WFP data already cached.\n")
}

wfp <- fread(wfp_file, encoding = "UTF-8")
cat(sprintf("  WFP raw: %d rows, %d columns\n", nrow(wfp), ncol(wfp)))
cat(sprintf("  Columns: %s\n", paste(names(wfp), collapse = ", ")))

# Validate: must have price, market, date columns
stopifnot("WFP data has no rows" = nrow(wfp) > 1000)

# ============================================================
# 2. UCDP Georeferenced Event Dataset (GED) v24.1
# ============================================================
cat("\nFetching UCDP GED data...\n")

# UCDP GED global CSV — filter to Burkina Faso
ucdp_file <- file.path(data_dir, "ucdp_ged_bfa.csv")

if (!file.exists(ucdp_file)) {
  # Download full GED dataset and filter
  ucdp_url <- "https://ucdp.uu.se/downloads/ged/ged241-csv.zip"
  zip_file <- file.path(data_dir, "ged241-csv.zip")

  resp <- httr::GET(ucdp_url, httr::write_disk(zip_file, overwrite = TRUE),
                    httr::timeout(300),
                    httr::progress())
  stopifnot("UCDP download failed" = httr::status_code(resp) == 200)

  # Unzip and read
  unzip(zip_file, exdir = data_dir)
  ged_files <- list.files(data_dir, pattern = "GEDEvent.*\\.csv$", full.names = TRUE)
  stopifnot("No GED CSV found after unzip" = length(ged_files) > 0)

  ged_all <- fread(ged_files[1])
  cat(sprintf("  GED global: %d rows\n", nrow(ged_all)))

  # Filter to Burkina Faso (country_id = 439 or country name)
  ged_bfa <- ged_all[country == "Burkina Faso" | grepl("Burkina", country)]
  cat(sprintf("  GED Burkina Faso: %d rows\n", nrow(ged_bfa)))
  stopifnot("No UCDP events for Burkina Faso" = nrow(ged_bfa) > 100)

  fwrite(ged_bfa, ucdp_file)

  # Clean up large files
  file.remove(zip_file)
  file.remove(ged_files)
  cat("  Saved filtered UCDP data.\n")
} else {
  ged_bfa <- fread(ucdp_file)
  cat(sprintf("  UCDP data cached: %d rows\n", nrow(ged_bfa)))
}

# ============================================================
# 3. Validate both datasets
# ============================================================
cat("\n=== Data Validation ===\n")
cat(sprintf("WFP: %d rows\n", nrow(wfp)))
cat(sprintf("UCDP BFA: %d rows\n", nrow(ged_bfa)))
cat(sprintf("UCDP year range: %d-%d\n", min(ged_bfa$year), max(ged_bfa$year)))
cat(sprintf("UCDP has lat/lon: %s\n",
            all(c("latitude", "longitude") %in% names(ged_bfa))))

cat("\nData fetch complete.\n")
