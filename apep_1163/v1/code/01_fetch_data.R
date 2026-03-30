## 01_fetch_data.R — Fetch CMS Open Payments data for bunching analysis

source("00_packages.R")

# --- CMS Open Payments reporting thresholds (per-transaction) ---
thresholds <- data.table(
  program_year = 2018:2024,
  threshold = c(10.42, 10.61, 10.73, 10.97, 11.29, 11.84, 12.70)
)
cat("Per-transaction reporting thresholds:\n")
print(thresholds)

# --- Distribution IDs (verified with curl) ---
dist_ids <- list(
  "2018" = "7a14808c-b314-5bc5-b3ad-ddffdecf06dc",
  "2020" = "041183ca-2bac-5658-bcfd-8d7def273ca5",
  "2022" = "2042cd29-5b89-5a62-b922-11b9d6a43085",
  "2024" = "9323b84e-cda3-5f6b-a501-b76926c7c035"
)

# --- Fetch one year ---
fetch_year_api <- function(year_str, dist_id, n_pages = 320, batch_size = 500) {
  outfile <- sprintf("../data/payments_%s_api.rds", year_str)
  if (file.exists(outfile) && file.size(outfile) > 500) {
    cat(sprintf("  %s: cached\n", year_str))
    return(readRDS(outfile))
  }

  cat(sprintf("Fetching %s (%d pages x %d)...\n", year_str, n_pages, batch_size))
  amounts_list <- vector("list", n_pages)
  types_list <- vector("list", n_pages)
  total_fetched <- 0

  for (page in 1:n_pages) {
    offset <- (page - 1) * batch_size
    url <- sprintf(
      "https://openpaymentsdata.cms.gov/api/1/datastore/query/%s?limit=%d&offset=%d",
      dist_id, batch_size, offset
    )

    resp <- httr::GET(url, httr::timeout(120))
    sc <- httr::status_code(resp)

    if (sc != 200) {
      cat(sprintf("  HTTP %d at page %d, stopping\n", sc, page))
      break
    }

    raw_text <- httr::content(resp, as = "text", encoding = "UTF-8")
    parsed <- jsonlite::fromJSON(raw_text, flatten = TRUE)
    results <- parsed$results

    if (is.null(results) || !is.data.frame(results) || nrow(results) == 0) {
      cat(sprintf("  No results at page %d, stopping\n", page))
      break
    }

    n_rows <- nrow(results)
    total_fetched <- total_fetched + n_rows

    amt <- as.numeric(results$total_amount_of_payment_usdollars)
    typ <- results$nature_of_payment_or_transfer_of_value

    # Keep only $2-$30 range
    keep <- !is.na(amt) & amt >= 2 & amt <= 30
    amounts_list[[page]] <- amt[keep]
    types_list[[page]] <- typ[keep]

    if (page %% 20 == 0) {
      n_kept <- sum(sapply(amounts_list[1:page], length))
      cat(sprintf("  Page %d: %d fetched, %d in [$2,$30]\n", page, total_fetched, n_kept))
    }

    if (n_rows < batch_size) break
    Sys.sleep(0.15)
  }

  all_amounts <- unlist(amounts_list)
  all_types <- unlist(types_list)

  if (length(all_amounts) == 0) {
    cat(sprintf("  WARNING: No in-range records for %s after %d records\n", year_str, total_fetched))
    return(NULL)
  }

  df <- data.table(
    amount = all_amounts,
    nature = all_types,
    program_year = as.integer(year_str)
  )

  saveRDS(df, outfile)
  cat(sprintf("  %s: %d in [$2,$30] from %d total\n", year_str, nrow(df), total_fetched))
  return(df)
}

# --- Fetch 4 years ---
all_data <- list()
for (yr_str in names(dist_ids)) {
  df <- fetch_year_api(yr_str, dist_ids[[yr_str]], n_pages = 320, batch_size = 500)
  if (!is.null(df) && nrow(df) > 0) all_data[[yr_str]] <- df
}

if (length(all_data) == 0) {
  stop("FATAL: No data fetched from CMS Open Payments API. Cannot proceed.")
}

payments <- rbindlist(all_data, fill = TRUE)
cat(sprintf("\n=== TOTAL: %s records in [$2,$30] across %d years ===\n",
            format(nrow(payments), big.mark = ","), length(unique(payments$program_year))))

stopifnot("Too few records" = nrow(payments) > 500)

# --- Clean payment types ---
payments[, payment_type := fcase(
  grepl("Food and Beverage", nature, ignore.case = TRUE), "Food & Beverage",
  grepl("Consulting", nature, ignore.case = TRUE), "Consulting Fee",
  grepl("Compensation", nature, ignore.case = TRUE), "Compensation",
  grepl("Education", nature, ignore.case = TRUE), "Education",
  grepl("Travel", nature, ignore.case = TRUE), "Travel",
  grepl("Gift", nature, ignore.case = TRUE), "Gift",
  default = "Other"
)]

# --- Merge thresholds ---
payments <- merge(payments, thresholds, by = "program_year", all.x = TRUE)

# --- Save ---
saveRDS(payments, "../data/payments_raw.rds")
fwrite(thresholds, "../data/thresholds.csv")

cat("\nPayments by year:\n")
print(payments[, .(n = .N, mean_amt = round(mean(amount), 2),
                   median_amt = round(median(amount), 2)),
               by = program_year][order(program_year)])

cat("\nPayments by type:\n")
print(payments[, .N, by = payment_type][order(-N)])

cat("\nData saved to data/payments_raw.rds\n")
