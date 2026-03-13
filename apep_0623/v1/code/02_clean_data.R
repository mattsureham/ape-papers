## 02_clean_data.R — Construct analysis dataset
## APEP apep_0623: The Symmetric Tax Shock

source("00_packages.R")

data_dir <- "../data"

## ============================================================
## 1. Process Zillow ZHVI — reshape wide to long
## ============================================================
cat("=== Processing Zillow ZHVI ===\n")

zhvi_raw <- fread(file.path(data_dir, "zillow_zhvi_zip.csv"))

# Identify date columns (format: YYYY-MM-DD)
date_cols <- grep("^\\d{4}-\\d{2}", names(zhvi_raw), value = TRUE)
id_cols <- c("RegionID", "RegionName", "RegionType", "StateName", "State",
             "City", "Metro", "CountyName", "SizeRank")
id_cols <- intersect(id_cols, names(zhvi_raw))

cat("  Date columns span:", min(date_cols), "to", max(date_cols), "\n")
cat("  Number of zip codes:", nrow(zhvi_raw), "\n")

# Reshape to long format
zhvi_long <- melt(zhvi_raw,
                  id.vars = id_cols,
                  measure.vars = date_cols,
                  variable.name = "date_str",
                  value.name = "zhvi",
                  variable.factor = FALSE)

# Parse dates
zhvi_long[, date := as.Date(date_str)]
zhvi_long[, year := year(date)]
zhvi_long[, month := month(date)]
zhvi_long[, ym := year * 12 + month]  # Numeric year-month for FE

# Clean zip code
zhvi_long[, zip5 := sprintf("%05d", as.integer(RegionName))]

# Drop missing ZHVI
n_before <- nrow(zhvi_long)
zhvi_long <- zhvi_long[!is.na(zhvi) & zhvi > 0]
n_after <- nrow(zhvi_long)
cat("  Dropped", n_before - n_after, "missing ZHVI observations\n")
cat("  Remaining:", format(n_after, big.mark = ","), "observations\n")

# Log ZHVI
zhvi_long[, log_zhvi := log(zhvi)]

# Keep 2014-2026 for analysis
zhvi_long <- zhvi_long[year >= 2014]
cat("  After restricting to 2014+:", format(nrow(zhvi_long), big.mark = ","), "observations\n")
cat("  Unique zip codes:", length(unique(zhvi_long$zip5)), "\n")

## ============================================================
## 2. Process IRS SOI — SALT exposure by zip code
## ============================================================
cat("\n=== Processing IRS SOI (2017) ===\n")

soi <- fread(file.path(data_dir, "irs_soi_2017_zip.csv"))

# Standardize column names to uppercase
old_names <- names(soi)
setnames(soi, toupper(old_names))

# Check what SALT-related columns exist
cat("  Looking for SALT columns...\n")
all_cols <- names(soi)
salt_candidates <- grep("A18|N18", all_cols, value = TRUE)
cat("  Found:", paste(salt_candidates, collapse = ", "), "\n")

# IRS SOI 2017 uses:
# A18300 = Total taxes paid amount (state/local taxes)
# N18300 = Number of returns with taxes paid deduction
# A18500 = Real estate taxes amount (if available separately)
# N18500 = Number of returns with real estate taxes

# Construct SALT exposure measure
# Clean zip code field
zip_col <- intersect(c("ZIPCODE", "ZIP", "STATEFIPS"), all_cols)
if ("ZIPCODE" %in% all_cols) {
  soi[, zip5 := sprintf("%05d", as.integer(ZIPCODE))]
} else {
  stop("FATAL: Cannot find zip code column in IRS SOI data")
}

# No AGI_STUB = 0 total row in 2017 data — aggregate across all income classes
# Sum A18300 (amount) and N18300 (returns) within each zip code
cat("  Aggregating across all AGI stubs per zip code...\n")

# Remove state-level aggregates (zip = 00000 or 99999)
soi <- soi[!zip5 %in% c("00000", "99999")]

# Aggregate SALT fields across all income brackets within each zip
soi_total <- soi[, .(
  A18300 = sum(as.numeric(A18300), na.rm = TRUE),
  N18300 = sum(as.numeric(N18300), na.rm = TRUE),
  A18500 = sum(as.numeric(A18500), na.rm = TRUE),
  N18500 = sum(as.numeric(N18500), na.rm = TRUE),
  N1 = sum(as.numeric(N1), na.rm = TRUE),
  STATEFIPS = first(STATEFIPS)
), by = zip5]

cat("  Unique zip codes after aggregation:", nrow(soi_total), "\n")

# Calculate average SALT deduction (A18300 is in thousands of dollars)
soi_total[, salt_amount := A18300 * 1000]  # Convert to dollars
soi_total[, salt_returns := N18300]
cat("  Using A18300 (total taxes paid deduction, summed across AGI classes)\n")

# Average SALT per itemizing return
soi_total[salt_returns > 0, avg_salt := salt_amount / salt_returns]
soi_total[salt_returns == 0 | is.na(salt_returns), avg_salt := 0]

# SALT share (fraction of returns claiming SALT)
soi_total[N1 > 0, salt_share := salt_returns / N1]

# Binary treatment: average SALT > $10,000 (above cap)
soi_total[, above_cap := as.integer(avg_salt > 10000)]

# Continuous treatment: SALT exposure (standardized)
soi_total[, salt_exposure := avg_salt / 1000]  # in thousands for interpretability

# State FIPS
soi_total[, state_fips := sprintf("%02d", as.integer(STATEFIPS))]

# Select relevant columns
salt_data <- soi_total[, .(zip5, state_fips, avg_salt, salt_exposure,
                            above_cap, salt_returns, salt_amount,
                            total_returns = N1,
                            salt_share)]
salt_data <- salt_data[!is.na(avg_salt)]

cat("  Zip codes with SALT data:", nrow(salt_data), "\n")
cat("  Zip codes above $10K cap:", sum(salt_data$above_cap, na.rm = TRUE),
    "(", round(100 * mean(salt_data$above_cap, na.rm = TRUE), 1), "%)\n")
cat("  Average SALT deduction: $", format(round(mean(salt_data$avg_salt, na.rm = TRUE)), big.mark = ","), "\n")
cat("  Median SALT deduction: $", format(round(median(salt_data$avg_salt, na.rm = TRUE)), big.mark = ","), "\n")

## ============================================================
## 3. Merge ZHVI with SALT exposure
## ============================================================
cat("\n=== Merging datasets ===\n")

panel <- merge(zhvi_long, salt_data, by = "zip5", all.x = FALSE)
cat("  Merged panel:", format(nrow(panel), big.mark = ","), "observations\n")
cat("  Unique zip codes:", length(unique(panel$zip5)), "\n")
cat("  Date range:", as.character(min(panel$date)), "to", as.character(max(panel$date)), "\n")

## ============================================================
## 4. Construct treatment variables
## ============================================================
cat("\n=== Constructing treatment variables ===\n")

# TCJA treatment (Jan 2018)
panel[, post_tcja := as.integer(date >= as.Date("2018-01-01"))]

# OBBB treatment (Jan 2025, retroactive)
panel[, post_obbb := as.integer(date >= as.Date("2025-01-01"))]

# Interacted treatment (continuous)
panel[, treat_tcja := post_tcja * salt_exposure]
panel[, treat_obbb := post_obbb * salt_exposure]

# Interacted treatment (binary)
panel[, treat_tcja_bin := post_tcja * above_cap]
panel[, treat_obbb_bin := post_obbb * above_cap]

# SALT quintiles for dose-response (assign from salt_data using frank)
salt_data[, salt_quintile := paste0("Q", ceiling(frank(avg_salt, ties.method = "random") /
                                                  .N * 5))]
salt_data_q <- salt_data[, .(zip5, salt_quintile)]
panel <- merge(panel, salt_data_q, by = "zip5", all.x = TRUE)

# Period indicators for event study
panel[, period := fcase(
  date < as.Date("2018-01-01"), "pre_tcja",
  date >= as.Date("2018-01-01") & date < as.Date("2025-01-01"), "post_tcja",
  date >= as.Date("2025-01-01"), "post_obbb"
)]

# Relative time to TCJA (in months)
panel[, rel_month_tcja := as.integer(difftime(date, as.Date("2018-01-01"), units = "days")) %/% 30]

# Create metro identifier from Zillow's Metro column
if ("Metro" %in% names(panel)) {
  panel[, metro_id := as.integer(factor(Metro))]
}

# Numeric identifiers for FE
panel[, zip_id := as.integer(factor(zip5))]
panel[, state_id := as.integer(factor(state_fips))]

## ============================================================
## 5. Create SALT quintile breakdowns for summary stats
## ============================================================
cat("\n=== Summary by SALT quintile ===\n")
quintile_summary <- panel[year == 2017 & !is.na(salt_quintile), .(
  n_zips = uniqueN(zip5),
  mean_zhvi = mean(zhvi, na.rm = TRUE),
  mean_salt = mean(avg_salt, na.rm = TRUE),
  pct_above_cap = 100 * mean(above_cap, na.rm = TRUE),
  mean_salt_share = mean(salt_share, na.rm = TRUE)
), by = salt_quintile]
print(quintile_summary[order(salt_quintile)])

## ============================================================
## 6. Save analysis dataset
## ============================================================
cat("\n=== Saving analysis dataset ===\n")
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
fwrite(salt_data, file.path(data_dir, "salt_exposure.csv"))

cat("Panel saved:", format(nrow(panel), big.mark = ","), "observations\n")
cat("  Zip codes:", length(unique(panel$zip5)), "\n")
cat("  Months:", length(unique(panel$date)), "\n")
cat("  Years:", paste(range(panel$year), collapse = "-"), "\n")
