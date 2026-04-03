# 02_clean_data.R — Build drug-quarter panel + identify generic entry events
# apep_1346: The Lag Windfall

source("00_packages.R")

data_dir <- "../data"

# =============================================================================
# 1. Build ASP drug-quarter panel
# =============================================================================
cat("=== Building ASP drug-quarter panel ===\n")

asp_files <- list.files(data_dir, pattern = "^asp_20\\d{2}Q\\d\\.csv$", full.names = TRUE)
cat("Found", length(asp_files), "quarterly ASP files\n")

asp_list <- lapply(asp_files, function(f) {
  dt <- fread(f)
  # Standardize column names
  old_names <- names(dt)
  # Find key columns by pattern matching
  hcpcs_col <- grep("HCPCS.*Code$|^HCPCS$", old_names, ignore.case = TRUE, value = TRUE)[1]
  desc_col <- grep("Short.*Desc|Description", old_names, ignore.case = TRUE, value = TRUE)[1]
  dosage_col <- grep("Dosage", old_names, ignore.case = TRUE, value = TRUE)[1]
  payment_col <- grep("Payment.*Limit|Limit", old_names, ignore.case = TRUE, value = TRUE)[1]

  if (is.na(hcpcs_col) || is.na(payment_col)) {
    cat("  Skipping", basename(f), "- missing key columns\n")
    return(NULL)
  }

  result <- data.table(
    hcpcs = dt[[hcpcs_col]],
    description = if (!is.na(desc_col)) dt[[desc_col]] else NA_character_,
    dosage = if (!is.na(dosage_col)) dt[[dosage_col]] else NA_character_,
    payment_limit = as.numeric(dt[[payment_col]]),
    year = dt$asp_year,
    quarter = dt$asp_quarter
  )
  result <- result[!is.na(hcpcs) & hcpcs != ""]
  return(result)
})

asp_panel <- rbindlist(asp_list[!sapply(asp_list, is.null)])

# Create time variable (numeric quarter index)
asp_panel[, yq := year + (quarter - 1) / 4]
asp_panel[, time_q := (year - 2017) * 4 + quarter]

# Remove rows with missing payment limits
asp_panel <- asp_panel[!is.na(payment_limit) & payment_limit > 0]

cat("ASP panel:", nrow(asp_panel), "drug-quarter obs\n")
cat("Unique HCPCS codes:", uniqueN(asp_panel$hcpcs), "\n")
cat("Quarter range:", min(asp_panel$yq), "to", max(asp_panel$yq), "\n")

# =============================================================================
# 2. Identify generic entry events from ASP payment limit drops
# =============================================================================
cat("\n=== Identifying generic entry events ===\n")

# Strategy: Within each HCPCS code, find quarters where the payment limit
# drops sharply (>20% decline). This signals generic entry because the ASP
# formula incorporates generic pricing with a 2-quarter lag.
# The lag windfall is the elevated payment during the transition quarters.

setorder(asp_panel, hcpcs, yq)

# Calculate quarter-over-quarter change
asp_panel[, payment_limit_lag1 := shift(payment_limit, 1), by = hcpcs]
asp_panel[, payment_limit_lag2 := shift(payment_limit, 2), by = hcpcs]
asp_panel[, pct_change := (payment_limit - payment_limit_lag1) / payment_limit_lag1]

# Find large drops (>20% decline in a single quarter)
big_drops <- asp_panel[pct_change < -0.20 & !is.na(pct_change)]
cat("Large payment limit drops (>20%):", nrow(big_drops), "events\n")

# For each HCPCS, take the FIRST large drop as the generic entry event
# Require at least 4 quarters of data before the drop
asp_panel[, n_quarters := .N, by = hcpcs]
asp_panel[, quarter_rank := frank(yq, ties.method = "min"), by = hcpcs]

# Merge quarter_rank from asp_panel into big_drops
big_drops <- merge(big_drops[, .(hcpcs, yq, pct_change, payment_limit, payment_limit_lag1)],
                   asp_panel[, .(hcpcs, yq, quarter_rank, n_quarters)],
                   by = c("hcpcs", "yq"))
entry_events <- big_drops[, .SD[which.min(yq)], by = hcpcs]
entry_events <- entry_events[quarter_rank >= 4]  # At least 4 pre-periods
cat("Generic entry events (with 4+ pre-periods):", nrow(entry_events), "\n")

# =============================================================================
# 3. Construct event study panel
# =============================================================================
cat("\n=== Constructing event study panel ===\n")

# For each entry event, create event-time relative to the drop quarter
entry_drugs <- entry_events[, .(hcpcs, entry_yq = yq,
                                pre_payment = payment_limit_lag1,
                                post_payment = payment_limit,
                                drop_pct = pct_change)]

# Merge entry timing back to full panel
event_panel <- merge(asp_panel, entry_drugs[, .(hcpcs, entry_yq)],
                     by = "hcpcs")

# Create event time (quarters relative to entry)
event_panel[, event_time := round((yq - entry_yq) * 4)]

# Keep reasonable window: -8 to +12 quarters
event_panel <- event_panel[event_time >= -8 & event_time <= 12]

# Normalize payment limit to pre-entry level (average of q-6 to q-3)
# Excludes lag window (ET -2, -1) from baseline to avoid contamination
event_panel[, pre_mean := mean(payment_limit[event_time >= -6 & event_time <= -3],
                               na.rm = TRUE), by = hcpcs]
event_panel[, norm_payment := payment_limit / pre_mean]

cat("Event study panel:", nrow(event_panel), "drug-quarter obs\n")
cat("Unique drugs in event study:", uniqueN(event_panel$hcpcs), "\n")

# =============================================================================
# 4. Compute the lag windfall
# =============================================================================
cat("\n=== Computing lag windfall ===\n")

# The windfall in quarters t and t+1 (event_time = 0 and 1) relative to the
# "immediate adjustment" counterfactual. The counterfactual = what the payment
# limit would have been if it adjusted immediately to the new equilibrium.
# Approximate the new equilibrium as the average payment limit in event_time 2-4.

event_panel[, post_eq := mean(payment_limit[event_time >= 2 & event_time <= 4],
                              na.rm = TRUE), by = hcpcs]

# Windfall = actual payment - counterfactual (immediate adjustment)
event_panel[, windfall := payment_limit - post_eq]
event_panel[, windfall_pct := windfall / pre_mean]

# Summary by event time
windfall_by_et <- event_panel[, .(
  mean_norm_payment = mean(norm_payment, na.rm = TRUE),
  se_norm_payment = sd(norm_payment, na.rm = TRUE) / sqrt(.N),
  mean_windfall_pct = mean(windfall_pct, na.rm = TRUE),
  se_windfall_pct = sd(windfall_pct, na.rm = TRUE) / sqrt(.N),
  n_drugs = .N
), by = event_time]

setorder(windfall_by_et, event_time)

cat("\nPayment limit evolution around generic entry:\n")
cat(sprintf("%-5s  %-12s  %-10s  %-12s  %s\n",
            "ET", "Norm Payment", "SE", "Windfall%", "N"))
for (i in 1:nrow(windfall_by_et)) {
  with(windfall_by_et[i], {
    cat(sprintf("%-5d  %-12.3f  %-10.3f  %-12.3f  %d\n",
                event_time, mean_norm_payment, se_norm_payment,
                mean_windfall_pct, n_drugs))
  })
}

# =============================================================================
# 5. Merge with Part B spending data for dollar amounts
# =============================================================================
cat("\n=== Merging with Part B spending ===\n")

partb_annual <- fread(file.path(data_dir, "partb_annual_spending.csv"))
cat("Annual Part B spending:", nrow(partb_annual), "drugs\n")
cat("Columns:", paste(names(partb_annual), collapse = ", "), "\n")

# Extract annual spending for drugs that experienced generic entry
# Get total spending and dosage units for the entry drugs
spending_cols <- grep("Tot_Spndng_\\d{4}", names(partb_annual), value = TRUE)
units_cols <- grep("Tot_Dsg_Unts_\\d{4}", names(partb_annual), value = TRUE)

# Match on HCPCS
entry_spending <- merge(
  entry_drugs,
  partb_annual[, c("HCPCS_Cd", "Brnd_Name", "Gnrc_Name", spending_cols, units_cols),
               with = FALSE],
  by.x = "hcpcs", by.y = "HCPCS_Cd", all.x = TRUE
)

cat("Entry drugs matched to spending data:", sum(!is.na(entry_spending$Brnd_Name)), "of",
    nrow(entry_spending), "\n")

# =============================================================================
# 6. Save cleaned data
# =============================================================================
cat("\n=== Saving cleaned data ===\n")

fwrite(asp_panel, file.path(data_dir, "asp_panel_clean.csv"))
fwrite(event_panel, file.path(data_dir, "event_study_panel.csv"))
fwrite(entry_drugs, file.path(data_dir, "generic_entry_events.csv"))
fwrite(windfall_by_et, file.path(data_dir, "windfall_by_event_time.csv"))
fwrite(entry_spending, file.path(data_dir, "entry_drugs_spending.csv"))

# Summary statistics for the paper
cat("\n=== Summary for Paper ===\n")
cat("Total drugs in ASP files:", uniqueN(asp_panel$hcpcs), "\n")
cat("Quarters covered:", min(asp_panel$year), "Q", min(asp_panel$quarter),
    "to", max(asp_panel$year), "Q", max(asp_panel$quarter), "\n")
cat("Generic entry events identified:", nrow(entry_drugs), "\n")
cat("Average pre-entry payment limit: $",
    round(mean(entry_drugs$pre_payment, na.rm = TRUE), 2), "\n")
cat("Average drop at entry:", round(mean(entry_drugs$drop_pct, na.rm = TRUE) * 100, 1), "%\n")

cat("\nData cleaning complete.\n")
