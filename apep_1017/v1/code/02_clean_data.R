# 02_clean_data.R — Construct analysis panel
# apep_1017: EU Fourth Railway Package and Rail Fares

source("00_packages.R")

cat("=== Loading raw data ===\n")
hicp <- readRDS("data/hicp_transport.rds")
rail_pax <- readRDS("data/rail_passengers.rds")
gdp <- readRDS("data/gdp_pc.rds")
transposition <- readRDS("data/transposition.rds")

# ---- 1. Reshape HICP to wide by transport mode ----
cat("Building monthly country panel...\n")

# Keep only observations from 2015 onward (index base year = 2015)
hicp <- hicp[year >= 2015]

# Create wide panel: one row per country-month
fare_panel <- dcast(hicp, geo + date + year + month + ym ~ coicop,
                    value.var = "values", fun.aggregate = mean)

# Rename columns
if ("CP0731" %in% names(fare_panel)) setnames(fare_panel, "CP0731", "rail_fare")
if ("CP0732" %in% names(fare_panel)) setnames(fare_panel, "CP0732", "road_fare")
if ("CP0733" %in% names(fare_panel)) setnames(fare_panel, "CP0733", "air_fare")

cat("Panel dimensions:", nrow(fare_panel), "rows,", uniqueN(fare_panel$geo), "countries\n")
cat("Date range:", as.character(min(fare_panel$date)), "to", as.character(max(fare_panel$date)), "\n")

# ---- 2. Merge transposition treatment ----
fare_panel <- merge(fare_panel, transposition[, .(geo, transposition_date, cohort, treat_ym)],
                    by = "geo", all.x = TRUE)

# Post-treatment indicator
fare_panel[, post := fifelse(date >= transposition_date, 1L, 0L)]

# For Callaway-Sant'Anna: first_treat = first treated period (as numeric ym)
# Countries with no transposition date are "never-treated" (shouldn't happen here
# since all EU countries transposed, but we use not-yet-treated as controls)
fare_panel[, first_treat := treat_ym]

# Create numeric time index for CS estimator (months since Jan 2015)
fare_panel[, time_idx := (year - 2015) * 12 + month]

# Create numeric country ID
fare_panel[, country_id := as.integer(factor(geo))]

# ---- 3. Log transform ----
fare_panel[, log_rail := log(rail_fare)]
fare_panel[, log_road := log(road_fare)]
fare_panel[, log_air := log(air_fare)]

# ---- 4. Merge GDP control (annual, interpolated to monthly) ----
fare_panel <- merge(fare_panel, gdp, by = c("geo", "year"), all.x = TRUE)
# Forward-fill GDP within country
setorder(fare_panel, geo, date)
fare_panel[, gdp_pc := nafill(gdp_pc, type = "locf"), by = geo]

# ---- 5. Pre-treatment summary statistics ----
cat("\n=== Pre-treatment summary (2015-2018) ===\n")
pre <- fare_panel[year >= 2015 & year <= 2018]

cat("\nRail fare index:\n")
print(summary(pre$rail_fare))
cat("\nRoad fare index:\n")
print(summary(pre$road_fare))
cat("\nAir fare index:\n")
print(summary(pre$air_fare))

# Pre-treatment SD of rail fares (for SDE calculation)
pre_sd_rail <- sd(pre$rail_fare, na.rm = TRUE)
pre_sd_log_rail <- sd(pre$log_rail, na.rm = TRUE)
cat("\nPre-treatment SD(rail_fare):", round(pre_sd_rail, 3), "\n")
cat("Pre-treatment SD(log_rail):", round(pre_sd_log_rail, 3), "\n")

# Store for later use
saveRDS(list(sd_rail = pre_sd_rail, sd_log_rail = pre_sd_log_rail),
        "data/pre_treatment_stats.rds")

# ---- 6. Check balance ----
cat("\n=== Panel balance check ===\n")
balance <- fare_panel[!is.na(rail_fare), .(n_months = .N), by = .(geo, cohort)]
cat("Countries with rail data:\n")
print(balance[order(cohort, geo)])

# ---- 7. Create quarterly aggregation for passenger-km analysis ----
cat("\n=== Building quarterly panel ===\n")
quarterly <- fare_panel[, .(
  rail_fare_q = mean(rail_fare, na.rm = TRUE),
  road_fare_q = mean(road_fare, na.rm = TRUE),
  air_fare_q = mean(air_fare, na.rm = TRUE),
  log_rail_q = mean(log_rail, na.rm = TRUE),
  gdp_pc_q = mean(gdp_pc, na.rm = TRUE)
), by = .(geo, year, quarter = quarter(date), cohort, first_treat, country_id)]

quarterly[, yq := year + (quarter - 1) / 4]

# Merge passenger-km if available
if (nrow(rail_pax) > 0) {
  pax_agg <- rail_pax[, .(pax_km = sum(values, na.rm = TRUE)),
                       by = .(geo, year, quarter)]
  quarterly <- merge(quarterly, pax_agg, by = c("geo", "year", "quarter"), all.x = TRUE)
  quarterly[, log_pax := log(pax_km)]
  cat("Quarterly panel with passengers:", nrow(quarterly), "rows\n")
}

# ---- 8. Save analysis-ready panels ----
saveRDS(fare_panel, "data/monthly_panel.rds")
saveRDS(quarterly, "data/quarterly_panel.rds")

cat("\n=== Panel construction complete ===\n")
cat("Monthly panel:", nrow(fare_panel), "rows,", uniqueN(fare_panel$geo), "countries\n")
cat("Quarterly panel:", nrow(quarterly), "rows\n")
cat("Date range:", as.character(min(fare_panel$date)), "to",
    as.character(max(fare_panel$date)), "\n")
cat("Early transposers:", sum(transposition$cohort == "early"), "\n")
cat("Late transposers:", sum(transposition$cohort == "late"), "\n")
