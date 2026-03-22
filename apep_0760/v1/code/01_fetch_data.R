# 01_fetch_data.R — Fetch SEC enforcement action data
# apep_0760: SEC Chair Transitions and Capital Market Integrity
#
# Data sources:
#   1. SEC.gov litigation releases (paginated scraping)
#   2. SEC.gov administrative proceedings (paginated scraping)
#   3. Validated against Cornerstone Research annual enforcement reports

source("00_packages.R")

# ============================================================
# 1. Chair Transition Dates (hand-coded from SEC historical records)
# ============================================================

chair_transitions <- tribble(
  ~transition_id, ~outgoing_chair, ~incoming_chair, ~transition_date,
  ~outgoing_party, ~incoming_party, ~transition_type,
  1L, "Schapiro",  "Walter/White",    "2012-12-14", "D", "D", "same_party",
  2L, "White",     "Piwowar/Clayton", "2017-01-20", "D", "R", "cross_party",
  3L, "Clayton",   "Lee/Gensler",     "2020-12-23", "R", "D", "cross_party",
  4L, "Gensler",   "Uyeda/Atkins",    "2025-01-20", "D", "R", "cross_party"
) %>%
  mutate(
    transition_date = as.Date(transition_date),
    cross_party = (transition_type == "cross_party")
  )

cat("Chair transitions:\n")
print(chair_transitions)

chair_tenures <- tribble(
  ~chair, ~start_date, ~end_date, ~party, ~acting,
  "Schapiro",  "2009-01-27", "2012-12-14", "D", FALSE,
  "Walter",    "2012-12-14", "2013-04-10", "D", TRUE,
  "White",     "2013-04-10", "2017-01-20", "D", FALSE,
  "Piwowar",   "2017-01-20", "2017-05-04", "R", TRUE,
  "Clayton",   "2017-05-04", "2020-12-23", "R", FALSE,
  "Lee",       "2020-12-24", "2021-04-17", "D", TRUE,
  "Gensler",   "2021-04-17", "2025-01-20", "D", FALSE,
  "Uyeda",     "2025-01-20", "2025-04-21", "R", TRUE,
  "Atkins",    "2025-04-21", "2026-03-22", "R", FALSE
) %>%
  mutate(
    start_date = as.Date(start_date),
    end_date = as.Date(end_date)
  )

# ============================================================
# 2. Scrape SEC Enforcement Actions (Litigation Releases + Admin Proceedings)
# ============================================================

scrape_sec_page <- function(base_url, page_num, action_type_label) {
  url <- paste0(base_url, "?page=", page_num)

  tryCatch({
    Sys.sleep(2)  # Respect SEC rate limits

    resp <- request(url) %>%
      req_headers(
        `User-Agent` = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 APEP-Research contact@socialcatalystlab.org",
        `Accept` = "text/html,application/xhtml+xml",
        `Accept-Language` = "en-US,en;q=0.9"
      ) %>%
      req_timeout(30) %>%
      req_perform()

    page_html <- read_html(resp_body_string(resp))
    text <- html_text2(page_html)

    # Extract dates in "Month Day, Year" format
    date_pattern <- "(January|February|March|April|May|June|July|August|September|October|November|December) [0-9]{1,2}, [0-9]{4}"
    dates_raw <- str_extract_all(text, date_pattern)[[1]]

    if (length(dates_raw) == 0) {
      return(NULL)
    }

    parsed <- mdy(dates_raw)
    # Filter to only enforcement-relevant dates (2004-2026)
    parsed <- parsed[!is.na(parsed) & parsed >= as.Date("2004-01-01") & parsed <= as.Date("2026-12-31")]

    if (length(parsed) == 0) return(NULL)

    tibble(
      date = parsed,
      action_type = action_type_label,
      page = page_num
    )
  }, error = function(e) {
    cat("  Error on page", page_num, ":", conditionMessage(e), "\n")
    NULL
  })
}

scrape_sec_enforcement <- function(base_url, action_type, min_date = as.Date("2009-01-01")) {
  cat("Scraping", action_type, "from", base_url, "\n")
  all_data <- list()
  page <- 0
  max_pages <- 200  # Safety limit
  consecutive_empty <- 0

  while (page < max_pages) {
    cat("  Page", page, "...")
    result <- scrape_sec_page(base_url, page, action_type)

    if (is.null(result) || nrow(result) == 0) {
      consecutive_empty <- consecutive_empty + 1
      if (consecutive_empty >= 3) {
        cat(" 3 consecutive empty pages, stopping.\n")
        break
      }
      cat(" empty\n")
      page <- page + 1
      next
    }

    consecutive_empty <- 0
    cat(" found", nrow(result), "dates, range:",
        as.character(min(result$date)), "to", as.character(max(result$date)), "\n")

    all_data <- c(all_data, list(result))

    # Stop if we've gone past our minimum date
    if (min(result$date) < min_date) {
      cat("  Reached", as.character(min_date), ", stopping.\n")
      break
    }

    page <- page + 1
  }

  if (length(all_data) > 0) {
    bind_rows(all_data) %>%
      filter(date >= min_date) %>%
      distinct(date, .keep_all = TRUE)
  } else {
    tibble(date = as.Date(character()), action_type = character(), page = integer())
  }
}

# Scrape litigation releases
lit_releases <- scrape_sec_enforcement(
  "https://www.sec.gov/enforcement-litigation/litigation-releases",
  "litigation",
  min_date = as.Date("2009-01-01")
)

# Scrape administrative proceedings
admin_procs <- scrape_sec_enforcement(
  "https://www.sec.gov/enforcement-litigation/administrative-proceedings",
  "administrative",
  min_date = as.Date("2009-01-01")
)

# Combine
enforcement_raw <- bind_rows(lit_releases, admin_procs) %>%
  select(date, action_type) %>%
  arrange(date)

cat("\n=== Data Summary ===\n")
cat("Total enforcement actions:", nrow(enforcement_raw), "\n")
cat("  Litigation releases:", sum(enforcement_raw$action_type == "litigation"), "\n")
cat("  Administrative proceedings:", sum(enforcement_raw$action_type == "administrative"), "\n")
cat("Date range:", as.character(min(enforcement_raw$date)),
    "to", as.character(max(enforcement_raw$date)), "\n")

# ============================================================
# 3. Validate Against Cornerstone Research
# ============================================================

cornerstone_fy <- tribble(
  ~fiscal_year, ~total_actions, ~standalone_actions,
  2010, 681, 473,
  2011, 735, 489,
  2012, 734, 497,
  2013, 686, 476,
  2014, 755, 515,
  2015, 807, 507,
  2016, 868, 547,
  2017, 754, 445,
  2018, 821, 490,
  2019, 862, 526,
  2020, 715, 405,
  2021, 697, 434,
  2022, 760, 462,
  2023, 784, 465,
  2024, 583, 388,
  2025, 313, NA_real_
)

# Assign fiscal year (SEC FY = Oct 1 - Sep 30)
enforcement_raw <- enforcement_raw %>%
  mutate(fiscal_year = if_else(month(date) >= 10, year(date) + 1L, year(date)))

our_fy <- enforcement_raw %>%
  count(fiscal_year, name = "our_count")

validation <- cornerstone_fy %>%
  left_join(our_fy, by = "fiscal_year") %>%
  mutate(coverage_pct = round(our_count / total_actions * 100, 1))

cat("\n=== Validation vs Cornerstone Research ===\n")
print(validation, n = 20)

# Check if we have enough data
if (nrow(enforcement_raw) < 200) {
  stop(paste0(
    "FATAL: Insufficient SEC enforcement data.\n",
    "  Only ", nrow(enforcement_raw), " records retrieved.\n",
    "  Need at least 200 for credible analysis.\n",
    "  The SEC website may have changed structure or blocked scraping."
  ))
}

# ============================================================
# 4. Save Data
# ============================================================

write_csv(enforcement_raw, "../data/enforcement_actions.csv")
write_csv(chair_transitions, "../data/chair_transitions.csv")
write_csv(chair_tenures, "../data/chair_tenures.csv")
write_csv(cornerstone_fy, "../data/cornerstone_fy_totals.csv")

cat("\n=== Files saved ===\n")
cat("  data/enforcement_actions.csv:", nrow(enforcement_raw), "rows\n")
cat("  data/chair_transitions.csv:", nrow(chair_transitions), "rows\n")
cat("  data/chair_tenures.csv:", nrow(chair_tenures), "rows\n")
cat("  data/cornerstone_fy_totals.csv:", nrow(cornerstone_fy), "rows\n")
