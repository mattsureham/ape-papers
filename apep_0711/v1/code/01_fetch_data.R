## 01_fetch_data.R — Fetch CDC provisional suicide estimates
## apep_0711: Online sports betting and suicide mortality
##
## Data source: CDC Early Model-Based Provisional Estimates
## Dataset: v2g4-wqg2 on data.cdc.gov
## REAL DATA ONLY — no simulated fallbacks.

source("00_packages.R")

cat("=== Fetching CDC Provisional Suicide Estimates ===\n")

## --- 1. Download CDC state-week provisional estimates ---
## The Socrata API on data.cdc.gov supports $limit and $offset
## We request all rows with outcome = "Suicide" from dataset v2g4-wqg2

base_url <- "https://data.cdc.gov/resource/v2g4-wqg2.csv"
limit <- 50000
offset <- 0
all_data <- list()
page <- 1

repeat {
  url <- paste0(base_url, "?$limit=", limit, "&$offset=", offset,
                "&$where=outcome%3D%27Suicide%27")
  cat("Fetching page", page, "offset", offset, "...\n")

  result <- tryCatch(
    read.csv(url, stringsAsFactors = FALSE),
    error = function(e) {
      stop("CDC API request failed: ", conditionMessage(e))
    }
  )

  if (is.null(result) || nrow(result) == 0) break

  cat("  Got", nrow(result), "rows\n")
  all_data[[page]] <- result

  if (nrow(result) < limit) break
  offset <- offset + limit
  page <- page + 1
}

if (length(all_data) == 0) {
  stop("FATAL: No data returned from CDC API. Cannot proceed without real data.")
}

cdc_raw <- bind_rows(all_data)
cat("Total CDC suicide rows:", nrow(cdc_raw), "\n")
cat("Columns:", paste(names(cdc_raw), collapse = ", "), "\n")

## Validate we got real data
stopifnot("No rows returned" = nrow(cdc_raw) > 1000)

## Save raw data
write_csv(cdc_raw, "../data/cdc_suicide_raw.csv")
cat("Saved cdc_suicide_raw.csv:", nrow(cdc_raw), "rows\n")

## --- 2. Also fetch transportation deaths as placebo ---
cat("\n=== Fetching CDC Provisional Transport Death Estimates ===\n")

offset <- 0
all_transport <- list()
page <- 1

repeat {
  url <- paste0(base_url, "?$limit=", limit, "&$offset=", offset,
                "&$where=outcome%3D%27Transport%20accidents%27")
  cat("Fetching transport page", page, "...\n")

  result <- tryCatch(
    read.csv(url, stringsAsFactors = FALSE),
    error = function(e) {
      stop("CDC API request failed for transport: ", conditionMessage(e))
    }
  )

  if (is.null(result) || nrow(result) == 0) break
  all_transport[[page]] <- result
  if (nrow(result) < limit) break
  offset <- offset + limit
  page <- page + 1
}

if (length(all_transport) == 0) {
  cat("WARNING: No transport death data returned. Trying alternative outcome name...\n")
  # Try with different outcome name
  offset <- 0
  page <- 1
  repeat {
    url <- paste0(base_url, "?$limit=", limit, "&$offset=", offset,
                  "&$where=outcome%3D%27Accidents%20(unintentional%20injuries)%27")
    cat("Fetching accidents page", page, "...\n")
    result <- tryCatch(
      read.csv(url, stringsAsFactors = FALSE),
      error = function(e) {
        stop("CDC API request failed for accidents: ", conditionMessage(e))
      }
    )
    if (is.null(result) || nrow(result) == 0) break
    all_transport[[page]] <- result
    if (nrow(result) < limit) break
    offset <- offset + limit
    page <- page + 1
  }
}

if (length(all_transport) > 0) {
  transport_raw <- bind_rows(all_transport)
  write_csv(transport_raw, "../data/cdc_transport_raw.csv")
  cat("Saved cdc_transport_raw.csv:", nrow(transport_raw), "rows\n")
} else {
  cat("WARNING: No transport/accident placebo data found. Will proceed without.\n")
}

cat("\n=== Data fetch complete ===\n")
