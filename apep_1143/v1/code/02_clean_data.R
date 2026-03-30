## 02_clean_data.R — Match solar facilities to BBS routes, build panel
## apep_1143: Solar Footprint

source("./code/00_packages.R")

DATA_DIR <- "./data"

# ============================================================
# 1. Load and clean USPVDB
# ============================================================
cat("\n=== LOADING USPVDB ===\n")
uspvdb <- fread(file.path(DATA_DIR, "uspvdb_v3_0_20250430.csv"))
cat("Total facilities:", nrow(uspvdb), "\n")

# Key columns: ylat, xlong, p_year, p_cap_ac (MW AC), p_type, p_state
# p_type categories (from codebook): greenfield, brownfield, landfill, superfund, etc.
cat("Columns available:", paste(names(uspvdb), collapse=", "), "\n")

# Check p_type distribution
if ("p_type" %in% names(uspvdb)) {
  cat("\nSite type distribution:\n")
  print(table(uspvdb$p_type, useNA = "always"))
}

# Check for greenfield classification via other columns
# The USPVDB may use different naming
for (col in c("p_type", "p_tech_pri", "p_sys_type")) {
  if (col %in% names(uspvdb)) {
    cat(sprintf("\n%s distribution:\n", col))
    print(table(uspvdb[[col]], useNA = "always"))
  }
}

# Use p_cap_ac (MW capacity) — if missing, try p_cap_dc
if ("p_cap_ac" %in% names(uspvdb)) {
  uspvdb[, mw := as.numeric(p_cap_ac)]
} else if ("p_cap_dc" %in% names(uspvdb)) {
  uspvdb[, mw := as.numeric(p_cap_dc)]
}

cat("\nCapacity summary (MW):\n")
print(summary(uspvdb$mw))

# Year distribution
cat("\nOperational year range:", range(uspvdb$p_year, na.rm=TRUE), "\n")
cat("Facilities by decade:\n")
print(table(floor(uspvdb$p_year/5)*5))

# Clean: keep US facilities with valid coordinates
solar <- uspvdb[!is.na(ylat) & !is.na(xlong) & !is.na(p_year) & !is.na(mw)]
cat("\nClean solar facilities:", nrow(solar), "\n")

# ============================================================
# 2. Load BBS routes
# ============================================================
cat("\n=== LOADING BBS ROUTES ===\n")
routes <- fread(file.path(DATA_DIR, "Routes.csv"))
routes_us <- routes[CountryNum == 840]  # US only
cat("US BBS routes:", nrow(routes_us), "\n")

# Create route ID
routes_us[, route_id := paste0(StateNum, "_", Route)]

# ============================================================
# 3. Compute distances: each BBS route to nearest solar facility
# ============================================================
cat("\n=== COMPUTING DISTANCES ===\n")

# Convert to sf objects for distance computation
routes_sf <- st_as_sf(routes_us, coords = c("Longitude", "Latitude"), crs = 4326)
solar_sf <- st_as_sf(solar, coords = c("xlong", "ylat"), crs = 4326)

# For each route, find all solar facilities within 10, 20 km
# Use st_buffer + st_intersection approach for efficiency
# But with 4,455 routes and 5,700 facilities, pairwise distance is feasible

cat("Computing pairwise distances...\n")
# Convert to projected CRS for distance in meters (US Albers)
routes_proj <- st_transform(routes_sf, 5070)
solar_proj <- st_transform(solar_sf, 5070)

# Compute distance matrix (this might be memory-intensive)
# For 8GB RAM, do it in chunks
n_routes <- nrow(routes_proj)
n_solar <- nrow(solar_proj)
cat("Routes:", n_routes, "Solar:", n_solar, "\n")

# For each route, compute cumulative solar MW within 10km by year
# Use a loop approach to save memory
RADIUS_KM <- 10  # Primary analysis radius
RADIUS_M <- RADIUS_KM * 1000

cat("Finding solar within", RADIUS_KM, "km of each route...\n")

# Extract coordinates for manual distance computation (faster than sf for large N)
route_coords <- st_coordinates(routes_proj)
solar_coords <- st_coordinates(solar_proj)

# Batch: for each route, find solar within radius
route_solar <- list()
for (i in 1:n_routes) {
  dx <- solar_coords[, 1] - route_coords[i, 1]
  dy <- solar_coords[, 2] - route_coords[i, 2]
  dist <- sqrt(dx^2 + dy^2)
  nearby <- which(dist <= RADIUS_M)

  if (length(nearby) > 0) {
    route_solar[[i]] <- data.table(
      route_id = routes_us$route_id[i],
      solar_idx = nearby,
      dist_m = dist[nearby],
      p_year = solar$p_year[nearby],
      mw = solar$mw[nearby],
      p_type = if ("p_type" %in% names(solar)) solar$p_type[nearby] else NA_character_
    )
  }

  if (i %% 500 == 0) cat("  Processed", i, "/", n_routes, "routes\n")
}

matches <- rbindlist(route_solar)
cat("\nMatches within", RADIUS_KM, "km:", nrow(matches), "\n")
cat("Routes with nearby solar:", uniqueN(matches$route_id), "\n")

# ============================================================
# 4. Build treatment panel (route × year)
# ============================================================
cat("\n=== BUILDING TREATMENT PANEL ===\n")

# For each route × year: cumulative greenfield solar MW within radius
years <- 2000:2024
treatment <- CJ(route_id = routes_us$route_id, year = years)

# Compute cumulative MW for each route-year
treatment[, cum_solar_mw := 0]

for (rid in unique(matches$route_id)) {
  route_matches <- matches[route_id == rid]
  for (y in years) {
    cum_mw <- sum(route_matches[p_year <= y]$mw, na.rm = TRUE)
    treatment[route_id == rid & year == y, cum_solar_mw := cum_mw]
  }
}

# Binary treatment: first year with any solar within radius
first_solar <- matches[, .(first_solar_year = min(p_year, na.rm = TRUE)), by = route_id]
treatment <- merge(treatment, first_solar, by = "route_id", all.x = TRUE)
treatment[, treated := as.integer(!is.na(first_solar_year))]
treatment[, post := as.integer(!is.na(first_solar_year) & year >= first_solar_year)]

# Cohort for CS-DiD (0 = never treated)
treatment[, cohort := fifelse(is.na(first_solar_year), 0L, as.integer(first_solar_year))]

cat("Treatment summary:\n")
cat("  Treated routes:", uniqueN(treatment[treated == 1]$route_id), "\n")
cat("  Never-treated routes:", uniqueN(treatment[treated == 0]$route_id), "\n")
cat("  Cohort distribution:\n")
print(treatment[treated == 1, .(n_routes = uniqueN(route_id)), by = cohort][order(cohort)])

# ============================================================
# 5. Load BBS bird count data
# ============================================================
cat("\n=== LOADING BBS BIRD COUNTS ===\n")

# Species AOU codes for farmland guild
farmland_aou <- c(5010, 5011, 5460, 4940, 6040, 4740, 2730)
# Forest placebo
forest_aou <- c(6740, 7550, 6080)  # Ovenbird, Wood Thrush, Scarlet Tanager

all_aou <- c(farmland_aou, forest_aou)

# Read 50-stop data files (10 files, one per stop group)
# Sum across all 50 stops per route per year per species
bbs_dir <- file.path(DATA_DIR, "bbs_counts/50-StopData")
bbs_files <- list.files(bbs_dir, pattern = "Fifty.*\\.csv$", full.names = TRUE)

cat("Reading", length(bbs_files), "BBS count files...\n")
bbs_list <- list()
for (f in bbs_files) {
  cat("  Reading", basename(f), "...\n")
  dt <- fread(f)
  # Filter to target species and US routes
  dt <- dt[AOU %in% all_aou & CountryNum == 840]
  # Sum across 50 stops
  stop_cols <- paste0("Stop", 1:50)
  available_stops <- intersect(stop_cols, names(dt))
  dt[, total_count := rowSums(.SD, na.rm = TRUE), .SDcols = available_stops]
  # Keep essential columns
  dt <- dt[, .(route_id = paste0(StateNum, "_", Route),
               year = Year, aou = AOU, count = total_count, rpid = RPID)]
  bbs_list[[basename(f)]] <- dt
}

bbs <- rbindlist(bbs_list)
cat("BBS records for target species:", nrow(bbs), "\n")
cat("Year range:", range(bbs$year), "\n")

# Aggregate to route × year × guild
bbs[, guild := fifelse(aou %in% farmland_aou, "farmland", "forest")]

# Sum counts by guild per route-year
bird_panel <- bbs[, .(
  total_count = sum(count, na.rm = TRUE),
  n_species = uniqueN(aou[count > 0]),
  max_species_count = max(count, na.rm = TRUE)
), by = .(route_id, year, guild)]

# Reshape to wide (one row per route-year)
bird_wide <- dcast(bird_panel, route_id + year ~ guild,
                   value.var = c("total_count", "n_species"),
                   fill = 0)

cat("Bird panel:", nrow(bird_wide), "route-year observations\n")

# ============================================================
# 6. Merge treatment + bird data
# ============================================================
cat("\n=== MERGING PANEL ===\n")
panel <- merge(treatment, bird_wide, by = c("route_id", "year"), all.x = FALSE)
cat("Final panel:", nrow(panel), "observations\n")
cat("  Unique routes:", uniqueN(panel$route_id), "\n")
cat("  Years:", range(panel$year), "\n")
cat("  Treated routes in panel:", uniqueN(panel[treated == 1]$route_id), "\n")

# Summary stats
cat("\n=== SUMMARY STATISTICS ===\n")
cat("Farmland bird count by treatment:\n")
print(panel[, .(mean_count = mean(total_count_farmland, na.rm=TRUE),
                sd_count = sd(total_count_farmland, na.rm=TRUE),
                mean_species = mean(n_species_farmland, na.rm=TRUE)),
            by = treated])

# Save
fwrite(panel, file.path(DATA_DIR, "analysis_panel.csv"))

# Diagnostics
diag <- list(
  n_treated = uniqueN(panel[treated == 1]$route_id),
  n_pre = as.integer(min(panel[treated == 1]$first_solar_year, na.rm = TRUE) - min(panel$year)),
  n_obs = nrow(panel)
)
jsonlite::write_json(diag, file.path(DATA_DIR, "diagnostics.json"), auto_unbox = TRUE)
cat("Diagnostics:", jsonlite::toJSON(diag, auto_unbox=TRUE), "\n")

cat("\n=== CLEAN DATA COMPLETE ===\n")
