## 01_fetch_data.R — Fetch FRED LAUS and Census ACS data
## apep_0662: Clean Slate Laws and Statistical Discrimination
## REAL DATA ONLY — no simulation, no silent fallbacks

source("00_packages.R")

cat("=== Fetching Data via FRED API ===\n")

# --- Load FRED API key ---
fred_key <- Sys.getenv("FRED_API_KEY", "")
if (nchar(fred_key) == 0) {
  env_files <- c("../../../../.env", "../../../.env", "../../.env")
  for (ef in env_files) {
    if (file.exists(ef)) {
      env_lines <- readLines(ef, warn = FALSE)
      line <- grep("^(export )?FRED_API_KEY=", env_lines, value = TRUE)
      if (length(line) > 0) {
        fred_key <- gsub("^(export )?FRED_API_KEY=", "", line[1])
        fred_key <- gsub("[\"']", "", fred_key)
        break
      }
    }
  }
}
stopifnot("FRED_API_KEY not found" = nchar(fred_key) > 0)

# --- State FIPS codes and abbreviations ---
state_info <- tibble(
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
                 "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
                 "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
                 "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
                 "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY","DC"),
  fips = c("01","02","04","05","06","08","09","10","12","13",
           "15","16","17","18","19","20","21","22","23","24",
           "25","26","27","28","29","30","31","32","33","34",
           "35","36","37","38","39","40","41","42","44","45",
           "46","47","48","49","50","51","53","54","55","56","11")
)

# --- Clean slate treatment assignment ---
clean_slate_states <- tribble(
  ~state_abbr, ~enact_year, ~implement_date,
  "PA",  2018, "2019-06-28",
  "UT",  2019, "2022-02-01",
  "NJ",  2019, "2020-06-15",
  "CA",  2019, "2023-01-01",
  "MI",  2020, "2023-04-11",
  "CT",  2021, "2023-01-01",
  "DE",  2021, "2024-08-01",
  "VA",  2021, "2026-07-01",
  "OK",  2022, "2025-01-01",
  "CO",  2022, "2025-07-01",
  "MN",  2023, "2025-01-01",
  "NY",  2023, "2027-11-01"
)

state_fips <- state_info %>%
  left_join(clean_slate_states, by = "state_abbr") %>%
  mutate(
    first_treat = ifelse(is.na(enact_year), 0, enact_year),
    treated = ifelse(first_treat > 0, 1, 0)
  )

# --- FRED API: Fetch state unemployment rates ---
# FRED series: {ST}UR = unemployment rate for state ST
fetch_fred <- function(series_id, fred_key) {
  url <- paste0(
    "https://api.stlouisfed.org/fred/series/observations?",
    "series_id=", series_id,
    "&api_key=", fred_key,
    "&file_type=json",
    "&observation_start=2012-01-01",
    "&observation_end=2025-12-31"
  )

  resp <- tryCatch(
    httr::GET(url, httr::timeout(30)),
    error = function(e) NULL
  )

  if (is.null(resp) || httr::status_code(resp) != 200) {
    warning("FRED failed for ", series_id)
    return(NULL)
  }

  content <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
  obs <- content$observations

  if (is.null(obs) || nrow(obs) == 0) return(NULL)

  obs %>%
    mutate(
      date = as.Date(date),
      value = as.numeric(value),
      series_id = series_id
    ) %>%
    filter(!is.na(value)) %>%
    select(date, value, series_id)
}

# FRED state unemployment rate series: {ST}UR (e.g., PAUR, COUR)
cat("Fetching state unemployment rates from FRED...\n")
urate_list <- list()
for (i in seq_len(nrow(state_fips))) {
  abbr <- state_fips$state_abbr[i]
  sid <- paste0(abbr, "UR")
  result <- fetch_fred(sid, fred_key)
  if (!is.null(result)) {
    result$state_abbr <- abbr
    result$state_fips <- state_fips$fips[i]
    urate_list[[length(urate_list) + 1]] <- result
  }
  if (i %% 10 == 0) cat("  ", i, "/", nrow(state_fips), " states...\n")
  Sys.sleep(0.15)
}
urate_df <- bind_rows(urate_list) %>%
  rename(urate = value) %>%
  mutate(
    year = as.integer(format(date, "%Y")),
    month = as.integer(format(date, "%m"))
  )

cat("  Unemployment rate: ", nrow(urate_df), " state-month obs, ",
    n_distinct(urate_df$state_abbr), " states\n")
stopifnot("No urate data" = nrow(urate_df) > 0)

# --- Also fetch nonfarm payrolls for employment level ---
cat("Fetching nonfarm payrolls from FRED...\n")
emp_list <- list()
for (i in seq_len(nrow(state_fips))) {
  abbr <- state_fips$state_abbr[i]
  # FRED series: {ST}NA = all employees, nonfarm (thousands)
  sid <- paste0(abbr, "NA")
  result <- fetch_fred(sid, fred_key)
  if (!is.null(result)) {
    result$state_abbr <- abbr
    result$state_fips <- state_fips$fips[i]
    emp_list[[length(emp_list) + 1]] <- result
  }
  if (i %% 10 == 0) cat("  ", i, "/", nrow(state_fips), " states...\n")
  Sys.sleep(0.15)
}

emp_df <- bind_rows(emp_list) %>%
  rename(nonfarm_emp = value) %>%
  mutate(
    year = as.integer(format(date, "%Y")),
    month = as.integer(format(date, "%m"))
  )
cat("  Nonfarm employment: ", nrow(emp_df), " state-month obs\n")

# --- Merge BLS panel ---
bls_panel <- urate_df %>%
  select(state_fips, state_abbr, year, month, urate)

if (nrow(emp_df) > 0) {
  bls_panel <- bls_panel %>%
    left_join(emp_df %>% select(state_fips, year, month, nonfarm_emp),
              by = c("state_fips", "year", "month"))
} else {
  bls_panel$nonfarm_emp <- NA_real_
}

bls_panel <- bls_panel %>%
  mutate(
    log_emp = ifelse(!is.na(nonfarm_emp) & nonfarm_emp > 0, log(nonfarm_emp), NA_real_),
    year_month = year + (month - 1) / 12
  )

# Add treatment info
bls_panel <- bls_panel %>%
  left_join(
    state_fips %>% select(fips, first_treat, treated),
    by = c("state_fips" = "fips")
  )

cat("\nBLS panel: ", nrow(bls_panel), " state-month observations\n")
cat("  States: ", n_distinct(bls_panel$state_abbr), "\n")
cat("  Treated: ", n_distinct(bls_panel$state_abbr[bls_panel$treated == 1]), "\n")
cat("  Year range: ", min(bls_panel$year), "-", max(bls_panel$year), "\n")

stopifnot("Expected 50+ states" = n_distinct(bls_panel$state_abbr) >= 50)
stopifnot("Expected treated observations" = sum(bls_panel$treated == 1) > 0)

# --- Census ACS: Race-stratified employment ---
cat("\n=== Fetching ACS Race-Stratified Employment ===\n")

census_key <- ""
env_files <- c("../../../../.env", "../../../.env", "../../.env")
for (ef in env_files) {
  if (file.exists(ef)) {
    env_lines <- readLines(ef, warn = FALSE)
    line <- grep("^(export )?CENSUS_API_KEY=", env_lines, value = TRUE)
    if (length(line) > 0) {
      census_key <- gsub("^(export )?CENSUS_API_KEY=", "", line[1])
      census_key <- gsub("[\"']", "", census_key)
      break
    }
  }
}

fetch_acs_race <- function(yr, census_key) {
  vars_black <- "C23002B_001E,C23002B_006E,C23002B_013E,C23002B_003E,C23002B_010E"
  vars_white <- "C23002H_001E,C23002H_006E,C23002H_013E,C23002H_003E,C23002H_010E"

  url_b <- paste0(
    "https://api.census.gov/data/", yr, "/acs/acs1?",
    "get=NAME,", vars_black, "&for=state:*"
  )
  url_w <- paste0(
    "https://api.census.gov/data/", yr, "/acs/acs1?",
    "get=NAME,", vars_white, "&for=state:*"
  )
  if (nchar(census_key) > 0) {
    url_b <- paste0(url_b, "&key=", census_key)
    url_w <- paste0(url_w, "&key=", census_key)
  }

  resp_b <- tryCatch(httr::GET(url_b, httr::timeout(60)), error = function(e) NULL)
  resp_w <- tryCatch(httr::GET(url_w, httr::timeout(60)), error = function(e) NULL)

  if (is.null(resp_b) || is.null(resp_w)) return(NULL)
  if (httr::status_code(resp_b) != 200 || httr::status_code(resp_w) != 200) {
    warning("ACS API failed for year ", yr,
            " (B:", httr::status_code(resp_b), ", W:", httr::status_code(resp_w), ")")
    return(NULL)
  }

  parse_acs <- function(resp) {
    content <- tryCatch(
      jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8")),
      error = function(e) NULL
    )
    if (is.null(content) || !is.matrix(content) || nrow(content) < 2) return(NULL)
    df <- as.data.frame(content[-1, , drop = FALSE], stringsAsFactors = FALSE)
    names(df) <- content[1, ]
    df
  }

  black_df <- parse_acs(resp_b)
  white_df <- parse_acs(resp_w)
  if (is.null(black_df) || is.null(white_df)) return(NULL)

  black <- black_df %>%
    transmute(
      state_fips = state,
      year = yr,
      black_pop_16plus = as.numeric(C23002B_001E),
      black_male_employed = as.numeric(C23002B_006E),
      black_female_employed = as.numeric(C23002B_013E),
      black_male_pop = as.numeric(C23002B_003E),
      black_female_pop = as.numeric(C23002B_010E)
    ) %>%
    mutate(
      black_employed = black_male_employed + black_female_employed,
      black_working_pop = black_male_pop + black_female_pop,
      black_epop = black_employed / black_working_pop * 100
    )

  white <- white_df %>%
    transmute(
      state_fips = state,
      year = yr,
      white_pop_16plus = as.numeric(C23002H_001E),
      white_male_employed = as.numeric(C23002H_006E),
      white_female_employed = as.numeric(C23002H_013E),
      white_male_pop = as.numeric(C23002H_003E),
      white_female_pop = as.numeric(C23002H_010E)
    ) %>%
    mutate(
      white_employed = white_male_employed + white_female_employed,
      white_working_pop = white_male_pop + white_female_pop,
      white_epop = white_employed / white_working_pop * 100
    )

  inner_join(black, white, by = c("state_fips", "year"))
}

acs_list <- list()
for (yr in 2012:2023) {
  cat("  ACS ", yr, "...\n")
  result <- fetch_acs_race(yr, census_key)
  if (!is.null(result)) {
    acs_list[[length(acs_list) + 1]] <- result
  }
  Sys.sleep(0.5)
}

acs_panel <- bind_rows(acs_list)

# Add treatment info
acs_panel <- acs_panel %>%
  left_join(
    state_fips %>% select(fips, state_abbr, first_treat, treated),
    by = c("state_fips" = "fips")
  ) %>%
  mutate(bw_gap = white_epop - black_epop)

cat("ACS panel: ", nrow(acs_panel), " state-year observations\n")
cat("  States: ", n_distinct(acs_panel$state_fips), "\n")
cat("  Years: ", min(acs_panel$year), "-", max(acs_panel$year), "\n")

stopifnot("No ACS data returned" = nrow(acs_panel) > 0)

# --- Save ---
save(bls_panel, acs_panel, state_fips, clean_slate_states,
     file = "data/clean_slate_data.RData")

cat("\n=== Data fetch complete ===\n")
cat("BLS: ", nrow(bls_panel), " state-months\n")
cat("ACS: ", nrow(acs_panel), " state-years\n")
