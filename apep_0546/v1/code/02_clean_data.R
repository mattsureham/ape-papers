# ==============================================================================
# 02_clean_data.R — Variable Construction and Panel Assembly
# APEP-0546: Do Red Flag Laws Save Lives or Shift Deaths?
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"

# ─── 1. Load raw data ───────────────────────────────────────────────────────

cdc_mapping <- fread(file.path(data_dir, "cdc_mapping_injury.csv"))
nchs <- fread(file.path(data_dir, "nchs_suicide_1999_2017.csv"))
# nchs_hom not available from NCHS (only 11 broad causes); homicide from CDC Mapping only
erpo_dates <- fread(file.path(data_dir, "erpo_adoption_dates.csv"))
anti_erpo <- fread(file.path(data_dir, "anti_erpo_states.csv"))
gun_proxy <- fread(file.path(data_dir, "gun_ownership_proxy.csv"))

# ─── 2. Standardize state names ─────────────────────────────────────────────

# Fix DC naming inconsistency
nchs[state == "District of Columbia", state := "District of Columbia"]
cdc_mapping[state == "District of Columbia", state := "District of Columbia"]

# Verify state name consistency
states_nchs <- sort(unique(nchs$state))
states_cdc <- sort(unique(cdc_mapping$state))
cat("States in NCHS but not CDC:", setdiff(states_nchs, states_cdc), "\n")
cat("States in CDC but not NCHS:", setdiff(states_cdc, states_nchs), "\n")

# ─── 2b. Clean suppressed/impossible rate values ───────────────────────────
# CDC rates may contain suppressed values or impossible numbers
# Rates must be >= 0 and < 200 (no state has 200+ per 100K for these outcomes)
rate_cols <- grep("^rate_", names(cdc_mapping), value = TRUE)
for (col in rate_cols) {
  bad <- !is.na(cdc_mapping[[col]]) & (cdc_mapping[[col]] < 0 | cdc_mapping[[col]] > 200)
  if (sum(bad) > 0) {
    cat("  Cleaned", sum(bad), "impossible values in", col, "\n")
    set(cdc_mapping, which(bad), col, NA_real_)
  }
}
# Also clean death counts
death_cols <- grep("^deaths_", names(cdc_mapping), value = TRUE)
for (col in death_cols) {
  bad <- !is.na(cdc_mapping[[col]]) & cdc_mapping[[col]] < 0
  if (sum(bad) > 0) {
    cat("  Cleaned", sum(bad), "negative death counts in", col, "\n")
    set(cdc_mapping, which(bad), col, NA_integer_)
  }
}

# Recompute non-firearm suicide after cleaning
cdc_mapping[, `:=`(
  deaths_NF_Suicide = fifelse(!is.na(deaths_All_Suicide) & !is.na(deaths_FA_Suicide),
                               deaths_All_Suicide - deaths_FA_Suicide, NA_integer_),
  rate_NF_Suicide = fifelse(!is.na(rate_All_Suicide) & !is.na(rate_FA_Suicide),
                             rate_All_Suicide - rate_FA_Suicide, NA_real_)
)]
# Clean NF_Suicide if result is negative (possible with age-adjusted rates)
cdc_mapping[!is.na(rate_NF_Suicide) & rate_NF_Suicide < 0, rate_NF_Suicide := NA_real_]

# ─── 3. Build combined panel (1999-2024, gap in 2018) ───────────────────────

# Panel A: NCHS 1999-2017 (total suicide only)
panel_a <- nchs[, .(state, year, rate_All_Suicide, deaths_All_Suicide)]

# Homicide only available from 2019-2024 panel (not from NCHS)

# Panel B: CDC Mapping Injury 2019-2024 (full detail)
panel_b <- cdc_mapping[, .(state, year,
  rate_All_Suicide, deaths_All_Suicide,
  rate_FA_Suicide, deaths_FA_Suicide,
  rate_NF_Suicide, deaths_NF_Suicide,
  rate_Drug_OD, deaths_Drug_OD,
  rate_FA_Homicide, deaths_FA_Homicide,
  rate_All_Homicide, deaths_All_Homicide)]

# Combined panel on total suicide (common variable)
combined <- rbindlist(list(panel_a, panel_b), fill = TRUE)
combined <- combined[order(state, year)]

cat("Combined panel: ", nrow(combined), " state-year observations\n")
cat("  Year range: ", min(combined$year), "-", max(combined$year), "\n")
cat("  States: ", uniqueN(combined$state), "\n")

# ─── 4. Add ERPO treatment variables ────────────────────────────────────────

# All states
all_states <- data.table(state = unique(combined$state))

# Merge ERPO adoption
all_states <- merge(all_states, erpo_dates, by = "state", all.x = TRUE)
all_states <- merge(all_states, anti_erpo, by = "state", all.x = TRUE)
all_states[is.na(anti_erpo), anti_erpo := FALSE]

# Treatment group classification
all_states[, erpo_status := fifelse(
  !is.na(erpo_year), "ERPO adopted",
  fifelse(anti_erpo, "Anti-ERPO", "Never treated")
)]

cat("\nTreatment group distribution:\n")
print(all_states[, .N, by = erpo_status])

# Merge to panel
combined <- merge(combined, all_states, by = "state", all.x = TRUE)

# Binary treatment indicator: 1 if year >= erpo_year
combined[, treated := fifelse(!is.na(erpo_year) & year >= erpo_year, 1L, 0L)]

# For CS-DiD: G variable (first treatment year; 0 for never-treated)
combined[, G := fifelse(!is.na(erpo_year), erpo_year, 0L)]

# ─── 5. Add gun ownership proxy ─────────────────────────────────────────────

combined <- merge(combined, gun_proxy, by = "state", all.x = TRUE)

# Create high/low gun ownership indicator (above/below median)
median_gun <- median(gun_proxy$gun_ownership_proxy, na.rm = TRUE)
combined[, high_gun_ownership := fifelse(
  gun_ownership_proxy >= median_gun, 1L, 0L)]

# ─── 6. Create state numeric ID for did package ─────────────────────────────

state_ids <- combined[, .(state = unique(state))][order(state)]
state_ids[, state_id := .I]
combined <- merge(combined, state_ids, by = "state")

# ─── 7. Population estimates ────────────────────────────────────────────────

pop_est <- fread(file.path(data_dir, "state_population_estimates.csv"))
combined <- merge(combined, pop_est[, .(state, year, pop_est)],
                  by = c("state", "year"), all.x = TRUE)

# ─── 8. Log transform rates (for percent interpretation) ────────────────────

combined[, `:=`(
  log_rate_All_Suicide = log(rate_All_Suicide + 0.1),
  log_rate_FA_Suicide = fifelse(!is.na(rate_FA_Suicide),
                                 log(rate_FA_Suicide + 0.1), NA_real_),
  log_rate_NF_Suicide = fifelse(!is.na(rate_NF_Suicide),
                                 log(pmax(rate_NF_Suicide, 0.1)), NA_real_),
  log_rate_Drug_OD = fifelse(!is.na(rate_Drug_OD),
                              log(rate_Drug_OD + 0.1), NA_real_)
)]

# ─── 9. Summary Statistics ──────────────────────────────────────────────────

cat("\n=== Summary Statistics ===\n")

# By treatment status
cat("\nTotal suicide rate by treatment group (1999-2024):\n")
print(combined[, .(
  mean_rate = mean(rate_All_Suicide, na.rm = TRUE),
  sd_rate = sd(rate_All_Suicide, na.rm = TRUE),
  n_obs = .N
), by = erpo_status])

# Pre-treatment means for treated states
cat("\nPre-treatment total suicide rate (treated states only):\n")
print(combined[!is.na(erpo_year) & year < erpo_year, .(
  mean_rate = mean(rate_All_Suicide, na.rm = TRUE),
  sd_rate = sd(rate_All_Suicide, na.rm = TRUE),
  n_obs = .N
)])

# Panel balance
cat("\nPanel balance check (observations per year):\n")
print(combined[, .N, by = year][order(year)])

# ─── 10. Save analysis-ready panels ─────────────────────────────────────────

# Full combined panel (total suicide, 1999-2024)
fwrite(combined, file.path(data_dir, "panel_combined.csv"))

# Short panel with mechanism decomposition (2019-2024)
short_panel <- combined[year >= 2019]
fwrite(short_panel, file.path(data_dir, "panel_short_2019_2024.csv"))

# Export summary statistics for tables
sumstats <- combined[, .(
  Variable = c("All Suicide Rate", "FA Suicide Rate", "NF Suicide Rate",
               "Drug OD Rate", "All Homicide Rate",
               "Gun Ownership Proxy", "ERPO Adopted"),
  Mean = c(
    mean(rate_All_Suicide, na.rm = TRUE),
    mean(rate_FA_Suicide[year >= 2019], na.rm = TRUE),
    mean(rate_NF_Suicide[year >= 2019], na.rm = TRUE),
    mean(rate_Drug_OD[year >= 2019], na.rm = TRUE),
    mean(rate_All_Homicide, na.rm = TRUE),
    mean(gun_ownership_proxy, na.rm = TRUE),
    mean(treated, na.rm = TRUE)
  ),
  SD = c(
    sd(rate_All_Suicide, na.rm = TRUE),
    sd(rate_FA_Suicide[year >= 2019], na.rm = TRUE),
    sd(rate_NF_Suicide[year >= 2019], na.rm = TRUE),
    sd(rate_Drug_OD[year >= 2019], na.rm = TRUE),
    sd(rate_All_Homicide, na.rm = TRUE),
    sd(gun_ownership_proxy, na.rm = TRUE),
    sd(treated, na.rm = TRUE)
  )
)]
fwrite(sumstats, file.path(data_dir, "summary_statistics.csv"))

cat("\nAll data cleaned and saved.\n")
cat("  panel_combined.csv: ", nrow(combined), " obs\n")
cat("  panel_short_2019_2024.csv: ", nrow(short_panel), " obs\n")
cat("DONE.\n")
