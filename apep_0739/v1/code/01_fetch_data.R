## 01_fetch_data.R — Fetch GP closure data and A&E statistics
## APEP-0739: GP Practice Closures and A&E Utilization

source("code/00_packages.R")
set.seed(20260322)

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a

cat("=== STEP 1: Fetch inactive GP practices from NHS ODS API ===\n")

fetch_ods_inactive <- function(role_id = "RO177", limit = 1000) {
  base_url <- "https://directory.spineservices.nhs.uk/ORD/2-0-0/organisations"
  all_orgs <- list()
  offset <- 1
  repeat {
    cat(sprintf("  Fetching offset=%d...\n", offset))
    resp <- httr2::request(base_url) |>
      httr2::req_url_query(
        Status = "Inactive", PrimaryRoleId = role_id,
        Limit = limit, Offset = offset
      ) |>
      httr2::req_headers(Accept = "application/fhir+json") |>
      httr2::req_timeout(60) |>
      httr2::req_retry(max_tries = 3) |>
      httr2::req_perform()

    stopifnot(httr2::resp_status(resp) == 200)
    body <- httr2::resp_body_json(resp)
    orgs <- body$Organisations
    if (length(orgs) == 0) break
    all_orgs <- c(all_orgs, orgs)
    offset <- offset + limit
    Sys.sleep(0.5)
  }
  cat(sprintf("  Fetched %d inactive organisations with role %s\n", length(all_orgs), role_id))
  return(all_orgs)
}

inactive_gp <- fetch_ods_inactive("RO177")

gp_closures_raw <- rbindlist(lapply(inactive_gp, function(org) {
  data.table(
    org_id      = as.character(org$OrgId %||% NA),
    name        = as.character(org$Name %||% NA),
    postcode    = as.character(org$PostCode %||% NA),
    last_change = as.character(org$LastChangeDate %||% NA)
  )
}))
cat(sprintf("Parsed %d inactive GP practice records\n", nrow(gp_closures_raw)))

gp_closures_raw <- gp_closures_raw[!is.na(postcode) & postcode != "" &
                                     !is.na(last_change) & last_change != ""]
gp_closures_raw[, closure_date := as.Date(last_change)]
gp_closures_raw <- gp_closures_raw[closure_date >= as.Date("2015-01-01") &
                                     closure_date <= as.Date("2024-12-31")]
cat(sprintf("GP closures 2015-2024: %d\n", nrow(gp_closures_raw)))
stopifnot("No GP closures found" = nrow(gp_closures_raw) > 50)


cat("\n=== STEP 2: Geocode practice postcodes via postcodes.io ===\n")

geocode_postcodes <- function(postcodes, batch_size = 100) {
  results <- list()
  batches <- split(postcodes, ceiling(seq_along(postcodes) / batch_size))
  for (i in seq_along(batches)) {
    if (i %% 10 == 0) cat(sprintf("  Geocoding batch %d/%d\n", i, length(batches)))
    resp <- httr2::request("https://api.postcodes.io/postcodes") |>
      httr2::req_body_json(list(postcodes = batches[[i]])) |>
      httr2::req_timeout(30) |>
      httr2::req_retry(max_tries = 3) |>
      httr2::req_perform()
    body <- httr2::resp_body_json(resp)
    for (item in body$result) {
      if (!is.null(item$result) && !is.null(item$result$latitude)) {
        results[[length(results) + 1]] <- data.table(
          postcode       = as.character(item$query),
          latitude       = as.numeric(item$result$latitude),
          longitude      = as.numeric(item$result$longitude),
          ccg            = as.character(item$result$ccg %||% NA),
          lsoa           = as.character(item$result$lsoa %||% NA),
          admin_district = as.character(item$result$admin_district %||% NA)
        )
      }
    }
    Sys.sleep(0.2)
  }
  rbindlist(results)
}

geo_data <- geocode_postcodes(unique(gp_closures_raw$postcode))
cat(sprintf("Geocoded %d postcodes\n", nrow(geo_data)))

gp_closures <- merge(gp_closures_raw, geo_data, by = "postcode", all.x = TRUE)
gp_closures <- gp_closures[!is.na(latitude)]
cat(sprintf("GP closures with coordinates: %d\n", nrow(gp_closures)))


cat("\n=== STEP 3: Fetch A&E monthly statistics ===\n")

## Scrape NHS England year pages for monthly "AE-by-provider" XLS URLs
year_pages <- c(
  "2018-19" = "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ae-attendances-and-emergency-admissions-2018-19/",
  "2019-20" = "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ae-attendances-and-emergency-admissions-2019-20/",
  "2020-21" = "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ae-attendances-and-emergency-admissions-2020-21/",
  "2021-22" = "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ae-attendances-and-emergency-admissions-2021-22/",
  "2022-23" = "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ae-attendances-and-emergency-admissions-2022-23/",
  "2023-24" = "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ae-attendances-and-emergency-admissions-2023-24/",
  "2024-25" = "https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ae-attendances-and-emergency-admissions-2024-25/"
)

## Function to scrape AE-by-provider XLS URLs from a year page
scrape_ae_urls <- function(page_url) {
  resp <- httr2::request(page_url) |>
    httr2::req_timeout(30) |>
    httr2::req_retry(max_tries = 3) |>
    httr2::req_error(is_error = function(r) FALSE) |>
    httr2::req_perform()
  if (httr2::resp_status(resp) != 200) return(character(0))
  html <- httr2::resp_body_string(resp)
  ## Extract all href containing "AE-by-provider" and ending in .xls
  m <- regmatches(html, gregexpr('href="([^"]*AE-by-provider[^"]*\\.xls)"', html, ignore.case = TRUE))[[1]]
  urls <- gsub('href="([^"]*)"', '\\1', m)
  ## Prefer non-revised versions, but take revised if that's all there is
  urls
}

all_ae_urls <- character(0)
for (yr in names(year_pages)) {
  cat(sprintf("  Scraping %s...\n", yr))
  urls <- scrape_ae_urls(year_pages[[yr]])
  cat(sprintf("    Found %d monthly files\n", length(urls)))
  all_ae_urls <- c(all_ae_urls, urls)
  Sys.sleep(0.5)
}

cat(sprintf("Total A&E URLs found: %d\n", length(all_ae_urls)))
stopifnot("No A&E data URLs found" = length(all_ae_urls) > 10)

## Parse month/year from filename
extract_month_year <- function(url) {
  fname <- basename(url)
  months <- c("January" = 1, "February" = 2, "March" = 3, "April" = 4,
              "May" = 5, "June" = 6, "July" = 7, "August" = 8,
              "September" = 9, "October" = 10, "November" = 11, "December" = 12)
  for (mname in names(months)) {
    if (grepl(mname, fname, ignore.case = TRUE)) {
      yr <- as.integer(regmatches(fname, regexpr("20[0-9]{2}", fname)))
      return(data.table(url = url, month = months[[mname]], year = yr,
                        month_name = mname))
    }
  }
  return(NULL)
}

ae_meta <- rbindlist(lapply(all_ae_urls, extract_month_year))
ae_meta <- ae_meta[!is.na(year)]
## Deduplicate: keep revised version if both exist, else keep first
ae_meta[, is_revised := grepl("revised", url, ignore.case = TRUE)]
ae_meta <- ae_meta[order(year, month, -is_revised)]
ae_meta <- ae_meta[!duplicated(paste(year, month))]
cat(sprintf("Unique month-year combinations: %d\n", nrow(ae_meta)))

## Download and parse each monthly file
dir.create("data/ae_monthly", showWarnings = FALSE, recursive = TRUE)

parse_ae_provider <- function(filepath) {
  sheets <- readxl::excel_sheets(filepath)
  ## Try "Provider Level Data" first, then any sheet with "provider" in name
  target <- sheets[grepl("provider", sheets, ignore.case = TRUE)]
  if (length(target) == 0) return(NULL)
  for (skip_n in c(15, 14, 13, 16, 12)) {
    d <- tryCatch(
      as.data.table(readxl::read_excel(filepath, sheet = target[1], skip = skip_n)),
      error = function(e) NULL
    )
    if (!is.null(d) && ncol(d) > 5) {
      cols <- tolower(names(d))
      if (any(grepl("code", cols))) return(d)
    }
  }
  NULL
}

ae_all <- list()
for (i in seq_len(nrow(ae_meta))) {
  row <- ae_meta[i]
  fname <- sprintf("data/ae_monthly/ae_%04d_%02d.xls", row$year, row$month)
  if (!file.exists(fname)) {
    cat(sprintf("  Downloading %s %d... ", row$month_name, row$year))
    tryCatch({
      resp <- httr2::request(row$url) |>
        httr2::req_timeout(120) |>
        httr2::req_retry(max_tries = 3) |>
        httr2::req_perform()
      writeBin(httr2::resp_body_raw(resp), fname)
      cat("OK\n")
    }, error = function(e) {
      cat(sprintf("FAILED: %s\n", e$message))
    })
    Sys.sleep(0.5)
  }
  if (file.exists(fname)) {
    d <- parse_ae_provider(fname)
    if (!is.null(d) && nrow(d) > 5) {
      ## Standardize column names
      cn <- tolower(names(d))
      code_col <- which(grepl("^code$|org.code", cn))[1]
      name_col <- which(grepl("^name$", cn))[1]

      ## Find Type 1 total attendances column (first "type 1" column)
      type1_cols <- which(grepl("type.1", cn))
      total_col <- which(grepl("total.attend", cn))[1]

      if (!is.na(code_col) && length(type1_cols) > 0) {
        parsed <- data.table(
          provider_code = as.character(d[[code_col]]),
          provider_name = if (!is.na(name_col)) as.character(d[[name_col]]) else NA_character_,
          type1_att     = suppressWarnings(as.numeric(d[[type1_cols[1]]])),
          total_att     = if (!is.na(total_col)) suppressWarnings(as.numeric(d[[total_col]])) else NA_real_,
          ae_year       = row$year,
          ae_month      = row$month
        )
        parsed <- parsed[!is.na(provider_code) & provider_code != "" &
                           provider_code != "-" & !is.na(type1_att)]
        ae_all[[length(ae_all) + 1]] <- parsed
      }
    }
  }
}

ae_panel <- rbindlist(ae_all, fill = TRUE)
cat(sprintf("A&E panel: %d trust-months, %d unique providers\n",
            nrow(ae_panel), uniqueN(ae_panel$provider_code)))
stopifnot("A&E panel too small" = nrow(ae_panel) > 500)


cat("\n=== STEP 4: Fetch trust postcodes from ODS API ===\n")

fetch_active_trusts <- function() {
  all_trusts <- list()
  for (role in c("RO197", "RO198")) {
    resp <- httr2::request("https://directory.spineservices.nhs.uk/ORD/2-0-0/organisations") |>
      httr2::req_url_query(Status = "Active", PrimaryRoleId = role, Limit = 1000) |>
      httr2::req_headers(Accept = "application/fhir+json") |>
      httr2::req_timeout(60) |>
      httr2::req_retry(max_tries = 3) |>
      httr2::req_perform()
    body <- httr2::resp_body_json(resp)
    all_trusts <- c(all_trusts, body$Organisations)
    Sys.sleep(0.5)
  }
  rbindlist(lapply(all_trusts, function(org) {
    data.table(
      trust_code = as.character(org$OrgId %||% NA),
      trust_name = as.character(org$Name %||% NA),
      trust_postcode = as.character(org$PostCode %||% NA)
    )
  }))
}

trusts <- fetch_active_trusts()
cat(sprintf("Active NHS trusts: %d\n", nrow(trusts)))

## Geocode trust postcodes
trust_geo <- geocode_postcodes(unique(trusts$trust_postcode[!is.na(trusts$trust_postcode)]))
trusts <- merge(trusts, trust_geo[, .(postcode, trust_lat = latitude, trust_lon = longitude,
                                       trust_ccg = ccg)],
                by.x = "trust_postcode", by.y = "postcode", all.x = TRUE)

cat("\n=== STEP 5: Save all raw data ===\n")

saveRDS(gp_closures, "data/gp_closures.rds")
saveRDS(ae_panel, "data/ae_panel.rds")
saveRDS(trusts, "data/trusts.rds")

cat("\n=== DATA FETCH COMPLETE ===\n")
cat(sprintf("  GP closures: %d events (2015-2024)\n", nrow(gp_closures)))
cat(sprintf("  A&E panel: %d trust-months\n", nrow(ae_panel)))
cat(sprintf("  NHS trusts: %d\n", nrow(trusts)))
