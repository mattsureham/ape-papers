## 02_clean_data.R — Construct analysis dataset with signed distance to CAZ boundary
## apep_0649: Clean Air Zone property values

source("00_packages.R")
setDTthreads(4)

DATA_DIR <- "../data"

# ═══════════════════════════════════════════════════════════════
# 1) LOAD DATA
# ═══════════════════════════════════════════════════════════════

lr <- fread(file.path(DATA_DIR, "lr_7cities.csv"))
gc_data <- fread(file.path(DATA_DIR, "postcode_geocodes.csv"))
caz <- st_read(file.path(DATA_DIR, "caz_boundaries.gpkg"), quiet = TRUE)

cat(sprintf("Loaded: %d transactions, %d geocodes, %d CAZ boundaries\n",
            nrow(lr), nrow(gc_data), nrow(caz)))

# ═══════════════════════════════════════════════════════════════
# 2) MERGE GEOCODES WITH TRANSACTIONS
# ═══════════════════════════════════════════════════════════════

lr <- merge(lr, gc_data, by = "postcode", all.x = FALSE)
cat(sprintf("After geocode merge: %d transactions (%.1f%% matched)\n",
            nrow(lr), 100 * nrow(lr) / nrow(fread(file.path(DATA_DIR, "lr_7cities.csv")))))

stopifnot("No geocoded transactions" = nrow(lr) > 0)

# ═══════════════════════════════════════════════════════════════
# 3) COMPUTE SIGNED DISTANCE TO CAZ BOUNDARY
# ═══════════════════════════════════════════════════════════════

# Convert to sf points in British National Grid (meters)
lr_sf <- st_as_sf(lr, coords = c("longitude", "latitude"), crs = 4326)
lr_sf <- st_transform(lr_sf, 27700)
caz_bng <- st_transform(caz, 27700)

# For each city, compute distance to that city's CAZ boundary
# Distance to boundary (not centroid): positive = inside, negative = outside

lr$signed_dist_m <- NA_real_
lr$nearest_city <- NA_character_

for (i in 1:nrow(caz_bng)) {
  city_name <- caz_bng$city[i]
  city_idx <- which(lr$city == city_name)

  if (length(city_idx) == 0) {
    cat(sprintf("  No transactions for %s, skipping\n", city_name))
    next
  }

  cat(sprintf("  Computing distances for %s (%d transactions)...\n", city_name, length(city_idx)))

  pts <- lr_sf[city_idx, ]
  boundary_line <- st_boundary(caz_bng[i, ])

  # Distance to boundary
  dist_to_boundary <- as.numeric(st_distance(pts, boundary_line))

  # Determine inside/outside
  inside <- st_intersects(pts, caz_bng[i, ], sparse = FALSE)[, 1]

  # Signed distance: positive inside, negative outside
  signed <- ifelse(inside, dist_to_boundary, -dist_to_boundary)

  lr$signed_dist_m[city_idx] <- signed
  lr$nearest_city[city_idx] <- city_name
}

cat(sprintf("Distance computed for %d transactions\n", sum(!is.na(lr$signed_dist_m))))

# ═══════════════════════════════════════════════════════════════
# 4) CREATE ANALYSIS VARIABLES
# ═══════════════════════════════════════════════════════════════

# CAZ info for merging
caz_info <- data.table(
  city       = c("Bath", "Birmingham", "Portsmouth", "Bradford", "Bristol", "Tyneside", "Sheffield"),
  launch     = as.Date(c("2021-03-15", "2021-06-01", "2021-11-29", "2022-09-26",
                          "2022-11-28", "2023-01-30", "2023-02-27")),
  class      = c("C", "D", "B", "C", "D", "C", "D"),
  class_num  = c(2, 3, 1, 2, 3, 2, 3)  # B=1, C=2, D=3
)

lr <- merge(lr, caz_info, by = "city", all.x = TRUE)

# Treatment indicators
lr[, `:=`(
  post = as.integer(date >= launch),
  inside = as.integer(signed_dist_m >= 0),
  log_price = log(price),
  year = year(date),
  quarter = quarter(date),
  year_quarter = paste0(year(date), "Q", quarter(date)),
  date_num = as.numeric(date)
)]

# Interaction term
lr[, inside_post := inside * post]

# ═══════════════════════════════════════════════════════════════
# 5) FILTER TO ANALYSIS BANDWIDTH
# ═══════════════════════════════════════════════════════════════

# Keep all transactions within 2000m for robustness; primary analysis uses 500m
MAX_BW <- 2000
lr_analysis <- lr[abs(signed_dist_m) <= MAX_BW & !is.na(signed_dist_m)]

cat(sprintf("\nAnalysis dataset (within %dm): %d transactions\n", MAX_BW, nrow(lr_analysis)))
cat("  By city:\n")
print(lr_analysis[, .N, by = city][order(-N)])
cat("  By inside/outside:\n")
print(lr_analysis[, .N, by = inside])
cat("  By pre/post:\n")
print(lr_analysis[, .N, by = post])
cat("  By property type:\n")
print(lr_analysis[, .N, by = prop_type])

# ═══════════════════════════════════════════════════════════════
# 6) SAVE
# ═══════════════════════════════════════════════════════════════

fwrite(lr_analysis, file.path(DATA_DIR, "analysis_panel.csv"))
cat(sprintf("\nSaved analysis panel: %d observations\n", nrow(lr_analysis)))
cat(sprintf("  Date range: %s to %s\n", min(lr_analysis$date), max(lr_analysis$date)))
cat(sprintf("  Distance range: %.0f to %.0f meters\n",
            min(lr_analysis$signed_dist_m), max(lr_analysis$signed_dist_m)))
