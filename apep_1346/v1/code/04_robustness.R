# 04_robustness.R — Robustness checks
# apep_1346: The Lag Windfall

source("00_packages.R")

data_dir <- "../data"

event_panel <- fread(file.path(data_dir, "event_study_panel.csv"))
drug_windfall <- fread(file.path(data_dir, "drug_windfall.csv"))
entry_drugs <- fread(file.path(data_dir, "generic_entry_events.csv"))
asp_panel <- fread(file.path(data_dir, "asp_panel_clean.csv"))

cat("=== Robustness Checks ===\n\n")

# =============================================================================
# R1: Placebo test — drugs WITHOUT generic entry
# =============================================================================
cat("--- R1: Placebo (no-entry drugs) ---\n")

# Select drugs that never experience a >20% drop
entry_hcpcs <- unique(entry_drugs$hcpcs)
stable_drugs <- asp_panel[!hcpcs %in% entry_hcpcs]
stable_drugs[, pct_change := (payment_limit - shift(payment_limit, 1)) / shift(payment_limit, 1),
             by = hcpcs]

# For stable drugs, compute max quarterly variation
stable_var <- stable_drugs[!is.na(pct_change), .(
  max_drop = min(pct_change, na.rm = TRUE),
  sd_change = sd(pct_change, na.rm = TRUE),
  n_quarters = .N
), by = hcpcs]
stable_var <- stable_var[n_quarters >= 8]

cat("Stable drugs (no entry):", nrow(stable_var), "\n")
cat("Mean max quarterly drop:", round(mean(stable_var$max_drop) * 100, 1), "%\n")
cat("Mean SD of quarterly changes:", round(mean(stable_var$sd_change) * 100, 1), "%\n")

# Create fake "events" at the median quarter for placebo drugs
# Use these for a placebo event study
placebo_panel <- stable_drugs[hcpcs %in% stable_var[n_quarters >= 12]$hcpcs]
placebo_panel[, med_yq := median(yq), by = hcpcs]
placebo_panel[, event_time := round((yq - med_yq) * 4)]
placebo_panel <- placebo_panel[event_time >= -8 & event_time <= 12]
placebo_panel[, pre_mean := mean(payment_limit[event_time >= -4 & event_time <= -1],
                                  na.rm = TRUE), by = hcpcs]
placebo_panel[, norm_payment := payment_limit / pre_mean]
placebo_panel <- placebo_panel[is.finite(norm_payment)]

placebo_panel[, et_factor := factor(event_time)]
placebo_panel[, et_factor := relevel(et_factor, ref = "-3")]

m_placebo <- feols(norm_payment ~ et_factor | hcpcs,
                   data = placebo_panel,
                   cluster = ~ hcpcs)

# Extract key coefficients
placebo_coefs <- coeftable(m_placebo)
cat("\nPlacebo event study (key quarters):\n")
for (et in c(-2, -1, 0, 1, 2)) {
  row_name <- paste0("et_factor", et)
  if (row_name %in% rownames(placebo_coefs)) {
    cat(sprintf("  ET %d: %.4f (SE=%.4f, p=%.3f)\n",
                et, placebo_coefs[row_name, 1], placebo_coefs[row_name, 2],
                placebo_coefs[row_name, 4]))
  }
}

# =============================================================================
# R2: Alternative drop thresholds
# =============================================================================
cat("\n--- R2: Alternative drop thresholds ---\n")

for (threshold in c(-0.15, -0.25, -0.30)) {
  setorder(asp_panel, hcpcs, yq)
  asp_panel[, pct_ch := (payment_limit - shift(payment_limit, 1)) / shift(payment_limit, 1),
            by = hcpcs]
  asp_panel[, qrank := frank(yq, ties.method = "min"), by = hcpcs]

  drops_alt <- asp_panel[pct_ch < threshold & !is.na(pct_ch)]
  drops_alt <- drops_alt[, .SD[which.min(yq)], by = hcpcs]
  drops_alt <- drops_alt[qrank >= 4]

  cat(sprintf("  Threshold %.0f%%: %d entry events\n",
              threshold * 100, nrow(drops_alt)))
}

# =============================================================================
# R3: Exclude high-cost outliers
# =============================================================================
cat("\n--- R3: Excluding top 5% by pre-entry payment ---\n")

p95 <- quantile(drug_windfall$pre_baseline, 0.95, na.rm = TRUE)
dw_trimmed <- drug_windfall[pre_baseline <= p95]

cat("After trimming (N =", nrow(dw_trimmed), "):\n")
cat(sprintf("  Mean windfall %%: %.1f%%\n",
            mean(dw_trimmed$windfall_pct, na.rm = TRUE) * 100))
cat(sprintf("  Median windfall %%: %.1f%%\n",
            median(dw_trimmed$windfall_pct, na.rm = TRUE) * 100))
cat(sprintf("  Share positive: %.1f%%\n",
            mean(dw_trimmed$windfall_per_unit > 0, na.rm = TRUE) * 100))

# Event study on trimmed sample
trimmed_hcpcs <- dw_trimmed$hcpcs
ep_trimmed <- event_panel[hcpcs %in% trimmed_hcpcs]
ep_trimmed[, et_factor := factor(event_time)]
ep_trimmed[, et_factor := relevel(et_factor, ref = "-3")]

m_trimmed <- feols(norm_payment ~ et_factor | hcpcs,
                   data = ep_trimmed, cluster = ~ hcpcs)

trimmed_coefs <- coeftable(m_trimmed)
cat("\nTrimmed event study (key quarters):\n")
for (et in c(-2, -1, 0, 1, 2)) {
  row_name <- paste0("et_factor", et)
  if (row_name %in% rownames(trimmed_coefs)) {
    cat(sprintf("  ET %d: %.4f (SE=%.4f, p=%.3f)\n",
                et, trimmed_coefs[row_name, 1], trimmed_coefs[row_name, 2],
                trimmed_coefs[row_name, 4]))
  }
}

# =============================================================================
# R4: Year-specific results
# =============================================================================
cat("\n--- R4: Entry events by year ---\n")

# Distribution of entry events across years
entry_by_year <- entry_drugs[, .(n_entries = .N,
                                 mean_drop = mean(drop_pct)),
                            by = .(year = floor(entry_yq))]
setorder(entry_by_year, year)
print(entry_by_year)

# =============================================================================
# Save robustness results
# =============================================================================
saveRDS(list(
  m_placebo = m_placebo,
  m_trimmed = m_trimmed,
  stable_var = stable_var
), file.path(data_dir, "robustness_results.rds"))

cat("\nRobustness checks complete.\n")
