## 02_clean_data.R — Construct analysis panel with detection-sensitivity taxonomy
## V2: Classify deficiency types by detection mode for mechanism architecture

source("00_packages.R")

provider <- readRDS("../data/provider.rds")
deficiencies <- readRDS("../data/deficiencies.rds")
mandate_info <- fread("../data/mandate_info.csv")

# ================================================================
# A. Detection-Sensitivity Taxonomy (V2 core innovation)
# ================================================================
cat("=== Building Detection-Sensitivity Taxonomy ===\n")

# CMS deficiency tags (F-tags) correspond to specific regulatory requirements
# They can be classified by how they are primarily DETECTED during inspections:
#
# OBSERVATION-DEPENDENT: Surveyor sees staff-resident interactions, care delivery
#   → More staff = more interactions visible = more potential violations detected
# DOCUMENTATION-DEPENDENT: Surveyor reviews care plans, charts, medication logs
#   → More staff = more documentation generated = more review surface area
# REPORT-DEPENDENT: Initiated by resident/family complaints (no surveyor observation needed)
#   → Should NOT increase with staffing (no detection channel)

# Classification based on CMS State Operations Manual inspection procedures
# The deficiency data has a "Deficiency.Tag.Number" or similar field
# Standard vs Complaint is already coded in the data

# Identify column names
def_cols <- colnames(deficiencies)
cat("Deficiency columns:\n")
cat(paste(def_cols, collapse = "\n"), "\n")

# Parse survey dates
date_cols <- grep("[Dd]ate", def_cols, value = TRUE)
cat("Date columns:", paste(date_cols, collapse = ", "), "\n")

# Standardize key columns
if ("CMS.Certification.Number..CCN." %in% def_cols) {
  setnames(deficiencies, "CMS.Certification.Number..CCN.", "ccn", skip_absent = TRUE)
} else if ("Federal.Provider.Number" %in% def_cols) {
  setnames(deficiencies, "Federal.Provider.Number", "ccn", skip_absent = TRUE)
} else {
  # Try to find CCN-like column
  ccn_col <- grep("CCN|cert|provider.*num", def_cols, ignore.case = TRUE, value = TRUE)[1]
  if (!is.na(ccn_col)) setnames(deficiencies, ccn_col, "ccn")
}

# Find survey date column
survey_date_col <- grep("[Ss]urvey.*[Dd]ate", def_cols, value = TRUE)[1]
if (is.na(survey_date_col)) survey_date_col <- date_cols[1]
if (!is.na(survey_date_col) && survey_date_col != "survey_date") {
  deficiencies[, survey_date := as.Date(get(survey_date_col))]
}
deficiencies[, survey_year := year(survey_date)]
deficiencies[, survey_quarter := quarter(survey_date)]
deficiencies[, survey_yq := paste0(survey_year, "Q", survey_quarter)]

# Find key classification columns
standard_col <- grep("[Ss]tandard.*[Dd]eficiency", def_cols, value = TRUE)[1]
complaint_col <- grep("[Cc]omplaint.*[Dd]eficiency", def_cols, value = TRUE)[1]
infection_col <- grep("[Ii]nfection.*[Cc]ontrol", def_cols, value = TRUE)[1]
severity_col <- grep("[Ss]cope.*[Ss]everity", def_cols, value = TRUE)[1]
tag_col <- grep("[Dd]eficiency.*[Tt]ag|[Tt]ag.*[Nn]umber", def_cols, value = TRUE)[1]
category_col <- grep("[Dd]eficiency.*[Cc]ategory|[Cc]ategory", def_cols, value = TRUE)
category_col <- category_col[!grepl("sub", category_col, ignore.case = TRUE)][1]

cat(sprintf("Standard: %s, Complaint: %s, Infection: %s\n",
            standard_col, complaint_col, infection_col))
cat(sprintf("Severity: %s, Tag: %s, Category: %s\n",
            severity_col, tag_col, category_col))

# Create indicator variables safely
deficiencies[, is_standard := fifelse(!is.na(get(standard_col)),
                                       get(standard_col) == "Y", FALSE)]
deficiencies[, is_complaint := fifelse(!is.na(get(complaint_col)),
                                        get(complaint_col) == "Y", FALSE)]
deficiencies[, is_infection := fifelse(!is.na(get(infection_col)),
                                        get(infection_col) == "Y", FALSE)]

# Severity coding
if (!is.na(severity_col)) {
  deficiencies[, sev_code := substr(get(severity_col), 1, 1)]
  deficiencies[, sev_numeric := match(sev_code, LETTERS[1:12])]
  # Severity groups: A-C = minimal, D-F = moderate, G-I = actual harm, J-L = jeopardy
  deficiencies[, sev_group := fcase(
    sev_numeric <= 3, "minimal",
    sev_numeric <= 6, "moderate",
    sev_numeric <= 9, "actual_harm",
    sev_numeric <= 12, "jeopardy",
    default = "unknown"
  )]
}

# V2 DETECTION-SENSITIVITY CLASSIFICATION
# Based on CMS inspection methodology (SOM Chapter 7):
# - Categories where violations are found through DIRECT OBSERVATION of care
#   delivery, staff-resident interactions, meals, activities
# - Categories where violations are found through RECORD REVIEW
# - Categories initiated by COMPLAINTS (no surveyor detection needed)

# Major CMS deficiency categories and their detection mode:
if (!is.na(category_col)) {
  cat("\nDeficiency categories in data:\n")
  cat_table <- deficiencies[, .N, by = get(category_col)][order(-N)]
  print(head(cat_table, 20))

  # Map categories to detection mode
  # Observation-heavy: Quality of Care, Nutrition, Activities, Pharmacy, Resident Rights (direct care)
  # Documentation-heavy: Administration, Assessment, Quality Assurance (record review)
  # Note: Many categories involve BOTH observation and documentation;
  # we classify by PRIMARY detection channel per SOM inspection protocol

  deficiencies[, detection_mode := fcase(
    is_complaint, "report",
    is_infection, "observation",
    grepl("[Qq]uality.*[Cc]are|[Nn]ursing|[Rr]esident.*[Rr]ight|[Aa]ctivit|[Nn]utrit|[Pp]harmac|[Pp]hysical.*[Ee]nviron",
          get(category_col), ignore.case = TRUE), "observation",
    grepl("[Aa]dmin|[Aa]ssess|[Qq]uality.*[Aa]ssur|[Dd]ischarge|[Pp]lanning",
          get(category_col), ignore.case = TRUE), "documentation",
    default = "observation"
  )]
} else {
  # Fallback: use standard/complaint classification
  deficiencies[, detection_mode := fcase(
    is_complaint, "report",
    is_infection, "observation",
    is_standard, "observation",
    default = "observation"
  )]
}

cat("\nDetection mode distribution:\n")
print(deficiencies[, .N, by = detection_mode][order(-N)])

# ================================================================
# B. Aggregate to facility-survey level with V2 taxonomy
# ================================================================
cat("\n=== Aggregating to facility-survey level ===\n")

survey_panel <- deficiencies[, .(
  # Total counts
  n_deficiencies = .N,
  n_standard = sum(is_standard),
  n_complaint = sum(is_complaint),
  n_infection = sum(is_infection),

  # V2: Detection-mode counts
  n_observation = sum(detection_mode == "observation"),
  n_documentation = sum(detection_mode == "documentation"),
  n_report = sum(detection_mode == "report"),

  # V2: Severity distribution
  n_minimal = sum(sev_group == "minimal", na.rm = TRUE),
  n_moderate = sum(sev_group == "moderate", na.rm = TRUE),
  n_actual_harm = sum(sev_group == "actual_harm", na.rm = TRUE),
  n_jeopardy = sum(sev_group == "jeopardy", na.rm = TRUE),

  # Severity summary
  max_severity = max(sev_numeric, na.rm = TRUE),
  mean_severity = mean(sev_numeric, na.rm = TRUE),
  has_severe = as.integer(any(sev_numeric >= 7, na.rm = TRUE)),

  # V2: Administrative vs clinical (low-severity vs high-severity)
  n_low_severity = sum(sev_numeric <= 6, na.rm = TRUE),
  n_high_severity = sum(sev_numeric >= 7, na.rm = TRUE)
), by = .(ccn, survey_date, survey_year, survey_quarter, survey_yq)]

cat(sprintf("Survey panel: %d facility-survey observations\n", nrow(survey_panel)))
cat(sprintf("Unique facilities: %d\n", uniqueN(survey_panel$ccn)))
cat(sprintf("Year range: %d-%d\n", min(survey_panel$survey_year), max(survey_panel$survey_year)))

# ================================================================
# C. Merge facility characteristics
# ================================================================
cat("\n=== Merging facility characteristics ===\n")

if ("CMS.Certification.Number..CCN." %in% colnames(provider)) {
  setnames(provider, "CMS.Certification.Number..CCN.", "ccn", skip_absent = TRUE)
} else {
  ccn_col <- grep("CCN|cert|provider.*num", colnames(provider), ignore.case = TRUE, value = TRUE)[1]
  if (!is.na(ccn_col)) setnames(provider, ccn_col, "ccn")
}

# Extract key provider characteristics
prov_cols <- colnames(provider)
state_col <- grep("^[Ss]tate$", prov_cols, value = TRUE)[1]
beds_col <- grep("[Cc]ertified.*[Bb]eds|[Nn]umber.*[Bb]eds", prov_cols, value = TRUE)[1]
ownership_col <- grep("[Oo]wnership", prov_cols, value = TRUE)[1]
urban_col <- grep("[Uu]rban", prov_cols, value = TRUE)[1]
chain_col <- grep("[Cc]hain.*[Ii][Dd]", prov_cols, value = TRUE)[1]
overall_rating_col <- grep("[Oo]verall.*[Rr]ating", prov_cols, value = TRUE)[1]
health_rating_col <- grep("[Hh]ealth.*[Rr]ating|[Ii]nspection.*[Rr]ating", prov_cols, value = TRUE)[1]

# Staffing columns (from PBJ)
hprd_total_col <- grep("[Rr]eported.*[Tt]otal.*[Nn]urse.*[Ss]taffing.*[Hh]ours.*[Pp]er.*[Rr]esident", prov_cols, value = TRUE)[1]
hprd_rn_col <- grep("[Rr]eported.*[Rr][Nn].*[Ss]taffing.*[Hh]ours.*[Pp]er", prov_cols, value = TRUE)[1]
hprd_cna_col <- grep("[Rr]eported.*[Nn]urse.*[Aa]ide.*[Ss]taffing", prov_cols, value = TRUE)[1]

cat(sprintf("Staffing columns: total=%s, RN=%s, CNA=%s\n",
            hprd_total_col, hprd_rn_col, hprd_cna_col))

prov_chars <- provider[, .(
  ccn = get("ccn"),
  state = get(state_col),
  beds = as.numeric(get(beds_col)),
  ownership = get(ownership_col),
  urban = as.integer(grepl("Y|[Uu]rban", get(urban_col))),
  in_chain = as.integer(get(chain_col) != "" & !is.na(get(chain_col))),
  overall_rating = as.numeric(get(overall_rating_col)),
  health_rating = as.numeric(get(health_rating_col)),
  hprd_total = as.numeric(get(hprd_total_col)),
  hprd_rn = as.numeric(get(hprd_rn_col)),
  hprd_cna = as.numeric(get(hprd_cna_col))
)]

# Merge
panel <- merge(survey_panel, prov_chars, by = "ccn", all.x = TRUE)
cat(sprintf("After merge: %d obs (%.1f%% matched)\n",
            nrow(panel), 100 * mean(!is.na(panel$state))))
panel <- panel[!is.na(state)]

# ================================================================
# D. Assign treatment status
# ================================================================
cat("\n=== Assigning treatment status ===\n")

mandate_lookup <- mandate_info[, .(state, mandate_year)]
panel <- merge(panel, mandate_lookup, by = "state", all.x = TRUE)

panel[, treated := as.integer(!is.na(mandate_year) & survey_year >= mandate_year)]
panel[, cohort := fifelse(!is.na(mandate_year) & mandate_year >= 2017,
                          mandate_year, 0L)]
panel[, treatment_group := fcase(
  is.na(mandate_year), "never_treated",
  mandate_year < 2017, "always_treated",
  mandate_year >= 2017, paste0("treated_", mandate_year)
)]

# Exclude always-treated states
panel_did <- panel[treatment_group != "always_treated"]

cat(sprintf("DiD panel (excl. always-treated): %d obs, %d facilities\n",
            nrow(panel_did), uniqueN(panel_did$ccn)))

# ================================================================
# E. Create analysis variables
# ================================================================
cat("\n=== Creating analysis variables ===\n")

panel_did[, own_cat := fcase(
  grepl("For profit", ownership, ignore.case = TRUE), "for_profit",
  grepl("Non profit", ownership, ignore.case = TRUE), "nonprofit",
  grepl("Government", ownership, ignore.case = TRUE), "government",
  default = "other"
)]

panel_did[, size_cat := fcase(
  beds <= 60, "small",
  beds <= 120, "medium",
  beds > 120, "large",
  default = "unknown"
)]

panel_did[, log_def := log(n_deficiencies + 1)]

# V2: NY-only indicator for primary specification
panel_did[, ny_treated := as.integer(state == "NY" & survey_year >= 2022)]
panel_did[, rel_year_ny := fifelse(state == "NY", survey_year - 2022L, NA_integer_)]

# ================================================================
# F. Summary statistics
# ================================================================
cat("\n=== Summary Statistics ===\n")

cat("\nPanel coverage by year:\n")
print(panel_did[, .(n_surveys = .N, n_fac = uniqueN(ccn),
                     mean_def = round(mean(n_deficiencies), 1),
                     mean_obs = round(mean(n_observation), 1),
                     mean_doc = round(mean(n_documentation), 1),
                     mean_rpt = round(mean(n_report), 1)),
                by = survey_year][order(survey_year)])

cat("\nTreatment group sizes:\n")
print(panel_did[, .(n_obs = .N, n_fac = uniqueN(ccn)), by = treatment_group])

cat("\nSeverity distribution (detection modes):\n")
print(panel_did[, .(
  pct_minimal = round(100 * mean(n_minimal / pmax(n_deficiencies, 1)), 1),
  pct_moderate = round(100 * mean(n_moderate / pmax(n_deficiencies, 1)), 1),
  pct_harm = round(100 * mean(n_actual_harm / pmax(n_deficiencies, 1)), 1),
  pct_jeopardy = round(100 * mean(n_jeopardy / pmax(n_deficiencies, 1)), 1)
)])

# ================================================================
# G. Save
# ================================================================
saveRDS(panel, "../data/full_panel.rds")
saveRDS(panel_did, "../data/panel_did.rds")

cat(sprintf("\n=== Panel construction complete ===\n"))
cat(sprintf("Full panel: %d obs\n", nrow(panel)))
cat(sprintf("DiD panel: %d obs, %d facilities, %d states\n",
            nrow(panel_did), uniqueN(panel_did$ccn), uniqueN(panel_did$state)))
