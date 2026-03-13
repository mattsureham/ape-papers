## 03_main_analysis.R — Main DiD estimation
## apep_0652: EPCS Mandates and Opioid Mortality

source("00_packages.R")

panel <- data.table::fread("../data/analysis_panel.csv")

# ============================================================================
# 1. Callaway-Sant'Anna DiD — Primary outcomes
# ============================================================================
message("Running Callaway-Sant'Anna DiD...")

# Ensure proper types
panel[, state_id := as.integer(factor(state_abbr))]
panel[, group := as.integer(group)]
panel[, year := as.integer(year)]

# --- Primary outcome: Prescription opioid death rate (T40.2) ---
message("\n--- Rx opioid death rate (T40.2) ---")
cs_rx <- att_gt(
  yname = "rx_opioid_rate",
  tname = "year",
  idname = "state_id",
  gname = "group",
  data = as.data.frame(panel[!is.na(rx_opioid_rate)]),
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)
message("CS-DiD Rx opioid complete.")

# Aggregate to overall ATT
agg_rx <- aggte(cs_rx, type = "simple")
message("Overall ATT (Rx opioid rate): ", round(agg_rx$overall.att, 3),
        " (SE: ", round(agg_rx$overall.se, 3), ")")

# Event study aggregation
es_rx <- aggte(cs_rx, type = "dynamic", min_e = -5, max_e = 5)

# --- Primary outcome: Synthetic opioid (fentanyl) death rate (T40.4) ---
message("\n--- Synthetic opioid rate (T40.4) ---")
cs_synth <- att_gt(
  yname = "synth_opioid_rate",
  tname = "year",
  idname = "state_id",
  gname = "group",
  data = as.data.frame(panel[!is.na(synth_opioid_rate)]),
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)
agg_synth <- aggte(cs_synth, type = "simple")
message("Overall ATT (Synth opioid rate): ", round(agg_synth$overall.att, 3),
        " (SE: ", round(agg_synth$overall.se, 3), ")")

es_synth <- aggte(cs_synth, type = "dynamic", min_e = -5, max_e = 5)

# --- Heroin death rate (T40.1) ---
message("\n--- Heroin rate (T40.1) ---")
cs_heroin <- att_gt(
  yname = "heroin_rate",
  tname = "year",
  idname = "state_id",
  gname = "group",
  data = as.data.frame(panel[!is.na(heroin_rate)]),
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)
agg_heroin <- aggte(cs_heroin, type = "simple")
message("Overall ATT (Heroin rate): ", round(agg_heroin$overall.att, 3),
        " (SE: ", round(agg_heroin$overall.se, 3), ")")

es_heroin <- aggte(cs_heroin, type = "dynamic", min_e = -5, max_e = 5)

# --- Total opioid death rate ---
message("\n--- Total opioid rate ---")
cs_total_opioid <- att_gt(
  yname = "all_opioid_rate",
  tname = "year",
  idname = "state_id",
  gname = "group",
  data = as.data.frame(panel[!is.na(all_opioid_rate)]),
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)
agg_total_opioid <- aggte(cs_total_opioid, type = "simple")
message("Overall ATT (Total opioid rate): ", round(agg_total_opioid$overall.att, 3),
        " (SE: ", round(agg_total_opioid$overall.se, 3), ")")

es_total_opioid <- aggte(cs_total_opioid, type = "dynamic", min_e = -5, max_e = 5)

# --- Placebo: Cocaine death rate (T40.5) ---
message("\n--- Cocaine rate (placebo) ---")
cs_cocaine <- att_gt(
  yname = "cocaine_rate",
  tname = "year",
  idname = "state_id",
  gname = "group",
  data = as.data.frame(panel[!is.na(cocaine_rate)]),
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)
agg_cocaine <- aggte(cs_cocaine, type = "simple")
message("Overall ATT (Cocaine rate, placebo): ", round(agg_cocaine$overall.att, 3),
        " (SE: ", round(agg_cocaine$overall.se, 3), ")")

# --- Psychostimulant death rate (T43.6) — additional placebo ---
message("\n--- Psychostimulant rate (placebo) ---")
cs_psychostim <- att_gt(
  yname = "psychostim_rate",
  tname = "year",
  idname = "state_id",
  gname = "group",
  data = as.data.frame(panel[!is.na(psychostim_rate)]),
  control_group = "notyettreated",
  est_method = "dr",
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000
)
agg_psychostim <- aggte(cs_psychostim, type = "simple")
message("Overall ATT (Psychostim rate, placebo): ", round(agg_psychostim$overall.att, 3),
        " (SE: ", round(agg_psychostim$overall.se, 3), ")")

# ============================================================================
# 2. TWFE comparison (for reference / Bacon decomposition)
# ============================================================================
message("\n--- TWFE comparison ---")
twfe_rx <- feols(rx_opioid_rate ~ treated | state_id + year,
                 data = panel, cluster = ~state_id)
twfe_synth <- feols(synth_opioid_rate ~ treated | state_id + year,
                    data = panel, cluster = ~state_id)
twfe_heroin <- feols(heroin_rate ~ treated | state_id + year,
                     data = panel, cluster = ~state_id)

message("TWFE Rx opioid: ", round(coef(twfe_rx)["treated"], 3),
        " (SE: ", round(se(twfe_rx)["treated"], 3), ")")
message("TWFE Synth opioid: ", round(coef(twfe_synth)["treated"], 3),
        " (SE: ", round(se(twfe_synth)["treated"], 3), ")")

# ============================================================================
# 3. Save results
# ============================================================================
results <- list(
  cs_rx = cs_rx, agg_rx = agg_rx, es_rx = es_rx,
  cs_synth = cs_synth, agg_synth = agg_synth, es_synth = es_synth,
  cs_heroin = cs_heroin, agg_heroin = agg_heroin, es_heroin = es_heroin,
  cs_total_opioid = cs_total_opioid, agg_total_opioid = agg_total_opioid, es_total_opioid = es_total_opioid,
  cs_cocaine = cs_cocaine, agg_cocaine = agg_cocaine,
  cs_psychostim = cs_psychostim, agg_psychostim = agg_psychostim,
  twfe_rx = twfe_rx, twfe_synth = twfe_synth, twfe_heroin = twfe_heroin
)
saveRDS(results, "../data/main_results.rds")

# ============================================================================
# 4. Write diagnostics.json
# ============================================================================
diag <- list(
  n_treated = uniqueN(panel[group > 0, state_abbr]),
  n_pre = length(unique(panel$year[panel$year < min(panel$group[panel$group > 0])])),
  n_obs = nrow(panel),
  n_states = uniqueN(panel$state_abbr),
  n_years = uniqueN(panel$year),
  treatment_groups = sort(unique(panel$group[panel$group > 0])),
  att_rx_opioid = round(agg_rx$overall.att, 4),
  se_rx_opioid = round(agg_rx$overall.se, 4),
  att_synth_opioid = round(agg_synth$overall.att, 4),
  se_synth_opioid = round(agg_synth$overall.se, 4),
  att_heroin = round(agg_heroin$overall.att, 4),
  se_heroin = round(agg_heroin$overall.se, 4)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

message("\n=== Main analysis complete ===")
message("Results saved to data/main_results.rds")
message("Diagnostics saved to data/diagnostics.json")

# Print summary
cat("\n========== RESULTS SUMMARY ==========\n")
cat(sprintf("%-25s  %8s  %8s  %8s\n", "Outcome", "ATT", "SE", "p-value"))
cat(strrep("-", 55), "\n")
cat(sprintf("%-25s  %8.3f  %8.3f  %8.4f\n", "Rx opioid (T40.2)",
            agg_rx$overall.att, agg_rx$overall.se,
            2 * pnorm(-abs(agg_rx$overall.att / agg_rx$overall.se))))
cat(sprintf("%-25s  %8.3f  %8.3f  %8.4f\n", "Synth opioid (T40.4)",
            agg_synth$overall.att, agg_synth$overall.se,
            2 * pnorm(-abs(agg_synth$overall.att / agg_synth$overall.se))))
cat(sprintf("%-25s  %8.3f  %8.3f  %8.4f\n", "Heroin (T40.1)",
            agg_heroin$overall.att, agg_heroin$overall.se,
            2 * pnorm(-abs(agg_heroin$overall.att / agg_heroin$overall.se))))
cat(sprintf("%-25s  %8.3f  %8.3f  %8.4f\n", "Total opioid",
            agg_total_opioid$overall.att, agg_total_opioid$overall.se,
            2 * pnorm(-abs(agg_total_opioid$overall.att / agg_total_opioid$overall.se))))
cat(sprintf("%-25s  %8.3f  %8.3f  %8.4f\n", "Cocaine (placebo)",
            agg_cocaine$overall.att, agg_cocaine$overall.se,
            2 * pnorm(-abs(agg_cocaine$overall.att / agg_cocaine$overall.se))))
cat(sprintf("%-25s  %8.3f  %8.3f  %8.4f\n", "Psychostim (placebo)",
            agg_psychostim$overall.att, agg_psychostim$overall.se,
            2 * pnorm(-abs(agg_psychostim$overall.att / agg_psychostim$overall.se))))
cat("=====================================\n")
