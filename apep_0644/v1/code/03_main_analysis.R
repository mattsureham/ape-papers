# 03_main_analysis.R — Main DiD analysis
# apep_0644: Pay Transparency Mandates and Employer Adjustment

source("00_packages.R")

cat("=== Main Analysis ===\n")

df <- readRDS("../data/analysis_data.rds")

# ---- 0. Aggregate to state-industry-quarter level for CS estimator ----
# County-level is too granular for CS estimator (memory); aggregate to state
state_df <- df %>%
  group_by(state_fips, industry, yq, time_index, first_treat_yq, treated_state) %>%
  summarize(
    Emp = sum(Emp, na.rm = TRUE),
    HirN = sum(HirN, na.rm = TRUE),
    HirA = sum(HirA, na.rm = TRUE),
    Sep = sum(Sep, na.rm = TRUE),
    FrmJbGn = sum(FrmJbGn, na.rm = TRUE),
    FrmJbLs = sum(FrmJbLs, na.rm = TRUE),
    FrmJbC = sum(FrmJbC, na.rm = TRUE),
    TurnOvrS = sum(TurnOvrS, na.rm = TRUE),
    EarnS_wt = sum(EarnS * EmpS, na.rm = TRUE),  # employment-weighted earnings
    EmpS_total = sum(EmpS, na.rm = TRUE),
    EarnHirNS_wt = sum(EarnHirNS * HirN, na.rm = TRUE),
    n_counties = n_distinct(county_fips),
    .groups = "drop"
  ) %>%
  mutate(
    new_hire_rate = ifelse(Emp > 0, HirN / Emp, NA_real_),
    total_hire_rate = ifelse(Emp > 0, HirA / Emp, NA_real_),
    recall_rate = ifelse(Emp > 0 & !is.na(HirA) & !is.na(HirN),
                         (HirA - HirN) / Emp, NA_real_),
    sep_rate = ifelse(Emp > 0, Sep / Emp, NA_real_),
    job_creation_rate = ifelse(Emp > 0, FrmJbGn / Emp, NA_real_),
    job_destruction_rate = ifelse(Emp > 0, FrmJbLs / Emp, NA_real_),
    net_job_creation_rate = ifelse(Emp > 0, FrmJbC / Emp, NA_real_),
    turnover_rate = ifelse(Emp > 0, TurnOvrS / Emp, NA_real_),
    avg_earn_stable = ifelse(EmpS_total > 0, EarnS_wt / EmpS_total, NA_real_),
    avg_earn_new_hire = ifelse(HirN > 0, EarnHirNS_wt / HirN, NA_real_),
    log_earn_stable = ifelse(avg_earn_stable > 0, log(avg_earn_stable), NA_real_),
    log_earn_new_hire = ifelse(avg_earn_new_hire > 0, log(avg_earn_new_hire), NA_real_)
  )

# Create a unique panel ID
state_df <- state_df %>%
  mutate(panel_id = as.numeric(factor(paste(state_fips, industry, sep = "_"))))

# Filter to non-missing for main analysis
state_df <- state_df %>% filter(!is.na(new_hire_rate), Emp > 0)

cat("Panel: ", n_distinct(state_df$panel_id), " state-industry units\n")
cat("Time periods: ", n_distinct(state_df$time_index), "\n")
cat("Treated units: ", n_distinct(state_df$panel_id[state_df$treated_state]), "\n")

# ---- 1. Map treatment timing ----
# Map first_treat_yq to time_index for consistent time scale
treat_time_map <- tribble(
  ~first_treat_yq, ~first_treat_ti,
  20211,            25,    # 2021Q1 = (2021-2015)*4 + 1 = 25
  20231,            33,    # 2023Q1 = (2023-2015)*4 + 1 = 33
  20234,            36,    # 2023Q4 = (2023-2015)*4 + 4 = 36
  0,                0      # never-treated
)

state_df <- state_df %>%
  left_join(treat_time_map, by = "first_treat_yq")

# ---- 2. Sun-Abraham Event Study (fixest) ----
cat("\n--- Sun-Abraham Event Study ---\n")
es_new_hire <- feols(
  new_hire_rate ~ sunab(first_treat_ti, time_index) |
    panel_id + time_index,
  data = state_df,
  cluster = ~state_fips
)
cat("New hire rate event study:\n")
print(summary(es_new_hire))

es_job_creation <- feols(
  job_creation_rate ~ sunab(first_treat_ti, time_index) |
    panel_id + time_index,
  data = state_df,
  cluster = ~state_fips
)

es_turnover <- feols(
  turnover_rate ~ sunab(first_treat_ti, time_index) |
    panel_id + time_index,
  data = state_df,
  cluster = ~state_fips
)

es_earn <- feols(
  log_earn_new_hire ~ sunab(first_treat_ti, time_index) |
    panel_id + time_index,
  data = state_df %>% filter(!is.na(log_earn_new_hire)),
  cluster = ~state_fips
)

# ---- 3. Callaway-Sant'Anna ATT(g,t) estimation ----
cat("\n--- Callaway-Sant'Anna Estimation ---\n")

# CS estimator for new hire rate
cs_new_hire <- att_gt(
  yname = "new_hire_rate",
  tname = "time_index",
  idname = "panel_id",
  gname = "first_treat_ti",
  data = as.data.frame(state_df),
  control_group = "nevertreated",
  est_method = "dr",
  base_period = "universal"
)

cat("\nCS ATT(g,t) for new hire rate:\n")
print(summary(cs_new_hire))

# Aggregate to overall ATT
cs_new_hire_agg <- aggte(cs_new_hire, type = "simple")
cat("\nOverall ATT (new hire rate): ", cs_new_hire_agg$overall.att, "\n")
cat("SE: ", cs_new_hire_agg$overall.se, "\n")

# Dynamic event study from CS
cs_new_hire_es <- aggte(cs_new_hire, type = "dynamic", min_e = -12, max_e = 8)

# CS for other outcomes
cs_job_creation <- att_gt(
  yname = "job_creation_rate",
  tname = "time_index",
  idname = "panel_id",
  gname = "first_treat_ti",
  data = as.data.frame(state_df),
  control_group = "nevertreated",
  est_method = "dr",
  base_period = "universal"
)
cs_job_creation_agg <- aggte(cs_job_creation, type = "simple")

cs_turnover <- att_gt(
  yname = "turnover_rate",
  tname = "time_index",
  idname = "panel_id",
  gname = "first_treat_ti",
  data = as.data.frame(state_df),
  control_group = "nevertreated",
  est_method = "dr",
  base_period = "universal"
)
cs_turnover_agg <- aggte(cs_turnover, type = "simple")

cs_earn <- att_gt(
  yname = "log_earn_new_hire",
  tname = "time_index",
  idname = "panel_id",
  gname = "first_treat_ti",
  data = as.data.frame(state_df %>% filter(!is.na(log_earn_new_hire))),
  control_group = "nevertreated",
  est_method = "dr",
  base_period = "universal"
)
cs_earn_agg <- aggte(cs_earn, type = "simple")

cs_sep <- att_gt(
  yname = "sep_rate",
  tname = "time_index",
  idname = "panel_id",
  gname = "first_treat_ti",
  data = as.data.frame(state_df),
  control_group = "nevertreated",
  est_method = "dr",
  base_period = "universal"
)
cs_sep_agg <- aggte(cs_sep, type = "simple")

cs_recall <- att_gt(
  yname = "recall_rate",
  tname = "time_index",
  idname = "panel_id",
  gname = "first_treat_ti",
  data = as.data.frame(state_df),
  control_group = "nevertreated",
  est_method = "dr",
  base_period = "universal"
)
cs_recall_agg <- aggte(cs_recall, type = "simple")

# ---- 3. Group-specific ATTs ----
cat("\n--- Group-specific ATTs ---\n")
cs_new_hire_group <- aggte(cs_new_hire, type = "group")
print(summary(cs_new_hire_group))

# ---- 4. Print summary of all results ----
cat("\n========================================\n")
cat("MAIN RESULTS SUMMARY\n")
cat("========================================\n")
results_summary <- tibble(
  outcome = c("New hire rate", "Recall rate", "Job creation rate",
              "Separation rate", "Turnover rate", "Log new hire earnings"),
  att = c(cs_new_hire_agg$overall.att, cs_recall_agg$overall.att,
          cs_job_creation_agg$overall.att,
          cs_sep_agg$overall.att, cs_turnover_agg$overall.att,
          cs_earn_agg$overall.att),
  se = c(cs_new_hire_agg$overall.se, cs_recall_agg$overall.se,
         cs_job_creation_agg$overall.se,
         cs_sep_agg$overall.se, cs_turnover_agg$overall.se,
         cs_earn_agg$overall.se)
) %>%
  mutate(
    t_stat = att / se,
    p_value = 2 * pnorm(-abs(t_stat)),
    ci_low = att - 1.96 * se,
    ci_high = att + 1.96 * se,
    stars = case_when(
      p_value < 0.01 ~ "***",
      p_value < 0.05 ~ "**",
      p_value < 0.10 ~ "*",
      TRUE ~ ""
    )
  )

print(results_summary, width = 120)

# ---- 5. Save results ----
save(
  es_new_hire, es_job_creation, es_turnover, es_earn,
  cs_new_hire, cs_new_hire_agg, cs_new_hire_es, cs_new_hire_group,
  cs_job_creation, cs_job_creation_agg,
  cs_turnover, cs_turnover_agg,
  cs_earn, cs_earn_agg,
  cs_sep, cs_sep_agg,
  cs_recall, cs_recall_agg,
  state_df, results_summary,
  file = "../data/main_results.RData"
)

# ---- 6. Diagnostics for validator ----
n_treated_counties <- n_distinct(df$county_fips[df$treated_state])
n_pre <- sum(state_df$time_index[state_df$first_treat_ti == 25] < 25) /
  n_distinct(state_df$panel_id[state_df$first_treat_ti == 25])

# Load original county data for diagnostics
df_orig <- readRDS("../data/analysis_data.rds")

diagnostics <- list(
  n_treated = n_distinct(df_orig$county_fips[df_orig$treated_state]),
  n_pre = 24,  # 2015Q1 to 2020Q4 = 24 quarters pre-CO treatment
  n_obs = nrow(state_df),
  n_counties = n_distinct(df_orig$county_fips),
  n_states = n_distinct(df_orig$state_fips),
  n_industries = n_distinct(state_df$industry),
  treatment_cohorts = list(
    CO_2021Q1 = sum(df_orig$state_fips == "08" & !duplicated(df_orig$county_fips)),
    CA_2023Q1 = sum(df_orig$state_fips == "06" & !duplicated(df_orig$county_fips)),
    WA_2023Q1 = sum(df_orig$state_fips == "53" & !duplicated(df_orig$county_fips)),
    NY_2023Q4 = sum(df_orig$state_fips == "36" & !duplicated(df_orig$county_fips))
  )
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\nDiagnostics saved. Main analysis complete.\n")
