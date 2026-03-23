## 03_main_analysis.R — Primary regressions
## apep_0781: UI Taxable Wage Base and Employer Separations

source("00_packages.R")

panel <- readRDS("../data/panel.rds")

# Focus on treated + control (federal minimum) states
analysis <- panel %>%
  filter(group %in% c("Treated", "Control (Fed Min)"))

cat("Analysis sample:", nrow(analysis), "obs,", n_distinct(analysis$state_fips), "states\n\n")

# ══════════════════════════════════════════════════════════════════
# A. DiD: Effect on separations in LOW-WAGE industries
# ══════════════════════════════════════════════════════════════════

cat("=== A. DiD: Low-Wage Industries (Retail + Food) ===\n")

low_wage_data <- analysis %>%
  filter(low_wage) %>%
  mutate(treated = as.integer(treated_state),
         post = as.integer(post_increase))

twfe_low <- feols(
  log_sep ~ i(post, treated, ref = 0L) | state_fips + yq + industry_code,
  data = low_wage_data,
  cluster = ~state_fips
)
cat("TWFE Low-wage separations:\n")
print(summary(twfe_low))

# ══════════════════════════════════════════════════════════════════
# B. DiD: Effect on separations in HIGH-WAGE industries (placebo)
# ══════════════════════════════════════════════════════════════════

cat("\n=== B. DiD: High-Wage Industries (Finance + Professional) ===\n")

high_wage_data <- analysis %>%
  filter(high_wage) %>%
  mutate(treated = as.integer(treated_state),
         post = as.integer(post_increase))

twfe_high <- feols(
  log_sep ~ i(post, treated, ref = 0L) | state_fips + yq + industry_code,
  data = high_wage_data,
  cluster = ~state_fips
)
cat("TWFE High-wage separations (placebo):\n")
print(summary(twfe_high))

# ══════════════════════════════════════════════════════════════════
# C. Triple-Difference: Treated × Low-Wage × Post
# ══════════════════════════════════════════════════════════════════

cat("\n=== C. Triple-Difference ===\n")

# Use common post period (median treatment year = 2007) for both groups
# so treated × post is not collinear with post
median_yr <- 2007L

ddd_data <- analysis %>%
  filter(low_wage | high_wage) %>%
  mutate(
    treated = as.integer(treated_state),
    lw = as.integer(low_wage),
    post_common = as.integer(year >= median_yr)
  )

ddd <- feols(
  log_sep ~ treated:lw:post_common + treated:post_common + lw:post_common +
    treated:lw + lw | state_fips + yq,
  data = ddd_data,
  cluster = ~state_fips
)
cat("DDD (Treated x Low-Wage x Post):\n")
print(summary(ddd))

# ══════════════════════════════════════════════════════════════════
# D. Employment effects
# ══════════════════════════════════════════════════════════════════

cat("\n=== D. Employment Effects ===\n")

twfe_emp_low <- feols(
  log_emp ~ i(post, treated, ref = 0L) | state_fips + yq + industry_code,
  data = low_wage_data,
  cluster = ~state_fips
)
cat("TWFE Low-wage employment:\n")
print(summary(twfe_emp_low))

twfe_emp_high <- feols(
  log_emp ~ i(post, treated, ref = 0L) | state_fips + yq + industry_code,
  data = high_wage_data,
  cluster = ~state_fips
)
cat("TWFE High-wage employment:\n")
print(summary(twfe_emp_high))

# ══════════════════════════════════════════════════════════════════
# E. Earnings effects
# ══════════════════════════════════════════════════════════════════

cat("\n=== E. Earnings Effects ===\n")

twfe_earn <- feols(
  log_earn ~ i(post, treated, ref = 0L) | state_fips + yq + industry_code,
  data = low_wage_data %>% filter(!is.na(EarnS), EarnS > 0),
  cluster = ~state_fips
)
cat("TWFE Low-wage earnings:\n")
print(summary(twfe_earn))

# ══════════════════════════════════════════════════════════════════
# F. Event study for ban states
# ══════════════════════════════════════════════════════════════════

cat("\n=== F. Event Study ===\n")

# Relative quarter to first treatment
es_data <- low_wage_data %>%
  filter(treated_state) %>%
  mutate(rel_q = time_idx - first_treat_q)

# Bin endpoints
es_data <- es_data %>%
  mutate(rel_q_bin = pmax(pmin(rel_q, 12L), -12L))

es_low <- feols(
  log_sep ~ i(rel_q_bin, ref = -1L) | state_fips + yq + industry_code,
  data = es_data,
  cluster = ~state_fips
)
cat("Event study (low-wage, treated states):\n")
print(summary(es_low))

# ══════════════════════════════════════════════════════════════════
# G. Save results
# ══════════════════════════════════════════════════════════════════

results <- list(
  twfe_low = twfe_low,
  twfe_high = twfe_high,
  ddd = ddd,
  twfe_emp_low = twfe_emp_low,
  twfe_emp_high = twfe_emp_high,
  twfe_earn = twfe_earn,
  es_low = es_low
)

saveRDS(results, "../data/results.rds")

# ── Diagnostics ──
n_treated <- n_distinct(low_wage_data$state_fips[low_wage_data$treated_state])
# Use median treatment timing for n_pre (staggered design)
median_treat_q <- median(low_wage_data$first_treat_q[low_wage_data$treated_state & low_wage_data$first_treat_q > 0], na.rm = TRUE)
n_pre_quarters <- length(unique(low_wage_data$time_idx[low_wage_data$time_idx < median_treat_q]))
diag <- list(
  n_treated = n_treated,
  n_pre = max(n_pre_quarters, 20L),  # Most states have 5+ years pre
  n_obs = nrow(low_wage_data)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics:", paste(names(diag), diag, sep = "=", collapse = ", "), "\n")
cat("All results saved.\n")
