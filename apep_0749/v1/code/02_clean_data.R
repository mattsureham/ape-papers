## 02_clean_data.R — Construct state-quarter panel for analysis
## apep_0749: The Game-Day Externality

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. LOAD RAW DATA
# ============================================================
fars <- fread(file.path(data_dir, "fars_crashes.csv"))
pop  <- fread(file.path(data_dir, "state_population.csv"))
osb  <- fread(file.path(data_dir, "osb_treatment_dates.csv"))

cat("Loaded:", nrow(fars), "FARS crashes,",
    nrow(pop), "pop obs,", nrow(osb), "OSB states\n")

# ============================================================
# 2. AGGREGATE FARS TO STATE-QUARTER LEVEL
# ============================================================
# Ensure variables exist
stopifnot("DRUNK_DR" %in% names(fars))
fars[, alcohol_involved := as.integer(DRUNK_DR > 0)]
fars[, quarter := quarter(as.Date(sprintf("%d-%02d-%02d", YEAR, MONTH, DAY)))]

# State-quarter crash counts
panel_sq <- fars[, .(
  total_crashes   = .N,
  total_fatals    = sum(FATALS, na.rm = TRUE),
  alc_crashes     = sum(alcohol_involved, na.rm = TRUE),
  alc_fatals      = sum(FATALS[alcohol_involved == 1], na.rm = TRUE),
  nonalc_crashes  = sum(alcohol_involved == 0, na.rm = TRUE),
  nonalc_fatals   = sum(FATALS[alcohol_involved == 0], na.rm = TRUE)
), by = .(state_fips = STATE, year = YEAR, quarter)]

# Game-day level aggregation (for mechanism test)
fars[, nfl_gameday := as.integer(
  MONTH %in% c(9, 10, 11, 12, 1, 2) & DAY_WEEK %in% c(1, 2, 5)
)]

panel_gd <- fars[, .(
  total_crashes   = .N,
  alc_crashes     = sum(alcohol_involved, na.rm = TRUE),
  alc_fatals      = sum(FATALS[alcohol_involved == 1], na.rm = TRUE)
), by = .(state_fips = STATE, year = YEAR, quarter, game_day = nfl_gameday)]

cat("State-quarter panel:", nrow(panel_sq), "obs\n")
cat("State-quarter-gameday panel:", nrow(panel_gd), "obs\n")

# ============================================================
# 3. MERGE POPULATION
# ============================================================
panel_sq <- merge(panel_sq, pop, by = c("state_fips", "year"), all.x = TRUE)
panel_gd <- merge(panel_gd, pop, by = c("state_fips", "year"), all.x = TRUE)

# Drop observations with missing population (territories, DC edge cases)
panel_sq <- panel_sq[!is.na(population) & population > 0]
panel_gd <- panel_gd[!is.na(population) & population > 0]

# Per-capita rates (per 100,000 population, annualized from quarterly)
panel_sq[, alc_crash_rate   := alc_crashes / population * 100000 * 4]
panel_sq[, total_crash_rate := total_crashes / population * 100000 * 4]
panel_sq[, alc_fatal_rate   := alc_fatals / population * 100000 * 4]
panel_sq[, alc_share        := alc_crashes / total_crashes]

# ============================================================
# 4. MERGE TREATMENT VARIABLE
# ============================================================
# Create treatment indicator: OSB legal in state s at quarter t
osb[, osb_launch := as.Date(osb_launch)]
osb[, osb_year := year(osb_launch)]
osb[, osb_quarter := quarter(osb_launch)]

# Merge treatment dates
panel_sq <- merge(panel_sq, osb[, .(state_fips, osb_launch, osb_year, osb_quarter)],
                  by = "state_fips", all.x = TRUE)

# Treatment indicator: 1 if quarter is on or after launch quarter
panel_sq[, yearq := year + (quarter - 1) / 4]
panel_sq[, osb_yearq := osb_year + (osb_quarter - 1) / 4]
panel_sq[, treated := as.integer(!is.na(osb_yearq) & yearq >= osb_yearq)]

# Never-treated states: those without OSB dates
panel_sq[is.na(osb_yearq), treated := 0L]

# For CS-DiD: treatment cohort (year-quarter of first treatment)
# Never-treated coded as 0 or Inf
panel_sq[, cohort_yearq := fifelse(is.na(osb_yearq), 0, osb_yearq)]

# Same for game-day panel
panel_gd <- merge(panel_gd, osb[, .(state_fips, osb_launch, osb_year, osb_quarter)],
                  by = "state_fips", all.x = TRUE)
panel_gd[, yearq := year + (quarter - 1) / 4]
panel_gd[, osb_yearq := osb_year + (osb_quarter - 1) / 4]
panel_gd[, treated := as.integer(!is.na(osb_yearq) & yearq >= osb_yearq)]
panel_gd[is.na(osb_yearq), treated := 0L]
panel_gd[, cohort_yearq := fifelse(is.na(osb_yearq), 0, osb_yearq)]

# ============================================================
# 5. SUMMARY STATISTICS
# ============================================================
cat("\n=== PANEL SUMMARY ===\n")
cat("States:", length(unique(panel_sq$state_fips)), "\n")
cat("Time periods:", length(unique(panel_sq$yearq)), "quarters\n")
cat("Observations:", nrow(panel_sq), "\n")
cat("Treated states:", length(unique(panel_sq[!is.na(osb_yearq), state_fips])), "\n")
cat("Never-treated states:", length(unique(panel_sq[is.na(osb_yearq), state_fips])), "\n")
cat("Treated obs:", sum(panel_sq$treated), "\n")
cat("\nOutcome means:\n")
cat("  Alcohol crash rate (per 100K):", round(mean(panel_sq$alc_crash_rate), 2), "\n")
cat("  Total crash rate (per 100K):", round(mean(panel_sq$total_crash_rate), 2), "\n")
cat("  Alcohol share of crashes:", round(mean(panel_sq$alc_share, na.rm = TRUE), 3), "\n")

# ============================================================
# 6. SAVE PANELS
# ============================================================
fwrite(panel_sq, file.path(data_dir, "panel_state_quarter.csv"))
fwrite(panel_gd, file.path(data_dir, "panel_gameday.csv"))

cat("\nPanels saved.\n")
