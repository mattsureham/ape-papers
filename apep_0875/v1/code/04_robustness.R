# =============================================================================
# 04_robustness.R — Robustness checks
# =============================================================================

source("00_packages.R")

survival_panel <- readRDS("../data/survival_panel.rds")

# =============================================================================
# 0. FIX COHORT: Use programs active in 2011 tracked FORWARD
# =============================================================================
# Using a forward-looking cohort avoids mechanical pre-trends from birth timing

cohort_2011 <- survival_panel %>%
  filter(year == 2011, alive == 1) %>%
  distinct(program_id)

fwd_panel <- survival_panel %>%
  filter(program_id %in% cohort_2011$program_id, year >= 2010) %>%
  mutate(
    event_time = year - 2015,
    post_ge = as.integer(year >= 2015),
    post_repeal = as.integer(year >= 2020),
    state_sector = paste(state, for_profit, sep = "_")
  )

cat(sprintf("Forward cohort 2011: %s programs (%s FP, %s Public)\n",
            format(n_distinct(fwd_panel$program_id), big.mark = ","),
            format(sum(fwd_panel$for_profit == 1 & fwd_panel$year == 2011), big.mark = ","),
            format(sum(fwd_panel$for_profit == 0 & fwd_panel$year == 2011), big.mark = ",")))

# Main event study on forward cohort
est_fwd_event <- feols(
  alive ~ i(event_time, for_profit, ref = -1) | program_id + year,
  data = fwd_panel,
  cluster = ~state
)
cat("\nForward Cohort Event Study:\n")
summary(est_fwd_event)

# Main DiD on forward cohort
est_fwd_did <- feols(
  alive ~ for_profit:post_ge | program_id + year,
  data = fwd_panel,
  cluster = ~state
)

est_fwd_3period <- feols(
  alive ~ for_profit:post_ge + for_profit:post_repeal | program_id + year,
  data = fwd_panel,
  cluster = ~state
)

cat("\nForward Cohort DiD:\n")
summary(est_fwd_did)
cat("\nForward Cohort 3-Period:\n")
summary(est_fwd_3period)

# Save main results for this cohort
saveRDS(est_fwd_event, "../data/est_fwd_event.rds")
saveRDS(est_fwd_did, "../data/est_fwd_did.rds")
saveRDS(est_fwd_3period, "../data/est_fwd_3period.rds")
saveRDS(fwd_panel, "../data/fwd_panel.rds")

# Update diagnostics
n_treated <- sum(fwd_panel$for_profit == 1 & fwd_panel$year == 2011)
n_pre <- length(unique(fwd_panel$year[fwd_panel$year < 2015]))
n_obs <- nrow(fwd_panel)
jsonlite::write_json(list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_clusters = n_distinct(fwd_panel$state)
), "../data/diagnostics.json", auto_unbox = TRUE)

# =============================================================================
# 1. PRE-TREND TEST: Placebo treatment at 2013
# =============================================================================
cat("\n=== Placebo Test: Fake Treatment at 2013 ===\n")

placebo_data <- fwd_panel %>%
  filter(year >= 2011, year <= 2014) %>%
  mutate(post_placebo = as.integer(year >= 2013))

est_placebo <- feols(
  alive ~ for_profit:post_placebo | program_id + year,
  data = placebo_data,
  cluster = ~state
)
cat("Placebo DiD (2011-2014, fake treatment at 2013):\n")
summary(est_placebo)

# =============================================================================
# 2. HETEROGENEITY: High-risk vs Low-risk CIP codes
# =============================================================================
cat("\n=== Heterogeneity by CIP Risk ===\n")

high_risk_cips <- c("12", "52")  # cosmetology, business
low_risk_cips <- c("51")  # healthcare

fwd_panel <- fwd_panel %>%
  mutate(
    cip_risk = case_when(
      cip2 %in% high_risk_cips ~ "High Risk",
      cip2 %in% low_risk_cips ~ "Low Risk",
      TRUE ~ "Other"
    ),
    high_risk = as.integer(cip_risk == "High Risk")
  )

# Triple-diff: for_profit × high_risk × post_ge
est_triple <- feols(
  alive ~ for_profit:post_ge + for_profit:high_risk:post_ge | program_id + year,
  data = fwd_panel,
  cluster = ~state
)
cat("Triple-diff (FP × High-Risk CIP × Post-GE):\n")
summary(est_triple)

# Separate DiD by CIP risk group
for (risk_grp in c("High Risk", "Low Risk", "Other")) {
  sub <- fwd_panel %>% filter(cip_risk == risk_grp)
  est_sub <- feols(
    alive ~ for_profit:post_ge | program_id + year,
    data = sub,
    cluster = ~state
  )
  cat(sprintf("\n%s: coef = %.4f (SE = %.4f), N = %s\n",
              risk_grp, coef(est_sub), se(est_sub),
              format(nrow(sub), big.mark = ",")))
}

# =============================================================================
# 3. ALTERNATIVE COHORT YEARS
# =============================================================================
cat("\n=== Alternative Cohort Years ===\n")

for (cohort_yr in c(2010, 2012, 2013, 2014)) {
  cohort_ids <- survival_panel %>%
    filter(year == cohort_yr, alive == 1) %>%
    distinct(program_id)

  alt_panel <- survival_panel %>%
    filter(program_id %in% cohort_ids$program_id, year >= cohort_yr) %>%
    mutate(post_ge = as.integer(year >= 2015))

  est_alt <- feols(
    alive ~ for_profit:post_ge | program_id + year,
    data = alt_panel,
    cluster = ~state
  )
  cat(sprintf("Cohort %d: coef = %.4f (SE = %.4f), N = %s, programs = %s\n",
              cohort_yr, coef(est_alt), se(est_alt),
              format(nrow(alt_panel), big.mark = ","),
              format(n_distinct(alt_panel$program_id), big.mark = ",")))
}

# =============================================================================
# 4. REPEAL ASYMMETRY TEST
# =============================================================================
cat("\n=== Repeal Asymmetry Test ===\n")

# Focus on 2017-2023 (post-GE, straddling the repeal)
repeal_panel <- fwd_panel %>%
  filter(year >= 2017) %>%
  mutate(
    post_repeal = as.integer(year >= 2020),
    event_repeal = year - 2020
  )

est_repeal <- feols(
  alive ~ for_profit:post_repeal | program_id + year,
  data = repeal_panel,
  cluster = ~state
)
cat("Repeal DiD (2017-2023, treatment at 2020):\n")
summary(est_repeal)

# =============================================================================
# 5. STATE-LEVEL ENROLLMENT SUBSTITUTION
# =============================================================================
cat("\n=== Enrollment Substitution ===\n")

enrollment_panel <- readRDS("../data/enrollment_panel.rds")

state_enroll <- enrollment_panel %>%
  group_by(state, year, for_profit) %>%
  summarise(total_enrollment = sum(total_enrollment, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = for_profit, values_from = total_enrollment,
              names_prefix = "enroll_fp_", values_fill = 0) %>%
  mutate(
    log_public = log(pmax(enroll_fp_0, 1)),
    log_forprofit = log(pmax(enroll_fp_1, 1)),
    fp_share = enroll_fp_1 / (enroll_fp_0 + enroll_fp_1),
    post_ge = as.integer(year >= 2015)
  )

# Event study: public enrollment response to GE rule
# States with larger pre-2015 FP shares should see bigger public enrollment gains
state_enroll <- state_enroll %>%
  group_by(state) %>%
  mutate(pre_fp_share = mean(fp_share[year < 2015], na.rm = TRUE)) %>%
  ungroup()

est_subst <- feols(
  log_public ~ pre_fp_share:post_ge | state + year,
  data = state_enroll,
  cluster = ~state
)
cat("Public enrollment ~ Pre-FP-share × Post-GE (state FE):\n")
summary(est_subst)

# Save robustness results
saveRDS(est_placebo, "../data/est_placebo.rds")
saveRDS(est_triple, "../data/est_triple.rds")
saveRDS(est_repeal, "../data/est_repeal.rds")

cat("\nRobustness checks complete.\n")
