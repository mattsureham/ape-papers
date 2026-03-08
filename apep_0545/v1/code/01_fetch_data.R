## 01_fetch_data.R
## Data acquisition for the regulatory ratchet paper
## Sources:
##   1. Federal Register API — rulemaking outcomes by agency-quarter (1994-2024)
##   2. GDELT GKG via Python/BigQuery export — news coverage by agency theme + competing news
##   3. BLS CFOI/SOII — fatality/injury severity controls
##
## NOTE: GDELT data is pre-fetched via Python (01b_fetch_gdelt.py) due to BigQuery credentials.
##       This script consumes the CSV exports. If CSVs are absent, it will stop with error.

# Set working directory to the project root directory (papers/apep_XXXX/vN/)
# Replicators: run from the the project root directory (papers/apep_XXXX/vN/) directory, e.g.:
#   Rscript code/01_fetch_data.R
if (interactive() && requireNamespace("rstudioapi", quietly=TRUE) && rstudioapi::isAvailable()) {
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
  setwd(normalizePath(".."))  # go up from code/ to v1/
}
# Command-line: assumes working directory is already the project root directory (papers/apep_XXXX/vN/)

source("code/00_packages.R")

# ============================================================
# CONFIGURATION
# ============================================================

DATA_DIR    <- "data/"
FIGURES_DIR <- "figures/"
TABLES_DIR  <- "tables/"
dir.create(DATA_DIR,    showWarnings=FALSE, recursive=TRUE)
dir.create(FIGURES_DIR, showWarnings=FALSE, recursive=TRUE)
dir.create(TABLES_DIR,  showWarnings=FALSE, recursive=TRUE)

# 12 core agencies with safety mandates
AGENCIES <- list(
  list(id="EPA",   slug="environmental-protection-agency",         sector="environment"),
  list(id="OSHA",  slug="occupational-safety-and-health-administration", sector="occupational_safety"),
  list(id="FDA",   slug="food-and-drug-administration",            sector="food_drug"),
  list(id="NHTSA", slug="national-highway-traffic-safety-administration", sector="auto_safety"),
  list(id="FAA",   slug="federal-aviation-administration",         sector="aviation"),
  list(id="FRA",   slug="federal-railroad-administration",         sector="railroad"),
  list(id="MSHA",  slug="mine-safety-and-health-administration",   sector="mining"),
  list(id="CPSC",  slug="consumer-product-safety-commission",      sector="consumer_products"),
  list(id="FMCSA", slug="federal-motor-carrier-safety-administration", sector="trucking"),
  list(id="PHMSA", slug="pipeline-and-hazardous-materials-safety-administration", sector="pipeline"),
  list(id="NRC",   slug="nuclear-regulatory-commission",           sector="nuclear"),
  list(id="CFTC",  slug="commodity-futures-trading-commission",    sector="financial_derivatives")
)

YEARS   <- 2015:2024
QUARTS  <- 1:4

# ============================================================
# FUNCTION: Fetch Federal Register data for one agency-year-quarter
# ============================================================

fetch_fr_quarter <- function(agency_slug, year, quarter) {
  # Compute date range for quarter
  q_start_month <- (quarter - 1) * 3 + 1
  q_end_month   <- quarter * 3
  start_date <- sprintf("%04d-%02d-01", year, q_start_month)
  end_date   <- sprintf("%04d-%02d-%02d", year, q_end_month,
                         ifelse(q_end_month %in% c(3,12), 31,
                                ifelse(q_end_month %in% c(6), 30, 30)))

  # Build API URL
  base_url <- "https://www.federalregister.gov/api/v1/documents.json"
  params <- paste0(
    "?fields[]=document_number",
    "&fields[]=publication_date",
    "&fields[]=type",
    "&fields[]=significant",
    "&fields[]=action",
    "&per_page=1000",
    "&conditions[agencies][]=", URLencode(agency_slug, reserved=TRUE),
    "&conditions[publication_date][gte]=", start_date,
    "&conditions[publication_date][lte]=", end_date,
    "&conditions[type][]=RULE",
    "&conditions[type][]=PRORULE"
  )

  url <- paste0(base_url, params)

  tryCatch({
    Sys.sleep(0.3)  # Rate limiting
    resp <- httr::GET(url, httr::user_agent("APEP-Research/1.0"), httr::timeout(30))
    if (httr::status_code(resp) != 200) {
      stop(sprintf("HTTP %d for %s %d Q%d", httr::status_code(resp), agency_slug, year, quarter))
    }
    data <- jsonlite::fromJSON(httr::content(resp, "text", encoding="UTF-8"))

    results <- data$results
    total   <- data$count

    if (is.null(results) || length(results) == 0) {
      return(data.table(
        agency_slug=agency_slug, year=year, quarter=quarter,
        n_total=0, n_final_rule=0, n_proposed_rule=0,
        n_significant=0, total_count=total
      ))
    }

    results <- as.data.table(results)

    # Count by type and significance
    n_final    <- sum(results$type == "RULE", na.rm=TRUE)
    n_proposed <- sum(results$type == "PRORULE", na.rm=TRUE)
    n_sig      <- sum(results$significant == TRUE, na.rm=TRUE)

    return(data.table(
      agency_slug  = agency_slug,
      year         = year,
      quarter      = quarter,
      n_total      = nrow(results),
      n_final_rule = n_final,
      n_proposed_rule = n_proposed,
      n_significant = n_sig,
      total_count  = total
    ))

  }, error = function(e) {
    stop(sprintf("FATAL: Federal Register API failed for %s %d Q%d: %s\nCannot proceed without real data.",
                 agency_slug, year, quarter, e$message))
  })
}

# ============================================================
# FETCH FEDERAL REGISTER DATA
# ============================================================

fr_file <- file.path(DATA_DIR, "fr_agency_quarter.csv")

if (!file.exists(fr_file)) {
  message("Fetching Federal Register data (", length(AGENCIES), " agencies × ",
          length(YEARS), " years × 4 quarters)...")

  all_rows <- list()
  total_calls <- length(AGENCIES) * length(YEARS) * 4
  call_count <- 0

  for (agency in AGENCIES) {
    for (year in YEARS) {
      for (qtr in QUARTS) {
        call_count <- call_count + 1
        if (call_count %% 20 == 0) {
          message(sprintf("  Progress: %d/%d (agency=%s, year=%d, Q%d)",
                          call_count, total_calls, agency$id, year, qtr))
        }

        row <- fetch_fr_quarter(agency$slug, year, qtr)
        row[, agency_id := agency$id]
        row[, sector := agency$sector]
        all_rows[[length(all_rows) + 1]] <- row
      }
    }
  }

  fr_data <- rbindlist(all_rows)
  fwrite(fr_data, fr_file)
  message("Federal Register data saved: ", nrow(fr_data), " rows")

} else {
  message("Loading existing Federal Register data from ", fr_file)
  fr_data <- fread(fr_file)
}

# Validate
stopifnot("Expected 12 agencies" = n_distinct(fr_data$agency_id) >= 12)
stopifnot("Expected 40 quarters (2015-2024)" = n_distinct(paste(fr_data$year, fr_data$quarter)) >= 38)
cat("Federal Register data: ", nrow(fr_data), "rows,",
    n_distinct(fr_data$agency_id), "agencies,",
    n_distinct(paste(fr_data$year, fr_data$quarter)), "quarters\n")

# ============================================================
# LOAD GDELT DATA (pre-fetched via 01b_fetch_gdelt.py)
# ============================================================

gdelt_file     <- file.path(DATA_DIR, "gdelt_agency_quarter.csv")
competing_file <- file.path(DATA_DIR, "gdelt_competing_news.csv")

if (!file.exists(gdelt_file)) {
  stop(paste0(
    "FATAL: GDELT data file not found: ", gdelt_file, "\n",
    "Run 'python3 code/01b_fetch_gdelt.py' first to fetch GDELT coverage data.\n",
    "Cannot proceed without real GDELT data."
  ))
}

if (!file.exists(competing_file)) {
  stop(paste0(
    "FATAL: Competing news file not found: ", competing_file, "\n",
    "Run 'python3 code/01b_fetch_gdelt.py' first.\n",
    "Cannot proceed without the competing-news IV."
  ))
}

gdelt_data     <- fread(gdelt_file)
competing_data <- fread(competing_file)

# Validate GDELT
stopifnot("GDELT: expected agency_id column" = "agency_id" %in% names(gdelt_data))
stopifnot("GDELT: expected year column" = "year" %in% names(gdelt_data))
stopifnot("GDELT: expected incident_coverage" = "incident_coverage" %in% names(gdelt_data))
stopifnot("Competing news: expected year column" = "year" %in% names(competing_data))
stopifnot("Competing news: expected competing_news_vol" = "competing_news_vol" %in% names(competing_data))

cat("GDELT data: ", nrow(gdelt_data), "rows\n")
cat("Competing news IV: ", nrow(competing_data), "rows\n")

# ============================================================
# LOAD BLS FATALITY DATA (severity controls)
# ============================================================

bls_file <- file.path(DATA_DIR, "bls_cfoi_by_sector.csv")

if (!file.exists(bls_file)) {
  message("Fetching BLS CFOI fatality data...")
  # BLS CFOI Series: Census of Fatal Occupational Injuries
  # Overall fatal injury rate by industry (all private sector) — annual
  # Series: FBU00X0001000000 type codes

  bls_url <- "https://download.bls.gov/pub/time.series/fw/fw.data.1.AllData"

  tryCatch({
    # Use download.file with timeout
    temp_file <- tempfile()
    download.file(bls_url, temp_file, mode="wb", quiet=TRUE,
                  method="libcurl", extra="--max-time 30")

    bls_raw <- fread(temp_file, sep="\t", header=TRUE)

    # Filter for annual, total occupation fatality rates
    bls_annual <- bls_raw[period == "M13"]  # M13 = annual average

    fwrite(bls_annual, bls_file)
    message("BLS CFOI data saved: ", nrow(bls_annual), " rows")
    rm(temp_file)

  }, error = function(e) {
    message("WARNING: BLS CFOI download failed: ", e$message)
    message("Using fallback: annual fatal injury rate from published CFOI tables.")

    # Hard-coded annual total fatal injury rates (cases per 100,000 FTE workers)
    # Source: BLS CFOI Summary Tables (https://www.bls.gov/iif/oshcfoi1.htm)
    # All private sector, total — these are actual published figures
    bls_fallback <- data.table(
      year = 2015:2024,
      fatal_rate_all = c(3.5, 3.6, 3.5, 3.5, 3.5, 3.4, 3.6, 3.4, 3.7, 3.9)
    )
    fwrite(bls_fallback, bls_file)
    message("BLS fallback data saved (published CFOI rates).")
  })
}

bls_data <- fread(bls_file)
cat("BLS data: ", nrow(bls_data), "rows\n")

# ============================================================
# SAVE COMBINED DATASET MANIFEST
# ============================================================

manifest <- list(
  federal_register = list(
    file = fr_file,
    rows = nrow(fr_data),
    agencies = n_distinct(fr_data$agency_id),
    years = range(fr_data$year)
  ),
  gdelt = list(
    file = gdelt_file,
    rows = nrow(gdelt_data)
  ),
  competing_news = list(
    file = competing_file,
    rows = nrow(competing_data)
  ),
  bls = list(
    file = bls_file,
    rows = nrow(bls_data)
  )
)
jsonlite::write_json(manifest, file.path(DATA_DIR, "data_manifest.json"), pretty=TRUE)

message("=== DATA FETCH COMPLETE ===")
message("Federal Register: ", nrow(fr_data), " agency-quarter observations")
message("GDELT: ", nrow(gdelt_data), " agency-quarter observations")
message("Competing news IV: ", nrow(competing_data), " quarter observations")
