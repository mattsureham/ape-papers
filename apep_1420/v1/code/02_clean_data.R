# 02_clean_data.R — Construct DRG triplets and treatment variables
# APEP-1420: The Coding Dividend
#
# Key steps:
# 1. Parse DRG descriptions to identify severity tiers (MCC/CC/base)
# 2. Group DRGs into triplets (same condition, different severity)
# 3. Construct within-triplet payment gaps and charge ratios
# 4. Create treatment variables for DiD

source("00_packages.R")

data_dir <- "../data"
puf <- fread(file.path(data_dir, "puf_combined.csv"))

cat(sprintf("Loaded PUF: %s rows\n", format(nrow(puf), big.mark = ",")))

# ============================================================
# 1. Identify severity tier from DRG description
# ============================================================
# MS-DRG descriptions encode severity:
#   "W MCC" = with Major Complication/Comorbidity
#   "W CC"  = with Complication/Comorbidity (but not MCC)
#   "W/O CC/MCC" or "W/O MCC" = without CC/MCC (base)

cat("\n=== Parsing DRG Severity Tiers ===\n")

# DRG descriptions use "WITH MCC", "WITH CC", "WITHOUT CC/MCC" etc.
# Parse carefully: "WITH MCC" but not "WITHOUT MCC"
puf[, severity := fcase(
  grepl("\\bWITH MCC\\b", drg_desc, ignore.case = TRUE) &
    !grepl("\\bWITHOUT MCC\\b", drg_desc, ignore.case = TRUE), "MCC",
  grepl("\\bWITH CC\\b", drg_desc, ignore.case = TRUE) &
    !grepl("\\bWITHOUT CC\\b", drg_desc, ignore.case = TRUE) &
    !grepl("\\bWITH MCC\\b", drg_desc, ignore.case = TRUE), "CC",
  grepl("\\bWITHOUT CC(/MCC)?\\b", drg_desc, ignore.case = TRUE) |
    grepl("\\bWITHOUT MCC\\b", drg_desc, ignore.case = TRUE) |
    grepl("\\bW/O CC(/MCC)?\\b", drg_desc, ignore.case = TRUE) |
    grepl("\\bW/O MCC\\b", drg_desc, ignore.case = TRUE), "BASE",
  default = NA_character_
)]

cat("Severity distribution:\n")
print(table(puf$severity, useNA = "always"))

# Keep only DRGs with identifiable severity tiers
puf_sev <- puf[!is.na(severity)]
cat(sprintf("\nRetained %s rows with severity classification (%.1f%%)\n",
            format(nrow(puf_sev), big.mark = ","),
            100 * nrow(puf_sev) / nrow(puf)))

# ============================================================
# 2. Construct DRG triplets
# ============================================================
# Strip severity suffixes to create a "base condition" identifier
# This groups the MCC, CC, and BASE versions of the same DRG

puf_sev[, base_condition := drg_desc]
# Strip severity suffixes (order matters: longer patterns first)
puf_sev[, base_condition := gsub("\\s+WITHOUT CC/MCC$", "", base_condition, ignore.case = TRUE)]
puf_sev[, base_condition := gsub("\\s+WITHOUT MCC$", "", base_condition, ignore.case = TRUE)]
puf_sev[, base_condition := gsub("\\s+WITHOUT CC$", "", base_condition, ignore.case = TRUE)]
puf_sev[, base_condition := gsub("\\s+WITH MCC$", "", base_condition, ignore.case = TRUE)]
puf_sev[, base_condition := gsub("\\s+WITH CC$", "", base_condition, ignore.case = TRUE)]
puf_sev[, base_condition := gsub("\\s+W/O CC/MCC$", "", base_condition, ignore.case = TRUE)]
puf_sev[, base_condition := gsub("\\s+W/O MCC$", "", base_condition, ignore.case = TRUE)]
puf_sev[, base_condition := gsub("\\s+W/O CC$", "", base_condition, ignore.case = TRUE)]
puf_sev[, base_condition := gsub("\\s+W MCC$", "", base_condition, ignore.case = TRUE)]
puf_sev[, base_condition := gsub("\\s+W CC$", "", base_condition, ignore.case = TRUE)]
# Also strip leading DRG code (e.g., "291 - ")
puf_sev[, base_condition := gsub("^\\d+\\s*-\\s*", "", base_condition)]
puf_sev[, base_condition := trimws(base_condition)]

# Identify complete triplets: conditions that have all 3 severity levels
triplet_check <- puf_sev[, .(
  has_mcc = any(severity == "MCC"),
  has_cc = any(severity == "CC"),
  has_base = any(severity == "BASE"),
  n_severity = uniqueN(severity)
), by = base_condition]

# Full triplets have all 3 levels
full_triplets <- triplet_check[has_mcc == TRUE & has_cc == TRUE & has_base == TRUE]
cat(sprintf("\nFull triplets (MCC + CC + BASE): %d conditions\n", nrow(full_triplets)))

# Partial pairs (MCC + base or CC + base)
pairs <- triplet_check[n_severity == 2]
cat(sprintf("Partial pairs (2 severity levels): %d conditions\n", nrow(pairs)))

# Keep full triplets for the main analysis (cleanest comparison)
puf_triplets <- puf_sev[base_condition %in% full_triplets$base_condition]
cat(sprintf("Rows in full triplets: %s\n", format(nrow(puf_triplets), big.mark = ",")))

# Create triplet_id (numeric) for FE
puf_triplets[, triplet_id := .GRP, by = base_condition]

# ============================================================
# 3. Construct within-triplet panels
# ============================================================
# For each hospital × triplet × year, compute:
# - Discharge share by severity level
# - Average charges at each severity level
# - Payment gap between severity tiers

cat("\n=== Constructing Within-Triplet Panels ===\n")

# Reshape to wide format: one row per hospital × triplet × year
# with separate columns for each severity tier
triplet_wide <- dcast(
  puf_triplets,
  provider_id + provider_name + state + base_condition + triplet_id + year ~ severity,
  value.var = c("discharges", "avg_charges", "avg_medicare_payment", "drg_code"),
  fun.aggregate = function(x) x[1]  # Should be unique
)

# Compute within-triplet metrics
triplet_wide[, `:=`(
  # Total discharges in triplet
  total_discharges = rowSums(cbind(
    fifelse(is.na(discharges_MCC), 0, discharges_MCC),
    fifelse(is.na(discharges_CC), 0, discharges_CC),
    fifelse(is.na(discharges_BASE), 0, discharges_BASE)
  )),
  # MCC share of discharges
  mcc_share = fifelse(
    !is.na(discharges_MCC) & !is.na(discharges_CC) & !is.na(discharges_BASE),
    discharges_MCC / (discharges_MCC + discharges_CC + discharges_BASE),
    NA_real_
  ),
  # CC share of discharges
  cc_share = fifelse(
    !is.na(discharges_MCC) & !is.na(discharges_CC) & !is.na(discharges_BASE),
    discharges_CC / (discharges_MCC + discharges_CC + discharges_BASE),
    NA_real_
  ),
  # Payment gaps
  mcc_cc_payment_gap = avg_medicare_payment_MCC - avg_medicare_payment_CC,
  mcc_base_payment_gap = avg_medicare_payment_MCC - avg_medicare_payment_BASE,
  cc_base_payment_gap = avg_medicare_payment_CC - avg_medicare_payment_BASE,
  # Charge gaps
  mcc_cc_charge_gap = avg_charges_MCC - avg_charges_CC,
  mcc_base_charge_gap = avg_charges_MCC - avg_charges_BASE,
  cc_base_charge_gap = avg_charges_CC - avg_charges_BASE,
  # Log ratios
  log_charges_mcc = log(avg_charges_MCC),
  log_charges_cc = log(avg_charges_CC),
  log_charges_base = log(avg_charges_BASE),
  log_payment_mcc = log(avg_medicare_payment_MCC),
  log_payment_cc = log(avg_medicare_payment_CC),
  log_payment_base = log(avg_medicare_payment_BASE),
  # Charge ratio (MCC/CC)
  charge_ratio_mcc_cc = avg_charges_MCC / avg_charges_CC,
  # Payment ratio (MCC/CC)
  payment_ratio_mcc_cc = avg_medicare_payment_MCC / avg_medicare_payment_CC
)]

# Log payment gap (for regression)
triplet_wide[, log_payment_gap_mcc_cc := log(avg_medicare_payment_MCC) - log(avg_medicare_payment_CC)]
triplet_wide[, log_charge_gap_mcc_cc := log(avg_charges_MCC) - log(avg_charges_CC)]

# ============================================================
# 4. Construct treatment: year-over-year payment gap changes
# ============================================================
# The treatment variable is the change in the MCC-CC payment gap
# driven by CMS weight recalibration.

cat("\n=== Constructing Treatment Variables ===\n")

# National-level payment gap by triplet × year (averaged across hospitals)
national_gaps <- triplet_wide[!is.na(mcc_cc_payment_gap), .(
  national_payment_gap = weighted.mean(mcc_cc_payment_gap, total_discharges, na.rm = TRUE),
  national_payment_ratio = weighted.mean(payment_ratio_mcc_cc, total_discharges, na.rm = TRUE),
  national_mcc_share = weighted.mean(mcc_share, total_discharges, na.rm = TRUE),
  n_hospitals = .N
), by = .(triplet_id, base_condition, year)]

setorder(national_gaps, triplet_id, year)

# Compute year-over-year change in national payment gap
national_gaps[, delta_payment_gap := national_payment_gap - shift(national_payment_gap, 1),
              by = triplet_id]
national_gaps[, delta_log_payment_ratio := log(national_payment_ratio) -
                shift(log(national_payment_ratio), 1),
              by = triplet_id]

# Merge treatment back to hospital-level data
triplet_wide <- merge(
  triplet_wide,
  national_gaps[, .(triplet_id, year, delta_payment_gap, delta_log_payment_ratio,
                    national_payment_gap, national_mcc_share)],
  by = c("triplet_id", "year"),
  all.x = TRUE
)

# Create hospital numeric ID for FE
triplet_wide[, hospital_id := .GRP, by = provider_id]

# ============================================================
# 5. Sample restrictions and validation
# ============================================================
cat("\n=== Applying Sample Restrictions ===\n")

# Require complete data on key variables
analysis <- triplet_wide[
  !is.na(mcc_share) &
  !is.na(mcc_cc_payment_gap) &
  !is.na(avg_charges_MCC) &
  !is.na(avg_charges_CC) &
  total_discharges >= 11  # CMS suppresses cells with <=10 discharges
]

cat(sprintf("Analysis sample: %s hospital-triplet-year observations\n",
            format(nrow(analysis), big.mark = ",")))
cat(sprintf("  Hospitals: %d\n", uniqueN(analysis$provider_id)))
cat(sprintf("  Triplets: %d\n", uniqueN(analysis$triplet_id)))
cat(sprintf("  Years: %s\n", paste(sort(unique(analysis$year)), collapse = ", ")))

# Validate sample sizes
stopifnot("FATAL: Too few observations" = nrow(analysis) > 1000)
stopifnot("FATAL: Too few hospitals" = uniqueN(analysis$provider_id) > 100)
stopifnot("FATAL: Too few triplets" = uniqueN(analysis$triplet_id) > 20)

# Summary statistics
cat("\n=== Key Summary Statistics ===\n")
cat(sprintf("Mean MCC share: %.3f\n", mean(analysis$mcc_share, na.rm = TRUE)))
cat(sprintf("Mean MCC-CC payment gap: $%s\n",
            format(round(mean(analysis$mcc_cc_payment_gap, na.rm = TRUE)), big.mark = ",")))
cat(sprintf("Mean MCC charges: $%s\n",
            format(round(mean(analysis$avg_charges_MCC, na.rm = TRUE)), big.mark = ",")))
cat(sprintf("Mean CC charges: $%s\n",
            format(round(mean(analysis$avg_charges_CC, na.rm = TRUE)), big.mark = ",")))
cat(sprintf("Mean charge ratio (MCC/CC): %.3f\n",
            mean(analysis$charge_ratio_mcc_cc, na.rm = TRUE)))
cat(sprintf("Mean payment ratio (MCC/CC): %.3f\n",
            mean(analysis$payment_ratio_mcc_cc, na.rm = TRUE)))

# Save
fwrite(analysis, file.path(data_dir, "analysis_panel.csv"))
fwrite(national_gaps, file.path(data_dir, "national_gaps.csv"))
cat(sprintf("\nSaved analysis panel: %s rows\n", format(nrow(analysis), big.mark = ",")))
