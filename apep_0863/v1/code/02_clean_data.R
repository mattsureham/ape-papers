## 02_clean_data.R — Build analysis sample with boundary-pair identification
## apep_0863: The Forecaster Lottery

library(data.table)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) > 0) setwd(file.path(script_dir, ".."))

## ============================================================
## 1. Load raw data
## ============================================================

tornadoes <- fread("data/tornadoes_raw.csv")
cat("Tornado events:", nrow(tornadoes), "\n")

county_wfo <- fread("data/county_wfo_map.csv")
cat("County-WFO mappings:", nrow(county_wfo), "\n")

# WFO performance averages (from IEM)
if (file.exists("data/wfo_averages.csv")) {
  wfo_avg <- fread("data/wfo_averages.csv")
  cat("WFO averages loaded:", nrow(wfo_avg), "WFOs\n")
} else {
  cat("WARNING: No WFO averages yet. Will use WFO FE as treatment.\n")
  wfo_avg <- data.table()
}

# Census
pop <- fread("data/census_population.csv")
pop_2020 <- pop[year == 2020, .(fips, population, mobile_homes)]
if (nrow(pop_2020) == 0) pop_2020 <- pop[year == max(year), .(fips, population, mobile_homes)]
cat("Census counties:", nrow(pop_2020), "\n")


## ============================================================
## 2. Merge tornado events with WFO assignments
## ============================================================

tornadoes <- merge(tornadoes, county_wfo[, .(fips, wfo, county_name)],
                   by = "fips", all.x = TRUE)
cat("Tornadoes with WFO:", sum(!is.na(tornadoes$wfo)), "/", nrow(tornadoes), "\n")
tornadoes <- tornadoes[!is.na(wfo)]

# Merge WFO performance
if (nrow(wfo_avg) > 0) {
  tornadoes <- merge(tornadoes, wfo_avg, by = "wfo", all.x = TRUE)
  cat("Tornadoes with WFO performance:", sum(!is.na(tornadoes$avg_lt_overall)), "/", nrow(tornadoes), "\n")
}

# Merge Census
tornadoes <- merge(tornadoes, pop_2020, by = "fips", all.x = TRUE)


## ============================================================
## 3. Construct boundary pairs from adjacency data
## ============================================================

cat("\nConstructing boundary pairs from shapefile...\n")

library(sf)
library(spdep)

shp_files <- list.files("data/nws_counties", pattern = "\\.shp$", full.names = TRUE)
stopifnot("NWS county shapefile not found" = length(shp_files) > 0)
counties_sf <- st_read(shp_files[1], quiet = TRUE)

# Build spatial adjacency (Queen contiguity = shared point or edge)
nb <- poly2nb(counties_sf, queen = TRUE)
adj_pairs <- list()
for (i in seq_along(nb)) {
  for (j in nb[[i]]) {
    if (j > i) {
      fi <- counties_sf$FIPS[i]
      fj <- counties_sf$FIPS[j]
      if (!is.na(fi) && !is.na(fj) && fi != "" && fj != "") {
        adj_pairs[[length(adj_pairs) + 1]] <- data.table(fips_a = fi, fips_b = fj)
      }
    }
  }
}

adj <- rbindlist(adj_pairs)
adj <- unique(adj)
cat("Spatially adjacent county pairs:", nrow(adj), "\n")

# Ensure consistent FIPS types (character)
county_wfo[, fips := as.character(fips)]
adj[, fips_a := as.character(fips_a)]
adj[, fips_b := as.character(fips_b)]

# Merge WFO for both sides
adj <- merge(adj, county_wfo[, .(fips, wfo)], by.x = "fips_a", by.y = "fips", all.x = TRUE)
setnames(adj, "wfo", "wfo_a")
adj <- merge(adj, county_wfo[, .(fips, wfo)], by.x = "fips_b", by.y = "fips", all.x = TRUE)
setnames(adj, "wfo", "wfo_b")

# Cross-WFO border pairs
border_pairs <- adj[!is.na(wfo_a) & !is.na(wfo_b) & wfo_a != wfo_b]
cat("Cross-WFO border pairs:", nrow(border_pairs), "\n")

# Canonical pair ID
border_pairs[, pair_id := paste0(pmin(fips_a, fips_b), "_", pmax(fips_a, fips_b))]
border_pairs <- unique(border_pairs, by = "pair_id")
cat("Unique cross-WFO border pairs:", nrow(border_pairs), "\n")

border_counties <- unique(c(border_pairs$fips_a, border_pairs$fips_b))
cat("Border counties:", length(border_counties), "\n")

fwrite(border_pairs, "data/border_pairs.csv")


## ============================================================
## 4. Build analysis dataset
## ============================================================

cat("\nBuilding analysis dataset...\n")

# Ensure consistent FIPS types across all datasets
tornadoes[, fips := as.character(fips)]
pop_2020[, fips := as.character(fips)]

# Filter tornadoes to border counties
torn_border <- tornadoes[fips %in% border_counties]
cat("Tornado events in border counties:", nrow(torn_border), "\n")

# Expand to tornado-pair observations
pairs_long <- rbind(
  border_pairs[, .(pair_id, fips = fips_a, partner_fips = fips_b, wfo_a, wfo_b)],
  border_pairs[, .(pair_id, fips = fips_b, partner_fips = fips_a, wfo_a = wfo_b, wfo_b = wfo_a)]
)

analysis <- merge(torn_border, pairs_long, by = "fips", allow.cartesian = TRUE)
cat("Analysis observations (tornado x pair):", nrow(analysis), "\n")

# Time of day
if ("time" %in% names(analysis)) {
  analysis[, hour := as.integer(substr(as.character(time), 1, 2))]
  analysis[is.na(hour), hour := 12L]
  analysis[, nighttime := as.integer(hour >= 20 | hour < 6)]
}

# Mobile home vulnerability
if ("mobile_homes" %in% names(analysis) & "population" %in% names(analysis)) {
  analysis[, mobile_share := mobile_homes / population]
  analysis[is.na(mobile_share), mobile_share := 0]
}

# Tornado intensity indicator
analysis[, strong_tornado := as.integer(ef_scale >= 2)]
analysis[, any_casualty := as.integer(casualties > 0)]
analysis[, any_death := as.integer(deaths > 0)]
analysis[, any_injury := as.integer(injuries > 0)]
analysis[, log_damage := log(damage_property + 1)]
analysis[, log_pop := log(population + 1)]
analysis[, ef_sq := ef_scale^2]


## ============================================================
## 5. Also build county-year panel for aggregate analysis
## ============================================================

county_year <- tornadoes[, .(
  n_tornadoes = .N,
  total_deaths = sum(deaths, na.rm = TRUE),
  total_injuries = sum(injuries, na.rm = TRUE),
  total_casualties = sum(casualties, na.rm = TRUE),
  total_damage = sum(damage_property, na.rm = TRUE),
  mean_ef = mean(ef_scale, na.rm = TRUE),
  max_ef = max(ef_scale, na.rm = TRUE)
), by = .(fips, wfo, year)]

county_year <- merge(county_year, pop_2020, by = "fips", all.x = TRUE)
if (nrow(wfo_avg) > 0) {
  county_year <- merge(county_year, wfo_avg, by = "wfo", all.x = TRUE)
}


## ============================================================
## 6. Summary
## ============================================================

cat("\n=== ANALYSIS SAMPLE ===\n")
cat("Total tornado-pair obs:", nrow(analysis), "\n")
n_torn_unique <- uniqueN(analysis, by = c("fips", "year", "begin_lat", "begin_lon"))
cat("Unique tornadoes:", n_torn_unique, "\n")
cat("Unique border pairs:", uniqueN(analysis$pair_id), "\n")
cat("Unique WFOs:", uniqueN(analysis$wfo), "\n")
cat("Years:", paste(range(analysis$year), collapse = "-"), "\n")
cat("Mean deaths/event:", round(mean(analysis$deaths, na.rm = TRUE), 4), "\n")
cat("Mean injuries/event:", round(mean(analysis$injuries, na.rm = TRUE), 4), "\n")
cat("Mean casualties/event:", round(mean(analysis$casualties, na.rm = TRUE), 4), "\n")

if ("avg_lt_overall" %in% names(analysis)) {
  cat("Mean WFO lead time:", round(mean(analysis$avg_lt_overall, na.rm = TRUE), 1), "min\n")
  cat("SD WFO lead time:", round(sd(analysis$avg_lt_overall, na.rm = TRUE), 1), "min\n")
}

fwrite(analysis, "data/analysis_tornado_pairs.csv")
fwrite(county_year, "data/county_year_panel.csv")
cat("\nSaved analysis datasets\n")
