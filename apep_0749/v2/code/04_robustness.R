## 04_robustness.R — Robustness checks and placebo tests
## apep_0749 v2: The Game-Day Externality
## V2: LOO, COVID exclusion, inference, placebo battery, heterogeneity

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

panel_q  <- fread(file.path(data_dir, "panel_state_quarter.csv"))
panel_gd <- fread(file.path(data_dir, "panel_gameday.csv"))
panel_w  <- fread(file.path(data_dir, "panel_state_week.csv"))
results  <- readRDS(file.path(data_dir, "main_results.rds"))

# CRITICAL: did package needs numeric (not integer) cohort_idx
panel_q[, cohort_idx := as.numeric(cohort_idx)]

# Reconstruct indices where needed
panel_q[, osb_launch := as.Date(osb_launch)]
panel_q[, time_idx := (year - 2013) * 4 + quarter]
panel_q[, osb_year := year(osb_launch)]
panel_q[, osb_quarter := quarter(osb_launch)]

# ============================================================
# 1. EXCLUDING COVID-ERA COHORTS
# ============================================================
cat("=== Robustness: Excluding COVID-era cohorts (2020-2021) ===\n")

covid_cohorts <- panel_q[osb_year %in% 2020:2021 & cohort_idx > 0, unique(cohort_idx)]
panel_nocovid <- panel_q[!(cohort_idx %in% covid_cohorts) | cohort_idx == 0]

cs_nocovid <- att_gt(
  yname = "alc_crash_rate", tname = "time_idx",
  idname = "state_fips", gname = "cohort_idx",
  data = as.data.frame(panel_nocovid),
  control_group = "nevertreated",
  anticipation = 0, est_method = "dr", base_period = "universal"
)
agg_nocovid <- aggte(cs_nocovid, type = "simple")
cat("No-COVID ATT:", round(agg_nocovid$overall.att, 4),
    "SE:", round(agg_nocovid$overall.se, 4), "\n")

# ============================================================
# 2. NOT-YET-TREATED COMPARISON GROUP
# ============================================================
cat("\n=== Robustness: Not-yet-treated comparison ===\n")

cs_nyt <- att_gt(
  yname = "alc_crash_rate", tname = "time_idx",
  idname = "state_fips", gname = "cohort_idx",
  data = as.data.frame(panel_q),
  control_group = "notyettreated",
  anticipation = 0, est_method = "dr", base_period = "universal"
)
agg_nyt <- aggte(cs_nyt, type = "simple")
cat("Not-yet-treated ATT:", round(agg_nyt$overall.att, 4),
    "SE:", round(agg_nyt$overall.se, 4), "\n")

# ============================================================
# 3. TOTAL CRASH RATE (BROADER PLACEBO)
# ============================================================
cat("\n=== Robustness: Total fatal crash rate ===\n")

cs_total <- att_gt(
  yname = "total_crash_rate", tname = "time_idx",
  idname = "state_fips", gname = "cohort_idx",
  data = as.data.frame(panel_q),
  control_group = "nevertreated",
  anticipation = 0, est_method = "dr", base_period = "universal"
)
agg_total <- aggte(cs_total, type = "simple")
cat("Total crash rate ATT:", round(agg_total$overall.att, 4),
    "SE:", round(agg_total$overall.se, 4), "\n")

# ============================================================
# 4. EXCLUDING EARLY ADOPTER (NJ)
# ============================================================
cat("\n=== Robustness: Excluding NJ ===\n")

panel_nonj <- panel_q[state_fips != 34]
cs_nonj <- att_gt(
  yname = "alc_crash_rate", tname = "time_idx",
  idname = "state_fips", gname = "cohort_idx",
  data = as.data.frame(panel_nonj),
  control_group = "nevertreated",
  anticipation = 0, est_method = "dr", base_period = "universal"
)
agg_nonj <- aggte(cs_nonj, type = "simple")
cat("No-NJ ATT:", round(agg_nonj$overall.att, 4),
    "SE:", round(agg_nonj$overall.se, 4), "\n")

# ============================================================
# 5. LEAVE-ONE-OUT (V2 NEW)
# ============================================================
cat("\n=== Leave-One-Out Analysis ===\n")

treated_states <- unique(panel_q[cohort_idx > 0, state_fips])
loo_results <- data.table(
  dropped_state = integer(0),
  att = numeric(0),
  se = numeric(0)
)

for (st in treated_states) {
  panel_loo <- panel_q[state_fips != st]
  cs_loo <- tryCatch({
    att_gt(
      yname = "alc_crash_rate", tname = "time_idx",
      idname = "state_fips", gname = "cohort_idx",
      data = as.data.frame(panel_loo),
      control_group = "nevertreated",
      anticipation = 0, est_method = "dr", base_period = "universal"
    )
  }, error = function(e) NULL)

  if (!is.null(cs_loo)) {
    agg_loo <- aggte(cs_loo, type = "simple")
    loo_results <- rbind(loo_results, data.table(
      dropped_state = st,
      att = agg_loo$overall.att,
      se = agg_loo$overall.se
    ))
  }
}

cat("LOO range: [", round(min(loo_results$att), 4), ",",
    round(max(loo_results$att), 4), "]\n")
fwrite(loo_results, file.path(data_dir, "loo_results.csv"))

# ============================================================
# 6. GAME-DAY PLACEBOS (V2 NEW)
# ============================================================
cat("\n=== Game-Day Placebo Tests ===\n")

# 6a. Non-alcohol crashes on game days
panel_q[, nonalc_nfl_rate := fifelse(nfl_game_days > 0,
  nfl_crashes_nonalc / nfl_game_days / (population / 100000) * 365.25,
  NA_real_)]
panel_q[, nonnfl_nonalc_rate := fifelse(nonnfl_days > 0,
  (nonalc_crashes - nfl_crashes_nonalc) / nonnfl_days / (population / 100000) * 365.25,
  NA_real_)]

gd_nonalc <- rbind(
  panel_q[nfl_game_days > 0, .(state_fips, time_idx, cohort_idx, treated,
    game_day = 1L, nonalc_rate = nonalc_nfl_rate)],
  panel_q[nonnfl_days > 0, .(state_fips, time_idx, cohort_idx, treated,
    game_day = 0L, nonalc_rate = nonnfl_nonalc_rate)]
)
gd_nonalc <- gd_nonalc[!is.na(nonalc_rate)]

ddd_nonalc_gd <- feols(nonalc_rate ~ treated * game_day |
                          state_fips + time_idx + game_day,
                        data = gd_nonalc, cluster = ~state_fips)
cat("Non-alc game-day DDD:", round(coef(ddd_nonalc_gd)["treated:game_day"], 4),
    "SE:", round(se(ddd_nonalc_gd)["treated:game_day"], 4), "\n")

# 6b. Off-season placebo: same DOW pattern during Mar-Aug (no NFL)
fars <- fread(file.path(data_dir, "fars_crashes.csv"))
fars[, date := as.Date(date)]
fars[, quarter := quarter(date)]
fars[, month := month(date)]
fars[, alcohol_involved := as.integer(DRUNK_DR > 0)]

fars[, offseason_pseudo_gd := as.integer(
  month %in% 3:8 & DAY_WEEK %in% c(1, 2, 5)
)]

offseason_q <- fars[month %in% 3:8, .(
  pseudo_gd_alc = sum(alcohol_involved == 1 & offseason_pseudo_gd == 1, na.rm = TRUE),
  non_pseudo_alc = sum(alcohol_involved == 1 & offseason_pseudo_gd == 0, na.rm = TRUE),
  pseudo_gd_days = uniqueN(date[offseason_pseudo_gd == 1]),
  non_pseudo_days = uniqueN(date[offseason_pseudo_gd == 0])
), by = .(state_fips = STATE, year = YEAR, quarter)]

pop <- fread(file.path(data_dir, "state_population.csv"))
osb <- fread(file.path(data_dir, "osb_treatment_dates.csv"))
osb[, osb_launch := as.Date(osb_launch)]

offseason_q <- merge(offseason_q, pop, by = c("state_fips", "year"), all.x = TRUE)
offseason_q <- merge(offseason_q, osb[, .(state_fips, osb_launch)],
                     by = "state_fips", all.x = TRUE)
offseason_q <- offseason_q[!is.na(population) & population > 0]
offseason_q[, yearq := year + (quarter - 1) / 4]
offseason_q[, osb_yearq := year(osb_launch) + (quarter(osb_launch) - 1) / 4]
offseason_q[, treated := as.integer(!is.na(osb_yearq) & yearq >= osb_yearq)]
offseason_q[is.na(osb_yearq), treated := 0L]
offseason_q[, time_idx := (year - 2013) * 4 + quarter]

offseason_gd <- rbind(
  offseason_q[pseudo_gd_days > 0, .(state_fips, time_idx, treated,
    game_day = 1L,
    alc_rate = pseudo_gd_alc / pseudo_gd_days / (population / 100000) * 365.25)],
  offseason_q[non_pseudo_days > 0, .(state_fips, time_idx, treated,
    game_day = 0L,
    alc_rate = non_pseudo_alc / non_pseudo_days / (population / 100000) * 365.25)]
)
offseason_gd <- offseason_gd[!is.na(alc_rate)]

ddd_offseason <- feols(alc_rate ~ treated * game_day |
                         state_fips + time_idx + game_day,
                       data = offseason_gd, cluster = ~state_fips)
cat("Off-season pseudo-gameday DDD:", round(coef(ddd_offseason)["treated:game_day"], 4),
    "SE:", round(se(ddd_offseason)["treated:game_day"], 4), "\n")

# ============================================================
# 7. HETEROGENEITY: NFL TEAM STATES (V2 NEW)
# ============================================================
cat("\n=== Heterogeneity: NFL Team States ===\n")

het_nfl <- feols(alc_crash_rate ~ treated * game_day * has_nfl_team |
                   state_fips + time_idx + game_day,
                 data = panel_gd, cluster = ~state_fips)
cat("NFL team triple interaction:\n")
print(coeftable(het_nfl))

# ============================================================
# 8. WILD CLUSTER BOOTSTRAP (V2 NEW)
# ============================================================
cat("\n=== Wild Cluster Bootstrap ===\n")

twfe_alc <- feols(alc_crash_rate ~ treated | state_fips + time_idx,
                  data = panel_q, cluster = ~state_fips)

wcb <- tryCatch({
  if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
    library(fwildclusterboot)
    set.seed(42)  # Reproducible bootstrap draws
    bt <- boottest(twfe_alc, param = "treated", B = 999,
                   clustid = "state_fips", type = "webb")
    list(p = bt$p_val, ci = bt$conf_int)
  } else {
    cat("fwildclusterboot not available — installing...\n")
    install.packages("fwildclusterboot", repos = "https://cloud.r-project.org", quiet = TRUE)
    library(fwildclusterboot)
    set.seed(42)  # Reproducible bootstrap draws
    bt <- boottest(twfe_alc, param = "treated", B = 999,
                   clustid = "state_fips", type = "webb")
    list(p = bt$p_val, ci = bt$conf_int)
  }
}, error = function(e) {
  cat("WCB error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(wcb)) {
  cat("WCB p-value:", round(wcb$p, 4), "\n")
  cat("WCB 95% CI: [", round(wcb$ci[1], 4), ",", round(wcb$ci[2], 4), "]\n")
}

# ============================================================
# 9. SAVE ROBUSTNESS RESULTS
# ============================================================
rob_results <- list(
  nocovid     = agg_nocovid,
  nyt         = agg_nyt,
  total       = agg_total,
  nonj        = agg_nonj,
  loo         = loo_results,
  ddd_nonalc  = ddd_nonalc_gd,
  ddd_offseason = ddd_offseason,
  het_nfl     = het_nfl,
  wcb         = wcb
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== ROBUSTNESS SUMMARY ===\n")
cat(sprintf("%-30s  ATT = %7.4f  SE = %7.4f\n",
            "Main (CS-DiD)", results$cs_alc_att$overall.att, results$cs_alc_att$overall.se))
cat(sprintf("%-30s  ATT = %7.4f  SE = %7.4f\n",
            "No COVID cohorts", agg_nocovid$overall.att, agg_nocovid$overall.se))
cat(sprintf("%-30s  ATT = %7.4f  SE = %7.4f\n",
            "Not-yet-treated", agg_nyt$overall.att, agg_nyt$overall.se))
cat(sprintf("%-30s  ATT = %7.4f  SE = %7.4f\n",
            "Total crash rate", agg_total$overall.att, agg_total$overall.se))
cat(sprintf("%-30s  ATT = %7.4f  SE = %7.4f\n",
            "Excl. NJ", agg_nonj$overall.att, agg_nonj$overall.se))
cat(sprintf("%-30s  LOO range [%7.4f, %7.4f]\n",
            "Leave-one-out", min(loo_results$att), max(loo_results$att)))
