## ==========================================================================
## 04_robustness.R — Robustness Checks for Constitutional Carry
## ==========================================================================

source("00_packages.R")
data_dir <- "../data"

panel_a <- fread(file.path(data_dir, "panel_a_suicide.csv"))
panel_c <- fread(file.path(data_dir, "panel_c_nics.csv"))
panel_b <- fread(file.path(data_dir, "panel_b_firearm.csv"))

panel_a[, state_id := as.integer(as.factor(state))]
panel_b[, state_id := as.integer(as.factor(state))]
panel_c[, state_id := as.integer(as.factor(state))]

## ==========================================================================
## 1. BACON DECOMPOSITION (Panel A — Suicide)
## ==========================================================================

cat("=== Bacon Decomposition ===\n")

# bacondecomp needs a balanced panel with binary treatment
bacon_data <- panel_a[, .(state, year, suicide_rate, treated, state_id)]
bacon_data <- bacon_data[complete.cases(bacon_data)]

bacon_out <- tryCatch({
  bacon(suicide_rate ~ treated, data = as.data.frame(bacon_data),
        id_var = "state_id", time_var = "year")
}, error = function(e) { cat("Bacon error:", e$message, "\n"); NULL })

if (!is.null(bacon_out)) {
  cat("\nBacon decomposition summary:\n")
  bacon_summary <- bacon_out %>%
    group_by(type) %>%
    summarise(
      n_comparisons = n(),
      mean_estimate = weighted.mean(estimate, weight),
      total_weight = sum(weight),
      .groups = "drop"
    )
  print(bacon_summary)
  fwrite(as.data.table(bacon_out), file.path(data_dir, "bacon_decomposition.csv"))
  fwrite(as.data.table(bacon_summary), file.path(data_dir, "bacon_summary.csv"))
}

## ==========================================================================
## 2. PRE-2020 SUBSAMPLE (COVID Robustness — Panel A)
## ==========================================================================

cat("\n=== Pre-2020 Subsample (Panel A) ===\n")

# Only 2010-2017 cohorts are treated before 2020
panel_a_pre <- panel_a[year <= 2017]  # Panel A already stops at 2017

twfe_suicide_pre <- feols(suicide_rate ~ treated | state_id + year,
                          data = panel_a_pre, cluster = ~state_id)

cat("TWFE Suicide (pre-2020 subsample, same as full Panel A):\n")
print(summary(twfe_suicide_pre))

## ==========================================================================
## 3. HETEROGENEITY: EARLY vs LATE ADOPTERS
## ==========================================================================

cat("\n=== Heterogeneity: Early vs Late Adopters ===\n")

# Early: 2010-2017, Late: 2019+
panel_a[, cohort_group := case_when(
  first_treat == 0 ~ "Never treated",
  first_treat <= 2017 ~ "Early (2010-2017)",
  TRUE ~ "Late (2019+)"
)]

twfe_early <- feols(suicide_rate ~ treated | state_id + year,
                    data = panel_a[cohort_group %in% c("Never treated", "Early (2010-2017)")],
                    cluster = ~state_id)

cat("Early adopters only (2010-2017):\n")
print(summary(twfe_early))

## ==========================================================================
## 4. CS-DiD WITH COVARIATES
## ==========================================================================

cat("\n=== CS-DiD with Covariates (Panel A) ===\n")

cs_cov <- tryCatch({
  att_gt(yname = "suicide_rate",
         tname = "year",
         idname = "state_id",
         gname = "first_treat",
         xformla = ~ poverty_rate + pct_black + log_pop,
         data = as.data.frame(panel_a[complete.cases(panel_a[, .(poverty_rate, pct_black, log_pop)])]),
         control_group = "nevertreated",
         anticipation = 0,
         base_period = "universal",
         clustervars = "state_id",
         print_details = FALSE)
}, error = function(e) { cat("CS cov error:", e$message, "\n"); NULL })

if (!is.null(cs_cov)) {
  cs_cov_agg <- aggte(cs_cov, type = "simple")
  cat("CS-DiD Suicide with covariates:\n")
  print(summary(cs_cov_agg))
}

## ==========================================================================
## 5. GROUP-SPECIFIC EFFECTS (CS-DiD)
## ==========================================================================

cat("\n=== Group-Specific Effects ===\n")

cs_suicide_main <- tryCatch({
  att_gt(yname = "suicide_rate",
         tname = "year",
         idname = "state_id",
         gname = "first_treat",
         data = as.data.frame(panel_a),
         control_group = "nevertreated",
         anticipation = 0,
         base_period = "universal",
         clustervars = "state_id",
         print_details = FALSE)
}, error = function(e) { cat("CS error:", e$message, "\n"); NULL })

if (!is.null(cs_suicide_main)) {
  cs_group <- aggte(cs_suicide_main, type = "group")
  cat("Group-specific ATTs:\n")
  print(summary(cs_group))

  group_data <- data.table(
    cohort = cs_group$egt,
    att = cs_group$att.egt,
    se = cs_group$se.egt,
    ci_lower = cs_group$att.egt - 1.96 * cs_group$se.egt,
    ci_upper = cs_group$att.egt + 1.96 * cs_group$se.egt
  )
  fwrite(group_data, file.path(data_dir, "cs_group_effects.csv"))
}

## ==========================================================================
## 6. LEAVE-ONE-COHORT-OUT
## ==========================================================================

cat("\n=== Leave-One-Cohort-Out ===\n")

cohorts <- sort(unique(panel_a$first_treat[panel_a$first_treat > 0]))
loo_results <- list()

for (g in cohorts) {
  loo_data <- panel_a[first_treat != g]
  loo_mod <- feols(suicide_rate ~ treated | state_id + year,
                   data = loo_data, cluster = ~state_id)
  loo_results[[as.character(g)]] <- data.table(
    dropped_cohort = g,
    coef = coef(loo_mod),
    se = se(loo_mod),
    pval = fixest::pvalue(loo_mod),
    n_obs = nobs(loo_mod)
  )
}

loo_dt <- rbindlist(loo_results)
cat("Leave-one-cohort-out results:\n")
print(loo_dt)
fwrite(loo_dt, file.path(data_dir, "leave_one_out.csv"))

## ==========================================================================
## 7. RANDOMIZATION INFERENCE (Panel A — Suicide)
## ==========================================================================

cat("\n=== Randomization Inference ===\n")

set.seed(42)
n_perms <- 500

# Observed ATT
obs_coef <- coef(feols(suicide_rate ~ treated | state_id + year,
                       data = panel_a, cluster = ~state_id))

# Get treated states and their treatment years
treated_states <- unique(panel_a[first_treat > 0, .(state_id, first_treat)])
n_treated <- nrow(treated_states)
all_state_ids <- unique(panel_a$state_id)

perm_coefs <- numeric(n_perms)

for (i in 1:n_perms) {
  if (i %% 100 == 0) cat("  Permutation", i, "/", n_perms, "\n")

  # Randomly reassign treatment years to random states
  perm_states <- sample(all_state_ids, n_treated, replace = FALSE)
  perm_years <- sample(treated_states$first_treat)

  perm_data <- copy(panel_a)
  perm_data[, first_treat_perm := 0L]
  for (j in 1:n_treated) {
    perm_data[state_id == perm_states[j], first_treat_perm := perm_years[j]]
  }
  perm_data[, treated_perm := as.integer(first_treat_perm > 0 & year >= first_treat_perm)]

  perm_mod <- tryCatch(
    feols(suicide_rate ~ treated_perm | state_id + year,
          data = perm_data, cluster = ~state_id),
    error = function(e) NULL
  )
  if (!is.null(perm_mod)) perm_coefs[i] <- coef(perm_mod)
}

ri_pval <- mean(abs(perm_coefs) >= abs(obs_coef))
cat("Observed coefficient:", round(obs_coef, 3), "\n")
cat("RI p-value (two-sided):", round(ri_pval, 3), "\n")

ri_data <- data.table(
  perm_coef = perm_coefs,
  obs_coef = obs_coef,
  ri_pval = ri_pval
)
fwrite(ri_data, file.path(data_dir, "randomization_inference.csv"))

## ==========================================================================
## 8. DOSE-RESPONSE: YEARS SINCE ADOPTION
## ==========================================================================

cat("\n=== Dose-Response ===\n")

panel_a[, years_since := ifelse(first_treat > 0 & year >= first_treat,
                                year - first_treat, NA_integer_)]
panel_a[, dose_group := case_when(
  is.na(years_since) ~ "Never treated",
  years_since == 0 ~ "Year 0",
  years_since <= 2 ~ "Years 1-2",
  years_since <= 4 ~ "Years 3-4",
  TRUE ~ "Years 5+"
)]
panel_a[, dose_group := factor(dose_group, levels = c("Never treated", "Year 0",
                                                       "Years 1-2", "Years 3-4", "Years 5+"))]

dose_mod <- feols(suicide_rate ~ i(dose_group, ref = "Never treated") | state_id + year,
                  data = panel_a, cluster = ~state_id)
cat("Dose-response:\n")
print(summary(dose_mod))

dose_data <- as.data.table(coeftable(dose_mod))
dose_data$dose <- c("Year 0", "Years 1-2", "Years 3-4", "Years 5+")
fwrite(dose_data, file.path(data_dir, "dose_response.csv"))

## ==========================================================================
## 9. WELFARE CALCULATION
## ==========================================================================

cat("\n=== Welfare Calculation ===\n")

# Use CS-DiD ATT for suicide (Panel A) and FA suicide (Panel B TWFE)
# VSL = $11.6M (2023 DOT)
vsl <- 11.6e6

# Panel A suicide ATT — extract from re-estimated TWFE
twfe_welfare <- feols(suicide_rate ~ treated | state_id + year,
                      data = panel_a, cluster = ~state_id)
suicide_att <- coef(twfe_welfare)[["treated"]]
avg_pop <- mean(panel_a[treated == 1]$population, na.rm = TRUE)
n_treated_states <- n_distinct(panel_a[treated == 1]$state)

# Excess deaths per year across treated states
excess_deaths_per_state <- suicide_att * avg_pop / 100000
total_excess_deaths <- excess_deaths_per_state * n_treated_states

welfare_cost <- total_excess_deaths * vsl
permit_fee_savings <- 150 * 500000 * n_treated_states  # ~$150 × ~500K permit holders per state

cat("Suicide ATT:", suicide_att, "per 100K\n")
cat("Average treated-state population:", round(avg_pop), "\n")
cat("Treated states:", n_treated_states, "\n")
cat("Excess deaths per state per year:", round(excess_deaths_per_state, 1), "\n")
cat("Total excess deaths per year:", round(total_excess_deaths, 0), "\n")
cat("Annual welfare cost (VSL):", format(welfare_cost, big.mark = ","), "\n")
cat("Annual permit fee savings:", format(permit_fee_savings, big.mark = ","), "\n")
cat("Net welfare cost:", format(welfare_cost - permit_fee_savings, big.mark = ","), "\n")

welfare_data <- data.table(
  metric = c("Suicide ATT (per 100K)", "Avg treated population",
             "N treated states", "Excess deaths/state/year",
             "Total excess deaths/year", "Annual welfare cost ($)",
             "Annual permit savings ($)", "Net welfare cost ($)"),
  value = c(suicide_att, avg_pop, n_treated_states,
            excess_deaths_per_state, total_excess_deaths,
            welfare_cost, permit_fee_savings, welfare_cost - permit_fee_savings)
)
fwrite(welfare_data, file.path(data_dir, "welfare_calculation.csv"))

## ==========================================================================
## 10. COLLECT ROBUSTNESS SUMMARY
## ==========================================================================

cat("\n=== Robustness Summary ===\n")

# Re-estimate models to extract coefficients programmatically
twfe_base <- feols(suicide_rate ~ treated | state_id + year,
                   data = panel_a, cluster = ~state_id)
twfe_cov <- feols(suicide_rate ~ treated + poverty_rate + pct_black + log_pop +
                    median_income | state_id + year,
                  data = panel_a, cluster = ~state_id)
sa_mod <- feols(suicide_rate ~ sunab(first_treat, year) | state_id + year,
                data = panel_a[first_treat != 0 | ever_treated == FALSE],
                cluster = ~state_id)
sa_att_val <- summary(sa_mod, agg = "ATT")$coeftable["ATT", 1]

# CS-DiD values from saved results
cs_vals <- fread(file.path(data_dir, "cs_results.csv"))
cs_nocov_val <- cs_vals[panel == "A" & outcome == "Suicide Rate"]$coef[1]
cs_cov_val <- if (!is.null(cs_cov)) aggte(cs_cov, type = "simple")$overall.att else NA_real_

robustness_summary <- data.table(
  check = c("TWFE (baseline)", "TWFE + covariates", "Sun-Abraham IW",
            "CS-DiD (no cov)", "CS-DiD (with cov)",
            "Early adopters only", "Randomization inference"),
  outcome = "Suicide Rate",
  coef = c(coef(twfe_base)[["treated"]], coef(twfe_cov)[["treated"]], sa_att_val,
           cs_nocov_val, cs_cov_val,
           coef(twfe_early)[["treated"]], coef(twfe_base)[["treated"]]),
  note = c("", "", "", "", "",
           "", paste0("RI p = ", round(ri_pval, 3)))
)
fwrite(robustness_summary, file.path(data_dir, "robustness_summary.csv"))

cat("\n=== Robustness checks complete ===\n")
