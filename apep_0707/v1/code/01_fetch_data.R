# 01_fetch_data.R — Fetch EPC data for MEES bunching analysis
# Sources: GOV.UK Live Tables D1 and D4B (ODS)

source("00_packages.R")

out_dir <- "../data"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# PART 1: GOV.UK EPC Live Tables (aggregate band counts)
# ============================================================================

cat("=== Fetching GOV.UK Live Tables ===\n")

# Live Table D1: EPC bands by Local Authority, quarterly
# Updated Jan 2026
d1_url <- "https://assets.publishing.service.gov.uk/media/697a1426ed48165466652fde/D1-_Domestic_Properties.ods"
d1_file <- file.path(out_dir, "live_table_d1.ods")

download.file(d1_url, d1_file, mode = "wb", quiet = FALSE)
stopifnot("D1 download failed" = file.exists(d1_file) && file.size(d1_file) > 10000)
cat("D1 downloaded:", file.size(d1_file), "bytes\n")

# Live Table D4B: Transaction type breakdown
d4b_url <- "https://assets.publishing.service.gov.uk/media/697a12953c71d838df6bd3c7/D4B-_Domestic_Properties.ods"
d4b_file <- file.path(out_dir, "live_table_d4b.ods")

download.file(d4b_url, d4b_file, mode = "wb", quiet = FALSE)
stopifnot("D4B download failed" = file.exists(d4b_file) && file.size(d4b_file) > 10000)
cat("D4B downloaded:", file.size(d4b_file), "bytes\n")

# ============================================================================
# PART 2: Read D1 — band counts by LA and quarter
# ============================================================================

cat("\n=== Reading D1 Live Tables ===\n")

d1_sheets <- readODS::list_ods_sheets(d1_file)
cat("D1 sheets:", paste(d1_sheets, collapse = ", "), "\n")

# Read each sheet to find the data with band breakdowns
for (i in seq_along(d1_sheets)) {
  cat("\nSheet", i, "(", d1_sheets[i], "):\n")
  d1_sheet <- tryCatch(
    readODS::read_ods(d1_file, sheet = i, range = "A1:Z5"),
    error = function(e) NULL
  )
  if (!is.null(d1_sheet)) {
    cat("  Dims:", nrow(d1_sheet), "x", ncol(d1_sheet), "\n")
    cat("  Cols:", paste(head(names(d1_sheet), 12), collapse = ", "), "\n")
  }
}

# Read the full data from the main data sheet (typically sheet 2 or the one with LA data)
# Try reading sheet with most data
best_sheet <- NULL
best_rows <- 0

for (i in seq_along(d1_sheets)) {
  d1_test <- tryCatch(
    readODS::read_ods(d1_file, sheet = i),
    error = function(e) data.frame()
  )
  if (nrow(d1_test) > best_rows) {
    best_rows <- nrow(d1_test)
    best_sheet <- i
  }
}

cat("\nBest D1 sheet:", best_sheet, "with", best_rows, "rows\n")
d1_raw <- readODS::read_ods(d1_file, sheet = best_sheet)
d1_dt <- as.data.table(d1_raw)

cat("D1 columns:", paste(names(d1_dt), collapse = ", "), "\n")
print(head(d1_dt, 10))

fwrite(d1_dt, file.path(out_dir, "d1_clean.csv"))

# ============================================================================
# PART 3: Read D4B — transaction type breakdown
# ============================================================================

cat("\n=== Reading D4B Live Tables ===\n")

d4b_sheets <- readODS::list_ods_sheets(d4b_file)
cat("D4B sheets:", paste(d4b_sheets, collapse = ", "), "\n")

for (i in seq_along(d4b_sheets)) {
  cat("\nSheet", i, "(", d4b_sheets[i], "):\n")
  d4b_sheet <- tryCatch(
    readODS::read_ods(d4b_file, sheet = i, range = "A1:Z5"),
    error = function(e) NULL
  )
  if (!is.null(d4b_sheet)) {
    cat("  Dims:", nrow(d4b_sheet), "x", ncol(d4b_sheet), "\n")
    cat("  Cols:", paste(head(names(d4b_sheet), 12), collapse = ", "), "\n")
  }
}

# Find best D4B sheet
best_sheet_d4b <- NULL
best_rows_d4b <- 0

for (i in seq_along(d4b_sheets)) {
  d4b_test <- tryCatch(
    readODS::read_ods(d4b_file, sheet = i),
    error = function(e) data.frame()
  )
  if (nrow(d4b_test) > best_rows_d4b) {
    best_rows_d4b <- nrow(d4b_test)
    best_sheet_d4b <- i
  }
}

cat("\nBest D4B sheet:", best_sheet_d4b, "with", best_rows_d4b, "rows\n")
d4b_raw <- readODS::read_ods(d4b_file, sheet = best_sheet_d4b)
d4b_dt <- as.data.table(d4b_raw)

cat("D4B columns:", paste(names(d4b_dt), collapse = ", "), "\n")
print(head(d4b_dt, 10))

fwrite(d4b_dt, file.path(out_dir, "d4b_clean.csv"))

# ============================================================================
# PART 4: Attempt EPC Open Data API for individual scores
# ============================================================================

cat("\n=== Attempting EPC Open Data API ===\n")

# The API requires Basic auth with email:api-key
epc_email <- Sys.getenv("EPC_EMAIL")
epc_key <- Sys.getenv("EPC_API_KEY")

if (nchar(epc_email) > 0 && nchar(epc_key) > 0) {
  auth_token <- base64enc::base64encode(charToRaw(paste0(epc_email, ":", epc_key)))
  cat("EPC credentials found, attempting API access...\n")
} else {
  cat("No EPC_EMAIL/EPC_API_KEY in environment.\n")
  cat("Attempting API without auth...\n")
  auth_token <- NULL
}

# Test the API
epc_base <- "https://epc.opendatacommunities.org/api/v1/domestic/search"

headers <- c(Accept = "text/csv")
if (!is.null(auth_token)) {
  headers["Authorization"] <- paste("Basic", auth_token)
}

test_resp <- tryCatch({
  resp <- httr::GET(
    epc_base,
    httr::add_headers(.headers = headers),
    query = list(
      postcode = "SW1A 1AA",
      size = 10
    )
  )
  cat("EPC API status:", httr::status_code(resp), "\n")

  if (httr::status_code(resp) == 200) {
    content_text <- httr::content(resp, as = "text", encoding = "UTF-8")
    epc_test <- fread(text = content_text)
    cat("EPC API returned", nrow(epc_test), "rows\n")
    cat("Columns:", paste(head(names(epc_test), 20), collapse = ", "), "\n")
    if ("current-energy-efficiency" %in% names(epc_test)) {
      cat("Score field confirmed! Range:",
          range(epc_test$`current-energy-efficiency`, na.rm = TRUE), "\n")
    }
    TRUE
  } else {
    cat("API returned status", httr::status_code(resp),
        "- will use aggregate data approach\n")
    FALSE
  }
}, error = function(e) {
  cat("EPC API failed:", e$message, "\n")
  FALSE
})

if (isTRUE(test_resp)) {
  cat("\n=== Fetching individual EPC records for large LAs ===\n")

  # Major English LAs with large rental sectors
  target_las <- c(
    "E09000001", "E09000007", "E09000012", "E09000013",
    "E09000019", "E09000020", "E09000022", "E09000025",
    "E09000028", "E09000030", "E09000032", "E09000033",
    "E08000003", "E08000025", "E08000033",
    "E06000023", "E06000015", "E06000014",
    "E07000178", "E07000032", "E07000026"
  )

  all_epc <- list()

  for (la in target_las) {
    cat("Fetching LA:", la, "... ")
    search_after <- NULL
    la_chunks <- list()
    total <- 0

    repeat {
      query_params <- list(
        `local-authority` = la,
        size = 5000
      )
      if (!is.null(search_after)) {
        query_params[["search-after"]] <- search_after
      }

      resp <- tryCatch({
        httr::GET(
          epc_base,
          httr::add_headers(.headers = headers),
          query = query_params
        )
      }, error = function(e) NULL)

      if (is.null(resp) || httr::status_code(resp) != 200) break

      content_text <- httr::content(resp, as = "text", encoding = "UTF-8")
      chunk <- tryCatch(fread(text = content_text), error = function(e) data.table())
      if (nrow(chunk) == 0) break

      la_chunks[[length(la_chunks) + 1]] <- chunk
      total <- total + nrow(chunk)

      # Get pagination token
      next_after <- httr::headers(resp)$`x-next-search-after`
      if (is.null(next_after) || nchar(next_after) == 0) break
      search_after <- next_after

      # Cap at 100K per LA
      if (total >= 100000) break

      Sys.sleep(0.3)
    }

    if (length(la_chunks) > 0) {
      la_dt <- rbindlist(la_chunks, fill = TRUE)
      # Keep only needed columns
      keep_cols <- intersect(
        c("current-energy-efficiency", "current-energy-rating",
          "transaction-type", "lodgement-datetime", "local-authority",
          "property-type", "built-form", "total-floor-area",
          "construction-age-band"),
        names(la_dt)
      )
      la_dt <- la_dt[, ..keep_cols]
      all_epc[[la]] <- la_dt
    }

    cat(total, "records\n")
  }

  if (length(all_epc) > 0) {
    epc_dt <- rbindlist(all_epc, fill = TRUE)
    cat("\nTotal EPC records:", nrow(epc_dt), "\n")
    cat("Score range:", range(epc_dt$`current-energy-efficiency`, na.rm = TRUE), "\n")
    cat("Transaction types:\n")
    print(table(epc_dt$`transaction-type`, useNA = "ifany"))

    fwrite(epc_dt, file.path(out_dir, "epc_individual.csv"))
    cat("Saved individual EPC data:", nrow(epc_dt), "records\n")
  }
} else {
  cat("\nEPC API not available. Analysis will use aggregate band-level data.\n")
  cat("For score-level bunching, we'll construct synthetic distributions from\n")
  cat("published statistics on EPC score distributions.\n")
}

# ============================================================================
# PART 5: Summary
# ============================================================================

cat("\n=== Data fetch complete ===\n")
cat("Files in data directory:\n")
for (f in list.files(out_dir, full.names = TRUE)) {
  cat(sprintf("  %s (%s KB)\n", basename(f), round(file.size(f) / 1024, 1)))
}
