# 03_main_analysis.R — Main DiD analysis for apep_0974

source("00_packages.R")

panel <- arrow::read_parquet("../data/panel.parquet")
cat(sprintf("Panel loaded: %d obs, %d states, %s to %s\n",
            nrow(panel), n_distinct(panel$state),
            min(panel$CLAIM_FROM_MONTH), max(panel$CLAIM_FROM_MONTH)))

# =============================================================================
# 1. TWFE baseline (for comparison — known to be biased with staggered treatment)
# =============================================================================
cat("\n=== TWFE Regressions ===\n")

# Main outcome: ED share
twfe_share <- feols(ed_share ~ post_ea | state + year_month, data = panel,
                     cluster = ~state)

# Log ED claims
twfe_ed <- feols(log_ed_claims ~ post_ea | state + year_month, data = panel,
                  cluster = ~state)

# Log PC claims
twfe_pc <- feols(log_pc_claims ~ post_ea | state + year_month, data = panel,
                  cluster = ~state)

# High-acuity ED share
twfe_acuity <- feols(ed_high_share ~ post_ea | state + year_month, data = panel,
                      cluster = ~state)

cat("TWFE ED share:\n")
print(summary(twfe_share))
cat("\nTWFE log ED:\n")
print(summary(twfe_ed))
cat("\nTWFE log PC:\n")
print(summary(twfe_pc))

# =============================================================================
# 2. Callaway-Sant'Anna (2021) — Staggered DiD
# =============================================================================
cat("\n=== Callaway-Sant'Anna DiD ===\n")

# Prepare data for CS: needs numeric id, time, group
cs_data <- panel |>
  mutate(
    state_id = as.integer(as.factor(state)),
    # CS requires group = first treatment period, 0 for never-treated
    g = first_treat
  )

# Main outcome: ED share
cs_share <- att_gt(
  yname = "ed_share",
  tname = "year_month",
  idname = "state_id",
  gname = "g",
  data = cs_data,
  control_group = "nevertreated",
  base_period = "universal"
)

# Aggregate: simple ATT
agg_simple <- aggte(cs_share, type = "simple")
cat("\nCS-DiD ATT (ED share):\n")
print(summary(agg_simple))

# Aggregate: dynamic/event study
agg_dynamic <- aggte(cs_share, type = "dynamic", min_e = -24, max_e = 24)
cat("\nCS-DiD Event Study (ED share):\n")
print(summary(agg_dynamic))

# Log ED claims
cs_ed <- att_gt(
  yname = "log_ed_claims",
  tname = "year_month",
  idname = "state_id",
  gname = "g",
  data = cs_data,
  control_group = "nevertreated",
  base_period = "universal"
)
agg_ed <- aggte(cs_ed, type = "simple")
cat("\nCS-DiD ATT (log ED claims):\n")
print(summary(agg_ed))

agg_ed_dyn <- aggte(cs_ed, type = "dynamic", min_e = -24, max_e = 24)

# Log PC claims
cs_pc <- att_gt(
  yname = "log_pc_claims",
  tname = "year_month",
  idname = "state_id",
  gname = "g",
  data = cs_data,
  control_group = "nevertreated",
  base_period = "universal"
)
agg_pc <- aggte(cs_pc, type = "simple")
cat("\nCS-DiD ATT (log PC claims):\n")
print(summary(agg_pc))

agg_pc_dyn <- aggte(cs_pc, type = "dynamic", min_e = -24, max_e = 24)

# High-acuity share
cs_acuity <- att_gt(
  yname = "ed_high_share",
  tname = "year_month",
  idname = "state_id",
  gname = "g",
  data = cs_data,
  control_group = "nevertreated",
  base_period = "universal"
)
agg_acuity <- aggte(cs_acuity, type = "simple")
cat("\nCS-DiD ATT (ED high-acuity share):\n")
print(summary(agg_acuity))

agg_acuity_dyn <- aggte(cs_acuity, type = "dynamic", min_e = -24, max_e = 24)

# ED per provider (workload)
cs_workload <- att_gt(
  yname = "ed_per_provider",
  tname = "year_month",
  idname = "state_id",
  gname = "g",
  data = cs_data,
  control_group = "nevertreated",
  base_period = "universal"
)
agg_workload <- aggte(cs_workload, type = "simple")
cat("\nCS-DiD ATT (ED claims per provider):\n")
print(summary(agg_workload))

# =============================================================================
# 3. Save results
# =============================================================================

# Save CS objects for event study plots and tables
results <- list(
  twfe_share = twfe_share,
  twfe_ed = twfe_ed,
  twfe_pc = twfe_pc,
  twfe_acuity = twfe_acuity,
  cs_share = cs_share,
  cs_ed = cs_ed,
  cs_pc = cs_pc,
  cs_acuity = cs_acuity,
  cs_workload = cs_workload,
  agg_simple = agg_simple,
  agg_ed = agg_ed,
  agg_pc = agg_pc,
  agg_acuity = agg_acuity,
  agg_workload = agg_workload,
  agg_dynamic = agg_dynamic,
  agg_ed_dyn = agg_ed_dyn,
  agg_pc_dyn = agg_pc_dyn,
  agg_acuity_dyn = agg_acuity_dyn
)

saveRDS(results, "../data/main_results.rds")

# Pre-treatment SD for SDE calculations
pre_panel <- panel |> filter(CLAIM_FROM_MONTH < "2021-04")
sd_ed_share <- sd(pre_panel$ed_share, na.rm = TRUE)
sd_log_ed <- sd(pre_panel$log_ed_claims, na.rm = TRUE)
sd_log_pc <- sd(pre_panel$log_pc_claims, na.rm = TRUE)
sd_ed_high_share <- sd(pre_panel$ed_high_share, na.rm = TRUE)
sd_ed_per_provider <- sd(pre_panel$ed_per_provider, na.rm = TRUE)

sde_info <- list(
  sd_ed_share = sd_ed_share,
  sd_log_ed = sd_log_ed,
  sd_log_pc = sd_log_pc,
  sd_ed_high_share = sd_ed_high_share,
  sd_ed_per_provider = sd_ed_per_provider
)
saveRDS(sde_info, "../data/sde_info.rds")

cat(sprintf("\nPre-treatment SDs: ed_share=%.4f, log_ed=%.4f, log_pc=%.4f\n",
            sd_ed_share, sd_log_ed, sd_log_pc))

# =============================================================================
# 4. Diagnostics for validate_v1.py
# =============================================================================
# All 51 states eventually lose EA; 18 early + 33 late (March 2023)
# Using not-yet-treated control, all states are treated units
n_treated <- n_distinct(panel$state)
n_pre <- length(unique(panel$year_month[panel$CLAIM_FROM_MONTH < "2021-04"]))
n_obs <- nrow(panel)

jsonlite::write_json(list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
), "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n", n_treated, n_pre, n_obs))
cat("Main analysis complete.\n")
