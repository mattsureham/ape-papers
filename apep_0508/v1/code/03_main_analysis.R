## ============================================================
## 03_main_analysis.R — Main event study + DiD analysis
## The Cost of Sponsorship: Kafala Reform and Firm Value
## ============================================================

source(file.path(dirname(normalizePath(sys.frame(1)$ofile)), "00_packages.R"))

dat <- readRDS(file.path(data_dir, "analysis_ready.rds"))
dfm   <- dat$dfm
panel <- dat$panel
events <- dat$events

## ===============================================================
## ANALYSIS 1: CUMULATIVE ABNORMAL RETURNS (CAR)
## ===============================================================

## For each event × firm: compute CAR over [-1, +3] window
compute_car <- function(panel_df, window_start = -1, window_end = 3) {
  panel_df %>%
    filter(in_event_window,
           event_time >= window_start,
           event_time <= window_end) %>%
    group_by(event_id, event_label, ticker, name, sector,
             high_exposure, migrant_share_approx) %>%
    summarise(
      car = sum(ar, na.rm = TRUE),
      n_days = n(),
      .groups = "drop"
    )
}

car_main <- compute_car(panel)
cat("CAR computed for", nrow(car_main), "firm × event observations\n")

## --- Main test: CAR by exposure group ---
car_test <- car_main %>%
  group_by(event_id, event_label, high_exposure) %>%
  summarise(
    n = n(),
    mean_car = mean(car),
    sd_car = sd(car),
    se_car = sd(car) / sqrt(n()),
    t_stat = mean(car) / (sd(car) / sqrt(n())),
    .groups = "drop"
  )

cat("\n=== CAR BY EXPOSURE GROUP ===\n")
print(car_test, width = Inf)

## --- Cross-sectional regression of CARs ---
## Pool across events for stacked analysis
car_reg <- feols(car ~ high_exposure | event_id, data = car_main,
                 cluster = ~ticker)
cat("\n=== STACKED CAR REGRESSION (Firm-clustered SE) ===\n")
summary(car_reg)

## With continuous exposure
car_reg_cont <- feols(car ~ migrant_share_approx | event_id, data = car_main,
                      cluster = ~ticker)
cat("\n=== CONTINUOUS EXPOSURE CAR REGRESSION ===\n")
summary(car_reg_cont)

## ===============================================================
## ANALYSIS 2: EVENT STUDY PLOT (Dynamic treatment effects)
## ===============================================================

## Compute daily abnormal returns by exposure group for each event
es_daily <- panel %>%
  filter(in_event_window) %>%
  group_by(event_id, event_label, event_time, high_exposure) %>%
  summarise(
    mean_ar = mean(ar, na.rm = TRUE),
    se_ar = sd(ar, na.rm = TRUE) / sqrt(n()),
    n = n(),
    .groups = "drop"
  )

## Compute CUMULATIVE abnormal returns through event time
es_cumulative <- panel %>%
  filter(in_event_window) %>%
  arrange(event_id, ticker, event_time) %>%
  group_by(event_id, event_label, ticker, high_exposure) %>%
  mutate(cum_ar = cumsum(ar)) %>%
  ungroup() %>%
  group_by(event_id, event_label, event_time, high_exposure) %>%
  summarise(
    mean_cum_ar = mean(cum_ar, na.rm = TRUE),
    se_cum_ar = sd(cum_ar, na.rm = TRUE) / sqrt(n()),
    n = n(),
    .groups = "drop"
  )

## ===============================================================
## ANALYSIS 3: DAILY PANEL DiD
## ===============================================================

## Use the full daily panel with firm + date FE
## Focus on a [-60, +60] trading day window around the first event

reform_td <- events$trading_date[events$event_id == 1]
did_window_start <- reform_td - 90  # ~60 trading days before
did_window_end   <- reform_td + 90  # ~60 trading days after

dfm_did <- dfm %>%
  filter(date >= did_window_start, date <= did_window_end)

## Main DiD: high_exposure × post_reform
did_main <- feols(ret_w ~ high_exposure:post_reform | ticker + date,
                  data = dfm_did, cluster = ~ticker)
cat("\n=== DAILY PANEL DiD (Main Specification) ===\n")
summary(did_main)

## Dynamic DiD with event-time interactions
## Create weekly event-time bins for readability
dfm_did <- dfm_did %>%
  mutate(
    trading_day_idx = match(date, sort(unique(date))),
    event_day_idx = match(reform_td, sort(unique(date))),
    rel_trading_day = trading_day_idx - event_day_idx,
    # Bin into 2-week (10 trading day) periods
    rel_week = floor(rel_trading_day / 10) * 10
  )

did_dynamic <- feols(ret_w ~ i(rel_week, high_exposure, ref = -10) | ticker + date,
                     data = dfm_did, cluster = ~ticker)
cat("\n=== DYNAMIC DiD (bi-weekly bins) ===\n")
summary(did_dynamic)

## ===============================================================
## ANALYSIS 4: STACKED EVENT STUDY (all 3 events)
## ===============================================================

## Create stacked dataset: for each event, take a [-30, +30] trading day window
stacked <- map_dfr(1:3, function(ev) {
  td <- events$trading_date[events$event_id == ev]
  tdays <- sort(unique(dfm$date))
  idx <- which(tdays == td)
  if (length(idx) == 0) return(NULL)

  window_idx <- max(1, idx - 30):min(length(tdays), idx + 30)
  window_dates <- tdays[window_idx]

  dfm %>%
    filter(date %in% window_dates) %>%
    mutate(
      stack_event = ev,
      rel_td = match(date, window_dates) - which(window_dates == td),
      post_event = date >= td
    )
})

## Stacked DiD
stacked_did <- feols(ret_w ~ high_exposure:post_event |
                       ticker^stack_event + date^stack_event,
                     data = stacked, cluster = ~ticker)
cat("\n=== STACKED DiD (3 events pooled) ===\n")
summary(stacked_did)

## ===============================================================
## ANALYSIS 5: MARKET MODEL APPROACH
## ===============================================================

## Estimate beta for each firm using pre-event estimation window
## Then compute market-model abnormal returns

## Use [-250, -11] trading days before first event for estimation
est_end <- reform_td - 15  # ~11 trading days
est_start <- reform_td - 365  # ~250 trading days

dfm_est <- dfm %>%
  filter(date >= est_start, date <= est_end, !is.na(mkt_ret))

## Estimate market model for each firm
betas <- dfm_est %>%
  group_by(ticker) %>%
  filter(n() >= 50) %>%  # need enough data
  do({
    mod <- lm(ret_w ~ mkt_ret, data = .)
    tibble(alpha = coef(mod)[1], beta = coef(mod)[2], r2 = summary(mod)$r.squared)
  }) %>%
  ungroup()

cat("\n=== MARKET MODEL BETAS ===\n")
cat("Estimated for", nrow(betas), "firms\n")
cat("Mean beta:", round(mean(betas$beta), 3), "\n")
cat("Mean R²:", round(mean(betas$r2), 3), "\n")

## Compute market-model abnormal returns
dfm_mm <- dfm %>%
  inner_join(betas, by = "ticker") %>%
  mutate(ar_mm = ret_w - (alpha + beta * mkt_ret))

## Re-compute CAR with market-model ARs
panel_mm <- panel %>%
  inner_join(betas, by = "ticker") %>%
  mutate(ar_mm = ar - (alpha + (beta - 1) * mkt_ret))

car_mm <- panel_mm %>%
  filter(in_event_window, event_time >= -1, event_time <= 3) %>%
  group_by(event_id, event_label, ticker, high_exposure) %>%
  summarise(car_mm = sum(ar_mm, na.rm = TRUE), .groups = "drop")

car_mm_reg <- feols(car_mm ~ high_exposure | event_id, data = car_mm,
                    cluster = ~ticker)
cat("\n=== MARKET MODEL CAR REGRESSION ===\n")
summary(car_mm_reg)

## ===============================================================
## SAVE ALL RESULTS
## ===============================================================

saveRDS(list(
  car_main = car_main,
  car_test = car_test,
  car_reg = car_reg,
  car_reg_cont = car_reg_cont,
  es_daily = es_daily,
  es_cumulative = es_cumulative,
  did_main = did_main,
  did_dynamic = did_dynamic,
  stacked_did = stacked_did,
  betas = betas,
  car_mm_reg = car_mm_reg,
  dfm_did = dfm_did,
  stacked = stacked
), file.path(data_dir, "main_results.rds"))

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
