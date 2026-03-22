## 01b_fetch_ae_provider.R — Fetch provider-level A&E monthly data
## apep_0748: GP Practice Closures and A&E Utilization
## Downloads individual monthly files and builds provider × month panel

source("00_packages.R")

data_dir <- "../data"
ae_dir <- file.path(data_dir, "ae_monthly")
dir.create(ae_dir, showWarnings = FALSE, recursive = TRUE)

## ============================================================
## Build URL list for monthly A&E files
## The naming convention differs across years, so we scrape URLs
## from annual pages. Below are the confirmed working URLs.
## ============================================================

## 2024-25 (provider-specific files with "AE-by-provider" naming)
urls_2024_25 <- c(
  "2025-01_Jan25" = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2025/02/January-2025-AE-by-provider-HyTsU.xls",
  "2024-12_Dec24" = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2025/01/December-2024-AE-by-provider-28BHd.xls",
  "2024-09_Sep24" = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2024/10/September-2024-AE-by-provider-t42ve.xls",
  "2024-06_Jun24" = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2024/07/June-2024-AE-by-provider-HW3bJ.xls",
  "2024-04_Apr24" = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2024/11/April-2024-AE-by-provider-24y7F-revised.xls"
)

## 2019-20 and earlier use "Monthly-AE" naming
urls_older <- c(
  "2020-03_Mar20" = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2020/08/Monthly-AE-March-2020-revised-220720-p4H66-1.xls",
  "2019-12_Dec19" = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2020/08/Monthly-AE-December-2019-revised-220720-7h43F.xls",
  "2019-09_Sep19" = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2020/08/Monthly-September-2019-revised-210720-L48uy.xls",
  "2019-06_Jun19" = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2020/08/Monthly-AE-June-2019-revised-210720-n48F9.xls",
  "2019-04_Apr19" = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2020/08/Monthly-AE-April-2019-revised-220720-632O5.xls"
)

## For a robust panel, we need many more months. Let me try scraping
## additional annual pages to fill in gaps.
## Strategy: Download what we can, fill gaps with quarterly/annual data

all_urls <- c(urls_2024_25, urls_older)

## ============================================================
## Actually, let's take a more efficient approach:
## Download the CSV versions for the years we need (2015-2024)
## from the annual pages. CSVs are faster and easier to parse.
## ============================================================

## Fetch URLs from multiple annual pages
scrape_ae_urls <- function(page_url) {
  tryCatch({
    resp <- curl::curl_fetch_memory(page_url)
    if (resp$status_code != 200) return(character(0))
    html <- rawToChar(resp$content)
    ## Extract all XLS/CSV URLs
    urls <- regmatches(html, gregexpr('https://www\\.england\\.nhs\\.uk/statistics/wp-content/uploads/sites/2/[^"]+\\.(xls|csv)', html))[[1]]
    ## Filter for monthly files (not quarterly)
    monthly <- urls[grepl("Monthly|by-provider", urls, ignore.case = TRUE)]
    ## Prefer XLS (has provider-level sheets)
    monthly
  }, error = function(e) character(0))
}

cat("=== Scraping A&E file URLs from annual pages ===\n")

annual_pages <- c(
  "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ae-attendances-and-emergency-admissions-2024-25/",
  "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ae-attendances-and-emergency-admissions-2023-24/",
  "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ae-attendances-and-emergency-admissions-2022-23/",
  "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ae-attendances-and-emergency-admissions-2021-22/",
  "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ae-attendances-and-emergency-admissions-2020-21/",
  "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ae-attendances-and-emergency-admissions-2019-20/",
  "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ae-attendances-and-emergency-admissions-2018-19/",
  "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ae-attendances-and-emergency-admissions-2017-18/",
  "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ae-attendances-and-emergency-admissions-2016-17/",
  "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ae-attendances-and-emergency-admissions-2015-16/"
)

all_file_urls <- c()
for (page in annual_pages) {
  urls <- scrape_ae_urls(page)
  cat("  ", basename(dirname(page)), "→", length(urls), "files\n")
  all_file_urls <- c(all_file_urls, urls)
  Sys.sleep(0.5)
}

## Keep only XLS files (they have provider-level data sheets)
xls_urls <- unique(all_file_urls[grepl("\\.xls$", all_file_urls, ignore.case = TRUE)])
## Remove quarterly/annual files
xls_urls <- xls_urls[!grepl("Quarter|Annual|Footprint|Attribution|NEL|Growth", xls_urls, ignore.case = TRUE)]

cat("\nTotal monthly XLS files found:", length(xls_urls), "\n")

## ============================================================
## Download all monthly files
## ============================================================
cat("\n=== Downloading monthly A&E files ===\n")

downloaded_files <- c()
for (i in seq_along(xls_urls)) {
  url <- xls_urls[i]
  fname <- basename(url)
  dest <- file.path(ae_dir, fname)

  if (file.exists(dest) && file.size(dest) > 10000) {
    cat("  [", i, "/", length(xls_urls), "] Exists:", fname, "\n")
    downloaded_files <- c(downloaded_files, dest)
    next
  }

  tryCatch({
    download.file(url, dest, mode = "wb", quiet = TRUE)
    if (file.size(dest) > 10000) {
      cat("  [", i, "/", length(xls_urls), "] Downloaded:", fname, "\n")
      downloaded_files <- c(downloaded_files, dest)
    } else {
      cat("  [", i, "/", length(xls_urls), "] Too small, skipping:", fname, "\n")
      unlink(dest)
    }
  }, error = function(e) {
    cat("  [", i, "/", length(xls_urls), "] FAILED:", fname, ":", conditionMessage(e), "\n")
  })
  Sys.sleep(0.3)
}

cat("\nSuccessfully downloaded:", length(downloaded_files), "files\n")

## ============================================================
## Parse provider-level data from each file
## ============================================================
cat("\n=== Parsing provider-level data ===\n")

parse_ae_provider <- function(filepath) {
  sheets <- tryCatch(readxl::excel_sheets(filepath), error = function(e) character(0))
  if (length(sheets) == 0) return(NULL)

  ## Look for "Provider Level Data" sheet (used in newer files)
  ## or parse the main sheet with provider data
  target_sheet <- sheets[grepl("Provider", sheets, ignore.case = TRUE)]
  if (length(target_sheet) == 0) {
    ## Older files may have provider data in a general sheet
    target_sheet <- sheets[1]
  } else {
    target_sheet <- target_sheet[1]
  }

  ## Try different skip values
  for (skip_n in c(15, 14, 16, 13, 12)) {
    tryCatch({
      tmp <- readxl::read_excel(filepath, sheet = target_sheet, skip = skip_n, .name_repair = "minimal")
      if (ncol(tmp) >= 6 && nrow(tmp) > 20) {
        cols_lower <- tolower(names(tmp))
        has_code <- any(grepl("code", cols_lower))
        has_type1 <- any(grepl("type.1|type 1|major", cols_lower))

        if (has_code && has_type1) {
          ## Extract the data period from the filename
          fname <- basename(filepath)

          ## Standardize column names
          names(tmp)[grepl("^code$", names(tmp), ignore.case = TRUE)] <- "provider_code"
          names(tmp)[grepl("name", names(tmp), ignore.case = TRUE)][1] <- "provider_name"

          ## Find Type 1 attendance column (first one that matches)
          type1_cols <- which(grepl("type.1|type 1|major", names(tmp), ignore.case = TRUE))
          if (length(type1_cols) > 0) {
            ## First Type 1 column is total Type 1 attendances
            names(tmp)[type1_cols[1]] <- "type1_attendances"
          }

          ## Find total attendance column
          total_cols <- which(grepl("total.attend", names(tmp), ignore.case = TRUE))
          if (length(total_cols) > 0) {
            names(tmp)[total_cols[1]] <- "total_attendances"
          }

          ## Find emergency admissions column
          emerg_cols <- which(grepl("emergency.admiss|emerg.*admiss", names(tmp), ignore.case = TRUE))
          if (length(emerg_cols) > 0) {
            names(tmp)[emerg_cols[1]] <- "emergency_admissions"
          }

          tmp$source_file <- fname
          return(tmp)
        }
      }
    }, error = function(e) NULL)
  }

  ## If provider sheet didn't work, try the main sheet
  if (target_sheet != sheets[1]) {
    for (skip_n in c(15, 14, 16)) {
      tryCatch({
        tmp <- readxl::read_excel(filepath, sheet = sheets[1], skip = skip_n, .name_repair = "minimal")
        if (ncol(tmp) >= 6 && nrow(tmp) > 20) {
          cols_lower <- tolower(names(tmp))
          if (any(grepl("code", cols_lower))) {
            type1_cols <- which(grepl("type.1|type 1|major", names(tmp), ignore.case = TRUE))
            if (length(type1_cols) > 0) {
              names(tmp)[grepl("^code$", names(tmp), ignore.case = TRUE)] <- "provider_code"
              names(tmp)[type1_cols[1]] <- "type1_attendances"
              total_cols <- which(grepl("total.attend", names(tmp), ignore.case = TRUE))
              if (length(total_cols) > 0) names(tmp)[total_cols[1]] <- "total_attendances"
              tmp$source_file <- basename(filepath)
              return(tmp)
            }
          }
        }
      }, error = function(e) NULL)
    }
  }

  return(NULL)
}

## Extract data period from filename
extract_period <- function(fname) {
  ## Try to extract month and year from filename
  months <- c("January" = 1, "February" = 2, "March" = 3, "April" = 4,
              "May" = 5, "June" = 6, "July" = 7, "August" = 8,
              "September" = 9, "October" = 10, "November" = 11, "December" = 12)

  for (month_name in names(months)) {
    if (grepl(month_name, fname, ignore.case = TRUE)) {
      year_match <- regmatches(fname, gregexpr("20[0-9]{2}", fname))[[1]]
      if (length(year_match) > 0) {
        year <- as.integer(year_match[1])
        month <- months[month_name]
        return(as.Date(paste(year, month, 1, sep = "-")))
      }
    }
  }
  return(NA)
}

all_provider_data <- list()
parse_errors <- 0

for (i in seq_along(downloaded_files)) {
  f <- downloaded_files[i]
  fname <- basename(f)

  parsed <- tryCatch(parse_ae_provider(f), error = function(e) {
    parse_errors <<- parse_errors + 1
    NULL
  })

  if (!is.null(parsed)) {
    period <- extract_period(fname)
    if (!is.na(period)) {
      ## Select only the columns we need
      cols_needed <- intersect(names(parsed),
                               c("provider_code", "provider_name", "type1_attendances",
                                 "total_attendances", "emergency_admissions", "source_file"))
      if ("provider_code" %in% cols_needed && "type1_attendances" %in% cols_needed) {
        subset_data <- parsed[, cols_needed, drop = FALSE]
        subset_data$period <- period
        ## Remove rows where provider_code is NA or "-" (national totals)
        subset_data <- subset_data[!is.na(subset_data$provider_code) &
                                     subset_data$provider_code != "-" &
                                     nchar(subset_data$provider_code) >= 3, ]
        all_provider_data[[length(all_provider_data) + 1]] <- subset_data
        cat("  [", i, "] Parsed:", fname, "→ period", as.character(period),
            "providers:", nrow(subset_data), "\n")
      } else {
        cat("  [", i, "] Missing columns:", fname, "\n")
      }
    } else {
      cat("  [", i, "] Could not extract period:", fname, "\n")
    }
  } else {
    cat("  [", i, "] Parse FAILED:", fname, "\n")
  }
}

## Combine into panel
if (length(all_provider_data) > 0) {
  ae_panel <- bind_rows(all_provider_data)

  ## Convert attendance columns to numeric
  ae_panel$type1_attendances <- as.numeric(ae_panel$type1_attendances)
  ae_panel$total_attendances <- as.numeric(ae_panel$total_attendances)
  if ("emergency_admissions" %in% names(ae_panel)) {
    ae_panel$emergency_admissions <- as.numeric(ae_panel$emergency_admissions)
  }

  ## Remove rows with missing type1
  ae_panel <- ae_panel[!is.na(ae_panel$type1_attendances), ]

  cat("\n=== A&E PROVIDER PANEL SUMMARY ===\n")
  cat("Total rows:", nrow(ae_panel), "\n")
  cat("Unique providers:", length(unique(ae_panel$provider_code)), "\n")
  cat("Period range:", as.character(min(ae_panel$period)), "to", as.character(max(ae_panel$period)), "\n")
  cat("Months covered:", length(unique(ae_panel$period)), "\n")
  cat("Parse errors:", parse_errors, "\n")

  saveRDS(ae_panel, file.path(data_dir, "ae_provider_panel.rds"))
  cat("Provider panel saved.\n")
} else {
  stop("FATAL: No provider-level A&E data could be parsed.")
}
