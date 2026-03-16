# 02_clean_data.R — Clean and merge WFP + UCDP data
# apep_0709: Markets Under Fire

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Clean WFP food prices
# ============================================================
cat("Cleaning WFP food prices...\n")
wfp <- fread(file.path(data_dir, "wfp_food_prices_bfa.csv"), encoding = "UTF-8")

# Standardize column names (HDX format varies)
names(wfp) <- tolower(names(wfp))
# Common HDX column names: date, admin1, admin2, market, latitude, longitude,
# category, commodity, unit, priceflag, pricetype, currency, price, usdprice

# Parse date
if ("date" %in% names(wfp)) {
  wfp[, date := as.Date(date)]
} else {
  stop("No 'date' column found in WFP data")
}

# Create year-month
wfp[, ym := as.Date(paste0(format(date, "%Y-%m"), "-01"))]
wfp[, year := year(date)]
wfp[, month := month(date)]

# Filter to retail prices only (exclude wholesale if present)
if ("pricetype" %in% names(wfp)) {
  cat(sprintf("  Price types: %s\n", paste(unique(wfp$pricetype), collapse = ", ")))
  wfp <- wfp[tolower(pricetype) == "retail"]
}

# Filter to key staple commodities
target_commodities <- c("Millet", "Sorghum", "Maize", "Rice", "Cowpeas",
                         "Groundnuts")

# Match commodity names (case-insensitive partial match)
wfp[, commodity_clean := NA_character_]
for (tc in target_commodities) {
  wfp[grepl(tc, commodity, ignore.case = TRUE) & is.na(commodity_clean),
      commodity_clean := tc]
}

cat(sprintf("  Commodities matched: %d / %d rows\n",
            sum(!is.na(wfp$commodity_clean)), nrow(wfp)))
cat(sprintf("  Matched commodities: %s\n",
            paste(unique(na.omit(wfp$commodity_clean)), collapse = ", ")))

wfp <- wfp[!is.na(commodity_clean)]

# Ensure we have market coordinates
stopifnot("Missing latitude" = "latitude" %in% names(wfp))
stopifnot("Missing longitude" = "longitude" %in% names(wfp))

# Create market ID
wfp[, market_id := as.integer(factor(market))]

# Filter to 2012-2023 (4 years pre-conflict + conflict period)
wfp <- wfp[year >= 2012 & year <= 2023]

# Remove zero/NA prices
wfp <- wfp[!is.na(price) & price > 0]

# Log price
wfp[, log_price := log(price)]

# Market-commodity panel: aggregate to monthly level
# (in case of duplicates within market-commodity-month)
panel <- wfp[, .(
  price = mean(price, na.rm = TRUE),
  log_price = mean(log_price, na.rm = TRUE),
  n_obs = .N,
  latitude = first(latitude),
  longitude = first(longitude),
  admin1 = first(admin1),
  market_name = first(market)
), by = .(market_id, commodity_clean, ym, year, month)]

cat(sprintf("\n  Panel: %d market-commodity-months\n", nrow(panel)))
cat(sprintf("  Markets: %d\n", uniqueN(panel$market_id)))
cat(sprintf("  Commodities: %d\n", uniqueN(panel$commodity_clean)))
cat(sprintf("  Months: %d\n", uniqueN(panel$ym)))

# ============================================================
# 2. Clean UCDP events
# ============================================================
cat("\nCleaning UCDP events...\n")
ged <- fread(file.path(data_dir, "ucdp_ged_bfa.csv"))

# Parse date
ged[, date_start := as.Date(date_start)]
ged[, ym := as.Date(paste0(format(date_start, "%Y-%m"), "-01"))]
ged[, year := year(date_start)]

cat(sprintf("  Events: %d\n", nrow(ged)))
cat(sprintf("  Year range: %d-%d\n", min(ged$year), max(ged$year)))
cat(sprintf("  Total fatalities: %d\n", sum(ged$best, na.rm = TRUE)))

# ============================================================
# 3. Match conflict events to markets (50km radius)
# ============================================================
cat("\nMatching conflict events to markets (50km radius)...\n")

# Get unique market locations
markets <- unique(panel[, .(market_id, market_name, latitude, longitude, admin1)])

# For each market, find first conflict event within 50km
RADIUS_KM <- 50

event_coords <- cbind(ged$longitude, ged$latitude)

treat_list <- lapply(1:nrow(markets), function(i) {
  mkt <- markets[i]
  mkt_coords <- matrix(c(mkt$longitude, mkt$latitude), ncol = 2,
                        nrow = nrow(ged), byrow = TRUE)

  dists <- geosphere::distHaversine(mkt_coords, event_coords) / 1000

  within_radius <- which(dists <= RADIUS_KM)

  if (length(within_radius) > 0) {
    first_event_idx <- within_radius[which.min(ged$date_start[within_radius])]
    first_event_date <- ged$date_start[first_event_idx]
    first_event_ym <- as.Date(paste0(format(first_event_date, "%Y-%m"), "-01"))
    total_events <- length(within_radius)
    total_fatalities <- sum(ged$best[within_radius], na.rm = TRUE)

    data.table(
      market_id = mkt$market_id,
      treated = TRUE,
      first_event_date = first_event_date,
      first_event_ym = first_event_ym,
      total_events_50km = total_events,
      total_fatalities_50km = total_fatalities
    )
  } else {
    data.table(
      market_id = mkt$market_id,
      treated = FALSE,
      first_event_date = as.Date(NA),
      first_event_ym = as.Date(NA),
      total_events_50km = 0L,
      total_fatalities_50km = 0L
    )
  }
})

market_treatment <- rbindlist(treat_list)

cat(sprintf("  Treated markets (50km): %d / %d\n",
            sum(market_treatment$treated), nrow(market_treatment)))
cat(sprintf("  Never-treated markets: %d\n", sum(!market_treatment$treated)))

# Show treatment cohorts
cohorts <- market_treatment[treated == TRUE, .(
  n_markets = .N
), by = .(cohort_ym = first_event_ym)][order(cohort_ym)]
cat("\n  Treatment cohorts:\n")
print(cohorts)

# ============================================================
# 4. Merge treatment status into panel
# ============================================================
panel <- merge(panel, market_treatment, by = "market_id", all.x = TRUE)

# Create time-to-treatment variable
panel[, time_to_treat := as.numeric(difftime(ym, first_event_ym, units = "days")) / 30.44]
panel[, time_to_treat_months := round(time_to_treat)]

# Post-treatment indicator
panel[, post := !is.na(first_event_ym) & ym >= first_event_ym]

# Numeric time period for did package
panel[, time_period := as.integer(ym - as.Date("2011-12-01")) %/% 30 + 1]

# Cohort variable for CS estimator (0 = never treated)
panel[, cohort := ifelse(treated, as.integer(format(first_event_ym, "%Y%m")), 0)]

# Create market × commodity unit ID
panel[, unit_id := as.integer(factor(paste(market_id, commodity_clean)))]

# ============================================================
# 5. Commodity classification for mechanism tests
# ============================================================
panel[, commodity_type := fcase(
  commodity_clean %in% c("Millet", "Sorghum", "Maize"), "Local cereal",
  commodity_clean == "Rice", "Imported",
  commodity_clean %in% c("Cowpeas", "Groundnuts"), "Protein/legume"
)]

# ============================================================
# 6. Save cleaned panel
# ============================================================
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
saveRDS(market_treatment, file.path(data_dir, "market_treatment.rds"))

cat(sprintf("\n=== Final panel ===\n"))
cat(sprintf("Observations: %s\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("Markets: %d\n", uniqueN(panel$market_id)))
cat(sprintf("Commodities: %d\n", uniqueN(panel$commodity_clean)))
cat(sprintf("Time periods: %d months\n", uniqueN(panel$ym)))
cat(sprintf("Treated markets: %d\n", sum(market_treatment$treated)))
cat(sprintf("Never-treated: %d\n", sum(!market_treatment$treated)))
cat(sprintf("Year range: %d-%d\n", min(panel$year), max(panel$year)))

cat("\nData cleaning complete.\n")
