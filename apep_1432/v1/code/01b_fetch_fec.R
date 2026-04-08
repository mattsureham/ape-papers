## 01b_fetch_fec.R — Fetch FEC small-dollar contributions for top protest cities
## apep_1432: Protests and Campaign Contributions (Weather IV)
## Strategy: query top 50 protest cities × 3 two-year cycles, cap at 500 records per query

source("00_packages.R")

ccc <- fread("../data/ccc_protests.csv") %>% as_tibble()

fec_key <- Sys.getenv("FEC_API_KEY", unset = "DEMO_KEY")

## Top protest cities
city_counts <- ccc %>%
  count(city_state, sort = TRUE) %>%
  filter(n >= 50)

## Extract city name and state
city_counts <- city_counts %>%
  mutate(
    city_upper = toupper(sub(",.*", "", city_state)),
    state = sub(".*,\\s*", "", city_state)
  )

## Take top 30 cities, 2 periods (2020 and 2022 — core analysis window)
top_cities <- head(city_counts, 30)
periods <- c(2020, 2022)

total_queries <- nrow(top_cities) * length(periods)
cat(sprintf("Fetching FEC data: %d cities x %d periods = %d queries\n",
            nrow(top_cities), length(periods), total_queries), flush = TRUE)

fec_data <- list()
query_num <- 0

for (p in periods) {
  for (j in seq_len(nrow(top_cities))) {
    query_num <- query_num + 1

    ## Build URL
    city_enc <- URLencode(top_cities$city_upper[j], reserved = TRUE)
    url <- sprintf(
      "https://api.open.fec.gov/v1/schedules/schedule_a/?api_key=%s&contributor_city=%s&contributor_state=%s&two_year_transaction_period=%d&max_amount=200&min_amount=1&per_page=100",
      fec_key, city_enc, top_cities$state[j], p
    )

    resp <- tryCatch(
      {
        Sys.sleep(0.4)
        r <- GET(url)
        content(r, as = "parsed")
      },
      error = function(e) NULL
    )

    if (!is.null(resp) && length(resp$results) > 0) {
      ## Get first page results
      page1 <- map_dfr(resp$results, ~ tibble(
        contributor_city = .x$contributor_city %||% NA_character_,
        contributor_state = .x$contributor_state %||% NA_character_,
        contribution_receipt_date = .x$contribution_receipt_date %||% NA_character_,
        contribution_receipt_amount = .x$contribution_receipt_amount %||% NA_real_,
        committee_name = .x$committee_name %||% NA_character_,
        contributor_name = .x$contributor_name %||% NA_character_
      ))
      fec_data[[query_num]] <- page1

      ## Get up to 4 more pages (500 total per city-period)
      last_idx <- resp$pagination$last_indexes$last_index
      last_dt <- resp$pagination$last_indexes$last_contribution_receipt_date
      for (pg in 2:5) {
        if (is.null(last_idx)) break
        url2 <- sprintf(
          "%s&last_index=%s&last_contribution_receipt_date=%s",
          url, last_idx, last_dt
        )
        resp2 <- tryCatch(
          {
            Sys.sleep(0.4)
            r2 <- GET(url2)
            content(r2, as = "parsed")
          },
          error = function(e) NULL
        )
        if (is.null(resp2) || length(resp2$results) == 0) break
        page_n <- map_dfr(resp2$results, ~ tibble(
          contributor_city = .x$contributor_city %||% NA_character_,
          contributor_state = .x$contributor_state %||% NA_character_,
          contribution_receipt_date = .x$contribution_receipt_date %||% NA_character_,
          contribution_receipt_amount = .x$contribution_receipt_amount %||% NA_real_,
          committee_name = .x$committee_name %||% NA_character_,
          contributor_name = .x$contributor_name %||% NA_character_
        ))
        fec_data[[length(fec_data) + 1]] <- page_n
        last_idx <- resp2$pagination$last_indexes$last_index
        last_dt <- resp2$pagination$last_indexes$last_contribution_receipt_date
      }
    }

    if (query_num %% 10 == 0) {
      n_so_far <- sum(sapply(fec_data, nrow))
      cat(sprintf("  Query %d/%d (%s, %d): %d contributions so far\n",
                  query_num, total_queries, top_cities$city_upper[j], p, n_so_far),
          flush = TRUE)
    }
  }
}

fec_df <- bind_rows(fec_data)
cat(sprintf("\nFEC raw contributions: %d rows\n", nrow(fec_df)), flush = TRUE)

if (nrow(fec_df) == 0) {
  stop("FATAL: FEC API returned zero contributions. Cannot proceed.")
}

## Clean
fec_df <- fec_df %>%
  mutate(
    contribution_date = as.Date(contribution_receipt_date),
    city = str_to_title(trimws(contributor_city)),
    state = toupper(trimws(contributor_state)),
    city_state = paste0(city, ", ", state),
    amount = as.numeric(contribution_receipt_amount)
  ) %>%
  filter(!is.na(contribution_date), !is.na(amount), amount > 0, amount <= 200)

cat(sprintf("FEC cleaned: %d contributions, %d cities\n",
            nrow(fec_df), n_distinct(fec_df$city_state)), flush = TRUE)

fwrite(fec_df, "../data/fec_contributions.csv")
cat("Saved FEC contributions.\n")
