# 01_fetch_data.R — Fetch CMS ASP Pricing Files + FDA Orange Book + Part B Spending
# apep_1346: The Lag Windfall

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# =============================================================================
# Part 1: Medicare Quarterly Part B Spending by Drug (HCPCS-level)
# =============================================================================
cat("=== Fetching Medicare Quarterly Part B Spending by Drug ===\n")

# Quarterly spending at HCPCS level — has claims, beneficiaries, spending per quarter
partb_q_url <- "https://data.cms.gov/sites/default/files/2026-01/bc1a311b-a338-4205-be8c-0afef9adc475/QDD_PTB_EXP_QTR_QTD202502_280126.csv"
partb_q_resp <- GET(partb_q_url, timeout(300))

if (status_code(partb_q_resp) != 200) {
  stop("FATAL: Cannot fetch Quarterly Part B Spending data. Status: ", status_code(partb_q_resp))
}

partb_q_raw <- content(partb_q_resp, as = "text", encoding = "UTF-8")
partb_q <- fread(text = partb_q_raw)
cat("Quarterly Part B spending:", nrow(partb_q), "rows,", ncol(partb_q), "columns\n")
cat("Columns:", paste(names(partb_q), collapse = ", "), "\n")
fwrite(partb_q, file.path(data_dir, "partb_quarterly_spending.csv"))

# =============================================================================
# Part 2: Medicare Annual Part B Spending by Drug
# =============================================================================
cat("\n=== Fetching Medicare Annual Part B Spending by Drug ===\n")

partb_a_url <- "https://data.cms.gov/sites/default/files/2025-05/f52d5fcd-8d93-481d-9173-6219813e4efb/DSD_PTB_RY25_P06_V10_DYT23_HCPCS-%20250430.csv"
partb_a_resp <- GET(partb_a_url, timeout(300))

if (status_code(partb_a_resp) != 200) {
  stop("FATAL: Cannot fetch Annual Part B Spending data. Status: ", status_code(partb_a_resp))
}

partb_a_raw <- content(partb_a_resp, as = "text", encoding = "UTF-8")
partb_a <- fread(text = partb_a_raw)
cat("Annual Part B spending:", nrow(partb_a), "rows,", ncol(partb_a), "columns\n")
cat("Columns:", paste(names(partb_a), collapse = ", "), "\n")
fwrite(partb_a, file.path(data_dir, "partb_annual_spending.csv"))

# =============================================================================
# Part 3: CMS ASP Quarterly Drug Pricing Files (2017-2024)
# =============================================================================
cat("\n=== Fetching ASP Quarterly Drug Pricing Files ===\n")

# Two URL patterns: old (pre-2020) and new (2020+)
month_names <- c("january", "april", "july", "october")
Month_Names <- c("January", "April", "July", "October")

asp_all <- list()
fetch_count <- 0

for (yr in 2017:2024) {
  for (qtr in 1:4) {
    quarter_label <- paste0(yr, "Q", qtr)

    # Try new URL pattern first (2020+)
    url_new <- sprintf("https://www.cms.gov/files/zip/%s-%d-asp-pricing-file.zip",
                       month_names[qtr], yr)
    # Old URL pattern (pre-2020)
    url_old <- sprintf("https://www.cms.gov/Medicare/Medicare-Fee-for-Service-Part-B-Drugs/McrPartBDrugAvgSalesPrice/Downloads/%d-%s-ASP-Pricing-File.zip",
                       yr, Month_Names[qtr])

    downloaded <- FALSE
    for (url in c(url_new, url_old)) {
      resp <- tryCatch(GET(url, timeout(30)), error = function(e) NULL)
      if (!is.null(resp) && status_code(resp) == 200) {
        zip_path <- file.path(data_dir, sprintf("asp_%s.zip", quarter_label))
        writeBin(content(resp, as = "raw"), zip_path)

        extract_dir <- file.path(data_dir, sprintf("asp_%s", quarter_label))
        dir.create(extract_dir, showWarnings = FALSE)
        tryCatch(unzip(zip_path, exdir = extract_dir), error = function(e) NULL)

        files <- list.files(extract_dir, pattern = "\\.(xlsx|xls|csv)$",
                           full.names = TRUE, recursive = TRUE)
        if (length(files) > 0) {
          f <- files[1]
          df_q <- tryCatch({
            if (grepl("\\.csv$", f, ignore.case = TRUE)) {
              fread(f)
            } else {
              # Excel files often have metadata rows at top
              raw <- read_excel(f)
              # Check if first row looks like header
              if (any(grepl("HCPCS", names(raw), ignore.case = TRUE))) {
                as.data.table(raw)
              } else {
                # Try skipping rows
                for (skip in c(4, 6, 8, 10)) {
                  raw2 <- tryCatch(read_excel(f, skip = skip), error = function(e) NULL)
                  if (!is.null(raw2) && any(grepl("HCPCS", names(raw2), ignore.case = TRUE))) {
                    break
                  }
                  raw2 <- NULL
                }
                if (!is.null(raw2)) as.data.table(raw2) else as.data.table(raw)
              }
            }
          }, error = function(e) {
            cat(sprintf("  ! %s: read error: %s\n", quarter_label, e$message))
            NULL
          })

          if (!is.null(df_q) && nrow(df_q) > 0) {
            df_q[, asp_year := yr]
            df_q[, asp_quarter := qtr]
            asp_all[[quarter_label]] <- df_q
            fetch_count <- fetch_count + 1
            cat(sprintf("  ✓ %s: %d rows\n", quarter_label, nrow(df_q)))
            downloaded <- TRUE
          }
        }
        break
      }
    }
    if (!downloaded) {
      cat(sprintf("  ✗ %s: not found\n", quarter_label))
    }
  }
}

cat(sprintf("\nFetched %d quarterly ASP pricing files\n", fetch_count))

if (fetch_count == 0) {
  stop("FATAL: No ASP pricing files could be downloaded.")
}

# Save individual quarter files for inspection
for (label in names(asp_all)) {
  fwrite(asp_all[[label]], file.path(data_dir, sprintf("asp_%s.csv", label)))
}

# =============================================================================
# Part 4: FDA Orange Book — Generic Drug Approvals
# =============================================================================
cat("\n=== Fetching FDA Orange Book ===\n")

ob_url <- "https://www.fda.gov/media/76860/download"
ob_resp <- GET(ob_url, timeout(120), config(followlocation = TRUE))

if (status_code(ob_resp) == 200) {
  ob_zip <- file.path(data_dir, "orange_book.zip")
  writeBin(content(ob_resp, as = "raw"), ob_zip)
  ob_dir <- file.path(data_dir, "orange_book")
  dir.create(ob_dir, showWarnings = FALSE)
  unzip(ob_zip, exdir = ob_dir)

  # Read products file
  ob_files <- list.files(ob_dir, pattern = "product", full.names = TRUE,
                        recursive = TRUE, ignore.case = TRUE)
  if (length(ob_files) > 0) {
    ob_products <- fread(ob_files[1], fill = TRUE)
    cat("Orange Book products:", nrow(ob_products), "rows\n")
    cat("Columns:", paste(names(ob_products), collapse = ", "), "\n")
    fwrite(ob_products, file.path(data_dir, "orange_book_products.csv"))
  } else {
    cat("No product file found in Orange Book ZIP\n")
    cat("Files in ZIP:", paste(list.files(ob_dir, recursive = TRUE), collapse = ", "), "\n")
  }

  # Read patent/exclusivity files
  ob_excl <- list.files(ob_dir, pattern = "exclus", full.names = TRUE,
                       recursive = TRUE, ignore.case = TRUE)
  if (length(ob_excl) > 0) {
    exclusivity <- fread(ob_excl[1], fill = TRUE)
    cat("Exclusivity data:", nrow(exclusivity), "rows\n")
    fwrite(exclusivity, file.path(data_dir, "orange_book_exclusivity.csv"))
  }

  ob_pat <- list.files(ob_dir, pattern = "patent", full.names = TRUE,
                      recursive = TRUE, ignore.case = TRUE)
  if (length(ob_pat) > 0) {
    patents <- fread(ob_pat[1], fill = TRUE)
    cat("Patent data:", nrow(patents), "rows\n")
    fwrite(patents, file.path(data_dir, "orange_book_patents.csv"))
  }
} else {
  stop("FATAL: Cannot fetch FDA Orange Book. Status: ", status_code(ob_resp))
}

# =============================================================================
# Part 5: NDC-HCPCS Crosswalk
# =============================================================================
cat("\n=== Fetching NDC-HCPCS Crosswalk ===\n")

ndc_url <- "https://www.cms.gov/files/zip/2024-asp-ndc-hcpcs-crosswalk.zip"
ndc_resp <- GET(ndc_url, timeout(60))

if (status_code(ndc_resp) == 200) {
  ndc_zip <- file.path(data_dir, "ndc_hcpcs_crosswalk.zip")
  writeBin(content(ndc_resp, as = "raw"), ndc_zip)
  ndc_dir <- file.path(data_dir, "ndc_crosswalk")
  dir.create(ndc_dir, showWarnings = FALSE)
  unzip(ndc_zip, exdir = ndc_dir)

  xwalk_files <- list.files(ndc_dir, pattern = "\\.(xlsx|xls|csv)$",
                           full.names = TRUE, recursive = TRUE)
  if (length(xwalk_files) > 0) {
    xwalk <- tryCatch(
      as.data.table(read_excel(xwalk_files[1])),
      error = function(e) fread(xwalk_files[1])
    )
    cat("NDC-HCPCS crosswalk:", nrow(xwalk), "rows\n")
    fwrite(xwalk, file.path(data_dir, "ndc_hcpcs_crosswalk.csv"))
  }
} else {
  cat("WARNING: Could not fetch NDC-HCPCS crosswalk. Status:", status_code(ndc_resp), "\n")
}

# =============================================================================
# Summary
# =============================================================================
cat("\n=== Data Fetch Summary ===\n")
data_files <- list.files(data_dir, pattern = "\\.(csv|rds)$")
cat("Files saved:\n")
for (f in data_files) {
  sz <- file.size(file.path(data_dir, f))
  cat(sprintf("  %s: %.1f KB\n", f, sz / 1024))
}
cat("\nData fetch complete.\n")
