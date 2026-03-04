## ============================================================
## 04_robustness.R — Robustness checks and placebos
## The Cost of Sponsorship: Kafala Reform and Firm Value
## ============================================================

source(file.path(dirname(normalizePath(sys.frame(1)$ofile)), "00_packages.R"))

dat <- readRDS(file.path(data_dir, "analysis_ready.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
dfm   <- dat$dfm
panel <- dat$panel
events <- dat$events

## ===============================================================
## ROBUSTNESS 1: ALTERNATIVE EVENT WINDOWS
## ===============================================================

windows <- list(
  "[-1,+1]"  = c(-1, 1),
  "[-1,+3]"  = c(-1, 3),   # main
  "[-2,+5]"  = c(-2, 5),
  "[0,+5]"   = c(0, 5),
  "[0,+10]"  = c(0, 10)
)

car_windows <- map_dfr(names(windows), function(wname) {
  w <- windows[[wname]]
  panel %>%
    filter(in_event_window, event_time >= w[1], event_time <= w[2]) %>%
    group_by(event_id, ticker, high_exposure) %>%
    summarise(car = sum(ar, na.rm = TRUE), .groups = "drop") %>%
    mutate(window = wname)
})

## Regression for each window
window_regs <- car_windows %>%
  group_by(window) %>%
  do({
    mod <- feols(car ~ high_exposure | event_id, data = ., cluster = ~ticker)
    tibble(
      coef = coef(mod)["high_exposureTRUE"],
      se = sqrt(diag(vcov(mod)))["high_exposureTRUE"],
      n = nobs(mod)
    )
  }) %>%
  ungroup() %>%
  mutate(
    ci_lo = coef - 1.96 * se,
    ci_hi = coef + 1.96 * se,
    p_val = 2 * pnorm(-abs(coef / se))
  )

cat("=== ALTERNATIVE WINDOW RESULTS ===\n")
print(window_regs)

## ===============================================================
## ROBUSTNESS 2: PLACEBO EVENT DATES
## ===============================================================

placebo_dates <- dat$placebo_dates
trading_days <- sort(unique(dfm$date))

placebo_results <- map_dfr(seq_along(placebo_dates), function(i) {
  pd <- placebo_dates[i]
  td <- trading_days[which.min(abs(trading_days - pd))]
  td_idx <- which(trading_days == td)

  if (td_idx < 11 || td_idx > length(trading_days) - 10) return(NULL)

  window_dates <- trading_days[(td_idx - 10):(td_idx + 10)]
  event_times <- -10:10

  pdat <- dfm %>%
    filter(date %in% window_dates) %>%
    mutate(event_time = match(date, window_dates) - 11) %>%
    filter(event_time >= -1, event_time <= 3) %>%
    group_by(ticker, high_exposure) %>%
    summarise(car = sum(ar, na.rm = TRUE), .groups = "drop") %>%
    mutate(placebo_date = as.character(pd), placebo_id = i)

  mod <- tryCatch(
    feols(car ~ high_exposure, data = pdat, cluster = ~ticker),
    error = function(e) NULL
  )

  if (is.null(mod)) return(NULL)

  tibble(
    placebo_date = as.character(pd),
    coef = coef(mod)["high_exposureTRUE"],
    se = sqrt(diag(vcov(mod)))["high_exposureTRUE"],
    n = nobs(mod)
  )
})

if (nrow(placebo_results) > 0) {
  placebo_results <- placebo_results %>%
    mutate(
      ci_lo = coef - 1.96 * se,
      ci_hi = coef + 1.96 * se,
      significant = abs(coef / se) > 1.96
    )
  cat("\n=== PLACEBO DATE RESULTS ===\n")
  print(placebo_results)
  cat("Significant placebos:", sum(placebo_results$significant), "of",
      nrow(placebo_results), "\n")
}

## ===============================================================
## ROBUSTNESS 3: GCC PLACEBO (Saudi firms should not react)
## ===============================================================

gcc_idx <- dat$gcc_idx

## Compute returns for Saudi and Qatar indices
gcc_ret <- gcc_idx %>%
  arrange(market, date) %>%
  group_by(market) %>%
  mutate(ret = (close / lag(close)) - 1) %>%
  filter(!is.na(ret)) %>%
  ungroup()

## For each event date, compute CAR for GCC indices
gcc_car <- map_dfr(1:3, function(ev) {
  td <- events$trading_date[events$event_id == ev]
  gcc_tdays <- sort(unique(gcc_ret$date))
  idx <- which.min(abs(gcc_tdays - td))

  if (idx < 2 || idx > length(gcc_tdays) - 3) return(NULL)

  window <- gcc_tdays[(idx - 1):(idx + 3)]

  gcc_ret %>%
    filter(date %in% window) %>%
    group_by(market) %>%
    summarise(car = sum(ret, na.rm = TRUE), .groups = "drop") %>%
    mutate(event_id = ev)
})

cat("\n=== GCC INDEX CAR AROUND UAE REFORM DATES ===\n")
print(gcc_car)

## ===============================================================
## ROBUSTNESS 4: RANDOMIZATION INFERENCE
## ===============================================================

## Permute the high_exposure label 1000 times
## Compare actual coefficient to null distribution

set.seed(42)
n_perms <- 1000

# Use the main stacked CAR data
car_main <- results$car_main
actual_coef <- coef(results$car_reg)["high_exposureTRUE"]

ri_coefs <- numeric(n_perms)
firms <- unique(car_main$ticker)

for (p in seq_len(n_perms)) {
  perm_map <- tibble(
    ticker = firms,
    high_exposure_perm = sample(car_main$high_exposure[match(firms, car_main$ticker)])
  )

  car_perm <- car_main %>%
    left_join(perm_map, by = "ticker") %>%
    mutate(high_exposure = high_exposure_perm)

  mod_perm <- tryCatch(
    feols(car ~ high_exposure | event_id, data = car_perm),
    error = function(e) NULL
  )
  if (!is.null(mod_perm)) {
    ri_coefs[p] <- coef(mod_perm)["high_exposureTRUE"]
  }
}

ri_pvalue <- mean(abs(ri_coefs) >= abs(actual_coef))
cat("\n=== RANDOMIZATION INFERENCE ===\n")
cat("Actual coefficient:", round(actual_coef, 4), "\n")
cat("RI p-value (two-sided):", round(ri_pvalue, 4), "\n")
cat("5th/95th percentile of null:", round(quantile(ri_coefs, c(0.05, 0.95)), 4), "\n")

## ===============================================================
## ROBUSTNESS 5: VOLUME RESPONSE (mechanism)
## ===============================================================

## Check if trading volume changed differentially for high vs low exposure
## This tests whether markets were paying attention

vol_panel <- panel %>%
  filter(in_event_window) %>%
  group_by(ticker) %>%
  mutate(
    log_volume = log(volume + 1),
    avg_volume_pre = mean(volume[event_time < 0], na.rm = TRUE),
    abnormal_volume = (volume - avg_volume_pre) / (avg_volume_pre + 1)
  ) %>%
  ungroup()

vol_reg <- feols(abnormal_volume ~ high_exposure:I(event_time >= 0) |
                   ticker + event_time^event_id,
                 data = vol_panel, cluster = ~ticker)
cat("\n=== VOLUME RESPONSE ===\n")
summary(vol_reg)

## ===============================================================
## ROBUSTNESS 6: EXCLUDING EACH EVENT (leave-one-out)
## ===============================================================

loo_results <- map_dfr(1:3, function(ev) {
  car_loo <- results$car_main %>% filter(event_id != ev)
  mod <- feols(car ~ high_exposure | event_id, data = car_loo, cluster = ~ticker)
  tibble(
    excluded_event = ev,
    coef = coef(mod)["high_exposureTRUE"],
    se = sqrt(diag(vcov(mod)))["high_exposureTRUE"]
  )
})

cat("\n=== LEAVE-ONE-OUT EVENT RESULTS ===\n")
print(loo_results)

## ===============================================================
## SAVE ALL ROBUSTNESS RESULTS
## ===============================================================

saveRDS(list(
  window_regs = window_regs,
  placebo_results = placebo_results,
  gcc_car = gcc_car,
  ri_pvalue = ri_pvalue,
  ri_coefs = ri_coefs,
  actual_coef = actual_coef,
  vol_reg = vol_reg,
  loo_results = loo_results,
  car_windows = car_windows
), file.path(data_dir, "robustness_results.rds"))

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
