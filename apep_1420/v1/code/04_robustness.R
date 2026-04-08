# 04_robustness.R — Robustness and placebo tests
# APEP-1420: The Coding Dividend

source("00_packages.R")

data_dir <- "../data"
analysis <- fread(file.path(data_dir, "analysis_panel.csv"))
results <- readRDS(file.path(data_dir, "main_results.rds"))

cat("=== Robustness Checks ===\n\n")

# ============================================================
# 1. PLACEBO: Non-triplet DRGs (singletons)
# ============================================================
# DRGs without severity tiers (singletons) should show no
# systematic payment-charge relationship from tier reclassification.
# Use singleton charge-payment elasticity as placebo benchmark.

cat("--- Placebo: Singleton DRGs ---\n")

puf_full <- fread(file.path(data_dir, "puf_combined.csv"))

# Identify singleton DRGs (no severity suffix)
puf_full[, has_severity := grepl("W MCC|W CC|W/O CC|W/O MCC", drg_desc, ignore.case = TRUE)]
singletons <- puf_full[has_severity == FALSE & !is.na(avg_charges) & !is.na(avg_medicare_payment)]
singletons[, hospital_id := .GRP, by = provider_id]
singletons[, drg_id := .GRP, by = drg_code]

if (nrow(singletons) > 1000) {
  m_placebo <- feols(
    log(avg_charges) ~ log(avg_medicare_payment) | hospital_id^drg_id + year,
    data = singletons[avg_charges > 0 & avg_medicare_payment > 0],
    cluster = ~drg_id
  )
  cat("Singleton charge-payment elasticity (benchmark):\n")
  etable(m_placebo, se.below = TRUE)
} else {
  cat("Insufficient singleton observations for placebo.\n")
  m_placebo <- NULL
}

# ============================================================
# 2. HETEROGENEITY: Surgical vs Medical DRGs
# ============================================================
# Surgical DRGs involve procedures; medical DRGs involve diagnosis.
# If the coding dividend differs, it reveals whether real treatment
# (surgery) vs labeling (diagnosis) drives the response.

cat("\n--- Heterogeneity: Surgical vs Medical ---\n")

# Identify surgical vs medical from DRG descriptions
# MDC codes: surgical DRGs typically have "OR" in the description
# or belong to surgical MDC ranges (DRG codes vary)
analysis[, surgical := grepl("\\bOR\\b|SURG|PROC|IMPLANT|TRANSPLANT",
                             base_condition, ignore.case = TRUE)]

m_surgical <- feols(
  log_charge_gap_mcc_cc ~ log_payment_gap_mcc_cc | hospital_id^triplet_id + year,
  data = analysis[surgical == TRUE],
  cluster = ~triplet_id
)

m_medical <- feols(
  log_charge_gap_mcc_cc ~ log_payment_gap_mcc_cc | hospital_id^triplet_id + year,
  data = analysis[surgical == FALSE],
  cluster = ~triplet_id
)

cat("Surgical DRGs:\n")
etable(m_surgical, se.below = TRUE)
cat("\nMedical DRGs:\n")
etable(m_medical, se.below = TRUE)

# ============================================================
# 3. HETEROGENEITY: Large vs Small Payment Gap
# ============================================================
cat("\n--- Heterogeneity: Large vs Small Payment Gap ---\n")

median_gap <- median(analysis$mcc_cc_payment_gap, na.rm = TRUE)
analysis[, large_gap := mcc_cc_payment_gap > median_gap]

m_large_gap <- feols(
  log_charge_gap_mcc_cc ~ log_payment_gap_mcc_cc | hospital_id^triplet_id + year,
  data = analysis[large_gap == TRUE],
  cluster = ~triplet_id
)

m_small_gap <- feols(
  log_charge_gap_mcc_cc ~ log_payment_gap_mcc_cc | hospital_id^triplet_id + year,
  data = analysis[large_gap == FALSE],
  cluster = ~triplet_id
)

cat("Large payment gap:\n")
etable(m_large_gap, se.below = TRUE)
cat("\nSmall payment gap:\n")
etable(m_small_gap, se.below = TRUE)

# ============================================================
# 4. ALTERNATIVE OUTCOME: Total discharges
# ============================================================
cat("\n--- Volume Response ---\n")

# Do total triplet discharges respond to payment changes?
# If so, payment affects admission decisions, not just coding.
analysis[, log_total_discharges := log(total_discharges)]

m_volume <- feols(
  log_total_discharges ~ mcc_cc_payment_gap | hospital_id^triplet_id + year,
  data = analysis,
  cluster = ~triplet_id
)

cat("Total discharge response:\n")
etable(m_volume, se.below = TRUE)

# ============================================================
# 5. ALTERNATIVE CLUSTERING
# ============================================================
cat("\n--- Alternative Clustering ---\n")

# Main result with state clustering
m_state_cluster <- feols(
  log_charge_gap_mcc_cc ~ log_payment_gap_mcc_cc | hospital_id^triplet_id + year,
  data = analysis,
  cluster = ~state
)

# Two-way clustering: triplet + year
m_twoway <- feols(
  log_charge_gap_mcc_cc ~ log_payment_gap_mcc_cc | hospital_id^triplet_id + year,
  data = analysis,
  cluster = ~triplet_id + year
)

cat("State clustering:\n")
etable(m_state_cluster, se.below = TRUE)
cat("\nTwo-way clustering (triplet + year):\n")
etable(m_twoway, se.below = TRUE)

# ============================================================
# 6. Save robustness results
# ============================================================
robust_results <- list(
  placebo = m_placebo,
  surgical = m_surgical,
  medical = m_medical,
  large_gap = m_large_gap,
  small_gap = m_small_gap,
  volume = m_volume,
  state_cluster = m_state_cluster,
  twoway_cluster = m_twoway
)

saveRDS(robust_results, file.path(data_dir, "robustness_results.rds"))
cat("\nRobustness checks complete.\n")
