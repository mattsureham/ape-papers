## 01_fetch_data.R — Data acquisition for The Deterrence Dividend (apep_0984)
## Sources: Yahoo Finance (palladium), NCSL (law dates), Google Trends (theft proxy)

source("00_packages.R")
set.seed(20260326)

cat("=== FETCHING DATA ===\n\n")

# -----------------------------------------------------------------------
# 1. PALLADIUM PRICES (Yahoo Finance)
# -----------------------------------------------------------------------
cat("1. Fetching palladium futures prices...\n")

getSymbols("PA=F", src = "yahoo", from = "2016-01-01", to = "2025-12-31",
           auto.assign = TRUE)
palladium_raw <- `PA=F`
palladium <- data.frame(
  date = index(palladium_raw),
  price_close = as.numeric(Cl(palladium_raw))
) %>%
  filter(!is.na(price_close)) %>%
  mutate(
    year  = year(date),
    month = month(date),
    quarter = quarter(date),
    yq = paste0(year, "Q", quarter),
    log_price = log(price_close)
  )

# Quarterly averages
palladium_q <- palladium %>%
  group_by(year, quarter, yq) %>%
  summarise(
    palladium_price = mean(price_close, na.rm = TRUE),
    log_palladium   = mean(log_price, na.rm = TRUE),
    .groups = "drop"
  )

cat(sprintf("  Palladium: %d daily obs, %d quarters\n",
            nrow(palladium), nrow(palladium_q)))
cat(sprintf("  Peak: $%.0f (%s), Trough: $%.0f (%s)\n",
            max(palladium$price_close), palladium$date[which.max(palladium$price_close)],
            min(palladium$price_close[palladium$date >= "2020-01-01"]),
            palladium$date[palladium$date >= "2020-01-01"][
              which.min(palladium$price_close[palladium$date >= "2020-01-01"])]))

saveRDS(palladium_q, "../data/palladium_quarterly.rds")
cat("  Saved palladium_quarterly.rds\n\n")

# -----------------------------------------------------------------------
# 2. STATE LAW ADOPTION DATES (NCSL compilation)
# -----------------------------------------------------------------------
cat("2. Compiling state catalytic converter anti-theft law dates...\n")

# Effective dates compiled from NCSL Catalytic Converter Theft Prevention
# Legislation tracker and individual state legislative records.
# Format: state FIPS, state abbreviation, effective date, law type
law_dates <- tribble(
  ~state_fips, ~state_abbr, ~effective_date, ~law_type,
  # 2021
  48, "TX", "2021-09-01", "felony_penalty",
  # 2022
  08, "CO", "2022-03-01", "dealer_regulation",
  53, "WA", "2022-06-09", "dealer_regulation",
  54, "WV", "2022-06-10", "dealer_regulation",
  18, "IN", "2022-07-01", "enhanced_penalty",
  28, "MS", "2022-07-01", "enhanced_penalty",
  47, "TN", "2022-07-01", "dealer_regulation",
  04, "AZ", "2022-07-06", "dealer_regulation",
  21, "KY", "2022-07-14", "enhanced_penalty",
  34, "NJ", "2022-08-01", "dealer_regulation",
  29, "MO", "2022-08-28", "enhanced_penalty",
  40, "OK", "2022-11-01", "enhanced_penalty",
  37, "NC", "2022-12-01", "dealer_regulation",
  55, "WI", "2022-03-30", "dealer_regulation",
  # 2023
  17, "IL", "2023-01-01", "dealer_regulation",
  45, "SC", "2023-05-18", "enhanced_penalty",
  49, "UT", "2023-05-03", "dealer_regulation",
  01, "AL", "2023-08-01", "enhanced_penalty",
  05, "AR", "2023-08-01", "enhanced_penalty",
  12, "FL", "2023-07-01", "enhanced_penalty",
  13, "GA", "2023-07-01", "dealer_regulation",
  15, "HI", "2023-07-01", "enhanced_penalty",
  19, "IA", "2023-07-01", "dealer_regulation",
  20, "KS", "2023-07-01", "enhanced_penalty",
  22, "LA", "2023-08-01", "dealer_regulation",
  24, "MD", "2023-10-01", "dealer_regulation",
  27, "MN", "2023-08-01", "dealer_regulation",
  31, "NE", "2023-09-02", "dealer_regulation",
  32, "NV", "2023-10-01", "dealer_regulation",
  35, "NM", "2023-07-01", "enhanced_penalty",
  51, "VA", "2023-07-01", "dealer_regulation",
  09, "CT", "2023-10-01", "dealer_regulation",
  # 2024
  06, "CA", "2024-01-01", "dealer_regulation",
  41, "OR", "2024-01-01", "dealer_regulation"
) %>%
  mutate(
    effective_date = as.Date(effective_date),
    effective_year = year(effective_date),
    effective_quarter = quarter(effective_date),
    first_treat_yq = paste0(effective_year, "Q", effective_quarter),
    # Numeric quarter for Callaway-Sant'Anna
    first_treat_num = (effective_year - 2016) * 4 + effective_quarter
  )

cat(sprintf("  %d states with anti-theft laws compiled\n", nrow(law_dates)))
cat(sprintf("  Earliest: %s (%s), Latest: %s (%s)\n",
            law_dates$state_abbr[which.min(law_dates$effective_date)],
            min(law_dates$effective_date),
            law_dates$state_abbr[which.max(law_dates$effective_date)],
            max(law_dates$effective_date)))

# All 50 states + DC
all_states <- data.frame(
  state_fips = c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,
                 24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,
                 42,44,45,46,47,48,49,50,51,53,54,55,56),
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
                  "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
                  "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                  "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
                  "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
)

saveRDS(law_dates, "../data/law_dates.rds")
saveRDS(all_states, "../data/all_states.rds")
cat("  Saved law_dates.rds, all_states.rds\n\n")

# -----------------------------------------------------------------------
# 3. GOOGLE TRENDS: "catalytic converter theft" by state
# -----------------------------------------------------------------------
cat("3. Fetching Google Trends data by state...\n")
cat("   Using state-level queries as revealed community concern proxy\n")

# Query each state individually (0-100 scale, normalized within-state)
# State FEs in the regression absorb cross-state scale differences
gtrends_results <- list()
batch_size <- 5
state_geos <- paste0("US-", all_states$state_abbr)

for (i in seq_along(state_geos)) {
  geo_code <- state_geos[i]
  state_ab <- all_states$state_abbr[i]

  cat(sprintf("  [%02d/%d] Fetching %s...", i, length(state_geos), state_ab))

  tryCatch({
    res <- gtrends(
      keyword = "catalytic converter theft",
      geo = geo_code,
      time = "2017-01-01 2025-12-31",
      gprop = "web",
      low_search_volume = TRUE
    )

    if (!is.null(res$interest_over_time) && nrow(res$interest_over_time) > 0) {
      df <- res$interest_over_time %>%
        mutate(
          hits = as.numeric(ifelse(hits == "<1", "0.5", hits)),
          state_abbr = state_ab,
          date = as.Date(date)
        ) %>%
        select(date, hits, state_abbr)
      gtrends_results[[state_ab]] <- df
      cat(sprintf(" %d obs, max=%s\n", nrow(df), max(df$hits, na.rm = TRUE)))
    } else {
      cat(" NO DATA\n")
    }
  }, error = function(e) {
    cat(sprintf(" ERROR: %s\n", e$message))
  })

  # Rate limiting: pause every batch_size queries
  if (i %% batch_size == 0 && i < length(state_geos)) {
    cat("  [pause 15s for rate limit]\n")
    Sys.sleep(15)
  } else {
    Sys.sleep(3)
  }
}

gtrends_df <- bind_rows(gtrends_results)

if (nrow(gtrends_df) == 0) {
  stop("FATAL: Google Trends returned no data for any state. Cannot proceed.")
}

# Aggregate to quarterly
gtrends_quarterly <- gtrends_df %>%
  mutate(
    year = year(date),
    quarter = quarter(date),
    yq = paste0(year, "Q", quarter)
  ) %>%
  group_by(state_abbr, year, quarter, yq) %>%
  summarise(
    search_index = mean(hits, na.rm = TRUE),
    n_months = n(),
    .groups = "drop"
  )

cat(sprintf("\nGoogle Trends: %d state-quarter observations across %d states\n",
            nrow(gtrends_quarterly), n_distinct(gtrends_quarterly$state_abbr)))

saveRDS(gtrends_df, "../data/gtrends_monthly.rds")
saveRDS(gtrends_quarterly, "../data/gtrends_quarterly.rds")
cat("Saved gtrends_monthly.rds, gtrends_quarterly.rds\n\n")

# -----------------------------------------------------------------------
# 4. STATE CONTROLS: Unemployment rate from FRED
# -----------------------------------------------------------------------
cat("4. Fetching state unemployment rates from FRED...\n")

fred_key <- Sys.getenv("FRED_API_KEY")
if (nchar(fred_key) == 0) {
  cat("  WARNING: No FRED_API_KEY. Skipping state controls.\n")
  state_unemp <- NULL
} else {
  # FRED series: {STATE}UR for unemployment rate
  unemp_list <- list()
  for (st in all_states$state_abbr) {
    series_id <- paste0(st, "UR")
    url <- sprintf(
      "https://api.stlouisfed.org/fred/series/observations?series_id=%s&api_key=%s&file_type=json&observation_start=2016-01-01&observation_end=2025-12-31",
      series_id, fred_key
    )
    tryCatch({
      resp <- GET(url)
      if (status_code(resp) == 200) {
        obs <- content(resp, as = "parsed")$observations
        if (length(obs) > 0) {
          df <- bind_rows(lapply(obs, function(x) {
            data.frame(date = as.Date(x$date),
                       unemp_rate = as.numeric(x$value),
                       stringsAsFactors = FALSE)
          })) %>%
            filter(!is.na(unemp_rate)) %>%
            mutate(state_abbr = st,
                   year = year(date),
                   quarter = quarter(date))
          unemp_list[[st]] <- df
        }
      }
    }, error = function(e) NULL)

    if (which(all_states$state_abbr == st) %% 10 == 0) {
      Sys.sleep(1)
    }
  }

  if (length(unemp_list) > 0) {
    state_unemp <- bind_rows(unemp_list) %>%
      group_by(state_abbr, year, quarter) %>%
      summarise(unemp_rate = mean(unemp_rate, na.rm = TRUE), .groups = "drop")
    saveRDS(state_unemp, "../data/state_unemployment.rds")
    cat(sprintf("  %d state-quarter unemployment observations\n", nrow(state_unemp)))
  } else {
    state_unemp <- NULL
    cat("  WARNING: Could not fetch unemployment data\n")
  }
}

cat("\n=== DATA FETCH COMPLETE ===\n")
cat(sprintf("Files saved in data/:\n"))
cat(sprintf("  palladium_quarterly.rds : %d obs\n", nrow(palladium_q)))
cat(sprintf("  law_dates.rds           : %d states\n", nrow(law_dates)))
cat(sprintf("  gtrends_quarterly.rds   : %d obs\n", nrow(gtrends_quarterly)))
if (!is.null(state_unemp)) {
  cat(sprintf("  state_unemployment.rds  : %d obs\n", nrow(state_unemp)))
}
