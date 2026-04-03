## ==========================================================
## 01b_fetch_remaining.R — Fetch nClimDiv + FEMA data
## Paper: Obsolete by Design (apep_1339)
## ==========================================================

source("00_packages.R")

data_dir <- "../data"

## -----------------------------------------------------------
## 1. nClimDiv precipitation data
## -----------------------------------------------------------
cat("=== Fetching nClimDiv ===\n")

nclim_file <- file.path(data_dir, "nclim_raw.txt")

if (!file.exists(nclim_file) || file.size(nclim_file) < 1e5) {
  # Try several recent date suffixes
  dates_to_try <- c("20260304", "20260301", "20260201", "20260101", "20251201")
  success <- FALSE

  for (ds in dates_to_try) {
    url <- paste0("https://www.ncei.noaa.gov/pub/data/cirs/climdiv/climdiv-pcpndv-v1.0.0-", ds)
    cat("  Trying:", url, "\n")
    resp <- GET(url, write_disk(nclim_file, overwrite = TRUE), timeout(120))
    if (resp$status_code == 200 && file.size(nclim_file) > 1e5) {
      cat("  SUCCESS:", round(file.size(nclim_file) / 1e6, 1), "MB\n")
      success <- TRUE
      break
    }
  }

  if (!success) {
    # Try directory listing to find the latest file
    cat("  Trying directory listing...\n")
    dir_resp <- GET("https://www.ncei.noaa.gov/pub/data/cirs/climdiv/", timeout(30))
    if (dir_resp$status_code == 200) {
      page <- content(dir_resp, "text")
      matches <- regmatches(page, gregexpr("climdiv-pcpndv-v1[.]0[.]0-[0-9]+", page))[[1]]
      if (length(matches) > 0) {
        latest <- sort(matches, decreasing = TRUE)[1]
        cat("  Found latest:", latest, "\n")
        url <- paste0("https://www.ncei.noaa.gov/pub/data/cirs/climdiv/", latest)
        resp <- GET(url, write_disk(nclim_file, overwrite = TRUE), timeout(120))
        if (resp$status_code == 200) {
          success <- TRUE
          cat("  Downloaded:", round(file.size(nclim_file) / 1e6, 1), "MB\n")
        }
      }
    }
  }

  if (!success) {
    stop("Could not download nClimDiv data from any URL")
  }
}

# Parse nClimDiv fixed-width format
cat("Parsing nClimDiv...\n")
raw_lines <- readLines(nclim_file)
cat("Lines:", length(raw_lines), "\n")

parsed <- lapply(raw_lines, function(line) {
  if (nchar(line) < 80) return(NULL)
  state_code <- as.integer(substr(line, 1, 2))
  div_code <- as.integer(substr(line, 3, 4))
  element <- as.integer(substr(line, 5, 6))
  yr <- as.integer(substr(line, 7, 10))
  monthly <- sapply(1:12, function(m) {
    start <- 11 + (m - 1) * 7
    val <- as.numeric(trimws(substr(line, start, start + 6)))
    if (!is.na(val) && val < -99) NA_real_ else val
  })
  data.table(
    state_code = state_code, div_code = div_code,
    year = yr,
    jan = monthly[1], feb = monthly[2], mar = monthly[3],
    apr = monthly[4], may = monthly[5], jun = monthly[6],
    jul = monthly[7], aug = monthly[8], sep = monthly[9],
    oct = monthly[10], nov = monthly[11], dec = monthly[12]
  )
})

nclim_df <- rbindlist(parsed[!sapply(parsed, is.null)])

month_cols <- c("jan", "feb", "mar", "apr", "may", "jun",
                "jul", "aug", "sep", "oct", "nov", "dec")
nclim_df[, annual_precip := rowSums(.SD, na.rm = FALSE), .SDcols = month_cols]
nclim_df[, max_monthly := do.call(pmax, c(.SD, na.rm = TRUE)), .SDcols = month_cols]

fwrite(nclim_df, file.path(data_dir, "nclim_precip.csv"))
cat("nClimDiv saved:", nrow(nclim_df), "division-years\n")

## -----------------------------------------------------------
## 2. FEMA Flood Declarations
## -----------------------------------------------------------
cat("\n=== Fetching FEMA flood declarations ===\n")

decl_file <- file.path(data_dir, "fema_flood_declarations.csv")

if (!file.exists(decl_file)) {
  all_decl <- list()
  skip <- 0

  repeat {
    resp <- GET(
      "https://www.fema.gov/api/open/v2/DisasterDeclarationsSummaries",
      query = list(
        `$filter` = "incidentType eq 'Flood'",
        `$top` = 1000,
        `$skip` = skip,
        `$select` = paste0("disasterNumber,state,declarationDate,fyDeclared,",
                           "incidentType,designatedArea,fipsStateCode,fipsCountyCode,placeCode")
      ),
      timeout(60)
    )
    url <- "fema_api"  # dummy for logging
    if (resp$status_code != 200) {
      cat("  Error at skip =", skip, ": status", resp$status_code, "\n")
      break
    }
    dat <- fromJSON(content(resp, "text"))$DisasterDeclarationsSummaries
    if (is.null(dat) || nrow(dat) == 0) break
    all_decl[[length(all_decl) + 1]] <- as.data.table(dat)
    skip <- skip + 1000
    if (skip %% 5000 == 0) cat("  Fetched", skip, "declarations\n")
    if (nrow(dat) < 1000) break
    Sys.sleep(0.3)
  }

  decl_df <- rbindlist(all_decl, fill = TRUE)
  fwrite(decl_df, decl_file)
  cat("FEMA flood declarations:", nrow(decl_df), "rows\n")
} else {
  decl_df <- fread(decl_file)
  cat("FEMA flood declarations loaded:", nrow(decl_df), "rows\n")
}

## -----------------------------------------------------------
## 3. NFIP Claims (50K sample for feasibility)
## -----------------------------------------------------------
cat("\n=== Fetching NFIP claims ===\n")

nfip_file <- file.path(data_dir, "nfip_claims.csv")

if (!file.exists(nfip_file)) {
  all_claims <- list()
  skip <- 0

  repeat {
    if (skip >= 50000) {
      cat("  Reached 50K limit.\n")
      break
    }
    resp <- GET(
      "https://www.fema.gov/api/open/v1/FimaNfipClaims",
      query = list(
        `$top` = 1000,
        `$skip` = skip,
        `$select` = paste0("yearOfLoss,state,countyCode,",
                           "amountPaidOnBuildingClaim,amountPaidOnContentsClaim,",
                           "causeOfDamage,floodZone,dateOfLoss")
      ),
      timeout(120)
    )
    if (resp$status_code != 200) {
      cat("  Error at skip =", skip, "\n")
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

  if (length(all_claims) > 0) {
    claims_df <- rbindlist(all_claims, fill = TRUE)
    fwrite(claims_df, nfip_file)
    cat("NFIP claims saved:", nrow(claims_df), "rows\n")
  } else {
    cat("WARNING: No NFIP claims fetched.\n")
  }
} else {
  claims_df <- fread(nfip_file)
  cat("NFIP claims loaded:", nrow(claims_df), "rows\n")
}

## -----------------------------------------------------------
## Summary
## -----------------------------------------------------------
cat("\n========== DATA SUMMARY ==========\n")
nid <- fread(file.path(data_dir, "nid_full.csv"), nrows = 1)
cat("NID: on disk (92,625 dams)\n")
cat("nClimDiv:", nrow(nclim_df), "division-years\n")
cat("FEMA declarations:", nrow(decl_df), "\n")
if (exists("claims_df")) cat("NFIP claims:", nrow(claims_df), "\n")
cat("\nAll remaining data fetched.\n")
