# =============================================================================
# 02_clean_data.R — Clean and prepare Korean stock data for analysis
# =============================================================================

source("00_packages.R")

# ---------------------------------------------------------------------------
# 1. Load data
# ---------------------------------------------------------------------------

stocks <- fread("../data/korean_stocks_daily.csv")
benchmark <- fread("../data/kospi_index_daily.csv")
chars <- fread("../data/pre_ban_characteristics.csv")

cat("Raw stocks:", nrow(stocks), "obs,", uniqueN(stocks$ticker), "tickers\n")
cat("Benchmark:", nrow(benchmark), "obs\n")
cat("Characteristics:", nrow(chars), "stocks\n")

# ---------------------------------------------------------------------------
# 2. Clean dates and compute returns
# ---------------------------------------------------------------------------

# Parse dates (handle timezone info)
stocks[, date := as.Date(substr(Date, 1, 10))]
benchmark[, date := as.Date(substr(Date, 1, 10))]

# Remove duplicates (keep last obs per stock-date)
stocks <- stocks[!duplicated(stocks[, .(ticker, date)], fromLast = TRUE)]
benchmark <- benchmark[!duplicated(benchmark[, .(date)], fromLast = TRUE)]

# Compute daily returns
setorder(stocks, ticker, date)
stocks[, ret := Close / shift(Close) - 1, by = ticker]

setorder(benchmark, date)
benchmark[, ret_mkt := Close / shift(Close) - 1]

# Drop first obs per stock (no return)
stocks <- stocks[!is.na(ret)]
benchmark <- benchmark[!is.na(ret_mkt)]

# ---------------------------------------------------------------------------
# 3. Merge with benchmark and compute abnormal returns
# ---------------------------------------------------------------------------

# Merge market return
stocks <- merge(stocks, benchmark[, .(date, ret_mkt)], by = "date", all.x = TRUE)

# Remove days without benchmark
stocks <- stocks[!is.na(ret_mkt)]

# Compute market-adjusted abnormal return
stocks[, ar := ret - ret_mkt]

# ---------------------------------------------------------------------------
# 4. Create period indicators
# ---------------------------------------------------------------------------

ban_start <- as.Date("2023-11-06")
ban_end <- as.Date("2025-03-31")

stocks[, period := fcase(
  date < ban_start, "pre_ban",
  date >= ban_start & date <= ban_end, "during_ban",
  date > ban_end, "post_ban"
)]

stocks[, period_num := fcase(
  date < ban_start, 0L,
  date >= ban_start & date <= ban_end, 1L,
  date > ban_end, 2L
)]

# Event day indicators
stocks[, ban_event_day := as.integer(date - ban_start)]
stocks[, lift_event_day := as.integer(date - ban_end)]

# ---------------------------------------------------------------------------
# 5. Merge pre-ban characteristics
# ---------------------------------------------------------------------------

stocks <- merge(stocks, chars, by = "ticker", all.x = TRUE)

# Create treatment intensity quartiles based on pre-ban volatility
stocks[, vol_quartile := cut(pre_ban_volatility,
  breaks = quantile(pre_ban_volatility, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE),
  labels = c("Q1_Low", "Q2", "Q3", "Q4_High"),
  include.lowest = TRUE
), by = date]

# High volatility indicator (top quartile)
stocks[, high_vol := as.integer(pre_ban_volatility >= quantile(pre_ban_volatility, 0.75, na.rm = TRUE))]

# Exchange indicator
stocks[, is_kosdaq := as.integer(exchange.x == "KOSDAQ")]

# Log turnover
stocks[, log_turnover := log(pre_ban_avg_turnover + 1)]

# Small cap indicator (below median price)
stocks[, small_cap := as.integer(pre_ban_close <= median(pre_ban_close, na.rm = TRUE))]

# ---------------------------------------------------------------------------
# 6. Compute cumulative abnormal returns around events
# ---------------------------------------------------------------------------

compute_car <- function(dt, event_col, windows) {
  results_list <- list()
  for (w in names(windows)) {
    lo <- windows[[w]][1]
    hi <- windows[[w]][2]
    car_dt <- dt[get(event_col) >= lo & get(event_col) <= hi,
      .(car = sum(ar, na.rm = TRUE),
        n_days = .N),
      by = .(ticker)]
    car_dt[, window := w]
    results_list[[w]] <- car_dt
  }
  rbindlist(results_list)
}

# CARs around ban imposition
windows_ban <- list(
  "ban_1_1" = c(-1, 1),
  "ban_1_5" = c(-1, 5),
  "ban_1_10" = c(-1, 10),
  "ban_0_0" = c(0, 0)
)
car_ban <- compute_car(stocks, "ban_event_day", windows_ban)
car_ban[, event := "ban_imposition"]

# CARs around ban lift
windows_lift <- list(
  "lift_1_1" = c(-1, 1),
  "lift_1_5" = c(-1, 5),
  "lift_1_10" = c(-1, 10),
  "lift_0_0" = c(0, 0)
)
car_lift <- compute_car(stocks, "lift_event_day", windows_lift)
car_lift[, event := "ban_lift"]

# Combine
car_all <- rbindlist(list(car_ban, car_lift))

# Merge characteristics
car_all <- merge(car_all, chars, by = "ticker", all.x = TRUE)

# ---------------------------------------------------------------------------
# 7. Compute price efficiency measures during ban
# ---------------------------------------------------------------------------

# Variance ratio (5-day vs 1-day returns)
compute_vr <- function(dt, period_val) {
  sub <- dt[period_num == period_val]
  setorder(sub, ticker, date)

  # 5-day returns
  sub[, ret_5d := shift(Close, 0) / shift(Close, 5) - 1, by = ticker]
  sub <- sub[!is.na(ret_5d)]

  vr <- sub[, .(
    var_1d = var(ret, na.rm = TRUE),
    var_5d = var(ret_5d, na.rm = TRUE),
    n_obs = .N
  ), by = ticker]
  vr[, vr_5 := var_5d / (5 * var_1d)]
  vr[, period := period_val]
  vr
}

vr_pre <- compute_vr(stocks, 0L)
vr_ban <- compute_vr(stocks, 1L)
vr_post <- compute_vr(stocks, 2L)

vr_all <- rbindlist(list(vr_pre, vr_ban, vr_post))
vr_all <- merge(vr_all, chars, by = "ticker", all.x = TRUE)

# ---------------------------------------------------------------------------
# 8. Compute overpricing measure: drift during ban + correction after
# ---------------------------------------------------------------------------

# Cumulative return during ban period
ban_returns <- stocks[period_num == 1,
  .(cum_ret_ban = prod(1 + ret, na.rm = TRUE) - 1,
    cum_ar_ban = sum(ar, na.rm = TRUE),
    n_days_ban = .N),
  by = ticker]

# Cumulative return in first 10 days after ban lift
post_lift <- stocks[lift_event_day >= 0 & lift_event_day <= 10,
  .(cum_ret_post10 = prod(1 + ret, na.rm = TRUE) - 1,
    cum_ar_post10 = sum(ar, na.rm = TRUE),
    n_days_post = .N),
  by = ticker]

overpricing <- merge(ban_returns, post_lift, by = "ticker", all = TRUE)
overpricing <- merge(overpricing, chars, by = "ticker", all.x = TRUE)

# ---------------------------------------------------------------------------
# 9. Save cleaned data
# ---------------------------------------------------------------------------

fwrite(stocks, "../data/stocks_clean.csv")
fwrite(car_all, "../data/car_events.csv")
fwrite(vr_all, "../data/variance_ratios.csv")
fwrite(overpricing, "../data/overpricing.csv")

cat("\n--- Summary ---\n")
cat("Clean stock-day obs:", nrow(stocks), "\n")
cat("Unique stocks:", uniqueN(stocks$ticker), "\n")
cat("Date range:", as.character(min(stocks$date)), "to", as.character(max(stocks$date)), "\n")
cat("Pre-ban obs:", sum(stocks$period_num == 0), "\n")
cat("During-ban obs:", sum(stocks$period_num == 1), "\n")
cat("Post-ban obs:", sum(stocks$period_num == 2), "\n")
cat("CAR observations:", nrow(car_all), "\n")
cat("Variance ratio observations:", nrow(vr_all), "\n")
cat("\nData cleaning complete.\n")
