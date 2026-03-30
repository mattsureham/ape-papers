##############################################################################
# 02_clean_data.R — Construct analysis dataset
# apep_1168: Contagious NIMBYism
##############################################################################

source("00_packages.R")
DATA_DIR <- "../data"

# ============================================================================
# 1. Clean USGS turbine data → county-year turbine panel
# ============================================================================
cat("=== Building county-year turbine panel ===\n")

turbines <- fread(file.path(DATA_DIR, "uswtdb_V8_3_20260325.csv"))

# County FIPS is t_fips (5-digit)
turbines[, fips := sprintf("%05d", as.integer(t_fips))]
turbines <- turbines[!is.na(p_year) & p_year >= 2000 & p_year <= 2024]

# Aggregate: county × year turbine counts and capacity
turb_cy <- turbines[, .(
  n_turbines_new = .N,
  capacity_new_mw = sum(p_cap, na.rm = TRUE) / 1000  # kW → MW
), by = .(fips, year = p_year)]

cat("  Turbine-county-year obs:", nrow(turb_cy), "\n")
cat("  Counties with turbines:", uniqueN(turb_cy$fips), "\n")
cat("  Year range:", range(turb_cy$year), "\n")

# Create cumulative panel: expand to full county × year grid
turb_counties <- unique(turb_cy$fips)
years <- 2000:2024
grid <- CJ(fips = turb_counties, year = years)
grid <- merge(grid, turb_cy, by = c("fips", "year"), all.x = TRUE)
grid[is.na(n_turbines_new), n_turbines_new := 0]
grid[is.na(capacity_new_mw), capacity_new_mw := 0]

# Cumulative turbines by county-year
setorder(grid, fips, year)
grid[, cum_turbines := cumsum(n_turbines_new), by = fips]
grid[, cum_capacity_mw := cumsum(capacity_new_mw), by = fips]

# Also build a full county list (all US counties)
turb_panel <- grid
cat("  Turbine panel rows:", nrow(turb_panel), "\n")

# ============================================================================
# 2. Clean SCI → normalized weight matrix
# ============================================================================
cat("\n=== Processing SCI data ===\n")

sci <- fread(file.path(DATA_DIR, "sci_us_counties.csv"))
# Columns: user_country, friend_country, user_region, friend_region, scaled_sci
# Keep US-US pairs only
sci <- sci[user_country == "US" & friend_country == "US"]
setnames(sci, c("user_region", "friend_region", "scaled_sci"),
         c("fips_i", "fips_j", "sci"))
sci[, fips_i := sprintf("%05d", as.integer(fips_i))]
sci[, fips_j := sprintf("%05d", as.integer(fips_j))]
# Remove self-connections
sci <- sci[fips_i != fips_j]

cat("  SCI pairs:", nrow(sci), "\n")
cat("  Unique counties (i):", uniqueN(sci$fips_i), "\n")

# Normalize: for each county i, compute share weights
sci[, sci_total_i := sum(as.numeric(sci)), by = fips_i]
sci[, w_ij := as.numeric(sci) / sci_total_i]

# Validation
cat("  Weight sum check (should be ~1):", mean(sci[, sum(w_ij), by = fips_i]$V1), "\n")

# ============================================================================
# 3. Clean ordinance data → county-level first adoption year
# ============================================================================
cat("\n=== Processing wind ordinance data ===\n")

ord <- as.data.table(readxl::read_excel(
  file.path(DATA_DIR, "nrel_ordinances_2025.xlsx"),
  sheet = "County-Level", skip = 1
))

setnames(ord, c("County Subdivision FIPS Code", "Ordinance Year"),
         c("fips_raw", "ord_year"))

# Clean FIPS — some may be 4-digit (need leading zero)
ord[, fips := sprintf("%05d", as.integer(fips_raw))]

# Keep rows with valid FIPS
ord <- ord[!is.na(fips_raw) & nchar(fips) == 5]
cat("  Rows with valid FIPS:", nrow(ord), "\n")

# First ordinance year per county (earliest restriction)
ord_first <- ord[!is.na(ord_year) & ord_year >= 2000 & ord_year <= 2024,
                 .(first_ord_year = min(ord_year)), by = fips]

# Also count counties with ANY ordinance (even if year is NA)
ord_ever <- ord[, .(has_ordinance = 1L), by = fips]
ord_ever <- unique(ord_ever)

cat("  Counties with dated ordinances:", nrow(ord_first), "\n")
cat("  Counties with any ordinance:", nrow(ord_ever), "\n")
cat("  Ordinance year range:", range(ord_first$first_ord_year), "\n")
cat("  Year distribution:\n")
print(table(ord_first$first_ord_year))

# ============================================================================
# 4. Construct shift-share exposure variable
# ============================================================================
cat("\n=== Constructing SCI-weighted turbine exposure ===\n")

# For each county i and year t:
# Exposure_it = Σ_j w_ij × CumTurbines_jt
# where w_ij = SCI_ij / Σ_k SCI_ik (pre-determined network weights)

# First, get cumulative turbines per county-year for ALL counties
# (counties without turbines have 0)
all_fips <- unique(c(sci$fips_i, sci$fips_j))
cat("  Total counties in SCI:", length(all_fips), "\n")

# Create full grid with turbine data
full_grid <- CJ(fips = all_fips, year = 2000:2024)
full_grid <- merge(full_grid, turb_panel[, .(fips, year, cum_turbines, cum_capacity_mw)],
                   by = c("fips", "year"), all.x = TRUE)
full_grid[is.na(cum_turbines), cum_turbines := 0]
full_grid[is.na(cum_capacity_mw), cum_capacity_mw := 0]

# Compute shift-share exposure using DuckDB for speed
con <- dbConnect(duckdb())
dbWriteTable(con, "sci_weights", sci[, .(fips_i, fips_j, w_ij)])
dbWriteTable(con, "turbine_panel", full_grid[, .(fips, year, cum_turbines, cum_capacity_mw)])

cat("  Computing SCI-weighted exposure (this may take a moment)...\n")
exposure <- dbGetQuery(con, "
  SELECT
    s.fips_i AS fips,
    t.year,
    SUM(s.w_ij * t.cum_turbines) AS sci_exposure_turbines,
    SUM(s.w_ij * t.cum_capacity_mw) AS sci_exposure_mw
  FROM sci_weights s
  JOIN turbine_panel t ON s.fips_j = t.fips
  GROUP BY s.fips_i, t.year
  ORDER BY s.fips_i, t.year
")
exposure <- as.data.table(exposure)
cat("  Exposure obs:", nrow(exposure), "\n")
cat("  Exposure range:", range(exposure$sci_exposure_turbines), "\n")

# ============================================================================
# 5. Construct geographic-distance-weighted exposure (horse race control)
# ============================================================================
cat("\n=== Constructing distance-weighted turbine exposure ===\n")

centroids <- fread(file.path(DATA_DIR, "county_centroids.csv"))
centroids[, fips := sprintf("%05d", as.integer(fips))]

# Compute pairwise distances for counties with turbines
# Use inverse-distance weighting: w_ij = 1/d_ij^2 (gravity)
# For efficiency, only compute for counties within 500km
dbWriteTable(con, "centroids", centroids[, .(fips, lon, lat)])

# Compute distance-weighted exposure using SQL
# Haversine approximation: cos(lat)*Δlon gives reasonable results for US
cat("  Computing distance-weighted exposure...\n")
geo_exposure <- dbGetQuery(con, "
  WITH dist AS (
    SELECT
      a.fips AS fips_i,
      b.fips AS fips_j,
      -- Approximate distance in km using equirectangular projection
      SQRT(
        POWER((b.lon - a.lon) * COS(RADIANS((a.lat + b.lat) / 2)) * 111.32, 2) +
        POWER((b.lat - a.lat) * 111.32, 2)
      ) AS dist_km
    FROM centroids a
    CROSS JOIN centroids b
    WHERE a.fips != b.fips
      AND ABS(b.lon - a.lon) < 10  -- Pre-filter: ~800km longitude
      AND ABS(b.lat - a.lat) < 10  -- Pre-filter: ~1100km latitude
  ),
  dist_weights AS (
    SELECT
      fips_i, fips_j,
      1.0 / POWER(GREATEST(dist_km, 1.0), 2) AS inv_dist_sq
    FROM dist
    WHERE dist_km < 500
  ),
  norm_weights AS (
    SELECT
      fips_i, fips_j,
      inv_dist_sq / SUM(inv_dist_sq) OVER (PARTITION BY fips_i) AS geo_w
    FROM dist_weights
  )
  SELECT
    n.fips_i AS fips,
    t.year,
    SUM(n.geo_w * t.cum_turbines) AS geo_exposure_turbines
  FROM norm_weights n
  JOIN turbine_panel t ON n.fips_j = t.fips
  GROUP BY n.fips_i, t.year
  ORDER BY n.fips_i, t.year
")
geo_exposure <- as.data.table(geo_exposure)
cat("  Geo exposure obs:", nrow(geo_exposure), "\n")

dbDisconnect(con, shutdown = TRUE)

# ============================================================================
# 6. Merge everything into analysis dataset
# ============================================================================
cat("\n=== Merging analysis dataset ===\n")

# Start with exposure panel
panel <- merge(exposure, geo_exposure, by = c("fips", "year"), all.x = TRUE)
panel[is.na(geo_exposure_turbines), geo_exposure_turbines := 0]

# Add own turbines
panel <- merge(panel, full_grid[, .(fips, year, cum_turbines, cum_capacity_mw)],
               by = c("fips", "year"), all.x = TRUE)
setnames(panel, c("cum_turbines", "cum_capacity_mw"),
         c("own_turbines", "own_capacity_mw"))

# Add ordinance adoption status
panel <- merge(panel, ord_first, by = "fips", all.x = TRUE)
panel <- merge(panel, ord_ever, by = "fips", all.x = TRUE)
panel[is.na(has_ordinance), has_ordinance := 0L]
panel[, ordinance_adopted := fifelse(!is.na(first_ord_year) & year >= first_ord_year, 1L, 0L)]

# Add county controls
controls <- fread(file.path(DATA_DIR, "county_controls.csv"))
controls[, fips := sprintf("%05d", as.integer(fips))]
panel <- merge(panel, controls[, .(fips, pop, medinc, college_share)],
               by = "fips", all.x = TRUE)

# Add election data (political lean)
elections <- fread(file.path(DATA_DIR, "county_elections.csv"))
elections[, fips := sprintf("%05d", as.integer(fips))]
panel <- merge(panel, elections[, .(fips, gop_share)],
               by = "fips", all.x = TRUE)

# Add state FIPS for clustering
panel[, state_fips := substr(fips, 1, 2)]

# Create log variables
panel[, log_pop := log(pop + 1)]
panel[, log_medinc := log(medinc + 1)]

# Summary statistics
cat("\nAnalysis Panel Summary:\n")
cat("  Observations:", nrow(panel), "\n")
cat("  Counties:", uniqueN(panel$fips), "\n")
cat("  Years:", range(panel$year), "\n")
cat("  Counties ever adopting ordinance:", sum(panel[year == 2024]$has_ordinance), "\n")
cat("  Counties with own turbines:", sum(panel[year == 2024]$own_turbines > 0, na.rm = TRUE), "\n")
cat("  Mean SCI exposure:", mean(panel$sci_exposure_turbines, na.rm = TRUE), "\n")
cat("  Mean Geo exposure:", mean(panel$geo_exposure_turbines, na.rm = TRUE), "\n")
cat("  Correlation SCI vs Geo:", cor(panel$sci_exposure_turbines,
    panel$geo_exposure_turbines, use = "complete.obs"), "\n")

# ============================================================================
# 7. Create key subsamples
# ============================================================================

# Key subsample: counties with NO own turbines (cleanest test of network diffusion)
panel[, no_own_turbines := fifelse(own_turbines == 0, 1L, 0L)]
cat("\n  Counties with ZERO own turbines (at any point):",
    uniqueN(panel[no_own_turbines == 1]$fips), "\n")
cat("  Of those, adopted ordinance:",
    sum(panel[no_own_turbines == 1 & year == 2024]$ordinance_adopted, na.rm = TRUE), "\n")

# Save
fwrite(panel, file.path(DATA_DIR, "analysis_panel.csv"))
cat("\nSaved analysis_panel.csv:", nrow(panel), "rows\n")
