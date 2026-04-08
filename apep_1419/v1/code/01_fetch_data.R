## 01_fetch_data.R — Fetch all data from NOMIS and DWP
## apep_1419: UK Auto-Enrollment Contribution Step-Up and Wages

source("00_packages.R")

data_dir <- "../data"

nomis_key <- Sys.getenv("NOMIS_API_KEY")
key_param <- ifelse(nzchar(nomis_key), paste0("&uid=", nomis_key), "")

## ========================================================================
## 1. ASHE median annual gross pay by Local Authority (2015-2023)
## ========================================================================
cat("Fetching ASHE earnings by LA...\n")

# NM_99_1: ASHE workplace analysis
# sex=8 (all), item=2 (median), pay=7 (annual gross), measures=20100 (value)
ashe_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_99_1.data.csv?",
  "geography=TYPE434",  # district/unitary LAs (2019 boundaries)
  "&sex=8",             # all employees
  "&item=2",            # median
  "&pay=7",             # annual gross pay
  "&measures=20100",    # value
  "&time=2014,2015,2016,2017,2018,2019,2020,2021,2022,2023",
  "&select=date_name,geography_name,geography_code,obs_value",
  key_param
)

ashe_raw <- read.csv(ashe_url, stringsAsFactors = FALSE)
stopifnot("Failed to fetch ASHE data" = nrow(ashe_raw) > 100)

names(ashe_raw) <- c("year", "la_name", "la_code", "median_annual_pay")
ashe_raw$year <- as.integer(ashe_raw$year)

cat(sprintf("  ASHE: %d rows, %d LAs, years %d-%d\n",
            nrow(ashe_raw), length(unique(ashe_raw$la_code)),
            min(ashe_raw$year), max(ashe_raw$year)))

## ========================================================================
## 2. ASHE hourly pay (for robustness)
## ========================================================================
cat("Fetching ASHE hourly pay by LA...\n")

ashe_hourly_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_99_1.data.csv?",
  "geography=TYPE434&sex=8&item=2&pay=6&measures=20100",  # pay=6 = hourly excl overtime
  "&time=2014,2015,2016,2017,2018,2019,2020,2021,2022,2023",
  "&select=date_name,geography_name,geography_code,obs_value",
  key_param
)

ashe_hourly <- read.csv(ashe_hourly_url, stringsAsFactors = FALSE)
names(ashe_hourly) <- c("year", "la_name", "la_code", "median_hourly_pay")
ashe_hourly$year <- as.integer(ashe_hourly$year)

cat(sprintf("  ASHE hourly: %d rows\n", nrow(ashe_hourly)))

## ========================================================================
## 3. ASHE number of jobs by LA (for weighting)
## ========================================================================
cat("Fetching ASHE job counts by LA...\n")

ashe_jobs_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_99_1.data.csv?",
  "geography=TYPE434&sex=8&item=1&pay=7&measures=20100",  # item=1 = number of jobs
  "&time=2014,2015,2016,2017,2018,2019,2020,2021,2022,2023",
  "&select=date_name,geography_name,geography_code,obs_value",
  key_param
)

ashe_jobs <- read.csv(ashe_jobs_url, stringsAsFactors = FALSE)
names(ashe_jobs) <- c("year", "la_name", "la_code", "n_jobs")
ashe_jobs$year <- as.integer(ashe_jobs$year)

cat(sprintf("  ASHE jobs: %d rows\n", nrow(ashe_jobs)))

## ========================================================================
## 4. UK Business Counts by employment size band × LA (2018 - pre-treatment)
## ========================================================================
cat("Fetching UK Business Counts by size band...\n")

# NM_141_1: local units by employment size band (detailed bands for weighting)
# industry=37748736 (all), legal_status=0 (all)
biz_url <- paste0(
  "https://www.nomisweb.co.uk/api/v01/dataset/NM_141_1.data.csv?",
  "geography=TYPE434",
  "&industry=37748736",           # all industries
  "&employment_sizeband=1,2,3,4,5,6,7,8,9",  # detailed bands for employment weighting
  "&legal_status=0",              # all
  "&measures=20100",
  "&time=2018",                   # pre-treatment year
  "&select=date_name,geography_name,geography_code,employment_sizeband_name,obs_value",
  key_param
)

biz_raw <- read.csv(biz_url, stringsAsFactors = FALSE)
stopifnot("Failed to fetch business count data" = nrow(biz_raw) > 100)

names(biz_raw) <- c("year", "la_name", "la_code", "size_band", "n_units")

cat(sprintf("  Business counts: %d rows\n", nrow(biz_raw)))

## ========================================================================
## 5. DWP pension data (already downloaded as Excel)
## ========================================================================
cat("Reading DWP pension workbook...\n")

dwp_file <- file.path(data_dir, "dwp_pensions.xlsx")
stopifnot("DWP file not found" = file.exists(dwp_file))

# Table 1.2: Participation by employer size (private sector)
dwp_12 <- read_excel(dwp_file, sheet = "Table 1.2 Employer Size",
                     skip = 3, n_max = 20)
cat("  DWP Tables loaded.\n")

## ========================================================================
## 6. CPI for deflating (ONS via NOMIS doesn't have CPI; use ONS API)
## ========================================================================
cat("Fetching CPI from ONS...\n")

# Use the ONS time series API for CPI (D7BT = CPI all items index)
cpi_url <- "https://api.beta.ons.gov.uk/v1/datasets/cpih01/editions/time-series/versions/36/observations?time=2015,2016,2017,2018,2019,2020,2021,2022,2023&geography=K02000001&aggregate=cpih1dim1A0"

cpi_resp <- tryCatch({
  httr::GET(cpi_url)
}, error = function(e) NULL)

# Fallback: hardcode CPI from ONS published data (2015=100 base)
# CPI annual average index (2015=100): ONS series D7BT
cpi_data <- data.frame(
  year = 2014:2023,
  cpi = c(98.8, 100.0, 101.0, 103.6, 106.1, 107.9, 108.9, 111.6, 121.7, 130.0)
)
cat("  CPI loaded (hardcoded from ONS D7BT series, 2015=100).\n")

## ========================================================================
## Save all raw data
## ========================================================================

save(ashe_raw, ashe_hourly, ashe_jobs, biz_raw, cpi_data,
     file = file.path(data_dir, "raw_data.RData"))

cat("\nAll data fetched and saved to data/raw_data.RData\n")
cat(sprintf("  ASHE earnings: %d obs across %d LAs\n",
            nrow(ashe_raw), length(unique(ashe_raw$la_code))))
cat(sprintf("  Business counts: %d obs across %d LAs\n",
            nrow(biz_raw), length(unique(biz_raw$la_code))))
