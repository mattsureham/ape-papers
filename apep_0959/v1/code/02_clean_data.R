## 02_clean_data.R — Construct analysis panel
## Creates facility-survey panel from Health Deficiencies + Provider Info

source("00_packages.R")

provider <- readRDS("../data/provider.rds")
deficiencies <- readRDS("../data/deficiencies.rds")
mandate_info <- fread("../data/mandate_info.csv")

# ================================================================
# A. Aggregate deficiencies to facility-survey level
# ================================================================
cat("=== Aggregating deficiencies to facility-survey level ===\n")

# Parse survey dates
deficiencies[, survey_date := as.Date(Survey.Date)]
deficiencies[, survey_year := year(survey_date)]
deficiencies[, survey_quarter := quarter(survey_date)]
deficiencies[, survey_yq := paste0(survey_year, "Q", survey_quarter)]

# Rename CCN column
setnames(deficiencies, "CMS.Certification.Number..CCN.", "ccn", skip_absent = TRUE)

# Aggregate: count deficiencies per facility per survey
survey_panel <- deficiencies[, .(
  n_deficiencies = .N,
  n_standard = sum(Standard.Deficiency == "Y", na.rm = TRUE),
  n_complaint = sum(Complaint.Deficiency == "Y", na.rm = TRUE),
  n_infection = sum(Infection.Control.Inspection.Deficiency == "Y", na.rm = TRUE),
  # Severity: map scope/severity codes to numeric
  # A-C = least severe (1-3), D-F = moderate (4-6), G-I = severe (7-9), J-L = most severe (10-12)
  max_severity = max(match(substr(Scope.Severity.Code, 1, 1),
                           c("A","B","C","D","E","F","G","H","I","J","K","L")), na.rm = TRUE),
  mean_severity = mean(match(substr(Scope.Severity.Code, 1, 1),
                             c("A","B","C","D","E","F","G","H","I","J","K","L")), na.rm = TRUE),
  has_severe = as.integer(any(Scope.Severity.Code %in% c("G","H","I","J","K","L")))
), by = .(ccn, survey_date, survey_year, survey_quarter, survey_yq)]

cat(sprintf("Survey panel: %d facility-survey observations\n", nrow(survey_panel)))
cat(sprintf("Unique facilities: %d\n", uniqueN(survey_panel$ccn)))
cat(sprintf("Year range: %d-%d\n", min(survey_panel$survey_year), max(survey_panel$survey_year)))

# ================================================================
# B. Merge facility characteristics from Provider Info
# ================================================================
cat("\n=== Merging facility characteristics ===\n")

# Extract key provider info columns
setnames(provider, "CMS.Certification.Number..CCN.", "ccn", skip_absent = TRUE)

prov_chars <- provider[, .(
  ccn,
  state = State,
  county = County.Parish,
  urban = as.integer(Urban == "Y"),
  ownership = Ownership.Type,
  beds = as.numeric(Number.of.Certified.Beds),
  avg_residents = as.numeric(Average.Number.of.Residents.per.Day),
  chain_id = Chain.ID,
  in_chain = as.integer(Chain.ID != ""),
  # Current staffing (for first-stage analysis)
  hprd_cna = as.numeric(Reported.Nurse.Aide.Staffing.Hours.per.Resident.per.Day),
  hprd_lpn = as.numeric(Reported.LPN.Staffing.Hours.per.Resident.per.Day),
  hprd_rn = as.numeric(Reported.RN.Staffing.Hours.per.Resident.per.Day),
  hprd_total = as.numeric(Reported.Total.Nurse.Staffing.Hours.per.Resident.per.Day),
  hprd_licensed = as.numeric(Reported.Licensed.Staffing.Hours.per.Resident.per.Day),
  hprd_weekend = as.numeric(Total.number.of.nurse.staff.hours.per.resident.per.day.on.the.weekend),
  hprd_rn_weekend = as.numeric(Registered.Nurse.hours.per.resident.per.day.on.the.weekend),
  # Adjusted (case-mix) staffing
  adj_hprd_cna = as.numeric(Adjusted.Nurse.Aide.Staffing.Hours.per.Resident.per.Day),
  adj_hprd_rn = as.numeric(Adjusted.RN.Staffing.Hours.per.Resident.per.Day),
  adj_hprd_total = as.numeric(Adjusted.Total.Nurse.Staffing.Hours.per.Resident.per.Day),
  # Ratings
  staffing_rating = as.numeric(Staffing.Rating),
  overall_rating = as.numeric(Overall.Rating),
  health_rating = as.numeric(Health.Inspection.Rating),
  qm_rating = as.numeric(QM.Rating),
  # Turnover
  rn_turnover = as.numeric(Registered.Nurse.turnover),
  total_turnover = as.numeric(Total.nursing.staff.turnover)
)]

# Merge provider characteristics onto survey panel
panel <- merge(survey_panel, prov_chars, by = "ccn", all.x = TRUE)

cat(sprintf("After merge: %d obs (%.1f%% matched)\n",
            nrow(panel), 100 * mean(!is.na(panel$state))))

# Drop observations without state info (can't assign treatment)
panel <- panel[!is.na(state)]

# ================================================================
# C. Assign treatment status
# ================================================================
cat("\n=== Assigning treatment status ===\n")

# Create mandate status variables
mandate_lookup <- mandate_info[, .(state, mandate_year)]

panel <- merge(panel, mandate_lookup, by = "state", all.x = TRUE)

# Treatment status at time of survey
panel[, treated := as.integer(!is.na(mandate_year) & survey_year >= mandate_year)]

# Cohort assignment for Callaway-Sant'Anna
# Only states treated during data period (2017+)
panel[, cohort := fifelse(!is.na(mandate_year) & mandate_year >= 2017,
                          mandate_year, 0L)]

# Treatment categories
panel[, treatment_group := fcase(
  is.na(mandate_year), "never_treated",
  mandate_year < 2017, "always_treated",
  mandate_year >= 2017, paste0("treated_", mandate_year)
)]

# For main analysis: exclude always-treated states (they lack a pre-period)
panel_did <- panel[treatment_group != "always_treated"]

cat(sprintf("DiD panel (excl. always-treated): %d obs, %d facilities\n",
            nrow(panel_did), uniqueN(panel_did$ccn)))

# Treatment group sizes
cat("\nTreatment group sizes:\n")
print(panel_did[, .(n_obs = .N, n_fac = uniqueN(ccn)), by = treatment_group])

# ================================================================
# D. Create analysis variables
# ================================================================
cat("\n=== Creating analysis variables ===\n")

# Ownership categories
panel_did[, own_cat := fcase(
  grepl("For profit", ownership, ignore.case = TRUE), "for_profit",
  grepl("Non profit", ownership, ignore.case = TRUE), "nonprofit",
  grepl("Government", ownership, ignore.case = TRUE), "government",
  default = "other"
)]

# Size categories
panel_did[, size_cat := fcase(
  beds <= 60, "small",
  beds <= 120, "medium",
  beds > 120, "large",
  default = "unknown"
)]

# Log deficiencies (for percent interpretation)
panel_did[, log_def := log(n_deficiencies + 1)]
panel_did[, log_std_def := log(n_standard + 1)]

# Year-quarter numeric for event study
panel_did[, yq_num := survey_year + (survey_quarter - 1) / 4]

# ================================================================
# E. Summary statistics
# ================================================================
cat("\n=== Summary Statistics ===\n")

cat("\nDeficiency panel coverage by year:\n")
print(panel_did[, .(n_surveys = .N, n_fac = uniqueN(ccn),
                     mean_def = round(mean(n_deficiencies), 1),
                     mean_severe = round(mean(has_severe), 3)),
                by = survey_year][order(survey_year)])

cat("\nStaffing levels (cross-sectional) by treatment group:\n")
staffing_summary <- panel_did[, .(
  mean_hprd = round(mean(hprd_total, na.rm = TRUE), 2),
  mean_rn = round(mean(hprd_rn, na.rm = TRUE), 2),
  mean_cna = round(mean(hprd_cna, na.rm = TRUE), 2),
  n_fac = uniqueN(ccn)
), by = .(mandate = !is.na(mandate_year))]
print(staffing_summary)

# ================================================================
# F. Save analysis datasets
# ================================================================
saveRDS(panel, "../data/full_panel.rds")
saveRDS(panel_did, "../data/panel_did.rds")

cat("\n=== Panel construction complete ===\n")
cat(sprintf("Full panel: %d obs\n", nrow(panel)))
cat(sprintf("DiD panel: %d obs, %d facilities, %d states\n",
            nrow(panel_did), uniqueN(panel_did$ccn), uniqueN(panel_did$state)))
