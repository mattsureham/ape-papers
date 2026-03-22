## 01_fetch_data.R — Download Companies House bulk data and define freeport LAs
## APEP-0745: The Freeport Gamble

source("00_packages.R")

cat("=== Step 1: Download Companies House Bulk Data ===\n")

# Companies House publishes monthly snapshots as a single CSV
# URL pattern for the basic company data
ch_url <- "http://download.companieshouse.gov.uk/BasicCompanyDataAsOneFile-2026-03-01.zip"
ch_zip <- "../data/companies_house.zip"
ch_csv <- "../data/companies_house.csv"

if (!file.exists(ch_csv)) {
  cat("Downloading Companies House bulk data (~468MB)...\n")
  dl_result <- tryCatch(
    download.file(ch_url, ch_zip, mode = "wb", timeout = 600),
    error = function(e) {
      # Try alternative date patterns
      cat("First URL failed, trying alternatives...\n")
      for (dt in c("2026-02-01", "2026-01-01", "2025-12-01")) {
        alt_url <- paste0("http://download.companieshouse.gov.uk/BasicCompanyDataAsOneFile-", dt, ".zip")
        cat("Trying:", alt_url, "\n")
        result <- tryCatch(
          download.file(alt_url, ch_zip, mode = "wb", timeout = 600),
          error = function(e2) 1
        )
        if (result == 0 && file.exists(ch_zip) && file.info(ch_zip)$size > 1e6) {
          return(0)
        }
      }
      stop("FATAL: Cannot download Companies House data from any URL")
    }
  )

  cat("Unzipping (flattening nested paths)...\n")
  # Companies House zip has nested directory structure
  system2("unzip", c("-o", "-j", ch_zip, "-d", "../data/"), stdout = TRUE, stderr = TRUE)
  csvs <- list.files("../data/", pattern = "BasicCompanyData.*\\.csv$", full.names = TRUE)
  if (length(csvs) == 0) stop("FATAL: No CSV found after unzipping Companies House data")
  file.rename(csvs[1], ch_csv)
  cat("Companies House data extracted.\n")
} else {
  cat("Companies House data already exists.\n")
}

stopifnot("Companies House CSV missing" = file.exists(ch_csv))
stopifnot("Companies House CSV is empty" = file.info(ch_csv)$size > 1e6)
cat("File size:", round(file.info(ch_csv)$size / 1e6), "MB\n")

cat("\n=== Step 2: Read and parse Companies House data ===\n")

# Read only columns we need (memory efficient)
ch_raw <- fread(
  ch_csv,
  select = c("CompanyNumber", "CompanyName", "RegAddress.PostCode",
             "CompanyCategory", "CompanyStatus", "IncorporationDate",
             "SICCode.SicText_1"),
  showProgress = FALSE
)
cat("Raw records:", format(nrow(ch_raw), big.mark = ","), "\n")

# Parse incorporation date
ch_raw[, inc_date := as.Date(IncorporationDate, format = "%d/%m/%Y")]
# Keep only companies incorporated 2014-2025
ch_raw <- ch_raw[inc_date >= as.Date("2014-01-01") & inc_date <= as.Date("2025-12-31")]
cat("Records 2014-2025:", format(nrow(ch_raw), big.mark = ","), "\n")

# Extract postcode outward code (first part before space)
ch_raw[, postcode := toupper(trimws(RegAddress.PostCode))]
ch_raw <- ch_raw[nchar(postcode) >= 5 & nchar(postcode) <= 8]
cat("Records with valid postcodes:", format(nrow(ch_raw), big.mark = ","), "\n")

# Create year-month variable
ch_raw[, ym := format(inc_date, "%Y-%m")]
ch_raw[, year := year(inc_date)]
ch_raw[, month := month(inc_date)]

# Extract SIC division (first 2 digits)
ch_raw[, sic_text := SICCode.SicText_1]
ch_raw[, sic_code := as.integer(substr(gsub("[^0-9]", "", sic_text), 1, 5))]
ch_raw[, sic_division := floor(sic_code / 1000)]

saveRDS(ch_raw, "../data/ch_parsed.rds")
cat("Parsed Companies House data saved.\n")

cat("\n=== Step 3: Map postcodes to Local Authorities ===\n")

# Get unique postcodes
unique_pcs <- unique(ch_raw$postcode)
cat("Unique postcodes to geocode:", format(length(unique_pcs), big.mark = ","), "\n")

# Use postcodes.io bulk API (100 postcodes per request)
geocode_batch <- function(postcodes) {
  results <- list()
  batch_size <- 100
  n_batches <- ceiling(length(postcodes) / batch_size)

  for (i in seq_len(n_batches)) {
    if (i %% 100 == 0) cat("  Batch", i, "of", n_batches, "\n")
    start_idx <- (i - 1) * batch_size + 1
    end_idx <- min(i * batch_size, length(postcodes))
    batch <- postcodes[start_idx:end_idx]

    resp <- tryCatch({
      httr_resp <- httr::POST(
        "https://api.postcodes.io/postcodes",
        body = toJSON(list(postcodes = batch), auto_unbox = TRUE),
        httr::content_type_json(),
        httr::timeout(30)
      )
      httr::content(httr_resp, as = "parsed")
    }, error = function(e) {
      cat("  Batch", i, "failed:", e$message, "\n")
      NULL
    })

    if (!is.null(resp) && !is.null(resp$result)) {
      for (r in resp$result) {
        if (!is.null(r$result)) {
          results[[length(results) + 1]] <- data.table(
            postcode = r$query,
            la_code = r$result$codes$admin_district,
            la_name = r$result$admin_district,
            region = r$result$region,
            latitude = r$result$latitude,
            longitude = r$result$longitude
          )
        }
      }
    }
  }

  rbindlist(results)
}

pc_lookup_file <- "../data/postcode_la_lookup.rds"
if (!file.exists(pc_lookup_file)) {
  cat("Geocoding postcodes via postcodes.io (this takes a while)...\n")
  # Sample approach: geocode in chunks, save progress
  pc_lookup <- geocode_batch(unique_pcs)
  saveRDS(pc_lookup, pc_lookup_file)
  cat("Geocoded", nrow(pc_lookup), "postcodes.\n")
} else {
  pc_lookup <- readRDS(pc_lookup_file)
  cat("Loaded existing postcode lookup:", nrow(pc_lookup), "entries.\n")
}

cat("\n=== Step 4: Define Freeport Tax Site LAs ===\n")

# Freeport tax sites and their containing Local Authorities
# Source: GOV.UK freeport designation documents
freeport_las <- data.table(
  freeport = c(
    rep("Teesside", 4),
    rep("Humber", 3),
    rep("Thames", 3),
    rep("Freeport East", 2),
    rep("Solent", 2),
    rep("East Midlands", 3),
    rep("Plymouth", 1),
    rep("Liverpool City Region", 3)
  ),
  la_name = c(
    # Teesside (Nov 2021)
    "Redcar and Cleveland", "Middlesbrough", "Stockton-on-Tees", "Hartlepool",
    # Humber (Nov 2021)
    "East Riding of Yorkshire", "North Lincolnshire", "North East Lincolnshire",
    # Thames (Nov 2021)
    "Thurrock", "Barking and Dagenham", "Havering",
    # Freeport East (Dec 2021)
    "Tendring", "Ipswich",
    # Solent (Mar 2022)
    "Southampton", "Eastleigh",
    # East Midlands (Apr 2022)
    "North West Leicestershire", "South Derbyshire", "Rushcliffe",
    # Plymouth (Jul 2022)
    "Plymouth",
    # Liverpool (Jul 2022)
    "Liverpool", "Halton", "Wirral"
  ),
  activation_date = as.Date(c(
    rep("2021-11-19", 4),  # Teesside
    rep("2021-11-19", 3),  # Humber
    rep("2021-11-19", 3),  # Thames
    rep("2021-12-30", 2),  # Freeport East
    rep("2022-03-22", 2),  # Solent
    rep("2022-04-01", 3),  # East Midlands
    rep("2022-07-04", 1),  # Plymouth
    rep("2022-07-01", 3)   # Liverpool
  ))
)

cat("Freeport LAs defined:", nrow(freeport_las), "LA-freeport pairs\n")
cat("Freeports:", length(unique(freeport_las$freeport)), "\n")
cat("Treatment timing:\n")
print(freeport_las[, .(n_las = .N, date = activation_date[1]), by = freeport])

saveRDS(freeport_las, "../data/freeport_las.rds")

cat("\n=== Step 5: Merge and build panel ===\n")

# Merge companies with LA codes
ch_data <- merge(ch_raw, pc_lookup, by = "postcode", all.x = FALSE)
cat("Companies matched to LAs:", format(nrow(ch_data), big.mark = ","), "\n")

# Keep only England
ch_england <- ch_data[region == "England" | region %in% c("London", "South East",
  "South West", "East of England", "East Midlands", "West Midlands",
  "North East", "North West", "Yorkshire and The Humber")]
# Filter for England (non-Scotland/Wales/NI)
ch_england <- ch_data[!is.na(region) & !region %in% c("Scotland", "Wales", "Northern Ireland")]
cat("English companies:", format(nrow(ch_england), big.mark = ","), "\n")

# Create LA x month panel
panel <- ch_england[, .(
  n_incorporations = .N
), by = .(la_name, la_code, ym, year, month)]

# Add freeport treatment
panel <- merge(panel, freeport_las[, .(la_name, freeport, activation_date)],
               by = "la_name", all.x = TRUE)
panel[, treated_la := !is.na(freeport)]
panel[, period_date := as.Date(paste0(ym, "-01"))]
panel[, post := !is.na(activation_date) & period_date >= activation_date]

# Create first_treat variable for CS-DiD (year-month as integer)
panel[, first_treat_ym := ifelse(treated_la,
  as.integer(format(activation_date, "%Y")) * 12 + as.integer(format(activation_date, "%m")),
  0)]

# Time variable as integer (year*12 + month)
panel[, time_int := year * 12L + month]

# Fill in zeros for LA-months with no incorporations
all_las <- unique(panel[, .(la_name, la_code, treated_la, freeport, activation_date, first_treat_ym)])
all_periods <- unique(panel[, .(ym, year, month, time_int, period_date)])
full_panel <- CJ(la_name = all_las$la_name, ym = all_periods$ym)
full_panel <- merge(full_panel, all_las, by = "la_name")
full_panel <- merge(full_panel, all_periods, by = "ym")
full_panel <- merge(full_panel, panel[, .(la_name, ym, n_incorporations)],
                    by = c("la_name", "ym"), all.x = TRUE)
full_panel[is.na(n_incorporations), n_incorporations := 0]
full_panel[, post := !is.na(activation_date) & period_date >= activation_date]
full_panel[, log_inc := log(1 + n_incorporations)]

cat("\nPanel dimensions:", nrow(full_panel), "rows (", n_distinct(full_panel$la_name), "LAs x",
    n_distinct(full_panel$ym), "months)\n")
cat("Treated LAs:", sum(all_las$treated_la), "\n")
cat("Control LAs:", sum(!all_las$treated_la), "\n")

saveRDS(full_panel, "../data/panel.rds")
cat("\n=== Data fetch and panel construction complete ===\n")
