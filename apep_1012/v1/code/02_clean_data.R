# 02_clean_data.R — Construct analysis panel
# Ban the Box and the Black Employment Gap (apep_1012)

source("00_packages.R")

qwi <- fread("../data/qwi_county_race.csv")

# ============================================================
# BTB treatment assignment
# ============================================================
# Private-employer Ban-the-Box adoption dates (year, quarter)
btb_states <- data.table(
  state_fips = c(25L, 15L, 27L, 44L, 17L, 11L, 34L, 41L, 50L, 9L, 6L, 32L, 53L, 8L, 36L, 24L),
  state_abbr = c("MA", "HI", "MN", "RI", "IL", "DC", "NJ", "OR", "VT", "CT", "CA", "NV", "WA", "CO", "NY", "MD"),
  btb_year   = c(2010L, 2010L, 2013L, 2014L, 2014L, 2014L, 2015L, 2016L, 2016L, 2017L, 2018L, 2018L, 2018L, 2019L, 2020L, 2020L),
  btb_quarter = c(3L, 3L, 1L, 1L, 3L, 4L, 1L, 1L, 3L, 1L, 1L, 1L, 2L, 3L, 1L, 1L)
)
btb_states[, btb_time_id := (btb_year - 2005) * 4 + btb_quarter]

# Merge treatment info
qwi <- merge(qwi, btb_states[, .(state_fips, btb_year, btb_quarter, btb_time_id)],
             by = "state_fips", all.x = TRUE)

# Treatment indicators
qwi[, treated_state := !is.na(btb_year)]
qwi[, post_btb := fifelse(treated_state & time_id >= btb_time_id, 1L, 0L)]
qwi[, black := fifelse(race == "A2", 1L, 0L)]

# Cohort variable for CS-DiD (treatment timing; 0 for never-treated)
qwi[, cohort := fifelse(treated_state, btb_time_id, 0L)]

# ============================================================
# Drop counties with excessive missingness or suppressed cells
# ============================================================
# Keep only counties with both Black and White data in at least 80% of quarters
county_coverage <- qwi[, .(
  n_quarters = uniqueN(time_id),
  n_white = sum(race == "A1" & !is.na(Emp) & Emp > 0),
  n_black = sum(race == "A2" & !is.na(Emp) & Emp > 0)
), by = county_fips]

max_q <- max(county_coverage$n_quarters)
threshold <- 0.8 * max_q

good_counties <- county_coverage[n_white >= threshold & n_black >= threshold]$county_fips
message(sprintf("Counties with sufficient coverage: %d of %d (%.0f%%)",
                length(good_counties), uniqueN(qwi$county_fips),
                100 * length(good_counties) / uniqueN(qwi$county_fips)))

qwi <- qwi[county_fips %in% good_counties]

# ============================================================
# Construct outcome variables
# ============================================================
# Log employment and hiring flows
for (v in c("Emp", "HirA", "HirN", "EmpS")) {
  qwi[, (paste0("ln_", tolower(v))) := log(get(v) + 1)]
}

# ============================================================
# Reshape to county-quarter panel with Black/White side by side
# ============================================================
# For the triple-diff, keep the long form (county × race × quarter)
# Also create the ratio form for event studies

# Wide form for ratios
qwi_wide <- dcast(qwi, county_fips + state_fips + year + quarter + time_id +
                    treated_state + post_btb + cohort + btb_year + btb_quarter + btb_time_id ~ race,
                  value.var = c("Emp", "HirA", "HirN", "EmpS", "EarnS"),
                  fun.aggregate = sum, fill = NA)

# Black/White employment ratio
qwi_wide[, bw_emp_ratio := Emp_A2 / Emp_A1]
qwi_wide[, bw_hira_ratio := HirA_A2 / HirA_A1]
qwi_wide[, bw_hirn_ratio := HirN_A2 / HirN_A1]
qwi_wide[, bw_emps_ratio := EmpS_A2 / EmpS_A1]

# Remove infinite/missing ratios
for (v in c("bw_emp_ratio", "bw_hira_ratio", "bw_hirn_ratio", "bw_emps_ratio")) {
  qwi_wide[is.infinite(get(v)) | is.nan(get(v)), (v) := NA]
}

# ============================================================
# Event time variable
# ============================================================
qwi_wide[, event_time := fifelse(treated_state, time_id - btb_time_id, NA_integer_)]

# ============================================================
# Summary
# ============================================================
message(sprintf("Final long panel: %s rows, %d counties, %d states",
                format(nrow(qwi), big.mark = ","), uniqueN(qwi$county_fips), uniqueN(qwi$state_fips)))
message(sprintf("Final wide panel: %s rows", format(nrow(qwi_wide), big.mark = ",")))
message(sprintf("Treated counties: %d in %d states",
                uniqueN(qwi[treated_state == TRUE]$county_fips),
                uniqueN(btb_states$state_fips)))
message(sprintf("Control counties: %d",
                uniqueN(qwi[treated_state == FALSE]$county_fips)))

# ============================================================
# Save
# ============================================================
fwrite(qwi, "../data/analysis_long.csv")
fwrite(qwi_wide, "../data/analysis_wide.csv")
message("Saved analysis_long.csv and analysis_wide.csv")
