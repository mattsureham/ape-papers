# =============================================================================
# 03_main_analysis.R — Main DDD regressions for apep_0663
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds")

# =============================================================================
# 1. SUMMARY STATISTICS
# =============================================================================

sumstats <- panel %>%
  group_by(expansion_state, high_esi) %>%
  summarise(
    across(c(hire_rate, sep_rate, hira_rate, net_job_creation, Emp),
           list(mean = ~mean(., na.rm = TRUE), sd = ~sd(., na.rm = TRUE))),
    n = n(),
    .groups = "drop"
  )

# Full sample summary stats for SDE computation
full_stats <- panel %>%
  summarise(
    across(c(hire_rate, sep_rate, hira_rate, net_job_creation, log_earnings),
           list(mean = ~mean(., na.rm = TRUE), sd = ~sd(., na.rm = TRUE)),
           .names = "{.col}_{.fn}"),
    N = n()
  )

saveRDS(sumstats, "../data/sumstats.rds")
saveRDS(full_stats, "../data/full_stats.rds")

# =============================================================================
# 2. TRIPLE-DIFFERENCE (DDD): Expansion × Post × High-ESI
# =============================================================================

cat("\n=== Triple-Difference Results ===\n")

# Main DDD specification with three-way FE
# Y = β(Expand × Post × HighESI) + state×industry FE + industry×time FE + state×time FE + ε
# The three-way FE absorb all two-way interactions except the triple interaction

ddd_hire <- feols(
  hire_rate ~ expansion_state:post:high_esi |
    state_ind + ind_time + state_time,
  data = panel,
  cluster = ~statefip
)

ddd_sep <- feols(
  sep_rate ~ expansion_state:post:high_esi |
    state_ind + ind_time + state_time,
  data = panel,
  cluster = ~statefip
)

ddd_hira <- feols(
  hira_rate ~ expansion_state:post:high_esi |
    state_ind + ind_time + state_time,
  data = panel,
  cluster = ~statefip
)

ddd_netjob <- feols(
  net_job_creation ~ expansion_state:post:high_esi |
    state_ind + ind_time + state_time,
  data = panel,
  cluster = ~statefip
)

ddd_earn <- feols(
  log_earnings ~ expansion_state:post:high_esi |
    state_ind + ind_time + state_time,
  data = panel,
  cluster = ~statefip
)

cat("\nNew Hire Rate (DDD):\n")
summary(ddd_hire)
cat("\nSeparation Rate (DDD):\n")
summary(ddd_sep)

# Save model objects
saveRDS(list(
  hire = ddd_hire,
  sep = ddd_sep,
  hira = ddd_hira,
  netjob = ddd_netjob,
  earn = ddd_earn
), "../data/ddd_models.rds")

# =============================================================================
# 3. QUADRUPLE-DIFFERENCE: DDD × Low Education
# =============================================================================

cat("\n=== Quadruple-Difference: By Education ===\n")

# Separate DDD for low-edu vs high-edu
panel_low <- panel %>% filter(edu_group == "no_bachelors")
panel_high <- panel %>% filter(edu_group == "bachelors_plus")

ddd_hire_low <- feols(
  hire_rate ~ expansion_state:post:high_esi |
    state_ind + ind_time + state_time,
  data = panel_low,
  cluster = ~statefip
)

ddd_hire_high <- feols(
  hire_rate ~ expansion_state:post:high_esi |
    state_ind + ind_time + state_time,
  data = panel_high,
  cluster = ~statefip
)

ddd_sep_low <- feols(
  sep_rate ~ expansion_state:post:high_esi |
    state_ind + ind_time + state_time,
  data = panel_low,
  cluster = ~statefip
)

ddd_sep_high <- feols(
  sep_rate ~ expansion_state:post:high_esi |
    state_ind + ind_time + state_time,
  data = panel_high,
  cluster = ~statefip
)

cat("\nNew Hire Rate — Low Education (DDD):\n")
summary(ddd_hire_low)
cat("\nNew Hire Rate — High Education (placebo, DDD):\n")
summary(ddd_hire_high)

saveRDS(list(
  hire_low = ddd_hire_low,
  hire_high = ddd_hire_high,
  sep_low = ddd_sep_low,
  sep_high = ddd_sep_high
), "../data/ddd_edu_models.rds")

# =============================================================================
# 4. EVENT STUDY (Sun-Abraham via fixest for the DDD)
# =============================================================================

cat("\n=== Event Study ===\n")

# Use Sun-Abraham event study via fixest::sunab() for a cleaner approach
# Focus on high-ESI, low-edu workers — the key treated group
es_data <- panel %>%
  filter(high_esi == 1, edu_group == "no_bachelors") %>%
  mutate(
    # For sunab: cohort = first treatment period; 0 or Inf = never-treated
    cohort = ifelse(expand_period > 0, expand_period, 10000)
  )

# Sun-Abraham event study
es_hire <- feols(
  hire_rate ~ sunab(cohort, period) | statefip + period,
  data = es_data,
  cluster = ~statefip
)

es_sep <- feols(
  sep_rate ~ sunab(cohort, period) | statefip + period,
  data = es_data,
  cluster = ~statefip
)

cat("\nSun-Abraham Event Study (New Hire Rate):\n")
summary(es_hire)

cat("\nSun-Abraham Event Study (Separation Rate):\n")
summary(es_sep)

saveRDS(es_hire, "../data/es_hire.rds")
saveRDS(es_sep, "../data/es_sep.rds")

# Also compute simple ATT from the DDD (already done above)
att_hire_coef <- coef(ddd_hire)[1]
att_hire_se <- sqrt(diag(vcov(ddd_hire)))[1]
att_sep_coef <- coef(ddd_sep)[1]
att_sep_se <- sqrt(diag(vcov(ddd_sep)))[1]

cat(sprintf("\nDDD ATT — Hire Rate: %.3f (SE: %.3f, p: %.4f)\n",
            att_hire_coef, att_hire_se, 2 * pt(-abs(att_hire_coef / att_hire_se), df = 50)))
cat(sprintf("DDD ATT — Sep Rate: %.3f (SE: %.3f, p: %.4f)\n",
            att_sep_coef, att_sep_se, 2 * pt(-abs(att_sep_coef / att_sep_se), df = 50)))

# =============================================================================
# 5. DIAGNOSTICS for validator
# =============================================================================

n_treated <- n_distinct(panel$statefip[panel$expansion_state == 1])
n_pre <- length(unique(panel$period[panel$period < 17]))  # 17 = 2014Q1
n_obs <- nrow(panel)

write_json(list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
), "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("\nDiagnostics: %d treated states, %d pre-periods, %s observations\n",
            n_treated, n_pre, format(n_obs, big.mark = ",")))
cat("\nMain analysis complete.\n")
