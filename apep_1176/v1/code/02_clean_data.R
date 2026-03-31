# 02_clean_data.R — Clean and merge CMS datasets, construct IV variables
source("00_packages.R")
setwd("../")

cat("=== Cleaning CMS Nursing Home Data ===\n")

# ---- Load raw data ----
deficiencies <- fread("data/health_deficiencies.csv")
providers    <- fread("data/provider_info.csv")
quality      <- fread("data/quality_measures.csv")

# ---- Standardize column names ----
setnames(deficiencies, make.names(names(deficiencies), unique = TRUE))
setnames(providers, make.names(names(providers), unique = TRUE))
setnames(quality, make.names(names(quality), unique = TRUE))

# ---- 1. Construct severity index from deficiency data ----
cat("\n[1] Constructing severity index...\n")

# Map scope-severity codes to numeric (A=1, ..., L=12)
sev_map <- data.table(
  code = c("A","B","C","D","E","F","G","H","I","J","K","L"),
  severity_score = 1:12,
  severity_label = c(
    rep("No harm (potential minimal)", 3),
    rep("No harm (potential > minimal)", 3),
    rep("Actual harm", 3),
    rep("Immediate jeopardy", 3)
  ),
  harm_level = c(rep(1,3), rep(2,3), rep(3,3), rep(4,3))
)

deficiencies[, severity_code := Scope.Severity.Code]
deficiencies <- merge(deficiencies, sev_map, by.x = "severity_code", by.y = "code", all.x = TRUE)

# Parse survey date and extract year
deficiencies[, survey_date := as.Date(Survey.Date, tryFormats = c("%Y-%m-%d", "%m/%d/%Y"))]
deficiencies[, survey_year := year(survey_date)]

# Facility ID
deficiencies[, ccn := CMS.Certification.Number..CCN.]
deficiencies[, state := State]

cat("  Severity scores assigned:", sum(!is.na(deficiencies$severity_score)), "/", nrow(deficiencies), "\n")
cat("  Year range:", range(deficiencies$survey_year, na.rm = TRUE), "\n")

# ---- 2. Aggregate deficiencies to facility-year level ----
cat("\n[2] Aggregating to facility-year level...\n")

facility_year <- deficiencies[!is.na(severity_score), .(
  mean_severity     = mean(severity_score, na.rm = TRUE),
  max_severity      = max(severity_score, na.rm = TRUE),
  n_deficiencies    = .N,
  n_severe          = sum(harm_level >= 3, na.rm = TRUE),  # G+ (actual harm or jeopardy)
  pct_severe        = mean(harm_level >= 3, na.rm = TRUE),
  any_jeopardy      = as.integer(any(harm_level == 4, na.rm = TRUE))
), by = .(ccn, state, survey_year)]

cat("  Facility-years:", nrow(facility_year), "\n")
cat("  Unique facilities:", uniqueN(facility_year$ccn), "\n")
cat("  Years:", sort(unique(facility_year$survey_year)), "\n")

# ---- 3. Construct leave-one-out state stringency instrument ----
cat("\n[3] Constructing leave-one-out state stringency...\n")

# State-year totals
state_year <- facility_year[, .(
  state_total_severity = sum(mean_severity),
  state_n_facilities   = .N
), by = .(state, survey_year)]

# Merge back and compute leave-one-out
facility_year <- merge(facility_year, state_year, by = c("state", "survey_year"))

facility_year[, loo_state_stringency := (state_total_severity - mean_severity) / (state_n_facilities - 1)]

# Drop singleton states (can't compute LOO)
facility_year <- facility_year[state_n_facilities > 1]

cat("  LOO stringency range:", round(range(facility_year$loo_state_stringency, na.rm = TRUE), 2), "\n")
cat("  States:", uniqueN(facility_year$state), "\n")

# ---- 4. Clean provider info ----
cat("\n[4] Cleaning provider info...\n")

prov <- providers[, .(
  ccn           = CMS.Certification.Number..CCN.,
  state         = State,
  beds          = as.numeric(Number.of.Certified.Beds),
  avg_residents = as.numeric(Average.Number.of.Residents.per.Day),
  ownership     = Ownership.Type,
  urban         = Urban,
  chain_name    = Chain.Name,
  chain_id      = Chain.ID,
  n_chain_fac   = as.numeric(Number.of.Facilities.in.Chain),
  overall_rating     = as.numeric(Overall.Rating),
  health_insp_rating = as.numeric(Health.Inspection.Rating),
  staffing_rating    = as.numeric(Staffing.Rating),
  qm_rating          = as.numeric(QM.Rating),
  total_nurse_hprd   = as.numeric(Reported.Total.Nurse.Staffing.Hours.per.Resident.per.Day),
  rn_hprd            = as.numeric(Reported.RN.Staffing.Hours.per.Resident.per.Day),
  lpn_hprd           = as.numeric(Reported.LPN.Staffing.Hours.per.Resident.per.Day),
  cna_hprd           = as.numeric(Reported.Nurse.Aide.Staffing.Hours.per.Resident.per.Day),
  adj_total_hprd     = as.numeric(Adjusted.Total.Nurse.Staffing.Hours.per.Resident.per.Day),
  adj_rn_hprd        = as.numeric(Adjusted.RN.Staffing.Hours.per.Resident.per.Day),
  rn_turnover        = as.numeric(Registered.Nurse.turnover),
  total_turnover     = as.numeric(Total.nursing.staff.turnover),
  n_fines            = as.numeric(Number.of.Fines),
  total_fines_usd    = as.numeric(Total.Amount.of.Fines.in.Dollars),
  n_penalties        = as.numeric(Total.Number.of.Penalties),
  weighted_health_score = as.numeric(Total.Weighted.Health.Survey.Score)
)]

# Flag chain vs independent
prov[, in_chain := as.integer(!is.na(chain_id) & chain_id != "")]

# Ownership categories
prov[, ownership_cat := fcase(
  grepl("For profit", ownership, ignore.case = TRUE), "For-profit",
  grepl("Non profit|Not for profit", ownership, ignore.case = TRUE), "Non-profit",
  grepl("Government", ownership, ignore.case = TRUE), "Government",
  default = "Other"
)]

cat("  Facilities:", nrow(prov), "\n")
cat("  In chain:", sum(prov$in_chain, na.rm = TRUE), "(", round(100*mean(prov$in_chain, na.rm = TRUE)), "%)\n")
cat("  Ownership:\n")
print(table(prov$ownership_cat))

# ---- 5. Clean quality measures ----
cat("\n[5] Cleaning quality measures...\n")

# Pivot quality to wide format (one row per facility)
qm <- quality[, .(
  ccn = CMS.Certification.Number..CCN.,
  measure = Measure.Code,
  score = as.numeric(Four.Quarter.Average.Score),
  resident_type = Resident.type
)]

# Key quality measures for nursing homes
# Focus on long-stay measures (more relevant)
qm_long <- qm[resident_type == "Long Stay" & !is.na(score)]

# Pivot to wide
qm_wide <- dcast(qm_long, ccn ~ measure, value.var = "score", fun.aggregate = mean)
cat("  Quality measures (long-stay):", ncol(qm_wide) - 1, "measures\n")
cat("  Facilities with QM data:", nrow(qm_wide), "\n")

# Print available measures
cat("  Measure codes:", paste(names(qm_wide)[-1], collapse = ", "), "\n")

# ---- 6. Merge all datasets ----
cat("\n[6] Merging datasets...\n")

# Use 2025 as the latest full year (2026 is partial)
latest_year <- 2025
cat("  Using latest full survey year:", latest_year, "\n")

# Cross-sectional: latest year deficiency + provider info
fy_latest <- facility_year[survey_year == latest_year]
cat("  Facilities in latest year:", nrow(fy_latest), "\n")

# Merge with provider info
analysis <- merge(fy_latest, prov, by = "ccn", all.x = TRUE, suffixes = c("", ".prov"))

# Merge with quality measures
analysis <- merge(analysis, qm_wide, by = "ccn", all.x = TRUE)

# Reconcile state columns from merge
state_cols <- grep("^state", names(analysis), value = TRUE)
cat("  State columns after merge:", paste(state_cols, collapse = ", "), "\n")
# The deficiency data 'state' is the primary; rename if needed
if ("state" %in% names(analysis)) {
  # state from deficiency data already present
} else if ("state.x" %in% names(analysis)) {
  setnames(analysis, "state.x", "state")
}
# Drop provider state duplicate
drop_cols <- setdiff(state_cols, "state")
if (length(drop_cols) > 0) analysis[, (drop_cols) := NULL]

cat("  Final analysis sample:", nrow(analysis), "facilities\n")
cat("  With staffing data:", sum(!is.na(analysis$total_nurse_hprd)), "\n")
cat("  In chains:", sum(analysis$in_chain == 1, na.rm = TRUE), "\n")

# ---- 7. Also prepare panel dataset (all years) ----
cat("\n[7] Preparing panel dataset...\n")

panel <- merge(facility_year, prov, by = "ccn", all.x = TRUE, suffixes = c("", ".prov"))
# Reconcile state in panel
panel_state_cols <- grep("^state", names(panel), value = TRUE)
if (length(panel_state_cols) > 1) {
  drop_panel <- setdiff(panel_state_cols, "state")
  panel[, (drop_panel) := NULL]
}

cat("  Panel observations:", nrow(panel), "\n")
cat("  Unique facilities:", uniqueN(panel$ccn), "\n")
cat("  Years:", sort(unique(panel$survey_year)), "\n")

# ---- 8. Summary statistics ----
cat("\n=== Summary Statistics ===\n")
cat("\nDeficiency severity (facility-year, latest):\n")
print(summary(analysis[, .(mean_severity, n_deficiencies, pct_severe)]))

cat("\nStaffing HPRD:\n")
print(summary(analysis[, .(total_nurse_hprd, rn_hprd, cna_hprd)]))

cat("\nInstrument (LOO state stringency):\n")
print(summary(analysis$loo_state_stringency))

cat("\nFacility characteristics:\n")
print(summary(analysis[, .(beds, avg_residents)]))

# ---- Save ----
cat("\n[8] Saving cleaned data...\n")
fwrite(analysis, "data/analysis_cross_section.csv")
fwrite(panel, "data/analysis_panel.csv")
fwrite(facility_year, "data/facility_year.csv")
saveRDS(analysis, "data/analysis_cross_section.rds")
saveRDS(panel, "data/analysis_panel.rds")

cat("\n=== Cleaning Complete ===\n")
cat("  Cross-section:", nrow(analysis), "facilities\n")
cat("  Panel:", nrow(panel), "facility-years\n")
