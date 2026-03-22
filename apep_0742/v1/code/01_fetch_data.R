## 01_fetch_data.R — Fetch all data for FOBT analysis
source("00_packages.R")
if (!requireNamespace("readODS", quietly = TRUE))
  install.packages("readODS", repos = "https://cloud.r-project.org")
library(readODS)

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

nomis_key <- Sys.getenv("NOMIS_API_KEY")
nomis_auth <- if (nchar(nomis_key) > 0) paste0("&uid=", nomis_key) else ""

# ============================================================================
# 1. Home Office PFA-level recorded crime (Mar 2013 onwards, single ODS file)
# ============================================================================
cat("=== Downloading PFA Crime Data ===\n")
pfa_url <- "https://assets.publishing.service.gov.uk/media/69779329d345446f8ce71f5e/prc-pfa-mar2013-onwards-tables-290126.ods"
pfa_file <- file.path(data_dir, "prc_pfa_tables.ods")

if (!file.exists(pfa_file) || file.size(pfa_file) < 50000) {
  resp <- httr::GET(pfa_url, httr::write_disk(pfa_file, overwrite = TRUE), httr::timeout(180))
  stopifnot("FATAL: Cannot download PFA crime data" = httr::status_code(resp) == 200)
}
cat("PFA crime file:", round(file.size(pfa_file)/1024), "KB\n")
stopifnot("FATAL: PFA crime file too small" = file.size(pfa_file) > 50000)

# ============================================================================
# 2. NOMIS UK Business Counts — SIC 92 (Gambling) by LA, 2016-2023
# ============================================================================
cat("\n=== Fetching NOMIS Gambling Business Counts ===\n")
# NOMIS code 146800732 = SIC 92 (Gambling and betting activities)

fetch_nomis <- function(industry_code, label, years = 2016:2023) {
  all_data <- list()
  for (yr in years) {
    cat("  ", label, yr, "...")
    url <- paste0(
      "https://www.nomisweb.co.uk/api/v01/dataset/NM_141_1.data.csv?",
      "geography=TYPE464",
      "&industry=", industry_code,
      "&employment_sizeband=0",
      "&legal_status=0",
      "&measures=20100",
      "&date=", yr,
      nomis_auth
    )
    resp <- httr::GET(url, httr::timeout(60))
    if (httr::status_code(resp) == 200) {
      txt <- httr::content(resp, as = "text", encoding = "UTF-8")
      df <- read.csv(textConnection(txt), stringsAsFactors = FALSE)
      if (nrow(df) > 0) {
        all_data[[as.character(yr)]] <- df %>%
          select(year = DATE_NAME, la_code = GEOGRAPHY_CODE,
                 la_name = GEOGRAPHY_NAME, count = OBS_VALUE) %>%
          mutate(year = as.integer(year), count = as.integer(count))
        cat("->", nrow(df), "LAs\n")
      }
    } else {
      cat("FAILED (", httr::status_code(resp), ")\n")
    }
    Sys.sleep(0.3)
  }
  result <- bind_rows(all_data)
  if (nrow(result) == 0) stop(paste("FATAL: No data for", label))
  return(result)
}

gambling <- fetch_nomis("146800732", "Gambling")
food_svc <- fetch_nomis("146800696", "Food_svc")

saveRDS(gambling, file.path(data_dir, "gambling_biz.rds"))
saveRDS(food_svc, file.path(data_dir, "food_biz.rds"))

# ============================================================================
# 3. NOMIS Population Estimates by LA
# ============================================================================
cat("\n=== Fetching Population Estimates ===\n")

pop_data <- list()
for (yr in 2016:2023) {
  cat("  Pop", yr, "...")
  url <- paste0(
    "https://www.nomisweb.co.uk/api/v01/dataset/NM_31_1.data.csv?",
    "geography=TYPE464",
    "&sex=7&age=0&measures=20100",
    "&date=", yr,
    nomis_auth
  )
  resp <- httr::GET(url, httr::timeout(60))
  if (httr::status_code(resp) == 200) {
    txt <- httr::content(resp, as = "text", encoding = "UTF-8")
    df <- read.csv(textConnection(txt), stringsAsFactors = FALSE)
    if (nrow(df) > 0) {
      pop_data[[as.character(yr)]] <- df %>%
        select(year = DATE_NAME, la_code = GEOGRAPHY_CODE,
               la_name = GEOGRAPHY_NAME, population = OBS_VALUE) %>%
        mutate(year = as.integer(year), population = as.integer(population))
      cat("->", nrow(df), "LAs\n")
    }
  } else {
    cat("FAILED\n")
  }
  Sys.sleep(0.3)
}

population <- bind_rows(pop_data)
stopifnot("FATAL: No population data" = nrow(population) > 0)
saveRDS(population, file.path(data_dir, "population.rds"))

# ============================================================================
# Summary
# ============================================================================
cat("\n=== FETCH SUMMARY ===\n")
cat("PFA crime file:", round(file.size(pfa_file)/1024), "KB\n")
cat("Gambling biz:", nrow(gambling), "LA-years\n")
cat("Food service biz:", nrow(food_svc), "LA-years\n")
cat("Population:", nrow(population), "LA-years\n")
cat("=== DONE ===\n")
