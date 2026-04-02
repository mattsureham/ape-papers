# 02_clean_data.R — Clean and prepare PPR data for bunching analysis
# Ireland HTB Price Bunching (apep_1297)

source("00_packages.R")

raw <- readRDS("../data/ppr_raw.rds")
cat("Loaded", nrow(raw), "raw transactions\n")

# Standardize column names
setnames(raw, c("date_raw", "address", "county", "eircode", "price_raw",
                "not_full_market", "vat_exclusive", "description", "size_desc", "source_year"))

# --- Parse price ---
# Format: "€250,000.00" or similar with euro sign and commas
raw[, price := as.numeric(gsub("[^0-9.]", "", price_raw))]
cat("Price parsing: ", sum(is.na(raw$price)), "NAs out of", nrow(raw), "\n")

# Drop missing prices
raw <- raw[!is.na(price) & price > 0]
cat("After dropping missing/zero prices:", nrow(raw), "\n")

# --- Parse date ---
raw[, sale_date := as.Date(date_raw, format = "%d/%m/%Y")]
raw[, year := year(sale_date)]
raw[, month := month(sale_date)]
raw[, quarter := quarter(sale_date)]
raw[, ym := year * 100 + month]

# --- New build indicator ---
# Description field contains "New Dwelling house /Apartment" or "Second-Hand Dwelling house /Apartment"
raw[, new_build := grepl("New", description, ignore.case = TRUE)]
raw[, second_hand := grepl("Second", description, ignore.case = TRUE)]

cat("\nProperty type breakdown:\n")
print(raw[, .N, by = .(new_build, second_hand)])

# --- HTB policy periods ---
# HTB launched January 2017, enhanced July 2020 (10%/€30K), reverted Dec 2022 (5%/€20K)
# Extended multiple times, still active as of 2025
raw[, period := fcase(
  sale_date < as.Date("2017-01-01"), "pre_htb",
  sale_date < as.Date("2020-07-23"), "htb_standard",    # 5% of price, max €20K
  sale_date < as.Date("2022-01-01"), "htb_enhanced",     # 10% of price, max €30K
  default = "htb_post_enhanced"                          # Reverted to 5%/€20K
)]

# --- Dublin indicator ---
dublin_counties <- c("Dublin", "Dublin 1", "Dublin 2", "Dublin 3", "Dublin 4",
                     "Dublin 5", "Dublin 6", "Dublin 6W", "Dublin 7", "Dublin 8",
                     "Dublin 9", "Dublin 10", "Dublin 11", "Dublin 12", "Dublin 13",
                     "Dublin 14", "Dublin 15", "Dublin 16", "Dublin 17", "Dublin 18",
                     "Dublin 20", "Dublin 22", "Dublin 24")
raw[, dublin := grepl("Dublin", county, ignore.case = TRUE)]

# --- VAT adjustment ---
# New builds are typically VAT-inclusive (13.5% rate)
# If VAT Exclusive = "Yes", we need to gross up
raw[, vat_excl := grepl("Yes", vat_exclusive, ignore.case = TRUE)]
# For consistency, work with VAT-inclusive prices
# New builds with "VAT Exclusive" flag: gross up by 13.5%
raw[, price_adj := fifelse(new_build & vat_excl, price * 1.135, price)]

# --- Key analysis variables ---
# Price bins for bunching (€5K bins)
raw[, price_bin_5k := floor(price_adj / 5000) * 5000]
# Price bins for finer analysis (€2.5K bins)
raw[, price_bin_2500 := floor(price_adj / 2500) * 2500]
# Price bins (€10K)
raw[, price_bin_10k := floor(price_adj / 10000) * 10000]

# --- Drop non-full-market-price transactions ---
raw[, not_fmp := grepl("Yes", not_full_market, ignore.case = TRUE)]
cat("\nNot full market price:", sum(raw$not_fmp), "transactions\n")
clean <- raw[not_fmp == FALSE]
cat("After dropping non-FMP:", nrow(clean), "\n")

# --- Sample restrictions ---
# Focus on €100K-€1M range for bunching analysis (captures the relevant range around €500K)
analysis <- clean[price_adj >= 100000 & price_adj <= 1000000]
cat("Analysis sample (€100K-€1M):", nrow(analysis), "\n")

# --- Summary stats ---
cat("\n=== Summary by period and property type ===\n")
summary_tab <- analysis[, .(
  n = .N,
  mean_price = mean(price_adj),
  median_price = median(price_adj),
  sd_price = sd(price_adj),
  pct_dublin = mean(dublin) * 100,
  pct_near_500k = mean(price_adj >= 450000 & price_adj <= 550000) * 100
), by = .(period, new_build)]
print(summary_tab[order(period, new_build)])

# --- Bunching diagnostics ---
cat("\n=== New builds near €500K threshold ===\n")
nb_near <- analysis[new_build == TRUE & price_adj >= 450000 & price_adj <= 550000]
cat("New builds €450K-€550K:", nrow(nb_near), "\n")
cat("New builds €490K-€510K:", nrow(analysis[new_build == TRUE & price_adj >= 490000 & price_adj <= 510000]), "\n")
cat("New builds €495K-€505K:", nrow(analysis[new_build == TRUE & price_adj >= 495000 & price_adj <= 505000]), "\n")

# Quick bunching check: count in €5K bins near threshold
cat("\n=== Bin counts near €500K (new builds, €5K bins) ===\n")
nb_bins <- analysis[new_build == TRUE & price_adj >= 400000 & price_adj <= 600000,
                     .N, by = price_bin_5k][order(price_bin_5k)]
print(nb_bins)

cat("\n=== Same for second-hand (placebo) ===\n")
sh_bins <- analysis[new_build == FALSE & price_adj >= 400000 & price_adj <= 600000,
                     .N, by = price_bin_5k][order(price_bin_5k)]
print(sh_bins)

# Save clean data
saveRDS(analysis, "../data/ppr_analysis.rds")
cat("\nSaved ppr_analysis.rds with", nrow(analysis), "transactions\n")
