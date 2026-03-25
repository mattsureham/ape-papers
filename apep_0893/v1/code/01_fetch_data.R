## 01_fetch_data.R — Fetch Federal Register rulemaking data
## Source: Federal Register API (https://www.federalregister.gov/developers/api/v1)
## No API key required.

source("00_packages.R")

DATA_DIR <- "../data"
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

# ---------------------------------------------------------------------------
# Helper: fetch all pages from Federal Register API
# ---------------------------------------------------------------------------
fetch_fr_documents <- function(doc_type, year_start = 2008, year_end = 2024) {
  base_url <- "https://www.federalregister.gov/api/v1/documents.json"

  all_docs <- list()
  page <- 1
  total_pages <- 1

  # Fields we need
  fields <- paste0(
    "fields[]=document_number&fields[]=type&fields[]=title",
    "&fields[]=publication_date&fields[]=agencies",
    "&fields[]=regulation_id_numbers&fields[]=significant",
    "&fields[]=action&fields[]=docket_ids"
  )

  cat(sprintf("Fetching %s documents (%d-%d)...\n", doc_type, year_start, year_end))

  while (page <= total_pages) {
    url <- sprintf(
      "%s?%s&conditions[type][]=%s&conditions[publication_date][gte]=%d-01-01&conditions[publication_date][lte]=%d-12-31&per_page=1000&page=%d",
      base_url, fields, doc_type, year_start, year_end, page
    )

    resp <- tryCatch({
      req <- request(url) |> req_retry(max_tries = 3, backoff = ~ 2)
      resp_body_json(req_perform(req))
    }, error = function(e) {
      stop(sprintf("API request failed on page %d: %s", page, e$message))
    })

    if (is.null(resp$results) || length(resp$results) == 0) {
      stop(sprintf("No results returned on page %d for %s", page, doc_type))
    }

    total_pages <- resp$total_pages %||% 1
    all_docs <- c(all_docs, resp$results)

    if (page %% 10 == 0 || page == 1) {
      cat(sprintf("  Page %d/%d (%d docs so far)\n", page, total_pages, length(all_docs)))
    }

    page <- page + 1
    Sys.sleep(0.5)  # respect rate limits
  }

  cat(sprintf("  Done: %d %s documents fetched.\n", length(all_docs), doc_type))
  return(all_docs)
}

# ---------------------------------------------------------------------------
# Parse documents into tibble
# ---------------------------------------------------------------------------
parse_docs <- function(docs, doc_label) {
  parsed <- map_dfr(docs, function(d) {
    agency_slugs <- paste(map_chr(d$agencies %||% list(), ~ .x$slug %||% "unknown"), collapse = ";")
    agency_ids <- paste(map_chr(d$agencies %||% list(), ~ as.character(.x$id %||% 0)), collapse = ";")

    rin_list <- d$regulation_id_numbers %||% list()
    rins <- tryCatch({
      if (length(rin_list) == 0) {
        ""
      } else if (is.character(rin_list)) {
        paste(rin_list, collapse = ";")
      } else {
        paste(map_chr(rin_list, function(r) {
          if (is.character(r)) r
          else if (is.list(r)) r$regulation_id_number %||% ""
          else as.character(r)
        }), collapse = ";")
      }
    }, error = function(e) "")
    docket_ids <- paste(d$docket_ids %||% character(0), collapse = ";")

    tibble(
      document_number = d$document_number %||% NA_character_,
      type             = d$type %||% NA_character_,
      title            = d$title %||% NA_character_,
      publication_date = d$publication_date %||% NA_character_,
      agency_slugs     = agency_slugs,
      agency_ids       = agency_ids,
      rins             = rins,
      docket_ids       = docket_ids,
      significant      = d$significant %||% FALSE,
      action           = d$action %||% NA_character_
    )
  })

  parsed$publication_date <- as.Date(parsed$publication_date)
  cat(sprintf("Parsed %d %s records.\n", nrow(parsed), doc_label))
  return(parsed)
}

# ---------------------------------------------------------------------------
# Fetch Proposed Rules and Final Rules (year-by-year to avoid 10k cap)
# ---------------------------------------------------------------------------
cat("\n=== Fetching year-by-year to avoid API 10k limit ===\n")

fetch_by_year <- function(doc_type, year_start, year_end) {
  all_raw <- list()
  for (yr in year_start:year_end) {
    cat(sprintf("\n--- %s year %d ---\n", doc_type, yr))
    yr_docs <- fetch_fr_documents(doc_type, yr, yr)
    all_raw <- c(all_raw, yr_docs)
    cat(sprintf("  Cumulative: %d documents\n", length(all_raw)))
  }
  return(all_raw)
}

proposed_raw <- fetch_by_year("PRORULE", 2008, 2024)
rule_raw     <- fetch_by_year("RULE", 2008, 2024)

proposed_df <- parse_docs(proposed_raw, "Proposed Rule")
rule_df     <- parse_docs(rule_raw, "Final Rule")

# Validate we got real data
stopifnot("No proposed rules fetched" = nrow(proposed_df) > 1000)
stopifnot("No final rules fetched" = nrow(rule_df) > 1000)

cat(sprintf("\nProposed Rules: %d\n", nrow(proposed_df)))
cat(sprintf("Final Rules: %d\n", nrow(rule_df)))
cat(sprintf("Date range (NPRM): %s to %s\n",
            min(proposed_df$publication_date, na.rm = TRUE),
            max(proposed_df$publication_date, na.rm = TRUE)))

# ---------------------------------------------------------------------------
# Save raw data
# ---------------------------------------------------------------------------
saveRDS(proposed_df, file.path(DATA_DIR, "proposed_rules.rds"))
saveRDS(rule_df, file.path(DATA_DIR, "final_rules.rds"))

write_csv(proposed_df, file.path(DATA_DIR, "proposed_rules.csv"))
write_csv(rule_df, file.path(DATA_DIR, "final_rules.csv"))

cat("\nData saved to data/proposed_rules.rds and data/final_rules.rds\n")
cat("Fetch complete.\n")
