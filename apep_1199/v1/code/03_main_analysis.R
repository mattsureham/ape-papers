# ─────────────────────────────────────────────
# 03_main_analysis.R — Main DiD analysis using Callaway-Sant'Anna
# ─────────────────────────────────────────────

source("00_packages.R")

DATA_DIR <- file.path(dirname(getwd()), "data")
TABLE_DIR <- file.path(dirname(getwd()), "tables")
if (!dir.exists(TABLE_DIR)) dir.create(TABLE_DIR, recursive = TRUE)

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"),
               colClasses = c(muni_code = "character"))

cat("Panel loaded:", nrow(panel), "observations,",
    uniqueN(panel$muni_code), "municipalities\n")

# ─────────────────────────────────────────────
# 1. Cohort sizes and treatment rollout
# ─────────────────────────────────────────────
cat("\n=== Treatment Rollout ===\n")
cohort_tab <- panel[, .(n = uniqueN(muni_code)), by = treatment_year]
print(cohort_tab[order(treatment_year)])

# Create numeric municipality ID (required by did::att_gt)
panel[, muni_id := as.integer(factor(muni_code))]

# ─────────────────────────────────────────────
# 2. Callaway-Sant'Anna ATT(g,t) estimation
# ─────────────────────────────────────────────
cat("\n=== Callaway-Sant'Anna Estimation ===\n")

# Primary specification: waterborne hospitalization rate
cs_out <- att_gt(
  yname = "hosp_rate_w",
  tname = "year",
  idname = "muni_id",
  gname = "treatment_year",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 1,
  est_method = "dr",      # Doubly robust (IPW + outcome regression)
  base_period = "universal",
  clustervars = "muni_id",
  print_details = FALSE
)

cat("\n--- ATT(g,t) Summary ---\n")
summary(cs_out)

# ─────────────────────────────────────────────
# 3. Aggregate to overall ATT
# ─────────────────────────────────────────────
cat("\n=== Aggregated Treatment Effects ===\n")

# Simple aggregate (weighted average across groups and time)
agg_simple <- aggte(cs_out, type = "simple")
cat("\n--- Simple ATT ---\n")
summary(agg_simple)

# Dynamic (event study) aggregate
agg_dynamic <- aggte(cs_out, type = "dynamic", min_e = -5, max_e = 3)
cat("\n--- Dynamic ATT (event study) ---\n")
summary(agg_dynamic)

# Group-specific ATT
agg_group <- aggte(cs_out, type = "group")
cat("\n--- Group-specific ATT ---\n")
summary(agg_group)

# ─────────────────────────────────────────────
# 4. Store results for tables
# ─────────────────────────────────────────────
# Overall ATT
att_overall <- agg_simple$overall.att
se_overall <- agg_simple$overall.se

cat(sprintf("\n=== MAIN RESULT ===\n"))
cat(sprintf("Overall ATT: %.3f (SE: %.3f)\n", att_overall, se_overall))
cat(sprintf("95%% CI: [%.3f, %.3f]\n",
            att_overall - 1.96 * se_overall,
            att_overall + 1.96 * se_overall))
cat(sprintf("p-value: %.4f\n", 2 * pnorm(-abs(att_overall / se_overall))))

# ─────────────────────────────────────────────
# 5. TWFE comparison (to show heterogeneity bias)
# ─────────────────────────────────────────────
cat("\n=== TWFE Comparison ===\n")

# Standard TWFE (potentially biased with staggered treatment)
twfe <- feols(hosp_rate_w ~ treated | muni_id + year,
              data = panel, cluster = ~muni_id)
cat("\nTWFE estimate:\n")
print(summary(twfe))

# TWFE with region-year FE
twfe_region <- feols(hosp_rate_w ~ treated | muni_id + region^year,
                     data = panel, cluster = ~muni_id)
cat("\nTWFE with region-year FE:\n")
print(summary(twfe_region))

# ─────────────────────────────────────────────
# 6. Under-5 outcome (mechanism: children most vulnerable)
# ─────────────────────────────────────────────
cat("\n=== Under-5 Analysis ===\n")

cs_under5 <- att_gt(
  yname = "under5_rate_w",
  tname = "year",
  idname = "muni_id",
  gname = "treatment_year",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 1,
  est_method = "dr",
  base_period = "universal",
  clustervars = "muni_id",
  print_details = FALSE
)

agg_under5 <- aggte(cs_under5, type = "simple")
cat("\nUnder-5 ATT:\n")
summary(agg_under5)

# ─────────────────────────────────────────────
# 7. Save diagnostics.json (required by validate_v1.py)
# ─────────────────────────────────────────────
diag_list <- list(
  n_treated = uniqueN(panel[treatment_year > 0]$muni_id),
  n_pre = length(unique(panel[year < 2021]$year)),
  n_obs = nrow(panel),
  n_clusters = uniqueN(panel$muni_id),
  att_overall = att_overall,
  se_overall = se_overall,
  att_under5 = agg_under5$overall.att,
  se_under5 = agg_under5$overall.se
)
write_json(diag_list, file.path(DATA_DIR, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")

# ─────────────────────────────────────────────
# 8. Save intermediate results for tables script
# ─────────────────────────────────────────────
save(cs_out, agg_simple, agg_dynamic, agg_group, agg_under5,
     cs_under5, twfe, twfe_region, panel,
     file = file.path(DATA_DIR, "main_results.RData"))
cat("Results saved to main_results.RData\n")
