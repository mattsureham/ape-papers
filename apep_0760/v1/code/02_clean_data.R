# 02_clean_data.R — Construct analysis datasets
# apep_0760: SEC Chair Transitions and Capital Market Integrity

source("00_packages.R")

if (!requireNamespace("quantmod", quietly = TRUE)) {
  install.packages("quantmod", repos = "https://cloud.r-project.org")
}
library(quantmod)

# ============================================================
# 1. Load enforcement data
# ============================================================

enforcement <- read_csv("../data/enforcement_actions.csv", show_col_types = FALSE) %>%
  mutate(date = as.Date(date))

transitions <- read_csv("../data/chair_transitions.csv", show_col_types = FALSE) %>%
  mutate(transition_date = as.Date(transition_date))

tenures <- read_csv("../data/chair_tenures.csv", show_col_types = FALSE) %>%
  mutate(start_date = as.Date(start_date), end_date = as.Date(end_date))

cornerstone <- read_csv("../data/cornerstone_fy_totals.csv", show_col_types = FALSE)

cat("Loaded enforcement data:", nrow(enforcement), "actions\n")

# ============================================================
# 2. Assign Chair tenure to each enforcement action
# ============================================================

assign_chair <- function(d, tenures_df) {
  match <- tenures_df %>%
    filter(d >= start_date & d <= end_date)
  if (nrow(match) > 0) return(match$chair[1])
  return(NA_character_)
}

enforcement <- enforcement %>%
  rowwise() %>%
  mutate(chair = assign_chair(date, tenures)) %>%
  ungroup()

cat("Chair assignment:\n")
print(enforcement %>% count(chair, sort = TRUE))

# ============================================================
# 3. Construct weekly enforcement time series
# ============================================================

# Create a complete daily panel from 2009 to 2026
daily_panel <- tibble(date = seq(as.Date("2009-01-01"), as.Date("2026-03-22"), by = "day")) %>%
  left_join(
    enforcement %>% count(date, name = "n_actions"),
    by = "date"
  ) %>%
  mutate(
    n_actions = replace_na(n_actions, 0L),
    week = floor_date(date, "week"),
    month = floor_date(date, "month"),
    year = year(date),
    fiscal_year = if_else(month(date) >= 10, year(date) + 1L, year(date)),
    wday = wday(date, label = TRUE),
    is_weekday = !(wday %in% c("Sat", "Sun"))
  )

# Assign Chair to daily panel
daily_panel <- daily_panel %>%
  rowwise() %>%
  mutate(chair = assign_chair(date, tenures)) %>%
  ungroup()

# Weekly aggregation (business days only for intensity calculation)
weekly <- daily_panel %>%
  group_by(week) %>%
  summarize(
    n_actions = sum(n_actions),
    n_weekdays = sum(is_weekday),
    daily_rate = n_actions / pmax(n_weekdays, 1),
    chair = if (all(is.na(chair))) NA_character_ else first(na.omit(chair)),
    .groups = "drop"
  ) %>%
  filter(week >= as.Date("2009-01-01") & week <= as.Date("2026-03-22"))

# Monthly aggregation
monthly <- daily_panel %>%
  group_by(month) %>%
  summarize(
    n_actions = sum(n_actions),
    n_weekdays = sum(is_weekday),
    daily_rate = n_actions / pmax(n_weekdays, 1),
    chair = if (all(is.na(chair))) NA_character_ else first(na.omit(chair)),
    fiscal_year = first(fiscal_year),
    .groups = "drop"
  )

cat("Weekly panel:", nrow(weekly), "weeks\n")
cat("Monthly panel:", nrow(monthly), "months\n")

# ============================================================
# 4. Construct event study dataset
# ============================================================

# For each transition, create centered time variables
event_study_weekly <- map_dfr(1:nrow(transitions), function(i) {
  t_date <- transitions$transition_date[i]
  t_id <- transitions$transition_id[i]
  t_type <- transitions$transition_type[i]

  weekly %>%
    mutate(
      transition_id = t_id,
      transition_type = t_type,
      cross_party = (t_type == "cross_party"),
      days_from_transition = as.numeric(week - t_date),
      weeks_from_transition = round(days_from_transition / 7)
    ) %>%
    filter(abs(weeks_from_transition) <= 26)  # ±6 months
})

event_study_monthly <- map_dfr(1:nrow(transitions), function(i) {
  t_date <- transitions$transition_date[i]
  t_id <- transitions$transition_id[i]
  t_type <- transitions$transition_type[i]

  monthly %>%
    mutate(
      transition_id = t_id,
      transition_type = t_type,
      cross_party = (t_type == "cross_party"),
      months_from_transition = round(as.numeric(month - t_date) / 30.44)
    ) %>%
    filter(abs(months_from_transition) <= 12)  # ±12 months
})

cat("Event study (weekly):", nrow(event_study_weekly), "obs across",
    n_distinct(event_study_weekly$transition_id), "transitions\n")

# ============================================================
# 5. Fetch stock market data from Yahoo Finance
# ============================================================

cat("\n--- Fetching stock market data from Yahoo Finance ---\n")

fetch_yahoo <- function(symbol, from = "2009-01-01", to = "2026-03-22") {
  tryCatch({
    getSymbols(symbol, src = "yahoo", from = from, to = to, auto.assign = FALSE)
  }, error = function(e) {
    cat("Failed to fetch", symbol, ":", conditionMessage(e), "\n")
    NULL
  })
}

# Fetch S&P 500, VIX, Financial Sector ETF, broad market ETF
sp500 <- fetch_yahoo("^GSPC")
vix   <- fetch_yahoo("^VIX")
xlf   <- fetch_yahoo("XLF")
spy   <- fetch_yahoo("SPY")

# Construct daily stock market panel
if (!is.null(sp500) && !is.null(vix)) {
  market_daily <- tibble(
    date = as.Date(index(sp500)),
    sp500_close = as.numeric(Cl(sp500)),
    sp500_return = c(NA, diff(log(as.numeric(Cl(sp500)))))
  )

  if (!is.null(vix)) {
    vix_df <- tibble(
      date = as.Date(index(vix)),
      vix_close = as.numeric(Cl(vix))
    )
    market_daily <- market_daily %>% left_join(vix_df, by = "date")
  }

  if (!is.null(xlf) && !is.null(spy)) {
    xlf_df <- tibble(
      date = as.Date(index(xlf)),
      xlf_return = c(NA, diff(log(as.numeric(Cl(xlf)))))
    )
    spy_df <- tibble(
      date = as.Date(index(spy)),
      spy_return = c(NA, diff(log(as.numeric(Cl(spy)))))
    )
    market_daily <- market_daily %>%
      left_join(xlf_df, by = "date") %>%
      left_join(spy_df, by = "date") %>%
      mutate(
        fin_excess_return = xlf_return - spy_return  # Financial sector excess return
      )
  }

  cat("Market data:", nrow(market_daily), "trading days\n")
  cat("Date range:", as.character(min(market_daily$date)),
      "to", as.character(max(market_daily$date)), "\n")

  # Create market event study dataset
  market_event_study <- map_dfr(1:nrow(transitions), function(i) {
    t_date <- transitions$transition_date[i]
    t_id <- transitions$transition_id[i]
    t_type <- transitions$transition_type[i]

    market_daily %>%
      mutate(
        transition_id = t_id,
        transition_type = t_type,
        cross_party = (t_type == "cross_party"),
        days_from_transition = as.numeric(date - t_date)
      ) %>%
      filter(abs(days_from_transition) <= 60)  # ±60 trading days
  })

  cat("Market event study:", nrow(market_event_study), "obs\n")
} else {
  stop("FATAL: Could not fetch stock market data from Yahoo Finance.")
}

# ============================================================
# 6. Construct Cornerstone-based enforcement panel
# ============================================================

# Use Cornerstone FY totals to construct implied monthly rates
# FY runs Oct 1 to Sep 30
cornerstone_monthly <- cornerstone %>%
  filter(!is.na(total_actions)) %>%
  mutate(
    monthly_total = total_actions / 12,
    monthly_standalone = standalone_actions / 12
  ) %>%
  # Expand each FY to 12 months
  rowwise() %>%
  do({
    fy <- .
    tibble(
      month = seq(as.Date(paste0(fy$fiscal_year - 1, "-10-01")),
                  as.Date(paste0(fy$fiscal_year, "-09-01")),
                  by = "month"),
      fiscal_year = fy$fiscal_year,
      implied_monthly_total = fy$monthly_total,
      implied_monthly_standalone = fy$monthly_standalone,
      fy_total_actions = fy$total_actions,
      fy_standalone_actions = fy$standalone_actions
    )
  }) %>%
  ungroup()

# Assign Chair to Cornerstone monthly panel
cornerstone_monthly <- cornerstone_monthly %>%
  rowwise() %>%
  mutate(chair = assign_chair(month, tenures)) %>%
  ungroup()

cat("Cornerstone monthly panel:", nrow(cornerstone_monthly), "months\n")

# ============================================================
# 7. Save analysis datasets
# ============================================================

write_csv(daily_panel, "../data/daily_panel.csv")
write_csv(weekly, "../data/weekly_panel.csv")
write_csv(monthly, "../data/monthly_panel.csv")
write_csv(event_study_weekly, "../data/event_study_weekly.csv")
write_csv(event_study_monthly, "../data/event_study_monthly.csv")
write_csv(market_daily, "../data/market_daily.csv")
write_csv(market_event_study, "../data/market_event_study.csv")
write_csv(cornerstone_monthly, "../data/cornerstone_monthly.csv")

cat("\n=== Analysis datasets saved ===\n")
cat("  daily_panel.csv:", nrow(daily_panel), "rows\n")
cat("  weekly_panel.csv:", nrow(weekly), "rows\n")
cat("  monthly_panel.csv:", nrow(monthly), "rows\n")
cat("  market_daily.csv:", nrow(market_daily), "rows\n")
cat("  market_event_study.csv:", nrow(market_event_study), "rows\n")
cat("  cornerstone_monthly.csv:", nrow(cornerstone_monthly), "rows\n")
