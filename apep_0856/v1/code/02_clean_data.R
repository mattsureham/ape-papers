# 02_clean_data.R — Clean and construct analysis variables
# apep_0856: Tipped MW Stability Paradox

source("code/00_packages.R")

# ============================================================
# 1. Load raw data
# ============================================================
qwi <- fread("data/qwi_restaurants_raw.csv")
qwi_placebo <- fread("data/qwi_placebo_raw.csv")
mw_panel <- fread("data/mw_panel.csv")

cat(sprintf("Loaded QWI restaurants: %d rows\n", nrow(qwi)))
cat(sprintf("Loaded QWI placebo: %d rows\n", nrow(qwi_placebo)))

# ============================================================
# 2. Clean QWI data
# ============================================================

# Create time period variable (year-quarter)
qwi[, yq := year + (quarter - 1) / 4]
qwi[, race_label := fifelse(race == "A1", "White", "Black")]

# Drop observations with missing key variables
qwi <- qwi[!is.na(earn_avg) & !is.na(Emp) & earn_avg > 0 & Emp > 0]

# Compute separation rate
qwi[, sep_rate := fifelse(Emp > 0, Sep / Emp, NA_real_)]

# Filter: minimum employment threshold per cell (reduce noise)
qwi <- qwi[Emp >= 25]

cat(sprintf("After cleaning: %d rows, %d counties\n", nrow(qwi), uniqueN(qwi$fips_county)))

# ============================================================
# 3. Merge with MW panel
# ============================================================

qwi <- merge(qwi, mw_panel, by = c("statefip", "year"), all.x = TRUE)
cat(sprintf("After MW merge: %d rows, %d with OFW\n", nrow(qwi), sum(qwi$ofw, na.rm=TRUE)))

# Drop if MW merge failed
qwi <- qwi[!is.na(tipped_mw)]

# Log tipped MW for continuous treatment
qwi[, log_tipped_mw := log(tipped_mw)]

# ============================================================
# 4. Construct state-year-race panel (for primary analysis)
# ============================================================

# Aggregate to state-year-race (weighted by employment)
state_yr_race <- qwi[, .(
  earn_avg = weighted.mean(earn_avg, Emp, na.rm = TRUE),
  sep_rate = weighted.mean(sep_rate, Emp, na.rm = TRUE),
  total_emp = sum(Emp, na.rm = TRUE),
  n_counties = uniqueN(fips_county)
), by = .(statefip, year, quarter, race, race_label, ofw, tipped_mw, regular_mw, tipped_ratio, log_tipped_mw)]

cat(sprintf("State-quarter-race panel: %d rows\n", nrow(state_yr_race)))

# Create state-year panel (annual, for DiD)
state_yr_race_annual <- qwi[, .(
  earn_avg = weighted.mean(earn_avg, Emp, na.rm = TRUE),
  sep_rate = weighted.mean(sep_rate, Emp, na.rm = TRUE),
  total_emp = sum(Emp, na.rm = TRUE),
  n_counties = uniqueN(fips_county)
), by = .(statefip, year, race, race_label, ofw, tipped_mw, regular_mw, tipped_ratio, log_tipped_mw)]

cat(sprintf("State-year-race panel (annual): %d rows\n", nrow(state_yr_race_annual)))

# ============================================================
# 5. Construct county-quarter-race panel
# ============================================================

county_panel <- qwi[, .(
  earn_avg = earn_avg,
  sep_rate = sep_rate,
  Emp = Emp,
  fips_county = fips_county,
  statefip = statefip,
  year = year,
  quarter = quarter,
  yq = yq,
  race = race,
  race_label = race_label,
  ofw = ofw,
  tipped_mw = tipped_mw,
  log_tipped_mw = log_tipped_mw,
  tipped_ratio = tipped_ratio
)]

# Black indicator
county_panel[, black := as.integer(race == "A2")]

cat(sprintf("County panel: %d rows, %d counties\n", nrow(county_panel), uniqueN(county_panel$fips_county)))

# ============================================================
# 6. Clean placebo data
# ============================================================
qwi_placebo[, yq := year + (quarter - 1) / 4]
qwi_placebo[, race_label := fifelse(race == "A1", "White", "Black")]
qwi_placebo <- qwi_placebo[!is.na(earn_avg) & !is.na(Emp) & earn_avg > 0 & Emp > 0]
qwi_placebo[, sep_rate := fifelse(Emp > 0, Sep / Emp, NA_real_)]
qwi_placebo <- qwi_placebo[Emp >= 25]

qwi_placebo <- merge(qwi_placebo, mw_panel, by = c("statefip", "year"), all.x = TRUE)
qwi_placebo <- qwi_placebo[!is.na(tipped_mw)]
qwi_placebo[, log_tipped_mw := log(tipped_mw)]
qwi_placebo[, black := as.integer(race == "A2")]

cat(sprintf("Placebo panel: %d rows\n", nrow(qwi_placebo)))

# ============================================================
# 7. Summary statistics
# ============================================================

cat("\n=== Summary: OFW vs Tip-Credit States ===\n")
summ <- state_yr_race_annual[, .(
  mean_earn = mean(earn_avg, na.rm=TRUE),
  mean_sep = mean(sep_rate, na.rm=TRUE),
  mean_emp = mean(total_emp, na.rm=TRUE),
  n_states = uniqueN(statefip),
  n_obs = .N
), by = .(ofw, race_label)]
print(summ[order(ofw, race_label)])

cat("\n=== Earnings Gap ===\n")
earn_gap <- dcast(state_yr_race_annual[, .(mean_earn = mean(earn_avg, na.rm=TRUE)), by = .(ofw, race_label)],
                  ofw ~ race_label, value.var = "mean_earn")
earn_gap[, gap := White - Black]
earn_gap[, gap_pct := (White - Black) / White * 100]
print(earn_gap)

cat("\n=== Separation Rate Gap ===\n")
sep_gap <- dcast(state_yr_race_annual[, .(mean_sep = mean(sep_rate, na.rm=TRUE)), by = .(ofw, race_label)],
                 ofw ~ race_label, value.var = "mean_sep")
sep_gap[, gap_pp := (Black - White) * 100]
print(sep_gap)

# ============================================================
# 8. Save cleaned data
# ============================================================

fwrite(state_yr_race, "data/state_quarter_race.csv")
fwrite(state_yr_race_annual, "data/state_year_race.csv")
fwrite(county_panel, "data/county_panel.csv")
fwrite(qwi_placebo, "data/placebo_panel.csv")

cat("\nCleaned data saved.\n")
