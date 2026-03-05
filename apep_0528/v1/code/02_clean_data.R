## 02_clean_data.R — Build spatial panel with border distances
## APEP-0528: Do Administrative Borders Tax Electricity?

source("00_packages.R")

data_dir <- "../data"

# ===========================================================================
# 1. Load data
# ===========================================================================
cat("=== Loading data ===\n")

elcom <- fread(file.path(data_dir, "elcom_tariffs.csv"))
reform_dates <- fread(file.path(data_dir, "reform_dates.csv"))
municipalities <- st_read(file.path(data_dir, "municipalities.gpkg"), quiet = TRUE)

cat("  ElCom:", nrow(elcom), "rows\n")
cat("  Municipalities:", nrow(municipalities), "polygons\n")

# ===========================================================================
# 2. Extract canton from municipality spatial data
# ===========================================================================
cat("=== Extracting canton assignments ===\n")

# Identify canton column (varies by data source)
mun_names <- names(municipalities)
cat("  Municipality columns:", paste(mun_names, collapse = ", "), "\n")

# Try common column names for BFS number and canton
# Use specific patterns to avoid false matches (e.g., uuid matching 'id')
bfs_col <- mun_names[grepl("^(bfs_nr|bfs_nummer|gde_nr|GDE_NR|GMDNR|BFS_NUMMER)$", mun_names, ignore.case = TRUE)]
canton_col <- mun_names[grepl("^(kantonsnummer|kanton_nr|KTNR|KT_NR|canton_id)$", mun_names, ignore.case = TRUE)]
name_col <- mun_names[grepl("^(gemname|name|GDE_NAME|GMDNAME)$", mun_names, ignore.case = TRUE)]

cat("  BFS ID column:", paste(bfs_col, collapse = "/"), "\n")
cat("  Canton column:", paste(canton_col, collapse = "/"), "\n")
cat("  Name column:", paste(name_col, collapse = "/"), "\n")

# Compute centroids
municipalities_proj <- st_transform(municipalities, 2056)  # Swiss LV95
centroids <- st_centroid(municipalities_proj)
coords <- st_coordinates(centroids)
municipalities_proj$x <- coords[, 1]
municipalities_proj$y <- coords[, 2]

# Extract municipality data with canton info
mun_data <- st_drop_geometry(municipalities_proj)

# Build a standardized municipality table
# We need: mun_id, canton, x, y
# Try to create it adaptively

if (length(bfs_col) > 0 && length(canton_col) > 0) {
  mun_dt <- data.table(
    mun_id = as.integer(mun_data[[bfs_col[1]]]),
    canton_nr = as.integer(mun_data[[canton_col[1]]]),
    x = mun_data$x,
    y = mun_data$y
  )
  if (length(name_col) > 0) mun_dt$mun_name <- mun_data[[name_col[1]]]
} else {
  cat("  WARNING: Could not auto-detect columns. Listing first 5 rows:\n")
  print(head(mun_data, 5))
  # Attempt with first numeric-looking columns
  mun_dt <- data.table(
    mun_id = seq_len(nrow(mun_data)),
    canton_nr = NA_integer_,
    x = mun_data$x,
    y = mun_data$y
  )
}

# Map canton numbers to abbreviations
canton_map <- data.table(
  canton_nr = 1:26,
  canton = c("ZH","BE","LU","UR","SZ","OW","NW","GL","ZG","FR",
             "SO","BS","BL","SH","AR","AI","SG","GR","AG","TG",
             "TI","VD","VS","NE","GE","JU")
)
mun_dt <- merge(mun_dt, canton_map, by = "canton_nr", all.x = TRUE)

cat("  Municipality data:", nrow(mun_dt), "rows\n")
cat("  Cantons found:", uniqueN(mun_dt$canton[!is.na(mun_dt$canton)]), "\n")

# ===========================================================================
# 3. Compute distance to cantonal borders
# ===========================================================================
cat("=== Computing distances to cantonal borders ===\n")

# Extract cantonal boundaries from municipal polygons
# Group by canton and dissolve
if (any(!is.na(mun_dt$canton_nr))) {
  # Remove non-municipality polygons (lakes, enclaves without canton)
  mun_dt <- mun_dt[!is.na(canton_nr) & !is.na(mun_id)]
  cat("  After removing NA cantons:", nrow(mun_dt), "municipalities\n")

  municipalities_proj$canton_nr <- as.integer(mun_data[[canton_col[1]]])
  mun_polys <- municipalities_proj[!is.na(municipalities_proj$canton_nr), ]

  # Dissolve to cantonal boundaries
  geom_col_name <- attr(mun_polys, "sf_column")
  cantonal_boundaries <- mun_polys %>%
    group_by(canton_nr) %>%
    summarise(do_union = TRUE) %>%
    ungroup()

  # Extract border lines (shared boundaries between cantons)
  canton_borders <- st_cast(st_boundary(cantonal_boundaries), "MULTILINESTRING")

  # For each municipality centroid, compute distance to nearest cantonal border
  mun_points <- st_as_sf(mun_dt[!is.na(x)], coords = c("x", "y"), crs = 2056)
  dist_matrix <- st_distance(mun_points, canton_borders)

  # Minimum distance to any cantonal border
  mun_dt[!is.na(x), dist_to_border := apply(dist_matrix, 1, min)]
  mun_dt[, dist_to_border_km := dist_to_border / 1000]

  cat("  Distance statistics (km):\n")
  cat("    Mean:", round(mean(mun_dt$dist_to_border_km, na.rm = TRUE), 1), "\n")
  cat("    Median:", round(median(mun_dt$dist_to_border_km, na.rm = TRUE), 1), "\n")
  cat("    Within 10km:", sum(mun_dt$dist_to_border_km <= 10, na.rm = TRUE), "\n")
  cat("    Within 15km:", sum(mun_dt$dist_to_border_km <= 15, na.rm = TRUE), "\n")
  cat("    Within 20km:", sum(mun_dt$dist_to_border_km <= 20, na.rm = TRUE), "\n")
}

# ===========================================================================
# 4. Identify border pairs and nearest canton
# ===========================================================================
cat("=== Identifying border pairs ===\n")

# For each municipality, find the nearest different-canton municipality
# This determines which border pair each municipality belongs to
if (any(!is.na(mun_dt$canton_nr))) {
  # For each municipality, find nearest canton that's different
  mun_sf <- st_as_sf(mun_dt[!is.na(x)], coords = c("x", "y"), crs = 2056)

  # Vectorized: compute full distance matrix between all municipality centroids
  cat("  Computing pairwise distances (this may take a moment)...\n")
  full_dist <- st_distance(mun_sf, mun_sf)

  # For each municipality, find nearest with different canton
  nearest_other_canton <- character(nrow(mun_sf))
  for (i in seq_len(nrow(mun_sf))) {
    own_canton <- mun_sf$canton_nr[i]
    other_idx <- which(mun_sf$canton_nr != own_canton)
    if (length(other_idx) == 0) {
      nearest_other_canton[i] <- NA
    } else {
      nearest <- other_idx[which.min(full_dist[i, other_idx])]
      nearest_other_canton[i] <- mun_sf$canton[nearest]
    }
  }
  cat("  Nearest-canton assignment complete.\n")

  mun_dt[!is.na(x), nearest_other_canton := nearest_other_canton]

  # Create border pair identifier (alphabetically ordered)
  mun_dt[, border_pair := fifelse(
    !is.na(canton) & !is.na(nearest_other_canton),
    paste(pmin(canton, nearest_other_canton), pmax(canton, nearest_other_canton), sep = "_"),
    NA_character_
  )]

  cat("  Unique border pairs:", uniqueN(mun_dt$border_pair[!is.na(mun_dt$border_pair)]), "\n")
  cat("  Top border pairs by municipality count:\n")
  bp_counts <- mun_dt[!is.na(border_pair), .N, by = border_pair][order(-N)]
  print(head(bp_counts, 15))
}

# ===========================================================================
# 5. Merge ElCom tariffs with spatial data
# ===========================================================================
cat("=== Merging ElCom tariffs with spatial data ===\n")

# Merge on municipality ID
panel <- merge(elcom, mun_dt, by = "mun_id", all.x = TRUE)

# Add reform treatment indicator
panel <- merge(panel, reform_dates[, .(canton, reform_year)],
               by = "canton", all.x = TRUE)
panel[, reformed := !is.na(reform_year)]
panel[, post_reform := fifelse(reformed & year >= reform_year, 1L, 0L)]
panel[, event_time := fifelse(reformed, year - reform_year, NA_integer_)]

# For the spatial DiD: treated = in a reform canton AND post-reform year
panel[, treated := post_reform == 1L]

cat("  Panel rows:", nrow(panel), "\n")
cat("  Municipalities matched:", uniqueN(panel$mun_id[!is.na(panel$canton)]), "\n")
cat("  Unmatched:", sum(is.na(panel$canton)), "rows\n")
cat("  Reform canton obs:", sum(panel$reformed, na.rm = TRUE), "\n")
cat("  Post-reform obs:", sum(panel$treated, na.rm = TRUE), "\n")

# ===========================================================================
# 6. Create analysis sample (municipalities within bandwidth of border)
# ===========================================================================
cat("=== Creating analysis samples ===\n")

for (bw in c(10, 15, 20)) {
  n_mun <- uniqueN(panel[dist_to_border_km <= bw & !is.na(dist_to_border_km)]$mun_id)
  n_obs <- nrow(panel[dist_to_border_km <= bw & !is.na(dist_to_border_km)])
  cat(sprintf("  Within %dkm: %d municipalities, %d observations\n", bw, n_mun, n_obs))
}

# Save full panel
fwrite(panel, file.path(data_dir, "panel.csv"))
cat("\n  Saved panel to data/panel.csv\n")

# Save spatial municipality data
fwrite(mun_dt, file.path(data_dir, "municipality_spatial.csv"))
cat("  Saved municipality spatial data to data/municipality_spatial.csv\n")

cat("\nData cleaning complete.\n")
