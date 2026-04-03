## 01_fetch_data.R — Fetch Ofsted MI, Land Registry PPD, and inspector data
## apep_1345: The Inspector Lottery

source("00_packages.R")
setwd(here::here("output", "apep_1345", "v1"))

dir.create("data", showWarnings = FALSE, recursive = TRUE)

## ── 1. Ofsted Management Information ─────────────────────────────────────────

cat("=== Fetching Ofsted Management Information ===\n")

# Search data.gov.uk CKAN for the Ofsted MI dataset
cat("Searching data.gov.uk for Ofsted MI...\n")
ckan_resp <- httr2::request("https://data.gov.uk/api/action/package_search") |>
  httr2::req_url_query(q = "ofsted management information state-funded schools inspections outcomes", rows = 5) |>
  httr2::req_timeout(30) |>
  httr2::req_perform()

ckan_data <- jsonlite::fromJSON(httr2::resp_body_string(ckan_resp))
cat("Found", ckan_data$result$count, "datasets.\n")

# Print dataset titles to find the right one
for (i in seq_len(min(5, length(ckan_data$result$results$title)))) {
  cat(" ", i, ":", ckan_data$result$results$title[i], "\n")
}

# Get resources from the first result
resources <- ckan_data$result$results$resources[[1]]
csv_resources <- resources[grepl("\\.csv", resources$url, ignore.case = TRUE), ]
cat("\nCSV resources found:", nrow(csv_resources), "\n")
if (nrow(csv_resources) > 0) {
  # Show URLs
  for (j in seq_len(min(3, nrow(csv_resources)))) {
    cat("  ", csv_resources$url[j], "\n")
  }
  # Download the most recent CSV
  csv_url <- csv_resources$url[nrow(csv_resources)]
  cat("\nDownloading:", csv_url, "\n")
  resp <- httr2::request(csv_url) |>
    httr2::req_timeout(120) |>
    httr2::req_perform()
  writeBin(httr2::resp_body_raw(resp), "data/ofsted_mi.csv")
  cat("Downloaded Ofsted MI CSV.\n")
} else {
  # Try direct GOV.UK with current date patterns
  cat("No CSV in CKAN. Trying GOV.UK direct download...\n")

  # Try multiple URL patterns
  urls_to_try <- c(
    "https://assets.publishing.service.gov.uk/media/67c9a7eaff764c5b2d0dc72f/Management_information_-_state-funded_schools_-_as_at_31_January_2025.csv",
    "https://assets.publishing.service.gov.uk/media/678ae5a3c945e1e37c01e0de/Management_information_-_state-funded_schools_-_as_at_31_December_2024.csv",
    "https://assets.publishing.service.gov.uk/media/6751a8f3f51b8089590db4cf/Management_information_-_state-funded_schools_-_as_at_30_November_2024.csv"
  )

  downloaded <- FALSE
  for (try_url in urls_to_try) {
    cat("Trying:", try_url, "\n")
    resp <- tryCatch({
      httr2::request(try_url) |>
        httr2::req_timeout(60) |>
        httr2::req_perform()
    }, error = function(e) NULL)

    if (!is.null(resp) && httr2::resp_status(resp) == 200) {
      writeBin(httr2::resp_body_raw(resp), "data/ofsted_mi.csv")
      cat("Downloaded Ofsted MI CSV.\n")
      downloaded <- TRUE
      break
    }
  }

  if (!downloaded) {
    # Last resort: scrape the GOV.UK page to find the current download link
    cat("Scraping GOV.UK page for current download link...\n")
    govuk_page <- rvest::read_html("https://www.gov.uk/government/statistical-data-sets/monthly-management-information-ofsteds-school-inspections-outcomes")
    links <- rvest::html_attr(rvest::html_elements(govuk_page, "a"), "href")
    csv_links <- links[grepl("Management_information.*\\.csv", links, ignore.case = TRUE)]
    if (length(csv_links) > 0) {
      dl_url <- csv_links[1]
      if (!grepl("^http", dl_url)) dl_url <- paste0("https://www.gov.uk", dl_url)
      cat("Found link:", dl_url, "\n")
      resp <- httr2::request(dl_url) |>
        httr2::req_timeout(120) |>
        httr2::req_perform()
      writeBin(httr2::resp_body_raw(resp), "data/ofsted_mi.csv")
      downloaded <- TRUE
    }
    if (!downloaded) stop("FATAL: Cannot download Ofsted MI data from any source.")
  }
}

# Read and inspect columns
ofsted <- fread("data/ofsted_mi.csv")
cat("\nOfsted MI dimensions:", nrow(ofsted), "rows x", ncol(ofsted), "cols\n")
cat("Column names:\n")
print(names(ofsted))

# Check for inspector-related columns
inspector_cols <- grep("inspector|hmi|lead|oin", names(ofsted), ignore.case = TRUE, value = TRUE)
cat("\nInspector-related columns found:", length(inspector_cols), "\n")
if (length(inspector_cols) > 0) print(inspector_cols)

# Save column info for debugging
writeLines(names(ofsted), "data/ofsted_mi_columns.txt")

## ── 2. Extract Inspector Names from Ofsted Reports ──────────────────────────

cat("\n=== Extracting Inspector Names from Ofsted Report Pages ===\n")

# Get URNs from MI data
urn_col <- grep("^urn$", names(ofsted), ignore.case = TRUE, value = TRUE)[1]
if (is.na(urn_col)) {
  # Try other patterns
  urn_col <- grep("urn|URN|school.urn|School.URN", names(ofsted), value = TRUE)[1]
}
cat("URN column:", urn_col, "\n")

# Filter to graded inspections (rating 1-4)
rating_col <- grep("overall.effectiveness|Overall.Effectiveness|overall_effectiveness",
                    names(ofsted), ignore.case = TRUE, value = TRUE)[1]
cat("Rating column:", rating_col, "\n")

if (!is.na(urn_col) && !is.na(rating_col)) {
  graded <- ofsted[!is.na(get(rating_col)) & get(rating_col) %in% 1:4]
  urns <- unique(graded[[urn_col]])
  cat("Graded inspections:", nrow(graded), "| Unique schools:", length(urns), "\n")
} else {
  # Show what columns we have to work with
  cat("Available columns:\n")
  print(names(ofsted))
  stop("FATAL: Cannot identify URN or rating columns in Ofsted MI data.")
}

# Extract inspector names by scraping Ofsted report pages
# reports.ofsted.gov.uk/provider/{URN} contains inspection history
# Each inspection report PDF lists the lead inspector

# For V1, we'll scrape a substantial sample to build the IV
# At 0.5s per request, 10,000 schools = ~83 minutes (too slow)
# Instead, try bulk API or structured data first

# Try the Ofsted inspection page which lists all inspections with details
cat("\nTrying bulk extraction via inspection history pages...\n")

# Sample first to calibrate extraction
sample_urns <- head(urns[!is.na(urns)], 30)
inspector_records <- list()

for (i in seq_along(sample_urns)) {
  urn <- sample_urns[i]

  tryCatch({
    # Ofsted provides inspection reports at this URL pattern
    url <- paste0("https://reports.ofsted.gov.uk/provider/", urn)
    page <- rvest::read_html(url)

    # Get all text content
    text_content <- rvest::html_text2(page)

    # Try multiple extraction patterns for lead inspector
    patterns <- c(
      "Lead [Ii]nspector[:,\\s]+([A-Z][a-zA-Z'-]+ [A-Z][a-zA-Z'-]+)",
      "([A-Z][a-zA-Z'-]+ [A-Z][a-zA-Z'-]+), lead inspector",
      "([A-Z][a-zA-Z'-]+ [A-Z][a-zA-Z'-]+), Lead Inspector",
      "(?:His|Her) Majesty.s Inspector[:,\\s]+([A-Z][a-zA-Z'-]+ [A-Z][a-zA-Z'-]+)"
    )

    lead_name <- NA_character_
    for (pat in patterns) {
      m <- stringr::str_match(text_content, pat)
      if (!is.na(m[1, 2])) {
        lead_name <- m[1, 2]
        break
      }
    }

    # Also check for structured HTML elements
    if (is.na(lead_name)) {
      # Try finding inspector info in specific HTML elements
      inspector_divs <- rvest::html_elements(page, ".inspection-report-details, .lead-inspector, .inspector-name")
      if (length(inspector_divs) > 0) {
        lead_name <- stringr::str_trim(rvest::html_text2(inspector_divs[1]))
      }
    }

    if (!is.na(lead_name) && nchar(lead_name) > 3) {
      inspector_records[[length(inspector_records) + 1]] <- data.table(
        urn = urn,
        lead_inspector = lead_name
      )
      cat("  [", i, "/", length(sample_urns), "] URN", urn, "->", lead_name, "\n")
    } else {
      cat("  [", i, "/", length(sample_urns), "] URN", urn, "-> NO INSPECTOR FOUND\n")
    }

    Sys.sleep(0.3)
  }, error = function(e) {
    cat("  [", i, "/", length(sample_urns), "] URN", urn, "-> Error:", e$message, "\n")
  })
}

extraction_rate <- length(inspector_records) / length(sample_urns)
cat("\n--- Inspector Extraction Results ---\n")
cat("Sample size:", length(sample_urns), "\n")
cat("Successful extractions:", length(inspector_records), "\n")
cat("Extraction rate:", round(extraction_rate * 100, 1), "%\n")

if (length(inspector_records) > 0) {
  sample_insp <- rbindlist(inspector_records)
  cat("Unique inspectors:", uniqueN(sample_insp$lead_inspector), "\n")
  print(table(sample_insp$lead_inspector))
}

# Decision point: if extraction works well, scale up
if (extraction_rate >= 0.5) {
  cat("\nExtraction rate sufficient. Scaling up to full sample...\n")
  cat("Processing all", length(urns), "URNs (this may take a while)...\n")

  all_records <- inspector_records  # Keep what we already have
  processed_urns <- sample_urns

  remaining_urns <- setdiff(urns, processed_urns)
  batch_size <- min(length(remaining_urns), 5000)  # Cap at 5000 for V1
  remaining_urns <- head(remaining_urns, batch_size)

  cat("Processing", length(remaining_urns), "additional URNs...\n")

  pb_interval <- max(1, round(length(remaining_urns) / 20))

  for (i in seq_along(remaining_urns)) {
    urn <- remaining_urns[i]

    if (i %% pb_interval == 0) {
      cat("  Progress:", i, "/", length(remaining_urns),
          "(", length(all_records), "extracted)\n")
    }

    tryCatch({
      url <- paste0("https://reports.ofsted.gov.uk/provider/", urn)
      page <- rvest::read_html(url)
      text_content <- rvest::html_text2(page)

      lead_name <- NA_character_
      for (pat in c(
        "Lead [Ii]nspector[:,\\s]+([A-Z][a-zA-Z'-]+ [A-Z][a-zA-Z'-]+)",
        "([A-Z][a-zA-Z'-]+ [A-Z][a-zA-Z'-]+), lead inspector",
        "([A-Z][a-zA-Z'-]+ [A-Z][a-zA-Z'-]+), Lead Inspector"
      )) {
        m <- stringr::str_match(text_content, pat)
        if (!is.na(m[1, 2])) {
          lead_name <- m[1, 2]
          break
        }
      }

      if (!is.na(lead_name) && nchar(lead_name) > 3) {
        all_records[[length(all_records) + 1]] <- data.table(
          urn = urn,
          lead_inspector = lead_name
        )
      }

      Sys.sleep(0.2)
    }, error = function(e) {
      # Silent fail for bulk processing
    })
  }

  all_inspectors <- rbindlist(all_records)
  cat("\n--- Full Extraction Results ---\n")
  cat("Total records:", nrow(all_inspectors), "\n")
  cat("Unique schools:", uniqueN(all_inspectors$urn), "\n")
  cat("Unique inspectors:", uniqueN(all_inspectors$lead_inspector), "\n")

  fwrite(all_inspectors, "data/inspector_linkage.csv")
  cat("Saved inspector linkage data.\n")

} else if (extraction_rate > 0) {
  cat("\nLow extraction rate (", round(extraction_rate*100,1), "%).",
      "Proceeding with available data.\n")
  if (length(inspector_records) > 0) {
    all_inspectors <- rbindlist(inspector_records)
    fwrite(all_inspectors, "data/inspector_linkage.csv")
  }
} else {
  cat("\n*** PIVOT: Inspector extraction failed. ***\n")
  cat("Switching to rating-change event study design.\n")
  cat("This uses Ofsted rating transitions (e.g., Good->RI) as treatment.\n")

  # For the alternative design, we need inspection dates and rating changes
  # The MI data has current and previous inspection results
  fwrite(data.table(urn = character(0), lead_inspector = character(0)),
         "data/inspector_linkage.csv")
}

## ── 3. HM Land Registry Price Paid Data ──────────────────────────────────────

cat("\n=== Fetching HM Land Registry Price Paid Data ===\n")

# Download annual files for 2015-2024
years <- 2015:2024
lr_base <- "http://prod.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com"

lr_cols <- c("txn_id", "price", "date", "postcode", "prop_type", "new_build",
             "tenure", "paon", "saon", "street", "locality", "town",
             "district", "county", "ppd_cat", "record_status")

lr_data_list <- list()
for (yr in years) {
  lr_url <- paste0(lr_base, "/pp-", yr, ".csv")
  lr_file <- paste0("data/pp-", yr, ".csv")

  if (!file.exists(lr_file)) {
    cat("Downloading Land Registry", yr, "...\n")
    tryCatch({
      resp_lr <- httr2::request(lr_url) |>
        httr2::req_timeout(300) |>
        httr2::req_perform()

      if (httr2::resp_status(resp_lr) == 200) {
        writeBin(httr2::resp_body_raw(resp_lr), lr_file)
        cat("  Downloaded:", yr, "(",
            round(file.size(lr_file)/1e6, 1), "MB)\n")
      }
    }, error = function(e) {
      cat("  Failed:", yr, "-", e$message, "\n")
    })
  } else {
    cat("Land Registry", yr, "already exists.\n")
  }

  # Read file if it exists
  if (file.exists(lr_file)) {
    dt <- fread(lr_file, header = FALSE, col.names = lr_cols)
    dt[, year := yr]
    lr_data_list[[as.character(yr)]] <- dt
    cat("  Read", yr, ":", nrow(dt), "transactions\n")
  }
}

if (length(lr_data_list) > 0) {
  lr_all <- rbindlist(lr_data_list)
  cat("\nTotal Land Registry records:", nrow(lr_all), "\n")
  cat("Date range:", min(lr_all$date), "to", max(lr_all$date), "\n")
  cat("Unique postcodes:", uniqueN(lr_all$postcode), "\n")

  # Save as parquet for efficiency
  arrow::write_parquet(lr_all, "data/land_registry_2015_2024.parquet")
  cat("Saved Land Registry parquet.\n")

  # Clean up individual CSVs
  for (yr in years) {
    f <- paste0("data/pp-", yr, ".csv")
    if (file.exists(f)) file.remove(f)
  }
} else {
  stop("FATAL: No Land Registry data downloaded.")
}

cat("\n=== Data fetch complete ===\n")
cat("Files in data/:\n")
print(list.files("data/"))
