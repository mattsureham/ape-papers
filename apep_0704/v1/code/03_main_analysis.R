## 03_main_analysis.R — Main DiD analysis for PSL paper
## apep_0704: Paid Sick Leave and Worker Separation Dynamics

source("00_packages.R")

cat("=== Running main analysis ===\n")

# ── Load cleaned data ──
qwi_main <- readRDS("../data/qwi_main.rds")

# ────────────────────────────────────────────────────────────────────
# TABLE 1: Summary Statistics
# ────────────────────────────────────────────────────────────────────
cat("\n--- Table 1: Summary Statistics ---\n")

hi_exp <- qwi_main %>% filter(high_exposure)

sumstats_pre <- hi_exp %>%
  filter(!post) %>%
  group_by(treated_state) %>%
  summarise(
    N = n(),
    States = n_distinct(state_abbr),
    mean_sep = mean(sep_rate, na.rm = TRUE),
    sd_sep = sd(sep_rate, na.rm = TRUE),
    mean_hire = mean(hire_rate, na.rm = TRUE),
    mean_turnover = mean(turnover_rate, na.rm = TRUE),
    mean_earnings = mean(earnings, na.rm = TRUE),
    mean_emp = mean(Emp, na.rm = TRUE),
    .groups = "drop"
  )
cat("Pre-treatment means (high-exposure industries):\n")
print(sumstats_pre)

# ────────────────────────────────────────────────────────────────────
# TABLE 2: DDD — Treated × Post × High-Exposure (main specification)
# ────────────────────────────────────────────────────────────────────
cat("\n--- Table 2: Triple-Difference ---\n")

ddd_data <- qwi_main %>%
  filter(industry %in% c("72", "44-45", "62", "52", "54")) %>%
  mutate(
    treated_post_high = treated_state & post & high_exposure
  )

# Main DDD with three-way FEs
ddd_sep <- feols(
  sep_rate ~ treated_post_high |
    state_abbr^industry + state_abbr^time_period + industry^time_period,
  data = ddd_data,
  cluster = ~state_abbr
)

ddd_hire <- feols(
  hire_rate ~ treated_post_high |
    state_abbr^industry + state_abbr^time_period + industry^time_period,
  data = ddd_data,
  cluster = ~state_abbr
)

ddd_newhire <- feols(
  new_hire_rate ~ treated_post_high |
    state_abbr^industry + state_abbr^time_period + industry^time_period,
  data = ddd_data,
  cluster = ~state_abbr
)

ddd_turnover <- feols(
  turnover_rate ~ treated_post_high |
    state_abbr^industry + state_abbr^time_period + industry^time_period,
  data = ddd_data,
  cluster = ~state_abbr
)

cat("\nDDD Results:\n")
etable(ddd_sep, ddd_hire, ddd_newhire, ddd_turnover,
       headers = c("Sep Rate", "Hire Rate", "New Hire Rate", "Turnover"))

# ────────────────────────────────────────────────────────────────────
# TABLE 3: Event Study (Sun-Abraham, high-exposure only)
# ────────────────────────────────────────────────────────────────────
cat("\n--- Table 3: Event Study ---\n")

# Prepare event study data for high-exposure industries
es_data <- hi_exp %>%
  mutate(
    # For sunab: cohort = first treatment period, 0 = never-treated
    cohort = ifelse(is.finite(first_treat_yq),
                    (floor(first_treat_yq) - 2005) * 4 +
                      round((first_treat_yq - floor(first_treat_yq)) * 4) + 1,
                    10000),  # never-treated gets large number
    state_ind = paste(state_abbr, industry, sep = "_")
  )

# Sun-Abraham event study using fixest::sunab()
es_mod <- feols(
  sep_rate ~ sunab(cohort, time_period, ref.p = -1) |
    state_ind + time_period,
  data = es_data,
  cluster = ~state_abbr
)

cat("\nEvent study coefficients:\n")
summary(es_mod)

# Extract event-study coefficients for table
es_coefs <- as.data.frame(coeftable(es_mod))
es_coefs$term <- rownames(es_coefs)
es_coefs <- es_coefs %>%
  filter(grepl("time_period::", term)) %>%
  mutate(
    event_time = as.numeric(gsub(".*::", "", term))
  ) %>%
  arrange(event_time)

cat("\nEvent time coefficients:\n")
print(es_coefs[, c("event_time", "Estimate", "Std. Error", "Pr(>|t|)")])

# ────────────────────────────────────────────────────────────────────
# TWFE comparison (for reference — not preferred)
# ────────────────────────────────────────────────────────────────────
cat("\n--- TWFE Comparison ---\n")

twfe_data <- hi_exp %>%
  mutate(state_ind = paste(state_abbr, industry, sep = "_"))

twfe_sep <- feols(
  sep_rate ~ i(treated_state & post) | state_ind + time_period,
  data = twfe_data,
  cluster = ~state_abbr
)

cat(sprintf("TWFE ATT: %.3f (SE: %.3f)\n",
            coef(twfe_sep)[[1]], se(twfe_sep)[[1]]))

# ────────────────────────────────────────────────────────────────────
# SD(Y) for SDE calculation
# ────────────────────────────────────────────────────────────────────
sd_sep <- sd(hi_exp$sep_rate[!hi_exp$post & hi_exp$treated_state], na.rm = TRUE)
sd_hire <- sd(hi_exp$hire_rate[!hi_exp$post & hi_exp$treated_state], na.rm = TRUE)
sd_turnover <- sd(hi_exp$turnover_rate[!hi_exp$post & hi_exp$treated_state], na.rm = TRUE)

cat(sprintf("\nPre-treatment SD(Y) for treated, high-exposure:\n"))
cat(sprintf("  SD(sep_rate) = %.3f\n", sd_sep))
cat(sprintf("  SD(hire_rate) = %.3f\n", sd_hire))
cat(sprintf("  SD(turnover) = %.3f\n", sd_turnover))

# ────────────────────────────────────────────────────────────────────
# Save results
# ────────────────────────────────────────────────────────────────────
results <- list(
  ddd_sep = ddd_sep,
  ddd_hire = ddd_hire,
  ddd_newhire = ddd_newhire,
  ddd_turnover = ddd_turnover,
  es_mod = es_mod,
  es_coefs = es_coefs,
  twfe_sep = twfe_sep,
  sumstats_pre = sumstats_pre,
  sd_sep = sd_sep,
  sd_hire = sd_hire,
  sd_turnover = sd_turnover,
  ddd_data = ddd_data
)
saveRDS(results, "../data/main_results.rds")

# ── Write diagnostics.json for validator ──
n_treated_cells <- n_distinct(hi_exp$state_abbr[hi_exp$treated_state]) *
                   n_distinct(hi_exp$industry[hi_exp$high_exposure])
# Pre-periods: quarters before first treated state (CT 2012Q1 = period 29)
n_pre <- 28  # 2005Q1 to 2011Q4 = 28 quarters
n_obs <- nrow(ddd_data)

jsonlite::write_json(
  list(
    n_treated = n_treated_cells,  # state × industry cells (16 states × 3 industries)
    n_pre = n_pre,
    n_obs = n_obs
  ),
  "../data/diagnostics.json",
  auto_unbox = TRUE
)

cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            n_treated_states, n_pre, n_obs))
cat("\n=== Main analysis complete ===\n")
