## 01_fetch_data.R — Fetch VAT revenue and GDP data from Eurostat
## apep_0830: VAT Receipt Lotteries and Compliance Gaps

source("00_packages.R")

cat("=== Fetching Eurostat data ===\n")

# --- 1. VAT Revenue (gov_10a_taxag) ---
# Tax category D211 = VAT, sector S13 = General government
# Unit: MIO_EUR (millions of euros)
cat("Fetching VAT revenue (gov_10a_taxag)...\n")
vat_raw <- get_eurostat("gov_10a_taxag",
  filters = list(
    na_item = "D211",
    sector  = "S13",
    unit    = "MIO_EUR"
  ),
  time_format = "num"
)
stopifnot("VAT revenue fetch failed" = nrow(vat_raw) > 0)
cat(sprintf("  VAT revenue: %d rows\n", nrow(vat_raw)))

# --- 2. GDP at current prices (nama_10_gdp) ---
# B1GQ = GDP at market prices, CP_MEUR = current prices in millions EUR
cat("Fetching GDP (nama_10_gdp)...\n")
gdp_raw <- get_eurostat("nama_10_gdp",
  filters = list(
    na_item = "B1GQ",
    unit    = "CP_MEUR"
  ),
  time_format = "num"
)
stopifnot("GDP fetch failed" = nrow(gdp_raw) > 0)
cat(sprintf("  GDP: %d rows\n", nrow(gdp_raw)))

# --- 3. Income tax revenue (D51, direct taxes) for placebo ---
cat("Fetching income tax revenue for placebo...\n")
income_tax_raw <- get_eurostat("gov_10a_taxag",
  filters = list(
    na_item = "D51",
    sector  = "S13",
    unit    = "MIO_EUR"
  ),
  time_format = "num"
)
stopifnot("Income tax fetch failed" = nrow(income_tax_raw) > 0)
cat(sprintf("  Income tax: %d rows\n", nrow(income_tax_raw)))

# --- 4. Total tax revenue (D2+D5+D91 or OTR) for normalization ---
cat("Fetching total tax revenue...\n")
total_tax_raw <- get_eurostat("gov_10a_taxag",
  filters = list(
    na_item = "D2",
    sector  = "S13",
    unit    = "MIO_EUR"
  ),
  time_format = "num"
)
stopifnot("Total tax fetch failed" = nrow(total_tax_raw) > 0)
cat(sprintf("  Total taxes on production: %d rows\n", nrow(total_tax_raw)))

# --- Save raw data ---
saveRDS(vat_raw, "../data/vat_revenue_raw.rds")
saveRDS(gdp_raw, "../data/gdp_raw.rds")
saveRDS(income_tax_raw, "../data/income_tax_raw.rds")
saveRDS(total_tax_raw, "../data/total_tax_raw.rds")

cat("=== Data fetch complete ===\n")
cat(sprintf("Countries in VAT data: %s\n",
  paste(sort(unique(vat_raw$geo)), collapse = ", ")))
cat(sprintf("Years in VAT data: %d to %d\n",
  min(vat_raw$time, na.rm = TRUE), max(vat_raw$time, na.rm = TRUE)))
