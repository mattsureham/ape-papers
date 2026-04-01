## 04_robustness.R — Robustness checks and event study
## APEP paper apep_1234: FATF Grey-Listing and Panama Banking

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

load(file.path(data_dir, "regression_results.RData"))

# ============================================================
# 1. Binned Event Study (semi-annual bins for tractability)
# ============================================================

df <- df %>%
  mutate(
    event_time = interval(as.Date("2019-06-01"), date) %/% months(1),
    # Semi-annual bins
    event_half = case_when(
      event_time <= -30 ~ -6L,   # ≤-30m
      event_time <= -24 ~ -5L,   # -30 to -24m
      event_time <= -18 ~ -4L,   # -24 to -18m
      event_time <= -12 ~ -3L,   # -18 to -12m
      event_time <= -6  ~ -2L,   # -12 to -6m
      event_time <= -1  ~ -1L,   # -6 to -1m (reference)
      event_time <= 5   ~ 0L,    # 0 to 5m
      event_time <= 11  ~ 1L,    # 6 to 11m
      event_time <= 17  ~ 2L,    # 12 to 17m
      event_time <= 23  ~ 3L,    # 18 to 23m
      event_time <= 29  ~ 4L,    # 24 to 29m
      event_time <= 35  ~ 5L,    # 30 to 35m
      event_time <= 41  ~ 6L,    # 36 to 41m
      event_time <= 47  ~ 7L,    # 42 to 47m
      event_time <= 53  ~ 8L,    # 48 to 53m (delist at ~52m)
      event_time <= 59  ~ 9L,    # 54 to 59m (post-delist)
      event_time <= 65  ~ 10L,   # 60 to 65m
      TRUE              ~ 11L    # 66+
    )
  )

es_binned_roa <- feols(roa ~ i(event_half, treated, ref = -1) | bank_id + date,
                       data = df, vcov = DK ~ date)
es_binned_roe <- feols(roe ~ i(event_half, treated, ref = -1) | bank_id + date,
                       data = df, vcov = DK ~ date)

cat("=== Binned Event Study (ROA) ===\n")
summary(es_binned_roa)

cat("\n=== Binned Event Study (ROE) ===\n")
summary(es_binned_roe)

# ============================================================
# 2. Placebo test: fake grey-listing date at Jan 2018
# ============================================================
df_placebo <- df %>%
  filter(date < as.Date("2019-06-01")) %>%
  mutate(
    fake_grey = as.integer(date >= as.Date("2018-01-01")),
    fake_did = treated * fake_grey
  )

placebo_roa <- feols(roa ~ fake_did | bank_id + date,
                     data = df_placebo, vcov = DK ~ date)

cat("\n=== Placebo Test (fake treatment Jan 2018, ROA) ===\n")
summary(placebo_roa)

# ============================================================
# 3. Triple-diff with Foreign Private as second control
# ============================================================

# DDD: compare (International - Panamanian Private) gap to
#      (Foreign Private - Panamanian Private) gap
panel <- read_csv(file.path(data_dir, "panel_indicators.csv"), show_col_types = FALSE) %>%
  mutate(date = floor_date(date, "month"))

df_ddd <- panel %>%
  dplyr::filter(treat_group %in% c("International License", "Panamanian Private", "Foreign Private")) %>%
  mutate(
    date = floor_date(date, "month"),
    international = as.integer(treat_group == "International License"),
    foreign = as.integer(treat_group == "Foreign Private"),
    grey_period = as.integer(date >= as.Date("2019-06-01") & date < as.Date("2023-10-01")),
    post_delist = as.integer(date >= as.Date("2023-10-01")),
    did_int = international * grey_period,
    did_for = foreign * grey_period,
    bank_id = as.integer(factor(treat_group))
  )

m_ddd_roa <- feols(roa ~ did_int + did_for | bank_id + date,
                   data = df_ddd, vcov = DK ~ date)

cat("\n=== DDD: International vs Foreign Private vs Panamanian Private (ROA) ===\n")
summary(m_ddd_roa)

# ============================================================
# 4. Alternative DK bandwidth
# ============================================================
m_dk6_roa <- feols(roa ~ did + did_delist | bank_id + date,
                   data = df, vcov = DK(6) ~ date)
m_dk12_roa <- feols(roa ~ did + did_delist | bank_id + date,
                    data = df, vcov = DK(12) ~ date)

cat("\n=== Sensitivity to DK bandwidth ===\n")
cat("DK(3) — default:\n")
cat(sprintf("  did: %.4f (SE=%.4f, p=%.3f)\n",
            coef(m1_roa)["did"], se(m1_roa)["did"], pvalue(m1_roa)["did"]))
cat("DK(6):\n")
cat(sprintf("  did: %.4f (SE=%.4f, p=%.3f)\n",
            coef(m_dk6_roa)["did"], se(m_dk6_roa)["did"], pvalue(m_dk6_roa)["did"]))
cat("DK(12):\n")
cat(sprintf("  did: %.4f (SE=%.4f, p=%.3f)\n",
            coef(m_dk12_roa)["did"], se(m_dk12_roa)["did"], pvalue(m_dk12_roa)["did"]))

# ============================================================
# 5. De-listing reversal test (post Oct 2023 only)
# ============================================================
df_delist <- df %>%
  filter(date >= as.Date("2019-06-01")) %>%
  mutate(
    post_delist = as.integer(date >= as.Date("2023-10-01")),
    delist_did = treated * post_delist
  )

m_delist_roa <- feols(roa ~ delist_did | bank_id + date,
                      data = df_delist, vcov = DK ~ date)
m_delist_roe <- feols(roe ~ delist_did | bank_id + date,
                      data = df_delist, vcov = DK ~ date)

cat("\n=== De-listing Reversal Test ===\n")
cat("ROA:\n")
summary(m_delist_roa)
cat("ROE:\n")
summary(m_delist_roe)

# ============================================================
# Save all robustness results
# ============================================================
save(es_binned_roa, es_binned_roe, placebo_roa, m_ddd_roa,
     m_dk6_roa, m_dk12_roa, m_delist_roa, m_delist_roe, df,
     file = file.path(data_dir, "robustness_results.RData"))

cat("\nRobustness results saved.\n")
