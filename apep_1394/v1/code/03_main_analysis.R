## 03_main_analysis.R — Primary DDD regressions
## apep_1394: PFL × Healthcare Workforce Retention

source("00_packages.R")

cat("=== MAIN ANALYSIS ===\n")

panel <- readRDS("../data/panel_clean.rds")

# -----------------------------------------------------------------------
# 1. TWFE DDD: Turnover
# -----------------------------------------------------------------------

# Primary specification: Y = β₁(Post × Female) + state×sex FE + quarter FE
# DDD coefficient = post_pfl × female interaction

m1_turnover <- feols(
  turnover ~ treated_ddd + post_pfl + female |
    state_sex_id + time_id,
  data = panel |> filter(!is.na(turnover)),
  cluster = ~state_fips
)

m2_turnover <- feols(
  turnover ~ treated_ddd + post_pfl + female |
    state_fips^female + time_id^female,
  data = panel |> filter(!is.na(turnover)),
  cluster = ~state_fips
)

# Full interaction with state-sex and sex-time FE (most demanding)
m3_turnover <- feols(
  turnover ~ treated_ddd |
    state_fips^female + time_id^female,
  data = panel |> filter(!is.na(turnover)),
  cluster = ~state_fips
)

cat("\n--- Turnover DDD (primary) ---\n")
summary(m3_turnover)

# -----------------------------------------------------------------------
# 2. Additional outcomes: Separations, Earnings
# -----------------------------------------------------------------------

m3_sep <- feols(
  ln_sep ~ treated_ddd |
    state_fips^female + time_id^female,
  data = panel |> filter(!is.na(separations)),
  cluster = ~state_fips
)

m3_earn <- feols(
  ln_earn ~ treated_ddd |
    state_fips^female + time_id^female,
  data = panel |> filter(!is.na(earnings)),
  cluster = ~state_fips
)

m3_seprate <- feols(
  sep_rate ~ treated_ddd |
    state_fips^female + time_id^female,
  data = panel |> filter(!is.na(sep_rate)),
  cluster = ~state_fips
)

m3_hirerate <- feols(
  hire_rate ~ treated_ddd |
    state_fips^female + time_id^female,
  data = panel |> filter(!is.na(hire_rate)),
  cluster = ~state_fips
)

cat("\n--- Log Separations ---\n")
summary(m3_sep)
cat("\n--- Log Earnings ---\n")
summary(m3_earn)
cat("\n--- Separation Rate ---\n")
summary(m3_seprate)

# -----------------------------------------------------------------------
# 3. Callaway-Sant'Anna event study (DDD via pre-processing)
# -----------------------------------------------------------------------

# For CS estimator, we need: group (first treatment period), time, outcome
# DDD approach: use the gender gap (female - male turnover) as the outcome
# Then apply standard DiD to the gap

gap_panel <- panel |>
  filter(!is.na(turnover)) |>
  select(state_fips, time_id, female, turnover, sep_rate, cohort_year, pfl_state, year, quarter) |>
  pivot_wider(
    id_cols = c(state_fips, time_id, cohort_year, pfl_state, year, quarter),
    names_from = female,
    values_from = c(turnover, sep_rate),
    names_prefix = "sex"
  ) |>
  mutate(
    turnover_gap = turnover_sex1 - turnover_sex0,
    seprate_gap = sep_rate_sex1 - sep_rate_sex0
  ) |>
  filter(!is.na(turnover_gap))

# CS requires group = first treatment period (0 for never-treated)
# Convert cohort_year to time_id
gap_panel <- gap_panel |>
  mutate(
    group_t = ifelse(cohort_year > 0, (cohort_year - 2001) * 4 + 1, 0)
  )

cat("\nGap panel:", nrow(gap_panel), "state-quarters\n")
cat("Cohorts:", table(gap_panel$group_t[!duplicated(gap_panel$state_fips)]), "\n")

# CS ATT(g,t) on the turnover gap
cs_out <- tryCatch({
  att_gt(
    yname = "turnover_gap",
    gname = "group_t",
    idname = "state_fips",
    tname = "time_id",
    data = as.data.frame(gap_panel),
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS estimation error:", e$message, "\n")
  NULL
})

if (!is.null(cs_out)) {
  cs_agg <- aggte(cs_out, type = "dynamic", min_e = -12, max_e = 12)
  cat("\n--- CS Dynamic ATT (turnover gap) ---\n")
  summary(cs_agg)

  cs_simple <- aggte(cs_out, type = "simple")
  cat("\n--- CS Simple ATT (turnover gap) ---\n")
  summary(cs_simple)
}

# -----------------------------------------------------------------------
# 4. Save results
# -----------------------------------------------------------------------

results <- list(
  m1_turnover = m1_turnover,
  m2_turnover = m2_turnover,
  m3_turnover = m3_turnover,
  m3_sep = m3_sep,
  m3_earn = m3_earn,
  m3_seprate = m3_seprate,
  m3_hirerate = m3_hirerate,
  cs_out = cs_out,
  gap_panel = gap_panel
)

saveRDS(results, "../data/main_results.rds")

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
