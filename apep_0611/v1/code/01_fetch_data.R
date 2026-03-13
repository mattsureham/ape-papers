## 01_fetch_data.R — Fetch final rules from Federal Register API
## APEP paper apep_0611: CRA Lookback Cutoff and Midnight Rulemaking
##
## Fetches ALL final rules from 1999-2025 via the Federal Register API.
## No authentication required. JSON responses, paginated at 1000/page.

source("00_packages.R")

# ── Federal Register API ─────────────────────────────────────────────
# Endpoint: https://www.federalregister.gov/api/v1/documents.json
# Filter: type = RULE (final rules)
# Fields: document_number, publication_date, agencies, significant,
#         start_page, end_page, page_length, title, cfr_references,
#         regulation_id_numbers, type, subtype, action

base_url <- "https://www.federalregister.gov/api/v1/documents.json"

# Fetch all final rules in yearly chunks to avoid API timeout
all_rules <- list()

for (yr in 1999:2025) {
  cat(sprintf("Fetching year %d...\n", yr))
  page <- 1
  year_rules <- list()

  repeat {
    url <- paste0(
      base_url,
      "?conditions[type][]=RULE",
      "&conditions[publication_date][year]=", yr,
      "&fields[]=document_number",
      "&fields[]=publication_date",
      "&fields[]=title",
      "&fields[]=agencies",
      "&fields[]=significant",
      "&fields[]=start_page",
      "&fields[]=end_page",
      "&fields[]=page_length",
      "&fields[]=cfr_references",
      "&fields[]=regulation_id_numbers",
      "&fields[]=action",
      "&fields[]=subtype",
      "&per_page=1000",
      "&page=", page
    )

    resp <- GET(url, timeout(60))

    if (status_code(resp) != 200) {
      warning(sprintf("HTTP %d for year %d, page %d", status_code(resp), yr, page))
      break
    }

    json <- content(resp, as = "text", encoding = "UTF-8")
    parsed <- fromJSON(json, flatten = TRUE)

    if (is.null(parsed$results) || length(parsed$results) == 0) break

    results <- as_tibble(parsed$results)
    year_rules[[page]] <- results

    # Check pagination
    total_pages <- parsed$total_pages %||% 1
    if (page >= total_pages) break
    page <- page + 1

    Sys.sleep(0.3) # Be polite to the API

  }

  if (length(year_rules) > 0) {
    yr_df <- bind_rows(year_rules)
    yr_df$fetch_year <- yr
    all_rules[[as.character(yr)]] <- yr_df
    cat(sprintf("  Year %d: %d rules fetched\n", yr, nrow(yr_df)))
  } else {
    cat(sprintf("  Year %d: 0 rules fetched\n", yr))
  }
}

# Combine all years
rules_raw <- bind_rows(all_rules)

cat(sprintf("\nTotal rules fetched: %d\n", nrow(rules_raw)))
cat(sprintf("Date range: %s to %s\n",
            min(rules_raw$publication_date, na.rm = TRUE),
            max(rules_raw$publication_date, na.rm = TRUE)))

# ── Basic cleaning ───────────────────────────────────────────────────
rules_raw <- rules_raw %>%
  mutate(
    pub_date = as.Date(publication_date),
    significant = as.logical(significant),
    page_length = as.numeric(page_length)
  )

# Extract primary agency name (agencies is a list-column)
rules_raw$agency_name <- sapply(rules_raw$agencies, function(a) {
  if (is.data.frame(a) && nrow(a) > 0) {
    a$name[1]
  } else if (is.list(a) && length(a) > 0) {
    a[[1]]$name %||% NA_character_
  } else {
    NA_character_
  }
})

# Count CFR references per rule
rules_raw$n_cfr_parts <- sapply(rules_raw$cfr_references, function(r) {
  if (is.data.frame(r)) nrow(r)
  else if (is.list(r)) length(r)
  else 0L
})

cat(sprintf("Significant rules: %d (%.1f%%)\n",
            sum(rules_raw$significant, na.rm = TRUE),
            100 * mean(rules_raw$significant, na.rm = TRUE)))

# ── Save raw data ────────────────────────────────────────────────────
# Select columns to save (drop complex list columns)
rules_save <- rules_raw %>%
  select(document_number, pub_date, title, agency_name,
         significant, page_length, n_cfr_parts, action, subtype)

saveRDS(rules_save, "../data/fr_rules_raw.rds")
write_csv(rules_save, "../data/fr_rules_raw.csv")
cat(sprintf("Saved %d rules to data/fr_rules_raw.rds\n", nrow(rules_save)))

# ── Validation assertions ────────────────────────────────────────────
stopifnot("No rules fetched" = nrow(rules_save) > 0)
stopifnot("Expected at least 50,000 rules" = nrow(rules_save) > 50000)
stopifnot("Missing publication dates" = sum(is.na(rules_save$pub_date)) < 100)

cat("\n01_fetch_data.R completed successfully.\n")
