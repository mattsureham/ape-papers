## ============================================================================
## 01_fetch_data.R — Data Acquisition
## Paper: NLW Bite and Care Home Closures in England (apep_0515)
## ============================================================================

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ---- Helper: NOMIS API direct query ----
nomis_query <- function(dataset_id, params) {
  base_url <- paste0("https://www.nomisweb.co.uk/api/v01/dataset/", dataset_id, ".data.csv")
  key <- Sys.getenv("NOMIS_API_KEY", "")
  if (nchar(key) > 0) params$uid <- key

  resp <- httr2::request(base_url) |>
    httr2::req_url_query(!!!params) |>
    httr2::req_timeout(120) |>
    httr2::req_perform()

  if (httr2::resp_status(resp) != 200) {
    stop("NOMIS API returned status ", httr2::resp_status(resp))
  }
  fread(text = httr2::resp_body_string(resp))
}

## ---- 1. CQC Active Care Homes ----
cat("=== Reading CQC Active Locations ===\n")

active_dt <- as.data.table(
  readODS::read_ods(file.path(data_dir, "cqc_active_locations.ods"),
                     sheet = "HSCA_Active_Locations")
)
# Keep care homes only
active_ch <- active_dt[`Care home?` == "Y"]
cat(sprintf("  Active care homes: %d\n", nrow(active_ch)))

# Standardize columns
active_ch[, `:=`(
  location_id  = `Location ID`,
  name         = `Location Name`,
  reg_date     = `Location HSCA start date`,
  deact_date   = NA_character_,
  beds         = as.integer(`Care homes beds`),
  la_name      = `Location Local Authority`,
  region       = `Location Region`,
  postcode     = `Location Postal Code`,
  rating       = `Location Latest Overall Rating`,
  sector       = `Location Type/Sector`,
  status       = "Active"
)]
active_clean <- active_ch[, .(location_id, name, reg_date, deact_date, beds,
                               la_name, region, postcode, rating, sector, status)]

## ---- 2. CQC Deactivated Care Homes ----
cat("=== Reading CQC Deactivated Locations ===\n")

deact_dt <- as.data.table(
  readODS::read_ods(file.path(data_dir, "cqc_deactivated_locations.ods"),
                     sheet = "Deactivated_Locations")
)
# Keep care homes only
deact_ch <- deact_dt[`Care home?` == "Y"]
cat(sprintf("  Deactivated care homes: %d\n", nrow(deact_ch)))

# Standardize columns
deact_ch[, `:=`(
  location_id  = `Location ID`,
  name         = `Location Name`,
  reg_date     = `Location HSCA start date`,
  deact_date   = `Location HSCA End Date`,
  beds         = as.integer(`Care homes beds at point location de-activated`),
  la_name      = `Location Local Authority`,
  region       = `Location Region`,
  postcode     = `Location Postal Code`,
  rating       = `Location Latest Overall Rating`,
  sector       = `Location Type/Sector`,
  status       = "Deactivated"
)]
deact_clean <- deact_ch[, .(location_id, name, reg_date, deact_date, beds,
                             la_name, region, postcode, rating, sector, status)]

## ---- 3. Combine Active + Deactivated ----
cat("=== Combining Care Home Data ===\n")

all_homes <- rbind(active_clean, deact_clean, fill = TRUE)

# Parse dates
all_homes[, reg_date_parsed := as.Date(reg_date, format = "%d/%m/%Y")]
all_homes[, deact_date_parsed := as.Date(deact_date, format = "%d/%m/%Y")]
all_homes[, reg_year := as.integer(format(reg_date_parsed, "%Y"))]
all_homes[, deact_year := as.integer(format(deact_date_parsed, "%Y"))]

cat(sprintf("  Total care homes (all time): %d\n", nrow(all_homes)))
cat(sprintf("  Active: %d | Deactivated: %d\n",
            sum(all_homes$status == "Active"),
            sum(all_homes$status == "Deactivated")))
cat(sprintf("  Deactivation year range: %d to %d\n",
            min(all_homes$deact_year, na.rm = TRUE),
            max(all_homes$deact_year, na.rm = TRUE)))

# Filter to England only (exclude Wales by checking region)
england_regions <- c("London", "South East", "South West", "East of England",
                     "East Midlands", "West Midlands", "North East",
                     "North West", "Yorkshire and The Humber")
all_homes_eng <- all_homes[region %in% england_regions | is.na(region)]
cat(sprintf("  England only: %d care homes\n", nrow(all_homes_eng)))

fwrite(all_homes_eng, file.path(data_dir, "cqc_all_care_homes_england.csv"))

## ---- 4. NOMIS ASHE: Median Hourly Wages by LA ----
cat("\n=== Fetching NOMIS ASHE Wages ===\n")

ashe_wages <- tryCatch({
  nomis_query("NM_99_1", list(
    time = "2012-2019",
    geography = "TYPE464",
    sex = 7,
    item = 2,
    pay = 5  # Hourly pay - gross
  ))
}, error = function(e) {
  stop("ASHE wage data unavailable: ", e$message,
       "\nCannot construct NLW bite measure.")
})

fwrite(ashe_wages, file.path(data_dir, "ashe_hourly_la.csv"))
cat(sprintf("  ASHE wages: %d rows, %d LAs, years: %s\n",
            nrow(ashe_wages),
            length(unique(ashe_wages$GEOGRAPHY_CODE)),
            paste(sort(unique(ashe_wages$DATE)), collapse = ", ")))

## ---- 5. NOMIS BRES: Care Sector Employment by LA ----
cat("\n=== Fetching NOMIS BRES Care Employment ===\n")

bres_care <- tryCatch({
  nomis_query("NM_189_1", list(
    time = "2012-2019",
    geography = "TYPE464",
    industry = "150287,150288",
    employment_status = 1
  ))
}, error = function(e) {
  cat("  BRES query failed:", e$message, "\n")
  cat("  Proceeding without BRES employment data.\n")
  NULL
})

if (!is.null(bres_care) && nrow(bres_care) > 0) {
  fwrite(bres_care, file.path(data_dir, "bres_care_employment_la.csv"))
  cat(sprintf("  BRES care employment: %d rows\n", nrow(bres_care)))
}

## ---- 6. ONS Population Estimates ----
cat("\n=== Fetching Population Estimates ===\n")

# Try multiple approaches for population data
pop_data <- tryCatch({
  nomis_query("NM_2002_1", list(
    time = "2012-2019",
    geography = "TYPE464",
    gender = 0,
    c_age = "200,210"  # All ages, 65+
  ))
}, error = function(e) {
  cat("  Population NOMIS query failed:", e$message, "\n")
  # Try alternative: ONS API
  tryCatch({
    nomis_query("NM_2010_1", list(
      time = "2012-2019",
      geography = "TYPE464",
      sex = 7,
      measures = 20100
    ))
  }, error = function(e2) {
    cat("  Alternative population query also failed:", e2$message, "\n")
    NULL
  })
})

if (!is.null(pop_data) && nrow(pop_data) > 0) {
  fwrite(pop_data, file.path(data_dir, "ons_population_la.csv"))
  cat(sprintf("  Population: %d rows\n", nrow(pop_data)))
} else {
  cat("  Will construct population controls from other sources.\n")
}

## ---- 7. NLW Schedule ----
cat("\n=== Recording NLW Schedule ===\n")

nlw_schedule <- data.table(
  year = 2012:2024,
  nlw_rate = c(NA, NA, NA, NA, 7.20, 7.50, 7.83, 8.21, 8.72, 8.91, 9.50, 10.42, 11.44),
  nmw_rate = c(6.19, 6.31, 6.50, 6.70, 7.20, 7.50, 7.83, 8.21, 8.72, 8.91, 9.50, 10.42, 11.44),
  policy_active = c(rep(FALSE, 4), rep(TRUE, 9))
)
fwrite(nlw_schedule, file.path(data_dir, "nlw_schedule.csv"))

## ---- DATA VALIDATION ----
cat("\n=== FINAL DATA VALIDATION ===\n")

cqc <- fread(file.path(data_dir, "cqc_all_care_homes_england.csv"))
stopifnot("Expected 15000+ care homes" = nrow(cqc) >= 15000)
stopifnot("Expected postcode column" = "postcode" %in% names(cqc))
stopifnot("Expected la_name column" = "la_name" %in% names(cqc))

n_active <- sum(cqc$status == "Active")
n_deact <- sum(cqc$status == "Deactivated")
n_la <- length(unique(cqc$la_name[!is.na(cqc$la_name)]))
cat(sprintf("  CQC care homes: %d total (%d active, %d deactivated)\n", nrow(cqc), n_active, n_deact))
cat(sprintf("  Unique LAs: %d\n", n_la))
cat(sprintf("  Deactivation years: %s\n",
            paste(sort(unique(cqc$deact_year[!is.na(cqc$deact_year)])), collapse = ", ")))

ashe <- fread(file.path(data_dir, "ashe_hourly_la.csv"))
stopifnot("Expected 50+ LAs in ASHE" = length(unique(ashe$GEOGRAPHY_CODE)) >= 50)
cat(sprintf("  ASHE: %d LAs, %d years\n",
            length(unique(ashe$GEOGRAPHY_CODE)),
            length(unique(ashe$DATE))))

cat("\nData validation passed. Ready for analysis.\n")
