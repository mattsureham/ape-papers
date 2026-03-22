## 04_robustness.R — Robustness checks
## apep_0749: The Game-Day Externality

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

panel    <- fread(file.path(data_dir, "panel_state_quarter.csv"))
panel_gd <- fread(file.path(data_dir, "panel_gameday.csv"))
results  <- readRDS(file.path(data_dir, "main_results.rds"))

# Reconstruct indices
panel[, time_idx := (year - 2013) * 4 + quarter]
panel[, cohort_idx := fifelse(cohort_yearq == 0, 0,
                                (osb_year - 2013) * 4 + osb_quarter)]
panel[, nonalc_crash_rate := nonalc_crashes / population * 100000 * 4]

panel_gd[, time_idx := (year - 2013) * 4 + quarter]
panel_gd[, cohort_idx := fifelse(cohort_yearq == 0, 0,
                                    (osb_year - 2013) * 4 + osb_quarter)]

# ============================================================
# 1. EXCLUDING COVID-ERA COHORTS
# ============================================================
cat("=== Robustness: Excluding COVID-era cohorts (2020 Q1 - 2021 Q2) ===\n")

# COVID cohorts are those with osb_yearq in 2020-2021
covid_cohorts <- panel[osb_year %in% 2020:2021, unique(cohort_idx)]
panel_nocovid <- panel[!(cohort_idx %in% covid_cohorts) | cohort_idx == 0]

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
# 2. NOT-YET-TREATED AS COMPARISON GROUP
# ============================================================
cat("\n=== Robustness: Not-yet-treated comparison group ===\n")

cs_nyt <- att_gt(
  yname = "alc_crash_rate", tname = "time_idx",
  idname = "state_fips", gname = "cohort_idx",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0, est_method = "dr", base_period = "universal"
)
agg_nyt <- aggte(cs_nyt, type = "simple")
cat("Not-yet-treated ATT:", round(agg_nyt$overall.att, 4),
    "SE:", round(agg_nyt$overall.se, 4), "\n")

# ============================================================
# 3. TOTAL FATAL CRASH RATE (BROADER OUTCOME)
# ============================================================
cat("\n=== Robustness: Total fatal crash rate ===\n")

cs_total <- att_gt(
  yname = "total_crash_rate", tname = "time_idx",
  idname = "state_fips", gname = "cohort_idx",
  data = as.data.frame(panel),
  control_group = "nevertreated",
  anticipation = 0, est_method = "dr", base_period = "universal"
)
agg_total <- aggte(cs_total, type = "simple")
cat("Total crash rate ATT:", round(agg_total$overall.att, 4),
    "SE:", round(agg_total$overall.se, 4), "\n")

# ============================================================
# 4. EXCLUDING EARLY ADOPTER (NJ)
# ============================================================
cat("\n=== Robustness: Excluding early adopter (NJ) ===\n")

panel_nonj <- panel[state_fips != 34]
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
# 5. WEEKEND-ONLY ANALYSIS (HIGHER ALCOHOL-CRASH RISK)
# ============================================================
cat("\n=== Robustness: Game-day restricted to Sundays only ===\n")

# NFL games are predominantly on Sundays (DAY_WEEK = 1 in FARS)
fars <- fread(file.path(data_dir, "fars_crashes.csv"))
fars[, alcohol_involved := as.integer(DRUNK_DR > 0)]
fars[, quarter := quarter(as.Date(sprintf("%d-%02d-%02d", YEAR, MONTH, DAY)))]

# Sunday-only game day
fars[, sunday_gameday := as.integer(
  MONTH %in% c(9, 10, 11, 12, 1, 2) & DAY_WEEK == 1
)]

panel_sun <- fars[, .(
  alc_crashes = sum(alcohol_involved, na.rm = TRUE),
  total_crashes = .N
), by = .(state_fips = STATE, year = YEAR, quarter, game_day = sunday_gameday)]

pop <- fread(file.path(data_dir, "state_population.csv"))
panel_sun <- merge(panel_sun, pop, by = c("state_fips", "year"), all.x = TRUE)
panel_sun <- panel_sun[!is.na(population) & population > 0]
panel_sun[, alc_crash_rate := alc_crashes / population * 100000 * 4]

osb <- fread(file.path(data_dir, "osb_treatment_dates.csv"))
osb[, osb_launch := as.Date(osb_launch)]
osb[, osb_year := year(osb_launch)]
osb[, osb_quarter := quarter(osb_launch)]
panel_sun <- merge(panel_sun, osb[, .(state_fips, osb_year, osb_quarter)],
                   by = "state_fips", all.x = TRUE)
panel_sun[, yearq := year + (quarter - 1) / 4]
panel_sun[, osb_yearq := osb_year + (osb_quarter - 1) / 4]
panel_sun[, treated := as.integer(!is.na(osb_yearq) & yearq >= osb_yearq)]
panel_sun[is.na(osb_yearq), treated := 0L]

twfe_sunday <- feols(alc_crash_rate ~ treated * game_day |
                       state_fips + I((year - 2013) * 4 + quarter) + game_day,
                     data = panel_sun, cluster = ~state_fips)
cat("Sunday DDD (treated × game_day):",
    round(coef(twfe_sunday)["treated:game_day"], 4),
    "SE:", round(se(twfe_sunday)["treated:game_day"], 4), "\n")

# ============================================================
# 6. SAVE ROBUSTNESS RESULTS
# ============================================================
rob_results <- list(
  nocovid = agg_nocovid,
  nyt     = agg_nyt,
  total   = agg_total,
  nonj    = agg_nonj,
  sunday  = twfe_sunday
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== ROBUSTNESS SUMMARY ===\n")
cat(sprintf("%-25s  ATT = %7.4f  SE = %7.4f\n",
            "Main (CS-DiD)", results$cs_alc_att$overall.att, results$cs_alc_att$overall.se))
cat(sprintf("%-25s  ATT = %7.4f  SE = %7.4f\n",
            "No COVID cohorts", agg_nocovid$overall.att, agg_nocovid$overall.se))
cat(sprintf("%-25s  ATT = %7.4f  SE = %7.4f\n",
            "Not-yet-treated", agg_nyt$overall.att, agg_nyt$overall.se))
cat(sprintf("%-25s  ATT = %7.4f  SE = %7.4f\n",
            "Total crash rate", agg_total$overall.att, agg_total$overall.se))
cat(sprintf("%-25s  ATT = %7.4f  SE = %7.4f\n",
            "Excl. NJ", agg_nonj$overall.att, agg_nonj$overall.se))
