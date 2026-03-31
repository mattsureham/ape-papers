# 01_fetch_data.R — Fetch FRA Form 54 accident data via Socrata API
# APEP-1194: Positive Train Control and Railroad Accident Prevention

source("00_packages.R")

# ---- Socrata API: FRA Rail Equipment Accident/Incident Data ----
# Endpoint: data.transportation.gov/resource/85tf-25kj.json
# No API key required. 223,913+ records.

base_url <- "https://data.transportation.gov/resource/85tf-25kj.json"

# Fetch in pages of 50,000 (Socrata limit)
all_records <- list()
offset <- 0
page_size <- 50000
total_fetched <- 0

cat("Fetching FRA Form 54 data from Socrata API...\n")

repeat {
  url <- paste0(base_url, "?$limit=", format(page_size, scientific = FALSE),
                "&$offset=", format(offset, scientific = FALSE),
                "&$order=:id")

  resp <- httr::GET(url, httr::timeout(120))

  if (httr::status_code(resp) != 200) {
    stop("API request failed with status ", httr::status_code(resp),
         ": ", httr::content(resp, "text"))
  }

  page_data <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"),
                                   flatten = TRUE)

  if (nrow(page_data) == 0) break

  all_records[[length(all_records) + 1]] <- page_data
  total_fetched <- total_fetched + nrow(page_data)
  cat(sprintf("  Fetched %d records (total: %d)\n", nrow(page_data), total_fetched))

  if (nrow(page_data) < page_size) break
  offset <- offset + page_size

  Sys.sleep(1)  # Be polite to API
}

raw_df <- bind_rows(all_records)
cat(sprintf("\nTotal records fetched: %d\n", nrow(raw_df)))

# ---- Validate data ----
stopifnot("Data fetch returned zero records" = nrow(raw_df) > 0)
stopifnot("Missing reportingrailroadcode" = "reportingrailroadcode" %in% names(raw_df))
stopifnot("Missing date field" = "date" %in% names(raw_df))

# Check for key fields
expected_fields <- c("reportingrailroadcode", "date", "accidentcausecode",
                     "totalpersonskilled", "totalpersonsinjured", "totaldamagecost")
missing_fields <- setdiff(expected_fields, names(raw_df))
if (length(missing_fields) > 0) {
  stop("Missing critical fields: ", paste(missing_fields, collapse = ", "))
}

cat("\nColumn names:\n")
cat(paste(names(raw_df), collapse = "\n"))
cat("\n")

# ---- Save raw data ----
saveRDS(raw_df, "../data/fra_form54_raw.rds")
cat(sprintf("\nSaved raw data: %d records, %d columns\n", nrow(raw_df), ncol(raw_df)))

# ---- Quick diagnostics ----
cat("\nDate range:", min(raw_df$date, na.rm = TRUE), "to", max(raw_df$date, na.rm = TRUE), "\n")
cat("Unique railroads:", n_distinct(raw_df$reportingrailroadcode), "\n")

# Check PTC indicators in adjunct fields
ptc_fields <- grep("adjunct", names(raw_df), value = TRUE, ignore.case = TRUE)
cat("\nAdjunct fields found:", paste(ptc_fields, collapse = ", "), "\n")

for (field in ptc_fields) {
  ptc_count <- sum(grepl("PTC|Positive Train Control|ptc", raw_df[[field]],
                         ignore.case = TRUE), na.rm = TRUE)
  cat(sprintf("  %s: %d PTC records\n", field, ptc_count))
}

cat("\nData fetch complete.\n")
