# 01_fetch_data.R — Download SBC LTER KFCD fish data and validate
# Data source: SBC LTER (Santa Barbara Coastal Long Term Ecological Research)
# Dataset: knb-lter-sbc.17 — Giant Kelp Forest Community Dynamics, reef fish component
# URL: https://portal.edirepository.org/nis/mapbrowse?scope=knb-lter-sbc&identifier=17

setwd(here::here())
source("code/00_packages.R")

# --- Download KFCD fish data (2000-2025, 11 sites, annual) ---
kfcd_url <- "https://pasta.lternet.edu/package/data/eml/knb-lter-sbc/17/41/a7899f2e57ea29a240be2c00cce7a0d4"
kfcd_file <- "data/sbc_lter_kfcd_fish.csv"

if (!file.exists(kfcd_file)) {
  download.file(kfcd_url, kfcd_file, mode = "wb")
}

fish <- fread(kfcd_file)
cat("KFCD fish data loaded:", nrow(fish), "rows\n")

# --- Validate essential columns exist ---
required_cols <- c("YEAR", "SITE", "TRANSECT", "SP_CODE", "COUNT",
                   "COMMON_NAME", "SCIENTIFIC_NAME")
missing <- setdiff(required_cols, names(fish))
if (length(missing) > 0) {
  stop("FATAL: Missing required columns: ", paste(missing, collapse = ", "))
}

# --- Basic data validation ---
stopifnot("No data loaded" = nrow(fish) > 0)
stopifnot("No sites" = length(unique(fish$SITE)) >= 10)
stopifnot("Year range too short" = max(fish$YEAR) - min(fish$YEAR) >= 20)

cat("Sites:", paste(sort(unique(fish$SITE)), collapse = ", "), "\n")
cat("Year range:", min(fish$YEAR), "-", max(fish$YEAR), "\n")
cat("Species:", length(unique(fish$SP_CODE)), "\n")
cat("Rows:", nrow(fish), "\n")

# --- Download MPA boundary data for treatment assignment verification ---
mpa_url <- "https://data-cdfw.opendata.arcgis.com/api/download/v1/items/117a99c8745a48c6a48bac70005b1b11/csv?layers=0"
mpa_file <- "data/mpa_boundaries.csv"
if (!file.exists(mpa_file)) {
  download.file(mpa_url, mpa_file, mode = "wb")
}
mpa <- fread(mpa_file)
cat("MPA boundary data loaded:", nrow(mpa), "MPAs\n")

# --- Save validated raw data ---
saveRDS(fish, "data/fish_raw.rds")
saveRDS(mpa, "data/mpa_boundaries.rds")
cat("Data fetch complete. Files saved to data/\n")
