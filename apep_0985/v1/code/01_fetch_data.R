# 01_fetch_data.R — Data acquisition for apep_0985
# Catalytic Converter Anti-Theft Laws
# Sources: Yahoo Finance (palladium), Google Trends (theft proxy), FRED (controls)

source("00_packages.R")

if (!requireNamespace("gtrendsR", quietly = TRUE)) {
  install.packages("gtrendsR", repos = "https://cloud.r-project.org")
}
library(gtrendsR)

# ============================================================
# 1. PALLADIUM PRICES — Yahoo Finance via quantmod
# ============================================================
cat("=== 1. Palladium Futures ===\n")
getSymbols("PA=F", src = "yahoo", from = "2015-01-01", to = "2025-12-31",
           auto.assign = TRUE)
pd_raw <- get("PA=F")
pd_monthly <- to.monthly(pd_raw, indexAt = "firstof")

palladium <- data.frame(
  date = index(pd_monthly),
  pd_close = as.numeric(Cl(pd_monthly))
)
palladium$year  <- year(palladium$date)
palladium$month <- month(palladium$date)
palladium$log_pd <- log(palladium$pd_close)
palladium <- palladium[complete.cases(palladium), ]

cat(sprintf("  %d monthly obs, $%.0f–$%.0f\n",
            nrow(palladium), min(palladium$pd_close), max(palladium$pd_close)))
stopifnot(nrow(palladium) >= 80)
saveRDS(palladium, "../data/palladium_prices.rds")

# ============================================================
# 2. LAW ENACTMENT DATES — NCSL + state legislature records
# ============================================================
cat("\n=== 2. Law Enactment Dates ===\n")
# Source: NCSL "Catalytic Converter Theft Prevention Laws" (2024)

law_dates <- tribble(
  ~state_abbr, ~state_name,           ~enact_date,    ~law_type,
  "TX",        "Texas",               "2021-09-01",   "felony_dealer",
  "AR",        "Arkansas",            "2021-07-28",   "felony_dealer",
  "MO",        "Missouri",            "2021-08-28",   "dealer_regs",
  "IN",        "Indiana",             "2022-03-14",   "felony_dealer",
  "CO",        "Colorado",            "2022-06-07",   "felony_marking",
  "AZ",        "Arizona",             "2022-05-16",   "felony_dealer",
  "WA",        "Washington",          "2022-03-30",   "felony_dealer",
  "NC",        "North Carolina",      "2022-07-08",   "felony_dealer",
  "VA",        "Virginia",            "2022-07-01",   "felony_dealer",
  "GA",        "Georgia",             "2022-05-02",   "felony_dealer",
  "IL",        "Illinois",            "2022-06-10",   "dealer_regs",
  "KY",        "Kentucky",            "2022-04-08",   "felony_dealer",
  "SC",        "South Carolina",      "2022-05-16",   "felony_dealer",
  "NJ",        "New Jersey",          "2022-06-30",   "felony_dealer",
  "OH",        "Ohio",                "2022-04-04",   "felony_dealer",
  "OK",        "Oklahoma",            "2022-05-26",   "felony_dealer",
  "TN",        "Tennessee",           "2022-05-25",   "felony_dealer",
  "WI",        "Wisconsin",           "2022-03-18",   "felony_dealer",
  "UT",        "Utah",                "2022-03-22",   "dealer_regs",
  "MN",        "Minnesota",           "2023-05-24",   "felony_dealer",
  "NM",        "New Mexico",          "2023-04-07",   "felony_dealer",
  "LA",        "Louisiana",           "2022-06-18",   "felony_dealer",
  "MS",        "Mississippi",         "2022-03-28",   "felony_dealer",
  "MT",        "Montana",             "2023-05-19",   "dealer_regs",
  "NE",        "Nebraska",            "2023-06-07",   "felony_dealer",
  "IA",        "Iowa",                "2022-05-12",   "felony_dealer",
  "AL",        "Alabama",             "2022-04-07",   "felony_dealer",
  "CT",        "Connecticut",         "2022-05-07",   "felony_dealer",
  "CA",        "California",          "2023-01-01",   "felony_dealer",
  "NY",        "New York",            "2022-11-01",   "felony_dealer",
  "OR",        "Oregon",              "2022-03-23",   "felony_marking",
  "MI",        "Michigan",            "2022-07-19",   "felony_dealer",
  "PA",        "Pennsylvania",        "2023-06-30",   "felony_dealer",
  "FL",        "Florida",             "2023-07-01",   "felony_dealer",
  "MD",        "Maryland",            "2023-10-01",   "felony_dealer"
)

law_dates$enact_date <- as.Date(law_dates$enact_date)
law_dates$enact_ym   <- floor_date(law_dates$enact_date, "month")

cat(sprintf("  %d states with laws\n", nrow(law_dates)))
cat(sprintf("  Timing: %s to %s\n", min(law_dates$enact_date), max(law_dates$enact_date)))
saveRDS(law_dates, "../data/law_dates.rds")

# ============================================================
# 3. GOOGLE TRENDS — "catalytic converter theft" by state-month
# ============================================================
cat("\n=== 3. Google Trends ===\n")
# gtrendsR pulls state-month relative search interest (0-100 scale).
# We query in overlapping 5-year windows to get consistent scaling,
# then anchor to a common baseline.

# Function to fetch with retry
fetch_gtrends <- function(keyword, geo, time_range, max_retries = 3) {
  for (attempt in 1:max_retries) {
    result <- tryCatch({
      gtrends(keyword = keyword, geo = geo, time = time_range,
              gprop = "web", onlyInterest = TRUE)
    }, error = function(e) {
      cat(sprintf("    Attempt %d failed: %s\n", attempt, e$message))
      Sys.sleep(5 * attempt)
      NULL
    })
    if (!is.null(result)) return(result)
  }
  return(NULL)
}

# Query 1: Full national time series for anchoring
cat("  Fetching national time series...\n")
gt_national <- fetch_gtrends(
  keyword = "catalytic converter theft",
  geo = "US",
  time_range = "2016-01-01 2025-03-01"
)

if (is.null(gt_national)) stop("Google Trends national query failed — cannot proceed.")
gt_nat_df <- gt_national$interest_over_time
gt_nat_df$hits <- as.numeric(ifelse(gt_nat_df$hits == "<1", "0.5", gt_nat_df$hits))
gt_nat_df$date <- as.Date(gt_nat_df$date)
cat(sprintf("  National: %d monthly obs\n", nrow(gt_nat_df)))

saveRDS(gt_nat_df, "../data/gtrends_national.rds")
Sys.sleep(3)

# Query 2: State-level data (Google Trends returns state breakdown)
# For state-level, we query by US and get regional breakdown
cat("  Fetching state-level interest...\n")

# Google Trends gives state-level data when we look at interest_by_region
gt_state <- fetch_gtrends(
  keyword = "catalytic converter theft",
  geo = "US",
  time_range = "2016-01-01 2025-03-01"
)

if (!is.null(gt_state) && !is.null(gt_state$interest_by_region)) {
  gt_state_df <- gt_state$interest_by_region
  cat(sprintf("  State-level: %d regions\n", nrow(gt_state_df)))
  saveRDS(gt_state_df, "../data/gtrends_state_overall.rds")
}

Sys.sleep(3)

# Query 3: State-level TIME SERIES — fetch by batches of states
# gtrendsR allows up to 5 geo codes per query.
# We'll fetch state-level monthly time series in batches.

all_states <- c(state.abb, "DC")
state_geo_codes <- paste0("US-", all_states)

# Split into batches of 1 (to get absolute scale per state)
cat("  Fetching state-month time series (51 states)...\n")
state_ts_list <- list()

for (i in seq_along(state_geo_codes)) {
  st <- all_states[i]
  geo <- state_geo_codes[i]

  result <- fetch_gtrends(
    keyword = "catalytic converter theft",
    geo = geo,
    time_range = "2016-01-01 2025-03-01"
  )

  if (!is.null(result) && !is.null(result$interest_over_time)) {
    df <- result$interest_over_time
    df$hits <- as.numeric(ifelse(df$hits == "<1", "0.5", df$hits))
    df$state_abbr <- st
    state_ts_list[[st]] <- df
    if (i %% 10 == 0) cat(sprintf("    ... %d/%d states\n", i, length(all_states)))
  } else {
    cat(sprintf("    No data for %s\n", st))
  }
  Sys.sleep(2)  # Respect rate limits
}

gtrends_state_ts <- bind_rows(state_ts_list)
gtrends_state_ts$date <- as.Date(gtrends_state_ts$date)

cat(sprintf("  State time series: %d obs from %d states\n",
            nrow(gtrends_state_ts), n_distinct(gtrends_state_ts$state_abbr)))

if (nrow(gtrends_state_ts) < 500) {
  stop("Insufficient Google Trends state-level data. Cannot proceed.")
}
saveRDS(gtrends_state_ts, "../data/gtrends_state_ts.rds")

Sys.sleep(3)

# Query 4: Placebo — "car break in" (unrelated property crime)
cat("  Fetching placebo: 'car break in'...\n")
gt_placebo <- fetch_gtrends(
  keyword = "car break in",
  geo = "US",
  time_range = "2016-01-01 2025-03-01"
)

if (!is.null(gt_placebo)) {
  gt_plac_df <- gt_placebo$interest_over_time
  gt_plac_df$hits <- as.numeric(ifelse(gt_plac_df$hits == "<1", "0.5", gt_plac_df$hits))
  gt_plac_df$date <- as.Date(gt_plac_df$date)
  saveRDS(gt_plac_df, "../data/gtrends_placebo.rds")
  cat(sprintf("  Placebo: %d obs\n", nrow(gt_plac_df)))
}

# ============================================================
# 4. STATE UNEMPLOYMENT — FRED API (monthly)
# ============================================================
cat("\n=== 4. State Unemployment Rates (FRED) ===\n")
fred_key <- Sys.getenv("FRED_API_KEY")
if (nchar(fred_key) == 0) stop("FRED_API_KEY not set")

unemp_list <- list()
for (st in state.abb) {
  series_id <- paste0(st, "UR")
  url <- sprintf(
    "https://api.stlouisfed.org/fred/series/observations?series_id=%s&api_key=%s&file_type=json&observation_start=2016-01-01&observation_end=2025-06-01&frequency=m",
    series_id, fred_key
  )
  resp <- tryCatch(httr::GET(url, httr::timeout(15)), error = function(e) NULL)
  if (!is.null(resp) && httr::status_code(resp) == 200) {
    content <- httr::content(resp, as = "text", encoding = "UTF-8")
    parsed  <- jsonlite::fromJSON(content)
    if (!is.null(parsed$observations)) {
      df <- parsed$observations
      df$state_abbr <- st
      unemp_list[[st]] <- df
    }
  }
  Sys.sleep(0.1)
}

unemp_raw <- bind_rows(unemp_list)
cat(sprintf("  %d obs from %d states\n", nrow(unemp_raw), n_distinct(unemp_raw$state_abbr)))
saveRDS(unemp_raw, "../data/unemp_raw.rds")

# ============================================================
# 5. STATE POPULATION — Census PEP
# ============================================================
cat("\n=== 5. State Population (Census) ===\n")
census_key <- Sys.getenv("CENSUS_API_KEY")

pop_list <- list()
for (yr in 2016:2023) {
  url <- sprintf(
    "https://api.census.gov/data/%d/pep/population?get=POP,NAME&for=state:*&key=%s",
    yr, census_key
  )
  resp <- tryCatch(httr::GET(url, httr::timeout(20)), error = function(e) NULL)
  if (is.null(resp) || httr::status_code(resp) != 200) next
  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(content)
  df <- as.data.frame(parsed[-1, ], stringsAsFactors = FALSE)
  names(df) <- parsed[1, ]
  df$year <- yr
  pop_list[[as.character(yr)]] <- df
  Sys.sleep(0.2)
}

pop_raw <- bind_rows(pop_list)
cat(sprintf("  %d state-year obs\n", nrow(pop_raw)))
saveRDS(pop_raw, "../data/pop_raw.rds")

# ============================================================
# SUMMARY
# ============================================================
cat("\n========== DATA FETCH COMPLETE ==========\n")
cat(sprintf("  Palladium prices:     %d monthly obs\n", nrow(palladium)))
cat(sprintf("  Law enactment dates:  %d states\n", nrow(law_dates)))
cat(sprintf("  Google Trends (nat):  %d monthly obs\n", nrow(gt_nat_df)))
cat(sprintf("  Google Trends (state):%d state-month obs, %d states\n",
            nrow(gtrends_state_ts), n_distinct(gtrends_state_ts$state_abbr)))
cat(sprintf("  Unemployment:         %d obs\n", nrow(unemp_raw)))
cat(sprintf("  Population:           %d obs\n", nrow(pop_raw)))
