## 01_fetch_data.R — Fetch FDA NME approvals and FAERS adverse events
## APEP-0601: PDUFA Deadline Bunching and Drug Safety

source("code/00_packages.R")

cat("=== Step 1: Download FDA NME Compilation ===\n")

# FDA Novel Drug Approvals compilation
# Source: https://www.fda.gov/drugs/novel-drug-approvals-fda
nme_url <- "https://www.fda.gov/media/177921/download?attachment"
nme_file <- "data/nme_approvals_raw.xlsx"

if (!file.exists(nme_file)) {
  resp <- httr2::request(nme_url) |>
    httr2::req_headers("User-Agent" = "APEP-Research/1.0") |>
    httr2::req_timeout(120) |>
    httr2::req_perform()

  writeBin(httr2::resp_body_raw(resp), nme_file)
  cat("Downloaded NME file:", nme_file, "\n")
} else {
  cat("NME file already exists, skipping download.\n")
}

# Try reading as Excel first, fall back to CSV
nme <- tryCatch(
  {
    readxl::read_excel(nme_file)
  },
  error = function(e) {
    cat("Excel read failed, trying CSV...\n")
    read.csv(nme_file, stringsAsFactors = FALSE)
  }
)

stopifnot("NME data must have rows" = nrow(nme) > 100)
cat("NME records loaded:", nrow(nme), "\n")
cat("Columns:", paste(names(nme), collapse = ", "), "\n")

# Save raw NME data
saveRDS(nme, "data/nme_raw.rds")

cat("\n=== Step 2: Query openFDA FAERS for adverse events ===\n")

# We need to query FAERS for each approved drug's NDA number
# First, let's understand the NME data structure
cat("First few rows of NME data:\n")
print(head(nme, 3))

# Also fetch from College Scorecard-style bulk: the FDA Drugs@FDA API
# Try the openFDA drug event API to get adverse event counts by NDA number

# Function to query openFDA FAERS
query_faers <- function(nda_number, limit = 1000) {
  # Clean NDA number (remove leading zeros, "NDA" prefix, etc.)
  nda_clean <- gsub("[^0-9]", "", as.character(nda_number))

  base_url <- "https://api.fda.gov/drug/event.json"

  # Search for events matching this NDA number
  search_term <- paste0('patient.drug.openfda.application_number:"NDA', nda_clean, '"')

  tryCatch({
    resp <- httr2::request(base_url) |>
      httr2::req_url_query(
        search = search_term,
        count = "serious",
        limit = 10
      ) |>
      httr2::req_timeout(30) |>
      httr2::req_perform()

    result <- httr2::resp_body_json(resp)

    if (!is.null(result$results)) {
      df <- bind_rows(lapply(result$results, as.data.frame))
      df$nda_number <- nda_clean
      return(df)
    }
    return(NULL)
  }, error = function(e) {
    return(NULL)
  })
}

# Function to get total AE count for an NDA
get_ae_count <- function(nda_number) {
  nda_clean <- gsub("[^0-9]", "", as.character(nda_number))
  base_url <- "https://api.fda.gov/drug/event.json"
  search_term <- paste0('patient.drug.openfda.application_number:"NDA', nda_clean, '"')

  tryCatch({
    resp <- httr2::request(base_url) |>
      httr2::req_url_query(
        search = search_term,
        limit = 1
      ) |>
      httr2::req_timeout(30) |>
      httr2::req_perform()

    result <- httr2::resp_body_json(resp)
    total <- result$meta$results$total
    return(as.integer(total))
  }, error = function(e) {
    return(NA_integer_)
  })
}

# Function to get serious AE count for an NDA
get_serious_ae_count <- function(nda_number) {
  nda_clean <- gsub("[^0-9]", "", as.character(nda_number))
  base_url <- "https://api.fda.gov/drug/event.json"
  search_term <- paste0('patient.drug.openfda.application_number:"NDA',
                         nda_clean, '"+AND+serious:1')

  tryCatch({
    resp <- httr2::request(base_url) |>
      httr2::req_url_query(
        search = search_term,
        limit = 1
      ) |>
      httr2::req_timeout(30) |>
      httr2::req_perform()

    result <- httr2::resp_body_json(resp)
    total <- result$meta$results$total
    return(as.integer(total))
  }, error = function(e) {
    return(NA_integer_)
  })
}

# Function to get death AE count for an NDA
get_death_ae_count <- function(nda_number) {
  nda_clean <- gsub("[^0-9]", "", as.character(nda_number))
  base_url <- "https://api.fda.gov/drug/event.json"
  search_term <- paste0('patient.drug.openfda.application_number:"NDA',
                         nda_clean, '"+AND+seriousnessdeath:1')

  tryCatch({
    resp <- httr2::request(base_url) |>
      httr2::req_url_query(
        search = search_term,
        limit = 1
      ) |>
      httr2::req_timeout(30) |>
      httr2::req_perform()

    result <- httr2::resp_body_json(resp)
    total <- result$meta$results$total
    return(as.integer(total))
  }, error = function(e) {
    return(NA_integer_)
  })
}

# Function to get enforcement actions (recalls) for an NDA
get_recall_count <- function(nda_number) {
  nda_clean <- gsub("[^0-9]", "", as.character(nda_number))
  base_url <- "https://api.fda.gov/drug/enforcement.json"
  search_term <- paste0('openfda.application_number:"NDA', nda_clean, '"')

  tryCatch({
    resp <- httr2::request(base_url) |>
      httr2::req_url_query(
        search = search_term,
        limit = 1
      ) |>
      httr2::req_timeout(30) |>
      httr2::req_perform()

    result <- httr2::resp_body_json(resp)
    total <- result$meta$results$total
    return(as.integer(total))
  }, error = function(e) {
    return(NA_integer_)
  })
}

cat("Querying FAERS for each NDA number...\n")
cat("This will take several minutes due to API rate limits.\n\n")

# Extract NDA numbers from NME data
# Column names vary — detect them
nda_col <- grep("NDA|BLA|Application", names(nme), value = TRUE, ignore.case = TRUE)
cat("NDA column candidates:", paste(nda_col, collapse = ", "), "\n")

# Use the first matching column
nda_numbers <- unique(nme[[nda_col[1]]])
cat("Unique NDA/BLA numbers:", length(nda_numbers), "\n")

# Query FAERS for all NDA numbers
# Rate limit: ~240 requests/minute without API key
ae_results <- data.frame(
  nda_number = character(),
  total_ae = integer(),
  serious_ae = integer(),
  death_ae = integer(),
  recall_count = integer(),
  stringsAsFactors = FALSE
)

ae_cache_file <- "data/faers_cache.rds"
if (file.exists(ae_cache_file)) {
  ae_results <- readRDS(ae_cache_file)
  cat("Loaded cached FAERS results:", nrow(ae_results), "drugs\n")
}

# Only query NDA numbers we haven't cached
cached_ndas <- ae_results$nda_number
remaining <- setdiff(gsub("[^0-9]", "", as.character(nda_numbers)), cached_ndas)
cat("Remaining NDA numbers to query:", length(remaining), "\n")

batch_size <- 50
for (i in seq_along(remaining)) {
  nda <- remaining[i]

  total <- get_ae_count(nda)
  Sys.sleep(0.3)  # rate limiting

  serious <- get_serious_ae_count(nda)
  Sys.sleep(0.3)

  death <- get_death_ae_count(nda)
  Sys.sleep(0.3)

  recalls <- get_recall_count(nda)
  Sys.sleep(0.3)

  ae_results <- bind_rows(ae_results, data.frame(
    nda_number = nda,
    total_ae = total,
    serious_ae = serious,
    death_ae = death,
    recall_count = recalls,
    stringsAsFactors = FALSE
  ))

  if (i %% batch_size == 0) {
    cat(sprintf("  Queried %d/%d NDA numbers...\n", i, length(remaining)))
    saveRDS(ae_results, ae_cache_file)
  }
}

# Final save
saveRDS(ae_results, ae_cache_file)
cat("\nFAERS query complete. Total drugs with AE data:",
    sum(!is.na(ae_results$total_ae)), "\n")

cat("\n=== Step 3: Query openFDA Drug Labeling for safety updates ===\n")

# Get labeling/safety label change counts per NDA
get_label_count <- function(nda_number) {
  nda_clean <- gsub("[^0-9]", "", as.character(nda_number))
  base_url <- "https://api.fda.gov/drug/label.json"
  search_term <- paste0('openfda.application_number:"NDA', nda_clean, '"')

  tryCatch({
    resp <- httr2::request(base_url) |>
      httr2::req_url_query(
        search = search_term,
        limit = 1
      ) |>
      httr2::req_timeout(30) |>
      httr2::req_perform()

    result <- httr2::resp_body_json(resp)

    # Check for boxed warning
    has_boxed <- FALSE
    if (length(result$results) > 0) {
      label <- result$results[[1]]
      if (!is.null(label$boxed_warning)) {
        has_boxed <- TRUE
      }
    }

    total <- result$meta$results$total
    return(list(label_versions = as.integer(total), has_boxed_warning = has_boxed))
  }, error = function(e) {
    return(list(label_versions = NA_integer_, has_boxed_warning = NA))
  })
}

# Query label data for all drugs
label_cache_file <- "data/label_cache.rds"
if (file.exists(label_cache_file)) {
  label_results <- readRDS(label_cache_file)
  cat("Loaded cached label results:", nrow(label_results), "drugs\n")
} else {
  label_results <- data.frame(
    nda_number = character(),
    label_versions = integer(),
    has_boxed_warning = logical(),
    stringsAsFactors = FALSE
  )
}

cached_label_ndas <- label_results$nda_number
remaining_labels <- setdiff(gsub("[^0-9]", "", as.character(nda_numbers)), cached_label_ndas)
cat("Remaining NDA numbers for label query:", length(remaining_labels), "\n")

for (i in seq_along(remaining_labels)) {
  nda <- remaining_labels[i]
  result <- get_label_count(nda)
  Sys.sleep(0.3)

  label_results <- bind_rows(label_results, data.frame(
    nda_number = nda,
    label_versions = result$label_versions,
    has_boxed_warning = result$has_boxed_warning,
    stringsAsFactors = FALSE
  ))

  if (i %% batch_size == 0) {
    cat(sprintf("  Queried %d/%d label records...\n", i, length(remaining_labels)))
    saveRDS(label_results, label_cache_file)
  }
}

saveRDS(label_results, label_cache_file)
cat("Label query complete. Drugs with label data:",
    sum(!is.na(label_results$label_versions)), "\n")

cat("\n=== All data fetched successfully ===\n")
cat("Files saved in data/:\n")
cat("  - nme_raw.rds (NME compilation)\n")
cat("  - faers_cache.rds (adverse event counts)\n")
cat("  - label_cache.rds (label/boxed warning data)\n")
