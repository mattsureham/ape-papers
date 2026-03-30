# 02_clean_data.R — Clean and prepare hospital bed panel
# APEP-1150

source("00_packages.R")

dt <- fread("../data/hospital_bed_panel.csv")
cat(sprintf("Raw panel: %d observations, %d hospitals\n", nrow(dt), uniqueN(dt$provider_id)))

# ============================================================
# 1. Remove duplicate reports per hospital-year
# ============================================================
# Some hospitals file amended reports; keep the latest one
# Use higher rpt_rec_num as proxy for later filing
dt[, max_rpt := max(as.numeric(gsub("[^0-9]", "", provider_id))), by = .(provider_id, fiscal_year)]

# If multiple reports per hospital-year, keep the one with more beds
# (amended reports are more accurate)
dt <- dt[, .SD[which.max(beds)], by = .(provider_id, fiscal_year)]
cat(sprintf("After dedup: %d observations\n", nrow(dt)))

# ============================================================
# 2. Drop implausible bed counts
# ============================================================
# Drop zero beds (closed/inactive hospitals) and extremely large (>1500)
dt <- dt[beds >= 1 & beds <= 1500]
cat(sprintf("After dropping implausible: %d observations\n", nrow(dt)))

# ============================================================
# 3. Create analysis variables
# ============================================================

# Round-number indicators
dt[, is_round5 := (beds %% 5 == 0)]
dt[, is_round10 := (beds %% 10 == 0)]

# Regulatory threshold indicators
dt[, at_cah_25 := (beds == 25)]
dt[, at_50 := (beds == 50)]
dt[, at_100 := (beds == 100)]

# Below/above threshold indicators (for subsample analysis)
dt[, below_cah := (beds <= 25)]
dt[, below_50 := (beds <= 50)]
dt[, above_100 := (beds >= 100)]

# Distance to nearest threshold
dt[, dist_to_25 := beds - 25]
dt[, dist_to_50 := beds - 50]
dt[, dist_to_100 := beds - 100]

# ============================================================
# 4. Create bed count frequency table (pooled)
# ============================================================
# For bunching analysis, we need the frequency of each bed count

# All hospitals
freq_all <- dt[, .(count = .N), by = beds][order(beds)]
freq_all[, hospital_type := "All"]

# CAH hospitals only
freq_cah <- dt[is_cah == TRUE, .(count = .N), by = beds][order(beds)]
freq_cah[, hospital_type := "CAH"]

# Non-CAH hospitals only
freq_noncah <- dt[is_cah == FALSE, .(count = .N), by = beds][order(beds)]
freq_noncah[, hospital_type := "Non-CAH"]

freq_table <- rbindlist(list(freq_all, freq_cah, freq_noncah))
fwrite(freq_table, "../data/bed_frequency.csv")

# ============================================================
# 5. Summary statistics
# ============================================================
cat("\n=== Summary Statistics ===\n")
cat(sprintf("Total hospital-years: %d\n", nrow(dt)))
cat(sprintf("Unique hospitals: %d\n", uniqueN(dt$provider_id)))
cat(sprintf("Fiscal years: %d-%d\n", min(dt$fiscal_year), max(dt$fiscal_year)))
cat(sprintf("CAH hospital-years: %d (%.1f%%)\n",
            sum(dt$is_cah), 100 * mean(dt$is_cah)))
cat(sprintf("Non-CAH hospital-years: %d (%.1f%%)\n",
            sum(!dt$is_cah), 100 * mean(!dt$is_cah)))

cat("\nBed count percentiles (all hospitals):\n")
print(quantile(dt$beds, probs = c(0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95)))

cat("\nBed count percentiles (CAH only):\n")
print(quantile(dt[is_cah == TRUE]$beds, probs = c(0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95)))

cat("\nBed count percentiles (non-CAH only):\n")
print(quantile(dt[is_cah == FALSE]$beds, probs = c(0.05, 0.10, 0.25, 0.50, 0.75, 0.90, 0.95)))

# Round-number prevalence
cat("\n=== Round-Number Heaping ===\n")
round10_counts <- dt[is_cah == FALSE & beds >= 10 & beds <= 200,
                     .(count = .N, is_regulatory = beds %in% c(25, 50, 100)),
                     by = .(beds, is_round10)]
heaping_ratio <- round10_counts[beds >= 10 & beds <= 200 & !beds %in% c(25, 50, 100),
                                .(avg_count = mean(count)),
                                by = is_round10]
cat("Average hospital-years per bed count (non-CAH, excluding regulatory thresholds):\n")
cat(sprintf("  Round-10 bed counts: %.1f\n", heaping_ratio[is_round10 == TRUE]$avg_count))
cat(sprintf("  Non-round bed counts: %.1f\n", heaping_ratio[is_round10 == FALSE]$avg_count))
cat(sprintf("  Heaping ratio: %.2f\n",
            heaping_ratio[is_round10 == TRUE]$avg_count /
            heaping_ratio[is_round10 == FALSE]$avg_count))

# ============================================================
# 6. Save cleaned panel
# ============================================================
fwrite(dt, "../data/hospital_bed_panel_clean.csv")
cat(sprintf("\nSaved cleaned panel to ../data/hospital_bed_panel_clean.csv\n"))
