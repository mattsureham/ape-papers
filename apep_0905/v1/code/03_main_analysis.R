## 03_main_analysis.R — Main DiD regressions
## apep_0905: Argentina Aviation Deregulation

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "route_month_panel.csv"))
cat("Panel loaded:", nrow(panel), "rows,", uniqueN(panel$route), "routes\n")

## ============================================================
## 1. Summary statistics
## ============================================================

# Pre vs post comparison for monopoly and competed routes
pre_data <- panel[post == 0 & ym >= "2022-01-01"]  # recent pre-period (avoid COVID)
post_data <- panel[post == 1]

summ_tab <- rbind(
  pre_data[monopoly == 1, .(
    Period = "Pre (2022-Jun 2024)", Group = "Monopoly",
    Mean_Pax = mean(passengers), SD_Pax = sd(passengers),
    Mean_Seats = mean(seats), Mean_Flights = mean(flights),
    Mean_LF = mean(load_factor[load_factor > 0], na.rm = TRUE),
    N_Routes = uniqueN(route), Obs = .N)],
  pre_data[monopoly == 0, .(
    Period = "Pre (2022-Jun 2024)", Group = "Competed",
    Mean_Pax = mean(passengers), SD_Pax = sd(passengers),
    Mean_Seats = mean(seats), Mean_Flights = mean(flights),
    Mean_LF = mean(load_factor[load_factor > 0], na.rm = TRUE),
    N_Routes = uniqueN(route), Obs = .N)],
  post_data[monopoly == 1, .(
    Period = "Post (Jul 2024-Jan 2026)", Group = "Monopoly",
    Mean_Pax = mean(passengers), SD_Pax = sd(passengers),
    Mean_Seats = mean(seats), Mean_Flights = mean(flights),
    Mean_LF = mean(load_factor[load_factor > 0], na.rm = TRUE),
    N_Routes = uniqueN(route), Obs = .N)],
  post_data[monopoly == 0, .(
    Period = "Post (Jul 2024-Jan 2026)", Group = "Competed",
    Mean_Pax = mean(passengers), SD_Pax = sd(passengers),
    Mean_Seats = mean(seats), Mean_Flights = mean(flights),
    Mean_LF = mean(load_factor[load_factor > 0], na.rm = TRUE),
    N_Routes = uniqueN(route), Obs = .N)]
)

cat("\n=== SUMMARY STATISTICS ===\n")
print(summ_tab)

## ============================================================
## 2. Main DiD: Binary treatment (monopoly vs competed)
## ============================================================

# Exclude COVID period for cleaner estimates (sensitivity with COVID included below)
panel_nocovid <- panel[covid == 0]

cat("\n=== MAIN DiD REGRESSIONS ===\n")

# (1) Log passengers
m1 <- feols(log_pax ~ monopoly:post | route_id + month_id,
            data = panel_nocovid, cluster = ~route)
cat("\nModel 1: Log passengers\n")
print(summary(m1))

# (2) Log seats
m2 <- feols(log_seats ~ monopoly:post | route_id + month_id,
            data = panel_nocovid, cluster = ~route)

# (3) Log flights
m3 <- feols(log_flights ~ monopoly:post | route_id + month_id,
            data = panel_nocovid, cluster = ~route)

# (4) Number of airlines serving route
m4 <- feols(n_airlines ~ monopoly:post | route_id + month_id,
            data = panel_nocovid, cluster = ~route)

# (5) Load factor (conditional on positive service)
m5 <- feols(load_factor ~ monopoly:post | route_id + month_id,
            data = panel_nocovid[seats > 0], cluster = ~route)

## ---- Print all results ----
cat("\n=== ALL MAIN RESULTS ===\n")
etable(m1, m2, m3, m4, m5,
       headers = c("Log Pax", "Log Seats", "Log Flights", "N Airlines", "Load Factor"),
       se.below = TRUE)

## ============================================================
## 3. Continuous treatment: HHI interaction
## ============================================================

cat("\n=== CONTINUOUS TREATMENT (HHI) ===\n")

m6 <- feols(log_pax ~ hhi_norm:post | route_id + month_id,
            data = panel_nocovid, cluster = ~route)
print(summary(m6))

m7 <- feols(log_seats ~ hhi_norm:post | route_id + month_id,
            data = panel_nocovid, cluster = ~route)

m8 <- feols(n_airlines ~ hhi_norm:post | route_id + month_id,
            data = panel_nocovid, cluster = ~route)

etable(m6, m7, m8,
       headers = c("Log Pax", "Log Seats", "N Airlines"),
       se.below = TRUE)

## ============================================================
## 4. Event study
## ============================================================

cat("\n=== EVENT STUDY ===\n")

# Trim event time: -36 to +18 months (3 years pre + 18 months post)
panel_es <- panel_nocovid[event_month >= -36 & event_month <= 18]
panel_es[, event_month_f := factor(event_month)]

# Reference period: t = -1 (June 2024)
es1 <- feols(log_pax ~ i(event_month, monopoly, ref = -1) | route_id + month_id,
             data = panel_es, cluster = ~route)

cat("Event study coefficients:\n")
print(summary(es1))

## ============================================================
## 5. Post-decree airline entry patterns
## ============================================================

# Load raw data for entry analysis
raw <- fread(file.path(data_dir, "domestic_flights.csv"))
raw[, city_A := pmin(origen_localidad, destino_localidad)]
raw[, city_B := pmax(origen_localidad, destino_localidad)]
raw[, route := paste(city_A, city_B, sep = " - ")]
raw[, ym := floor_date(as.Date(indice_tiempo), "month")]

# For each route-airline, find first month of service
first_service <- raw[, .(first_month = min(ym)), by = .(route, aerolinea)]

# New entrants after decree
new_entrants <- first_service[first_month >= as.Date("2024-07-01")]
cat("\n=== NEW ROUTE ENTRIES POST-DECREE ===\n")
cat("Total new route-airline entries:", nrow(new_entrants), "\n")

# Merge with HHI to see if entry targeted monopoly routes
hhi_2023 <- fread(file.path(data_dir, "route_month_panel.csv"))[,
  .(hhi_pre = hhi_pre[1], monopoly = monopoly[1]),
  by = route]
new_entrants <- merge(new_entrants, hhi_2023, by = "route", all.x = TRUE)

cat("Entries on monopoly routes:", sum(new_entrants$monopoly == 1, na.rm = TRUE), "\n")
cat("Entries on competed routes:", sum(new_entrants$monopoly == 0, na.rm = TRUE), "\n")
cat("Entries on brand-new routes:", sum(is.na(new_entrants$monopoly)), "\n")

cat("\nBy airline:\n")
print(new_entrants[, .N, by = aerolinea][order(-N)])

## ============================================================
## 6. Save results for tables
## ============================================================

# Save key objects
results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
  m6 = m6, m7 = m7, m8 = m8,
  es1 = es1,
  summ_tab = summ_tab,
  new_entrants = new_entrants
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

## ============================================================
## 7. Diagnostics for validator
## ============================================================

diag <- list(
  n_treated = uniqueN(panel$route[panel$monopoly == 1]),
  n_pre = sum(unique(panel$ym) < as.Date("2024-07-01")),
  n_obs = nrow(panel),
  n_routes = uniqueN(panel$route),
  n_monopoly = uniqueN(panel$route[panel$monopoly == 1]),
  n_competed = uniqueN(panel$route[panel$monopoly == 0])
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics written.\n")

cat("\n03_main_analysis.R complete.\n")
