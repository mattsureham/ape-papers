# =============================================================================
# 02_clean_data.R — Clean and construct analysis dataset
# APEP-0560: Market Discipline and Mining Safety
# =============================================================================

source("00_packages.R")

cat("=== Loading raw data ===\n")
events_dt <- fread("../data/tailings_events_cleaned.csv")
stock_dt <- fread("../data/stock_returns.csv")
bench_dt <- fread("../data/benchmark_returns.csv")
firms_dt <- fread("../data/mining_firms_universe.csv")

# Convert dates
events_dt[, event_date := as.Date(event_date)]
stock_dt[, date := as.Date(date)]
bench_dt[, date := as.Date(date)]

# --- 1. Clean events data ---
cat("\n=== Cleaning events data ===\n")

# Standardize country names
events_dt[, country_clean := trimws(country)]
events_dt[grepl("USA|United States", country_clean, ignore.case = TRUE), country_clean := "USA"]
events_dt[grepl("Brazil", country_clean, ignore.case = TRUE), country_clean := "Brazil"]
events_dt[grepl("China|Chinese", country_clean, ignore.case = TRUE), country_clean := "China"]
events_dt[grepl("Philippines", country_clean, ignore.case = TRUE), country_clean := "Philippines"]
events_dt[grepl("Canada", country_clean, ignore.case = TRUE), country_clean := "Canada"]
events_dt[grepl("Chile", country_clean, ignore.case = TRUE), country_clean := "Chile"]
events_dt[grepl("Peru", country_clean, ignore.case = TRUE), country_clean := "Peru"]
events_dt[grepl("Mexico", country_clean, ignore.case = TRUE), country_clean := "Mexico"]
events_dt[grepl("Romania", country_clean, ignore.case = TRUE), country_clean := "Romania"]
events_dt[grepl("Spain", country_clean, ignore.case = TRUE), country_clean := "Spain"]
events_dt[grepl("South Africa", country_clean, ignore.case = TRUE), country_clean := "South Africa"]
events_dt[grepl("Australia", country_clean, ignore.case = TRUE), country_clean := "Australia"]
events_dt[grepl("UK|United Kingdom|Britain", country_clean, ignore.case = TRUE), country_clean := "UK"]

# Standardize ore types
events_dt[, ore_clean := str_to_title(trimws(ore_type))]
events_dt[grepl("gold", ore_clean, ignore.case = TRUE), ore_clean := "Gold"]
events_dt[grepl("copper", ore_clean, ignore.case = TRUE), ore_clean := "Copper"]
events_dt[grepl("iron", ore_clean, ignore.case = TRUE), ore_clean := "Iron Ore"]
events_dt[grepl("coal", ore_clean, ignore.case = TRUE), ore_clean := "Coal"]
events_dt[grepl("zinc|lead", ore_clean, ignore.case = TRUE), ore_clean := "Zinc/Lead"]
events_dt[grepl("urani", ore_clean, ignore.case = TRUE), ore_clean := "Uranium"]
events_dt[grepl("phosph|gypsum", ore_clean, ignore.case = TRUE), ore_clean := "Phosphate"]
events_dt[grepl("nickel", ore_clean, ignore.case = TRUE), ore_clean := "Nickel"]
events_dt[grepl("silver", ore_clean, ignore.case = TRUE), ore_clean := "Silver"]
events_dt[grepl("tin", ore_clean, ignore.case = TRUE), ore_clean := "Tin"]
events_dt[grepl("bauxite|alumi", ore_clean, ignore.case = TRUE), ore_clean := "Aluminum"]
events_dt[grepl("platin|pgm", ore_clean, ignore.case = TRUE), ore_clean := "PGM"]

# Classify event severity
events_dt[, severity := fifelse(
  has_fatalities & fatality_count >= 10, "Major",
  fifelse(has_fatalities, "Fatal",
  fifelse(!is.na(release_volume_m3) & release_volume_m3 >= 100000, "Large Release",
  "Other"))
)]

# Post-GISTM indicator
events_dt[, post_gistm := event_date >= as.Date("2020-08-05")]

# Create event ID
events_dt[, event_id := .I]

# Summary statistics
cat("Events by severity:\n")
print(events_dt[, .N, by = severity])
cat("\nEvents by decade:\n")
print(events_dt[, .(N = .N), by = .(decade = floor(year / 10) * 10)])
cat("\nTop 10 countries:\n")
print(events_dt[, .N, by = country_clean][order(-N)][1:10])
cat("\nTop ore types:\n")
print(events_dt[, .N, by = ore_clean][order(-N)][1:10])

# --- 2. Prepare stock data for event study ---
cat("\n=== Preparing stock panel ===\n")

# Use S&P 500 as primary market benchmark
sp500 <- bench_dt[benchmark == "^GSPC", .(date, mkt_ret)]

# Merge market returns with stock returns
stock_panel <- merge(stock_dt, sp500, by = "date", all.x = TRUE)
stock_panel <- stock_panel[!is.na(mkt_ret)]

# Create trading day counter (for event windows)
trading_dates <- sort(unique(stock_panel$date))
date_to_td <- data.table(date = trading_dates, td = seq_along(trading_dates))
stock_panel <- merge(stock_panel, date_to_td, by = "date")

# --- 3. Map events to trading days ---
cat("\n=== Mapping events to trading days ===\n")

# For each event, find the closest trading day on or after the event date
events_dt[, event_td := sapply(event_date, function(d) {
  if (is.na(d)) return(NA_integer_)
  idx <- which(trading_dates >= d)
  if (length(idx) == 0) return(NA_integer_)
  date_to_td$td[idx[1]]
})]

# Filter events that fall within our stock data period
events_analysis <- events_dt[!is.na(event_td)]
cat("Events with matched trading days:", nrow(events_analysis), "\n")

# Filter to events where we have enough pre-event data (at least 280 trading days)
min_td <- min(date_to_td$td) + 280
events_analysis <- events_analysis[event_td >= min_td]
cat("Events with sufficient pre-event data:", nrow(events_analysis), "\n")

# Check for overlapping events (within 10 trading days)
events_analysis <- events_analysis[order(event_td)]
events_analysis[, overlap := c(FALSE, diff(event_td) < 10)]
cat("Overlapping events (within 10 trading days):", sum(events_analysis$overlap), "\n")

# --- 4. Compute commodity match between events and firms ---
cat("\n=== Computing commodity matches ===\n")

# Create commodity mapping between event ore types and firm commodities
commodity_map <- data.table(
  event_ore = c("Gold", "Copper", "Iron Ore", "Coal", "Zinc/Lead", "Uranium",
                "Phosphate", "Nickel", "Silver", "Aluminum", "PGM"),
  firm_commodity = c("Gold", "Copper", "Iron Ore", "Coal", "Zinc", "Uranium",
                     "Phosphate", "Nickel", "Silver", "Aluminum", "PGM")
)

# For each event-firm pair, determine if same commodity
# This will be done in the analysis script via cross-join

# --- 5. Save analysis-ready datasets ---
cat("\n=== Saving analysis datasets ===\n")

fwrite(events_analysis, "../data/events_analysis.csv")
fwrite(stock_panel, "../data/stock_panel.csv")
fwrite(date_to_td, "../data/trading_dates.csv")

cat("Events for analysis:", nrow(events_analysis), "\n")
cat("Stock panel rows:", nrow(stock_panel), "\n")
cat("Unique firms:", uniqueN(stock_panel$ticker), "\n")
cat("Trading days:", nrow(date_to_td), "\n")

# Summary for paper
cat("\n=== SUMMARY FOR PAPER ===\n")
cat("Period:", as.character(min(stock_panel$date)), "to", as.character(max(stock_panel$date)), "\n")
cat("Events:", nrow(events_analysis), "\n")
cat("  Pre-GISTM:", sum(!events_analysis$post_gistm), "\n")
cat("  Post-GISTM:", sum(events_analysis$post_gistm), "\n")
cat("  Fatal:", sum(events_analysis$has_fatalities), "\n")
cat("  Major:", sum(events_analysis$severity == "Major"), "\n")
cat("Countries:", uniqueN(events_analysis$country_clean), "\n")
cat("Firms:", uniqueN(stock_panel$ticker), "\n")
