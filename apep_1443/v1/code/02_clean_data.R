## 02_clean_data.R — Clean Taiwan transaction data and construct repeat-sale holding periods
## Optimized version: select columns early, hash property IDs
source("00_packages.R")

data_dir <- "../data"

cat("=== Loading raw transaction data (selected columns only) ===\n")
dt <- fread(file.path(data_dir, "taiwan_raw_transactions.csv"),
            encoding = "UTF-8", fill = TRUE, showProgress = TRUE,
            select = c("鄉鎮市區", "交易標的", "土地位置建物門牌",
                       "交易年月日", "總價元", "單價元平方公尺",
                       "建物移轉總面積平方公尺", "建物型態", "source_file"))
cat(sprintf("Raw data: %s rows\n", format(nrow(dt), big.mark = ",")))

# Skip English header row
dt <- dt[!grepl("^(The villages|transaction sign)", `交易標的`, ignore.case = TRUE)]

# ---- Parse ROC dates ----
cat("Parsing dates...\n")
dt[, txn_str := as.character(`交易年月日`)]
dt[, txn_str := trimws(txn_str)]
dt[nchar(txn_str) == 6, txn_str := paste0("0", txn_str)]

dt[, roc_yr := as.integer(substr(txn_str, 1, 3))]
dt[, mon := as.integer(substr(txn_str, 4, 5))]
dt[, day := as.integer(substr(txn_str, 6, 7))]
dt[, west_yr := roc_yr + 1911L]

# Filter valid dates
dt <- dt[!is.na(roc_yr) & mon >= 1 & mon <= 12 & day >= 1 & day <= 31 & west_yr >= 2005 & west_yr <= 2025]
dt[, txn_date := as.Date(sprintf("%04d-%02d-%02d", west_yr, mon, day))]
dt <- dt[!is.na(txn_date)]
cat(sprintf("Valid dated rows: %s\n", format(nrow(dt), big.mark = ",")))

# ---- Clean numerics ----
dt[, total_price := as.numeric(gsub("[^0-9.]", "", `總價元`))]
dt[, unit_price := as.numeric(gsub("[^0-9.]", "", `單價元平方公尺`))]
dt[, area := as.numeric(gsub("[^0-9.]", "", `建物移轉總面積平方公尺`))]

# ---- Create hashed property ID (much faster for grouping) ----
cat("Creating property identifiers...\n")
dt[, prop_id := paste0(`鄉鎮市區`, "|", `土地位置建物門牌`)]

# Filter to building transactions
building_mask <- grepl("(房地|建物)", dt$`交易標的`)
cat(sprintf("Building transactions: %s / %s\n", format(sum(building_mask), big.mark = ","), format(nrow(dt), big.mark = ",")))
if (sum(building_mask) > 50000) {
  dt <- dt[building_mask]
}

# Drop unnecessary columns to save memory
dt[, c("交易標的", "土地位置建物門牌", "鄉鎮市區_orig") := NULL]
# Keep district for later
setnames(dt, "鄉鎮市區", "district", skip_absent = TRUE)

cat(sprintf("Working dataset: %s rows\n", format(nrow(dt), big.mark = ",")))

# ---- Find repeat sales efficiently ----
cat("\nFinding repeat sales...\n")

# Count transactions per property
prop_counts <- dt[, .N, by = prop_id]
repeat_ids <- prop_counts[N >= 2, prop_id]
cat(sprintf("Properties with 2+ transactions: %s\n", format(length(repeat_ids), big.mark = ",")))

# Subset to repeat properties only
rp <- dt[prop_id %chin% repeat_ids]
cat(sprintf("Repeat-sale rows: %s\n", format(nrow(rp), big.mark = ",")))

# Sort and lag
cat("Sorting and lagging...\n")
setorder(rp, prop_id, txn_date)
rp[, prev_date := shift(txn_date, 1L, type = "lag"), by = prop_id]
rp[, prev_price := shift(total_price, 1L, type = "lag"), by = prop_id]

# Keep only rows with a prior transaction (the "sale" in a pair)
pairs <- rp[!is.na(prev_date)]
cat(sprintf("Repeat-sale pairs: %s\n", format(nrow(pairs), big.mark = ",")))

# ---- Compute holding period ----
pairs[, holding_days := as.integer(txn_date - prev_date)]
pairs[, holding_years := holding_days / 365.25]

# Filter: positive and < 20 years
pairs <- pairs[holding_days > 0 & holding_days < 7300]

# ---- Rename for clarity ----
setnames(pairs, c("txn_date", "total_price", "prev_date", "prev_price"),
         c("sale_date", "sale_price", "acq_date", "acq_price"))

pairs[, sale_year := year(sale_date)]

# ---- Tax regime ----
pairs[, tax_regime := fcase(
  acq_date < as.Date("2016-01-01"), "exempt",
  acq_date >= as.Date("2016-01-01") & acq_date < as.Date("2021-07-01"), "tax1",
  acq_date >= as.Date("2021-07-01"), "tax2"
)]

# ---- Price return ----
pairs[, price_return := fifelse(acq_price > 0, (sale_price - acq_price) / acq_price, NA_real_)]

# ---- Keep relevant columns ----
pairs <- pairs[, .(prop_id, acq_date, acq_price, sale_date, sale_price,
                    unit_price, district, area, sale_year,
                    holding_days, holding_years, tax_regime, price_return,
                    building_type = `建物型態`)]

# ---- Save ----
fwrite(pairs, file.path(data_dir, "repeat_sale_pairs.csv"))
cat(sprintf("\nSaved: %s (%s rows)\n", file.path(data_dir, "repeat_sale_pairs.csv"),
            format(nrow(pairs), big.mark = ",")))

# ---- Summary ----
cat("\n=== Summary Statistics ===\n")
cat(sprintf("Total repeat-sale pairs: %s\n", format(nrow(pairs), big.mark = ",")))
cat(sprintf("Date range: %s to %s\n", min(pairs$sale_date), max(pairs$sale_date)))
cat(sprintf("Mean holding period: %.0f days (%.1f years)\n",
            mean(pairs$holding_days), mean(pairs$holding_years)))

cat("\nTax regime distribution:\n")
print(pairs[, .N, by = tax_regime][order(tax_regime)])

cat("\nSales by year:\n")
print(pairs[, .N, by = sale_year][order(sale_year)])
