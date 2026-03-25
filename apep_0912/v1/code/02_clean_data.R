## ── 02_clean_data.R ──────────────────────────────────────────────
## Clean WFP data and merge with import dependence
## Construct analysis panel for within-market across-commodity DiD
## ──────────────────────────────────────────────────────────────────

source("code/00_packages.R")

data_dir <- "data"

## ── 1. Load and Harmonize WFP Yearly Files ──────────────────────

cat("=== Loading WFP Yearly Files ===\n")

wfp_files <- list.files(data_dir, pattern = "^wfp_20(2[1-5])\\.csv$", full.names = TRUE)
cat("Files to load:", paste(basename(wfp_files), collapse = ", "), "\n")

all_wfp <- lapply(wfp_files, function(f) {
  dt <- fread(f, encoding = "UTF-8")
  cat("  Loaded", basename(f), ":", nrow(dt), "rows\n")
  dt
})

wfp <- rbindlist(all_wfp, fill = TRUE)
cat("Combined:", nrow(wfp), "rows\n")

## ── 2. Standardize Variables ────────────────────────────────────

# Yearly files have: countryiso3, date, admin1, admin2, market, market_id,
#   latitude, longitude, category, commodity, commodity_id, unit, priceflag,
#   pricetype, currency, price, usdprice

# Parse date
wfp[, date := as.Date(date)]
wfp[, year := as.integer(format(date, "%Y"))]
wfp[, month := as.integer(format(date, "%m"))]
wfp[, ym := year * 100 + month]

# Create market identifier (country + market name)
wfp[, market_key := paste0(countryiso3, "_", market_id)]

cat("\n=== WFP Data Overview ===\n")
cat("Rows:", nrow(wfp), "\n")
cat("Countries:", uniqueN(wfp$countryiso3), "\n")
cat("Markets:", uniqueN(wfp$market_key), "\n")
cat("Commodities:", uniqueN(wfp$commodity), "\n")
cat("Date range:", as.character(range(wfp$date)), "\n")

## ── 3. Classify Commodities ─────────────────────────────────────

# Rice (treatment commodity)
wfp[, is_rice := grepl("rice|Rice", commodity, ignore.case = TRUE)]

# Control commodities: staple grains and substitutes in same markets
# These have independent supply chains from Indian rice
control_keywords <- c("maize", "millet", "sorghum", "wheat", "beans",
                       "groundnut", "cassava", "potato", "lentil")
wfp[, is_control := grepl(paste(control_keywords, collapse = "|"),
                           commodity, ignore.case = TRUE) & !is_rice]

cat("\nCommodity classification:\n")
cat("  Rice observations:", sum(wfp$is_rice), "\n")
cat("  Control observations:", sum(wfp$is_control), "\n")
cat("  Other:", sum(!wfp$is_rice & !wfp$is_control), "\n")

cat("\nRice commodities:\n")
print(sort(table(wfp[is_rice == TRUE]$commodity), decreasing = TRUE)[1:10])

cat("\nControl commodities:\n")
print(sort(table(wfp[is_control == TRUE]$commodity), decreasing = TRUE)[1:10])

## ── 4. Filter to Analysis Sample ────────────────────────────────

# Keep only rice and control commodities, retail prices, with valid USD price
panel <- wfp[
  (is_rice | is_control) &
  !is.na(usdprice) & usdprice > 0 &
  pricetype == "Retail" &
  year >= 2021 & year <= 2025
]

cat("\n=== Analysis Sample ===\n")
cat("Rows after filter:", nrow(panel), "\n")
cat("Countries:", uniqueN(panel$countryiso3), "\n")
cat("Markets:", uniqueN(panel$market_key), "\n")

# Require markets to have BOTH rice and control commodities
# (essential for within-market identification)
markets_with_rice <- unique(panel[is_rice == TRUE]$market_key)
markets_with_control <- unique(panel[is_control == TRUE]$market_key)
markets_both <- intersect(markets_with_rice, markets_with_control)
cat("Markets with both rice and control:", length(markets_both), "\n")

panel <- panel[market_key %in% markets_both]
cat("Rows after requiring both:", nrow(panel), "\n")

# Require at least 6 pre-ban months and 6 post-ban months per market
# Ban date: July 2023
ban_ym <- 202307
panel[, pre_ban := ym < ban_ym]
panel[, post_ban := ym >= ban_ym]

market_coverage <- panel[, .(
  n_pre = sum(pre_ban),
  n_post = sum(post_ban),
  n_months_pre = uniqueN(ym[pre_ban == TRUE]),
  n_months_post = uniqueN(ym[post_ban == TRUE])
), by = market_key]

good_markets <- market_coverage[n_months_pre >= 6 & n_months_post >= 6]$market_key
cat("Markets with >=6 pre and >=6 post months:", length(good_markets), "\n")

panel <- panel[market_key %in% good_markets]
cat("Final analysis rows:", nrow(panel), "\n")
cat("Final countries:", uniqueN(panel$countryiso3), "\n")
cat("Final markets:", uniqueN(panel$market_key), "\n")

## ── 5. Merge Import Dependence ──────────────────────────────────

cat("\n=== Merging Import Dependence ===\n")

imp_dep <- fread(file.path(data_dir, "india_import_dependence.csv"))
# The FAO file has iso3 from countrycode
imp_dep_slim <- imp_dep[, .(iso3, india_share)]
imp_dep_slim <- imp_dep_slim[!is.na(iso3) & iso3 != ""]
# Deduplicate (some countries may appear twice if reporting entities differ)
imp_dep_slim <- imp_dep_slim[, .(india_share = max(india_share)), by = iso3]

# Merge
panel <- merge(panel, imp_dep_slim, by.x = "countryiso3", by.y = "iso3", all.x = TRUE)

# Countries not in FAO → assume zero dependence (e.g., small islands)
panel[is.na(india_share), india_share := 0]

cat("Countries with India share > 0:", uniqueN(panel[india_share > 0]$countryiso3), "\n")
cat("Countries with India share > 20%:", uniqueN(panel[india_share > 0.20]$countryiso3), "\n")
cat("Countries with India share = 0:", uniqueN(panel[india_share == 0]$countryiso3), "\n")

## ── 6. Create Treatment Variables ───────────────────────────────

# Post indicator
panel[, post := as.integer(ym >= ban_ym)]

# Rice indicator
panel[, rice := as.integer(is_rice)]

# Continuous treatment intensity
panel[, treat_intensity := india_share]

# DiD interaction
panel[, rice_post := rice * post]
panel[, rice_post_intensity := rice * post * india_share]

# Event time (months relative to July 2023)
panel[, event_month := (year - 2023) * 12 + (month - 7)]

# Log price (main dependent variable)
panel[, log_price := log(usdprice)]

## ── 7. Create Market-Time FE Identifiers ────────────────────────

# market_key x year-month FE
panel[, mkt_ym := paste0(market_key, "_", ym)]

# Country-level identifiers for clustering
panel[, country := countryiso3]

## ── 8. Summary Statistics and Validation ────────────────────────

cat("\n=== Final Panel Summary ===\n")
cat("Observations:", nrow(panel), "\n")
cat("Countries:", uniqueN(panel$country), "\n")
cat("Markets:", uniqueN(panel$market_key), "\n")
cat("Commodities:", uniqueN(panel$commodity), "\n")
cat("Rice obs:", sum(panel$rice == 1), "\n")
cat("Control obs:", sum(panel$rice == 0), "\n")
cat("Pre-ban obs:", sum(panel$post == 0), "\n")
cat("Post-ban obs:", sum(panel$post == 1), "\n")
cat("Mean USD price (rice):", round(mean(panel[rice == 1]$usdprice, na.rm = TRUE), 3), "\n")
cat("Mean USD price (control):", round(mean(panel[rice == 0]$usdprice, na.rm = TRUE), 3), "\n")
cat("Mean India share:", round(mean(panel$india_share), 3), "\n")
cat("SD India share:", round(sd(panel$india_share), 3), "\n")

# Validate: enough treated units for credible inference
n_countries <- uniqueN(panel$country)
n_markets <- uniqueN(panel$market_key)
n_treated_countries <- uniqueN(panel[india_share > 0.10]$country)
n_pre <- uniqueN(panel[post == 0]$ym)
n_obs <- nrow(panel)

cat("\n=== Diagnostics ===\n")
cat("N countries:", n_countries, "\n")
cat("N markets:", n_markets, "\n")
cat("N treated countries (India share > 10%):", n_treated_countries, "\n")
cat("N pre-ban months:", n_pre, "\n")
cat("N total obs:", n_obs, "\n")

stopifnot("Need >= 20 treated countries" = n_treated_countries >= 20)
stopifnot("Need >= 5 pre-ban months" = n_pre >= 5)
stopifnot("Need >= 100 observations" = n_obs >= 100)

## ── 9. Save Panel ───────────────────────────────────────────────

fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat("\nPanel saved to data/analysis_panel.csv\n")

# Save key identifiers for quick loading
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
cat("Panel saved to data/analysis_panel.rds\n")
