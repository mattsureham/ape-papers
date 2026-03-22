## 01_fetch_data.R — Fetch GP practice data and A&E statistics
## apep_0748: GP Practice Closures and A&E Utilization

source("00_packages.R")

if (!requireNamespace("curl", quietly = TRUE)) install.packages("curl")
library(curl)

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## Helper: fetch from ODS API with proper headers
ods_fetch <- function(url) {
  h <- curl::new_handle()
  curl::handle_setheaders(h, "Accept" = "application/json")
  resp <- curl::curl_fetch_memory(url, handle = h)
  if (resp$status_code != 200) {
    stop("ODS API returned status ", resp$status_code, ": ", rawToChar(resp$content))
  }
  jsonlite::fromJSON(rawToChar(resp$content))
}

## ============================================================
## STEP 1: Fetch GP Practice Data from NHS ODS API
## ============================================================
cat("=== STEP 1: Fetch GP Practice Data (NHS ODS API) ===\n")

base_url <- "https://directory.spineservices.nhs.uk/ORD/2-0-0/organisations"

fetch_all_practices <- function(status, role_id = "RO177") {
  all_results <- list()
  limit <- 1000

  ## First request without Offset
  url <- paste0(base_url, "?PrimaryRoleId=", role_id,
                "&Status=", status, "&Limit=", limit)
  result <- tryCatch(ods_fetch(url), error = function(e) {
    cat("  First page error:", conditionMessage(e), "\n")
    NULL
  })

  if (is.null(result) || is.null(result$Organisations) || nrow(result$Organisations) == 0) {
    return(data.frame())
  }

  all_results[[1]] <- result$Organisations
  n_fetched <- nrow(result$Organisations)
  cat("  ", status, ": page 1 →", n_fetched, "records\n")

  ## Subsequent requests with Offset (1-based, API rejects Offset=0)
  page <- 2
  while (n_fetched >= limit) {
    offset <- (page - 1) * limit + 1
    url <- paste0(base_url, "?PrimaryRoleId=", role_id,
                  "&Status=", status, "&Limit=", limit, "&Offset=", offset)
    result <- tryCatch(ods_fetch(url), error = function(e) {
      cat("  Page", page, "error:", conditionMessage(e), "\n")
      NULL
    })

    if (is.null(result) || is.null(result$Organisations) || nrow(result$Organisations) == 0) break

    all_results[[page]] <- result$Organisations
    n_fetched <- nrow(result$Organisations)
    cat("  ", status, ": page", page, "→", n_fetched, "records (total:", sum(sapply(all_results, nrow)), ")\n")
    page <- page + 1
    Sys.sleep(0.15)
  }

  bind_rows(all_results)
}

active_df <- fetch_all_practices("Active")
inactive_df <- fetch_all_practices("Inactive")

cat("Active GP practices:", nrow(active_df), "\n")
cat("Inactive GP practices:", nrow(inactive_df), "\n")

## Combine
active_df$api_status <- "Active"
inactive_df$api_status <- "Inactive"
gp_practices <- bind_rows(active_df, inactive_df)

if (nrow(gp_practices) < 100) {
  stop("FATAL: Only fetched ", nrow(gp_practices), " GP practices. Expected thousands.")
}

cat("Total GP practices:", nrow(gp_practices), "\n")

## Fetch close dates for inactive practices
closed_codes <- gp_practices$OrgId[gp_practices$api_status == "Inactive"]
cat("\nFetching operational dates for", length(closed_codes), "inactive practices...\n")

date_records <- list()
errors <- 0
for (i in seq_along(closed_codes)) {
  code <- closed_codes[i]
  tryCatch({
    url <- paste0(base_url, "/", code)
    org_detail <- ods_fetch(url)

    if (!is.null(org_detail$Organisation$Date)) {
      dates <- org_detail$Organisation$Date
      op_idx <- which(dates$Type == "Operational")
      if (length(op_idx) > 0) {
        date_records[[code]] <- data.frame(
          OrgId = code,
          open_date = dates$Start[op_idx[1]],
          close_date = dates$End[op_idx[1]],
          stringsAsFactors = FALSE
        )
      }
    }
  }, error = function(e) {
    errors <<- errors + 1
  })

  if (i %% 500 == 0) cat("  Processed", i, "/", length(closed_codes), "(errors:", errors, ")\n")
  Sys.sleep(0.03)
}

if (length(date_records) > 0) {
  dates_df <- bind_rows(date_records)
  gp_practices <- left_join(gp_practices, dates_df, by = "OrgId")
  cat("Close dates obtained for", sum(!is.na(gp_practices$close_date)), "practices\n")
} else {
  gp_practices$open_date <- NA_character_
  gp_practices$close_date <- NA_character_
}

saveRDS(gp_practices, file.path(data_dir, "gp_practices_raw.rds"))
cat("GP practice data saved.\n")

## ============================================================
## STEP 2: Fetch A&E Monthly Time Series
## ============================================================
cat("\n=== STEP 2: Fetch A&E Monthly Time Series ===\n")

ae_url <- "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2026/03/Monthly-AE-Time-Series-February-2026-D36ah6.xls"
ae_file <- file.path(data_dir, "ae_timeseries.xls")

download.file(ae_url, ae_file, mode = "wb", quiet = FALSE)

if (!file.exists(ae_file) || file.size(ae_file) < 5000) {
  stop("FATAL: A&E time series download failed.")
}

cat("A&E time series downloaded:", round(file.size(ae_file) / 1024), "KB\n")

## Parse the Excel file
sheets <- readxl::excel_sheets(ae_file)
cat("Sheets:", paste(sheets, collapse = " | "), "\n")

## Read each sheet and find useful data
ae_provider <- NULL
ae_national <- NULL

for (sheet in sheets) {
  for (skip_n in c(0, 1, 2, 3, 5, 10, 13, 14, 15)) {
    tryCatch({
      tmp <- readxl::read_excel(ae_file, sheet = sheet, skip = skip_n, .name_repair = "minimal")
      if (ncol(tmp) > 3 && nrow(tmp) > 10) {
        cols_lower <- tolower(names(tmp))
        has_ae <- any(grepl("type.1|type 1|attend|total", cols_lower))
        has_provider <- any(grepl("code|org|provider", cols_lower))

        if (has_ae && has_provider && nrow(tmp) > 50) {
          ae_provider <- tmp
          cat("  PROVIDER data: sheet='", sheet, "' skip=", skip_n,
              " (", nrow(tmp), "x", ncol(tmp), ")\n", sep = "")
          cat("  Cols:", paste(head(names(tmp), 10), collapse = " | "), "\n")
          break
        } else if (has_ae && is.null(ae_national)) {
          ae_national <- list(data = tmp, sheet = sheet, skip = skip_n)
        }
      }
    }, error = function(e) NULL)
  }
  if (!is.null(ae_provider)) break
}

## Use provider-level if found, otherwise national
ae_data <- if (!is.null(ae_provider)) {
  ae_provider
} else if (!is.null(ae_national)) {
  cat("  Using NATIONAL data from sheet='", ae_national$sheet, "'\n", sep = "")
  cat("  Cols:", paste(head(names(ae_national$data), 10), collapse = " | "), "\n")
  ae_national$data
} else {
  ## Brute force: read all sheets and pick biggest
  biggest <- NULL
  for (sheet in sheets) {
    for (skip_n in c(0, 3, 14)) {
      tryCatch({
        tmp <- readxl::read_excel(ae_file, sheet = sheet, skip = skip_n, .name_repair = "minimal")
        cat("  Sheet '", sheet, "' skip=", skip_n, ": ", nrow(tmp), "x", ncol(tmp), "\n", sep = "")
        if (is.null(biggest) || nrow(tmp) > nrow(biggest)) biggest <- tmp
      }, error = function(e) NULL)
    }
  }
  biggest
}

if (is.null(ae_data)) stop("FATAL: Could not parse A&E data.")

saveRDS(ae_data, file.path(data_dir, "ae_data_raw.rds"))
cat("A&E data saved:", nrow(ae_data), "rows x", ncol(ae_data), "cols\n")

## ============================================================
## STEP 3: Fetch NHS Trust Locations
## ============================================================
cat("\n=== STEP 3: Fetch NHS Trust Locations ===\n")

trust_df <- fetch_all_practices("Active", role_id = "RO197")
cat("Active NHS Trusts:", nrow(trust_df), "\n")

saveRDS(trust_df, file.path(data_dir, "nhs_trusts_raw.rds"))

## ============================================================
## STEP 4: Geocode Postcodes
## ============================================================
cat("\n=== STEP 4: Geocode Postcodes ===\n")

all_postcodes <- unique(c(
  trimws(gp_practices$PostCode),
  trimws(trust_df$PostCode)
))
all_postcodes <- all_postcodes[!is.na(all_postcodes) & nchar(all_postcodes) > 3]
cat("Unique postcodes to geocode:", length(all_postcodes), "\n")

## Batch geocode via postcodes.io
geocode_batch <- function(postcodes) {
  results <- list()
  batch_size <- 100

  for (i in seq(1, length(postcodes), by = batch_size)) {
    batch <- postcodes[i:min(i + batch_size - 1, length(postcodes))]
    batch <- batch[!is.na(batch) & nchar(batch) > 0]
    if (length(batch) == 0) next

    body_json <- jsonlite::toJSON(list(postcodes = batch), auto_unbox = TRUE)
    h <- curl::new_handle()
    curl::handle_setopt(h, postfields = body_json)
    curl::handle_setheaders(h,
      "Content-Type" = "application/json",
      "Accept" = "application/json"
    )

    resp <- tryCatch({
      r <- curl::curl_fetch_memory("https://api.postcodes.io/postcodes", handle = h)
      if (r$status_code == 200) {
        jsonlite::fromJSON(rawToChar(r$content))
      } else NULL
    }, error = function(e) NULL)

    if (!is.null(resp) && !is.null(resp$result)) {
      for (j in seq_len(nrow(resp$result))) {
        r <- resp$result[j, ]
        if (!is.null(r$result) && !is.na(r$result$latitude[1])) {
          results[[length(results) + 1]] <- data.frame(
            postcode = r$query,
            latitude = r$result$latitude,
            longitude = r$result$longitude,
            lsoa = r$result$lsoa %||% NA_character_,
            msoa = r$result$msoa %||% NA_character_,
            local_authority = r$result$admin_district %||% NA_character_,
            region = r$result$region %||% NA_character_,
            stringsAsFactors = FALSE
          )
        }
      }
    }

    if ((i - 1) %% 2000 == 0 && i > 1) {
      cat("  Geocoded", min(i + batch_size - 1, length(postcodes)),
          "/", length(postcodes), "\n")
    }
    Sys.sleep(0.05)
  }

  if (length(results) == 0) stop("FATAL: No postcodes geocoded.")
  bind_rows(results)
}

geocoded <- geocode_batch(all_postcodes)
cat("Successfully geocoded:", nrow(geocoded), "postcodes\n")
saveRDS(geocoded, file.path(data_dir, "postcodes_geocoded.rds"))

## ============================================================
## VALIDATION
## ============================================================
cat("\n=== DATA FETCH SUMMARY ===\n")
cat("GP practices:", nrow(gp_practices), "\n")
cat("  Active:", sum(gp_practices$api_status == "Active"), "\n")
cat("  Inactive:", sum(gp_practices$api_status == "Inactive"), "\n")
cat("  With close dates:", sum(!is.na(gp_practices$close_date)), "\n")
cat("A&E data:", nrow(ae_data), "rows x", ncol(ae_data), "cols\n")
cat("NHS Trusts:", nrow(trust_df), "\n")
cat("Geocoded postcodes:", nrow(geocoded), "\n")
cat("\nAll data saved to:", normalizePath(data_dir), "\n")
