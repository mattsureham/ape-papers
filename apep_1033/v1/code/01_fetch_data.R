## 01_fetch_data.R — Fetch CDC NORS outbreak data via Socrata API
## APEP-1033: Pouring Risk — Raw Milk Legalization and Foodborne Illness

source("00_packages.R")

cat("=== Fetching CDC NORS Data ===\n")

## ---- NORS Socrata API ----
## Dataset: National Outbreak Reporting System (NORS)
## Socrata ID: 5xkq-dg7x
## URL: https://data.cdc.gov/resource/5xkq-dg7x.json

base_url <- "https://data.cdc.gov/resource/5xkq-dg7x.json"

## Paginated fetch — Socrata limits to 50K per request
all_records <- list()
offset <- 0
batch_size <- 50000
repeat {
  url <- paste0(base_url, "?$limit=", batch_size, "&$offset=", offset)
  cat("Fetching offset", offset, "...\n")
  resp <- GET(url, add_headers("Accept" = "application/json"))

  if (status_code(resp) != 200) {
    stop("NORS API returned status ", status_code(resp), ": ", content(resp, "text"))
  }

  batch <- fromJSON(content(resp, "text", encoding = "UTF-8"), flatten = TRUE)
  if (nrow(batch) == 0) break

  all_records[[length(all_records) + 1]] <- batch
  offset <- offset + batch_size

  if (nrow(batch) < batch_size) break
  Sys.sleep(1)  # polite rate limiting
}

nors_raw <- bind_rows(all_records)
cat("Total NORS records fetched:", nrow(nors_raw), "\n")

## Validate: should be ~66K records
stopifnot("Fewer than 10,000 NORS records — API may have changed" = nrow(nors_raw) >= 10000)

## Save raw data
write_csv(nors_raw, "../data/nors_raw.csv")
cat("Saved nors_raw.csv with", nrow(nors_raw), "rows and", ncol(nors_raw), "columns\n")
cat("Column names:", paste(names(nors_raw), collapse = ", "), "\n")

## ---- Examine dairy-related outbreaks ----
## Look for dairy/milk-related fields
cat("\n=== Examining fields for dairy identification ===\n")

## Check which columns contain food/commodity info
food_cols <- grep("food|commodity|ilfs|vehicle|etiol|genus|species|serotype",
                  names(nors_raw), ignore.case = TRUE, value = TRUE)
cat("Food/etiology related columns:", paste(food_cols, collapse = ", "), "\n")

## Check primary mode column
if ("primary_mode" %in% names(nors_raw)) {
  cat("\nPrimary modes:\n")
  print(table(nors_raw$primary_mode, useNA = "always"))
}

## Check for any column containing "milk" or "dairy" values
for (col in names(nors_raw)) {
  vals <- nors_raw[[col]]
  if (is.character(vals)) {
    n_dairy <- sum(grepl("milk|dairy|unpasteurized|raw milk", vals, ignore.case = TRUE),
                   na.rm = TRUE)
    if (n_dairy > 0) {
      cat(sprintf("Column '%s': %d dairy-related entries\n", col, n_dairy))
    }
  }
}

cat("\n=== Data fetch complete ===\n")
