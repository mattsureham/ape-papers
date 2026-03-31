# ==============================================================================
# 04_robustness.R — Robustness checks and placebos
# apep_1211: Medicaid Reimbursement and Black-White Nursing Home Earnings Gap
# ==============================================================================

source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")

# ==============================================================================
# 1. Placebo Industry: Accommodation (NAICS 721)
# ==============================================================================
# Hotels are demographically similar to nursing homes (large Black workforce)
# but not dependent on Medicaid reimbursement.

cat("=== Placebo: Accommodation (NAICS 721) ===\n")

placebo_df <- df |>
  filter(industry %in% c("721", "621")) |>
  group_by(state_fips, year, race, black, industry,
           nursing_home, treat_year, post, ind_label) |>
  summarise(
    EarnS = weighted.mean(EarnS, Emp, na.rm = TRUE),
    Emp = sum(Emp, na.rm = TRUE),
    log_earn = log(weighted.mean(EarnS, Emp, na.rm = TRUE)),
    .groups = "drop"
  ) |>
  mutate(
    hotel = as.integer(industry == "721")
  )

# DDD with hotels instead of nursing homes
m_placebo <- feols(
  log_earn ~ post:black:hotel + post:hotel + post:black |
    state_fips^year + industry^race + state_fips^industry + state_fips^race,
  data = placebo_df,
  cluster = ~state_fips
)

cat("Placebo DDD (Hotels vs Ambulatory):\n")
summary(m_placebo)

# ==============================================================================
# 2. Employment Effects (extensive margin)
# ==============================================================================
# Check whether rate increases affect employment levels, not just earnings

cat("\n=== Employment Effects ===\n")

emp_df <- df |>
  filter(industry %in% c("623", "621")) |>
  group_by(state_fips, year, race, black, industry, nursing_home,
           treat_year, post) |>
  summarise(
    Emp = sum(Emp, na.rm = TRUE),
    HirN = sum(HirN, na.rm = TRUE),
    Sep = sum(Sep, na.rm = TRUE),
    log_emp = log(sum(Emp, na.rm = TRUE)),
    .groups = "drop"
  )

# DDD on log employment
m_emp <- feols(
  log_emp ~ post:black:nursing_home + post:nursing_home + post:black |
    state_fips^year + industry^race + state_fips^industry + state_fips^race,
  data = emp_df,
  cluster = ~state_fips
)

cat("Employment DDD:\n")
summary(m_emp)

# DDD on new hires
m_hires <- feols(
  log(HirN + 1) ~ post:black:nursing_home + post:nursing_home + post:black |
    state_fips^year + industry^race + state_fips^industry + state_fips^race,
  data = emp_df,
  cluster = ~state_fips
)

cat("\nNew Hires DDD:\n")
summary(m_hires)

# ==============================================================================
# 3. Leave-One-Out: Drop each treated state
# ==============================================================================

cat("\n=== Leave-One-Out Sensitivity ===\n")

treated_states <- unique(df$state_fips[df$treat_year > 0])

ddd_annual <- df |>
  filter(industry %in% c("623", "621")) |>
  group_by(state_fips, year, race, black, industry, nursing_home,
           treat_year, post) |>
  summarise(
    log_earn = log(weighted.mean(EarnS, Emp, na.rm = TRUE)),
    .groups = "drop"
  )

loo_results <- map_dfr(treated_states, function(drop_state) {
  loo_data <- ddd_annual |> filter(state_fips != drop_state)
  m <- feols(
    log_earn ~ post:black:nursing_home + post:nursing_home + post:black |
      state_fips^year + industry^race + state_fips^industry + state_fips^race,
    data = loo_data,
    cluster = ~state_fips
  )
  tibble(
    dropped_state = drop_state,
    coef = coef(m)["post:black:nursing_home"],
    se = se(m)["post:black:nursing_home"]
  )
})

cat("Leave-one-out range:\n")
cat(sprintf("  Min coef: %.4f (dropping state %d)\n",
            min(loo_results$coef), loo_results$dropped_state[which.min(loo_results$coef)]))
cat(sprintf("  Max coef: %.4f (dropping state %d)\n",
            max(loo_results$coef), loo_results$dropped_state[which.max(loo_results$coef)]))
cat(sprintf("  Full sample coef: %.4f\n", coef(results$ddd_basic)["post:black:nursing_home"]))

# ==============================================================================
# 4. Wild Cluster Bootstrap (few-cluster inference)
# ==============================================================================

cat("\n=== Wild Cluster Bootstrap ===\n")

# fwildclusterboot doesn't support ^ notation — re-estimate with | notation
ddd_for_boot <- ddd_annual |>
  mutate(
    fe_sy = paste(state_fips, year, sep = "_"),
    fe_ir = paste(industry, race, sep = "_"),
    fe_si = paste(state_fips, industry, sep = "_"),
    fe_sr = paste(state_fips, race, sep = "_")
  )

m_boot <- feols(
  log_earn ~ post:black:nursing_home + post:nursing_home + post:black |
    fe_sy + fe_ir + fe_si + fe_sr,
  data = ddd_for_boot,
  cluster = ~state_fips
)

if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)
  boot_result <- tryCatch({
    bt <- boottest(
      m_boot,
      param = "post:black:nursing_home",
      clustid = ~state_fips,
      B = 9999,
      type = "webb"
    )
    cat("Wild cluster bootstrap p-value:", bt$p_val, "\n")
    cat("Bootstrap CI:", bt$conf_int, "\n")
    bt
  }, error = function(e) {
    cat("Bootstrap failed:", e$message, "\n")
    NULL
  })
} else {
  cat("fwildclusterboot not installed — skipping.\n")
  boot_result <- NULL
}

# ==============================================================================
# 5. Pre-treatment trend test
# ==============================================================================

cat("\n=== Pre-Treatment Trend Test ===\n")

# Use event-time dummies within the DDD framework
# Include both treated and control states; controls have event_time = NA (dropped)
ddd_event <- df |>
  filter(industry %in% c("623", "621")) |>
  mutate(event_time = ifelse(treat_year > 0, year - treat_year, NA_integer_)) |>
  filter(!is.na(event_time)) |>
  filter(event_time >= -5, event_time <= 4) |>
  group_by(state_fips, year, race, black, industry, nursing_home,
           event_time) |>
  summarise(
    log_earn = log(weighted.mean(EarnS, Emp, na.rm = TRUE)),
    .groups = "drop"
  )

# Event study: interact event-time dummies with Black × NH
m_event <- feols(
  log_earn ~ i(event_time, I(black * nursing_home), ref = -1) |
    state_fips^year + industry^race + state_fips^industry + state_fips^race,
  data = ddd_event,
  cluster = ~state_fips
)

cat("Event study coefficients (DDD):\n")
summary(m_event)

# Joint F-test on pre-treatment coefficients
pre_coefs <- grep("event_time::-[2-5]:", names(coef(m_event)), value = TRUE)
if (length(pre_coefs) > 0) {
  f_test <- tryCatch(wald(m_event, pre_coefs), error = function(e) NULL)
  if (!is.null(f_test) && is.list(f_test)) {
    cat(sprintf("\nJoint pre-trend F-test: stat = %.2f, p = %.3f\n",
                f_test$stat, f_test$p))
  } else {
    cat("\nF-test returned non-standard format — see event study coefficients above.\n")
  }
}

# ==============================================================================
# 6. Save robustness results
# ==============================================================================

rob_results <- list(
  placebo_hotel = m_placebo,
  emp_ddd = m_emp,
  hires_ddd = m_hires,
  loo = loo_results,
  boot = boot_result,
  event_study_ddd = m_event
)

saveRDS(rob_results, "../data/robustness_results.rds")

cat("\nRobustness results saved.\n")
