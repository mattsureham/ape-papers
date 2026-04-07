# =============================================================================
# 01_fetch_data.R — Fetch QWI race microdata from Census API + PFL dates
# =============================================================================

source("00_packages.R")

CENSUS_API_KEY <- Sys.getenv("CENSUS_API_KEY", "")
stopifnot("CENSUS_API_KEY required" = nchar(CENSUS_API_KEY) > 0)

# --- PFL adoption dates (hand-coded from NCSL) ---
pfl_states <- tibble(
  state_fips = c("06", "34", "53", "44", "36", "11", "25", "09"),
  state_name = c("California", "New Jersey", "Washington", "Rhode Island",
                 "New York", "DC", "Massachusetts", "Connecticut"),
  state_abbr = c("CA", "NJ", "WA", "RI", "NY", "DC", "MA", "CT"),
  pfl_year   = c(2004, 2009, 2020, 2014, 2018, 2020, 2021, 2022),
  pfl_quarter = c(3, 2, 1, 1, 1, 3, 1, 1),
  benefit_rate = c(0.55, 0.67, 0.90, 0.60, 0.67, 0.90, 0.80, 0.75),
  max_weeks  = c(6, 6, 12, 4, 12, 8, 12, 12),
  job_protection = c(FALSE, FALSE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE)
)

saveRDS(pfl_states, "../data/pfl_states.rds")

# --- Fetch QWI race data ---
# QWI rh endpoint: race by Hispanic origin
# Get all quarters at once per state using time range

fetch_qwi_state <- function(state_fips, race_code) {
  base_url <- "https://api.census.gov/data/timeseries/qwi/rh"

  # Fetch all available quarters at once
  url <- sprintf(
    "%s?get=HirA,Emp,EarnS,Sep&for=state:%s&time=from+2000-Q1+to+2024-Q2&race=%s&ethnicity=A0&ownercode=A05&seasonadj=U&industry=00&key=%s",
    base_url, state_fips, race_code, CENSUS_API_KEY
  )

  resp <- httr::GET(url, httr::timeout(60))
  status <- httr::status_code(resp)

  if (status == 204 || status == 400) return(NULL)
  if (status != 200) {
    warning(sprintf("State %s race %s: HTTP %d", state_fips, race_code, status))
    return(NULL)
  }

  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(content)

  if (is.null(parsed) || nrow(parsed) <= 1) return(NULL)

  df <- as.data.frame(parsed[-1, , drop = FALSE], stringsAsFactors = FALSE)
  names(df) <- parsed[1, ]

  df <- df %>%
    mutate(
      across(c(HirA, Emp, EarnS, Sep), ~as.numeric(.)),
      state_fips = state,
      race_code = race,
      year = as.integer(sub("-Q.*", "", time)),
      quarter = as.integer(sub(".*-Q", "", time))
    ) %>%
    select(state_fips, race_code, year, quarter, HirA, Emp, EarnS, Sep)

  return(df)
}

# All state FIPS
all_states <- c(sprintf("%02d", c(1:2, 4:6, 8:13, 15:42, 44:51, 53:56)))

cat("Fetching QWI race data for", length(all_states), "states × 2 races...\n")

all_data <- list()
for (i in seq_along(all_states)) {
  st <- all_states[i]
  for (race in c("A1", "A2")) {
    df <- fetch_qwi_state(st, race)
    if (!is.null(df) && nrow(df) > 0) {
      all_data[[paste0(st, "_", race)]] <- df
    }
    Sys.sleep(0.3)
  }
  if (i %% 10 == 0) cat(sprintf("  %d/%d states done\n", i, length(all_states)))
}

qwi_raw <- bind_rows(all_data)
cat("\nTotal QWI rows fetched:", nrow(qwi_raw), "\n")
cat("States:", n_distinct(qwi_raw$state_fips), "\n")
cat("Year range:", min(qwi_raw$year), "-", max(qwi_raw$year), "\n")

stopifnot("QWI data must not be empty" = nrow(qwi_raw) > 0)
stopifnot("Must have both races" = all(c("A1", "A2") %in% qwi_raw$race_code))

saveRDS(qwi_raw, "../data/qwi_raw.rds")
cat("Data fetch complete.\n")
