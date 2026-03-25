## 02_clean_data.R — Clean and construct analysis panel
## apep_0954: Beirut Port Explosion and Food Prices

source("00_packages.R")

data_dir <- "../data"

# ---- 1. Load raw data ----
dt <- fread(file.path(data_dir, "wfp_food_prices_lbn.csv"))
geo <- fread(file.path(data_dir, "markets_geocoded.csv"))

cat(sprintf("Raw data: %d rows\n", nrow(dt)))
cat(sprintf("Columns: %s\n", paste(names(dt), collapse = ", ")))

# ---- 2. Parse dates and create time variables ----
dt[, date := as.Date(date)]
dt[, ym := floor_date(date, "month")]
dt[, year := year(date)]
dt[, month := month(date)]

# Explosion date: August 4, 2020
explosion_date <- as.Date("2020-08-04")
dt[, post := as.integer(date >= explosion_date)]

# Months relative to explosion
dt[, months_rel := as.integer(difftime(ym, floor_date(explosion_date, "month"), units = "days")) %/% 30]

# ---- 3. Merge market geocoding ----
dt <- merge(dt, geo, by = c("admin1", "market"), all.x = TRUE)
stopifnot(sum(is.na(dt$beirut_proximity)) == 0)

cat(sprintf("After merge: %d rows with geocoding\n", nrow(dt)))

# ---- 4. Classify commodities as imported vs locally-produced ----
# Based on FAO Lebanon food balance and common knowledge of Lebanese agriculture
# Lebanon imports ~80% of wheat, 100% of rice, most lentils, sugar, vegetable oil
# Lebanon produces eggs, some vegetables, dairy, some fruits

imported_commodities <- c(
  "Rice", "Rice (imported)", "Lentils", "Sugar", "Sugar (imported)",
  "Oil (vegetable)", "Oil (sunflower)", "Oil (olive)",
  "Wheat flour", "Flour (wheat)", "Bread", "Bread (pita)",
  "Pasta", "Milk (powdered)", "Fuel (diesel)", "Fuel (gasoline)",
  "Chickpeas", "Beans", "Beans (white)", "Canned food",
  "Tea", "Coffee"
)

local_commodities <- c(
  "Eggs", "Tomatoes", "Potatoes", "Cucumbers", "Apples",
  "Bananas", "Lettuce", "Onions", "Garlic"
)

# Check actual commodity names in data
cat("\nUnique commodities in data:\n")
print(sort(unique(dt$commodity)))

# Classify: imported if matches pattern, local if matches pattern, ambiguous otherwise
dt[, imported := as.integer(
  commodity %in% imported_commodities |
  grepl("rice|lentil|sugar|oil|flour|bread|pasta|fuel|diesel|gasoline|tea|coffee|chickpea|bean|milk.*powder|canned",
        commodity, ignore.case = TRUE)
)]

dt[, local := as.integer(
  commodity %in% local_commodities |
  grepl("egg|tomato|potato|cucumber|apple|banana|lettuce|onion|garlic",
        commodity, ignore.case = TRUE)
)]

# For triple-diff: exclude ambiguous commodities (neither clearly imported nor local)
dt[, commodity_type := fifelse(imported == 1, "imported",
                               fifelse(local == 1, "local", "ambiguous"))]

cat(sprintf("\nCommodity classification:\n"))
print(dt[, .N, by = commodity_type])
cat("\nImported commodities:\n")
print(sort(unique(dt[imported == 1, commodity])))
cat("\nLocal commodities:\n")
print(sort(unique(dt[local == 1, commodity])))

# ---- 5. Price cleaning ----
# Use 'price' column (or 'usdprice' if available)
# Check which price columns exist
price_cols <- grep("price", names(dt), ignore.case = TRUE, value = TRUE)
cat(sprintf("\nPrice columns: %s\n", paste(price_cols, collapse = ", ")))

# Use the main price column (in LBP)
dt[, price_lbp := as.numeric(price)]

# Remove zero/negative/missing prices
n_before <- nrow(dt)
dt <- dt[!is.na(price_lbp) & price_lbp > 0]
cat(sprintf("Removed %d rows with missing/zero prices (%.1f%%)\n",
            n_before - nrow(dt), 100 * (n_before - nrow(dt)) / n_before))

# Log price
dt[, log_price := log(price_lbp)]

# USD price if available
if ("usdprice" %in% names(dt)) {
  dt[, price_usd := as.numeric(usdprice)]
  dt[price_usd <= 0 | is.na(price_usd), price_usd := NA]
  dt[, log_price_usd := log(price_usd)]
}

# ---- 6. Create panel identifiers ----
# Market-commodity pair
dt[, mc_id := paste0(market, "_", commodity)]
dt[, mc_num := as.integer(factor(mc_id))]

# Time period (monthly)
dt[, t := as.integer(factor(ym))]

# ---- 7. Restrict sample window ----
# Main analysis: Jan 2019 - Dec 2021 (19 months pre + 17 months post)
# Extended: Jan 2018 - Jun 2022 (for longer pre-trends)
dt_main <- dt[ym >= "2019-01-01" & ym <= "2021-12-31"]
dt_extended <- dt[ym >= "2018-01-01" & ym <= "2022-06-30"]

cat(sprintf("\nMain sample (2019-2021): %d obs, %d market-commodity pairs\n",
            nrow(dt_main), uniqueN(dt_main$mc_id)))
cat(sprintf("Extended sample (2018-2022H1): %d obs, %d market-commodity pairs\n",
            nrow(dt_extended), uniqueN(dt_extended$mc_id)))

# ---- 8. Summary statistics ----
cat("\n--- PRE-EXPLOSION SUMMARY (2019-01 to 2020-07) ---\n")
pre <- dt_main[post == 0]
cat(sprintf("Observations: %d\n", nrow(pre)))
cat(sprintf("Markets: %d\n", uniqueN(pre$market)))
cat(sprintf("Commodities: %d\n", uniqueN(pre$commodity)))
cat(sprintf("Mean price (LBP): %.0f\n", mean(pre$price_lbp, na.rm = TRUE)))
cat(sprintf("SD price (LBP): %.0f\n", sd(pre$price_lbp, na.rm = TRUE)))

cat("\n--- POST-EXPLOSION SUMMARY (2020-08 to 2021-12) ---\n")
pst <- dt_main[post == 1]
cat(sprintf("Observations: %d\n", nrow(pst)))
cat(sprintf("Mean price (LBP): %.0f\n", mean(pst$price_lbp, na.rm = TRUE)))
cat(sprintf("SD price (LBP): %.0f\n", sd(pst$price_lbp, na.rm = TRUE)))

# ---- 9. Save cleaned data ----
fwrite(dt_main, file.path(data_dir, "panel_main.csv"))
fwrite(dt_extended, file.path(data_dir, "panel_extended.csv"))
fwrite(dt, file.path(data_dir, "panel_full.csv"))

cat("\nCleaned data saved.\n")
