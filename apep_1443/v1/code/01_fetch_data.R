## 01_fetch_data.R — Fetch Taiwan Actual Price Registration data
## Source: Ministry of Interior, plvr.land.moi.gov.tw

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# Taiwan Actual Price Registration bulk download
# Format: season (S1=Q1..S4=Q4), ROC year (民國, = Western year - 1911)
# Municipalities: A=Taipei, B=Taichung, C=Keelung, D=Tainan, E=Kaohsiung,
#   F=Hsinchu(city), G=Chiayi(city), H=Taoyuan, I=Miaoli, J=Changhua,
#   K=Nantou, L=Yunlin, M=Chiayi(county), N=Pingtung, O=Yilan,
#   P=Hualien, Q=Taitung, R=Penghu, S=Kinmen, T=Lienchiang,
#   U=Hsinchu(county), V=Taichung(old), W=Tainan(old), X=Kaohsiung(old)

# Focus on 6 major municipalities (covers ~70% of transactions)
municipalities <- c("A", "B", "E", "F", "H", "D")
muni_names <- c("Taipei", "Taichung", "Kaohsiung", "Hsinchu_city", "Taoyuan", "Tainan")

# ROC years 101-113 (2012-2024), seasons 1-4
roc_years <- 101:113
seasons <- 1:4

# Download function
fetch_quarter <- function(muni, roc_year, season) {
  url <- sprintf(
    "https://plvr.land.moi.gov.tw/DownloadSeason?season=%dS%d&type=csv&fileName=lvr_landcsv.zip",
    roc_year, season
  )

  zip_file <- file.path(data_dir, sprintf("raw_%s_%dS%d.zip", muni, roc_year, season))
  if (file.exists(zip_file)) return(zip_file)

  tryCatch({
    resp <- GET(url, timeout(60))
    if (status_code(resp) == 200 && length(content(resp, "raw")) > 1000) {
      writeBin(content(resp, "raw"), zip_file)
      cat(sprintf("  Downloaded %s %dS%d (%d bytes)\n", muni, roc_year, season, file.size(zip_file)))
      return(zip_file)
    } else {
      cat(sprintf("  Skip %s %dS%d (HTTP %d or too small)\n", muni, roc_year, season, status_code(resp)))
      return(NULL)
    }
  }, error = function(e) {
    cat(sprintf("  Error %s %dS%d: %s\n", muni, roc_year, season, e$message))
    return(NULL)
  })
}

# Actually, the Taiwan open data portal uses a different URL structure.
# Let me use the direct CSV download links from data.gov.tw
# The actual download URL pattern confirmed in the smoke test:
# https://plvr.land.moi.gov.tw/DownloadOpenData

# Alternative approach: use the pre-packaged seasonal CSV files
# URL format: https://plvr.land.moi.gov.tw/DownloadSeason?season=112S3&type=csv&fileName=lvr_landcsv.zip

cat("=== Fetching Taiwan Actual Price Registration Data ===\n")
cat("Attempting bulk download from plvr.land.moi.gov.tw...\n\n")

# Try the seasonal bulk download first
all_files <- list()
download_count <- 0
fail_count <- 0

for (roc_yr in roc_years) {
  for (s in seasons) {
    url <- sprintf(
      "https://plvr.land.moi.gov.tw/DownloadSeason?season=%dS%d&type=csv&fileName=lvr_landcsv.zip",
      roc_yr, s
    )

    zip_file <- file.path(data_dir, sprintf("plvr_%dS%d.zip", roc_yr, s))

    if (file.exists(zip_file) && file.size(zip_file) > 5000) {
      cat(sprintf("  Cached: %dS%d\n", roc_yr, s))
      all_files <- c(all_files, zip_file)
      download_count <- download_count + 1
      next
    }

    Sys.sleep(1)  # Rate limiting

    result <- tryCatch({
      resp <- GET(url, timeout(120),
                  add_headers("User-Agent" = "Mozilla/5.0 APEP-Research"))
      if (status_code(resp) == 200) {
        raw <- content(resp, "raw")
        if (length(raw) > 5000) {
          writeBin(raw, zip_file)
          cat(sprintf("  OK: %dS%d (%s KB)\n", roc_yr, s, format(round(length(raw)/1024), big.mark=",")))
          all_files <- c(all_files, zip_file)
          download_count <- download_count + 1
          "ok"
        } else {
          cat(sprintf("  Too small: %dS%d (%d bytes)\n", roc_yr, s, length(raw)))
          fail_count <- fail_count + 1
          "small"
        }
      } else {
        cat(sprintf("  HTTP %d: %dS%d\n", status_code(resp), roc_yr, s))
        fail_count <- fail_count + 1
        "http_error"
      }
    }, error = function(e) {
      cat(sprintf("  Error: %dS%d — %s\n", roc_yr, s, e$message))
      fail_count <<- fail_count + 1
      "error"
    })
  }
}

cat(sprintf("\n=== Download summary: %d succeeded, %d failed ===\n", download_count, fail_count))

if (download_count == 0) {
  stop("FATAL: No data downloaded from Taiwan Actual Price Registration. Cannot proceed.")
}

# Parse downloaded ZIPs — extract building transaction CSVs
cat("\n=== Parsing downloaded files ===\n")

all_transactions <- list()
parse_count <- 0

for (zf in all_files) {
  tryCatch({
    tmp_dir <- tempdir()
    csv_files <- unzip(zf, list = TRUE)$Name

    # Look for building transaction files (不動產買賣 or containing '_a_' for building sales)
    # The CSV naming convention: {municipality}_lvr_land_a.csv = building transactions
    building_csvs <- csv_files[grepl("_a\\.", csv_files, ignore.case = TRUE)]

    if (length(building_csvs) == 0) {
      # Try alternative pattern
      building_csvs <- csv_files[grepl("(buy|sale|build|不動產)", csv_files, ignore.case = TRUE)]
    }

    if (length(building_csvs) == 0) {
      # Just use all CSVs
      building_csvs <- csv_files[grepl("\\.csv$", csv_files, ignore.case = TRUE)]
    }

    for (cf in building_csvs) {
      unzip(zf, files = cf, exdir = tmp_dir, overwrite = TRUE)
      csv_path <- file.path(tmp_dir, cf)

      if (file.exists(csv_path) && file.size(csv_path) > 100) {
        dt <- tryCatch(
          fread(csv_path, encoding = "UTF-8", fill = TRUE, showProgress = FALSE),
          error = function(e) {
            tryCatch(
              fread(csv_path, encoding = "Big5", fill = TRUE, showProgress = FALSE),
              error = function(e2) NULL
            )
          }
        )

        if (!is.null(dt) && nrow(dt) > 0) {
          # Add source file info
          season_match <- regmatches(basename(zf), regexpr("\\d+S\\d", basename(zf)))
          dt[, source_file := basename(zf)]
          dt[, season_code := ifelse(length(season_match) > 0, season_match, NA_character_)]
          all_transactions[[length(all_transactions) + 1]] <- dt
          parse_count <- parse_count + nrow(dt)
        }
      }
      unlink(csv_path)
    }
  }, error = function(e) {
    cat(sprintf("  Parse error %s: %s\n", basename(zf), e$message))
  })
}

cat(sprintf("\nParsed %d total rows from %d file chunks\n", parse_count, length(all_transactions)))

if (parse_count == 0) {
  stop("FATAL: No transaction data parsed from downloaded files. Cannot proceed.")
}

# Combine all data
combined <- rbindlist(all_transactions, fill = TRUE)
cat(sprintf("Combined dataset: %d rows, %d columns\n", nrow(combined), ncol(combined)))
cat("Column names:\n")
print(names(combined))

# Save raw combined data
fwrite(combined, file.path(data_dir, "taiwan_raw_transactions.csv"))
cat(sprintf("\nSaved raw data: %s\n", file.path(data_dir, "taiwan_raw_transactions.csv")))

# Print sample to understand structure
cat("\n=== First 5 rows (sample) ===\n")
print(head(combined, 5))
