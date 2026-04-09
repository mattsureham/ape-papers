# 02_clean_data.R — Variable construction for apep_1442
# Planning Inspector Leniency and Housing Supply

source("00_packages.R")

# =============================================================================
# Load PINS cases
# =============================================================================

cases <- fread("../data/pins_cases_raw.csv")
cat(sprintf("Loaded %d PINS cases.\n", nrow(cases)))

# Parse dates
cases[, decision_date_parsed := as.Date(decision_date, format = "%d %b %Y")]
cases[, start_date_parsed := as.Date(start_date, format = "%d %b %Y")]
cases[, decision_year := year(decision_date_parsed)]
cases[, decision_quarter := quarter(decision_date_parsed)]
cases[, decision_yq := paste0(decision_year, "Q", decision_quarter)]

# Binary outcome: allowed = 1
cases[, allowed := as.integer(outcome == "Allowed")]

# Standardize case types
cases[, case_type_clean := fcase(
  grepl("Householder", case_type, ignore.case = TRUE), "Householder",
  grepl("Planning Appeal", case_type, ignore.case = TRUE), "Planning",
  grepl("Enforcement", case_type, ignore.case = TRUE), "Enforcement",
  grepl("Lawful Development", case_type, ignore.case = TRUE), "LDC",
  grepl("Commercial", case_type, ignore.case = TRUE), "Commercial",
  default = "Other"
)]

# Standardize LPA names (trim whitespace, consistent case)
cases[, lpa_clean := trimws(lpa)]

# Keep only decided cases with known outcome
cases <- cases[outcome %in% c("Allowed", "Dismissed")]
cat(sprintf("After keeping Allowed/Dismissed only: %d cases\n", nrow(cases)))

# Keep only cases with inspector names
cases_with_insp <- cases[!is.na(inspector) & inspector != ""]
cat(sprintf("Cases with inspector names: %d\n", nrow(cases_with_insp)))

# =============================================================================
# Construct Inspector Leniency Scores (Leave-One-Out)
# =============================================================================

cat("\n=== Constructing leniency scores ===\n")

# Cell: case_type_clean × decision_year
cases_with_insp[, cell := paste(case_type_clean, decision_year, sep = "_")]

# Inspector case counts
insp_counts <- cases_with_insp[, .N, by = inspector]
cat(sprintf("Inspector distribution: median %d cases, mean %.1f, range %d-%d\n",
            median(insp_counts$N), mean(insp_counts$N),
            min(insp_counts$N), max(insp_counts$N)))

# Drop inspectors with fewer than 3 cases (need some variation for LOO)
keep_inspectors <- insp_counts[N >= 3, inspector]
cases_with_insp <- cases_with_insp[inspector %in% keep_inspectors]
cat(sprintf("Inspectors with >=3 cases: %d (covering %d cases)\n",
            length(keep_inspectors), nrow(cases_with_insp)))

# Leave-one-out leniency within cells
cases_with_insp[, insp_cell_total := sum(allowed), by = .(inspector, cell)]
cases_with_insp[, insp_cell_n := .N, by = .(inspector, cell)]
cases_with_insp[, leniency_raw := (insp_cell_total - allowed) / (insp_cell_n - 1)]

# Handle cells where inspector has only 1 case: use overall inspector rate (LOO)
cases_with_insp[, insp_total_allowed := sum(allowed), by = inspector]
cases_with_insp[, insp_total_n := .N, by = inspector]
cases_with_insp[insp_cell_n == 1,
                leniency_raw := (insp_total_allowed - allowed) / (insp_total_n - 1)]

# Standardize leniency within cells (mean 0, sd 1)
cases_with_insp[, leniency := (leniency_raw - mean(leniency_raw, na.rm = TRUE)) /
                  sd(leniency_raw, na.rm = TRUE), by = cell]

# Replace any remaining NAs
cases_with_insp <- cases_with_insp[!is.na(leniency)]
cat(sprintf("Final analysis sample: %d cases\n", nrow(cases_with_insp)))

# =============================================================================
# Create LPA-Quarter Panel
# =============================================================================

cat("\n=== Creating LPA-quarter panel ===\n")

lpa_qtr <- cases_with_insp[, .(
  n_appeals = .N,
  n_allowed = sum(allowed),
  allow_rate = mean(allowed),
  avg_leniency = mean(leniency),
  n_inspectors = uniqueN(inspector)
), by = .(lpa_clean, decision_year, decision_quarter, decision_yq)]

cat(sprintf("LPA-quarter panel: %d observations, %d LPAs, %d quarters\n",
            nrow(lpa_qtr), uniqueN(lpa_qtr$lpa_clean),
            uniqueN(lpa_qtr$decision_yq)))

# =============================================================================
# Merge Land Registry data (if available)
# =============================================================================

if (file.exists("../data/land_registry_ppd.csv")) {
  cat("\n=== Processing Land Registry data ===\n")
  lr <- fread("../data/land_registry_ppd.csv")

  # Parse dates and extract district
  lr[, date_parsed := as.Date(date)]
  lr[, yr := year(date_parsed)]
  lr[, qtr := quarter(date_parsed)]
  lr[, yq := paste0(yr, "Q", qtr)]

  # Cast price to numeric to avoid type inconsistency
  lr[, price := as.double(price)]

  # Aggregate to district-quarter: median price, transaction count, new build count
  lr_panel <- lr[, .(
    median_price = as.double(median(price, na.rm = TRUE)),
    mean_price = as.double(mean(price, na.rm = TRUE)),
    n_transactions = .N,
    n_new_build = sum(new_build == "Y", na.rm = TRUE),
    share_new_build = mean(new_build == "Y", na.rm = TRUE)
  ), by = .(district, yr, qtr, yq)]

  fwrite(lr_panel, "../data/lr_district_panel.csv")
  cat(sprintf("Land Registry panel: %d district-quarters\n", nrow(lr_panel)))

  # Attempt merge with LPA panel (district names may not perfectly match LPA names)
  # We'll do fuzzy matching in analysis
} else {
  cat("No Land Registry data available.\n")
}

# =============================================================================
# Save analysis datasets
# =============================================================================

fwrite(cases_with_insp, "../data/pins_analysis.csv")
fwrite(lpa_qtr, "../data/lpa_quarter_panel.csv")

cat("\n=== CLEANING COMPLETE ===\n")
cat(sprintf("Case-level dataset: %d obs\n", nrow(cases_with_insp)))
cat(sprintf("LPA-quarter panel: %d obs\n", nrow(lpa_qtr)))
cat(sprintf("Unique inspectors: %d\n", uniqueN(cases_with_insp$inspector)))
cat(sprintf("Unique LPAs: %d\n", uniqueN(cases_with_insp$lpa_clean)))
cat(sprintf("Allow rate: %.1f%%\n", 100 * mean(cases_with_insp$allowed)))
cat(sprintf("Leniency SD (raw): %.3f\n", sd(cases_with_insp$leniency_raw, na.rm = TRUE)))
