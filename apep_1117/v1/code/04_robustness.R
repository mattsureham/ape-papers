## 04_robustness.R — Robustness checks for payment timing and crime
## apep_1117: Payday Depletion Cycle and Property Crime in Buenos Aires

source("00_packages.R")

data_dir <- "../data"

daily <- fread(file.path(data_dir, "daily_panel.csv"))
daily[, date := as.Date(date)]
daily[, ym := format(date, "%Y-%m")]
daily[, dow := factor(wday(date))]
daily[, day_of_month := mday(date)]
daily[, weekend := as.integer(wday(date) %in% c(1, 7))]

## Reconstruct payment variables
digit_day <- fread(file.path(data_dir, "digit_day_dsp.csv"))
digit_day[, date := as.Date(date)]

groups_paid_today <- digit_day[days_since_payment == 0, .(n_paid_today = .N), by = date]
daily <- merge(daily, groups_paid_today, by = "date", all.x = TRUE)
daily[is.na(n_paid_today), n_paid_today := 0]
daily[, payment_day := as.integer(n_paid_today > 0)]

groups_week <- digit_day[days_since_payment <= 7, .(n_paid_recent7 = .N), by = date]
daily <- merge(daily, groups_week, by = "date", all.x = TRUE)
daily[is.na(n_paid_recent7), n_paid_recent7 := 0]

all_paid <- digit_day[, .(all_paid = as.integer(all(days_since_payment > 0) & .N == 10)),
                       by = date]
daily <- merge(daily, all_paid, by = "date", all.x = TRUE)
daily[is.na(all_paid), all_paid := 0]

daily[, log_property := log(property_crimes + 1)]

cat("=== ROBUSTNESS CHECKS ===\n\n")

## ============================================================
## R1: Control for day-of-month (parabolic calendar effects)
## ============================================================

cat("--- R1: Day-of-month controls ---\n")
r1a <- feols(property_crimes ~ avg_days_since_payment +
               day_of_month + I(day_of_month^2) | dow + ym,
             data = daily, vcov = ~ym)
print(summary(r1a))

## ============================================================
## R2: Weekday-only sample (drop weekends — crime patterns differ)
## ============================================================

cat("--- R2: Weekday-only sample ---\n")
daily_wkday <- daily[weekend == 0]
r2a <- feols(property_crimes ~ avg_days_since_payment | dow + ym,
             data = daily_wkday, vcov = ~ym)
print(summary(r2a))

r2b <- feols(property_crimes ~ payment_day | dow + ym,
             data = daily_wkday, vcov = ~ym)
cat("Payment day (weekdays only):\n")
print(summary(r2b))

## ============================================================
## R3: Year-by-year estimates
## ============================================================

cat("--- R3: Year-by-year estimates ---\n")
for (yr in c(2019, 2021, 2022, 2023)) {
  sub <- daily[year(date) == yr]
  r3 <- feols(property_crimes ~ avg_days_since_payment | dow + ym,
              data = sub, vcov = ~ym)
  cat(sprintf("  %d: coef = %.3f, se = %.3f, p = %.3f (n = %d)\n",
              yr, coef(r3)[1], sqrt(vcov(r3)[1,1]),
              2 * pt(-abs(coef(r3)[1] / sqrt(vcov(r3)[1,1])),
                     df = nrow(sub) - 2),
              nrow(sub)))
}

## ============================================================
## R4: Permutation test — randomly shuffle payment calendar
## ============================================================

cat("\n--- R4: Permutation test (200 iterations) ---\n")
set.seed(42)
n_perm <- 200
true_coef_dsp <- coef(feols(property_crimes ~ avg_days_since_payment | dow + ym,
                             data = daily, vcov = ~ym))[1]
true_coef_pay <- coef(feols(property_crimes ~ payment_day | dow + ym,
                             data = daily, vcov = ~ym))[1]

perm_coefs_dsp <- numeric(n_perm)
perm_coefs_pay <- numeric(n_perm)

for (i in 1:n_perm) {
  ## Shuffle the payment calendar: randomly reassign digit-group payment dates
  ## within each month (preserving the monthly structure)
  cal_shuf <- fread(file.path(data_dir, "anses_payment_calendar.csv"))
  cal_shuf[, payment_date := as.Date(payment_date)]

  ## Shuffle payment dates within each month
  cal_shuf[, payment_date := sample(payment_date), by = .(year, month)]

  ## Reconstruct DSP from shuffled calendar
  digit_day_shuf <- list()
  all_dates_dt <- data.table(date = seq(min(daily$date), max(daily$date), by = "day"))

  for (dig in 0:9) {
    dig_cal <- cal_shuf[digit == dig, .(payment_date)]
    setorder(dig_cal, payment_date)

    merged <- copy(all_dates_dt)
    merged[, join_date := date]
    dig_cal[, join_date := payment_date]

    setkey(merged, join_date)
    setkey(dig_cal, join_date)

    result <- dig_cal[merged, roll = TRUE]
    result[, `:=`(
      digit = dig,
      days_since_payment = as.integer(date - payment_date)
    )]
    digit_day_shuf[[dig + 1]] <- result[!is.na(days_since_payment) &
                                          days_since_payment >= 0,
                                        .(date, digit, days_since_payment)]
  }

  dds <- rbindlist(digit_day_shuf)

  ## Compute shuffled DSP and payment day
  avg_dsp_shuf <- dds[, .(avg_dsp_shuf = mean(days_since_payment)), by = date]
  paid_today_shuf <- dds[days_since_payment == 0, .(pay_shuf = 1L), by = date]

  daily_tmp <- merge(daily[, .(date, property_crimes, dow, ym)],
                     avg_dsp_shuf, by = "date", all.x = TRUE)
  daily_tmp <- merge(daily_tmp, paid_today_shuf, by = "date", all.x = TRUE)
  daily_tmp[is.na(avg_dsp_shuf), avg_dsp_shuf := 15]
  daily_tmp[is.na(pay_shuf), pay_shuf := 0]

  m_dsp <- tryCatch(
    feols(property_crimes ~ avg_dsp_shuf | dow + ym, data = daily_tmp),
    error = function(e) NULL
  )
  m_pay <- tryCatch(
    feols(property_crimes ~ pay_shuf | dow + ym, data = daily_tmp),
    error = function(e) NULL
  )

  perm_coefs_dsp[i] <- if (!is.null(m_dsp)) coef(m_dsp)[1] else NA
  perm_coefs_pay[i] <- if (!is.null(m_pay)) coef(m_pay)[1] else NA
}

perm_p_dsp <- mean(abs(perm_coefs_dsp) >= abs(true_coef_dsp), na.rm = TRUE)
perm_p_pay <- mean(abs(perm_coefs_pay) >= abs(true_coef_pay), na.rm = TRUE)

cat(sprintf("  DSP: true coef = %.3f, permutation p-value = %.3f\n",
            true_coef_dsp, perm_p_dsp))
cat(sprintf("  Payment day: true coef = %.3f, permutation p-value = %.3f\n",
            true_coef_pay, perm_p_pay))

## ============================================================
## R5: Total crime (all types) — broader outcome
## ============================================================

cat("\n--- R5: Total crime (all types) ---\n")
r5a <- feols(total_crimes ~ avg_days_since_payment | dow + ym,
             data = daily, vcov = ~ym)
r5b <- feols(total_crimes ~ payment_day | dow + ym,
             data = daily, vcov = ~ym)
cat("All crimes on DSP:\n")
print(summary(r5a))
cat("All crimes on payment day:\n")
print(summary(r5b))

## ============================================================
## Save permutation results
## ============================================================

perm_results <- list(
  n_permutations = n_perm,
  dsp_true_coef = true_coef_dsp,
  dsp_perm_p = perm_p_dsp,
  dsp_perm_mean = mean(perm_coefs_dsp, na.rm = TRUE),
  dsp_perm_sd = sd(perm_coefs_dsp, na.rm = TRUE),
  payment_day_true_coef = true_coef_pay,
  payment_day_perm_p = perm_p_pay,
  payment_day_perm_mean = mean(perm_coefs_pay, na.rm = TRUE),
  payment_day_perm_sd = sd(perm_coefs_pay, na.rm = TRUE)
)

write_json(perm_results, file.path(data_dir, "permutation_results.json"),
           auto_unbox = TRUE, pretty = TRUE)

cat("\nRobustness checks complete.\n")
