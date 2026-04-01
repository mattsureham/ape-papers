# =============================================================================
# 04_robustness.R — Robustness checks and placebo tests
# =============================================================================

source("00_packages.R")

# ---------------------------------------------------------------------------
# 1. Load data
# ---------------------------------------------------------------------------

stocks <- fread("../data/stocks_clean.csv")
car_all <- fread("../data/car_events.csv")
overpricing <- fread("../data/overpricing.csv")
chars <- fread("../data/pre_ban_characteristics.csv")
stocks[, date := as.Date(date)]

load("../data/main_results.RData")

cat("Loaded data for robustness checks\n")

# ---------------------------------------------------------------------------
# 2. Alternative event windows
# ---------------------------------------------------------------------------

# Wider windows: [-1,+5] and [-1,+10]
car_ban_5 <- car_all[event == "ban_imposition" & window == "ban_1_5"]
car_ban_10 <- car_all[event == "ban_imposition" & window == "ban_1_10"]
car_lift_5 <- car_all[event == "ban_lift" & window == "lift_1_5"]
car_lift_10 <- car_all[event == "ban_lift" & window == "lift_1_10"]

reg_ban_w5 <- feols(car ~ pre_ban_volatility + log(pre_ban_avg_turnover + 1) +
  log(pre_ban_close) | exchange, data = car_ban_5)
reg_ban_w10 <- feols(car ~ pre_ban_volatility + log(pre_ban_avg_turnover + 1) +
  log(pre_ban_close) | exchange, data = car_ban_10)
reg_lift_w5 <- feols(car ~ pre_ban_volatility + log(pre_ban_avg_turnover + 1) +
  log(pre_ban_close) | exchange, data = car_lift_5)
reg_lift_w10 <- feols(car ~ pre_ban_volatility + log(pre_ban_avg_turnover + 1) +
  log(pre_ban_close) | exchange, data = car_lift_10)

cat("\n=== Alternative Windows ===\n")
cat("Ban [-1,+5]:\n")
print(summary(reg_ban_w5))
cat("Ban [-1,+10]:\n")
print(summary(reg_ban_w10))
cat("Lift [-1,+5]:\n")
print(summary(reg_lift_w5))
cat("Lift [-1,+10]:\n")
print(summary(reg_lift_w10))

# ---------------------------------------------------------------------------
# 3. Placebo test: same-day-of-week, one year before ban
# ---------------------------------------------------------------------------

# Placebo ban date: November 6, 2022 (Sunday -> use Nov 7 Monday)
placebo_ban <- as.Date("2022-11-07")
stocks[, placebo_event_day := as.integer(date - placebo_ban)]

# Compute placebo CARs
placebo_car <- stocks[placebo_event_day >= -1 & placebo_event_day <= 1,
  .(car = sum(ar, na.rm = TRUE), n_days = .N),
  by = ticker]
placebo_car <- merge(placebo_car, chars, by = "ticker", all.x = TRUE)

reg_placebo <- feols(car ~ pre_ban_volatility + log(pre_ban_avg_turnover + 1) +
  log(pre_ban_close) | exchange, data = placebo_car)

cat("\n=== Placebo Test (Nov 2022) ===\n")
print(summary(reg_placebo))

# ---------------------------------------------------------------------------
# 4. KOSPI vs KOSDAQ subsample analysis
# ---------------------------------------------------------------------------

car_ban_1_1 <- car_all[event == "ban_imposition" & window == "ban_1_1"]
car_lift_1_1 <- car_all[event == "ban_lift" & window == "lift_1_1"]

reg_kospi_ban <- feols(car ~ pre_ban_volatility + log(pre_ban_avg_turnover + 1) +
  log(pre_ban_close), data = car_ban_1_1[exchange == "KOSPI"])
reg_kosdaq_ban <- feols(car ~ pre_ban_volatility + log(pre_ban_avg_turnover + 1) +
  log(pre_ban_close), data = car_ban_1_1[exchange == "KOSDAQ"])

cat("\n=== KOSPI vs KOSDAQ: Ban Imposition ===\n")
etable(reg_kospi_ban, reg_kosdaq_ban)

# ---------------------------------------------------------------------------
# 5. Amihud illiquidity as alternative treatment intensity
# ---------------------------------------------------------------------------

# More illiquid stocks should be MORE affected by short-selling ban
reg_amihud_ban <- feols(car ~ pre_ban_amihud + log(pre_ban_avg_turnover + 1) +
  log(pre_ban_close) | exchange, data = car_ban_1_1)
reg_amihud_lift <- feols(car ~ pre_ban_amihud + log(pre_ban_avg_turnover + 1) +
  log(pre_ban_close) | exchange, data = car_lift_1_1)

cat("\n=== Amihud Illiquidity as Treatment Intensity ===\n")
etable(reg_amihud_ban, reg_amihud_lift)

# ---------------------------------------------------------------------------
# 6. Symmetry test: correlation of ban-day and lift-day CARs
# ---------------------------------------------------------------------------

ban_cars <- car_all[event == "ban_imposition" & window == "ban_1_1", .(ticker, car_ban = car)]
lift_cars <- car_all[event == "ban_lift" & window == "lift_1_1", .(ticker, car_lift = car)]
symm <- merge(ban_cars, lift_cars, by = "ticker")

symm_cor <- cor.test(symm$car_ban, symm$car_lift)
cat("\n=== Symmetry: Correlation of Ban-Day and Lift-Day CARs ===\n")
cat("Correlation:", round(symm_cor$estimate, 3), "\n")
cat("p-value:", format.pval(symm_cor$p.value), "\n")
cat("N:", nrow(symm), "\n")

# Regression
reg_symmetry <- feols(car_lift ~ car_ban, data = symm)
cat("\nCAR_lift = α + β × CAR_ban:\n")
print(summary(reg_symmetry))

# ---------------------------------------------------------------------------
# 7. Save robustness results
# ---------------------------------------------------------------------------

save(reg_ban_w5, reg_ban_w10, reg_lift_w5, reg_lift_w10,
  reg_placebo,
  reg_kospi_ban, reg_kosdaq_ban,
  reg_amihud_ban, reg_amihud_lift,
  reg_symmetry, symm_cor,
  file = "../data/robustness_results.RData")

cat("\nRobustness checks complete.\n")
