## 01_fetch_data.R — Fetch INE EPA and DIRCE data via API
## apep_0594: Spain's 2022 Temporary Contract Ban

source("00_packages.R")

cat("=== Fetching INE EPA data ===\n")

# =============================================================================
# Helper: Fetch INE API data
# =============================================================================

fetch_ine_table <- function(table_id, nult = 60) {
  url <- sprintf(
    "https://servicios.ine.es/wstempus/js/EN/DATOS_TABLA/%s?nult=%d",
    table_id, nult
  )
  cat("Fetching:", url, "\n")

  resp <- GET(url, timeout(120))
  if (http_error(resp)) {
    stop("INE API error for table ", table_id, ": HTTP ", status_code(resp))
  }

  raw <- content(resp, as = "text", encoding = "UTF-8")
  data <- fromJSON(raw, flatten = TRUE)

  if (is.null(data) || length(data) == 0) {
    stop("INE API returned empty data for table ", table_id)
  }

  cat("  Retrieved", nrow(data), "series\n")
  return(data)
}

# =============================================================================
# Helper: Parse INE series into tidy data frame
# =============================================================================

parse_ine_series <- function(data) {
  # Handle different API response structures
  if (is.data.frame(data)) {
    n_series <- nrow(data)
  } else if (is.list(data)) {
    n_series <- length(data)
  } else {
    stop("Unexpected data structure from INE API")
  }

  rows <- list()
  for (i in seq_len(n_series)) {
    if (is.data.frame(data)) {
      series <- data[i, ]
      series_name <- series$Nombre
      meta <- series$MetaData[[1]]
      vals <- series$Data[[1]]
    } else {
      series <- data[[i]]
      series_name <- series$Nombre
      meta <- as.data.frame(do.call(rbind, series$MetaData))
      vals <- as.data.frame(do.call(rbind, series$Data))
    }

    # Extract dimension labels
    if (is.data.frame(meta) && "Nombre" %in% names(meta)) {
      dims <- as.character(meta$Nombre)
    } else {
      dims <- character(0)
    }

    # Extract values
    if (is.null(vals) || !is.data.frame(vals) || nrow(vals) == 0) next

    for (j in seq_len(nrow(vals))) {
      row <- list(
        series_name = series_name,
        value = as.numeric(vals$Valor[j]),
        date = as.numeric(vals$Fecha[j])
      )
      for (k in seq_along(dims)) {
        row[[paste0("dim_", k)]] <- dims[k]
      }
      rows[[length(rows) + 1]] <- row
    }
  }

  dt <- rbindlist(rows, fill = TRUE)
  # Parse date (INE returns epoch milliseconds)
  dt[, date := as.POSIXct(date / 1000, origin = "1970-01-01", tz = "UTC")]
  dt[, year := year(date)]
  dt[, quarter := quarter(date)]
  dt[, yq := paste0(year, "Q", quarter)]
  return(dt)
}

# =============================================================================
# Fetch Table 65328: Wage earners by contract type, sex, Autonomous Community
# Quarterly, has contract type x region breakdowns
# =============================================================================

cat("\n--- Table 65328: Contract type by region ---\n")
raw_65328 <- fetch_ine_table("65328", nult = 60)
dt_region <- parse_ine_series(raw_65328)
cat("  Parsed", nrow(dt_region), "observations\n")

# Save raw
fwrite(dt_region, file.path(data_dir, "ine_epa_65328_raw.csv"))
cat("  Saved to data/ine_epa_65328_raw.csv\n")

# =============================================================================
# Fetch Table 65133: Contract type by economic sector
# =============================================================================

cat("\n--- Table 65133: Contract type by sector ---\n")
raw_65133 <- fetch_ine_table("65133", nult = 60)
dt_sector <- parse_ine_series(raw_65133)
cat("  Parsed", nrow(dt_sector), "observations\n")

fwrite(dt_sector, file.path(data_dir, "ine_epa_65133_raw.csv"))
cat("  Saved to data/ine_epa_65133_raw.csv\n")

# =============================================================================
# Fetch Table 3994: Wage earners by contract type and Autonomous Community
# (alternative table with longer time series)
# =============================================================================

cat("\n--- Table 3994: Wage earners by type and region (long series) ---\n")
raw_3994 <- tryCatch({
  d <- fetch_ine_table("3994", nult = 60)
  dt <- parse_ine_series(d)
  cat("  Parsed", nrow(dt), "observations\n")
  fwrite(dt, file.path(data_dir, "ine_epa_3994_raw.csv"))
  dt
}, error = function(e) {
  cat("  Table 3994 parse error:", e$message, "\n")
  cat("  Proceeding with Table 65328 only.\n")
  NULL
})

# =============================================================================
# Fetch Table 4076: Employment rate by Autonomous Community
# =============================================================================

cat("\n--- Table 4076: Employment/unemployment rates by region ---\n")
tryCatch({
  raw_4076 <- fetch_ine_table("4076", nult = 60)
  dt_rates <- parse_ine_series(raw_4076)
  cat("  Parsed", nrow(dt_rates), "observations\n")
  fwrite(dt_rates, file.path(data_dir, "ine_epa_4076_raw.csv"))
}, error = function(e) {
  cat("  Table 4076 error:", e$message, "\n")
})

# =============================================================================
# Fetch Table 306: DIRCE firms by province and size
# =============================================================================

cat("\n--- Table 306: DIRCE firms by province ---\n")
tryCatch({
  raw_306 <- fetch_ine_table("306", nult = 20)
  dt_firms <- parse_ine_series(raw_306)
  cat("  Parsed", nrow(dt_firms), "observations\n")
  fwrite(dt_firms, file.path(data_dir, "ine_dirce_306_raw.csv"))
}, error = function(e) {
  cat("  Table 306 error:", e$message, "\n")
})

# =============================================================================
# DATA VALIDATION
# =============================================================================

cat("\n=== DATA VALIDATION ===\n")

# Validate main table
stopifnot("Region data must have >100 observations" = nrow(dt_region) > 100)

# Check time coverage
years_present <- sort(unique(dt_region$year))
cat("Years in region data:", paste(years_present, collapse = ", "), "\n")
stopifnot("Must have pre-reform years" = any(years_present < 2022))
stopifnot("Must have post-reform years" = any(years_present >= 2022))

# Check we have enough quarters
n_quarters <- length(unique(dt_region$yq))
cat("Distinct quarters:", n_quarters, "\n")
stopifnot("Need at least 20 quarters" = n_quarters >= 20)

cat("\nData validation PASSED:", nrow(dt_region), "region obs,",
    nrow(dt_sector), "sector obs,", n_quarters, "quarters\n")

cat("\n=== Data fetch complete ===\n")
