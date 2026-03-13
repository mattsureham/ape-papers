## 02_clean_data.R — Clean and construct analysis panel
## apep_0652: EPCS Mandates and Opioid Mortality

source("00_packages.R")

# ============================================================================
# 1. Load raw data
# ============================================================================
cdc_raw <- data.table::fread("../data/cdc_vsrr_raw.csv")
epcs_dates <- data.table::fread("../data/epcs_treatment_dates.csv")
pop_dt <- data.table::fread("../data/state_population.csv")

state_xwalk <- data.table::data.table(
  state_name = c(state.name, "District of Columbia"),
  state_abbr = c(state.abb, "DC")
)

# ============================================================================
# 2. Clean CDC VSRR
# ============================================================================
message("Cleaning CDC VSRR data...")

# month is text — convert to numeric
month_map <- setNames(1:12, month.name)
cdc_raw[, month_num := month_map[month]]

# Filter to US states (exclude territories and "United States")
cdc <- cdc_raw[state_name %in% c(state.name, "District of Columbia")]
message("After state filter: ", nrow(cdc), " rows")

# Ensure numeric types
cdc[, data_value := as.numeric(data_value)]
cdc[, predicted_value := as.numeric(predicted_value)]
cdc[, year := as.integer(year)]

# Keep relevant indicators
target_indicators <- c(
  "Number of Drug Overdose Deaths",
  "Natural & semi-synthetic opioids (T40.2)",
  "Synthetic opioids, excl. methadone (T40.4)",
  "Heroin (T40.1)",
  "Opioids (T40.0-T40.4,T40.6)",
  "Cocaine (T40.5)",
  "Methadone (T40.3)",
  "Psychostimulants with abuse potential (T43.6)"
)

cdc <- cdc[indicator %in% target_indicators]
message("After indicator filter: ", nrow(cdc), " rows")

# Short names
cdc[, indicator_short := fcase(
  indicator == "Number of Drug Overdose Deaths", "total_overdose",
  indicator == "Natural & semi-synthetic opioids (T40.2)", "rx_opioid",
  indicator == "Synthetic opioids, excl. methadone (T40.4)", "synth_opioid",
  indicator == "Heroin (T40.1)", "heroin",
  indicator == "Opioids (T40.0-T40.4,T40.6)", "all_opioid",
  indicator == "Cocaine (T40.5)", "cocaine",
  indicator == "Methadone (T40.3)", "methadone",
  indicator == "Psychostimulants with abuse potential (T43.6)", "psychostim"
)]

# Merge state abbreviations
cdc <- merge(cdc, state_xwalk, by = "state_name", all.x = TRUE)

# ============================================================================
# 3. Aggregate to state-year (use December 12-month ending counts)
# ============================================================================
message("Aggregating to state-year level...")

# For each state-year-indicator, take December (12-month ending count).
# If December missing, take latest available month.
cdc_annual <- cdc[, {
  dec_row <- .SD[month_num == 12]
  if (nrow(dec_row) > 0 && !is.na(dec_row$data_value[1])) {
    dec_row[1]
  } else {
    valid <- .SD[!is.na(data_value)]
    if (nrow(valid) > 0) valid[which.max(month_num)][1] else .SD[1]
  }
}, by = .(state_name, state_abbr, year, indicator_short)]

cdc_annual[, deaths := data_value]

# Check coverage
message("State-year-indicator observations: ", nrow(cdc_annual))
message("Indicators per state-year: ", cdc_annual[!is.na(deaths), .N, by = .(state_abbr, year)][, mean(N)])

# ============================================================================
# 4. Pivot wide
# ============================================================================
panel_wide <- dcast(cdc_annual,
                    state_name + state_abbr + year ~ indicator_short,
                    value.var = "deaths",
                    fun.aggregate = function(x) x[!is.na(x)][1])

message("Panel: ", nrow(panel_wide), " state-years, ", ncol(panel_wide), " columns")

# ============================================================================
# 5. Merge population
# ============================================================================
# Interpolate missing 2020 (ACS 2020 1-year was cancelled)
pop_dt[, year := as.integer(year)]
pop_dt[, population := as.numeric(population)]

# Linear interpolation for 2020
for (s in unique(pop_dt$state_name)) {
  p19 <- pop_dt[state_name == s & year == 2019, population]
  p21 <- pop_dt[state_name == s & year == 2021, population]
  if (length(p19) == 1 && length(p21) == 1) {
    if (nrow(pop_dt[state_name == s & year == 2020]) == 0) {
      pop_dt <- rbind(pop_dt, data.table(
        state_name = s,
        state_fips = pop_dt[state_name == s & year == 2019, state_fips],
        year = 2020L,
        population = (p19 + p21) / 2
      ))
    }
  }
}

panel_wide[, year := as.integer(year)]
panel_wide <- merge(panel_wide, pop_dt[, .(state_name, year, population)],
                    by = c("state_name", "year"), all.x = TRUE)

# Per capita rates (per 100K)
rate_vars <- c("total_overdose", "rx_opioid", "synth_opioid", "heroin",
               "all_opioid", "cocaine", "methadone", "psychostim")
for (v in rate_vars) {
  if (v %in% names(panel_wide)) {
    rate_name <- paste0(v, "_rate")
    panel_wide[, (rate_name) := get(v) / population * 100000]
  }
}

# ============================================================================
# 6. Merge EPCS treatment
# ============================================================================
epcs_annual <- unique(epcs_dates[, .(state_abbr, epcs_year)])
panel_wide <- merge(panel_wide, epcs_annual, by = "state_abbr", all.x = TRUE)

panel_wide[, treated := fifelse(!is.na(epcs_year) & year >= epcs_year, 1L, 0L)]
panel_wide[, group := fifelse(is.na(epcs_year), 0L, as.integer(epcs_year))]

# ============================================================================
# 7. Sample restrictions
# ============================================================================
panel <- panel_wide[year >= 2015 & year <= 2023]

# Drop if population missing (shouldn't happen)
panel <- panel[!is.na(population)]

# Create numeric state ID
panel[, state_id := as.integer(factor(state_abbr))]

# ============================================================================
# 8. Save and validate
# ============================================================================
data.table::fwrite(panel, "../data/analysis_panel.csv")

message("\n=== Panel construction complete ===")
message("States: ", uniqueN(panel$state_abbr))
message("Years: ", paste(range(panel$year), collapse = "-"))
message("State-years: ", nrow(panel))
message("Treated states: ", uniqueN(panel[group > 0, state_abbr]))
message("Never-treated: ", uniqueN(panel[group == 0, state_abbr]))
message("Treatment groups: ", paste(sort(unique(panel$group[panel$group > 0])), collapse = ", "))

# Treatment cohort summary
treat_summary <- panel[group > 0, .(n_states = uniqueN(state_abbr)), by = group]
setorder(treat_summary, group)
message("\nTreatment cohorts:")
print(treat_summary)

# Validate
stopifnot(uniqueN(panel$state_abbr) >= 40)
stopifnot(nrow(panel) >= 300)
stopifnot(sum(panel$group > 0) > 0)

message("\nSample means:")
for (v in c("rx_opioid_rate", "synth_opioid_rate", "heroin_rate", "total_overdose_rate")) {
  message("  ", v, ": ", round(mean(panel[[v]], na.rm = TRUE), 2))
}
