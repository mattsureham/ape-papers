# 03_main_analysis.R — Main analysis for SEC Chair Transitions paper
# apep_0760

source("00_packages.R")
library(fixest)  # Fixed effects estimation (feols)

# ============================================================
# Load data
# ============================================================

enforcement <- read_csv("../data/enforcement_actions.csv", show_col_types = FALSE) %>%
  mutate(date = as.Date(date))
transitions <- read_csv("../data/chair_transitions.csv", show_col_types = FALSE) %>%
  mutate(transition_date = as.Date(transition_date))
tenures <- read_csv("../data/chair_tenures.csv", show_col_types = FALSE) %>%
  mutate(start_date = as.Date(start_date), end_date = as.Date(end_date))
cornerstone <- read_csv("../data/cornerstone_fy_totals.csv", show_col_types = FALSE)
market_es <- read_csv("../data/market_event_study.csv", show_col_types = FALSE) %>%
  mutate(date = as.Date(date))
monthly <- read_csv("../data/monthly_panel.csv", show_col_types = FALSE) %>%
  mutate(month = as.Date(month))

cat("Data loaded.\n")

# ============================================================
# Analysis 1: Enforcement Intensity by Chair Tenure
# ============================================================

# Compute enforcement rates by Chair from Cornerstone FY totals
chair_enforcement <- tenures %>%
  mutate(
    tenure_months = as.numeric(difftime(end_date, start_date, units = "days")) / 30.44,
    tenure_fy_start = if_else(month(start_date) >= 10,
                              year(start_date) + 1L, year(start_date)),
    tenure_fy_end = if_else(month(end_date) >= 10,
                            year(end_date) + 1L, year(end_date))
  )

# For each Chair, compute their average monthly enforcement rate
# Using Cornerstone FY totals prorated by tenure overlap
chair_rates <- chair_enforcement %>%
  rowwise() %>%
  mutate(
    # Simple approach: average of FY totals during their tenure
    fy_range = list(seq(tenure_fy_start, tenure_fy_end)),
    avg_fy_total = mean(cornerstone$total_actions[cornerstone$fiscal_year %in% unlist(fy_range)],
                        na.rm = TRUE),
    avg_monthly_rate = avg_fy_total / 12
  ) %>%
  ungroup() %>%
  select(chair, party, acting, start_date, end_date, tenure_months,
         avg_fy_total, avg_monthly_rate)

cat("\n=== Chair Enforcement Rates ===\n")
print(chair_rates)

# ============================================================
# Analysis 2: FY-Level Transition Effects
# ============================================================

# Identify transition fiscal years
transition_fys <- transitions %>%
  mutate(
    transition_fy = if_else(month(transition_date) >= 10,
                            year(transition_date) + 1L, year(transition_date))
  )

# Compare transition FY to pre-transition FY
fy_comparison <- transition_fys %>%
  rowwise() %>%
  mutate(
    fy_total = cornerstone$total_actions[cornerstone$fiscal_year == transition_fy],
    pre_fy_total = cornerstone$total_actions[cornerstone$fiscal_year == (transition_fy - 1)],
    pct_change = (fy_total - pre_fy_total) / pre_fy_total * 100,
    standalone = cornerstone$standalone_actions[cornerstone$fiscal_year == transition_fy],
    pre_standalone = cornerstone$standalone_actions[cornerstone$fiscal_year == (transition_fy - 1)],
    standalone_pct_change = (standalone - pre_standalone) / pre_standalone * 100
  ) %>%
  ungroup()

cat("\n=== FY-Level Transition Effects ===\n")
print(fy_comparison %>%
        select(outgoing_chair, transition_type, transition_fy,
               pre_fy_total, fy_total, pct_change,
               pre_standalone, standalone, standalone_pct_change))

# ============================================================
# Analysis 3: Scraped Data Event Study (March-July pattern)
# ============================================================

# Focus on March-July of each year (where we have good coverage)
# This captures the POST-transition period for most transitions
mar_jul <- enforcement %>%
  filter(month(date) >= 3 & month(date) <= 7) %>%
  mutate(
    year = year(date),
    fiscal_year = if_else(month(date) >= 10, year + 1L, year)
  )

mar_jul_monthly <- mar_jul %>%
  mutate(month_num = month(date)) %>%
  count(year, month_num, name = "n_actions")

# Compute mean monthly rate in Mar-Jul for each year
mar_jul_rates <- mar_jul_monthly %>%
  group_by(year) %>%
  summarize(
    mean_monthly = mean(n_actions),
    total_mar_jul = sum(n_actions),
    .groups = "drop"
  )

cat("\n=== March-July Enforcement Rates by Year ===\n")
print(mar_jul_rates)

# ============================================================
# Analysis 4: Market Event Study (VIX around transitions)
# ============================================================

# Pooled event study: VIX levels around transitions
market_es_clean <- market_es %>%
  filter(!is.na(vix_close) & !is.na(sp500_return)) %>%
  distinct(date, transition_id, .keep_all = TRUE)

# Weekly binning of market event study
market_es_weekly <- market_es_clean %>%
  mutate(week_from_transition = floor(days_from_transition / 7)) %>%
  group_by(week_from_transition, transition_id, cross_party) %>%
  summarize(
    mean_vix = mean(vix_close, na.rm = TRUE),
    mean_return = mean(sp500_return, na.rm = TRUE),
    mean_fin_excess = mean(fin_excess_return, na.rm = TRUE),
    n_days = n(),
    .groups = "drop"
  )

# Pooled regression: VIX on post-transition indicator
market_es_clean <- market_es_clean %>%
  mutate(
    post = as.integer(days_from_transition >= 0),
    cross_party = as.integer(cross_party)
  )

# Model 1: VIX level ~ post-transition
m1_vix <- feols(vix_close ~ post | transition_id,
                data = market_es_clean,
                cluster = ~transition_id)

# Model 2: VIX ~ post × cross_party
m2_vix <- feols(vix_close ~ post * cross_party | transition_id,
                data = market_es_clean,
                cluster = ~transition_id)

# Model 3: Financial sector excess return ~ post
m3_fin <- feols(fin_excess_return ~ post | transition_id,
                data = market_es_clean %>% filter(!is.na(fin_excess_return)),
                cluster = ~transition_id)

# Model 4: Financial sector excess return ~ post × cross_party
m4_fin <- feols(fin_excess_return ~ post * cross_party | transition_id,
                data = market_es_clean %>% filter(!is.na(fin_excess_return)),
                cluster = ~transition_id)

cat("\n=== VIX Event Study ===\n")
cat("Model 1: VIX ~ Post-Transition\n")
summary(m1_vix)

cat("\nModel 2: VIX ~ Post × Cross-Party\n")
summary(m2_vix)

cat("\nModel 3: Financial Excess Return ~ Post-Transition\n")
summary(m3_fin)

cat("\nModel 4: Financial Excess Return ~ Post × Cross-Party\n")
summary(m4_fin)

# ============================================================
# Analysis 5: Dynamic Event Study (weekly coefficients)
# ============================================================

# Create weekly dummies for event study (omit week -1 as baseline)
market_es_dyn <- market_es_clean %>%
  mutate(
    week_rel = floor(days_from_transition / 7),
    week_rel = pmax(pmin(week_rel, 8), -8)  # Trim to ±8 weeks
  ) %>%
  filter(abs(week_rel) <= 8)

# VIX dynamic event study
m5_dyn <- feols(vix_close ~ i(week_rel, ref = -1) | transition_id,
                data = market_es_dyn,
                cluster = ~transition_id)

cat("\n=== Dynamic Event Study (VIX) ===\n")
summary(m5_dyn)

# Financial excess return dynamic event study
m6_dyn <- feols(fin_excess_return ~ i(week_rel, ref = -1) | transition_id,
                data = market_es_dyn %>% filter(!is.na(fin_excess_return)),
                cluster = ~transition_id)

cat("\n=== Dynamic Event Study (Financial Excess Return) ===\n")
summary(m6_dyn)

# ============================================================
# Write diagnostics.json for validator
# ============================================================

diagnostics <- list(
  n_treated = sum(market_es_clean$post == 1),  # Post-transition trading days
  n_pre = sum(market_es_clean$post == 0),      # Pre-transition trading days
  n_obs = nrow(market_es_clean),
  n_transitions = nrow(transitions),
  n_enforcement_actions = nrow(enforcement),
  n_trading_days = nrow(market_es_clean),
  cornerstone_fy_range = paste(range(cornerstone$fiscal_year), collapse = "-")
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Diagnostics ===\n")
cat("Cross-party transitions (treated):", diagnostics$n_treated, "\n")
cat("Pre-period trading days:", diagnostics$n_pre, "\n")
cat("Total market event study obs:", diagnostics$n_obs, "\n")

# ============================================================
# Save regression results
# ============================================================

saveRDS(list(
  m1_vix = m1_vix, m2_vix = m2_vix,
  m3_fin = m3_fin, m4_fin = m4_fin,
  m5_dyn = m5_dyn, m6_dyn = m6_dyn,
  fy_comparison = fy_comparison,
  chair_rates = chair_rates,
  mar_jul_rates = mar_jul_rates
), "../data/regression_results.rds")

cat("\nAnalysis complete. Results saved.\n")
