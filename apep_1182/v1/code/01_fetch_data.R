## 01_fetch_data.R — Fetch and prepare all data for analysis
source("./code/00_packages.R")

data_dir <- "./data"

## 1. County centroids from Census Gazetteer --------------------------------
cat("=== Loading county centroids ===\n")
gaz <- fread("/tmp/2019_Gaz_counties_national.txt", sep = "\t")
names(gaz) <- trimws(names(gaz))
# Build 5-digit FIPS
gaz[, fips := sprintf("%02d%03d", as.integer(USPS), GEOID %% 1000)]
# Actually GEOID is already 5-digit FIPS
gaz[, fips := sprintf("%05d", GEOID)]
gaz_clean <- gaz[, .(fips, lat = INTPTLAT, lon = INTPTLONG)]
gaz_clean <- gaz_clean[nchar(fips) == 5]
cat(sprintf("  Counties: %d\n", nrow(gaz_clean)))
fwrite(gaz_clean, file.path(data_dir, "county_centroids.csv"))

## 2. Coal plant data (already prepared in Python) -------------------------
cat("=== Loading coal plant data ===\n")
coal <- fread(file.path(data_dir, "coal_plants.csv"))
coal <- coal[!is.na(lat) & !is.na(lon)]
# Use SO2 + NOx as emission measure (precursors to PM2.5)
coal[, total_emissions := fifelse(is.na(PLSO2AN), 0, PLSO2AN) +
                          fifelse(is.na(PLNOXAN), 0, PLNOXAN)]
cat(sprintf("  Coal plants: %d, with emissions: %d\n",
            nrow(coal), sum(coal$total_emissions > 0)))

## 3. County-year PM2.5 from CDC -------------------------------------------
cat("=== Loading county-year PM2.5 ===\n")
pm25 <- fread("/tmp/county_year_pm25_2001_2019.csv")
pm25[, fips := sprintf("%02d%03d", as.integer(statefips), as.integer(countyfips))]
cat(sprintf("  PM2.5 observations: %d, years: %s\n",
            nrow(pm25), paste(unique(pm25$year), collapse=", ")))

## 4. QCEW labor data (pre-downloaded via curl) ----------------------------
cat("=== Loading QCEW county-year data ===\n")
qcew_all <- list()
for (yr in 2016:2019) {
  destfile <- sprintf("/tmp/qcew_%d.zip", yr)
  stopifnot(file.exists(destfile))

  tmpdir <- sprintf("/tmp/qcew_%d", yr)
  dir.create(tmpdir, showWarnings = FALSE)
  unzip(destfile, exdir = tmpdir, overwrite = TRUE)
  csvfile <- list.files(tmpdir, pattern = "\\.csv$", full.names = TRUE)[1]

  dt <- fread(csvfile)
  # Filter: all industries (10), total all ownerships (0), county level (70)
  dt <- dt[own_code == 0 & industry_code == "10" & agglvl_code == 70]
  dt[, year := yr]
  dt[, fips := sprintf("%05d", as.integer(area_fips))]
  qcew_all[[as.character(yr)]] <- dt[, .(fips, year,
                                          annual_avg_emplvl,
                                          total_annual_wages,
                                          annual_avg_estabs = qtrly_estabs)]
  cat(sprintf("  QCEW %d: %d counties\n", yr, nrow(dt)))
}

qcew <- rbindlist(qcew_all)
cat(sprintf("  Total QCEW observations: %d\n", nrow(qcew)))
fwrite(qcew, file.path(data_dir, "qcew_county_year.csv"))

## 5. Compute coal exposure instrument -------------------------------------
cat("=== Computing coal exposure instrument ===\n")
# For each county, compute emission-weighted inverse-distance-squared from all coal plants
# Exclude plants in the same county (own-county exclusion)

counties <- gaz_clean
plants <- coal[total_emissions > 0]

# Compute pairwise distances (this is the key step)
cat(sprintf("  Computing %d × %d = %s pairwise distances...\n",
            nrow(counties), nrow(plants),
            format(nrow(counties) * nrow(plants), big.mark = ",")))

# Use geosphere::distVincentySphere for accurate distances
# Build matrices
county_coords <- as.matrix(counties[, .(lon, lat)])
plant_coords <- as.matrix(plants[, .(lon, lat)])

# Compute distance matrix (meters)
dist_mat <- distm(county_coords, plant_coords, fun = distVincentySphere)
dist_km <- dist_mat / 1000

# Build FIPS for county-plant matching (for own-county exclusion)
county_state_fips <- substr(counties$fips, 1, 2)
plant_state_fips <- plants$state_fips

# Coal exposure: sum over plants (excluding own-county, >25km)
emissions_vec <- plants$total_emissions
exposure <- matrix(0, nrow = nrow(counties), ncol = 1)

for (i in seq_len(nrow(counties))) {
  # Exclude plants within 25km (own-county proxy)
  mask <- dist_km[i, ] > 25
  if (any(mask)) {
    exposure[i, 1] <- sum(emissions_vec[mask] / (dist_km[i, mask])^2)
  }
}

counties[, coal_exposure := exposure[, 1]]
cat(sprintf("  Coal exposure: mean=%.2f, sd=%.2f, min=%.2f, max=%.2f\n",
            mean(counties$coal_exposure), sd(counties$coal_exposure),
            min(counties$coal_exposure), max(counties$coal_exposure)))

fwrite(counties[, .(fips, lat, lon, coal_exposure)],
       file.path(data_dir, "county_coal_exposure.csv"))

## 6. Merge all datasets ----------------------------------------------------
cat("=== Merging datasets ===\n")
pm25_clean <- pm25[, .(fips, year, pm25 = as.numeric(pm25_annual))]
qcew_clean <- qcew[, .(fips, year, employment = annual_avg_emplvl,
                        wages = total_annual_wages, establishments = annual_avg_estabs)]
exposure <- fread(file.path(data_dir, "county_coal_exposure.csv"))

panel <- merge(pm25_clean, qcew_clean, by = c("fips", "year"), all.x = TRUE)
panel <- merge(panel, exposure[, .(fips, coal_exposure)], by = "fips", all.x = TRUE)

# Add state FIPS for state×year FE
panel[, state_fips := substr(fips, 1, 2)]

# Compute per-worker wages
panel[, wages_per_worker := wages / employment]
panel[, log_wages_pw := log(wages_per_worker)]
panel[, log_employment := log(employment)]

# Drop incomplete observations
panel <- panel[!is.na(pm25) & !is.na(employment) & !is.na(coal_exposure) &
               employment > 0 & wages > 0 & coal_exposure > 0]

cat(sprintf("  Final panel: %d county-years, %d unique counties, years: %s\n",
            nrow(panel), uniqueN(panel$fips), paste(sort(unique(panel$year)), collapse=", ")))

# Save diagnostics
diagnostics <- list(
  n_treated = uniqueN(panel$fips),
  n_pre = 0,  # cross-sectional IV, not DiD
  n_obs = nrow(panel)
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("  diagnostics.json written\n")

fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat("=== Data preparation complete ===\n")
