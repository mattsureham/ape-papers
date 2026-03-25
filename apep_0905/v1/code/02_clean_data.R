## 02_clean_data.R — Construct route-month panel with treatment intensity
## apep_0905: Argentina Aviation Deregulation

source("00_packages.R")

data_dir <- "../data"

## ---- Load domestic flights ----
df <- fread(file.path(data_dir, "domestic_flights.csv"))
cat("Loaded domestic flights:", nrow(df), "rows\n")

## ---- Create route identifier (undirected: alphabetically sorted city pair) ----
df[, city_A := pmin(origen_localidad, destino_localidad)]
df[, city_B := pmax(origen_localidad, destino_localidad)]
df[, route := paste(city_A, city_B, sep = " - ")]

## ---- Aggregate to route x airline x month ----
df[, ym := floor_date(as.Date(indice_tiempo), "month")]

route_airline_month <- df[, .(
  passengers = sum(pasajeros, na.rm = TRUE),
  seats      = sum(asientos, na.rm = TRUE),
  flights    = sum(vuelos, na.rm = TRUE)
), by = .(route, aerolinea, ym)]

cat("Route-airline-month cells:", nrow(route_airline_month), "\n")

## ---- Compute pre-decree HHI (2023 calendar year) ----
# HHI = sum of squared market shares (passenger-based) per route
pre_period <- route_airline_month[ym >= "2023-01-01" & ym <= "2023-12-31"]

route_airline_pax_2023 <- pre_period[, .(pax_2023 = sum(passengers)), by = .(route, aerolinea)]
route_total_2023 <- route_airline_pax_2023[, .(total_pax = sum(pax_2023)), by = route]
route_airline_pax_2023 <- merge(route_airline_pax_2023, route_total_2023, by = "route")
route_airline_pax_2023[, share := pax_2023 / total_pax]
route_airline_pax_2023[, share_sq := share^2]

hhi_2023 <- route_airline_pax_2023[, .(
  hhi_pre  = sum(share_sq) * 10000,
  n_carriers_2023 = .N,
  total_pax_2023 = total_pax[1]
), by = route]

cat("\nHHI distribution (2023):\n")
print(summary(hhi_2023$hhi_pre))
cat("Monopoly routes (HHI = 10000):", sum(hhi_2023$hhi_pre == 10000), "\n")
cat("Competed routes (HHI < 10000):", sum(hhi_2023$hhi_pre < 10000), "\n")

## ---- Aggregate to route x month panel ----
panel <- df[, .(
  passengers = sum(pasajeros, na.rm = TRUE),
  seats      = sum(asientos, na.rm = TRUE),
  flights    = sum(vuelos, na.rm = TRUE),
  n_airlines = uniqueN(aerolinea)
), by = .(route, ym)]

## ---- Compute load factor ----
panel[, load_factor := ifelse(seats > 0, passengers / seats, NA_real_)]

## ---- Merge HHI treatment intensity ----
panel <- merge(panel, hhi_2023, by = "route", all.x = TRUE)

# Drop routes not active in 2023 (no HHI baseline)
panel <- panel[!is.na(hhi_pre)]
cat("\nRoutes with 2023 HHI baseline:", uniqueN(panel$route), "\n")

## ---- Create treatment variables ----
panel[, post := as.integer(ym >= as.Date("2024-07-01"))]
panel[, monopoly := as.integer(hhi_pre == 10000)]
panel[, hhi_norm := hhi_pre / 10000]  # Normalized 0-1

## ---- Create event-time variable ----
panel[, event_time := as.integer(difftime(ym, as.Date("2024-07-01"), units = "days")) %/% 30]
# More precise: months since July 2024
panel[, event_month := (year(ym) - 2024) * 12 + (month(ym) - 7)]

## ---- Create log outcomes ----
panel[, log_pax := log(passengers + 1)]
panel[, log_seats := log(seats + 1)]
panel[, log_flights := log(flights + 1)]

## ---- Route characteristics for heterogeneity ----
# Buenos Aires hub routes (origin or destination is Buenos Aires area)
ba_cities <- c("Buenos Aires", "Ciudad Autónoma de Buenos Aires")
panel[, route_parts := strsplit(route, " - ")]
panel[, is_ba_route := sapply(route_parts, function(x) any(x %in% ba_cities))]
panel[, route_parts := NULL]

# Route size terciles based on 2023 traffic
route_size <- panel[ym >= "2023-01-01" & ym <= "2023-12-31",
                    .(annual_pax = sum(passengers)), by = route]
route_size[, size_tercile := cut(annual_pax,
                                  breaks = quantile(annual_pax, probs = c(0, 1/3, 2/3, 1)),
                                  labels = c("Small", "Medium", "Large"),
                                  include.lowest = TRUE)]
panel <- merge(panel, route_size[, .(route, size_tercile, annual_pax)], by = "route", all.x = TRUE)

## ---- Balance panel (fill missing route-months with zeros) ----
all_routes <- unique(panel$route)
all_months <- seq(as.Date("2017-01-01"), as.Date("2026-01-01"), by = "month")
skeleton <- CJ(route = all_routes, ym = all_months)

panel <- merge(skeleton, panel, by = c("route", "ym"), all.x = TRUE)

# Fill missing with zeros for outcome variables
panel[is.na(passengers), passengers := 0]
panel[is.na(seats), seats := 0]
panel[is.na(flights), flights := 0]
panel[is.na(n_airlines), n_airlines := 0]
panel[is.na(load_factor) & seats == 0, load_factor := 0]
panel[, log_pax := log(passengers + 1)]
panel[, log_seats := log(seats + 1)]
panel[, log_flights := log(flights + 1)]

# Fill treatment variables from route-level info
panel[, post := as.integer(ym >= as.Date("2024-07-01"))]
route_info <- hhi_2023[, .(route, hhi_pre, n_carriers_2023, total_pax_2023)]
panel[is.na(hhi_pre), c("hhi_pre", "n_carriers_2023", "total_pax_2023") :=
        merge(.SD[, .(route)], route_info, by = "route", all.x = TRUE)[,
              .(hhi_pre, n_carriers_2023, total_pax_2023)]]
panel[, monopoly := as.integer(hhi_pre == 10000)]
panel[, hhi_norm := hhi_pre / 10000]
panel[, event_month := (year(ym) - 2024) * 12 + (month(ym) - 7)]

# Fill route characteristics
panel <- merge(panel[, !c("size_tercile", "annual_pax"), with = FALSE],
               route_size[, .(route, size_tercile, annual_pax)], by = "route", all.x = TRUE)

## ---- Create route numeric ID for FE ----
panel[, route_id := as.integer(as.factor(route))]
panel[, month_id := as.integer(as.factor(ym))]

## ---- Summary statistics ----
cat("\n=== PANEL SUMMARY ===\n")
cat("Routes:", uniqueN(panel$route), "\n")
cat("Months:", uniqueN(panel$ym), "\n")
cat("Observations:", nrow(panel), "\n")
cat("Monopoly routes:", sum(hhi_2023$hhi_pre == 10000), "\n")
cat("Competed routes:", sum(hhi_2023$hhi_pre < 10000), "\n")
cat("Date range:", as.character(range(panel$ym)), "\n")
cat("Pre-treatment months:", sum(unique(panel$ym) < as.Date("2024-07-01")), "\n")
cat("Post-treatment months:", sum(unique(panel$ym) >= as.Date("2024-07-01")), "\n")

## ---- COVID indicator ----
panel[, covid := as.integer(ym >= as.Date("2020-03-01") & ym <= as.Date("2021-12-31"))]

## ---- Save panel ----
fwrite(panel, file.path(data_dir, "route_month_panel.csv"))
cat("\nSaved route_month_panel.csv:", nrow(panel), "rows\n")

cat("\n02_clean_data.R complete.\n")
