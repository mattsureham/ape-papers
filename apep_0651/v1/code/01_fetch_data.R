# ==============================================================================
# 01_fetch_data.R — Download MSHA bulk data + news competition instruments
# APEP Paper apep_0651: The Spotlight Effect on Mine Safety Enforcement
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------------------------
# 1. MSHA Bulk Data Downloads
# Source: https://arlweb.msha.gov/OpenGovernmentData/OGIMSHA.asp
# ------------------------------------------------------------------------------

msha_base <- "https://arlweb.msha.gov/OpenGovernmentData/DataSets"

msha_files <- c(
  "Accidents"    = "Accidents.zip",
  "Inspections"  = "Inspections.zip",
  "Violations"   = "Violations.zip",
  "Mines"        = "Mines.zip"
)

for (nm in names(msha_files)) {
  zip_path <- file.path(data_dir, msha_files[nm])
  url <- paste0(msha_base, "/", msha_files[nm])

  if (!file.exists(zip_path)) {
    cat("Downloading", nm, "...\n")
    download.file(url, zip_path, mode = "wb", quiet = TRUE)
    stopifnot(file.exists(zip_path))
    cat("  Downloaded:", zip_path, "\n")
  } else {
    cat(nm, "already exists, skipping download.\n")
  }

  # Unzip
  txt_files <- unzip(zip_path, list = TRUE)$Name
  cat("  Contains:", paste(txt_files, collapse = ", "), "\n")
  unzip(zip_path, exdir = data_dir, overwrite = TRUE)
}

# ------------------------------------------------------------------------------
# 2. Read and validate MSHA data
# ------------------------------------------------------------------------------

cat("\nReading MSHA Accidents...\n")
accidents <- fread(file.path(data_dir, "Accidents.txt"),
                   sep = "|", header = TRUE, fill = TRUE,
                   na.strings = c("", "NA"))
cat("  Rows:", nrow(accidents), " Cols:", ncol(accidents), "\n")
cat("  Columns:", paste(head(names(accidents), 15), collapse = ", "), "\n")

cat("\nReading MSHA Inspections...\n")
inspections <- fread(file.path(data_dir, "Inspections.txt"),
                     sep = "|", header = TRUE, fill = TRUE,
                     na.strings = c("", "NA"))
cat("  Rows:", nrow(inspections), " Cols:", ncol(inspections), "\n")
cat("  Columns:", paste(head(names(inspections), 15), collapse = ", "), "\n")

cat("\nReading MSHA Violations...\n")
violations <- fread(file.path(data_dir, "Violations.txt"),
                    sep = "|", header = TRUE, fill = TRUE,
                    na.strings = c("", "NA"))
cat("  Rows:", nrow(violations), " Cols:", ncol(violations), "\n")
cat("  Columns:", paste(head(names(violations), 15), collapse = ", "), "\n")

cat("\nReading MSHA Mines...\n")
mines <- fread(file.path(data_dir, "Mines.txt"),
               sep = "|", header = TRUE, fill = TRUE,
               na.strings = c("", "NA"))
cat("  Rows:", nrow(mines), " Cols:", ncol(mines), "\n")
cat("  Columns:", paste(head(names(mines), 15), collapse = ", "), "\n")

# Save column names for inspection
col_info <- list(
  accidents = names(accidents),
  inspections = names(inspections),
  violations = names(violations),
  mines = names(mines)
)
writeLines(jsonlite::toJSON(col_info, pretty = TRUE, auto_unbox = TRUE),
           file.path(data_dir, "msha_columns.json"))

# Save as RDS for faster loading
saveRDS(accidents, file.path(data_dir, "accidents_raw.rds"))
saveRDS(inspections, file.path(data_dir, "inspections_raw.rds"))
saveRDS(violations, file.path(data_dir, "violations_raw.rds"))
saveRDS(mines, file.path(data_dir, "mines_raw.rds"))

# ------------------------------------------------------------------------------
# 3. FEMA Disaster Declarations (competing news instrument)
# Source: https://www.fema.gov/api/open/v2/DisasterDeclarationsSummaries
# Natural disasters create competing news that crowds out mine fatality coverage.
# This follows the Eisensee-Strömberg (2007) design.
# ------------------------------------------------------------------------------

fema_csv <- file.path(data_dir, "fema_disasters.csv")

if (!file.exists(fema_csv)) {
  cat("\nFetching FEMA disaster declarations...\n")

  # FEMA API returns paginated results (max 1000 per page)
  fema_base <- "https://www.fema.gov/api/open/v2/DisasterDeclarationsSummaries"
  all_records <- list()
  skip <- 0
  page_size <- 1000

  repeat {
    # URL-encode the filter parameter properly
    filter_str <- URLencode("declarationDate ge '2000-01-01T00:00:00.000z'",
                            reserved = TRUE)
    select_str <- URLencode("disasterNumber,declarationDate,declarationType,incidentType,state,declarationTitle",
                            reserved = FALSE)
    url <- paste0(fema_base, "?$skip=", skip, "&$top=", page_size,
                  "&$filter=", filter_str,
                  "&$select=", select_str)
    resp <- tryCatch(
      jsonlite::fromJSON(url),
      error = function(e) { cat("FEMA API error:", e$message, "\n"); NULL }
    )

    if (is.null(resp) || length(resp$DisasterDeclarationsSummaries) == 0) break

    records <- as.data.table(resp$DisasterDeclarationsSummaries)
    all_records[[length(all_records) + 1]] <- records
    cat("  Page", length(all_records), ":", nrow(records), "records (skip=", skip, ")\n")

    if (nrow(records) < page_size) break
    skip <- skip + page_size
  }

  fema <- rbindlist(all_records)
  cat("  Total FEMA records:", nrow(fema), "\n")
  fwrite(fema, fema_csv)
} else {
  cat("FEMA disaster data already fetched.\n")
  fema <- fread(fema_csv)
}

cat("FEMA disasters:", nrow(fema), "records\n")

# ------------------------------------------------------------------------------
# 4. FRED VIX Index (alternative news competition proxy)
# Source: FRED API — CBOE Volatility Index (VIXCLS)
# High VIX = more financial market uncertainty = more competing news
# ------------------------------------------------------------------------------

vix_csv <- file.path(data_dir, "fred_vix.csv")

if (!file.exists(vix_csv)) {
  cat("\nFetching FRED VIX data...\n")

  fred_key <- Sys.getenv("FRED_API_KEY")
  if (nchar(fred_key) == 0) {
    # Try loading from .env
    env_file <- "../../../../.env"
    if (file.exists(env_file)) {
      env_lines <- readLines(env_file)
      fred_line <- grep("^FRED_API_KEY=", env_lines, value = TRUE)
      if (length(fred_line) > 0) {
        fred_key <- gsub("^FRED_API_KEY=", "", fred_line[1])
        fred_key <- gsub("['\"]", "", fred_key)
      }
    }
  }

  if (nchar(fred_key) > 0) {
    vix_url <- paste0("https://api.stlouisfed.org/fred/series/observations",
                      "?series_id=VIXCLS&api_key=", fred_key,
                      "&file_type=json&observation_start=2000-01-01",
                      "&observation_end=2025-01-01")

    resp <- jsonlite::fromJSON(vix_url)
    vix <- as.data.table(resp$observations)
    vix[, value := as.numeric(value)]
    vix[, date := as.Date(date)]
    vix <- vix[!is.na(value)]
    fwrite(vix[, .(date, vix = value)], vix_csv)
    cat("  VIX records:", nrow(vix), "\n")
  } else {
    cat("  WARNING: FRED API key not found. Skipping VIX.\n")
    fwrite(data.table(date = as.Date(character()), vix = numeric()), vix_csv)
  }
} else {
  cat("FRED VIX data already fetched.\n")
}

vix <- fread(vix_csv)
cat("VIX data:", nrow(vix), "trading days\n")

# ------------------------------------------------------------------------------
# 5. Validation assertions
# ------------------------------------------------------------------------------

stopifnot("No accident records" = nrow(accidents) > 100000)
stopifnot("No inspection records" = nrow(inspections) > 500000)
stopifnot("No violation records" = nrow(violations) > 1000000)
stopifnot("No mine records" = nrow(mines) > 10000)
stopifnot("No FEMA records" = nrow(fema) > 1000)

cat("\n=== Data fetch complete. All assertions passed. ===\n")
