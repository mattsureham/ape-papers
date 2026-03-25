# 02_clean_data.R — Clean and prepare ZWG panel for RDD analysis
# apep_0903: Second-Home Construction Ban RDD

base_dir <- normalizePath(file.path(getwd(), ".."))
source(file.path(base_dir, "code", "00_packages.R"))
data_dir <- file.path(base_dir, "data")

cat("=== Cleaning ZWG Panel ===\n")

panel <- readRDS(file.path(data_dir, "zwg_panel.rds"))
cat(sprintf("Raw panel: %d obs, %d columns\n", nrow(panel), ncol(panel)))
cat(sprintf("Columns: %s\n", paste(names(panel), collapse = ", ")))

# Check data types
cat("\nColumn classes:\n")
for (col in names(panel)) {
  cat(sprintf("  %s: %s (sample: %s)\n", col, class(panel[[col]])[1],
              as.character(panel[[col]][1])))
}

# ---------------------------------------------------------------
# 1. Standardize column names
# ---------------------------------------------------------------

# Map actual GeoPackage column names to analysis names
setDT(panel)
old_names <- c("Gem_No", "Name", "ZWG_3010", "ZWG_3150", "ZWG_3100",
               "ZWG_3110", "ZWG_3120")
new_names <- c("mun_id", "mun_name", "n_primary", "n_total", "n_equivalent",
               "pct_primary", "pct_secondary")

for (i in seq_along(old_names)) {
  if (old_names[i] %in% names(panel)) {
    setnames(panel, old_names[i], new_names[i])
  }
}

# Handle Status/Verfahren columns (may vary across waves)
if ("Status" %in% names(panel)) setnames(panel, "Status", "status")
if ("Verfahren" %in% names(panel)) setnames(panel, "Verfahren", "verfahren")
if ("ZWG_3200" %in% names(panel)) setnames(panel, "ZWG_3200", "n_secondary_counted")

# ---------------------------------------------------------------
# 2. Convert to numeric
# ---------------------------------------------------------------

numeric_cols <- c("mun_id", "n_primary", "n_total", "n_equivalent",
                  "pct_primary", "pct_secondary")
for (col in numeric_cols) {
  if (col %in% names(panel)) {
    panel[[col]] <- as.numeric(as.character(panel[[col]]))
  }
}

cat(sprintf("\nAfter type conversion:\n"))
cat(sprintf("  pct_secondary: mean=%.2f, sd=%.2f, range=[%.2f, %.2f]\n",
            mean(panel$pct_secondary, na.rm=TRUE),
            sd(panel$pct_secondary, na.rm=TRUE),
            min(panel$pct_secondary, na.rm=TRUE),
            max(panel$pct_secondary, na.rm=TRUE)))
cat(sprintf("  pct_primary: mean=%.2f, sd=%.2f\n",
            mean(panel$pct_primary, na.rm=TRUE),
            sd(panel$pct_primary, na.rm=TRUE)))
cat(sprintf("  n_total: mean=%.0f, median=%.0f\n",
            mean(panel$n_total, na.rm=TRUE),
            median(panel$n_total, na.rm=TRUE)))

# ---------------------------------------------------------------
# 3. Treatment assignment
# ---------------------------------------------------------------

# The 20% threshold determines treatment
# We need the INITIAL classification (first wave a municipality appears)
# Use the earliest wave's pct_secondary as the running variable

# For each municipality, get its earliest observed secondary share
first_obs <- panel[!is.na(pct_secondary),
                   .(first_pct_secondary = pct_secondary[which.min(wave_date)],
                     first_wave = wave[which.min(wave_date)]),
                   by = mun_id]

cat(sprintf("\nMunicipalities with first observation: %d\n", nrow(first_obs)))

# Treatment: municipalities whose FIRST observed secondary share >= 20%
first_obs[, treated := first_pct_secondary >= 20]
cat(sprintf("Treated (first obs >= 20%%): %d\n", sum(first_obs$treated)))
cat(sprintf("Control (first obs < 20%%): %d\n", sum(!first_obs$treated)))

# Merge treatment assignment back to panel
panel <- merge(panel, first_obs[, .(mun_id, first_pct_secondary, treated)],
               by = "mun_id", all.x = TRUE)

# Running variable: centered at 20%
panel[, running_var := first_pct_secondary - 20]

# ---------------------------------------------------------------
# 4. Summary statistics around threshold
# ---------------------------------------------------------------

cat("\n=== Distribution around 20% threshold ===\n")
breaks <- c(0, 5, 10, 15, 17, 18, 19, 19.5, 20, 20.5, 21, 22, 23, 25, 30, 40, 100)
first_obs[, bucket := cut(first_pct_secondary, breaks = breaks, right = FALSE)]
print(table(first_obs$bucket))

# Narrow bandwidth
narrow_bw <- first_obs[first_pct_secondary >= 15 & first_pct_secondary <= 25]
cat(sprintf("\nIn 15-25%% bandwidth: %d municipalities\n", nrow(narrow_bw)))
cat(sprintf("In 18-22%% bandwidth: %d municipalities\n",
            nrow(first_obs[first_pct_secondary >= 18 & first_pct_secondary < 22])))
cat(sprintf("In 19-21%% bandwidth: %d municipalities\n",
            nrow(first_obs[first_pct_secondary >= 19 & first_pct_secondary < 21])))

# ---------------------------------------------------------------
# 5. Create analysis-ready dataset
# ---------------------------------------------------------------

# Keep only municipalities with non-missing secondary share
analysis <- panel[!is.na(pct_secondary) & !is.na(mun_id)]

# Create wave index (numeric)
wave_dates <- sort(unique(analysis$wave_date))
analysis[, wave_idx := match(wave_date, wave_dates)]

# Create year variable
analysis[, year := year(wave_date)]
analysis[, month := month(wave_date)]

# Compute changes from first observation
analysis <- merge(analysis,
                  analysis[, .(baseline_pct_secondary = pct_secondary[which.min(wave_date)],
                               baseline_n_total = n_total[which.min(wave_date)]),
                           by = mun_id],
                  by = "mun_id")
analysis[, delta_pct_secondary := pct_secondary - baseline_pct_secondary]
analysis[, pct_change_total := (n_total - baseline_n_total) / baseline_n_total * 100]

cat(sprintf("\nAnalysis dataset: %d obs, %d municipalities, %d waves\n",
            nrow(analysis), uniqueN(analysis$mun_id), uniqueN(analysis$wave)))

# ---------------------------------------------------------------
# 6. Validate data
# ---------------------------------------------------------------

cat("\n=== Data Validation ===\n")

# Check: pct_primary + pct_secondary should approximate 100
analysis[, pct_sum := pct_primary + pct_secondary]
cat(sprintf("pct_primary + pct_secondary: mean=%.2f, min=%.2f, max=%.2f\n",
            mean(analysis$pct_sum, na.rm=TRUE),
            min(analysis$pct_sum, na.rm=TRUE),
            max(analysis$pct_sum, na.rm=TRUE)))

# Check: no missing running variable
cat(sprintf("Missing running_var: %d\n", sum(is.na(analysis$running_var))))

# Treatment stability
treatment_changes <- analysis[, .(n_treated_waves = sum(pct_secondary >= 20),
                                   n_total_waves = .N),
                               by = mun_id]
treatment_changes[, always_treated := n_treated_waves == n_total_waves]
treatment_changes[, never_treated := n_treated_waves == 0]
treatment_changes[, switcher := !always_treated & !never_treated]
cat(sprintf("Always above 20%%: %d\n", sum(treatment_changes$always_treated)))
cat(sprintf("Never above 20%%: %d\n", sum(treatment_changes$never_treated)))
cat(sprintf("Switchers (crossed 20%%): %d\n", sum(treatment_changes$switcher)))

# ---------------------------------------------------------------
# 7. Save
# ---------------------------------------------------------------

fwrite(analysis, file.path(data_dir, "analysis_panel.csv"))
saveRDS(analysis, file.path(data_dir, "analysis_panel.rds"))
saveRDS(first_obs, file.path(data_dir, "first_obs.rds"))

cat(sprintf("\nSaved analysis panel: %s\n", file.path(data_dir, "analysis_panel.csv")))
cat("\n=== Cleaning complete ===\n")
