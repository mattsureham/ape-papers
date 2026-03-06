# 02_clean_data.R — Clean DVF data, compute distances to GPE stations, construct analysis panel
# APEP-0540: Grand Paris Express Construction-Phase Capitalization

source("00_packages.R")

cat("=== PHASE 2: DATA CLEANING AND PANEL CONSTRUCTION ===\n")

# ──────────────────────────────────────────────────────────────────
# 1. LOAD AND HARMONIZE DVF DATA
# ──────────────────────────────────────────────────────────────────

cat("Loading geo-DVF (2020-2024)...\n")
geo_dvf <- fread(file.path(DATA_DIR, "geo_dvf_idf_2020_2024.csv"))

# Check for pre-2020 cadastre DVF
pre2020_file <- file.path(DATA_DIR, "cadastre_dvf_idf_pre2020.csv")
has_pre2020 <- file.exists(pre2020_file) && file.size(pre2020_file) > 100

if (has_pre2020) {
  cat("Loading pre-2020 cadastre DVF...\n")
  cadastre_dvf <- fread(pre2020_file)

  # Harmonize column names between geo-DVF and cadastre DVF
  # Cadastre DVF uses similar names but may differ
  common_cols <- intersect(names(geo_dvf), names(cadastre_dvf))
  cat(sprintf("  Common columns: %d\n", length(common_cols)))

  # The cadastre format from etalab-dvf has the same column names as geo-dvf
  dvf <- rbindlist(list(geo_dvf, cadastre_dvf), fill = TRUE, use.names = TRUE)
  cat(sprintf("  Combined DVF: %s rows (%d-%d)\n",
              format(nrow(dvf), big.mark = ","),
              min(dvf$year, na.rm = TRUE), max(dvf$year, na.rm = TRUE)))
} else {
  cat("No pre-2020 data available. Using 2020-2024 only.\n")
  dvf <- copy(geo_dvf)
}

rm(geo_dvf)
if (exists("cadastre_dvf")) rm(cadastre_dvf)
gc()

# ──────────────────────────────────────────────────────────────────
# 2. CLEAN TRANSACTION DATA
# ──────────────────────────────────────────────────────────────────

cat("\nCleaning transaction data...\n")
n_start <- nrow(dvf)

# Parse date
dvf[, date := as.Date(date_mutation)]
dvf[, year_quarter := paste0(year(date), "Q", quarter(date))]
dvf[, year_month := floor_date(date, "month")]

# Filter to residential properties (apartments = 2, houses = 1)
dvf <- dvf[code_type_local %in% c(1, 2)]
cat(sprintf("  After residential filter: %s rows (dropped %s)\n",
            format(nrow(dvf), big.mark = ","),
            format(n_start - nrow(dvf), big.mark = ",")))

# Clean prices
dvf[, price := as.numeric(gsub(",", ".", as.character(valeur_fonciere)))]
dvf <- dvf[!is.na(price) & price > 10000 & price < 5000000]
cat(sprintf("  After price filter (10K-5M EUR): %s rows\n",
            format(nrow(dvf), big.mark = ",")))

# Clean surface area
dvf[, surface := as.numeric(surface_reelle_bati)]
dvf <- dvf[!is.na(surface) & surface >= 9 & surface <= 500]
cat(sprintf("  After surface filter (9-500 m2): %s rows\n",
            format(nrow(dvf), big.mark = ",")))

# Compute price per m2
dvf[, price_m2 := price / surface]
dvf[, log_price_m2 := log(price_m2)]

# Drop extreme price_m2 (below 1st or above 99th percentile)
p01 <- quantile(dvf$price_m2, 0.01, na.rm = TRUE)
p99 <- quantile(dvf$price_m2, 0.99, na.rm = TRUE)
dvf <- dvf[price_m2 >= p01 & price_m2 <= p99]
cat(sprintf("  After price_m2 winsorization (1%%-99%%): %s rows\n",
            format(nrow(dvf), big.mark = ",")))

# Clean coordinates
dvf <- dvf[!is.na(longitude) & !is.na(latitude)]
dvf <- dvf[longitude > 1.0 & longitude < 4.0 & latitude > 48.0 & latitude < 49.5]
cat(sprintf("  After coordinate filter (IDF bounding box): %s rows\n",
            format(nrow(dvf), big.mark = ",")))

# Rooms
dvf[, rooms := as.integer(nombre_pieces_principales)]

# Property type label
dvf[, prop_type := fifelse(code_type_local == 2, "apartment", "house")]

# Commune code (ensure 5-digit)
dvf[, commune := str_pad(as.character(code_commune), 5, pad = "0")]
dvf[, department := substr(commune, 1, 2)]

cat(sprintf("\nCleaned DVF: %s transactions, %d communes, years %d-%d\n",
            format(nrow(dvf), big.mark = ","),
            uniqueN(dvf$commune),
            min(year(dvf$date)), max(year(dvf$date))))

# ──────────────────────────────────────────────────────────────────
# 3. COMPUTE DISTANCES TO GPE STATIONS
# ──────────────────────────────────────────────────────────────────

cat("\nComputing distances to GPE stations...\n")
stations <- fread(file.path(DATA_DIR, "gpe_stations.csv"))

# Convert to sf for distance computation
dvf_sf <- st_as_sf(dvf, coords = c("longitude", "latitude"), crs = 4326)
stations_sf <- st_as_sf(stations, coords = c("lon", "lat"), crs = 4326)

# Project to Lambert-93 (EPSG:2154) for metric distances
dvf_proj <- st_transform(dvf_sf, 2154)
stations_proj <- st_transform(stations_sf, 2154)

# Compute distance to nearest GPE station
cat("  Computing nearest-station distances (this may take a moment)...\n")
dist_matrix <- st_distance(dvf_proj, stations_proj)

# Find nearest station and distance
dvf[, nearest_station_idx := apply(dist_matrix, 1, which.min)]
dvf[, dist_nearest_m := apply(dist_matrix, 1, min)]
dvf[, dist_nearest_km := as.numeric(dist_nearest_m) / 1000]

# Map station info
dvf[, nearest_station := stations$station_name[nearest_station_idx]]
dvf[, nearest_line := stations$line[nearest_station_idx]]

cat(sprintf("  Distance stats: median = %.1f km, mean = %.1f km\n",
            median(dvf$dist_nearest_km), mean(dvf$dist_nearest_km)))

# ──────────────────────────────────────────────────────────────────
# 4. DEFINE TREATMENT RINGS
# ──────────────────────────────────────────────────────────────────

cat("\nDefining treatment rings...\n")

# Treatment rings
dvf[, ring_500m := dist_nearest_km <= 0.5]
dvf[, ring_1km := dist_nearest_km <= 1.0]
dvf[, ring_1500m := dist_nearest_km <= 1.5]
dvf[, control := dist_nearest_km > 2.0]

# Buffer zone (1.5-2.0 km) excluded from analysis
dvf[, in_buffer := dist_nearest_km > 1.5 & dist_nearest_km <= 2.0]

cat(sprintf("  Within 500m: %s (%0.1f%%)\n",
            format(sum(dvf$ring_500m), big.mark = ","), 100 * mean(dvf$ring_500m)))
cat(sprintf("  Within 1km: %s (%0.1f%%)\n",
            format(sum(dvf$ring_1km), big.mark = ","), 100 * mean(dvf$ring_1km)))
cat(sprintf("  Within 1.5km: %s (%0.1f%%)\n",
            format(sum(dvf$ring_1500m), big.mark = ","), 100 * mean(dvf$ring_1500m)))
cat(sprintf("  Control (>2km): %s (%0.1f%%)\n",
            format(sum(dvf$control), big.mark = ","), 100 * mean(dvf$control)))

# ──────────────────────────────────────────────────────────────────
# 5. ASSIGN TREATMENT TIMING
# ──────────────────────────────────────────────────────────────────

cat("\nAssigning treatment timing from milestones...\n")
milestones <- fread(file.path(DATA_DIR, "gpe_milestones.csv"))

# Stations from API use simple line codes (L14, L15, L16, L17, L18)
# and compound codes like "L14/L15/L16/L17", "L15/L14".
# Milestones use segment codes (L14S, L14N, L15S, L15O, L15E, L16, L17, L18).
# Strategy: map each station to its primary line, then use
# the EARLIEST construction start for that line family.

# Build a lookup: for each base line (L14, L15, L16, L17, L18),
# take the earliest construction_start across segments
line_family <- milestones[, .(
  dup_date = min(as.Date(dup_date)),
  construction_start = min(as.Date(construction_start)),
  opening_date = min(as.Date(opening_date))
), by = .(base_line = substr(line, 1, 3))]

cat("Line family milestones:\n")
print(line_family)

# Extract the primary line from station line codes
# "L14/L15/L16/L17" -> "L14" (take first)
stations[, primary_line := sub("/.*", "", line)]
# Some have prefix like "L14" -> base is "L14"
stations[, base_line := substr(primary_line, 1, 3)]

# Merge milestones to stations
station_milestones <- merge(stations[, .(station_name, base_line)],
                            line_family, by = "base_line", all.x = TRUE)

cat(sprintf("Stations with milestones: %d/%d\n",
            sum(!is.na(station_milestones$construction_start)), nrow(station_milestones)))

# Merge milestone dates to transactions via nearest station
dvf <- merge(dvf, station_milestones[, .(station_name, dup_date, construction_start, opening_date)],
             by.x = "nearest_station", by.y = "station_name", all.x = TRUE)

# Define treatment status at each milestone
dvf[, post_dup := date >= as.Date(dup_date)]
dvf[, post_construction := date >= as.Date(construction_start)]
dvf[, post_opening := date >= as.Date(opening_date)]

# Treatment indicators (only for properties within 1km ring)
dvf[, treated_dup := ring_1km & post_dup]
dvf[, treated_construction := ring_1km & post_construction]
dvf[, treated_opening := ring_1km & post_opening]

# Event time relative to construction start (main specification)
dvf[, event_quarter := as.integer(difftime(date, as.Date(construction_start), units = "days")) %/% 91]

# Treatment cohort (year-quarter of construction start)
dvf[, cohort_yq := paste0(year(as.Date(construction_start)), "Q", quarter(as.Date(construction_start)))]

cat("Treatment status summary:\n")
cat(sprintf("  Post-DUP within 1km: %s\n", format(sum(dvf$treated_dup, na.rm = TRUE), big.mark = ",")))
cat(sprintf("  Post-construction within 1km: %s\n", format(sum(dvf$treated_construction, na.rm = TRUE), big.mark = ",")))
cat(sprintf("  Post-opening within 1km: %s\n", format(sum(dvf$treated_opening, na.rm = TRUE), big.mark = ",")))

# ──────────────────────────────────────────────────────────────────
# 6. CONSTRUCT ANALYSIS PANEL
# ──────────────────────────────────────────────────────────────────

cat("\nConstructing analysis panel...\n")

# Exclude buffer zone for main analysis
panel <- dvf[in_buffer == FALSE]

# Create time period variable (year-quarter)
panel[, yq := as.integer(factor(year_quarter, levels = sort(unique(year_quarter))))]
panel[, year_num := year(date)]

# Commune fixed effects
panel[, commune_fe := as.integer(factor(commune))]

# Summary statistics
cat("\nFinal analysis panel:\n")
cat(sprintf("  Observations: %s\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("  Communes: %d\n", uniqueN(panel$commune)))
cat(sprintf("  Year range: %d-%d\n", min(panel$year_num), max(panel$year_num)))
cat(sprintf("  Apartments: %s (%0.1f%%)\n",
            format(sum(panel$prop_type == "apartment"), big.mark = ","),
            100 * mean(panel$prop_type == "apartment")))
cat(sprintf("  Mean price/m2: EUR %s\n", format(round(mean(panel$price_m2)), big.mark = ",")))
cat(sprintf("  Median price/m2: EUR %s\n", format(round(median(panel$price_m2)), big.mark = ",")))

# Save analysis panel
fwrite(panel, file.path(DATA_DIR, "analysis_panel.csv"))
cat(sprintf("\nSaved analysis panel: %s rows\n", format(nrow(panel), big.mark = ",")))

# Save summary for reference
summary_stats <- panel[, .(
  n_transactions = .N,
  n_communes = uniqueN(commune),
  mean_price_m2 = mean(price_m2),
  median_price_m2 = median(price_m2),
  sd_price_m2 = sd(price_m2),
  pct_apartment = mean(prop_type == "apartment"),
  mean_surface = mean(surface),
  mean_rooms = mean(rooms, na.rm = TRUE),
  min_year = min(year_num),
  max_year = max(year_num)
), by = .(ring = fifelse(ring_1km, "Treatment (<=1km)", "Control (>2km)"))]

fwrite(summary_stats, file.path(DATA_DIR, "summary_stats_by_ring.csv"))
cat("\nSummary by ring:\n")
print(summary_stats)

cat("\n=== DATA CLEANING COMPLETE ===\n")
