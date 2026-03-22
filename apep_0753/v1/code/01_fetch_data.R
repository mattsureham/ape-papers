# ============================================================
# 01_fetch_data.R — Fetch SNAP retailer and benefits data
# apep_0753: The Hunger Cliff and the Corner Store
# ============================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ----------------------------------------------------------
# 1. SNAP Retailer Historical Database (USDA FNS)
# ----------------------------------------------------------
cat("=== Downloading SNAP Retailer Historical Database ===\n")

retailer_url <- "https://www.fns.usda.gov/sites/default/files/resource-files/snap-retailer-locator-data2005-2025.zip"
zip_path <- file.path(data_dir, "snap_retailers.zip")

if (!file.exists(file.path(data_dir, "snap_retailers_raw.csv"))) {
  resp <- httr::GET(retailer_url, httr::write_disk(zip_path, overwrite = TRUE),
                    httr::timeout(300))
  stopifnot("SNAP retailer download failed" = httr::status_code(resp) == 200)
  cat("  Downloaded:", round(file.size(zip_path) / 1e6, 1), "MB\n")

  # Unzip
  csv_files <- unzip(zip_path, exdir = data_dir)
  cat("  Extracted files:", paste(basename(csv_files), collapse = ", "), "\n")

  # Find the main CSV
  main_csv <- csv_files[grepl("\\.csv$", csv_files, ignore.case = TRUE)][1]
  stopifnot("No CSV found in zip" = !is.na(main_csv))
  file.rename(main_csv, file.path(data_dir, "snap_retailers_raw.csv"))
  unlink(zip_path)
} else {
  cat("  Already downloaded, skipping.\n")
}

# Read and validate
retailers <- fread(file.path(data_dir, "snap_retailers_raw.csv"),
                   showProgress = FALSE)
cat("  Rows:", nrow(retailers), "\n")
cat("  Columns:", paste(names(retailers), collapse = ", "), "\n")

# Check key columns exist
expected_cols <- c("State")
for (col in expected_cols) {
  if (!col %in% names(retailers)) {
    cat("  WARNING: Expected column", col, "not found. Available:",
        paste(head(names(retailers), 20), collapse = ", "), "\n")
  }
}

cat("  Store types:\n")
# Find the store type column
type_col <- names(retailers)[grepl("type|category|store.*type", names(retailers),
                                    ignore.case = TRUE)]
if (length(type_col) > 0) {
  print(table(retailers[[type_col[1]]]))
}

# ----------------------------------------------------------
# 2. FNS State-Monthly SNAP Participation & Benefits
# ----------------------------------------------------------
cat("\n=== Fetching FNS State-Monthly SNAP Data ===\n")

# Try direct USDA FNS data download
# The FNS data is available at:
# https://www.fns.usda.gov/pd/supplemental-nutrition-assistance-program-snap
# We'll try the direct CSV endpoints

# State-level monthly data: persons and benefits
# Available via the USDA data API or direct download
fns_base <- "https://www.fns.usda.gov/pd/supplemental-nutrition-assistance-program-snap"

# Try getting participation data by fiscal year
# FNS publishes state-level monthly data as Excel files
# Let's try the direct data endpoint

# Alternative: Use FRED API for state-level SNAP data
fred_key <- Sys.getenv("FRED_API_KEY")
if (nchar(fred_key) > 0) {
  cat("  Using FRED API for state-level SNAP data...\n")

  # FRED has SNAP participation by state with series like BRXX (XX = state FIPS)
  # Also snap_persons_XX for each state

  # State FIPS codes
  state_fips <- data.frame(
    state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
                   "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
                   "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
                   "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
                   "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY","DC"),
    fips = sprintf("%02d", c(1,2,4,5,6,8,9,10,12,13,
                              15,16,17,18,19,20,21,22,23,24,
                              25,26,27,28,29,30,31,32,33,34,
                              35,36,37,38,39,40,41,42,44,45,
                              46,47,48,49,50,51,53,54,55,56,11)),
    stringsAsFactors = FALSE
  )

  # FRED series: BRXX000SNAP for SNAP persons by state (monthly)
  # Actually the series ID format is: SNAP_[STATE]
  # Let me try a few known FRED SNAP series

  # Try FRED series for SNAP persons participating
  # Series: SUPPSNAP_[STATE_FIPS] or BR[FIPS]000SNAP
  fred_fetch <- function(series_id) {
    url <- paste0("https://api.stlouisfed.org/fred/series/observations?",
                  "series_id=", series_id,
                  "&api_key=", fred_key,
                  "&file_type=json",
                  "&observation_start=2019-01-01",
                  "&observation_end=2024-12-31")
    resp <- httr::GET(url, httr::timeout(30))
    if (httr::status_code(resp) == 200) {
      content <- httr::content(resp, "parsed")
      if (!is.null(content$observations) && length(content$observations) > 0) {
        return(bind_rows(lapply(content$observations, as.data.frame)))
      }
    }
    return(NULL)
  }

  # Try getting total US SNAP participation first as validation
  test <- fred_fetch("SNAP")
  if (!is.null(test)) {
    cat("  FRED SNAP data available. Total US series has", nrow(test), "observations.\n")
  }
}

# ----------------------------------------------------------
# 2b. Construct state-monthly panel from retailer data
# ----------------------------------------------------------
# Since FNS state-monthly data may require manual download,
# we can construct our treatment from the retailer panel itself.
# The key treatment variable is EA expiration dates, which we hardcode
# from official USDA/CBPP sources.

cat("\n=== Constructing EA Expiration Treatment ===\n")

# Emergency Allotment expiration dates by state
# Sources: USDA FNS, CBPP, Lakhani et al. (2024 Health Affairs)
# Format: last month EA was issued
ea_dates <- data.frame(
  state_abbr = c(
    # Early opt-out states (18 total)
    "ID",  # Idaho - first to opt out
    "MT",  # Montana
    "ND",  # North Dakota
    "NE",  # Nebraska
    "SD",  # South Dakota
    "WY",  # Wyoming
    "TN",  # Tennessee
    "FL",  # Florida
    "IA",  # Iowa
    "MS",  # Mississippi
    "MO",  # Missouri
    "IN",  # Indiana
    "AK",  # Alaska
    "AZ",  # Arizona
    "AR",  # Arkansas
    "GA",  # Georgia
    "KY",  # Kentucky
    "SC",  # South Carolina
    # Remaining states + DC: March 2023 universal termination
    "AL","CA","CO","CT","DE","DC","HI","IL","KS","LA",
    "ME","MD","MA","MI","MN","NV","NH","NJ","NM","NY",
    "NC","OH","OK","OR","PA","RI","TX","UT","VT","VA",
    "WA","WV","WI"
  ),
  ea_last_month = as.Date(c(
    # Early opt-outs (last month EA was issued)
    "2021-04-01",  # Idaho: April 2021
    "2021-07-01",  # Montana: July 2021
    "2021-09-01",  # North Dakota: September 2021
    "2021-07-01",  # Nebraska: July 2021
    "2021-07-01",  # South Dakota: July 2021
    "2021-07-01",  # Wyoming: July 2021
    "2021-07-01",  # Tennessee: July 2021
    "2021-07-01",  # Florida: July 2021
    "2021-07-01",  # Iowa: July 2021
    "2021-07-01",  # Mississippi: July 2021
    "2021-07-01",  # Missouri: July 2021
    "2021-08-01",  # Indiana: August 2021
    "2022-03-01",  # Alaska: March 2022
    "2022-04-01",  # Arizona: April 2022
    "2022-06-01",  # Arkansas: June 2022
    "2022-06-01",  # Georgia: June 2022
    "2022-06-01",  # Kentucky: June 2022
    "2023-01-01",  # South Carolina: January 2023
    # Universal termination: last EA in February 2023
    rep("2023-02-01", 33)
  )),
  early_optout = c(rep(TRUE, 18), rep(FALSE, 33)),
  stringsAsFactors = FALSE
)

cat("  Early opt-out states:", sum(ea_dates$early_optout), "\n")
cat("  Universal termination states:", sum(!ea_dates$early_optout), "\n")
cat("  Date range:", as.character(min(ea_dates$ea_last_month)), "to",
    as.character(max(ea_dates$ea_last_month)), "\n")

# Save treatment data
saveRDS(ea_dates, file.path(data_dir, "ea_expiration_dates.rds"))

# ----------------------------------------------------------
# 3. Validate data
# ----------------------------------------------------------
cat("\n=== Data Validation ===\n")

# Retailer data
n_retailers <- nrow(retailers)
cat("  Total retailers:", format(n_retailers, big.mark = ","), "\n")

stopifnot("Retailer data must have > 100K rows" = n_retailers > 100000)

# Save raw data summary
cat("  Data fetch complete.\n")
