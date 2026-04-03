## ==========================================================
## 01_fetch_data.R — Fetch NID, Atlas 14, nClimDiv, OpenFEMA
## Paper: Obsolete by Design (apep_1339)
## ==========================================================

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## -----------------------------------------------------------
## 1. National Inventory of Dams (NID)
## -----------------------------------------------------------
cat("=== Fetching NID data ===\n")

nid_url <- "https://nid.sec.usace.army.mil/api/nation/csv"
nid_file <- file.path(data_dir, "nid_full.csv")

if (!file.exists(nid_file)) {
  resp <- GET(nid_url,
              add_headers(Accept = "text/csv"),
              write_disk(nid_file, overwrite = TRUE),
              timeout(300))
  stopifnot("NID download failed" = file.exists(nid_file) && file.size(nid_file) > 1e6)
  cat("NID downloaded:", round(file.size(nid_file) / 1e6, 1), "MB\n")
} else {
  cat("NID already on disk.\n")
}

nid <- fread(nid_file, showProgress = FALSE)
cat("NID:", nrow(nid), "dams,", ncol(nid), "columns\n")

## -----------------------------------------------------------
## 2. NOAA Atlas 14 — current 100-yr 24-hr precipitation
## -----------------------------------------------------------
cat("\n=== Querying NOAA Atlas 14 for dam locations ===\n")

atlas14_file <- file.path(data_dir, "atlas14_at_dams.csv")

if (!file.exists(atlas14_file)) {
  # Filter to pre-1980 dams with coordinates and high/significant hazard
  dams_for_atlas <- nid[!is.na(`Latitude`) & !is.na(`Longitude`) &
                          !is.na(`Year Completed`) &
                          `Year Completed` > 1900 &
                          `Latitude` > 24 & `Latitude` < 50 &
                          `Longitude` > -125 & `Longitude` < -66,
                        .(`NID ID`, `Dam Name`, `Latitude`, `Longitude`,
                          `Year Completed`, `State`, `County`,
                          `Hazard Potential Classification`,
                          `Max Discharge (Cubic Ft/Second)`,
                          `Drainage Area (Sq Miles)`,
                          `NID Storage (Acre-Ft)`,
                          `Spillway Type`, `Dam Height (Ft)`)]

  cat("Dams in CONUS with valid coords:", nrow(dams_for_atlas), "\n")

  # Sample stratified: all high/significant hazard + random of low
  high_haz <- dams_for_atlas[`Hazard Potential Classification` %in% c("High", "Significant")]
  low_haz <- dams_for_atlas[`Hazard Potential Classification` == "Low"]

  cat("High/Significant hazard:", nrow(high_haz), "\n")
  cat("Low hazard:", nrow(low_haz), "\n")

  # Query Atlas 14 for all high/significant + sample of low
  set.seed(42)
  low_sample <- low_haz[sample(.N, min(5000, .N))]
  query_dams <- rbind(high_haz, low_sample)
  cat("Querying Atlas 14 for", nrow(query_dams), "dams...\n")

  # Query in batches with rate limiting
  results <- list()
  n_success <- 0
  n_fail <- 0

  for (i in seq_len(nrow(query_dams))) {
    lat <- query_dams$Latitude[i]
    lon <- query_dams$Longitude[i]
    nid_id <- query_dams$`NID ID`[i]

    tryCatch({
      resp <- GET(
        "https://hdsc.nws.noaa.gov/cgi-bin/hdsc/new/cgi_readH5.py",
        query = list(lat = as.character(lat),
                     lon = as.character(lon),
                     type = "pf",
                     data = "depth",
                     series = "pds"),
        timeout(15)
      )

      if (resp$status_code == 200) {
        content_text <- content(resp, "text", encoding = "UTF-8")
        # Parse the response — Atlas 14 returns a specific format
        # Extract 100-year 24-hour depth
        # Format: quantiles in a structured text response
        lines <- strsplit(content_text, "\n")[[1]]

        # Find the line with 100-yr return period and 24-hr duration
        # The response format varies; try to extract the key value
        depth_100yr_24hr <- NA_real_

        # Look for the quantile data section
        if (grepl("quantiles", content_text)) {
          # Try JSON parsing
          parsed <- tryCatch(fromJSON(content_text), error = function(e) NULL)
          if (!is.null(parsed) && !is.null(parsed$quantiles)) {
            # quantiles is typically a matrix; row=duration, col=return period
            # 100-yr is usually column index for "100"
            q <- parsed$quantiles
            if (is.character(q)) {
              q_mat <- matrix(as.numeric(unlist(strsplit(q, ","))),
                              nrow = length(parsed$quantiles))
            }
          }
        }

        # Alternative parsing: look for specific pattern
        if (is.na(depth_100yr_24hr) && grepl("upper", content_text)) {
          parsed <- tryCatch(fromJSON(content_text), error = function(e) NULL)
          if (!is.null(parsed)) {
            # Try to find 100-year value in the parsed structure
            if (!is.null(parsed$result)) {
              # Some endpoints return nested structure
              depth_100yr_24hr <- as.numeric(parsed$result$`100`$`24`)
            }
          }
        }

        results[[length(results) + 1]] <- data.table(
          nid_id = nid_id,
          lat = lat,
          lon = lon,
          atlas14_100yr_24hr = depth_100yr_24hr,
          raw_response_len = nchar(content_text)
        )
        n_success <- n_success + 1
      } else {
        n_fail <- n_fail + 1
      }
    }, error = function(e) {
      n_fail <<- n_fail + 1
    })

    if (i %% 500 == 0) {
      cat("  Queried", i, "of", nrow(query_dams),
          "(success:", n_success, ", fail:", n_fail, ")\n")
      Sys.sleep(2)  # Rate limit
    }
    if (i %% 50 == 0) Sys.sleep(0.5)

    # Stop after 2000 for initial feasibility
    if (i >= 2000) {
      cat("  Stopping at 2000 queries for feasibility check.\n")
      break
    }
  }

  atlas14_df <- rbindlist(results)
  cat("\nAtlas 14 queries complete:", nrow(atlas14_df), "results\n")
  cat("  Non-NA depths:", sum(!is.na(atlas14_df$atlas14_100yr_24hr)), "\n")

  # Save raw response sample for debugging
  fwrite(atlas14_df, atlas14_file)

  # If API parsing failed, inspect a raw response
  if (sum(!is.na(atlas14_df$atlas14_100yr_24hr)) == 0) {
    cat("\nDEBUG: Inspecting raw Atlas 14 response...\n")
    test_resp <- GET(
      "https://hdsc.nws.noaa.gov/cgi-bin/hdsc/new/cgi_readH5.py",
      query = list(lat = "38.0", lon = "-97.0", type = "pf",
                   data = "depth", series = "pds"),
      timeout(15)
    )
    cat(content(test_resp, "text", encoding = "UTF-8"))
  }
} else {
  atlas14_df <- fread(atlas14_file)
  cat("Atlas 14 data loaded:", nrow(atlas14_df), "records\n")
}

## -----------------------------------------------------------
## 3. NOAA nClimDiv — Climate Division precipitation data
## -----------------------------------------------------------
cat("\n=== Fetching NOAA nClimDiv precipitation data ===\n")

nclim_file <- file.path(data_dir, "nclim_precip.csv")

if (!file.exists(nclim_file)) {
  # nClimDiv data from NOAA
  # Monthly precipitation by climate division, 1895-present
  nclim_url <- "https://www.ncei.noaa.gov/pub/data/cirs/climdiv/climdiv-pcpndv-v1.0.0-20260304"

  resp <- GET(nclim_url, write_disk(file.path(data_dir, "nclim_raw.txt"),
                                      overwrite = TRUE), timeout(120))

  if (resp$status_code != 200) {
    # Try alternative date
    cat("Trying alternative nClimDiv URL...\n")
    nclim_url2 <- "https://www.ncei.noaa.gov/pub/data/cirs/climdiv/climdiv-pcpndv-v1.0.0-20260301"
    resp <- GET(nclim_url2, write_disk(file.path(data_dir, "nclim_raw.txt"),
                                         overwrite = TRUE), timeout(120))
  }

  if (resp$status_code == 200) {
    cat("nClimDiv downloaded:", round(file.size(file.path(data_dir, "nclim_raw.txt")) / 1e6, 1), "MB\n")

    # Parse the fixed-width format
    raw_lines <- readLines(file.path(data_dir, "nclim_raw.txt"))
    cat("nClimDiv lines:", length(raw_lines), "\n")

    # Format: StateCode(2) + DivCode(2) + ElementCode(2) + Year(4) + 12 monthly values (6 chars each)
    # Total width: 2+2+2+4 + 12*7 = 94 chars per line
    parsed <- lapply(raw_lines, function(line) {
      if (nchar(line) < 80) return(NULL)
      state_code <- as.integer(substr(line, 1, 2))
      div_code <- as.integer(substr(line, 3, 4))
      element <- as.integer(substr(line, 5, 6))
      year <- as.integer(substr(line, 7, 10))
      monthly <- sapply(1:12, function(m) {
        start <- 11 + (m - 1) * 7
        val <- as.numeric(trimws(substr(line, start, start + 6)))
        if (!is.na(val) && val < -99) NA_real_ else val
      })
      data.table(
        state_code = state_code,
        div_code = div_code,
        year = year,
        jan = monthly[1], feb = monthly[2], mar = monthly[3],
        apr = monthly[4], may = monthly[5], jun = monthly[6],
        jul = monthly[7], aug = monthly[8], sep = monthly[9],
        oct = monthly[10], nov = monthly[11], dec = monthly[12]
      )
    })

    nclim_df <- rbindlist(parsed[!sapply(parsed, is.null)])
    # Compute annual total precipitation
    month_cols <- c("jan", "feb", "mar", "apr", "may", "jun",
                    "jul", "aug", "sep", "oct", "nov", "dec")
    nclim_df[, annual_precip := rowSums(.SD, na.rm = FALSE), .SDcols = month_cols]
    # Compute max monthly as proxy for extreme precipitation
    nclim_df[, max_monthly := do.call(pmax, c(.SD, na.rm = TRUE)), .SDcols = month_cols]

    fwrite(nclim_df, nclim_file)
    cat("nClimDiv parsed:", nrow(nclim_df), "division-years\n")
  } else {
    cat("nClimDiv download failed with status:", resp$status_code, "\n")
    cat("Will use Atlas 14 only for precipitation data.\n")
  }
} else {
  nclim_df <- fread(nclim_file)
  cat("nClimDiv loaded:", nrow(nclim_df), "records\n")
}

## -----------------------------------------------------------
## 4. OpenFEMA — Disaster Declarations and NFIP Claims
## -----------------------------------------------------------
cat("\n=== Fetching OpenFEMA data ===\n")

# 4a. FEMA Disaster Declarations
decl_file <- file.path(data_dir, "fema_flood_declarations.csv")

if (!file.exists(decl_file)) {
  cat("Fetching FEMA flood declarations...\n")
  all_decl <- list()
  skip <- 0

  repeat {
    url <- paste0(
      "https://www.fema.gov/api/open/v2/DisasterDeclarationsSummaries",
      "?$filter=incidentType eq 'Flood'",
      "&$top=1000&$skip=", skip,
      "&$select=disasterNumber,state,declarationDate,fyDeclared,",
      "incidentType,designatedArea,fipsStateCode,fipsCountyCode,placeCode"
    )
    resp <- GET(url, timeout(60))
    if (resp$status_code != 200) break
    dat <- fromJSON(content(resp, "text"))$DisasterDeclarationsSummaries
    if (is.null(dat) || nrow(dat) == 0) break
    all_decl[[length(all_decl) + 1]] <- as.data.table(dat)
    skip <- skip + 1000
    if (nrow(dat) < 1000) break
    Sys.sleep(0.3)
  }

  decl_df <- rbindlist(all_decl, fill = TRUE)
  fwrite(decl_df, decl_file)
  cat("FEMA declarations:", nrow(decl_df), "rows\n")
} else {
  decl_df <- fread(decl_file)
  cat("FEMA declarations loaded:", nrow(decl_df), "rows\n")
}

# 4b. NFIP Claims (sample for feasibility — full dataset is 2.5M+)
nfip_file <- file.path(data_dir, "nfip_claims.csv")

if (!file.exists(nfip_file)) {
  cat("Fetching NFIP claims (sampling for feasibility)...\n")
  all_claims <- list()
  skip <- 0
  max_records <- 50000  # Feasibility sample

  repeat {
    if (skip >= max_records) break
    url <- paste0(
      "https://www.fema.gov/api/open/v1/FimaNfipClaims",
      "?$top=1000&$skip=", skip,
      "&$select=yearOfLoss,state,countyCode,",
      "amountPaidOnBuildingClaim,amountPaidOnContentsClaim,",
      "causeOfDamage,floodZone,dateOfLoss"
    )
    resp <- GET(url, timeout(120))
    if (resp$status_code != 200) {
      cat("  NFIP API error at skip=", skip, "\n")
      break
    }
    dat <- fromJSON(content(resp, "text"))$FimaNfipClaims
    if (is.null(dat) || nrow(dat) == 0) break
    all_claims[[length(all_claims) + 1]] <- as.data.table(dat)
    skip <- skip + 1000
    if (skip %% 10000 == 0) cat("  Fetched", skip, "NFIP claims\n")
    if (nrow(dat) < 1000) break
    Sys.sleep(0.2)
  }

  claims_df <- rbindlist(all_claims, fill = TRUE)
  fwrite(claims_df, nfip_file)
  cat("NFIP claims:", nrow(claims_df), "rows\n")
} else {
  claims_df <- fread(nfip_file)
  cat("NFIP claims loaded:", nrow(claims_df), "rows\n")
}

## -----------------------------------------------------------
## 5. Summary
## -----------------------------------------------------------
cat("\n========== DATA SUMMARY ==========\n")
cat("NID:", nrow(nid), "dams\n")
cat("FEMA flood declarations:", nrow(decl_df), "\n")
cat("NFIP claims:", nrow(claims_df), "\n")

# Dam vintage distribution
nid[, year_built := as.numeric(`Year Completed`)]
cat("\nDams by era:\n")
cat("  Pre-1970:", sum(nid$year_built < 1970, na.rm = TRUE), "\n")
cat("  1970-1999:", sum(nid$year_built >= 1970 & nid$year_built < 2000, na.rm = TRUE), "\n")
cat("  2000+:", sum(nid$year_built >= 2000, na.rm = TRUE), "\n")

# Hazard classification
cat("\nDams by hazard:\n")
print(table(nid$`Hazard Potential Classification`, useNA = "ifany"))

cat("\nData fetch complete.\n")
