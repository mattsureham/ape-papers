# 03_main_analysis.R — Callaway-Sant'Anna DiD analysis
# APEP Working Paper apep_0917

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "panel_clean.rds"))

# ============================================================
# Prepare for CS-DiD
# ============================================================
# The `did` package requires gname where 0 = never treated
# Our reform_year already uses 0 for never-reformed states
cat("Cohort distribution:\n")
print(table(panel[, .(reform_year)][, .(n = .N), by = reform_year][order(reform_year)]))

# Number of agencies per cohort
cat("\nAgencies per cohort:\n")
agency_cohort <- unique(panel[, .(agency_id, NCIC_ST, reform_year)])
print(table(agency_cohort$reform_year))

# ============================================================
# 1. TWFE baseline (for comparison — known to be biased with het. effects)
# ============================================================
cat("\n=== TWFE ESTIMATES ===\n")

twfe_asinh <- feols(asinh_es_revenue ~ post_reform | agency_id + FORM_FY,
                     data = panel, cluster = "NCIC_ST")
cat("TWFE (asinh ES revenue):\n")
print(summary(twfe_asinh))

twfe_ext <- feols(has_es_revenue ~ post_reform | agency_id + FORM_FY,
                   data = panel, cluster = "NCIC_ST")
cat("\nTWFE (extensive margin — any ES revenue):\n")
print(summary(twfe_ext))

# ============================================================
# 2. Callaway-Sant'Anna Group-Time ATT
# ============================================================
cat("\n=== CALLAWAY-SANT'ANNA ESTIMATES ===\n")

# Main specification: asinh(ES revenue), never-treated comparison
cs_main <- att_gt(
  yname = "asinh_es_revenue",
  tname = "FORM_FY",
  idname = "agency_id",
  gname = "reform_year",
  data = as.data.frame(panel),
  control_group = "nevertreated",
  clustervars = "NCIC_ST",
  allow_unbalanced_panel = TRUE,
  bstrap = TRUE,
  biters = 1000
)
cat("Group-time ATTs estimated.\n")

# Aggregate: simple ATT
agg_simple <- aggte(cs_main, type = "simple")
cat("\nSimple ATT (overall):\n")
print(summary(agg_simple))

# Aggregate: dynamic (event-study)
agg_dynamic <- aggte(cs_main, type = "dynamic", min_e = -4, max_e = 6)
cat("\nDynamic (event-study) ATT:\n")
print(summary(agg_dynamic))

# Aggregate: group-level
agg_group <- aggte(cs_main, type = "group")
cat("\nGroup-level ATT:\n")
print(summary(agg_group))

# ============================================================
# 3. Extensive margin: any ES revenue
# ============================================================
cat("\n=== EXTENSIVE MARGIN ===\n")

cs_ext <- att_gt(
  yname = "has_es_revenue",
  tname = "FORM_FY",
  idname = "agency_id",
  gname = "reform_year",
  data = as.data.frame(panel),
  control_group = "nevertreated",
  clustervars = "NCIC_ST",
  allow_unbalanced_panel = TRUE,
  bstrap = TRUE,
  biters = 1000
)

agg_ext_simple <- aggte(cs_ext, type = "simple")
cat("Extensive margin ATT:\n")
print(summary(agg_ext_simple))

agg_ext_dynamic <- aggte(cs_ext, type = "dynamic", min_e = -4, max_e = 6)
cat("Extensive margin event study:\n")
print(summary(agg_ext_dynamic))

# ============================================================
# 4. Heterogeneity: Strong vs Weak reform
# ============================================================
cat("\n=== HETEROGENEITY: STRONG vs WEAK REFORM ===\n")

# Strong: abolish + conviction required
panel_strong <- panel[reform_year == 0 | strong_reform == TRUE]
panel_weak   <- panel[reform_year == 0 | strong_reform == FALSE]

cat("Strong reform panel:", nrow(panel_strong), "obs,",
    length(unique(panel_strong$NCIC_ST)), "states\n")
cat("Weak reform panel:", nrow(panel_weak), "obs,",
    length(unique(panel_weak$NCIC_ST)), "states\n")

cs_strong <- att_gt(
  yname = "asinh_es_revenue",
  tname = "FORM_FY", idname = "agency_id", gname = "reform_year",
  data = as.data.frame(panel_strong),
  control_group = "nevertreated",
  clustervars = "NCIC_ST",
  allow_unbalanced_panel = TRUE,
  bstrap = TRUE, biters = 1000
)
agg_strong <- aggte(cs_strong, type = "simple")
cat("Strong reform ATT:\n")
print(summary(agg_strong))

cs_weak <- att_gt(
  yname = "asinh_es_revenue",
  tname = "FORM_FY", idname = "agency_id", gname = "reform_year",
  data = as.data.frame(panel_weak),
  control_group = "nevertreated",
  clustervars = "NCIC_ST",
  allow_unbalanced_panel = TRUE,
  bstrap = TRUE, biters = 1000
)
agg_weak <- aggte(cs_weak, type = "simple")
cat("Weak reform ATT:\n")
print(summary(agg_weak))

# ============================================================
# 5. Heterogeneity: Anti-circumvention laws
# ============================================================
cat("\n=== HETEROGENEITY: ANTI-CIRCUMVENTION ===\n")

panel_anticirc <- panel[reform_year == 0 | anti_circumvention == TRUE]
panel_no_anticirc <- panel[reform_year > 0 & anti_circumvention == FALSE |
                            reform_year == 0]

cat("Anti-circumvention panel:", nrow(panel_anticirc), "obs,",
    length(unique(panel_anticirc$NCIC_ST)), "states\n")
cat("No anti-circumvention panel:", nrow(panel_no_anticirc), "obs,",
    length(unique(panel_no_anticirc$NCIC_ST)), "states\n")

cs_anticirc <- att_gt(
  yname = "asinh_es_revenue",
  tname = "FORM_FY", idname = "agency_id", gname = "reform_year",
  data = as.data.frame(panel_anticirc),
  control_group = "nevertreated",
  clustervars = "NCIC_ST",
  allow_unbalanced_panel = TRUE,
  bstrap = TRUE, biters = 1000
)
agg_anticirc <- aggte(cs_anticirc, type = "simple")
cat("Anti-circumvention ATT:\n")
print(summary(agg_anticirc))

cs_no_anticirc <- att_gt(
  yname = "asinh_es_revenue",
  tname = "FORM_FY", idname = "agency_id", gname = "reform_year",
  data = as.data.frame(panel_no_anticirc),
  control_group = "nevertreated",
  clustervars = "NCIC_ST",
  allow_unbalanced_panel = TRUE,
  bstrap = TRUE, biters = 1000
)
agg_no_anticirc <- aggte(cs_no_anticirc, type = "simple")
cat("No anti-circumvention ATT:\n")
print(summary(agg_no_anticirc))

# ============================================================
# Save all results
# ============================================================
results <- list(
  twfe_asinh = twfe_asinh,
  twfe_ext = twfe_ext,
  cs_main = cs_main,
  agg_simple = agg_simple,
  agg_dynamic = agg_dynamic,
  agg_group = agg_group,
  cs_ext = cs_ext,
  agg_ext_simple = agg_ext_simple,
  agg_ext_dynamic = agg_ext_dynamic,
  cs_strong = cs_strong,
  agg_strong = agg_strong,
  cs_weak = cs_weak,
  agg_weak = agg_weak,
  cs_anticirc = cs_anticirc,
  agg_anticirc = agg_anticirc,
  cs_no_anticirc = cs_no_anticirc,
  agg_no_anticirc = agg_no_anticirc
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

# ============================================================
# Diagnostics for validation
# ============================================================
n_treated_states <- length(unique(panel[reform_year > 0, NCIC_ST]))
# Pre-periods: count FYs before the LATEST cohort (2021) — gives max pre-periods
latest_cohort <- max(panel[reform_year > 0, reform_year])
n_pre <- length(unique(panel[FORM_FY < latest_cohort, FORM_FY]))
diag_list <- list(
  n_treated = n_treated_states,
  n_pre = n_pre,
  n_obs = nrow(panel),
  n_agencies = length(unique(panel$agency_id)),
  n_states = length(unique(panel$NCIC_ST)),
  n_fy = length(unique(panel$FORM_FY)),
  att_overall = agg_simple$overall.att,
  att_se = agg_simple$overall.se
)
write_json(diag_list, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")

cat("\n=== SUMMARY ===\n")
cat("Overall ATT (asinh ES revenue):", round(agg_simple$overall.att, 4),
    "(SE:", round(agg_simple$overall.se, 4), ")\n")
cat("Extensive margin ATT:", round(agg_ext_simple$overall.att, 4),
    "(SE:", round(agg_ext_simple$overall.se, 4), ")\n")
cat("Strong reform ATT:", round(agg_strong$overall.att, 4),
    "(SE:", round(agg_strong$overall.se, 4), ")\n")
cat("Weak reform ATT:", round(agg_weak$overall.att, 4),
    "(SE:", round(agg_weak$overall.se, 4), ")\n")
cat("MAIN ANALYSIS COMPLETE\n")
