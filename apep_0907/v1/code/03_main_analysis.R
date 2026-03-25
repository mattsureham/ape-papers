## 03_main_analysis.R — Main DiD analysis
## apep_0907: The Digital Door to Food Stamps

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

# ============================================================
# 1. TWFE baseline (to show forbidden-comparison bias)
# ============================================================
cat("=== TWFE Baseline ===\n")

# Simple TWFE
twfe_base <- feols(snap_rate ~ treated | state_id + year, data = panel,
                   cluster = ~state_id)
cat("TWFE (no controls):\n")
summary(twfe_base)

# TWFE with policy controls
twfe_ctrl <- feols(snap_rate ~ treated + bbce + cap + faceini + facerec +
                     fingerprint + transben + outreach + reportsimple |
                     state_id + year,
                   data = panel, cluster = ~state_id)
cat("\nTWFE (with controls):\n")
summary(twfe_ctrl)

# ============================================================
# 2. Callaway-Sant'Anna (main specification)
# ============================================================
cat("\n=== Callaway-Sant'Anna ===\n")

# CS requires: yname, tname, idname, gname, data
# gname = first treatment period (0 for never-treated)

cs_out <- att_gt(
  yname = "snap_rate",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = panel,
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",  # Doubly robust
  base_period = "universal"
)

cat("CS group-time ATTs:\n")
summary(cs_out)

# Aggregate: overall ATT
cs_agg <- aggte(cs_out, type = "simple")
cat("\nCS Overall ATT:\n")
summary(cs_agg)

# Dynamic event study
cs_dynamic <- aggte(cs_out, type = "dynamic", min_e = -8, max_e = 10)
cat("\nCS Event Study:\n")
summary(cs_dynamic)

# Group-level aggregation
cs_group <- aggte(cs_out, type = "group")
cat("\nCS Group-level ATTs:\n")
summary(cs_group)

# ============================================================
# 3. CS with policy controls
# ============================================================
cat("\n=== CS with Controls ===\n")

cs_ctrl <- att_gt(
  yname = "snap_rate",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = panel,
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  xformla = ~ bbce + cap + faceini + facerec + fingerprint + transben,
  base_period = "universal"
)

cs_ctrl_agg <- aggte(cs_ctrl, type = "simple")
cat("CS with controls, Overall ATT:\n")
summary(cs_ctrl_agg)

cs_ctrl_dynamic <- aggte(cs_ctrl, type = "dynamic", min_e = -8, max_e = 10)

# ============================================================
# 4. CS with not-yet-treated comparison group
# ============================================================
cat("\n=== CS (not-yet-treated) ===\n")

cs_nyt <- att_gt(
  yname = "snap_rate",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = panel,
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

cs_nyt_agg <- aggte(cs_nyt, type = "simple")
cat("CS (not-yet-treated), Overall ATT:\n")
summary(cs_nyt_agg)

# ============================================================
# 5. Log specification
# ============================================================
cat("\n=== Log Specification ===\n")

cs_log <- att_gt(
  yname = "log_snap",
  tname = "year",
  idname = "state_id",
  gname = "first_treat",
  data = panel,
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

cs_log_agg <- aggte(cs_log, type = "simple")
cat("CS Log ATT:\n")
summary(cs_log_agg)

# ============================================================
# 6. Save results
# ============================================================
results <- list(
  twfe_base = twfe_base,
  twfe_ctrl = twfe_ctrl,
  cs_out = cs_out,
  cs_agg = cs_agg,
  cs_dynamic = cs_dynamic,
  cs_group = cs_group,
  cs_ctrl = cs_ctrl,
  cs_ctrl_agg = cs_ctrl_agg,
  cs_ctrl_dynamic = cs_ctrl_dynamic,
  cs_nyt = cs_nyt,
  cs_nyt_agg = cs_nyt_agg,
  cs_log = cs_log,
  cs_log_agg = cs_log_agg
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

# ============================================================
# 7. Diagnostics for validation
# ============================================================
n_treated_states <- sum(panel$first_treat > 0) / length(unique(panel$year[panel$first_treat > 0]))
n_pre_min <- min(panel$first_treat[panel$first_treat > 0]) - min(panel$year)

diagnostics <- list(
  n_treated = length(unique(panel$state_id[panel$first_treat > 0])),
  n_pre = as.integer(n_pre_min),
  n_obs = nrow(panel),
  n_states = n_distinct(panel$state_id),
  n_years = n_distinct(panel$year),
  att_estimate = cs_agg$overall.att,
  att_se = cs_agg$overall.se,
  twfe_estimate = coef(twfe_base)["treated"],
  twfe_se = sqrt(diag(vcov(twfe_base)))["treated"]
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Main analysis complete ===\n")
cat("CS ATT:", round(cs_agg$overall.att, 2), "(SE:", round(cs_agg$overall.se, 2), ")\n")
cat("TWFE:", round(coef(twfe_base)["treated"], 2),
    "(SE:", round(sqrt(diag(vcov(twfe_base)))["treated"], 2), ")\n")
cat("Diagnostics saved.\n")
