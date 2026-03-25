## 02_clean_data.R — Prepare analysis dataset
## apep_0952: Australian Stamp Duty Threshold Bunching

source("00_packages.R")

sales <- fread("../data/nsw_residential_sales.csv")
sales[, contract_date := as.Date(contract_date)]
sales[, settlement_date := as.Date(settlement_date)]

cat("Raw residential sales:", nrow(sales), "\n")

## ---- Define reform periods ----
# NSW threshold changed from $650K to $800K on July 1, 2023
reform_date <- as.Date("2023-07-01")

sales[, post_reform := contract_date >= reform_date]
sales[, period := ifelse(post_reform, "Post-reform", "Pre-reform")]

## ---- Define price bins for bunching analysis ----
# Use $5,000 bins for the histogram
bin_width <- 5000
sales[, price_bin := floor(purchase_price / bin_width) * bin_width]

## ---- Area cleaning ----
# area_unit: M = square meters, H = hectares
sales[area_unit == "H", area_sqm := area * 10000]
sales[area_unit == "M", area_sqm := area]
sales[is.na(area_unit) | area_unit == "", area_sqm := NA_real_]

## ---- Property type classification ----
# description field: RESIDENCE, UNIT, VACANT LAND, etc.
sales[, prop_type := fcase(
  grepl("UNIT|APART|FLAT|STRATA", description, ignore.case = TRUE), "Unit",
  grepl("RESID|HOUSE|COTTAGE|DWELLING|VILLA|TERRACE|SEMI", description, ignore.case = TRUE), "House",
  grepl("VACANT|LAND", description, ignore.case = TRUE), "Vacant Land",
  default = "Other"
)]

## ---- Create analysis variables ----
sales[, year := year(contract_date)]
sales[, month := month(contract_date)]
sales[, quarter := quarter(contract_date)]
sales[, yr_qtr := paste0(year, "Q", quarter)]

# Distance from $800K threshold (in $000s)
sales[, dist_800k := (purchase_price - 800000) / 1000]

# Distance from $650K threshold (old, in $000s)
sales[, dist_650k := (purchase_price - 650000) / 1000]

# Indicator: near $800K threshold (within $50K)
sales[, near_800k := abs(dist_800k) <= 50]

# Log price for regressions
sales[, log_price := log(purchase_price)]

## ---- Summary statistics ----
cat("\n--- Summary by period ---\n")
print(sales[, .(
  n_sales = .N,
  mean_price = mean(purchase_price),
  median_price = median(purchase_price),
  p25 = quantile(purchase_price, 0.25),
  p75 = quantile(purchase_price, 0.75),
  mean_area = mean(area_sqm, na.rm = TRUE),
  pct_house = mean(prop_type == "House") * 100,
  pct_unit = mean(prop_type == "Unit") * 100
), by = period])

cat("\n--- Sales near $800K by period ---\n")
print(sales[near_800k == TRUE, .(
  n = .N,
  mean_price = mean(purchase_price),
  mean_area = mean(area_sqm, na.rm = TRUE),
  pct_house = mean(prop_type == "House") * 100
), by = period])

## ---- Price bin counts for bunching analysis ----
# Focus on $500K-$1.1M range
analysis_range <- sales[purchase_price >= 500000 & purchase_price <= 1100000]

bins_pre <- analysis_range[post_reform == FALSE, .(count = .N), by = price_bin][order(price_bin)]
bins_post <- analysis_range[post_reform == TRUE, .(count = .N), by = price_bin][order(price_bin)]

# Merge
bins <- merge(bins_pre, bins_post, by = "price_bin", suffixes = c("_pre", "_post"), all = TRUE)
bins[is.na(count_pre), count_pre := 0]
bins[is.na(count_post), count_post := 0]

# Normalize to density (share of sales in each bin)
bins[, share_pre := count_pre / sum(count_pre)]
bins[, share_post := count_post / sum(count_post)]

fwrite(bins, "../data/price_bins.csv")
fwrite(sales, "../data/nsw_sales_clean.csv")

cat("\nCleaned data saved. Total:", nrow(sales), "sales\n")
cat("Analysis range ($500K-$1.1M):", nrow(analysis_range), "sales\n")
cat("  Pre-reform:", nrow(analysis_range[post_reform == FALSE]), "\n")
cat("  Post-reform:", nrow(analysis_range[post_reform == TRUE]), "\n")
