## 02_clean_data.R — Build analysis dataset
## apep_1345: The Inspector Lottery — Rating Event Study
## Links Ofsted inspections to nearby house prices via postcode

source("00_packages.R")
setwd(here::here("output", "apep_1345", "v1"))

## ── 1. Clean Ofsted MI ───────────────────────────────────────────────────────

cat("=== Cleaning Ofsted MI data ===\n")
ofsted_raw <- fread("data/ofsted_mi.csv")

# Rename columns for convenience
ofsted <- ofsted_raw[, .(
  urn         = `URN`,
  school_name = `School name`,
  phase       = `Ofsted phase`,
  school_type = `Type of education`,
  admissions  = `Admissions policy`,
  sixth_form  = `Sixth form`,
  region      = `Ofsted region`,
  local_auth  = `Local authority`,
  postcode    = `Postcode`,
  idaci       = `The income deprivation affecting children index (IDACI) quintile`,
  n_pupils    = `Total number of pupils`,
  lowest_age  = `Statutory lowest age`,
  highest_age = `Statutory highest age`,
  insp_date   = `Inspection start date of latest OEIF graded inspection`,
  pub_date    = `Publication date of latest OEIF graded inspection`,
  rating      = `Latest OEIF overall effectiveness`,
  quality_ed  = `Latest OEIF quality of education`,
  behaviour   = `Latest OEIF behaviour and attitudes`,
  personal    = `Latest OEIF personal development`,
  leadership  = `Latest OEIF effectiveness of leadership and management`
)]

# Parse dates
ofsted[, insp_date := as.Date(insp_date, format = "%d/%m/%Y")]
ofsted[, pub_date := as.Date(pub_date, format = "%d/%m/%Y")]

# If date format is different, try ISO
if (all(is.na(ofsted$insp_date))) {
  ofsted_raw2 <- fread("data/ofsted_mi.csv")
  # Try alternative date formats
  ofsted[, insp_date := as.Date(ofsted_raw2$`Inspection start date of latest OEIF graded inspection`)]
  ofsted[, pub_date := as.Date(ofsted_raw2$`Publication date of latest OEIF graded inspection`)]
}

# Filter to graded inspections
ofsted <- ofsted[!is.na(rating) & rating %in% 1:4]
cat("Graded schools:", nrow(ofsted), "\n")

# Create treatment variables
ofsted[, rating_num := as.integer(rating)]
ofsted[, rating_label := factor(rating_num, levels = 1:4,
       labels = c("Outstanding", "Good", "Requires Improvement", "Inadequate"))]

# Binary: good (1-2) vs bad (3-4)
ofsted[, good_rating := as.integer(rating_num <= 2)]

# Extract postcode district (first half: e.g., "SW1A" from "SW1A 1AA")
ofsted[, pc_district := str_extract(postcode, "^[A-Z]{1,2}[0-9][A-Z0-9]?")]

# Extract outward code (postcode district + sector)
ofsted[, pc_outward := str_extract(postcode, "^[A-Z]{1,2}[0-9][A-Z0-9]?\\s?[0-9]?")]
ofsted[, pc_outward := str_trim(pc_outward)]

# Inspection year and quarter
ofsted[, insp_year := year(insp_date)]
ofsted[, insp_qtr := quarter(insp_date)]
ofsted[, insp_yq := paste0(insp_year, "Q", insp_qtr)]

cat("Inspection date range:", as.character(min(ofsted$insp_date, na.rm=TRUE)),
    "to", as.character(max(ofsted$insp_date, na.rm=TRUE)), "\n")
cat("\nRating distribution:\n")
print(table(ofsted$rating_label))
cat("\nInspections by year:\n")
print(table(ofsted$insp_year))

## ── 2. Clean Land Registry Data ──────────────────────────────────────────────

cat("\n=== Cleaning Land Registry data ===\n")

lr <- arrow::read_parquet("data/land_registry_2015_2024.parquet")
setDT(lr)
cat("Raw Land Registry records:", nrow(lr), "\n")

# Parse transaction date
lr[, txn_date := as.Date(date)]
lr[, txn_year := year(txn_date)]
lr[, txn_month := floor_date(txn_date, "month")]
lr[, txn_qtr := paste0(txn_year, "Q", quarter(txn_date))]

# Clean postcode
lr[, postcode := str_trim(postcode)]
lr[, pc_district := str_extract(postcode, "^[A-Z]{1,2}[0-9][A-Z0-9]?")]

# Filter: standard price paid, not additional transactions
lr <- lr[ppd_cat == "A"]  # Standard transactions only
lr <- lr[price > 10000 & price < 5000000]  # Remove outliers
lr <- lr[!is.na(postcode) & postcode != ""]

cat("Filtered Land Registry records:", nrow(lr), "\n")
cat("Transaction date range:", as.character(min(lr$txn_date, na.rm=TRUE)),
    "to", as.character(max(lr$txn_date, na.rm=TRUE)), "\n")

# Log price
lr[, log_price := log(price)]

## ── 3. Aggregate House Prices at Postcode District x Month ───────────────────

cat("\n=== Aggregating house prices ===\n")

# Aggregate to postcode district x month level
lr_agg <- lr[, .(
  mean_price    = mean(price, na.rm = TRUE),
  median_price  = median(price, na.rm = TRUE),
  log_mean_price = mean(log_price, na.rm = TRUE),
  n_txns        = .N,
  sd_log_price  = sd(log_price, na.rm = TRUE)
), by = .(pc_district, txn_month)]

cat("Postcode district x month cells:", nrow(lr_agg), "\n")
cat("Unique postcode districts:", uniqueN(lr_agg$pc_district), "\n")

## ── 4. Link Ofsted to House Prices ───────────────────────────────────────────

cat("\n=== Linking inspections to house prices ===\n")

# For each school inspection, get house prices in the same postcode district
# in the 24 months before and 24 months after the inspection

# Create event-time panel: for each school, months -24 to +24 relative to publication
event_months <- -24:24
panel_list <- list()

schools_with_data <- 0
for (i in 1:nrow(ofsted)) {
  s <- ofsted[i]
  if (is.na(s$pub_date) || is.na(s$pc_district)) next

  # Define the event window
  month_grid <- data.table(
    event_month = event_months,
    txn_month = s$pub_date %m+% months(event_months)
  )
  month_grid[, txn_month := floor_date(txn_month, "month")]

  # Merge with house prices
  merged <- merge(month_grid, lr_agg[pc_district == s$pc_district],
                  by = "txn_month", all.x = TRUE)

  if (sum(!is.na(merged$mean_price)) >= 12) {
    merged[, urn := s$urn]
    merged[, rating := s$rating_num]
    merged[, good_rating := s$good_rating]
    merged[, pc_district := s$pc_district]
    merged[, region := s$region]
    merged[, insp_date := s$insp_date]
    merged[, pub_date := s$pub_date]
    merged[, insp_year := s$insp_year]
    merged[, phase := s$phase]
    merged[, idaci := s$idaci]
    merged[, n_pupils := s$n_pupils]

    panel_list[[length(panel_list) + 1]] <- merged
    schools_with_data <- schools_with_data + 1
  }
}

cat("Schools with sufficient house price data:", schools_with_data, "\n")

if (schools_with_data < 100) {
  stop("FATAL: Insufficient data linkage. Only ", schools_with_data, " schools matched.")
}

panel <- rbindlist(panel_list)
cat("Panel dimensions:", nrow(panel), "rows x", ncol(panel), "cols\n")

# Create post-inspection indicator
panel[, post := as.integer(event_month >= 0)]

# Create binned event time (for event study)
panel[, event_bin := fcase(
  event_month <= -13, "Pre (-24 to -13)",
  event_month <= -7, "Pre (-12 to -7)",
  event_month <= -1, "Pre (-6 to -1)",
  event_month == 0, "Month 0",
  event_month <= 6, "Post (1 to 6)",
  event_month <= 12, "Post (7 to 12)",
  event_month <= 24, "Post (13 to 24)"
)]

# Normalize log prices relative to school-specific pre-inspection mean
panel[, pre_mean_lp := mean(log_mean_price[event_month %in% -12:-1], na.rm = TRUE),
      by = urn]
panel[, norm_log_price := log_mean_price - pre_mean_lp]

## ── 5. Summary Statistics ────────────────────────────────────────────────────

cat("\n=== Summary Statistics ===\n")

# School-level summary
school_summ <- ofsted[urn %in% unique(panel$urn)]
cat("Schools in analysis:", nrow(school_summ), "\n")
cat("Rating distribution in analysis sample:\n")
print(table(school_summ$rating_label))

cat("\nMean house price by rating:\n")
print(panel[event_month == 0, .(
  mean_price = mean(mean_price, na.rm = TRUE),
  median_price = mean(median_price, na.rm = TRUE),
  n_schools = uniqueN(urn)
), by = rating])

## ── 6. Save ──────────────────────────────────────────────────────────────────

fwrite(panel, "data/analysis_panel.csv")
fwrite(ofsted, "data/ofsted_clean.csv")
cat("\nSaved analysis_panel.csv and ofsted_clean.csv\n")
cat("Files in data/:\n")
print(list.files("data/"))
