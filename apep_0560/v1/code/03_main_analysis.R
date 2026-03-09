# =============================================================================
# 03_main_analysis.R — Event study and cross-sectional regressions
# APEP-0560: Market Discipline and Mining Safety
# =============================================================================

source("00_packages.R")

cat("=== Loading analysis data ===\n")
events <- fread("../data/events_analysis.csv")
stock <- fread("../data/stock_panel.csv")
dates_map <- fread("../data/trading_dates.csv")
firms <- fread("../data/mining_firms_universe.csv")

# Convert dates
stock[, date := as.Date(date)]
dates_map[, date := as.Date(date)]
events[, event_date := as.Date(event_date)]

# =============================================================================
# STEP 1: Estimate Market Model Parameters (Normal Returns)
# =============================================================================
cat("\n=== STEP 1: Estimating Market Model ===\n")

# Estimation window: [-250, -31] trading days before each event
# Event window: [-5, +10] trading days (flexible, trim later)

estimate_normal_returns <- function(event_td, estimation_window = c(-250, -31),
                                    event_window = c(-5, 10)) {
  est_start <- event_td + estimation_window[1]
  est_end <- event_td + estimation_window[2]
  evt_start <- event_td + event_window[1]
  evt_end <- event_td + event_window[2]

  # Get all firm-level data in estimation window
  est_data <- stock[td >= est_start & td <= est_end]
  evt_data <- stock[td >= evt_start & td <= evt_end]

  if (nrow(est_data) == 0 || nrow(evt_data) == 0) return(NULL)

  # Estimate market model for each firm
  firms_in_data <- unique(est_data$ticker)
  results_list <- list()

  for (tkr in firms_in_data) {
    firm_est <- est_data[ticker == tkr]
    firm_evt <- evt_data[ticker == tkr]

    # Need at least 100 estimation days
    if (nrow(firm_est) < 100) next

    # OLS: R_it = alpha + beta * R_mt + eps
    model <- tryCatch(
      lm(ret ~ mkt_ret, data = firm_est),
      error = function(e) NULL
    )
    if (is.null(model)) next

    alpha <- coef(model)[1]
    beta <- coef(model)[2]
    sigma <- sd(residuals(model))

    # Predicted (normal) returns in event window
    if (nrow(firm_evt) == 0) next

    firm_evt[, `:=`(
      normal_ret = alpha + beta * mkt_ret,
      ar = ret - (alpha + beta * mkt_ret),  # Abnormal return
      event_day = td - event_td
    )]

    firm_evt[, `:=`(
      alpha_hat = alpha,
      beta_hat = beta,
      sigma_hat = sigma,
      n_est_days = nrow(firm_est)
    )]

    results_list[[tkr]] <- firm_evt
  }

  if (length(results_list) == 0) return(NULL)
  rbindlist(results_list, fill = TRUE)
}

# Run event study for each event
cat("Running event study for", nrow(events), "events...\n")

all_ar <- list()
for (i in seq_len(nrow(events))) {
  if (i %% 10 == 0) cat("  Event", i, "of", nrow(events), "\n")

  evt <- events[i]
  ar_data <- estimate_normal_returns(evt$event_td)

  if (!is.null(ar_data)) {
    ar_data[, event_id := evt$event_id]
    ar_data[, event_year := evt$year]
    ar_data[, event_country := evt$country_clean]
    ar_data[, event_ore := evt$ore_clean]
    ar_data[, event_severity := evt$severity]
    ar_data[, event_fatal := evt$has_fatalities]
    ar_data[, event_fatality_count := evt$fatality_count]
    ar_data[, post_gistm := evt$post_gistm]

    # Match commodity
    ar_data[, same_commodity := (primary_commodity == event_ore) |
              (primary_commodity == "Diversified")]

    all_ar[[i]] <- ar_data
  }
}

ar_dt <- rbindlist(all_ar, fill = TRUE)
cat("Total abnormal return observations:", nrow(ar_dt), "\n")
cat("Unique events with data:", uniqueN(ar_dt$event_id), "\n")
cat("Unique firms:", uniqueN(ar_dt$ticker), "\n")

# =============================================================================
# STEP 2: Compute Cumulative Abnormal Returns (CARs)
# =============================================================================
cat("\n=== STEP 2: Computing CARs ===\n")

# Primary window: [-1, +5]
compute_car <- function(dt, window_start, window_end, suffix = "") {
  car <- dt[event_day >= window_start & event_day <= window_end,
            .(car = sum(ar, na.rm = TRUE),
              n_days = .N),
            by = .(event_id, ticker)]
  setnames(car, "car", paste0("car", suffix))
  setnames(car, "n_days", paste0("n_days", suffix))
  return(car)
}

# Multiple windows
car_1_1 <- compute_car(ar_dt, -1, 1, "_short")
car_1_5 <- compute_car(ar_dt, -1, 5, "_main")
car_1_10 <- compute_car(ar_dt, -1, 10, "_long")
car_pre <- compute_car(ar_dt, -5, -2, "_pre")  # Pre-event placebo

# Merge all CARs
car_dt <- Reduce(function(x, y) merge(x, y, by = c("event_id", "ticker"), all = TRUE),
                 list(car_1_1, car_1_5, car_1_10, car_pre))

# Merge event and firm characteristics
car_dt <- merge(car_dt, events[, .(event_id, year, country_clean, ore_clean, severity,
                                    has_fatalities, fatality_count, post_gistm,
                                    release_volume_m3, event_date, overlap)],
                by = "event_id", all.x = TRUE)
car_dt <- merge(car_dt, firms[, .(ticker, company, primary_commodity,
                                   has_tailings_dams, is_streaming_royalty)],
                by = "ticker", all.x = TRUE)

# Compute same-commodity indicator
car_dt[, same_commodity := (primary_commodity == ore_clean) | (primary_commodity == "Diversified")]

# Save CARs
fwrite(car_dt, "../data/car_results.csv")

# =============================================================================
# STEP 3: Average CARs (Main Result)
# =============================================================================
cat("\n=== STEP 3: Average CARs ===\n")

# Overall average CAR
avg_car <- car_dt[, .(
  mean_car = mean(car_main, na.rm = TRUE),
  se_car = sd(car_main, na.rm = TRUE) / sqrt(.N),
  median_car = median(car_main, na.rm = TRUE),
  n_obs = .N,
  n_events = uniqueN(event_id),
  n_firms = uniqueN(ticker),
  pct_negative = mean(car_main < 0, na.rm = TRUE)
)]

cat("\n--- Overall Average CAR [-1, +5] ---\n")
cat(sprintf("  Mean CAR: %.4f (%.4f)\n", avg_car$mean_car, avg_car$se_car))
cat(sprintf("  t-stat: %.2f\n", avg_car$mean_car / avg_car$se_car))
cat(sprintf("  Median CAR: %.4f\n", avg_car$median_car))
cat(sprintf("  %% Negative: %.1f%%\n", avg_car$pct_negative * 100))
cat(sprintf("  N: %d obs, %d events, %d firms\n",
            avg_car$n_obs, avg_car$n_events, avg_car$n_firms))

# Pre-event CAR (placebo)
avg_pre <- car_dt[, .(
  mean_car = mean(car_pre, na.rm = TRUE),
  se_car = sd(car_pre, na.rm = TRUE) / sqrt(.N)
)]
cat(sprintf("\n  Pre-event CAR [-5, -2]: %.4f (%.4f), t=%.2f\n",
            avg_pre$mean_car, avg_pre$se_car,
            avg_pre$mean_car / avg_pre$se_car))

# =============================================================================
# STEP 4: Heterogeneity Analysis
# =============================================================================
cat("\n=== STEP 4: Heterogeneity Analysis ===\n")

# 4a. By tailings dam ownership (H1)
cat("\n--- H1: Tailings Dam Ownership ---\n")
h1 <- car_dt[, .(mean_car = mean(car_main, na.rm = TRUE),
                   se = sd(car_main, na.rm = TRUE) / sqrt(.N),
                   n = .N),
              by = has_tailings_dams]
print(h1)

# 4b. By commodity match (H2)
cat("\n--- H2: Same vs Different Commodity ---\n")
h2 <- car_dt[, .(mean_car = mean(car_main, na.rm = TRUE),
                   se = sd(car_main, na.rm = TRUE) / sqrt(.N),
                   n = .N),
              by = same_commodity]
print(h2)

# 4c. By GISTM period (H4)
cat("\n--- H4: Pre vs Post GISTM ---\n")
h4 <- car_dt[, .(mean_car = mean(car_main, na.rm = TRUE),
                   se = sd(car_main, na.rm = TRUE) / sqrt(.N),
                   n = .N),
              by = post_gistm]
print(h4)

# 4d. By severity (H5)
cat("\n--- H5: By Severity ---\n")
h5 <- car_dt[, .(mean_car = mean(car_main, na.rm = TRUE),
                   se = sd(car_main, na.rm = TRUE) / sqrt(.N),
                   n = .N),
              by = severity]
print(h5)

# =============================================================================
# STEP 5: Cross-Sectional Regressions
# =============================================================================
cat("\n=== STEP 5: Cross-Sectional Regressions ===\n")

# Convert to percentages for readability
car_dt[, car_pct := car_main * 100]

# Model 1: Baseline (overall contagion)
m1 <- feols(car_pct ~ 1, data = car_dt, cluster = ~event_id)

# Model 2: Tailings ownership (H1) + commodity match (H2)
m2 <- feols(car_pct ~ has_tailings_dams + same_commodity,
            data = car_dt, cluster = ~event_id)

# Model 3: Add severity (H5)
m3 <- feols(car_pct ~ has_tailings_dams + same_commodity +
              i(severity, ref = "Other"),
            data = car_dt, cluster = ~event_id)

# Model 4: GISTM interaction (H4)
m4 <- feols(car_pct ~ has_tailings_dams * post_gistm +
              same_commodity * post_gistm +
              i(severity, ref = "Other"),
            data = car_dt, cluster = ~event_id)

# Model 5: Full model with streaming/royalty placebo (H3 proxy)
m5 <- feols(car_pct ~ has_tailings_dams * post_gistm +
              same_commodity * post_gistm +
              is_streaming_royalty +
              i(severity, ref = "Other"),
            data = car_dt, cluster = ~event_id)

# Model 6: Event fixed effects (within-event variation only)
m6 <- feols(car_pct ~ has_tailings_dams + same_commodity +
              is_streaming_royalty | event_id,
            data = car_dt)

cat("\n--- Regression Results ---\n")
etable(m1, m2, m3, m4, m5, m6,
       headers = c("Baseline", "H1+H2", "Severity", "GISTM", "Full", "Event FE"),
       se.below = TRUE)

# Save regression results
reg_results <- etable(m1, m2, m3, m4, m5, m6,
                       headers = c("Baseline", "H1+H2", "Severity", "GISTM", "Full", "Event FE"),
                       tex = TRUE)
writeLines(reg_results, "../tables/tab2_main_regressions.tex")

# =============================================================================
# STEP 6: Event-Level Analysis (Average CARs by Event)
# =============================================================================
cat("\n=== STEP 6: Event-Level Analysis ===\n")

event_avg <- car_dt[, .(
  avg_car = mean(car_main, na.rm = TRUE),
  avg_car_pct = mean(car_pct, na.rm = TRUE),
  median_car = median(car_main, na.rm = TRUE),
  n_firms = uniqueN(ticker),
  avg_car_tailings = mean(car_main[has_tailings_dams == TRUE], na.rm = TRUE),
  avg_car_no_tailings = mean(car_main[has_tailings_dams == FALSE], na.rm = TRUE),
  avg_car_same_comm = mean(car_main[same_commodity == TRUE], na.rm = TRUE),
  avg_car_diff_comm = mean(car_main[same_commodity == FALSE], na.rm = TRUE)
), by = .(event_id, year, country_clean, ore_clean, severity,
          has_fatalities, fatality_count, post_gistm)]

fwrite(event_avg, "../data/event_level_cars.csv")

# Event-level regressions
cat("\n--- Event-Level Regressions ---\n")
em1 <- feols(avg_car_pct ~ post_gistm, data = event_avg)
em2 <- feols(avg_car_pct ~ post_gistm + i(severity, ref = "Other"), data = event_avg)
em3 <- feols(avg_car_pct ~ post_gistm + has_fatalities + log1p(fatality_count),
             data = event_avg)
etable(em1, em2, em3, se.below = TRUE)

# =============================================================================
# STEP 7: Day-by-Day Event Study (for figures)
# =============================================================================
cat("\n=== STEP 7: Day-by-Day Abnormal Returns ===\n")

daily_ar <- ar_dt[event_day >= -5 & event_day <= 10,
                   .(mean_ar = mean(ar, na.rm = TRUE),
                     se_ar = sd(ar, na.rm = TRUE) / sqrt(.N),
                     n = .N),
                   by = event_day]
daily_ar[, car := cumsum(mean_ar)]
daily_ar[, car_upper := car + 1.96 * se_ar * sqrt(abs(event_day - min(event_day)) + 1)]
daily_ar[, car_lower := car - 1.96 * se_ar * sqrt(abs(event_day - min(event_day)) + 1)]

fwrite(daily_ar, "../data/daily_ar_overall.csv")

# By tailings ownership
daily_ar_tailings <- ar_dt[event_day >= -5 & event_day <= 10,
                            .(mean_ar = mean(ar, na.rm = TRUE),
                              se_ar = sd(ar, na.rm = TRUE) / sqrt(.N),
                              n = .N),
                            by = .(event_day, has_tailings_dams)]
daily_ar_tailings[, car := cumsum(mean_ar), by = has_tailings_dams]

fwrite(daily_ar_tailings, "../data/daily_ar_by_tailings.csv")

# By GISTM period
daily_ar_gistm <- ar_dt[event_day >= -5 & event_day <= 10,
                         .(mean_ar = mean(ar, na.rm = TRUE),
                           se_ar = sd(ar, na.rm = TRUE) / sqrt(.N),
                           n = .N),
                         by = .(event_day, post_gistm)]
daily_ar_gistm[, car := cumsum(mean_ar), by = post_gistm]

fwrite(daily_ar_gistm, "../data/daily_ar_by_gistm.csv")

# By commodity match
daily_ar_commodity <- ar_dt[event_day >= -5 & event_day <= 10,
                             .(mean_ar = mean(ar, na.rm = TRUE),
                               se_ar = sd(ar, na.rm = TRUE) / sqrt(.N),
                               n = .N),
                             by = .(event_day, same_commodity)]
daily_ar_commodity[, car := cumsum(mean_ar), by = same_commodity]

fwrite(daily_ar_commodity, "../data/daily_ar_by_commodity.csv")

# By severity
daily_ar_severity <- ar_dt[event_day >= -5 & event_day <= 10 & event_severity %in% c("Major", "Fatal", "Other"),
                            .(mean_ar = mean(ar, na.rm = TRUE),
                              se_ar = sd(ar, na.rm = TRUE) / sqrt(.N),
                              n = .N),
                            by = .(event_day, event_severity)]
daily_ar_severity[, car := cumsum(mean_ar), by = event_severity]
setnames(daily_ar_severity, "event_severity", "severity")

fwrite(daily_ar_severity, "../data/daily_ar_by_severity.csv")

# =============================================================================
# STEP 8: Summary Statistics
# =============================================================================
cat("\n=== STEP 8: Summary Statistics ===\n")

# Panel A: Event characteristics
event_sumstats <- events[event_id %in% unique(car_dt$event_id), .(
  N = .N,
  years_min = min(year),
  years_max = max(year),
  pct_fatal = mean(has_fatalities) * 100,
  mean_fatalities = mean(fatality_count[has_fatalities == TRUE]),
  pct_post_gistm = mean(post_gistm) * 100,
  n_countries = uniqueN(country_clean),
  n_ore_types = uniqueN(ore_clean)
)]
cat("Event summary:\n")
print(event_sumstats)

# Panel B: Firm characteristics
firm_sumstats <- firms[ticker %in% unique(car_dt$ticker), .(
  N = .N,
  pct_tailings = mean(has_tailings_dams) * 100,
  pct_streaming = mean(is_streaming_royalty) * 100,
  n_commodities = uniqueN(primary_commodity)
)]
cat("\nFirm summary:\n")
print(firm_sumstats)

# Panel C: CAR distribution
car_sumstats <- car_dt[, .(
  mean_car_short = mean(car_short, na.rm = TRUE) * 100,
  sd_car_short = sd(car_short, na.rm = TRUE) * 100,
  mean_car_main = mean(car_main, na.rm = TRUE) * 100,
  sd_car_main = sd(car_main, na.rm = TRUE) * 100,
  mean_car_long = mean(car_long, na.rm = TRUE) * 100,
  sd_car_long = sd(car_long, na.rm = TRUE) * 100,
  mean_car_pre = mean(car_pre, na.rm = TRUE) * 100,
  sd_car_pre = sd(car_pre, na.rm = TRUE) * 100,
  N = .N
)]
cat("\nCAR summary (%):\n")
print(car_sumstats)

# Save all summary statistics
fwrite(event_sumstats, "../data/sumstats_events.csv")
fwrite(firm_sumstats, "../data/sumstats_firms.csv")
fwrite(car_sumstats, "../data/sumstats_cars.csv")

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
