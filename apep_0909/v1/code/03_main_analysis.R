# 03_main_analysis.R — Main event study analysis
# PCC Electoral Cycles and Crime Investigation Quality (apep_0909)
#
# Key insight: All PCC forces have elections simultaneously, so event time is
# collinear with calendar time within PCC forces alone. We use the Metropolitan
# Police and City of London (which never had PCC elections) as controls in a
# DiD event study: PCC × event_time interaction.

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# 1. Load and fix data
# ============================================================================
force_quarter <- readRDS(file.path(data_dir, "force_quarter.rds"))
force_quarter[force_name == "London, City of", pcc := 0L]

cat(sprintf("PCC forces: %d\n", uniqueN(force_quarter[pcc == 1]$force_name)))
cat(sprintf("Non-PCC forces: %d (%s)\n",
            uniqueN(force_quarter[pcc == 0]$force_name),
            paste(unique(force_quarter[pcc == 0]$force_name), collapse = ", ")))

# ============================================================================
# 2. Create election timing
# ============================================================================
# PCC Elections: Nov 2012, May 2016, May 2021, May 2024
# yq values: 2012.75, 2016.25, 2021.25, 2024.25
election_yqs <- c(2012.75, 2016.25, 2021.25, 2024.25)

# For each quarter, compute distance to nearest election
force_quarter[, quarters_to_nearest := {
  dists <- sapply(election_yqs, function(e) round((yq - e) * 4))
  apply(dists, 1, function(d) d[which.min(abs(d))])
}]

force_quarter[, nearest_election_idx := {
  dists <- sapply(election_yqs, function(e) abs(round((yq - e) * 4)))
  apply(dists, 1, which.min)
}]

# ============================================================================
# 3. Stacked DiD Event Study: PCC vs non-PCC
# ============================================================================
cat("\n=== Building stacked event study dataset ===\n")

# Create stacked dataset: each election is a separate cohort
# Include both PCC and non-PCC forces in each cohort
stacked_list <- list()

for (idx in 2:4) {  # Elections 2-4 (Election 1 is before our data)
  e_yq <- election_yqs[idx]
  # Window: 8 quarters before to 7 quarters after
  dt_e <- force_quarter[
    round((yq - e_yq) * 4) >= -8 & round((yq - e_yq) * 4) <= 7
  ]
  dt_e <- copy(dt_e)
  dt_e[, cohort := idx]
  dt_e[, event_time := round((yq - e_yq) * 4)]
  dt_e[, cohort_force := paste0(force_name, "_c", idx)]
  dt_e[, cohort_yq := paste0(yq, "_c", idx)]
  stacked_list[[idx]] <- dt_e
}

stacked <- rbindlist(stacked_list)
cat(sprintf("Stacked dataset: %d rows, %d elections\n",
            nrow(stacked), uniqueN(stacked$cohort)))

# ============================================================================
# 4. Primary specification: DiD event study
# ============================================================================
cat("\n=== PRIMARY: DiD Event Study — Charge Rate ===\n")

# Specification: Y_{f,q,c} = α_{f,c} + γ_{q,c} + Σ_k β_k × PCC_f × 1[k] + ε
# Reference: event_time = -5 (5 quarters before election)
# PCC × event_time interaction: differential change for PCC vs non-PCC forces

es_charge <- feols(
  charged_rate ~ i(event_time, pcc, ref = -5) | cohort_force + cohort_yq,
  data = stacked,
  cluster = ~force_name
)
cat("DiD Event Study — Charge rate:\n")
summary(es_charge)

cat("\n=== PRIMARY: DiD Event Study — No Suspect Rate ===\n")

es_nosuspect <- feols(
  no_suspect_rate ~ i(event_time, pcc, ref = -5) | cohort_force + cohort_yq,
  data = stacked,
  cluster = ~force_name
)
cat("DiD Event Study — No suspect identified rate:\n")
summary(es_nosuspect)

cat("\n=== PRIMARY: DiD Event Study — Evidential Difficulties Rate ===\n")

es_evid <- feols(
  evid_diff_rate ~ i(event_time, pcc, ref = -5) | cohort_force + cohort_yq,
  data = stacked,
  cluster = ~force_name
)
cat("DiD Event Study — Evidential difficulties rate:\n")
summary(es_evid)

# ============================================================================
# 5. Pooled DiD: pre-election and post-election effects
# ============================================================================
cat("\n=== POOLED DiD: Pre/Post election effects ===\n")

stacked[, pre_elect := fifelse(event_time >= -4 & event_time <= -1, 1L, 0L)]
stacked[, post_elect := fifelse(event_time >= 0 & event_time <= 3, 1L, 0L)]

# PCC × pre-election interaction
stacked[, pcc_pre := pcc * pre_elect]
stacked[, pcc_post := pcc * post_elect]

pooled_charge <- feols(
  charged_rate ~ pcc_pre + pcc_post | cohort_force + cohort_yq,
  data = stacked,
  cluster = ~force_name
)
cat("Pooled DiD — Charge rate:\n")
summary(pooled_charge)

pooled_nosuspect <- feols(
  no_suspect_rate ~ pcc_pre + pcc_post | cohort_force + cohort_yq,
  data = stacked,
  cluster = ~force_name
)
cat("\nPooled DiD — No suspect rate:\n")
summary(pooled_nosuspect)

pooled_evid <- feols(
  evid_diff_rate ~ pcc_pre + pcc_post | cohort_force + cohort_yq,
  data = stacked,
  cluster = ~force_name
)
cat("\nPooled DiD — Evidential difficulties rate:\n")
summary(pooled_evid)

# ============================================================================
# 6. Election-by-election analysis
# ============================================================================
cat("\n=== Election-by-election effects ===\n")

for (idx in 2:4) {
  cat(sprintf("\n--- Election %d (%.0f) ---\n", idx, election_yqs[idx]))
  dt_e <- stacked[cohort == idx]

  # Pre/Post effect
  dt_e[, pcc_pre := pcc * pre_elect]
  dt_e[, pcc_post := pcc * post_elect]

  m <- feols(
    charged_rate ~ pcc_pre + pcc_post | force_name + yq,
    data = dt_e,
    cluster = ~force_name
  )
  cat(sprintf("  Charge rate: pre = %.4f (se=%.4f), post = %.4f (se=%.4f)\n",
              coef(m)["pcc_pre"], se(m)["pcc_pre"],
              coef(m)["pcc_post"], se(m)["pcc_post"]))

  m2 <- feols(
    no_suspect_rate ~ pcc_pre + pcc_post | force_name + yq,
    data = dt_e,
    cluster = ~force_name
  )
  cat(sprintf("  No suspect rate: pre = %.4f (se=%.4f), post = %.4f (se=%.4f)\n",
              coef(m2)["pcc_pre"], se(m2)["pcc_pre"],
              coef(m2)["pcc_post"], se(m2)["pcc_post"]))
}

# ============================================================================
# 7. Total crime volume placebo
# ============================================================================
cat("\n=== Placebo: Total crime volume ===\n")

# If the election cycle affects investigation quality, not crime itself,
# total crime volume should NOT show the same pattern
stacked[, log_total := log(total_outcomes + 1)]

placebo_volume <- feols(
  log_total ~ pcc_pre + pcc_post | cohort_force + cohort_yq,
  data = stacked,
  cluster = ~force_name
)
cat("Placebo — Total crime volume (log):\n")
summary(placebo_volume)

# ============================================================================
# 8. Save results and diagnostics
# ============================================================================
results <- list(
  es_charge = es_charge,
  es_nosuspect = es_nosuspect,
  es_evid = es_evid,
  pooled_charge = pooled_charge,
  pooled_nosuspect = pooled_nosuspect,
  pooled_evid = pooled_evid,
  placebo_volume = placebo_volume
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# Diagnostics for validator
n_pcc_forces <- uniqueN(stacked[pcc == 1]$force_name)
n_quarters <- uniqueN(stacked$yq)
n_obs <- nrow(stacked)

diag <- list(
  n_treated = n_pcc_forces,
  n_pre = 8L,
  n_obs = n_obs
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))

# Print key summary statistics
cat("\n=== Key summary statistics ===\n")
cat(sprintf("Mean charge rate (PCC): %.4f\n",
            mean(stacked[pcc == 1]$charged_rate, na.rm = TRUE)))
cat(sprintf("Mean charge rate (non-PCC): %.4f\n",
            mean(stacked[pcc == 0]$charged_rate, na.rm = TRUE)))
cat(sprintf("SD charge rate: %.4f\n",
            sd(stacked$charged_rate, na.rm = TRUE)))
cat(sprintf("Mean no-suspect rate (PCC): %.4f\n",
            mean(stacked[pcc == 1]$no_suspect_rate, na.rm = TRUE)))
cat(sprintf("Mean no-suspect rate (non-PCC): %.4f\n",
            mean(stacked[pcc == 0]$no_suspect_rate, na.rm = TRUE)))
cat(sprintf("SD no-suspect rate: %.4f\n",
            sd(stacked$no_suspect_rate, na.rm = TRUE)))

cat("\n=== Main analysis complete ===\n")
