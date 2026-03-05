# ============================================================================
# 02_clean_data.R — Construct analysis dataset: ZIP × border × year panel
# APEP-0525: Tax Borders and the Rich
# ============================================================================

source("00_packages.R")

# ============================================================================
# 1. Load data
# ============================================================================

irs <- fread(file.path(DATA_DIR, "irs_zip_panel.csv"))
zcta <- fread(file.path(DATA_DIR, "zcta_centroids.csv"))
border_pairs <- fread(file.path(DATA_DIR, "border_pairs.csv"))
states <- readRDS(file.path(DATA_DIR, "state_borders.rds"))
tax_rates <- fread(file.path(DATA_DIR, "state_tax_rates.csv"))

# Ensure ZIP codes are 5-digit character strings
irs[, zipcode := sprintf("%05d", as.integer(zipcode))]
irs[, statefips := sprintf("%02d", as.integer(statefips))]
zcta[, zipcode := sprintf("%05d", as.integer(zipcode))]

# Ensure border pair FIPS are character
border_pairs[, high_tax_fips := sprintf("%02d", as.integer(high_tax_fips))]
border_pairs[, low_tax_fips := sprintf("%02d", as.integer(low_tax_fips))]
tax_rates[, state_fips := sprintf("%02d", as.integer(state_fips))]

cat("Loaded IRS data:", nrow(irs), "rows\n")
cat("Loaded ZCTA centroids:", nrow(zcta), "rows\n")

# ============================================================================
# 2. Compute ZIP-level outcomes by income group
# ============================================================================

# IRS agi_stub: 1=<$25K, 2=$25-50K, 3=$50-75K, 4=$75-100K, 5=$100-200K, 6=$200K+
# Compute totals by summing all stubs

total <- irs[, .(total_returns = sum(n1, na.rm = TRUE),
                  total_agi = sum(a00100, na.rm = TRUE)),
              by = .(zipcode, year)]
high_inc <- irs[agi_stub == 6, .(high_returns = n1, high_agi = a00100),
                 by = .(zipcode, year)]
low_inc <- irs[agi_stub %in% c(1, 2), .(low_returns = sum(n1, na.rm = TRUE),
                                          low_agi = sum(a00100, na.rm = TRUE)),
                by = .(zipcode, year)]
mid_inc <- irs[agi_stub %in% c(3, 4), .(mid_returns = sum(n1, na.rm = TRUE),
                                          mid_agi = sum(a00100, na.rm = TRUE)),
                by = .(zipcode, year)]

zip_panel <- merge(total, high_inc, by = c("zipcode", "year"), all.x = TRUE)
zip_panel <- merge(zip_panel, low_inc, by = c("zipcode", "year"), all.x = TRUE)
zip_panel <- merge(zip_panel, mid_inc, by = c("zipcode", "year"), all.x = TRUE)

# Replace NAs with 0 (missing high-income means suppressed or zero)
setnafill(zip_panel, fill = 0, cols = c("high_returns", "high_agi",
                                         "low_returns", "low_agi",
                                         "mid_returns", "mid_agi"))

# Compute shares
zip_panel[, high_share := fifelse(total_returns > 0, high_returns / total_returns, NA_real_)]
zip_panel[, low_share := fifelse(total_returns > 0, low_returns / total_returns, NA_real_)]
zip_panel[, mid_share := fifelse(total_returns > 0, mid_returns / total_returns, NA_real_)]
zip_panel[, avg_agi_high := fifelse(high_returns > 0, high_agi / high_returns, NA_real_)]
zip_panel[, log_high_returns := log1p(high_returns)]
zip_panel[, log_total_returns := log1p(total_returns)]

# Flag suppressed ZIPs
zip_panel[, suppressed := (total_returns > 10 & high_returns == 0)]

cat("ZIP panel constructed:", nrow(zip_panel), "rows,",
    uniqueN(zip_panel$zipcode), "ZIPs\n")

# ============================================================================
# 3. Merge ZIP centroids and assign to states
# ============================================================================

zip_panel <- merge(zip_panel, zcta, by = "zipcode", all.x = TRUE)
zip_panel <- zip_panel[!is.na(lon) & !is.na(lat)]

# Assign state FIPS from IRS data
zip_state <- irs[, .(statefips = statefips[1]), by = zipcode]
zip_panel <- merge(zip_panel, zip_state, by = "zipcode", all.x = TRUE)

cat("After centroid merge:", nrow(zip_panel), "rows,",
    uniqueN(zip_panel$zipcode), "ZIPs\n")

# ============================================================================
# 4. Compute distance to each relevant state border
# ============================================================================

# Convert ZIP centroids to sf object in same CRS as state boundaries
zip_unique <- zip_panel[, .(zipcode, lon, lat, statefips)][!duplicated(zipcode)]
zip_sf <- st_as_sf(zip_unique, coords = c("lon", "lat"), crs = 4326)
zip_sf <- st_transform(zip_sf, crs = 5070)

cat("Computing distances to state borders...\n")

border_assignments <- list()

for (p in 1:nrow(border_pairs)) {
  pair <- border_pairs[p]
  cat("  Processing pair:", pair$pair_label, "\n")

  # Get boundary between the two states
  state_h <- states[states$STATEFP == pair$high_tax_fips, ]
  state_l <- states[states$STATEFP == pair$low_tax_fips, ]

  if (nrow(state_h) == 0 | nrow(state_l) == 0) {
    cat("    WARNING: Could not find states for pair", pair$pair_label, "\n")
    next
  }

  # The border is the intersection of the two state boundary lines
  border_line <- tryCatch(
    st_intersection(st_boundary(state_h), st_boundary(state_l)),
    error = function(e) {
      cat("    WARNING: Border intersection failed:", e$message, "\n")
      NULL
    }
  )

  if (is.null(border_line) || nrow(border_line) == 0) {
    cat("    WARNING: No shared border found for", pair$pair_label, "\n")
    next
  }

  border_geom <- st_union(st_geometry(border_line))

  if (st_is_empty(border_geom)) {
    cat("    WARNING: Empty border for", pair$pair_label, "\n")
    next
  }

  # Get ZIPs in both states
  zips_in_pair <- zip_unique[statefips %in% c(pair$high_tax_fips, pair$low_tax_fips)]

  if (nrow(zips_in_pair) == 0) {
    cat("    WARNING: No ZIPs found for", pair$pair_label, "\n")
    next
  }

  zip_subset <- zip_sf[zip_sf$zipcode %in% zips_in_pair$zipcode, ]

  # Distance to border (in km)
  dists <- as.numeric(st_distance(zip_subset, border_geom)) / 1000

  # Sign: negative for high-tax side, positive for low-tax side
  zip_fips_lookup <- setNames(zips_in_pair$statefips, zips_in_pair$zipcode)
  zip_fips_vec <- zip_fips_lookup[zip_subset$zipcode]
  signs <- ifelse(zip_fips_vec == pair$high_tax_fips, -1, 1)

  border_dt_p <- data.table(
    zipcode = zip_subset$zipcode,
    pair_id = pair$pair_id,
    pair_label = pair$pair_label,
    dist_to_border_km = dists * signs,
    high_tax_side = as.integer(zip_fips_vec == pair$high_tax_fips)
  )

  border_assignments[[p]] <- border_dt_p
  cat("    Assigned", nrow(border_dt_p), "ZIPs\n")
}

border_dt <- rbindlist(border_assignments)
cat("Border assignments:", nrow(border_dt), "ZIP-pair records\n")

# ============================================================================
# 5. Create analysis panel: ZIP × border pair × year
# ============================================================================

# Restrict to ZIPs within 50km of a border
border_dt <- border_dt[abs(dist_to_border_km) <= 50]
cat("ZIPs within 50km of border:", uniqueN(border_dt$zipcode), "\n")

# Merge with ZIP panel
analysis <- merge(zip_panel[, !c("statefips"), with = FALSE],
                  border_dt, by = "zipcode", allow.cartesian = TRUE)

# Add tax rate differential
tax_long <- melt(tax_rates,
                 id.vars = c("state_fips", "state_abbr", "state_name"),
                 measure.vars = patterns("^rate_"),
                 variable.name = "year_var",
                 value.name = "top_rate")
tax_long[, year := as.integer(gsub("rate_", "", year_var))]
tax_long[, year_var := NULL]

# Merge tax rates for the high-tax state in each pair
bp_tax_h <- merge(border_pairs[, .(pair_id, high_tax_fips)],
                  tax_long[, .(state_fips, year, top_rate)],
                  by.x = "high_tax_fips", by.y = "state_fips",
                  allow.cartesian = TRUE)
setnames(bp_tax_h, "top_rate", "high_tax_rate")

bp_tax_l <- merge(border_pairs[, .(pair_id, low_tax_fips)],
                  tax_long[, .(state_fips, year, top_rate)],
                  by.x = "low_tax_fips", by.y = "state_fips",
                  allow.cartesian = TRUE)
setnames(bp_tax_l, "top_rate", "low_tax_rate")

bp_tax <- merge(bp_tax_h[, .(pair_id, year, high_tax_rate)],
                bp_tax_l[, .(pair_id, year, low_tax_rate)],
                by = c("pair_id", "year"))
bp_tax[, tax_differential := high_tax_rate - low_tax_rate]

analysis <- merge(analysis, bp_tax, by = c("pair_id", "year"), all.x = TRUE)

# Add period indicators
analysis[, post_salt := as.integer(year >= 2018)]
analysis[, post_covid := as.integer(year >= 2020)]
analysis[, period := fcase(
  year < 2018, "Pre-SALT",
  year %in% 2018:2019, "Post-SALT/Pre-COVID",
  year >= 2020, "COVID"
)]

# Border pair × year fixed effect
analysis[, pair_year := paste(pair_id, year, sep = "_")]

cat("\n=== ANALYSIS PANEL CONSTRUCTED ===\n")
cat("Rows:", nrow(analysis), "\n")
cat("ZIP codes:", uniqueN(analysis$zipcode), "\n")
cat("Border pairs:", uniqueN(analysis$pair_id), "\n")
cat("Years:", uniqueN(analysis$year), "\n")
cat("Mean high-income share:", round(mean(analysis$high_share, na.rm = TRUE), 4), "\n")
cat("Mean distance to border:", round(mean(abs(analysis$dist_to_border_km), na.rm = TRUE), 1), "km\n")

fwrite(analysis, file.path(DATA_DIR, "analysis_panel.csv"))
cat("Analysis panel saved\n")

# ============================================================================
# 6. Validation
# ============================================================================

stopifnot("Expected multiple border pairs" = uniqueN(analysis$pair_id) >= 5)
stopifnot("Expected 10 years" = uniqueN(analysis$year) == 10)
stopifnot("Expected 500+ ZIPs near borders" = uniqueN(analysis$zipcode) >= 500)
stopifnot("High share between 0 and 1" = all(analysis$high_share >= 0 & analysis$high_share <= 1, na.rm = TRUE))

cat("\nVALIDATION PASSED\n")
