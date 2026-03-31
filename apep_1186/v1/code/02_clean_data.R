## 02_clean_data.R — Construct crossing-year panel
## apep_1186: Railroad Quiet Zones and Crossing Safety

source("00_packages.R")

## ---------------------------------------------------------------
## 1. Load raw data
## ---------------------------------------------------------------
inv <- fread("../data/fra_inventory_raw.csv")
acc <- fread("../data/fra_accidents_raw.csv")

cat("Raw inventory:", nrow(inv), "rows\n")
cat("Raw accidents:", nrow(acc), "rows\n")

## ---------------------------------------------------------------
## 2. Clean inventory
## ---------------------------------------------------------------
## Key variables
inv[, `:=`(
  crossing_id = crossingid,
  state_fips  = as.integer(statecode),
  county_fips = as.integer(countycode),
  aadt        = as.numeric(annualaveragedailytrafficcount),
  trains_day  = as.numeric(totaldaylightthrutrains),
  trains_night = as.numeric(totalnighttimethrutrains),
  trains_switch = as.numeric(totalswitchingtrains),
  trains_pass = as.numeric(numberpassengertrainperday),
  max_speed   = as.numeric(maximumtimetablespeed),
  has_gates   = as.integer(countroadwaygatearms > 0),
  n_lanes     = as.numeric(trafficlane),
  lat         = as.numeric(latitude),
  lon         = as.numeric(longitude),
  is_closed   = (crossingclosed == "Yes"),
  on_state_hwy = (crossingonstatehighwaysystem == "Yes")
)]

## Total trains per day
inv[, total_trains := trains_day + trains_night + trains_switch + trains_pass]

## Quiet zone treatment
inv[, `:=`(
  qz_24hr     = (whistleban == "24 hr"),
  qz_partial  = (whistleban == "Partial"),
  qz_chicago  = (whistleban == "Chicago Excused"),
  qz_date     = as.Date(whistledate, format = "%Y-%m-%d")
)]

## Treatment year (year quiet zone was established)
inv[, qz_year := as.integer(format(qz_date, "%Y"))]

cat("\nQuiet zone crossings:\n")
cat("  24hr:", sum(inv$qz_24hr, na.rm = TRUE), "\n")
cat("  Partial:", sum(inv$qz_partial, na.rm = TRUE), "\n")
cat("  Chicago:", sum(inv$qz_chicago, na.rm = TRUE), "\n")
cat("\nQZ year distribution:\n")
print(table(inv$qz_year, useNA = "ifany"))

## ---------------------------------------------------------------
## 3. Clean accidents — aggregate to crossing-year
## ---------------------------------------------------------------
acc[, `:=`(
  crossing_id = gxid,
  year        = as.integer(year4),
  killed      = as.numeric(totkld),
  injured     = as.numeric(totinj),
  incidents   = as.numeric(totocc),
  user_killed = as.numeric(userkld),
  user_injured = as.numeric(userinj)
)]

## Drop records with missing crossing ID or year
acc <- acc[!is.na(crossing_id) & crossing_id != "" & !is.na(year)]

## Aggregate to crossing-year level
acc_cy <- acc[, .(
  accidents    = .N,
  total_killed = sum(killed, na.rm = TRUE),
  total_injured = sum(injured, na.rm = TRUE),
  user_killed  = sum(user_killed, na.rm = TRUE),
  user_injured = sum(user_injured, na.rm = TRUE)
), by = .(crossing_id, year)]

cat("\nAccident-crossing-year obs:", nrow(acc_cy), "\n")
cat("Year range:", range(acc_cy$year), "\n")

## ---------------------------------------------------------------
## 4. Construct balanced crossing-year panel
## ---------------------------------------------------------------
## Focus: public, non-closed crossings with valid coordinates
panel_inv <- inv[!is.na(lat) & !is.na(lon) & is_closed == FALSE]

cat("\nPanel inventory (open, geocoded):", nrow(panel_inv), "\n")

## Create crossing-year panel: 1990-2024
years <- 1990:2024
panel <- CJ(crossing_id = panel_inv$crossing_id, year = years)

## Merge crossing characteristics (time-invariant from current snapshot)
panel <- merge(panel, panel_inv[, .(
  crossing_id, state_fips, county_fips, aadt, total_trains,
  max_speed, has_gates, n_lanes, lat, lon, on_state_hwy,
  qz_24hr, qz_date, qz_year
)], by = "crossing_id", all.x = TRUE)

## Merge accident counts
panel <- merge(panel, acc_cy, by = c("crossing_id", "year"), all.x = TRUE)

## Fill zeros for crossing-years with no accidents
for (v in c("accidents", "total_killed", "total_injured",
            "user_killed", "user_injured")) {
  set(panel, which(is.na(panel[[v]])), v, 0L)
}

## Treatment indicator
panel[, treated := as.integer(!is.na(qz_year) & year >= qz_year)]

## Any accident indicator (extensive margin)
panel[, any_accident := as.integer(accidents > 0)]
panel[, any_casualty := as.integer(total_killed + total_injured > 0)]

## ---------------------------------------------------------------
## 5. Sample restrictions for main analysis
## ---------------------------------------------------------------
## Focus on 24hr quiet zone crossings as treated, rest as control
## Drop crossings with QZ before 2000 (pre-rule) or partial/Chicago
panel[, treat_group := fifelse(qz_24hr == TRUE & qz_year >= 2000 & qz_year <= 2020,
                                qz_year, 0L)]
panel[is.na(treat_group), treat_group := 0L]

## Drop partial and Chicago excused crossings (ambiguous treatment)
partial_ids <- panel_inv[qz_partial == TRUE | qz_chicago == TRUE, crossing_id]
panel <- panel[!(crossing_id %in% partial_ids)]

cat("\nFinal panel:\n")
cat("  Rows:", nrow(panel), "\n")
cat("  Crossings:", uniqueN(panel$crossing_id), "\n")
cat("  Years:", min(panel$year), "-", max(panel$year), "\n")
cat("  Treated crossings:", uniqueN(panel[treat_group > 0, crossing_id]), "\n")
cat("  Never-treated crossings:", uniqueN(panel[treat_group == 0, crossing_id]), "\n")
cat("  Total accidents in panel:", sum(panel$accidents), "\n")
cat("  Total killed:", sum(panel$total_killed), "\n")

## ---------------------------------------------------------------
## 6. Save
## ---------------------------------------------------------------
fwrite(panel, "../data/panel.csv")

cat("\nPanel saved to data/panel.csv\n")
