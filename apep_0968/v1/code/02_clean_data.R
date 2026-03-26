# ==============================================================================
# 02_clean_data.R — Construct analysis panel
# Paper: The Recertification Ripple (apep_0968)
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"

# =============================================================================
# 1. Clean CMS Medicaid Enrollment
# =============================================================================

cat("Cleaning CMS enrollment data...\n")
cms_raw <- readRDS(file.path(data_dir, "cms_enrollment_raw.rds"))

cms <- cms_raw %>%
  transmute(
    state_abbr = State.Abbreviation,
    reporting_period = as.character(Reporting.Period),
    # Parse YYYYMM format
    year = as.integer(substr(reporting_period, 1, 4)),
    month = as.integer(substr(reporting_period, 5, 6)),
    medicaid_enrollment = as.numeric(gsub(",", "", Total.Medicaid.Enrollment)),
    chip_enrollment = as.numeric(gsub(",", "", Total.CHIP.Enrollment)),
    total_enrollment = as.numeric(gsub(",", "", Total.Medicaid.and.CHIP.Enrollment)),
    child_enrollment = as.numeric(gsub(",", "", Medicaid.and.CHIP.Child.Enrollment)),
    adult_enrollment = as.numeric(gsub(",", "", Total.Adult.Medicaid.Enrollment)),
    new_applications = as.numeric(gsub(",", "", New.Applications.Submitted.to.Medicaid.and.CHIP.Agencies)),
    determinations = as.numeric(gsub(",", "", Total.Medicaid.and.CHIP.Determinations)),
    expanded_medicaid = State.Expanded.Medicaid,
    final_report = Final.Report
  ) %>%
  # Keep only US states + DC (exclude territories)
  filter(state_abbr %in% c(state.abb, "DC")) %>%
  # Keep 2018-2022 (SNAP Policy DB overlap + post-COVID)
  filter(year >= 2018 & year <= 2022) %>%
  # Remove rows with missing enrollment
  filter(!is.na(medicaid_enrollment) & medicaid_enrollment > 0) %>%
  # CRITICAL: Deduplicate — CMS publishes preliminary AND updated reports
  # Keep the most recent (final or updated) per state-month
  group_by(state_abbr, year, month) %>%
  arrange(desc(final_report == "Y"), desc(reporting_period)) %>%
  slice(1) %>%
  ungroup() %>%
  arrange(state_abbr, year, month)

cat(sprintf("CMS cleaned: %d state-month obs, %d states, %s to %s\n",
            nrow(cms), n_distinct(cms$state_abbr),
            paste0(min(cms$year), "-", sprintf("%02d", min(cms$month[cms$year == min(cms$year)]))),
            paste0(max(cms$year), "-", sprintf("%02d", max(cms$month[cms$year == max(cms$year)])))))

# Compute enrollment volatility measures
cms <- cms %>%
  group_by(state_abbr) %>%
  arrange(year, month) %>%
  mutate(
    # Month-over-month absolute change
    delta_enrollment = medicaid_enrollment - lag(medicaid_enrollment),
    # Month-over-month percent change
    pct_change = delta_enrollment / lag(medicaid_enrollment) * 100,
    # Absolute percent change (for volatility)
    abs_pct_change = abs(pct_change),
    # Year-month identifier for FE
    ym = year * 100 + month,
    ym_date = as.Date(paste(year, month, "01", sep = "-"))
  ) %>%
  ungroup()

# Rolling CV (12-month window) - measure of sustained volatility
cms <- cms %>%
  group_by(state_abbr) %>%
  arrange(ym_date) %>%
  mutate(
    roll_mean_12 = zoo::rollmean(medicaid_enrollment, k = 12, fill = NA, align = "right"),
    roll_sd_12 = zoo::rollapply(medicaid_enrollment, width = 12, FUN = sd, fill = NA, align = "right"),
    roll_cv_12 = roll_sd_12 / roll_mean_12
  ) %>%
  ungroup()

cat(sprintf("Enrollment volatility: mean abs pct change = %.3f%%, mean rolling CV = %.4f\n",
            mean(cms$abs_pct_change, na.rm = TRUE),
            mean(cms$roll_cv_12, na.rm = TRUE)))

# =============================================================================
# 2. Clean SNAP Policy Database
# =============================================================================

cat("\nCleaning SNAP Policy Database...\n")
snap_raw <- readRDS(file.path(data_dir, "snap_policy_raw.rds"))

# Key recertification variables:
# certearn0103: share of earning HHs with 1-3 month cert period
# certearn0406: share with 4-6 month cert period
# certearn0712: share with 7-12 month cert period
# certearn1399: share with 13+ month cert period
# certearnavg: average cert period for earners (months)
# certearnmed: median cert period for earners

snap <- snap_raw %>%
  mutate(
    yearmonth = as.integer(yearmonth),
    year = yearmonth %/% 100,
    month = yearmonth %% 100,
    state_abbr = state_pc  # 2-letter state code
  ) %>%
  filter(year >= 2018 & year <= 2020) %>%  # SNAP DB ends Dec 2020
  select(
    state_abbr, year, month, yearmonth,
    # Recertification intensity measures
    certearn0103,   # Share on 1-3 month cert (highest admin intensity)
    certearn0406,   # Share on 4-6 month cert
    certearn0712,   # Share on 7-12 month cert
    certearn1399,   # Share on 13+ month cert
    certearnavg,    # Average cert period (months)
    certearnmed,    # Median cert period
    # Other policy controls
    bbce,           # Broad-based categorical eligibility
    cap,            # Combined Application Project (SNAP-SSI)
    call_any,       # Call center reporting
    simplified_rpt  = matches("^simplerpt")
  )

# Convert to numeric where needed
snap <- snap %>%
  mutate(across(c(certearn0103, certearn0406, certearn0712, certearn1399,
                  certearnavg, certearnmed), as.numeric))

# Create our key treatment variable: short-cycle recertification intensity
# = share of earning HHs on ≤6 month certification periods
snap <- snap %>%
  mutate(
    short_cert_share = certearn0103 + certearn0406,  # Share on 1-6 month cycles
    recert_intensity = short_cert_share  # Primary treatment variable
  )

cat(sprintf("SNAP cleaned: %d state-month obs\n", nrow(snap)))
cat(sprintf("Recertification intensity (short_cert_share): mean=%.3f, sd=%.3f, range=[%.3f, %.3f]\n",
            mean(snap$recert_intensity, na.rm = TRUE),
            sd(snap$recert_intensity, na.rm = TRUE),
            min(snap$recert_intensity, na.rm = TRUE),
            max(snap$recert_intensity, na.rm = TRUE)))

# =============================================================================
# 3. Merge IES Classification
# =============================================================================

cat("\nMerging IES classification...\n")
ies <- readRDS(file.path(data_dir, "ies_classification.rds"))

# =============================================================================
# 4. Merge Unemployment Controls
# =============================================================================

cat("Merging unemployment data...\n")
unemp <- readRDS(file.path(data_dir, "bls_unemployment.rds"))

# =============================================================================
# 5. Build Analysis Panel
# =============================================================================

cat("\nBuilding analysis panel...\n")

# Start from CMS enrollment (wider time range)
panel <- cms %>%
  # Merge IES classification
  left_join(ies %>% select(state_abbr, ies_status), by = "state_abbr") %>%
  # Merge SNAP policy (only available through Dec 2020)
  left_join(
    snap %>% select(state_abbr, year, month, recert_intensity, short_cert_share,
                    certearnavg, certearnmed, certearn0103, certearn0406),
    by = c("state_abbr", "year", "month")
  ) %>%
  # Merge unemployment
  left_join(unemp, by = c("state_abbr", "year", "month"))

# For months after SNAP DB ends (2021-2022), carry forward last known values
panel <- panel %>%
  group_by(state_abbr) %>%
  arrange(year, month) %>%
  fill(recert_intensity, short_cert_share, certearnavg, certearnmed,
       certearn0103, certearn0406, .direction = "down") %>%
  ungroup()

# Create time periods
panel <- panel %>%
  mutate(
    # Pre-COVID: Jan 2018 - Feb 2020
    # COVID waiver: Mar 2020 - Dec 2020 (blanket SNAP recert extensions)
    # Post-waiver: Jan 2021+ (waivers phasing out, unwinding begins Apr 2023)
    period = case_when(
      year < 2020 | (year == 2020 & month <= 2) ~ "pre_covid",
      year == 2020 & month >= 3 ~ "covid_waiver",
      year >= 2021 & (year < 2023 | (year == 2023 & month < 4)) ~ "post_waiver",
      TRUE ~ "unwinding"
    ),
    # Interaction: recertification intensity × IES
    recert_x_ies = recert_intensity * ies_status,
    # Create state numeric ID for fixest
    state_id = as.integer(factor(state_abbr)),
    # Year-month factor for time FE
    ym_factor = factor(ym)
  )

# Summary statistics
cat("\n=== ANALYSIS PANEL SUMMARY ===\n")
cat(sprintf("Total observations: %d\n", nrow(panel)))
cat(sprintf("States: %d (%d IES, %d non-IES)\n",
            n_distinct(panel$state_abbr),
            n_distinct(panel$state_abbr[panel$ies_status == 1]),
            n_distinct(panel$state_abbr[panel$ies_status == 0])))
cat(sprintf("Time range: %d-%02d to %d-%02d\n",
            min(panel$year), min(panel$month[panel$year == min(panel$year)]),
            max(panel$year), max(panel$month[panel$year == max(panel$year)])))
cat(sprintf("Periods: %s\n", paste(table(panel$period), collapse = ", ")))

# By IES status
panel %>%
  filter(!is.na(recert_intensity)) %>%
  group_by(ies_status) %>%
  summarise(
    n = n(),
    mean_recert = mean(recert_intensity, na.rm = TRUE),
    mean_abs_pct = mean(abs_pct_change, na.rm = TRUE),
    mean_cv = mean(roll_cv_12, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# Save analysis panel
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
cat("\nAnalysis panel saved.\n")
