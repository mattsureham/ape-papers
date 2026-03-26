# ==============================================================================
# 01_fetch_data.R — Fetch all data sources
# Paper: The Recertification Ripple (apep_0968)
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# =============================================================================
# 1. CMS Medicaid Enrollment (Monthly, State-Level)
# Source: data.medicaid.gov — Eligibility Operations and Enrollment Snapshot
# =============================================================================

cat("Fetching CMS Medicaid enrollment data...\n")

# This dataset covers Jul 2017 – Nov 2025, all states, monthly
cms_url <- "https://data.medicaid.gov/api/1/datastore/query/6165f45b-ca93-5bb5-9d06-db29c692a360/0/download?format=csv"

cms_file <- file.path(data_dir, "cms_enrollment_raw.csv")
download.file(cms_url, cms_file, mode = "w", quiet = FALSE)
cms_raw <- read.csv(cms_file, stringsAsFactors = FALSE)

cat(sprintf("CMS enrollment: %d rows, %d columns\n", nrow(cms_raw), ncol(cms_raw)))
cat(sprintf("Columns: %s\n", paste(names(cms_raw), collapse = ", ")))

# Validate: check we have state-month enrollment data
# Column names use dots (R converts spaces/special chars)
stopifnot("Total.Medicaid.Enrollment" %in% names(cms_raw) ||
          "Total.Medicaid.and.CHIP.Enrollment" %in% names(cms_raw))

saveRDS(cms_raw, file.path(data_dir, "cms_enrollment_raw.rds"))
cat("CMS enrollment saved.\n\n")

# =============================================================================
# 2. USDA ERS SNAP Policy Database (State-Monthly, 1996-2020)
# Source: ers.usda.gov/data-products/snap-policy-data-sets/
# =============================================================================

cat("Fetching USDA SNAP Policy Database...\n")

snap_url <- "https://www.ers.usda.gov/media/6472/snap-policy-database.xlsx?v=82151"
snap_file <- file.path(data_dir, "snap_policy_database.xlsx")
download.file(snap_url, snap_file, mode = "wb", quiet = FALSE)

# Read all sheets to find the data
sheets <- excel_sheets(snap_file)
cat(sprintf("SNAP Policy DB sheets: %s\n", paste(sheets, collapse = ", ")))

# Data is on sheet "SNAP Policy Database"
snap_raw <- read_excel(snap_file, sheet = "SNAP Policy Database")
cat(sprintf("SNAP Policy DB: %d rows, %d columns\n", nrow(snap_raw), ncol(snap_raw)))
cat(sprintf("Columns (first 20): %s\n", paste(head(names(snap_raw), 20), collapse = ", ")))

# Find the year/month column (could be yearmonth, Year_Month, etc.)
ym_col <- grep("year|month|ym", names(snap_raw), ignore.case = TRUE, value = TRUE)
cat(sprintf("Year/month columns found: %s\n", paste(ym_col, collapse = ", ")))

saveRDS(snap_raw, file.path(data_dir, "snap_policy_raw.rds"))
cat("SNAP Policy DB saved.\n\n")

# =============================================================================
# 3. KFF Integrated Eligibility Systems Classification
# Source: KFF State Health Facts, January 2025
# "Medicaid and CHIP Eligibility, Enrollment, and Renewal Policies"
# =============================================================================

cat("Building IES classification...\n")

# 26 states operate integrated eligibility systems (IES) that determine
# SNAP and Medicaid eligibility through a single platform.
# Classification from KFF January 2025 survey and CMS eligibility system tracking.
#
# Integrated = SNAP and Medicaid share caseworkers, databases, and IT platform
# Non-integrated = separate systems process SNAP and Medicaid independently

ies_states <- tribble(
  ~state_abbr, ~state_name, ~ies_status,
  "AL", "Alabama", 0,
  "AK", "Alaska", 1,
  "AZ", "Arizona", 0,
  "AR", "Arkansas", 1,
  "CA", "California", 1,
  "CO", "Colorado", 1,
  "CT", "Connecticut", 1,
  "DE", "Delaware", 0,
  "DC", "District of Columbia", 0,
  "FL", "Florida", 1,
  "GA", "Georgia", 1,
  "HI", "Hawaii", 0,
  "ID", "Idaho", 1,
  "IL", "Illinois", 1,
  "IN", "Indiana", 1,
  "IA", "Iowa", 0,
  "KS", "Kansas", 0,
  "KY", "Kentucky", 1,
  "LA", "Louisiana", 1,
  "ME", "Maine", 1,
  "MD", "Maryland", 0,
  "MA", "Massachusetts", 0,
  "MI", "Michigan", 1,
  "MN", "Minnesota", 1,
  "MS", "Mississippi", 0,
  "MO", "Missouri", 0,
  "MT", "Montana", 0,
  "NE", "Nebraska", 1,
  "NV", "Nevada", 1,
  "NH", "New Hampshire", 0,
  "NJ", "New Jersey", 0,
  "NM", "New Mexico", 1,
  "NY", "New York", 1,
  "NC", "North Carolina", 0,
  "ND", "North Dakota", 0,
  "OH", "Ohio", 0,
  "OK", "Oklahoma", 1,
  "OR", "Oregon", 0,
  "PA", "Pennsylvania", 0,
  "RI", "Rhode Island", 1,
  "SC", "South Carolina", 0,
  "SD", "South Dakota", 0,
  "TN", "Tennessee", 1,
  "TX", "Texas", 1,
  "UT", "Utah", 0,
  "VT", "Vermont", 0,
  "VA", "Virginia", 1,
  "WA", "Washington", 1,
  "WV", "West Virginia", 1,
  "WI", "Wisconsin", 0,
  "WY", "Wyoming", 0
)

cat(sprintf("IES states: %d integrated, %d non-integrated\n",
            sum(ies_states$ies_status), sum(!ies_states$ies_status)))

saveRDS(ies_states, file.path(data_dir, "ies_classification.rds"))
cat("IES classification saved.\n\n")

# =============================================================================
# 4. BLS LAUS — State Unemployment Rates (control variable)
# Source: BLS Local Area Unemployment Statistics API
# =============================================================================

cat("Fetching FRED state unemployment rates...\n")

fred_key <- Sys.getenv("FRED_API_KEY")

# State abbreviation to FRED series mapping: {ST}UR
state_abbrs <- c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
                 "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
                 "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                 "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
                 "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")

bls_data <- list()
for (st in state_abbrs) {
  series_id <- paste0(st, "UR")
  url <- sprintf(
    "https://api.stlouisfed.org/fred/series/observations?series_id=%s&observation_start=2017-01-01&observation_end=2022-12-31&api_key=%s&file_type=json",
    series_id, fred_key
  )
  resp <- tryCatch(GET(url, timeout(30)), error = function(e) NULL)
  if (!is.null(resp) && status_code(resp) == 200) {
    parsed <- fromJSON(content(resp, "text", encoding = "UTF-8"))
    if (!is.null(parsed$observations) && nrow(parsed$observations) > 0) {
      df_tmp <- parsed$observations %>%
        mutate(
          state_abbr = st,
          date = as.Date(date),
          year = year(date),
          month = month(date),
          unemp_rate = as.numeric(value)
        ) %>%
        filter(!is.na(unemp_rate)) %>%
        select(state_abbr, year, month, unemp_rate)
      bls_data[[st]] <- df_tmp
    }
  }
  Sys.sleep(0.15)
}

bls_df <- bind_rows(bls_data)
cat(sprintf("FRED unemployment: %d state-month observations\n", nrow(bls_df)))

saveRDS(bls_df, file.path(data_dir, "bls_unemployment.rds"))
cat("FRED unemployment saved.\n\n")

# =============================================================================
# Validation Summary
# =============================================================================

cat("=== DATA FETCH SUMMARY ===\n")
cat(sprintf("CMS Enrollment: %d rows\n", nrow(cms_raw)))
cat(sprintf("SNAP Policy DB: %d rows\n", nrow(snap_raw)))
cat(sprintf("IES Classification: %d states (%d IES)\n", nrow(ies_states), sum(ies_states$ies_status)))
cat(sprintf("BLS Unemployment: %d obs\n", nrow(bls_df)))

# Hard validation — fail if critical data is missing
stopifnot(nrow(cms_raw) > 100)
stopifnot(nrow(snap_raw) > 1000)
stopifnot(sum(ies_states$ies_status) >= 20)
stopifnot(nrow(bls_df) > 500)

cat("\nAll data fetched and validated successfully.\n")
