## ============================================================================
## 02_clean_data.R — Construct analysis panel with cash-mediation classification
## Paper: Demonetization by Design (apep_0555)
## ============================================================================

source(file.path(here::here(), "output", "apep_0555", "v1", "code", "00_packages.R"))

wfp <- fread(file.path(data_dir, "wfp_prices_raw.csv"))

## --- 1. Parse dates and create time variables ---
wfp[, date := as.Date(date)]
wfp[, `:=`(
  year  = year(date),
  month = month(date),
  ym    = as.yearmon(date)  # requires zoo
)]

## yearmon helper if zoo not available
if (!requireNamespace("zoo", quietly = TRUE)) {
  wfp[, ym := year + (month - 1) / 12]
} else {
  wfp[, ym := as.numeric(zoo::as.yearmon(date))]
}

## Create a numeric time index (months since Jan 2000)
wfp[, time_idx := (year - 2000) * 12 + month]

## --- 2. Cash-Mediation Intensity Classification ---
## HIGH CMI: locally produced, cash-mediated supply chains
## LOW CMI: imported, banking-mediated supply chains

high_cmi_commodities <- c(
  "Millet", "Millet (local)", "Millet (imported)",
  "Sorghum", "Sorghum (white)", "Sorghum (brown)", "Sorghum (red)",
  "Maize", "Maize (white)", "Maize (yellow)", "Maize flour",
  "Rice (local)", "Rice - Loss Ratio (local)", "Rice (milled, local)",
  "Yam", "Yam (white)", "Yam (water)", "Yam (Abuja)",
  "Cowpeas", "Cowpeas (brown)", "Cowpeas (white)",
  "Cassava", "Cassava meal (Gari)", "Gari (white)", "Gari (yellow)",
  "Cassava meal (gari, yellow)",
  "Groundnuts", "Groundnuts (shelled)",
  "Palm oil", "Oil (palm)",
  "Beans", "Beans (brown)", "Beans (white)", "Beans (red)", "Beans (niebe)",
  "Sesame",
  "Fish", "Fish (smoked)",
  "Meat (beef)", "Meat (goat)",
  "Eggs",
  "Tomatoes",
  "Onions",
  "Spinach",
  "Oranges",
  "Bananas",
  "Watermelons"
)

low_cmi_commodities <- c(
  "Rice (imported)", "Rice - Loss Ratio (imported)",
  "Wheat flour", "Wheat",
  "Sugar", "Sugar (imported)",
  "Pasta",
  "Oil (vegetable)",
  "Salt",
  "Bread",
  "Milk (powder)",
  "Seasoning (maggi cube)"
)

## Classify
wfp[, cmi := fcase(
  commodity %chin% high_cmi_commodities, "high",
  commodity %chin% low_cmi_commodities,  "low",
  default = NA_character_
)]

## Report classification coverage
cat("CMI classification:\n")
cat("  High CMI:", sum(!is.na(wfp$cmi) & wfp$cmi == "high"), "observations\n")
cat("  Low CMI:",  sum(!is.na(wfp$cmi) & wfp$cmi == "low"),  "observations\n")
cat("  Unclassified:", sum(is.na(wfp$cmi)), "observations\n")

## Check what's unclassified
unclassified <- wfp[is.na(cmi), .N, by = commodity][order(-N)]
cat("\nUnclassified commodities:\n")
print(unclassified)

## --- 3. Create binary and numeric CMI indicators ---
wfp[, high_cmi := as.integer(cmi == "high")]

## Note: Onions are locally produced in northern Nigeria (Sokoto, Kebbi, Kano)
## and classified as high CMI. "Onions (imported)" would be low CMI but does
## not appear in the data.

## --- 4. Define treatment periods ---

## Key dates:
## Oct 26, 2022: Policy announced
## Jan 31, 2023: Old notes cease to be legal tender
## Feb-Mar 2023: Peak cash crisis
## Mar 3, 2023: Supreme Court invalidates deadline
## Jun 2023: FX unification (separate confound)
## Dec 31, 2023: Old notes finally cease circulation

wfp[, `:=`(
  ## Acute cash crisis: Feb-May 2023 (before FX unification in June)
  cash_crisis_acute = as.integer(year == 2023 & month >= 2 & month <= 5),
  ## Extended crisis: Feb-Dec 2023
  cash_crisis_extended = as.integer(year == 2023 & month >= 2),
  ## Announcement period: Nov 2022 - Jan 2023 (anticipation)
  announcement = as.integer(
    (year == 2022 & month >= 11) | (year == 2023 & month == 1)
  ),
  ## Post-crisis recovery: Jan 2024 onwards
  recovery = as.integer(year >= 2024),
  ## Pre-reform period: before Oct 2022

  pre_reform = as.integer(date < as.Date("2022-10-01"))
)]

## --- 5. Create market-commodity panel identifier ---
wfp[, market_commodity := paste(market, commodity, sep = "_")]
wfp[, market_id_num := as.integer(as.factor(market))]
wfp[, commodity_id_num := as.integer(as.factor(commodity))]

## --- 6. Create state-level identifiers ---
wfp[, state := admin1]

## Northeast conflict states (for robustness exclusion)
conflict_states <- c("Borno", "Yobe", "Adamawa")
wfp[, conflict_state := as.integer(state %in% conflict_states)]

## --- 7. Filter to analysis window ---
## Main analysis: Jan 2020 - Dec 2024 (2 years pre, crisis, 1+ year post)
panel <- wfp[!is.na(cmi) & date >= as.Date("2020-01-01") & date <= as.Date("2024-12-31")]
cat("\nAnalysis panel:", nrow(panel), "observations\n")
cat("  Markets:", n_distinct(panel$market), "\n")
cat("  Commodities:", n_distinct(panel$commodity), "\n")
cat("  Months:", n_distinct(panel$time_idx), "\n")

## --- 8. Create rice-only subsample (local vs imported) ---
rice <- wfp[commodity %in% c("Rice (local)", "Rice (imported)") &
              date >= as.Date("2020-01-01") & date <= as.Date("2024-12-31")]

## Keep only markets with BOTH local and imported rice
rice_markets <- rice[, .(n_types = n_distinct(commodity)), by = market][n_types == 2, market]
rice <- rice[market %in% rice_markets]
cat("\nRice subsample:", nrow(rice), "obs in", n_distinct(rice$market), "markets\n")

## --- 9. Log prices ---
panel[, log_price := log(price)]
rice[, log_price := log(price)]

## Remove any NA prices
panel <- panel[!is.na(price) & price > 0]
rice <- rice[!is.na(price) & price > 0]

## --- 10. Event study time variable ---
## Relative to Feb 2023 (start of acute crisis)
panel[, event_time := time_idx - (2023 * 12 + 2 - 2000 * 12)]
rice[, event_time := time_idx - (2023 * 12 + 2 - 2000 * 12)]

## --- 11. Summary statistics ---
sumstats <- panel[, .(
  n_obs = .N,
  n_markets = n_distinct(market),
  n_commodities = n_distinct(commodity),
  mean_price = mean(price, na.rm = TRUE),
  sd_price = sd(price, na.rm = TRUE),
  mean_log_price = mean(log_price, na.rm = TRUE),
  sd_log_price = sd(log_price, na.rm = TRUE)
), by = cmi]
cat("\nSummary statistics by CMI:\n")
print(sumstats)

## Pre vs post comparison
pre_post <- panel[, .(
  mean_price = mean(price, na.rm = TRUE),
  sd_price = sd(price, na.rm = TRUE)
), by = .(cmi, period = fifelse(cash_crisis_acute == 1, "crisis", "other"))]
cat("\nPre-crisis vs crisis by CMI:\n")
print(pre_post)

## --- 12. Save analysis datasets ---
fwrite(panel, file.path(data_dir, "panel.csv"))
fwrite(rice, file.path(data_dir, "rice_panel.csv"))
fwrite(sumstats, file.path(data_dir, "sumstats.csv"))
fwrite(pre_post, file.path(data_dir, "pre_post_comparison.csv"))

## Full WFP data for long pre-period event study
long_panel <- wfp[!is.na(cmi) & date >= as.Date("2017-01-01") & date <= as.Date("2024-12-31")]
long_panel[, log_price := log(price)]
long_panel <- long_panel[!is.na(price) & price > 0]
long_panel[, event_time := time_idx - (2023 * 12 + 2 - 2000 * 12)]
fwrite(long_panel, file.path(data_dir, "long_panel.csv"))

cat("\n=== CLEANING COMPLETE ===\n")
cat("Main panel:", nrow(panel), "obs\n")
cat("Rice panel:", nrow(rice), "obs\n")
cat("Long panel:", nrow(long_panel), "obs\n")
