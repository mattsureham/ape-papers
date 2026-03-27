## 01_fetch_data.R — Download OSHA ITA 300A Summary data
## apep_1087: Healthcare WVP Mandates and Worker Injuries
##
## Data: OSHA Injury Tracking Application (ITA) 300A establishment-level
## annual injury summaries. Each year is a separate CSV download.
## Source: https://www.osha.gov/Establishment-Specific-Injury-and-Illness-Data

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## --- OSHA ITA 300A data ---
## The OSHA ITA data is available as CSV files from the OSHA data catalog.
## We use the direct download URLs from data.gov / OSHA's public data portal.
## Available years: 2016-2023 (2016 is the first year of electronic reporting)

## OSHA ITA 300A ZIP download URLs (from OSHA public data portal)
## Format: establishment-level records with injury counts
osha_urls <- c(
  "2016" = "https://www.osha.gov/sites/default/files/ITA%20Data%20CY%202016.zip",
  "2017" = "https://www.osha.gov/sites/default/files/ITA%20Data%20CY%202017.zip",
  "2018" = "https://www.osha.gov/sites/default/files/ITA%20Data%20CY%202018.zip",
  "2019" = "https://www.osha.gov/sites/default/files/ITA%20Data%20CY%202019.zip",
  "2020" = "https://www.osha.gov/sites/default/files/ITA-Data-CY-2020.zip",
  "2021" = "https://www.osha.gov/sites/default/files/ITA-data-cy2021.zip",
  "2022" = "https://www.osha.gov/sites/default/files/ITA-data-cy2022.zip",
  "2023" = "https://www.osha.gov/sites/default/files/ITA_300A_Summary_Data_2023_through_12-31-2024.zip"
)

## Download each year (ZIP files)
all_years <- list()

for (yr in names(osha_urls)) {
  csv_file <- file.path(data_dir, paste0("osha_ita_", yr, ".csv"))
  zip_file <- file.path(data_dir, paste0("osha_ita_", yr, ".zip"))

  if (!file.exists(csv_file)) {
    cat("Downloading OSHA ITA", yr, "...\n")
    resp <- httr::GET(
      osha_urls[[yr]],
      httr::write_disk(zip_file, overwrite = TRUE),
      httr::timeout(180),
      httr::user_agent("Mozilla/5.0 APEP-Research")
    )
    if (httr::status_code(resp) != 200) {
      stop("Failed to download OSHA ITA data for year ", yr,
           ": HTTP ", httr::status_code(resp))
    }
    cat("  Downloaded:", round(file.size(zip_file) / 1e6, 1), "MB\n")

    ## Unzip
    csv_names <- unzip(zip_file, list = TRUE)$Name
    cat("  ZIP contents:", paste(csv_names, collapse = ", "), "\n")
    ## Extract CSV files (skip directories)
    csv_to_extract <- csv_names[grepl("\\.(csv|CSV)$", csv_names)]
    if (length(csv_to_extract) == 0) {
      stop("No CSV found in ZIP for year ", yr)
    }
    unzip(zip_file, files = csv_to_extract, exdir = data_dir, overwrite = TRUE)
    ## Rename extracted file to standard name
    extracted <- file.path(data_dir, csv_to_extract[1])
    if (file.exists(extracted) && extracted != csv_file) {
      file.rename(extracted, csv_file)
    }
    ## Clean up zip
    file.remove(zip_file)
  } else {
    cat("Using cached file for", yr, "\n")
  }

  ## Read the CSV
  df_yr <- data.table::fread(csv_file, showProgress = FALSE, fill = TRUE)
  df_yr$data_year <- as.integer(yr)
  all_years[[yr]] <- df_yr
  cat("  Year", yr, ":", nrow(df_yr), "establishments\n")
}

## Inspect column names across years to find the right fields
cat("\n--- Column names (first year) ---\n")
cat(paste(names(all_years[[1]]), collapse = ", "), "\n")

## Harmonize column names across years
## The OSHA ITA data has varied column naming over the years.
## Key fields we need:
##   - State (2-letter or FIPS)
##   - NAICS code (at least 2-digit)
##   - Total injuries (case counts)
##   - DAFW cases (days away from work)
##   - Establishment size (annual average employees)

harmonize_columns <- function(df, year) {
  ## Standardize column names to lowercase
  names(df) <- tolower(names(df))

  ## Map common column name variants
  ## State
  state_col <- grep("^(state|st$|establishment_state)", names(df), value = TRUE)[1]
  ## NAICS
  naics_col <- grep("naics", names(df), value = TRUE)[1]
  ## Total cases (injuries)
  total_col <- grep("(total_injuries|total_other_cases|no_injuries_illnesses)",
                    names(df), value = TRUE)[1]
  ## DAFW cases
  dafw_col <- grep("(total_dafw_cases|dafw_cases|total_days_away)",
                   names(df), value = TRUE)[1]
  ## DJTR cases (days of job transfer or restriction)
  djtr_col <- grep("(total_djtr_cases|djtr_cases|total_days_job_transfer)",
                   names(df), value = TRUE)[1]
  ## Total deaths
  death_col <- grep("(total_deaths|deaths)", names(df), value = TRUE)[1]
  ## Annual average employees
  emp_col <- grep("(annual_average_employees|average_employees|size|annual_avg)",
                  names(df), value = TRUE)[1]
  ## Total hours worked
  hours_col <- grep("(total_hours_worked|hours_worked)", names(df), value = TRUE)[1]

  cat("Year", year, "mapping: state=", state_col, " naics=", naics_col,
      " dafw=", dafw_col, " emp=", emp_col, "\n")

  ## Build standardized data frame
  result <- data.frame(
    state = as.character(df[[state_col]]),
    naics_code = as.character(df[[naics_col]]),
    year = as.integer(year),
    stringsAsFactors = FALSE
  )

  ## Numeric fields — safely convert
  safe_num <- function(x) {
    if (is.null(x)) return(NA_real_)
    suppressWarnings(as.numeric(x))
  }

  if (!is.null(total_col) && !is.na(total_col))
    result$total_injuries <- safe_num(df[[total_col]])
  if (!is.null(dafw_col) && !is.na(dafw_col))
    result$dafw_cases <- safe_num(df[[dafw_col]])
  if (!is.null(djtr_col) && !is.na(djtr_col))
    result$djtr_cases <- safe_num(df[[djtr_col]])
  if (!is.null(death_col) && !is.na(death_col))
    result$deaths <- safe_num(df[[death_col]])
  if (!is.null(emp_col) && !is.na(emp_col))
    result$avg_employees <- safe_num(df[[emp_col]])
  if (!is.null(hours_col) && !is.na(hours_col))
    result$total_hours <- safe_num(df[[hours_col]])

  return(result)
}

## Harmonize all years
harmonized <- lapply(names(all_years), function(yr) {
  harmonize_columns(all_years[[yr]], yr)
})

## Bind all years
osha_raw <- data.table::rbindlist(harmonized, fill = TRUE)
cat("\nCombined dataset:", nrow(osha_raw), "establishment-year records\n")
cat("Years:", paste(sort(unique(osha_raw$year)), collapse = ", "), "\n")
cat("States:", length(unique(osha_raw$state)), "\n")

## Save raw combined data
data.table::fwrite(osha_raw, file.path(data_dir, "osha_ita_combined.csv"))
cat("Saved combined data to", file.path(data_dir, "osha_ita_combined.csv"), "\n")

## --- Validation assertions ---
stopifnot("No data loaded" = nrow(osha_raw) > 0)
stopifnot("Missing years" = length(unique(osha_raw$year)) >= 6)
stopifnot("Missing states" = length(unique(osha_raw$state)) >= 40)

cat("\n=== Data fetch complete ===\n")
