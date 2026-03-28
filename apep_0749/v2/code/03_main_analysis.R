## 03_main_analysis.R — Main DiD and game-day DDD estimation
## apep_0749 v2: The Game-Day Externality
## V2: CS-DiD at state-quarter + game-day DDD with proper exposure + hour splits

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

panel_q  <- fread(file.path(data_dir, "panel_state_quarter.csv"))
panel_gd <- fread(file.path(data_dir, "panel_gameday.csv"))
panel_w  <- fread(file.path(data_dir, "panel_state_week.csv"))

# CRITICAL: did package needs numeric (not integer) cohort_idx
panel_q[, cohort_idx := as.numeric(cohort_idx)]

# ============================================================
# 1. CALLAWAY-SANT'ANNA: BASELINE (STATE-QUARTER)
# ============================================================
cat("=== CS-DiD: Alcohol-Involved Fatal Crash Rate ===\n")

cs_alc <- att_gt(
  yname     = "alc_crash_rate",
  tname     = "time_idx",
  idname    = "state_fips",
  gname     = "cohort_idx",
  data      = as.data.frame(panel_q),
  control_group = "nevertreated",
  anticipation  = 0,
  est_method    = "dr",
  base_period   = "universal"
)

agg_simple <- aggte(cs_alc, type = "simple")
cat("Overall ATT:", round(agg_simple$overall.att, 4),
    "SE:", round(agg_simple$overall.se, 4), "\n")

agg_es <- aggte(cs_alc, type = "dynamic", min_e = -8, max_e = 8)
cat("Dynamic ATT computed\n")

# ============================================================
# 2. PLACEBO: NON-ALCOHOL CRASHES
# ============================================================
cat("\n=== Placebo: Non-Alcohol Fatal Crash Rate ===\n")

cs_nonalc <- att_gt(
  yname     = "nonalc_crash_rate",
  tname     = "time_idx",
  idname    = "state_fips",
  gname     = "cohort_idx",
  data      = as.data.frame(panel_q),
  control_group = "nevertreated",
  anticipation  = 0,
  est_method    = "dr",
  base_period   = "universal"
)
agg_nonalc <- aggte(cs_nonalc, type = "simple")
cat("Non-alcohol ATT:", round(agg_nonalc$overall.att, 4),
    "SE:", round(agg_nonalc$overall.se, 4), "\n")

# ============================================================
# 3. ALCOHOL FATALITIES (for welfare)
# ============================================================
cat("\n=== CS-DiD: Alcohol-Involved Fatality Rate ===\n")

cs_fatal <- att_gt(
  yname     = "alc_fatal_rate",
  tname     = "time_idx",
  idname    = "state_fips",
  gname     = "cohort_idx",
  data      = as.data.frame(panel_q),
  control_group = "nevertreated",
  anticipation  = 0,
  est_method    = "dr",
  base_period   = "universal"
)
agg_fatal <- aggte(cs_fatal, type = "simple")
cat("Alcohol fatality rate ATT:", round(agg_fatal$overall.att, 4),
    "SE:", round(agg_fatal$overall.se, 4), "\n")

# ============================================================
# 4. ALCOHOL SHARE
# ============================================================
cat("\n=== CS-DiD: Alcohol Share of Crashes ===\n")

cs_share <- att_gt(
  yname     = "alc_share",
  tname     = "time_idx",
  idname    = "state_fips",
  gname     = "cohort_idx",
  data      = as.data.frame(panel_q),
  control_group = "nevertreated",
  anticipation  = 0,
  est_method    = "dr",
  base_period   = "universal"
)
agg_share <- aggte(cs_share, type = "simple")
cat("Alcohol share ATT:", round(agg_share$overall.att, 4),
    "SE:", round(agg_share$overall.se, 4), "\n")

# ============================================================
# 5. GAME-DAY DDD WITH PROPER EXPOSURE (V2 FIX)
# ============================================================
# panel_gameday has per-day rates: crashes / actual_days / (pop/100K) * 365.25
# This corrects the V1 bug where game and non-game days had different exposure
cat("\n=== Game-Day Triple-Difference (Corrected Exposure) ===\n")

# TWFE DDD on per-day rates
ddd_rate <- feols(alc_crash_rate ~ treated * game_day |
                    state_fips + time_idx + game_day,
                  data = panel_gd, cluster = ~state_fips)
cat("DDD (per-day rate): treated:game_day =",
    round(coef(ddd_rate)["treated:game_day"], 4),
    "SE =", round(se(ddd_rate)["treated:game_day"], 4), "\n")

# Poisson count model with exposure offset (more appropriate for rare events)
ddd_pois <- fepois(alc_crashes ~ treated * game_day |
                     state_fips + time_idx + game_day,
                   data = panel_gd[alc_crashes >= 0],
                   offset = ~log(days * population / 100000),
                   cluster = ~state_fips)
cat("DDD Poisson: treated:game_day =",
    round(coef(ddd_pois)["treated:game_day"], 4),
    "SE =", round(se(ddd_pois)["treated:game_day"], 4), "\n")

# ============================================================
# 6. STATE-WEEK GAME-WEEK DESIGN
# ============================================================
cat("\n=== State-Week Game-Week DDD ===\n")

# Game-week indicator already in panel_w
week_ddd <- feols(alc_crash_rate ~ treated * game_week |
                    state_fips + iso_year^iso_week,
                  data = panel_w, cluster = ~state_fips)
cat("Week DDD: treated:game_week =",
    round(coef(week_ddd)["treated:game_week"], 4),
    "SE =", round(se(week_ddd)["treated:game_week"], 4), "\n")

# Week-level Poisson
week_pois <- fepois(alc_crashes ~ treated * game_week |
                      state_fips + iso_year^iso_week,
                    data = panel_w[alc_crashes >= 0 & !is.na(log_exposure)],
                    offset = ~log_exposure,
                    cluster = ~state_fips)
cat("Week Poisson: treated:game_week =",
    round(coef(week_pois)["treated:game_week"], 4),
    "SE =", round(se(week_pois)["treated:game_week"], 4), "\n")

# ============================================================
# 7. NIGHTTIME VS DAYTIME MECHANISM (V2 NEW)
# ============================================================
cat("\n=== Night vs Day Mechanism Test ===\n")

# Night: 8pm-4am (the post-game drinking window)
cs_night <- att_gt(
  yname     = "alc_night_rate",
  tname     = "time_idx",
  idname    = "state_fips",
  gname     = "cohort_idx",
  data      = as.data.frame(panel_q),
  control_group = "nevertreated",
  anticipation  = 0,
  est_method    = "dr",
  base_period   = "universal"
)
agg_night <- aggte(cs_night, type = "simple")
cat("Nighttime alcohol crash ATT:", round(agg_night$overall.att, 4),
    "SE:", round(agg_night$overall.se, 4), "\n")

cs_day <- att_gt(
  yname     = "alc_day_rate",
  tname     = "time_idx",
  idname    = "state_fips",
  gname     = "cohort_idx",
  data      = as.data.frame(panel_q),
  control_group = "nevertreated",
  anticipation  = 0,
  est_method    = "dr",
  base_period   = "universal"
)
agg_day <- aggte(cs_day, type = "simple")
cat("Daytime alcohol crash ATT:", round(agg_day$overall.att, 4),
    "SE:", round(agg_day$overall.se, 4), "\n")

# ============================================================
# 8. TWFE COMPARISON
# ============================================================
cat("\n=== TWFE Comparison ===\n")

twfe_alc <- feols(alc_crash_rate ~ treated | state_fips + time_idx,
                  data = panel_q, cluster = ~state_fips)
cat("TWFE (alc crash rate):", round(coef(twfe_alc)[1], 4),
    "SE:", round(se(twfe_alc)[1], 4), "\n")

# Sun-Abraham
panel_q[, cohort_sa := fifelse(cohort_idx == 0, 1e6, cohort_idx)]
sa_alc <- feols(alc_crash_rate ~ sunab(cohort_sa, time_idx) | state_fips + time_idx,
                data = panel_q, cluster = ~state_fips)

# ============================================================
# 9. SAVE ALL RESULTS
# ============================================================
results <- list(
  # Baseline CS-DiD
  cs_alc_att    = agg_simple,
  cs_alc_es     = agg_es,
  cs_nonalc_att = agg_nonalc,
  cs_fatal_att  = agg_fatal,
  cs_share_att  = agg_share,
  # Night/day
  cs_night_att  = agg_night,
  cs_day_att    = agg_day,
  # DDD (corrected)
  ddd_rate      = ddd_rate,
  ddd_pois      = ddd_pois,
  # Week-level
  week_ddd      = week_ddd,
  week_pois     = week_pois,
  # TWFE
  twfe_alc      = twfe_alc,
  sa_alc        = sa_alc,
  # Pre-treatment means
  pretx_mean_alc = panel_q[treated == 0 & cohort_idx > 0,
                            mean(alc_crash_rate, na.rm = TRUE)],
  pretx_mean_alc_ctrl = panel_q[cohort_idx == 0,
                                 mean(alc_crash_rate, na.rm = TRUE)]
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# Diagnostics for validator
diag <- list(
  n_treated = uniqueN(panel_q[cohort_idx > 0, state_fips]),
  n_pre     = {
    first_treat <- min(panel_q[cohort_idx > 0, time_idx])
    length(unique(panel_q[time_idx < first_treat, time_idx]))
  },
  n_obs     = nrow(panel_q)
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== MAIN RESULTS SUMMARY ===\n")
cat(sprintf("%-30s  ATT = %7.4f  SE = %7.4f\n",
            "CS ATT (alc crash rate)", agg_simple$overall.att, agg_simple$overall.se))
cat(sprintf("%-30s  ATT = %7.4f  SE = %7.4f\n",
            "CS ATT (non-alc placebo)", agg_nonalc$overall.att, agg_nonalc$overall.se))
cat(sprintf("%-30s  ATT = %7.4f  SE = %7.4f\n",
            "CS ATT (alc fatality rate)", agg_fatal$overall.att, agg_fatal$overall.se))
cat(sprintf("%-30s  ATT = %7.4f  SE = %7.4f\n",
            "CS ATT (nighttime alc)", agg_night$overall.att, agg_night$overall.se))
cat(sprintf("%-30s  ATT = %7.4f  SE = %7.4f\n",
            "CS ATT (daytime alc)", agg_day$overall.att, agg_day$overall.se))
cat(sprintf("%-30s  coef = %7.4f  SE = %7.4f\n",
            "DDD per-day rate", coef(ddd_rate)["treated:game_day"],
            se(ddd_rate)["treated:game_day"]))
cat(sprintf("%-30s  coef = %7.4f  SE = %7.4f\n",
            "DDD Poisson", coef(ddd_pois)["treated:game_day"],
            se(ddd_pois)["treated:game_day"]))
cat(sprintf("%-30s  coef = %7.4f  SE = %7.4f\n",
            "Week DDD", coef(week_ddd)["treated:game_week"],
            se(week_ddd)["treated:game_week"]))
