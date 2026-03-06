###############################################################################
# 02_clean_data.R — Construct analysis dataset
# APEP-0541: How Many Generics Does It Take?
#
# Combined approach:
# (1) Panel: market x week with competitor counts. Market FE + week FE.
# (2) Event study: subset of markets with new entrants during sample.
# (3) Orange Book cross-walk: link NADAC markets to ANDA approval history.
###############################################################################

source("00_packages.R")

data_dir <- "../data"

# ==========================================================================
# 1. Load and clean NADAC
# ==========================================================================

nadac <- fread(file.path(data_dir, "nadac_raw.csv"))
cat("Loaded", nrow(nadac), "NADAC records\n")

# Standardize columns
if ("NDC Description" %in% names(nadac)) {
  setnames(nadac, c("NDC Description", "NDC", "NADAC Per Unit",
                     "Effective Date", "Classification for Rate Setting"),
           c("ndc_description", "ndc", "nadac_per_unit",
             "effective_date", "classification"))
}

nadac[, effective_date := as.Date(effective_date, format = "%m/%d/%Y")]
nadac[, nadac_per_unit := as.numeric(nadac_per_unit)]

# Keep generics only with valid prices
nadac <- nadac[toupper(classification) == "G" &
               !is.na(nadac_per_unit) & nadac_per_unit > 0]
cat("Generic records with valid prices:", nrow(nadac), "\n")

# Create week and market variables
nadac[, week := floor_date(effective_date, "week")]
nadac[, market := toupper(trimws(ndc_description))]

# ==========================================================================
# 2. Build market x week panel
# ==========================================================================

# Aggregate to NDC x week
setorder(nadac, ndc, effective_date)
ndc_weekly <- nadac[, .(
  price = last(nadac_per_unit),
  market = last(market)
), by = .(ndc, week)]

# For each market x week, compute:
# - average price across NDCs
# - number of active generic competitors (distinct NDCs)
market_panel <- ndc_weekly[, .(
  avg_price = mean(price, na.rm = TRUE),
  med_price = median(price, na.rm = TRUE),
  min_price = min(price, na.rm = TRUE),
  n_competitors = uniqueN(ndc),
  log_price = log(mean(price, na.rm = TRUE)),
  log_min_price = log(min(price, na.rm = TRUE))
), by = .(market, week)]

cat("\nMarket-week panel:", nrow(market_panel), "obs\n")
cat("Unique markets:", uniqueN(market_panel$market), "\n")
cat("Weeks:", uniqueN(market_panel$week), "\n")
cat("Date range:", as.character(min(market_panel$week)),
    "to", as.character(max(market_panel$week)), "\n")

# ==========================================================================
# 3. Identify within-market variation in competitor counts
# ==========================================================================

# Markets where the number of competitors changes during the sample
market_variation <- market_panel[, .(
  min_n = min(n_competitors),
  max_n = max(n_competitors),
  sd_n = sd(n_competitors),
  mean_n = mean(n_competitors),
  n_weeks = .N
), by = market]

market_variation[, has_entry := max_n > min_n]
market_variation[, n_change := max_n - min_n]

cat("\nMarkets with within-sample competitor changes:",
    sum(market_variation$has_entry), "of", nrow(market_variation),
    sprintf("(%.1f%%)\n", mean(market_variation$has_entry) * 100))

cat("Distribution of competitor counts:\n")
cat("  Mean competitors:", round(mean(market_panel$n_competitors), 1), "\n")
cat("  Median competitors:", median(market_panel$n_competitors), "\n")
cat("  Max competitors:", max(market_panel$n_competitors), "\n")

# ==========================================================================
# 4. Cross-section: competitor count vs price level
# ==========================================================================

# For each market, compute time-average price and average competitor count
market_cross <- market_panel[, .(
  avg_log_price = mean(log_price, na.rm = TRUE),
  avg_min_log_price = mean(log_min_price, na.rm = TRUE),
  avg_n = mean(n_competitors, na.rm = TRUE),
  n_weeks = .N
), by = market]

# Bin by competitor count
cross_by_n <- market_panel[, .(
  avg_price = mean(avg_price, na.rm = TRUE),
  med_price = median(med_price, na.rm = TRUE),
  avg_log_price = mean(log_price, na.rm = TRUE),
  n_markets = uniqueN(market),
  n_obs = .N
), by = n_competitors][order(n_competitors)]

cat("\nPrice by number of competitors (cross-section):\n")
print(cross_by_n[n_competitors <= 20])

fwrite(cross_by_n, file.path(data_dir, "cross_section_by_n.csv"))

# ==========================================================================
# 5. Identify entry events for event-study design
# ==========================================================================

# Track when each NDC first appears in each market
ndc_entry <- ndc_weekly[, .(first_week = min(week)), by = .(ndc, market)]
setorder(ndc_entry, market, first_week)
ndc_entry[, entry_order := seq_len(.N), by = market]

# Identify new entries DURING the sample (not at sample start)
min_week <- min(market_panel$week)
new_entries <- ndc_entry[first_week > min_week + weeks(4)]

cat("\nNew NDC entries during sample:", nrow(new_entries), "\n")

# For each new entry, what is the pre-entry and post-entry competitor count?
new_entries_enriched <- merge(
  new_entries,
  market_panel[, .(n_pre = n_competitors[which.min(abs(week - (min_week + weeks(2))))]),
               by = market],
  by = "market", all.x = TRUE
)

# Group by market: a market "entry event" is when competitor count increases
market_events <- market_panel[, {
  # Find weeks where n_competitors increases
  change <- diff(n_competitors)
  idx <- which(change > 0) + 1
  if (length(idx) > 0) {
    data.table(
      event_week = week[idx],
      n_before = n_competitors[idx - 1],
      n_after = n_competitors[idx],
      gain = change[idx[seq_along(idx)] - 1 + which(change > 0)]
    )
  } else {
    data.table(event_week = as.Date(character()),
               n_before = integer(), n_after = integer(), gain = integer())
  }
}, by = market]

# Remove artifacts from first few weeks (left-censoring)
market_events <- market_events[event_week > min_week + weeks(6)]

cat("Market entry events (competitor count increases):",
    nrow(market_events), "\n")
cat("By pre-entry competitor count:\n")
print(market_events[, .N, by = n_before][order(n_before)][1:15])

# ==========================================================================
# 6. Build event-study panels around entry events
# ==========================================================================

pre_w <- 16
post_w <- 30

event_panels <- lapply(seq_len(nrow(market_events)), function(i) {
  ev <- market_events[i]
  prices <- market_panel[market == ev$market]
  if (nrow(prices) < 15) return(NULL)

  prices[, event_time := as.integer(difftime(week, ev$event_week, units = "weeks"))]
  prices_win <- prices[event_time >= -pre_w & event_time <= post_w]

  if (sum(prices_win$event_time < 0) < 4 ||
      sum(prices_win$event_time >= 0) < 4) return(NULL)

  prices_win[, `:=`(
    event_id = paste(ev$market, ev$event_week, sep = "__"),
    n_before = ev$n_before,
    n_after = ev$n_after,
    entry_position = ev$n_after  # N after entry = position
  )]

  prices_win
})

event_data <- rbindlist(event_panels[!sapply(event_panels, is.null)])

cat("\nEvent-study panel:\n")
cat("  Total observations:", nrow(event_data), "\n")
cat("  Unique events:", uniqueN(event_data$event_id), "\n")
cat("  Events by entry position (n_after):\n")
print(event_data[, .(n_events = uniqueN(event_id)), by = n_after][order(n_after)][1:15])

# ==========================================================================
# 7. Save everything
# ==========================================================================

# Add market integer ID for FE estimation
market_panel[, market_id := as.integer(factor(market))]
event_data[, market_id := as.integer(factor(market))]

fwrite(market_panel, file.path(data_dir, "analysis_panel.csv"))
fwrite(event_data, file.path(data_dir, "event_panel.csv"))
fwrite(market_events, file.path(data_dir, "entry_events.csv"))
fwrite(ndc_entry, file.path(data_dir, "entry_events_clean.csv"))
fwrite(cross_by_n, file.path(data_dir, "cross_section_by_n.csv"))

# Summary statistics
summary_stats <- market_panel[, .(
  n_markets = uniqueN(market),
  n_obs = .N,
  mean_price = mean(avg_price, na.rm = TRUE),
  med_price = median(avg_price, na.rm = TRUE),
  mean_competitors = mean(n_competitors, na.rm = TRUE),
  sd_competitors = sd(n_competitors, na.rm = TRUE)
)]
cat("\nOverall summary:\n")
print(summary_stats)

# Summary by competitor count bin
summary_by_n <- market_panel[n_competitors <= 20, .(
  n_events = uniqueN(market),
  n_obs = .N,
  mean_price = mean(avg_price, na.rm = TRUE),
  med_price = median(avg_price, na.rm = TRUE),
  mean_log_price = mean(log_price, na.rm = TRUE),
  n_clean = 100
), by = .(entry_position = n_competitors)][order(entry_position)]

fwrite(summary_by_n, file.path(data_dir, "summary_by_position.csv"))

# Validation
stopifnot("Expected 1000+ markets" = uniqueN(market_panel$market) >= 1000)
stopifnot("Expected 30000+ market-week obs" = nrow(market_panel) >= 30000)
cat("\nData cleaning complete.\n")
