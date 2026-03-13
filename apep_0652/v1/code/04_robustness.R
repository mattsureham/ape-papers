## 04_robustness.R — Robustness checks and sensitivity analysis
## apep_0652: EPCS Mandates and Opioid Mortality

source("00_packages.R")

panel <- data.table::fread("../data/analysis_panel.csv")
results <- readRDS("../data/main_results.rds")

panel[, state_id := as.integer(factor(state_abbr))]
panel[, group := as.integer(group)]
panel[, year := as.integer(year)]

# ============================================================================
# 1. Sun-Abraham estimator (alternative to CS-DiD)
# ============================================================================
message("Running Sun-Abraham estimator...")

# Create event time variable
panel[, event_time := fifelse(group > 0, year - group, NA_integer_)]

# sunab() for main outcomes
sa_rx <- feols(rx_opioid_rate ~ sunab(group, year) | state_id + year,
               data = panel[group != 2024],  # Drop IL (2024, only 0 post)
               cluster = ~state_id)

sa_synth <- feols(synth_opioid_rate ~ sunab(group, year) | state_id + year,
                  data = panel[group != 2024],
                  cluster = ~state_id)

# Extract aggregate ATT from Sun-Abraham (returns matrix)
sa_rx_agg <- aggregate(sa_rx, agg = "ATT")
sa_synth_agg <- aggregate(sa_synth, agg = "ATT")
sa_rx_coef <- sa_rx_agg["ATT", "Estimate"]
sa_rx_se <- sa_rx_agg["ATT", "Std. Error"]
sa_synth_coef <- sa_synth_agg["ATT", "Estimate"]
sa_synth_se <- sa_synth_agg["ATT", "Std. Error"]
message("Sun-Abraham Rx opioid ATT: ", round(sa_rx_coef, 3), " (SE: ", round(sa_rx_se, 3), ")")
message("Sun-Abraham Synth opioid ATT: ", round(sa_synth_coef, 3), " (SE: ", round(sa_synth_se, 3), ")")

# ============================================================================
# 2. Never-treated only control group
# ============================================================================
message("Running CS-DiD with never-treated controls only...")

cs_rx_nt <- att_gt(
  yname = "rx_opioid_rate",
  tname = "year",
  idname = "state_id",
  gname = "group",
  data = as.data.frame(panel[!is.na(rx_opioid_rate)]),
  control_group = "nevertreated",
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)
agg_rx_nt <- aggte(cs_rx_nt, type = "simple")
message("CS-DiD (never-treated) Rx opioid ATT: ", round(agg_rx_nt$overall.att, 3))

cs_synth_nt <- att_gt(
  yname = "synth_opioid_rate",
  tname = "year",
  idname = "state_id",
  gname = "group",
  data = as.data.frame(panel[!is.na(synth_opioid_rate)]),
  control_group = "nevertreated",
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)
agg_synth_nt <- aggte(cs_synth_nt, type = "simple")
message("CS-DiD (never-treated) Synth opioid ATT: ", round(agg_synth_nt$overall.att, 3))

# ============================================================================
# 3. Leave-one-out: Drop New York (earliest adopter)
# ============================================================================
message("Leave-one-out: dropping NY...")

panel_no_ny <- panel[state_abbr != "NY"]
panel_no_ny[, state_id := as.integer(factor(state_abbr))]

cs_rx_no_ny <- att_gt(
  yname = "rx_opioid_rate",
  tname = "year",
  idname = "state_id",
  gname = "group",
  data = as.data.frame(panel_no_ny[!is.na(rx_opioid_rate)]),
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)
agg_rx_no_ny <- aggte(cs_rx_no_ny, type = "simple")
message("Leave-one-out (no NY) Rx opioid ATT: ", round(agg_rx_no_ny$overall.att, 3))

# ============================================================================
# 4. Restrict to 2015-2021 (pre-fentanyl surge completion)
# ============================================================================
message("Restricting to 2015-2021...")

panel_2021 <- panel[year <= 2021]
panel_2021[, state_id := as.integer(factor(state_abbr))]

cs_rx_2021 <- att_gt(
  yname = "rx_opioid_rate",
  tname = "year",
  idname = "state_id",
  gname = "group",
  data = as.data.frame(panel_2021[!is.na(rx_opioid_rate)]),
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  biters = 1000
)
agg_rx_2021 <- aggte(cs_rx_2021, type = "simple")
message("2015-2021 Rx opioid ATT: ", round(agg_rx_2021$overall.att, 3))

# ============================================================================
# 5. Wild cluster bootstrap (few-cluster inference)
# ============================================================================
message("Wild cluster bootstrap for TWFE...")

# Use fwildclusterboot for bootstrap p-values
twfe_rx <- feols(rx_opioid_rate ~ treated | state_id + year,
                 data = panel, cluster = ~state_id)

boot_rx <- boottest(twfe_rx, B = 999, param = "treated",
                    clustid = "state_id", type = "webb")
message("Wild bootstrap p-value (Rx opioid): ", round(boot_rx$p_val, 4))

# ============================================================================
# 6. HonestDiD sensitivity for pre-trend violations (CS estimator)
# ============================================================================
message("Running HonestDiD sensitivity analysis...")

# Extract event study from CS-DiD for Rx opioid
es_rx <- results$es_rx

# Get pre-treatment coefficients for sensitivity
pre_idx <- which(es_rx$egt < 0)
post_idx <- which(es_rx$egt >= 0)

if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
  # Construct beta_hat and sigma for HonestDiD
  beta_hat <- es_rx$att.egt
  sigma_hat <- diag(es_rx$att.egt.se^2)  # Approximate with diagonal

  # Relative magnitudes approach
  honest_result <- tryCatch({
    HonestDiD::createSensitivityResults_relativeMagnitudes(
      betahat = beta_hat,
      sigma = sigma_hat,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mbarvec = seq(0, 2, by = 0.5)
    )
  }, error = function(e) {
    message("HonestDiD error: ", e$message)
    NULL
  })

  if (!is.null(honest_result)) {
    message("HonestDiD sensitivity bounds computed.")
    saveRDS(honest_result, "../data/honestdid_results.rds")
  }
} else {
  message("Insufficient pre/post periods for HonestDiD. Skipping.")
  honest_result <- NULL
}

# ============================================================================
# 7. Save robustness results
# ============================================================================
rob_results <- list(
  sa_rx = sa_rx, sa_synth = sa_synth,
  agg_rx_nt = agg_rx_nt, agg_synth_nt = agg_synth_nt,
  agg_rx_no_ny = agg_rx_no_ny,
  agg_rx_2021 = agg_rx_2021,
  boot_rx = boot_rx,
  honest_result = honest_result
)
saveRDS(rob_results, "../data/robustness_results.rds")

message("\n=== Robustness checks complete ===")

# Summary table
cat("\n========== ROBUSTNESS SUMMARY ==========\n")
cat(sprintf("%-35s  %8s  %8s\n", "Specification", "ATT", "SE"))
cat(strrep("-", 55), "\n")
cat(sprintf("%-35s  %8.3f  %8.3f\n", "Baseline CS-DiD (not-yet-treated)",
            results$agg_rx$overall.att, results$agg_rx$overall.se))
cat(sprintf("%-35s  %8.3f  %8.3f\n", "Sun-Abraham",
            sa_rx_coef, sa_rx_se))
cat(sprintf("%-35s  %8.3f  %8.3f\n", "CS-DiD (never-treated)",
            agg_rx_nt$overall.att, agg_rx_nt$overall.se))
cat(sprintf("%-35s  %8.3f  %8.3f\n", "Leave-one-out (drop NY)",
            agg_rx_no_ny$overall.att, agg_rx_no_ny$overall.se))
cat(sprintf("%-35s  %8.3f  %8.3f\n", "Restrict 2015-2021",
            agg_rx_2021$overall.att, agg_rx_2021$overall.se))
cat(sprintf("%-35s  %8s  p=%5.4f\n", "Wild cluster bootstrap",
            "", boot_rx$p_val))
cat("=========================================\n")
