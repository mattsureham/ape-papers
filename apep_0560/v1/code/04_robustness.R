# =============================================================================
# 04_robustness.R — Robustness checks and placebo tests
# APEP-0560: Market Discipline and Mining Safety
# =============================================================================

source("00_packages.R")

cat("=== Loading analysis data ===\n")
car_dt <- fread("../data/car_results.csv")
ar_dt_path <- "../data/stock_panel.csv"
events <- fread("../data/events_analysis.csv")
stock <- fread("../data/stock_panel.csv")
dates_map <- fread("../data/trading_dates.csv")

stock[, date := as.Date(date)]
dates_map[, date := as.Date(date)]
events[, event_date := as.Date(event_date)]

car_dt[, car_pct := car_main * 100]

# =============================================================================
# ROBUSTNESS 1: Alternative Event Windows
# =============================================================================
cat("\n=== Robustness 1: Alternative Event Windows ===\n")

windows <- list(
  "[-1,+1]" = c(-1, 1),
  "[-1,+3]" = c(-1, 3),
  "[-1,+5]" = c(-1, 5),
  "[0,+1]" = c(0, 1),
  "[0,+5]" = c(0, 5),
  "[-1,+10]" = c(-1, 10)
)

window_results <- rbindlist(lapply(names(windows), function(w) {
  ws <- windows[[w]][1]
  we <- windows[[w]][2]
  col <- paste0("car_", gsub("[^0-9]", "", w))

  # Recompute CARs for this window from ar_dt if needed
  # For now use the pre-computed windows
  if (w == "[-1,+1]") var <- "car_short"
  else if (w == "[-1,+5]") var <- "car_main"
  else if (w == "[-1,+10]") var <- "car_long"
  else return(NULL)

  data.table(
    window = w,
    mean_car = mean(car_dt[[var]], na.rm = TRUE) * 100,
    se = sd(car_dt[[var]], na.rm = TRUE) / sqrt(sum(!is.na(car_dt[[var]]))) * 100,
    n = sum(!is.na(car_dt[[var]]))
  )
}), fill = TRUE)

window_results <- window_results[!is.na(mean_car)]
window_results[, t_stat := mean_car / se]
cat("Window robustness:\n")
print(window_results)
fwrite(window_results, "../data/robustness_windows.csv")

# =============================================================================
# ROBUSTNESS 2: Exclude Overlapping Events
# =============================================================================
cat("\n=== Robustness 2: Exclude Overlapping Events ===\n")

car_no_overlap <- car_dt[overlap == FALSE | is.na(overlap)]
m_no_overlap <- feols(car_pct ~ has_tailings_dams + same_commodity +
                        i(severity, ref = "Other") | event_id,
                      data = car_no_overlap)
cat("Without overlapping events (N =", nrow(car_no_overlap), "):\n")
summary(m_no_overlap)

# =============================================================================
# ROBUSTNESS 3: Exclude Largest Events (Brumadinho, Samarco, Mount Polley)
# =============================================================================
cat("\n=== Robustness 3: Exclude Mega-Events ===\n")

# Identify events with most fatalities (likely Brumadinho, Samarco)
top_events <- events[order(-fatality_count)][1:min(5, nrow(events))]
cat("Top 5 deadliest events:\n")
print(top_events[, .(event_id, year, country_clean, ore_clean, fatality_count)])

car_no_mega <- car_dt[!event_id %in% top_events$event_id[1:3]]
m_no_mega <- feols(car_pct ~ has_tailings_dams + same_commodity +
                     i(severity, ref = "Other") | event_id,
                   data = car_no_mega)
cat("\nWithout top 3 deadliest events:\n")
summary(m_no_mega)

# =============================================================================
# ROBUSTNESS 4: Placebo Test — Random Event Dates
# =============================================================================
cat("\n=== Robustness 4: Placebo (Random Dates) ===\n")

set.seed(42)
n_placebo <- 200
trading_days <- dates_map$td

# Function to compute average CAR for a set of pseudo-events
compute_placebo_car <- function(pseudo_tds, stock_data) {
  all_cars <- numeric()
  for (ptd in pseudo_tds) {
    est_start <- ptd - 250
    est_end <- ptd - 31
    evt_start <- ptd - 1
    evt_end <- ptd + 5

    est_data <- stock_data[td >= est_start & td <= est_end]
    evt_data <- stock_data[td >= evt_start & td <= evt_end]

    if (nrow(est_data) < 1000 || nrow(evt_data) < 100) next

    # Quick estimation per firm
    for (tkr in unique(est_data$ticker)) {
      fe <- est_data[ticker == tkr]
      fv <- evt_data[ticker == tkr]
      if (nrow(fe) < 100 || nrow(fv) < 5) next

      mod <- tryCatch(lm(ret ~ mkt_ret, data = fe), error = function(e) NULL)
      if (is.null(mod)) next

      ar <- fv$ret - predict(mod, newdata = fv)
      all_cars <- c(all_cars, sum(ar))
    }
  }
  mean(all_cars, na.rm = TRUE)
}

# Generate placebo distribution
valid_tds <- trading_days[trading_days >= 300 & trading_days <= max(trading_days) - 20]
placebo_cars <- numeric(n_placebo)

cat("Running", n_placebo, "placebo iterations...\n")
for (iter in seq_len(n_placebo)) {
  if (iter %% 20 == 0) cat("  Iteration", iter, "\n")
  # Sample same number of events as actual
  n_events_actual <- uniqueN(car_dt$event_id)
  pseudo_tds <- sample(valid_tds, min(n_events_actual, 30))
  placebo_cars[iter] <- compute_placebo_car(pseudo_tds, stock)
}

placebo_dt <- data.table(
  iteration = seq_len(n_placebo),
  placebo_car = placebo_cars * 100
)

# Compare actual vs placebo
actual_car <- mean(car_dt$car_main, na.rm = TRUE) * 100
p_value <- mean(placebo_cars * 100 <= actual_car, na.rm = TRUE)

cat(sprintf("\nPlacebo test results:\n"))
cat(sprintf("  Actual mean CAR: %.4f%%\n", actual_car))
cat(sprintf("  Placebo mean: %.4f%%\n", mean(placebo_cars * 100, na.rm = TRUE)))
cat(sprintf("  Placebo SD: %.4f%%\n", sd(placebo_cars * 100, na.rm = TRUE)))
cat(sprintf("  p-value (one-sided): %.4f\n", p_value))

fwrite(placebo_dt, "../data/placebo_distribution.csv")
fwrite(data.table(actual_car = actual_car, p_value = p_value),
       "../data/placebo_test_result.csv")

# =============================================================================
# ROBUSTNESS 5: Non-Mining Placebo Firms
# =============================================================================
cat("\n=== Robustness 5: Non-Mining Placebo (XLU Utilities ETF) ===\n")

# Fetch utility sector ETF as placebo
tryCatch({
  xlu <- getSymbols("XLU", src = "yahoo", from = "2000-01-01", auto.assign = FALSE)
  xlu_ret <- dailyReturn(Ad(xlu), type = "log")
  xlu_dt <- data.table(
    date = index(xlu_ret),
    xlu_ret = as.numeric(xlu_ret)
  )
  xlu_dt <- xlu_dt[!is.na(xlu_ret)]
  xlu_dt[, date := as.Date(date)]

  # Merge with trading dates
  xlu_dt <- merge(xlu_dt, dates_map, by = "date")

  # Compute CARs for XLU around actual events
  sp500 <- fread("../data/benchmark_returns.csv")
  sp500 <- sp500[benchmark == "^GSPC", .(date = as.Date(date), mkt_ret)]
  xlu_dt <- merge(xlu_dt, sp500, by = "date")

  xlu_cars <- numeric()
  for (i in seq_len(nrow(events))) {
    evt_td <- events$event_td[i]
    est <- xlu_dt[td >= (evt_td - 250) & td <= (evt_td - 31)]
    evt <- xlu_dt[td >= (evt_td - 1) & td <= (evt_td + 5)]

    if (nrow(est) < 100 || nrow(evt) < 5) next

    mod <- lm(xlu_ret ~ mkt_ret, data = est)
    ar <- evt$xlu_ret - predict(mod, newdata = evt)
    xlu_cars <- c(xlu_cars, sum(ar))
  }

  cat(sprintf("  Utility (XLU) placebo CAR [-1,+5]: %.4f%%\n",
              mean(xlu_cars, na.rm = TRUE) * 100))
  cat(sprintf("  t-stat: %.2f\n",
              mean(xlu_cars, na.rm = TRUE) / (sd(xlu_cars, na.rm = TRUE) / sqrt(length(xlu_cars)))))

  fwrite(data.table(xlu_car = xlu_cars * 100), "../data/xlu_placebo_cars.csv")
}, error = function(e) {
  cat("  XLU placebo failed:", e$message, "\n")
})

# =============================================================================
# ROBUSTNESS 6: Leave-One-Event-Out
# =============================================================================
cat("\n=== Robustness 6: Leave-One-Event-Out ===\n")

events_unique <- unique(car_dt$event_id)
loo_results <- data.table(
  dropped_event = events_unique,
  mean_car = sapply(events_unique, function(eid) {
    mean(car_dt[event_id != eid]$car_main, na.rm = TRUE) * 100
  })
)

cat(sprintf("  LOO range: [%.4f%%, %.4f%%]\n",
            min(loo_results$mean_car), max(loo_results$mean_car)))
cat(sprintf("  Full sample: %.4f%%\n", actual_car))

fwrite(loo_results, "../data/loo_results.csv")

# =============================================================================
# ROBUSTNESS 7: Fama-French 3-Factor Model
# =============================================================================
cat("\n=== Robustness 7: Alternative Market Model (XME Benchmark) ===\n")

# Use mining-sector ETF (XME) as alternative benchmark
xme <- fread("../data/benchmark_returns.csv")[benchmark == "XME"]
xme[, date := as.Date(date)]
setnames(xme, "mkt_ret", "xme_ret")

if (nrow(xme) > 0) {
  stock_xme <- merge(stock, xme[, .(date, xme_ret)], by = "date")

  # Re-estimate with XME as benchmark for events within XME coverage
  # XME starts June 2006; need 250 days estimation window, so events from ~mid 2007+
  xme_min_td <- min(stock_xme$td, na.rm = TRUE) + 260
  xme_events <- events[event_td >= xme_min_td]
  cat(sprintf("  Events within XME coverage: %d of %d\n", nrow(xme_events), nrow(events)))
  sample_events <- xme_events$event_td

  xme_cars <- list()
  for (evt_td in sample_events) {
    est <- stock_xme[td >= (evt_td - 250) & td <= (evt_td - 31)]
    evt <- stock_xme[td >= (evt_td - 1) & td <= (evt_td + 5)]

    for (tkr in unique(est$ticker)) {
      fe <- est[ticker == tkr]
      fv <- evt[ticker == tkr]
      if (nrow(fe) < 100 || nrow(fv) < 5) next

      mod <- tryCatch(lm(ret ~ xme_ret, data = fe), error = function(e) NULL)
      if (is.null(mod)) next

      ar <- fv$ret - predict(mod, newdata = fv)
      xme_cars[[length(xme_cars) + 1]] <- data.table(
        event_td = evt_td, ticker = tkr, car_xme = sum(ar)
      )
    }
  }

  xme_dt <- rbindlist(xme_cars)
  cat(sprintf("  XME-benchmark CAR: %.4f%% (N=%d)\n",
              mean(xme_dt$car_xme, na.rm = TRUE) * 100, nrow(xme_dt)))
  fwrite(xme_dt, "../data/robustness_xme_cars.csv")
} else {
  cat("  XME data not available, skipping\n")
}

# =============================================================================
# ROBUSTNESS 8: Winsorized CARs
# =============================================================================
cat("\n=== Robustness 8: Winsorized CARs ===\n")

winsorize <- function(x, p = 0.01) {
  q <- quantile(x, probs = c(p, 1 - p), na.rm = TRUE)
  pmin(pmax(x, q[1]), q[2])
}

car_dt[, car_pct_w := winsorize(car_pct)]
m_winsor <- feols(car_pct_w ~ has_tailings_dams + same_commodity +
                    i(severity, ref = "Other") | event_id,
                  data = car_dt)
cat("Winsorized (1/99) regression:\n")
summary(m_winsor)

# Save robustness summary
robustness_summary <- data.table(
  test = c("Main", "No overlap", "No mega-events", "Placebo p-value",
           "Winsorized", "LOO min", "LOO max"),
  value = c(
    actual_car,
    mean(car_no_overlap$car_pct, na.rm = TRUE),
    mean(car_no_mega$car_pct, na.rm = TRUE),
    p_value,
    mean(car_dt$car_pct_w, na.rm = TRUE),
    min(loo_results$mean_car),
    max(loo_results$mean_car)
  )
)
fwrite(robustness_summary, "../data/robustness_summary.csv")

# =============================================================================
# ROBUSTNESS 9: Two-Way Clustering (Event + Firm)
# =============================================================================
cat("\n=== Robustness 9: Two-Way Clustering (Event + Firm) ===\n")

# Re-estimate key specifications with two-way clustering
m_twoway_h1 <- feols(car_pct ~ has_tailings_dams + same_commodity,
                     data = car_dt, cluster = ~event_id + ticker)
m_twoway_fe <- feols(car_pct ~ has_tailings_dams + same_commodity | event_id,
                     data = car_dt, cluster = ~event_id + ticker)
m_twoway_gistm <- feols(car_pct ~ has_tailings_dams * post_gistm +
                           same_commodity * post_gistm +
                           i(severity, ref = "Other"),
                         data = car_dt, cluster = ~event_id + ticker)

cat("\n--- Two-Way Clustered Results ---\n")
cat("H1 (has_tailings): coef =", coef(m_twoway_h1)["has_tailings_damsTRUE"],
    ", SE =", se(m_twoway_h1)["has_tailings_damsTRUE"],
    ", t =", tstat(m_twoway_h1)["has_tailings_damsTRUE"], "\n")
cat("Event FE (has_tailings): coef =", coef(m_twoway_fe)["has_tailings_damsTRUE"],
    ", SE =", se(m_twoway_fe)["has_tailings_damsTRUE"],
    ", t =", tstat(m_twoway_fe)["has_tailings_damsTRUE"], "\n")
cat("GISTM interaction: coef =", coef(m_twoway_gistm)["has_tailings_damsTRUE:post_gistmTRUE"],
    ", SE =", se(m_twoway_gistm)["has_tailings_damsTRUE:post_gistmTRUE"],
    ", t =", tstat(m_twoway_gistm)["has_tailings_damsTRUE:post_gistmTRUE"], "\n")

twoway_results <- data.table(
  spec = c("H1 (OLS)", "H1 (Event FE)", "GISTM interaction"),
  coef = c(coef(m_twoway_h1)["has_tailings_damsTRUE"],
           coef(m_twoway_fe)["has_tailings_damsTRUE"],
           coef(m_twoway_gistm)["has_tailings_damsTRUE:post_gistmTRUE"]),
  se_event = c(se(feols(car_pct ~ has_tailings_dams + same_commodity,
                        data = car_dt, cluster = ~event_id))["has_tailings_damsTRUE"],
               se(feols(car_pct ~ has_tailings_dams + same_commodity | event_id,
                        data = car_dt, cluster = ~event_id))["has_tailings_damsTRUE"],
               se(feols(car_pct ~ has_tailings_dams * post_gistm +
                          same_commodity * post_gistm +
                          i(severity, ref = "Other"),
                        data = car_dt, cluster = ~event_id))["has_tailings_damsTRUE:post_gistmTRUE"]),
  se_twoway = c(se(m_twoway_h1)["has_tailings_damsTRUE"],
                se(m_twoway_fe)["has_tailings_damsTRUE"],
                se(m_twoway_gistm)["has_tailings_damsTRUE:post_gistmTRUE"]),
  t_twoway = c(tstat(m_twoway_h1)["has_tailings_damsTRUE"],
               tstat(m_twoway_fe)["has_tailings_damsTRUE"],
               tstat(m_twoway_gistm)["has_tailings_damsTRUE:post_gistmTRUE"])
)
fwrite(twoway_results, "../data/robustness_twoway.csv")
cat("\nTwo-way clustering results:\n")
print(twoway_results)

# =============================================================================
# ROBUSTNESS 10: Leave-One-Streaming-Firm-Out
# =============================================================================
cat("\n=== Robustness 10: Leave-One-Streaming-Firm-Out ===\n")

streaming_tickers <- car_dt[is_streaming_royalty == TRUE, unique(ticker)]
cat("Streaming firms:", paste(streaming_tickers, collapse = ", "), "\n")

loo_streaming <- list()
for (drop_ticker in streaming_tickers) {
  sub <- car_dt[ticker != drop_ticker]
  m_sub <- feols(car_pct ~ has_tailings_dams + same_commodity | event_id,
                 data = sub, cluster = ~event_id)
  loo_streaming[[drop_ticker]] <- data.table(
    dropped = drop_ticker,
    coef = coef(m_sub)["has_tailings_damsTRUE"],
    se = se(m_sub)["has_tailings_damsTRUE"],
    t = tstat(m_sub)["has_tailings_damsTRUE"],
    n = nobs(m_sub)
  )
  cat(sprintf("  Drop %s: coef=%.4f, t=%.2f (N=%d)\n",
              drop_ticker, coef(m_sub)["has_tailings_damsTRUE"],
              tstat(m_sub)["has_tailings_damsTRUE"], nobs(m_sub)))
}
loo_streaming_dt <- rbindlist(loo_streaming)
fwrite(loo_streaming_dt, "../data/robustness_loo_streaming.csv")

# =============================================================================
# ROBUSTNESS 11: Brumadinho vs GISTM Disentangling
# =============================================================================
cat("\n=== Robustness 11: Brumadinho vs GISTM ===\n")

# Create three periods: Pre-Brumadinho, Post-Brumadinho/Pre-GISTM, Post-GISTM
car_dt[, event_date_dt := as.Date(event_date)]
car_dt[, period := fcase(
  event_date_dt < as.Date("2019-01-25"), "Pre-Brumadinho",
  event_date_dt >= as.Date("2019-01-25") & event_date_dt < as.Date("2020-08-05"), "Post-Brumadinho",
  event_date_dt >= as.Date("2020-08-05"), "Post-GISTM"
)]
car_dt[, period := factor(period, levels = c("Pre-Brumadinho", "Post-Brumadinho", "Post-GISTM"))]

cat("Events by period:\n")
print(car_dt[, .(n_events = uniqueN(event_id), n_obs = .N), by = period])

m_triple <- feols(car_pct ~ has_tailings_dams * period +
                    same_commodity +
                    i(severity, ref = "Other"),
                  data = car_dt, cluster = ~event_id)
cat("\nTriple-period results:\n")
summary(m_triple)

# Save key coefficients
triple_results <- data.table(
  term = names(coef(m_triple)),
  coef = coef(m_triple),
  se = se(m_triple),
  t = tstat(m_triple)
)
fwrite(triple_results, "../data/robustness_brumadinho.csv")

cat("\n=== ALL ROBUSTNESS CHECKS COMPLETE ===\n")
print(robustness_summary)
