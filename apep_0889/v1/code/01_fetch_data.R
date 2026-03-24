# 01_fetch_data.R — Download QCEW, MIT Election Lab, EAVS, and Census data
# APEP-0889: Slower Mail, Fewer Voters

source("00_packages.R")
set.seed(20260324)

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# 1. BLS QCEW: USPS establishments by county (NAICS 491110), 2014-2023
# ============================================================================
cat("=== Downloading QCEW data (NAICS 491110) ===\n")

qcew_years <- 2014:2023
qcew_list <- list()

for (yr in qcew_years) {
  url <- sprintf("https://data.bls.gov/cew/data/api/%d/a/industry/491110.csv", yr)
  cat(sprintf("  Fetching %d... ", yr))

  resp <- tryCatch(
    GET(url, timeout(60)),
    error = function(e) {
      cat(sprintf("ERROR: %s\n", e$message))
      return(NULL)
    }
  )

  if (is.null(resp) || status_code(resp) != 200) {
    cat(sprintf("FAILED (HTTP %s)\n", ifelse(is.null(resp), "ERR", status_code(resp))))
    stop(sprintf("QCEW data unavailable for %d. Cannot proceed.", yr))
  }

  raw_text <- content(resp, as = "text", encoding = "UTF-8")
  df_yr <- fread(text = raw_text)
  df_yr$year <- yr
  qcew_list[[as.character(yr)]] <- df_yr
  cat(sprintf("OK (%d rows)\n", nrow(df_yr)))
}

qcew_raw <- rbindlist(qcew_list, fill = TRUE)

# Filter to county-level, federal government (own_code=1) USPS establishments
qcew_county <- qcew_raw[
  own_code == 1 &
  nchar(area_fips) == 5 &
  !grepl("^(US|C[0-9]|CS)", area_fips) &
  agglvl_code == 78,  # County-level, 6-digit NAICS
  .(fips = area_fips,
    year,
    usps_estabs = annual_avg_estabs,
    usps_emp = annual_avg_emplvl,
    disclosure = disclosure_code)
]

# Drop suppressed observations
qcew_county <- qcew_county[disclosure == "" | is.na(disclosure)]

cat(sprintf("\nQCEW panel: %d county-years, %d unique counties\n",
            nrow(qcew_county), uniqueN(qcew_county$fips)))

fwrite(qcew_county, file.path(data_dir, "qcew_usps_county.csv"))

# ============================================================================
# 2. MIT Election Lab: County Presidential Returns 2000-2024
# ============================================================================
cat("\n=== Downloading MIT Election Lab county presidential returns ===\n")

mit_url <- "https://dataverse.harvard.edu/api/access/datafile/13573089"
mit_file <- file.path(data_dir, "countypres_2000_2024.csv")

resp_mit <- GET(mit_url, timeout(120), write_disk(mit_file, overwrite = TRUE))
if (status_code(resp_mit) != 200) {
  stop(sprintf("MIT Election Lab download failed: HTTP %d", status_code(resp_mit)))
}

mit_raw <- fread(mit_file)
cat(sprintf("MIT Election Lab: %d rows, years %d-%d\n",
            nrow(mit_raw), min(mit_raw$year), max(mit_raw$year)))

# ============================================================================
# 3. EAC EAVS: Mail-in ballot and registration data (2016-2024)
# ============================================================================
cat("\n=== Downloading EAC EAVS data ===\n")

eavs_files <- list(
  "2018" = "https://www.eac.gov/sites/default/files/Research/EAVS_2018_for_Public_Release_Updates3.csv",
  "2020" = "https://www.eac.gov/sites/default/files/2023-12/2020_EAVS_for_Public_Release_nolabel_V1.2_CSV.zip",
  "2022" = "https://www.eac.gov/media/258536",
  "2024" = "https://www.eac.gov/sites/default/files/2026-02/2024_EAVS_for_Public_Release_nolabel_V2_csv.zip"
)

eavs_list <- list()

for (yr_name in names(eavs_files)) {
  url <- eavs_files[[yr_name]]
  cat(sprintf("  Fetching EAVS %s... ", yr_name))

  dest <- file.path(data_dir, sprintf("eavs_%s_raw", yr_name))

  resp <- tryCatch(
    GET(url, timeout(120), write_disk(paste0(dest, ifelse(grepl("\\.zip", url), ".zip", ".csv")),
                                       overwrite = TRUE)),
    error = function(e) {
      cat(sprintf("ERROR: %s\n", e$message))
      return(NULL)
    }
  )

  if (is.null(resp) || status_code(resp) >= 400) {
    cat(sprintf("FAILED (HTTP %s) — will proceed without EAVS %s\n",
                ifelse(is.null(resp), "ERR", status_code(resp)), yr_name))
    next
  }

  # Handle ZIP files
  if (grepl("\\.zip", url)) {
    zip_file <- paste0(dest, ".zip")
    exdir <- file.path(data_dir, sprintf("eavs_%s", yr_name))
    dir.create(exdir, showWarnings = FALSE)
    unzip(zip_file, exdir = exdir)
    csv_files <- list.files(exdir, pattern = "\\.csv$", full.names = TRUE)
    if (length(csv_files) > 0) {
      eavs_list[[yr_name]] <- tryCatch(
        fread(csv_files[1], fill = TRUE),
        error = function(e) { cat(sprintf("  Parse error: %s\n", e$message)); NULL }
      )
    }
  } else {
    csv_file <- paste0(dest, ".csv")
    eavs_list[[yr_name]] <- tryCatch(
      fread(csv_file, fill = TRUE),
      error = function(e) { cat(sprintf("  Parse error: %s\n", e$message)); NULL }
    )
  }

  if (!is.null(eavs_list[[yr_name]])) {
    cat(sprintf("OK (%d rows, %d cols)\n", nrow(eavs_list[[yr_name]]),
                ncol(eavs_list[[yr_name]])))
  }
}

cat(sprintf("\nEAVS years downloaded: %s\n", paste(names(eavs_list), collapse = ", ")))

# Save EAVS metadata for later parsing
saveRDS(eavs_list, file.path(data_dir, "eavs_raw_list.rds"))

# ============================================================================
# 4. Census ACS: County demographics (via tidycensus)
# ============================================================================
cat("\n=== Downloading Census ACS county demographics ===\n")

census_api_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_api_key) > 0) {
  library(tidycensus)
  census_api_key(census_api_key, install = FALSE)

  # Variables: total pop, median income, % rural, % 65+, % non-white, internet access
  acs_vars <- c(
    total_pop = "B01003_001",
    median_income = "B19013_001",
    pop_65_plus = "B01001_020",  # Male 65-66 (will sum age groups)
    pop_white = "B02001_002",
    pop_total_race = "B02001_001",
    internet_sub = "B28002_004"   # With internet subscription
  )

  acs_years <- c(2015, 2019, 2022)
  acs_list <- list()

  for (yr in acs_years) {
    cat(sprintf("  Fetching ACS %d... ", yr))
    acs_data <- tryCatch(
      get_acs(
        geography = "county",
        variables = names(acs_vars),
        year = yr,
        survey = "acs5",
        output = "wide",
        cache_table = TRUE
      ),
      error = function(e) {
        cat(sprintf("ERROR: %s\n", e$message))
        return(NULL)
      }
    )

    if (!is.null(acs_data)) {
      acs_data$acs_year <- yr
      acs_list[[as.character(yr)]] <- acs_data
      cat(sprintf("OK (%d counties)\n", nrow(acs_data)))
    }
  }

  if (length(acs_list) > 0) {
    acs_combined <- bind_rows(acs_list)
    fwrite(acs_combined, file.path(data_dir, "census_acs_county.csv"))
    cat(sprintf("\nCensus ACS: %d county-year observations\n", nrow(acs_combined)))
  }
} else {
  cat("  CENSUS_API_KEY not set — skipping ACS download.\n")
  cat("  Will use QCEW employment data as demographic proxy.\n")
}

# ============================================================================
# Summary
# ============================================================================
cat("\n=== Data Fetch Summary ===\n")
cat(sprintf("QCEW USPS: %d county-years (%d-%d)\n",
            nrow(qcew_county), min(qcew_county$year), max(qcew_county$year)))
cat(sprintf("MIT Election Lab: %d rows\n", nrow(mit_raw)))
cat(sprintf("EAVS: %d years downloaded\n", length(eavs_list)))
cat(sprintf("Census ACS: %s\n",
            ifelse(exists("acs_combined"), sprintf("%d rows", nrow(acs_combined)), "skipped")))
cat("\nData fetch complete.\n")
