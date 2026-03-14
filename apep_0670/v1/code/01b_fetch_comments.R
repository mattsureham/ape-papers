## 01b_fetch_comments.R — Fetch comment counts from Regulations.gov
## apep_0670: Comment Period Length and Public Participation
## Runs AFTER 01_fetch_data.R (Stage 1 complete)

source("00_packages.R")

# Load .env for API key
env_file <- file.path(dirname(getwd()), "..", "..", "..", ".env")
if (!file.exists(env_file)) env_file <- here::here(".env")
if (file.exists(env_file)) {
  env_lines <- readLines(env_file)
  for (line in env_lines) {
    line <- trimws(line)
    if (nchar(line) == 0 || startsWith(line, "#")) next
    parts <- strsplit(line, "=", fixed = TRUE)[[1]]
    if (length(parts) >= 2) {
      key <- trimws(parts[1])
      val <- trimws(paste(parts[-1], collapse = "="))
      val <- gsub("^['\"]|['\"]$", "", val)
      do.call(Sys.setenv, setNames(list(val), key))
    }
  }
  cat("Loaded .env file\n")
}

reg_gov_key <- Sys.getenv("REGULATIONS_GOV_API_KEY")
stopifnot("REGULATIONS_GOV_API_KEY not found" = nchar(reg_gov_key) > 0)
cat(sprintf("API key loaded (first 5 chars: %s...)\n", substr(reg_gov_key, 1, 5)))

# Load rules from Stage 1
df_rules <- read_csv("../data/federal_register_proposed_rules.csv", show_col_types = FALSE)
cat(sprintf("Loaded %d rules from Stage 1\n", nrow(df_rules)))

# Filter to rules with valid docket IDs and comment periods
eligible <- df_rules |>
  filter(
    !is.na(docket_id), docket_id != "",
    !is.na(comment_days), comment_days >= 10, comment_days <= 180
  )

cat(sprintf("Eligible rules (docket + valid period): %d\n", nrow(eligible)))

# Stratified sample by period bin
set.seed(42)
eligible <- eligible |>
  mutate(period_bin = case_when(
    comment_days <= 30 ~ "short",
    comment_days <= 60 ~ "medium",
    TRUE ~ "long"
  ))

# Sample up to 200 per bin
sample_per_bin <- function(df, n_max = 200) {
  df |> slice_sample(n = min(n_max, nrow(df)))
}
sample_rules <- eligible |>
  group_by(period_bin) |>
  group_modify(~ sample_per_bin(.x, 200)) |>
  ungroup()

unique_dockets <- unique(sample_rules$docket_id)
cat(sprintf("Sampled %d rules -> %d unique dockets\n",
            nrow(sample_rules), length(unique_dockets)))

# Fetch function
fetch_comment_count <- function(docket_id, api_key) {
  tryCatch({
    resp <- request("https://api.regulations.gov/v4/documents") |>
      req_url_query(
        `filter[docketId]` = docket_id,
        `filter[documentType]` = "Public Submission",
        `page[size]` = 5,
        api_key = api_key
      ) |>
      req_retry(max_tries = 3, backoff = ~ 10) |>
      req_perform()

    body <- resp_body_json(resp)
    total <- body$meta$totalElements %||% 0L

    n_org <- 0L
    n_sampled <- 0L
    if (length(body$data) > 0) {
      for (d in body$data) {
        attrs <- d$attributes %||% list()
        n_sampled <- n_sampled + 1L
        if (!is.null(attrs$organization) && nchar(attrs$organization %||% "") > 0) {
          n_org <- n_org + 1L
        }
      }
    }

    tibble(
      docket_id = docket_id,
      total_comments = as.integer(total),
      sample_n_org = n_org,
      sample_n = n_sampled,
      status = "ok"
    )
  }, error = function(e) {
    tibble(
      docket_id = docket_id,
      total_comments = NA_integer_,
      sample_n_org = NA_integer_,
      sample_n = NA_integer_,
      status = paste0("error: ", conditionMessage(e))
    )
  })
}

# Fetch with rate limiting
cat(sprintf("\nFetching comment counts for %d dockets...\n", length(unique_dockets)))
cat("(~3.7s per request, estimated time: %.0f min)\n\n",
    length(unique_dockets) * 3.7 / 60)

comment_results <- list()
t_start <- Sys.time()

for (i in seq_along(unique_dockets)) {
  if (i %% 25 == 0 || i == 1) {
    elapsed <- as.numeric(difftime(Sys.time(), t_start, units = "mins"))
    remaining <- (length(unique_dockets) - i) * 3.7 / 60
    cat(sprintf("  Docket %d / %d (elapsed: %.1f min, remaining: ~%.1f min)\n",
                i, length(unique_dockets), elapsed, remaining))
  }

  comment_results[[i]] <- fetch_comment_count(unique_dockets[i], reg_gov_key)
  Sys.sleep(3.7)
}

df_comments <- bind_rows(comment_results)

n_ok <- sum(df_comments$status == "ok")
n_err <- sum(df_comments$status != "ok")
cat(sprintf("\nFetch complete: %d ok, %d errors\n", n_ok, n_err))

if (n_err > 0) {
  cat("Error examples:\n")
  df_comments |> filter(status != "ok") |> head(5) |> print()
}

stopifnot("Too many API errors" = n_ok > 30)

# Summary
cat("\nComment count summary:\n")
df_comments |>
  filter(status == "ok") |>
  summarise(
    n = n(),
    mean_comments = mean(total_comments),
    median_comments = median(total_comments),
    min_comments = min(total_comments),
    max_comments = max(total_comments),
    pct_zero = 100 * mean(total_comments == 0)
  ) |>
  print()

write_csv(df_comments, "../data/comment_counts.csv")
cat(sprintf("\nSaved to data/comment_counts.csv (%d rows)\n", nrow(df_comments)))
cat("=== Comment fetch complete ===\n")
