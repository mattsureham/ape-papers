## 03_main_analysis.R — Callaway-Sant'Anna DiD + TWFE
## apep_0805: Prescribed fire liability reform and wildfire severity

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("Panel loaded:", nrow(panel), "obs,", uniqueN(panel$state), "states,",
    range(panel$year), "years\n")
cat("Treated states:", uniqueN(panel$state[panel$first_treat > 0]), "\n")
cat("Treatment cohorts:", sort(unique(panel$first_treat[panel$first_treat > 0])), "\n")

# ─────────────────────────────────────────────────────────
# 1. Callaway-Sant'Anna: Main outcomes
# ─────────────────────────────────────────────────────────
# Convert to data.frame for did package
df <- as.data.frame(panel)

# Ensure no NA in key variables
df <- df[complete.cases(df[, c("ln_fires", "year", "state_id", "first_treat")]), ]

cat("\n=== CS DiD: Log wildfire count ===\n")
cs_fires <- att_gt(
  yname  = "ln_fires",
  tname  = "year",
  idname = "state_id",
  gname  = "first_treat",
  data   = df,
  control_group = "nevertreated",
  anticipation  = 0,
  est_method    = "dr",
  bstrap        = TRUE,
  cband         = TRUE,
  biters        = 1000
)

cat("\n=== CS DiD: Log acres burned ===\n")
cs_acres <- att_gt(
  yname  = "ln_acres",
  tname  = "year",
  idname = "state_id",
  gname  = "first_treat",
  data   = df,
  control_group = "nevertreated",
  anticipation  = 0,
  est_method    = "dr",
  bstrap        = TRUE,
  cband         = TRUE,
  biters        = 1000
)

cat("\n=== CS DiD: Log large fires ===\n")
cs_large <- att_gt(
  yname  = "ln_large",
  tname  = "year",
  idname = "state_id",
  gname  = "first_treat",
  data   = df,
  control_group = "nevertreated",
  anticipation  = 0,
  est_method    = "dr",
  bstrap        = TRUE,
  cband         = TRUE,
  biters        = 1000
)

# ─────────────────────────────────────────────────────────
# 2. Aggregate ATT estimates
# ─────────────────────────────────────────────────────────
# Overall ATT
agg_fires <- aggte(cs_fires, type = "simple")
agg_acres <- aggte(cs_acres, type = "simple")
agg_large <- aggte(cs_large, type = "simple")

cat("\n=== Overall ATT ===\n")
cat("Log fires:  ATT =", round(agg_fires$overall.att, 4),
    " SE =", round(agg_fires$overall.se, 4), "\n")
cat("Log acres:  ATT =", round(agg_acres$overall.att, 4),
    " SE =", round(agg_acres$overall.se, 4), "\n")
cat("Log large:  ATT =", round(agg_large$overall.att, 4),
    " SE =", round(agg_large$overall.se, 4), "\n")

# Event study aggregation
es_fires <- aggte(cs_fires, type = "dynamic", min_e = -8, max_e = 10)
es_acres <- aggte(cs_acres, type = "dynamic", min_e = -8, max_e = 10)
es_large <- aggte(cs_large, type = "dynamic", min_e = -8, max_e = 10)

# ─────────────────────────────────────────────────────────
# 3. TWFE as benchmark (fixest)
# ─────────────────────────────────────────────────────────
cat("\n=== TWFE (fixest) ===\n")

twfe_fires <- feols(ln_fires ~ treated | state_id + year, data = df,
                    cluster = ~state_id)
twfe_acres <- feols(ln_acres ~ treated | state_id + year, data = df,
                    cluster = ~state_id)
twfe_large <- feols(ln_large ~ treated | state_id + year, data = df,
                    cluster = ~state_id)

cat("TWFE Log fires: ", round(coef(twfe_fires)["treated"], 4),
    " (", round(se(twfe_fires)["treated"], 4), ")\n")
cat("TWFE Log acres: ", round(coef(twfe_acres)["treated"], 4),
    " (", round(se(twfe_acres)["treated"], 4), ")\n")
cat("TWFE Log large: ", round(coef(twfe_large)["treated"], 4),
    " (", round(se(twfe_large)["treated"], 4), ")\n")

# ─────────────────────────────────────────────────────────
# 4. Mechanism: Debris burning fires (proxy for prescribed fire activity)
# ─────────────────────────────────────────────────────────
cat("\n=== CS DiD: Log debris burning fires (mechanism) ===\n")
cs_debris <- att_gt(
  yname  = "ln_debris",
  tname  = "year",
  idname = "state_id",
  gname  = "first_treat",
  data   = df,
  control_group = "nevertreated",
  anticipation  = 0,
  est_method    = "dr",
  bstrap        = TRUE,
  cband         = TRUE,
  biters        = 1000
)

agg_debris <- aggte(cs_debris, type = "simple")
cat("Log debris fires: ATT =", round(agg_debris$overall.att, 4),
    " SE =", round(agg_debris$overall.se, 4), "\n")

# ─────────────────────────────────────────────────────────
# 5. Placebo: Lightning fires (should be unaffected by tort reform)
# ─────────────────────────────────────────────────────────
cat("\n=== CS DiD: Log lightning fires (placebo) ===\n")
cs_lightning <- att_gt(
  yname  = "ln_lightning",
  tname  = "year",
  idname = "state_id",
  gname  = "first_treat",
  data   = df,
  control_group = "nevertreated",
  anticipation  = 0,
  est_method    = "dr",
  bstrap        = TRUE,
  cband         = TRUE,
  biters        = 1000
)

agg_lightning <- aggte(cs_lightning, type = "simple")
cat("Log lightning fires: ATT =", round(agg_lightning$overall.att, 4),
    " SE =", round(agg_lightning$overall.se, 4), "\n")

# ─────────────────────────────────────────────────────────
# 6. Heterogeneity: Private vs Federal land
# ─────────────────────────────────────────────────────────
cat("\n=== CS DiD: Private vs Federal land fires ===\n")

cs_private <- att_gt(
  yname = "ln_private_fires", tname = "year", idname = "state_id",
  gname = "first_treat", data = df, control_group = "nevertreated",
  est_method = "dr", bstrap = TRUE, biters = 1000
)
agg_private <- aggte(cs_private, type = "simple")

cs_federal <- att_gt(
  yname = "ln_federal_fires", tname = "year", idname = "state_id",
  gname = "first_treat", data = df, control_group = "nevertreated",
  est_method = "dr", bstrap = TRUE, biters = 1000
)
agg_federal <- aggte(cs_federal, type = "simple")

cat("Private land fires: ATT =", round(agg_private$overall.att, 4),
    " SE =", round(agg_private$overall.se, 4), "\n")
cat("Federal land fires: ATT =", round(agg_federal$overall.att, 4),
    " SE =", round(agg_federal$overall.se, 4), "\n")

# ─────────────────────────────────────────────────────────
# 7. Save all results
# ─────────────────────────────────────────────────────────
results <- list(
  # CS DiD models
  cs_fires = cs_fires, cs_acres = cs_acres, cs_large = cs_large,
  cs_debris = cs_debris, cs_lightning = cs_lightning,
  cs_private = cs_private, cs_federal = cs_federal,
  # Aggregated ATTs
  agg_fires = agg_fires, agg_acres = agg_acres, agg_large = agg_large,
  agg_debris = agg_debris, agg_lightning = agg_lightning,
  agg_private = agg_private, agg_federal = agg_federal,
  # Event studies
  es_fires = es_fires, es_acres = es_acres, es_large = es_large,
  # TWFE
  twfe_fires = twfe_fires, twfe_acres = twfe_acres, twfe_large = twfe_large
)
saveRDS(results, file.path(data_dir, "results.rds"))

# ─────────────────────────────────────────────────────────
# 8. Write diagnostics.json for validator
# ─────────────────────────────────────────────────────────
# Compute pre-periods: use median cohort's pre-period length (not minimum)
cohort_years <- unique(panel$first_treat[panel$first_treat > 0])
pre_per_cohort <- cohort_years - min(panel$year)
diagnostics <- list(
  n_treated = uniqueN(df$state_id[df$first_treat > 0]),
  n_pre = as.integer(median(pre_per_cohort)),
  n_obs = nrow(df)
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics:", diagnostics$n_treated, "treated states,",
    diagnostics$n_pre, "pre-periods,",
    diagnostics$n_obs, "observations\n")

cat("\n=== All main analysis complete ===\n")
