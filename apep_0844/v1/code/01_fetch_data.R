# 01_fetch_data.R — Fetch IPEDS data from NCES
# apep_0844: State Disinvestment and Enrollment Composition
#
# Uses NCES IPEDS bulk data files (CSV) via their public download portal.
# Key tables: Institutional Characteristics (IC), Finance (F1A),
# Fall Enrollment (EF), Student Financial Aid (SFA), Header (HD)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# IPEDS download helper
# ============================================================================
download_ipeds <- function(survey, year, data_dir) {
  # NCES bulk download URL pattern for provisionally released data
  # Format: https://nces.ed.gov/ipeds/datacenter/data/HD2022.zip
  fname <- paste0(toupper(survey), year)
  url <- paste0("https://nces.ed.gov/ipeds/datacenter/data/", fname, ".zip")
  zip_path <- file.path(data_dir, paste0(fname, ".zip"))
  csv_path <- file.path(data_dir, paste0(tolower(fname), ".csv"))

  if (file.exists(csv_path)) {
    cat("Already downloaded:", fname, "\n")
    return(csv_path)
  }

  cat("Downloading:", url, "\n")
  resp <- httr::GET(url, httr::write_disk(zip_path, overwrite = TRUE),
                    httr::timeout(120))

  if (httr::status_code(resp) != 200) {
    # Try alternate naming: some years use _RV suffix or different patterns
    url2 <- paste0("https://nces.ed.gov/ipeds/datacenter/data/", fname, "_RV.zip")
    resp <- httr::GET(url2, httr::write_disk(zip_path, overwrite = TRUE),
                      httr::timeout(120))
    if (httr::status_code(resp) != 200) {
      stop("Failed to download ", fname, " (HTTP ", httr::status_code(resp), ")")
    }
  }

  # Unzip
  unzip(zip_path, exdir = data_dir)
  unlink(zip_path)

  # Find the CSV (case-insensitive)
  csvs <- list.files(data_dir, pattern = paste0("(?i)^", tolower(survey), ".*", year),
                     full.names = TRUE)
  csvs <- csvs[grepl("\\.csv$", csvs, ignore.case = TRUE)]

  if (length(csvs) == 0) {
    stop("No CSV found after unzipping ", fname)
  }

  # Rename to standardized name
  if (csvs[1] != csv_path) {
    file.rename(csvs[1], csv_path)
  }

  cat("Extracted:", csv_path, "\n")
  return(csv_path)
}

# ============================================================================
# Download key IPEDS files: 2003-2022
# We need: HD (header), IC (inst char), F1A (finance), EF (enrollment), SFA (aid)
# ============================================================================

years <- 2003:2022

# Header files (institution metadata, state FIPS, Carnegie class, control)
cat("\n=== Downloading Header (HD) files ===\n")
for (y in years) {
  tryCatch(download_ipeds("HD", y, data_dir),
           error = function(e) cat("  SKIP HD", y, ":", e$message, "\n"))
}

# Institutional Characteristics (tuition)
cat("\n=== Downloading Institutional Characteristics (IC) files ===\n")
for (y in years) {
  tryCatch(download_ipeds("IC", y, data_dir),
           error = function(e) cat("  SKIP IC", y, ":", e$message, "\n"))
}

# Finance files (state appropriations) — F1A for public institutions
cat("\n=== Downloading Finance (F1A) files ===\n")
for (y in years) {
  fname <- paste0("F", substr(y, 3, 4), substr(y+1, 3, 4), "_F1A")
  url <- paste0("https://nces.ed.gov/ipeds/datacenter/data/", fname, ".zip")
  zip_path <- file.path(data_dir, paste0(fname, ".zip"))
  csv_check <- list.files(data_dir, pattern = paste0("(?i)f", substr(y, 3, 4)),
                          full.names = TRUE)
  csv_check <- csv_check[grepl("f1a.*\\.csv$", csv_check, ignore.case = TRUE)]

  if (length(csv_check) > 0) {
    cat("Already have finance file for", y, "\n")
    next
  }

  cat("Downloading finance:", url, "\n")
  resp <- httr::GET(url, httr::write_disk(zip_path, overwrite = TRUE),
                    httr::timeout(120))
  if (httr::status_code(resp) == 200) {
    unzip(zip_path, exdir = data_dir)
    unlink(zip_path)
    cat("  Extracted finance for", y, "\n")
  } else {
    # Try _RV suffix
    url2 <- paste0("https://nces.ed.gov/ipeds/datacenter/data/", fname, "_RV.zip")
    resp2 <- httr::GET(url2, httr::write_disk(zip_path, overwrite = TRUE),
                       httr::timeout(120))
    if (httr::status_code(resp2) == 200) {
      unzip(zip_path, exdir = data_dir)
      unlink(zip_path)
      cat("  Extracted finance (RV) for", y, "\n")
    } else {
      cat("  SKIP finance", y, ": HTTP", httr::status_code(resp), "\n")
    }
  }
}

# Fall Enrollment (enrollment by race/ethnicity)
cat("\n=== Downloading Fall Enrollment (EF) files ===\n")
for (y in years) {
  # EF files have format: EFCYYYY (enrollment by race) or EF_YYYY_A
  fname <- paste0("EF", y, "A")
  url <- paste0("https://nces.ed.gov/ipeds/datacenter/data/", fname, ".zip")
  zip_path <- file.path(data_dir, paste0(fname, ".zip"))
  csv_check <- list.files(data_dir, pattern = paste0("(?i)ef", y, "a"),
                          full.names = TRUE)
  csv_check <- csv_check[grepl("\\.csv$", csv_check, ignore.case = TRUE)]

  if (length(csv_check) > 0) {
    cat("Already have enrollment file for", y, "\n")
    next
  }

  cat("Downloading enrollment:", url, "\n")
  resp <- httr::GET(url, httr::write_disk(zip_path, overwrite = TRUE),
                    httr::timeout(120))
  if (httr::status_code(resp) == 200) {
    unzip(zip_path, exdir = data_dir)
    unlink(zip_path)
    cat("  Extracted enrollment for", y, "\n")
  } else {
    # Try _RV suffix
    url2 <- paste0("https://nces.ed.gov/ipeds/datacenter/data/", fname, "_RV.zip")
    resp2 <- httr::GET(url2, httr::write_disk(zip_path, overwrite = TRUE),
                       httr::timeout(120))
    if (httr::status_code(resp2) == 200) {
      unzip(zip_path, exdir = data_dir)
      unlink(zip_path)
    } else {
      cat("  SKIP enrollment", y, ": HTTP", httr::status_code(resp), "\n")
    }
  }
}

# Student Financial Aid (Pell grants)
cat("\n=== Downloading Student Financial Aid (SFA) files ===\n")
for (y in years) {
  fname <- paste0("SFA", substr(y, 3, 4), substr(y+1, 3, 4))
  url <- paste0("https://nces.ed.gov/ipeds/datacenter/data/", fname, ".zip")
  zip_path <- file.path(data_dir, paste0(fname, ".zip"))
  csv_check <- list.files(data_dir, pattern = paste0("(?i)sfa", substr(y, 3, 4)),
                          full.names = TRUE)
  csv_check <- csv_check[grepl("\\.csv$", csv_check, ignore.case = TRUE)]

  if (length(csv_check) > 0) {
    cat("Already have SFA file for", y, "\n")
    next
  }

  cat("Downloading SFA:", url, "\n")
  resp <- httr::GET(url, httr::write_disk(zip_path, overwrite = TRUE),
                    httr::timeout(120))
  if (httr::status_code(resp) == 200) {
    unzip(zip_path, exdir = data_dir)
    unlink(zip_path)
    cat("  Extracted SFA for", y, "\n")
  } else {
    url2 <- paste0("https://nces.ed.gov/ipeds/datacenter/data/", fname, "_RV.zip")
    resp2 <- httr::GET(url2, httr::write_disk(zip_path, overwrite = TRUE),
                       httr::timeout(120))
    if (httr::status_code(resp2) == 200) {
      unzip(zip_path, exdir = data_dir)
      unlink(zip_path)
    } else {
      cat("  SKIP SFA", y, ": HTTP", httr::status_code(resp), "\n")
    }
  }
}

# ============================================================================
# Also download state fiscal data from Census Bureau (state gov finances)
# ============================================================================
cat("\n=== Downloading FRED state unemployment data ===\n")

# Use FRED API for national unemployment rate (for Bartik shock)
fred_key <- Sys.getenv("FRED_API_KEY", "")
if (nchar(fred_key) == 0) {
  # Load from .env
  env_lines <- readLines("../../../../.env", warn = FALSE)
  for (line in env_lines) {
    if (grepl("^FRED_API_KEY=", line)) {
      fred_key <- sub("^FRED_API_KEY=", "", line)
      fred_key <- gsub("['\"]", "", fred_key)
    }
  }
}

if (nchar(fred_key) > 0) {
  # Get national GDP growth for Bartik shock component
  fred_url <- paste0("https://api.stlouisfed.org/fred/series/observations?",
                     "series_id=A191RL1Q225SBEA&api_key=", fred_key,
                     "&file_type=json&observation_start=2000-01-01&observation_end=2023-12-31")
  resp <- httr::GET(fred_url, httr::timeout(30))
  if (httr::status_code(resp) == 200) {
    gdp_data <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
    gdp_df <- gdp_data$observations[, c("date", "value")]
    gdp_df$value <- as.numeric(gdp_df$value)
    gdp_df$year <- as.integer(substr(gdp_df$date, 1, 4))
    # Annual average GDP growth
    gdp_annual <- gdp_df %>%
      group_by(year) %>%
      summarize(gdp_growth = mean(value, na.rm = TRUE), .groups = "drop")
    write.csv(gdp_annual, file.path(data_dir, "fred_gdp_growth.csv"), row.names = FALSE)
    cat("FRED GDP growth data saved.\n")
  }

  # Also get total state government tax revenue (annual)
  # Series: QTAXTOTALQTAXCAT1STAXNO for total state tax revenue
  fred_url2 <- paste0("https://api.stlouisfed.org/fred/series/observations?",
                      "series_id=QTAXTOTALQTAXCAT1STAXNO&api_key=", fred_key,
                      "&file_type=json&observation_start=2000-01-01&observation_end=2023-12-31")
  resp2 <- httr::GET(fred_url2, httr::timeout(30))
  if (httr::status_code(resp2) == 200) {
    tax_data <- jsonlite::fromJSON(httr::content(resp2, "text", encoding = "UTF-8"))
    tax_df <- tax_data$observations[, c("date", "value")]
    tax_df$value <- as.numeric(tax_df$value)
    tax_df$year <- as.integer(substr(tax_df$date, 1, 4))
    tax_annual <- tax_df %>%
      group_by(year) %>%
      summarize(total_state_tax = mean(value, na.rm = TRUE), .groups = "drop")
    write.csv(tax_annual, file.path(data_dir, "fred_state_tax_revenue.csv"), row.names = FALSE)
    cat("FRED state tax revenue data saved.\n")
  }
} else {
  cat("WARNING: No FRED API key found. Will construct Bartik from IPEDS data alone.\n")
}

cat("\n=== Data download complete ===\n")
cat("Files in data directory:\n")
cat(paste(list.files(data_dir), collapse = "\n"), "\n")
