# 02_clean_data.R — Construct analysis panel
# apep_0839: TFP Revision and Food Security

source("00_packages.R")

this_dir <- tryCatch(
  dirname(rstudioapi::getSourceEditorContext()$path),
  error = function(e) {
    args <- commandArgs(trailingOnly = FALSE)
    file_arg <- grep("--file=", args, value = TRUE)
    if (length(file_arg) > 0) dirname(sub("--file=", "", file_arg))
    else getwd()
  }
)
setwd(this_dir)

data_dir <- "../data/"

cat("=== CLEANING DATA FOR APEP_0839 ===\n\n")

# ─── Load data ───
acs <- fread(paste0(data_dir, "acs_panel.csv"))
dosage <- fread(paste0(data_dir, "dosage_2019.csv"))
ea <- fread(paste0(data_dir, "ea_end_dates.csv"))
unemp <- fread(paste0(data_dir, "state_unemployment.csv"))

cat(sprintf("ACS panel: %d obs, %d states\n", nrow(acs), uniqueN(acs$fips)))
cat(sprintf("Dosage: %d states\n", nrow(dosage)))

# ─── Merge dosage (2019 SNAP rate) ───
panel <- merge(acs, dosage[, .(fips, snap_rate_2019, poverty_rate_2019, population_2019)],
               by = "fips", all.x = TRUE)

# ─── Merge EA timing ───
panel <- merge(panel, ea[, .(fips, early_ea_end)], by = "fips", all.x = TRUE)

# ─── Merge unemployment ───
panel <- merge(panel, unemp, by = c("state_abbr", "year"), all.x = TRUE)

# ─── Treatment indicators ───
# TFP effective Oct 1, 2021. ACS is calendar year survey.
# 2021 ACS covers Jan-Dec 2021, so only partial treatment (~3 months).
# Clean post-treatment: 2022, 2023
# Partial: 2021
# Pre-treatment: 2017, 2018, 2019

panel[, post_tfp := fifelse(year >= 2022, 1L, 0L)]
panel[, partial_tfp := fifelse(year == 2021, 1L, 0L)]

# Treatment intensity = post × 2019 SNAP rate
panel[, treat_intensity := post_tfp * snap_rate_2019]
panel[, treat_intensity_partial := partial_tfp * snap_rate_2019]

# Triple-diff: treatment × early EA end
panel[, triple_diff := treat_intensity * early_ea_end]

# Standardize dosage for interpretability
panel[, snap_dose_sd := (snap_rate_2019 - mean(snap_rate_2019, na.rm = TRUE)) /
        sd(snap_rate_2019, na.rm = TRUE)]

# ─── Event study dummies ───
# Base year: 2019 (last full pre-treatment year)
for (yr in unique(panel$year)) {
  panel[, paste0("yr_", yr) := fifelse(year == yr, 1L, 0L)]
}
# Interactions with dosage for event study
for (yr in setdiff(unique(panel$year), 2019)) {
  panel[, paste0("dose_yr_", yr) := snap_rate_2019 * get(paste0("yr_", yr))]
}

# ─── Outcomes in percentage points (easier to interpret) ───
panel[, snap_rate_pct := snap_rate * 100]
panel[, poverty_rate_pct := poverty_rate * 100]
panel[, snap_rate_2019_pct := snap_rate_2019 * 100]

# ─── Log income ───
panel[, ln_median_income := log(median_hh_income)]

# ─── Summary statistics ───
cat("\n=== PANEL SUMMARY ===\n")
cat(sprintf("Observations: %d\n", nrow(panel)))
cat(sprintf("States: %d\n", uniqueN(panel$fips)))
cat(sprintf("Years: %s\n", paste(sort(unique(panel$year)), collapse = ", ")))
cat(sprintf("Note: ACS 2020 not released (COVID). Panel has 6 years.\n"))

cat("\n--- Pre-treatment (2014-2019) ---\n")
pre <- panel[year <= 2019]
cat(sprintf("  SNAP rate: mean=%.1f%%, SD=%.1f%%\n",
            mean(pre$snap_rate_pct), sd(pre$snap_rate_pct)))
cat(sprintf("  Poverty rate: mean=%.1f%%, SD=%.1f%%\n",
            mean(pre$poverty_rate_pct), sd(pre$poverty_rate_pct)))
cat(sprintf("  Unemployment: mean=%.1f%%\n", mean(pre$unemp_rate, na.rm = TRUE)))

cat("\n--- Post-treatment (2022-2023) ---\n")
post <- panel[year >= 2022]
cat(sprintf("  SNAP rate: mean=%.1f%%, SD=%.1f%%\n",
            mean(post$snap_rate_pct), sd(post$snap_rate_pct)))
cat(sprintf("  Poverty rate: mean=%.1f%%, SD=%.1f%%\n",
            mean(post$poverty_rate_pct), sd(post$poverty_rate_pct)))
cat(sprintf("  Unemployment: mean=%.1f%%\n", mean(post$unemp_rate, na.rm = TRUE)))

cat("\n--- Dosage variation ---\n")
cat(sprintf("  2019 SNAP rate: mean=%.1f%%, SD=%.1f%%, min=%.1f%%, max=%.1f%%\n",
            mean(dosage$snap_rate_2019 * 100), sd(dosage$snap_rate_2019 * 100),
            min(dosage$snap_rate_2019 * 100), max(dosage$snap_rate_2019 * 100)))
cat(sprintf("  Early EA-end states: %d (%.0f%%)\n",
            sum(ea$early_ea_end), 100 * mean(ea$early_ea_end)))

# ─── Save analysis panel ───
fwrite(panel, paste0(data_dir, "analysis_panel.csv"))
cat(sprintf("\nSaved analysis_panel.csv: %d rows, %d cols\n", nrow(panel), ncol(panel)))

cat("\n=== CLEANING COMPLETE ===\n")
