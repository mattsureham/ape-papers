## 02_clean_data.R — Construct analysis panel
source("00_packages.R")

cat("=== Cleaning SNAP Policy Data ===\n")

snap <- fread("../data/snap_policy_raw.csv")
cat("SNAP policy data:", nrow(snap), "rows\n")
cat("Columns:", paste(names(snap), collapse = ", "), "\n")

## Identify the time variable — SNAP Policy Database uses yearmonth or date_m
## Check what time variables exist
time_cols <- names(snap)[grepl("year|month|date|yrmo|period", tolower(names(snap)))]
cat("Time-related columns:", paste(time_cols, collapse = ", "), "\n")

## The SNAP Policy Database typically has state_fips + yearmonth
## Standardize column names to lowercase
setnames(snap, tolower(names(snap)))

## Print unique values of reportsimple
cat("reportsimple values:", paste(sort(unique(snap$reportsimple)), collapse = ", "), "\n")
cat("reportsimple distribution:\n")
print(table(snap$reportsimple, useNA = "always"))

## --- Construct adoption date for each state ---
## reportsimple = 1 means simplified reporting is in effect
## We need the first month each state switches to 1

## First, figure out the date structure
if ("yearmonth" %in% names(snap)) {
  snap[, year := as.integer(substr(yearmonth, 1, 4))]
  snap[, month := as.integer(substr(yearmonth, 5, 6))]
} else if ("date_m" %in% names(snap)) {
  snap[, year := as.integer(substr(date_m, 1, 4))]
  snap[, month := as.integer(substr(date_m, 5, 6))]
} else if (all(c("year", "month") %in% names(snap))) {
  snap[, year := as.integer(year)]
  snap[, month := as.integer(month)]
} else {
  ## Check for a numeric date column
  cat("Looking for date column...\n")
  for (col in names(snap)) {
    uvals <- head(unique(snap[[col]]), 5)
    cat(col, ":", paste(uvals, collapse=", "), "\n")
  }
  stop("Cannot identify time variable")
}

snap[, reportsimple := as.integer(reportsimple)]

## Use state_fips as the state identifier
if ("state_fips" %in% names(snap)) {
  snap[, state_fips := sprintf("%02d", as.integer(state_fips))]
} else if ("statefips" %in% names(snap)) {
  setnames(snap, "statefips", "state_fips")
  snap[, state_fips := sprintf("%02d", as.integer(state_fips))]
}

## Find first month of simplified reporting for each state
adoption <- snap[reportsimple == 1,
                 .(adopt_year = min(year),
                   adopt_month = month[which.min(year * 12 + month)]),
                 by = state_fips]

## Convert to quarter
adoption[, adopt_quarter := ceiling(adopt_month / 3)]
adoption[, cohort_yq := adopt_year + (adopt_quarter - 1) / 4]

## States that never adopted (or adopted after 2020)
all_states <- unique(snap$state_fips)
never_treated <- setdiff(all_states, adoption$state_fips)
cat("\nAdoption summary:\n")
cat("States that adopted simplified reporting:", nrow(adoption), "\n")
cat("Never-treated states:", length(never_treated), "\n")
if (length(never_treated) > 0) {
  cat("Never-treated FIPS:", paste(never_treated, collapse = ", "), "\n")
}

cat("\nAdoption year distribution:\n")
print(table(adoption$adopt_year))

fwrite(adoption, "../data/snap_adoption_dates.csv")

## Also get state names for later
state_names <- unique(snap[, .(state_fips, statename)])
if ("statename" %in% names(snap)) {
  state_names <- unique(snap[, .(state_fips, statename)])
} else if ("state_pc" %in% names(snap)) {
  state_names <- unique(snap[, .(state_fips, state_pc)])
  setnames(state_names, "state_pc", "statename")
}
fwrite(state_names, "../data/state_names.csv")

## === QWI Data ===
cat("\n=== Cleaning QWI Data ===\n")

qwi <- fread("../data/qwi_state_education.csv")
cat("QWI data:", nrow(qwi), "rows\n")

## Ensure proper types
qwi[, state := sprintf("%02d", as.integer(state))]
qwi[, year := as.integer(year)]
qwi[, quarter := as.integer(quarter)]

## Create year-quarter variable
qwi[, yq := year + (quarter - 1) / 4]

## Merge adoption dates
panel <- merge(qwi, adoption, by.x = "state", by.y = "state_fips", all.x = TRUE)

## Never-treated states: set cohort_yq to Inf (for did package)
panel[is.na(cohort_yq), cohort_yq := 0]  # 0 = never-treated in did package
panel[is.na(adopt_year), adopt_year := 9999]

## Create treatment indicator
panel[, treated := as.integer(adopt_year < 9999 & yq >= cohort_yq)]

## Create education labels
panel[, ed_label := factor(education,
  levels = c("E1", "E2", "E3", "E4"),
  labels = c("Less than HS", "HS/GED", "Some College", "Bachelor's+")
)]

## Create numeric time index (quarters since 2000Q1)
panel[, time_idx := (year - 2000) * 4 + quarter]

## Summary statistics
cat("\nPanel summary:\n")
cat("Observations:", nrow(panel), "\n")
cat("States:", uniqueN(panel$state), "\n")
cat("Education levels:", paste(unique(panel$education), collapse = ", "), "\n")
cat("Year range:", min(panel$year), "-", max(panel$year), "\n")
cat("Treated observations:", sum(panel$treated, na.rm = TRUE), "\n")

## Low-education subsample (E1 + E2)
panel_low <- panel[education %in% c("E1", "E2")]
cat("\nLow-education panel:", nrow(panel_low), "rows\n")
cat("Mean turnover rate:", mean(panel_low$TurnOvrS, na.rm = TRUE), "\n")
cat("Mean hires:", mean(panel_low$HirA, na.rm = TRUE), "\n")

## High-education subsample (E4) — placebo
panel_high <- panel[education == "E4"]
cat("High-education panel:", nrow(panel_high), "rows\n")

## Save
fwrite(panel, "../data/panel_full.csv")
fwrite(panel_low, "../data/panel_low_education.csv")
fwrite(panel_high, "../data/panel_high_education.csv")

cat("\n=== Data cleaning complete ===\n")
