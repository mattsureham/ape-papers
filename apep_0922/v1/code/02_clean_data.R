## 02_clean_data.R — Clean QCEW data and construct treatment variables
## APEP paper apep_0922: Alkaline Hydrolysis and Funeral Industry Competition

source("00_packages.R")

## ── Load raw data ────────────────────────────────────────────────────────────
raw <- readRDS("../data/qcew_raw.rds")
message(sprintf("Loaded raw data: %d rows", nrow(raw)))

## ── Treatment timing: state alkaline hydrolysis legalization ─────────────────
## Sources: manifest idea_1668 cross-referenced with state legislative records
treatment_map <- data.table(
  state_fips = c("27", "23", "41", "12", "20", "24", "08",
                 "13", "17", "47", "16", "50", "56",
                 "01", "06", "32", "37", "49",
                 "53", "40", "15", "04", "51"),
  state_abbr = c("MN", "ME", "OR", "FL", "KS", "MD", "CO",
                 "GA", "IL", "TN", "ID", "VT", "WY",
                 "AL", "CA", "NV", "NC", "UT",
                 "WA", "OK", "HI", "AZ", "VA"),
  legalization_year = c(2003L, 2009L, 2009L, 2010L, 2010L, 2011L, 2011L,
                        2012L, 2012L, 2013L, 2014L, 2014L, 2014L,
                        2017L, 2017L, 2017L, 2018L, 2018L,
                        2020L, 2021L, 2022L, 2022L, 2023L)
)

## ── State FIPS lookup (all 50 states + DC) ───────────────────────────────────
## Extract state FIPS from area_fips (first 2 characters for counties)
## State-level records have area_fips ending in "000"

## ── COUNTY-LEVEL PANEL (establishments) ──────────────────────────────────────
## agglvl_code 78 = County, 6-digit NAICS
county <- raw[agglvl_code == 78 & own_code == 5 & naics_code == "812210"]
county[, state_fips := substr(area_fips, 1, 2)]
county[, county_fips := area_fips]

## Merge treatment
county <- merge(county, treatment_map[, .(state_fips, legalization_year)],
                by = "state_fips", all.x = TRUE)
county[is.na(legalization_year), legalization_year := 0L]  # never-treated

## Treatment indicator
county[, treated := as.integer(legalization_year > 0 & year >= legalization_year)]

## Cohort variable for CS-DiD (group = first treatment year, 0 = never treated)
county[, cohort := legalization_year]

## Key outcome: establishment count (available even when employment suppressed)
county[, estabs := as.numeric(annual_avg_estabs)]

## Remove non-county areas that slipped through
county <- county[nchar(area_fips) == 5 & !grepl("000$", area_fips)]

## ── STATE-LEVEL PANEL (employment, wages) ────────────────────────────────────
## agglvl_code 58 = State, 6-digit NAICS
state_panel <- raw[agglvl_code == 58 & own_code == 5 & naics_code == "812210"]
state_panel[, state_fips := substr(area_fips, 1, 2)]

## Merge treatment
state_panel <- merge(state_panel, treatment_map[, .(state_fips, legalization_year)],
                     by = "state_fips", all.x = TRUE)
state_panel[is.na(legalization_year), legalization_year := 0L]

state_panel[, treated := as.integer(legalization_year > 0 & year >= legalization_year)]
state_panel[, cohort := legalization_year]

## Key outcomes (state-level, no suppression)
state_panel[, `:=`(
  employment = as.numeric(annual_avg_emplvl),
  avg_wkly_wage = as.numeric(annual_avg_wkly_wage),
  estabs = as.numeric(annual_avg_estabs),
  ln_empl = log(as.numeric(annual_avg_emplvl)),
  ln_wage = log(as.numeric(annual_avg_wkly_wage))
)]

## ── NAICS 812220 PANEL (Cemeteries/Crematories — substitution test) ──────────
county_220 <- raw[agglvl_code == 78 & own_code == 5 & naics_code == "812220"]
county_220[, state_fips := substr(area_fips, 1, 2)]
county_220[, county_fips := area_fips]
county_220 <- merge(county_220, treatment_map[, .(state_fips, legalization_year)],
                    by = "state_fips", all.x = TRUE)
county_220[is.na(legalization_year), legalization_year := 0L]
county_220[, treated := as.integer(legalization_year > 0 & year >= legalization_year)]
county_220[, cohort := legalization_year]
county_220[, estabs := as.numeric(annual_avg_estabs)]
county_220 <- county_220[nchar(area_fips) == 5 & !grepl("000$", area_fips)]

state_220 <- raw[agglvl_code == 58 & own_code == 5 & naics_code == "812220"]
state_220[, state_fips := substr(area_fips, 1, 2)]
state_220 <- merge(state_220, treatment_map[, .(state_fips, legalization_year)],
                   by = "state_fips", all.x = TRUE)
state_220[is.na(legalization_year), legalization_year := 0L]
state_220[, treated := as.integer(legalization_year > 0 & year >= legalization_year)]
state_220[, cohort := legalization_year]
state_220[, `:=`(
  employment = as.numeric(annual_avg_emplvl),
  estabs = as.numeric(annual_avg_estabs)
)]

## ── Summary statistics ───────────────────────────────────────────────────────
message("\n=== COUNTY PANEL (812210 — Funeral Homes) ===")
message(sprintf("Counties: %d | Years: %d-%d | Obs: %d",
                uniqueN(county$county_fips), min(county$year), max(county$year), nrow(county)))
message(sprintf("Treated states in window (2017-2023): %d",
                uniqueN(county[cohort >= 2017, state_fips])))
message(sprintf("Never-treated states: %d",
                uniqueN(county[cohort == 0, state_fips])))
message(sprintf("Establishment count: mean=%.1f, sd=%.1f, min=%d, max=%d",
                mean(county$estabs), sd(county$estabs),
                min(county$estabs), max(county$estabs)))

message("\n=== STATE PANEL (812210 — Funeral Homes) ===")
message(sprintf("States: %d | Years: %d-%d | Obs: %d",
                uniqueN(state_panel$state_fips), min(state_panel$year),
                max(state_panel$year), nrow(state_panel)))
message(sprintf("Employment: mean=%.0f, sd=%.0f",
                mean(state_panel$employment), sd(state_panel$employment)))
message(sprintf("Avg weekly wage: mean=$%.0f, sd=$%.0f",
                mean(state_panel$avg_wkly_wage), sd(state_panel$avg_wkly_wage)))

## ── Save cleaned data ────────────────────────────────────────────────────────
saveRDS(county, "../data/county_panel.rds")
saveRDS(state_panel, "../data/state_panel.rds")
saveRDS(county_220, "../data/county_panel_220.rds")
saveRDS(state_220, "../data/state_panel_220.rds")
message("\nCleaned data saved to data/")
