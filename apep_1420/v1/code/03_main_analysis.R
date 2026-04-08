# 03_main_analysis.R — Main DiD analysis
# APEP-1420: The Coding Dividend
#
# Key regressions:
# 1. Does the MCC-CC payment gap predict charge gaps? (coding dividend)
# 2. Does the MCC-CC payment gap predict discharge composition? (coding margin)
# 3. Event study around large payment gap changes

source("00_packages.R")

data_dir <- "../data"
analysis <- fread(file.path(data_dir, "analysis_panel.csv"))
national_gaps <- fread(file.path(data_dir, "national_gaps.csv"))

cat(sprintf("Analysis sample: %s rows, %d hospitals, %d triplets, %d years\n",
            format(nrow(analysis), big.mark = ","),
            uniqueN(analysis$provider_id),
            uniqueN(analysis$triplet_id),
            uniqueN(analysis$year)))

# ============================================================
# 1. MAIN SPECIFICATION: The Coding Dividend
# ============================================================
# Does a $1 increase in the MCC-CC payment gap lead to a $1 increase
# in the MCC-CC charge gap? Or is the charge gap unresponsive?
#
# Y = log(charge_ratio_MCC_CC)
# X = log(payment_ratio_MCC_CC)
# FE = hospital + year + triplet
# Cluster = triplet level

cat("\n=== Main Specification: Coding Dividend ===\n")

# Spec 1: OLS with triplet + year FE (cross-sectional + time variation)
m1 <- feols(
  log_charge_gap_mcc_cc ~ log_payment_gap_mcc_cc | triplet_id + year,
  data = analysis,
  cluster = ~triplet_id
)

# Spec 2: Add hospital FE (within-hospital variation)
m2 <- feols(
  log_charge_gap_mcc_cc ~ log_payment_gap_mcc_cc | hospital_id + triplet_id + year,
  data = analysis,
  cluster = ~triplet_id
)

# Spec 3: Hospital × triplet FE (pure within-hospital-triplet time variation)
m3 <- feols(
  log_charge_gap_mcc_cc ~ log_payment_gap_mcc_cc | hospital_id^triplet_id + year,
  data = analysis,
  cluster = ~triplet_id
)

cat("\n--- Coding Dividend Estimates ---\n")
cat("Interpretation: β = 1 means full pass-through; β = 0 means pure coding\n")
etable(m1, m2, m3,
       headers = c("Triplet+Year FE", "+Hospital FE", "Hosp×Triplet FE"),
       se.below = TRUE)

# ============================================================
# 2. CODING MARGIN: MCC Share Response
# ============================================================
# Does a larger payment gap increase the share of discharges coded as MCC?

cat("\n=== Coding Margin: MCC Share ===\n")

# Spec 1: MCC share ~ payment gap (triplet + year FE)
m4 <- feols(
  mcc_share ~ mcc_cc_payment_gap | triplet_id + year,
  data = analysis,
  cluster = ~triplet_id
)

# Spec 2: Add hospital FE
m5 <- feols(
  mcc_share ~ mcc_cc_payment_gap | hospital_id + triplet_id + year,
  data = analysis,
  cluster = ~triplet_id
)

# Spec 3: Hospital × triplet FE
m6 <- feols(
  mcc_share ~ mcc_cc_payment_gap | hospital_id^triplet_id + year,
  data = analysis,
  cluster = ~triplet_id
)

cat("\n--- MCC Share Response ---\n")
cat("Interpretation: β > 0 means hospitals code more aggressively when gap is larger\n")
etable(m4, m5, m6,
       headers = c("Triplet+Year FE", "+Hospital FE", "Hosp×Triplet FE"),
       se.below = TRUE)

# ============================================================
# 3. CHARGE LEVEL REGRESSIONS
# ============================================================
# Separate regressions for MCC charges and CC charges

cat("\n=== Charge Level Regressions ===\n")

# MCC charges ~ payment gap (hosp×triplet FE + year FE)
m7 <- feols(
  log_charges_mcc ~ log_payment_mcc | hospital_id^triplet_id + year,
  data = analysis,
  cluster = ~triplet_id
)

# CC charges ~ payment gap
m8 <- feols(
  log_charges_cc ~ log_payment_cc | hospital_id^triplet_id + year,
  data = analysis,
  cluster = ~triplet_id
)

cat("\n--- Charge-Payment Elasticities ---\n")
etable(m7, m8,
       headers = c("MCC Charges", "CC Charges"),
       se.below = TRUE)

# ============================================================
# 4. EVENT STUDY: Large Payment Gap Changes
# ============================================================
# Identify triplets with large year-over-year payment gap changes
# and estimate event study around these "shocks"

cat("\n=== Event Study: Large Payment Gap Changes ===\n")

# Identify triplet-years with large payment gap changes (top quartile)
gap_changes <- national_gaps[!is.na(delta_payment_gap) & !is.na(year)]

q75 <- quantile(abs(gap_changes$delta_payment_gap), 0.75, na.rm = TRUE)
cat(sprintf("75th percentile of |Δ payment gap|: $%s\n", format(round(q75), big.mark = ",")))

# Mark "shock" triplet-years
gap_changes[, large_shock := abs(delta_payment_gap) > q75]
gap_changes[, shock_direction := fifelse(delta_payment_gap > q75, "increase",
                                          fifelse(delta_payment_gap < -q75, "decrease", "none"))]

# For each triplet with a shock, create event time relative to shock year
shock_triplets <- gap_changes[large_shock == TRUE, .(
  shock_year = year[which.max(abs(delta_payment_gap))]
), by = triplet_id]

# Merge back
analysis_es <- merge(analysis, shock_triplets, by = "triplet_id", all.x = TRUE)
analysis_es[, event_time := year - shock_year]

# Keep observations within event window [-3, +3]
analysis_es <- analysis_es[!is.na(event_time) & abs(event_time) <= 3]

cat(sprintf("Event study sample: %s observations, %d triplets with shocks\n",
            format(nrow(analysis_es), big.mark = ","),
            uniqueN(analysis_es$triplet_id)))

if (nrow(analysis_es) > 100) {
  # Event study regression
  analysis_es[, event_time_f := factor(event_time)]
  analysis_es[, event_time_f := relevel(event_time_f, ref = "-1")]  # t-1 as baseline

  m_es_charges <- feols(
    log_charge_gap_mcc_cc ~ event_time_f | hospital_id + triplet_id,
    data = analysis_es,
    cluster = ~triplet_id
  )

  m_es_coding <- feols(
    mcc_share ~ event_time_f | hospital_id + triplet_id,
    data = analysis_es,
    cluster = ~triplet_id
  )

  cat("\n--- Event Study: Charge Gap ---\n")
  etable(m_es_charges, se.below = TRUE)

  cat("\n--- Event Study: MCC Share ---\n")
  etable(m_es_coding, se.below = TRUE)
}

# ============================================================
# 5. Save results and diagnostics
# ============================================================
cat("\n=== Saving Results ===\n")

# Save model results for table generation
results <- list(
  coding_dividend = list(m1 = m1, m2 = m2, m3 = m3),
  coding_margin = list(m4 = m4, m5 = m5, m6 = m6),
  charge_elasticity = list(m7 = m7, m8 = m8)
)

if (exists("m_es_charges")) {
  results$event_study <- list(charges = m_es_charges, coding = m_es_coding)
}

saveRDS(results, file.path(data_dir, "main_results.rds"))

# Diagnostics for validator
diagnostics <- list(
  n_treated = uniqueN(analysis_es$triplet_id),
  n_pre = length(unique(analysis_es$year[analysis_es$event_time < 0])),
  n_obs = nrow(analysis)
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("Main analysis complete.\n")
