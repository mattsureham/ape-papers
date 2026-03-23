# 03_main_analysis.R — Callaway-Sant'Anna DiD for quiet zones
# apep_0785: Quiet zone designations and property values

source("00_packages.R")

cat("=== Loading analysis panel ===\n")
panel <- readRDS("../data/analysis_panel.rds")

cat("Panel:", nrow(panel), "obs,", n_distinct(panel$RegionID), "cities\n")
cat("Treated:", n_distinct(panel$RegionID[panel$ever_treated]), "\n")
cat("Control:", n_distinct(panel$RegionID[!panel$ever_treated]), "\n")

# --- Annual aggregation for CS estimation ---
cat("\n=== Aggregating to annual ===\n")

panel_yr <- panel %>%
  group_by(RegionID, year, ever_treated, first_qz_year_month,
           n_public_crossings, n_qz_crossings) %>%
  summarise(
    zhvi = mean(zhvi, na.rm = TRUE),
    log_zhvi = mean(log_zhvi, na.rm = TRUE),
    n_months = n(),
    .groups = "drop"
  ) %>%
  mutate(
    # Cohort: year of first quiet zone designation (0 for never-treated)
    cohort_yr = if_else(
      !is.na(first_qz_year_month),
      as.integer(year(first_qz_year_month)),
      0L
    ),
    # Post-treatment indicator
    post_qz = if_else(ever_treated & year >= cohort_yr, 1L, 0L)
  )

# Balance the panel — keep only cities present in all years
city_year_counts <- panel_yr %>%
  count(RegionID) %>%
  filter(n == max(n))

panel_bal <- panel_yr %>%
  filter(RegionID %in% city_year_counts$RegionID)

cat("Balanced annual panel:", nrow(panel_bal), "obs\n")
cat("Cities:", n_distinct(panel_bal$RegionID), "\n")
cat("Years:", n_distinct(panel_bal$year), "\n")
cat("Treated:", n_distinct(panel_bal$RegionID[panel_bal$ever_treated]), "\n")
cat("Control:", n_distinct(panel_bal$RegionID[!panel_bal$ever_treated]), "\n")

cat("\nCohort distribution:\n")
cohort_tab <- panel_bal %>%
  filter(cohort_yr > 0) %>%
  distinct(RegionID, cohort_yr) %>%
  count(cohort_yr) %>%
  arrange(cohort_yr)
print(cohort_tab, n = 30)

# Merge small cohorts: combine years with <5 cities into neighbors
# Keep 2005-2020 as main sample (most coverage)
panel_analysis <- panel_bal %>%
  filter(year >= 2000 & year <= 2024) %>%
  mutate(
    # Bin very late cohorts (2021+) together for CS stability
    cohort_binned = case_when(
      cohort_yr == 0 ~ 0L,
      cohort_yr >= 2021 ~ 2021L,
      TRUE ~ cohort_yr
    )
  )

cat("\nBinned cohort distribution:\n")
print(
  panel_analysis %>%
    filter(cohort_binned > 0) %>%
    distinct(RegionID, cohort_binned) %>%
    count(cohort_binned),
  n = 30
)

# --- Callaway-Sant'Anna ---
cat("\n=== Callaway-Sant'Anna estimation ===\n")

cs_out <- att_gt(
  yname = "log_zhvi",
  tname = "year",
  idname = "RegionID",
  gname = "cohort_binned",
  data = as.data.frame(panel_analysis),
  control_group = "nevertreated",
  anticipation = 0,
  est_method = "dr",
  base_period = "universal"
)

cat("CS estimation complete.\n")
cat("Number of group-time ATTs:", length(cs_out$att), "\n")

# Aggregate: overall ATT
agg_overall <- aggte(cs_out, type = "simple")
cat("\n--- Overall ATT ---\n")
summary(agg_overall)

# Aggregate: dynamic event study
agg_es <- aggte(cs_out, type = "dynamic", min_e = -5, max_e = 15)
cat("\n--- Dynamic event study ---\n")
summary(agg_es)

# Aggregate: calendar time
agg_cal <- aggte(cs_out, type = "calendar")
cat("\n--- Calendar time ATT ---\n")
summary(agg_cal)

# Aggregate: by group (cohort)
agg_group <- aggte(cs_out, type = "group")
cat("\n--- Group-level ATT ---\n")
summary(agg_group)

# Save CS results
saveRDS(cs_out, "../data/cs_results.rds")
saveRDS(agg_overall, "../data/cs_overall.rds")
saveRDS(agg_es, "../data/cs_event_study.rds")
saveRDS(agg_cal, "../data/cs_calendar.rds")
saveRDS(agg_group, "../data/cs_group.rds")

# --- TWFE for comparison ---
cat("\n=== TWFE comparison ===\n")

twfe_reg <- feols(
  log_zhvi ~ post_qz | RegionID + year,
  data = panel_analysis,
  cluster = ~RegionID
)

cat("TWFE result:\n")
summary(twfe_reg)

# --- Sun-Abraham event study ---
cat("\n=== Sun-Abraham event study ===\n")

panel_sa <- panel_analysis %>%
  mutate(
    cohort_sa = if_else(cohort_binned == 0, 10000L, cohort_binned)
  )

sa_reg <- feols(
  log_zhvi ~ sunab(cohort_sa, year, ref.p = -1) | RegionID + year,
  data = panel_sa,
  cluster = ~RegionID
)

cat("Sun-Abraham IW estimator:\n")
cat("ATT:", sum(coef(sa_reg)[grep("year::", names(coef(sa_reg)))][
  as.numeric(gsub(".*::", "", names(coef(sa_reg)[grep("year::", names(coef(sa_reg)))]))) >= 0
] * 1/length(coef(sa_reg)[grep("year::", names(coef(sa_reg)))][
  as.numeric(gsub(".*::", "", names(coef(sa_reg)[grep("year::", names(coef(sa_reg)))]))) >= 0
])), "\n")

# --- Dose-response: QZ intensity ---
cat("\n=== Dose-response by QZ intensity ===\n")

panel_analysis <- panel_analysis %>%
  mutate(
    qz_intensity = if_else(ever_treated, n_qz_crossings / n_public_crossings, 0),
    med_intensity = median(qz_intensity[ever_treated & qz_intensity > 0]),
    high_intensity = ever_treated & qz_intensity > med_intensity,
    post_high = as.integer(post_qz == 1 & high_intensity),
    post_low = as.integer(post_qz == 1 & !high_intensity & ever_treated)
  )

dose_reg <- feols(
  log_zhvi ~ post_high + post_low | RegionID + year,
  data = panel_analysis,
  cluster = ~RegionID
)

cat("Dose-response (high vs low intensity):\n")
summary(dose_reg)

# Continuous dose
dose_continuous <- feols(
  log_zhvi ~ i(post_qz, qz_intensity) | RegionID + year,
  data = panel_analysis,
  cluster = ~RegionID
)
cat("Continuous dose-response:\n")
summary(dose_continuous)

# --- State-by-year FE robustness ---
cat("\n=== State-by-year FE ===\n")

# Need state variable
panel_analysis <- panel_analysis %>%
  left_join(
    panel %>% distinct(RegionID, state_clean) %>% slice_head(n = 1, by = RegionID),
    by = "RegionID"
  )

state_yr_reg <- feols(
  log_zhvi ~ post_qz | RegionID + state_clean^year,
  data = panel_analysis,
  cluster = ~RegionID
)

cat("State-by-year FE result:\n")
summary(state_yr_reg)

# --- Write diagnostics ---
cat("\n=== Writing diagnostics ===\n")

diagnostics <- list(
  n_treated = n_distinct(panel_analysis$RegionID[panel_analysis$ever_treated]),
  n_control = n_distinct(panel_analysis$RegionID[!panel_analysis$ever_treated]),
  n_pre = 5L,
  n_obs = nrow(panel_analysis),
  n_cohorts = n_distinct(panel_analysis$cohort_binned[panel_analysis$cohort_binned > 0]),
  att_overall = agg_overall$overall.att,
  att_se = agg_overall$overall.se,
  twfe_coef = as.numeric(coef(twfe_reg)["post_qz"]),
  twfe_se = as.numeric(se(twfe_reg)["post_qz"])
)

write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat("Diagnostics saved.\n")

# Save all regression objects for tables
saveRDS(twfe_reg, "../data/twfe_reg.rds")
saveRDS(sa_reg, "../data/sa_reg.rds")
saveRDS(dose_reg, "../data/dose_reg.rds")
saveRDS(dose_continuous, "../data/dose_continuous.rds")
saveRDS(state_yr_reg, "../data/state_yr_reg.rds")
saveRDS(panel_analysis, "../data/panel_analysis.rds")

cat("\n=== Main analysis complete ===\n")
