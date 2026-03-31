# 03_main_analysis.R — Main DiD analysis with Callaway-Sant'Anna
# Section 60 Stop-and-Search Relaxation and Knife Crime

source("00_packages.R")

panel <- fread("../data/panel_analysis.csv")
panel[, date := as.Date(date)]

cat(sprintf("Panel: %d obs, %d forces, %d months\n",
            nrow(panel), uniqueN(panel$force), uniqueN(panel$month)))

# ── Treatment definitions ────────────────────────────────────────────────
cohort1_forces <- c("metropolitan", "west-midlands", "greater-manchester",
                    "merseyside", "south-yorkshire", "south-wales", "west-yorkshire")

# ── 1. FIRST STAGE: Did S60 stops increase? ─────────────────────────────
cat("\n=== FIRST STAGE: S60 STOP INTENSITY ===\n")

# TWFE first stage
fs_twfe <- feols(s60_rate ~ treated | force_id + t, data = panel, cluster = ~force_id)
cat("TWFE First Stage (S60 stops per 100K):\n")
print(summary(fs_twfe))

# Callaway-Sant'Anna for S60 stops
cs_s60 <- att_gt(
  yname = "s60_rate",
  tname = "t",
  idname = "force_id",
  gname = "g",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "universal"
)
cat("\nCallaway-Sant'Anna ATT(g,t) for S60 stops:\n")
print(summary(cs_s60))

# Aggregate to overall ATT
cs_s60_agg <- aggte(cs_s60, type = "simple")
cat("\nAggregate ATT (S60 stops):\n")
print(summary(cs_s60_agg))

# ── 2. MAIN RESULT: Effect on weapons crime ──────────────────────────────
cat("\n=== MAIN RESULT: WEAPONS POSSESSION CRIME ===\n")

# TWFE
main_twfe <- feols(weapons_rate ~ treated | force_id + t, data = panel, cluster = ~force_id)
cat("TWFE (Weapons crime per 100K):\n")
print(summary(main_twfe))

# Callaway-Sant'Anna
cs_weapons <- att_gt(
  yname = "weapons_rate",
  tname = "t",
  idname = "force_id",
  gname = "g",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "universal"
)
cat("\nCallaway-Sant'Anna ATT(g,t) for weapons crime:\n")
print(summary(cs_weapons))

cs_weapons_agg <- aggte(cs_weapons, type = "simple")
cat("\nAggregate ATT (Weapons crime):\n")
print(summary(cs_weapons_agg))

# Event study aggregation
cs_weapons_es <- aggte(cs_weapons, type = "dynamic")
cat("\nEvent study ATT (Weapons crime):\n")
print(summary(cs_weapons_es))

# ── 3. SECONDARY OUTCOME: Violent crime ──────────────────────────────────
cat("\n=== SECONDARY: VIOLENT CRIME ===\n")

cs_violent <- att_gt(
  yname = "violent_rate",
  tname = "t",
  idname = "force_id",
  gname = "g",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "universal"
)
cs_violent_agg <- aggte(cs_violent, type = "simple")
cat("Aggregate ATT (Violent crime):\n")
print(summary(cs_violent_agg))

# TWFE for violent crime
violent_twfe <- feols(violent_rate ~ treated | force_id + t, data = panel, cluster = ~force_id)

# ── 4. SPATIAL DISPLACEMENT TEST ─────────────────────────────────────────
cat("\n=== SPATIAL DISPLACEMENT TEST ===\n")

# Focus on Cohort 2 forces (not yet treated) during April-July 2019
# Compare neighbors of Cohort 1 vs non-neighbors
displacement_window <- panel[cohort == 2 & date >= as.Date("2019-04-01") & date <= as.Date("2019-07-01")]
pre_window <- panel[cohort == 2 & date >= as.Date("2018-04-01") & date <= as.Date("2018-07-01")]

# DiD: Neighbor × Post for Cohort 2 forces only
# "Post" = Apr-Jul 2019 vs Apr-Jul 2018 (same seasonal months)
disp_data <- rbind(
  pre_window[, .(force, force_id, month, date, weapons_rate, violent_rate,
                 neighbor_cohort1, period = 0L)],
  displacement_window[, .(force, force_id, month, date, weapons_rate, violent_rate,
                          neighbor_cohort1, period = 1L)]
)

# Displacement regression
disp_reg <- feols(weapons_rate ~ neighbor_cohort1:period + period |
                    force_id, data = disp_data, cluster = ~force_id)
cat("Displacement test (weapons crime):\n")
print(summary(disp_reg))

disp_reg_v <- feols(violent_rate ~ neighbor_cohort1:period + period |
                      force_id, data = disp_data, cluster = ~force_id)
cat("\nDisplacement test (violent crime):\n")
print(summary(disp_reg_v))

# ── 5. PLACEBO OUTCOMES ──────────────────────────────────────────────────
cat("\n=== PLACEBO OUTCOMES ===\n")

# Shoplifting — should not respond to S60 relaxation
cs_shoplifting <- att_gt(
  yname = "shoplifting_rate",
  tname = "t",
  idname = "force_id",
  gname = "g",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "universal"
)
cs_shoplifting_agg <- aggte(cs_shoplifting, type = "simple")
cat("Placebo ATT (Shoplifting):\n")
print(summary(cs_shoplifting_agg))

# Other theft — should not respond
cs_theft <- att_gt(
  yname = "theft_rate",
  tname = "t",
  idname = "force_id",
  gname = "g",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "universal"
)
cs_theft_agg <- aggte(cs_theft, type = "simple")
cat("Placebo ATT (Other theft):\n")
print(summary(cs_theft_agg))

shoplifting_twfe <- feols(shoplifting_rate ~ treated | force_id + t, data = panel, cluster = ~force_id)
theft_twfe <- feols(theft_rate ~ treated | force_id + t, data = panel, cluster = ~force_id)

# ── 6. SAVE RESULTS ─────────────────────────────────────────────────────
results <- list(
  # First stage
  fs_twfe_coef = coef(fs_twfe)["treated"],
  fs_twfe_se = sqrt(vcov(fs_twfe)["treated", "treated"]),
  fs_cs_att = cs_s60_agg$overall.att,
  fs_cs_se = cs_s60_agg$overall.se,
  # Main result: weapons crime
  main_twfe_coef = coef(main_twfe)["treated"],
  main_twfe_se = sqrt(vcov(main_twfe)["treated", "treated"]),
  main_cs_att = cs_weapons_agg$overall.att,
  main_cs_se = cs_weapons_agg$overall.se,
  # Violent crime
  violent_twfe_coef = coef(violent_twfe)["treated"],
  violent_twfe_se = sqrt(vcov(violent_twfe)["treated", "treated"]),
  violent_cs_att = cs_violent_agg$overall.att,
  violent_cs_se = cs_violent_agg$overall.se,
  # Displacement
  disp_weapons_coef = coef(disp_reg)["neighbor_cohort1:period"],
  disp_weapons_se = sqrt(vcov(disp_reg)["neighbor_cohort1:period", "neighbor_cohort1:period"]),
  disp_violent_coef = coef(disp_reg_v)["neighbor_cohort1:period"],
  disp_violent_se = sqrt(vcov(disp_reg_v)["neighbor_cohort1:period", "neighbor_cohort1:period"]),
  # Placebos
  placebo_shoplifting_att = cs_shoplifting_agg$overall.att,
  placebo_shoplifting_se = cs_shoplifting_agg$overall.se,
  placebo_theft_att = cs_theft_agg$overall.att,
  placebo_theft_se = cs_theft_agg$overall.se,
  # Sample info
  n_obs = nrow(panel),
  n_forces = uniqueN(panel$force),
  n_months = uniqueN(panel$month),
  n_treated_cohort1 = 7L,
  n_treated_cohort2 = uniqueN(panel$force) - 7L,
  pre_mean_weapons = mean(panel[date < as.Date("2019-04-01")]$weapons_rate, na.rm = TRUE),
  pre_sd_weapons = sd(panel[date < as.Date("2019-04-01")]$weapons_rate, na.rm = TRUE),
  pre_mean_violent = mean(panel[date < as.Date("2019-04-01")]$violent_rate, na.rm = TRUE),
  pre_sd_violent = sd(panel[date < as.Date("2019-04-01")]$violent_rate, na.rm = TRUE)
)

# Event study coefficients
es_coefs <- data.table(
  egt = cs_weapons_es$egt,
  att = cs_weapons_es$att.egt,
  se = cs_weapons_es$se.egt
)
fwrite(es_coefs, "../data/event_study_coefs.csv")

saveRDS(results, "../data/results.rds")
jsonlite::write_json(results, "../data/results.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nResults saved.\n")

# ── 7. DIAGNOSTICS for validator ─────────────────────────────────────────
diagnostics <- list(
  n_treated = results$n_treated_cohort1 + results$n_treated_cohort2,
  n_pre = length(unique(panel[date < as.Date("2019-04-01")]$t)),
  n_obs = results$n_obs
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("Diagnostics saved.\n")
