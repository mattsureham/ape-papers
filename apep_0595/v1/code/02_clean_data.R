# ==============================================================================
# 02_clean_data.R — Clean and construct analysis dataset
# Paper: Trade Protection by Fiat (apep_0595)
# ==============================================================================

source("00_packages.R")

# --- Load raw data ---
nga <- fread(file.path(DATA_DIR, "nga_raw.csv"))
ben <- fread(file.path(DATA_DIR, "ben_raw.csv"))
ner <- fread(file.path(DATA_DIR, "ner_raw.csv"))

# ==============================================================================
# 1. NIGERIA: Clean and construct variables
# ==============================================================================

nga[, date := as.Date(date)]
nga[, year_month := floor_date(date, "month")]
nga[, year := year(date)]
nga[, month := month(date)]

# --- Restrict to analysis window: Jan 2017 - Dec 2021 ---
nga <- nga[year >= 2017 & year <= 2021]

# --- Standardize commodity names ---
nga[, commodity_lower := tolower(commodity)]

# --- Classify commodities ---
# Tradeable staples (main outcomes)
rice_patterns <- c("rice")
maize_patterns <- c("maize", "corn")
sorghum_patterns <- c("sorghum")
millet_patterns <- c("millet")

# Non-tradeable placebos
nontrade_patterns <- c("firewood", "charcoal", "fuel")

nga[, commodity_group := fcase(
  grepl(paste(rice_patterns, collapse = "|"), commodity_lower), "rice",
  grepl(paste(maize_patterns, collapse = "|"), commodity_lower), "maize",
  grepl(paste(sorghum_patterns, collapse = "|"), commodity_lower), "sorghum",
  grepl(paste(millet_patterns, collapse = "|"), commodity_lower), "millet",
  grepl(paste(nontrade_patterns, collapse = "|"), commodity_lower), "non_tradeable",
  default = "other"
)]

cat("Commodity group distribution:\n")
print(nga[, .N, by = commodity_group][order(-N)])

# --- Market coordinates ---
market_coords <- nga[!is.na(latitude) & !is.na(longitude),
                     .(lat = first(latitude), lon = first(longitude)),
                     by = .(market, admin1)]
cat("Markets with coordinates:", nrow(market_coords), "\n")

# --- Compute distance to nearest land border ---
# Nigeria land borders: approximate border points
# Benin (west), Niger (north), Chad (northeast), Cameroon (east)
border_points <- data.frame(
  border = c(
    # Benin border (west)
    rep("Benin", 6),
    # Niger border (north)
    rep("Niger", 8),
    # Chad border (northeast)
    rep("Chad", 3),
    # Cameroon border (east/southeast)
    rep("Cameroon", 8)
  ),
  lat = c(
    # Benin border points (roughly north-south along western border)
    6.35, 7.0, 7.8, 8.5, 9.5, 11.0,
    # Niger border points (roughly east-west along northern border)
    11.8, 12.0, 12.5, 13.0, 13.5, 13.7, 13.5, 13.3,
    # Chad border points (Lake Chad area)
    13.1, 12.8, 12.5,
    # Cameroon border points (east and southeast)
    12.0, 10.5, 9.0, 7.5, 6.5, 5.8, 5.5, 4.5
  ),
  lon = c(
    # Benin border
    2.7, 2.7, 2.8, 3.0, 3.2, 3.4,
    # Niger border
    3.6, 4.5, 5.5, 7.0, 8.5, 10.0, 11.5, 13.0,
    # Chad border
    14.0, 14.3, 14.5,
    # Cameroon border
    14.5, 13.5, 12.5, 12.0, 11.5, 10.5, 9.5, 8.5
  )
)

# Compute minimum distance from each market to any border point
market_coords[, dist_to_border_km := {
  min_dists <- numeric(nrow(market_coords))
  for (i in seq_len(nrow(market_coords))) {
    dists <- distHaversine(
      cbind(market_coords$lon[i], market_coords$lat[i]),
      cbind(border_points$lon, border_points$lat)
    ) / 1000  # Convert to km
    min_dists[i] <- min(dists)
  }
  min_dists
}]

cat("Distance to border range:", round(min(market_coords$dist_to_border_km)),
    "to", round(max(market_coords$dist_to_border_km)), "km\n")

# --- Treatment assignment ---
market_coords[, border_market := as.integer(dist_to_border_km < 150)]
market_coords[, dist_bin := fcase(
  dist_to_border_km < 100, "0-100km",
  dist_to_border_km < 200, "100-200km",
  default = "200+km"
)]

cat("Border markets (<150km):", sum(market_coords$border_market), "\n")
cat("Interior markets (>=150km):", sum(!market_coords$border_market), "\n")
cat("Distance bin distribution:\n")
print(market_coords[, .N, by = dist_bin][order(dist_bin)])

# --- Merge distance to main dataset ---
nga <- merge(nga, market_coords[, .(market, dist_to_border_km, border_market, dist_bin)],
             by = "market", all.x = TRUE)
nga <- nga[!is.na(dist_to_border_km)]

# --- Treatment timing ---
closure_date <- as.Date("2019-08-01")  # First full month of closure
nga[, post := as.integer(year_month >= closure_date)]

# --- Normalize prices to per-kg ---
# Extract numeric weight from unit column
nga[, unit_kg := fcase(
  unit == "KG", 1,
  grepl("^[0-9.]+ KG$", unit), as.numeric(gsub(" KG$", "", unit)),
  default = NA_real_
)]
cat("Unit normalization:\n")
print(nga[, .N, by = .(unit, unit_kg)][order(-N)])

# Price per kg
nga[, price_per_kg := price / unit_kg]
nga[!is.na(usdprice) & usdprice > 0, usdprice_per_kg := usdprice / unit_kg]

# Drop observations with unknown units
nga <- nga[!is.na(unit_kg)]

# --- Restrict to retail prices for clean comparison ---
# (Wholesale prices have different dynamics and coverage)
nga[, pricetype_clean := tolower(pricetype)]
cat("\nPrice type distribution:\n")
print(nga[, .N, by = pricetype_clean][order(-N)])

# Keep retail prices only for primary analysis (larger sample, consumer-relevant)
nga_retail <- nga[pricetype_clean == "retail"]

# Also keep wholesale for robustness
nga_wholesale <- nga[pricetype_clean == "wholesale"]

# Use retail as main analysis dataset
nga <- nga_retail

cat("\nAfter restricting to retail, per-kg prices:\n")
cat("Obs:", nrow(nga), "Markets:", n_distinct(nga$market), "\n")
cat("Price per kg range:", round(min(nga$price_per_kg, na.rm=T)),
    "to", round(max(nga$price_per_kg, na.rm=T)), "NGN\n")

# --- Log prices (now per-kg) ---
nga[, log_price := log(price_per_kg)]
nga[!is.na(usdprice_per_kg) & usdprice_per_kg > 0, log_usdprice := log(usdprice_per_kg)]

# --- Create market-commodity panel ID ---
nga[, market_commodity := paste0(market, "_", commodity)]
nga[, market_id := as.integer(factor(market))]
nga[, time_id := as.integer(factor(year_month))]

# --- Event time (months relative to closure) ---
nga[, event_time := interval(closure_date, year_month) %/% months(1)]

# ==============================================================================
# 2. BENIN: Clean for cross-border validation
# ==============================================================================

ben[, date := as.Date(date)]
ben[, year_month := floor_date(date, "month")]
ben[, year := year(date)]
ben <- ben[year >= 2017 & year <= 2021]

ben[, commodity_lower := tolower(commodity)]
ben[, commodity_group := fcase(
  grepl("rice|riz", commodity_lower), "rice",
  grepl("maize|mais|corn", commodity_lower), "maize",
  grepl("sorghum|sorgho", commodity_lower), "sorghum",
  grepl("millet|mil", commodity_lower), "millet",
  default = "other"
)]

# Benin markets are near the Nigeria border by definition
ben[, country := "Benin"]

# Normalize Benin prices to per-kg
ben[, unit_kg := fcase(
  unit == "KG", 1,
  grepl("^[0-9.]+ KG$", unit), as.numeric(gsub(" KG$", "", unit)),
  default = NA_real_
)]
ben <- ben[!is.na(unit_kg)]
ben[, price_per_kg := price / unit_kg]
ben[!is.na(usdprice) & usdprice > 0, usdprice_per_kg := usdprice / unit_kg]

# Restrict to retail
ben <- ben[tolower(pricetype) == "retail"]
ben[, log_price := log(price_per_kg)]
ben[, market_id := as.integer(factor(market))]
ben[, time_id := as.integer(factor(year_month))]
ben[, post := as.integer(year_month >= closure_date)]
ben[, event_time := interval(closure_date, year_month) %/% months(1)]

# Compute distance to Nigeria border for Benin markets
if ("latitude" %in% names(ben) & "longitude" %in% names(ben)) {
  ben_coords <- ben[!is.na(latitude) & !is.na(longitude),
                    .(lat = first(latitude), lon = first(longitude)),
                    by = market]

  # Nigeria-Benin border points
  nga_ben_border <- border_points[border_points$border == "Benin", ]

  ben_coords[, dist_to_nga_border_km := {
    min_dists <- numeric(nrow(ben_coords))
    for (i in seq_len(nrow(ben_coords))) {
      dists <- distHaversine(
        cbind(ben_coords$lon[i], ben_coords$lat[i]),
        cbind(nga_ben_border$lon, nga_ben_border$lat)
      ) / 1000
      min_dists[i] <- min(dists)
    }
    min_dists
  }]

  ben <- merge(ben, ben_coords[, .(market, dist_to_nga_border_km)],
               by = "market", all.x = TRUE)
  ben[, border_market_ben := as.integer(dist_to_nga_border_km < 150)]
}

# ==============================================================================
# 3. NIGER: Clean for cross-border validation
# ==============================================================================

ner[, date := as.Date(date)]
ner[, year_month := floor_date(date, "month")]
ner[, year := year(date)]
ner <- ner[year >= 2017 & year <= 2021]

ner[, commodity_lower := tolower(commodity)]
ner[, commodity_group := fcase(
  grepl("rice|riz", commodity_lower), "rice",
  grepl("maize|mais|corn", commodity_lower), "maize",
  grepl("sorghum|sorgho", commodity_lower), "sorghum",
  grepl("millet|mil", commodity_lower), "millet",
  default = "other"
)]

ner[, country := "Niger"]

# Normalize Niger prices to per-kg
ner[, unit_kg := fcase(
  unit == "KG", 1,
  grepl("^[0-9.]+ KG$", unit), as.numeric(gsub(" KG$", "", unit)),
  default = NA_real_
)]
ner <- ner[!is.na(unit_kg)]
ner[, price_per_kg := price / unit_kg]
ner[!is.na(usdprice) & usdprice > 0, usdprice_per_kg := usdprice / unit_kg]

# Restrict to retail
ner <- ner[tolower(pricetype) == "retail"]
ner[, log_price := log(price_per_kg)]
ner[, market_id := as.integer(factor(market))]
ner[, time_id := as.integer(factor(year_month))]
ner[, post := as.integer(year_month >= closure_date)]
ner[, event_time := interval(closure_date, year_month) %/% months(1)]

# ==============================================================================
# 4. Save analysis datasets
# ==============================================================================

# Nigeria main analysis
fwrite(nga, file.path(DATA_DIR, "nga_analysis.csv"))

# Nigeria rice-only panel (primary specification)
nga_rice <- nga[commodity_group == "rice"]
fwrite(nga_rice, file.path(DATA_DIR, "nga_rice.csv"))

# Nigeria all cereals
nga_cereals <- nga[commodity_group %in% c("rice", "maize", "sorghum", "millet")]
fwrite(nga_cereals, file.path(DATA_DIR, "nga_cereals.csv"))

# Nigeria non-tradeables (placebo)
nga_placebo <- nga[commodity_group == "non_tradeable"]
fwrite(nga_placebo, file.path(DATA_DIR, "nga_placebo.csv"))

# Benin (cross-border)
fwrite(ben, file.path(DATA_DIR, "ben_analysis.csv"))

# Niger (cross-border)
fwrite(ner, file.path(DATA_DIR, "ner_analysis.csv"))

# Market coordinates with treatment assignment
fwrite(market_coords, file.path(DATA_DIR, "market_coords.csv"))

# Summary
cat("\n=== Analysis datasets saved ===\n")
cat("Nigeria full:", nrow(nga), "obs,", n_distinct(nga$market), "markets\n")
cat("Nigeria rice:", nrow(nga_rice), "obs,", n_distinct(nga_rice$market), "markets\n")
cat("Nigeria cereals:", nrow(nga_cereals), "obs\n")
cat("Nigeria non-tradeable (placebo):", nrow(nga_placebo), "obs\n")

# Save wholesale for robustness
fwrite(nga_wholesale, file.path(DATA_DIR, "nga_wholesale.csv"))
cat("Benin:", nrow(ben), "obs,", n_distinct(ben$market), "markets\n")
cat("Niger:", nrow(ner), "obs,", n_distinct(ner$market), "markets\n")
cat("Border markets:", sum(market_coords$border_market), "\n")
cat("Interior markets:", sum(!market_coords$border_market), "\n")
