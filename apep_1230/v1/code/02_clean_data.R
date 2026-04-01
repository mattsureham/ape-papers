## 02_clean_data.R — Construct analysis datasets
## Key tasks:
##   1. Parse enrollment dates from PECOS enrollment IDs
##   2. Classify ownership type (for-profit vs nonprofit)
##   3. Build state × quarter panel of new enrollments
##   4. Pivot quality data to provider-level cross-section

source("00_packages.R")

data_dir <- "../data"
enroll <- readRDS(file.path(data_dir, "hospice_enrollments.rds"))
quality <- readRDS(file.path(data_dir, "hospice_quality.rds"))
owners <- readRDS(file.path(data_dir, "hospice_owners.rds"))

# ============================================================
# 1. Parse Enrollment Data
# Enrollment ID format: O + YYYYMMDD + NNNNNN (PECOS enrollment date)
# ============================================================

cat("Parsing enrollment dates...\n")

enroll[, enrollment_date_str := substr(`ENROLLMENT ID`, 2, 9)]
enroll[, enrollment_date := as.Date(enrollment_date_str, format = "%Y%m%d")]

# Validate: dates should be between 2000 and 2026
valid_dates <- enroll[!is.na(enrollment_date) &
                        enrollment_date >= as.Date("2000-01-01") &
                        enrollment_date <= as.Date("2026-01-31")]
cat(sprintf("Valid enrollment dates: %d / %d (%.1f%%)\n",
            nrow(valid_dates), nrow(enroll), 100 * nrow(valid_dates) / nrow(enroll)))

# Use ENROLLMENT STATE as the state (where the hospice operates)
valid_dates[, state := `ENROLLMENT STATE`]

# Ownership: P = proprietary (for-profit), N = nonprofit
# Some rows have garbled PROPRIETARY_NONPROFIT field
valid_dates[, for_profit := fifelse(PROPRIETARY_NONPROFIT == "P", 1L,
                                    fifelse(PROPRIETARY_NONPROFIT == "N", 0L, NA_integer_))]

cat("Ownership distribution:\n")
print(table(valid_dates$PROPRIETARY_NONPROFIT, useNA = "ifany"))

# Create quarter variable
valid_dates[, year := year(enrollment_date)]
valid_dates[, qtr := quarter(enrollment_date)]
valid_dates[, year_qtr := year + (qtr - 1) / 4]

# ============================================================
# 2. Treatment Assignment
# PPEO states: AZ, CA, NV, TX — treatment starts Q3 2023 (July 2023)
# ============================================================

ppeo_states <- c("AZ", "CA", "NV", "TX")
ppeo_start_yq <- 2023 + (3 - 1) / 4  # 2023.5

valid_dates[, treated_state := fifelse(state %in% ppeo_states, 1L, 0L)]
valid_dates[, post := fifelse(year_qtr >= ppeo_start_yq, 1L, 0L)]

# ============================================================
# 3. State × Quarter Panel of New Enrollments
# ============================================================

cat("Building state × quarter panel...\n")

# Create complete grid of all states × all quarters (2017 Q1 to 2025 Q4)
all_states <- unique(valid_dates$state)
all_states <- all_states[nchar(all_states) == 2]  # only valid 2-letter state codes

quarters_grid <- CJ(
  state = all_states,
  year = 2017:2025,
  qtr = 1:4
)
quarters_grid[, year_qtr := year + (qtr - 1) / 4]

# Count new enrollments per state × quarter
enrollment_counts <- valid_dates[year >= 2017 & year <= 2025 & nchar(state) == 2,
                                  .(new_enrollments = .N,
                                    new_fp = sum(for_profit == 1, na.rm = TRUE),
                                    new_np = sum(for_profit == 0, na.rm = TRUE)),
                                  by = .(state, year, qtr)]

# Merge onto complete grid (zeros where no enrollments)
panel <- merge(quarters_grid, enrollment_counts, by = c("state", "year", "qtr"), all.x = TRUE)
panel[is.na(new_enrollments), new_enrollments := 0L]
panel[is.na(new_fp), new_fp := 0L]
panel[is.na(new_np), new_np := 0L]

# For-profit share (avoid division by zero)
panel[, fp_share := fifelse(new_enrollments > 0, new_fp / new_enrollments, NA_real_)]

# Treatment variables
panel[, treated_state := fifelse(state %in% ppeo_states, 1L, 0L)]
panel[, post := fifelse(year_qtr >= ppeo_start_yq, 1L, 0L)]
panel[, did := treated_state * post]

# Time relative to treatment (in quarters)
panel[, rel_qtr := as.integer(round((year_qtr - ppeo_start_yq) * 4))]

# CA moratorium indicator (Jan 2022 = 2022 Q1)
ca_moratorium_yq <- 2022.0
panel[, ca_moratorium := fifelse(state == "CA" & year_qtr >= ca_moratorium_yq, 1L, 0L)]

cat(sprintf("Panel dimensions: %d rows × %d cols\n", nrow(panel), ncol(panel)))
cat(sprintf("States: %d | Quarters: %d\n",
            length(unique(panel$state)), length(unique(panel$year_qtr))))

# Summary stats
cat("\n--- Pre-period summary (2017-Q1 to 2023-Q2) ---\n")
pre <- panel[year_qtr < ppeo_start_yq]
cat(sprintf("Treated states avg new enrollments/qtr: %.1f\n",
            mean(pre[treated_state == 1]$new_enrollments)))
cat(sprintf("Control states avg new enrollments/qtr: %.1f\n",
            mean(pre[treated_state == 0]$new_enrollments)))

# ============================================================
# 4. Quality Cross-Section (Provider-Level)
# Pivot quality data from long to wide: one row per provider
# ============================================================

cat("\nBuilding quality cross-section...\n")

# Key measures to extract
key_measures <- c(
  "H_012_00_OBSERVED",   # HCI Overall Score
  "H_012_07_OBSERVED",   # Per-beneficiary spending
  "H_012_10_OBSERVED",   # Visits near death (% decedents)
  "H_012_03_OBSERVED",   # Early live discharges (%)
  "H_011_01_OBSERVED",   # Hospice Visits in Last Days of Life
  "H_001_01_DENOMINATOR", # Total beneficiaries (denominator)
  "Average_Daily_Census"  # Average daily census
)

quality_wide <- quality[`Measure Code` %in% key_measures,
                         .(`Measure Code`, Score,
                           ccn = `CMS Certification Number (CCN)`,
                           state = State)]

quality_wide[, Score := as.numeric(Score)]

# Pivot wider
quality_pivot <- dcast(quality_wide, ccn + state ~ `Measure Code`,
                        value.var = "Score", fun.aggregate = mean, na.rm = TRUE)

# Rename columns
setnames(quality_pivot, old = c("H_012_00_OBSERVED", "H_012_07_OBSERVED",
                                 "H_012_10_OBSERVED", "H_012_03_OBSERVED",
                                 "H_011_01_OBSERVED", "H_001_01_DENOMINATOR",
                                 "Average_Daily_Census"),
         new = c("hci_score", "per_bene_spending", "visits_near_death",
                 "early_discharges", "visits_last_days", "total_bene",
                 "avg_daily_census"),
         skip_absent = TRUE)

quality_pivot[, treated_state := fifelse(state %in% ppeo_states, 1L, 0L)]

cat(sprintf("Quality cross-section: %d providers\n", nrow(quality_pivot)))
cat(sprintf("  Treated state providers: %d\n", sum(quality_pivot$treated_state == 1)))
cat(sprintf("  Control state providers: %d\n", sum(quality_pivot$treated_state == 0)))

# ============================================================
# 5. State-Level Quality Aggregates
# ============================================================

state_quality <- quality_pivot[, .(
  mean_hci = mean(hci_score, na.rm = TRUE),
  mean_spending = mean(per_bene_spending, na.rm = TRUE),
  mean_visits_death = mean(visits_near_death, na.rm = TRUE),
  mean_early_discharge = mean(early_discharges, na.rm = TRUE),
  n_hospices = .N,
  total_bene = sum(total_bene, na.rm = TRUE)
), by = .(state, treated_state)]

cat("\n--- State-level quality means ---\n")
cat("Treated states:\n")
print(state_quality[treated_state == 1, .(state, n_hospices, mean_hci,
                                           mean_spending, mean_visits_death)])
cat("Control states (sample):\n")
print(head(state_quality[treated_state == 0, .(state, n_hospices, mean_hci,
                                                mean_spending, mean_visits_death)], 10))

# ============================================================
# 6. Save analysis datasets
# ============================================================

saveRDS(panel, file.path(data_dir, "state_quarter_panel.rds"))
saveRDS(quality_pivot, file.path(data_dir, "quality_cross_section.rds"))
saveRDS(state_quality, file.path(data_dir, "state_quality.rds"))
saveRDS(valid_dates, file.path(data_dir, "enrollments_clean.rds"))

cat("\n=== Cleaning complete ===\n")
cat(sprintf("  State × quarter panel: %d rows\n", nrow(panel)))
cat(sprintf("  Quality cross-section: %d providers\n", nrow(quality_pivot)))
