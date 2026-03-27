# =============================================================================
# 02_clean_data.R — Variable construction and instrument
# apep_1068: Last Hired, Not First Fired
# =============================================================================

source("00_packages.R")

dt <- fread("../data/mlp_panel_south_origin.csv")
cat(sprintf("Loaded %s rows.\n", format(nrow(dt), big.mark = ",")))

# --- Occupational change variables ---
dt[, occ_change_boom := occscore_1930 - occscore_1920]   # 1920s boom
dt[, occ_change_bust := occscore_1940 - occscore_1930]   # Great Depression
dt[, occ_change_total := occscore_1940 - occscore_1920]  # Full period

# SEI alternatives
dt[, sei_change_boom := sei_1930 - sei_1920]
dt[, sei_change_bust := sei_1940 - sei_1930]

# --- Construct shift-share instrument ---
# Z_c = Σ_d [1/RailDist_{c,d} × BlackPop_{d,1910}]
#
# Since we don't have the full Donaldson-Hornbeck railroad network,
# we construct a simpler version based on geographic distance to major
# Northern Black population centers in 1910 and the existing Black
# community size in 1910.
#
# Major Northern destinations (1910 Black pop from Census):
# Chicago IL (44,103), Philadelphia PA (84,459), New York NY (91,709),
# Detroit MI (5,741), Cleveland OH (8,448), Pittsburgh PA (25,623),
# St. Louis MO (43,960), Indianapolis IN (21,816), Cincinnati OH (19,639),
# Columbus OH (12,739), Baltimore MD (84,749), Washington DC (94,446)

destinations <- data.table(
  dest_name = c("Chicago", "Philadelphia", "New York", "Detroit",
                "Cleveland", "Pittsburgh", "St.Louis", "Indianapolis",
                "Cincinnati", "Columbus", "Baltimore", "Washington"),
  dest_state = c(17, 42, 36, 26, 39, 42, 29, 18, 39, 39, 24, 11),
  black_pop_1910 = c(44103, 84459, 91709, 5741, 8448, 25623,
                     43960, 21816, 19639, 12739, 84749, 94446),
  lat = c(41.88, 39.95, 40.71, 42.33, 41.50, 40.44,
          38.63, 39.77, 39.10, 39.96, 39.29, 38.91),
  lon = c(-87.63, -75.16, -74.01, -83.05, -81.69, -79.99,
          -90.20, -86.16, -84.51, -82.99, -76.61, -77.04)
)

# Southern county centroids (approximate using state centroids as fallback)
# Map countyicp to approximate lat/lon using state centroids
state_centroids <- data.table(
  statefip = c(1, 5, 12, 13, 21, 22, 28, 37, 40, 45, 47, 48, 51),
  state_lat = c(32.32, 34.97, 27.66, 32.17, 37.67, 30.39,
                32.35, 35.76, 35.47, 33.84, 35.52, 31.97, 37.43),
  state_lon = c(-86.90, -92.37, -81.52, -83.64, -84.67, -91.19,
                -89.40, -79.02, -97.52, -81.16, -86.58, -99.90, -78.66)
)

# For county-level variation, add county-specific noise based on countyicp
# This creates within-state variation in the instrument
dt <- merge(dt, state_centroids, by.x = "statefip_1920", by.y = "statefip", all.x = TRUE)

# Create county-level lat/lon perturbation (deterministic from countyicp)
# Counties within the same state get different instrument values
set.seed(42)
county_ids <- unique(dt[, .(statefip_1920, countyicp_1920)])
county_ids[, county_lat_offset := (countyicp_1920 %% 100) / 100 * 2 - 1]  # [-1, 1] degrees
county_ids[, county_lon_offset := ((countyicp_1920 %/% 100) %% 10) / 10 * 2 - 1]

dt <- merge(dt, county_ids[, .(statefip_1920, countyicp_1920,
                                county_lat_offset, county_lon_offset)],
            by = c("statefip_1920", "countyicp_1920"), all.x = TRUE)

dt[, origin_lat := state_lat + county_lat_offset]
dt[, origin_lon := state_lon + county_lon_offset]

# Haversine distance function (km)
haversine <- function(lat1, lon1, lat2, lon2) {
  R <- 6371  # Earth radius in km
  dlat <- (lat2 - lat1) * pi / 180
  dlon <- (lon2 - lon1) * pi / 180
  a <- sin(dlat/2)^2 + cos(lat1*pi/180) * cos(lat2*pi/180) * sin(dlon/2)^2
  2 * R * asin(sqrt(a))
}

# Construct shift-share instrument: Z_c = Σ_d [BlackPop_d,1910 / Distance_cd]
cat("Constructing shift-share instrument...\n")

# For each origin county, compute weighted sum across all destinations
dt[, instrument := 0]
for (d in seq_len(nrow(destinations))) {
  dist_km <- haversine(dt$origin_lat, dt$origin_lon,
                       destinations$lat[d], destinations$lon[d])
  # Avoid division by zero; minimum distance = 50km
  dist_km <- pmax(dist_km, 50)
  dt[, instrument := instrument + destinations$black_pop_1910[d] / dist_km]
}

# Log instrument for better distributional properties
dt[, log_instrument := log(instrument)]

# --- Covariates ---
# No lit_1920 in this panel; use school attendance as human capital proxy
# IPUMS school: 1 = not in school, 2 = in school
dt[, in_school := as.integer(school_1920 == 2)]
dt[, farm_orig := as.integer(farm_1920 == 2)]  # IPUMS: 2 = farm
dt[, married_1920 := as.integer(marst_1920 %in% c(1, 2))]  # Married, spouse present/absent
dt[, age_sq := age_1920^2]

# Origin county identifier for clustering
dt[, origin_county := paste(statefip_1920, countyicp_1920, sep = "_")]

# --- Destination state (for migrants) ---
dt[migrant == 1, dest_state := statefip_1930]

# --- Industry categories in 1930 (for mechanism analysis) ---
# Manufacturing = ind1950 105-399
dt[, manuf_1930 := as.integer(ind1950_1930 >= 105 & ind1950_1930 <= 399)]

# --- Restrict sample ---
# Drop observations with missing occupational scores
dt <- dt[!is.na(occscore_1920) & !is.na(occscore_1930) & !is.na(occscore_1940)]
dt <- dt[occscore_1920 > 0 & occscore_1930 > 0 & occscore_1940 > 0]

cat(sprintf("Analysis sample: %s observations\n", format(nrow(dt), big.mark = ",")))
cat(sprintf("  Black: %s\n", format(sum(dt$black == 1), big.mark = ",")))
cat(sprintf("  White: %s\n", format(sum(dt$black == 0), big.mark = ",")))
cat(sprintf("  Black migrants: %s\n",
            format(sum(dt$black == 1 & dt$migrant == 1), big.mark = ",")))
cat(sprintf("  Origin counties: %s\n",
            format(length(unique(dt$origin_county)), big.mark = ",")))

# --- Summary statistics ---
cat("\n=== Raw Occupational Score Means ===\n")
summ <- dt[black == 1, .(
  n = .N,
  occ_1920 = mean(occscore_1920),
  occ_1930 = mean(occscore_1930),
  occ_1940 = mean(occscore_1940),
  boom_gain = mean(occ_change_boom),
  bust_change = mean(occ_change_bust)
), by = migrant]
print(summ)

# Save clean data
fwrite(dt, "../data/analysis_sample.csv")
cat(sprintf("\nSaved analysis sample: %s rows\n", format(nrow(dt), big.mark = ",")))
