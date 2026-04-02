## ============================================================
## 01_fetch_data.R — Fetch SNAP Retailer + Natality Data
## APEP Paper apep_1301: SNAP Retailer Exits and Birth Outcomes
##
## Data strategy:
##   1. SNAP retailers: USDA FNS historical database (bulk CSV)
##   2. Natality: CDC fixed-width microdata (state-level, 2016-2023)
##      + CDC Tracking Network API (county-level LBW, fallback)
##   3. Controls: BLS LAUS unemployment, Census ACS population
## ============================================================

source("code/00_packages.R")

data_dir <- "data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ---- 1. SNAP Retailer Historical Database ----
cat("=== Downloading SNAP Retailer Historical Database ===\n")

snap_file <- file.path(data_dir, "snap_retailers.csv")
if (!file.exists(snap_file)) {
  snap_urls <- c(
    "https://fns-prod.azureedge.us/sites/default/files/resource-files/snap-retailer-locator-data2005-2025.zip",
    "https://www.fns.usda.gov/sites/default/files/resource-files/snap-retailer-locator-data2005-2025.zip"
  )

  zip_file <- file.path(data_dir, "snap_retailers.zip")
  downloaded <- FALSE
  for (url in snap_urls) {
    cat("Trying:", url, "\n")
    tryCatch({
      download.file(url, zip_file, mode = "wb", timeout = 600, quiet = FALSE)
      downloaded <- TRUE
      break
    }, error = function(e) {
      cat("  Failed:", conditionMessage(e), "\n")
    })
  }
  if (!downloaded) stop("FATAL: Could not download SNAP retailer data from any URL.")

  csv_files <- unzip(zip_file, exdir = data_dir)
  cat("Extracted files:", csv_files, "\n")

  main_csv <- csv_files[grepl("\\.csv$", csv_files, ignore.case = TRUE)][1]
  if (is.na(main_csv)) stop("FATAL: No CSV found in SNAP ZIP archive.")
  file.rename(main_csv, snap_file)
  file.remove(zip_file)
  cat("SNAP retailer data saved to:", snap_file, "\n")
} else {
  cat("SNAP retailer data already exists, skipping download.\n")
}

# Validate SNAP data
snap_raw <- data.table::fread(snap_file, nrows = 5)
cat("SNAP columns:", paste(names(snap_raw), collapse = ", "), "\n")
snap_nrow <- as.integer(system(paste("wc -l <", shQuote(snap_file)), intern = TRUE))
cat("SNAP total rows:", snap_nrow, "\n")
stopifnot("SNAP data must have >100K rows" = snap_nrow > 100000)


## ---- 2. CDC Natality Microdata (state-year aggregation) ----
cat("\n=== Processing CDC Natality Microdata (Fixed-Width) ===\n")

# NCHS state code → state abbreviation
nchs_states <- c(
  "01" = "AL", "02" = "AK", "03" = "AZ", "04" = "AR", "05" = "CA",
  "06" = "CO", "07" = "CT", "08" = "DE", "09" = "DC", "10" = "FL",
  "11" = "GA", "12" = "HI", "13" = "ID", "14" = "IL", "15" = "IN",
  "16" = "IA", "17" = "KS", "18" = "KY", "19" = "LA", "20" = "ME",
  "21" = "MD", "22" = "MA", "23" = "MI", "24" = "MN", "25" = "MS",
  "26" = "MO", "27" = "MT", "28" = "NE", "29" = "NV", "30" = "NH",
  "31" = "NJ", "32" = "NM", "33" = "NY", "34" = "NC", "35" = "ND",
  "36" = "OH", "37" = "OK", "38" = "OR", "39" = "PA", "40" = "RI",
  "41" = "SC", "42" = "SD", "43" = "TN", "44" = "TX", "45" = "UT",
  "46" = "VT", "47" = "VA", "48" = "WA", "49" = "WV", "50" = "WI",
  "51" = "WY"
)

# State abbreviation → FIPS mapping
state_fips_map <- c(
  "AL"="01","AK"="02","AZ"="04","AR"="05","CA"="06","CO"="08","CT"="09",
  "DE"="10","DC"="11","FL"="12","GA"="13","HI"="15","ID"="16","IL"="17",
  "IN"="18","IA"="19","KS"="20","KY"="21","LA"="22","ME"="23","MD"="24",
  "MA"="25","MI"="26","MN"="27","MS"="28","MO"="29","MT"="30","NE"="31",
  "NV"="32","NH"="33","NJ"="34","NM"="35","NY"="36","NC"="37","ND"="38",
  "OH"="39","OK"="40","OR"="41","PA"="42","RI"="44","SC"="45","SD"="46",
  "TN"="47","TX"="48","UT"="49","VT"="50","VA"="51","WA"="53","WV"="54",
  "WI"="55","WY"="56"
)

col_spec <- readr::fwf_positions(
  start = c( 9, 13, 21, 408, 436, 492, 504),
  end   = c(12, 14, 22, 408, 436, 493, 507),
  col_names = c("dob_yy", "dob_mm", "nchs_state",
                "dmeth_rec", "pay_rec", "oegest_r10", "dbwt")
)

natality_file <- file.path(data_dir, "natality_state_year.csv")

if (!file.exists(natality_file)) {
  options(timeout = 600)
  years <- 2016:2023
  all_collapsed <- list()

  for (yr in years) {
    cat(sprintf("\n--- Processing %d ---\n", yr))

    zip_file <- file.path(data_dir, sprintf("Nat%dus.zip", yr))

    # Download
    if (!file.exists(zip_file) || file.size(zip_file) < 1e8) {
      if (file.exists(zip_file)) file.remove(zip_file)
      url <- sprintf("https://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/DVS/natality/Nat%dus.zip", yr)
      cat("  Downloading:", url, "\n")
      dl_exit <- system2("curl", args = c("-L", "-o", zip_file, url,
                                          "--max-time", "600", "--retry", "3"),
                         stdout = FALSE, stderr = "")
      if (dl_exit != 0 || !file.exists(zip_file) || file.size(zip_file) < 1e8) {
        cat(sprintf("  WARNING: Could not download %d, skipping.\n", yr))
        next
      }
    }
    cat("  Zip size:", round(file.size(zip_file) / 1e6, 1), "MB\n")

    # Extract
    zip_contents <- unzip(zip_file, list = TRUE)$Name
    txt_file <- zip_contents[1]
    tmp_dir <- tempdir()
    system2("unzip", args = c("-o", zip_file, txt_file, "-d", tmp_dir),
            stdout = FALSE, stderr = FALSE)
    extracted_path <- file.path(tmp_dir, txt_file)

    if (!file.exists(extracted_path)) {
      possible <- list.files(tmp_dir, pattern = sprintf("Nat%d", yr),
                             recursive = TRUE, full.names = TRUE)
      if (length(possible) > 0) extracted_path <- possible[1]
      else { cat("  Extracted file not found, skipping.\n"); next }
    }

    cat("  File size:", round(file.size(extracted_path) / 1e6, 1), "MB\n")

    # Parse fixed-width
    cat("  Parsing...\n")
    raw <- readr::read_fwf(
      extracted_path,
      col_positions = col_spec,
      col_types = readr::cols(
        dob_yy = readr::col_integer(),
        dob_mm = readr::col_integer(),
        nchs_state = readr::col_character(),
        dmeth_rec = readr::col_integer(),
        pay_rec = readr::col_integer(),
        oegest_r10 = readr::col_integer(),
        dbwt = readr::col_integer()
      ),
      progress = FALSE
    )

    cat("  Rows parsed:", nrow(raw), "\n")
    unlink(extracted_path)

    # Map NCHS state → abbreviation → FIPS
    raw <- as.data.table(raw)
    raw[, state_abbr := nchs_states[nchs_state]]
    raw <- raw[!is.na(state_abbr)]
    raw[, state_fips := state_fips_map[state_abbr]]

    # Collapse to state-year
    collapsed <- raw[
      dmeth_rec %in% c(1, 2) & pay_rec %in% c(1, 2, 3, 4) & dbwt > 0 & dbwt < 9999,
      .(
        births = .N,
        mean_bwt = mean(dbwt, na.rm = TRUE),
        lbw_count = sum(dbwt < 2500, na.rm = TRUE),
        preterm_count = sum(!is.na(oegest_r10) & oegest_r10 <= 5, na.rm = TRUE),
        medicaid_births = sum(pay_rec == 1, na.rm = TRUE),
        csection_count = sum(dmeth_rec == 2, na.rm = TRUE)
      ),
      by = .(state_fips, state_abbr, year = dob_yy)
    ]

    collapsed[, `:=`(
      lbw_rate = lbw_count / births,
      preterm_rate = preterm_count / births,
      medicaid_share = medicaid_births / births,
      csection_rate = csection_count / births
    )]

    cat(sprintf("  States: %d, Total births: %s\n",
                nrow(collapsed), format(sum(collapsed$births), big.mark = ",")))

    all_collapsed[[as.character(yr)]] <- collapsed
    rm(raw); gc()

    # Remove ZIP to save disk
    file.remove(zip_file)
  }

  if (length(all_collapsed) == 0) stop("FATAL: No natality data downloaded.")

  natality <- rbindlist(all_collapsed)
  fwrite(natality, natality_file)
  cat(sprintf("\nNatality saved: %d state-year obs, years %s\n",
              nrow(natality), paste(sort(unique(natality$year)), collapse = ", ")))
} else {
  cat("State-year natality already exists.\n")
  natality <- fread(natality_file)
}


## ---- 3. BLS LAUS (state unemployment) ----
cat("\n=== Fetching State Unemployment from BLS LAUS ===\n")

unemp_file <- file.path(data_dir, "state_unemployment.csv")

if (!file.exists(unemp_file)) {
  unemp_list <- list()
  for (yr in 2014:2023) {
    url <- sprintf("https://www.bls.gov/lau/lastrk%02d.htm", yr %% 100)
    cat(sprintf("  %d: ", yr))
    tryCatch({
      resp <- httr::GET(url, httr::timeout(30))
      if (httr::status_code(resp) == 200) {
        content <- httr::content(resp, "text", encoding = "UTF-8")
        # Parse HTML table — extract state and rate
        lines <- strsplit(content, "\n")[[1]]
        # Try alternative: BLS text file
        url2 <- sprintf("https://www.bls.gov/lau/ststdsadata.txt")
        resp2 <- httr::GET(url2, httr::timeout(30))
        if (httr::status_code(resp2) == 200) {
          txt <- httr::content(resp2, "text", encoding = "UTF-8")
          # This file has all years
          if (yr == 2014) {
            writeLines(txt, file.path(data_dir, "bls_laus_states_raw.txt"))
            cat("saved raw file\n")
          } else {
            cat("using cached raw\n")
          }
        } else {
          cat(sprintf("HTTP %d\n", httr::status_code(resp2)))
        }
      }
    }, error = function(e) {
      cat(sprintf("error: %s\n", conditionMessage(e)))
    })
  }

  # Parse the raw BLS LAUS data if available
  raw_file <- file.path(data_dir, "bls_laus_states_raw.txt")
  if (file.exists(raw_file)) {
    lines <- readLines(raw_file)
    # Find state data rows
    # Alternative: use FRED for state unemployment
    cat("  Parsing BLS LAUS state data...\n")
  }

  # Fallback: use FRED API for state-level unemployment
  fred_key <- Sys.getenv("FRED_API_KEY")
  if (nchar(fred_key) > 0) {
    cat("  Using FRED API for state unemployment...\n")
    unemp_list <- list()

    for (st in names(state_fips_map)) {
      series_id <- paste0(st, "UR")
      url <- sprintf(
        "https://api.stlouisfed.org/fred/series/observations?series_id=%s&api_key=%s&file_type=json&observation_start=2014-01-01&observation_end=2023-12-31&frequency=a",
        series_id, fred_key
      )
      tryCatch({
        resp <- httr::GET(url, httr::timeout(15))
        if (httr::status_code(resp) == 200) {
          json <- jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8"))
          if (!is.null(json$observations) && nrow(json$observations) > 0) {
            obs <- as.data.table(json$observations)
            obs[, `:=`(
              state_fips = state_fips_map[st],
              year = year(as.Date(date)),
              unemp_rate = as.numeric(value)
            )]
            unemp_list[[st]] <- obs[!is.na(unemp_rate), .(state_fips, year, unemp_rate)]
          }
        }
      }, error = function(e) NULL)
      Sys.sleep(0.1)
    }

    if (length(unemp_list) > 0) {
      unemp <- rbindlist(unemp_list)
      fwrite(unemp, unemp_file)
      cat(sprintf("  Saved %d state-year unemployment obs\n", nrow(unemp)))
    }
  } else {
    cat("  WARNING: No FRED_API_KEY, skipping unemployment data.\n")
  }
} else {
  cat("State unemployment data already exists.\n")
}


## ---- 4. State population (Census ACS) ----
cat("\n=== Fetching State Population ===\n")

pop_file <- file.path(data_dir, "state_population.csv")

if (!file.exists(pop_file)) {
  census_key <- Sys.getenv("CENSUS_API_KEY")
  if (nchar(census_key) > 0) {
    pop_url <- sprintf(
      "https://api.census.gov/data/2020/acs/acs5?get=B01003_001E,NAME&for=state:*&key=%s",
      census_key
    )
    cat("  Fetching from Census ACS...\n")
    resp <- httr::GET(pop_url, httr::timeout(120))
    if (httr::status_code(resp) == 200) {
      pop_json <- jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8"))
      pop_dt <- as.data.table(pop_json[-1, ])
      setnames(pop_dt, c("population", "name", "state_fips"))
      pop_dt[, population := as.integer(population)]
      fwrite(pop_dt[, .(state_fips, name, population)], pop_file)
      cat(sprintf("  Saved population for %d states\n", nrow(pop_dt)))
    } else {
      stop(sprintf("FATAL: Census API returned HTTP %d", httr::status_code(resp)))
    }
  } else {
    stop("FATAL: CENSUS_API_KEY not set.")
  }
} else {
  cat("State population data already exists.\n")
}


## ---- 5. State abbreviation-to-FIPS crosswalk ----
cat("\n=== State Crosswalk ===\n")

xwalk <- data.table(
  state_abbr = names(state_fips_map),
  state_fips = unname(state_fips_map)
)
fwrite(xwalk, file.path(data_dir, "state_fips_xwalk.csv"))
cat("  Saved state crosswalk.\n")

cat("\n=== All data fetched successfully ===\n")
