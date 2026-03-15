## 01_fetch_data.R — apep_0697
## Fetch NZ Property Transfer Statistics and BIS House Prices
## REAL DATA ONLY — no simulation, no fallback

source("00_packages.R")

# Load environment variables
env_file <- "../../../../.env"
if (file.exists(env_file)) {
  lines <- readLines(env_file, warn = FALSE)
  for (line in lines) {
    line <- trimws(line)
    if (nchar(line) == 0 || startsWith(line, "#")) next
    parts <- strsplit(line, "=", fixed = TRUE)[[1]]
    if (length(parts) >= 2) {
      key <- trimws(parts[1])
      val <- trimws(paste(parts[-1], collapse = "="))
      val <- gsub("^['\"]|['\"]$", "", val)
      do.call(Sys.setenv, setNames(list(val), key))
    }
  }
  cat("Loaded .env\n")
}

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. Stats NZ Property Transfer Statistics (primary data)
# ============================================================
# Final release: June 2024 quarter
# Contains quarterly property transfers by territorial authority and overseas person status
# Available as Excel download from Stats NZ

pts_url <- "https://www.stats.govt.nz/assets/Uploads/Property-transfer-statistics/Property-transfer-statistics-June-2024-quarter/Download-data/property-transfer-statistics-june-2024-quarter.xlsx"
pts_file <- file.path(data_dir, "nz_property_transfers.xlsx")

cat("Downloading Stats NZ Property Transfer Statistics...\n")
resp <- GET(pts_url, write_disk(pts_file, overwrite = TRUE), timeout(120))
stopifnot("Stats NZ download failed" = status_code(resp) == 200)
cat("  Downloaded:", format(file.size(pts_file), big.mark = ","), "bytes\n")

# Read the Excel file
if (!requireNamespace("readxl", quietly = TRUE)) install.packages("readxl")
library(readxl)

# List sheets to understand structure
sheets <- excel_sheets(pts_file)
cat("  Excel sheets:", paste(sheets, collapse = ", "), "\n")

# Read all sheets to find the one with TA-level data
pts_data_list <- list()
for (s in sheets) {
  tryCatch({
    d <- read_excel(pts_file, sheet = s)
    pts_data_list[[s]] <- d
    cat(sprintf("  Sheet '%s': %d rows x %d cols\n", s, nrow(d), ncol(d)))
    cat("    Columns:", paste(head(names(d), 10), collapse = ", "), "\n")
  }, error = function(e) {
    cat(sprintf("  Sheet '%s': error reading - %s\n", s, e$message))
  })
}

# Save raw sheets as RDS for inspection
saveRDS(pts_data_list, file.path(data_dir, "pts_raw_sheets.rds"))

# ============================================================
# 2. BIS Real Residential Property Prices from FRED (supplementary)
# ============================================================
# Quarterly real house price indices for NZ and OECD donor pool

fred_api_key <- Sys.getenv("FRED_API_KEY")
stopifnot("FRED_API_KEY not set" = nchar(fred_api_key) > 0)

# Country codes for BIS real property prices on FRED
# Series ID pattern: Q{CC}R628BIS (quarterly, real, all residential)
countries <- c(
  NZ = "QNZR628BIS",
  AU = "QAUR628BIS",
  CA = "QCAR628BIS",
  GB = "QGBR628BIS",
  IE = "QIER628BIS",
  NO = "QNOR628BIS",
  DK = "QDKR628BIS",
  SE = "QSER628BIS",
  FI = "QFIR628BIS",
  NL = "QNLR628BIS",
  BE = "QBER628BIS",
  AT = "QATR628BIS",
  FR = "QFRR628BIS",
  ES = "QESR628BIS",
  PT = "QPTR628BIS",
  IT = "QITR628BIS",
  JP = "QJPR628BIS",
  KR = "QKRR628BIS"
)

cat("\nDownloading BIS house prices from FRED...\n")

fetch_fred <- function(series_id, api_key) {
  url <- sprintf(
    "https://api.stlouisfed.org/fred/series/observations?series_id=%s&api_key=%s&file_type=json&observation_start=2005-01-01",
    series_id, api_key
  )
  resp <- GET(url, timeout(30))
  stopifnot(status_code(resp) == 200)
  json <- content(resp, as = "parsed")
  obs <- json$observations
  if (length(obs) == 0) return(NULL)
  tibble(
    date = as.Date(sapply(obs, `[[`, "date")),
    value = as.numeric(sapply(obs, function(x) {
      v <- x[["value"]]
      if (v == ".") return(NA_real_)
      as.numeric(v)
    }))
  )
}

bis_data <- map2_dfr(names(countries), countries, function(cc, series_id) {
  cat(sprintf("  Fetching %s (%s)...", cc, series_id))
  d <- fetch_fred(series_id, fred_api_key)
  if (is.null(d)) {
    cat(" FAILED\n")
    stop(sprintf("No data returned for %s", cc))
  }
  cat(sprintf(" %d obs\n", nrow(d)))
  d %>% mutate(country = cc)
})

cat(sprintf("  Total BIS observations: %d\n", nrow(bis_data)))

# Save BIS data
saveRDS(bis_data, file.path(data_dir, "bis_house_prices.rds"))
write_csv(bis_data, file.path(data_dir, "bis_house_prices.csv"))

cat("\nData fetch complete.\n")
cat(sprintf("  Property transfers: %s\n", pts_file))
cat(sprintf("  BIS prices: %d country-quarter obs across %d countries\n",
            nrow(bis_data), n_distinct(bis_data$country)))
