## 02_clean_data.R — Variable construction and panel preparation
## apep_0519: MuKEn 2014 Building Energy Codes and Heat Pump Adoption

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "panel_canton_year.csv"))
surface <- fread(file.path(data_dir, "panel_surface.csv"))

## ============================================================================
## 1. CONSTRUCT ANALYSIS VARIABLES
## ============================================================================

## Change in heat pump count (absolute)
setorder(panel, canton, year)
panel[, delta_hp := n_heat_pump - shift(n_heat_pump, 1), by = canton]
panel[, delta_oil := n_oil - shift(n_oil, 1), by = canton]
panel[, delta_gas := n_gas - shift(n_gas, 1), by = canton]

## Log heat pump share (for proportional effects)
panel[, log_hp_share := log(share_heat_pump + 0.001)]
panel[, log_fossil_share := log(share_fossil + 0.001)]

## Treatment cohort groups for CS-DiD
panel[, cohort := fifelse(is.na(adoption_year), Inf, as.numeric(adoption_year))]
panel[, cohort_label := fifelse(is.na(adoption_year), "Never",
                                as.character(adoption_year))]

## Treatment intensity: years since adoption (censored at 0 for pre-treatment)
panel[, years_treated := pmax(0L, years_since_adoption, na.rm = TRUE)]
panel[is.na(adoption_year), years_treated := 0L]

## Relative time to treatment (for event study)
panel[, rel_time := fifelse(is.na(adoption_year), NA_integer_, years_since_adoption)]

## Pre/post indicator
panel[, post := fifelse(year >= 2021, 1L, 0L)]

## Early vs late adopter (pre-2020 vs 2020+)
panel[, early_adopter := fifelse(!is.na(adoption_year) & adoption_year < 2020, 1L, 0L)]

## ============================================================================
## 2. CREATE ANALYSIS SUBSETS
## ============================================================================

## Building counts panel (2009-2015, 2021, 2022)
panel_counts <- panel[!is.na(share_heat_pump)]

## Surface panel (2021-2023)
panel_surface <- panel[!is.na(pct_heat_pump_surface)]

## Long-difference panel: average pre (2009-2015) vs post (2021-2022)
panel_pre <- panel_counts[year <= 2015, .(
  share_heat_pump_pre = mean(share_heat_pump, na.rm = TRUE),
  share_oil_pre = mean(share_oil, na.rm = TRUE),
  share_gas_pre = mean(share_gas, na.rm = TRUE),
  share_fossil_pre = mean(share_fossil, na.rm = TRUE),
  n_heat_pump_pre = mean(n_heat_pump, na.rm = TRUE),
  total_buildings_pre = mean(total_buildings, na.rm = TRUE)
), by = .(canton, adoption_year, adopted, cohort_label)]

panel_post <- panel_counts[year >= 2021, .(
  share_heat_pump_post = mean(share_heat_pump, na.rm = TRUE),
  share_oil_post = mean(share_oil, na.rm = TRUE),
  share_gas_post = mean(share_gas, na.rm = TRUE),
  share_fossil_post = mean(share_fossil, na.rm = TRUE),
  n_heat_pump_post = mean(n_heat_pump, na.rm = TRUE),
  total_buildings_post = mean(total_buildings, na.rm = TRUE)
), by = .(canton, adoption_year, adopted, cohort_label)]

panel_long_diff <- merge(panel_pre, panel_post, by = c("canton", "adoption_year", "adopted", "cohort_label"))
panel_long_diff[, `:=`(
  delta_hp_share = share_heat_pump_post - share_heat_pump_pre,
  delta_oil_share = share_oil_post - share_oil_pre,
  delta_fossil_share = share_fossil_post - share_fossil_pre,
  years_exposed = fifelse(is.na(adoption_year), 0,
                          pmax(0, 2022 - adoption_year))
)]

## ============================================================================
## 3. SUMMARY STATISTICS
## ============================================================================

cat("=== Panel Summary ===\n")
cat("Canton-year observations:", nrow(panel_counts), "\n")
cat("Cantons:", uniqueN(panel_counts$canton), "\n")
cat("Years:", paste(sort(unique(panel_counts$year)), collapse = ", "), "\n\n")

cat("Treatment cohorts:\n")
print(panel_counts[, .(n_cantons = uniqueN(canton)), by = cohort_label][order(cohort_label)])

cat("\nHeat pump share trends:\n")
print(panel_counts[, .(mean_hp = round(mean(share_heat_pump), 3),
                        mean_oil = round(mean(share_oil), 3),
                        mean_fossil = round(mean(share_fossil), 3)),
                   by = year][order(year)])

cat("\nLong-difference: Mean change in HP share by treatment status\n")
panel_long_diff[, .(
  mean_delta_hp = round(mean(delta_hp_share), 3),
  sd_delta_hp = round(sd(delta_hp_share), 3),
  n = .N
), by = .(treated = adoption_year <= 2021 & !is.na(adoption_year))]

## ============================================================================
## 4. SAVE
## ============================================================================

fwrite(panel_counts, file.path(data_dir, "analysis_panel.csv"))
fwrite(panel_long_diff, file.path(data_dir, "long_difference.csv"))
fwrite(panel_surface, file.path(data_dir, "surface_panel.csv"))

cat("\nAnalysis datasets saved.\n")
