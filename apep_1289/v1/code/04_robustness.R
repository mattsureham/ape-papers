## 04_robustness.R — Robustness and falsification tests
## APEP paper apep_1289

source("00_packages.R")

cat("=== Robustness checks for apep_1289 ===\n")

# Load data
analysis_df <- readRDS("../data/analysis_clean.rds")
national_merged <- readRDS("../data/national_merged.rds")
main_results <- readRDS("../data/main_results.rds")

# ============================================================
# 1. Falsification: Child Fatality Rates
# ============================================================
cat("\n--- 1. Falsification: Child Fatalities ---\n")

# National-level: If DR diverts referrals, fatalities should be unaffected
# because fatal cases are NEVER diverted to assessment track

# Count number of DR states by year for national-level test
dr_share <- analysis_df %>%
  filter(year >= 2000) %>%
  group_by(year) %>%
  summarise(
    n_dr_states = sum(dr_adopted),
    pct_dr = mean(dr_adopted) * 100,
    .groups = "drop"
  )

# Merge with national fatality data
falsification_df <- national_merged %>%
  filter(year >= 2000) %>%
  left_join(dr_share, by = "year") %>%
  filter(!is.na(n_dr_states))

# Regression: fatality rate on DR share
if (nrow(falsification_df) > 5) {
  false_reg <- lm(fatality_rate_per_100k ~ pct_dr + year, data = falsification_df)
  cat("Falsification — fatality rate on DR share:\n")
  cat(sprintf("  Coefficient on pct_dr: %.4f (SE: %.4f, p=%.3f)\n",
              coef(false_reg)["pct_dr"],
              summary(false_reg)$coefficients["pct_dr", "Std. Error"],
              summary(false_reg)$coefficients["pct_dr", "Pr(>|t|)"]))
  cat(sprintf("  Year trend: %.4f\n", coef(false_reg)["year"]))
}

# Contrast: victim rate declines while fatality rate rises
cat("\nContrast — victims vs fatalities:\n")
cat(sprintf("  Victim rate: %.1f (2000) → %.1f (2023) [down %.0f%%]\n",
            national_merged$victim_rate_national[national_merged$year == 2000],
            national_merged$victim_rate_national[national_merged$year == 2023],
            100 * (1 - national_merged$victim_rate_national[national_merged$year == 2023] /
                     national_merged$victim_rate_national[national_merged$year == 2000])))
cat(sprintf("  Fatality rate: %.2f (2000) → %.2f (2023) [up %.0f%%]\n",
            national_merged$fatality_rate_per_100k[national_merged$year == 2000],
            national_merged$fatality_rate_per_100k[national_merged$year == 2023],
            100 * (national_merged$fatality_rate_per_100k[national_merged$year == 2023] /
                     national_merged$fatality_rate_per_100k[national_merged$year == 2000] - 1)))

# ============================================================
# 2. Placebo Test: Random Adoption Dates
# ============================================================
cat("\n--- 2. Placebo: Randomized Adoption Dates ---\n")

set.seed(20260401)
n_placebo <- 500

placebo_atts <- numeric(n_placebo)

for (i in 1:n_placebo) {
  # Randomly reassign DR adoption dates among treated states
  treated_states <- unique(analysis_df$state[analysis_df$first_treat > 0])
  actual_years <- unique(analysis_df$first_treat[analysis_df$first_treat > 0])

  placebo_df <- analysis_df %>%
    mutate(
      first_treat_placebo = case_when(
        first_treat == 0 ~ 0L,
        TRUE ~ sample(actual_years, n(), replace = TRUE)
      ),
      dr_adopted_placebo = as.integer(first_treat_placebo > 0 & year >= first_treat_placebo)
    )

  placebo_reg <- tryCatch(
    feols(victim_rate ~ dr_adopted_placebo | state_id + year,
          data = placebo_df, cluster = ~state_id),
    error = function(e) NULL
  )

  if (!is.null(placebo_reg)) {
    placebo_atts[i] <- coef(placebo_reg)["dr_adopted_placebo"]
  }
}

placebo_atts <- placebo_atts[placebo_atts != 0]
actual_att <- coef(main_results$twfe)["dr_adopted"]

cat(sprintf("Actual TWFE ATT: %.3f\n", actual_att))
cat(sprintf("Placebo distribution: mean=%.3f, SD=%.3f\n",
            mean(placebo_atts), sd(placebo_atts)))
cat(sprintf("Rank of actual in placebo distribution: %.1f%%\n",
            100 * mean(placebo_atts <= actual_att)))

# ============================================================
# 3. Leave-One-Out: Drop each state
# ============================================================
cat("\n--- 3. Leave-One-Out ---\n")

loo_results <- map_dfr(unique(analysis_df$state), function(s) {
  loo_df <- filter(analysis_df, state != s)
  loo_reg <- tryCatch(
    feols(victim_rate ~ dr_adopted | state_id + year,
          data = loo_df, cluster = ~state_id),
    error = function(e) NULL
  )

  if (!is.null(loo_reg)) {
    tibble(
      dropped_state = s,
      coef = coef(loo_reg)["dr_adopted"],
      se = se(loo_reg)["dr_adopted"]
    )
  } else {
    tibble()
  }
})

cat(sprintf("Leave-one-out range: [%.3f, %.3f]\n",
            min(loo_results$coef), max(loo_results$coef)))
cat(sprintf("Most influential state: %s (coef when dropped: %.3f)\n",
            loo_results$dropped_state[which.max(abs(loo_results$coef - actual_att))],
            loo_results$coef[which.max(abs(loo_results$coef - actual_att))]))

# ============================================================
# 4. Alternative Specifications
# ============================================================
cat("\n--- 4. Alternative Specifications ---\n")

# 4a. Log outcome
twfe_log <- feols(log_victim_rate ~ dr_adopted | state_id + year,
                  data = analysis_df, cluster = ~state_id)
cat(sprintf("Log specification: %.4f (SE: %.4f)\n",
            coef(twfe_log)["dr_adopted"], se(twfe_log)["dr_adopted"]))

# 4b. State-specific linear trends
twfe_trends <- feols(victim_rate ~ dr_adopted | state_id[year] + year,
                     data = analysis_df, cluster = ~state_id)
cat(sprintf("With state trends: %.4f (SE: %.4f)\n",
            coef(twfe_trends)["dr_adopted"], se(twfe_trends)["dr_adopted"]))

# 4c. C-S with not-yet-treated as controls
cs_nyt <- tryCatch({
  att_gt(
    yname = "victim_rate",
    tname = "year",
    idname = "state_id",
    gname = "first_treat",
    data = analysis_df,
    control_group = "notyettreated",
    est_method = "dr",
    base_period = "universal"
  )
}, error = function(e) {
  cat(sprintf("  C-S with not-yet-treated failed: %s\n", e$message))
  NULL
})

if (!is.null(cs_nyt)) {
  cs_nyt_simple <- aggte(cs_nyt, type = "simple")
  cat(sprintf("C-S (not-yet-treated): %.4f (SE: %.4f)\n",
              cs_nyt_simple$overall.att, cs_nyt_simple$overall.se))
}

# ============================================================
# 5. Referral-Victim Decomposition (National Level)
# ============================================================
cat("\n--- 5. Referral-Victim Decomposition ---\n")

national_merged <- readRDS("../data/national_merged.rds")

# Calculate referral-to-victim ratio
if ("referrals_national" %in% names(national_merged) &&
    "victims_national" %in% names(national_merged)) {
  national_merged <- national_merged %>%
    mutate(
      victim_to_referral = victims_national / referrals_national,
      referral_growth = referrals_national / first(referrals_national),
      victim_growth = victims_national / first(victims_national)
    )

  cat("National trends (2000 = base):\n")
  cat(sprintf("  2000: Referrals = %s, Victims = %s, Ratio = %.3f\n",
              format(national_merged$referrals_national[national_merged$year == 2000], big.mark = ","),
              format(national_merged$victims_national[national_merged$year == 2000], big.mark = ","),
              national_merged$victim_to_referral[national_merged$year == 2000]))
  cat(sprintf("  2023: Referrals = %s, Victims = %s, Ratio = %.3f\n",
              format(national_merged$referrals_national[national_merged$year == 2023], big.mark = ","),
              format(national_merged$victims_national[national_merged$year == 2023], big.mark = ","),
              national_merged$victim_to_referral[national_merged$year == 2023]))
  cat(sprintf("  Referral change: %.0f%%\n",
              100 * (national_merged$referral_growth[national_merged$year == 2023] - 1)))
  cat(sprintf("  Victim change: %.0f%%\n",
              100 * (national_merged$victim_growth[national_merged$year == 2023] - 1)))
}

# ============================================================
# 6. Save robustness results
# ============================================================
robustness <- list(
  falsification = if (exists("false_reg")) false_reg else NULL,
  placebo_atts = placebo_atts,
  loo_results = loo_results,
  twfe_log = twfe_log,
  twfe_trends = twfe_trends,
  cs_nyt = if (!is.null(cs_nyt)) cs_nyt_simple else NULL
)

saveRDS(robustness, "../data/robustness_results.rds")
cat("\nRobustness results saved.\n")
