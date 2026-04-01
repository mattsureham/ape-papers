# ==============================================================================
# 03_main_analysis.R — Main DiD regressions
# ==============================================================================

source("00_packages.R")

analysis <- readRDS("../data/analysis_panel.rds")

cat("Analysis panel: ", nrow(analysis), " rows\n")
cat("States: ", n_distinct(analysis$state_fips), "\n")

# ==============================================================================
# A. Continuous Treatment DiD (fixest)
# ==============================================================================
# Treatment: log state MW. Key regressors: log_mw interacted with industry_group
# FE: state × industry, year-quarter
# Cluster: state level

cat("\n=== A. Continuous Treatment DiD ===\n")

# Restrict to low-wage industries for main results
low_wage <- analysis |> filter(industry_group == "low_wage")

# Table 1: Main results — effect of log MW on racial gaps
# Col 1: log earnings ratio (B/W)
m1_earns <- feols(log_earns_ratio ~ log_mw | state_id + yq_id,
                  data = low_wage, cluster = ~state_fips)

# Col 2: log employment ratio (B/W)
m1_emp <- feols(log_emp_ratio ~ log_mw | state_id + yq_id,
                data = low_wage, cluster = ~state_fips)

# Col 3: log wage bill ratio (B/W)
m1_wb <- feols(log_wage_bill_ratio ~ log_mw | state_id + yq_id,
               data = low_wage, cluster = ~state_fips)

cat("\n--- Main Results (Low-Wage Industries) ---\n")
etable(m1_earns, m1_emp, m1_wb,
       headers = c("Earnings Gap", "Employment Gap", "Wage Bill Gap"))

# ==============================================================================
# B. Triple-Difference: Low-wage vs High-wage industries
# ==============================================================================

cat("\n=== B. Triple Difference ===\n")

# Create DDD interaction
analysis_ddd <- analysis |>
  mutate(
    low_wage_ind = as.integer(industry_group == "low_wage"),
    mw_x_lowwage = log_mw * low_wage_ind
  )

# DDD: log_mw × low_wage_ind with state×industry, year-quarter FE
m2_earns <- feols(log_earns_ratio ~ mw_x_lowwage + log_mw + low_wage_ind |
                    state_id^industry_group + yq_id,
                  data = analysis_ddd, cluster = ~state_fips)

m2_emp <- feols(log_emp_ratio ~ mw_x_lowwage + log_mw + low_wage_ind |
                  state_id^industry_group + yq_id,
                data = analysis_ddd, cluster = ~state_fips)

m2_wb <- feols(log_wage_bill_ratio ~ mw_x_lowwage + log_mw + low_wage_ind |
                 state_id^industry_group + yq_id,
               data = analysis_ddd, cluster = ~state_fips)

cat("\n--- DDD Results ---\n")
etable(m2_earns, m2_emp, m2_wb,
       headers = c("Earnings Gap", "Employment Gap", "Wage Bill Gap"))

# ==============================================================================
# C. Callaway-Sant'Anna Event Study
# ==============================================================================

cat("\n=== C. Callaway-Sant'Anna Staggered DiD ===\n")

# Collapse to state × period for CS-DiD (low-wage only)
cs_data <- low_wage |>
  group_by(state_fips, state_id, period, first_treat_period) |>
  summarize(
    log_earns_ratio = weighted.mean(log_earns_ratio, w = emp_A1 + emp_A2, na.rm = TRUE),
    log_emp_ratio = weighted.mean(log_emp_ratio, w = emp_A1 + emp_A2, na.rm = TRUE),
    log_wage_bill_ratio = weighted.mean(log_wage_bill_ratio, w = emp_A1 + emp_A2, na.rm = TRUE),
    .groups = "drop"
  ) |>
  filter(is.finite(log_earns_ratio), is.finite(log_emp_ratio))

cat("CS data: ", nrow(cs_data), " state-periods\n")
cat("Treatment groups: ", n_distinct(cs_data$first_treat_period[cs_data$first_treat_period > 0]), "\n")

# CS-DiD for earnings ratio
cs_earns <- tryCatch({
  att_gt(
    yname = "log_earns_ratio",
    tname = "period",
    idname = "state_id",
    gname = "first_treat_period",
    data = as.data.frame(cs_data),
    control_group = "nevertreated",
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS-DiD error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_earns)) {
  cs_earns_agg <- aggte(cs_earns, type = "simple")
  cat("\nCS-DiD ATT (earnings ratio):\n")
  cat("  ATT:", round(cs_earns_agg$overall.att, 4),
      " SE:", round(cs_earns_agg$overall.se, 4), "\n")

  # Event study
  cs_earns_es <- aggte(cs_earns, type = "dynamic", min_e = -12, max_e = 12)
  cat("Event study computed. Periods:", length(cs_earns_es$egt), "\n")
}

# CS-DiD for wage bill ratio
cs_wb <- tryCatch({
  att_gt(
    yname = "log_wage_bill_ratio",
    tname = "period",
    idname = "state_id",
    gname = "first_treat_period",
    data = as.data.frame(cs_data),
    control_group = "nevertreated",
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS-DiD wage bill error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_wb)) {
  cs_wb_agg <- aggte(cs_wb, type = "simple")
  cat("\nCS-DiD ATT (wage bill ratio):\n")
  cat("  ATT:", round(cs_wb_agg$overall.att, 4),
      " SE:", round(cs_wb_agg$overall.se, 4), "\n")
}

# ==============================================================================
# Save results
# ==============================================================================

results <- list(
  m1_earns = m1_earns,
  m1_emp = m1_emp,
  m1_wb = m1_wb,
  m2_earns = m2_earns,
  m2_emp = m2_emp,
  m2_wb = m2_wb,
  cs_earns = cs_earns,
  cs_wb = cs_wb,
  cs_earns_es = if (exists("cs_earns_es")) cs_earns_es else NULL,
  cs_data = cs_data
)

saveRDS(results, "../data/main_results.rds")
cat("\nMain analysis complete. Results saved.\n")
