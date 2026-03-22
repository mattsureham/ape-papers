# 04_robustness.R — Robustness checks for SEC Chair Transitions paper
# apep_0760

source("00_packages.R")

# ============================================================
# Load data
# ============================================================

market_es <- read_csv("../data/market_event_study.csv", show_col_types = FALSE) %>%
  mutate(date = as.Date(date))
cornerstone <- read_csv("../data/cornerstone_fy_totals.csv", show_col_types = FALSE)
transitions <- read_csv("../data/chair_transitions.csv", show_col_types = FALSE) %>%
  mutate(transition_date = as.Date(transition_date))
market_daily <- read_csv("../data/market_daily.csv", show_col_types = FALSE) %>%
  mutate(date = as.Date(date))

results <- readRDS("../data/regression_results.rds")

market_es_clean <- market_es %>%
  filter(!is.na(vix_close) & !is.na(sp500_return)) %>%
  distinct(date, transition_id, .keep_all = TRUE) %>%
  mutate(post = as.integer(days_from_transition >= 0),
         cross_party = as.integer(cross_party))

cat("Data loaded for robustness checks.\n")

# ============================================================
# 1. Placebo Transitions — Use non-transition dates
# ============================================================

# Placebo: Use mid-FY dates (April 15) of non-transition years
placebo_dates <- as.Date(c("2011-04-15", "2014-04-15",
                           "2016-04-15", "2019-04-15", "2023-04-15"))

placebo_market_es <- map_dfr(seq_along(placebo_dates), function(i) {
  t_date <- placebo_dates[i]
  market_daily %>%
    mutate(
      transition_id = 100L + i,
      transition_type = "placebo",
      cross_party = FALSE,
      days_from_transition = as.numeric(date - t_date)
    ) %>%
    filter(abs(days_from_transition) <= 60)
}) %>%
  filter(!is.na(vix_close) & !is.na(sp500_return)) %>%
  distinct(date, transition_id, .keep_all = TRUE) %>%
  mutate(post = as.integer(days_from_transition >= 0))

# Placebo VIX test
m_placebo_vix <- feols(vix_close ~ post | transition_id,
                       data = placebo_market_es,
                       cluster = ~transition_id)

cat("\n=== Placebo Test: VIX at Non-Transition Dates ===\n")
summary(m_placebo_vix)

# Placebo financial excess return test
m_placebo_fin <- feols(fin_excess_return ~ post | transition_id,
                       data = placebo_market_es %>% filter(!is.na(fin_excess_return)),
                       cluster = ~transition_id)

cat("\n=== Placebo Test: Financial Excess Return at Non-Transition Dates ===\n")
summary(m_placebo_fin)

# ============================================================
# 2. Bandwidth Sensitivity — Vary event window
# ============================================================

bandwidths <- c(30, 45, 60, 90)

bw_results <- map_dfr(bandwidths, function(bw) {
  es_bw <- market_es %>%
    filter(!is.na(vix_close) & !is.na(sp500_return)) %>%
    filter(abs(days_from_transition) <= bw) %>%
    distinct(date, transition_id, .keep_all = TRUE) %>%
    mutate(post = as.integer(days_from_transition >= 0))

  m_vix <- feols(vix_close ~ post | transition_id, data = es_bw,
                 cluster = ~transition_id)

  tibble(
    bandwidth = bw,
    outcome = "VIX",
    estimate = coef(m_vix)["post"],
    se = se(m_vix)["post"],
    n = nobs(m_vix)
  )
})

cat("\n=== Bandwidth Sensitivity ===\n")
print(bw_results)

# ============================================================
# 3. Exclude FY2025 (the extreme transition)
# ============================================================

es_no_2025 <- market_es_clean %>%
  filter(transition_id != 4)

m_no_2025_vix <- feols(vix_close ~ post | transition_id,
                       data = es_no_2025,
                       cluster = ~transition_id)

m_no_2025_fin <- feols(fin_excess_return ~ post | transition_id,
                       data = es_no_2025 %>% filter(!is.na(fin_excess_return)),
                       cluster = ~transition_id)

cat("\n=== Excluding FY2025 Transition: VIX ===\n")
summary(m_no_2025_vix)

cat("\n=== Excluding FY2025 Transition: Financial Excess Return ===\n")
summary(m_no_2025_fin)

# ============================================================
# 4. FY-Level Permutation Test
# ============================================================

# Under the null, transition years should not systematically show
# different enforcement levels than non-transition years
transition_fys <- c(2013, 2017, 2021, 2025)

# Compute percentage change from prior year for all FYs
fy_changes <- cornerstone %>%
  arrange(fiscal_year) %>%
  mutate(
    pct_change = (total_actions - lag(total_actions)) / lag(total_actions) * 100,
    is_transition = fiscal_year %in% transition_fys
  ) %>%
  filter(!is.na(pct_change))

# Compare transition vs non-transition year changes
transition_change <- mean(fy_changes$pct_change[fy_changes$is_transition])
non_transition_change <- mean(fy_changes$pct_change[!fy_changes$is_transition])

# Permutation test
set.seed(42)
n_perms <- 10000
perm_diffs <- replicate(n_perms, {
  perm_idx <- sample(nrow(fy_changes), sum(fy_changes$is_transition))
  mean(fy_changes$pct_change[perm_idx]) - mean(fy_changes$pct_change[-perm_idx])
})

observed_diff <- transition_change - non_transition_change
p_value_perm <- mean(abs(perm_diffs) >= abs(observed_diff))

cat("\n=== FY-Level Permutation Test ===\n")
cat("Transition year avg change:", round(transition_change, 1), "%\n")
cat("Non-transition year avg change:", round(non_transition_change, 1), "%\n")
cat("Difference:", round(observed_diff, 1), "pp\n")
cat("Permutation p-value (two-sided):", p_value_perm, "\n")

# ============================================================
# 5. Cross-party vs Same-party FY Comparison
# ============================================================

cross_party_fys <- c(2017, 2021, 2025)
same_party_fys <- c(2013)

cross_change <- mean(fy_changes$pct_change[fy_changes$fiscal_year %in% cross_party_fys])
same_change <- mean(fy_changes$pct_change[fy_changes$fiscal_year %in% same_party_fys])

cat("\n=== Cross-Party vs Same-Party FY Changes ===\n")
cat("Cross-party avg change:", round(cross_change, 1), "%\n")
cat("Same-party avg change:", round(same_change, 1), "%\n")
cat("Difference:", round(cross_change - same_change, 1), "pp\n")

# ============================================================
# Save robustness results
# ============================================================

robustness_results <- list(
  placebo_vix = m_placebo_vix,
  placebo_fin = m_placebo_fin,
  bw_results = bw_results,
  no_2025_vix = m_no_2025_vix,
  no_2025_fin = m_no_2025_fin,
  perm_test = list(
    observed_diff = observed_diff,
    p_value = p_value_perm,
    transition_change = transition_change,
    non_transition_change = non_transition_change
  ),
  cross_vs_same = list(
    cross_change = cross_change,
    same_change = same_change
  )
)

saveRDS(robustness_results, "../data/robustness_results.rds")

cat("\nRobustness checks complete.\n")
