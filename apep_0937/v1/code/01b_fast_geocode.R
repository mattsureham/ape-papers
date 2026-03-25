# 01b_fast_geocode.R — Fast postcode-to-LA mapping using outward codes
# Strategy: pick one sample postcode per outcode, bulk-lookup via postcodes.io

source("00_packages.R")

data_dir <- "../data/"

# Load Companies House data (already downloaded)
companies <- fread(file.path(data_dir, "companies_filtered.csv"))
cat("Companies loaded:", nrow(companies), "\n")

# Extract outward code (first part of postcode, before the last 3 chars)
companies[, postcode_clean := toupper(gsub(" ", "", postcode))]
companies[nchar(postcode_clean) >= 5,
          outcode := substr(postcode_clean, 1, nchar(postcode_clean) - 3)]

# Get one sample full postcode per outcode
samples <- companies[!is.na(outcode) & nchar(postcode_clean) >= 5,
                     .(sample_pc = postcode_clean[1]), by = outcode]
cat("Unique outcodes:", nrow(samples), "\n")

# Format postcodes with space for API
samples[, formatted_pc := paste0(
  substr(sample_pc, 1, nchar(sample_pc) - 3), " ",
  substr(sample_pc, nchar(sample_pc) - 2, nchar(sample_pc))
)]

# Bulk lookup via postcodes.io (100 at a time)
cat("Looking up", nrow(samples), "sample postcodes via postcodes.io bulk API...\n")
oc_lookup <- data.table()
batch_size <- 100

for (i in seq(1, nrow(samples), by = batch_size)) {
  batch_end <- min(i + batch_size - 1, nrow(samples))
  batch_pcs <- samples$formatted_pc[i:batch_end]
  batch_ocs <- samples$outcode[i:batch_end]

  body <- jsonlite::toJSON(list(postcodes = batch_pcs), auto_unbox = TRUE)
  resp <- tryCatch(
    httr::POST(
      "https://api.postcodes.io/postcodes",
      body = body,
      httr::content_type_json(),
      httr::timeout(30)
    ),
    error = function(e) NULL
  )

  if (!is.null(resp) && httr::status_code(resp) == 200) {
    content <- httr::content(resp, as = "parsed")
    for (k in seq_along(content$result)) {
      item <- content$result[[k]]
      if (!is.null(item$result)) {
        r <- item$result
        oc_lookup <- rbind(oc_lookup, data.table(
          outcode = batch_ocs[k],
          la_code = if (!is.null(r$codes$admin_district)) r$codes$admin_district else NA_character_,
          la_name = if (!is.null(r$admin_district)) r$admin_district else NA_character_,
          country = if (!is.null(r$country)) r$country else NA_character_,
          region = if (!is.null(r$region)) r$region else NA_character_
        ), fill = TRUE)
      }
    }
  }

  if (i %% 500 == 1) {
    cat("  Processed", min(batch_end, nrow(samples)), "of", nrow(samples), "outcodes\n")
  }
  Sys.sleep(0.2)
}

cat("Outcodes with LA code:", sum(!is.na(oc_lookup$la_code)), "of", nrow(oc_lookup), "\n")
fwrite(oc_lookup, file.path(data_dir, "outcode_la_lookup.csv"))

# Drop any old LA columns before merge
for (col in c("la_code", "la_name", "country", "region")) {
  if (col %in% names(companies)) companies[, (col) := NULL]
}

# Merge onto companies
companies <- merge(companies, oc_lookup[, .(outcode, la_code, la_name, country, region)],
                   by = "outcode", all.x = TRUE)

match_rate <- round(100 * sum(!is.na(companies$la_code)) / nrow(companies), 1)
cat("Companies with LA:", sum(!is.na(companies$la_code)), "of", nrow(companies),
    "(", match_rate, "%)\n")

if (match_rate < 50) {
  stop("FATAL: Less than 50% of companies matched to LAs. Check postcode quality.")
}

# Save updated companies
fwrite(companies, file.path(data_dir, "companies_filtered.csv"))

# =========================================================================
# NOMIS dwelling data
# =========================================================================
cat("\n=== Fetching NOMIS dwelling data ===\n")

dwelling_file <- file.path(data_dir, "nomis_dwelling_type.csv")
if (file.exists(dwelling_file)) {
  cat("NOMIS dwelling data already exists, skipping.\n")
} else {
  nomis_api_key <- Sys.getenv("NOMIS_API_KEY")
  nomis_key_param <- ifelse(nchar(nomis_api_key) > 0, paste0("&uid=", nomis_api_key), "")

  # Census 2021 TS044 — Accommodation type
  nomis_url <- paste0(
    "https://www.nomisweb.co.uk/api/v01/dataset/NM_2072_1.data.csv",
    "?date=latest",
    "&geography=TYPE464",
    "&c2021_accom_7=0,1,2,3,4,5,6",
    "&measures=20100",
    "&select=date_name,geography_name,geography_code,c2021_accom_7_name,obs_value",
    nomis_key_param
  )

  resp <- httr::GET(nomis_url, httr::timeout(60))

  if (httr::status_code(resp) == 200) {
    content <- httr::content(resp, as = "text", encoding = "UTF-8")
    dwelling_data <- fread(content)
    cat("NOMIS Census 2021 dwelling data rows:", nrow(dwelling_data), "\n")
    fwrite(dwelling_data, dwelling_file)
  } else {
    cat("Census 2021 failed (status", httr::status_code(resp), "), trying Census 2011...\n")
    alt_url <- paste0(
      "https://www.nomisweb.co.uk/api/v01/dataset/NM_547_1.data.csv",
      "?date=latest&geography=TYPE464&rural_urban=0",
      "&c_typaccom=0,2,3,4,5,6&measures=20100",
      "&select=date_name,geography_name,geography_code,c_typaccom_name,obs_value",
      nomis_key_param
    )
    alt_resp <- httr::GET(alt_url, httr::timeout(60))
    if (httr::status_code(alt_resp) == 200) {
      content <- httr::content(alt_resp, as = "text", encoding = "UTF-8")
      dwelling_data <- fread(content)
      cat("NOMIS Census 2011 dwelling data rows:", nrow(dwelling_data), "\n")
      fwrite(dwelling_data, dwelling_file)
    } else {
      stop("FATAL: Cannot fetch dwelling data from NOMIS")
    }
  }
}

cat("\n=== Fast geocode complete ===\n")
