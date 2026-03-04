## ============================================================
## 02_clean_data.R — Construct variables and classify exposure
## The Cost of Sponsorship: Kafala Reform and Firm Value
## ============================================================

source(file.path(dirname(normalizePath(sys.frame(1)$ofile)), "00_packages.R"))

## ---------------------------------------------------------------
## 1. Load raw data
## ---------------------------------------------------------------
dfm_raw <- read_csv(file.path(data_dir, "dfm_raw.csv"), show_col_types = FALSE)
gcc_idx <- read_csv(file.path(data_dir, "gcc_indices.csv"), show_col_types = FALSE)

cat("Loaded DFM:", nrow(dfm_raw), "obs from", n_distinct(dfm_raw$ticker), "tickers\n")

## ---------------------------------------------------------------
## 2. Classify migrant labor exposure
## ---------------------------------------------------------------
## Based on UAE MOHRE statistics:
## - Construction/Real Estate: ~95% migrant workforce
## - Services/Hospitality/Transport: ~90% migrant workforce
## - Industrial/Manufacturing: ~85% migrant workforce
## - Banking/Finance: ~65% migrant workforce (more Emiratis in banking)
## - Insurance: ~70% migrant workforce
## - Telecom: ~60% migrant workforce (government-linked, more Emiratis)
## - Utilities: ~70% migrant workforce (government-linked)
## - Investment/Holding: ~60% migrant workforce

exposure_map <- tribble(
  ~sector, ~high_exposure, ~migrant_share_approx,
  "RealEstate",  TRUE,  0.95,
  "Services",    TRUE,  0.90,
  "Industrial",  TRUE,  0.85,
  "Banking",     FALSE, 0.65,
  "Insurance",   FALSE, 0.70,
  "Telecom",     FALSE, 0.60,
  "Financial",   FALSE, 0.65,
  "Investment",  FALSE, 0.60,
  "Utilities",   FALSE, 0.70
)

dfm <- dfm_raw %>%
  left_join(exposure_map, by = "sector") %>%
  filter(!is.na(high_exposure))

cat("After exposure classification:", nrow(dfm), "obs\n")
cat("High exposure firms:", n_distinct(dfm$ticker[dfm$high_exposure]), "\n")
cat("Low exposure firms:", n_distinct(dfm$ticker[!dfm$high_exposure]), "\n")

## ---------------------------------------------------------------
## 3. Compute daily returns
## ---------------------------------------------------------------
dfm <- dfm %>%
  arrange(ticker, date) %>%
  group_by(ticker) %>%
  mutate(
    ret = (close / lag(close)) - 1,
    log_ret = log(close / lag(close))
  ) %>%
  ungroup() %>%
  filter(!is.na(ret))

## Winsorize returns at 1st/99th percentile (remove extreme outliers)
p01 <- quantile(dfm$ret, 0.01, na.rm = TRUE)
p99 <- quantile(dfm$ret, 0.99, na.rm = TRUE)
dfm <- dfm %>%
  mutate(ret_w = pmax(pmin(ret, p99), p01))

## ---------------------------------------------------------------
## 4. Market index returns
## ---------------------------------------------------------------
## Use DFM General Index as the market benchmark
dfm_mkt <- gcc_idx %>%
  filter(market == "UAE_DFM") %>%
  arrange(date) %>%
  mutate(mkt_ret = (close / lag(close)) - 1) %>%
  filter(!is.na(mkt_ret)) %>%
  select(date, mkt_ret)

## Merge market return
dfm <- dfm %>%
  left_join(dfm_mkt, by = "date")

## ---------------------------------------------------------------
## 5. Compute abnormal returns (market-adjusted model)
## ---------------------------------------------------------------
## Simple market-adjusted return: AR = R_i - R_m
dfm <- dfm %>%
  mutate(ar = ret_w - mkt_ret)

## ---------------------------------------------------------------
## 6. Define event dates and windows
## ---------------------------------------------------------------
## Three key kafala reform events:
events <- tribble(
  ~event_id, ~event_date, ~event_label,
  1L, as.Date("2021-09-20"), "Law Signing (Decree-Law 33)",
  2L, as.Date("2021-11-15"), "Implementing Regulations Published",
  3L, as.Date("2022-02-02"), "Law Enters into Effect"
)

## Find nearest trading day for each event
trading_days <- sort(unique(dfm$date))

find_nearest_trading_day <- function(d, tdays) {
  idx <- which.min(abs(tdays - d))
  tdays[idx]
}

events <- events %>%
  rowwise() %>%
  mutate(trading_date = find_nearest_trading_day(event_date, trading_days)) %>%
  ungroup()

cat("\nEvent dates (nearest trading day):\n")
print(events)

## Create event windows: [-10, +10] trading days around each event
## Also define estimation window: [-120, -11] for market model estimation
create_event_window <- function(event_td, tdays, pre = 10, post = 10,
                                 est_start = 120, est_end = 11) {
  idx <- which(tdays == event_td)
  if (length(idx) == 0) return(NULL)

  window_start <- max(1, idx - pre)
  window_end   <- min(length(tdays), idx + post)
  est_begin    <- max(1, idx - est_start)
  est_finish   <- max(1, idx - est_end)

  tibble(
    date = tdays[window_start:window_end],
    event_time = (window_start:window_end) - idx,
    in_event_window = TRUE
  ) %>%
    bind_rows(
      tibble(
        date = tdays[est_begin:est_finish],
        event_time = (est_begin:est_finish) - idx,
        in_event_window = FALSE
      )
    )
}

event_windows <- events %>%
  rowwise() %>%
  mutate(window = list(create_event_window(trading_date, trading_days))) %>%
  unnest(window) %>%
  select(event_id, event_label, date, event_time, in_event_window)

## ---------------------------------------------------------------
## 7. Merge events with stock data
## ---------------------------------------------------------------
panel <- dfm %>%
  inner_join(event_windows, by = "date", relationship = "many-to-many")

cat("\nPanel dimensions:", nrow(panel), "obs\n")
cat("Events × firms × days structure created\n")

## ---------------------------------------------------------------
## 8. Create period indicators for DiD
## ---------------------------------------------------------------
## For the daily panel DiD: use Sept 20, 2021 as the main break
reform_date <- events$trading_date[events$event_id == 1]

dfm <- dfm %>%
  mutate(
    post_reform = date >= reform_date,
    post_law    = date >= events$trading_date[events$event_id == 3],
    # Relative time (in trading days) from first event
    rel_time = as.integer(difftime(date, reform_date, units = "days"))
  )

## ---------------------------------------------------------------
## 9. Summary statistics
## ---------------------------------------------------------------
summ <- dfm %>%
  group_by(high_exposure) %>%
  summarise(
    n_firms = n_distinct(ticker),
    n_obs = n(),
    mean_ret = mean(ret_w, na.rm = TRUE),
    sd_ret = sd(ret_w, na.rm = TRUE),
    mean_volume = mean(volume, na.rm = TRUE),
    .groups = "drop"
  )

cat("\n=== SUMMARY BY EXPOSURE GROUP ===\n")
print(summ)

## ---------------------------------------------------------------
## 10. Placebo dates (for robustness)
## ---------------------------------------------------------------
placebo_dates <- as.Date(c(
  "2021-03-15",  # Random pre-reform date
  "2021-06-01",  # Random pre-reform date
  "2020-09-14",  # Random pre-reform date
  "2022-06-01",  # Post-reform date (no specific event)
  "2020-03-09"   # COVID crash (test for general sensitivity)
))

## ---------------------------------------------------------------
## 11. Save cleaned data
## ---------------------------------------------------------------
write_csv(dfm, file.path(data_dir, "dfm_clean.csv"))
write_csv(panel, file.path(data_dir, "event_panel.csv"))
write_csv(events, file.path(data_dir, "events.csv"))
saveRDS(list(dfm = dfm, panel = panel, events = events,
             placebo_dates = placebo_dates, gcc_idx = gcc_idx,
             exposure_map = exposure_map),
        file.path(data_dir, "analysis_ready.rds"))

cat("\n=== CLEANING COMPLETE ===\n")
cat("DFM clean:", nrow(dfm), "obs,", n_distinct(dfm$ticker), "firms\n")
cat("Event panel:", nrow(panel), "obs across", n_distinct(panel$event_id), "events\n")
