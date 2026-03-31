## 02_clean_data.R — apep_1223: The Choice Tax
## Merge data sources, compute shares, and build analysis panel

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Load and merge pot-size × method panel
# ============================================================
panel <- fread(file.path(data_dir, "panel_potsize_method.csv"))
supplement <- fread(file.path(data_dir, "panel_potsize_method_1518_supplement.csv"))

# Merge supplement (2015-18 full_withdrawal and ufpls)
# Remove any existing records that overlap before merging
panel <- rbind(panel, supplement)
# Remove duplicates: keep the one with the higher count (supplement is more complete)
panel <- panel[, .(count = max(count, na.rm = TRUE)), by = .(period, pot_size, method)]

# Period ordering
period_order <- c("H2_2015", "H1_2016", "H2_2016", "H1_2017", "H2_2017",
                  "H1_2018", "H2_2018", "H1_2019", "H2_2019",
                  "H1_2020", "H2_2020", "H1_2021", "H2_2021",
                  "H1_2022", "H2_2022", "H1_2023", "H2_2023")

panel[, period_num := match(period, period_order)]
panel <- panel[!is.na(period_num)]

# Pot-size ordering with numeric midpoints for regressions
pot_order <- c("<10K", "10-29K", "30-49K", "50-99K", "100-249K", "250K+")
pot_midpoints <- c(5000, 19500, 39500, 74500, 174500, 375000)
panel[, pot_idx := match(pot_size, pot_order)]
panel[, pot_mid := pot_midpoints[pot_idx]]
panel[, log_pot := log(pot_mid)]

# ============================================================
# 2. Reshape to wide (one row per period × pot_size)
# ============================================================
panel_wide <- dcast(panel, period + period_num + pot_size + pot_idx + pot_mid + log_pot ~ method,
                    value.var = "count", fill = 0, fun.aggregate = sum)

# Compute totals and shares
panel_wide[, total := annuity + drawdown + ufpls + full_withdrawal]
panel_wide[total > 0, `:=`(
  share_annuity = annuity / total,
  share_drawdown = drawdown / total,
  share_ufpls = ufpls / total,
  share_fullwd = full_withdrawal / total
)]

# Calendar year for time trends
panel_wide[, year := as.numeric(sub("H[12]_", "", period))]
panel_wide[, half := as.numeric(sub("H([12])_.*", "\\1", period))]
panel_wide[, time := year + (half - 1) * 0.5]

cat("Panel wide summary:\n")
cat(sprintf("  Rows: %d | Periods: %d | Pot sizes: %d\n",
            nrow(panel_wide), uniqueN(panel_wide$period), uniqueN(panel_wide$pot_size)))
cat(sprintf("  Total pots in dataset: %s\n", format(sum(panel_wide$total, na.rm = TRUE), big.mark = ",")))

# ============================================================
# 3. Load advice data (2018-24)
# ============================================================
advice <- fread(file.path(data_dir, "advice_1824.csv"))
advice[, pot_idx := match(pot_size, pot_order)]
advice[, pot_mid := pot_midpoints[pot_idx]]
advice[, log_pot := log(pot_mid)]
advice[, period_num := match(period, period_order)]

# Cross-period averages by pot size
advice_avg <- advice[, .(
  mean_advice_rate = mean(advice_rate, na.rm = TRUE),
  mean_any_help = mean(any_help_rate, na.rm = TRUE),
  mean_no_advice = 1 - mean(any_help_rate, na.rm = TRUE),
  total_pots = sum(total, na.rm = TRUE)
), by = pot_size]
advice_avg[, pot_idx := match(pot_size, pot_order)]
setorder(advice_avg, pot_idx)

cat("\nAdvice rates (2018-24 average):\n")
print(advice_avg)

# ============================================================
# 4. Compute cross-period averages for descriptive tables
# ============================================================
desc <- panel_wide[, .(
  mean_total = mean(total, na.rm = TRUE),
  mean_share_fullwd = mean(share_fullwd, na.rm = TRUE),
  mean_share_annuity = mean(share_annuity, na.rm = TRUE),
  mean_share_drawdown = mean(share_drawdown, na.rm = TRUE),
  n_periods = .N
), by = .(pot_size, pot_idx)]
setorder(desc, pot_idx)

cat("\nDescriptive averages:\n")
print(desc)

# ============================================================
# 5. Save analysis-ready datasets
# ============================================================
fwrite(panel_wide, file.path(data_dir, "analysis_panel.csv"))
fwrite(advice, file.path(data_dir, "advice_clean.csv"))
fwrite(advice_avg, file.path(data_dir, "advice_averages.csv"))

cat("\nClean data saved.\n")
