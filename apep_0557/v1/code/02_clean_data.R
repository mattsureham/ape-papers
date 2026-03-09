## ============================================================
## 02_clean_data.R — Build state x month panel
## Paper: Does Foreign Aid Buffer Oil Revenue Shocks?
##        Geocoded Evidence from Nigeria
## ============================================================

source("00_packages.R")

DATA_DIR <- "../data"

## ============================================================
## 1) Load raw data
## ============================================================

projects     <- readRDS(file.path(DATA_DIR, "aiddata_projects.rds"))
locations    <- readRDS(file.path(DATA_DIR, "aiddata_locations.rds"))
transactions <- readRDS(file.path(DATA_DIR, "aiddata_transactions.rds"))
conflict     <- readRDS(file.path(DATA_DIR, "ucdp_nigeria.rds"))
oil_monthly  <- fread(file.path(DATA_DIR, "oil_monthly.csv"))

cat(sprintf("Loaded: %d projects, %d locations, %s conflict events\n",
            nrow(projects), nrow(locations),
            format(nrow(conflict), big.mark = ",")))

## Canonical Nigerian states (36 states + FCT = 37)
valid_states <- c(
  "Abia", "Adamawa", "Akwa Ibom", "Anambra", "Bauchi", "Bayelsa",
  "Benue", "Borno", "Cross River", "Delta", "Ebonyi", "Edo",
  "Ekiti", "Enugu", "Federal Capital Territory", "Gombe", "Imo",
  "Jigawa", "Kaduna", "Kano", "Katsina", "Kebbi", "Kogi", "Kwara",
  "Lagos", "Nasarawa", "Niger", "Ogun", "Ondo", "Osun", "Oyo",
  "Plateau", "Rivers", "Sokoto", "Taraba", "Yobe", "Zamfara"
)

## ============================================================
## 2) Extract state from AidData geocoded locations
## ============================================================

cat("\n--- Extracting states from AidData locations ---\n")

## gazetteer_adm_name format: "Earth|Africa|Nigeria|State Name"
locations[, state_raw := {
  parts <- strsplit(gazetteer_adm_name, "\\|")
  sapply(parts, function(p) {
    if (length(p) >= 4) trimws(p[4]) else NA_character_
  })
}]

## Clean state names
locations[, state := gsub('"', '', state_raw)]
locations[, state := gsub("\\s+State$", "", state)]
locations[, state := trimws(state)]

## Filter to precision <= 4 (at least admin1 level)
loc_geocoded <- locations[precision_code <= 4 & !is.na(state) & state != ""]

cat(sprintf("Geocoded locations (precision <= 4): %d of %d total\n",
            nrow(loc_geocoded), nrow(locations)))
cat(sprintf("States in AidData: %d\n", uniqueN(loc_geocoded$state)))

## ============================================================
## 3) Build state-level aid exposure measures
## ============================================================

cat("\n--- Building state-level aid exposure ---\n")

## Merge locations with project info
loc_proj <- merge(loc_geocoded, projects,
                  by = "project_id", all.x = TRUE)

## Parse project start dates
loc_proj[, start_date := as.Date(start_actual_isodate)]
loc_proj[, start_year := year(start_date)]
loc_proj[is.na(start_year), start_year := as.integer(transactions_start_year)]

## Merge with transactions to get commitment values
trans_agg <- transactions[, .(
  total_value = sum(as.numeric(transaction_value), na.rm = TRUE)
), by = project_id]

loc_proj <- merge(loc_proj, trans_agg, by = "project_id", all.x = TRUE)

loc_proj[, commitment := fifelse(
  !is.na(total_value) & total_value > 0,
  total_value,
  as.numeric(gsub("[^0-9.]", "", total_commitments))
)]
loc_proj[is.na(commitment), commitment := 0]

cat(sprintf("Projects with start_year: %d of %d\n",
            sum(!is.na(loc_proj$start_year)), nrow(loc_proj)))

## Filter to valid states only
loc_proj <- loc_proj[state %in% valid_states]
cat(sprintf("After filtering to valid states: %d location-project rows\n",
            nrow(loc_proj)))

## Build cumulative aid exposure by state x year
years <- 1989:2014
states_aid <- valid_states

## Count projects started in each state-year
aid_by_state_year <- loc_proj[!is.na(start_year), .(
  n_projects_started = uniqueN(project_id),
  total_commitment   = sum(commitment, na.rm = TRUE)
), by = .(state, start_year)]

## Create state x year grid
state_year <- CJ(state = states_aid, year = years)

## Cumulative projects by state-year
state_year[, cum_projects := {
  sapply(year, function(y) {
    sum(aid_by_state_year[state == .BY$state & start_year <= y,
                           n_projects_started])
  })
}, by = state]

state_year[, cum_commitment := {
  sapply(year, function(y) {
    sum(aid_by_state_year[state == .BY$state & start_year <= y,
                           total_commitment])
  })
}, by = state]

## New projects per year
state_year <- merge(state_year,
  aid_by_state_year[, .(new_projects = sum(n_projects_started)),
                    by = .(state, year = start_year)],
  by = c("state", "year"), all.x = TRUE)
state_year[is.na(new_projects), new_projects := 0]

cat("\nAid exposure by state (as of Dec 2007, pre-shock):\n")
pre_shock_aid <- state_year[year == 2007,
  .(state, cum_projects, cum_commitment)][order(-cum_projects)]
print(pre_shock_aid[1:15])

## Sector breakdown from projects
cat("\nAid sectors:\n")
print(loc_proj[, .N, by = ad_sector_names][order(-N)][1:10])

## ============================================================
## 4) Clean UCDP GED and aggregate to state x month
## ============================================================

cat("\n--- Aggregating UCDP conflict data to state x month ---\n")

## Clean admin1 names in UCDP
conflict[, state := gsub("\\s+State$", "", admin1)]
conflict[, state := trimws(state)]

## Create year-month variable
conflict[, ym := floor_date(event_date, "month")]

## Aggregate to state x month
conflict_sm <- conflict[!is.na(state) & state != "" & !is.na(ym), .(
  n_events      = .N,
  n_state_based = sum(type_of_violence == 1, na.rm = TRUE),
  n_non_state   = sum(type_of_violence == 2, na.rm = TRUE),
  n_one_sided   = sum(type_of_violence == 3, na.rm = TRUE),
  fatalities    = sum(best_est, na.rm = TRUE),
  fatalities_hi = sum(high_est, na.rm = TRUE),
  fatalities_lo = sum(low_est, na.rm = TRUE),
  civ_deaths    = sum(deaths_civ, na.rm = TRUE)
), by = .(state, ym)]

cat(sprintf("Conflict state-months: %d (%d states, %d months)\n",
            nrow(conflict_sm),
            uniqueN(conflict_sm$state),
            uniqueN(conflict_sm$ym)))

## National monthly totals
national_monthly <- conflict[!is.na(ym), .(
  n_events   = .N,
  fatalities = sum(best_est, na.rm = TRUE)
), by = ym]

## ============================================================
## 5) Harmonize state names between UCDP and AidData
## ============================================================

cat("\n--- Harmonizing state names ---\n")

## UCDP uses "Borno state" format; AidData uses "Borno" format
## Standardize UCDP: remove " state" suffix, fix capitalization
conflict_sm[, state := gsub("\\s+state$", "", state, ignore.case = TRUE)]
conflict_sm[, state := trimws(state)]
conflict_sm[state == "Federal Capital territory", state := "Federal Capital Territory"]

## Filter AidData to valid states only (drop geocoding artifacts like
## "Agbede", "Ajara", "Dar es Salaam Region", etc.)
aid_invalid <- setdiff(unique(state_year$state), valid_states)
if (length(aid_invalid) > 0) {
  cat(sprintf("Dropping %d non-state AidData entries: %s\n",
              length(aid_invalid), paste(aid_invalid, collapse = ", ")))
  state_year <- state_year[state %in% valid_states]
}

## Handle UCDP historical state "Gongola" (split into Adamawa + Taraba in 1991)
conflict_sm[state == "Gongola", state := "Adamawa"]

## Filter UCDP to valid states
conflict_sm <- conflict_sm[state %in% valid_states]

## Check coverage
ucdp_states <- sort(unique(conflict_sm$state))
aid_states  <- sort(unique(state_year$state))

matched <- intersect(ucdp_states, aid_states)
cat(sprintf("Matched states: %d\n", length(matched)))
cat(sprintf("UCDP states: %d, AidData states: %d\n",
            length(ucdp_states), length(aid_states)))

## Use the canonical 37 valid states as the panel universe
all_states <- valid_states
cat(sprintf("Panel states: %d\n", length(all_states)))

## ============================================================
## 6) Build the analysis panel
## ============================================================

cat("\n--- Building state x month analysis panel ---\n")

## Use UCDP data range: 1989-2023 but focus on 1997-2014
## (1997: Brent oil price data starts; 2014: AidData ends)
all_months <- seq(as.Date("1997-01-01"), as.Date("2014-12-01"), by = "month")
panel_grid <- CJ(state = all_states, ym = all_months)

## Merge conflict outcomes
panel <- merge(panel_grid, conflict_sm, by = c("state", "ym"), all.x = TRUE)

## Fill missing months with zeros (no events = no conflict)
conflict_cols <- c("n_events", "n_state_based", "n_non_state", "n_one_sided",
                   "fatalities", "fatalities_hi", "fatalities_lo", "civ_deaths")
for (col in conflict_cols) {
  panel[is.na(get(col)), (col) := 0L]
}

## Add year for merging
panel[, year := year(ym)]

## Merge cumulative aid exposure
panel <- merge(panel, state_year[, .(state, year, cum_projects,
                                      cum_commitment, new_projects)],
               by = c("state", "year"), all.x = TRUE)
panel[is.na(cum_projects), cum_projects := 0]
panel[is.na(cum_commitment), cum_commitment := 0]
panel[is.na(new_projects), new_projects := 0]

## Pre-determined aid exposure (as of Dec 2007 — before oil crash)
pre_aid <- state_year[year == 2007, .(state,
  aid_projects_2007 = cum_projects,
  aid_commit_2007 = cum_commitment)]
panel <- merge(panel, pre_aid, by = "state", all.x = TRUE)
panel[is.na(aid_projects_2007), aid_projects_2007 := 0]
panel[is.na(aid_commit_2007), aid_commit_2007 := 0]

## Merge oil prices
oil_monthly[, ym := as.Date(ym)]
panel <- merge(panel, oil_monthly, by = "ym", all.x = TRUE)

## ============================================================
## 7) Define treatment and shock variables
## ============================================================

cat("\n--- Defining treatment and shock variables ---\n")

## Oil shock: September 2008 (Lehman collapse, oil crashes from $100+ to $40)
panel[, post_shock := as.integer(ym >= as.Date("2008-09-01"))]

## Event time (months relative to Sep 2008)
panel[, event_time := as.integer(
  round(difftime(ym, as.Date("2008-09-01"), units = "days") / 30.44)
)]

## Log outcomes
panel[, log_events := log(n_events + 1)]
panel[, log_state_based := log(n_state_based + 1)]
panel[, log_non_state := log(n_non_state + 1)]
panel[, log_one_sided := log(n_one_sided + 1)]
panel[, log_fatalities := log(fatalities + 1)]
panel[, log_civ_deaths := log(civ_deaths + 1)]

## Log aid exposure
panel[, log_aid := log(aid_projects_2007 + 1)]
panel[, log_aid_commit := log(aid_commit_2007 + 1)]

## Binary treatment (above median aid projects as of 2007)
med_aid <- median(unique(panel[, .(state, aid_projects_2007)])$aid_projects_2007)
panel[, high_aid := as.integer(aid_projects_2007 > med_aid)]

## DiD interactions
panel[, aid_x_post := aid_projects_2007 * post_shock]
panel[, log_aid_x_post := log_aid * post_shock]
panel[, high_aid_x_post := high_aid * post_shock]

## Oil-producing states (Niger Delta region)
oil_states <- c("Rivers", "Delta", "Bayelsa", "Akwa Ibom", "Edo",
                "Ondo", "Abia", "Imo", "Anambra")
panel[, oil_state := as.integer(state %in% oil_states)]

## Fixed effect IDs
panel[, state_id := as.integer(factor(state))]
panel[, ym_id := as.integer(factor(ym))]
panel[, year_id := as.integer(factor(year))]

## ============================================================
## 8) Summary statistics and save
## ============================================================

cat("\n=== PANEL SUMMARY ===\n")
cat(sprintf("Observations: %d\n", nrow(panel)))
cat(sprintf("States: %d\n", uniqueN(panel$state)))
cat(sprintf("Months: %d (%s to %s)\n",
            uniqueN(panel$ym), min(panel$ym), max(panel$ym)))
cat(sprintf("Pre-shock obs: %d\n", sum(panel$post_shock == 0)))
cat(sprintf("Post-shock obs: %d\n", sum(panel$post_shock == 1)))

unique_states <- unique(panel[, .(state, aid_projects_2007)])
cat(sprintf("\nAid exposure (pre-determined, Dec 2007):\n"))
cat(sprintf("  Mean projects: %.1f\n", mean(unique_states$aid_projects_2007)))
cat(sprintf("  Median projects: %.0f\n", med_aid))
cat(sprintf("  States with any aid: %d\n",
            sum(unique_states$aid_projects_2007 > 0)))
cat(sprintf("  States with high aid (above median): %d\n",
            sum(unique_states$aid_projects_2007 > med_aid)))

cat(sprintf("\nConflict (monthly, per state):\n"))
cat(sprintf("  Mean events: %.3f\n", mean(panel$n_events)))
cat(sprintf("  Mean fatalities: %.3f\n", mean(panel$fatalities)))
cat(sprintf("  Total events: %d\n", sum(panel$n_events)))

## Save analysis-ready panel
fwrite(panel, file.path(DATA_DIR, "analysis_panel.csv"))
saveRDS(panel, file.path(DATA_DIR, "analysis_panel.rds"))

## Save summary statistics
sumstats <- panel[, .(
  mean_events      = mean(n_events),
  sd_events        = sd(n_events),
  mean_log_events  = mean(log_events),
  sd_log_events    = sd(log_events),
  mean_fatalities  = mean(fatalities),
  sd_fatalities    = sd(fatalities),
  mean_log_fatal   = mean(log_fatalities),
  sd_log_fatal     = sd(log_fatalities),
  mean_aid_proj    = mean(aid_projects_2007),
  sd_aid_proj      = sd(aid_projects_2007),
  pct_high_aid     = mean(high_aid),
  mean_oil_price   = mean(oil_price, na.rm = TRUE)
)]
fwrite(sumstats, file.path(DATA_DIR, "summary_statistics.csv"))

## State-level summary
state_summary <- panel[, .(
  mean_events      = mean(n_events),
  total_events     = sum(n_events),
  mean_fatalities  = mean(fatalities),
  total_fatalities = sum(fatalities),
  aid_projects     = first(aid_projects_2007),
  aid_commitment   = first(aid_commit_2007),
  oil_producing    = first(oil_state)
), by = state][order(-aid_projects)]
fwrite(state_summary, file.path(DATA_DIR, "state_summary.csv"))

## National monthly time series
national_ts <- panel[, .(
  total_events     = sum(n_events),
  total_fatalities = sum(fatalities),
  total_state_based = sum(n_state_based),
  total_non_state  = sum(n_non_state),
  mean_oil_price   = first(oil_price)
), by = ym]
fwrite(national_ts, file.path(DATA_DIR, "national_monthly.csv"))

cat("\nData cleaning complete.\n")
