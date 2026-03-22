# 02_clean_data.R — Clean data and compute distances
# apep_0735: ABF Monument Boundary Spatial RDD

source("00_packages.R")

data_dir <- "../data/"

# ============================================================
# 1. Load data
# ============================================================
cat("Loading data...\n")
dvf <- fread(file.path(data_dir, "dvf_combined.csv"))
monuments <- fread(file.path(data_dir, "monuments_geo.csv"))

cat("Raw DVF rows:", nrow(dvf), "\n")
cat("Monuments with coordinates:", nrow(monuments), "\n")

# ============================================================
# 2. Filter DVF to usable transactions
# ============================================================
cat("\nCleaning DVF...\n")

# Keep only sales (Vente) of apartments and houses with valid price/coords
dvf_clean <- dvf[
  nature_mutation == "Vente" &
  type_local %in% c("Appartement", "Maison") &
  !is.na(valeur_fonciere) & valeur_fonciere > 0 &
  !is.na(latitude) & !is.na(longitude) &
  latitude != 0 & longitude != 0 &
  !is.na(surface_reelle_bati) & surface_reelle_bati > 0
]

# Remove extreme outliers
dvf_clean[, price_per_m2 := valeur_fonciere / surface_reelle_bati]
dvf_clean <- dvf_clean[price_per_m2 >= 200 & price_per_m2 <= 30000]
dvf_clean <- dvf_clean[surface_reelle_bati >= 9 & surface_reelle_bati <= 500]
dvf_clean <- dvf_clean[valeur_fonciere >= 10000]

# Remove overseas departments
dvf_clean <- dvf_clean[!code_departement %in% c("971", "972", "973", "974", "976")]

cat("DVF after cleaning:", nrow(dvf_clean), "rows\n")

# ============================================================
# 3. Compute distance to nearest monument
# ============================================================
cat("\nComputing distances to nearest monument...\n")
cat("This may take a few minutes for", nrow(dvf_clean), "transactions x",
    nrow(monuments), "monuments...\n")

# Use spatial indexing: for each transaction, find nearest monument
# Haversine distance function (vectorized for one point to many)
haversine_vec <- function(lon1, lat1, lon2, lat2) {
  R <- 6371000  # Earth radius in meters
  dlat <- (lat2 - lat1) * pi / 180
  dlon <- (lon2 - lon1) * pi / 180
  lat1r <- lat1 * pi / 180
  lat2r <- lat2 * pi / 180
  a <- sin(dlat / 2)^2 + cos(lat1r) * cos(lat2r) * sin(dlon / 2)^2
  2 * R * asin(sqrt(a))
}

# Strategy: Build a spatial grid for fast nearest-neighbor lookup
# Convert monuments to sf for spatial indexing
mon_sf <- st_as_sf(monuments, coords = c("lon", "lat"), crs = 4326)
dvf_sf <- st_as_sf(dvf_clean, coords = c("longitude", "latitude"), crs = 4326)

# Find nearest monument for each transaction
cat("Finding nearest monument for each transaction...\n")

# Process in chunks to manage memory
chunk_size <- 50000
n_chunks <- ceiling(nrow(dvf_sf) / chunk_size)
nearest_indices <- integer(nrow(dvf_sf))
nearest_distances <- numeric(nrow(dvf_sf))

for (i in seq_len(n_chunks)) {
  start_idx <- (i - 1) * chunk_size + 1
  end_idx <- min(i * chunk_size, nrow(dvf_sf))
  chunk <- dvf_sf[start_idx:end_idx, ]

  nn <- st_nearest_feature(chunk, mon_sf)
  dists <- st_distance(chunk, mon_sf[nn, ], by_element = TRUE)

  nearest_indices[start_idx:end_idx] <- nn
  nearest_distances[start_idx:end_idx] <- as.numeric(dists)

  cat("  Chunk", i, "/", n_chunks, "done\n")
}

dvf_clean[, dist_to_monument := nearest_distances]
dvf_clean[, nearest_monument_idx := nearest_indices]
dvf_clean[, monument_type := monuments$type[nearest_indices]]

cat("\nDistance summary (meters):\n")
print(summary(dvf_clean$dist_to_monument))

# ============================================================
# 4. Create analysis sample
# ============================================================
# Focus on properties within 1000m of a monument (bandwidth for analysis)
analysis_sample <- dvf_clean[dist_to_monument <= 1000]

# Create treatment indicator
analysis_sample[, treated := as.integer(dist_to_monument < 500)]

# Create centered distance (running variable)
analysis_sample[, dist_centered := dist_to_monument - 500]

# Log price per m2
analysis_sample[, log_price_m2 := log(price_per_m2)]

# Department code for clustering
analysis_sample[, dept := substr(code_commune, 1, 2)]

cat("\nAnalysis sample (within 1000m):", nrow(analysis_sample), "rows\n")
cat("  Treated (< 500m):", sum(analysis_sample$treated == 1), "\n")
cat("  Control (>= 500m):", sum(analysis_sample$treated == 0), "\n")
cat("  Monument types:", table(analysis_sample$monument_type), "\n")

# Save
fwrite(analysis_sample, file.path(data_dir, "analysis_sample.csv"))
cat("Analysis sample saved.\n")
