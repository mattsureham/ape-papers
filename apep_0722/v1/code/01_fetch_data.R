# 01_fetch_data.R — Fetch OECD CPI data via SDMX API
# apep_0722: Japan's Split-Rate Consumption Tax

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ===================================================================
# OECD SDMX API: Monthly CPI by COICOP for Japan
# ===================================================================

# COICOP divisions
coicop_codes <- c("CP01", "CP02", "CP03", "CP04", "CP05", "CP06",
                  "CP07", "CP08", "CP09", "CP10", "CP11", "CP12", "_T")
coicop_labels <- c("Food", "Alcohol/Tobacco", "Clothing", "Housing",
                   "Furnishings", "Health", "Transport", "Communications",
                   "Recreation", "Education", "Restaurants/Hotels",
                   "Miscellaneous", "All Items")

# Try OECD SDMX REST API
# Format: https://sdmx.oecd.org/public/rest/data/{flow}/{key}
cat("Fetching OECD CPI data for Japan...\n")

# Build the query
coicop_str <- paste(coicop_codes, collapse = "+")
url <- sprintf(
  "https://sdmx.oecd.org/public/rest/data/OECD.SDD.TPS,DSD_PRICES@DF_PRICES_ALL,1.0/JPN.M.N.CPI.IX.%s.N.?startPeriod=2012-01&endPeriod=2020-12&dimensionAtObservation=AllDimensions",
  coicop_str
)

cat(sprintf("URL: %s\n", substr(url, 1, 100)))

# Fetch as CSV
csv_url <- url
headers <- c("Accept" = "application/vnd.sdmx.data+csv;file=true")

result <- tryCatch({
  # Download to temp file
  tmp <- tempfile(fileext = ".csv")
  download.file(csv_url, tmp, mode = "wb", quiet = TRUE,
                headers = c("Accept" = "application/vnd.sdmx.data+csv"))
  lines <- readLines(tmp, warn = FALSE)
  cat(sprintf("Downloaded %d lines\n", length(lines)))
  if (length(lines) > 1) {
    df <- read.csv(tmp, stringsAsFactors = FALSE)
    df
  } else {
    NULL
  }
}, error = function(e) {
  cat(sprintf("CSV download error: %s\n", conditionMessage(e)))
  NULL
})

# If CSV didn't work, try JSON-stat or XML
if (is.null(result) || nrow(result) < 10) {
  cat("Trying alternative SDMX approach...\n")

  # Try each COICOP individually with simpler URL
  all_data <- list()
  for (i in seq_along(coicop_codes)) {
    cp <- coicop_codes[i]
    api_url <- sprintf(
      "https://sdmx.oecd.org/public/rest/data/OECD.SDD.TPS,DSD_PRICES@DF_PRICES_ALL,1.0/JPN.M.N.CPI.IX.%s.N.?startPeriod=2012-01&endPeriod=2020-12",
      cp
    )

    cat(sprintf("  Fetching %s (%s)...", cp, coicop_labels[i]))

    resp <- tryCatch({
      tmp <- tempfile(fileext = ".csv")
      download.file(api_url, tmp, mode = "wb", quiet = TRUE,
                    headers = c("Accept" = "application/vnd.sdmx.data+csv"))
      df <- read.csv(tmp, stringsAsFactors = FALSE)
      cat(sprintf(" %d obs\n", nrow(df)))
      df$coicop <- cp
      df$coicop_label <- coicop_labels[i]
      df
    }, error = function(e) {
      cat(sprintf(" ERROR: %s\n", conditionMessage(e)))
      NULL
    })

    if (!is.null(resp) && nrow(resp) > 0) {
      all_data[[cp]] <- resp
    }
    Sys.sleep(0.5)
  }

  if (length(all_data) > 0) {
    result <- bind_rows(all_data)
  }
}

if (is.null(result) || nrow(result) < 10) {
  # Fallback: try the older OECD.Stat API
  cat("\nTrying OECD.Stat legacy API...\n")

  all_data <- list()
  for (i in seq_along(coicop_codes)) {
    cp <- coicop_codes[i]
    # Legacy API format
    api_url <- sprintf(
      "https://stats.oecd.org/SDMX-JSON/data/PRICES_CPI/JPN.%s.IXOB.M/all?startTime=2012&endTime=2020",
      cp
    )

    cat(sprintf("  Fetching %s...", cp))

    resp <- tryCatch({
      json_text <- readLines(api_url, warn = FALSE)
      parsed <- jsonlite::fromJSON(paste(json_text, collapse = ""))

      # Extract observations
      obs <- parsed$dataSets[[1]]$series
      if (length(obs) > 0) {
        # Get the first series
        series_key <- names(obs)[1]
        values <- obs[[series_key]]$observations

        # Get time periods
        times <- parsed$structure$dimensions$observation[[1]]$values
        time_ids <- times$id

        # Build dataframe
        obs_vals <- unlist(lapply(values, function(x) x[[1]]))
        obs_idx <- as.integer(names(values))

        df <- data.frame(
          coicop = cp,
          coicop_label = coicop_labels[i],
          time_period = time_ids[obs_idx + 1],
          value = obs_vals,
          stringsAsFactors = FALSE
        )
        cat(sprintf(" %d obs\n", nrow(df)))
        df
      } else {
        cat(" no data\n")
        NULL
      }
    }, error = function(e) {
      cat(sprintf(" error: %s\n", conditionMessage(e)))
      NULL
    })

    if (!is.null(resp)) all_data[[cp]] <- resp
    Sys.sleep(0.3)
  }

  if (length(all_data) > 0) {
    result <- bind_rows(all_data)
  }
}

if (is.null(result) || nrow(result) < 10) {
  stop("FATAL: Could not retrieve OECD CPI data. API may be down.")
}

cat(sprintf("\nTotal observations: %d\n", nrow(result)))
cat(sprintf("Categories: %s\n", paste(unique(result$coicop), collapse = ", ")))

# ===================================================================
# STANDARDIZE COLUMN NAMES
# ===================================================================

# The SDMX CSV format varies; standardize
if ("TIME_PERIOD" %in% names(result)) {
  result <- result %>% rename(time_period = TIME_PERIOD)
}
if ("OBS_VALUE" %in% names(result)) {
  result <- result %>% rename(value = OBS_VALUE)
}
if ("COICOP" %in% names(result)) {
  result <- result %>% rename(coicop = COICOP)
} else if ("EXPENDITURE" %in% names(result)) {
  result <- result %>% rename(coicop = EXPENDITURE)
}

# Parse time period to year-month
result <- result %>%
  mutate(
    year = as.integer(substr(time_period, 1, 4)),
    month = as.integer(substr(time_period, 6, 7)),
    ym = year + (month - 1) / 12,
    cpi = as.numeric(value)
  ) %>%
  filter(!is.na(cpi))

cat(sprintf("Parsed: %d obs, %d categories, %s to %s\n",
            nrow(result), length(unique(result$coicop)),
            min(result$time_period), max(result$time_period)))

# ===================================================================
# QUICK VALIDATION: Check 2019 tax hike effect
# ===================================================================

cat("\n--- CPI around Oct 2019 tax hike ---\n")
result %>%
  filter(coicop %in% c("CP01", "CP11", "_T"),
         year == 2019, month %in% 9:11) %>%
  select(coicop, time_period, cpi) %>%
  arrange(coicop, time_period) %>%
  print()

# Save
saveRDS(result, file.path(data_dir, "oecd_cpi_japan.rds"))
cat("\nData saved.\n")
