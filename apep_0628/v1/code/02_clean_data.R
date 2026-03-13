###############################################################################
# 02_clean_data.R — Clean trade data and construct treatment variables
# Paper: The Invisible Tariff (apep_0628)
###############################################################################

source("00_packages.R")

# --------------------------------------------------------------------------
# Load raw data
# --------------------------------------------------------------------------
trade_raw <- readRDS("../data/trade_raw.rds")
banned_hs2 <- readRDS("../data/banned_hs2.rds")

cat(sprintf("Raw data: %d observations\n", nrow(trade_raw)))

# --------------------------------------------------------------------------
# Standardize column names
# --------------------------------------------------------------------------
dt <- as.data.table(trade_raw)

# Rename key columns for consistency
if ("primaryValue" %in% names(dt)) {
  setnames(dt, "primaryValue", "import_value", skip_absent = TRUE)
}
if ("cmdCode" %in% names(dt)) {
  setnames(dt, "cmdCode", "hs6", skip_absent = TRUE)
}
if ("reporterCode" %in% names(dt)) {
  setnames(dt, "reporterCode", "reporter_code", skip_absent = TRUE)
}
if ("reporterDesc" %in% names(dt)) {
  setnames(dt, "reporterDesc", "reporter_name", skip_absent = TRUE)
}
if ("reporterISO" %in% names(dt)) {
  setnames(dt, "reporterISO", "reporter_iso", skip_absent = TRUE)
}

# Ensure year is numeric
dt[, year := as.integer(period)]

# --------------------------------------------------------------------------
# Construct HS2 chapter from HS6 code
# --------------------------------------------------------------------------
dt[, hs2 := substr(as.character(hs6), 1, 2)]

# Pad HS2 codes to 2 digits if needed
dt[, hs2 := sprintf("%02s", hs2)]

# --------------------------------------------------------------------------
# Treatment assignment: Banned product indicator
# --------------------------------------------------------------------------
dt[, banned := as.integer(hs2 %in% banned_hs2)]

cat(sprintf("Banned HS2 chapters: %d\n", length(banned_hs2)))
cat(sprintf("HS6 codes flagged as banned: %d\n", dt[banned == 1, uniqueN(hs6)]))
cat(sprintf("HS6 codes NOT banned: %d\n", dt[banned == 0, uniqueN(hs6)]))

# --------------------------------------------------------------------------
# Treatment timing
# --------------------------------------------------------------------------
# CBN circular issued June 23, 2015
# Annual data: 2015 is the treatment year (partial treatment)
# Clean pre: 2012-2014, clean post: 2016-2022
dt[, post := as.integer(year >= 2016)]  # Use 2016+ as post to avoid partial-year contamination

# Nigeria indicator
dt[, nigeria := as.integer(reporter_code == 566 | reporter_iso == "NGA" |
                            grepl("Nigeria", reporter_name, ignore.case = TRUE))]

cat(sprintf("\nNigeria observations: %d\n", sum(dt$nigeria)))
cat(sprintf("Control country observations: %d\n", sum(!dt$nigeria)))

# --------------------------------------------------------------------------
# Drop 2015 (partial treatment year)
# --------------------------------------------------------------------------
dt_clean <- dt[year != 2015]
cat(sprintf("After dropping 2015: %d observations\n", nrow(dt_clean)))

# --------------------------------------------------------------------------
# Aggregate to product-country-year level (ensure no duplicates)
# --------------------------------------------------------------------------
panel <- dt_clean[, .(
  import_value = sum(import_value, na.rm = TRUE),
  n_records = .N
), by = .(reporter_code, reporter_name, reporter_iso, hs6, hs2, year, banned, post, nigeria)]

cat(sprintf("Panel: %d product-country-year observations\n", nrow(panel)))

# --------------------------------------------------------------------------
# Create outcome variables
# --------------------------------------------------------------------------
# Log import value (add $1 to handle zeros)
panel[, log_imports := log(import_value + 1)]

# Inverse hyperbolic sine (handles zeros without arbitrary $1)
panel[, asinh_imports := asinh(import_value)]

# Import value in millions
panel[, imports_millions := import_value / 1e6]

# --------------------------------------------------------------------------
# Create balanced panel for event study
# --------------------------------------------------------------------------
# For Nigeria-only analysis: ensure all HS6 codes appear in all years
nigeria_panel <- panel[nigeria == 1]

# Create complete grid of HS6 x year
all_hs6 <- unique(nigeria_panel$hs6)
all_years <- unique(nigeria_panel$year)
complete_grid <- CJ(hs6 = all_hs6, year = all_years)

# Merge with data, fill missing with zero imports
nigeria_balanced <- merge(complete_grid, nigeria_panel,
                          by = c("hs6", "year"), all.x = TRUE)

# Fill missing values
nigeria_balanced[is.na(import_value), import_value := 0]
nigeria_balanced[is.na(log_imports), log_imports := log(1)]  # log(0+1) = 0
nigeria_balanced[is.na(asinh_imports), asinh_imports := 0]
nigeria_balanced[, reporter_code := 566]
nigeria_balanced[, reporter_name := "Nigeria"]
nigeria_balanced[, reporter_iso := "NGA"]
nigeria_balanced[, nigeria := 1]
nigeria_balanced[is.na(hs2), hs2 := substr(as.character(hs6), 1, 2)]
nigeria_balanced[is.na(banned), banned := as.integer(hs2 %in% banned_hs2)]
nigeria_balanced[is.na(post), post := as.integer(year >= 2016)]

# Event time relative to 2015 (dropping 2015 itself)
nigeria_balanced[, event_time := year - 2015]

cat(sprintf("\nNigeria balanced panel: %d obs (%d products x %d years)\n",
            nrow(nigeria_balanced), length(all_hs6), length(all_years)))
cat(sprintf("  Banned products: %d\n", nigeria_balanced[banned == 1, uniqueN(hs6)]))
cat(sprintf("  Control products: %d\n", nigeria_balanced[banned == 0, uniqueN(hs6)]))

# --------------------------------------------------------------------------
# Summary statistics
# --------------------------------------------------------------------------
cat("\n=== Summary Statistics ===\n")
cat("\nNigeria: Mean imports by banned status and period:\n")
print(nigeria_balanced[, .(
  mean_imports_M = mean(imports_millions, na.rm = TRUE),
  median_imports_M = median(imports_millions, na.rm = TRUE),
  n_positive = sum(import_value > 0),
  n_zero = sum(import_value == 0),
  n_total = .N
), by = .(banned, post)])

# --------------------------------------------------------------------------
# Save cleaned data
# --------------------------------------------------------------------------
saveRDS(panel, "../data/panel.rds")
saveRDS(nigeria_balanced, "../data/nigeria_balanced.rds")

cat("\nSaved panel.rds and nigeria_balanced.rds\n")
