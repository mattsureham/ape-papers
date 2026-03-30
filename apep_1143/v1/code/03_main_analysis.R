## 03_main_analysis.R — DiD estimation: Solar → Farmland Birds
## apep_1143: The Solar Footprint

source("./code/00_packages.R")

DATA_DIR <- "./data"

# ============================================================
# 1. Load panel
# ============================================================
cat("\n=== LOADING PANEL ===\n")
panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
cat("Panel:", nrow(panel), "rows,", uniqueN(panel$route_id), "routes\n")
cat("Treated:", uniqueN(panel[treated == 1]$route_id), "\n")

# Create numeric route ID
panel[, route_num := as.integer(factor(route_id))]

# State ID (from route_id)
panel[, state_num := as.integer(sub("_.*", "", route_id))]

# Log transform count (add 1 for zeros)
panel[, ln_farm := log(total_count_farmland + 1)]
panel[, ln_forest := log(total_count_forest + 1)]

# ============================================================
# 2. TWFE: Farmland birds
# ============================================================
cat("\n=== TWFE: FARMLAND BIRDS ===\n")

# Binary treatment
twfe_farm <- feols(
  ln_farm ~ post | route_num + year,
  data = panel,
  cluster = ~state_num
)
cat("TWFE (log farmland count):\n")
print(summary(twfe_farm))

# Dose-response: cumulative MW
twfe_dose <- feols(
  ln_farm ~ cum_solar_mw | route_num + year,
  data = panel,
  cluster = ~state_num
)
cat("\nTWFE dose-response (MW):\n")
print(summary(twfe_dose))

# With state×year FE
twfe_sy <- feols(
  ln_farm ~ post | route_num + state_num^year,
  data = panel,
  cluster = ~state_num
)
cat("\nTWFE + state×year FE:\n")
print(summary(twfe_sy))

# ============================================================
# 3. PLACEBO: Forest birds
# ============================================================
cat("\n=== PLACEBO: FOREST BIRDS ===\n")

twfe_forest <- feols(
  ln_forest ~ post | route_num + year,
  data = panel,
  cluster = ~state_num
)
cat("TWFE forest (placebo):\n")
print(summary(twfe_forest))

# ============================================================
# 4. Callaway-Sant'Anna
# ============================================================
cat("\n=== CALLAWAY-SANT'ANNA ===\n")

# Restrict to cohorts with >=5 pre-periods (2005+)
panel_cs <- panel[cohort == 0 | cohort >= 2005]
cat("CS sample:", nrow(panel_cs), "rows,",
    uniqueN(panel_cs[treated == 1]$route_id), "treated routes\n")

cs_result <- att_gt(
  yname = "ln_farm",
  tname = "year",
  idname = "route_num",
  gname = "cohort",
  data = as.data.frame(panel_cs),
  control_group = "notyettreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal",
  print_details = FALSE
)

# Overall ATT
agg_overall <- aggte(cs_result, type = "simple")
cat("\nCS Overall ATT:\n")
summary(agg_overall)

# Event study
agg_dyn <- aggte(cs_result, type = "dynamic", min_e = -5, max_e = 8)
cat("\nCS Event Study:\n")
summary(agg_dyn)

# Save event study
es_df <- data.table(
  event_time = agg_dyn$egt,
  att = agg_dyn$att.egt,
  se = agg_dyn$se.egt,
  ci_lower = agg_dyn$att.egt - 1.96 * agg_dyn$se.egt,
  ci_upper = agg_dyn$att.egt + 1.96 * agg_dyn$se.egt
)
fwrite(es_df, file.path(DATA_DIR, "event_study_cs.csv"))

# Pre-trend check
pre <- es_df[event_time < 0 & !is.na(se)]
cat("\nPre-trend coefficients:\n")
print(pre)
if (nrow(pre) > 0) {
  cat("Max |t-stat| in pre-period:", max(abs(pre$att / pre$se), na.rm=TRUE), "\n")
}

# ============================================================
# 5. Sun-Abraham event study
# ============================================================
cat("\n=== SUN-ABRAHAM ===\n")
sa_result <- feols(
  ln_farm ~ sunab(cohort, year) | route_num + year,
  data = panel_cs,
  cluster = ~state_num
)
cat("Sun-Abraham:\n")
print(summary(sa_result))

# ============================================================
# 6. Save results
# ============================================================
cat("\n=== SAVING RESULTS ===\n")

results <- list(
  twfe_binary_coef = coef(twfe_farm)["post"],
  twfe_binary_se = sqrt(vcov(twfe_farm)["post","post"]),
  twfe_dose_coef = coef(twfe_dose)["cum_solar_mw"],
  twfe_dose_se = sqrt(vcov(twfe_dose)["cum_solar_mw","cum_solar_mw"]),
  twfe_sy_coef = coef(twfe_sy)["post"],
  twfe_sy_se = sqrt(vcov(twfe_sy)["post","post"]),
  placebo_forest_coef = coef(twfe_forest)["post"],
  placebo_forest_se = sqrt(vcov(twfe_forest)["post","post"]),
  cs_att = agg_overall$overall.att,
  cs_att_se = agg_overall$overall.se,
  n_treated = uniqueN(panel[treated == 1]$route_id),
  n_control = uniqueN(panel[treated == 0]$route_id),
  n_obs = nrow(panel),
  mean_farm_treated_pre = panel[treated == 1 & post == 0, mean(total_count_farmland, na.rm=TRUE)],
  mean_farm_control = panel[treated == 0, mean(total_count_farmland, na.rm=TRUE)],
  sd_farm = panel[, sd(total_count_farmland, na.rm=TRUE)]
)

jsonlite::write_json(results, file.path(DATA_DIR, "main_results.json"),
                     auto_unbox = TRUE, pretty = TRUE)
cat("Results saved\n")

# Update diagnostics
diag <- list(
  n_treated = uniqueN(panel_cs[treated == 1]$route_id),
  n_pre = 5L,
  n_obs = nrow(panel_cs)
)
jsonlite::write_json(diag, file.path(DATA_DIR, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
