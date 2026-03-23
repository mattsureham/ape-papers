## 03_main_analysis.R — Main DiD analysis: smart motorways and collision rates
## Callaway-Sant'Anna for staggered adoption + TWFE as benchmark

args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("--file=", "", args[grep("--file=", args)])
if (length(script_path) > 0) script_dir <- dirname(normalizePath(script_path)) else script_dir <- getwd()
source(file.path(script_dir, "00_packages.R"))
setwd(dirname(script_dir))

cat("=== Load panel ===\n")
panel <- fread("data/analysis_panel.csv")
panel[, unit_id_num := as.integer(as.factor(unit_id))]

cat(sprintf("  Panel: %d obs, %d units, %d years\n",
            nrow(panel), length(unique(panel$unit_id)), length(unique(panel$year))))
cat(sprintf("  Treated units: %d, Control units: %d\n",
            sum(panel$cohort > 0 & !duplicated(panel$unit_id)),
            sum(panel$cohort == 0 & !duplicated(panel$unit_id))))

# Check cohort distribution
cat("\n  Treatment cohorts:\n")
cohort_tab <- panel[!duplicated(unit_id), .N, by = cohort]
setorder(cohort_tab, cohort)
print(cohort_tab)

cat("\n=== ANALYSIS 1: Callaway-Sant'Anna (primary) ===\n")

# Callaway-Sant'Anna requires:
# - yname: outcome
# - tname: time period
# - gname: treatment group (first year treated; 0 for never-treated)
# - idname: unit identifier

# Primary outcome: collision rate per mile (rate_total)
cs_result <- att_gt(
  yname = "rate_total",
  tname = "time_period",
  gname = "cohort",
  idname = "unit_id_num",
  data = as.data.frame(panel),
  control_group = "notyettreated",  # Not-yet-treated as controls
  anticipation = 0,
  base_period = "varying"
)

cat("\n  Group-time ATT estimates:\n")
print(summary(cs_result))

# Aggregate to overall ATT
cs_agg <- aggte(cs_result, type = "simple")
cat("\n  Overall ATT (simple aggregate):\n")
print(summary(cs_agg))

# Dynamic (event study) aggregation
cs_dynamic <- aggte(cs_result, type = "dynamic", min_e = -8, max_e = 10)
cat("\n  Dynamic ATT (event study):\n")
print(summary(cs_dynamic))

# Save event study estimates for table
es_dt <- data.table(
  event_time = cs_dynamic$egt,
  att = cs_dynamic$att.egt,
  se = cs_dynamic$se.egt,
  ci_lower = cs_dynamic$att.egt - 1.96 * cs_dynamic$se.egt,
  ci_upper = cs_dynamic$att.egt + 1.96 * cs_dynamic$se.egt
)
fwrite(es_dt, "data/event_study_cs.csv")

cat("\n=== ANALYSIS 2: TWFE (benchmark) ===\n")

# Standard TWFE for comparison
twfe <- feols(rate_total ~ treated | unit_id_num + year,
              data = panel,
              cluster = ~unit_id_num)
cat("\n  TWFE result:\n")
print(summary(twfe))

# TWFE with KSI rate
twfe_ks <- feols(rate_ks ~ treated | unit_id_num + year,
                  data = panel,
                  cluster = ~unit_id_num)
cat("\n  TWFE (KSI rate):\n")
print(summary(twfe_ks))

# TWFE with fatal rate
twfe_fatal <- feols(rate_fatal ~ treated | unit_id_num + year,
                     data = panel,
                     cluster = ~unit_id_num)
cat("\n  TWFE (fatal rate):\n")
print(summary(twfe_fatal))

cat("\n=== ANALYSIS 3: Sun-Abraham (robustness) ===\n")

# Sun-Abraham estimator via fixest::sunab
# Need to define cohort and relative period
panel[, rel_year := fifelse(cohort > 0, year - cohort, NA_integer_)]

sunab_result <- feols(rate_total ~ sunab(cohort, year) | unit_id_num + year,
                       data = panel[cohort > 0 | cohort == 0],
                       cluster = ~unit_id_num)
cat("\n  Sun-Abraham result:\n")
print(summary(sunab_result))

cat("\n=== ANALYSIS 4: CS by smart motorway type (ALR vs DHSR) ===\n")

# ALR only
alr_ids <- panel[type == "ALR" & !duplicated(unit_id)]$unit_id_num
ctrl_ids <- panel[cohort == 0 & !duplicated(unit_id)]$unit_id_num
panel_alr <- panel[unit_id_num %in% c(alr_ids, ctrl_ids)]

if (length(alr_ids) >= 3) {
  cs_alr <- tryCatch({
    att_gt(yname = "rate_total", tname = "time_period", gname = "cohort",
           idname = "unit_id_num", data = as.data.frame(panel_alr),
           control_group = "notyettreated", anticipation = 0, base_period = "varying")
  }, error = function(e) { cat("  ALR CS failed:", e$message, "\n"); NULL })

  if (!is.null(cs_alr)) {
    cs_alr_agg <- aggte(cs_alr, type = "simple")
    cat("\n  ALR ATT (simple):\n")
    print(summary(cs_alr_agg))
  }
}

# DHSR only
dhsr_ids <- panel[type == "DHSR" & !duplicated(unit_id)]$unit_id_num
panel_dhsr <- panel[unit_id_num %in% c(dhsr_ids, ctrl_ids)]

if (length(dhsr_ids) >= 3) {
  cs_dhsr <- tryCatch({
    att_gt(yname = "rate_total", tname = "time_period", gname = "cohort",
           idname = "unit_id_num", data = as.data.frame(panel_dhsr),
           control_group = "notyettreated", anticipation = 0, base_period = "varying")
  }, error = function(e) { cat("  DHSR CS failed:", e$message, "\n"); NULL })

  if (!is.null(cs_dhsr)) {
    cs_dhsr_agg <- aggte(cs_dhsr, type = "simple")
    cat("\n  DHSR ATT (simple):\n")
    print(summary(cs_dhsr_agg))
  }
}

cat("\n=== ANALYSIS 5: Severity decomposition ===\n")

# CS for KSI rate
cs_ks <- att_gt(
  yname = "rate_ks",
  tname = "time_period",
  gname = "cohort",
  idname = "unit_id_num",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "varying"
)
cs_ks_agg <- aggte(cs_ks, type = "simple")
cat("\n  KSI rate ATT:\n")
print(summary(cs_ks_agg))

# CS for fatal rate
cs_fatal <- att_gt(
  yname = "rate_fatal",
  tname = "time_period",
  gname = "cohort",
  idname = "unit_id_num",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "varying"
)
cs_fatal_agg <- aggte(cs_fatal, type = "simple")
cat("\n  Fatal rate ATT:\n")
print(summary(cs_fatal_agg))

# Save all main results
results <- list(
  cs_overall = list(
    att = cs_agg$overall.att,
    se = cs_agg$overall.se,
    ci_lower = cs_agg$overall.att - 1.96 * cs_agg$overall.se,
    ci_upper = cs_agg$overall.att + 1.96 * cs_agg$overall.se
  ),
  twfe = list(
    coef = coef(twfe)["treated"],
    se = se(twfe)["treated"],
    pval = pvalue(twfe)["treated"]
  ),
  twfe_ks = list(
    coef = coef(twfe_ks)["treated"],
    se = se(twfe_ks)["treated"],
    pval = pvalue(twfe_ks)["treated"]
  ),
  twfe_fatal = list(
    coef = coef(twfe_fatal)["treated"],
    se = se(twfe_fatal)["treated"],
    pval = pvalue(twfe_fatal)["treated"]
  ),
  cs_ks = list(
    att = cs_ks_agg$overall.att,
    se = cs_ks_agg$overall.se
  ),
  cs_fatal = list(
    att = cs_fatal_agg$overall.att,
    se = cs_fatal_agg$overall.se
  )
)

saveRDS(results, "data/main_results.rds")

# Diagnostics for validate_v1.py
diagnostics <- list(
  n_treated = length(unique(panel[cohort > 0]$unit_id)),
  n_pre = min(panel[cohort > 0, cohort]) - min(panel$year),
  n_obs = nrow(panel),
  n_collisions = sum(panel$n_collisions),
  n_control = length(unique(panel[cohort == 0]$unit_id)),
  outcome = "collision rate per mile per year",
  method = "Callaway-Sant'Anna staggered DiD",
  treatment = "smart motorway conversion",
  panel_years = paste(range(panel$year), collapse = "-")
)
jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
cat(sprintf("  CS ATT (total): %.3f (SE %.3f)\n", cs_agg$overall.att, cs_agg$overall.se))
cat(sprintf("  TWFE (total): %.3f (SE %.3f)\n", coef(twfe)["treated"], se(twfe)["treated"]))
cat(sprintf("  CS ATT (KSI): %.3f (SE %.3f)\n", cs_ks_agg$overall.att, cs_ks_agg$overall.se))
cat(sprintf("  CS ATT (fatal): %.3f (SE %.3f)\n", cs_fatal_agg$overall.att, cs_fatal_agg$overall.se))
