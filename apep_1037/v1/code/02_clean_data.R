# 02_clean_data.R — Clean and construct analysis panels
# apep_1037: The Round-Trip Tax
# Two panels: (1) TAIEX aggregate market (2) per-stock daily sample

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# Panel 1: TAIEX Market-Level Aggregate
# ============================================================================

cat("=== Building TAIEX aggregate panel ===\n")

taiex_raw <- readRDS(file.path(data_dir, "taiex_monthly_raw.rds"))

clean_num <- function(x) {
  x <- gsub(",", "", x)
  x <- gsub("\\s+", "", x)
  suppressWarnings(as.numeric(x))
}

# Each row is a trading day with market totals
taiex_daily <- taiex_raw %>%
  mutate(
    volume = clean_num(volume_shares),
    value = clean_num(value_twd),
    transactions = clean_num(n_transactions),
    quarter = ceiling(month / 3),
    yq = year * 10 + quarter,
    ym = year * 100 + month
  ) %>%
  filter(!is.na(volume), volume > 0)

# Monthly aggregation
taiex_monthly <- taiex_daily %>%
  group_by(year, month, ym) %>%
  summarise(
    total_vol = sum(volume, na.rm = TRUE),
    total_val = sum(value, na.rm = TRUE),
    total_trans = sum(transactions, na.rm = TRUE),
    n_days = n(),
    avg_daily_vol = mean(volume, na.rm = TRUE),
    avg_daily_val = mean(value, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    quarter = ceiling(month / 3),
    yq = year * 10 + quarter,
    log_vol = log(total_vol),
    log_val = log(total_val),
    log_daily_vol = log(avg_daily_vol),
    log_daily_val = log(avg_daily_val)
  )

# Quarterly aggregation
taiex_quarterly <- taiex_daily %>%
  group_by(year, quarter, yq) %>%
  summarise(
    total_vol = sum(volume, na.rm = TRUE),
    total_val = sum(value, na.rm = TRUE),
    total_trans = sum(transactions, na.rm = TRUE),
    n_days = n(),
    avg_daily_vol = mean(volume, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    log_vol = log(total_vol),
    log_daily_vol = log(avg_daily_vol),
    # Policy periods
    period = case_when(
      yq < 20122 ~ "pre_announcement",
      yq >= 20122 & yq < 20131 ~ "announcement",
      yq >= 20131 & yq <= 20153 ~ "cgt_active",
      yq >= 20154 ~ "post_repeal"
    ),
    cgt_active = as.integer(yq >= 20131 & yq <= 20153),
    post_repeal = as.integer(yq >= 20154),
    post_announce = as.integer(yq >= 20122),
    # Event time relative to CGT start (2013Q1)
    event_time = (year - 2013) * 4 + quarter - 1,
    # Event time relative to repeal (2015Q4)
    event_time_rep = (year - 2015) * 4 + quarter - 4
  )

cat("TAIEX monthly:", nrow(taiex_monthly), "obs\n")
cat("TAIEX quarterly:", nrow(taiex_quarterly), "obs\n")

saveRDS(taiex_monthly, file.path(data_dir, "taiex_monthly_panel.rds"))
saveRDS(taiex_quarterly, file.path(data_dir, "taiex_quarterly_panel.rds"))

# ============================================================================
# Panel 2: Per-Stock Daily Sample
# ============================================================================

cat("\n=== Building per-stock panel ===\n")

stock_file <- file.path(data_dir, "stock_daily_sample.rds")
if (file.exists(stock_file)) {
  stock_raw <- readRDS(stock_file)

  # Parse ROC dates (e.g. "99/01/04" = 2010/01/04)
  stock_clean <- stock_raw %>%
    mutate(
      volume = clean_num(volume_shares),
      value = clean_num(value_twd),
      price_close = clean_num(close),
      price_open = clean_num(open),
      n_trans = clean_num(n_transactions),
      quarter = ceiling(month / 3),
      yq = year * 10 + quarter,
      ym = year * 100 + month
    ) %>%
    filter(!is.na(volume), volume > 0, !is.na(price_close), price_close > 0)

  cat("Stock daily observations:", nrow(stock_clean), "\n")
  cat("Unique stocks:", n_distinct(stock_clean$stock_code), "\n")

  # Aggregate to monthly
  stock_monthly <- stock_clean %>%
    group_by(stock_code, year, month, ym) %>%
    summarise(
      total_vol = sum(volume, na.rm = TRUE),
      total_val = sum(value, na.rm = TRUE),
      avg_close = mean(price_close, na.rm = TRUE),
      n_days = n(),
      avg_daily_vol = mean(volume, na.rm = TRUE),
      total_trans = sum(n_trans, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      quarter = ceiling(month / 3),
      yq = year * 10 + quarter,
      log_vol = log(total_vol),
      log_val = log(total_val),
      log_daily_vol = log(avg_daily_vol),
      log_price = log(avg_close),
      turnover = total_vol / avg_close  # crude turnover proxy
    )

  # Aggregate to quarterly
  stock_quarterly <- stock_monthly %>%
    group_by(stock_code, year, quarter, yq) %>%
    summarise(
      total_vol = sum(total_vol, na.rm = TRUE),
      total_val = sum(total_val, na.rm = TRUE),
      avg_close = mean(avg_close, na.rm = TRUE),
      avg_daily_vol = mean(avg_daily_vol, na.rm = TRUE),
      n_days = sum(n_days),
      total_trans = sum(total_trans, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      log_vol = log(total_vol),
      log_val = log(total_val),
      log_daily_vol = log(avg_daily_vol),
      log_price = log(avg_close),
      # Policy periods
      cgt_active = as.integer(yq >= 20131 & yq <= 20153),
      post_repeal = as.integer(yq >= 20154),
      event_time = (year - 2013) * 4 + quarter - 1,
      event_time_rep = (year - 2015) * 4 + quarter - 4
    )

  # Size classification based on pre-2012 average volume
  pre_size <- stock_quarterly %>%
    filter(yq < 20122) %>%
    group_by(stock_code) %>%
    summarise(
      pre_vol = mean(total_vol, na.rm = TRUE),
      pre_price = mean(avg_close, na.rm = TRUE),
      pre_mcap_proxy = mean(total_vol * avg_close, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      size_quintile = ntile(pre_mcap_proxy, 5),
      small_cap = as.integer(size_quintile <= 2),
      large_cap = as.integer(size_quintile >= 4)
    )

  stock_quarterly <- stock_quarterly %>%
    left_join(pre_size %>% select(stock_code, size_quintile, small_cap, large_cap),
              by = "stock_code")

  cat("Stock monthly:", nrow(stock_monthly), "obs\n")
  cat("Stock quarterly:", nrow(stock_quarterly), "obs,",
      n_distinct(stock_quarterly$stock_code), "stocks\n")

  saveRDS(stock_monthly, file.path(data_dir, "stock_monthly_panel.rds"))
  saveRDS(stock_quarterly, file.path(data_dir, "stock_quarterly_panel.rds"))
} else {
  cat("Stock daily sample not yet available, skipping\n")
}

# ============================================================================
# P/E data (quarterly)
# ============================================================================

cat("\n=== Processing P/E data ===\n")

pe_file <- file.path(data_dir, "pe_dividend_raw.rds")
if (file.exists(pe_file)) {
  pe_raw <- readRDS(pe_file)
  pe_clean <- pe_raw %>%
    mutate(
      stock_code = trimws(stock_code),
      pe = clean_num(pe_ratio),
      div_yield = clean_num(dividend_yield),
      pb = clean_num(pb_ratio),
      yq = year * 10 + quarter
    ) %>%
    filter(!is.na(pe) | !is.na(div_yield))

  cat("P/E data:", nrow(pe_clean), "obs\n")
  saveRDS(pe_clean, file.path(data_dir, "pe_clean.rds"))
}

cat("\n=== All panels built ===\n")
