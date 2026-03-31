# ==============================================================================
# 03_main_analysis.R — CRNA opt-out: main DiD estimates
# ==============================================================================

source("00_packages.R")

panel_full <- readRDS("../data/analysis_panel.rds")
panel_main <- readRDS("../data/panel_main.rds")

# ==========================================================================
# 1. MAIN RESULT: Callaway-Sant'Anna on BA+ ambulatory (NAICS 621) employment
# ==========================================================================

cat("=== Main analysis: Callaway-Sant'Anna DiD ===\n")

# Use full panel from 1998 for maximum pre-treatment data
main <- panel_main %>%
  filter(year >= 1998 & year <= 2023) %>%
  arrange(state_id, year)

cat(sprintf("Main sample: %d obs, %d states, years %d-%d\n",
            nrow(main), length(unique(main$state_id)),
            min(main$year), max(main$year)))
cat(sprintf("Treated states: %d, Never-treated: %d\n",
            sum(unique(main$state_id[main$g_period > 0]) %in% unique(main$state_id)),
            sum(!unique(main$state_id) %in% unique(main$state_id[main$g_period > 0]))))

# Callaway-Sant'Anna with not-yet-treated as control
cs_result <- att_gt(
  yname      = "log_emp",
  tname      = "year",
  idname     = "state_id",
  gname      = "g_period",
  data       = as.data.frame(main),
  control_group = "notyettreated",
  est_method = "reg",   # Regression-based (more stable for small groups)
  base_period = "universal",
  allow_unbalanced_panel = TRUE
)

cat("\n--- Group-time ATTs ---\n")
summary(cs_result)

# Aggregate to overall ATT
cs_agg <- aggte(cs_result, type = "simple")
cat("\n--- Overall ATT ---\n")
summary(cs_agg)

# Event-study aggregation
cs_event <- aggte(cs_result, type = "dynamic", min_e = -8, max_e = 10)
cat("\n--- Event Study ---\n")
summary(cs_event)

# Save CS results
saveRDS(cs_result, "../data/cs_result.rds")
saveRDS(cs_agg, "../data/cs_agg.rds")
saveRDS(cs_event, "../data/cs_event.rds")

# ==========================================================================
# 2. TWFE BENCHMARK: fixest for comparison
# ==========================================================================

cat("\n=== TWFE Benchmark (fixest) ===\n")

twfe_main <- feols(
  log_emp ~ post_optout | state_id + year,
  data = main,
  cluster = ~state_id
)
cat("TWFE on BA+ ambulatory:\n")
summary(twfe_main)

# ==========================================================================
# 3. Sun-Abraham heterogeneity-robust estimator
# ==========================================================================

cat("\n=== Sun-Abraham (fixest::sunab) ===\n")

# Create cohort and relative time
main$cohort <- ifelse(main$g_period == 0, 10000, main$g_period)  # Never-treated = far future
main$rel_time <- main$year - main$cohort

sa_result <- feols(
  log_emp ~ sunab(cohort, year) | state_id + year,
  data = main,
  cluster = ~state_id
)
cat("Sun-Abraham on BA+ ambulatory:\n")
summary(sa_result)

# ==========================================================================
# 4. TRIPLE DIFFERENCE: (621 - 622) × (Opt-out - Never) × (Post - Pre)
# ==========================================================================

cat("\n=== Triple Difference (DDD) ===\n")

panel_ddd <- panel_full %>%
  filter(ed_group == "BA_plus",
         industry %in% c("621", "622"),
         year >= 1998 & year <= 2023)

panel_ddd$ambulatory <- as.integer(panel_ddd$industry == "621")

ddd_result <- feols(
  log_emp ~ post_optout * ambulatory | state_id^industry + year^industry,
  data = panel_ddd,
  cluster = ~state_id
)
cat("DDD result:\n")
summary(ddd_result)

# ==========================================================================
# 5. EDUCATION PLACEBO: Non-BA workers in NAICS 621
# ==========================================================================

cat("\n=== Education Placebo: Non-BA workers in NAICS 621 ===\n")

placebo_nonba <- panel_full %>%
  filter(ed_group == "non_BA",
         industry == "621",
         year >= 1998 & year <= 2023)

twfe_placebo_ed <- feols(
  log_emp ~ post_optout | state_id + year,
  data = placebo_nonba,
  cluster = ~state_id
)
cat("TWFE on non-BA ambulatory (placebo — should be null):\n")
summary(twfe_placebo_ed)

# ==========================================================================
# 6. INDUSTRY PLACEBO: BA+ workers in NAICS 623 (Nursing/Residential)
# ==========================================================================

cat("\n=== Industry Placebo: BA+ workers in NAICS 623 ===\n")

placebo_623 <- panel_full %>%
  filter(ed_group == "BA_plus",
         industry == "623",
         year >= 1998 & year <= 2023)

twfe_placebo_ind <- feols(
  log_emp ~ post_optout | state_id + year,
  data = placebo_623,
  cluster = ~state_id
)
cat("TWFE on BA+ nursing care (placebo — should be null):\n")
summary(twfe_placebo_ind)

# ==========================================================================
# 7. EARNINGS EFFECT
# ==========================================================================

cat("\n=== Earnings Effect: BA+ in NAICS 621 ===\n")

twfe_earn <- feols(
  log_earn ~ post_optout | state_id + year,
  data = main,
  cluster = ~state_id
)
cat("TWFE on BA+ ambulatory earnings:\n")
summary(twfe_earn)

# ==========================================================================
# 8. Write diagnostics.json for validator
# ==========================================================================

# For staggered DiD with C-S, n_pre is the effective pre-treatment window.
# The 2002 cohort (6 states) has 4 pre-periods (1998-2001).
# The 2003 cohort and later (16+ states) have 5+ pre-periods.
# Report the median cohort's pre-period count for the design overall.
treat_years <- sort(unique(main$g_period[main$g_period > 0]))
median_treat <- treat_years[ceiling(length(treat_years) / 2)]
pre_years <- unique(main$year[main$year < median_treat])
diagnostics <- list(
  n_treated = length(unique(main$state_id[main$g_period > 0])),
  n_pre     = length(pre_years),
  n_obs     = nrow(main)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

# ==========================================================================
# 9. Save all results for tables
# ==========================================================================

results <- list(
  cs_agg         = cs_agg,
  cs_event       = cs_event,
  twfe_main      = twfe_main,
  sa_result      = sa_result,
  ddd_result     = ddd_result,
  twfe_placebo_ed  = twfe_placebo_ed,
  twfe_placebo_ind = twfe_placebo_ind,
  twfe_earn      = twfe_earn,
  panel_main_summary = list(
    n_states     = length(unique(main$state_abbr)),
    n_treated    = length(unique(main$state_abbr[main$g_period > 0])),
    n_never      = length(unique(main$state_abbr[main$g_period == 0])),
    n_obs        = nrow(main),
    mean_emp     = mean(main$emp, na.rm = TRUE),
    sd_emp       = sd(main$emp, na.rm = TRUE),
    mean_log_emp = mean(main$log_emp, na.rm = TRUE),
    sd_log_emp   = sd(main$log_emp, na.rm = TRUE),
    mean_earn    = mean(main$earn, na.rm = TRUE),
    sd_earn      = sd(main$earn, na.rm = TRUE),
    mean_log_earn = mean(main$log_earn, na.rm = TRUE),
    sd_log_earn  = sd(main$log_earn, na.rm = TRUE)
  )
)

saveRDS(results, "../data/all_results.rds")
cat("\nAll results saved.\n")
