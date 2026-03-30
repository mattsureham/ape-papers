## 02_clean_data.R — Build analysis panels from raw data
## Constructs: (1) LA-quarter panel with treatment timing
##             (2) Transaction-level PPD with LA linkage

source("00_packages.R")

DATA_DIR <- "../data"

# ===========================================================================
# 1. Clean UK HPI — LA-quarter panel with average prices
# ===========================================================================
cat("--- Cleaning UK HPI data ---\n")

hpi <- fread(file.path(DATA_DIR, "uk_hpi_full.csv"))

# Parse date (DD/MM/YYYY format)
hpi[, date := as.Date(Date, format = "%d/%m/%Y")]
hpi[, year := year(date)]
hpi[, quarter := quarter(date)]
hpi[, yq := year + (quarter - 1) / 4]  # numeric year-quarter

# Keep only English and Welsh LAs (E06=unitary, E07=district, E08=metro borough,
# E09=London borough, W06=Welsh unitary)
la_codes <- grep("^(E0[6-9]|W06)", unique(hpi$AreaCode), value = TRUE)
hpi_la <- hpi[AreaCode %in% la_codes]

cat(sprintf("HPI LA-level: %d rows, %d unique LAs\n", nrow(hpi_la), length(unique(hpi_la$AreaCode))))

# Aggregate to quarterly (HPI is monthly — take Q3 month = end-of-quarter snapshot)
# Use month 3 of each quarter (March, June, September, December) for consistency
hpi_la[, month := month(date)]
hpi_la[, qtr_month := ifelse(month %in% c(3, 6, 9, 12), TRUE, FALSE)]

# Take quarterly average of monthly prices
hpi_q <- hpi_la[year >= 2005, .(
  avg_price = mean(AveragePrice, na.rm = TRUE),
  sales_volume = sum(SalesVolume, na.rm = TRUE),
  detached_price = mean(as.numeric(DetachedPrice), na.rm = TRUE),
  semi_price = mean(as.numeric(SemiDetachedPrice), na.rm = TRUE),
  terraced_price = mean(as.numeric(TerracedPrice), na.rm = TRUE),
  flat_price = mean(as.numeric(FlatPrice), na.rm = TRUE)
), by = .(la_code = AreaCode, la_name = RegionName, year, quarter)]

hpi_q[, yq := year + (quarter - 1) / 4]

cat(sprintf("Quarterly panel: %d LA-quarters, %d LAs, years %d-%d\n",
            nrow(hpi_q), length(unique(hpi_q$la_code)),
            min(hpi_q$year), max(hpi_q$year)))

# ===========================================================================
# 2. Define treatment: when does LA median cross GBP 450K?
# ===========================================================================
cat("\n--- Defining treatment timing ---\n")

LISA_CAP <- 450000
LISA_START_YQ <- 2017.25  # LISA launched April 2017 = Q2 2017

# For each LA, find the first quarter where avg_price >= 450K
# Only count crossings AFTER LISA launch (pre-LISA crossings are irrelevant)
treatment_timing <- hpi_q[year >= 2010, .(
  first_above_450k = {
    above <- yq[avg_price >= LISA_CAP & yq >= LISA_START_YQ]
    if (length(above) > 0) min(above) else NA_real_
  },
  ever_above_450k = any(avg_price >= LISA_CAP & yq >= LISA_START_YQ),
  price_at_lisa_launch = {
    launch_prices <- avg_price[abs(yq - LISA_START_YQ) < 0.1]
    if (length(launch_prices) > 0) mean(launch_prices) else NA_real_
  },
  max_price = max(avg_price, na.rm = TRUE),
  min_price = min(avg_price[year >= 2010], na.rm = TRUE)
), by = .(la_code, la_name)]

# Classify LAs
treatment_timing[, treated := ever_above_450k]
treatment_timing[, group := fifelse(treated, "Treated", "Control")]

n_treated <- sum(treatment_timing$treated, na.rm = TRUE)
n_control <- sum(!treatment_timing$treated, na.rm = TRUE)
cat(sprintf("Treatment groups: %d treated LAs (crossed 450K), %d control LAs\n",
            n_treated, n_control))

# Show treatment timing distribution
if (n_treated > 0) {
  timing_dist <- treatment_timing[treated == TRUE, .(
    n_las = .N
  ), by = .(cross_year = floor(first_above_450k))]
  setorder(timing_dist, cross_year)
  cat("\nTreatment timing (year of first crossing):\n")
  print(timing_dist)
}

# ===========================================================================
# 3. Merge treatment info into quarterly panel
# ===========================================================================
panel <- merge(hpi_q, treatment_timing[, .(la_code, first_above_450k, treated, group)],
               by = "la_code", all.x = TRUE)

# Create post-treatment indicator
panel[, post := fifelse(!is.na(first_above_450k) & yq >= first_above_450k, 1L, 0L)]

# Event time (quarters relative to treatment)
panel[, event_time := fifelse(treated,
                              as.integer(round((yq - first_above_450k) * 4)),
                              NA_integer_)]

# Create Callaway-Sant'Anna group variable (first treatment period as integer)
# CS requires group = 0 for never-treated
panel[, g := fifelse(treated,
                     as.integer(round(first_above_450k * 4)),  # quarter index
                     0L)]

cat(sprintf("\nPanel: %d rows, %d LAs, %d treated\n",
            nrow(panel), length(unique(panel$la_code)), n_treated))

# ===========================================================================
# 4. Process PPD for transaction-level analysis
#    Focus on post-2010, aggregate to LA-quarter-property-type cells
# ===========================================================================
cat("\n--- Processing PPD data ---\n")

ppd_dir <- file.path(DATA_DIR, "ppd")
ppd_files <- list.files(ppd_dir, pattern = "pp-20.*\\.csv$", full.names = TRUE)

# PPD column names (no header in file)
ppd_colnames <- c("txn_id", "price", "date", "postcode", "prop_type",
                  "old_new", "duration", "paon", "saon", "street",
                  "locality", "town", "district", "county", "ppd_cat", "record_status")

# Read and aggregate each year to LA-quarter-proptype cells
# This avoids loading all 15 files into memory at once
cat("  Processing PPD files into LA-quarter cells...\n")

ppd_cells_list <- list()
for (f in ppd_files) {
  yr <- as.integer(gsub(".*pp-(\\d{4})\\.csv", "\\1", f))
  cat(sprintf("  Processing %d... ", yr))

  dt <- fread(f, header = FALSE,
              select = c(2, 3, 4, 5, 13))  # price, date, postcode, prop_type, district
  setnames(dt, c("price", "date", "postcode", "prop_type", "district"))
  dt[, date := as.Date(date)]
  dt[, year := year(date)]
  dt[, quarter := quarter(date)]
  dt[, price := as.numeric(price)]

  # Remove missing/invalid
  dt <- dt[!is.na(price) & price > 0 & nchar(district) > 0]

  # Aggregate to district-quarter-proptype
  cells <- dt[, .(
    n_txns = .N,
    median_price = median(price, na.rm = TRUE),
    mean_price = mean(price, na.rm = TRUE),
    p25_price = quantile(price, 0.25, na.rm = TRUE),
    p75_price = quantile(price, 0.75, na.rm = TRUE),
    n_below_450k = sum(price <= LISA_CAP),
    n_above_450k = sum(price > LISA_CAP),
    n_near_450k = sum(price >= 400000 & price <= 500000),
    n_bunching_window = sum(price >= 425000 & price <= 450000)
  ), by = .(district, year, quarter, prop_type)]

  ppd_cells_list[[as.character(yr)]] <- cells
  cat(sprintf("%d cells\n", nrow(cells)))
}

ppd_cells <- rbindlist(ppd_cells_list)
cat(sprintf("\nTotal PPD cells: %d (district x quarter x property type)\n", nrow(ppd_cells)))

# Also create district-quarter totals (all property types combined)
ppd_la_q <- ppd_cells[, .(
  total_txns = sum(n_txns),
  median_price = weighted.mean(median_price, n_txns, na.rm = TRUE),
  n_below_450k = sum(n_below_450k),
  n_above_450k = sum(n_above_450k),
  share_above_450k = sum(n_above_450k) / sum(n_txns),
  n_near_450k = sum(n_near_450k),
  n_bunching = sum(n_bunching_window)
), by = .(district, year, quarter)]

ppd_la_q[, yq := year + (quarter - 1) / 4]

cat(sprintf("PPD LA-quarter panel: %d rows\n", nrow(ppd_la_q)))

# ===========================================================================
# 5. Link PPD districts to HPI LA codes
#    PPD 'district' = LA name; HPI has la_code + la_name
# ===========================================================================
cat("\n--- Linking PPD districts to HPI LA codes ---\n")

# Get unique LA names from both sources
la_lookup <- unique(panel[, .(la_code, la_name)])

# Clean both for matching
la_lookup[, la_name_clean := tolower(trimws(la_name))]
ppd_districts <- unique(ppd_la_q$district)
ppd_dist_clean <- data.table(district = ppd_districts,
                              dist_clean = tolower(trimws(ppd_districts)))

# Exact match
ppd_dist_clean <- merge(ppd_dist_clean, la_lookup,
                         by.x = "dist_clean", by.y = "la_name_clean",
                         all.x = TRUE)

matched <- sum(!is.na(ppd_dist_clean$la_code))
total <- nrow(ppd_dist_clean)
cat(sprintf("PPD-HPI match: %d/%d districts matched (%.1f%%)\n",
            matched, total, 100 * matched / total))

# Merge LA code into PPD panel
ppd_la_q <- merge(ppd_la_q, ppd_dist_clean[, .(district, la_code)],
                   by = "district", all.x = TRUE)

# Drop unmatched
ppd_la_q <- ppd_la_q[!is.na(la_code)]
cat(sprintf("PPD panel after linking: %d rows, %d LAs\n",
            nrow(ppd_la_q), length(unique(ppd_la_q$la_code))))

# Merge treatment info
ppd_la_q <- merge(ppd_la_q, treatment_timing[, .(la_code, first_above_450k, treated, group)],
                   by = "la_code", all.x = TRUE)
ppd_la_q[, post := fifelse(!is.na(first_above_450k) & yq >= first_above_450k, 1L, 0L)]

# ===========================================================================
# 6. Save cleaned data
# ===========================================================================
cat("\n--- Saving cleaned data ---\n")

fwrite(panel, file.path(DATA_DIR, "panel_hpi_la_quarter.csv"))
fwrite(ppd_la_q, file.path(DATA_DIR, "panel_ppd_la_quarter.csv"))
fwrite(ppd_cells, file.path(DATA_DIR, "ppd_cells_proptype.csv"))
fwrite(treatment_timing, file.path(DATA_DIR, "treatment_timing.csv"))

cat(sprintf("Saved:\n  panel_hpi_la_quarter.csv: %d rows\n  panel_ppd_la_quarter.csv: %d rows\n  ppd_cells_proptype.csv: %d rows\n  treatment_timing.csv: %d rows\n",
            nrow(panel), nrow(ppd_la_q), nrow(ppd_cells), nrow(treatment_timing)))

cat("\n=== CLEANING COMPLETE ===\n")
