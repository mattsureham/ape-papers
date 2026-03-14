## 01_fetch_data.R — Fetch all data for APEP-0683
## Council Tax Empty Homes Premium and Long-Term Vacancy in England
##
## Data sources:
##   1. MHCLG Live Table 615: Long-term vacant dwellings by LA (2004-2024)
##   2. MHCLG Council Taxbase: Premium adoption by LA (multiple years)
##   3. MHCLG Live Table 100: Total dwelling stock by LA
##   4. ONS mid-year population estimates by LA (NOMIS)

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE)

## ============================================================
## 1. MHCLG Live Table 615 — Long-term vacant dwellings
## ============================================================
cat("=== Fetching Table 615 (vacant dwellings) ===\n")

url_615 <- "https://assets.publishing.service.gov.uk/media/69723e20a1311bdcfa0ed8d4/Live_Table_615.ods"

dest_615 <- file.path(data_dir, "Live_Table_615.ods")
if (!file.exists(dest_615)) {
  resp <- httr2::request(url_615) |>
    httr2::req_timeout(120) |>
    httr2::req_perform()
  writeBin(httr2::resp_body_raw(resp), dest_615)
  cat("  Downloaded Table 615:", file.size(dest_615), "bytes\n")
} else {
  cat("  Table 615 already cached.\n")
}

sheets_615 <- readODS::list_ods_sheets(dest_615)
cat("  Sheets:", paste(sheets_615, collapse = ", "), "\n")

## ============================================================
## 2. MHCLG Council Taxbase — Premium adoption data
## ============================================================
cat("\n=== Fetching Council Taxbase data ===\n")

# CTB 2025 (latest — has Tables 1-5 including empty homes premium)
url_ctb_2025 <- "https://assets.publishing.service.gov.uk/media/696f60535b6060ca6736a081/Tables_1_-_5_2025.ods"
dest_ctb_2025 <- file.path(data_dir, "CTB_Tables_1_5_2025.ods")
if (!file.exists(dest_ctb_2025)) {
  resp <- httr2::request(url_ctb_2025) |>
    httr2::req_timeout(120) |>
    httr2::req_perform()
  writeBin(httr2::resp_body_raw(resp), dest_ctb_2025)
  cat("  Downloaded CTB 2025 Tables:", file.size(dest_ctb_2025), "bytes\n")
} else {
  cat("  CTB 2025 already cached.\n")
}

# CTB 2025 Local Authority level data (detailed LA-level premium info)
url_ctb_la_2025 <- "https://assets.publishing.service.gov.uk/media/696f605ff6aa424b452e3359/2025_Local_Authority_Drop_Down.xlsx"
dest_ctb_la_2025 <- file.path(data_dir, "CTB_LA_2025.xlsx")
if (!file.exists(dest_ctb_la_2025)) {
  resp <- httr2::request(url_ctb_la_2025) |>
    httr2::req_timeout(120) |>
    httr2::req_perform()
  writeBin(httr2::resp_body_raw(resp), dest_ctb_la_2025)
  cat("  Downloaded CTB LA 2025:", file.size(dest_ctb_la_2025), "bytes\n")
} else {
  cat("  CTB LA 2025 already cached.\n")
}

# CTB 2024 LA-level data (for historical premium adoption)
url_ctb_la_2024 <- "https://assets.publishing.service.gov.uk/media/67cab2ba8247839c255ae419/Council_Taxbase_Local_Authority_Level_Data_2024.ods"
dest_ctb_la_2024 <- file.path(data_dir, "CTB_LA_2024.ods")
if (!file.exists(dest_ctb_la_2024)) {
  resp <- httr2::request(url_ctb_la_2024) |>
    httr2::req_timeout(120) |>
    httr2::req_perform()
  writeBin(httr2::resp_body_raw(resp), dest_ctb_la_2024)
  cat("  Downloaded CTB LA 2024:", file.size(dest_ctb_la_2024), "bytes\n")
} else {
  cat("  CTB LA 2024 already cached.\n")
}

# CTB 2024 Tables 1-5 (includes historical Table 3b with premium counts)
url_ctb_tables_2024 <- "https://assets.publishing.service.gov.uk/media/675c432c1857548bccbcf9e1/Council_Taxbase_Tables_1_to_5__2024.ods"
dest_ctb_tables_2024 <- file.path(data_dir, "CTB_Tables_1_5_2024.ods")
if (!file.exists(dest_ctb_tables_2024)) {
  resp <- httr2::request(url_ctb_tables_2024) |>
    httr2::req_timeout(120) |>
    httr2::req_perform()
  writeBin(httr2::resp_body_raw(resp), dest_ctb_tables_2024)
  cat("  Downloaded CTB 2024 Tables:", file.size(dest_ctb_tables_2024), "bytes\n")
} else {
  cat("  CTB 2024 Tables already cached.\n")
}

cat("  CTB sheets (2025):", paste(readODS::list_ods_sheets(dest_ctb_2025), collapse = ", "), "\n")
cat("  CTB LA sheets (2025):", paste(readxl::excel_sheets(dest_ctb_la_2025), collapse = ", "), "\n")

## ============================================================
## 3. MHCLG Live Table 100 — Total dwelling stock
## ============================================================
cat("\n=== Fetching Table 100 (dwelling stock) ===\n")

# Try multiple URL patterns (gov.uk media links change)
url_100_candidates <- c(
  "https://assets.publishing.service.gov.uk/media/69723df9a1311bdcfa0ed8d3/Live_Table_100.ods",
  "https://assets.publishing.service.gov.uk/media/67a860719a4f84dfa82a6ca3/LT_100.ods"
)

dest_100 <- file.path(data_dir, "Live_Table_100.ods")
if (!file.exists(dest_100)) {
  fetched <- FALSE
  for (u in url_100_candidates) {
    resp <- tryCatch({
      httr2::request(u) |> httr2::req_timeout(60) |> httr2::req_perform()
    }, error = function(e) NULL)
    if (!is.null(resp)) {
      writeBin(httr2::resp_body_raw(resp), dest_100)
      cat("  Downloaded Table 100:", file.size(dest_100), "bytes\n")
      fetched <- TRUE
      break
    }
  }
  if (!fetched) {
    cat("  WARNING: Table 100 not available. Will use All_vacants from Table 615 for normalization.\n")
  }
} else {
  cat("  Table 100 already cached.\n")
}

## ============================================================
## 4. ONS Mid-Year Population Estimates by LA
## ============================================================
cat("\n=== Fetching ONS population estimates ===\n")

nomis_key <- Sys.getenv("NOMIS_API_KEY")
nomis_base <- "https://www.nomisweb.co.uk/api/v01/"

# MYE by LA — dataset NM_2002_1
pop_url <- paste0(
  nomis_base, "dataset/NM_2002_1.data.csv?",
  "geography=TYPE464",
  "&date=2004-2024",
  "&gender=0",
  "&c_age=200",
  "&measures=20100",
  "&select=date_name,geography_name,geography_code,obs_value"
)
if (nchar(nomis_key) > 0) pop_url <- paste0(pop_url, "&uid=", nomis_key)

dest_pop <- file.path(data_dir, "population_la.csv")
if (!file.exists(dest_pop)) {
  resp <- tryCatch({
    httr2::request(pop_url) |>
      httr2::req_timeout(120) |>
      httr2::req_perform()
  }, error = function(e) {
    cat("  NOMIS population fetch failed:", conditionMessage(e), "\n")
    cat("  Will construct vacancy rates using dwelling stock instead.\n")
    NULL
  })

  if (!is.null(resp)) {
    writeBin(httr2::resp_body_raw(resp), dest_pop)
    cat("  Downloaded population data:", file.size(dest_pop), "bytes\n")
  }
} else {
  cat("  Population data already cached.\n")
}

if (file.exists(dest_pop)) {
  pop_raw <- read_csv(dest_pop, show_col_types = FALSE)
  cat("  Population data:", nrow(pop_raw), "rows,",
      n_distinct(pop_raw$GEOGRAPHY_CODE), "LAs\n")
}

## ============================================================
## Validation: Critical files must exist
## ============================================================
cat("\n=== Data validation ===\n")
required <- c(dest_615, dest_ctb_2025)
for (f in required) {
  if (!file.exists(f)) {
    stop("FATAL: Required data file missing: ", f,
         "\nCannot proceed without real data.")
  }
  cat("  OK:", basename(f), "-", file.size(f), "bytes\n")
}

cat("\n=== Exploring Table 615 structure ===\n")
# Read the long-term vacants sheet
raw_ltv <- readODS::read_ods(dest_615, sheet = "All_long_term_vacants", col_names = FALSE)
cat("  All_long_term_vacants dimensions:", nrow(raw_ltv), "x", ncol(raw_ltv), "\n")
cat("  First 15 rows (to find header):\n")
print(head(raw_ltv, 15))
cat("  Column count:", ncol(raw_ltv), "\n")

# Also peek at All_vacants
raw_av <- readODS::read_ods(dest_615, sheet = "All_vacants", col_names = FALSE)
cat("\n  All_vacants dimensions:", nrow(raw_av), "x", ncol(raw_av), "\n")
cat("  First 10 rows:\n")
print(head(raw_av, 10))

cat("\n=== Exploring CTB structure ===\n")
# Read Table_3b (empty homes premium)
raw_3b <- readODS::read_ods(dest_ctb_2025, sheet = "Table_3b", col_names = FALSE)
cat("  Table_3b dimensions:", nrow(raw_3b), "x", ncol(raw_3b), "\n")
cat("  First 15 rows:\n")
print(head(raw_3b, 15))

# Read Empty Properties Data from LA-level file
ep_sheets <- readxl::excel_sheets(dest_ctb_la_2025)
cat("\n  CTB LA 2025 sheets:", paste(ep_sheets, collapse = ", "), "\n")
raw_ep <- readxl::read_excel(dest_ctb_la_2025, sheet = "Empty Properties Data", col_names = FALSE)
cat("  Empty Properties Data dimensions:", nrow(raw_ep), "x", ncol(raw_ep), "\n")
cat("  First 15 rows:\n")
print(head(raw_ep, 15))

cat("\nData fetch complete.\n")
