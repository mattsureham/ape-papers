# 04_robustness.R — Robustness checks
source("00_packages.R")

boundary <- readRDS("../data/boundary_panel.rds")
analysis <- readRDS("../data/analysis_panel.rds")

cat("=== Robustness Checks ===\n")

# --- R1: Restrict to major facilities only ---
cat("\nR1: Major facilities only\n")
boundary_major <- boundary[is_major == TRUE]
if (nrow(boundary_major) > 30 && uniqueN(boundary_major$huc8[boundary_major$listed_303d]) > 1) {
  r1 <- fixest::feols(pct_violation ~ listed_303d | huc8,
                       data = boundary_major, cluster = ~huc8)
  print(summary(r1))
} else {
  cat("  Too few major facilities in boundary sample for HUC-8 FE.\n")
  r1 <- fixest::feols(pct_violation ~ listed_303d | CWP_STATE,
                       data = boundary_major, cluster = ~CWP_STATE)
  print(summary(r1))
}

# --- R2: Different outcome — number of violation quarters ---
cat("\nR2: Count of violation quarters\n")
r2 <- fixest::feols(n_violation_qtrs ~ listed_303d | huc8,
                     data = boundary, cluster = ~huc8)
print(summary(r2))

# --- R3: Full sample (all HUC-8s, state FE) ---
cat("\nR3: Full sample with state FE\n")
r3 <- fixest::feols(pct_violation ~ listed_303d | CWP_STATE,
                     data = analysis, cluster = ~huc8)
print(summary(r3))

# --- R4: Placebo — facility type should not predict 303(d) listing ---
cat("\nR4: Balance check — are treated/control facilities comparable?\n")
# Check if facility size (flow) is balanced
analysis[, flow := as.numeric(gsub("[^0-9.]", "", as.character(CWP_MAJOR_MINOR_TYPE_FLAG)))]
cat("Pct major (treated):", mean(boundary$is_major[boundary$listed_303d], na.rm = TRUE), "\n")
cat("Pct major (control):", mean(boundary$is_major[!boundary$listed_303d], na.rm = TRUE), "\n")

# --- R5: Vary the sample — drop states with extreme listing rates ---
cat("\nR5: Drop states with <10 or >500 listed HUC-12s\n")
state_counts <- boundary[, .(n_listed = sum(listed_303d), n_total = .N), by = CWP_STATE]
balanced_states <- state_counts[n_listed >= 5 & (n_total - n_listed) >= 5]$CWP_STATE
boundary_balanced <- boundary[CWP_STATE %in% balanced_states]
if (nrow(boundary_balanced) > 30) {
  r5 <- fixest::feols(pct_violation ~ listed_303d | huc8,
                       data = boundary_balanced, cluster = ~huc8)
  cat("Balanced sample:", nrow(boundary_balanced), "facilities,",
      uniqueN(boundary_balanced$CWP_STATE), "states\n")
  print(summary(r5))
}

# Save robustness models
rob_models <- list(r1 = r1, r2 = r2, r3 = r3)
if (exists("r5")) rob_models$r5 <- r5
saveRDS(rob_models, "../data/robustness_models.rds")

cat("\n=== Robustness checks complete ===\n")
