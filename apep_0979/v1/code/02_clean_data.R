# =============================================================================
# 02_clean_data.R — Construct analysis panel for DDD
# =============================================================================
source("00_packages.R")

df_raw <- readRDS("../data/qwi_raw.rds")
ulr_states <- read_csv("../data/ulr_states.csv", show_col_types = FALSE)

# --- Build state-quarter panel ---
df <- df_raw %>%
  filter(!is.na(avg_monthly_earn), Emp > 0) %>%
  mutate(
    time_q = year + (quarter - 1) / 4,
    log_earn = log(avg_monthly_earn)
  )

# Merge ULR treatment info
df <- df %>%
  left_join(
    ulr_states %>% select(state_fips, first_treat_q, state_abbr),
    by = "state_fips"
  ) %>%
  mutate(
    ulr_state = !is.na(first_treat_q),
    post_ulr = as.integer(ifelse(ulr_state, time_q >= first_treat_q, FALSE)),
    # For C-S estimator: first_treat_q for treated, 0 for never-treated
    first_treat_cs = ifelse(ulr_state, first_treat_q, 0),
    # Indicators
    black = as.integer(race_label == "Black"),
    healthcare = as.integer(industry_label == "Healthcare"),
    # DDD treatment variable
    treat_ddd = as.integer(post_ulr & black == 1 & healthcare == 1),
    # Event time (quarters relative to treatment)
    event_time = ifelse(ulr_state, (time_q - first_treat_q) * 4, NA_real_)
  )

# Create factor IDs for FEs
df <- df %>%
  mutate(
    state_id = as.factor(state_fips),
    quarter_id = as.factor(sprintf("%d_Q%d", year, quarter)),
    race_ind = interaction(race_label, industry_label, drop = TRUE),
    state_race_ind = interaction(state_fips, race_label, industry_label, drop = TRUE),
    state_quarter = interaction(state_fips, year, quarter, drop = TRUE),
    quarter_race_ind = interaction(year, quarter, race_label, industry_label, drop = TRUE)
  )

cat("Panel dimensions:\n")
cat(sprintf("  Observations: %s\n", format(nrow(df), big.mark = ",")))
cat(sprintf("  States: %d\n", n_distinct(df$state_fips)))
cat(sprintf("  ULR states: %d\n", sum(ulr_states$state_fips %in% unique(df$state_fips))))
cat(sprintf("  Quarters: %d\n", n_distinct(df$quarter_id)))
cat(sprintf("  Race groups: %s\n", paste(unique(df$race_label), collapse = ", ")))
cat(sprintf("  Industries: %s\n", paste(unique(df$industry_label), collapse = ", ")))

# Summary stats for paper
summary_stats <- df %>%
  group_by(race_label, industry_label) %>%
  summarize(
    mean_wkly_earn = weighted.mean(avg_monthly_earn, Emp, na.rm = TRUE),
    sd_wkly_earn = sqrt(weighted.mean((avg_monthly_earn - weighted.mean(avg_monthly_earn, Emp, na.rm = TRUE))^2, Emp, na.rm = TRUE)),
    mean_emp = mean(Emp, na.rm = TRUE),
    n_state_qtrs = n(),
    .groups = "drop"
  )

cat("\nSummary statistics:\n")
print(summary_stats)

# Pre-treatment SD of log earnings (for SDE calculation)
pre_sds <- df %>%
  filter(!post_ulr | !ulr_state) %>%
  filter(time_q < 2019) %>%
  group_by(race_label, industry_label) %>%
  summarize(
    sd_log_earn = sd(log_earn, na.rm = TRUE),
    sd_earn = sd(avg_monthly_earn, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nPre-treatment SD of log earnings:\n")
print(pre_sds)

saveRDS(df, "../data/analysis_panel.rds")
saveRDS(summary_stats, "../data/summary_stats.rds")
saveRDS(pre_sds, "../data/pre_sds.rds")

cat("\nAnalysis panel saved: data/analysis_panel.rds\n")
