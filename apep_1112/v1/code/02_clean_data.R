## 02_clean_data.R — Construct analysis panel
## APEP-1112: The Alliance Ratchet
##
## From the filtered DB1B data, constructs a route-quarter panel with:
## - Treatment indicator: NEA routes (both B6 and AA present pre-NEA)
## - Period indicators: formation and dissolution
## - Route-level aggregates: avg fare, passengers, HHI, carrier counts

source("00_packages.R")

## ---- Load data ----
db1b <- readRDS("../data/db1b_nea_airports.rds")
cat(sprintf("Loaded %s ticket-level observations\n", format(nrow(db1b), big.mark = ",")))

## ---- Create time variable ----
db1b[, time_q := Year + (Quarter - 1) / 4]
db1b[, yq := sprintf("%dQ%d", Year, Quarter)]

## ---- Define directional route ----
## Route = ordered Origin-Dest pair
db1b[, route := paste(Origin, Dest, sep = "-")]

## ---- Identify NEA carriers ----
## B6 = JetBlue, AA = American Airlines
db1b[, is_b6 := OpCarrier == "B6" | TkCarrier == "B6"]
db1b[, is_aa := OpCarrier == "AA" | TkCarrier == "AA"]

## ---- Identify NEA airports ----
nea_airports <- c("JFK", "LGA", "BOS", "EWR")
db1b[, origin_nea := Origin %in% nea_airports]
db1b[, dest_nea := Dest %in% nea_airports]
db1b[, has_nea_endpoint := origin_nea | dest_nea]

## ---- Pre-NEA period: Q1 2018 - Q4 2020 ----
pre_nea <- db1b[Year >= 2018 & (Year < 2021 | (Year == 2020 & Quarter <= 4))]

## Identify routes where both B6 and AA operated pre-NEA
## A route is "NEA-eligible" if both carriers had passengers on it in >=2 pre-NEA quarters
route_carrier_presence <- pre_nea[, .(
  b6_quarters = sum(is_b6),
  aa_quarters = sum(is_aa),
  total_pax = sum(Passengers)
), by = route]

## NEA treatment: routes where both B6 and AA operated (at least some tickets)
## Require at least some presence from each
nea_routes <- route_carrier_presence[b6_quarters >= 50 & aa_quarters >= 50, route]
cat(sprintf("NEA treatment routes: %d\n", length(nea_routes)))

## ---- Treatment assignment ----
db1b[, treated := as.integer(route %in% nea_routes)]

## ---- Period indicators ----
## Pre-NEA: Q1 2018 - Q4 2020
## Formation: Q1 2021 - Q2 2023 (NEA active)
## Dissolution: Q3 2023 onwards (court ruling May 2023, JB terminated July 2023)
db1b[, period := fcase(
  Year < 2021, "pre",
  Year == 2021 | Year == 2022 | (Year == 2023 & Quarter <= 2), "formation",
  default = "dissolution"
)]
db1b[, formation := as.integer(period == "formation")]
db1b[, dissolution := as.integer(period == "dissolution")]

## ---- Create numeric quarter index (relative to Q4 2020 = 0) ----
db1b[, q_index := (Year - 2020) * 4 + Quarter - 4]
## Q1 2018 = -11, Q4 2020 = 0, Q1 2021 = 1, Q3 2023 = 11, Q4 2024 = 16

## ---- Aggregate to route-quarter panel ----
cat("Constructing route-quarter panel...\n")

panel <- db1b[, .(
  avg_fare = weighted.mean(MktFare, Passengers),
  med_fare = median(rep(MktFare, Passengers)),
  log_avg_fare = log(weighted.mean(MktFare, Passengers)),
  total_pax = sum(Passengers),
  n_tickets = .N,
  avg_distance = weighted.mean(MktMilesFlown, Passengers),
  ## Fare per mile
  avg_fare_per_mile = weighted.mean(MktFare / pmax(MktMilesFlown, 1), Passengers),
  ## Price dispersion: coefficient of variation
  fare_cv = sd(rep(MktFare, pmin(Passengers, 10))) / mean(rep(MktFare, pmin(Passengers, 10))),
  ## Carrier concentration
  n_carriers = uniqueN(OpCarrier),
  ## HHI (based on passenger shares of operating carriers)
  hhi = {
    shares <- .SD[, .(pax = sum(Passengers)), by = OpCarrier][, pax / sum(pax)]
    sum(shares^2) * 10000
  },
  ## JetBlue and AA presence
  b6_share = sum(Passengers[is_b6]) / sum(Passengers),
  aa_share = sum(Passengers[is_aa]) / sum(Passengers),
  ## Nonstop share
  nonstop_share = sum(Passengers[MktCoupons == 1]) / sum(Passengers)
), by = .(route, Year, Quarter, yq, time_q, q_index,
          treated, period, formation, dissolution)]

cat(sprintf("Panel: %s route-quarter observations\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("  Routes: %d (%d treated, %d control)\n",
            uniqueN(panel$route),
            uniqueN(panel$route[panel$treated == 1]),
            uniqueN(panel$route[panel$treated == 0])))

## ---- Log fare ----
panel[, log_fare := log(avg_fare)]
panel[, log_med_fare := log(med_fare)]
panel[, log_pax := log(total_pax + 1)]

## ---- Require routes to appear in at least 3 pre-NEA quarters ----
pre_count <- panel[period == "pre", .N, by = route]
valid_routes <- pre_count[N >= 3, route]
panel <- panel[route %in% valid_routes]
cat(sprintf("After requiring >=3 pre-NEA quarters: %s obs, %d routes\n",
            format(nrow(panel), big.mark = ","), uniqueN(panel$route)))

## ---- Create route numeric ID for FE ----
panel[, route_id := as.integer(factor(route))]

## ---- Summary ----
cat("\n=== Panel Summary ===\n")
cat(sprintf("Observations: %s\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("Routes: %d (%d treated, %d control)\n",
            uniqueN(panel$route),
            uniqueN(panel$route[panel$treated == 1]),
            uniqueN(panel$route[panel$treated == 0])))
cat(sprintf("Quarters: %d (Q%d %d to Q%d %d)\n",
            uniqueN(panel$yq),
            min(panel$Quarter[panel$Year == min(panel$Year)]),
            min(panel$Year),
            max(panel$Quarter[panel$Year == max(panel$Year)]),
            max(panel$Year)))
cat(sprintf("Pre-NEA quarters: %d\n", uniqueN(panel$yq[panel$period == "pre"])))
cat(sprintf("Formation quarters: %d\n", uniqueN(panel$yq[panel$period == "formation"])))
cat(sprintf("Dissolution quarters: %d\n", uniqueN(panel$yq[panel$period == "dissolution"])))
cat(sprintf("\nMean fare (treated, pre): $%.0f\n",
            mean(panel$avg_fare[panel$treated == 1 & panel$period == "pre"])))
cat(sprintf("Mean fare (control, pre): $%.0f\n",
            mean(panel$avg_fare[panel$treated == 0 & panel$period == "pre"])))

## ---- Save ----
saveRDS(panel, "../data/analysis_panel.rds")
cat("\nSaved analysis panel to data/analysis_panel.rds\n")
