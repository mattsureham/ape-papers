## 03_main_analysis.R — Main regressions: payment timing and property crime
## apep_1117: Payday Depletion Cycle and Property Crime in Buenos Aires

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

daily <- fread(file.path(data_dir, "daily_panel.csv"))
daily[, date := as.Date(date)]
daily[, ym := format(date, "%Y-%m")]
daily[, dow := factor(wday(date))]
daily[, year := factor(year(date))]
daily[, month_num := month(date)]

## Also load digit-day panel for supplementary analysis
digit_day <- fread(file.path(data_dir, "digit_day_dsp.csv"))
digit_day[, date := as.Date(date)]

## ============================================================
## PART 1: Construct additional treatment measures
## ============================================================

## A. Number of digit groups paid today
groups_paid_today <- digit_day[days_since_payment == 0, .(n_paid_today = .N), by = date]
daily <- merge(daily, groups_paid_today, by = "date", all.x = TRUE)
daily[is.na(n_paid_today), n_paid_today := 0]

## B. Number of groups paid within last 3 days
groups_recent <- digit_day[days_since_payment <= 3, .(n_paid_recent3 = .N), by = date]
daily <- merge(daily, groups_recent, by = "date", all.x = TRUE)
daily[is.na(n_paid_recent3), n_paid_recent3 := 0]

## C. Number of groups paid within last 7 days
groups_week <- digit_day[days_since_payment <= 7, .(n_paid_recent7 = .N), by = date]
daily <- merge(daily, groups_week, by = "date", all.x = TRUE)
daily[is.na(n_paid_recent7), n_paid_recent7 := 0]

## D. Payment window indicator: at least one group got paid today
daily[, payment_day := as.integer(n_paid_today > 0)]

## E. Post-window indicator: all 10 groups already paid this month
## (max days_since_payment > 0 for all groups = all have been paid)
all_paid <- digit_day[, .(all_paid = as.integer(all(days_since_payment > 0) & .N == 10)),
                       by = date]
daily <- merge(daily, all_paid, by = "date", all.x = TRUE)
daily[is.na(all_paid), all_paid := 0]

## F. Weekend/holiday controls
daily[, weekend := as.integer(wday(date) %in% c(1, 7))]

cat("=== Treatment variable distributions ===\n")
cat(sprintf("Days with payment (n_paid_today > 0): %d / %d\n",
            sum(daily$payment_day), nrow(daily)))
cat(sprintf("Mean groups paid within 7 days: %.1f\n",
            mean(daily$n_paid_recent7)))
cat(sprintf("Avg DSP range: %.1f to %.1f\n",
            min(daily$avg_days_since_payment),
            max(daily$avg_days_since_payment)))

## ============================================================
## PART 2: Main specifications — Property Crime
## ============================================================

cat("\n=== MAIN RESULTS ===\n")

## Spec 1: Linear days-since-payment (continuous)
m1 <- feols(property_crimes ~ avg_days_since_payment | dow + ym,
            data = daily, vcov = ~ym)

## Spec 2: Quadratic
m2 <- feols(property_crimes ~ avg_days_since_payment +
              I(avg_days_since_payment^2) | dow + ym,
            data = daily, vcov = ~ym)

## Spec 3: Number of groups recently paid (within 7 days)
m3 <- feols(property_crimes ~ n_paid_recent7 | dow + ym,
            data = daily, vcov = ~ym)

## Spec 4: Payment day indicator
m4 <- feols(property_crimes ~ payment_day | dow + ym,
            data = daily, vcov = ~ym)

## Spec 5: Post-window (all paid) indicator
m5 <- feols(property_crimes ~ all_paid | dow + ym,
            data = daily, vcov = ~ym)

cat("\n--- Spec 1: Linear DSP ---\n")
print(summary(m1))

cat("\n--- Spec 2: Quadratic DSP ---\n")
print(summary(m2))

cat("\n--- Spec 3: Groups recently paid (7 days) ---\n")
print(summary(m3))

cat("\n--- Spec 4: Payment day ---\n")
print(summary(m4))

cat("\n--- Spec 5: Post-window ---\n")
print(summary(m5))

## ============================================================
## PART 3: Placebo — Violent non-property crime
## ============================================================

cat("\n=== PLACEBO: Violent Non-Property Crime ===\n")

p1 <- feols(violent_nonprop ~ avg_days_since_payment | dow + ym,
            data = daily, vcov = ~ym)

p3 <- feols(violent_nonprop ~ n_paid_recent7 | dow + ym,
            data = daily, vcov = ~ym)

cat("\n--- Placebo Spec 1: Linear DSP ---\n")
print(summary(p1))

cat("\n--- Placebo Spec 3: Groups recently paid ---\n")
print(summary(p3))

## ============================================================
## PART 4: Robbery vs. Theft decomposition
## ============================================================

cat("\n=== DECOMPOSITION: Robbery vs. Theft ===\n")

r1 <- feols(robbery ~ avg_days_since_payment | dow + ym,
            data = daily, vcov = ~ym)

t1 <- feols(theft ~ avg_days_since_payment | dow + ym,
            data = daily, vcov = ~ym)

r3 <- feols(robbery ~ n_paid_recent7 | dow + ym,
            data = daily, vcov = ~ym)

t3 <- feols(theft ~ n_paid_recent7 | dow + ym,
            data = daily, vcov = ~ym)

cat("Robbery on DSP:\n")
print(summary(r1))
cat("Theft on DSP:\n")
print(summary(t1))

## ============================================================
## PART 5: COVID period analysis (exclude 2020)
## ============================================================

cat("\n=== EXCLUDING COVID (2020) ===\n")

daily_nocovid <- daily[year(date) != 2020]

m1_nc <- feols(property_crimes ~ avg_days_since_payment | dow + ym,
               data = daily_nocovid, vcov = ~ym)

m3_nc <- feols(property_crimes ~ n_paid_recent7 | dow + ym,
               data = daily_nocovid, vcov = ~ym)

cat("Excluding 2020:\n")
print(summary(m1_nc))

## ============================================================
## PART 6: Log specification
## ============================================================

daily[, log_property := log(property_crimes + 1)]
daily[, log_violent := log(violent_nonprop + 1)]

m1_log <- feols(log_property ~ avg_days_since_payment | dow + ym,
                data = daily, vcov = ~ym)

m3_log <- feols(log_property ~ n_paid_recent7 | dow + ym,
                data = daily, vcov = ~ym)

cat("\n--- Log specification ---\n")
print(summary(m1_log))

## ============================================================
## PART 7: Save key results for diagnostics
## ============================================================

## Write diagnostics.json
n_obs <- nrow(daily)
n_treated <- sum(daily$payment_day)  # days with payment
n_pre <- uniqueN(daily$ym)  # months of data (cross-sectional design, no pre-period)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_digits = 10,
  n_months = uniqueN(daily$ym),
  mean_property_crimes = round(mean(daily$property_crimes), 1),
  sd_property_crimes = round(sd(daily$property_crimes), 1),
  mean_dsp = round(mean(daily$avg_days_since_payment), 1),
  sd_dsp = round(sd(daily$avg_days_since_payment), 1),
  coef_dsp_linear = round(coef(m1)["avg_days_since_payment"], 4),
  se_dsp_linear = round(sqrt(vcov(m1)["avg_days_since_payment",
                                       "avg_days_since_payment"]), 4),
  coef_recent7 = round(coef(m3)["n_paid_recent7"], 4),
  se_recent7 = round(sqrt(vcov(m3)["n_paid_recent7", "n_paid_recent7"]), 4)
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
           auto_unbox = TRUE, pretty = TRUE)

cat("\nDiagnostics written to data/diagnostics.json\n")

## Save model objects
save(m1, m2, m3, m4, m5, p1, p3, r1, t1, r3, t3,
     m1_nc, m3_nc, m1_log, m3_log,
     file = file.path(data_dir, "models.RData"))

cat("\nMain analysis complete.\n")
