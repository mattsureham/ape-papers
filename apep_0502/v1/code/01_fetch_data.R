# ==============================================================================
# 01_fetch_data.R — Fetch EPA AQS and EIA generator data
# Clean Air, Dirty Power? NAAQS Nonattainment and the Clean Energy Transition
# ==============================================================================

source("00_packages.R")

# ==============================================================================
# 1. EPA AQS Annual Summary Data (PM2.5 concentrations by monitor)
# ==============================================================================

cat("\n=== Fetching EPA AQS PM2.5 data ===\n")

aqs_years <- 1999:2023
aqs_all <- list()

for (yr in aqs_years) {
  fname <- file.path(data_dir, paste0("aqs_annual_", yr, ".csv"))

  if (!file.exists(fname)) {
    url <- paste0("https://aqs.epa.gov/aqsweb/airdata/annual_conc_by_monitor_", yr, ".zip")
    zip_path <- file.path(data_dir, paste0("aqs_", yr, ".zip"))

    tryCatch({
      download.file(url, zip_path, mode = "wb", quiet = TRUE)
      # Extract CSV from zip
      csv_name <- unzip(zip_path, list = TRUE)$Name
      csv_name <- csv_name[grepl("\\.csv$", csv_name)]
      unzip(zip_path, files = csv_name, exdir = data_dir, overwrite = TRUE)
      # Rename to standardized name
      extracted <- file.path(data_dir, csv_name)
      if (length(extracted) == 1 && file.exists(extracted)) {
        file.rename(extracted, fname)
      } else {
        # Handle nested directory
        actual_file <- list.files(data_dir, pattern = paste0("annual_conc.*", yr, ".*\\.csv$"),
                                  recursive = TRUE, full.names = TRUE)
        if (length(actual_file) > 0) {
          file.rename(actual_file[1], fname)
        }
      }
      # Clean up zip and any extracted directories
      file.remove(zip_path)
      extracted_dirs <- list.dirs(data_dir, recursive = FALSE)
      for (d in extracted_dirs) {
        if (grepl("annual_conc", d)) unlink(d, recursive = TRUE)
      }
      cat(sprintf("  Downloaded AQS %d\n", yr))
    }, error = function(e) {
      stop(sprintf("Failed to download AQS data for %d: %s\nPivot research question or fix source.", yr, e$message))
    })
  } else {
    cat(sprintf("  AQS %d already cached\n", yr))
  }

  # Read and filter to PM2.5
  tryCatch({
    dt <- fread(fname, select = c(
      "State Code", "County Code", "Parameter Code", "Parameter Name",
      "Pollutant Standard", "Metric Used", "Year", "Arithmetic Mean",
      "Observation Percent", "Completeness Indicator",
      "State Name", "County Name", "CBSA Name",
      "Latitude", "Longitude"
    ))

    # Filter: PM2.5 FRM/FEM, Annual standard
    # Pollutant Standard values look like "PM25 Annual 2012"
    # Metric Used for annual is "Quarterly Means of Daily Means"
    pm25 <- dt[`Parameter Code` %in% c(88101, 88502) &
                 grepl("Annual", `Pollutant Standard`, ignore.case = TRUE)]

    if (nrow(pm25) > 0) {
      pm25[, county_fips := sprintf("%02d%03d", as.integer(`State Code`), as.integer(`County Code`))]
      aqs_all[[as.character(yr)]] <- pm25
      cat(sprintf("    PM2.5 monitors: %d, counties: %d\n", nrow(pm25), uniqueN(pm25$county_fips)))
    } else {
      cat(sprintf("    WARNING: No PM2.5 annual data for %d\n", yr))
    }
  }, error = function(e) {
    cat(sprintf("    ERROR reading AQS %d: %s\n", yr, e$message))
  })
}

aqs_pm25 <- rbindlist(aqs_all, fill = TRUE)
cat(sprintf("\nTotal PM2.5 annual observations: %d\n", nrow(aqs_pm25)))
cat(sprintf("Unique counties: %d, years: %d-%d\n",
            uniqueN(aqs_pm25$county_fips), min(aqs_pm25$Year), max(aqs_pm25$Year)))

# ==============================================================================
# 2. EPA Nonattainment Designations (Green Book)
# ==============================================================================

cat("\n=== Fetching EPA Green Book nonattainment designations ===\n")

# The Green Book data is available as CSV from EPA
# PM2.5 nonattainment areas by county
gb_url <- "https://www3.epa.gov/airquality/greenbook/anayo_pm25.html"

# Parse the Green Book HTML table for PM2.5 nonattainment areas
# We'll construct designation status from our AQS design values instead
# (more precise for RDD than binary Green Book designations)

# Compute county-year design values from AQS monitor data
# PM2.5 annual NAAQS design value = 3-year average of annual mean PM2.5
# weighted by monitor completeness

design_values <- aqs_pm25[, .(
  pm25_mean = mean(`Arithmetic Mean`, na.rm = TRUE),
  n_monitors = .N
), by = .(county_fips, Year, `State Name`, `County Name`)]

setorder(design_values, county_fips, Year)

# Compute 3-year rolling average (design value)
design_values[, design_value := frollmean(pm25_mean, n = 3, align = "right", na.rm = TRUE),
              by = county_fips]

# Determine nonattainment status based on applicable standard
# Pre-2012: Standard was 15 μg/m³
# 2012-2023: Standard is 12 μg/m³
# 2024+: Standard is 9 μg/m³ (designations pending)
design_values[, naaqs_standard := fifelse(Year < 2012, 15, 12)]
design_values[, nonattainment := as.integer(design_value > naaqs_standard)]
design_values[, running_var := design_value - naaqs_standard]

cat(sprintf("Design values computed: %d county-years\n", nrow(design_values[!is.na(design_value)])))
cat(sprintf("Nonattainment county-years (DV > standard): %d\n",
            sum(design_values$nonattainment == 1, na.rm = TRUE)))

# ==============================================================================
# 3. EPA eGRID — Plant-Level Generation, Capacity, and Emissions Data
# ==============================================================================

cat("\n=== Fetching EPA eGRID plant-level data ===\n")

# eGRID provides comprehensive plant-level data with county FIPS codes
# Available years: 2018, 2019, 2020, 2021, 2022
# Each file contains the full plant inventory for that year

if (!requireNamespace("readxl", quietly = TRUE)) install.packages("readxl")
library(readxl)

# Use eGRID 2022 as the primary source (most recent, comprehensive)
# Additional years add panel variation but are not required
egrid_urls <- c(
  "2022" = "https://www.epa.gov/system/files/documents/2024-01/egrid2022_data.xlsx"
)

egrid_all <- list()

for (yr_name in names(egrid_urls)) {
  fname <- file.path(data_dir, paste0("egrid_plants_", yr_name, ".rds"))

  if (file.exists(fname)) {
    egrid_all[[yr_name]] <- readRDS(fname)
    cat(sprintf("  eGRID %s already cached (%d plants)\n", yr_name, nrow(egrid_all[[yr_name]])))
    next
  }

  url <- egrid_urls[yr_name]
  xlsx_path <- file.path(data_dir, paste0("egrid", yr_name, ".xlsx"))

  tryCatch({
    download.file(url, xlsx_path, mode = "wb", quiet = TRUE)

    # Read the PLNT (plant-level) sheet
    sheets <- excel_sheets(xlsx_path)
    plnt_sheet <- sheets[grepl("PLNT", sheets, ignore.case = TRUE)]

    if (length(plnt_sheet) > 0) {
      dt <- as.data.table(read_excel(xlsx_path, sheet = plnt_sheet[1], skip = 1))
      dt[, egrid_year := as.integer(yr_name)]

      saveRDS(dt, fname)
      egrid_all[[yr_name]] <- dt
      cat(sprintf("  eGRID %s: %d plants, %d columns\n", yr_name, nrow(dt), ncol(dt)))
    } else {
      cat(sprintf("  eGRID %s: no PLNT sheet found\n", yr_name))
    }

    file.remove(xlsx_path)
  }, error = function(e) {
    if (yr_name == "2022") {
      stop(sprintf("Failed to download eGRID %s: %s\nPivot research question or fix source.", yr_name, e$message))
    } else {
      cat(sprintf("  WARNING: Could not download eGRID %s: %s (continuing with available data)\n", yr_name, e$message))
    }
  })
}

generators <- rbindlist(egrid_all, fill = TRUE)
cat(sprintf("\nTotal eGRID plant observations: %d\n", nrow(generators)))

# ==============================================================================
# 4. County Demographics from Census ACS
# ==============================================================================

cat("\n=== Fetching county demographics from Census ACS ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY", unset = "")

acs_years <- 2010:2022
acs_all <- list()

for (yr in acs_years) {
  fname <- file.path(data_dir, paste0("acs_county_", yr, ".rds"))

  if (file.exists(fname)) {
    acs_all[[as.character(yr)]] <- readRDS(fname)
    cat(sprintf("  ACS %d already cached\n", yr))
    next
  }

  # ACS 5-year estimates, county level
  # Variables: total pop, median income, manufacturing employment
  variables <- "B01003_001E,B19013_001E,B08006_001E"

  api_url <- paste0(
    "https://api.census.gov/data/", yr, "/acs/acs5?get=NAME,",
    variables, "&for=county:*",
    if (nchar(census_key) > 0) paste0("&key=", census_key) else ""
  )

  tryCatch({
    resp <- httr::GET(api_url, httr::timeout(60))
    if (httr::status_code(resp) == 200) {
      content <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
      dt <- as.data.table(content[-1, ])
      setnames(dt, content[1, ])
      dt[, year := yr]
      dt[, county_fips := paste0(state, county)]
      dt[, total_pop := as.numeric(B01003_001E)]
      dt[, median_income := as.numeric(B19013_001E)]
      dt[, total_workers := as.numeric(B08006_001E)]

      saveRDS(dt, fname)
      acs_all[[as.character(yr)]] <- dt
      cat(sprintf("  ACS %d: %d counties\n", yr, nrow(dt)))
    } else {
      cat(sprintf("  ACS %d: HTTP %d\n", yr, httr::status_code(resp)))
    }
  }, error = function(e) {
    cat(sprintf("  ACS %d failed: %s\n", yr, e$message))
  })

  Sys.sleep(0.3)
}

acs_demo <- rbindlist(acs_all, fill = TRUE)
cat(sprintf("\nTotal ACS observations: %d county-years\n", nrow(acs_demo)))

# ==============================================================================
# 5. Save all fetched data
# ==============================================================================

cat("\n=== Saving compiled datasets ===\n")

saveRDS(aqs_pm25, file.path(data_dir, "aqs_pm25_raw.rds"))
saveRDS(design_values, file.path(data_dir, "design_values.rds"))
saveRDS(generators, file.path(data_dir, "generators_raw.rds"))
saveRDS(acs_demo, file.path(data_dir, "acs_demographics.rds"))

cat("All data saved.\n")

# === DATA VALIDATION (required) ===
stopifnot("PM2.5 data spans multiple years" = uniqueN(aqs_pm25$Year) >= 10)
stopifnot("PM2.5 covers 200+ counties" = uniqueN(aqs_pm25$county_fips) >= 200)
stopifnot("Design values computed" = sum(!is.na(design_values$design_value)) > 1000)
stopifnot("Generator data has observations" = nrow(generators) > 100)

cat(sprintf("\nData validation passed:\n"))
cat(sprintf("  PM2.5: %d rows, %d counties, %d years\n",
            nrow(aqs_pm25), uniqueN(aqs_pm25$county_fips), uniqueN(aqs_pm25$Year)))
cat(sprintf("  Design values: %d county-years with values\n", sum(!is.na(design_values$design_value))))
cat(sprintf("  Generators: %d observations\n", nrow(generators)))
cat(sprintf("  ACS demographics: %d county-years\n", nrow(acs_demo)))
