## 03_main_analysis.R — Callaway-Sant'Anna DiD + TWFE diagnostics
## apep_0981: Good Samaritan Laws and Opioid Treatment Entry

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

cat("=== Panel loaded: %d obs, %d states ===\n", nrow(panel), uniqueN(panel$state))

# ============================================================================
# 1. TWFE BASELINE (diagnostic, not preferred)
# ============================================================================
cat("\n=== TWFE Baseline ===\n")

# Log buprenorphine prescriptions with state + year FEs
twfe_bup <- feols(log_bup_rx ~ treated | state_id + year, data = panel,
                   cluster = ~state_id)
cat("TWFE — Log buprenorphine Rx:\n")
print(summary(twfe_bup))

# Log opioid placebo with state + year FEs
twfe_opi <- feols(log_opioid_rx ~ treated | state_id + year, data = panel,
                   cluster = ~state_id)
cat("\nTWFE — Log opioid Rx (placebo):\n")
print(summary(twfe_opi))

# Per-capita rate
twfe_rate <- feols(log_bup_rate ~ treated | state_id + year, data = panel,
                    cluster = ~state_id)
cat("\nTWFE — Log bup rate/100K:\n")
print(summary(twfe_rate))

# ============================================================================
# 2. CALLAWAY-SANT'ANNA (PREFERRED ESTIMATOR)
# ============================================================================
cat("\n=== Callaway-Sant'Anna DiD ===\n")

# CS requires: yname, tname, idname, gname, data
# gname = first treatment year (0 = never treated)
# We use not-yet-treated as comparison (only 1 never-treated state)

cs_bup <- att_gt(
  yname = "log_bup_rx",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",  # doubly robust
  base_period = "universal"
)

cat("\nCS group-time ATTs (buprenorphine):\n")
print(summary(cs_bup))

# Aggregate to simple ATT
cs_att <- aggte(cs_bup, type = "simple")
cat("\n=== Simple ATT (buprenorphine) ===\n")
print(summary(cs_att))

# Dynamic event study
cs_es <- aggte(cs_bup, type = "dynamic", min_e = -6, max_e = 6)
cat("\n=== Event Study (buprenorphine) ===\n")
print(summary(cs_es))

# ============================================================================
# 3. MECHANISM TEST: OPIOID PLACEBO
# ============================================================================
cat("\n=== CS DiD — Opioid Placebo ===\n")

cs_opi <- att_gt(
  yname = "log_opioid_rx",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

cs_att_opi <- aggte(cs_opi, type = "simple")
cat("\nSimple ATT (opioid placebo):\n")
print(summary(cs_att_opi))

cs_es_opi <- aggte(cs_opi, type = "dynamic", min_e = -6, max_e = 6)
cat("\nEvent Study (opioid placebo):\n")
print(summary(cs_es_opi))

# ============================================================================
# 4. PER-CAPITA SPECIFICATION
# ============================================================================
cat("\n=== CS DiD — Bup rate per 100K ===\n")

cs_rate <- att_gt(
  yname = "log_bup_rate",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

cs_att_rate <- aggte(cs_rate, type = "simple")
cat("\nSimple ATT (bup rate/100K):\n")
print(summary(cs_att_rate))

# ============================================================================
# 5. SAVE RESULTS
# ============================================================================

# Store results for tables/SDE
results <- list(
  twfe_bup = twfe_bup,
  twfe_opi = twfe_opi,
  twfe_rate = twfe_rate,
  cs_bup = cs_bup,
  cs_att = cs_att,
  cs_es = cs_es,
  cs_opi = cs_opi,
  cs_att_opi = cs_att_opi,
  cs_es_opi = cs_es_opi,
  cs_rate = cs_rate,
  cs_att_rate = cs_att_rate
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

# Write diagnostics.json for validator
n_treated_states <- uniqueN(panel[first_treat > 0 & treated == 1, state])
n_pre_years <- length(unique(panel[first_treat == 2015 & year < 2015, year]))  # median cohort
n_obs <- nrow(panel)

write_json(
  list(
    n_treated = n_treated_states,
    n_pre = n_pre_years,
    n_obs = n_obs
  ),
  file.path(data_dir, "diagnostics.json"),
  auto_unbox = TRUE
)

cat(sprintf("\n=== DIAGNOSTICS ===\n"))
cat(sprintf("  n_treated: %d states\n", n_treated_states))
cat(sprintf("  n_pre: %d years (for 2015 cohort)\n", n_pre_years))
cat(sprintf("  n_obs: %d\n", n_obs))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
cat(sprintf("  CS ATT (bup Rx): %.3f (SE: %.3f)\n",
            cs_att$overall.att, cs_att$overall.se))
cat(sprintf("  CS ATT (opioid placebo): %.3f (SE: %.3f)\n",
            cs_att_opi$overall.att, cs_att_opi$overall.se))
