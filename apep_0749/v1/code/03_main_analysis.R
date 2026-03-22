## 03_main_analysis.R — Main DiD estimation
## apep_0749: The Game-Day Externality

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

panel <- fread(file.path(data_dir, "panel_state_quarter.csv"))

# ============================================================
# 1. PREPARE FOR CS-DiD
# ============================================================
# Recode cohort for did package: never-treated = 0
# Time periods as integers (quarter index)
panel[, time_idx := (year - 2013) * 4 + quarter]
panel[, cohort_idx := fifelse(cohort_yearq == 0, 0,
                                (osb_year - 2013) * 4 + osb_quarter)]

# Ensure state_fips is the panel id
setorder(panel, state_fips, time_idx)

cat("Panel dimensions:", nrow(panel), "obs\n")
cat("Cohort distribution:\n")
print(panel[, .N, by = cohort_idx][order(cohort_idx)])

# ============================================================
# 2. CALLAWAY-SANT'ANNA ESTIMATION
# ============================================================
cat("\n=== CS-DiD: Alcohol-Involved Fatal Crash Rate ===\n")

cs_alc <- att_gt(
  yname     = "alc_crash_rate",
  tname     = "time_idx",
  idname    = "state_fips",
  gname     = "cohort_idx",
  data      = as.data.frame(panel),
  control_group = "nevertreated",
  anticipation  = 0,
  est_method    = "dr",  # doubly-robust
  base_period   = "universal"
)

cat("\nGroup-time ATTs computed:", length(cs_alc$att), "\n")

# Aggregate to overall ATT
agg_simple <- aggte(cs_alc, type = "simple")
cat("\nOverall ATT (simple):\n")
summary(agg_simple)

# Event-study aggregation
agg_es <- aggte(cs_alc, type = "dynamic", min_e = -8, max_e = 8)
cat("\nEvent study ATTs:\n")
summary(agg_es)

# ============================================================
# 3. TWFE COMPARISON (fixest)
# ============================================================
cat("\n=== TWFE Comparison ===\n")

# Basic TWFE
twfe_alc <- feols(alc_crash_rate ~ treated | state_fips + time_idx,
                  data = panel, cluster = ~state_fips)
cat("TWFE coefficient:", round(coef(twfe_alc)[1], 4), "\n")
cat("TWFE std error:", round(se(twfe_alc)[1], 4), "\n")

# Sun-Abraham heterogeneity-robust
# Create cohort factor for Sun-Abraham
panel[, cohort_sa := fifelse(cohort_idx == 0, 1e6, cohort_idx)]
panel[, rel_time := time_idx - cohort_idx]
panel[cohort_idx == 0, rel_time := -1e6]  # never-treated

sa_alc <- feols(alc_crash_rate ~ sunab(cohort_sa, time_idx) | state_fips + time_idx,
                data = panel, cluster = ~state_fips)
cat("\nSun-Abraham overall ATT:\n")
print(summary(sa_alc, agg = "ATT"))

# ============================================================
# 4. TOTAL FATAL CRASH RATE (NON-ALCOHOL AS PLACEBO)
# ============================================================
cat("\n=== Placebo: Non-Alcohol Fatal Crash Rate ===\n")

panel[, nonalc_crash_rate := nonalc_crashes / population * 100000 * 4]

cs_nonalc <- att_gt(
  yname     = "nonalc_crash_rate",
  tname     = "time_idx",
  idname    = "state_fips",
  gname     = "cohort_idx",
  data      = as.data.frame(panel),
  control_group = "nevertreated",
  anticipation  = 0,
  est_method    = "dr",
  base_period   = "universal"
)

agg_nonalc <- aggte(cs_nonalc, type = "simple")
cat("Non-alcohol crash rate ATT:\n")
summary(agg_nonalc)

# ============================================================
# 5. ALCOHOL SHARE OF CRASHES
# ============================================================
cat("\n=== Alcohol Share of Fatal Crashes ===\n")

cs_share <- att_gt(
  yname     = "alc_share",
  tname     = "time_idx",
  idname    = "state_fips",
  gname     = "cohort_idx",
  data      = as.data.frame(panel),
  control_group = "nevertreated",
  anticipation  = 0,
  est_method    = "dr",
  base_period   = "universal"
)

agg_share <- aggte(cs_share, type = "simple")
cat("Alcohol share ATT:\n")
summary(agg_share)

# ============================================================
# 6. GAME-DAY MECHANISM TEST (TRIPLE-DIFFERENCE)
# ============================================================
cat("\n=== Game-Day Triple-Difference ===\n")

panel_gd <- fread(file.path(data_dir, "panel_gameday.csv"))

# Merge with OSB treatment
panel_gd[, time_idx := (year - 2013) * 4 + quarter]
panel_gd[, cohort_idx := fifelse(cohort_yearq == 0, 0,
                                    (osb_year - 2013) * 4 + osb_quarter)]

# Per-capita rate (need to account for fewer game days vs non-game days in quarter)
panel_gd[, alc_crash_rate := alc_crashes / population * 100000 * 4]

# Triple-diff: treated × game_day × post
twfe_ddd <- feols(alc_crash_rate ~ treated * game_day |
                    state_fips + time_idx + game_day,
                  data = panel_gd, cluster = ~state_fips)
cat("DDD coefficient (treated × game_day):\n")
print(summary(twfe_ddd))

# ============================================================
# 7. SAVE KEY RESULTS
# ============================================================
results <- list(
  cs_alc_att    = agg_simple,
  cs_alc_es     = agg_es,
  cs_nonalc_att = agg_nonalc,
  cs_share_att  = agg_share,
  twfe_alc      = twfe_alc,
  sa_alc        = sa_alc,
  twfe_ddd      = twfe_ddd
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# Write diagnostics.json for validator
diag <- list(
  n_treated = length(unique(panel[cohort_idx > 0, state_fips])),
  n_pre     = {
    first_treat <- min(panel[cohort_idx > 0, time_idx])
    length(unique(panel[time_idx < first_treat, time_idx]))
  },
  n_obs     = nrow(panel)
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== MAIN RESULTS SUMMARY ===\n")
cat("CS ATT (alc crash rate):", round(agg_simple$overall.att, 4),
    "SE:", round(agg_simple$overall.se, 4), "\n")
cat("CS ATT (non-alc placebo):", round(agg_nonalc$overall.att, 4),
    "SE:", round(agg_nonalc$overall.se, 4), "\n")
cat("CS ATT (alc share):", round(agg_share$overall.att, 4),
    "SE:", round(agg_share$overall.se, 4), "\n")
cat("TWFE (alc crash rate):", round(coef(twfe_alc)[1], 4),
    "SE:", round(se(twfe_alc)[1], 4), "\n")
cat("\nDiagnostics saved.\n")
