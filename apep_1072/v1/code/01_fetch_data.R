# 01_fetch_data.R — Fetch American Rivers dam removal data + USGS water quality
# apep_1072: Dam Removal and Water Quality

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. AMERICAN RIVERS DAM REMOVAL DATABASE
# ============================================================================

cat("=== Fetching American Rivers Dam Removal Database ===\n")

# The database is publicly available on Figshare as CSV
# Source: American Rivers, "American Rivers Dam Removal Database" (2023)
ar_url <- "https://ndownloader.figshare.com/files/62712199"

ar_file <- file.path(data_dir, "dam_removals_raw.csv")
if (!file.exists(ar_file)) {
  download.file(ar_url, ar_file, mode = "wb", quiet = FALSE)
}

dams_raw <- read.csv(ar_file, stringsAsFactors = FALSE)
cat(sprintf("  Raw dam removal records: %d\n", nrow(dams_raw)))

# Inspect columns
cat("  Columns:", paste(names(dams_raw), collapse = ", "), "\n")

# Standardize column names (the dataset uses various naming conventions)
names(dams_raw) <- tolower(gsub("[^a-zA-Z0-9]", "_", names(dams_raw)))
names(dams_raw) <- gsub("_+", "_", names(dams_raw))
names(dams_raw) <- gsub("_$", "", names(dams_raw))

cat("  Standardized columns:", paste(names(dams_raw), collapse = ", "), "\n")

# Save raw for inspection
saveRDS(dams_raw, file.path(data_dir, "dams_raw.rds"))

# ============================================================================
# 2. USGS NWIS WATER QUALITY DATA
# ============================================================================

cat("\n=== Fetching USGS Water Quality Data ===\n")

# States with most dam removals (>30 removals each)
target_states <- c("PA", "CA", "WI", "MI", "OR", "OH", "MA", "MN",
                   "NY", "VA", "NC", "CT", "NH", "VT", "ME", "WA")

# USGS parameter codes
params <- list(
  temp = "00010",      # Water temperature (deg C)
  do   = "00300",      # Dissolved oxygen (mg/L)
  turb = "63680"       # Turbidity (FNU)
)

# Function to query USGS NWIS daily values
fetch_usgs_daily <- function(state_code, param_code, param_name,
                             start_date = "1995-01-01",
                             end_date   = "2023-12-31") {

  base_url <- "https://waterservices.usgs.gov/nwis/dv/"

  query_params <- list(
    format       = "json",
    stateCd      = state_code,
    parameterCd  = param_code,
    startDT      = start_date,
    endDT        = end_date,
    siteType     = "ST",           # Stream sites only
    siteStatus   = "all",
    statCd       = "00003"         # Daily mean
  )

  resp <- tryCatch(
    httr::GET(base_url, query = query_params,
              httr::timeout(120),
              httr::user_agent("APEP-research/1.0 (academic research)")),
    error = function(e) {
      warning(sprintf("  HTTP error for %s/%s: %s", state_code, param_name, e$message))
      return(NULL)
    }
  )

  if (is.null(resp)) return(NULL)

  if (httr::status_code(resp) != 200) {
    warning(sprintf("  Status %d for %s/%s", httr::status_code(resp),
                    state_code, param_name))
    return(NULL)
  }

  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  json <- jsonlite::fromJSON(content, simplifyVector = FALSE)

  # Extract time series
  ts_list <- json$value$timeSeries
  if (length(ts_list) == 0) {
    cat(sprintf("    No data for %s/%s\n", state_code, param_name))
    return(NULL)
  }

  results <- list()
  for (i in seq_along(ts_list)) {
    ts <- ts_list[[i]]
    site_code <- ts$sourceInfo$siteCode[[1]]$value
    site_name <- ts$sourceInfo$siteName
    lat <- as.numeric(ts$sourceInfo$geoLocation$geogLocation$latitude)
    lon <- as.numeric(ts$sourceInfo$geoLocation$geogLocation$longitude)

    values <- ts$values[[1]]$value
    if (length(values) == 0) next

    df <- data.frame(
      site_no   = site_code,
      site_name = site_name,
      lat       = lat,
      lon       = lon,
      date      = sapply(values, function(v) v$dateTime),
      value     = sapply(values, function(v) as.numeric(v$value)),
      qualifier = sapply(values, function(v) paste(v$qualifiers, collapse = ",")),
      stringsAsFactors = FALSE
    )
    df$param <- param_name
    df$state <- state_code
    results[[length(results) + 1]] <- df
  }

  if (length(results) == 0) return(NULL)
  bind_rows(results)
}

# Fetch water temperature data for all target states
# This is the most widely available parameter
temp_data_list <- list()
for (st in target_states) {
  cat(sprintf("  Fetching temperature data for %s...\n", st))
  cache_file <- file.path(data_dir, sprintf("usgs_temp_%s.rds", st))

  if (file.exists(cache_file)) {
    cat(sprintf("    Loading from cache: %s\n", cache_file))
    temp_data_list[[st]] <- readRDS(cache_file)
    next
  }

  result <- fetch_usgs_daily(st, params$temp, "temperature")
  if (!is.null(result) && nrow(result) > 0) {
    cat(sprintf("    Got %d observations from %d sites\n",
                nrow(result), n_distinct(result$site_no)))
    saveRDS(result, cache_file)
    temp_data_list[[st]] <- result
  } else {
    cat(sprintf("    No temperature data for %s\n", st))
  }

  Sys.sleep(2)  # Be polite to USGS API
}

temp_data <- bind_rows(temp_data_list)
cat(sprintf("\nTotal temperature observations: %d from %d sites\n",
            nrow(temp_data), n_distinct(temp_data$site_no)))

# Fetch dissolved oxygen data (may be sparser)
do_data_list <- list()
for (st in target_states) {
  cat(sprintf("  Fetching DO data for %s...\n", st))
  cache_file <- file.path(data_dir, sprintf("usgs_do_%s.rds", st))

  if (file.exists(cache_file)) {
    cat(sprintf("    Loading from cache: %s\n", cache_file))
    do_data_list[[st]] <- readRDS(cache_file)
    next
  }

  result <- fetch_usgs_daily(st, params$do, "dissolved_oxygen")
  if (!is.null(result) && nrow(result) > 0) {
    cat(sprintf("    Got %d observations from %d sites\n",
                nrow(result), n_distinct(result$site_no)))
    saveRDS(result, cache_file)
    do_data_list[[st]] <- result
  } else {
    cat(sprintf("    No DO data for %s\n", st))
  }

  Sys.sleep(2)
}

do_data <- bind_rows(do_data_list)
cat(sprintf("\nTotal DO observations: %d from %d sites\n",
            nrow(do_data), n_distinct(do_data$site_no)))

# Save combined datasets
saveRDS(temp_data, file.path(data_dir, "usgs_temperature_all.rds"))
saveRDS(do_data, file.path(data_dir, "usgs_do_all.rds"))

# ============================================================================
# 3. VALIDATION — Fail loudly if data is missing
# ============================================================================

stopifnot("Dam removal data must have rows" = nrow(dams_raw) > 100)
stopifnot("Temperature data must exist" = nrow(temp_data) > 1000)
stopifnot("DO data must exist" = nrow(do_data) > 1000)

cat("\n=== Data fetch complete ===\n")
cat(sprintf("  Dam removals: %d records\n", nrow(dams_raw)))
cat(sprintf("  Temperature:  %d observations, %d sites\n",
            nrow(temp_data), n_distinct(temp_data$site_no)))
cat(sprintf("  Dissolved O2: %d observations, %d sites\n",
            nrow(do_data), n_distinct(do_data$site_no)))
