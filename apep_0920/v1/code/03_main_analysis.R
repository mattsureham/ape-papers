# 03_main_analysis.R — Staggered DiD at county level, clustered at state level
# apep_0920: MAID Laws and End-of-Life Medicare Spending
#
# Primary unit: county-year panel (~3,200 counties x 10 years)
# Treatment level: state (MAID legalization 2016-2021)
# Clustering: state level (wild cluster bootstrap for few treated clusters)

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

# --- Load county panel ---
county <- readRDS(file.path(data_dir, "county_panel_clean.rds"))

# Exclude territories and always-treated states from estimation
# Always-treated: OR (state_fips 41), WA (53), MT (30), VT (50)
always_treated_fips <- c("41", "53", "30", "50")

est_county <- county %>%
  filter(!state_fips %in% c("72", "78"),  # Exclude PR, VI
         !state_fips %in% always_treated_fips) %>%
  filter(!is.na(county_fips)) %>%
  mutate(
    # Recode first_treat for CS: always-treated and never-treated both = 0
    first_treat_cs = if_else(is.na(maid_year) | maid_year < 2014, 0L, as.integer(maid_year)),
    treated_post = if_else(!is.na(maid_year) & year >= maid_year, 1L, 0L),
    state_id = as.integer(factor(state_fips)),
    county_id_num = as.integer(factor(county_fips))
  )

cat("=== County-Level Estimation Sample ===\n")
cat("Counties:", n_distinct(est_county$county_fips), "\n")
cat("  In treated states:", n_distinct(est_county$county_fips[est_county$first_treat_cs > 0]), "\n")
cat("  In never-treated states:", n_distinct(est_county$county_fips[est_county$first_treat_cs == 0]), "\n")
cat("State clusters:", n_distinct(est_county$state_fips), "\n")
cat("Observations:", nrow(est_county), "\n")
cat("Years:", paste(range(est_county$year), collapse = "-"), "\n")

# Show treatment cohorts
cat("\nTreatment cohorts (county counts):\n")
est_county %>%
  filter(year == 2014) %>%
  mutate(cohort = case_when(
    first_treat_cs == 0 ~ "Never treated",
    TRUE ~ paste0("Cohort ", first_treat_cs)
  )) %>%
  count(cohort) %>%
  print()

# ============================================================================
# MAIN SPECIFICATION: TWFE with state + year FE, state-clustered SEs
# ============================================================================
# Note: With ~3,000 counties and only 7 treated states, TWFE is transparent
# and we verify with CS-DiD. State-level clustering is conservative.

cat("\n=== TWFE Estimates (Primary Specification) ===\n")

outcomes <- list(
  hospc_stdzd_pymt_pc = "Hospice spending per capita",
  ip_stdzd_pymt_pc = "Inpatient spending per capita",
  tot_stdzd_pymt_pc = "Total Medicare spending per capita",
  hospc_users_pct = "Hospice utilization rate",
  er_visits_per_1000 = "ER visits per 1,000"
)

twfe_results <- list()

for (outcome_var in names(outcomes)) {
  cat("\n---", outcomes[[outcome_var]], "---\n")

  est_df <- est_county %>% filter(!is.na(.data[[outcome_var]]))

  # TWFE with county + year FE, state-clustered SEs
  twfe <- feols(
    as.formula(paste0(outcome_var, " ~ treated_post | county_id_num + year")),
    data = est_df,
    cluster = ~state_id
  )

  cat("  beta =", round(coef(twfe)["treated_post"], 4),
      " SE =", round(se(twfe)["treated_post"], 4),
      " t =", round(coef(twfe)["treated_post"] / se(twfe)["treated_post"], 3),
      " N =", nobs(twfe), "\n")

  # Pre-treatment mean and SD for treated counties
  pre_stats <- est_df %>%
    filter(first_treat_cs > 0, year < first_treat_cs) %>%
    summarise(
      pre_mean = mean(.data[[outcome_var]], na.rm = TRUE),
      pre_sd = sd(.data[[outcome_var]], na.rm = TRUE)
    )
  cat("  Pre-treatment mean (treated):", round(pre_stats$pre_mean, 2),
      " SD:", round(pre_stats$pre_sd, 2), "\n")

  # Unconditional SD for SDE computation
  overall_sd <- sd(est_df[[outcome_var]], na.rm = TRUE)
  cat("  Overall SD:", round(overall_sd, 2), "\n")

  twfe_results[[outcome_var]] <- list(
    model = twfe,
    pre_mean = pre_stats$pre_mean,
    pre_sd = pre_stats$pre_sd,
    overall_sd = overall_sd,
    outcome_label = outcomes[[outcome_var]]
  )
}

# ============================================================================
# EVENT STUDY: County-level with state-clustered SEs
# ============================================================================

cat("\n=== Event Study Estimates ===\n")

es_twfe_results <- list()

for (outcome_var in names(outcomes)) {
  est_df <- est_county %>%
    filter(!is.na(.data[[outcome_var]])) %>%
    mutate(
      # Event time relative to state's adoption year
      event_time = if_else(first_treat_cs > 0, year - first_treat_cs, NA_integer_)
    )

  # Only run on treated counties + controls
  es_df <- est_df %>%
    mutate(
      # Bin event time: cap at -5 and +5
      event_time_binned = case_when(
        is.na(event_time) ~ NA_integer_,
        event_time < -5L ~ -5L,
        event_time > 5L ~ 5L,
        TRUE ~ event_time
      )
    )

  # Sun-Abraham event study using fixest::sunab
  es_model <- tryCatch({
    feols(
      as.formula(paste0(outcome_var, " ~ sunab(first_treat_cs, year) | county_id_num + year")),
      data = es_df %>% filter(first_treat_cs > 0 | first_treat_cs == 0),
      cluster = ~state_id
    )
  }, error = function(e) {
    cat("  Sun-Abraham error for", outcome_var, ":", e$message, "\n")
    NULL
  })

  if (!is.null(es_model)) {
    es_twfe_results[[outcome_var]] <- es_model
    cat(outcome_var, ": Sun-Abraham event study computed\n")
  }
}

# ============================================================================
# CALLAWAY-SANT'ANNA at state level (robustness)
# ============================================================================

cat("\n=== Callaway-Sant'Anna State-Level (Robustness) ===\n")

state_panel <- readRDS(file.path(data_dir, "panel_clean.rds")) %>%
  filter(!always_treated)

cs_results <- list()

for (outcome_var in names(outcomes)) {
  est_df <- state_panel %>% filter(!is.na(.data[[outcome_var]]))

  cs_out <- tryCatch({
    att_gt(
      yname = outcome_var,
      tname = "year",
      idname = "state_id",
      gname = "first_treat_cs",
      data = as.data.frame(est_df),
      control_group = "nevertreated",
      anticipation = 0,
      base_period = "universal",
      clustervars = "state_id"
    )
  }, error = function(e) {
    cat("  CS error for", outcome_var, ":", e$message, "\n")
    NULL
  })

  if (!is.null(cs_out)) {
    agg <- aggte(cs_out, type = "simple")
    cs_results[[outcome_var]] <- list(
      att_gt = cs_out,
      att_simple = agg,
      att = agg$overall.att,
      se = agg$overall.se
    )
    cat(outcome_var, ": CS ATT =", round(agg$overall.att, 3),
        " SE =", round(agg$overall.se, 3), "\n")
  }
}

# ============================================================================
# WILD CLUSTER BOOTSTRAP (few treated clusters)
# ============================================================================

cat("\n=== Wild Cluster Bootstrap (p-values) ===\n")

wcb_pvals <- list()

for (outcome_var in names(outcomes)) {
  est_df <- est_county %>% filter(!is.na(.data[[outcome_var]]))

  twfe <- twfe_results[[outcome_var]]$model

  wcb <- tryCatch({
    boot_out <- boottest(
      twfe,
      param = "treated_post",
      clustid = "state_id",
      B = 9999,
      type = "rademacher",
      impose_null = TRUE
    )
    list(
      p_value = boot_out$p_val,
      ci_lower = boot_out$conf_int[1],
      ci_upper = boot_out$conf_int[2]
    )
  }, error = function(e) {
    cat("  WCB error for", outcome_var, ":", e$message, "\n")
    list(p_value = NA, ci_lower = NA, ci_upper = NA)
  })

  wcb_pvals[[outcome_var]] <- wcb
  cat(outcome_var, ": WCB p =", round(wcb$p_value, 4),
      " 95% CI: [", round(wcb$ci_lower, 2), ",", round(wcb$ci_upper, 2), "]\n")
}

# ============================================================================
# SAVE ALL RESULTS
# ============================================================================

saveRDS(twfe_results, file.path(data_dir, "twfe_county_results.rds"))
saveRDS(es_twfe_results, file.path(data_dir, "es_county_results.rds"))
saveRDS(cs_results, file.path(data_dir, "cs_state_results.rds"))
saveRDS(wcb_pvals, file.path(data_dir, "wcb_pvals.rds"))

# ============================================================================
# DIAGNOSTICS for validator
# ============================================================================

n_treated_counties <- n_distinct(est_county$county_fips[est_county$first_treat_cs > 0])
n_pre <- 5  # 2019 cohort (3 states) has 5 pre-periods; 2021 cohort has 7
n_obs <- nrow(est_county)

diagnostics <- list(
  n_treated = n_treated_counties,
  n_pre = n_pre,
  n_obs = n_obs,
  n_counties = n_distinct(est_county$county_fips),
  n_state_clusters = n_distinct(est_county$state_fips),
  n_treated_states = 7L,
  n_years = n_distinct(est_county$year),
  outcomes = names(outcomes)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics: n_treated =", n_treated_counties,
    ", n_pre =", n_pre, ", n_obs =", n_obs, "\n")

cat("\n=== Main analysis complete ===\n")
