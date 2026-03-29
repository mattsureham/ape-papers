# ── 02_clean_data.R ────────────────────────────────────────────────
# Clean panel and construct analysis variables
# ───────────────────────────────────────────────────────────────────
source("code/00_packages.R")

panel <- fread("data/district_panel.csv")
cat(sprintf("Loaded panel: %d obs\n", nrow(panel)))

# ── 1. Drop problematic observations ─────────────────────────────
# Drop Telangana (state_id 36) — carved out from AP in June 2014,
# right before the 14th FC; its fc13_share is 0 (was part of AP)
panel <- panel[pc11_state_id != "36"]

# Drop districts with zero nightlights in all years (uninhabited)
zero_districts <- panel[, .(max_light = max(total_light)), by = district_id]
zero_districts <- zero_districts[max_light == 0, district_id]
cat(sprintf("Dropping %d always-dark districts\n", length(zero_districts)))
panel <- panel[!district_id %in% zero_districts]

# ── 2. Balanced panel ────────────────────────────────────────────
# Keep only districts observed in ALL 16 years 2008-2023
n_expected_years <- uniqueN(panel$year)
year_counts <- panel[, .(n_years = uniqueN(year)), by = district_id]
balanced_ids <- year_counts[n_years == n_expected_years, district_id]
cat(sprintf("Balanced panel: %d of %d districts have all %d years\n",
            length(balanced_ids), uniqueN(panel$district_id), n_expected_years))
panel <- panel[district_id %in% balanced_ids]

# ── 3. Construct baseline quartiles for heterogeneity ─────────────
# Urbanization proxy: baseline nightlight intensity (2008-2014 pre-treatment mean)
baseline <- panel[year < 2015,
                  .(baseline_light = mean(total_light)),
                  by = district_id]
panel <- merge(panel, baseline, by = "district_id")

# Quartiles of baseline economic activity
panel[, light_quartile := cut(baseline_light,
                               breaks = quantile(baseline_light, probs = 0:4/4,
                                                  na.rm = TRUE),
                               labels = c("Q1_darkest", "Q2", "Q3", "Q4_brightest"),
                               include.lowest = TRUE)]

# State income terciles (based on inverse of windfall_pc —
# poorer states got higher windfall under 14th FC formula)
state_windfall <- unique(panel[, .(pc11_state_id, windfall_pc_z, state_name)])
state_windfall[, income_tercile := cut(windfall_pc_z,
                                        breaks = quantile(windfall_pc_z, probs = 0:3/3),
                                        labels = c("low_windfall", "mid_windfall", "high_windfall"),
                                        include.lowest = TRUE)]
panel <- merge(panel, state_windfall[, .(pc11_state_id, income_tercile)],
               by = "pc11_state_id", all.x = TRUE)

# ── 4. Summary statistics ────────────────────────────────────────
cat("\n=== Summary Statistics ===\n")
cat(sprintf("States: %d\n", uniqueN(panel$pc11_state_id)))
cat(sprintf("Districts: %d\n", uniqueN(panel$district_id)))
cat(sprintf("Years: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("Observations: %d\n", nrow(panel)))

cat("\nNightlights (log):\n")
print(summary(panel$log_light))

cat("\nWindfall (z-score):\n")
print(summary(panel$windfall_pc_z))

# ── 5. Save cleaned panel ────────────────────────────────────────
fwrite(panel, "data/district_panel_clean.csv")
cat("\nCleaned panel saved.\n")
