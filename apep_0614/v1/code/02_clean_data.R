## 02_clean_data.R — Clean and merge CEJST, EV, and HMDA data
## APEP paper apep_0614: CEJST Justice40 RDD
## Uses spatial join with TIGER/Line tract shapefile for EV geocoding

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Load and clean CEJST data
# ============================================================
cat("=== Processing CEJST data ===\n")

# Read GEOID10 as character to preserve leading zeros (11-digit FIPS overflows int)
cejst <- fread(file.path(data_dir, "cejst_tracts.csv"), colClasses = c(GEOID10 = "character"))
cat("CEJST raw rows:", nrow(cejst), "\n")

# Standardize tract ID
cejst[, tract_id := GEOID10]
cejst[, state_fips := substr(tract_id, 1, 2)]
cejst[, county_fips := substr(tract_id, 1, 5)]

# Designation
cejst[, designated := as.integer(SN_C)]
cat("Designated:", sum(cejst$designated == 1, na.rm = TRUE), "\n")
cat("Not designated:", sum(cejst$designated == 0, na.rm = TRUE), "\n")

# Income percentile (running variable)
cejst[, income_pctile := as.numeric(P200_I_PFS)]

# Population
cejst[, population := as.numeric(TPF)]

# Burden category indicators
burden_cats <- c("N_CLT", "N_ENY", "N_TRN", "N_HSG", "N_PLN", "N_HLTH", "N_WTR", "N_WKFC")
for (bc in burden_cats) cejst[, (bc) := as.integer(get(bc))]

cejst[, meets_any_burden := as.integer(rowSums(.SD, na.rm = TRUE) > 0), .SDcols = burden_cats]
cejst[, n_burdens := rowSums(.SD, na.rm = TRUE), .SDcols = burden_cats]
cat("Tracts meeting any burden:", sum(cejst$meets_any_burden == 1), "\n")

# Center running variable at 0.65 (65th percentile cutoff)
cejst[, rv_centered := income_pctile - 0.65]

# Burden percentile scores (covariates)
pctile_cols <- c("DF_PFS", "AF_PFS", "HDF_PFS", "EBF_PFS", "PM25F_PFS",
                 "LPF_PFS", "TF_PFS", "WF_PFS")
for (pc in pctile_cols) cejst[, (pc) := as.numeric(get(pc))]

# Demographics
demo_cols <- c("DM_B", "DM_AI", "DM_A", "DM_HI", "DM_T", "DM_W", "DM_H", "DM_O")
for (dc in demo_cols) cejst[, (dc) := as.numeric(get(dc))]

cat("CEJST processed:", nrow(cejst), "tracts\n")

# ============================================================
# 2. Download census tract shapefile for spatial join
# ============================================================
cat("\n=== Downloading census tract shapefile ===\n")

shp_dir <- file.path(data_dir, "tract_shp")
shp_file <- file.path(shp_dir, "cb_2020_us_tract_500k.shp")

if (!file.exists(shp_file)) {
  dir.create(shp_dir, showWarnings = FALSE, recursive = TRUE)
  # Cartographic boundary file — smaller (~80MB) but sufficient for point-in-polygon
  shp_url <- "https://www2.census.gov/geo/tiger/GENZ2020/shp/cb_2020_us_tract_500k.zip"
  shp_zip <- file.path(shp_dir, "tracts.zip")

  cat("Downloading TIGER/Line tract shapefile (~300MB)...\n")
  resp <- request(shp_url) |>
    req_timeout(600) |>
    req_perform()

  if (resp_status(resp) != 200) {
    stop("Tract shapefile download failed: ", resp_status(resp))
  }
  writeBin(resp_body_raw(resp), shp_zip)
  cat("Unzipping...\n")
  unzip(shp_zip, exdir = shp_dir)
  cat("Shapefile ready.\n")
} else {
  cat("Tract shapefile already exists.\n")
}

# ============================================================
# 3. Load and geocode EV stations via spatial join
# ============================================================
cat("\n=== Processing EV charger data ===\n")

ev <- fread(file.path(data_dir, "nrel_ev_stations.csv"))
cat("EV stations raw:", nrow(ev), "\n")

ev[, lat := as.numeric(Latitude)]
ev[, lon := as.numeric(Longitude)]
ev[, open_date := as.Date(`Open Date`)]

# Filter valid US locations
ev <- ev[!is.na(lat) & !is.na(lon) & lat > 20 & lat < 72 & lon > -180 & lon < -60]
cat("EV stations with valid coords:", nrow(ev), "\n")

# Period classification
cejst_start <- as.Date("2022-11-01")
cejst_end <- as.Date("2025-01-20")
pre_start <- as.Date("2020-11-01")

ev[, period := fcase(
  open_date >= cejst_start & open_date <= cejst_end, "post",
  open_date >= pre_start & open_date < cejst_start, "pre",
  default = "other"
)]
cat("EV by period:\n")
print(ev[, .N, by = period][order(period)])

# Keep only pre/post stations
ev_work <- ev[period %in% c("pre", "post")]
cat("EV stations to assign to tracts:", nrow(ev_work), "\n")

ev_geocoded_file <- file.path(data_dir, "ev_geocoded.rds")

if (!file.exists(ev_geocoded_file)) {
  # Load tract shapefile
  cat("Loading tract shapefile...\n")
  tracts_sf <- st_read(shp_file, quiet = TRUE)
  cat("Tract polygons loaded:", nrow(tracts_sf), "\n")

  # Convert EV stations to sf points
  cat("Creating spatial points for EV stations...\n")
  ev_sf <- st_as_sf(ev_work, coords = c("lon", "lat"), crs = 4269)  # NAD83 = TIGER CRS

  # Spatial join: assign each EV station to the tract it falls within
  cat("Running spatial join (this takes ~1-2 min)...\n")
  ev_joined <- st_join(ev_sf, tracts_sf[, c("GEOID", "geometry")], join = st_within)

  # Extract tract ID — GEOID is already a properly formatted 11-char string
  ev_work[, tract_id := as.character(ev_joined$GEOID)]
  # Ensure 11-digit padding (GEOID should already be padded, but just in case)
  ev_work[!is.na(tract_id), tract_id := stringr::str_pad(tract_id, 11, pad = "0")]

  cat("Geocoded:", sum(!is.na(ev_work$tract_id)), "/", nrow(ev_work),
      "(", round(100 * mean(!is.na(ev_work$tract_id)), 1), "%)\n")

  saveRDS(ev_work, ev_geocoded_file)
  rm(tracts_sf, ev_sf, ev_joined)
  gc()
} else {
  ev_work <- readRDS(ev_geocoded_file)
  cat("Loaded cached geocoded EV stations:", sum(!is.na(ev_work$tract_id)), "/", nrow(ev_work), "\n")
}

# Aggregate to tract level
ev_tract <- ev_work[!is.na(tract_id), .(
  ev_count_pre = sum(period == "pre"),
  ev_count_post = sum(period == "post")
), by = tract_id]
cat("Tracts with any EV station:", nrow(ev_tract), "\n")

# ============================================================
# 4. Load and process HMDA data
# ============================================================
cat("\n=== Processing HMDA data ===\n")

hmda_dir <- file.path(data_dir, "hmda")

process_hmda <- function(year) {
  f <- file.path(hmda_dir, paste0("hmda_", year, ".csv"))
  if (!file.exists(f)) {
    cat(sprintf("HMDA %d not found.\n", year))
    return(NULL)
  }

  cat(sprintf("Processing HMDA %d...\n", year))
  dt <- fread(f, select = c("census_tract", "action_taken", "loan_amount",
                             "income", "property_value"),
              na.strings = c("", "NA", "Exempt", "null"))

  cat(sprintf("  HMDA %d raw: %s rows\n", year, format(nrow(dt), big.mark = ",")))

  # census_tract is a large number — handle as character to avoid integer overflow
  dt[, tract_id := stringr::str_pad(as.character(census_tract), 11, pad = "0")]
  dt <- dt[!is.na(census_tract) & nchar(tract_id) == 11 & tract_id != "          NA"]

  agg <- dt[, .(
    n_originated = sum(action_taken == 1, na.rm = TRUE),
    n_applications = .N,
    mean_loan_amount = mean(as.numeric(loan_amount), na.rm = TRUE),
    mean_income = mean(as.numeric(income), na.rm = TRUE)
  ), by = tract_id]

  cat(sprintf("  HMDA %d: %s tracts\n", year, format(nrow(agg), big.mark = ",")))
  rm(dt); gc()
  return(agg)
}

hmda_pre <- process_hmda(2021)
hmda_post <- process_hmda(2023)

if (!is.null(hmda_pre) && !is.null(hmda_post)) {
  hmda_merged <- merge(
    hmda_pre[, .(tract_id, orig_pre = n_originated, apps_pre = n_applications,
                  loan_amt_pre = mean_loan_amount)],
    hmda_post[, .(tract_id, orig_post = n_originated, apps_post = n_applications,
                   loan_amt_post = mean_loan_amount)],
    by = "tract_id", all = TRUE
  )
  hmda_merged[is.na(orig_pre), orig_pre := 0L]
  hmda_merged[is.na(orig_post), orig_post := 0L]
  hmda_merged[, orig_change := orig_post - orig_pre]
  hmda_merged[, orig_pct_change := fifelse(orig_pre > 5, (orig_post - orig_pre) / orig_pre, NA_real_)]
  cat("HMDA merged tracts:", nrow(hmda_merged), "\n")
  rm(hmda_pre, hmda_post); gc()
} else {
  hmda_merged <- NULL
}

# ============================================================
# 5. Merge all datasets
# ============================================================
cat("\n=== Merging datasets ===\n")

keep_cols <- c("tract_id", "state_fips", "county_fips", "designated",
               "income_pctile", "rv_centered", "meets_any_burden", "n_burdens",
               "population", burden_cats, pctile_cols, demo_cols)
analysis <- cejst[, ..keep_cols]

# Merge EV
analysis <- merge(analysis, ev_tract, by = "tract_id", all.x = TRUE)
analysis[is.na(ev_count_pre), ev_count_pre := 0L]
analysis[is.na(ev_count_post), ev_count_post := 0L]
analysis[, any_ev_post := as.integer(ev_count_post > 0)]
analysis[, ev_change := ev_count_post - ev_count_pre]

# Merge HMDA
if (!is.null(hmda_merged)) {
  analysis <- merge(analysis, hmda_merged, by = "tract_id", all.x = TRUE)
}

cat("\n=== Final Analysis Dataset ===\n")
cat("Total tracts:", nrow(analysis), "\n")
cat("Designated:", sum(analysis$designated == 1, na.rm = TRUE), "\n")
cat("Meets any burden:", sum(analysis$meets_any_burden == 1, na.rm = TRUE), "\n")
rdd_n <- nrow(analysis[meets_any_burden == 1 & !is.na(income_pctile)])
cat("RDD sample (burden + valid income):", rdd_n, "\n")
cat("Any new EV post:", sum(analysis$any_ev_post == 1, na.rm = TRUE), "\n")
cat("Mean EV post (all):", mean(analysis$ev_count_post), "\n")
cat("Mean EV post (designated):", mean(analysis[designated == 1]$ev_count_post), "\n")
cat("Mean EV post (not designated):", mean(analysis[designated == 0]$ev_count_post), "\n")
if ("orig_post" %in% names(analysis)) {
  cat("Tracts with HMDA data:", sum(!is.na(analysis$orig_post)), "\n")
}

saveRDS(analysis, file.path(data_dir, "analysis_dataset.rds"))
cat("\nSaved analysis_dataset.rds\n")
