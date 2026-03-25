# 01_fetch_data.R — Fetch Companies House and VOA data
# apep_0937: Grenfell fire and fire safety industry formation

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ===========================================================================
# 1. Companies House — Free Company Data Product (bulk CSV)
# ===========================================================================
# The bulk file is ~500MB+. Instead, we use the Companies House Advanced Search
# API to fetch companies by SIC code and incorporation date range.
# No API key needed for basic search.

cat("=== Fetching Companies House data via API ===\n")

# Target SIC codes
fire_sics <- c("84250", "71200", "80200", "71121", "71129", "43999")
control_sics <- c("43210", "43220", "43290")
all_sics <- c(fire_sics, control_sics)

# Function to fetch companies from Companies House search API
fetch_ch_companies <- function(sic_code, start_year = 2008, end_year = 2025) {
  all_results <- list()

  for (year in start_year:end_year) {
    for (month_start in c(1, 4, 7, 10)) {
      month_end <- month_start + 2
      date_from <- sprintf("%d-%02d-01", year, month_start)
      date_to <- sprintf("%d-%02d-28", year, month_end)
      if (month_end == 12) date_to <- sprintf("%d-12-31", year)

      url <- paste0(
        "https://api.company-information.service.gov.uk/advanced-search/companies",
        "?sic_codes=", sic_code,
        "&incorporated_from=", date_from,
        "&incorporated_to=", date_to,
        "&size=500"
      )

      resp <- tryCatch(
        httr::GET(url, httr::timeout(30)),
        error = function(e) {
          cat("  Request failed for SIC", sic_code, year, "Q", (month_start - 1) / 3 + 1, ":", e$message, "\n")
          return(NULL)
        }
      )

      if (is.null(resp) || httr::status_code(resp) != 200) {
        # Try alternative: basic search
        next
      }

      content <- httr::content(resp, as = "parsed")
      items <- content$items

      if (length(items) > 0) {
        batch <- lapply(items, function(x) {
          data.table(
            company_number = x$company_number %||% NA_character_,
            company_name = x$company_name %||% NA_character_,
            date_of_creation = x$date_of_creation %||% NA_character_,
            company_status = x$company_status %||% NA_character_,
            registered_office_address_postal_code = x$registered_office_address$postal_code %||% NA_character_,
            sic_codes = sic_code
          )
        })
        all_results <- c(all_results, batch)
      }

      Sys.sleep(0.6)  # Rate limit
    }
  }

  if (length(all_results) > 0) {
    return(rbindlist(all_results, fill = TRUE))
  }
  return(data.table())
}

# Attempt Companies House API — this may require an API key
# First test if the advanced search endpoint works
test_url <- "https://api.company-information.service.gov.uk/advanced-search/companies?sic_codes=84250&incorporated_from=2020-01-01&incorporated_to=2020-12-31&size=5"
test_resp <- tryCatch(
  httr::GET(test_url, httr::timeout(15)),
  error = function(e) NULL
)

ch_api_works <- !is.null(test_resp) && httr::status_code(test_resp) == 200

if (!ch_api_works) {
  cat("Companies House advanced search requires authentication.\n")
  cat("Falling back to Companies House streaming API for basic company data.\n")

  # Alternative: Download the free BasicCompanyData CSV
  # This is a large file (~500MB) but contains all UK companies
  # For efficiency, we'll use the Companies House streaming endpoint
  # which provides a snapshot

  # Actually, use a direct approach: download the BasicCompanyDataAsOneFile
  ch_bulk_url <- "http://download.companieshouse.gov.uk/BasicCompanyDataAsOneFile-2025-03-01.zip"

  cat("Downloading Companies House bulk data...\n")
  zip_path <- file.path(data_dir, "ch_basic.zip")
  csv_path <- file.path(data_dir, "ch_basic.csv")

  if (!file.exists(csv_path)) {
    # Try current month first, then fall back
    for (date_str in c("2025-03-01", "2025-02-01", "2025-01-01")) {
      bulk_url <- paste0("http://download.companieshouse.gov.uk/BasicCompanyDataAsOneFile-", date_str, ".zip")
      dl_result <- tryCatch(
        download.file(bulk_url, zip_path, mode = "wb", quiet = TRUE, timeout = 300),
        error = function(e) 1
      )
      if (dl_result == 0 && file.exists(zip_path) && file.size(zip_path) > 1e6) {
        break
      }
    }

    if (!file.exists(zip_path) || file.size(zip_path) < 1e6) {
      stop("FATAL: Cannot download Companies House bulk data. No fallback available.")
    }

    cat("Unzipping...\n")
    unzip(zip_path, exdir = data_dir)
    csv_files <- list.files(data_dir, pattern = "BasicCompanyData.*\\.csv$", full.names = TRUE)
    if (length(csv_files) > 0) {
      file.rename(csv_files[1], csv_path)
    }
    unlink(zip_path)
  }

  cat("Reading Companies House bulk data (filtering to target SICs)...\n")
  # Read only columns we need and filter
  ch_raw <- fread(
    csv_path,
    select = c("CompanyNumber", "CompanyName", "IncorporationDate",
                "CompanyStatus", "RegAddress.PostCode",
                "SICCode.SicText_1", "SICCode.SicText_2",
                "SICCode.SicText_3", "SICCode.SicText_4"),
    showProgress = FALSE
  )

  cat("  Total companies loaded:", nrow(ch_raw), "\n")

  # Extract 5-digit SIC codes from the SicText fields
  extract_sic <- function(x) {
    str_extract(x, "^\\d{5}")
  }

  ch_raw[, sic1 := extract_sic(SICCode.SicText_1)]
  ch_raw[, sic2 := extract_sic(SICCode.SicText_2)]
  ch_raw[, sic3 := extract_sic(SICCode.SicText_3)]
  ch_raw[, sic4 := extract_sic(SICCode.SicText_4)]

  # Filter to target SIC codes
  ch_filtered <- ch_raw[
    sic1 %in% all_sics | sic2 %in% all_sics | sic3 %in% all_sics | sic4 %in% all_sics
  ]

  # Assign primary matched SIC
  ch_filtered[, matched_sic := fifelse(
    sic1 %in% all_sics, sic1,
    fifelse(sic2 %in% all_sics, sic2,
    fifelse(sic3 %in% all_sics, sic3, sic4))
  )]

  companies <- ch_filtered[, .(
    company_number = CompanyNumber,
    company_name = CompanyName,
    date_of_creation = IncorporationDate,
    company_status = CompanyStatus,
    postcode = RegAddress.PostCode,
    sic_code = matched_sic
  )]

  rm(ch_raw, ch_filtered)
  gc()

} else {
  cat("Companies House advanced search API works. Fetching by SIC code...\n")

  company_list <- list()
  for (sic in all_sics) {
    cat("  Fetching SIC", sic, "...\n")
    result <- fetch_ch_companies(sic, start_year = 2008, end_year = 2025)
    if (nrow(result) > 0) {
      company_list[[sic]] <- result
    }
  }

  companies <- rbindlist(company_list, fill = TRUE)
  setnames(companies, "registered_office_address_postal_code", "postcode")
  setnames(companies, "sic_codes", "sic_code")
}

cat("Companies in target SICs:", nrow(companies), "\n")

# Parse dates
companies[, inc_date := as.Date(date_of_creation, format = "%d/%m/%Y")]
# Try alternative format if first fails
companies[is.na(inc_date), inc_date := as.Date(date_of_creation, format = "%Y-%m-%d")]
companies[, inc_year := year(inc_date)]
companies[, inc_month := month(inc_date)]
companies[, inc_ym := as.Date(paste0(inc_year, "-", sprintf("%02d", inc_month), "-01"))]

# Classify treatment vs control SIC
companies[, sic_group := fifelse(sic_code %in% fire_sics, "fire_safety", "control_construction")]

cat("Fire safety companies:", nrow(companies[sic_group == "fire_safety"]), "\n")
cat("Control construction companies:", nrow(companies[sic_group == "control_construction"]), "\n")
cat("Incorporation date range:", as.character(min(companies$inc_date, na.rm = TRUE)),
    "to", as.character(max(companies$inc_date, na.rm = TRUE)), "\n")

# Save
fwrite(companies, file.path(data_dir, "companies_filtered.csv"))
cat("Saved companies_filtered.csv\n")

# ===========================================================================
# 2. Postcode to Local Authority mapping via postcodes.io bulk API
# ===========================================================================
cat("\n=== Mapping postcodes to local authorities ===\n")

# Clean postcodes
companies[, postcode_clean := str_to_upper(str_replace_all(postcode, " ", ""))]
unique_postcodes <- unique(companies$postcode_clean[!is.na(companies$postcode_clean) &
                                                      nchar(companies$postcode_clean) >= 5])
cat("Unique postcodes to geocode:", length(unique_postcodes), "\n")

# Bulk lookup via postcodes.io (100 at a time)
pc_lookup <- data.table()
batch_size <- 100

for (i in seq(1, length(unique_postcodes), by = batch_size)) {
  batch <- unique_postcodes[i:min(i + batch_size - 1, length(unique_postcodes))]

  body <- jsonlite::toJSON(list(postcodes = batch), auto_unbox = TRUE)
  resp <- tryCatch(
    httr::POST(
      "https://api.postcodes.io/postcodes",
      body = body,
      httr::content_type_json(),
      httr::timeout(30)
    ),
    error = function(e) NULL
  )

  if (is.null(resp) || httr::status_code(resp) != 200) {
    cat("  Batch", ceiling(i / batch_size), "failed\n")
    next
  }

  content <- httr::content(resp, as = "parsed")

  for (item in content$result) {
    if (!is.null(item$result)) {
      r <- item$result
      pc_lookup <- rbind(pc_lookup, data.table(
        postcode_clean = str_to_upper(str_replace_all(item$query, " ", "")),
        la_code = r$codes$admin_district %||% NA_character_,
        la_name = r$admin_district %||% NA_character_,
        country = r$country %||% NA_character_,
        region = r$region %||% NA_character_
      ), fill = TRUE)
    }
  }

  if (i %% 5000 == 1) {
    cat("  Processed", min(i + batch_size - 1, length(unique_postcodes)),
        "of", length(unique_postcodes), "postcodes\n")
  }
  Sys.sleep(0.2)
}

cat("Postcodes geocoded:", nrow(pc_lookup), "of", length(unique_postcodes), "\n")
fwrite(pc_lookup, file.path(data_dir, "postcode_la_lookup.csv"))

# ===========================================================================
# 3. VOA Council Tax dwelling stock by LA
# ===========================================================================
cat("\n=== Fetching VOA dwelling stock data ===\n")

# VOA Table CTSOP4.0 — Dwelling stock by Council Tax band and property type
# Available on GOV.UK
voa_url <- "https://assets.publishing.service.gov.uk/media/65e0e1aa65ca2f001b7c65d8/CTSOP4.0_2023.ods"

# Try CSV version from data.gov.uk
# The VOA publishes "Table CTSOP4.0" with columns for flats, terraced, semi, detached by LA
# Let's try the latest available

# Alternative: ONS dwelling stock by tenure and dwelling type
# Table 100 — Dwelling stock by tenure and district
# Published by DLUHC (formerly MHCLG)

dluhc_url <- "https://assets.publishing.service.gov.uk/media/5a7c2178ed915d69e9320e13/LT_100.ods"

# For simplicity and reliability, let's construct flat share from NOMIS Census 2011 data
# Census table QS402EW — Accommodation type by household
# This gives dwelling type at LA level

cat("Fetching Census 2011 accommodation type data from NOMIS...\n")

nomis_api_key <- Sys.getenv("NOMIS_API_KEY")
nomis_key_param <- ""
if (nchar(nomis_api_key) > 0) {
  nomis_key_param <- paste0("&uid=", nomis_api_key)
}

# NOMIS Census 2011 — QS402EW Accommodation type
# Geography type 464 = local authority districts 2023
nomis_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_547_1.data.csv",
  "?date=latest",
  "&geography=TYPE464",  # Local authority districts
  "&rural_urban=0",      # Total
  "&c_typaccom=0,2,3,4,5,6",  # Total, detached, semi, terraced, flat/maisonette, caravan
  "&measures=20100",     # Value
  "&select=date_name,geography_name,geography_code,c_typaccom_name,obs_value",
  nomis_key_param
)

nomis_resp <- httr::GET(nomis_url, httr::timeout(60))

if (httr::status_code(nomis_resp) == 200) {
  nomis_content <- httr::content(nomis_resp, as = "text", encoding = "UTF-8")
  dwelling_data <- fread(nomis_content)
  cat("  NOMIS dwelling data rows:", nrow(dwelling_data), "\n")
  fwrite(dwelling_data, file.path(data_dir, "nomis_dwelling_type.csv"))
} else {
  cat("  NOMIS Census query returned status:", httr::status_code(nomis_resp), "\n")
  cat("  Trying alternative approach...\n")

  # Alternative: Use Census 2021 TS044 dataset from NOMIS
  alt_url <- paste0(
    "https://www.nomisweb.co.uk/api/v01/dataset/NM_2072_1.data.csv",
    "?date=latest",
    "&geography=TYPE464",
    "&c2021_accom_7=0,1,2,3,4,5,6",
    "&measures=20100",
    "&select=date_name,geography_name,geography_code,c2021_accom_7_name,obs_value",
    nomis_key_param
  )

  alt_resp <- httr::GET(alt_url, httr::timeout(60))

  if (httr::status_code(alt_resp) == 200) {
    alt_content <- httr::content(alt_resp, as = "text", encoding = "UTF-8")
    dwelling_data <- fread(alt_content)
    cat("  NOMIS Census 2021 dwelling data rows:", nrow(dwelling_data), "\n")
    fwrite(dwelling_data, file.path(data_dir, "nomis_dwelling_type.csv"))
  } else {
    stop("FATAL: Cannot fetch dwelling stock data from NOMIS. Status: ",
         httr::status_code(alt_resp))
  }
}

cat("\n=== Data fetch complete ===\n")
cat("Files saved in:", normalizePath(data_dir), "\n")
