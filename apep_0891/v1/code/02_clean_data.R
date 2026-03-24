## 02_clean_data.R — Construct analysis panel
## SNAP EA Expiration and Eviction Filings

source("00_packages.R")

data_dir <- "../data"
ets_raw  <- readRDS(file.path(data_dir, "ets_raw.rds"))
acs_df   <- readRDS(file.path(data_dir, "acs_tract.rds"))
ea_all   <- readRDS(file.path(data_dir, "ea_dates.rds"))

## ═══════════════════════════════════════════════════════════════════
## 1. Clean ETS data
## ═══════════════════════════════════════════════════════════════════
cat("Cleaning ETS data...\n")

## Keep tract-level observations only
ets <- ets_raw[type == "Census Tract"]
cat("Tract-level rows:", nrow(ets), "\n")

## Extract state FIPS from GEOID (first 2 digits of 11-digit tract FIPS)
ets[, state_fips := substr(GEOID, 1, 2)]

## Map state FIPS to abbreviation
fips_to_abbr <- c(
  "01"="AL","02"="AK","04"="AZ","05"="AR","06"="CA","08"="CO","09"="CT",
  "10"="DE","11"="DC","12"="FL","13"="GA","15"="HI","16"="ID","17"="IL",
  "18"="IN","19"="IA","20"="KS","21"="KY","22"="LA","23"="ME","24"="MD",
  "25"="MA","26"="MI","27"="MN","28"="MS","29"="MO","30"="MT","31"="NE",
  "32"="NV","33"="NH","34"="NJ","35"="NM","36"="NY","37"="NC","38"="ND",
  "39"="OH","40"="OK","41"="OR","42"="PA","44"="RI","45"="SC","46"="SD",
  "47"="TN","48"="TX","49"="UT","50"="VT","51"="VA","53"="WA","54"="WV",
  "55"="WI","56"="WY"
)
ets[, state_abbr := fips_to_abbr[state_fips]]

cat("States in ETS data:", paste(sort(unique(ets$state_abbr)), collapse = ", "), "\n")

## Rename filings column (filings_2020 = current filings count despite legacy name)
setnames(ets, "filings_2020", "filings", skip_absent = TRUE)

## Ensure week_date is Date
ets[, week_date := as.Date(week_date)]

## ═══════════════════════════════════════════════════════════════════
## 2. Merge EA treatment dates
## ═══════════════════════════════════════════════════════════════════
cat("\nMerging EA treatment dates...\n")

ets <- merge(ets, ea_all[, c("state", "ea_end_date", "early_optout", "treat_cohort")],
             by.x = "state_abbr", by.y = "state", all.x = TRUE)

## Drop tracts with no state match (shouldn't happen)
ets <- ets[!is.na(ea_end_date)]

## Create treatment indicator: 1 if EA has ended in this state by this week
ets[, treated := as.integer(week_date >= ea_end_date)]

## Treatment timing for CS estimator: cohort = first week where treated
## For CS, we need a group variable = the period when treatment turns on
## Convert ea_end_date to a week number in the panel
week_ref <- min(ets$week_date)
ets[, treat_week := as.integer(difftime(ea_end_date, week_ref, units = "weeks")) + 1L]

## For never-/late-treated (control), set treat_week to 0 (CS convention)
## We use "not-yet-treated" as controls: late states are treated in March 2023
## For the pre-March-2023 analysis window, they serve as controls
## But we should restrict the analysis window to avoid late states' treatment
ets[, treat_week_cs := fifelse(early_optout, treat_week, 0L)]

cat("Early opt-out tracts:", length(unique(ets[early_optout == TRUE, GEOID])), "\n")
cat("Control tracts:", length(unique(ets[early_optout == FALSE, GEOID])), "\n")

## ═══════════════════════════════════════════════════════════════════
## 3. Merge ACS tract characteristics
## ═══════════════════════════════════════════════════════════════════
cat("\nMerging ACS demographics...\n")

## ACS GEOID is 11-digit (state+county+tract)
acs_merge <- acs_df[, .(geoid, snap_rate, renter_rate, median_income,
                         total_pop, pct_black, pct_hispanic,
                         renter_units = B25003_003E)]

ets <- merge(ets, acs_merge, by.x = "GEOID", by.y = "geoid", all.x = TRUE)

## How many tracts matched?
matched <- sum(!is.na(ets$snap_rate))
cat("ACS match rate:", round(matched / nrow(ets) * 100, 1), "%\n")

## ═══════════════════════════════════════════════════════════════════
## 4. Construct analysis variables
## ═══════════════════════════════════════════════════════════════════
cat("\nConstructing analysis variables...\n")

## Filing rate per 1000 renter-occupied units
ets[, filing_rate := fifelse(renter_units > 0, filings / renter_units * 1000, NA_real_)]

## SNAP participation quartiles (for heterogeneity)
ets[, snap_quartile := cut(snap_rate,
                            breaks = quantile(snap_rate, probs = c(0, 0.25, 0.5, 0.75, 1),
                                              na.rm = TRUE),
                            labels = c("Q1_low", "Q2", "Q3", "Q4_high"),
                            include.lowest = TRUE)]

## Income quartiles (for placebo)
ets[, income_quartile := cut(median_income,
                              breaks = quantile(median_income,
                                                probs = c(0, 0.25, 0.5, 0.75, 1),
                                                na.rm = TRUE),
                              labels = c("Q1_low", "Q2", "Q3", "Q4_high"),
                              include.lowest = TRUE)]

## ═══════════════════════════════════════════════════════════════════
## 5. Restrict analysis window
## ═══════════════════════════════════════════════════════════════════
cat("\nRestricting analysis window...\n")

## Window: January 2020 (week ~2) through February 2023 (before national termination)
## This gives us:
## - ~16 months pre-treatment for Wave 1 (Jan 2020 - Mar 2021)
## - ~8 months pre-treatment for Wave 2 (Jan 2020 - Jun 2021)
## - ~20+ months post-treatment for early states
## Late states remain untreated throughout this window

ets_panel <- ets[week_date >= as.Date("2020-01-01") &
                   week_date < as.Date("2023-03-01")]

cat("Analysis panel:", nrow(ets_panel), "tract-weeks\n")
cat("  Tracts:", length(unique(ets_panel$GEOID)), "\n")
cat("  Weeks:", length(unique(ets_panel$week)), "\n")
cat("  States:", length(unique(ets_panel$state_abbr)), "\n")
cat("  Date range:", as.character(min(ets_panel$week_date)), "to",
    as.character(max(ets_panel$week_date)), "\n")

## Drop tracts with zero renter units or all-missing filings
ets_panel <- ets_panel[renter_units > 0 & !is.na(filing_rate)]
cat("After dropping zero-renter tracts:", nrow(ets_panel), "rows\n")

## ═══════════════════════════════════════════════════════════════════
## 6. Create monthly aggregation for CS estimator
## ═══════════════════════════════════════════════════════════════════
cat("\nCreating monthly panel for CS estimator...\n")

ets_panel[, year_month := floor_date(week_date, "month")]
ets_panel[, month_num := as.integer(difftime(year_month, min(year_month), units = "days")) %/% 30 + 1L]

## Monthly aggregation by tract
monthly <- ets_panel[, .(
  filings = sum(filings, na.rm = TRUE),
  filing_rate = mean(filing_rate, na.rm = TRUE),
  weeks_in_month = .N
), by = .(GEOID, state_abbr, year_month, month_num,
          treat_week_cs, early_optout, ea_end_date,
          snap_rate, renter_rate, median_income, total_pop,
          pct_black, pct_hispanic, renter_units,
          snap_quartile, income_quartile)]

## Treatment timing in months for CS
monthly[, treat_month := as.integer(difftime(ea_end_date, min(year_month), units = "days")) %/% 30 + 1L]
monthly[, treat_month_cs := fifelse(early_optout, treat_month, 0L)]

## Post indicator
monthly[, post := as.integer(year_month >= ea_end_date)]

cat("Monthly panel:", nrow(monthly), "tract-months\n")
cat("  Tracts:", length(unique(monthly$GEOID)), "\n")
cat("  Months:", length(unique(monthly$month_num)), "\n")

## ═══════════════════════════════════════════════════════════════════
## 7. Summary statistics
## ═══════════════════════════════════════════════════════════════════
cat("\n=== PANEL SUMMARY ===\n")

## By treatment group
summ_by_group <- monthly[, .(
  tracts = length(unique(GEOID)),
  mean_filings = mean(filings, na.rm = TRUE),
  mean_filing_rate = mean(filing_rate, na.rm = TRUE),
  mean_snap_rate = mean(snap_rate, na.rm = TRUE),
  mean_renter_rate = mean(renter_rate, na.rm = TRUE),
  mean_income = mean(median_income, na.rm = TRUE),
  mean_pct_black = mean(pct_black, na.rm = TRUE)
), by = early_optout]

cat("\nBy treatment group:\n")
print(summ_by_group)

## Save analysis panels
saveRDS(ets_panel, file.path(data_dir, "ets_panel_weekly.rds"))
saveRDS(monthly, file.path(data_dir, "ets_panel_monthly.rds"))

cat("\nPanel construction complete.\n")
