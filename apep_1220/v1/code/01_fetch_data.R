## 01_fetch_data.R — Fetch data from Statistics Denmark API
## apep_1220: Denmark Property Tax Reform and Housing Market Lock-in
##
## All data from api.statbank.dk (no registration required)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# Helper: fetch from Statistics Denmark API
# ============================================================

fetch_dst <- function(table_id, variables, label = table_id) {
  cat(sprintf("\n=== Fetching %s (%s) ===\n", label, table_id))

  # Build the API request body
  body <- list(
    table = table_id,
    format = "CSV",
    variables = variables
  )

  url <- "https://api.statbank.dk/v1/data"
  resp <- httr::POST(
    url,
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    httr::content_type_json(),
    httr::timeout(120)
  )

  if (httr::status_code(resp) != 200) {
    cat(sprintf("  ERROR: HTTP %d\n", httr::status_code(resp)))
    cat(sprintf("  Response: %s\n", substr(httr::content(resp, as = "text"), 1, 500)))
    return(NULL)
  }

  raw <- httr::content(resp, as = "text", encoding = "UTF-8")
  df <- read.csv(text = raw, sep = ";", stringsAsFactors = FALSE, check.names = FALSE)
  cat(sprintf("  Rows: %d, Columns: %d\n", nrow(df), ncol(df)))
  cat(sprintf("  Columns: %s\n", paste(names(df), collapse = ", ")))
  if (nrow(df) > 0) {
    print(head(df, 3))
  }

  return(df)
}

# First, let's explore available tables to understand the variable codes
explore_table <- function(table_id) {
  cat(sprintf("\n=== Exploring table %s ===\n", table_id))
  url <- sprintf("https://api.statbank.dk/v1/tableinfo/%s?format=JSON", table_id)
  resp <- httr::GET(url, httr::timeout(30))
  if (httr::status_code(resp) != 200) {
    cat(sprintf("  ERROR: HTTP %d\n", httr::status_code(resp)))
    return(NULL)
  }
  info <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"),
                             simplifyVector = FALSE)
  cat(sprintf("  Description: %s\n", info$description))
  for (v in info$variables) {
    val_ids <- sapply(v$values, function(x) x$id)
    val_texts <- sapply(v$values, function(x) x$text)
    n_vals <- length(val_ids)
    cat(sprintf("  Variable '%s' (%s): %d values\n", v$id, v$text, n_vals))
    if (n_vals <= 15) {
      for (i in seq_len(n_vals)) {
        cat(sprintf("    %s = %s\n", val_ids[i], val_texts[i]))
      }
    } else {
      for (i in 1:5) {
        cat(sprintf("    %s = %s\n", val_ids[i], val_texts[i]))
      }
      cat(sprintf("    ... (%d more)\n", n_vals - 5))
    }
  }
  return(info)
}

# ============================================================
# STEP 1: Explore table structures
# ============================================================

cat("\n========================================\n")
cat("STEP 1: Exploring table structures\n")
cat("========================================\n")

# Key tables from the idea manifest
tables_to_explore <- c("EJDSK2", "EJENEU", "TVANG3")

table_info <- list()
for (tbl in tables_to_explore) {
  table_info[[tbl]] <- explore_table(tbl)
}

# Also check LABY22 and ESKAT
table_info[["LABY22"]] <- explore_table("LABY22")
table_info[["ESKAT"]] <- explore_table("ESKAT")

# ============================================================
# Helper: extract all variable IDs from table info and fetch
# ============================================================

fetch_all_from_info <- function(tbl_id, tinfo, label, save_name) {
  cat(sprintf("\n========================================\n"))
  cat(sprintf("Fetching %s (%s)\n", label, tbl_id))
  cat(sprintf("========================================\n"))

  if (is.null(tinfo)) {
    cat("  Table info is NULL, skipping\n")
    return(NULL)
  }

  vars <- list()
  for (v in tinfo$variables) {
    val_ids <- sapply(v$values, function(x) x$id)
    vars[[length(vars) + 1]] <- list(code = v$id, values = val_ids)
  }

  df <- fetch_dst(tbl_id, vars, label)
  if (!is.null(df) && nrow(df) > 0) {
    saveRDS(df, file.path(data_dir, save_name))
    cat(sprintf("  Saved %s: %d rows\n", save_name, nrow(df)))
  }
  return(df)
}

# ============================================================
# STEPS 2-6: Fetch all core tables
# ============================================================

ejdsk2_df <- fetch_all_from_info("EJDSK2", table_info[["EJDSK2"]],
  "Grundskyld rates", "ejdsk2_grundskyld.rds")

ejeneu_df <- fetch_all_from_info("EJENEU", table_info[["EJENEU"]],
  "House Price Index", "ejeneu_hpi.rds")

tvang3_df <- fetch_all_from_info("TVANG3", table_info[["TVANG3"]],
  "Forced sales", "tvang3_forced_sales.rds")

laby22_df <- fetch_all_from_info("LABY22", table_info[["LABY22"]],
  "Prices + first-time buyers", "laby22_prices.rds")

eskat_df <- fetch_all_from_info("ESKAT", table_info[["ESKAT"]],
  "Property taxes", "eskat_taxes.rds")

# ============================================================
# STEP 7: Additional housing tables
# ============================================================

cat("\n========================================\n")
cat("STEP 7: Additional housing tables\n")
cat("========================================\n")

for (tbl in c("BM011", "BM010", "EJ131")) {
  tinfo <- explore_table(tbl)
  if (!is.null(tinfo)) {
    fetch_all_from_info(tbl, tinfo, tbl, sprintf("%s.rds", tolower(tbl)))
  }
}

# ============================================================
# STEP 8: Summary
# ============================================================

cat("\n========================================\n")
cat("DATA FETCH SUMMARY\n")
cat("========================================\n")

files <- list.files(data_dir, pattern = "\\.rds$", full.names = TRUE)
total_rows <- 0
for (f in files) {
  df <- readRDS(f)
  total_rows <- total_rows + nrow(df)
  cat(sprintf("  %s: %d rows (%.1f KB)\n", basename(f), nrow(df), file.size(f)/1e3))
}
cat(sprintf("\nTotal: %d files, %d rows\n", length(files), total_rows))

if (length(files) < 3) {
  stop("FATAL: Fewer than 3 data files fetched. Cannot proceed with analysis.")
}

cat("\nData fetch complete.\n")
