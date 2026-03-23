## 01_fetch_data.R — Fetch FPA FOD wildfire data + daLaw treatment coding
## apep_0805: Prescribed fire liability reform and wildfire severity

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ─────────────────────────────────────────────────────────
# 1. Load daLaw from erer package — treatment classification
# ─────────────────────────────────────────────────────────
data(daLaw, package = "erer")
cat("daLaw loaded:", nrow(daLaw), "rows,", ncol(daLaw), "cols\n")
cat("Column names:", paste(names(daLaw), collapse = ", "), "\n")
print(str(daLaw))
print(table(daLaw$y))

# Save for later use
saveRDS(daLaw, file.path(data_dir, "daLaw.rds"))

# ─────────────────────────────────────────────────────────
# 2. Download FPA FOD 6th Edition (SQLite)
# ─────────────────────────────────────────────────────────
# The FPA FOD database is ~200MB zipped, ~800MB unzipped
# Direct download link from USDA Research Data Archive
# Try 6th edition first, fall back to 5th edition (Kaggle)
fod_db_v6 <- file.path(data_dir, "FPA_FOD_20221014.sqlite")
fod_db_v5 <- file.path(data_dir, "FPA_FOD_20170508.sqlite")

if (file.exists(fod_db_v6)) {
  fod_db <- fod_db_v6
  cat("Using FPA FOD 6th Edition (1992-2020):", round(file.size(fod_db) / 1e6, 1), "MB\n")
} else if (file.exists(fod_db_v5)) {
  fod_db <- fod_db_v5
  cat("Using FPA FOD 5th Edition (1992-2015):", round(file.size(fod_db) / 1e6, 1), "MB\n")
} else {
  # Download from Kaggle
  cat("Downloading FPA FOD from Kaggle...\n")
  system2("kaggle", c("datasets", "download", "-d", "rtatman/188-million-us-wildfires",
                       "-p", data_dir), stdout = TRUE, stderr = TRUE)
  zip_file <- file.path(data_dir, "188-million-us-wildfires.zip")
  if (file.exists(zip_file)) {
    unzip(zip_file, exdir = data_dir)
  }
  fod_db <- fod_db_v5
  if (!file.exists(fod_db)) {
    stop("FPA FOD download failed. Cannot proceed without real data.")
  }
  cat("Downloaded FPA FOD:", round(file.size(fod_db) / 1e6, 1), "MB\n")
}

# ─────────────────────────────────────────────────────────
# 3. Extract state-year panel from FPA FOD
# ─────────────────────────────────────────────────────────
con <- dbConnect(RSQLite::SQLite(), fod_db)

# Check table names
tables <- dbListTables(con)
cat("Tables in database:", paste(tables, collapse = ", "), "\n")

# Query the main fires table — extract key fields
# FIRE_YEAR, STATE, FIRE_SIZE, FIRE_SIZE_CLASS, STAT_CAUSE_DESCR
fires_raw <- dbGetQuery(con, "
  SELECT FIRE_YEAR, STATE, FIRE_SIZE, FIRE_SIZE_CLASS,
         STAT_CAUSE_DESCR, OWNER_DESCR, LATITUDE, LONGITUDE,
         NWCG_REPORTING_AGENCY
  FROM Fires
  WHERE FIRE_YEAR >= 1992
")
dbDisconnect(con)

cat("Loaded", nrow(fires_raw), "fire records from FPA FOD\n")
stopifnot(nrow(fires_raw) > 1e6)  # Should be ~2.3M

# Quick summary
cat("\nFire years range:", range(fires_raw$FIRE_YEAR), "\n")
cat("States:", length(unique(fires_raw$STATE)), "\n")
cat("Cause categories:", paste(unique(fires_raw$STAT_CAUSE_DESCR), collapse = ", "), "\n")

# ─────────────────────────────────────────────────────────
# 4. Aggregate to state-year panel
# ─────────────────────────────────────────────────────────
fires <- as.data.table(fires_raw)

# Total fires, total acres, large fires (>100 acres)
state_year <- fires[, .(
  n_fires      = .N,
  total_acres  = sum(FIRE_SIZE, na.rm = TRUE),
  large_fires  = sum(FIRE_SIZE > 100, na.rm = TRUE),
  mean_size    = mean(FIRE_SIZE, na.rm = TRUE),
  # By cause
  n_debris     = sum(STAT_CAUSE_DESCR == "Debris Burning", na.rm = TRUE),
  n_lightning  = sum(STAT_CAUSE_DESCR == "Lightning", na.rm = TRUE),
  n_arson      = sum(STAT_CAUSE_DESCR == "Arson", na.rm = TRUE),
  # By land ownership (private vs public)
  n_private    = sum(OWNER_DESCR %in% c("PRIVATE", "Private"), na.rm = TRUE),
  n_federal    = sum(grepl("USFS|BLM|NPS|FWS|BIA|DOD|DOE|USDA|BOR", OWNER_DESCR), na.rm = TRUE),
  acres_private = sum(FIRE_SIZE[OWNER_DESCR %in% c("PRIVATE", "Private")], na.rm = TRUE),
  acres_federal = sum(FIRE_SIZE[grepl("USFS|BLM|NPS|FWS|BIA|DOD|DOE|USDA|BOR", OWNER_DESCR)], na.rm = TRUE),
  # Large fires on different land types
  large_private = sum(FIRE_SIZE > 100 & OWNER_DESCR %in% c("PRIVATE", "Private"), na.rm = TRUE),
  large_federal = sum(FIRE_SIZE > 100 & grepl("USFS|BLM|NPS|FWS|BIA|DOD|DOE|USDA|BOR", OWNER_DESCR), na.rm = TRUE)
), by = .(state = STATE, year = FIRE_YEAR)]

cat("\nState-year panel:", nrow(state_year), "observations\n")
cat("States:", length(unique(state_year$state)), "\n")
cat("Years:", range(state_year$year), "\n")

# Log transformations
state_year[, `:=`(
  ln_fires     = log(1 + n_fires),
  ln_acres     = log(1 + total_acres),
  ln_large     = log(1 + large_fires),
  ln_debris    = log(1 + n_debris),
  ln_lightning = log(1 + n_lightning),
  ln_private_fires = log(1 + n_private),
  ln_federal_fires = log(1 + n_federal),
  ln_private_acres = log(1 + acres_private),
  ln_federal_acres = log(1 + acres_federal)
)]

saveRDS(state_year, file.path(data_dir, "state_year_panel.rds"))
cat("Saved state-year panel to", file.path(data_dir, "state_year_panel.rds"), "\n")
