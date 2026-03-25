# 04_robustness.R — Robustness checks for MAID DiD
# apep_0920: MAID Laws and End-of-Life Medicare Spending

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

county <- readRDS(file.path(data_dir, "county_panel_clean.rds"))
state_panel <- readRDS(file.path(data_dir, "panel_clean.rds"))

# Estimation sample (same as main analysis)
always_treated_fips <- c("41", "53", "30", "50")

est_county <- county %>%
  filter(!state_fips %in% c("72", "78"),
         !state_fips %in% always_treated_fips) %>%
  filter(!is.na(county_fips)) %>%
  mutate(
    first_treat_cs = if_else(is.na(maid_year) | maid_year < 2014, 0L, as.integer(maid_year)),
    treated_post = if_else(!is.na(maid_year) & year >= maid_year, 1L, 0L),
    state_id = as.integer(factor(state_fips)),
    county_id_num = as.integer(factor(county_fips))
  )

# ============================================================================
# 1. PLACEBO OUTCOMES — Non-terminal Medicare spending categories
# ============================================================================

cat("=== Placebo Outcomes (should show no effect) ===\n")

# SNF and Home Health are not end-of-life specific — MAID shouldn't affect them
placebo_outcomes <- list(
  snf_stdzd_pymt_pc = "SNF spending per capita (placebo)",
  hh_stdzd_pymt_pc = "Home health spending per capita (placebo)"
)

placebo_results <- list()
for (outcome_var in names(placebo_outcomes)) {
  est_df <- est_county %>% filter(!is.na(.data[[outcome_var]]))
  twfe <- feols(
    as.formula(paste0(outcome_var, " ~ treated_post | county_id_num + year")),
    data = est_df,
    cluster = ~state_id
  )
  placebo_results[[outcome_var]] <- twfe
  cat(outcome_var, ": beta =", round(coef(twfe)["treated_post"], 3),
      " SE =", round(se(twfe)["treated_post"], 3),
      " t =", round(tstat(twfe)["treated_post"], 3), "\n")
}

# ============================================================================
# 2. INCLUDE ALWAYS-TREATED STATES
# ============================================================================

cat("\n=== Robustness: Include always-treated states (OR, WA, MT, VT) ===\n")

est_all <- county %>%
  filter(!state_fips %in% c("72", "78")) %>%
  filter(!is.na(county_fips)) %>%
  mutate(
    treated_post = if_else(!is.na(maid_year) & year >= maid_year, 1L, 0L),
    state_id = as.integer(factor(state_fips)),
    county_id_num = as.integer(factor(county_fips))
  )

main_outcomes <- c("hospc_stdzd_pymt_pc", "ip_stdzd_pymt_pc", "tot_stdzd_pymt_pc",
                   "er_visits_per_1000")
always_treat_results <- list()

for (outcome_var in main_outcomes) {
  est_df <- est_all %>% filter(!is.na(.data[[outcome_var]]))
  twfe <- feols(
    as.formula(paste0(outcome_var, " ~ treated_post | county_id_num + year")),
    data = est_df,
    cluster = ~state_id
  )
  always_treat_results[[outcome_var]] <- twfe
  cat(outcome_var, ": beta =", round(coef(twfe)["treated_post"], 3),
      " SE =", round(se(twfe)["treated_post"], 3), "\n")
}

# ============================================================================
# 3. COHORT-BY-COHORT ESTIMATES (heterogeneity across adoption waves)
# ============================================================================

cat("\n=== Cohort-specific estimates ===\n")

cohort_results <- list()
cohorts <- c(2016, 2017, 2019, 2021)

for (g in cohorts) {
  # Compare cohort g to never-treated only
  cohort_df <- est_county %>%
    filter(first_treat_cs %in% c(0, g)) %>%
    filter(!is.na(hospc_stdzd_pymt_pc))

  if (nrow(cohort_df) < 100) next

  twfe <- feols(
    hospc_stdzd_pymt_pc ~ treated_post | county_id_num + year,
    data = cohort_df,
    cluster = ~state_id
  )

  cohort_results[[as.character(g)]] <- twfe
  cat("Cohort", g, ": beta =", round(coef(twfe)["treated_post"], 3),
      " SE =", round(se(twfe)["treated_post"], 3),
      " N_treated =", n_distinct(cohort_df$county_fips[cohort_df$first_treat_cs == g]),
      " N_control =", n_distinct(cohort_df$county_fips[cohort_df$first_treat_cs == 0]),
      "\n")
}

# ============================================================================
# 4. WILD CLUSTER BOOTSTRAP (fix singleton issue)
# ============================================================================

cat("\n=== Wild Cluster Bootstrap (singletons pre-filtered) ===\n")

wcb_results <- list()
key_outcomes <- c("hospc_stdzd_pymt_pc", "ip_stdzd_pymt_pc", "er_visits_per_1000")

for (outcome_var in key_outcomes) {
  # Pre-filter to remove counties with all-NA outcomes
  est_df <- est_county %>%
    filter(!is.na(.data[[outcome_var]])) %>%
    group_by(county_id_num) %>%
    filter(n() == max(n_distinct(est_county$year))) %>%
    ungroup()

  twfe <- feols(
    as.formula(paste0(outcome_var, " ~ treated_post | county_id_num + year")),
    data = est_df,
    cluster = ~state_id,
    fixef.rm = "none"  # Don't remove singletons
  )

  wcb <- tryCatch({
    set.seed(12345)
    boot_out <- boottest(
      twfe,
      param = "treated_post",
      clustid = "state_id",
      B = 9999,
      type = "rademacher",
      impose_null = TRUE
    )
    list(p_value = boot_out$p_val,
         ci_lower = boot_out$conf_int[1],
         ci_upper = boot_out$conf_int[2])
  }, error = function(e) {
    cat("  WCB error for", outcome_var, ":", e$message, "\n")
    list(p_value = NA, ci_lower = NA, ci_upper = NA)
  })

  wcb_results[[outcome_var]] <- wcb
  if (!is.na(wcb$p_value)) {
    cat(outcome_var, ": WCB p =", round(wcb$p_value, 4),
        " 95% CI: [", round(wcb$ci_lower, 2), ",", round(wcb$ci_upper, 2), "]\n")
  }
}

# ============================================================================
# 5. TRIPLE-DIFFERENCE: Non-terminal spending as within-state control
# ============================================================================

cat("\n=== Triple-Difference: Terminal vs Non-Terminal Spending ===\n")

# Stack hospice (terminal indicator = 1) and SNF (terminal indicator = 0)
# within the same county-year
td_data <- est_county %>%
  filter(!is.na(hospc_stdzd_pymt_pc), !is.na(snf_stdzd_pymt_pc)) %>%
  select(county_id_num, year, state_id, first_treat_cs, treated_post,
         hospc_stdzd_pymt_pc, snf_stdzd_pymt_pc) %>%
  pivot_longer(cols = c(hospc_stdzd_pymt_pc, snf_stdzd_pymt_pc),
               names_to = "spending_type", values_to = "spending_pc") %>%
  mutate(
    terminal = if_else(spending_type == "hospc_stdzd_pymt_pc", 1L, 0L),
    ddd_treat = treated_post * terminal
  )

ddd_model <- feols(
  spending_pc ~ ddd_treat + treated_post:terminal | county_id_num^spending_type + year^spending_type,
  data = td_data,
  cluster = ~state_id
)

cat("DDD coefficient (MAID x Terminal):", round(coef(ddd_model)["ddd_treat"], 3),
    " SE:", round(se(ddd_model)["ddd_treat"], 3), "\n")

# ============================================================================
# SAVE ROBUSTNESS RESULTS
# ============================================================================

saveRDS(placebo_results, file.path(data_dir, "placebo_results.rds"))
saveRDS(cohort_results, file.path(data_dir, "cohort_results.rds"))
saveRDS(wcb_results, file.path(data_dir, "wcb_results.rds"))
saveRDS(always_treat_results, file.path(data_dir, "always_treat_results.rds"))

cat("\n=== Robustness checks complete ===\n")
