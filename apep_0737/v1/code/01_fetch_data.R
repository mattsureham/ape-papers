## 01_fetch_data.R — Fetch FDIC bank financial data
## Uses FDIC BankFind Suite API for quarterly total assets
## Source: https://banks.data.fdic.gov/api/

source("00_packages.R")

cat("=== Fetching FDIC bank data via BankFind Suite API ===\n")

# --- Configuration ---
# We need quarterly total asset data for FDIC-insured institutions
# FDIC API provides institution-level financial data
# Key variable: ASSET (total assets in thousands)
# Date range: 2001Q1 to 2024Q4

base_url <- "https://banks.data.fdic.gov/api/financials"

# Fetch in annual batches to manage API limits
# FDIC financials endpoint returns call report data
# REPDTE format: YYYYMMDD (end of quarter: 0331, 0630, 0930, 1231)

all_data <- list()
batch <- 0

for (year in 2001:2024) {
  for (qtr_end in c("0331", "0630", "0930", "1231")) {
    repdte <- paste0(year, qtr_end)
    batch <- batch + 1

    # Only fetch banks with assets between $1B and $25B (bunching window + buffer)
    # ASSET field is in thousands, so $1B = 1000000, $25B = 25000000
    url <- paste0(
      base_url,
      "?filters=REPDTE%3A", repdte,
      "%20AND%20ASSET%3A%5B1000000%20TO%2025000000%5D",
      "&fields=REPDTE,CERT,REPNM,ASSET,STNAME,SPECGRP,SUBCHAPS,INSTCAT",
      "&limit=10000",
      "&sort_by=ASSET",
      "&sort_order=ASC"
    )

    response <- tryCatch(
      {
        resp <- httr::GET(url, httr::timeout(60))
        if (httr::status_code(resp) != 200) {
          stop(paste("HTTP", httr::status_code(resp), "for", repdte))
        }
        resp
      },
      error = function(e) {
        stop(paste("FATAL: API fetch failed for", repdte, ":", e$message))
      }
    )

    content <- httr::content(response, as = "text", encoding = "UTF-8")
    parsed <- jsonlite::fromJSON(content)

    if (is.null(parsed$data) || length(parsed$data) == 0) {
      cat(sprintf("  WARNING: No data for %s\n", repdte))
      next
    }

    # FDIC API nests: parsed$data is a DF with columns "data" (nested DF) and "score"
    # Extract the nested data frame directly
    raw_df <- parsed$data$data
    if (is.null(raw_df) || !is.data.frame(raw_df)) {
      # Fallback: try flattening
      raw_df <- as.data.frame(parsed$data)
      names(raw_df) <- sub("^data[.]", "", names(raw_df))
      raw_df$score <- NULL
    }
    raw_df$repdte_raw <- repdte
    # Drop ID column if present
    raw_df$ID <- NULL
    all_data[[batch]] <- raw_df

    cat(sprintf("  %s: %d banks fetched\n", repdte, nrow(raw_df)))

    Sys.sleep(0.3)  # Rate limiting
  }
}

# Combine all quarters
bank_data <- bind_rows(all_data)

cat(sprintf("\n=== Total records fetched: %s ===\n", format(nrow(bank_data), big.mark = ",")))

# Validate: we must have real data
stopifnot("FATAL: No data fetched from FDIC API" = nrow(bank_data) > 0)
stopifnot("FATAL: ASSET column missing" = "ASSET" %in% names(bank_data))

# --- Clean and standardize ---
# Handle potentially missing columns
if (!"REPNM" %in% names(bank_data)) bank_data$REPNM <- NA_character_
if (!"INSTCAT" %in% names(bank_data)) bank_data$INSTCAT <- NA_character_
if (!"SPECGRP" %in% names(bank_data)) bank_data$SPECGRP <- NA_character_
if (!"STNAME" %in% names(bank_data)) bank_data$STNAME <- NA_character_
# Drop ID column if present
bank_data$ID <- NULL

bank_data <- bank_data %>%
  mutate(
    # ASSET is in thousands; convert to billions
    total_assets_B = as.numeric(ASSET) / 1e6,
    cert = as.character(CERT),
    bank_name = REPNM,
    state = STNAME,
    spec_group = SPECGRP,
    inst_category = INSTCAT,
    # Parse date
    year = as.integer(substr(repdte_raw, 1, 4)),
    quarter = case_when(
      substr(repdte_raw, 5, 8) == "0331" ~ 1L,
      substr(repdte_raw, 5, 8) == "0630" ~ 2L,
      substr(repdte_raw, 5, 8) == "0930" ~ 3L,
      substr(repdte_raw, 5, 8) == "1231" ~ 4L
    ),
    yearq = year + (quarter - 1) / 4,
    # Period indicators
    period = case_when(
      year <= 2009 ~ "pre_dodd_frank",
      year >= 2011 & year <= 2017 ~ "post_dodd_frank",
      year >= 2019 ~ "post_egrrcpa",
      TRUE ~ "transition"
    )
  ) %>%
  select(cert, bank_name, state, total_assets_B, year, quarter, yearq,
         period, spec_group, inst_category)

# Validate data quality
cat(sprintf("\nUnique banks: %d\n", n_distinct(bank_data$cert)))
cat(sprintf("Date range: %d Q%d to %d Q%d\n",
            min(bank_data$year), min(bank_data$quarter[bank_data$year == min(bank_data$year)]),
            max(bank_data$year), max(bank_data$quarter[bank_data$year == max(bank_data$year)])))
cat(sprintf("Banks in $5B-$15B window (all periods): %d obs\n",
            sum(bank_data$total_assets_B >= 5 & bank_data$total_assets_B <= 15)))

# Final validation
stopifnot("FATAL: Too few banks in bunching window" =
            sum(bank_data$total_assets_B >= 5 & bank_data$total_assets_B <= 15) > 1000)

# Save
saveRDS(bank_data, "../data/bank_data.rds")
cat("\nData saved to data/bank_data.rds\n")
