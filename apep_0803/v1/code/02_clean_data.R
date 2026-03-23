## 02_clean_data.R — Variable construction for apep_0803
## Who Gets the New Jobs? Medicaid Expansion and Racial Employment in Healthcare

source("00_packages.R")

data_dir <- "../data/"

cat("=== DATA CLEANING START ===\n")

## ─────────────────────────────────────────────────────────
## 1. Load raw data
## ─────────────────────────────────────────────────────────
qwi <- fread(file.path(data_dir, "qwi_healthcare_race.csv"))
## Create Medicaid expansion dates (KFF State Health Facts)
expansion <- data.table(
  state = c("AZ","AR","CA","CO","CT","DE","DC","HI","IL","IN",
            "IA","KY","MD","MA","MI","MN","MT","NV","NH","NJ",
            "NM","NY","ND","OH","OR","PA","RI","VT","WA","WV",
            "AK","LA","VA","ME","ID","UT","NE","OK","MO","SD",
            "TX","GA","FL","WI","NC","SC","TN","AL","MS","WY","KS"),
  expansion_year = c(
    2014L,2014L,2014L,2014L,2014L,2014L,2014L,2014L,2014L,2015L,
    2014L,2014L,2014L,2014L,2014L,2014L,2016L,2014L,2014L,2014L,
    2014L,2014L,2014L,2014L,2014L,2015L,2014L,2014L,2014L,2014L,
    2015L,2016L,2019L,2019L,2020L,2020L,2020L,2021L,2021L,2023L,
    NA_integer_,NA_integer_,NA_integer_,NA_integer_,NA_integer_,
    NA_integer_,NA_integer_,NA_integer_,NA_integer_,NA_integer_,NA_integer_)
)

## Create state FIPS crosswalk
state_fips <- data.table(
  state_fips = sprintf("%02d", c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,
                                  21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,
                                  36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,
                                  53,54,55,56)),
  state = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID",
            "IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO",
            "MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA",
            "RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
)
qwi_retail <- fread(file.path(data_dir, "qwi_retail_race.csv"))
qwi_total <- fread(file.path(data_dir, "qwi_total_race.csv"))

cat(sprintf("  Healthcare: %d rows\n", nrow(qwi)))
cat(sprintf("  Retail placebo: %d rows\n", nrow(qwi_retail)))
cat(sprintf("  Total employment: %d rows\n", nrow(qwi_total)))

## ─────────────────────────────────────────────────────────
## 2. Add state identifier from county FIPS
## ─────────────────────────────────────────────────────────
qwi[, state_fips := sprintf("%02d", as.integer(fips) %/% 1000L)]
qwi_retail[, state_fips := sprintf("%02d", as.integer(fips) %/% 1000L)]
qwi_total[, state_fips := sprintf("%02d", as.integer(fips) %/% 1000L)]

## Merge state abbreviation
qwi <- merge(qwi, state_fips, by = "state_fips", all.x = TRUE)
qwi_retail <- merge(qwi_retail, state_fips, by = "state_fips", all.x = TRUE)
qwi_total <- merge(qwi_total, state_fips, by = "state_fips", all.x = TRUE)

## ─────────────────────────────────────────────────────────
## 3. Merge Medicaid expansion dates
## ─────────────────────────────────────────────────────────
qwi <- merge(qwi, expansion[, .(state, expansion_year)], by = "state", all.x = TRUE)
qwi_retail <- merge(qwi_retail, expansion[, .(state, expansion_year)], by = "state", all.x = TRUE)

## Treatment indicator
qwi[, expanded := !is.na(expansion_year)]
qwi[, post := fifelse(expanded & year >= expansion_year, 1L, 0L)]
qwi[, time_to_treat := fifelse(expanded, year - expansion_year, NA_integer_)]

qwi_retail[, expanded := !is.na(expansion_year)]
qwi_retail[, post := fifelse(expanded & year >= expansion_year, 1L, 0L)]

## ─────────────────────────────────────────────────────────
## 4. Focus on key race groups and clean
## ─────────────────────────────────────────────────────────
## QWI race codes: A0=All, A1=White, A2=Black, A3=AIAN, A4=Asian, A7=Two+
## Ethnicity: A0=All, A1=Non-Hispanic, A2=Hispanic

## Keep race-specific rows with ethnicity = All (A0)
## This avoids double-counting
qwi_race <- qwi[ethnicity == "A0" & race %in% c("A1", "A2", "A4")]
qwi_all <- qwi[race == "A0" & ethnicity == "A0"]

## Also create Hispanic panel (all races, Hispanic ethnicity)
qwi_hisp <- qwi[race == "A0" & ethnicity == "A2"]

cat(sprintf("  Race-specific panel (White/Black/Asian): %d rows\n", nrow(qwi_race)))
cat(sprintf("  All-race panel: %d rows\n", nrow(qwi_all)))
cat(sprintf("  Hispanic panel: %d rows\n", nrow(qwi_hisp)))

## Label race groups
qwi_race[, race_label := fcase(
  race == "A1", "White",
  race == "A2", "Black",
  race == "A4", "Asian"
)]

## ─────────────────────────────────────────────────────────
## 5. Aggregate to state × year × quarter × race
## ─────────────────────────────────────────────────────────
## Sum county-level employment to state level
state_race <- qwi_race[, .(
  emp = sum(emp, na.rm = TRUE),
  emp_end = sum(emp_end, na.rm = TRUE),
  hires = sum(hires_all, na.rm = TRUE),
  hires_new = sum(hires_new, na.rm = TRUE),
  separations = sum(separations, na.rm = TRUE),
  n_counties = .N
), by = .(state, state_fips, year, quarter, race, race_label, expansion_year, expanded, post, time_to_treat)]

state_all <- qwi_all[, .(
  emp = sum(emp, na.rm = TRUE),
  emp_end = sum(emp_end, na.rm = TRUE),
  hires = sum(hires_all, na.rm = TRUE),
  separations = sum(separations, na.rm = TRUE)
), by = .(state, state_fips, year, quarter, expansion_year, expanded, post, time_to_treat)]

## Retail placebo at state × quarter level
retail_all <- qwi_retail[race == "A0" & ethnicity == "A0", .(
  emp_retail = sum(emp, na.rm = TRUE),
  hires_retail = sum(hires_all, na.rm = TRUE)
), by = .(state, state_fips, year, quarter, expansion_year, expanded, post)]

## ─────────────────────────────────────────────────────────
## 6. Create time variable and race-specific measures
## ─────────────────────────────────────────────────────────
## Year-quarter numeric
state_race[, yq := year + (quarter - 1) / 4]
state_all[, yq := year + (quarter - 1) / 4]

## Log employment
state_race[emp > 0, log_emp := log(emp)]
state_all[emp > 0, log_emp := log(emp)]

## Healthcare employment share of total
## (Will be constructed after merge with total employment)

## ─────────────────────────────────────────────────────────
## 7. Construct DDD panel: Black vs White × Expansion
## ─────────────────────────────────────────────────────────
## Wide format: one row per state × year × quarter with White and Black employment
ddd <- dcast(state_race[race %in% c("A1", "A2")],
             state + state_fips + year + quarter + yq + expansion_year + expanded + post + time_to_treat ~
               race_label,
             value.var = c("emp", "hires", "separations"),
             fill = 0)

## Black-White employment gap (log ratio)
ddd[emp_White > 0 & emp_Black > 0, log_gap := log(emp_Black) - log(emp_White)]
ddd[emp_White > 0 & emp_Black > 0, black_share := emp_Black / (emp_Black + emp_White)]
ddd[hires_White > 0 & hires_Black > 0, hires_gap := log(hires_Black) - log(hires_White)]

## Cohort assignment for CS estimator (year of expansion, 0 for never-treated)
state_race[, cohort := fifelse(expanded, expansion_year, 0L)]
state_all[, cohort := fifelse(expanded, expansion_year, 0L)]
ddd[, cohort := fifelse(expanded, expansion_year, 0L)]

## ─────────────────────────────────────────────────────────
## 8. Summary statistics
## ─────────────────────────────────────────────────────────
cat("\n--- Summary Statistics ---\n")
cat(sprintf("  States: %d (expanded: %d, control: %d)\n",
    length(unique(state_race$state)),
    length(unique(state_race[expanded == TRUE]$state)),
    length(unique(state_race[expanded == FALSE]$state))))

cat(sprintf("  Years: %d-%d\n", min(state_race$year), max(state_race$year)))
cat(sprintf("  Quarters: %d\n", length(unique(paste(state_race$year, state_race$quarter)))))

## Pre-expansion (2013) baseline by race
baseline <- state_race[year == 2013, .(total_emp = sum(emp, na.rm = TRUE)), by = race_label]
cat("  Baseline healthcare employment (2013):\n")
print(baseline)

## ─────────────────────────────────────────────────────────
## 9. Save analysis-ready datasets
## ─────────────────────────────────────────────────────────
fwrite(state_race, file.path(data_dir, "panel_state_race.csv"))
fwrite(state_all, file.path(data_dir, "panel_state_all.csv"))
fwrite(ddd, file.path(data_dir, "panel_ddd.csv"))
fwrite(retail_all, file.path(data_dir, "panel_retail.csv"))

cat("\n=== DATA CLEANING COMPLETE ===\n")
cat(sprintf("  panel_state_race.csv: %d rows\n", nrow(state_race)))
cat(sprintf("  panel_state_all.csv: %d rows\n", nrow(state_all)))
cat(sprintf("  panel_ddd.csv: %d rows\n", nrow(ddd)))
cat(sprintf("  panel_retail.csv: %d rows\n", nrow(retail_all)))
