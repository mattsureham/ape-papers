## =============================================================================
## 02_clean_data.R — Clean and prepare analysis datasets
## =============================================================================

source("00_packages.R")

data_dir <- "../data"

## ---------------------------------------------------------------------------
## 1. Clean RTEP petrol price panel
## ---------------------------------------------------------------------------

rtep <- fread(file.path(data_dir, "rtep_analysis.csv"))

# Remove observations with missing petrol prices
rtep <- rtep[!is.na(o_fuel_petrol_gasoline) & o_fuel_petrol_gasoline > 0]

# Create log prices
rtep[, log_petrol := log(o_fuel_petrol_gasoline)]

# Handle diesel and kerosene (for placebo tests)
rtep[, has_diesel := !is.na(o_fuel_diesel) & o_fuel_diesel > 0]
rtep[, has_kerosene := !is.na(o_fuel_kerosene) & o_fuel_kerosene > 0]
rtep[has_diesel == TRUE, log_diesel := log(o_fuel_diesel)]
rtep[has_kerosene == TRUE, log_kerosene := log(o_fuel_kerosene)]

# Standardize distance (for interpretation)
rtep[, dist_100km := dist_nearest / 100]
rtep[, dist_post_100 := dist_100km * post]

# Create event time variable (months relative to reform)
rtep[, date := as.Date(date)]
rtep[, event_time := as.integer(round(
  difftime(date, as.Date("2023-06-01"), units = "days") / 30.44
))]

# Create event time interactions for event study
rtep[, event_dist := event_time * dist_100km]

# Summary statistics
cat("=== RTEP Panel Summary ===\n")
cat("Markets:", n_distinct(rtep$mkt_name), "\n")
cat("States:", n_distinct(rtep$adm1_name), "\n")
cat("Observations:", nrow(rtep), "\n")
cat("Date range:", as.character(min(rtep$date)), "to", as.character(max(rtep$date)), "\n")
cat("Pre-reform obs:", sum(rtep$post == 0), "\n")
cat("Post-reform obs:", sum(rtep$post == 1), "\n")
cat("\nPetrol price summary:\n")
cat("  Pre-reform:  mean =", round(mean(rtep[post == 0]$o_fuel_petrol_gasoline), 1),
    ", sd =", round(sd(rtep[post == 0]$o_fuel_petrol_gasoline), 1), "\n")
cat("  Post-reform: mean =", round(mean(rtep[post == 1]$o_fuel_petrol_gasoline), 1),
    ", sd =", round(sd(rtep[post == 1]$o_fuel_petrol_gasoline), 1), "\n")
cat("  Distance range:", round(min(rtep$dist_nearest)), "to",
    round(max(rtep$dist_nearest)), "km\n")

fwrite(rtep, file.path(data_dir, "rtep_clean.csv"))

## ---------------------------------------------------------------------------
## 2. Clean WFP food price panel
## ---------------------------------------------------------------------------

wfp <- fread(file.path(data_dir, "wfp_analysis.csv"))

# Keep only retail prices (most relevant for consumers)
wfp <- wfp[pricetype == "Retail"]

# Remove missing prices
wfp <- wfp[!is.na(price) & price > 0]

# Create log price
wfp[, log_price := log(price)]

# Standardize distance
wfp[, dist_100km := dist_nearest / 100]
wfp[, dist_post_100 := dist_100km * post]

# Create date-related variables
wfp[, date := as.Date(date)]
wfp[, event_time := as.integer(round(
  difftime(date, as.Date("2023-06-01"), units = "days") / 30.44
))]

# Create market-commodity fixed effects
wfp[, mkt_comm_id := as.integer(factor(market_commodity))]
wfp[, month_id := as.integer(factor(paste0(year, "-", sprintf("%02d", month))))]

# Separate fuel from food
wfp[, is_fuel := grepl("Fuel|Petrol|Diesel|Kerosene|Gas", commodity, ignore.case = TRUE)]

# Classify commodities
wfp[, commodity_group := fcase(
  grepl("Maize|Rice|Sorghum|Millet|Wheat", commodity, ignore.case = TRUE), "Cereals",
  grepl("Bean|Cowpea|Groundnut|Lentil", commodity, ignore.case = TRUE), "Legumes",
  grepl("Cassava|Gari|Yam|Potato", commodity, ignore.case = TRUE), "Roots/Tubers",
  grepl("Oil|Sugar|Salt", commodity, ignore.case = TRUE), "Processed",
  grepl("Fish|Meat|Egg|Chicken", commodity, ignore.case = TRUE), "Protein",
  grepl("Fuel|Petrol|Diesel|Kerosene", commodity, ignore.case = TRUE), "Fuel",
  default = "Other"
)]

cat("\n=== WFP Panel Summary ===\n")
cat("Markets:", n_distinct(wfp$market), "\n")
cat("Commodities:", n_distinct(wfp$commodity), "\n")
cat("Observations:", nrow(wfp), "\n")
cat("\nBy commodity group:\n")
print(wfp[, .N, by = commodity_group][order(-N)])
cat("\nBy transport intensity:\n")
print(wfp[, .N, by = transport_intensive])

fwrite(wfp, file.path(data_dir, "wfp_clean.csv"))

## ---------------------------------------------------------------------------
## 3. Clean ACLED conflict data (if available)
## ---------------------------------------------------------------------------

acled_file <- file.path(data_dir, "acled_nigeria.csv")

if (file.exists(acled_file)) {
  acled <- fread(acled_file)

  # Parse dates
  acled[, event_date := as.Date(event_date)]
  acled[, year := year(event_date)]
  acled[, month := month(event_date)]
  acled[, date := as.Date(paste0(year, "-", sprintf("%02d", month), "-01"))]

  # Clean latitude/longitude
  acled[, latitude := as.numeric(latitude)]
  acled[, longitude := as.numeric(longitude)]

  # Load terminal coordinates for distance computation
  terminals <- fread(file.path(data_dir, "terminals.csv"))

  # Compute distance from nearest terminal for each event
  event_coords <- acled[!is.na(latitude) & !is.na(longitude), .(latitude, longitude)]
  if (nrow(event_coords) > 0) {
    terminal_coords <- as.matrix(terminals[, c("lon", "lat")])
    event_mat <- as.matrix(event_coords[, .(longitude, latitude)])
    event_dist <- geodist::geodist(x = event_mat, y = terminal_coords,
                                    measure = "haversine") / 1000
    acled[!is.na(latitude) & !is.na(longitude),
          dist_nearest := apply(event_dist, 1, min)]
  }

  # Classify events
  acled[, is_protest := as.integer(event_type == "Protests")]
  acled[, is_riot := as.integer(event_type == "Riots")]
  acled[, is_battle := as.integer(event_type == "Battles")]
  acled[, is_violence := as.integer(event_type == "Violence against civilians")]

  # Flag fuel/cost-of-living related events (from notes field)
  acled[, fuel_related := as.integer(
    grepl("fuel|petrol|gasoline|subsid|pump price|PMS|kerosene|diesel|cost of living|price hike|inflation",
          notes, ignore.case = TRUE)
  )]

  # Post-reform indicator
  acled[, post := as.integer(date >= as.Date("2023-06-01"))]

  # Aggregate to admin1 (state) × month level
  # Using admin1 as state identifier
  acled_state_month <- acled[, .(
    total_events = .N,
    protests = sum(is_protest, na.rm = TRUE),
    riots = sum(is_riot, na.rm = TRUE),
    battles = sum(is_battle, na.rm = TRUE),
    violence_civilians = sum(is_violence, na.rm = TRUE),
    fuel_events = sum(fuel_related, na.rm = TRUE),
    fatalities = sum(as.numeric(fatalities), na.rm = TRUE),
    avg_dist = mean(dist_nearest, na.rm = TRUE)
  ), by = .(admin1, date)]

  acled_state_month[, post := as.integer(date >= as.Date("2023-06-01"))]

  cat("\n=== ACLED Summary ===\n")
  cat("Total events:", nrow(acled), "\n")
  cat("States:", n_distinct(acled$admin1), "\n")
  cat("Event types:\n")
  print(table(acled$event_type))
  cat("Fuel-related events:", sum(acled$fuel_related), "\n")

  fwrite(acled, file.path(data_dir, "acled_clean.csv"))
  fwrite(acled_state_month, file.path(data_dir, "acled_state_month.csv"))
} else {
  cat("ACLED data not available. Skipping conflict panel.\n")
}

## ---------------------------------------------------------------------------
## 4. Summary statistics table data
## ---------------------------------------------------------------------------

# Create summary statistics dataset
sumstats <- rbind(
  data.table(
    panel = "A: Petrol Prices",
    variable = c("PMS price (₦/L)", "Log PMS price", "Distance to terminal (km)"),
    n = c(nrow(rtep), nrow(rtep), nrow(rtep)),
    mean = c(mean(rtep$o_fuel_petrol_gasoline), mean(rtep$log_petrol),
             mean(rtep$dist_nearest)),
    sd = c(sd(rtep$o_fuel_petrol_gasoline), sd(rtep$log_petrol),
           sd(rtep$dist_nearest)),
    min = c(min(rtep$o_fuel_petrol_gasoline), min(rtep$log_petrol),
            min(rtep$dist_nearest)),
    max = c(max(rtep$o_fuel_petrol_gasoline), max(rtep$log_petrol),
            max(rtep$dist_nearest))
  ),
  data.table(
    panel = "B: Food Prices",
    variable = c("Price (₦)", "Log price", "Distance to terminal (km)"),
    n = c(nrow(wfp[is_fuel == FALSE]),
          nrow(wfp[is_fuel == FALSE]),
          nrow(wfp[is_fuel == FALSE])),
    mean = c(mean(wfp[is_fuel == FALSE]$price),
             mean(wfp[is_fuel == FALSE]$log_price),
             mean(wfp[is_fuel == FALSE & !is.na(dist_nearest)]$dist_nearest)),
    sd = c(sd(wfp[is_fuel == FALSE]$price),
           sd(wfp[is_fuel == FALSE]$log_price),
           sd(wfp[is_fuel == FALSE & !is.na(dist_nearest)]$dist_nearest)),
    min = c(min(wfp[is_fuel == FALSE]$price),
            min(wfp[is_fuel == FALSE]$log_price),
            min(wfp[is_fuel == FALSE & !is.na(dist_nearest)]$dist_nearest, na.rm = TRUE)),
    max = c(max(wfp[is_fuel == FALSE]$price),
            max(wfp[is_fuel == FALSE]$log_price),
            max(wfp[is_fuel == FALSE & !is.na(dist_nearest)]$dist_nearest, na.rm = TRUE))
  )
)

fwrite(sumstats, file.path(data_dir, "summary_statistics.csv"))

cat("\n=== All data cleaning complete ===\n")
