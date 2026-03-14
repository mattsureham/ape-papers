## 01_fetch_data.R — Fetch proposed rules with comment counts from Federal Register API
## apep_0670: Comment Period Length and Public Participation
##
## Key insight: The FR API includes regulations_dot_gov_info.comments_count
## for each document, eliminating the need for separate Regulations.gov calls.

source("00_packages.R")

cat("============================================================\n")
cat("Fetching All Proposed Rules 2010-2023 (with comment counts)\n")
cat("============================================================\n")

base_url <- "https://www.federalregister.gov/api/v1/documents.json"
all_rules <- list()
page <- 1

# Request fields including regulations_dot_gov_info for comment counts
requested_fields <- c("document_number", "publication_date", "comments_close_on",
                      "page_length", "significant", "agencies", "cfr_references",
                      "regulation_id_numbers", "docket_ids", "action", "abstract",
                      "title", "regulations_dot_gov_info")

repeat {
  cat(sprintf("  Page %d... ", page))

  resp <- request(base_url) |>
    req_url_query(
      `conditions[type][]` = "PRORULE",
      `conditions[publication_date][gte]` = "2010-01-01",
      `conditions[publication_date][lte]` = "2023-12-31",
      per_page = 1000,
      page = page,
      .multi = "explode",
      `fields[]` = requested_fields
    ) |>
    req_retry(max_tries = 3, backoff = ~ 5) |>
    req_perform()

  body <- resp_body_json(resp)
  results <- body$results
  if (length(results) == 0) break

  all_rules <- c(all_rules, results)
  cat(sprintf("%d results (cumulative: %d / %d)\n",
              length(results), length(all_rules), body$count))

  if (is.null(body$next_page_url)) break
  page <- page + 1
  Sys.sleep(0.5)
}

cat(sprintf("\nTotal proposed rules fetched: %d\n", length(all_rules)))
stopifnot("No rules fetched" = length(all_rules) > 0)

# --- Parse into data frame ---
parse_rule <- function(r) {
  agencies <- r$agencies %||% list()
  docket_ids <- r$docket_ids %||% list()
  rin_list <- r$regulation_id_numbers %||% list()
  reg_info <- r$regulations_dot_gov_info %||% list()

  tibble(
    doc_number = r$document_number %||% NA_character_,
    title = r$title %||% NA_character_,
    pub_date = r$publication_date %||% NA_character_,
    comments_close = r$comments_close_on %||% NA_character_,
    page_length = as.integer(r$page_length %||% NA),
    significant = if (!is.null(r$significant)) as.logical(r$significant) else NA,
    action = r$action %||% NA_character_,
    abstract = substr(r$abstract %||% "", 1, 500),
    agency_name = if (length(agencies) > 0) agencies[[1]]$name %||% NA_character_ else NA_character_,
    agency_slug = if (length(agencies) > 0) agencies[[1]]$slug %||% NA_character_ else NA_character_,
    n_agencies = length(agencies),
    n_cfr_parts = length(r$cfr_references %||% list()),
    docket_id = if (length(docket_ids) > 0) docket_ids[[1]] else NA_character_,
    rin = if (length(rin_list) > 0) rin_list[[1]] else NA_character_,
    # Comment count from regulations.gov cross-reference
    reg_gov_comments = as.integer(reg_info$comments_count %||% NA),
    reg_gov_doc_id = reg_info$document_id %||% NA_character_,
    reg_gov_agency = reg_info$agency_id %||% NA_character_
  )
}

df_rules <- bind_rows(lapply(all_rules, parse_rule))

# Compute comment period length
df_rules <- df_rules |>
  mutate(
    pub_date = as.Date(pub_date),
    comments_close = as.Date(comments_close),
    comment_days = as.numeric(difftime(comments_close, pub_date, units = "days")),
    year = lubridate::year(pub_date)
  )

# Report
n_valid_period <- sum(!is.na(df_rules$comment_days) & df_rules$comment_days > 0)
n_valid_comments <- sum(!is.na(df_rules$reg_gov_comments))
n_both <- sum(!is.na(df_rules$comment_days) & df_rules$comment_days > 0 &
                !is.na(df_rules$reg_gov_comments))

cat(sprintf("\nParsed %d rules\n", nrow(df_rules)))
cat(sprintf("  With valid comment periods: %d (%.1f%%)\n", n_valid_period,
            100 * n_valid_period / nrow(df_rules)))
cat(sprintf("  With reg.gov comment counts: %d (%.1f%%)\n", n_valid_comments,
            100 * n_valid_comments / nrow(df_rules)))
cat(sprintf("  With BOTH: %d (%.1f%%)\n", n_both, 100 * n_both / nrow(df_rules)))

# Comment period distribution
valid <- df_rules |> filter(!is.na(comment_days), comment_days > 0, comment_days <= 365)
cat(sprintf("\nComment period: range %.0f-%.0f days, mean %.1f, median %.0f\n",
            min(valid$comment_days), max(valid$comment_days),
            mean(valid$comment_days), median(valid$comment_days)))

cat("\nDistribution:\n")
valid |>
  mutate(bin = case_when(
    comment_days < 30 ~ "< 30 days",
    comment_days == 30 ~ "= 30 days",
    comment_days %in% 31:45 ~ "31-45 days",
    comment_days %in% 46:60 ~ "46-60 days",
    comment_days %in% 61:90 ~ "61-90 days",
    TRUE ~ "> 90 days"
  )) |>
  count(bin) |>
  mutate(pct = sprintf("%.1f%%", 100 * n / sum(n))) |>
  print()

# Comment count distribution
both <- df_rules |> filter(!is.na(comment_days), comment_days > 0, !is.na(reg_gov_comments))
cat(sprintf("\nComment counts (N=%d):\n", nrow(both)))
cat(sprintf("  Mean: %.1f, Median: %d, Max: %s\n",
            mean(both$reg_gov_comments), median(both$reg_gov_comments),
            format(max(both$reg_gov_comments), big.mark = ",")))
cat(sprintf("  Zero comments: %d (%.1f%%)\n",
            sum(both$reg_gov_comments == 0), 100 * mean(both$reg_gov_comments == 0)))

stopifnot("Insufficient data" = n_both > 500)

# Save
write_csv(df_rules, "../data/federal_register_proposed_rules.csv")
cat(sprintf("\nSaved to data/ (%d rows)\n", nrow(df_rules)))
cat("=== Fetch complete ===\n")
