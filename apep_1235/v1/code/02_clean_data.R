## 02_clean_data.R — Construct analysis panel from STATENT municipal data
source("00_packages.R")

cat("=== Constructing Analysis Panel ===\n")

## ---- Load raw data ----
df_raw <- fread("../data/statent_municipal_raw.csv")

## ---- Identify observation unit codes ----
# BFS typically: 1=Arbeitsstätten (establishments), 2=Beschäftigte (employees), 5=VZÄ (FTE)
obs_lookup <- fread("../data/obs_lookup.csv")
cat("Observation units:\n")
print(obs_lookup)

# Identify the employee count variable — total only (not gendered)
emp_code <- obs_lookup[obs_name == "Beschäftigte", obs_unit]
est_code <- obs_lookup[obs_name == "Arbeitsstätten", obs_unit]
fte_code <- obs_lookup[obs_name == "Vollzeitäquivalente", obs_unit]

# Fallbacks
if (length(emp_code) != 1) emp_code <- 2L
if (length(est_code) != 1) est_code <- 1L
if (length(fte_code) != 1) fte_code <- 5L

cat("Employee code:", emp_code, "\n")
cat("Establishment code:", est_code, "\n")
cat("FTE code:", fte_code, "\n")

## ---- Identify sector codes ----
sec_lookup <- fread("../data/sector_lookup.csv")
cat("\nSectors:\n")
print(sec_lookup)

# Map to broad categories (exact match for safety)
total_code <- sec_lookup[grepl("Total", sector_name), sector][1]
sec2_code  <- sec_lookup[grepl("Sekund", sector_name), sector][1]
sec3_code  <- sec_lookup[grepl("Terti", sector_name), sector][1]

cat("Total sector code:", total_code, "\n")
cat("Secondary sector code:", sec2_code, "\n")
cat("Tertiary sector code:", sec3_code, "\n")

## Ensure consistent types for filtering
df_raw[, obs_unit := as.integer(obs_unit)]
df_raw[, sector := as.integer(sector)]
emp_code <- as.integer(emp_code)
est_code <- as.integer(est_code)
fte_code <- as.integer(fte_code)
total_code <- as.integer(total_code)
sec2_code <- as.integer(sec2_code)
sec3_code <- as.integer(sec3_code)

## ---- Reshape: one row per municipality-year ----
# Employees by sector
emp_wide <- dcast(df_raw[obs_unit == emp_code & sector %in% c(total_code, sec2_code, sec3_code)],
                  gem_id + gem_name + year ~ sector, value.var = "value")

# Rename dynamically (dcast creates character column names from integer codes)
old_chr <- as.character(c(total_code, sec2_code, sec3_code))
new_emp  <- c("emp_total", "emp_secondary", "emp_tertiary")
for (i in seq_along(old_chr)) {
  if (old_chr[i] %in% names(emp_wide)) setnames(emp_wide, old_chr[i], new_emp[i])
}

# Establishments by sector
est_wide <- dcast(df_raw[obs_unit == est_code & sector %in% c(total_code, sec2_code, sec3_code)],
                  gem_id + year ~ sector, value.var = "value")
new_est <- c("est_total", "est_secondary", "est_tertiary")
for (i in seq_along(old_chr)) {
  if (old_chr[i] %in% names(est_wide)) setnames(est_wide, old_chr[i], new_est[i])
}

# FTE by sector
fte_wide <- dcast(df_raw[obs_unit == fte_code & sector %in% c(total_code, sec2_code, sec3_code)],
                  gem_id + year ~ sector, value.var = "value")
new_fte <- c("fte_total", "fte_secondary", "fte_tertiary")
for (i in seq_along(old_chr)) {
  if (old_chr[i] %in% names(fte_wide)) setnames(fte_wide, old_chr[i], new_fte[i])
}

## ---- Merge all measures ----
panel <- merge(emp_wide, est_wide, by = c("gem_id", "year"), all.x = TRUE)
panel <- merge(panel, fte_wide, by = c("gem_id", "year"), all.x = TRUE)

## ---- Construct key variables ----
# Sectoral employment shares
panel[, manuf_share := emp_secondary / emp_total]
panel[, service_share := emp_tertiary / emp_total]

# Log employment
panel[, log_emp_secondary := log(pmax(emp_secondary, 1))]
panel[, log_emp_tertiary := log(pmax(emp_tertiary, 1))]
panel[, log_emp_total := log(pmax(emp_total, 1))]

# FTE per establishment (intensive margin)
panel[est_secondary > 0, fte_per_est_sec := fte_secondary / est_secondary]
panel[est_tertiary > 0, fte_per_est_tert := fte_tertiary / est_tertiary]

# Post-shock indicator
panel[, post := as.integer(year >= 2015)]

## ---- Construct treatment exposure (2014 manufacturing share) ----
exposure_2014 <- panel[year == 2014, .(gem_id, manuf_share_2014 = manuf_share,
                                        emp_total_2014 = emp_total,
                                        emp_secondary_2014 = emp_secondary)]

panel <- merge(panel, exposure_2014, by = "gem_id", all.x = TRUE)

# Binary treatment: >30% manufacturing in 2014
panel[, high_manuf := as.integer(manuf_share_2014 > 0.30)]

## ---- Drop municipalities with missing 2014 data or zero employment ----
n_before <- uniqueN(panel$gem_id)
panel <- panel[!is.na(manuf_share_2014) & emp_total_2014 > 0]
n_after <- uniqueN(panel$gem_id)
cat("\nMunicipalities: ", n_before, " -> ", n_after, " (dropped", n_before - n_after, "with missing 2014 data)\n")

## ---- Extract canton from gem_id (first digit(s) for canton approximation) ----
# BFS gem_id encodes canton: first 1-2 digits. Use lookup.
# Simple approach: first classify by gem_id ranges
# Actually, we need the gem_name which includes canton info, or use a crosswalk
# For now, extract from gem_name patterns or use the first digits
# BFS encoding: gem_id 1-299 = ZH, 301-399 = BE, etc.
# This is approximate; for robustness we'd need a proper crosswalk

## ---- Summary statistics ----
cat("\n=== Panel Summary ===\n")
cat("Municipalities:", uniqueN(panel$gem_id), "\n")
cat("Years:", sort(unique(panel$year)), "\n")
cat("Total observations:", nrow(panel), "\n")

cat("\nManufacturing share (2014) distribution:\n")
exp_dist <- panel[year == 2014]
cat("  Mean:", round(mean(exp_dist$manuf_share_2014, na.rm = TRUE), 3), "\n")
cat("  Median:", round(median(exp_dist$manuf_share_2014, na.rm = TRUE), 3), "\n")
cat("  SD:", round(sd(exp_dist$manuf_share_2014, na.rm = TRUE), 3), "\n")
cat("  P10:", round(quantile(exp_dist$manuf_share_2014, 0.10, na.rm = TRUE), 3), "\n")
cat("  P25:", round(quantile(exp_dist$manuf_share_2014, 0.25, na.rm = TRUE), 3), "\n")
cat("  P75:", round(quantile(exp_dist$manuf_share_2014, 0.75, na.rm = TRUE), 3), "\n")
cat("  P90:", round(quantile(exp_dist$manuf_share_2014, 0.90, na.rm = TRUE), 3), "\n")

cat("\nHigh-manufacturing municipalities (>30%):", sum(exp_dist$high_manuf == 1), "\n")
cat("Low-manufacturing municipalities (<=30%):", sum(exp_dist$high_manuf == 0), "\n")

## ---- Save analysis panel ----
fwrite(panel, "../data/analysis_panel.csv")
cat("\nSaved: data/analysis_panel.csv (", nrow(panel), " rows)\n")
cat("=== Panel construction complete ===\n")
