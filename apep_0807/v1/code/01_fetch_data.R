## 01_fetch_data.R — Fetch all enacted public laws from GovTrack API
## APEP-0807: Legislating at Midnight
##
## Uses GovTrack API v2 (no API key required).
## Fetches enacted public laws for Congresses 93-118 (1973-2024).

source("00_packages.R")

cat("=== Fetching enacted public laws from GovTrack API ===\n")

# --- Congressional session end dates ---
# Source: Official records from the Office of the Clerk
# Each Congress has two sessions; we use the FINAL adjournment date
session_dates <- tribble(
  ~congress, ~session_start, ~session_end,
  93,  "1973-01-03", "1975-01-03",
  94,  "1975-01-14", "1977-01-03",
  95,  "1977-01-04", "1979-01-03",
  96,  "1979-01-15", "1981-01-03",
  97,  "1981-01-05", "1983-01-03",
  98,  "1983-01-03", "1985-01-03",
  99,  "1985-01-03", "1987-01-03",
  100, "1987-01-06", "1989-01-03",
  101, "1989-01-03", "1991-01-03",
  102, "1991-01-03", "1993-01-03",
  103, "1993-01-05", "1995-01-03",
  104, "1995-01-04", "1997-01-03",
  105, "1997-01-07", "1999-01-03",
  106, "1999-01-06", "2001-01-03",
  107, "2001-01-03", "2003-01-03",
  108, "2003-01-07", "2005-01-03",
  109, "2005-01-04", "2007-01-03",
  110, "2007-01-04", "2009-01-03",
  111, "2009-01-06", "2011-01-03",
  112, "2011-01-05", "2013-01-03",
  113, "2013-01-03", "2015-01-03",
  114, "2015-01-06", "2017-01-03",
  115, "2017-01-03", "2019-01-03",
  116, "2019-01-03", "2021-01-03",
  117, "2021-01-03", "2023-01-03",
  118, "2023-01-03", "2025-01-03"
) %>%
  mutate(
    session_start = as.Date(session_start),
    session_end = as.Date(session_end),
    session_length_days = as.integer(session_end - session_start)
  )

# --- Fetch function with rate limiting ---
fetch_enacted_laws <- function(congress_num, status = "enacted_signed") {
  base_url <- "https://www.govtrack.us/api/v2/bill"
  all_bills <- list()
  offset <- 0
  limit <- 100

  repeat {
    url <- paste0(
      base_url,
      "?congress=", congress_num,
      "&current_status=", status,
      "&limit=", limit,
      "&offset=", offset,
      "&fields=id,congress,bill_type,number,title_without_number,",
      "current_status_date,introduced_date,is_alive,",
      "sponsor,related_bills,major_actions,display_number"
    )

    resp <- GET(url)
    if (status_code(resp) != 200) {
      warning(sprintf("HTTP %d for congress %d, offset %d", status_code(resp), congress_num, offset))
      Sys.sleep(2)
      next
    }

    data <- content(resp, as = "parsed", simplifyVector = FALSE)
    bills <- data$objects
    total <- data$meta$total_count

    if (length(bills) == 0) break
    all_bills <- c(all_bills, bills)

    cat(sprintf("  Congress %d: fetched %d/%d bills\n", congress_num, length(all_bills), total))

    offset <- offset + limit
    if (offset >= total) break

    Sys.sleep(0.5)  # Rate limiting
  }

  return(all_bills)
}

# --- Parse a single bill into a row ---
parse_bill <- function(bill) {
  # Count major actions
  n_actions <- length(bill$major_actions)

  # Parse major actions for process indicators
  actions_text <- sapply(bill$major_actions, function(a) tolower(a[[3]]))

  # Check for voice vote vs roll call
  has_voice_vote <- any(grepl("voice vote", actions_text))
  has_roll_call <- any(grepl("roll call|yea-nay|recorded vote", actions_text))
  has_unanimous <- any(grepl("unanimous consent", actions_text))

  # Check for conference
  has_conference <- any(grepl("conference", actions_text))

  # Check if passed both chambers
  passed_house <- any(grepl("passed house|agreed to.*house|pass.*where.*h", actions_text))
  passed_senate <- any(grepl("passed senate|agreed to.*senate|pass.*where.*s", actions_text))

  # Sponsor info
  sponsor_party <- NA_character_
  if (!is.null(bill$sponsor) && !is.null(bill$sponsor$name)) {
    party_match <- regmatches(bill$sponsor$name, regexpr("\\[([RDI])", bill$sponsor$name))
    if (length(party_match) > 0) {
      sponsor_party <- gsub("\\[", "", party_match)
    }
  }

  # Related bills count
  n_related <- length(bill$related_bills)

  tibble(
    govtrack_id     = bill$id %||% NA_integer_,
    congress        = bill$congress %||% NA_integer_,
    bill_type       = bill$bill_type %||% NA_character_,
    number          = bill$number %||% NA_integer_,
    display_number  = bill$display_number %||% NA_character_,
    title           = bill$title_without_number %||% NA_character_,
    enacted_date    = bill$current_status_date %||% NA_character_,
    introduced_date = bill$introduced_date %||% NA_character_,
    sponsor_party   = sponsor_party,
    n_major_actions = n_actions,
    has_voice_vote  = has_voice_vote,
    has_roll_call   = has_roll_call,
    has_unanimous   = has_unanimous,
    has_conference  = has_conference,
    n_related_bills = n_related
  )
}

# --- Main fetch loop ---
all_laws <- list()

for (cong in session_dates$congress) {
  cat(sprintf("\nFetching Congress %d...\n", cong))

  # Fetch signed bills
  signed <- fetch_enacted_laws(cong, "enacted_signed")

  # Also fetch veto overrides (rare but should be included)
  veto <- fetch_enacted_laws(cong, "enacted_veto_override")

  combined <- c(signed, veto)
  cat(sprintf("  Congress %d: %d enacted laws total\n", cong, length(combined)))

  if (length(combined) > 0) {
    parsed <- map_dfr(combined, parse_bill)
    all_laws[[as.character(cong)]] <- parsed
  }

  Sys.sleep(1)  # Courtesy pause between Congresses
}

# --- Combine and save ---
laws_df <- bind_rows(all_laws) %>%
  mutate(
    enacted_date = as.Date(enacted_date),
    introduced_date = as.Date(introduced_date)
  ) %>%
  left_join(session_dates, by = "congress") %>%
  mutate(
    days_remaining    = as.integer(session_end - enacted_date),
    deliberation_days = as.integer(enacted_date - introduced_date),
    pct_session_elapsed = as.numeric(enacted_date - session_start) / session_length_days
  )

cat(sprintf("\n=== Total enacted laws fetched: %d ===\n", nrow(laws_df)))
cat(sprintf("Congresses: %d to %d\n", min(laws_df$congress), max(laws_df$congress)))
cat(sprintf("Date range: %s to %s\n", min(laws_df$enacted_date, na.rm=TRUE), max(laws_df$enacted_date, na.rm=TRUE)))

# Validate — no simulated data
stopifnot(nrow(laws_df) > 5000)
stopifnot(all(!is.na(laws_df$enacted_date)))
stopifnot(all(!is.na(laws_df$congress)))

saveRDS(laws_df, "../data/enacted_laws_raw.rds")
cat("Saved to data/enacted_laws_raw.rds\n")
