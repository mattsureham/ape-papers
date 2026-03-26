# 02_clean_data.R — Construct analysis dataset for SDLT bunching
# apep_1020/v1

source("00_packages.R")

data_dir <- "../data/"
ppd <- fread(file.path(data_dir, "ppd_combined.csv"))
ppd[, date_transfer := as.Date(date_transfer)]

cat("Raw data:", nrow(ppd), "transactions\n")

# ============================================================
# Define regime periods
# ============================================================
# Pre-reversion:  Jan 2023 – Sep 2024 (stable SDLT regime, before announcement)
# Anticipation:   Oct 2024 – Mar 2025 (announced Oct 30, 2024)
# Post-reversion:  May 2025 – latest (April excluded as transition month)

ppd[, regime := fcase(
  date_transfer >= as.Date("2023-01-01") & date_transfer <= as.Date("2024-09-30"), "pre",
  date_transfer >= as.Date("2024-10-01") & date_transfer <= as.Date("2025-03-31"), "anticipation",
  date_transfer >= as.Date("2025-04-01") & date_transfer <= as.Date("2025-04-30"), "transition",
  date_transfer >= as.Date("2025-05-01"), "post",
  default = NA_character_
)]

ppd <- ppd[!is.na(regime)]
cat("After regime assignment:", nrow(ppd), "\n")
cat("By regime:\n")
print(ppd[, .N, by = regime])

# ============================================================
# Focus on England only (Wales has LTT, different thresholds)
# ============================================================
ppd_eng <- ppd[country == "England"]
cat("\nEngland only:", nrow(ppd_eng), "transactions\n")

# ============================================================
# Create price bins for bunching analysis
# ============================================================
# Use £2,500 bins from £50K to £2M
bin_width <- 2500
ppd_eng[, price_bin := floor(price / bin_width) * bin_width]

# Focus on price range relevant to SDLT thresholds
# Main analysis: £50K to £700K (covers £125K, £250K, £300K, £425K thresholds)
# Extended: up to £1.1M for £925K threshold
ppd_eng_main <- ppd_eng[price >= 50000 & price <= 700000]
ppd_eng_ext <- ppd_eng[price >= 50000 & price <= 1100000]

cat("\nMain sample (£50K-£700K):", nrow(ppd_eng_main), "\n")
cat("Extended sample (£50K-£1.1M):", nrow(ppd_eng_ext), "\n")

# ============================================================
# Build bin-level counts by regime
# ============================================================
# Main thresholds
bin_counts_main <- ppd_eng_main[regime %in% c("pre", "post"),
  .(count = .N),
  by = .(price_bin, regime)]

# Spread to wide format
bin_wide <- dcast(bin_counts_main, price_bin ~ regime, value.var = "count", fill = 0)

# Normalize by number of months in each regime
n_months_pre <- as.numeric(difftime(as.Date("2024-10-01"), as.Date("2023-01-01"),
                                     units = "days")) / 30.44
n_months_post <- as.numeric(difftime(as.Date("2025-12-31"), as.Date("2025-05-01"),
                                      units = "days")) / 30.44
# Use actual months from data
pre_months <- ppd_eng_main[regime == "pre", uniqueN(ym)]
post_months <- ppd_eng_main[regime == "post", uniqueN(ym)]
cat("\nPre months:", pre_months, "| Post months:", post_months, "\n")

bin_wide[, pre_monthly := pre / pre_months]
bin_wide[, post_monthly := post / post_months]

# ============================================================
# Also build anticipation period counts
# ============================================================
bin_antic <- ppd_eng_main[regime == "anticipation",
  .(anticipation = .N), by = price_bin]
antic_months <- ppd_eng_main[regime == "anticipation", uniqueN(ym)]

bin_antic[, antic_monthly := anticipation / antic_months]

bin_wide <- merge(bin_wide, bin_antic[, .(price_bin, antic_monthly)],
                  by = "price_bin", all.x = TRUE)
bin_wide[is.na(antic_monthly), antic_monthly := 0]

# ============================================================
# Extended sample for upper thresholds
# ============================================================
bin_counts_ext <- ppd_eng_ext[regime %in% c("pre", "post"),
  .(count = .N),
  by = .(price_bin, regime)]
bin_wide_ext <- dcast(bin_counts_ext, price_bin ~ regime, value.var = "count", fill = 0)
bin_wide_ext[, pre_monthly := pre / pre_months]
bin_wide_ext[, post_monthly := post / post_months]

# ============================================================
# Save analysis datasets
# ============================================================
fwrite(bin_wide, file.path(data_dir, "bin_counts_main.csv"))
fwrite(bin_wide_ext, file.path(data_dir, "bin_counts_ext.csv"))
fwrite(ppd_eng, file.path(data_dir, "ppd_england.csv"))

# Summary statistics
cat("\n=== Summary Statistics ===\n")
cat("England transactions by regime:\n")
print(ppd_eng[, .N, by = regime])
cat("\nMedian price by regime:\n")
print(ppd_eng[regime %in% c("pre", "post"), .(median_price = median(price),
  mean_price = mean(price), n = .N), by = regime])
cat("\nProperty type distribution:\n")
print(ppd_eng[, .N, by = property_type])

cat("\nCleaned data saved.\n")
