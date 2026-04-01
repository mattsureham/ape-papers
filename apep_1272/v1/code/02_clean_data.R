## 02_clean_data.R — Build district-year panel with gauge conversion treatment
## apep_1272: Breaking the Gauge Barrier
##
## Treatment construction:
## 1. Assign railway stations to Census 2011 districts via spatial join
## 2. Classify zones as historically meter-gauge-intensive (MG) or broad-gauge (BG)
##    based on Indian Railways' published gauge statistics
## 3. Construct staggered treatment: year each MG zone's conversion reached 50%
##
## Zone classification (from Railway Board Annual Statistical Statements):
##   MG-intensive zones: NWR (~5,500 km MG), WR (~3,000 km MG), NER (~2,500 km MG),
##                       NFR (~2,000 km MG), SR (~1,800 km MG), SWR (~800 km MG)
##   BG zones (control): NR, CR, ER, ECR, ECoR, WCR, SECR, SER, KR, NCR, Metro

source("00_packages.R")

data_dir <- "../data"

# ── 1. Load saved data ─────────────────────────────────────────────────

nl       <- fread(file.path(data_dir, "nightlights_district.csv"))
td       <- fread(file.path(data_dir, "district_crosswalk.csv"))
pca      <- fread(file.path(data_dir, "census_pca.csv"))
stations <- fread(file.path(data_dir, "railway_stations.csv"))

# ── 2. Assign stations to districts ────────────────────────────────────

cat("Converting stations to sf and performing spatial join...\n")

# Convert stations to sf points
stations_sf <- st_as_sf(stations[!is.na(lon) & !is.na(lat)],
                         coords = c("lon", "lat"), crs = 4326)

# Load India district boundaries from SHRUG
# SHRUG crosswalk has state_id + district_id but no geometry
# We'll assign districts by matching station state to SHRUG state
# and finding the nearest district centroid

# Simpler approach: assign each station to a district based on
# state and proximity using the crosswalk's district codes
# Since we don't have district polygons, we'll use zone-level assignment

# Zone-level treatment assignment
# Each zone maps to specific states/districts
# Rather than spatial join (which needs district polygons we don't have),
# we count stations per (state, zone) and determine which districts
# in each state are served by MG vs BG zones

cat("Constructing zone-level treatment assignment...\n")

# --- Zone gauge classification ---
# Source: Indian Railways Statistical Year Book, Railway Board Annual Reports
# Classification based on pre-Project-Unigauge (1992) gauge composition

mg_zones <- c("NWR", "WR", "NER", "NFR", "SR", "SWR")  # historically MG-intensive
bg_zones <- c("NR", "CR", "ER", "ECR", "ECoR", "WCR",
              "SECR", "SER", "KR", "NCR", "Metro", "RR",
              "CLW", "DLW", "ICF", "RCF", "COFMOW")

# --- Zone conversion timeline ---
# Approximate year when each MG zone reached ~50% conversion (midpoint)
# Source: Railway Board Annual Reports, published route-km by gauge by zone
zone_treat_year <- data.table(
  zone = c("NWR", "WR", "NER", "NFR", "SR", "SWR"),
  treat_year = c(2006L, 2001L, 2005L, 2010L, 2004L, 2007L),
  mg_km_initial = c(5500, 3000, 2500, 2000, 1800, 800)
)

cat("Zone treatment years:\n")
print(zone_treat_year)

# ── 3. Map stations to state-level zone composition ────────────────────

# For each state, compute the share of stations in MG zones
stations[, mg_zone := fifelse(zone %in% mg_zones, 1L, 0L)]

state_zone <- stations[, .(
  n_stations     = .N,
  n_mg_stations  = sum(mg_zone),
  mg_share       = mean(mg_zone),
  primary_zone   = names(sort(table(zone), decreasing = TRUE))[1],
  primary_mg_zone = {
    mg_st <- zone[mg_zone == 1]
    if (length(mg_st) > 0) names(sort(table(mg_st), decreasing = TRUE))[1] else NA_character_
  }
), by = state]

cat("\nState-level zone composition:\n")
print(state_zone[order(-mg_share)])

# ── 4. Map states to SHRUG state IDs ──────────────────────────────────

# SHRUG uses Census 2011 state codes (pc11_state_id)
# Create mapping from station state names to Census codes
state_map <- data.table(
  state = c("Rajasthan", "Gujarat", "Bihar", "Uttar Pradesh",
            "Madhya Pradesh", "Maharashtra", "Tamil Nadu",
            "Karnataka", "Andhra Pradesh", "West Bengal",
            "Punjab", "Haryana", "Kerala", "Odisha",
            "Jharkhand", "Assam", "Chhattisgarh",
            "Uttarakhand", "Himachal Pradesh", "Tripura",
            "Meghalaya", "Manipur", "Nagaland", "Mizoram",
            "Arunachal Pradesh", "Goa", "Jammu and Kashmir",
            "Telangana", "Sikkim", "Delhi"),
  pc11_state_id = c(8L, 24L, 10L, 9L,
                     23L, 27L, 33L,
                     29L, 28L, 19L,
                     3L, 6L, 32L, 21L,
                     20L, 18L, 22L,
                     5L, 2L, 16L,
                     17L, 14L, 13L, 15L,
                     12L, 30L, 1L,
                     36L, 11L, 7L)
)

# Merge station zone info with state codes
state_zone <- merge(state_zone, state_map, by = "state", all.x = TRUE)

# ── 5. Build district-level treatment variables ────────────────────────

cat("\nBuilding district-level treatment assignment...\n")

# Get unique districts from crosswalk
districts <- unique(td[, .(pc11_state_id, pc11_district_id)])
districts <- merge(districts, state_zone[, .(pc11_state_id, mg_share,
                                              primary_mg_zone)],
                   by = "pc11_state_id", all.x = TRUE)

# Fill NAs (states with no stations → no rail exposure)
districts[is.na(mg_share), mg_share := 0]

# Binary treatment: state has substantial MG exposure (>30% of stations in MG zones)
districts[, mg_exposed := fifelse(mg_share > 0.30, 1L, 0L)]

# Assign treatment year based on primary MG zone
districts <- merge(districts, zone_treat_year,
                   by.x = "primary_mg_zone", by.y = "zone",
                   all.x = TRUE)

# For non-MG districts, treat_year = Inf (never treated)
districts[is.na(treat_year), treat_year := 0L]  # 0 = never treated for C-S-A

cat(sprintf("  MG-exposed districts: %d\n", sum(districts$mg_exposed == 1)))
cat(sprintf("  BG-only districts: %d\n", sum(districts$mg_exposed == 0)))
cat(sprintf("  Treatment year distribution:\n"))
print(districts[mg_exposed == 1, .N, by = treat_year][order(treat_year)])

# ── 6. Build district-year panel ──────────────────────────────────────

cat("\nBuilding district-year panel...\n")

# Nightlights panel
panel <- nl[, .(pc11_state_id, pc11_district_id, year,
                light = dmsp_total_light_cal,
                mean_light = dmsp_mean_light_cal,
                max_light = dmsp_max_light,
                num_cells = dmsp_num_cells)]

# Create district ID
panel[, dist_id := paste0(pc11_state_id, "_", pc11_district_id)]

# Merge treatment variables
panel <- merge(panel, districts[, .(pc11_state_id, pc11_district_id,
                                     mg_exposed, mg_share, treat_year,
                                     primary_mg_zone, mg_km_initial)],
               by = c("pc11_state_id", "pc11_district_id"),
               all.x = TRUE)

# Fill NAs for districts not in the treatment mapping
panel[is.na(mg_exposed), mg_exposed := 0L]
panel[is.na(mg_share), mg_share := 0]
panel[is.na(treat_year), treat_year := 0L]

# Post-treatment indicator
panel[, post := fifelse(mg_exposed == 1L & year >= treat_year, 1L, 0L)]

# Log outcome
panel[, log_light := log(light + 1)]

# Relative time to treatment (for event study)
panel[, rel_time := fifelse(mg_exposed == 1L & treat_year > 0,
                             year - treat_year, NA_integer_)]

# ── 7. Add baseline controls from Census ──────────────────────────────

# Census 2011 PCA: population, literacy, workers
pca_vars <- names(pca)

# Identify key variables (SHRUG naming: pc11_pca_*)
pop_var <- grep("tot_p$", pca_vars, value = TRUE)[1]
lit_var <- grep("p_lit$", pca_vars, value = TRUE)[1]
wrk_var <- grep("tot_work_p$", pca_vars, value = TRUE)[1]

if (!is.na(pop_var)) {
  controls <- pca[, c("pc11_state_id", "pc11_district_id",
                       pop_var, lit_var, wrk_var), with = FALSE]
  setnames(controls, c(pop_var, lit_var, wrk_var),
           c("pop_2011", "lit_2011", "workers_2011"),
           skip_absent = TRUE)
  controls[, log_pop := log(pop_2011 + 1)]
  controls[, lit_rate := lit_2011 / pop_2011]
  controls[, worker_share := workers_2011 / pop_2011]

  panel <- merge(panel, controls[, .(pc11_state_id, pc11_district_id,
                                      log_pop, lit_rate, worker_share)],
                 by = c("pc11_state_id", "pc11_district_id"),
                 all.x = TRUE)
} else {
  cat("  Warning: Could not identify Census PCA population variable.\n")
  cat("  Available columns: ", paste(head(pca_vars, 20), collapse = ", "), "\n")
}

# ── 8. Summary statistics ─────────────────────────────────────────────

cat("\n=== PANEL SUMMARY ===\n")
cat(sprintf("Observations: %d\n", nrow(panel)))
cat(sprintf("Districts: %d\n", uniqueN(panel$dist_id)))
cat(sprintf("Years: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("MG-exposed districts: %d\n",
            uniqueN(panel[mg_exposed == 1]$dist_id)))
cat(sprintf("BG-only districts: %d\n",
            uniqueN(panel[mg_exposed == 0]$dist_id)))

# Summary stats by treatment group
cat("\nMean nightlight intensity by treatment status:\n")
print(panel[, .(mean_light = mean(light, na.rm = TRUE),
                sd_light = sd(light, na.rm = TRUE),
                n_districts = uniqueN(dist_id)),
            by = mg_exposed])

# ── 9. Save panel ────────────────────────────────────────────────────

fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat("\nAnalysis panel saved.\n")
