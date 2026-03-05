## ============================================================
## 02_clean_data.R — Merge and construct analysis variables
## apep_0522: Flood Re and English Property Values
## ============================================================

source("00_packages.R")

data_dir <- "../data"

## -------------------------------------------------------
## 1. Load datasets
## -------------------------------------------------------

lr <- fread(file.path(data_dir, "land_registry_panel.csv"))
flood <- fread(file.path(data_dir, "flood_risk_postcodes.csv"))

cat(sprintf("Land Registry: %s rows\n", format(nrow(lr), big.mark = ",")))
cat(sprintf("Flood risk: %s rows\n", format(nrow(flood), big.mark = ",")))

## -------------------------------------------------------
## 2. Clean flood risk data
## -------------------------------------------------------

cat("Flood risk columns:", paste(names(flood), collapse = ", "), "\n")

# EA RoFRS data has counts per risk band per postcode:
# RES_CNT_High, RES_CNT_Medium, RES_CNT_Low, RES_CNT_VeryLow
# We use RESIDENTIAL counts (RES_) to classify postcodes
# A postcode is "high risk" if it has ANY residential properties at High or Medium risk

# Standardize column names
setnames(flood, "PC", "postcode")
flood[, postcode := str_trim(postcode)]

# Derive flood risk classification from residential property counts
flood[, res_high := as.integer(RES_CNT_High)]
flood[, res_medium := as.integer(RES_CNT_Medium)]
flood[, res_low := as.integer(RES_CNT_Low)]
flood[, res_verylow := as.integer(RES_CNT_VeryLow)]

# Assign risk band based on highest risk level present
flood[, flood_risk_band := fcase(
  res_high > 0, "High",
  res_medium > 0, "Medium",
  res_low > 0, "Low",
  res_verylow > 0, "VeryLow",
  default = "None"
)]

# Binary treatment: High or Medium risk
flood[, flood_risk_high := as.integer(flood_risk_band %in% c("High", "Medium"))]
flood[, flood_risk_any := as.integer(flood_risk_band %in%
  c("High", "Medium", "Low", "VeryLow"))]

# Keep one row per postcode (already unique in this dataset)
flood_pc <- flood[, .(postcode, flood_risk_band, flood_risk_high, flood_risk_any,
                       res_high, res_medium, res_low, res_verylow)]

cat(sprintf("Flood risk postcodes: %s total\n",
            format(nrow(flood_pc), big.mark = ",")))
cat(sprintf("  High risk: %s\n", format(sum(flood_pc$flood_risk_band == "High"), big.mark = ",")))
cat(sprintf("  Medium risk: %s\n", format(sum(flood_pc$flood_risk_band == "Medium"), big.mark = ",")))
cat(sprintf("  Low risk: %s\n", format(sum(flood_pc$flood_risk_band == "Low"), big.mark = ",")))
cat(sprintf("  VeryLow risk: %s\n", format(sum(flood_pc$flood_risk_band == "VeryLow"), big.mark = ",")))
cat(sprintf("  Treatment group (High+Medium): %s\n",
            format(sum(flood_pc$flood_risk_high), big.mark = ",")))

## -------------------------------------------------------
## 3. Merge flood risk to Land Registry
## -------------------------------------------------------

# Ensure clean postcode
lr[, postcode_clean := str_trim(postcode)]

lr <- merge(lr, flood_pc[, .(postcode, flood_risk_band, flood_risk_high,
                              flood_risk_any)],
            by.x = "postcode_clean", by.y = "postcode",
            all.x = TRUE)

# Non-matched postcodes are NOT in flood risk areas
lr[is.na(flood_risk_high), flood_risk_high := 0L]
lr[is.na(flood_risk_any), flood_risk_any := 0L]
lr[is.na(flood_risk_band), flood_risk_band := "None"]

cat(sprintf("Transactions in flood risk areas (high/medium): %s (%.1f%%)\n",
            format(sum(lr$flood_risk_high), big.mark = ","),
            100 * mean(lr$flood_risk_high)))

## -------------------------------------------------------
## 4. Construct treatment and analysis variables
## -------------------------------------------------------

# Parse dates
lr[, date_of_transfer := as.Date(date_of_transfer)]
lr[, year := year(date_of_transfer)]
lr[, quarter := quarter(date_of_transfer)]
lr[, year_quarter := year + (quarter - 1) / 4]
lr[, year_quarter_str := paste0(year, "Q", quarter)]

# Flood Re treatment timing
# Announced: Water Act 2014 (May 2014)
# Launched: April 4, 2016
lr[, post_floodre := as.integer(date_of_transfer >= as.Date("2016-04-04"))]
lr[, post_announcement := as.integer(date_of_transfer >= as.Date("2014-05-14"))]

# Relative year (base = 2015, pre-treatment)
lr[, rel_year := year - 2016L]

# New build flag
lr[, new_build := as.integer(old_new == "Y")]

# Create property identifier for repeat sales
lr[, property_id := paste0(postcode_clean, "_", property_type)]

# Classify Flood Re eligibility
# Flood Re covers properties built before Jan 1, 2009
# Our data starts 2010, so we use the old_new flag:
# - "Y" (new build) after 2008 → definitively ineligible (post-2009 construction)
# - "N" (existing) → presumed eligible (vast majority of housing stock is pre-2009)
# This is conservative: some "N" properties might have been built post-2009
# and resold, but this is rare and biases toward attenuation

# Find properties ever sold as new builds after 2008
post2009_new <- lr[new_build == 1 & year >= 2009, unique(property_id)]

lr[, eligibility := fifelse(
  property_id %in% post2009_new, "ineligible", "eligible"
)]

cat(sprintf("Eligibility classification:\n"))
cat(sprintf("  Eligible (not new-build post-2008): %s transactions\n",
            format(sum(lr$eligibility == "eligible"), big.mark = ",")))
cat(sprintf("  Ineligible (new-build post-2008): %s transactions\n",
            format(sum(lr$eligibility == "ineligible"), big.mark = ",")))

lr[, eligible := as.integer(eligibility == "eligible")]
lr[, ineligible := as.integer(eligibility == "ineligible")]

# Log price
lr[, ln_price := log(price)]

# Extract postcode sector for FE
lr[, postcode_sector := str_extract(postcode_clean,
                                     "^[A-Z]{1,2}[0-9][0-9A-Z]?\\s?[0-9]")]

# Use "district" field from Land Registry as local authority proxy
# This is the administrative district recorded in the deed
lr[, la_code := district]

# Derive region from postcode area (first 1-2 letters)
# This is approximate but sufficient for heterogeneity analysis
lr[, pc_area := str_extract(postcode_clean, "^[A-Z]{1,2}")]

# Map postcode areas to regions (approximate)
region_map <- data.table(
  pc_area = c(
    # London
    "E", "EC", "N", "NW", "SE", "SW", "W", "WC",
    # South East
    "BN", "CT", "GU", "HP", "ME", "MK", "OX", "PO", "RG", "RH",
    "SL", "SO", "TN", "TW",
    # South West
    "BA", "BH", "BS", "DT", "EX", "GL", "PL", "SN", "SP", "TA", "TQ", "TR",
    # East of England
    "AL", "CB", "CM", "CO", "EN", "IG", "IP", "LU", "NR", "PE", "RM",
    "SG", "SS",
    # West Midlands
    "B", "CV", "DY", "HR", "ST", "TF", "WR", "WS", "WV",
    # East Midlands
    "DE", "LE", "LN", "NG", "NN",
    # Yorkshire and the Humber
    "BD", "DN", "HD", "HG", "HU", "HX", "LS", "S", "WF", "YO",
    # North West
    "BB", "BL", "CA", "CH", "CW", "FY", "L", "LA", "M", "OL",
    "PR", "SK", "WA", "WN",
    # North East
    "DH", "DL", "NE", "SR", "TS"
  ),
  region = c(
    rep("London", 8),
    rep("South East", 14),
    rep("South West", 12),
    rep("East of England", 13),
    rep("West Midlands", 9),
    rep("East Midlands", 5),
    rep("Yorkshire and the Humber", 10),
    rep("North West", 14),
    rep("North East", 5)
  )
)

lr <- merge(lr, region_map, by = "pc_area", all.x = TRUE)
cat(sprintf("Region assignment: %s matched, %s unmatched\n",
            format(sum(!is.na(lr$region)), big.mark = ","),
            format(sum(is.na(lr$region)), big.mark = ",")))

# For unmatched, assign "Other"
lr[is.na(region), region := "Other"]

## -------------------------------------------------------
## 5. Dose-response variable
## -------------------------------------------------------

# Create numeric flood risk dose for dose-response analysis
lr[, flood_dose := fcase(
  flood_risk_band %in% c("High", "HIGH", "high"), 3L,
  flood_risk_band %in% c("Medium", "MEDIUM", "medium"), 2L,
  flood_risk_band %in% c("Low", "LOW", "low"), 1L,
  default = 0L
)]

## -------------------------------------------------------
## 6. Create analysis dataset
## -------------------------------------------------------

# Key variables for analysis
analysis_vars <- c(
  "transaction_id", "postcode_clean", "postcode_sector",
  "property_type", "old_new", "new_build", "duration", "price", "ln_price",
  "date_of_transfer", "year", "quarter", "year_quarter", "year_quarter_str",
  "rel_year", "post_floodre", "post_announcement",
  "flood_risk_band", "flood_risk_high", "flood_risk_any", "flood_dose",
  "eligibility", "eligible", "ineligible",
  "la_code", "region",
  "district", "county", "property_id"
)

panel <- lr[, ..analysis_vars]

# Save
panel_file <- file.path(data_dir, "analysis_panel.csv")
fwrite(panel, panel_file)
cat(sprintf("\nSaved analysis panel: %s rows, %d columns\n",
            format(nrow(panel), big.mark = ","), ncol(panel)))

## -------------------------------------------------------
## 7. Summary statistics
## -------------------------------------------------------

cat("\n=== SUMMARY STATISTICS ===\n")
cat(sprintf("Total transactions (England, 2010-2025): %s\n",
            format(nrow(panel), big.mark = ",")))
cat(sprintf("Years: %d to %d\n", min(panel$year), max(panel$year)))
cat(sprintf("Unique postcodes: %s\n",
            format(uniqueN(panel$postcode_clean), big.mark = ",")))
cat(sprintf("Unique local authorities (districts): %d\n", uniqueN(panel$la_code)))
cat(sprintf("Mean price: GBP %s\n",
            format(round(mean(panel$price)), big.mark = ",")))
cat(sprintf("Median price: GBP %s\n",
            format(round(median(panel$price)), big.mark = ",")))

# Treatment group sizes
cat("\n--- Treatment groups ---\n")
panel[, .N, by = flood_risk_high][order(flood_risk_high)] |> print()

cat("\n--- Eligibility x Flood Risk ---\n")
panel[flood_risk_high == 1, .N, by = eligibility][order(eligibility)] |> print()

# Pre/post balance
cat("\n--- Pre vs Post Flood Re ---\n")
panel[, .(
  mean_price = mean(price),
  median_price = median(price),
  n_transactions = .N
), by = .(flood_risk_high, post_floodre)][order(flood_risk_high, post_floodre)] |>
  print()

# Save summary stats for tables
sumstats <- panel[, .(
  n = .N,
  mean_price = mean(as.double(price)),
  sd_price = sd(as.double(price)),
  median_price = as.double(median(price)),
  pct_detached = mean(property_type == "D"),
  pct_semi = mean(property_type == "S"),
  pct_terrace = mean(property_type == "T"),
  pct_flat = mean(property_type == "F"),
  pct_freehold = mean(duration == "F"),
  pct_newbuild = mean(new_build)
), by = .(flood_risk_high, post_floodre)]

fwrite(sumstats, file.path(data_dir, "summary_stats.csv"))
cat("\nSummary statistics saved.\n")
