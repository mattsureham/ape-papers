## 01_fetch_data.R — Fetch QWI data from Census API
## apep_0761: Post-Dobbs Healthcare Labor Reallocation

source("00_packages.R")

CENSUS_KEY <- Sys.getenv("CENSUS_API_KEY")
if (nchar(CENSUS_KEY) == 0) {
  CENSUS_KEY <- Sys.getenv("CENSUS_KEY")
}
if (nchar(CENSUS_KEY) == 0) stop("CENSUS_API_KEY not set in environment")

# NAICS codes of interest
naics_codes <- c(
  "62141",  # Family Planning Centers
  "6211",   # Offices of Physicians
  "6214",   # Outpatient Care Centers
  "6219",   # Other Ambulatory Health Care Services
  "6213"    # Dental/Optometry (PLACEBO)
)

# State FIPS codes (50 states + DC)
state_fips <- sprintf("%02d", c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,
                                21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,
                                36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,
                                53,54,55,56))

# Time periods: 2015-Q1 to 2024-Q2
quarters <- expand.grid(
  year = 2015:2024,
  q = 1:4,
  stringsAsFactors = FALSE
) %>%
  filter(!(year == 2024 & q > 2)) %>%
  mutate(time_str = paste0(year, "-Q", q))

# Strategy: query all states as comma-separated list per industry-quarter
# Census QWI supports state:01,02,04,...
states_str <- paste(state_fips, collapse = ",")

cat("Fetching QWI data:", length(naics_codes), "industries x",
    nrow(quarters), "quarters x", length(state_fips), "states\n")

fetch_qwi <- function(naics, time_str) {
  url <- paste0(
    "https://api.census.gov/data/timeseries/qwi/sa",
    "?get=Emp,EmpS,EarnS,EmpEnd",
    "&for=state:", states_str,
    "&industry=", naics,
    "&time=", time_str,
    "&key=", CENSUS_KEY
  )

  resp <- tryCatch(
    httr::GET(url, httr::timeout(60)),
    error = function(e) {
      warning(paste("HTTP error for", naics, time_str, ":", e$message))
      return(NULL)
    }
  )

  if (is.null(resp) || httr::status_code(resp) != 200) {
    # Try single-state fallback for problem cases
    warning(paste("Non-200 for", naics, time_str,
                  "- status:", ifelse(is.null(resp), "NULL", httr::status_code(resp))))
    return(NULL)
  }

  raw <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(raw)

  if (is.null(parsed) || nrow(parsed) < 2) {
    warning(paste("Empty response for", naics, time_str))
    return(NULL)
  }

  df <- as.data.frame(parsed[-1, , drop = FALSE], stringsAsFactors = FALSE)
  names(df) <- parsed[1, ]
  df$industry <- naics
  df$time <- time_str
  return(df)
}

all_data <- list()
idx <- 0
total <- length(naics_codes) * nrow(quarters)

for (naics in naics_codes) {
  for (i in seq_len(nrow(quarters))) {
    idx <- idx + 1
    ts <- quarters$time_str[i]

    if (idx %% 10 == 0) cat(sprintf("  [%d/%d] %s %s\n", idx, total, naics, ts))

    result <- fetch_qwi(naics, ts)
    if (!is.null(result)) {
      all_data[[length(all_data) + 1]] <- result
    }

    Sys.sleep(0.15)
  }
}

cat("Fetched", length(all_data), "successful API responses out of", total, "requests\n")

if (length(all_data) == 0) {
  stop("FATAL: No QWI data fetched. Check CENSUS_API_KEY and API availability.")
}

qwi_raw <- bind_rows(all_data)

stopifnot(nrow(qwi_raw) > 0)

cat("Raw QWI data:", nrow(qwi_raw), "rows\n")
cat("States:", n_distinct(qwi_raw$state), "\n")
cat("Industries:", n_distinct(qwi_raw$industry), "\n")
cat("Time periods:", n_distinct(qwi_raw$time), "\n")

saveRDS(qwi_raw, "../data/qwi_raw.rds")
cat("Saved qwi_raw.rds\n")
