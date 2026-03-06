# ==============================================================================
# 02_clean_data.R — Construct analysis variables and treatment assignment
# Paper: When the Train Doesn't Come (apep_0542)
# ==============================================================================

source("code/00_packages.R")

# Load data
lr <- fread(file.path(DATA_DIR, "lr_raw_geocoded.csv"))
stations <- fread(file.path(DATA_DIR, "hs2_stations.csv"))
cat("Loaded:", nrow(lr), "transactions\n")

# Drop non-geocoded
lr <- lr[!is.na(lat) & !is.na(lng)]
cat("After geocode filter:", nrow(lr), "transactions\n")

# ------------------------------------------------------------------------------
# 1) Compute distance to nearest station in each phase
# ------------------------------------------------------------------------------

# Phase 2 cancelled stations
p2 <- stations[phase == "Phase2_cancelled"]
# Phase 1 continuing stations
p1 <- stations[phase == "Phase1_continuing"]

# Compute minimum distance to Phase 2 and Phase 1 stations (km)
cat("Computing distances to HS2 stations...\n")

# Use matrix operations for efficiency
lr_coords <- as.matrix(lr[, .(lng, lat)])

# Distance to nearest Phase 2 cancelled station
p2_coords <- as.matrix(p2[, .(lng, lat)])
dist_p2 <- apply(p2_coords, 1, function(s) {
  distHaversine(lr_coords, matrix(s, nrow = nrow(lr_coords), ncol = 2, byrow = TRUE)) / 1000
})
lr[, dist_phase2_km := apply(dist_p2, 1, min)]
lr[, nearest_phase2 := p2$station[apply(dist_p2, 1, which.min)]]

# Distance to nearest Phase 1 continuing station
p1_coords <- as.matrix(p1[, .(lng, lat)])
dist_p1 <- apply(p1_coords, 1, function(s) {
  distHaversine(lr_coords, matrix(s, nrow = nrow(lr_coords), ncol = 2, byrow = TRUE)) / 1000
})
lr[, dist_phase1_km := apply(dist_p1, 1, min)]
lr[, nearest_phase1 := p1$station[apply(dist_p1, 1, which.min)]]

cat("Distance computation complete.\n")
cat("Median distance to Phase 2:", round(median(lr$dist_phase2_km), 1), "km\n")
cat("Median distance to Phase 1:", round(median(lr$dist_phase1_km), 1), "km\n")

# ------------------------------------------------------------------------------
# 2) Treatment assignment
# ------------------------------------------------------------------------------

# Treatment groups based on distance rings
lr[, near_station_2km := as.integer(dist_phase2_km <= 2)]
lr[, near_station_5km := as.integer(dist_phase2_km <= 5)]
lr[, near_station_10km := as.integer(dist_phase2_km <= 10)]

# Phase 1 control group (within-project control)
lr[, near_phase1_5km := as.integer(dist_phase1_km <= 5)]
lr[, near_phase1_10km := as.integer(dist_phase1_km <= 10)]

# Post-announcement indicator (October 4, 2023)
announcement_date <- as.Date("2023-10-04")
lr[, post := as.integer(date >= announcement_date)]

# Year-quarter numeric for event study
lr[, yq := year(date) + (quarter(date) - 1) / 4]
lr[, yq_factor := factor(year_quarter)]

# Event time (quarters relative to Q4 2023 = 0)
lr[, event_quarter := 4 * (year(date) - 2023) + quarter(date) - 4]

# Log price
lr[, log_price := log(price)]

# Property type factor
lr[, prop_type := factor(property_type,
                          levels = c("D", "S", "T", "F", "O"),
                          labels = c("Detached", "Semi", "Terraced", "Flat", "Other"))]

# Tenure factor
lr[, tenure_f := factor(tenure, levels = c("F", "L"), labels = c("Freehold", "Leasehold"))]

# New build indicator
lr[, new_build := as.integer(old_new == "N")]

# ------------------------------------------------------------------------------
# 3) Sample restrictions
# ------------------------------------------------------------------------------

# Drop prices below 10K or above 10M (likely errors/commercial)
lr <- lr[price >= 10000 & price <= 10000000]

# Focus on standard PPD category (A = standard, B = additional price)
lr <- lr[ppd_cat == "A"]

# Drop incomplete postcodes
lr <- lr[nchar(postcode_clean) >= 5]

# Keep 2019-2024 (sufficient pre/post window)
lr <- lr[year >= 2019 & year <= 2024]

cat("After restrictions:", nrow(lr), "transactions\n")

# ------------------------------------------------------------------------------
# 4) Define analysis samples
# ------------------------------------------------------------------------------

# Main sample: Properties within 50km of any cancelled Phase 2 station
# (includes treated, near-control, and far-control)
main_sample <- lr[dist_phase2_km <= 50 | dist_phase1_km <= 50]
cat("Main sample (within 50km of any HS2 station):", nrow(main_sample), "\n")

# Treatment and control counts
cat("\n--- Treatment Assignment ---\n")
cat("Within 2km of Phase 2 station:", sum(main_sample$near_station_2km), "\n")
cat("Within 5km of Phase 2 station:", sum(main_sample$near_station_5km), "\n")
cat("Within 10km of Phase 2 station:", sum(main_sample$near_station_10km), "\n")
cat("Within 5km of Phase 1 station:", sum(main_sample$near_phase1_5km), "\n")
cat("Within 10km of Phase 1 station:", sum(main_sample$near_phase1_10km), "\n")

# Summary stats by treatment
cat("\n--- Price Summary by Treatment ---\n")
main_sample[, .(
  n = .N,
  mean_price = round(mean(price)),
  median_price = round(median(price)),
  mean_log_price = round(mean(log_price), 3)
), by = .(near_station_5km, post)][order(near_station_5km, post)] |> print()

# Save analysis datasets
fwrite(main_sample, file.path(DATA_DIR, "analysis_main.csv"))
fwrite(lr, file.path(DATA_DIR, "lr_clean.csv"))
cat("\nSaved analysis_main.csv:", nrow(main_sample), "rows\n")
cat("Saved lr_clean.csv:", nrow(lr), "rows\n")

# Save summary statistics for tables
sumstats <- main_sample[, .(
  n_transactions = as.double(.N),
  mean_price = mean(price),
  sd_price = sd(price),
  median_price = as.double(median(price)),
  mean_log_price = mean(log_price),
  sd_log_price = sd(log_price),
  pct_detached = mean(prop_type == "Detached"),
  pct_semi = mean(prop_type == "Semi"),
  pct_terraced = mean(prop_type == "Terraced"),
  pct_flat = mean(prop_type == "Flat"),
  pct_freehold = mean(tenure_f == "Freehold"),
  pct_new_build = mean(new_build)
), by = .(Treatment = fifelse(near_station_5km == 1, "Within 5km Phase 2",
                               fifelse(near_phase1_5km == 1, "Within 5km Phase 1",
                                       "Control (>5km)")))]
fwrite(sumstats, file.path(DATA_DIR, "summary_statistics.csv"))
cat("Saved summary_statistics.csv\n")
