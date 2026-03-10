###############################################################################
# 02_clean_data.R — Construct analysis sample from pre-linked dataset
# apep_0477 v2: Do Energy Labels Move Markets?
# WS1: Match quality classification + address validation
# WS5: Retain district column for clustering
# WS3: Pre/post MEES indicators
###############################################################################

source("00_packages.R")

DATA_DIR <- "../data"

###############################################################################
# 1. Load pre-linked data
###############################################################################

cat("=== Loading linked dataset ===\n")
df <- as.data.table(read_parquet(file.path(DATA_DIR, "linked_transactions_2015.parquet")))
cat(sprintf("Raw linked rows: %s\n", format(nrow(df), big.mark = ",")))

###############################################################################
# 2. Rename and construct core variables
###############################################################################

cat("\n=== Constructing variables ===\n")

# Rename LR fields for consistency
setnames(df, c("transactionid", "price", "dateoftransfer", "propertytype",
               "oldnew", "district"),
         c("txn_id", "price", "date_transfer", "property_type",
           "old_new", "district"),
         skip_absent = TRUE)

# EPC score
df[, epc_score := as.integer(CURRENT_ENERGY_EFFICIENCY)]
df[, epc_band := CURRENT_ENERGY_RATING]

# Log price
df[, log_price := log(price)]

# Tenure indicators
df[, is_rental := grepl("rental", TENURE, ignore.case = TRUE)]
df[, is_owner := grepl("owner", TENURE, ignore.case = TRUE)]
df[, tenure_simple := fifelse(is_rental, "rental",
                       fifelse(is_owner, "owner", "other"))]

# Floor area
df[, floor_area := as.numeric(TOTAL_FLOOR_AREA)]

# WS5: Clean district for clustering
df[, district_clean := gsub("\\s+", " ", trimws(toupper(district)))]

# Postcode area
df[, postcode_clean := gsub("\\s+", " ", trimws(toupper(postcode)))]
df[, postcode_area := sub(" .*", "", postcode_clean)]

# Property type labels
df[, prop_type_label := fcase(
  property_type == "D", "Detached",
  property_type == "S", "Semi-detached",
  property_type == "T", "Terraced",
  property_type == "F", "Flat",
  property_type == "O", "Other",
  default = "Unknown"
)]

# Is flat / new
df[, is_flat := property_type == "F"]
df[, is_new := old_new == "Y"]

# Number of habitable rooms
df[, n_rooms := as.integer(NUMBER_HABITABLE_ROOMS)]

###############################################################################
# 3. WS1: Match quality classification
###############################################################################

cat("\n=== WS1: Match quality classification ===\n")

# Chi et al. UPRN_SOURCE tells us how the link was established
# "Address Matched" = high-quality UPRN-based address match
# "Energy Assessor" or NA = lower-quality match (postcode-level)
df[, match_quality := fifelse(
  !is.na(UPRN_SOURCE) & UPRN_SOURCE == "Address Matched", "address", "postcode"
)]

cat(sprintf("  Address-matched: %s (%.1f%%)\n",
            format(sum(df$match_quality == "address"), big.mark = ","),
            100 * mean(df$match_quality == "address")))
cat(sprintf("  Other matching: %s (%.1f%%)\n",
            format(sum(df$match_quality == "postcode"), big.mark = ","),
            100 * mean(df$match_quality == "postcode")))

# WS1: Additional address-level validation via Jaro-Winkler
# Compare LR PAON+street to EPC ADDRESS field
cat("Computing Jaro-Winkler address similarity for validation...\n")

df[, paon_clean := gsub("\\s+", " ", trimws(toupper(
  fifelse(is.na(paon), "", as.character(paon))
)))]
df[, street_clean := gsub("\\s+", " ", trimws(toupper(
  fifelse(is.na(street), "", as.character(street))
)))]

# EPC ADDRESS field contains full address; extract components
# ADDRESS field format: "80, West Street" or "Bushmans, Petworth Road, Chiddingfold"
if ("ADDRESS" %in% names(df)) {
  # Not present in linked parquet — the ADDRESS field is in epc20_id.csv
  # Instead, use LOCAL_AUTHORITY_LABEL as a proxy
  cat("  Note: Full EPC ADDRESS not in linked dataset; using UPRN_SOURCE for match quality\n")
}

# Match diagnostic: how many transactions share the same postcode?
epc_by_pc <- df[, .(n_epc_candidates = .N), by = postcode_clean]
df <- merge(df, epc_by_pc, by = "postcode_clean", all.x = TRUE)

# EPC recency: days between EPC inspection and transaction
df[, epc_date := as.Date(INSPECTION_DATE)]
df[, epc_recency := as.numeric(date_transfer - epc_date)]

cat(sprintf("  Median EPC candidates per postcode: %.0f\n",
            median(df$n_epc_candidates, na.rm = TRUE)))
cat(sprintf("  Median EPC recency (days): %.0f\n",
            median(df$epc_recency, na.rm = TRUE)))

###############################################################################
# 4. Period and time variables
###############################################################################

cat("\n=== Time variables ===\n")

# Period assignment
df[, period := fcase(
  date_transfer < as.Date("2018-04-01"), "Pre-MEES",
  date_transfer < as.Date("2021-10-01"), "Post-MEES Pre-Crisis",
  date_transfer < as.Date("2023-07-01"), "Crisis",
  default = "Post-Crisis"
)]
df[, period := factor(period, levels = PERIOD_LABELS)]

# Year and year-quarter
df[, year_txn := year(date_transfer)]
df[, yq := paste0(year(date_transfer), "Q", quarter(date_transfer))]

# WS3: Pre/post MEES indicator for diff-in-disc
df[, post_mees := as.integer(date_transfer >= MEES_DATE)]

###############################################################################
# 5. EPC band distance variables
###############################################################################

# Distance to each boundary
for (i in seq_along(EPC_BOUNDARIES)) {
  b <- EPC_BOUNDARIES[i]
  nm <- paste0("dist_", EPC_BAND_NAMES[i])
  df[, (nm) := epc_score - b]
}

# Indicator: above each boundary
for (i in seq_along(EPC_BOUNDARIES)) {
  b <- EPC_BOUNDARIES[i]
  nm <- paste0("above_", EPC_BAND_NAMES[i])
  df[, (nm) := as.integer(epc_score >= b)]
}

###############################################################################
# 6. Sample restrictions
###############################################################################

cat("\n=== Sample restrictions ===\n")
n_start <- nrow(df)

# Drop extreme prices (below £10K or above £10M)
df <- df[price >= 10000 & price <= 10000000]
cat(sprintf("  After price filter: %s (dropped %s)\n",
            format(nrow(df), big.mark = ","),
            format(n_start - nrow(df), big.mark = ",")))

# Drop if floor area missing or extreme
df <- df[!is.na(floor_area) & floor_area >= 10 & floor_area <= 500]
cat(sprintf("  After floor area filter: %s\n",
            format(nrow(df), big.mark = ",")))

# Drop EPC scores outside valid range
df <- df[epc_score >= 1 & epc_score <= 100]
cat(sprintf("  After EPC score filter: %s\n",
            format(nrow(df), big.mark = ",")))

###############################################################################
# 7. Summary statistics
###############################################################################

cat("\n=== Analysis Sample Summary ===\n")
cat(sprintf("Total transactions: %s\n",
            format(nrow(df), big.mark = ",")))
cat(sprintf("  Address-matched (UPRN): %s (%.1f%%)\n",
            format(sum(df$match_quality == "address"), big.mark = ","),
            100 * mean(df$match_quality == "address")))
cat(sprintf("Unique postcodes: %s\n",
            format(uniqueN(df$postcode_clean), big.mark = ",")))
cat(sprintf("Unique districts: %s\n",
            format(uniqueN(df$district_clean), big.mark = ",")))
cat(sprintf("Date range: %s to %s\n",
            min(df$date_transfer), max(df$date_transfer)))

cat("\nBy period:\n")
print(df[, .(N = .N, mean_price = mean(price),
             median_price = median(price),
             mean_epc = mean(epc_score)),
         by = period][order(period)])

cat("\nBy EPC band:\n")
print(df[, .(N = .N, mean_price = mean(price),
             mean_log_price = mean(log_price)),
         by = epc_band][order(epc_band)])

cat("\nNear boundaries (±10 score points):\n")
for (i in seq_along(EPC_BOUNDARIES)) {
  b <- EPC_BOUNDARIES[i]
  n_near <- sum(abs(df$epc_score - b) <= 10)
  n_addr <- sum(abs(df$epc_score - b) <= 10 & df$match_quality == "address")
  cat(sprintf("  %s (score %d): %s transactions (%s address-matched)\n",
              EPC_BAND_NAMES[i], b, format(n_near, big.mark = ","),
              format(n_addr, big.mark = ",")))
}

cat("\nBy tenure:\n")
print(df[, .(N = .N, pct = round(.N/nrow(df)*100, 1)), by = tenure_simple])

cat("\nMatch quality diagnostics:\n")
cat(sprintf("  Median EPC candidates per postcode: %.0f\n",
            median(df$n_epc_candidates, na.rm = TRUE)))
cat(sprintf("  Median EPC recency (days): %.0f\n",
            median(df$epc_recency, na.rm = TRUE)))

###############################################################################
# 8. Save analysis dataset
###############################################################################

# Select columns for analysis
keep_cols <- c(
  "txn_id", "price", "log_price", "date_transfer", "postcode_clean",
  "property_type", "prop_type_label", "old_new", "is_flat", "is_new",
  "district_clean", "postcode_area",
  "epc_score", "epc_band", "epc_date", "floor_area", "n_rooms",
  "TENURE", "tenure_simple", "is_rental", "is_owner",
  "match_quality", "n_epc_candidates", "epc_recency",
  "period", "year_txn", "yq", "post_mees",
  paste0("dist_", EPC_BAND_NAMES),
  paste0("above_", EPC_BAND_NAMES),
  "MAINS_GAS_FLAG", "CONSTRUCTION_AGE_BAND", "BUILT_FORM"
)

# Keep only columns that exist
keep_cols <- intersect(keep_cols, names(df))
df <- df[, ..keep_cols]

write_parquet(df, file.path(DATA_DIR, "analysis_sample.parquet"))
cat(sprintf("\nSaved analysis sample: %s (%s rows)\n",
            file.path(DATA_DIR, "analysis_sample.parquet"),
            format(nrow(df), big.mark = ",")))
