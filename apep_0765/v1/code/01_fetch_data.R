# ============================================================
# 01_fetch_data.R — Fetch HMDA and SNAP data
# apep_0765: SNAP Retailer Exits and Mortgage Access
# ============================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ----------------------------------------------------------
# 1. SNAP Retailer Historical Database (reuse if available)
# ----------------------------------------------------------
cat("=== Loading SNAP Retailer Data ===\n")

snap_sources <- c(
  "../../apep_0753/v1/data/snap_retailers_raw.csv",
  "../../apep_0757/v1/data/snap_retailers_raw.csv"
)
snap_local <- file.path(data_dir, "snap_retailers_raw.csv")

if (!file.exists(snap_local)) {
  copied <- FALSE
  for (src in snap_sources) {
    if (file.exists(src)) {
      file.copy(src, snap_local)
      cat("  Copied from", src, "\n")
      copied <- TRUE
      break
    }
  }
  if (!copied) {
    cat("  Downloading fresh...\n")
    url <- "https://www.fns.usda.gov/sites/default/files/resource-files/snap-retailer-locator-data2005-2025.zip"
    zip_path <- file.path(data_dir, "snap.zip")
    resp <- httr::GET(url, httr::write_disk(zip_path, overwrite = TRUE), httr::timeout(300))
    stopifnot("SNAP download failed" = httr::status_code(resp) == 200)
    csv_files <- unzip(zip_path, exdir = data_dir)
    file.rename(csv_files[grepl("\\.csv$", csv_files)][1], snap_local)
    unlink(zip_path)
  }
}

retailers <- fread(snap_local, showProgress = FALSE)
cat("  SNAP retailers:", format(nrow(retailers), big.mark = ","), "\n")

# ----------------------------------------------------------
# 2. HMDA Data from CFPB Data Browser API
# ----------------------------------------------------------
cat("\n=== Fetching HMDA Data ===\n")

hmda_cache <- file.path(data_dir, "hmda_tract_year.rds")

if (!file.exists(hmda_cache)) {
  # State FIPS codes for API
  state_codes <- c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
                   "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
                   "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                   "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
                   "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")

  years <- 2018:2023

  # CFPB Data Browser API: download state-by-state, year-by-year
  # Filter to home purchase loans (loan_purpose=1), originated or denied
  all_hmda <- list()

  for (yr in years) {
    cat("  Year", yr, "...")
    yr_data <- list()

    for (st in state_codes) {
      url <- paste0(
        "https://ffiec.cfpb.gov/v2/data-browser-api/view/csv?",
        "years=", yr,
        "&states=", st,
        "&actions_taken=1,3",
        "&loan_purposes=1"
      )

      tryCatch({
        resp <- httr::GET(url, httr::timeout(120))
        if (httr::status_code(resp) == 200) {
          content <- httr::content(resp, "text", encoding = "UTF-8")
          if (nchar(content) > 100) {
            df <- fread(text = content, showProgress = FALSE,
                        select = c("census_tract", "action_taken",
                                    "loan_amount", "loan_type"))
            if (nrow(df) > 0) {
              df[, year := yr]
              df[, state := st]
              yr_data[[st]] <- df
            }
          }
        }
      }, error = function(e) {
        # Skip silently on timeout/error
      })
    }

    if (length(yr_data) > 0) {
      yr_combined <- rbindlist(yr_data, fill = TRUE)
      all_hmda[[as.character(yr)]] <- yr_combined
      cat(" ", format(nrow(yr_combined), big.mark = ","), "loans\n")
    } else {
      cat(" no data\n")
    }
  }

  hmda_raw <- rbindlist(all_hmda, fill = TRUE)
  cat("  Total HMDA records:", format(nrow(hmda_raw), big.mark = ","), "\n")

  if (nrow(hmda_raw) < 1000) {
    stop("HMDA data fetch returned too few records. Check API.")
  }

  # Aggregate to tract-year
  cat("  Aggregating to tract-year...\n")

  # Clean census tract — should be 11-digit FIPS
  hmda_raw[, tract := as.character(census_tract)]
  hmda_raw[, tract := gsub("\\.", "", tract)]

  # Originations (action_taken = 1) and denials (action_taken = 3)
  hmda_tract <- hmda_raw[, .(
    n_originations = sum(action_taken == 1, na.rm = TRUE),
    n_denials = sum(action_taken == 3, na.rm = TRUE),
    n_applications = .N,
    median_loan = median(loan_amount[action_taken == 1], na.rm = TRUE),
    n_fha = sum(loan_type == 2 & action_taken == 1, na.rm = TRUE)
  ), by = .(tract, year)]

  hmda_tract[, denial_rate := n_denials / n_applications]
  hmda_tract[, fha_share := n_fha / pmax(n_originations, 1)]
  hmda_tract[, ln_orig := log(pmax(n_originations, 1))]

  cat("  Tract-year observations:", format(nrow(hmda_tract), big.mark = ","), "\n")
  cat("  Unique tracts:", length(unique(hmda_tract$tract)), "\n")

  saveRDS(hmda_tract, hmda_cache)
} else {
  cat("  Loading cached HMDA data...\n")
  hmda_tract <- readRDS(hmda_cache)
  cat("  Tract-year observations:", format(nrow(hmda_tract), big.mark = ","), "\n")
}

# ----------------------------------------------------------
# 3. Validate
# ----------------------------------------------------------
cat("\n=== Validation ===\n")
stopifnot("HMDA must have data" = nrow(hmda_tract) > 10000)
stopifnot("SNAP must have data" = nrow(retailers) > 100000)
cat("  Both datasets validated.\n")
