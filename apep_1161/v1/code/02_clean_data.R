# 02_clean_data.R — Construct analysis panel from aggregated MOT data
# apep_1161: The Compliance Upgrade

source("00_packages.R")

# ---- Read aggregated panel ----
panel <- fread("../data/mot_panel.csv")
cat("Raw panel rows:", nrow(panel), "\n")
cat("Unique postcode areas:", uniqueN(panel$postcode_area), "\n")
cat("Years:", sort(unique(panel$year)), "\n")

# ---- Define treatment timing ----
# Map treatment_wave to first treatment year (year the zone became active)
wave_year <- data.table(
  treatment_wave = c("phase1_central", "phase2_inner", "phase3_birmingham",
                     "phase4_bristol", "phase5_outer", "never"),
  first_treat_year = c(2019, 2021, 2021, 2022, 2023, Inf)
)

panel <- merge(panel, wave_year, by = "treatment_wave", all.x = TRUE)

# Binary treated indicator: is this postcode-year under active ULEZ/CAZ?
panel[, treated := as.integer(year >= first_treat_year)]

# For Callaway-Sant'Anna: gname needs 0 for never-treated
panel[, g_period := ifelse(is.infinite(first_treat_year), 0, first_treat_year)]

# ---- Focus on petrol and diesel (drop "other" fuel types) ----
panel_main <- panel[fuel_type %in% c("petrol", "diesel")]
cat("Panel after keeping petrol/diesel:", nrow(panel_main), "\n")

# ---- Create postcode-area level panel (collapse across fuel types) ----
panel_pc <- panel_main[, .(
  n_tests = sum(n_tests),
  n_fail = sum(n_fail),
  n_pass = sum(n_pass),
  fail_rate = sum(n_fail) / sum(n_tests),
  avg_mileage = weighted.mean(avg_mileage, n_tests, na.rm = TRUE),
  avg_age = weighted.mean(avg_age, n_tests, na.rm = TRUE),
  euro4_tests = sum(euro4_tests),
  euro4_fail = sum(euro4_fail),
  euro4_fail_rate = sum(euro4_fail) / pmax(sum(euro4_tests), 1)
), by = .(year, postcode_area, treatment_wave, first_treat_year, treated, g_period)]

cat("Postcode-area panel rows:", nrow(panel_pc), "\n")
cat("Treated areas:", uniqueN(panel_pc[treated == 1]$postcode_area), "\n")
cat("Never-treated areas:", uniqueN(panel_pc[g_period == 0]$postcode_area), "\n")

# ---- Create diesel-specific and petrol-specific panels ----
panel_diesel <- panel_main[fuel_type == "diesel", .(
  n_tests, n_fail, fail_rate, avg_mileage, avg_age,
  euro4_tests, euro4_fail, euro4_fail_rate,
  year, postcode_area, treatment_wave, first_treat_year, treated, g_period
)]

panel_petrol <- panel_main[fuel_type == "petrol", .(
  n_tests, n_fail, fail_rate, avg_mileage, avg_age,
  euro4_tests, euro4_fail, euro4_fail_rate,
  year, postcode_area, treatment_wave, first_treat_year, treated, g_period
)]

# ---- Create unique postcode-area ID for panel estimation ----
pc_ids <- data.table(
  postcode_area = sort(unique(panel_pc$postcode_area)),
  pc_id = seq_len(uniqueN(panel_pc$postcode_area))
)

panel_pc <- merge(panel_pc, pc_ids, by = "postcode_area")
panel_diesel <- merge(panel_diesel, pc_ids, by = "postcode_area")
panel_petrol <- merge(panel_petrol, pc_ids, by = "postcode_area")

# ---- Drop tiny postcode areas (< 1000 tests/year) for stability ----
min_tests <- panel_pc[, .(min_n = min(n_tests)), by = postcode_area]
keep_pcs <- min_tests[min_n >= 1000]$postcode_area

panel_pc <- panel_pc[postcode_area %in% keep_pcs]
panel_diesel <- panel_diesel[postcode_area %in% keep_pcs]
panel_petrol <- panel_petrol[postcode_area %in% keep_pcs]

cat("\nAfter dropping tiny areas:\n")
cat("Postcode areas remaining:", uniqueN(panel_pc$postcode_area), "\n")
cat("Treated:", uniqueN(panel_pc[g_period > 0]$postcode_area), "\n")
cat("Never-treated:", uniqueN(panel_pc[g_period == 0]$postcode_area), "\n")

# ---- Save analysis-ready data ----
fwrite(panel_pc, "../data/analysis_panel_pc.csv")
fwrite(panel_diesel, "../data/analysis_panel_diesel.csv")
fwrite(panel_petrol, "../data/analysis_panel_petrol.csv")
fwrite(panel_main, "../data/analysis_panel_fuel.csv")

cat("\nAnalysis panels saved.\n")
