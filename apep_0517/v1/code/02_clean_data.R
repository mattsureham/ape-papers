#' 02_clean_data.R — Build analysis panel
#' Constructs the LSOA x year panel with boundary distance,
#' PFA assignment, workforce data, and crime counts.

source("00_packages.R")

DATA_DIR <- "../data"

# ===================================================================
# 1. Load all data
# ===================================================================
cat("=== Loading data ===\n")

crime <- fread(file.path(DATA_DIR, "crime_lsoa_month.csv"))
lsoa_dist <- fread(file.path(DATA_DIR, "lsoa_boundary_distance.csv"))
boundary_pairs <- fread(file.path(DATA_DIR, "boundary_pairs.csv"))
workforce <- fread(file.path(DATA_DIR, "police_workforce.csv"))

# IMD (optional)
imd_file <- file.path(DATA_DIR, "imd_2019_lsoa.csv")
has_imd <- file.exists(imd_file)
if (has_imd) {
  imd <- fread(imd_file)
  cat("  IMD loaded:", nrow(imd), "LSOAs\n")
}

cat("  Crime:", nrow(crime), "rows\n")
cat("  LSOA distances:", nrow(lsoa_dist), "LSOAs\n")
cat("  Boundary pairs:", nrow(boundary_pairs), "\n")
cat("  Workforce:", nrow(workforce), "rows\n")

# ===================================================================
# 2. Aggregate crime to LSOA x year
# ===================================================================
cat("\n=== Aggregating crime to LSOA x year ===\n")

crime[, year := as.integer(substr(month, 1, 4))]

# Total crime per LSOA-year
crime_total <- crime[, .(total_crime = sum(count)), by = .(lsoa_code, year)]

# Crime by category per LSOA-year
crime_cats <- crime[, .(count = sum(count)), by = .(lsoa_code, year, crime_type)]
crime_wide <- dcast(crime_cats, lsoa_code + year ~ crime_type, value.var = "count",
                    fill = 0)

# Clean column names
old_names <- names(crime_wide)[-(1:2)]
new_names <- gsub("[^a-zA-Z0-9]", "_", tolower(old_names))
new_names <- gsub("_+", "_", new_names)
new_names <- gsub("_$", "", new_names)
setnames(crime_wide, old_names, new_names)

# Merge total crime
crime_panel <- merge(crime_wide, crime_total, by = c("lsoa_code", "year"))

cat("  Crime panel:", nrow(crime_panel), "LSOA-years\n")
cat("  Years:", paste(sort(unique(crime_panel$year)), collapse = ", "), "\n")
cat("  Crime categories:", paste(new_names, collapse = ", "), "\n")

# ===================================================================
# 3. Merge with spatial data
# ===================================================================
cat("\n=== Merging spatial data ===\n")

# Standardize force names in workforce to match crime data
workforce_names <- unique(workforce$force)
lsoa_force <- fread(file.path(DATA_DIR, "lsoa_force_mapping.csv"))

panel <- merge(crime_panel, lsoa_dist[, .(lsoa_code, dist_to_boundary_m,
                                           pfa_name, pfa_code, lat, lng)],
               by = "lsoa_code", all.x = TRUE)

# Drop LSOAs without PFA assignment or distance
panel <- panel[!is.na(dist_to_boundary_m) & !is.na(pfa_name)]

cat("  Panel after spatial merge:", nrow(panel), "LSOA-years\n")
cat("  PFAs represented:", uniqueN(panel$pfa_name), "\n")

# ===================================================================
# 4. Identify nearest boundary and assign to boundary pair
# ===================================================================
cat("\n=== Assigning boundary pairs ===\n")

# For each LSOA, find which boundary pair it's closest to
# This requires checking which adjacent PFA the LSOA is closest to

# Load PFA boundaries for neighbor check
pfa <- st_read(file.path(DATA_DIR, "pfa_boundaries.geojson"), quiet = TRUE)
pfa_proj <- st_transform(pfa, 27700)

# For LSOAs within 10km of a boundary, find the nearest neighboring PFA
lsoa_near <- lsoa_dist[dist_to_boundary_m <= 10000 & !is.na(pfa_name)]

if (nrow(lsoa_near) > 0) {
  # Create sf from LSOA centroids
  lsoa_near_sf <- st_as_sf(lsoa_near, coords = c("lng", "lat"), crs = 4326) %>%
    st_transform(27700)

  # Vectorized approach: for each unique PFA, find nearest neighbor PFA
  # Process per-PFA group (vectorized st_nearest_feature within group)
  lsoa_near$nearest_neighbor_pfa <- NA_character_
  unique_pfas <- unique(lsoa_near$pfa_name)

  for (own_pfa in unique_pfas) {
    idx <- which(lsoa_near$pfa_name == own_pfa)
    other_pfas <- pfa_proj[pfa_proj$PFA23NM != own_pfa, ]
    if (nrow(other_pfas) > 0) {
      nearest_idx <- st_nearest_feature(lsoa_near_sf[idx, ], other_pfas)
      lsoa_near$nearest_neighbor_pfa[idx] <- other_pfas$PFA23NM[nearest_idx]
    }
    cat("  Processed PFA:", own_pfa, "(", length(idx), "LSOAs)\n")
  }

  # Create boundary pair ID
  lsoa_near[, boundary_pair := paste(
    pmin(pfa_name, nearest_neighbor_pfa),
    pmax(pfa_name, nearest_neighbor_pfa),
    sep = " | "
  )]

  fwrite(lsoa_near[, .(lsoa_code, nearest_neighbor_pfa, boundary_pair)],
         file.path(DATA_DIR, "lsoa_boundary_pair.csv"))
}

# Merge boundary pair into panel
bp_lookup <- fread(file.path(DATA_DIR, "lsoa_boundary_pair.csv"))
panel <- merge(panel, bp_lookup, by = "lsoa_code", all.x = TRUE)

cat("  LSOAs with boundary pair:", sum(!is.na(panel$boundary_pair)), "\n")
cat("  Unique boundary pairs:", uniqueN(panel$boundary_pair[!is.na(panel$boundary_pair)]), "\n")

# ===================================================================
# 5. Merge workforce data
# ===================================================================
cat("\n=== Merging workforce data ===\n")

# Standardize force names for matching
panel[, force_key := tolower(gsub(" ", "-", pfa_name))]
workforce[, force_key := tolower(gsub(" ", "-", force))]

# Try direct merge
panel <- merge(panel, workforce[, .(force_key, year, officers)],
               by = c("force_key", "year"), all.x = TRUE)

cat("  Officers matched:", sum(!is.na(panel$officers)), "/", nrow(panel), "\n")

# ===================================================================
# 6. Merge IMD data
# ===================================================================
if (has_imd) {
  cat("\n=== Merging IMD data ===\n")
  # IMD uses 2011 LSOA codes, crime data uses 2021 codes
  # Most codes are the same but some have changed
  panel <- merge(panel, imd[, .(lsoa_code, imd_rank, imd_decile)],
                 by = "lsoa_code", all.x = TRUE)
  cat("  IMD matched:", sum(!is.na(panel$imd_rank)), "/", nrow(panel), "\n")
}

# ===================================================================
# 7. Create analysis variables
# ===================================================================
cat("\n=== Creating analysis variables ===\n")

# Distance in km (easier to interpret)
panel[, dist_km := dist_to_boundary_m / 1000]

# Log crime (add 1 for zeros)
panel[, log_total_crime := log(total_crime + 1)]

# Near boundary indicator
panel[, near_boundary := dist_km <= 5]

# Period indicators
panel[, period := fcase(
  year <= 2012, "pre_austerity",
  year %between% c(2013, 2018), "austerity",
  year %between% c(2019, 2021), "uplift_covid",
  year >= 2022, "post_covid"
)]

# Crime rate categories (if columns exist)
crime_type_cols <- intersect(
  c("anti_social_behaviour", "violent_crime", "violence_and_sexual_offences",
    "burglary", "robbery", "vehicle_crime", "criminal_damage_and_arson",
    "drugs", "other_theft", "shoplifting", "public_order",
    "theft_from_the_person", "bicycle_theft", "possession_of_weapons",
    "other_crime"),
  names(panel)
)

for (col in crime_type_cols) {
  panel[, paste0("log_", col) := log(get(col) + 1)]
}

cat("  Panel dimensions:", nrow(panel), "x", ncol(panel), "\n")
cat("  Years:", paste(sort(unique(panel$year)), collapse = ", "), "\n")
cat("  LSOAs:", uniqueN(panel$lsoa_code), "\n")
cat("  PFAs:", uniqueN(panel$pfa_name), "\n")

# ===================================================================
# 8. Save analysis panel
# ===================================================================
fwrite(panel, file.path(DATA_DIR, "analysis_panel.csv"))
cat("\n=== Analysis panel saved ===\n")
cat("  File:", file.path(DATA_DIR, "analysis_panel.csv"), "\n")
cat("  Rows:", nrow(panel), "\n")
cat("  Near-boundary LSOA-years:", sum(panel$near_boundary, na.rm = TRUE), "\n")
