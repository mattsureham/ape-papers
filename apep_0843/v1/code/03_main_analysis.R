## 03_main_analysis.R — Callaway-Sant'Anna DiD estimation
## apep_0843: RON Laws and New Business Formation

source("00_packages.R")

panel <- readRDS("../data/panel_primary.rds")

# ------------------------------------------------------------------
# Create numeric state ID for did package
# ------------------------------------------------------------------
panel <- panel %>%
  mutate(state_id = as.integer(factor(state)))

cat("=== Running Callaway-Sant'Anna Estimation ===\n\n")

# ------------------------------------------------------------------
# 1. Main specification: log(BA) with never-treated control
# ------------------------------------------------------------------
cat("--- Model 1: log(Business Applications), never-treated control ---\n")

cs_ba <- att_gt(
  yname       = "log_BA",
  tname       = "time_index",
  idname      = "state_id",
  gname       = "first_treat",
  data        = panel,
  control_group = "nevertreated",
  anticipation  = 0,
  base_period   = "varying"
)

cat("ATT(g,t) estimation complete.\n")

# Simple aggregate ATT
agg_ba <- aggte(cs_ba, type = "simple")
cat("\nAggregate ATT (Business Applications):\n")
summary(agg_ba)

# Dynamic (event study) aggregation
es_ba <- aggte(cs_ba, type = "dynamic", min_e = -24, max_e = 12)
cat("\nEvent Study (Business Applications):\n")
summary(es_ba)

# ------------------------------------------------------------------
# 2. Corporate BA (notarization-intensive)
# ------------------------------------------------------------------
cat("\n--- Model 2: log(Corporate Business Applications) ---\n")

cs_cba <- att_gt(
  yname       = "log_CBA",
  tname       = "time_index",
  idname      = "state_id",
  gname       = "first_treat",
  data        = panel,
  control_group = "nevertreated",
  anticipation  = 0,
  base_period   = "varying"
)

agg_cba <- aggte(cs_cba, type = "simple")
cat("\nAggregate ATT (Corporate BA):\n")
summary(agg_cba)

es_cba <- aggte(cs_cba, type = "dynamic", min_e = -24, max_e = 12)

# ------------------------------------------------------------------
# 3. High-Propensity BA (less notarization-intensive)
# ------------------------------------------------------------------
cat("\n--- Model 3: log(High-Propensity BA) ---\n")

cs_hba <- att_gt(
  yname       = "log_HBA",
  tname       = "time_index",
  idname      = "state_id",
  gname       = "first_treat",
  data        = panel,
  control_group = "nevertreated",
  anticipation  = 0,
  base_period   = "varying"
)

agg_hba <- aggte(cs_hba, type = "simple")
cat("\nAggregate ATT (High-Propensity BA):\n")
summary(agg_hba)

es_hba <- aggte(cs_hba, type = "dynamic", min_e = -24, max_e = 12)

# ------------------------------------------------------------------
# 4. BA with Planned Wages
# ------------------------------------------------------------------
cat("\n--- Model 4: log(BA with Planned Wages) ---\n")

cs_wba <- att_gt(
  yname       = "log_WBA",
  tname       = "time_index",
  idname      = "state_id",
  gname       = "first_treat",
  data        = panel,
  control_group = "nevertreated",
  anticipation  = 0,
  base_period   = "varying"
)

agg_wba <- aggte(cs_wba, type = "simple")
cat("\nAggregate ATT (BA with Planned Wages):\n")
summary(agg_wba)

es_wba <- aggte(cs_wba, type = "dynamic", min_e = -24, max_e = 12)

# ------------------------------------------------------------------
# 5. TWFE baseline for comparison
# ------------------------------------------------------------------
cat("\n--- TWFE Baseline (for comparison with CS estimator) ---\n")

twfe_ba <- feols(
  log_BA ~ post | state_id + time_index,
  data = panel,
  cluster = ~state_id
)

twfe_cba <- feols(
  log_CBA ~ post | state_id + time_index,
  data = panel,
  cluster = ~state_id
)

cat("\nTWFE (Business Applications):\n")
summary(twfe_ba)

cat("\nTWFE (Corporate BA):\n")
summary(twfe_cba)

# ------------------------------------------------------------------
# Save all results
# ------------------------------------------------------------------
results <- list(
  cs_ba   = cs_ba,
  cs_cba  = cs_cba,
  cs_hba  = cs_hba,
  cs_wba  = cs_wba,
  agg_ba  = agg_ba,
  agg_cba = agg_cba,
  agg_hba = agg_hba,
  agg_wba = agg_wba,
  es_ba   = es_ba,
  es_cba  = es_cba,
  es_hba  = es_hba,
  es_wba  = es_wba,
  twfe_ba = twfe_ba,
  twfe_cba = twfe_cba
)

saveRDS(results, "../data/main_results.rds")

# ------------------------------------------------------------------
# Diagnostics for validate_v1.py
# ------------------------------------------------------------------
diag <- list(
  n_treated = n_distinct(panel$state_id[panel$treated_state]),
  n_pre = max(panel$time_index[panel$ym < min(panel$ron_ym[panel$treated_state], na.rm = TRUE)]) -
          min(panel$time_index) + 1,
  n_obs = nrow(panel)
)

write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics saved to data/diagnostics.json\n")
cat("  n_treated:", diag$n_treated, "\n")
cat("  n_pre:", diag$n_pre, "\n")
cat("  n_obs:", diag$n_obs, "\n")

cat("\n=== Main analysis complete ===\n")
