## 03_main_analysis.R — Main DiD estimation
## apep_1169: Click to Incorporate

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")
cat("Panel loaded:", nrow(panel), "rows,", length(unique(panel$state)), "states\n")

# ============================================================
# A) Callaway-Sant'Anna — WBA (primary, complete coverage)
# ============================================================

cat("\n=== CS DiD: Wage-Planned Applications (WBA) ===\n")
cs_wba <- att_gt(
  yname = "log_WBA",
  tname = "ym",
  idname = "state_id",
  gname = "first_treat",
  data = panel,
  control_group = "nevertreated",
  base_period = "universal",
  clustervars = "state_id",
  print_details = FALSE
)

es_wba <- aggte(cs_wba, type = "dynamic", min_e = -24, max_e = 24)
att_wba <- aggte(cs_wba, type = "simple")
cat("ATT (WBA):", round(att_wba$overall.att, 4),
    " SE:", round(att_wba$overall.se, 4), "\n")

# ---- CBA (corporate applications — mechanism test) ----
cat("\n=== CS DiD: Corporate Applications (CBA) ===\n")
cs_cba <- att_gt(
  yname = "log_CBA",
  tname = "ym",
  idname = "state_id",
  gname = "first_treat",
  data = panel,
  control_group = "nevertreated",
  base_period = "universal",
  clustervars = "state_id",
  print_details = FALSE
)

es_cba <- aggte(cs_cba, type = "dynamic", min_e = -24, max_e = 24)
att_cba <- aggte(cs_cba, type = "simple")
cat("ATT (CBA):", round(att_cba$overall.att, 4),
    " SE:", round(att_cba$overall.se, 4), "\n")

# ---- BA (total — may have some state gaps, use panel=FALSE) ----
cat("\n=== CS DiD: All Business Applications (BA) ===\n")
panel_ba <- panel %>% filter(!is.na(BA) & BA > 0)
cs_ba <- att_gt(
  yname = "log_BA",
  tname = "ym",
  idname = "state_id",
  gname = "first_treat",
  data = panel_ba,
  control_group = "nevertreated",
  base_period = "universal",
  clustervars = "state_id",
  panel = FALSE,
  print_details = FALSE
)

es_ba <- aggte(cs_ba, type = "dynamic", min_e = -24, max_e = 24)
att_ba <- aggte(cs_ba, type = "simple")
cat("ATT (BA):", round(att_ba$overall.att, 4),
    " SE:", round(att_ba$overall.se, 4), "\n")

# ---- HBA ----
cat("\n=== CS DiD: High-Propensity Applications (HBA) ===\n")
panel_hba <- panel %>% filter(!is.na(HBA) & HBA > 0)
cs_hba <- att_gt(
  yname = "log_HBA",
  tname = "ym",
  idname = "state_id",
  gname = "first_treat",
  data = panel_hba,
  control_group = "nevertreated",
  base_period = "universal",
  clustervars = "state_id",
  panel = FALSE,
  print_details = FALSE
)

es_hba <- aggte(cs_hba, type = "dynamic", min_e = -24, max_e = 24)
att_hba <- aggte(cs_hba, type = "simple")
cat("ATT (HBA):", round(att_hba$overall.att, 4),
    " SE:", round(att_hba$overall.se, 4), "\n")

# ============================================================
# B) TWFE for comparison
# ============================================================

cat("\n=== TWFE ===\n")
twfe_wba <- feols(log_WBA ~ treated | state_id + ym, data = panel, cluster = ~state_id)
twfe_cba <- feols(log_CBA ~ treated | state_id + ym, data = panel, cluster = ~state_id)
twfe_ba <- feols(log_BA ~ treated | state_id + ym, data = panel_ba, cluster = ~state_id)
twfe_hba <- feols(log_HBA ~ treated | state_id + ym, data = panel_hba, cluster = ~state_id)

cat("TWFE WBA:", round(coef(twfe_wba)["treated"], 4), "\n")
cat("TWFE CBA:", round(coef(twfe_cba)["treated"], 4), "\n")
cat("TWFE BA:", round(coef(twfe_ba)["treated"], 4), "\n")
cat("TWFE HBA:", round(coef(twfe_hba)["treated"], 4), "\n")

# ============================================================
# Save results
# ============================================================

results <- list(
  cs_wba = cs_wba, cs_cba = cs_cba, cs_ba = cs_ba, cs_hba = cs_hba,
  es_wba = es_wba, es_cba = es_cba, es_ba = es_ba, es_hba = es_hba,
  att_wba = att_wba, att_cba = att_cba, att_ba = att_ba, att_hba = att_hba,
  twfe_wba = twfe_wba, twfe_cba = twfe_cba, twfe_ba = twfe_ba, twfe_hba = twfe_hba
)
saveRDS(results, "../data/main_results.rds")

# ---- Diagnostics JSON ----
diag <- list(
  n_treated = length(unique(panel$state[panel$treated_state])),
  n_pre = length(unique(panel$ym[panel$ym < min(panel$launch_ym[panel$treated_state])])),
  n_obs = nrow(panel)
)
write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics:", toJSON(diag, auto_unbox = TRUE), "\n")
cat("MAIN ANALYSIS COMPLETE.\n")
