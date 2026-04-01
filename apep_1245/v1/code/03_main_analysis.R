# =============================================================================
# 03_main_analysis.R — Main event study and cross-sectional analysis
# =============================================================================

source("00_packages.R")

# ---------------------------------------------------------------------------
# 1. Load cleaned data
# ---------------------------------------------------------------------------

stocks <- fread("../data/stocks_clean.csv")
car_all <- fread("../data/car_events.csv")
vr_all <- fread("../data/variance_ratios.csv")
overpricing <- fread("../data/overpricing.csv")

stocks[, date := as.Date(date)]
n_stocks <- uniqueN(stocks$ticker)
cat("Loaded", nrow(stocks), "stock-day obs for", n_stocks, "stocks\n")

# ---------------------------------------------------------------------------
# 2. Average market reaction to ban events
# ---------------------------------------------------------------------------

# Average CAR by event and window
avg_car <- car_all[, .(
  mean_car = mean(car, na.rm = TRUE),
  se_car = sd(car, na.rm = TRUE) / sqrt(.N),
  median_car = median(car, na.rm = TRUE),
  n = .N,
  pct_positive = mean(car > 0, na.rm = TRUE)
), by = .(event, window)]

cat("\n=== Average CARs by Event ===\n")
print(avg_car)

# ---------------------------------------------------------------------------
# 3. Cross-sectional regression: CAR on pre-ban characteristics
# ---------------------------------------------------------------------------

# Focus on [-1, +1] window
car_ban_1_1 <- car_all[event == "ban_imposition" & window == "ban_1_1"]
car_lift_1_1 <- car_all[event == "ban_lift" & window == "lift_1_1"]

# Ban imposition: high-vol stocks should gain MORE (short squeeze)
reg_ban_1 <- feols(car ~ pre_ban_volatility, data = car_ban_1_1)
reg_ban_2 <- feols(car ~ pre_ban_volatility + log(pre_ban_avg_turnover + 1) +
  log(pre_ban_close) + pre_ban_amihud, data = car_ban_1_1)
reg_ban_3 <- feols(car ~ pre_ban_volatility + log(pre_ban_avg_turnover + 1) +
  log(pre_ban_close) + pre_ban_amihud | exchange, data = car_ban_1_1)

cat("\n=== Ban Imposition CAR[-1,+1] Regressions ===\n")
etable(reg_ban_1, reg_ban_2, reg_ban_3)

# Ban lift: high-vol stocks should LOSE MORE (correction)
reg_lift_1 <- feols(car ~ pre_ban_volatility, data = car_lift_1_1)
reg_lift_2 <- feols(car ~ pre_ban_volatility + log(pre_ban_avg_turnover + 1) +
  log(pre_ban_close) + pre_ban_amihud, data = car_lift_1_1)
reg_lift_3 <- feols(car ~ pre_ban_volatility + log(pre_ban_avg_turnover + 1) +
  log(pre_ban_close) + pre_ban_amihud | exchange, data = car_lift_1_1)

cat("\n=== Ban Lift CAR[-1,+1] Regressions ===\n")
etable(reg_lift_1, reg_lift_2, reg_lift_3)

# ---------------------------------------------------------------------------
# 4. Price efficiency: variance ratio analysis
# ---------------------------------------------------------------------------

# Panel regression: variance ratio across periods
# Stack pre (0) vs ban (1) vs post (2)
vr_all[, during_ban := as.integer(period == 1)]
vr_all[, post_ban := as.integer(period == 2)]

# Deviation from random walk (VR = 1 means efficient)
vr_all[, vr_deviation := abs(vr_5 - 1)]

# Regression: does VR deviate more during ban, especially for high-vol stocks?
reg_vr_1 <- feols(vr_deviation ~ during_ban + post_ban, data = vr_all)
reg_vr_2 <- feols(vr_deviation ~ during_ban + post_ban +
  during_ban:pre_ban_volatility + post_ban:pre_ban_volatility +
  pre_ban_volatility, data = vr_all)
reg_vr_3 <- feols(vr_deviation ~ during_ban + post_ban +
  during_ban:pre_ban_volatility + post_ban:pre_ban_volatility |
  ticker, data = vr_all)

cat("\n=== Variance Ratio Regressions ===\n")
etable(reg_vr_1, reg_vr_2, reg_vr_3)

# ---------------------------------------------------------------------------
# 5. Overpricing and correction
# ---------------------------------------------------------------------------

# Do stocks that drifted up during ban correct more after lift?
reg_over_1 <- feols(cum_ar_post10 ~ cum_ar_ban, data = overpricing)
reg_over_2 <- feols(cum_ar_post10 ~ cum_ar_ban + pre_ban_volatility +
  log(pre_ban_avg_turnover + 1) + log(pre_ban_close), data = overpricing)

cat("\n=== Overpricing Correction Regressions ===\n")
etable(reg_over_1, reg_over_2)

# Symmetric test: high-vol stocks gained more during ban, lost more after
reg_symm_ban <- feols(cum_ar_ban ~ pre_ban_volatility +
  log(pre_ban_avg_turnover + 1) + log(pre_ban_close), data = overpricing)
reg_symm_post <- feols(cum_ar_post10 ~ pre_ban_volatility +
  log(pre_ban_avg_turnover + 1) + log(pre_ban_close), data = overpricing)

cat("\n=== Symmetric Test: Ban Period vs Post-Lift ===\n")
etable(reg_symm_ban, reg_symm_post)

# ---------------------------------------------------------------------------
# 6. Summary statistics for diagnostics
# ---------------------------------------------------------------------------

n_treated <- n_stocks  # All stocks are treated (complete ban)
n_pre <- uniqueN(stocks$date[stocks$period_num == 0])
n_obs <- nrow(stocks)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_stocks = n_stocks,
  n_ban_days = uniqueN(stocks$date[stocks$period_num == 1]),
  n_post_days = uniqueN(stocks$date[stocks$period_num == 2]),
  avg_car_ban_imposition = as.numeric(avg_car[event == "ban_imposition" & window == "ban_1_1", mean_car]),
  avg_car_ban_lift = as.numeric(avg_car[event == "ban_lift" & window == "lift_1_1", mean_car])
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\n=== Diagnostics ===\n")
cat("N stocks (treated):", n_treated, "\n")
cat("N pre-ban trading days:", n_pre, "\n")
cat("N total stock-day obs:", n_obs, "\n")
cat("Avg CAR[-1,+1] ban imposition:", round(diagnostics$avg_car_ban_imposition * 100, 2), "%\n")
cat("Avg CAR[-1,+1] ban lift:", round(diagnostics$avg_car_ban_lift * 100, 2), "%\n")

# Save key regression objects for table generation
save(reg_ban_1, reg_ban_2, reg_ban_3,
  reg_lift_1, reg_lift_2, reg_lift_3,
  reg_vr_1, reg_vr_2, reg_vr_3,
  reg_over_1, reg_over_2,
  reg_symm_ban, reg_symm_post,
  avg_car,
  file = "../data/main_results.RData")

cat("\nMain analysis complete. Results saved.\n")
