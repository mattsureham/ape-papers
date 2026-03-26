# 03_main_analysis.R — Primary regressions
# apep_1017: EU Fourth Railway Package and Rail Fares

source("00_packages.R")

cat("=== Loading analysis panel ===\n")
df <- readRDS("data/monthly_panel.rds")
qdf <- readRDS("data/quarterly_panel.rds")
pre_stats <- readRDS("data/pre_treatment_stats.rds")

# ---- 1. TWFE baseline (for comparison/Bacon decomposition) ----
cat("\n=== TWFE Baseline ===\n")

twfe_rail <- feols(log_rail ~ post | geo + ym, data = df, cluster = ~geo)
twfe_road <- feols(log_road ~ post | geo + ym, data = df, cluster = ~geo)
twfe_air  <- feols(log_air  ~ post | geo + ym, data = df, cluster = ~geo)

cat("TWFE Rail:\n"); print(summary(twfe_rail))
cat("\nTWFE Road (placebo):\n"); print(summary(twfe_road))
cat("\nTWFE Air (placebo):\n"); print(summary(twfe_air))

# ---- 2. Callaway-Sant'Anna — Main specification ----
cat("\n=== Callaway-Sant'Anna DiD ===\n")

# Prepare data for CS: need numeric time, numeric id, numeric first_treat
cs_data <- df[!is.na(rail_fare) & !is.na(first_treat)]
cs_data[, time_period := time_idx]
cs_data[, unit_id := country_id]

# Convert first_treat from ym format to time_idx format
cs_data[, g := (as.integer(substr(as.character(first_treat), 1, 4)) - 2015) * 12 +
          as.integer(substr(as.character(first_treat), 5, 6))]

cat("CS data: ", nrow(cs_data), " obs, ", uniqueN(cs_data$unit_id), " units\n")
cat("Treatment groups:", unique(cs_data$g), "\n")

# Run CS with not-yet-treated as controls
cs_out <- att_gt(
  yname = "log_rail",
  tname = "time_period",
  idname = "unit_id",
  gname = "g",
  data = as.data.frame(cs_data),
  control_group = "notyettreated",
  base_period = "universal"
)

cat("\nGroup-time ATTs:\n")
print(summary(cs_out))

# Aggregate: simple ATT
cs_simple <- aggte(cs_out, type = "simple")
cat("\nSimple ATT:\n")
print(summary(cs_simple))

# Aggregate: dynamic event study
cs_dynamic <- aggte(cs_out, type = "dynamic")
cat("\nDynamic ATT (event study):\n")
print(summary(cs_dynamic))

# ---- 3. Callaway-Sant'Anna — Placebo sectors ----
cat("\n=== Placebo: Road fares (CS) ===\n")
cs_data_road <- df[!is.na(road_fare) & !is.na(first_treat)]
cs_data_road[, time_period := time_idx]
cs_data_road[, unit_id := country_id]
cs_data_road[, g := (as.integer(substr(as.character(first_treat), 1, 4)) - 2015) * 12 +
               as.integer(substr(as.character(first_treat), 5, 6))]

cs_road <- att_gt(
  yname = "log_road",
  tname = "time_period",
  idname = "unit_id",
  gname = "g",
  data = as.data.frame(cs_data_road),
  control_group = "notyettreated",
  base_period = "universal"
)
cs_road_simple <- aggte(cs_road, type = "simple")
cat("Road placebo ATT:\n"); print(summary(cs_road_simple))

cat("\n=== Placebo: Air fares (CS) ===\n")
cs_data_air <- df[!is.na(air_fare) & !is.na(first_treat)]
cs_data_air[, time_period := time_idx]
cs_data_air[, unit_id := country_id]
cs_data_air[, g := (as.integer(substr(as.character(first_treat), 1, 4)) - 2015) * 12 +
              as.integer(substr(as.character(first_treat), 5, 6))]

cs_air <- att_gt(
  yname = "log_air",
  tname = "time_period",
  idname = "unit_id",
  gname = "g",
  data = as.data.frame(cs_data_air),
  control_group = "notyettreated",
  base_period = "universal"
)
cs_air_simple <- aggte(cs_air, type = "simple")
cat("Air placebo ATT:\n"); print(summary(cs_air_simple))

# ---- 4. Triple-difference: Rail vs Road within country-month ----
cat("\n=== Triple-Difference: Rail vs Road ===\n")

# Stack rail and road fares in long format
ddd <- rbind(
  df[!is.na(rail_fare), .(geo, date, year, month, ym, country_id, cohort,
                           post, log_fare = log_rail, sector = "rail")],
  df[!is.na(road_fare), .(geo, date, year, month, ym, country_id, cohort,
                           post, log_fare = log_road, sector = "road")]
)
ddd[, rail := fifelse(sector == "rail", 1L, 0L)]
ddd[, rail_post := rail * post]

# DDD: country×sector FE + common time FE, rail×post interaction
# Using common ym FE (not ym^sector) so road/air trends inform the counterfactual
ddd_reg <- feols(log_fare ~ rail_post + post | geo^sector + ym, data = ddd, cluster = ~geo)
cat("Triple-diff (rail vs road):\n"); print(summary(ddd_reg))

# Also rail vs air
ddd_air <- rbind(
  df[!is.na(rail_fare), .(geo, date, year, month, ym, country_id, cohort,
                           post, log_fare = log_rail, sector = "rail")],
  df[!is.na(air_fare), .(geo, date, year, month, ym, country_id, cohort,
                          post, log_fare = log_air, sector = "air")]
)
ddd_air[, rail := fifelse(sector == "rail", 1L, 0L)]
ddd_air[, rail_post := rail * post]
ddd_air_reg <- feols(log_fare ~ rail_post + post | geo^sector + ym, data = ddd_air, cluster = ~geo)
cat("\nTriple-diff (rail vs air):\n"); print(summary(ddd_air_reg))

# ---- 5. Event study with fixest (for plots) ----
cat("\n=== Event study (fixest) ===\n")

# Create relative time variable
df[, rel_month := as.integer(difftime(date, transposition_date, units = "days")) %/% 30]

# Trim to [-36, +48] window
es_data <- df[rel_month >= -36 & rel_month <= 48 & !is.na(log_rail)]

# Event study with fixest sunab()
es_data[, treat_time := as.integer(format(transposition_date, "%Y%m"))]
es_reg <- feols(log_rail ~ sunab(treat_time, ym) | geo + ym,
                data = es_data, cluster = ~geo)
cat("Event study coefficients:\n")
print(summary(es_reg))

# ---- 6. Heterogeneity: Early vs Late transposers ----
cat("\n=== Heterogeneity by cohort ===\n")

het_early <- feols(log_rail ~ post | geo + ym,
                   data = df[cohort == "early"], cluster = ~geo)
het_late <- feols(log_rail ~ post | geo + ym,
                  data = df[cohort == "late"], cluster = ~geo)
cat("Early transposers:\n"); print(summary(het_early))
cat("Late transposers:\n"); print(summary(het_late))

# ---- 7. Save results ----
cat("\n=== Saving results ===\n")

results <- list(
  twfe_rail = twfe_rail,
  twfe_road = twfe_road,
  twfe_air = twfe_air,
  cs_out = cs_out,
  cs_simple = cs_simple,
  cs_dynamic = cs_dynamic,
  cs_road_simple = cs_road_simple,
  cs_air_simple = cs_air_simple,
  ddd_reg = ddd_reg,
  ddd_air_reg = ddd_air_reg,
  es_reg = es_reg,
  het_early = het_early,
  het_late = het_late,
  pre_stats = pre_stats
)
saveRDS(results, "data/main_results.rds")

# ---- 8. Diagnostics for validator ----
n_treated_early <- uniqueN(df[cohort == "early"]$geo)
n_treated_late <- uniqueN(df[cohort == "late"]$geo)
n_pre <- length(unique(df[date < as.Date("2019-01-01")]$ym))
n_obs <- nrow(df[!is.na(rail_fare)])

diagnostics <- list(
  n_treated = n_treated_early + n_treated_late,
  n_pre = n_pre,
  n_obs = n_obs,
  n_early = n_treated_early,
  n_late = n_treated_late,
  n_countries = uniqueN(df$geo)
)
jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)
cat("Diagnostics written: n_treated =", diagnostics$n_treated,
    ", n_pre =", diagnostics$n_pre, ", n_obs =", diagnostics$n_obs, "\n")

cat("\n=== Main analysis complete ===\n")
