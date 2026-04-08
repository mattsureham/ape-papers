##############################################################################
# 01_fetch_data.R — Fetch congressional hearings + Google Trends
# apep_1434: When Scandals Go Dark
#
# Data strategy:
# 1. GovInfo POST search: all CHRG records per agency (title + date)
# 2. Google Trends: agency + scandal interest & competing event interest
# 3. Pre-determined mega-event calendar (hardcoded from Wikipedia)
##############################################################################

source("00_packages.R")

# Google Trends package
if (!requireNamespace("gtrendsR", quietly = TRUE)) {
  install.packages("gtrendsR", repos = "https://cloud.r-project.org")
}
library(gtrendsR)

# Load .env
dotenv_path <- normalizePath(file.path(getwd(), "..", "..", "..", "..", ".env"),
                             mustWork = FALSE)
if (file.exists(dotenv_path)) {
  env_lines <- readLines(dotenv_path, warn = FALSE)
  for (line in env_lines) {
    line <- trimws(line)
    if (nchar(line) == 0 || startsWith(line, "#")) next
    if (grepl("^export ", line)) line <- sub("^export ", "", line)
    eq_pos <- regexpr("=", line, fixed = TRUE)
    if (eq_pos > 0) {
      key <- trimws(substr(line, 1, eq_pos - 1))
      val <- trimws(substr(line, eq_pos + 1, nchar(line)))
      val <- gsub('^"|"$', '', val)
      val <- gsub("^'|'$", '', val)
      if (nchar(key) > 0 && grepl("^[A-Za-z_][A-Za-z0-9_]*$", key)) {
        do.call(Sys.setenv, setNames(list(val), key))
      }
    }
  }
}

api_key <- Sys.getenv("REGULATIONS_GOV_API_KEY")
if (nchar(api_key) == 0) stop("REGULATIONS_GOV_API_KEY not found")

###########################################################################
# 1. Agency definitions
###########################################################################

agencies <- tribble(
  ~agency_code, ~agency_name, ~govinfo_query, ~gtrends_term,
  "VA",   "Veterans Affairs",   "\"veterans affairs\"",          "veterans affairs scandal",
  "EPA",  "EPA",                "\"environmental protection agency\" OR \"EPA\"",  "EPA scandal",
  "FDA",  "FDA",                "\"food and drug administration\" OR \"FDA\"",     "FDA scandal",
  "FAA",  "FAA",                "\"federal aviation\" OR \"FAA\"",                 "FAA scandal",
  "FEMA", "FEMA",               "\"FEMA\" OR \"federal emergency\"",               "FEMA scandal",
  "IRS",  "IRS",                "\"internal revenue\" OR \"IRS\"",                 "IRS scandal",
  "DHS",  "Homeland Security",  "\"homeland security\"",                           "homeland security scandal",
  "DOD",  "Defense",            "\"department of defense\" OR \"pentagon\"",        "pentagon scandal",
  "HHS",  "HHS",                "\"health and human services\"",                   "HHS scandal",
  "DOJ",  "Justice",            "\"department of justice\" OR \"attorney general\"","department of justice scandal",
  "DOE",  "Energy",             "\"department of energy\"",                        "department of energy scandal",
  "USDA", "Agriculture",        "\"department of agriculture\" OR \"USDA\"",       "USDA scandal",
  "DOI",  "Interior",           "\"department of the interior\"",                  "interior department scandal",
  "DOL",  "Labor",              "\"department of labor\" OR \"OSHA\"",             "OSHA scandal",
  "DOT",  "Transportation",     "\"department of transportation\"",                "transportation department scandal",
  "ED",   "Education",          "\"department of education\"",                     "department of education scandal",
  "HUD",  "HUD",                "\"housing and urban development\" OR \"HUD\"",   "HUD scandal",
  "CDC",  "CDC",                "\"centers for disease control\" OR \"CDC\"",      "CDC scandal",
  "NASA", "NASA",               "\"NASA\"",                                        "NASA scandal"
)

###########################################################################
# 2. Fetch hearings from GovInfo
###########################################################################
cat("=== Fetching hearings from GovInfo ===\n")

fetch_agency_hearings <- function(query_text, api_key) {
  url <- paste0("https://api.govinfo.gov/search?api_key=", api_key)
  full_query <- paste0("collection:CHRG AND (", query_text, ")")

  all_results <- list()
  offset_mark <- "*"
  page <- 1

  repeat {
    body <- list(query = full_query, pageSize = 100, offsetMark = offset_mark)

    resp <- tryCatch(
      {
        req <- request(url) |>
          req_method("POST") |>
          req_body_json(body) |>
          req_timeout(60) |>
          req_retry(max_tries = 3, backoff = ~3)
        resp_body_json(req_perform(req))
      },
      error = function(e) {
        cat("  Error p", page, ":", conditionMessage(e), "\n")
        NULL
      }
    )

    if (is.null(resp)) break
    results <- resp$results
    if (is.null(results) || length(results) == 0) break

    all_results <- c(all_results, results)

    next_offset <- resp$offsetMark
    if (is.null(next_offset) || next_offset == offset_mark) break
    offset_mark <- next_offset
    page <- page + 1
    Sys.sleep(0.5)
  }

  return(all_results)
}

# Cache: skip GovInfo if already fetched
if (file.exists("data/hearings_raw.rds") && file.exists("data/agency_hearings.rds")) {
  cat("=== GovInfo data cached, loading from disk ===\n")
  hearings_raw <- readRDS("data/hearings_raw.rds")
  hearings_dedup <- readRDS("data/hearings_dedup.rds")
  agency_hearings <- readRDS("data/agency_hearings.rds")
  cat("Loaded", nrow(hearings_dedup), "hearings\n")
} else {
  hearing_records <- list()

  for (i in seq_len(nrow(agencies))) {
    agency <- agencies$agency_code[i]
    query <- agencies$govinfo_query[i]
    cat("Fetching", agency, "...")

    results <- fetch_agency_hearings(query, api_key)
    cat(" ", length(results), "hearings\n")

    if (length(results) > 0) {
      records <- map_dfr(results, function(r) {
        tibble(
          agency_code = agency,
          title = r$title %||% NA_character_,
          date_issued = r$dateIssued %||% NA_character_,
          package_id = r$packageId %||% NA_character_
        )
      })
      hearing_records[[i]] <- records
    }
    Sys.sleep(1)
  }

  hearings_raw <- bind_rows(hearing_records)
  cat("\nTotal hearing records:", nrow(hearings_raw), "\n")

  if (nrow(hearings_raw) < 500) {
    stop("FATAL: Only ", nrow(hearings_raw),
         " hearings found. Expected thousands.")
  }

  # Parse dates and filter to 2009-2024
  hearings_raw <- hearings_raw |>
    mutate(
      date = as.Date(date_issued),
      ym = floor_date(date, "month"),
      year = year(date)
    ) |>
    filter(!is.na(date), year >= 2009, year <= 2024)

  # Deduplicate
  hearings_dedup <- hearings_raw |>
    distinct(agency_code, package_id, .keep_all = TRUE)

  agency_hearings <- hearings_dedup |>
    group_by(agency_code, ym) |>
    summarise(n_hearings = n(), .groups = "drop")

  cat("Hearings 2009-2024:", nrow(hearings_dedup), "\n")
  cat("\nAgency totals:\n")
  print(hearings_dedup |> count(agency_code, sort = TRUE))

  # Save immediately so we don't lose data
  dir.create("data", showWarnings = FALSE)
  saveRDS(hearings_raw, "data/hearings_raw.rds")
  saveRDS(hearings_dedup, "data/hearings_dedup.rds")
  saveRDS(agency_hearings, "data/agency_hearings.rds")
  cat("GovInfo data saved to cache.\n")
}

###########################################################################
# 3. Google Trends: agency scandal salience
###########################################################################
cat("\n=== Fetching Google Trends data ===\n")

# Fetch trends for each agency's scandal terms
# Google Trends returns monthly data for queries spanning > 5 years

trends_data <- list()

for (i in seq_len(nrow(agencies))) {
  agency <- agencies$agency_code[i]
  term <- agencies$gtrends_term[i]
  cat("Google Trends for", agency, "(", term, ")...")

  result <- tryCatch(
    {
      gtrends(
        keyword = term,
        geo = "US",
        time = "2009-01-01 2024-12-31",
        onlyInterest = TRUE
      )
    },
    error = function(e) {
      cat(" Error:", conditionMessage(e), "\n")
      NULL
    }
  )

  if (!is.null(result) && !is.null(result$interest_over_time)) {
    df <- result$interest_over_time |>
      mutate(
        agency_code = agency,
        ym = floor_date(as.Date(date), "month"),
        scandal_interest = as.numeric(gsub("<1", "0.5", hits))
      ) |>
      select(agency_code, ym, scandal_interest)

    trends_data[[i]] <- df
    cat(" ", nrow(df), "months, max =", max(df$scandal_interest, na.rm = TRUE), "\n")
  } else {
    cat(" No data\n")
  }

  Sys.sleep(3)  # Google Trends rate limit
}

scandal_trends <- bind_rows(trends_data)
cat("Total trends rows:", nrow(scandal_trends), "\n")

# Competing news trends: Olympics, impeachment
cat("\n--- Competing event trends ---\n")

competing_trends_raw <- tryCatch(
  {
    gtrends(
      keyword = c("Olympics", "impeachment"),
      geo = "US",
      time = "2009-01-01 2024-12-31",
      onlyInterest = TRUE
    )
  },
  error = function(e) {
    cat("Error:", conditionMessage(e), "\n")
    NULL
  }
)

if (!is.null(competing_trends_raw)) {
  competing_trends <- competing_trends_raw$interest_over_time |>
    mutate(
      ym = floor_date(as.Date(date), "month"),
      interest = as.numeric(gsub("<1", "0.5", hits))
    ) |>
    select(ym, keyword, interest) |>
    pivot_wider(names_from = keyword, values_from = interest,
                values_fn = mean) |>
    rename(olympics_interest = Olympics, impeach_interest = impeachment) |>
    mutate(competing_interest = olympics_interest + impeach_interest)

  cat("Competing trends:", nrow(competing_trends), "months\n")
} else {
  stop("FATAL: Cannot fetch competing news trends from Google Trends.")
}

###########################################################################
# 4. Pre-determined mega-event calendar
###########################################################################
cat("\n=== Building event calendar ===\n")

mega_events <- tribble(
  ~event, ~start_date, ~end_date, ~event_type,
  "Summer Olympics 2012", "2012-07-27", "2012-08-12", "olympics",
  "Summer Olympics 2016", "2016-08-05", "2016-08-21", "olympics",
  "Summer Olympics 2020", "2021-07-23", "2021-08-08", "olympics",
  "Summer Olympics 2024", "2024-07-26", "2024-08-11", "olympics",
  "Winter Olympics 2010", "2010-02-12", "2010-02-28", "olympics",
  "Winter Olympics 2014", "2014-02-07", "2014-02-23", "olympics",
  "Winter Olympics 2018", "2018-02-09", "2018-02-25", "olympics",
  "Winter Olympics 2022", "2022-02-04", "2022-02-20", "olympics",
  "Trump Impeachment 1",  "2019-09-24", "2020-02-05", "impeachment",
  "Trump Impeachment 2",  "2021-01-13", "2021-02-13", "impeachment",
  "Royal Wedding 2011",   "2011-04-29", "2011-05-01", "royals",
  "Royal Wedding 2018",   "2018-05-19", "2018-05-21", "royals",
  "Queen Elizabeth Death", "2022-09-08", "2022-09-19", "royals",
  "World Cup 2014",       "2014-06-12", "2014-07-13", "worldcup",
  "World Cup 2018",       "2018-06-14", "2018-07-15", "worldcup",
  "World Cup 2022",       "2022-11-20", "2022-12-18", "worldcup"
) |>
  mutate(start_date = as.Date(start_date), end_date = as.Date(end_date))

event_months <- map_dfr(seq_len(nrow(mega_events)), function(e) {
  evt <- mega_events[e, ]
  covered <- seq(floor_date(evt$start_date, "month"),
                 floor_date(evt$end_date, "month"), by = "month")
  tibble(ym = covered, event = evt$event, event_type = evt$event_type)
}) |>
  group_by(ym) |>
  summarise(
    has_mega_event = TRUE,
    n_events = n(),
    events = paste(event, collapse = "; "),
    .groups = "drop"
  )

cat("Months with mega-events:", nrow(event_months), "\n")

###########################################################################
# 5. Political controls (2009-2024)
###########################################################################
political <- tribble(
  ~congress, ~start_year, ~divided_gov, ~dem_house, ~dem_senate,
  111, 2009, 0, 1, 1,
  112, 2011, 1, 0, 1,
  113, 2013, 1, 0, 1,
  114, 2015, 1, 0, 0,
  115, 2017, 0, 0, 0,
  116, 2019, 1, 1, 0,
  117, 2021, 0, 1, 1,
  118, 2023, 1, 0, 1
) |>
  rowwise() |>
  mutate(
    ym = list(seq(as.Date(paste0(start_year, "-01-01")),
                  as.Date(paste0(start_year + 1, "-12-01")),
                  by = "month"))
  ) |>
  unnest(ym) |>
  select(ym, divided_gov, dem_house, dem_senate, congress)

###########################################################################
# 6. Save all raw data
###########################################################################
cat("\n=== Saving raw data ===\n")

saveRDS(hearings_raw, "data/hearings_raw.rds")
saveRDS(hearings_dedup, "data/hearings_dedup.rds")
saveRDS(agency_hearings, "data/agency_hearings.rds")
saveRDS(scandal_trends, "data/scandal_trends.rds")
saveRDS(competing_trends, "data/competing_trends.rds")
saveRDS(event_months, "data/event_months.rds")
saveRDS(mega_events, "data/mega_events.rds")
saveRDS(political, "data/political.rds")
saveRDS(agencies, "data/agencies.rds")

cat("\n=== Data fetch complete ===\n")
cat("Hearings (2009-2024):", nrow(hearings_dedup), "\n")
cat("Scandal trends rows:", nrow(scandal_trends), "\n")
cat("Competing trends rows:", nrow(competing_trends), "\n")
cat("Mega-event months:", nrow(event_months), "\n")
