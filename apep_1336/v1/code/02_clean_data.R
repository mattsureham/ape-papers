# 02_clean_data.R — Construct county-year panel for analysis
# apep_1336: EPA Enforcement Federalism Production Function

source("00_packages.R")

data_dir <- "../data/"

# ==============================================================================
# 1. LOAD RAW DATA
# ==============================================================================

cat("=== Loading data ===\n")
aqs <- readRDS(file.path(data_dir, "aqs_monitor_data.rds"))
state_fed <- readRDS(file.path(data_dir, "state_fed_share.rds"))
epa_staff <- readRDS(file.path(data_dir, "epa_staffing.rds"))

cat(sprintf("AQS: %d rows\n", nrow(aqs)))
cat(sprintf("States with federal shares: %d\n", nrow(state_fed)))

# ==============================================================================
# 2. AGGREGATE AQS TO COUNTY-YEAR-POLLUTANT LEVEL
# ==============================================================================
# Average across monitors within the same county-year-pollutant

cat("\n=== Aggregating AQS to county-year level ===\n")

county_panel <- aqs[, .(
  mean_conc = weighted.mean(mean_conc, valid_days, na.rm = TRUE),
  max_value = max(max_value, na.rm = TRUE),
  n_monitors = .N,
  total_valid_days = sum(valid_days, na.rm = TRUE)
), by = .(county_id, state_fips, county_fips, state_abbr, state_name,
          county_name, param_code, param_name, year)]

cat(sprintf("County-year-pollutant panel: %d observations\n", nrow(county_panel)))

# ==============================================================================
# 3. CREATE WIDE POLLUTANT PANELS
# ==============================================================================
# Separate panel for each pollutant (main analysis uses PM2.5)

# PM2.5 panel (parameter code 88101)
pm25 <- county_panel[param_code == 88101]
cat(sprintf("PM2.5 panel: %d county-years, %d counties, years %d-%d\n",
            nrow(pm25), n_distinct(pm25$county_id),
            min(pm25$year), max(pm25$year)))

# SO2 panel (parameter code 42401)
so2 <- county_panel[param_code == 42401]
cat(sprintf("SO2 panel: %d county-years, %d counties\n",
            nrow(so2), n_distinct(so2$county_id)))

# NO2 panel (parameter code 42602)
no2 <- county_panel[param_code == 42602]
cat(sprintf("NO2 panel: %d county-years, %d counties\n",
            nrow(no2), n_distinct(no2$county_id)))

# Ozone panel (parameter code 44201)
ozone <- county_panel[param_code == 44201]
cat(sprintf("Ozone panel: %d county-years, %d counties\n",
            nrow(ozone), n_distinct(ozone$county_id)))

# ==============================================================================
# 4. MERGE WITH TREATMENT VARIABLES
# ==============================================================================

cat("\n=== Merging with treatment variables ===\n")

# Prepare federal share data for merging
fed_share <- state_fed[, c("state_abbr", "fed_share", "epa_region")]

# Merge each panel with federal share and EPA staffing
merge_treatment <- function(dt) {
  # Add federal share
  dt <- merge(dt, fed_share, by = "state_abbr", all.x = TRUE)

  # Add EPA staffing
  dt <- merge(dt, epa_staff[, c("year", "oeca_index", "post_decline")],
              by = "year", all.x = TRUE)

  # Construct shift-share treatment variable
  # Treatment = federal share × (1 - OECA staffing index)
  # Higher fed_share × lower staffing = more exposure to enforcement decline
  dt[, treatment := fed_share * (1 - oeca_index)]

  # Simple binary post × continuous exposure
  dt[, post_x_fedshare := post_decline * fed_share]

  # Log outcome (add small constant to avoid log(0))
  dt[, log_conc := log(mean_conc + 0.001)]

  # Balanced panel indicator: keep counties observed in all years
  county_year_counts <- dt[, .N, by = county_id]
  n_years <- n_distinct(dt$year)
  balanced_counties <- county_year_counts[N >= n_years * 0.7, county_id]
  dt[, balanced := county_id %in% balanced_counties]

  return(dt)
}

pm25 <- merge_treatment(pm25)
so2 <- merge_treatment(so2)
no2 <- merge_treatment(no2)
ozone <- merge_treatment(ozone)

cat(sprintf("PM2.5 with treatment: %d rows, %d balanced counties\n",
            nrow(pm25), n_distinct(pm25[balanced == TRUE, county_id])))
cat(sprintf("SO2 with treatment: %d rows, %d balanced counties\n",
            nrow(so2), n_distinct(so2[balanced == TRUE, county_id])))

# ==============================================================================
# 5. CONSTRUCT STATE-LEVEL INSPECTION PANEL
# ==============================================================================
# State-level panel for mechanism test (state substitution)

cat("\n=== Constructing state-level panel ===\n")

state_panel <- pm25[, .(
  mean_pm25 = mean(mean_conc, na.rm = TRUE),
  n_counties = n_distinct(county_id),
  n_monitors = sum(n_monitors)
), by = .(state_abbr, year)]

state_panel <- merge(state_panel, fed_share, by = "state_abbr")
state_panel <- merge(state_panel,
                     epa_staff[, c("year", "oeca_index", "post_decline")],
                     by = "year")
state_panel[, post_x_fedshare := post_decline * fed_share]
state_panel[, log_pm25 := log(mean_pm25)]

cat(sprintf("State-year panel: %d observations, %d states\n",
            nrow(state_panel), n_distinct(state_panel$state_abbr)))

# ==============================================================================
# 6. SAVE ANALYSIS-READY DATA
# ==============================================================================

saveRDS(pm25, file.path(data_dir, "panel_pm25.rds"))
saveRDS(so2, file.path(data_dir, "panel_so2.rds"))
saveRDS(no2, file.path(data_dir, "panel_no2.rds"))
saveRDS(ozone, file.path(data_dir, "panel_ozone.rds"))
saveRDS(state_panel, file.path(data_dir, "panel_state.rds"))

cat("\n=== Summary Statistics ===\n")
cat(sprintf("PM2.5 mean: %.2f μg/m³ (sd=%.2f)\n",
            mean(pm25$mean_conc, na.rm = TRUE),
            sd(pm25$mean_conc, na.rm = TRUE)))
cat(sprintf("Federal share mean: %.3f (sd=%.3f)\n",
            mean(pm25$fed_share, na.rm = TRUE),
            sd(pm25$fed_share, na.rm = TRUE)))

cat("\nCleaning complete.\n")
