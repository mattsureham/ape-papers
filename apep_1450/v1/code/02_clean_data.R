# 02_clean_data.R — Clean and merge HACRP, hospital info, HAI data
source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. HACRP data — running variable and treatment
# ============================================================
hacrp <- fread(file.path(data_dir, "hacrp_fy2026.csv"))

# Convert numeric columns
num_cols <- c("total_hac_score", "psi_90_composite_value", "psi_90_w_z_score",
              "clabsi_sir", "clabsi_w_z_score", "cauti_sir", "cauti_w_z_score",
              "ssi_sir", "ssi_w_z_score", "cdi_sir", "cdi_w_z_score",
              "mrsa_sir", "mrsa_w_z_score")

for (col in num_cols) {
  if (col %in% names(hacrp)) {
    hacrp[, (col) := as.numeric(get(col))]
  }
}

# Create penalty indicator
hacrp[, penalized := as.integer(payment_reduction == "Yes")]

# Find the cutoff: 75th percentile of Total HAC Score
# Hospitals with score ABOVE this are penalized
scores <- hacrp[!is.na(total_hac_score), total_hac_score]
cutoff <- quantile(scores, 0.75)
cat("Cutoff (75th pct):", cutoff, "\n")

# Verify: penalized should be those above the cutoff
hacrp[!is.na(total_hac_score), cutoff_check := as.integer(total_hac_score > cutoff)]
agreement <- hacrp[!is.na(total_hac_score), mean(penalized == cutoff_check, na.rm = TRUE)]
cat("Agreement between penalty and score > p75:", round(agreement, 4), "\n")

# Create centered running variable
hacrp[, score_centered := total_hac_score - cutoff]

# Count footnoted (missing) scores
n_missing_score <- sum(is.na(hacrp$total_hac_score))
cat("Hospitals with missing Total HAC Score:", n_missing_score, "\n")
cat("Hospitals with valid score:", nrow(hacrp) - n_missing_score, "\n")

# Domain completeness
for (d in c("psi_90_w_z_score", "clabsi_w_z_score", "cauti_w_z_score",
            "ssi_w_z_score", "cdi_w_z_score", "mrsa_w_z_score")) {
  cat(sprintf("  %s: %d valid (%.1f%%)\n", d,
              sum(!is.na(hacrp[[d]])),
              100 * mean(!is.na(hacrp[[d]]))))
}

# ============================================================
# 2. Hospital General Information — covariates
# ============================================================
hosp_info <- fread(file.path(data_dir, "hospital_info.csv"))
cat("\nHospital info columns:", paste(names(hosp_info), collapse = ", "), "\n")

# Standardize facility ID for merge
# HACRP uses 6-digit CCN, hospital info may use different format
hacrp[, ccn := facility_id]
hosp_info_cols <- names(hosp_info)

# Identify the facility ID column in hospital info
id_col <- intersect(c("facility_id", "provider_id", "cms_certification_number_ccn",
                       "facility_id_ccn"), tolower(hosp_info_cols))
cat("Hospital info ID column candidates:", paste(id_col, collapse = ", "), "\n")

# Try to find the right merge key
if ("facility_id" %in% names(hosp_info)) {
  hosp_info[, ccn := facility_id]
} else {
  potential_ids <- grep("facility|provider|ccn|id", names(hosp_info), ignore.case = TRUE, value = TRUE)
  cat("Potential ID columns:", paste(potential_ids, collapse = ", "), "\n")
  if (length(potential_ids) > 0) {
    hosp_info[, ccn := get(potential_ids[1])]
  }
}

# Ensure ccn is character in both datasets
hacrp[, ccn := as.character(ccn)]
hosp_info[, ccn := as.character(ccn)]

# Select useful covariates from hospital info
cat("Hospital info sample columns:\n")
print(head(hosp_info, 2))

# ============================================================
# 3. Merge HACRP + Hospital Info
# ============================================================
# Merge on CCN
merged <- merge(hacrp, hosp_info, by = "ccn", all.x = TRUE, suffixes = c("", ".info"))
cat("\nMerged dataset:", nrow(merged), "rows\n")
cat("Match rate:", round(100 * mean(!is.na(merged$ccn)), 1), "%\n")

# Check what hospital characteristics we got
info_vars <- setdiff(names(merged), names(hacrp))
cat("Variables from hospital info:", paste(head(info_vars, 20), collapse = ", "), "\n")

# ============================================================
# 4. HAI data — individual infection SIRs as supplementary outcomes
# ============================================================
hai <- fread(file.path(data_dir, "hai_hospital.csv"))

# Keep only SIR measures (the main comparable metric)
hai_sirs <- hai[grepl("_SIR$", `Measure ID`)]
cat("\nHAI SIR measures:", paste(unique(hai_sirs$`Measure ID`), collapse = ", "), "\n")

# Pivot to wide: one row per hospital
hai_wide <- dcast(hai_sirs, `Facility ID` ~ `Measure ID`, value.var = "Score",
                  fun.aggregate = function(x) as.numeric(x[1]))
setnames(hai_wide, "Facility ID", "ccn")
cat("HAI wide:", nrow(hai_wide), "hospitals,", ncol(hai_wide), "measures\n")

# Merge HAI into main dataset
merged <- merge(merged, hai_wide, by = "ccn", all.x = TRUE)

# ============================================================
# 5. Final analysis dataset
# ============================================================
# Keep only hospitals with valid Total HAC Score (our RDD sample)
analysis <- merged[!is.na(total_hac_score)]
cat("\nFinal analysis sample:", nrow(analysis), "hospitals\n")
cat("  Penalized:", sum(analysis$penalized), "\n")
cat("  Not penalized:", sum(!analysis$penalized), "\n")
cat("  Score range:", round(min(analysis$total_hac_score), 4), "to",
    round(max(analysis$total_hac_score), 4), "\n")
cat("  Cutoff:", round(cutoff, 4), "\n")

# Gap at cutoff
just_below <- max(analysis[penalized == 0, total_hac_score])
just_above <- min(analysis[penalized == 1, total_hac_score])
cat("  Last non-penalized score:", round(just_below, 4), "\n")
cat("  First penalized score:", round(just_above, 4), "\n")
cat("  Gap:", round(just_above - just_below, 4), "\n")

# Save
saveRDS(analysis, file.path(data_dir, "analysis.rds"))
saveRDS(cutoff, file.path(data_dir, "cutoff.rds"))

cat("\nSaved analysis.rds and cutoff.rds\n")

# Quick summary stats
cat("\n=== Summary Statistics ===\n")
cat("Total HAC Score:\n")
print(summary(analysis$total_hac_score))
cat("\nDomain z-scores (means):\n")
for (d in c("psi_90_w_z_score", "clabsi_w_z_score", "cauti_w_z_score",
            "ssi_w_z_score", "cdi_w_z_score", "mrsa_w_z_score")) {
  cat(sprintf("  %s: mean=%.3f, sd=%.3f\n", d,
              mean(analysis[[d]], na.rm = TRUE),
              sd(analysis[[d]], na.rm = TRUE)))
}
