## ============================================================
## 01_fetch_data.R — Data acquisition
## APEP Paper: Does Naming Work?
## Sources: Companies House, FSA FHRS API, NOMIS, postcodes.io
## ============================================================

source("00_packages.R")
library(httr2)
library(jsonlite)
data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ============================================================
## 1. Companies House — Bulk company data
## ============================================================
cat("\n=== COMPANIES HOUSE: Downloading bulk data ===\n")

ch_url <- "https://download.companieshouse.gov.uk/en_output.html"

# Parse page to find the latest BasicCompanyDataAsOneFile zip
ch_page <- tryCatch({
  req <- request(ch_url) |> req_timeout(60)
  resp <- req_perform(req)
  resp_body_string(resp)
}, error = function(e) stop("Companies House page unavailable: ", e$message,
                            "\nPivot research question or fix the source."))

zip_match <- regmatches(ch_page,
  regexpr("BasicCompanyDataAsOneFile-[0-9-]+\\.zip", ch_page))

if (length(zip_match) == 0) {
  # Try split files instead
  zip_match <- regmatches(ch_page,
    gregexpr("BasicCompanyData-[0-9-]+-part[0-9]+_[0-9]+\\.zip", ch_page))[[1]]
  if (length(zip_match) == 0) stop("No Companies House bulk files found")
  cat("Using split files:", length(zip_match), "parts\n")
  ch_zip_urls <- paste0("https://download.companieshouse.gov.uk/", zip_match)
} else {
  ch_zip_urls <- paste0("https://download.companieshouse.gov.uk/", zip_match[1])
  cat("Using single file:", zip_match[1], "\n")
}

ch_zip <- file.path(data_dir, "ch_bulk.zip")
ch_csv <- file.path(data_dir, "ch_bulk.csv")

if (!file.exists(ch_csv)) {
  # Download first zip (single file or first part)
  cat("Downloading Companies House data (this takes several minutes)...\n")
  tryCatch({
    download.file(ch_zip_urls[1], ch_zip, mode = "wb", quiet = FALSE)
    cat("Unzipping...\n")
    unzip(ch_zip, exdir = data_dir)
    # Find the extracted CSV (may be nested in subdirectories)
    extracted <- list.files(data_dir, pattern = "BasicCompanyData.*\\.csv$",
                            full.names = TRUE, recursive = TRUE)
    if (length(extracted) == 0) stop("No CSV found after unzip")
    file.rename(extracted[1], ch_csv)
    unlink(ch_zip)
    cat("Companies House data ready:", ch_csv, "\n")
  }, error = function(e) stop("Companies House download failed: ", e$message))
} else {
  cat("Companies House data already downloaded.\n")
}

# Read with data.table — filter to food-related SIC codes
cat("Reading Companies House data (filtering to relevant SIC codes)...\n")
ch <- fread(ch_csv, select = c(
  "CompanyName", "CompanyNumber", "CompanyStatus",
  "SICCode.SicText_1", "SICCode.SicText_2",
  "IncorporationDate", "DissolutionDate",
  "RegAddress.PostCode", "RegAddress.Country",
  "CompanyCategory"
), showProgress = TRUE)

cat("Total companies loaded:", format(nrow(ch), big.mark = ","), "\n")

# Food-related SIC codes: 56.xx (food service), 10.xx (food manufacturing)
# SIC text format: "56101 - Licensed restaurants"
ch[, sic1 := substr(trimws(`SICCode.SicText_1`), 1, 5)]
ch[, sic2 := substr(trimws(`SICCode.SicText_2`), 1, 5)]

# Food service activities (our treatment group)
food_sic <- c("56101", "56102", "56103", "56210", "56290", "56301", "56302")
# Food retail
food_retail_sic <- c("47110", "47210", "47220", "47230", "47240", "47250",
                      "47290")
# Non-food services (placebo — professional services, IT, etc.)
nonfood_sic <- c("62011", "62012", "62020", "62090", "69101", "69102",
                  "69201", "69202", "70100", "70210", "70220", "71111",
                  "71112", "71121", "71122", "71200", "73110", "73120",
                  "74100", "74200", "74300", "74900")

ch[, is_food := sic1 %in% food_sic | sic2 %in% food_sic]
ch[, is_food_retail := sic1 %in% food_retail_sic | sic2 %in% food_retail_sic]
ch[, is_nonfood := sic1 %in% nonfood_sic | sic2 %in% nonfood_sic]

# Keep only businesses relevant to our analysis
ch_relevant <- ch[is_food == TRUE | is_nonfood == TRUE]
cat("Relevant companies (food + placebo):", format(nrow(ch_relevant), big.mark = ","), "\n")
cat("  Food service:", format(sum(ch_relevant$is_food), big.mark = ","), "\n")
cat("  Non-food placebo:", format(sum(ch_relevant$is_nonfood), big.mark = ","), "\n")

# Parse dates
ch_relevant[, inc_date := as.Date(IncorporationDate, format = "%d/%m/%Y")]
ch_relevant[, diss_date := as.Date(DissolutionDate, format = "%d/%m/%Y")]
ch_relevant[, postcode := trimws(`RegAddress.PostCode`)]

# Filter to 2005–2025 incorporations/dissolutions for manageable panel
ch_relevant <- ch_relevant[
  (is.na(inc_date) | inc_date >= as.Date("2005-01-01")) &
  (is.na(diss_date) | diss_date >= as.Date("2005-01-01"))
]

fwrite(ch_relevant, file.path(data_dir, "ch_food_nonfood.csv"))
cat("Saved ch_food_nonfood.csv:", format(nrow(ch_relevant), big.mark = ","), "rows\n")

## ============================================================
## 2. Postcode → LA geocoding via ONS Postcode Directory
## ============================================================
cat("\n=== ONS POSTCODE DIRECTORY: Mapping postcodes to Local Authorities ===\n")

`%||%` <- function(x, y) if (is.null(x)) y else x

geocode_file <- file.path(data_dir, "postcode_la_lookup.csv")

if (!file.exists(geocode_file)) {
  # Download ONS postcode directory (ONSPD) — free, contains all UK postcodes
  # The ONSPD is large (~1GB zip). Instead, use the lightweight ONS Postcode
  # Directory User Guide (NSPL) — or build lookup from postcodes.io in bulk.
  #
  # Strategy: Use prefix-based approach with postcodes.io random samples,
  # then bulk-assign based on postcode area → LA mapping from FHRS data.
  #
  # Actually, the simplest robust approach: derive LA mapping from Companies
  # House RegAddress.Country + postcode prefix matching to FHRS la_code.
  # FHRS already has la_code per establishment.

  # Get unique postcodes from Companies House
  postcodes <- unique(ch_relevant$postcode)
  postcodes <- postcodes[!is.na(postcodes) & nchar(postcodes) >= 5]
  cat("Unique postcodes to geocode:", format(length(postcodes), big.mark = ","), "\n")

  # Build postcode→country mapping from postcode prefix
  # UK postcodes: first 1-2 letters = postcode area
  # Welsh postcodes: CF, LD, LL, NP, SA, SY (partially)
  # NI postcodes: BT
  # Everything else: England (approximately)

  pc_lookup <- data.table(postcode = postcodes)
  pc_lookup[, pc_clean := gsub(" ", "", toupper(postcode))]
  pc_lookup[, pc_area := gsub("[0-9].*", "", pc_clean)]

  # Country assignment based on postcode area
  welsh_areas <- c("CF", "LD", "LL", "NP", "SA")
  ni_areas <- c("BT")
  # SY is split between Wales and England — assign to England (majority)

  pc_lookup[, country := fifelse(pc_area %in% ni_areas, "Northern Ireland",
                          fifelse(pc_area %in% welsh_areas, "Wales",
                                  "England"))]

  # For LA-level assignment, use postcodes.io for a SAMPLE then expand
  # Actually, for DiD we primarily need country assignment (for treatment)
  # and LA-level grouping. Let's get the LA codes from a small sample
  # per postcode district (first part of postcode) via postcodes.io

  # Get unique postcode districts (outward code = first part before space)
  pc_lookup[, pc_district := sub(" .*", "", postcode)]
  districts <- unique(pc_lookup$pc_district)
  cat("Unique postcode districts:", length(districts), "\n")

  # Sample one postcode per district and geocode those
  district_samples <- pc_lookup[, .(postcode = postcode[1]), by = pc_district]
  cat("Geocoding", nrow(district_samples), "representative postcodes...\n")

  geocode_batch <- function(pcs) {
    tryCatch({
      resp <- request("https://api.postcodes.io/postcodes") |>
        req_body_json(list(postcodes = pcs)) |>
        req_timeout(30) |>
        req_perform()
      results <- resp_body_json(resp)$result
      out <- rbindlist(lapply(results, function(r) {
        if (is.null(r$result)) {
          data.table(postcode = r$query, la_code = NA_character_,
                     la_name = NA_character_, country = NA_character_,
                     region = NA_character_)
        } else {
          data.table(
            postcode = r$query,
            la_code = r$result$codes$admin_district %||% NA_character_,
            la_name = r$result$admin_district %||% NA_character_,
            country = r$result$country %||% NA_character_,
            region = r$result$region %||% NA_character_
          )
        }
      }), fill = TRUE)
      return(out)
    }, error = function(e) {
      warning("Geocode batch failed: ", e$message)
      return(NULL)
    })
  }

  # Batch geocode districts (much smaller — ~2800 vs 305K)
  batches <- split(district_samples$postcode, ceiling(seq_along(district_samples$postcode) / 100))
  results <- list()
  for (i in seq_along(batches)) {
    results[[i]] <- geocode_batch(batches[[i]])
    if (i %% 10 == 0) cat("  Batch", i, "/", length(batches), "\n")
    Sys.sleep(0.05)
  }

  district_lookup <- rbindlist(results, fill = TRUE)
  district_lookup <- district_lookup[!is.na(la_code)]
  district_lookup[, pc_district := sub(" .*", "", postcode)]

  # Now expand: assign each postcode the LA of its district
  district_la <- district_lookup[, .(la_code, la_name, country, region, pc_district)]
  postcode_lookup <- merge(pc_lookup[, .(postcode, pc_district)],
                           district_la, by = "pc_district", all.x = TRUE)
  postcode_lookup <- postcode_lookup[!is.na(la_code)]
  postcode_lookup[, pc_district := NULL]

  fwrite(postcode_lookup, geocode_file)
  cat("Saved postcode_la_lookup.csv:", format(nrow(postcode_lookup), big.mark = ","),
      "postcodes mapped to", uniqueN(postcode_lookup$la_code), "LAs\n")
} else {
  cat("Postcode lookup already exists.\n")
  postcode_lookup <- fread(geocode_file)
}

## ============================================================
## 3. FSA FHRS API — Food hygiene ratings
## ============================================================
cat("\n=== FSA FHRS: Downloading food hygiene ratings ===\n")

fhrs_file <- file.path(data_dir, "fhrs_establishments.csv")

if (!file.exists(fhrs_file)) {
  # Download establishments for England (1), Wales (3), Northern Ireland (4)
  all_establishments <- list()

  # FSA API countryIds: 1=England, 2=Northern Ireland, 3=Scotland (FHIS), 4=Wales
  for (country_id in c(1, 2, 4)) {
    country_name <- c("England", "Northern Ireland", "", "Wales")[country_id]
    cat("Downloading", country_name, "establishments...\n")

    page <- 1
    page_size <- 5000
    country_data <- list()

    repeat {
      resp <- tryCatch({
        request(paste0("https://api.ratings.food.gov.uk/Establishments")) |>
          req_url_query(countryId = country_id,
                        pageNumber = page,
                        pageSize = page_size) |>
          req_headers(`x-api-version` = "2", accept = "application/json") |>
          req_timeout(60) |>
          req_perform()
      }, error = function(e) {
        warning("FHRS API error: ", e$message)
        return(NULL)
      })

      if (is.null(resp)) break

      body <- resp_body_json(resp)
      establishments <- body$establishments

      if (length(establishments) == 0) break

      batch <- rbindlist(lapply(establishments, function(e) {
        data.table(
          fhrs_id = e$FHRSID %||% NA_integer_,
          business_name = e$BusinessName %||% NA_character_,
          business_type = e$BusinessType %||% NA_character_,
          business_type_id = e$BusinessTypeID %||% NA_integer_,
          rating_value = e$RatingValue %||% NA_character_,
          rating_date = e$RatingDate %||% NA_character_,
          la_name = e$LocalAuthorityName %||% NA_character_,
          la_code = e$LocalAuthorityCode %||% NA_character_,
          postcode = e$PostCode %||% NA_character_,
          longitude = e$geocode$longitude %||% NA_real_,
          latitude = e$geocode$latitude %||% NA_real_,
          hygiene_score = e$scores$Hygiene %||% NA_integer_,
          structural_score = e$scores$Structural %||% NA_integer_,
          confidence_score = e$scores$ConfidenceInManagement %||% NA_integer_,
          country = country_name
        )
      }), fill = TRUE)

      country_data[[page]] <- batch

      total_pages <- ceiling(body$meta$totalCount / page_size)
      if (page %% 10 == 0) {
        cat("  ", country_name, ": page", page, "/", total_pages, "\n")
      }

      if (page >= total_pages) break
      page <- page + 1
      Sys.sleep(0.1)
    }

    all_establishments[[country_name]] <- rbindlist(country_data, fill = TRUE)
    cat("  ", country_name, ":", nrow(all_establishments[[country_name]]),
        "establishments\n")
  }

  fhrs <- rbindlist(all_establishments, fill = TRUE)
  fhrs[, rating_date := as.Date(substr(rating_date, 1, 10))]
  fhrs[, rating_numeric := suppressWarnings(as.integer(rating_value))]

  fwrite(fhrs, fhrs_file)
  cat("Saved fhrs_establishments.csv:", format(nrow(fhrs), big.mark = ","),
      "establishments\n")
} else {
  cat("FHRS data already exists.\n")
  fhrs <- fread(fhrs_file)
}

## ============================================================
## 4. NOMIS — Population by LA (for normalizing rates)
## ============================================================
cat("\n=== NOMIS: Population estimates by LA ===\n")

nomis_file <- file.path(data_dir, "nomis_population.csv")

if (!file.exists(nomis_file)) {
  # Mid-year population estimates by LA (NM_2002_1)
  # TYPE464 = local authority districts (2023 boundaries)
  nomis_url <- paste0(
    "https://www.nomisweb.co.uk/api/v01/dataset/NM_2002_1.data.csv?",
    "geography=TYPE464&",
    "date=2008-2024&",
    "gender=0&",         # Total
    "c_age=200&",        # All ages
    "measures=20100&",   # Value
    "select=date_name,geography_name,geography_code,obs_value"
  )

  pop <- tryCatch({
    fread(nomis_url, showProgress = TRUE)
  }, error = function(e) {
    # Try alternative: smaller date range
    cat("Trying smaller date range...\n")
    nomis_url2 <- paste0(
      "https://www.nomisweb.co.uk/api/v01/dataset/NM_2002_1.data.csv?",
      "geography=TYPE464&",
      "date=2010-2023&",
      "gender=0&",
      "c_age=200&",
      "measures=20100&",
      "select=date_name,geography_name,geography_code,obs_value"
    )
    tryCatch(fread(nomis_url2, showProgress = TRUE),
             error = function(e2) stop("NOMIS API unavailable: ", e2$message))
  })

  setnames(pop, c("year", "la_name", "la_code", "population"))
  pop[, year := as.integer(substr(year, 1, 4))]

  fwrite(pop, nomis_file)
  cat("Saved nomis_population.csv:", nrow(pop), "rows\n")
} else {
  cat("NOMIS population data already exists.\n")
  pop <- fread(nomis_file)
}

## ============================================================
## 5. Data validation
## ============================================================
cat("\n=== DATA VALIDATION ===\n")

ch_relevant <- fread(file.path(data_dir, "ch_food_nonfood.csv"))
fhrs <- fread(file.path(data_dir, "fhrs_establishments.csv"))
postcode_lookup <- fread(file.path(data_dir, "postcode_la_lookup.csv"))

# Validation checks
stopifnot("Companies House: need food businesses" =
  sum(ch_relevant$is_food) >= 10000)
stopifnot("FHRS: need establishments" = nrow(fhrs) >= 100000)
stopifnot("Postcode lookup: need geocoded postcodes" =
  nrow(postcode_lookup) >= 10000)

# Check country coverage in FHRS
fhrs_summary <- fhrs[, .N, by = country]
cat("FHRS coverage:\n")
print(fhrs_summary)

# Check country coverage in Companies House via postcode lookup
ch_with_la <- merge(ch_relevant, postcode_lookup, by = "postcode", all.x = TRUE)
ch_country <- ch_with_la[!is.na(country), .N, by = country]
cat("\nCompanies House coverage by country:\n")
print(ch_country)

cat("\nData validation passed:",
    format(nrow(ch_relevant), big.mark = ","), "companies,",
    format(nrow(fhrs), big.mark = ","), "FHRS establishments,",
    format(nrow(postcode_lookup), big.mark = ","), "geocoded postcodes\n")

cat("\n=== ALL DATA FETCHED SUCCESSFULLY ===\n")
