# 02_clean_data.R — Construct LA-month panel for analysis
# apep_0937: Grenfell fire and fire safety industry formation

source("00_packages.R")

data_dir <- "../data/"

# ===========================================================================
# 1. Load Companies House data (already merged with LA in 01b_fast_geocode.R)
# ===========================================================================
cat("=== Loading data ===\n")

companies <- fread(file.path(data_dir, "companies_filtered.csv"))
cat("Companies:", nrow(companies), "\n")
cat("Companies with LA match:", sum(!is.na(companies$la_code)), "of", nrow(companies),
    "(", round(100 * sum(!is.na(companies$la_code)) / nrow(companies), 1), "%)\n")

# Parse dates
companies[, inc_date := as.Date(inc_date)]
companies[, inc_ym := as.Date(inc_ym)]
companies[, inc_year := year(inc_date)]
companies[, inc_month := month(inc_date)]

# Filter to England only (our analysis geography) and 2008-2024
companies_eng <- companies[country == "England" & inc_year >= 2008 & inc_year <= 2024]
cat("English companies 2008-2024:", nrow(companies_eng), "\n")

# ===========================================================================
# 2. Construct LA-month panel: count of incorporations by SIC group
# ===========================================================================
cat("\n=== Constructing LA-month panel ===\n")

# Get all English LAs
english_las <- unique(companies_eng[!is.na(la_code), .(la_code, la_name)])
cat("English LAs:", nrow(english_las), "\n")

# Create balanced panel: all LAs × all months
all_months <- data.table(
  inc_ym = seq(as.Date("2008-01-01"), as.Date("2024-12-01"), by = "month")
)

panel_skeleton <- CJ(
  la_code = english_las$la_code,
  inc_ym = all_months$inc_ym
)

# Count fire safety incorporations per LA-month
fire_counts <- companies_eng[sic_group == "fire_safety" & !is.na(la_code),
  .(fire_incorp = .N), by = .(la_code, inc_ym)]

control_counts <- companies_eng[sic_group == "control_construction" & !is.na(la_code),
  .(control_incorp = .N), by = .(la_code, inc_ym)]

# All incorporations per LA-month (for normalization)
all_counts <- companies_eng[!is.na(la_code),
  .(total_incorp = .N), by = .(la_code, inc_ym)]

# Merge onto balanced panel
panel <- merge(panel_skeleton, fire_counts, by = c("la_code", "inc_ym"), all.x = TRUE)
panel <- merge(panel, control_counts, by = c("la_code", "inc_ym"), all.x = TRUE)
panel <- merge(panel, all_counts, by = c("la_code", "inc_ym"), all.x = TRUE)

# Fill zeros for months with no incorporations
panel[is.na(fire_incorp), fire_incorp := 0]
panel[is.na(control_incorp), control_incorp := 0]
panel[is.na(total_incorp), total_incorp := 0]

# Add LA names
panel <- merge(panel, english_las, by = "la_code", all.x = TRUE)

# ===========================================================================
# 3. Construct treatment intensity: flat share from dwelling data
# ===========================================================================
cat("\n=== Constructing treatment intensity ===\n")

dwelling_file <- file.path(data_dir, "nomis_dwelling_type.csv")
if (!file.exists(dwelling_file)) {
  stop("FATAL: nomis_dwelling_type.csv not found. Run 01_fetch_data.R first.")
}

dwelling <- fread(dwelling_file)
cat("Dwelling data rows:", nrow(dwelling), "\n")
cat("Dwelling columns:", paste(names(dwelling), collapse = ", "), "\n")

# KS401EW format: GEOGRAPHY_CODE, CELL_NAME (with "Household spaces..." for total, "Flat..." for flats)
# Standardize column names
setnames(dwelling, names(dwelling), toupper(names(dwelling)))

cat("Dwelling columns:", paste(names(dwelling), collapse = ", "), "\n")
cat("Unique cell types:", paste(unique(dwelling$CELL_NAME), collapse = "; "), "\n")

# Identify total and flat categories
dwelling[, cell_lower := tolower(CELL_NAME)]

total_rows <- dwelling[grepl("household spaces with at least one", cell_lower)]
flat_rows <- dwelling[grepl("flat|maisonette|apartment", cell_lower)]

cat("Total rows:", nrow(total_rows), "\n")
cat("Flat rows:", nrow(flat_rows), "\n")

if (nrow(total_rows) == 0 || nrow(flat_rows) == 0) {
  stop("FATAL: Cannot identify total/flat rows in dwelling data")
}

# Compute flat share by LA
la_total <- total_rows[, .(total_dwellings = sum(as.numeric(OBS_VALUE), na.rm = TRUE)),
                        by = GEOGRAPHY_CODE]
setnames(la_total, "GEOGRAPHY_CODE", "la_code")

la_flats <- flat_rows[, .(total_flats = sum(as.numeric(OBS_VALUE), na.rm = TRUE)),
                       by = GEOGRAPHY_CODE]
setnames(la_flats, "GEOGRAPHY_CODE", "la_code")

flat_share <- merge(la_total, la_flats, by = "la_code", all.x = TRUE)
flat_share[is.na(total_flats), total_flats := 0]
flat_share[, flat_share := total_flats / total_dwellings]

cat("Flat share summary:\n")
cat("  Mean:", round(mean(flat_share$flat_share, na.rm = TRUE), 3), "\n")
cat("  SD:", round(sd(flat_share$flat_share, na.rm = TRUE), 3), "\n")
cat("  Min:", round(min(flat_share$flat_share, na.rm = TRUE), 3), "\n")
cat("  Max:", round(max(flat_share$flat_share, na.rm = TRUE), 3), "\n")
cat("  LAs with flat data:", nrow(flat_share), "\n")

# ===========================================================================
# 4. Merge treatment intensity onto panel
# ===========================================================================
panel <- merge(panel, flat_share[, .(la_code, flat_share, total_dwellings)],
               by = "la_code", all.x = TRUE)

# Create time variables
panel[, year := year(inc_ym)]
panel[, month := month(inc_ym)]
panel[, year_month := as.numeric(inc_ym)]  # For FE
panel[, post_grenfell := as.integer(inc_ym >= as.Date("2017-07-01"))]

# Treatment intensity × post
panel[, treat_x_post := flat_share * post_grenfell]

# Event study: months relative to June 2017
grenfell_date <- as.Date("2017-06-01")
panel[, months_since := as.integer(round(difftime(inc_ym, grenfell_date, units = "days") / 30.44))]

# Create calendar month for seasonality
panel[, cal_month := factor(month)]

# Year-quarter for coarser analysis
panel[, yq := paste0(year, "Q", quarter(inc_ym))]

# Log outcome (adding 1 to handle zeros)
panel[, log_fire := log(fire_incorp + 1)]
panel[, log_control := log(control_incorp + 1)]

# Drop LAs with missing flat share
panel <- panel[!is.na(flat_share)]

cat("\n=== Final panel ===\n")
cat("Observations:", nrow(panel), "\n")
cat("LAs:", uniqueN(panel$la_code), "\n")
cat("Months:", uniqueN(panel$inc_ym), "\n")
cat("Date range:", as.character(min(panel$inc_ym)), "to", as.character(max(panel$inc_ym)), "\n")
cat("Mean fire incorporations per LA-month:", round(mean(panel$fire_incorp), 3), "\n")
cat("Mean control incorporations per LA-month:", round(mean(panel$control_incorp), 3), "\n")

# Save
fwrite(panel, file.path(data_dir, "panel.csv"))
cat("Saved panel.csv\n")
