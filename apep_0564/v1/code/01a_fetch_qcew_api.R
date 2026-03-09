## =============================================================================
## 01a_fetch_qcew_api.R — Fetch BLS QCEW via API (targeted counties only)
## =============================================================================

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

cat("Fetching BLS QCEW data via API (targeted counties)...\n")

# Ensure crosswalk exists before reading
if (!file.exists(file.path(data_dir, "court_county_crosswalk.csv"))) {
  source("01_fetch_data.R")  # This creates the crosswalk
}

# Load court-county crosswalk to get target counties
crosswalk <- fread(file.path(data_dir, "court_county_crosswalk.csv"))
target_fips <- unique(crosswalk$county_fips)
cat("Target counties:", length(target_fips), "\n")

# QCEW API: https://data.bls.gov/cew/data/api/{year}/a/area/{fips}.csv
# Returns annual average for one county-year (all industries)

years <- 2005:2023
target_industries <- c("10", "72", "56", "52", "54")

qcew_all <- list()
errors <- character()

for (fips in target_fips) {
  for (yr in years) {
    cache_key <- paste0("qcew_api_", fips, "_", yr, ".csv")
    cache_file <- file.path(data_dir, cache_key)

    if (file.exists(cache_file)) {
      dt <- fread(cache_file)
      if (nrow(dt) > 0) qcew_all[[cache_key]] <- dt
      next
    }

    url <- paste0("https://data.bls.gov/cew/data/api/", yr, "/a/area/", fips, ".csv")

    tryCatch({
      resp <- GET(url, timeout(30))
      if (status_code(resp) == 200) {
        txt <- content(resp, as = "text", encoding = "UTF-8")
        if (nchar(txt) > 100) {
          dt <- fread(text = txt)
          # Filter to private ownership and target industries
          dt <- dt[own_code == 5 & industry_code %in% target_industries]
          dt[, year := yr]
          dt[, area_fips := fips]
          if (nrow(dt) > 0) {
            fwrite(dt, cache_file)
            qcew_all[[cache_key]] <- dt
          }
        }
      } else if (status_code(resp) == 202 || status_code(resp) == 204) {
        # 202/204 = data not available for this area/year
        NULL
      } else {
        errors <- c(errors, paste(fips, yr, "HTTP", status_code(resp)))
      }
    }, error = function(e) {
      errors <<- c(errors, paste(fips, yr, e$message))
    })

    Sys.sleep(0.2)  # Rate limiting
  }
  cat(".")
}

cat("\n")

if (length(qcew_all) > 0) {
  qcew <- rbindlist(qcew_all, fill = TRUE)
  cat("QCEW data fetched:", nrow(qcew), "rows,",
      n_distinct(qcew$area_fips), "counties,",
      n_distinct(qcew$year), "years\n")

  # Save combined
  fwrite(qcew, file.path(data_dir, "qcew_combined.csv"))

  # Validation
  stopifnot("QCEW must cover 30+ counties" = n_distinct(qcew$area_fips) >= 30)
  stopifnot("QCEW must cover 10+ years" = n_distinct(qcew$year) >= 10)
  cat("QCEW validation passed.\n")
} else {
  stop("No QCEW data fetched. Errors: ", paste(head(errors, 10), collapse = "; "))
}

if (length(errors) > 0) {
  cat("Errors (", length(errors), "):", paste(head(errors, 5), collapse = "; "), "\n")
}
