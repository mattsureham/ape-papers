## 02_clean_data.R — Clean and construct analysis panel
## APEP Paper apep_0584: Oregon Drug Decriminalization Symmetric Test

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Load raw data
# ============================================================
vsrr <- fread(file.path(data_dir, "vsrr_raw.csv"))
pop <- fread(file.path(data_dir, "census_population.csv"))

# ============================================================
# 2. Clean VSRR data
# ============================================================

# Parse year and month
vsrr[, year := as.integer(year)]
vsrr[, month_num := match(tolower(month), tolower(month.name))]

# Filter to US states + DC (exclude territories, US total)
us_states <- c(state.name, "District of Columbia")
vsrr <- vsrr[state_name %in% us_states]

# Create numeric date for time series
vsrr[, date := as.Date(sprintf("%d-%02d-01", year, month_num))]

# Clean death counts — use "data_value" column
vsrr[, deaths := as.numeric(data_value)]

# Create state FIPS lookup from state names
state_fips_map <- data.table(
  state_name = c(state.name, "District of Columbia"),
  state_fips = c(sprintf("%02d", c(1,2,4,5,6,8,9,10,12,13,15,16,17,18,19,20,21,22,23,24,
                                    25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,
                                    44,45,46,47,48,49,50,51,53,54,55,56)), "11")
)
vsrr <- merge(vsrr, state_fips_map, by = "state_name", all.x = TRUE)

# ============================================================
# 3. Create separate panels by indicator
# ============================================================

# Total overdose deaths
total_od <- vsrr[indicator == "Number of Drug Overdose Deaths",
                 .(state_name, state_fips, year, month_num, date, deaths)]
setnames(total_od, "deaths", "od_deaths")

# Synthetic opioids (fentanyl proxy)
fent <- vsrr[indicator == "Synthetic opioids, excl. methadone (T40.4)",
             .(state_name, state_fips, year, month_num, date, deaths)]
setnames(fent, "deaths", "fent_deaths")

# Heroin
heroin <- vsrr[indicator == "Heroin (T40.1)",
               .(state_name, state_fips, year, month_num, date, deaths)]
setnames(heroin, "deaths", "heroin_deaths")

# Cocaine
cocaine <- vsrr[indicator == "Cocaine (T40.5)",
                .(state_name, state_fips, year, month_num, date, deaths)]
setnames(cocaine, "deaths", "cocaine_deaths")

# Psychostimulants
psycho <- vsrr[indicator == "Psychostimulants with abuse potential (T43.6)",
               .(state_name, state_fips, year, month_num, date, deaths)]
setnames(psycho, "deaths", "psycho_deaths")

# Merge all drug types
panel <- total_od
for (df_drug in list(fent, heroin, cocaine, psycho)) {
  panel <- merge(panel, df_drug,
                 by = c("state_name", "state_fips", "year", "month_num", "date"),
                 all.x = TRUE)
}

# ============================================================
# 4. Merge population and compute rates
# ============================================================

# Population is annual — merge by state and year
pop[, state_fips := sprintf("%02d", as.integer(state_fips))]
panel <- merge(panel, pop[, .(state_fips, year, population)],
               by = c("state_fips", "year"), all.x = TRUE)

# Interpolate missing 2020 population (ACS disrupted by COVID)
# Use linear interpolation between 2019 and 2021
if (panel[year == 2020 & is.na(population), .N] > 0) {
  cat("Interpolating 2020 population (ACS COVID gap)...\n")
  pop_2019 <- pop[year == 2019, .(state_fips, pop_2019 = population)]
  pop_2021 <- pop[year == 2021, .(state_fips, pop_2021 = population)]
  pop_interp <- merge(pop_2019, pop_2021, by = "state_fips")
  pop_interp[, pop_2020 := as.integer(round((pop_2019 + pop_2021) / 2))]
  panel[pop_interp, on = .(state_fips), population := fifelse(
    year == 2020 & is.na(population), pop_2020, population
  )]
  cat("  Interpolated", panel[year == 2020 & !is.na(population), uniqueN(state_fips)], "states\n")
}

# Compute rates per 100K (these are 12-month-ending counts)
panel[, od_rate := od_deaths / population * 100000]
panel[, fent_rate := fent_deaths / population * 100000]
panel[, heroin_rate := heroin_deaths / population * 100000]
panel[, cocaine_rate := cocaine_deaths / population * 100000]
panel[, psycho_rate := psycho_deaths / population * 100000]

# Fentanyl exposure share
panel[, fent_share := fifelse(od_deaths > 0, fent_deaths / od_deaths, NA_real_)]

# ============================================================
# 5. Create time indices
# ============================================================

# Create numeric time index (months since Jan 2015)
panel[, time_index := (year - 2015) * 12 + month_num]

# Create numeric state ID
panel[, state_id := as.integer(factor(state_fips))]

# Oregon indicator
panel[, oregon := as.integer(state_name == "Oregon")]

# Treatment indicators
# Measure 110: effective Feb 1, 2021
panel[, post_decrim := as.integer(date >= as.Date("2021-02-01"))]
# HB 4002: effective Sep 1, 2024
panel[, post_recrim := as.integer(date >= as.Date("2024-09-01"))]

# Treatment phase
panel[, phase := fifelse(post_recrim == 1, "recriminalized",
                  fifelse(post_decrim == 1, "decriminalized", "pre"))]

# ============================================================
# 6. Filter to analysis sample
# ============================================================

# Keep Jan 2015 through latest available
panel <- panel[date >= as.Date("2015-01-01")]
panel <- panel[!is.na(od_deaths)]

# Sort
setorder(panel, state_fips, date)

# ============================================================
# 7. Summary statistics
# ============================================================
cat("\n=== PANEL SUMMARY ===\n")
cat(sprintf("States: %d\n", uniqueN(panel$state_name)))
cat(sprintf("Time range: %s to %s\n", min(panel$date), max(panel$date)))
cat(sprintf("Total rows: %d\n", nrow(panel)))
cat(sprintf("Oregon rows: %d\n", sum(panel$oregon)))

# Oregon trajectory
oregon_summary <- panel[state_name == "Oregon",
                        .(od_deaths = mean(od_deaths, na.rm = TRUE),
                          od_rate = mean(od_rate, na.rm = TRUE),
                          fent_share = mean(fent_share, na.rm = TRUE)),
                        by = phase]
cat("\nOregon by phase:\n")
print(oregon_summary)

# Save summary stats for tables
sumstats <- panel[, .(
  mean_od_deaths = mean(od_deaths, na.rm = TRUE),
  sd_od_deaths = sd(od_deaths, na.rm = TRUE),
  mean_od_rate = mean(od_rate, na.rm = TRUE),
  sd_od_rate = sd(od_rate, na.rm = TRUE),
  mean_fent_share = mean(fent_share, na.rm = TRUE),
  sd_fent_share = sd(fent_share, na.rm = TRUE),
  n_months = .N
), by = .(oregon = fifelse(oregon == 1, "Oregon", "Other States"))]

fwrite(sumstats, file.path(data_dir, "summary_stats.csv"))

# Detailed summary stats by phase
sumstats_phase <- panel[, .(
  mean_od_rate = mean(od_rate, na.rm = TRUE),
  sd_od_rate = sd(od_rate, na.rm = TRUE),
  mean_fent_rate = mean(fent_rate, na.rm = TRUE),
  mean_heroin_rate = mean(heroin_rate, na.rm = TRUE),
  mean_psycho_rate = mean(psycho_rate, na.rm = TRUE),
  mean_fent_share = mean(fent_share, na.rm = TRUE),
  n = .N
), by = .(group = fifelse(oregon == 1, "Oregon", "All Other States"), phase)]
fwrite(sumstats_phase, file.path(data_dir, "summary_stats_phase.csv"))

# ============================================================
# 8. Save analysis panel
# ============================================================
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat(sprintf("\nSaved analysis_panel.csv: %d rows\n", nrow(panel)))

# Validation
stopifnot("Panel has 51 states" = uniqueN(panel$state_name) == 51)
stopifnot("Oregon present" = "Oregon" %in% panel$state_name)
stopifnot("Has pre-period data" = any(panel$date < as.Date("2021-02-01")))
stopifnot("Has post-decrim data" = any(panel$date >= as.Date("2021-02-01")))
cat("Panel validation passed.\n")
