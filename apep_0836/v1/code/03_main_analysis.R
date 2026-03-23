# 03_main_analysis.R — Main regression analysis
# Japan Heisei Municipal Merger Fiscal Cliff (apep_0836)

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "panel_clean.rds"))

cat("=== Panel Summary ===\n")
cat(sprintf("Observations: %d\n", nrow(panel)))
cat(sprintf("Municipalities: %d (merged: %d, never-merged: %d)\n",
            uniqueN(panel$muni_code),
            uniqueN(panel$muni_code[panel$merged == TRUE]),
            uniqueN(panel$muni_code[panel$never_merged == TRUE])))

# ============================================================
# 1. Treatment variables
# ============================================================

# Binary treatment: post-phase-out-start indicator
panel[, post_phaseout := fifelse(merged == TRUE & event_time >= 0, 1L, 0L)]

# Continuous treatment: cumulative phase-out percentage
panel[, phaseout_intensity := fifelse(merged == TRUE, phaseout_pct / 100, 0)]

# Cohort variable for staggered DiD (year phase-out starts)
panel[, cohort := fifelse(merged == TRUE, phaseout_start_fy, Inf)]

# Log outcomes (add small constant for zeros)
panel[, log_sfd_pc := log(sfd_pc + 1)]
panel[, log_sfr_pc := log(sfr_pc + 1)]
panel[, log_lat_pc := log(lat_pc + 1)]
panel[, log_std_scale_pc := log(std_scale_pc + 1)]

# ============================================================
# 2. Main specification: TWFE event study (Sun & Abraham 2021)
# ============================================================
cat("\n=== Main Event Study: SFD per capita (log) ===\n")

# Trim event time for clean estimation window
panel[, event_time_trim := fcase(
  is.na(event_time), NA_integer_,
  event_time < -5, -5L,
  event_time > 8, 8L,
  default = as.integer(event_time)
)]

# Sun & Abraham interaction-weighted estimator via fixest
# Reference period: event_time = -1 (last pre-treatment year)
est_sfd <- feols(
  log_sfd_pc ~ sunab(cohort, fiscal_year) | muni_code + fiscal_year,
  data = panel[!is.na(event_time_trim) | never_merged == TRUE],
  cluster = ~muni_code
)
cat("SFD event study:\n")
summary(est_sfd)

# ============================================================
# 3. Main specification: LAT per capita (implied)
# ============================================================
cat("\n=== Main Event Study: LAT per capita (log) ===\n")

est_lat <- feols(
  log_lat_pc ~ sunab(cohort, fiscal_year) | muni_code + fiscal_year,
  data = panel[!is.na(event_time_trim) | never_merged == TRUE],
  cluster = ~muni_code
)
cat("LAT event study:\n")
summary(est_lat)

# ============================================================
# 4. Standard fiscal revenue (own-source proxy)
# ============================================================
cat("\n=== Main Event Study: SFR per capita (log) ===\n")

est_sfr <- feols(
  log_sfr_pc ~ sunab(cohort, fiscal_year) | muni_code + fiscal_year,
  data = panel[!is.na(event_time_trim) | never_merged == TRUE],
  cluster = ~muni_code
)
cat("SFR event study:\n")
summary(est_sfr)

# ============================================================
# 5. Balance ratio
# ============================================================
cat("\n=== Main Event Study: Balance Ratio ===\n")

est_balance <- feols(
  balance_ratio ~ sunab(cohort, fiscal_year) | muni_code + fiscal_year,
  data = panel[!is.na(event_time_trim) | never_merged == TRUE],
  cluster = ~muni_code
)
cat("Balance ratio event study:\n")
summary(est_balance)

# ============================================================
# 6. Simple DiD (binary treatment, pre/post)
# ============================================================
cat("\n=== Simple DiD: Binary Treatment ===\n")

did_sfd <- feols(
  log_sfd_pc ~ post_phaseout | muni_code + fiscal_year,
  data = panel,
  cluster = ~muni_code
)

did_lat <- feols(
  log_lat_pc ~ post_phaseout | muni_code + fiscal_year,
  data = panel,
  cluster = ~muni_code
)

did_sfr <- feols(
  log_sfr_pc ~ post_phaseout | muni_code + fiscal_year,
  data = panel,
  cluster = ~muni_code
)

did_balance <- feols(
  balance_ratio ~ post_phaseout | muni_code + fiscal_year,
  data = panel,
  cluster = ~muni_code
)

cat("\nSimple DiD results:\n")
etable(did_sfd, did_lat, did_sfr, did_balance,
       headers = c("Log SFD/cap", "Log LAT/cap", "Log SFR/cap", "Balance Ratio"))

# ============================================================
# 7. Dose-response: Continuous phaseout intensity
# ============================================================
cat("\n=== Dose-Response: Phase-out Intensity ===\n")

dose_sfd <- feols(
  log_sfd_pc ~ phaseout_intensity | muni_code + fiscal_year,
  data = panel,
  cluster = ~muni_code
)

dose_lat <- feols(
  log_lat_pc ~ phaseout_intensity | muni_code + fiscal_year,
  data = panel,
  cluster = ~muni_code
)

dose_sfr <- feols(
  log_sfr_pc ~ phaseout_intensity | muni_code + fiscal_year,
  data = panel,
  cluster = ~muni_code
)

cat("\nDose-response results:\n")
etable(dose_sfd, dose_lat, dose_sfr,
       headers = c("Log SFD/cap", "Log LAT/cap", "Log SFR/cap"))

# ============================================================
# 8. Save results and diagnostics
# ============================================================

# Save all model objects
saveRDS(list(
  est_sfd = est_sfd, est_lat = est_lat, est_sfr = est_sfr, est_balance = est_balance,
  did_sfd = did_sfd, did_lat = did_lat, did_sfr = did_sfr, did_balance = did_balance,
  dose_sfd = dose_sfd, dose_lat = dose_lat, dose_sfr = dose_sfr
), file.path(data_dir, "models.rds"))

# Write diagnostics.json for validator
diagnostics <- list(
  n_treated = uniqueN(panel$muni_code[panel$merged == TRUE]),
  n_pre = length(unique(panel$event_time[panel$event_time < 0 & !is.na(panel$event_time)])),
  n_obs = nrow(panel),
  n_controls = uniqueN(panel$muni_code[panel$never_merged == TRUE]),
  fy_range = paste(range(panel$fiscal_year), collapse = "-"),
  cohort_range = paste(range(panel$phaseout_start_fy[panel$merged == TRUE], na.rm = TRUE), collapse = "-")
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== Analysis complete. Models and diagnostics saved. ===\n")
