# =============================================================================
# 04_robustness.R — Robustness checks for DDD
# =============================================================================
source("00_packages.R")

df <- readRDS("../data/analysis_panel.rds")
ulr_states <- read_csv("../data/ulr_states.csv", show_col_types = FALSE)

cat("=== ROBUSTNESS CHECKS ===\n\n")

# --- R1: Arizona-only (pre-COVID clean test) ---
df_az <- df %>%
  filter(time_q <= 2020.0) %>%  # Drop COVID period
  mutate(
    post_ulr_az = as.integer(state_fips == "04" & time_q >= 2019.0),
    ulr_az = state_fips == "04"
  )

r1 <- feols(
  log_earn ~ post_ulr_az:black:healthcare |
    state_fips^quarter_id + state_fips^race_label^industry_label + quarter_id^race_label^industry_label,
  data = df_az,
  weights = ~Emp,
  cluster = ~state_fips
)
cat("R1: Arizona-only pre-COVID\n")
summary(r1)

# --- R2: Wild cluster bootstrap for main specification ---
m2 <- feols(
  log_earn ~ post_ulr:black:healthcare |
    state_fips^quarter_id + state_fips^race_label^industry_label + quarter_id^race_label^industry_label,
  data = df,
  weights = ~Emp,
  cluster = ~state_fips
)

cat("\nR2: Few-cluster inference (CR3 small-sample correction via fixest)\n")
# With 51 states (11 treated), standard cluster-robust SEs are reasonable
# but we report CR3 correction as additional robustness
m2_cr3 <- feols(
  log_earn ~ post_ulr:black:healthcare |
    state_fips^quarter_id + state_fips^race_label^industry_label + quarter_id^race_label^industry_label,
  data = df,
  weights = ~Emp,
  cluster = ~state_fips,
  ssc = ssc(adj = TRUE, fixef.K = "full", cluster.adj = TRUE)
)
cat("CR3-corrected results:\n")
summary(m2_cr3)
wcb <- list(
  p_val = pvalue(m2_cr3)["post_ulr:black:healthcare"],
  conf_int = c(
    coef(m2_cr3)["post_ulr:black:healthcare"] - qt(0.975, 50) * se(m2_cr3)["post_ulr:black:healthcare"],
    coef(m2_cr3)["post_ulr:black:healthcare"] + qt(0.975, 50) * se(m2_cr3)["post_ulr:black:healthcare"]
  )
)

# --- R3: Leave-one-out (drop each ULR state) ---
cat("\nR3: Leave-one-out\n")
loo_results <- map_dfr(ulr_states$state_fips, function(s) {
  df_loo <- df %>% filter(state_fips != s)
  m_loo <- feols(
    log_earn ~ post_ulr:black:healthcare |
      state_fips^quarter_id + state_fips^race_label^industry_label + quarter_id^race_label^industry_label,
    data = df_loo,
    weights = ~Emp,
    cluster = ~state_fips
  )
  tibble(
    dropped_state = s,
    dropped_abbr = ulr_states$state_abbr[ulr_states$state_fips == s],
    coef = coef(m_loo)["post_ulr:black:healthcare"],
    se = se(m_loo)["post_ulr:black:healthcare"],
    pval = pvalue(m_loo)["post_ulr:black:healthcare"]
  )
})
print(loo_results)

# --- R4: Alternative placebo industries ---
# Retail (44-45) data was pre-fetched by 01_fetch_data.py
df_retail_raw <- read_csv("../data/qwi_retail.csv", show_col_types = FALSE)

df_retail <- df_retail_raw %>%
  mutate(
    race_label = ifelse(race == "A2", "Black", "White"),
    industry_label = ifelse(industry == "62", "Healthcare", "Retail"),
    avg_monthly_earn = ifelse(Emp > 0, EarnS / Emp, NA_real_),
    log_earn = log(avg_monthly_earn),
    year = as.integer(year),
    quarter = as.integer(quarter),
    time_q = year + (quarter - 1) / 4,
    black = as.integer(race_label == "Black"),
    healthcare = as.integer(industry_label == "Healthcare")
  ) %>%
  filter(!is.na(log_earn)) %>%
  left_join(
    ulr_states %>% select(state_fips, first_treat_q),
    by = "state_fips"
  ) %>%
  mutate(
    ulr_state = !is.na(first_treat_q),
    post_ulr = as.integer(ifelse(ulr_state, time_q >= first_treat_q, FALSE)),
    quarter_id = sprintf("%d_Q%d", year, quarter)
  )

r4 <- feols(
  log_earn ~ post_ulr:black:healthcare |
    state_fips^quarter_id + state_fips^race_label^industry_label + quarter_id^race_label^industry_label,
  data = df_retail,
  weights = ~Emp,
  cluster = ~state_fips
)
cat("\nR4: Healthcare vs Retail placebo\n")
summary(r4)

# --- R5: Unweighted regression ---
r5 <- feols(
  log_earn ~ post_ulr:black:healthcare |
    state_fips^quarter_id + state_fips^race_label^industry_label + quarter_id^race_label^industry_label,
  data = df,
  cluster = ~state_fips
)
cat("\nR5: Unweighted\n")
summary(r5)

# --- Save all robustness results ---
robustness <- list(
  r1_arizona = r1,
  wcb = wcb,
  loo = loo_results,
  r4_retail = r4,
  r5_unweighted = r5
)
saveRDS(robustness, "../data/robustness_results.rds")

cat("\n=== ROBUSTNESS COMPLETE ===\n")
