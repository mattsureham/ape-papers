# =============================================================================
# 04_robustness.R — Robustness checks and mechanism tests
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds")
race_panel <- readRDS("../data/race_panel_clean.rds")
results <- readRDS("../data/main_results.rds")
pre_gaps <- readRDS("../data/pre_gaps.rds")

# =============================================================================
# 1. Industry heterogeneity: High-gap vs Low-gap industries
# =============================================================================
cat("=== Industry heterogeneity test ===\n")

# DDD: interact post with high_gap indicator
ddd_industry <- feols(
  earn_gap_log ~ post * high_gap |
    unit_id + yq,
  data = panel,
  cluster = ~state_fips,
  weights = ~total_emp
)

cat("DDD (Post × High-Gap Industry):\n")
summary(ddd_industry)

# Individual industry effects (top 6 by gap size)
top_industries <- pre_gaps %>%
  arrange(desc(gap_pct)) %>%
  head(6) %>%
  pull(industry)

industry_effects <- map_dfr(top_industries, function(ind) {
  d <- panel %>% filter(industry == ind)
  if (nrow(d) < 50) return(NULL)
  d$post_num <- as.numeric(d$post)
  m <- feols(earn_gap_log ~ post_num | state_fips + yq,
             data = d, cluster = ~state_fips)
  tibble(
    industry = ind,
    coef = coef(m)["post_num"],
    se = se(m)["post_num"],
    n = nobs(m),
    gap_name = pre_gaps$gap_pct[pre_gaps$industry == ind]
  )
})

cat("\nIndustry-specific effects:\n")
print(industry_effects)

# =============================================================================
# 2. Race mechanism: Black-White earnings gap
# =============================================================================
cat("\n=== Race mechanism (Doleac-Hansen test) ===\n")

# State-quarter aggregation for race panel
race_state <- race_panel %>%
  group_by(state_fips, year, quarter, yq, time_int, first_treat_yq, first_treat_int, treated) %>%
  summarise(
    race_gap_log = weighted.mean(race_gap_log, total_emp, na.rm = TRUE),
    race_gap_ratio = weighted.mean(race_gap_ratio, total_emp, na.rm = TRUE),
    hire_gap_race = weighted.mean(hire_gap_race, total_emp, na.rm = TRUE),
    black_earn = weighted.mean(EarnHirNS_Black, Emp_Black, na.rm = TRUE),
    total_emp = sum(total_emp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    state_id = as.numeric(as.factor(state_fips)),
    post = ifelse(first_treat_yq > 0, yq >= first_treat_yq, FALSE)
  )

# CS-DiD on Black-White earnings gap
cs_race <- tryCatch({
  att_gt(
    yname = "race_gap_log",
    tname = "time_int",
    idname = "state_id",
    gname = "first_treat_int",
    data = race_state,
    control_group = "nevertreated",
    anticipation = 0,
    est_method = "dr",
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS-DiD on race gap failed:", e$message, "\n")
  NULL
})

if (!is.null(cs_race)) {
  agg_race_simple <- aggte(cs_race, type = "simple", na.rm = TRUE)
  cat("Race gap ATT (overall):\n")
  summary(agg_race_simple)

  agg_race_dynamic <- aggte(cs_race, type = "dynamic", min_e = -12, max_e = 12, na.rm = TRUE)
} else {
  # Fallback: TWFE
  cat("Using TWFE for race gap...\n")
  twfe_race <- feols(
    race_gap_log ~ post | state_fips + yq,
    data = race_state,
    cluster = ~state_fips
  )
  summary(twfe_race)
  agg_race_simple <- NULL
  agg_race_dynamic <- NULL
}

# Black hiring rate effect
twfe_black_hire <- feols(
  hire_gap_race ~ post | state_fips + yq,
  data = race_state,
  cluster = ~state_fips
)

cat("\nBlack-White hiring rate gap (TWFE):\n")
summary(twfe_black_hire)

# =============================================================================
# 3. Pre-treatment placebo (fake treatment 4 years early)
# =============================================================================
cat("\n=== Pre-treatment placebo ===\n")

placebo_panel <- panel %>%
  filter(yq < 2017.75) %>%
  mutate(
    fake_treat_yq = ifelse(first_treat_yq > 0, first_treat_yq - 4, 0),
    fake_post = ifelse(fake_treat_yq > 0, yq >= fake_treat_yq, FALSE)
  )

placebo_twfe <- feols(
  earn_gap_log ~ fake_post |
    unit_id + yq,
  data = placebo_panel,
  cluster = ~state_fips,
  weights = ~total_emp
)

cat("Pre-treatment placebo (should be ~0):\n")
summary(placebo_twfe)

# =============================================================================
# 4. Bacon decomposition
# =============================================================================
cat("\n=== Bacon decomposition ===\n")

# Need balanced panel at state level
state_qtr <- results$state_qtr %>%
  filter(time_int %in% 1:44) %>%
  group_by(state_id) %>%
  filter(n() == 44) %>%
  ungroup()

bacon_out <- tryCatch({
  bacon(earn_gap_log ~ post,
        data = state_qtr %>% mutate(post = yq >= first_treat_yq & first_treat_yq > 0),
        id_var = "state_id",
        time_var = "time_int")
}, error = function(e) {
  cat("Bacon decomposition failed:", e$message, "\n")
  NULL
})

if (!is.null(bacon_out)) {
  cat("Bacon decomposition:\n")
  print(bacon_out %>%
          group_by(type) %>%
          summarise(
            weight = sum(weight),
            avg_estimate = weighted.mean(estimate, weight),
            .groups = "drop"
          ))
}

# =============================================================================
# 5. HonestDiD sensitivity analysis
# =============================================================================
cat("\n=== HonestDiD sensitivity ===\n")

honest_result <- tryCatch({
  es <- results$agg_dynamic
  betahat <- es$att.egt
  sigma <- es$V
  # Find the index where e = 0 (first post-treatment)
  e_vals <- es$egt
  n_pre <- sum(e_vals < 0)

  if (n_pre >= 2 && length(betahat) > n_pre) {
    honest <- HonestDiD::createSensitivityResults(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = n_pre,
      numPostPeriods = length(betahat) - n_pre,
      Mvec = seq(0, 0.05, by = 0.01),
      l_vec = basisVector(index = 1, size = length(betahat) - n_pre)
    )
    honest
  } else {
    cat("Not enough pre-periods for HonestDiD.\n")
    NULL
  }
}, error = function(e) {
  cat("HonestDiD failed:", e$message, "\n")
  NULL
})

if (!is.null(honest_result)) {
  cat("HonestDiD results:\n")
  print(honest_result)
}

# =============================================================================
# 6. Male-only earnings (additional placebo)
# =============================================================================
cat("\n=== Male earnings placebo ===\n")

state_qtr_male <- results$state_qtr %>%
  mutate(
    log_male_earn = log(male_earn),
    post = yq >= first_treat_yq & first_treat_yq > 0
  )

twfe_male <- feols(
  log_male_earn ~ post | state_id + time_int,
  data = state_qtr_male,
  cluster = ~state_fips
)

cat("Male earnings effect (should be small/zero if bans target gender gap):\n")
summary(twfe_male)

# =============================================================================
# Save robustness results
# =============================================================================
rob_results <- list(
  ddd_industry = ddd_industry,
  industry_effects = industry_effects,
  cs_race = cs_race,
  agg_race_simple = agg_race_simple,
  agg_race_dynamic = agg_race_dynamic,
  twfe_black_hire = twfe_black_hire,
  placebo_twfe = placebo_twfe,
  bacon_out = bacon_out,
  honest_result = honest_result,
  twfe_male = twfe_male
)

saveRDS(rob_results, "../data/robustness_results.rds")
cat("\n=== Robustness checks complete ===\n")
