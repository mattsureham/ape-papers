# 02_clean_data.R — Clean and merge D1 (band counts) and D4B (transaction types)
# Creates LA × quarter panel with EPC band shares and rental intensity

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# PART 1: Clean D1 — EPC band counts by LA × quarter
# ============================================================================

cat("=== Cleaning D1 ===\n")

d1_raw <- fread(file.path(data_dir, "d1_clean.csv"))

# Fix column names (row 3 has the actual headers)
# Columns: LA Code, Region, Quarter, Number Lodgements, Total Floor Area, A, B, C, D, E, F, G, Not Recorded
actual_names <- as.character(d1_raw[3, ])
cat("Actual column names:", paste(actual_names, collapse = " | "), "\n")

# Skip header rows
d1 <- d1_raw[4:.N]
setnames(d1, c("la_code", "la_name", "quarter", "n_lodgements", "floor_area",
               "band_a", "band_b", "band_c", "band_d", "band_e",
               "band_f", "band_g", "not_recorded"))

# Convert to numeric
num_cols <- c("n_lodgements", "floor_area", "band_a", "band_b", "band_c",
              "band_d", "band_e", "band_f", "band_g", "not_recorded")
for (col in num_cols) {
  d1[, (col) := as.numeric(get(col))]
}

# Parse quarter to date
# Format: "2008/4" → 2008 Q4
d1[, year := as.integer(sub("/.*", "", quarter))]
d1[, q := as.integer(sub(".*/", "", quarter))]
d1[, date := as.Date(paste0(year, "-", q * 3, "-01"))]

# Remove rows with missing LA code or invalid data
d1 <- d1[!is.na(la_code) & nchar(la_code) == 9 & grepl("^E|^W", la_code)]

# Compute band shares
d1[, total_rated := band_a + band_b + band_c + band_d + band_e + band_f + band_g]
d1[, fg_count := band_f + band_g]
d1[, fg_share := fifelse(total_rated > 0, fg_count / total_rated, NA_real_)]
d1[, e_share := fifelse(total_rated > 0, band_e / total_rated, NA_real_)]
d1[, de_share := fifelse(total_rated > 0, (band_d + band_e) / total_rated, NA_real_)]
d1[, abc_share := fifelse(total_rated > 0, (band_a + band_b + band_c) / total_rated, NA_real_)]

cat("D1 cleaned:", nrow(d1), "LA-quarter observations\n")
cat("LAs:", uniqueN(d1$la_code), "\n")
cat("Quarters:", uniqueN(d1$quarter), "\n")
cat("Year range:", range(d1$year, na.rm = TRUE), "\n")

# ============================================================================
# PART 2: Clean D4B — transaction type by LA × quarter
# ============================================================================

cat("\n=== Cleaning D4B ===\n")

d4b_raw <- fread(file.path(data_dir, "d4b_clean.csv"))

# Row 3 has actual headers
actual_names_d4b <- as.character(d4b_raw[3, ])
cat("D4B column names:", paste(actual_names_d4b, collapse = " | "), "\n")

d4b <- d4b_raw[4:.N]
setnames(d4b, c("la_code", "la_name", "quarter", "new_dwelling", "marketed_sale",
                "non_marketed_sale", "rental", "none_former", "fit_app",
                "green_deal_assess", "following_green_deal", "eco_assess",
                "rhi_app", "stock_condition", "unknown", "n_lodgements_d4b"))

# Convert to numeric
num_cols_d4b <- c("new_dwelling", "marketed_sale", "non_marketed_sale", "rental",
                  "none_former", "fit_app", "green_deal_assess", "following_green_deal",
                  "eco_assess", "rhi_app", "stock_condition", "unknown", "n_lodgements_d4b")
for (col in num_cols_d4b) {
  d4b[, (col) := as.numeric(get(col))]
}

# Parse quarter
d4b[, year := as.integer(sub("/.*", "", quarter))]
d4b[, q := as.integer(sub(".*/", "", quarter))]
d4b[, date := as.Date(paste0(year, "-", q * 3, "-01"))]

# Remove invalid rows
d4b <- d4b[!is.na(la_code) & nchar(la_code) == 9 & grepl("^E|^W", la_code)]

# Compute rental share (rental / total non-missing lodgements)
d4b[, total_trans := new_dwelling + marketed_sale + non_marketed_sale + rental]
d4b[, rental_share := fifelse(total_trans > 0, rental / total_trans, NA_real_)]
d4b[, sale_share := fifelse(total_trans > 0, (marketed_sale + non_marketed_sale) / total_trans, NA_real_)]

cat("D4B cleaned:", nrow(d4b), "LA-quarter observations\n")
cat("LAs:", uniqueN(d4b$la_code), "\n")
cat("Quarters:", uniqueN(d4b$quarter), "\n")
cat("Year range:", range(d4b$year, na.rm = TRUE), "\n")

# ============================================================================
# PART 3: Compute pre-MEES LA-level rental intensity (treatment intensity)
# ============================================================================

cat("\n=== Computing treatment intensity ===\n")

# MEES announced 2015, implemented April 2018
# Use 2012-2017 as pre-period to compute baseline rental share per LA
pre_mees <- d4b[year >= 2012 & year <= 2017]
la_rental_intensity <- pre_mees[, .(
  pre_rental_share = sum(rental, na.rm = TRUE) / sum(total_trans, na.rm = TRUE),
  pre_rental_count = sum(rental, na.rm = TRUE),
  pre_total_count = sum(total_trans, na.rm = TRUE)
), by = la_code]

cat("LA rental intensity summary:\n")
print(summary(la_rental_intensity$pre_rental_share))

# Define treatment intensity terciles
la_rental_intensity[, rental_tercile := cut(
  pre_rental_share,
  breaks = quantile(pre_rental_share, probs = c(0, 1/3, 2/3, 1), na.rm = TRUE),
  labels = c("Low", "Medium", "High"),
  include.lowest = TRUE
)]

cat("Rental terciles:\n")
print(table(la_rental_intensity$rental_tercile))

# ============================================================================
# PART 4: Merge and create analysis panel
# ============================================================================

cat("\n=== Creating analysis panel ===\n")

# Merge D1 band data with LA rental intensity
panel <- merge(
  d1[, .(la_code, la_name, quarter, year, q, date,
         n_lodgements, total_rated, fg_count, fg_share, e_share,
         de_share, abc_share, band_e, band_f, band_g)],
  la_rental_intensity[, .(la_code, pre_rental_share, rental_tercile)],
  by = "la_code",
  all.x = TRUE
)

# Define MEES periods
# Announced: March 2015
# New tenancies: April 2018
# All tenancies: April 2020
panel[, period := fcase(
  year < 2015, "Pre-announcement",
  year >= 2015 & (year < 2018 | (year == 2018 & q <= 1)), "Post-announcement",
  year >= 2018 & (year < 2020 | (year == 2020 & q <= 1)), "New tenancies only",
  default = "All tenancies"
)]
panel[, period := factor(period, levels = c(
  "Pre-announcement", "Post-announcement", "New tenancies only", "All tenancies"
))]

# Binary post-MEES indicator (April 2018 = implementation)
panel[, post_mees := as.integer(year > 2018 | (year == 2018 & q >= 2))]

# Continuous treatment intensity
panel[, treatment := pre_rental_share * post_mees]

# England only (MEES applies to England and Wales, but focus on England for cleaner LA variation)
panel_eng <- panel[grepl("^E", la_code)]

cat("Panel dimensions:", nrow(panel_eng), "obs,",
    uniqueN(panel_eng$la_code), "LAs,",
    uniqueN(panel_eng$quarter), "quarters\n")
cat("Year range:", range(panel_eng$year, na.rm = TRUE), "\n")
cat("F+G share summary:\n")
print(summary(panel_eng$fg_share))

# Also create England-level aggregates for time series
eng_ts <- d1[grepl("^E", la_code), .(
  total_lodgements = sum(n_lodgements, na.rm = TRUE),
  total_rated = sum(total_rated, na.rm = TRUE),
  total_fg = sum(fg_count, na.rm = TRUE),
  total_e = sum(band_e, na.rm = TRUE),
  total_f = sum(band_f, na.rm = TRUE),
  total_g = sum(band_g, na.rm = TRUE),
  total_d = sum(band_d, na.rm = TRUE),
  total_abc = sum(band_a + band_b + band_c, na.rm = TRUE)
), by = .(year, q, quarter, date)]

eng_ts[, fg_share := total_fg / total_rated]
eng_ts[, f_share := total_f / total_rated]
eng_ts[, g_share := total_g / total_rated]
eng_ts[, e_share := total_e / total_rated]
eng_ts[, d_share := total_d / total_rated]
eng_ts <- eng_ts[order(year, q)]

cat("\n=== England time series ===\n")
cat("F+G share over time:\n")
print(eng_ts[, .(quarter, fg_share = round(fg_share, 4),
                 f_share = round(f_share, 4), g_share = round(g_share, 4))])

# Also create D4B England time series for rental volumes
eng_rental_ts <- d4b[grepl("^E", la_code), .(
  total_rental = sum(rental, na.rm = TRUE),
  total_sale = sum(marketed_sale + non_marketed_sale, na.rm = TRUE),
  total_new = sum(new_dwelling, na.rm = TRUE),
  total_all = sum(total_trans, na.rm = TRUE)
), by = .(year, q, quarter, date)]
eng_rental_ts[, rental_share := total_rental / total_all]
eng_rental_ts <- eng_rental_ts[order(year, q)]

cat("\nRental share over time (England):\n")
print(eng_rental_ts[, .(quarter, rental_share = round(rental_share, 3),
                         total_rental, total_sale)])

# ============================================================================
# PART 5: Save
# ============================================================================

fwrite(panel_eng, file.path(data_dir, "panel_la_quarter.csv"))
fwrite(eng_ts, file.path(data_dir, "england_timeseries.csv"))
fwrite(eng_rental_ts, file.path(data_dir, "england_rental_ts.csv"))
fwrite(la_rental_intensity, file.path(data_dir, "la_rental_intensity.csv"))

cat("\n=== Clean data saved ===\n")
cat("Panel:", nrow(panel_eng), "obs\n")
cat("England TS:", nrow(eng_ts), "quarters\n")
