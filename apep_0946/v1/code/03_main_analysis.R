# 03_main_analysis.R — Primary estimation (Callaway-Sant'Anna DiD)
# apep_0946: EECC transposition and consumer telecom prices

source("00_packages.R")

# ===========================================================================
# 1. Load data
# ===========================================================================

panel <- fread("../data/panel_main.csv")

cat("Panel loaded:", nrow(panel), "obs,", uniqueN(panel$geo), "countries\n")
cat("Treatment cohorts:\n")
print(panel[, .(n_countries = uniqueN(geo)), by = first_treat][order(first_treat)])

# ===========================================================================
# 2. Callaway-Sant'Anna ATT(g,t)
# ===========================================================================

cat("\n=== Callaway-Sant'Anna Estimation ===\n")

# Main specification: CP08 level, never-treated comparison
cs_out <- att_gt(
  yname = "cp08",
  tname = "year",
  idname = "country_id",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "nevertreated",
  base_period = "universal",
  anticipation = 0
)

cat("\nGroup-time ATTs:\n")
summary(cs_out)

# ===========================================================================
# 3. Aggregate to event-study and overall ATT
# ===========================================================================

# Event study
es <- aggte(cs_out, type = "dynamic", min_e = -6, max_e = 4)
cat("\n=== Event Study ===\n")
summary(es)

# Overall ATT
overall <- aggte(cs_out, type = "simple")
cat("\n=== Overall ATT ===\n")
summary(overall)

# Group-level ATTs
group_atts <- aggte(cs_out, type = "group")
cat("\n=== Group-level ATTs ===\n")
summary(group_atts)

# ===========================================================================
# 4. Log specification for elasticity interpretation
# ===========================================================================

cat("\n=== Log Specification ===\n")

cs_log <- att_gt(
  yname = "ln_cp08",
  tname = "year",
  idname = "country_id",
  gname = "first_treat",
  data = as.data.frame(panel),
  control_group = "nevertreated",
  base_period = "universal",
  anticipation = 0
)

overall_log <- aggte(cs_log, type = "simple")
cat("Log ATT:", round(overall_log$overall.att, 4),
    "SE:", round(overall_log$overall.se, 4), "\n")
cat("Interpretation: EECC transposition changes communications CPI by",
    round(overall_log$overall.att * 100, 2), "%\n")

es_log <- aggte(cs_log, type = "dynamic", min_e = -6, max_e = 4)

# ===========================================================================
# 5. TWFE comparison (for sign-flip narrative)
# ===========================================================================

cat("\n=== TWFE Comparison ===\n")

twfe <- feols(cp08 ~ post | geo + year, data = panel, cluster = ~geo)
cat("TWFE coefficient:", round(coef(twfe)["post"], 3),
    "SE:", round(se(twfe)["post"], 3), "\n")

twfe_log <- feols(ln_cp08 ~ post | geo + year, data = panel, cluster = ~geo)
cat("TWFE log coefficient:", round(coef(twfe_log)["post"], 4),
    "SE:", round(se(twfe_log)["post"], 4), "\n")

# ===========================================================================
# 6. Save diagnostics.json
# ===========================================================================

diag <- list(
  n_treated = uniqueN(panel[first_treat > 0]$geo),
  n_pre = length(unique(panel[year < 2020]$year)),
  n_obs = nrow(panel),
  n_countries = uniqueN(panel$geo),
  n_never_treated = uniqueN(panel[first_treat == 0]$geo),
  overall_att = overall$overall.att,
  overall_se = overall$overall.se,
  overall_att_log = overall_log$overall.att,
  overall_se_log = overall_log$overall.se,
  twfe_coef = as.numeric(coef(twfe)["post"]),
  twfe_se = as.numeric(se(twfe)["post"]),
  pre_treatment_sd = panel[year <= 2019, sd(cp08, na.rm = TRUE)]
)

write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\ndiagnostics.json written.\n")

# ===========================================================================
# 7. Save estimation objects for tables
# ===========================================================================

saveRDS(cs_out, "../data/cs_out.rds")
saveRDS(es, "../data/es.rds")
saveRDS(overall, "../data/overall.rds")
saveRDS(group_atts, "../data/group_atts.rds")
saveRDS(cs_log, "../data/cs_log.rds")
saveRDS(es_log, "../data/es_log.rds")
saveRDS(overall_log, "../data/overall_log.rds")
saveRDS(twfe, "../data/twfe.rds")
saveRDS(twfe_log, "../data/twfe_log.rds")

cat("All estimation objects saved.\n")
