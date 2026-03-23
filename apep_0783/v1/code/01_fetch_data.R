## 01_fetch_data.R — Fetch POStPlan treatment data and Census BFS outcomes
## apep_0783: USPS POStPlan and Rural Business Formation

source("00_packages.R")

data_dir <- "../data/"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. POStPlan Treatment Data (already downloaded as CSV)
# ============================================================
cat("=== Loading POStPlan data ===\n")

postplan_file <- file.path(data_dir, "postplan_offices.csv")
if (!file.exists(postplan_file)) {
  stop("FATAL: POStPlan CSV not found at ", postplan_file,
       "\nDownload from Google Sheets first.")
}

postplan <- read.csv(postplan_file, stringsAsFactors = FALSE)
cat("POStPlan data loaded:", nrow(postplan), "rows\n")
cat("Columns:", paste(names(postplan), collapse = ", "), "\n")

# Check treatment distribution
cat("\nIn POStPlan:\n")
print(table(postplan$In.POStPlan))
cat("\nProposed Level (hours):\n")
print(table(postplan$Proposed.Level))
cat("\nStates:\n")
cat("Unique states:", length(unique(postplan$ST)), "\n")

# Extract 5-digit ZIP
postplan$zip5 <- substr(gsub("[^0-9]", "", postplan$ZIP.Code), 1, 5)
cat("Unique ZIPs:", length(unique(postplan$zip5)), "\n")

saveRDS(postplan, file.path(data_dir, "postplan_raw.rds"))

# ============================================================
# 2. ZIP-to-County Crosswalk (HUD USPS ZIP Crosswalk)
# ============================================================
cat("\n=== Fetching ZIP-to-county crosswalk ===\n")

# Use the Census Bureau's ZCTA-to-county relationship file
# This maps ZIP codes to counties (FIPS)
xwalk_url <- "https://www2.census.gov/geo/docs/maps-data/data/rel2020/zcta520/tab20_zcta520_county20_natl.txt"

xwalk_file <- file.path(data_dir, "zip_county_xwalk.txt")
tryCatch({
  download.file(xwalk_url, xwalk_file, mode = "wb", quiet = TRUE)
  xwalk <- read.delim(xwalk_file, sep = "|", stringsAsFactors = FALSE)
  cat("Crosswalk downloaded:", nrow(xwalk), "rows\n")
  cat("Columns:", paste(names(xwalk), collapse = ", "), "\n")
}, error = function(e) {
  stop("FATAL: Failed to download ZIP-county crosswalk: ", e$message)
})

saveRDS(xwalk, file.path(data_dir, "zip_county_xwalk.rds"))

# ============================================================
# 3. Census Business Formation Statistics (BFS)
# ============================================================
cat("\n=== Fetching Census BFS data ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) {
  warning("CENSUS_API_KEY not set — will try without key")
  key_param <- ""
} else {
  key_param <- paste0("&key=", census_key)
}

# BFS time series API — county-level business applications
# Available 2004Q3 - present
# We need annual totals by county

bfs_all <- list()

# First, let's try the time series endpoint
# BFS provides quarterly data; we'll aggregate to annual
for (yr in 2005:2023) {
  for (qtr in 1:4) {
    time_str <- paste0(yr, "-Q", qtr)
    cat("Fetching BFS", time_str, "...")

    url <- paste0(
      "https://api.census.gov/data/timeseries/eits/bfs?get=BA_BA,GEO_ID",
      "&for=county:*",
      "&time=", yr, "-Q", qtr,
      key_param
    )

    resp <- tryCatch(httr::GET(url, httr::timeout(60)),
                     error = function(e) NULL)

    if (!is.null(resp) && httr::status_code(resp) == 200) {
      content <- httr::content(resp, "text", encoding = "UTF-8")
      parsed <- jsonlite::fromJSON(content)
      if (is.matrix(parsed) && nrow(parsed) > 1) {
        df <- as.data.frame(parsed[-1, , drop = FALSE], stringsAsFactors = FALSE)
        names(df) <- parsed[1, ]
        df$year <- yr
        df$quarter <- qtr
        bfs_all[[paste0(yr, "_Q", qtr)]] <- df
        cat(" OK —", nrow(df), "counties\n")
      } else {
        cat(" Empty response\n")
      }
    } else {
      # Try state-level if county fails
      if (!is.null(resp)) {
        cat(" Status:", httr::status_code(resp))
      }
      cat(" — trying alternative...\n")

      # Try the newer BFS endpoint
      url2 <- paste0(
        "https://api.census.gov/data/timeseries/eits/bfs?get=BA_BA",
        "&for=state:*",
        "&time=", yr, "-Q", qtr,
        key_param
      )

      resp2 <- tryCatch(httr::GET(url2, httr::timeout(60)),
                        error = function(e) NULL)

      if (!is.null(resp2) && httr::status_code(resp2) == 200) {
        content2 <- httr::content(resp2, "text", encoding = "UTF-8")
        parsed2 <- jsonlite::fromJSON(content2)
        if (is.matrix(parsed2) && nrow(parsed2) > 1) {
          df2 <- as.data.frame(parsed2[-1, , drop = FALSE], stringsAsFactors = FALSE)
          names(df2) <- parsed2[1, ]
          df2$year <- yr
          df2$quarter <- qtr
          bfs_all[[paste0(yr, "_Q", qtr, "_state")]] <- df2
          cat("   State-level OK —", nrow(df2), "states\n")
        }
      }
    }

    Sys.sleep(0.3)
  }
}

if (length(bfs_all) == 0) {
  cat("BFS API did not return county data. Trying bulk download...\n")

  # Try the BFS bulk CSV download
  bfs_bulk_url <- "https://www.census.gov/econ/bfs/csv/bfs_county_apps_annual.csv"
  bfs_bulk_file <- file.path(data_dir, "bfs_county_annual.csv")

  tryCatch({
    download.file(bfs_bulk_url, bfs_bulk_file, mode = "wb", quiet = TRUE)
    bfs_bulk <- read.csv(bfs_bulk_file, stringsAsFactors = FALSE)
    cat("BFS bulk data downloaded:", nrow(bfs_bulk), "rows\n")
    saveRDS(bfs_bulk, file.path(data_dir, "bfs_raw.rds"))
  }, error = function(e) {
    cat("Bulk download also failed:", e$message, "\n")
    cat("Trying BFS website directly...\n")

    # Final fallback: Download from the BFS data page
    bfs_url3 <- "https://www.census.gov/econ/bfs/data/datasets/bfs_county.csv"
    tryCatch({
      download.file(bfs_url3, bfs_bulk_file, mode = "wb", quiet = TRUE)
      bfs_bulk <- read.csv(bfs_bulk_file, stringsAsFactors = FALSE)
      cat("BFS downloaded:", nrow(bfs_bulk), "rows\n")
      saveRDS(bfs_bulk, file.path(data_dir, "bfs_raw.rds"))
    }, error = function(e2) {
      stop("FATAL: Cannot retrieve BFS data from any source: ", e2$message)
    })
  })
} else {
  bfs_raw <- bind_rows(bfs_all)
  cat("\nBFS data retrieved:", nrow(bfs_raw), "total rows across",
      length(unique(paste(bfs_raw$year, bfs_raw$quarter))), "quarters\n")
  saveRDS(bfs_raw, file.path(data_dir, "bfs_raw.rds"))
}

# ============================================================
# 4. County Business Patterns (CBP) — for establishment counts
# ============================================================
cat("\n=== Fetching County Business Patterns data ===\n")

# CBP provides establishment counts by county - useful as control/outcome
cbp_all <- list()

for (yr in c(2008, 2010, 2012, 2014, 2016, 2018, 2020)) {
  cat("Fetching CBP", yr, "...")

  url <- paste0(
    "https://api.census.gov/data/", yr, "/cbp?get=ESTAB,EMP,PAYANN",
    "&for=county:*&NAICS2017=00",
    key_param
  )

  # Try NAICS2012 for older years
  if (yr <= 2016) {
    url <- paste0(
      "https://api.census.gov/data/", yr, "/cbp?get=ESTAB,EMP,PAYANN",
      "&for=county:*&NAICS2012=00",
      key_param
    )
  }

  resp <- tryCatch(httr::GET(url, httr::timeout(60)),
                   error = function(e) NULL)

  if (!is.null(resp) && httr::status_code(resp) == 200) {
    content <- httr::content(resp, "text", encoding = "UTF-8")
    parsed <- jsonlite::fromJSON(content)
    if (is.matrix(parsed) && nrow(parsed) > 1) {
      df <- as.data.frame(parsed[-1, , drop = FALSE], stringsAsFactors = FALSE)
      names(df) <- parsed[1, ]
      df$year <- yr
      cbp_all[[as.character(yr)]] <- df
      cat(" OK —", nrow(df), "counties\n")
    } else {
      cat(" Empty\n")
    }
  } else {
    cat(" FAILED\n")
  }

  Sys.sleep(0.5)
}

if (length(cbp_all) > 0) {
  cbp_raw <- bind_rows(cbp_all)
  cat("CBP data:", nrow(cbp_raw), "county-years\n")
  saveRDS(cbp_raw, file.path(data_dir, "cbp_raw.rds"))
}

# ============================================================
# 5. Summary
# ============================================================
cat("\n=== Data Fetch Summary ===\n")
cat("Files in data directory:\n")
files <- list.files(data_dir, pattern = "\\.(rds|csv|txt)$")
for (f in files) {
  sz <- file.size(file.path(data_dir, f))
  cat(sprintf("  %-35s %s\n", f, format(sz, big.mark = ",")))
}
