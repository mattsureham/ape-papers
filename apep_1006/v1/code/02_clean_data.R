# 02_clean_data.R — Construct analysis panel for APEP 1006
# Merges RPW corridor-quarter data with FATF grey-list treatment status

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# 1. Load and process RPW data
# ============================================================================
cat("Loading RPW data...\n")
rpw <- fread(file.path(data_dir, "rpw_raw.csv"))

# Parse period (format: "2011_1Q" -> year + quarter)
rpw[, year := as.integer(sub("_.*", "", period))]
rpw[, quarter := as.integer(sub(".*_(\\d)Q", "\\1", period))]
rpw[, yq := year + (quarter - 1) / 4]  # Numeric year-quarter
rpw[, time_index := (year - 2010) * 4 + quarter]  # Integer time index (2011Q1 = 5)

# Clean cost variable
setnames(rpw, "cc1 total cost %", "total_cost_pct", skip_absent = TRUE)
rpw[, total_cost_pct := as.numeric(total_cost_pct)]

# Clean FX margin
setnames(rpw, "cc1 fx margin", "fx_margin_pct", skip_absent = TRUE)
rpw[, fx_margin_pct := as.numeric(fx_margin_pct)]

# Clean fee
setnames(rpw, "cc1 lcu fee", "fee_lcu", skip_absent = TRUE)
rpw[, fee_lcu := as.numeric(fee_lcu)]

# Standardize firm type
rpw[, firm_type_clean := fcase(
  grepl("^Bank", firm_type, ignore.case = TRUE) &
    !grepl("Money Transfer", firm_type, ignore.case = TRUE), "Bank",
  grepl("Mobile", firm_type, ignore.case = TRUE), "Mobile",
  grepl("Post", firm_type, ignore.case = TRUE), "Post Office",
  default = "MTO"  # Money Transfer Operator
)]

# Create corridor ID
rpw[, corridor_id := paste0(source_code, "_", destination_code)]

# Drop observations with missing cost
rpw <- rpw[!is.na(total_cost_pct) & total_cost_pct > 0 & total_cost_pct < 50]
cat("RPW after cleaning:", nrow(rpw), "observations\n")
cat("Corridors:", uniqueN(rpw$corridor_id), "\n")
cat("Periods:", uniqueN(rpw$period), "\n")

# ============================================================================
# 2. Aggregate to corridor-quarter level
# ============================================================================
cat("Aggregating to corridor-quarter level...\n")

corridor_qt <- rpw[, .(
  avg_cost       = mean(total_cost_pct, na.rm = TRUE),
  median_cost    = median(total_cost_pct, na.rm = TRUE),
  avg_fx_margin  = mean(fx_margin_pct, na.rm = TRUE),
  n_providers    = .N,
  n_firms        = uniqueN(firm),
  pct_bank       = mean(firm_type_clean == "Bank", na.rm = TRUE),
  pct_mto        = mean(firm_type_clean == "MTO", na.rm = TRUE),
  pct_mobile     = mean(firm_type_clean == "Mobile", na.rm = TRUE)
), by = .(corridor_id, source_code, destination_code, time_index, year, quarter, yq)]

# Create a numeric corridor identifier for the did package
corridor_qt[, corridor_num := as.integer(factor(corridor_id))]

cat("Corridor-quarter panel:", nrow(corridor_qt), "observations\n")
cat("Unique corridors:", uniqueN(corridor_qt$corridor_id), "\n")

# ============================================================================
# 3. Load and expand FATF grey-list to panel format
# ============================================================================
cat("Processing FATF grey-list...\n")
fatf <- fread(file.path(data_dir, "fatf_greylist_episodes.csv"))

# Create a set of all quarters in the sample
all_quarters <- sort(unique(corridor_qt$time_index))
all_dest <- sort(unique(corridor_qt$destination_code))

# For each destination country-quarter, determine grey-list status
# Expand episodes to country-quarter panel
dest_qt_list <- list()
for (i in seq_len(nrow(fatf))) {
  iso <- fatf$iso3[i]
  entry_t <- fatf$entry_qtr[i]  # quarters since 2008Q1
  exit_t <- fatf$exit_qtr[i]

  # Convert to our time index (2011Q1 = 5, i.e., (2011-2010)*4+1)
  # fatf$entry_qtr = (entry_year - 2008)*4 + entry_quarter
  # our time_index = (year - 2010)*4 + quarter
  # So: time_index = entry_qtr - 8  (since (2010-2008)*4 = 8)
  entry_ti <- entry_t - 8
  exit_ti <- if (is.na(exit_t)) max(all_quarters) + 1 else exit_t - 8

  # Get quarters this country was grey-listed
  grey_quarters <- all_quarters[all_quarters >= entry_ti & all_quarters < exit_ti]
  if (length(grey_quarters) > 0 && iso %in% all_dest) {
    dest_qt_list[[length(dest_qt_list) + 1]] <- data.table(
      destination_code = iso,
      time_index = grey_quarters,
      grey_listed = 1L
    )
  }
}

if (length(dest_qt_list) > 0) {
  dest_grey <- rbindlist(dest_qt_list)
  # If country has overlapping episodes, just keep grey_listed = 1
  dest_grey <- dest_grey[, .(grey_listed = max(grey_listed)), by = .(destination_code, time_index)]
} else {
  stop("FATAL: No FATF grey-list episodes overlap with RPW data")
}

cat("Country-quarters with grey-listing:", nrow(dest_grey), "\n")
cat("Countries ever grey-listed in sample:", uniqueN(dest_grey$destination_code), "\n")

# ============================================================================
# 4. Merge grey-list status with corridor panel
# ============================================================================
corridor_qt <- merge(corridor_qt, dest_grey,
                     by = c("destination_code", "time_index"),
                     all.x = TRUE)
corridor_qt[is.na(grey_listed), grey_listed := 0L]

cat("Grey-listed corridor-quarters:", sum(corridor_qt$grey_listed == 1),
    "(", round(100 * mean(corridor_qt$grey_listed), 1), "%)\n")

# ============================================================================
# 5. Create CS-DiD variables
# ============================================================================
# For each corridor, find first treatment quarter (first time destination goes grey)
# Only count entries WITHIN the sample period (not pre-sample)

# First, identify entry events within sample
fatf_entries <- fatf[, .(iso3, entry_qtr)]
fatf_entries[, entry_ti := entry_qtr - 8]

# For each destination, find the first entry that falls within the sample
first_grey <- fatf_entries[entry_ti >= min(all_quarters) & iso3 %in% all_dest,
                           .(first_grey_ti = min(entry_ti)), by = .(destination_code = iso3)]

# Also check for destinations that were ALREADY grey at start of sample
already_grey <- dest_grey[time_index == min(all_quarters) & grey_listed == 1, destination_code]
cat("Destinations already grey-listed at sample start:", length(already_grey), "\n")

# Merge first treatment period
corridor_qt <- merge(corridor_qt, first_grey, by = "destination_code", all.x = TRUE)

# For CS-DiD: gname = first_grey_ti for treated corridors, 0 for never-treated
# Exclude corridors where destination was already grey at sample start (no clean entry)
corridor_qt[, first_treat := ifelse(is.na(first_grey_ti), 0L, as.integer(first_grey_ti))]

# Mark corridors with already-grey destinations for exclusion from CS-DiD
corridor_qt[, already_grey := destination_code %in% already_grey & first_treat == 0L]

# Create CS-DiD sample: exclude already-grey destinations
cs_sample <- corridor_qt[already_grey == FALSE]
cat("CS-DiD sample (excluding already-grey):", nrow(cs_sample), "obs\n")
cat("  Treated corridors (first_treat > 0):", uniqueN(cs_sample[first_treat > 0, corridor_id]), "\n")
cat("  Control corridors (never treated):", uniqueN(cs_sample[first_treat == 0, corridor_id]), "\n")
cat("  Treatment cohorts:", uniqueN(cs_sample[first_treat > 0, first_treat]), "\n")

# ============================================================================
# 6. Also create sending-country grey-list status (for placebo)
# ============================================================================
dest_grey_send <- copy(dest_grey)
setnames(dest_grey_send, "destination_code", "source_code")
setnames(dest_grey_send, "grey_listed", "source_grey_listed")

corridor_qt <- merge(corridor_qt, dest_grey_send,
                     by = c("source_code", "time_index"),
                     all.x = TRUE)
corridor_qt[is.na(source_grey_listed), source_grey_listed := 0L]

# ============================================================================
# 7. Summary statistics
# ============================================================================
cat("\n=== SUMMARY STATISTICS ===\n")
cat("Panel dimensions:\n")
cat("  Corridor-quarters:", nrow(corridor_qt), "\n")
cat("  Unique corridors:", uniqueN(corridor_qt$corridor_id), "\n")
cat("  Time periods:", length(unique(corridor_qt$time_index)), "\n")
cat("  Sending countries:", uniqueN(corridor_qt$source_code), "\n")
cat("  Receiving countries:", uniqueN(corridor_qt$destination_code), "\n")

cat("\nOutcome variable (avg_cost, %):\n")
cat("  Mean:", round(mean(corridor_qt$avg_cost, na.rm = TRUE), 2), "\n")
cat("  SD:", round(sd(corridor_qt$avg_cost, na.rm = TRUE), 2), "\n")
cat("  Min:", round(min(corridor_qt$avg_cost, na.rm = TRUE), 2), "\n")
cat("  Max:", round(max(corridor_qt$avg_cost, na.rm = TRUE), 2), "\n")

cat("\nTreatment:\n")
cat("  Corridor-quarters with grey-listed destination:",
    sum(corridor_qt$grey_listed == 1), "\n")
cat("  Fraction:", round(mean(corridor_qt$grey_listed), 3), "\n")

# ============================================================================
# 8. Save analysis datasets
# ============================================================================
fwrite(corridor_qt, file.path(data_dir, "corridor_panel.csv"))
fwrite(cs_sample, file.path(data_dir, "cs_sample.csv"))

# Save summary stats for table generation
sumstats <- corridor_qt[, .(
  mean_cost = mean(avg_cost, na.rm = TRUE),
  sd_cost = sd(avg_cost, na.rm = TRUE),
  mean_fx = mean(avg_fx_margin, na.rm = TRUE),
  sd_fx = sd(avg_fx_margin, na.rm = TRUE),
  mean_providers = mean(n_firms, na.rm = TRUE),
  sd_providers = sd(n_firms, na.rm = TRUE),
  mean_grey = mean(grey_listed),
  n_obs = .N,
  n_corridors = uniqueN(corridor_id),
  n_periods = uniqueN(time_index)
)]

# By grey-list status
sumstats_by_grey <- corridor_qt[, .(
  mean_cost = mean(avg_cost, na.rm = TRUE),
  sd_cost = sd(avg_cost, na.rm = TRUE),
  mean_fx = mean(avg_fx_margin, na.rm = TRUE),
  sd_fx = sd(avg_fx_margin, na.rm = TRUE),
  mean_providers = mean(n_firms, na.rm = TRUE),
  sd_providers = sd(n_firms, na.rm = TRUE),
  n_obs = .N
), by = grey_listed]

fwrite(sumstats, file.path(data_dir, "sumstats_overall.csv"))
fwrite(sumstats_by_grey, file.path(data_dir, "sumstats_by_grey.csv"))

cat("\nAll data saved. Ready for analysis.\n")
