# 01_fetch_data.R — Fetch Medicaid enrollment data and construct treatment variable
# apep_0777: SNAP-Medicaid Data Coordination and Enrollment Resilience

source("00_packages.R")
library(fixest)  # For analysis downstream

# ============================================================
# 1. E14 Waiver States (hand-coded from CBPP documentation)
# ============================================================

# States that received Section 1902(e)(14)(A) waivers allowing
# SNAP-based ex parte Medicaid renewal during 2023 unwinding
# Source: CBPP "Streamlining Medicaid Renewals" tracker, KFF survey

e14_states <- tribble(
  ~state, ~state_fips, ~e14_waiver, ~e14_approval_date,
  "Alabama", "01", TRUE, "2023-04-01",
  "Alaska", "02", FALSE, NA,
  "Arizona", "04", TRUE, "2023-05-01",
  "Arkansas", "05", TRUE, "2023-04-01",
  "California", "06", TRUE, "2023-06-01",
  "Colorado", "08", TRUE, "2023-04-01",
  "Connecticut", "09", FALSE, NA,
  "Delaware", "10", FALSE, NA,
  "District of Columbia", "11", FALSE, NA,
  "Florida", "12", FALSE, NA,
  "Georgia", "13", FALSE, NA,
  "Hawaii", "15", TRUE, "2023-07-01",
  "Idaho", "16", FALSE, NA,
  "Illinois", "17", FALSE, NA,
  "Indiana", "18", TRUE, "2023-04-01",
  "Iowa", "19", FALSE, NA,
  "Kansas", "20", FALSE, NA,
  "Kentucky", "21", TRUE, "2023-05-01",
  "Louisiana", "22", TRUE, "2023-04-01",
  "Maine", "23", FALSE, NA,
  "Maryland", "24", FALSE, NA,
  "Massachusetts", "25", TRUE, "2023-06-01",
  "Michigan", "26", FALSE, NA,
  "Minnesota", "27", TRUE, "2023-04-01",
  "Mississippi", "28", FALSE, NA,
  "Missouri", "29", FALSE, NA,
  "Montana", "30", FALSE, NA,
  "Nebraska", "31", FALSE, NA,
  "Nevada", "32", TRUE, "2023-05-01",
  "New Hampshire", "33", FALSE, NA,
  "New Jersey", "34", FALSE, NA,
  "New Mexico", "35", TRUE, "2023-04-01",
  "New York", "36", FALSE, NA,
  "North Carolina", "37", FALSE, NA,
  "North Dakota", "38", FALSE, NA,
  "Ohio", "39", TRUE, "2023-04-01",
  "Oklahoma", "40", FALSE, NA,
  "Oregon", "41", TRUE, "2023-04-01",
  "Pennsylvania", "42", FALSE, NA,
  "Rhode Island", "44", FALSE, NA,
  "South Carolina", "45", FALSE, NA,
  "South Dakota", "46", FALSE, NA,
  "Tennessee", "47", FALSE, NA,
  "Texas", "48", FALSE, NA,
  "Utah", "49", FALSE, NA,
  "Vermont", "50", FALSE, NA,
  "Virginia", "51", FALSE, NA,
  "Washington", "53", TRUE, "2023-04-01",
  "West Virginia", "54", TRUE, "2023-05-01",
  "Wisconsin", "55", FALSE, NA,
  "Wyoming", "56", FALSE, NA
) %>%
  mutate(e14_approval_date = as.Date(e14_approval_date))

cat("E14 waiver states:", sum(e14_states$e14_waiver), "\n")
cat("Non-E14 states:", sum(!e14_states$e14_waiver), "\n")

# ============================================================
# 2. Fetch Medicaid Enrollment from CMS data.medicaid.gov
# ============================================================

# The CMS Medicaid & CHIP Monthly Enrollment dataset
# https://data.medicaid.gov/dataset/6165f45b-ca93-5bb5-9d06-db29c2a26a33
# This has state-month Medicaid enrollment counts

cat("\n--- Fetching CMS Medicaid enrollment data ---\n")

fetch_cms_enrollment <- function(max_records = 20000) {
  # CMS DKAN API endpoint — correct UUID confirmed
  base_url <- "https://data.medicaid.gov/api/1/datastore/query/6165f45b-ca93-5bb5-9d06-db29c692a360/0"

  all_data <- list()
  offset <- 0
  batch_size <- 2000

  while (offset < max_records) {
    cat("  Fetching offset", offset, "...")

    tryCatch({
      resp <- request(base_url) %>%
        req_url_query(limit = batch_size, offset = offset) %>%
        req_headers(`User-Agent` = "APEP-Research") %>%
        req_timeout(60) %>%
        req_perform()

      json <- resp_body_json(resp)

      if (length(json$results) == 0) {
        cat(" no more results.\n")
        break
      }

      batch <- map_dfr(json$results, function(row) {
        tibble(
          state = row$state_name %||% NA_character_,
          reporting_period = row$reporting_period %||% NA_character_,
          enrollment = as.numeric(row$total_medicaid_and_chip_enrollment %||% NA),
          medicaid_only = as.numeric(row$total_medicaid_enrollment %||% NA),
          preliminary = row$preliminary_or_updated %||% NA_character_
        )
      })

      cat(" got", nrow(batch), "rows\n")
      all_data <- c(all_data, list(batch))
      offset <- offset + batch_size

      Sys.sleep(0.5)

    }, error = function(e) {
      cat(" error:", conditionMessage(e), "\n")
      break
    })
  }

  if (length(all_data) > 0) bind_rows(all_data) else NULL
}

cms_data <- fetch_cms_enrollment(max_records = 20000)

if (is.null(cms_data) || nrow(cms_data) < 100) {
  stop("FATAL: Could not fetch CMS Medicaid enrollment data.")
}

cat("CMS data:", nrow(cms_data), "rows\n")
cat("Columns:", paste(names(cms_data), collapse = ", "), "\n")

# ============================================================
# 3. Clean enrollment data
# ============================================================

enrollment <- cms_data %>%
  filter(!is.na(state) & !is.na(reporting_period)) %>%
  mutate(
    year = as.integer(substr(reporting_period, 1, 4)),
    month = as.integer(substr(reporting_period, 5, 6)),
    date = as.Date(paste(year, month, "01", sep = "-")),
    state = str_to_title(trimws(state)),
    # Use total Medicaid+CHIP enrollment, fall back to Medicaid-only
    enrollment = coalesce(enrollment, medicaid_only)
  ) %>%
  filter(!is.na(enrollment) & enrollment > 0) %>%
  # Prefer updated over preliminary
  group_by(state, date) %>%
  arrange(desc(preliminary == "U")) %>%
  slice(1) %>%
  ungroup() %>%
  # Filter to analysis window
  filter(date >= as.Date("2019-01-01") & date <= as.Date("2024-12-01")) %>%
  arrange(state, date)

cat("Cleaned enrollment:", nrow(enrollment), "state-months\n")
cat("States:", n_distinct(enrollment$state), "\n")
cat("Date range:", as.character(range(enrollment$date)), "\n")

# ============================================================
# 4. Fetch unemployment data from FRED
# ============================================================

cat("\n--- Fetching BLS unemployment from FRED ---\n")

fred_key <- Sys.getenv("FRED_API_KEY")

fetch_fred_state_unemployment <- function() {
  if (fred_key == "") {
    cat("FRED_API_KEY not set, skipping unemployment data\n")
    return(NULL)
  }

  # FRED series IDs for state unemployment rates follow pattern: [STATE]UR
  state_abbrevs <- c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
                     "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
                     "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                     "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
                     "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")

  all_unemp <- map_dfr(state_abbrevs, function(st) {
    series_id <- paste0(st, "UR")
    url <- paste0("https://api.stlouisfed.org/fred/series/observations",
                  "?series_id=", series_id,
                  "&api_key=", fred_key,
                  "&file_type=json",
                  "&observation_start=2019-01-01",
                  "&observation_end=2024-12-31")
    tryCatch({
      resp <- request(url) %>%
        req_timeout(15) %>%
        req_perform()
      json <- resp_body_json(resp)
      if (length(json$observations) > 0) {
        map_dfr(json$observations, function(obs) {
          tibble(
            state_abbrev = st,
            date = as.Date(obs$date),
            unemployment_rate = as.numeric(obs$value)
          )
        })
      } else {
        tibble()
      }
    }, error = function(e) {
      tibble()
    })
  })

  if (nrow(all_unemp) > 0) {
    # Map abbreviations to full names
    state_map <- tibble(
      state_abbrev = state_abbrevs,
      state = c("Alabama","Alaska","Arizona","Arkansas","California","Colorado",
                "Connecticut","Delaware","District Of Columbia","Florida",
                "Georgia","Hawaii","Idaho","Illinois","Indiana","Iowa",
                "Kansas","Kentucky","Louisiana","Maine","Maryland",
                "Massachusetts","Michigan","Minnesota","Mississippi","Missouri",
                "Montana","Nebraska","Nevada","New Hampshire","New Jersey",
                "New Mexico","New York","North Carolina","North Dakota","Ohio",
                "Oklahoma","Oregon","Pennsylvania","Rhode Island",
                "South Carolina","South Dakota","Tennessee","Texas","Utah",
                "Vermont","Virginia","Washington","West Virginia","Wisconsin","Wyoming")
    )
    all_unemp <- all_unemp %>%
      left_join(state_map, by = "state_abbrev") %>%
      select(state, date, unemployment_rate)
  }

  all_unemp
}

unemp_data <- fetch_fred_state_unemployment()
if (!is.null(unemp_data) && nrow(unemp_data) > 0) {
  cat("Unemployment data:", nrow(unemp_data), "state-months\n")
} else {
  cat("Unemployment data not available, proceeding without.\n")
}

# ============================================================
# 5. Save raw data
# ============================================================

write_csv(enrollment, "../data/medicaid_enrollment.csv")
write_csv(e14_states, "../data/e14_waiver_states.csv")
if (!is.null(unemp_data) && nrow(unemp_data) > 0) {
  write_csv(unemp_data, "../data/state_unemployment.csv")
}

cat("\n=== Data saved ===\n")
cat("  medicaid_enrollment.csv:", nrow(enrollment), "rows\n")
cat("  e14_waiver_states.csv:", nrow(e14_states), "rows\n")
