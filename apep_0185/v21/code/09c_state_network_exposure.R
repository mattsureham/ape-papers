################################################################################
# 09c_state_network_exposure.R
# Construct state-level network MW exposure from raw SCI
#
# Properly aggregates county-pair SCI to state-state level:
#   SCI_ss' = Σ_{c∈s, d∈s'} SCI_cd × Pop_d
#   w_ss' = SCI_ss' / Σ_{k≠s} SCI_sk
#   NetworkMW_s,t = Σ_{j≠s} w_sj × log(MW_j,t)
#
# Also constructs:
#   - Distance-restricted IVs (non-adjacent, >500km)
#   - Placebo exposures (gas tax, corporate tax)
#   - Geographic proximity benchmark (inverse distance)
#
# Input:  ../data/raw_sci.rds, raw_county_centroids.rds, state_mw_panel.rds,
#         state_political_panel.rds (for placebo policies)
# Output: ../data/state_diffusion_panel.rds
################################################################################

source("00_packages.R")

cat("=== Constructing State-Level Network Exposure Panel ===\n\n")

# ============================================================================
# 1. Load Data
# ============================================================================

cat("1. Loading data...\n")

sci_raw <- readRDS("../data/raw_sci.rds")
centroids <- readRDS("../data/raw_county_centroids.rds")
state_mw_panel <- readRDS("../data/state_mw_panel.rds")
political_panel <- readRDS("../data/state_political_panel.rds")

# Load county population proxy from analysis panel if available
if (file.exists("../data/analysis_panel.rds")) {
  panel <- readRDS("../data/analysis_panel.rds")
  county_pop <- panel %>%
    filter(year %in% c(2012, 2013)) %>%
    group_by(county_fips) %>%
    summarise(pop_proxy = mean(emp, na.rm = TRUE), .groups = "drop")
  cat("  Using pre-treatment employment as population proxy\n")
} else {
  # Fallback: use uniform weights
  county_pop <- centroids %>%
    select(county_fips = fips) %>%
    mutate(pop_proxy = 1)
  cat("  WARNING: No analysis_panel.rds found, using uniform county weights\n")
}

cat("  SCI pairs:", format(nrow(sci_raw), big.mark = ","), "\n")
cat("  Counties:", nrow(centroids), "\n")

# ============================================================================
# 2. Aggregate SCI to State-State Level
# ============================================================================

cat("\n2. Aggregating SCI to state-state level...\n")

sci <- as_tibble(sci_raw) %>%
  mutate(
    state_fips_1 = substr(county_fips_1, 1, 2),
    state_fips_2 = substr(county_fips_2, 1, 2)
  ) %>%
  # Exclude self-county pairs
  filter(county_fips_1 != county_fips_2) %>%
  # Exclude within-state pairs (we want cross-state only)
  filter(state_fips_1 != state_fips_2)

# Join population proxy for destination county
sci <- sci %>%
  left_join(county_pop, by = c("county_fips_2" = "county_fips"))

# Aggregate to state-state: SCI_ss' = Σ_{c∈s, d∈s'} SCI_cd × Pop_d
state_sci <- sci %>%
  filter(!is.na(pop_proxy)) %>%
  group_by(state_fips_1, state_fips_2) %>%
  summarise(
    sci_state = sum(sci * pop_proxy, na.rm = TRUE),
    n_county_pairs = n(),
    .groups = "drop"
  )

cat("  State-state pairs:", nrow(state_sci), "\n")
cat("  Unique origin states:", n_distinct(state_sci$state_fips_1), "\n")

# Normalize: w_ss' = SCI_ss' / Σ_{k≠s} SCI_sk
state_sci_totals <- state_sci %>%
  group_by(state_fips_1) %>%
  summarise(total_sci = sum(sci_state), .groups = "drop")

state_sci <- state_sci %>%
  left_join(state_sci_totals, by = "state_fips_1") %>%
  mutate(w_state = sci_state / total_sci)

cat("  Weight sum check (should be ~1 for each state):\n")
weight_check <- state_sci %>%
  group_by(state_fips_1) %>%
  summarise(w_sum = sum(w_state), .groups = "drop")
cat("  Range: [", round(min(weight_check$w_sum), 6), ",",
    round(max(weight_check$w_sum), 6), "]\n")

# ============================================================================
# 3. Compute Inter-State Distances and Adjacency
# ============================================================================

cat("\n3. Computing inter-state distances and adjacency...\n")

# State population centroids (population-weighted centroid of county centroids)
state_centroids <- centroids %>%
  left_join(county_pop, by = c("fips" = "county_fips")) %>%
  filter(!is.na(pop_proxy)) %>%
  group_by(state_fips) %>%
  summarise(
    state_lon = weighted.mean(lon, pop_proxy, na.rm = TRUE),
    state_lat = weighted.mean(lat, pop_proxy, na.rm = TRUE),
    .groups = "drop"
  )

# Haversine distance between state centroids
haversine <- function(lon1, lat1, lon2, lat2) {
  R <- 6371
  dLat <- (lat2 - lat1) * pi / 180
  dLon <- (lon2 - lon1) * pi / 180
  lat1_rad <- lat1 * pi / 180
  lat2_rad <- lat2 * pi / 180
  a <- sin(dLat/2)^2 + cos(lat1_rad) * cos(lat2_rad) * sin(dLon/2)^2
  c <- 2 * atan2(sqrt(a), sqrt(1-a))
  R * c
}

state_dist <- expand_grid(
  s1 = state_centroids$state_fips,
  s2 = state_centroids$state_fips
) %>%
  filter(s1 != s2) %>%
  left_join(state_centroids %>% rename(s1 = state_fips, lon1 = state_lon, lat1 = state_lat), by = "s1") %>%
  left_join(state_centroids %>% rename(s2 = state_fips, lon2 = state_lon, lat2 = state_lat), by = "s2") %>%
  mutate(dist_km = haversine(lon1, lat1, lon2, lat2))

# Add distance to state SCI
state_sci <- state_sci %>%
  left_join(
    state_dist %>% select(s1, s2, dist_km),
    by = c("state_fips_1" = "s1", "state_fips_2" = "s2")
  )

# State adjacency (border-sharing)
# Manually coded adjacency for contiguous US
adjacent_pairs <- tribble(
  ~s1, ~s2,
  "01","12", "01","13", "01","28", "01","47",
  "04","06", "04","08", "04","32", "04","35", "04","49",
  "05","22", "05","28", "05","29", "05","40", "05","47", "05","48",
  "06","32", "06","41",
  "08","20", "08","31", "08","35", "08","49", "08","56",
  "09","25", "09","36", "09","44",
  "10","24", "10","34", "10","42",
  "12","13",
  "13","37", "13","45", "13","47",
  "16","30", "16","32", "16","41", "16","49", "16","53", "16","56",
  "17","18", "17","19", "17","21", "17","29", "17","55",
  "18","21", "18","26", "18","39",
  "19","27", "19","29", "19","31", "19","46", "19","55",
  "20","29", "20","31", "20","40",
  "21","29", "21","39", "21","47", "21","51", "21","54",
  "22","28", "22","48",
  "23","33",
  "24","42", "24","51", "24","54",
  "25","33", "25","36", "25","44", "25","50",
  "26","39", "26","55",
  "27","38", "27","46", "27","55",
  "28","47",
  "29","31", "29","40", "29","47",
  "30","38", "30","46", "30","56",
  "31","46", "31","56",
  "32","41", "32","49",
  "33","36", "33","50",
  "34","36", "34","42",
  "35","40", "35","48", "35","49",
  "36","42", "36","50",
  "37","45", "37","47", "37","51",
  "38","46",
  "39","42", "39","54",
  "40","48",
  "41","53",
  "42","54",
  "45","37",
  "47","51",
  "49","56",
  "51","54"
)

# Make symmetric
adjacent_both <- bind_rows(
  adjacent_pairs,
  adjacent_pairs %>% rename(s1 = s2, s2 = s1)
) %>%
  distinct()

# Flag adjacent states in state_sci
state_sci <- state_sci %>%
  left_join(
    adjacent_both %>% mutate(is_adjacent = TRUE),
    by = c("state_fips_1" = "s1", "state_fips_2" = "s2")
  ) %>%
  mutate(is_adjacent = replace_na(is_adjacent, FALSE))

cat("  Adjacent state pairs:", sum(state_sci$is_adjacent), "\n")
cat("  Non-adjacent pairs:", sum(!state_sci$is_adjacent), "\n")

# ============================================================================
# 4. Compute State-Level Network MW Exposure
# ============================================================================

cat("\n4. Computing state-level network MW exposure...\n")

# State MW panel (collapse to state-year for annual analysis)
state_mw_annual <- state_mw_panel %>%
  group_by(state_fips, year) %>%
  summarise(
    min_wage = mean(min_wage),
    log_min_wage = mean(log_min_wage),
    .groups = "drop"
  ) %>%
  filter(year >= 2012, year <= 2022)

# Function to compute state-level network exposure for a given year
# with optional distance/adjacency restriction
compute_state_exposure <- function(yr, restrict = "none") {
  mw_this_year <- state_mw_annual %>%
    filter(year == yr) %>%
    select(state_fips, log_mw = log_min_wage, mw_level = min_wage)

  # Apply restriction
  weights <- state_sci
  if (restrict == "non_adjacent") {
    weights <- weights %>% filter(!is_adjacent)
  } else if (restrict == "dist_500") {
    weights <- weights %>% filter(dist_km > 500)
  } else if (restrict == "dist_300") {
    weights <- weights %>% filter(dist_km > 300)
  }

  # Re-normalize weights after restriction
  weights <- weights %>%
    group_by(state_fips_1) %>%
    mutate(w_renorm = sci_state / sum(sci_state)) %>%
    ungroup()

  # Compute exposure
  exposure <- weights %>%
    left_join(mw_this_year, by = c("state_fips_2" = "state_fips")) %>%
    filter(!is.na(log_mw)) %>%
    group_by(state_fips_1) %>%
    summarise(
      network_mw = sum(w_renorm * log_mw),
      network_mw_dollar = sum(w_renorm * mw_level),
      n_connected_states = n(),
      .groups = "drop"
    ) %>%
    mutate(year = yr)

  return(exposure)
}

# Compute all versions
cat("  Full network exposure...\n")
full_list <- lapply(2012:2022, function(yr) compute_state_exposure(yr, "none"))
exposure_full <- bind_rows(full_list) %>%
  rename(network_mw_full = network_mw, network_mw_full_dollar = network_mw_dollar)

cat("  Non-adjacent states only (IV)...\n")
nonadj_list <- lapply(2012:2022, function(yr) compute_state_exposure(yr, "non_adjacent"))
exposure_nonadj <- bind_rows(nonadj_list) %>%
  rename(network_mw_nonadj = network_mw, network_mw_nonadj_dollar = network_mw_dollar,
         n_nonadj_states = n_connected_states)

cat("  Distance > 500km (IV)...\n")
dist500_list <- lapply(2012:2022, function(yr) compute_state_exposure(yr, "dist_500"))
exposure_dist500 <- bind_rows(dist500_list) %>%
  rename(network_mw_dist500 = network_mw, network_mw_dist500_dollar = network_mw_dollar,
         n_dist500_states = n_connected_states)

cat("  Distance > 300km (IV)...\n")
dist300_list <- lapply(2012:2022, function(yr) compute_state_exposure(yr, "dist_300"))
exposure_dist300 <- bind_rows(dist300_list) %>%
  rename(network_mw_dist300 = network_mw, network_mw_dist300_dollar = network_mw_dollar,
         n_dist300_states = n_connected_states)

# ============================================================================
# 5. Geographic Proximity Benchmark
# ============================================================================

cat("\n5. Computing geographic proximity exposure (inverse distance)...\n")

# State-level inverse distance weights
geo_weights <- state_dist %>%
  filter(dist_km > 0) %>%
  mutate(inv_dist = 1 / dist_km) %>%
  group_by(s1) %>%
  mutate(w_geo = inv_dist / sum(inv_dist)) %>%
  ungroup()

geo_list <- lapply(2012:2022, function(yr) {
  mw <- state_mw_annual %>%
    filter(year == yr) %>%
    select(state_fips, log_mw = log_min_wage)

  geo_weights %>%
    left_join(mw, by = c("s2" = "state_fips")) %>%
    filter(!is.na(log_mw)) %>%
    group_by(s1) %>%
    summarise(
      geo_mw_exposure = sum(w_geo * log_mw),
      .groups = "drop"
    ) %>%
    mutate(year = yr) %>%
    rename(state_fips_1 = s1)
})

exposure_geo <- bind_rows(geo_list)

# ============================================================================
# 6. Placebo Exposures (Gas Tax, Corporate Tax)
# ============================================================================

cat("\n6. Computing placebo exposures...\n")

# Gas tax exposure: same SCI weights, applied to gas tax rates
cat("  Gas tax placebo...\n")
gas_tax_list <- lapply(2012:2022, function(yr) {
  gas <- political_panel %>%
    filter(year == yr, !is.na(log_gas_tax)) %>%
    select(state_fips, log_gas_tax)

  state_sci %>%
    group_by(state_fips_1) %>%
    mutate(w_renorm = sci_state / sum(sci_state)) %>%
    ungroup() %>%
    left_join(gas, by = c("state_fips_2" = "state_fips")) %>%
    filter(!is.na(log_gas_tax)) %>%
    group_by(state_fips_1) %>%
    summarise(
      network_gas_tax = sum(w_renorm * log_gas_tax),
      .groups = "drop"
    ) %>%
    mutate(year = yr)
})
exposure_gas <- bind_rows(gas_tax_list)

# Corporate tax exposure: same SCI weights, applied to corporate tax rates
cat("  Corporate tax placebo...\n")
corp_tax_list <- lapply(2012:2022, function(yr) {
  corp <- political_panel %>%
    filter(year == yr, !is.na(corp_tax_rate)) %>%
    select(state_fips, corp_tax_rate)

  state_sci %>%
    group_by(state_fips_1) %>%
    mutate(w_renorm = sci_state / sum(sci_state)) %>%
    ungroup() %>%
    left_join(corp, by = c("state_fips_2" = "state_fips")) %>%
    filter(!is.na(corp_tax_rate)) %>%
    group_by(state_fips_1) %>%
    summarise(
      network_corp_tax = sum(w_renorm * corp_tax_rate),
      .groups = "drop"
    ) %>%
    mutate(year = yr)
})
exposure_corp <- bind_rows(corp_tax_list)

# ============================================================================
# 7. Merge All State-Level Exposures
# ============================================================================

cat("\n7. Merging all exposures into diffusion panel...\n")

# Start with own MW
diffusion_panel <- state_mw_annual %>%
  rename(own_mw = min_wage, log_own_mw = log_min_wage)

# Add all network exposures
diffusion_panel <- diffusion_panel %>%
  left_join(exposure_full %>% select(state_fips_1, year, network_mw_full, network_mw_full_dollar, n_connected_states),
            by = c("state_fips" = "state_fips_1", "year")) %>%
  left_join(exposure_nonadj %>% select(state_fips_1, year, network_mw_nonadj, n_nonadj_states),
            by = c("state_fips" = "state_fips_1", "year")) %>%
  left_join(exposure_dist500 %>% select(state_fips_1, year, network_mw_dist500, n_dist500_states),
            by = c("state_fips" = "state_fips_1", "year")) %>%
  left_join(exposure_dist300 %>% select(state_fips_1, year, network_mw_dist300),
            by = c("state_fips" = "state_fips_1", "year")) %>%
  left_join(exposure_geo %>% select(state_fips_1, year, geo_mw_exposure),
            by = c("state_fips" = "state_fips_1", "year")) %>%
  left_join(exposure_gas %>% select(state_fips_1, year, network_gas_tax),
            by = c("state_fips" = "state_fips_1", "year")) %>%
  left_join(exposure_corp %>% select(state_fips_1, year, network_corp_tax),
            by = c("state_fips" = "state_fips_1", "year"))

# Add political controls
diffusion_panel <- diffusion_panel %>%
  left_join(political_panel, by = c("state_fips", "year"))

# ============================================================================
# 8. Construct Outcome Variables
# ============================================================================

cat("\n8. Constructing outcome variables...\n")

diffusion_panel <- diffusion_panel %>%
  arrange(state_fips, year) %>%
  group_by(state_fips) %>%
  mutate(
    # Forward outcomes (t+1)
    log_own_mw_lead = lead(log_own_mw, 1),
    own_mw_lead = lead(own_mw, 1),
    delta_log_mw = lead(log_own_mw, 1) - log_own_mw,
    mw_increased = as.integer(delta_log_mw > 0.001),
    # Real increase indicator: exceeds CPI inflation rate
    real_increase = case_when(
      is.na(delta_log_mw) ~ NA_integer_,
      is.na(cpi_u) ~ NA_integer_,
      TRUE ~ {
        # CPI inflation rate for this year
        cpi_growth <- lead(cpi_u, 1) / cpi_u - 1
        # MW growth rate
        mw_growth <- (own_mw_lead / own_mw) - 1
        as.integer(mw_growth > cpi_growth + 0.005)  # Real increase if > inflation + 0.5pp
      }
    )
  ) %>%
  ungroup()

# Drop last year (no forward lead)
diffusion_panel <- diffusion_panel %>%
  filter(!is.na(delta_log_mw))

# Exclude states at $15 ceiling
diffusion_panel <- diffusion_panel %>%
  mutate(at_ceiling = own_mw >= 14.50)

cat("  Total state-year obs:", nrow(diffusion_panel), "\n")
cat("  States:", n_distinct(diffusion_panel$state_fips), "\n")
cat("  At $15 ceiling:", sum(diffusion_panel$at_ceiling), "\n")
cat("  MW increases:", sum(diffusion_panel$mw_increased, na.rm = TRUE), "\n")
cat("  Real increases:", sum(diffusion_panel$real_increase, na.rm = TRUE), "\n")

# ============================================================================
# 9. Add Census Region
# ============================================================================

cat("\n9. Adding Census regions...\n")

census_regions <- tribble(
  ~state_fips, ~census_region, ~census_division,
  "09","Northeast","New England", "23","Northeast","New England",
  "25","Northeast","New England", "33","Northeast","New England",
  "44","Northeast","New England", "50","Northeast","New England",
  "34","Northeast","Mid-Atlantic", "36","Northeast","Mid-Atlantic",
  "42","Northeast","Mid-Atlantic",
  "17","Midwest","E N Central", "18","Midwest","E N Central",
  "26","Midwest","E N Central", "39","Midwest","E N Central",
  "55","Midwest","E N Central",
  "19","Midwest","W N Central", "20","Midwest","W N Central",
  "27","Midwest","W N Central", "29","Midwest","W N Central",
  "31","Midwest","W N Central", "38","Midwest","W N Central",
  "46","Midwest","W N Central",
  "10","South","S Atlantic", "11","South","S Atlantic",
  "12","South","S Atlantic", "13","South","S Atlantic",
  "24","South","S Atlantic", "37","South","S Atlantic",
  "45","South","S Atlantic", "51","South","S Atlantic",
  "54","South","S Atlantic",
  "01","South","E S Central", "21","South","E S Central",
  "28","South","E S Central", "47","South","E S Central",
  "05","South","W S Central", "22","South","W S Central",
  "40","South","W S Central", "48","South","W S Central",
  "04","West","Mountain", "08","West","Mountain",
  "16","West","Mountain", "30","West","Mountain",
  "32","West","Mountain", "35","West","Mountain",
  "49","West","Mountain", "56","West","Mountain",
  "02","West","Pacific", "06","West","Pacific",
  "15","West","Pacific", "41","West","Pacific",
  "53","West","Pacific"
)

diffusion_panel <- diffusion_panel %>%
  left_join(census_regions, by = "state_fips")

# ============================================================================
# 10. Save
# ============================================================================

cat("\n10. Saving diffusion panel...\n")

saveRDS(diffusion_panel, "../data/state_diffusion_panel.rds")

# Also save state SCI weights for cascade simulation
saveRDS(state_sci, "../data/state_sci_weights.rds")

cat("\n=== State-Level Exposure Summary ===\n")
cat("  Network MW (full):     mean =", round(mean(diffusion_panel$network_mw_full, na.rm = TRUE), 4),
    ", sd =", round(sd(diffusion_panel$network_mw_full, na.rm = TRUE), 4), "\n")
cat("  Network MW (non-adj):  mean =", round(mean(diffusion_panel$network_mw_nonadj, na.rm = TRUE), 4),
    ", sd =", round(sd(diffusion_panel$network_mw_nonadj, na.rm = TRUE), 4), "\n")
cat("  Network MW (dist>500): mean =", round(mean(diffusion_panel$network_mw_dist500, na.rm = TRUE), 4),
    ", sd =", round(sd(diffusion_panel$network_mw_dist500, na.rm = TRUE), 4), "\n")
cat("  Geographic exposure:   mean =", round(mean(diffusion_panel$geo_mw_exposure, na.rm = TRUE), 4),
    ", sd =", round(sd(diffusion_panel$geo_mw_exposure, na.rm = TRUE), 4), "\n")
cat("  Gas tax placebo:       mean =", round(mean(diffusion_panel$network_gas_tax, na.rm = TRUE), 4),
    ", sd =", round(sd(diffusion_panel$network_gas_tax, na.rm = TRUE), 4), "\n")

cat("\nFiles saved:\n")
cat("  - state_diffusion_panel.rds\n")
cat("  - state_sci_weights.rds\n")
cat("=== State Network Exposure Complete ===\n")
