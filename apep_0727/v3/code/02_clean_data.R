## 02_clean_data.R — Construct analysis samples for bunching analysis
## apep_0727 v2: German Solar PV Bunching at 10 kWp Threshold
##
## Four policy periods:
##   1. Pre-FIT-tier:  2008-2011 (no 10 kWp threshold)
##   2. FIT kink:      2012-2013 (FIT rate tier at 10 kWp, no surcharge)
##   3. Surcharge:     2014-2020 (self-consumption surcharge, exempt <10 kWp)
##   4. Post-reform:   2021-2024 (threshold raised to 30 kWp / surcharge abolished)
##
## Note: EEG 2014 effective Aug 1, 2014. EEG 2021 effective Jan 1, 2021.
## The EEG surcharge on self-consumption was abolished effective July 1, 2022
## (Osterpaket, BGBl. I 2022 S. 1237). Calendar-year bins are a clean
## simplification because the reforms align with annual boundaries (except 2014 H1).

source("00_packages.R")

cat("Loading processed MaStR data...\n")
dt <- fread("../data/solar_installations.csv")
cat(sprintf("Loaded %s records\n", format(nrow(dt), big.mark = ",")))

# ---- Period assignment ----
dt[, period := fcase(
  year >= 2008 & year <= 2011, "1_pre_fit_tier",
  year >= 2012 & year <= 2013, "2_fit_kink",
  year >= 2014 & year <= 2020, "3_surcharge",
  year >= 2021 & year <= 2024, "4_post_reform",
  default = NA_character_
)]

# Drop 2025 (incomplete year in Feb 2025 snapshot) and pre-2008
dt <- dt[!is.na(period)]

# ---- Create bins ----
dt[, bin_01 := floor(capacity_kwp * 10) / 10]  # 0.1 kWp bins
dt[, bin_05 := floor(capacity_kwp * 2) / 2]    # 0.5 kWp bins

# ---- Main sample: ROOFTOP only ----
# The surcharge and self-consumption logic bite on rooftop residential systems.
# Ground-mount is a placebo. Balcony systems are typically <1 kWp (irrelevant).
dt_rooftop <- dt[install_type == "rooftop"]
dt_ground  <- dt[install_type == "ground_mount"]

cat(sprintf("\nMain sample (rooftop): %s records\n", format(nrow(dt_rooftop), big.mark = ",")))
cat(sprintf("Placebo (ground-mount): %s records\n", format(nrow(dt_ground), big.mark = ",")))

# ---- Analysis windows ----
# 10 kWp analysis: 3-20 kWp
dt_10 <- dt_rooftop[capacity_kwp >= 3 & capacity_kwp <= 20]
# 30 kWp analysis: 20-40 kWp
dt_30 <- dt_rooftop[capacity_kwp >= 20 & capacity_kwp <= 40]
# Ground-mount placebo: 3-20 kWp
dt_gm_10 <- dt_ground[capacity_kwp >= 3 & capacity_kwp <= 20]

cat(sprintf("\n10 kWp window (rooftop, 3-20 kWp): %s records\n",
    format(nrow(dt_10), big.mark = ",")))
cat(sprintf("30 kWp window (rooftop, 20-40 kWp): %s records\n",
    format(nrow(dt_30), big.mark = ",")))
cat(sprintf("Ground-mount 10 kWp window (3-20 kWp): %s records\n",
    format(nrow(dt_gm_10), big.mark = ",")))

# ---- Bin counts by period ----
# 10 kWp threshold
bin_10_period <- dt_10[, .(count = .N), by = .(bin_01, period)]
bin_10_wide <- dcast(bin_10_period, bin_01 ~ period, value.var = "count", fill = 0)

# Annual bins (10 kWp)
bin_10_year <- dt_10[, .(count = .N), by = .(bin_01, year)]

# 30 kWp threshold
bin_30_period <- dt_30[, .(count = .N), by = .(bin_01, period)]
bin_30_year <- dt_30[, .(count = .N), by = .(bin_01, year)]

# Ground-mount placebo
bin_gm_period <- dt_gm_10[, .(count = .N), by = .(bin_01, period)]

# ---- Module count analysis (near 10 kWp) ----
dt_modules <- dt_10[!is.na(n_modules) & capacity_kwp >= 8 & capacity_kwp <= 12]
module_summary <- dt_modules[, .(
  mean_modules = mean(n_modules),
  median_modules = median(n_modules),
  n = .N
), by = .(bin_01, period)]

# ---- Summary statistics by period ----
cat("\n=== Records by period (rooftop, 3-20 kWp) ===\n")
period_summary <- dt_10[, .(
  n = .N,
  mean_kwp = mean(capacity_kwp),
  median_kwp = median(capacity_kwp),
  mean_modules = mean(n_modules, na.rm = TRUE),
  pct_modules = 100 * mean(!is.na(n_modules))
), by = period][order(period)]
print(period_summary)

# ---- Key bins around thresholds ----
cat("\n=== 10 kWp threshold (rooftop, surcharge period) ===\n")
surcharge_10 <- bin_10_wide[bin_01 >= 9.0 & bin_01 <= 11.0,
                             .(bin_01, `3_surcharge`)]
print(surcharge_10)

cat("\n=== 10 kWp threshold (rooftop, post-reform) ===\n")
post_10 <- bin_10_wide[bin_01 >= 9.0 & bin_01 <= 11.0,
                        .(bin_01, `4_post_reform`)]
print(post_10)

# Compute headline ratios
for (p in c("3_surcharge", "4_post_reform")) {
  n99 <- bin_10_wide[bin_01 == 9.9, get(p)]
  n101 <- bin_10_wide[bin_01 == 10.1, get(p)]
  ratio <- n99 / max(n101, 1)
  cat(sprintf("  %s: 9.9 kWp = %s, 10.1 kWp = %s, ratio = %.1f:1\n",
      p, format(n99, big.mark = ","), format(n101, big.mark = ","), ratio))
}

# ---- Save all analysis datasets ----
fwrite(dt_10, "../data/solar_clean_10.csv")
fwrite(dt_30, "../data/solar_clean_30.csv")
fwrite(dt_gm_10, "../data/solar_gm_10.csv")
fwrite(bin_10_wide, "../data/bin_counts_10_period.csv")
fwrite(bin_10_year, "../data/bin_counts_10_year.csv")
fwrite(bin_30_period, "../data/bin_counts_30_period.csv")
fwrite(bin_30_year, "../data/bin_counts_30_year.csv")
fwrite(bin_gm_period, "../data/bin_counts_gm_period.csv")
fwrite(module_summary, "../data/module_summary.csv")
fwrite(period_summary, "../data/period_summary.csv")

# Save summary stats for paper
stats <- list(
  n_total_mastr = nrow(dt),
  n_rooftop = nrow(dt_rooftop),
  n_ground_mount = nrow(dt_ground),
  n_10_window = nrow(dt_10),
  n_30_window = nrow(dt_30),
  n_gm_window = nrow(dt_gm_10),
  periods = as.list(period_summary[, .(period, n)])
)
write_json(stats, "../data/clean_summary.json", auto_unbox = TRUE)

cat("\nAll analysis datasets saved.\n")
