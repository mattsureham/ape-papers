# 03_main_analysis.R — Main analysis: effect of 303(d) listing on facility compliance
source("00_packages.R")

# --- Load and merge data ---
facilities <- readRDS("../data/facilities_raw.rds")
huc12_map <- readRDS("../data/facility_huc12.rds")
attains <- readRDS("../data/attains_303d.rds")

# Merge HUC-12 assignments
setDT(facilities)
setDT(huc12_map)
facilities <- merge(facilities, huc12_map, by = "NPDES_ID", all.x = FALSE)
cat("Facilities with HUC-12:", nrow(facilities), "\n")

# Clean
facilities[, `:=`(
  lat = as.numeric(FAC_LAT),
  lon = as.numeric(FAC_LONG),
  huc8 = as.character(FAC_DERIVED_HUC),
  is_major = (CWP_MAJOR_MINOR_TYPE_FLAG == "M")
)]
facilities <- facilities[!is.na(huc12) & nchar(huc12) == 12]
cat("With valid HUC-12:", nrow(facilities), "\n")

# --- Construct treatment: Is the facility's HUC-12 on the 303(d) list? ---
attains[, huc12 := as.character(huc12)]
listed_huc12s <- unique(attains[on303dlist == "Y", .(huc12)])
listed_huc12s[, listed_303d := TRUE]

facilities <- merge(facilities, listed_huc12s, by = "huc12", all.x = TRUE)
facilities[is.na(listed_303d), listed_303d := FALSE]

cat("\n=== Treatment variable ===\n")
cat("Facilities in 303(d)-listed HUC-12:", sum(facilities$listed_303d), "\n")
cat("Facilities in non-listed HUC-12:", sum(!facilities$listed_303d), "\n")

# --- Parse compliance outcome ---
# CWP_13QTRS_COMPL_STATUS: 13-character string, most recent quarter first
# V = violation, S = SNC, E = effluent violation, _ = compliant, space/NA = unknown
facilities[, compl_str := as.character(CWP_13QTRS_COMPL_STATUS)]
facilities[, n_violation_qtrs := nchar(gsub("[^VES]", "", compl_str))]
facilities[, pct_violation := n_violation_qtrs / 13]

# Binary outcome: any violation in the 13-quarter window
facilities[, any_violation := (n_violation_qtrs > 0)]

# --- Restrict to HUC-8s with within-group variation ---
huc8_var <- facilities[, .(
  n_fac = .N,
  n_listed = sum(listed_303d),
  n_unlisted = sum(!listed_303d)
), by = huc8]
huc8_var[, has_variation := (n_listed > 0 & n_unlisted > 0)]

cat("\n=== HUC-8 variation ===\n")
cat("Total HUC-8s:", nrow(huc8_var), "\n")
cat("With within-variation:", sum(huc8_var$has_variation), "\n")

analysis <- merge(facilities, huc8_var[, .(huc8, has_variation, n_fac)],
                  by = "huc8", all.x = TRUE)
boundary <- analysis[has_variation == TRUE]

cat("\nBoundary sample:\n")
cat("  Facilities:", nrow(boundary), "\n")
cat("  Treated:", sum(boundary$listed_303d), "\n")
cat("  Control:", sum(!boundary$listed_303d), "\n")
cat("  HUC-8s:", uniqueN(boundary$huc8), "\n")
cat("  States:", uniqueN(boundary$CWP_STATE), "\n")

# --- Main specification: within-HUC-8 comparison ---
cat("\n=== MAIN RESULTS ===\n")

# Spec 1: OLS with HUC-8 fixed effects
# Y = pct_violation, T = listed_303d, FE = HUC-8
if (nrow(boundary) > 50) {
  m1 <- fixest::feols(pct_violation ~ listed_303d | huc8,
                       data = boundary, cluster = ~huc8)
  cat("\nSpec 1: Violation rate ~ 303(d) listing | HUC-8 FE\n")
  print(summary(m1))

  # Spec 2: Binary outcome
  m2 <- fixest::feols(any_violation ~ listed_303d | huc8,
                       data = boundary, cluster = ~huc8)
  cat("\nSpec 2: Any violation ~ 303(d) listing | HUC-8 FE\n")
  print(summary(m2))

  # Spec 3: Add state FE (absorbs state-level enforcement intensity)
  m3 <- fixest::feols(pct_violation ~ listed_303d | huc8 + CWP_STATE,
                       data = boundary, cluster = ~huc8)
  cat("\nSpec 3: Violation rate ~ 303(d) listing | HUC-8 + State FE\n")
  print(summary(m3))

  # Save models
  saveRDS(list(m1 = m1, m2 = m2, m3 = m3), "../data/main_models.rds")
} else {
  # Fallback: use full sample with state FE if boundary sample too small
  cat("\nBoundary sample too small. Using full sample.\n")
  m1 <- fixest::feols(pct_violation ~ listed_303d | CWP_STATE,
                       data = analysis, cluster = ~huc8)
  print(summary(m1))

  m2 <- fixest::feols(any_violation ~ listed_303d | CWP_STATE,
                       data = analysis, cluster = ~huc8)
  print(summary(m2))

  saveRDS(list(m1 = m1, m2 = m2), "../data/main_models.rds")
}

# --- Descriptive statistics ---
cat("\n=== Descriptive Statistics ===\n")
cat("Violation rate (treated):", mean(boundary$pct_violation[boundary$listed_303d], na.rm = TRUE), "\n")
cat("Violation rate (control):", mean(boundary$pct_violation[!boundary$listed_303d], na.rm = TRUE), "\n")
cat("Any violation (treated):", mean(boundary$any_violation[boundary$listed_303d], na.rm = TRUE), "\n")
cat("Any violation (control):", mean(boundary$any_violation[!boundary$listed_303d], na.rm = TRUE), "\n")

# --- Write diagnostics ---
diagnostics <- list(
  n_treated = sum(boundary$listed_303d),
  n_control = sum(!boundary$listed_303d),
  n_pre = 13,  # 13 quarters of compliance data
  n_obs = nrow(boundary),
  n_huc8 = uniqueN(boundary$huc8),
  n_states = uniqueN(boundary$CWP_STATE)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

# Save analysis data for robustness
saveRDS(analysis, "../data/analysis_panel.rds")
saveRDS(boundary, "../data/boundary_panel.rds")
cat("\n=== Analysis complete ===\n")
