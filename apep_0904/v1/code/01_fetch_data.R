# 01_fetch_data.R — Fetch federal contract data from USAspending.gov
# Uses $10K bins to reduce API calls; adds rate limiting

source("00_packages.R")

# Set working directory to project root
PROJ_DIR <- normalizePath(file.path(getwd(), ".."))
DATA_DIR <- file.path(PROJ_DIR, "data")
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

# --- Configuration ---
BIN_WIDTH <- 10000   # $10K bins (reduces API calls)
MIN_AMOUNT <- 50000
MAX_AMOUNT <- 400000
FISCAL_YEARS <- 2008:2025

# --- Helper: Count contracts in a bin for a fiscal year ---
count_contracts_in_bin <- function(fy, lower, upper, retries = 5) {
  body <- list(
    filters = list(
      time_period = list(
        list(
          start_date = sprintf("%d-10-01", fy - 1),
          end_date = sprintf("%d-09-30", fy)
        )
      ),
      award_type_codes = list("A", "B", "C", "D"),
      award_amounts = list(
        list(
          lower_bound = lower,
          upper_bound = upper
        )
      )
    )
  )

  for (attempt in seq_len(retries)) {
    result <- tryCatch({
      resp <- httr::POST(
        "https://api.usaspending.gov/api/v2/search/spending_by_award_count/",
        body = jsonlite::toJSON(body, auto_unbox = TRUE),
        httr::content_type_json(),
        httr::timeout(90)
      )

      if (httr::status_code(resp) != 200) {
        stop(sprintf("HTTP %d", httr::status_code(resp)))
      }

      content <- httr::content(resp, as = "parsed")
      count <- 0
      if (!is.null(content$results$contracts)) {
        count <- content$results$contracts
      }
      return(count)
    }, error = function(e) {
      if (attempt == retries) {
        stop(sprintf("Failed after %d attempts for FY%d $%d-$%d: %s",
                     retries, fy, lower, upper, e$message))
      }
      wait_time <- 2^attempt
      cat(sprintf("[retry %d, wait %ds] ", attempt, wait_time))
      Sys.sleep(wait_time)
      return(NULL)
    })

    if (!is.null(result)) return(result)
  }
}

# --- Main: Build binned density ---
bins <- seq(MIN_AMOUNT, MAX_AMOUNT - BIN_WIDTH, by = BIN_WIDTH)
n_bins <- length(bins)

cat(sprintf("Fetching contract counts: %d bins x %d years = %d API calls\n",
            n_bins, length(FISCAL_YEARS), n_bins * length(FISCAL_YEARS)))
cat(sprintf("Bin width: $%s, Range: $%s-$%s\n",
            format(BIN_WIDTH, big.mark = ","),
            format(MIN_AMOUNT, big.mark = ","),
            format(MAX_AMOUNT, big.mark = ",")))

# Check for existing partial data
partial_file <- file.path(DATA_DIR, "contract_bins_partial.csv")
if (file.exists(partial_file)) {
  existing <- fread(partial_file)
  completed_fy <- unique(existing$fiscal_year)
  cat(sprintf("Resuming: %d FYs already complete\n", length(completed_fy)))
  all_data <- existing
} else {
  completed_fy <- integer(0)
  all_data <- data.table()
}

for (fy in FISCAL_YEARS) {
  if (fy %in% completed_fy) {
    cat(sprintf("FY%d: skipped (already done)\n", fy))
    next
  }

  cat(sprintf("FY%d: ", fy))
  fy_counts <- numeric(n_bins)

  for (i in seq_along(bins)) {
    lower <- bins[i]
    upper <- lower + BIN_WIDTH - 1

    fy_counts[i] <- count_contracts_in_bin(fy, lower, upper)
    Sys.sleep(1.5)  # Rate limit — USAspending.gov drops connections if too fast

    if (i %% 10 == 0) cat(".")
  }

  fy_dt <- data.table(
    fiscal_year = fy,
    bin_lower = bins,
    bin_upper = bins + BIN_WIDTH,
    bin_midpoint = bins + BIN_WIDTH / 2,
    count = fy_counts
  )
  all_data <- rbindlist(list(all_data, fy_dt))

  # Save intermediate
  fwrite(all_data, partial_file)

  cat(sprintf(" total = %s contracts\n", format(sum(fy_counts), big.mark = ",")))
}

# --- Validation ---
stopifnot("No data fetched" = nrow(all_data) > 0)
stopifnot("Zero total contracts" = sum(all_data$count) > 0)

total_contracts <- sum(all_data$count)
cat(sprintf("\nTotal contracts: %s across %d FYs\n",
            format(total_contracts, big.mark = ","), length(FISCAL_YEARS)))

# Print density around key thresholds as sanity check
cat("\n--- Density around $150K threshold (FY2018, pre-move) ---\n")
check <- all_data[fiscal_year == 2018 & bin_lower >= 120000 & bin_lower <= 180000]
print(check[, .(bin_lower, bin_upper, count)])

cat("\n--- Density around $250K threshold (FY2024, post-move) ---\n")
check <- all_data[fiscal_year == 2024 & bin_lower >= 220000 & bin_lower <= 280000]
print(check[, .(bin_lower, bin_upper, count)])

# --- Save final ---
fwrite(all_data, file.path(DATA_DIR, "contract_bins.csv"))
if (file.exists(partial_file)) file.remove(partial_file)

cat("\nData saved to data/contract_bins.csv\n")
