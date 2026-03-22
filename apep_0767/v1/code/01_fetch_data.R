## 01_fetch_data.R — Fetch SNAP Policy Database and QWI data
source("00_packages.R")

cat("=== Fetching SNAP Policy Database ===\n")

## ---- 1. SNAP Policy Database from USDA ERS ----
snap_url <- "https://www.ers.usda.gov/media/6472/snap-policy-database.xlsx?v=61156"
snap_file <- "../data/snap_policy_database.xlsx"

if (!file.exists(snap_file)) {
  download.file(snap_url, snap_file, mode = "wb")
  cat("Downloaded SNAP Policy Database.\n")
} else {
  cat("SNAP Policy Database already on disk.\n")
}

## Parse the Excel file
if (!requireNamespace("readxl", quietly = TRUE)) install.packages("readxl")
library(readxl)

sheets <- excel_sheets(snap_file)
cat("Available sheets:", paste(sheets, collapse = ", "), "\n")

snap_raw <- NULL
for (sh in sheets) {
  tmp <- tryCatch(read_excel(snap_file, sheet = sh, n_max = 5), error = function(e) NULL)
  if (!is.null(tmp) && "reportsimple" %in% tolower(names(tmp))) {
    snap_raw <- read_excel(snap_file, sheet = sh)
    cat("Found reportsimple in sheet:", sh, "\n")
    break
  }
}

if (is.null(snap_raw)) {
  stop("Cannot find reportsimple in SNAP Policy Database")
}

snap_dt <- as.data.table(snap_raw)
cols_lower <- tolower(names(snap_dt))
rs_col <- names(snap_dt)[grepl("reportsimple", cols_lower)]
cat("Using column:", rs_col[1], "\n")
setnames(snap_dt, rs_col[1], "reportsimple")

fwrite(snap_dt, "../data/snap_policy_raw.csv")
cat("Saved snap_policy_raw.csv with", nrow(snap_dt), "rows.\n")

## ---- 2. QWI Data via Census API ----
cat("\n=== Fetching QWI Data ===\n")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (nchar(census_key) == 0) census_key <- Sys.getenv("CENSUS_KEY")

key_param <- ""
if (nchar(census_key) > 0) {
  key_param <- paste0("&key=", census_key)
  cat("Census API key found.\n")
} else {
  cat("No Census API key found. Proceeding without.\n")
}

base_url <- "https://api.census.gov/data/timeseries/qwi/se"
years <- 2000:2019
quarters <- 1:4
education_levels <- c("E1", "E2", "E3", "E4")

## All US state FIPS codes (wildcard not supported for QWI)
all_fips <- paste0(
  c("01","02","04","05","06","08","09","10","11","12","13","15","16","17","18",
    "19","20","21","22","23","24","25","26","27","28","29","30","31","32","33",
    "34","35","36","37","38","39","40","41","42","44","45","46","47","48","49",
    "50","51","53","54","55","56"),
  collapse = ","
)

all_qwi <- list()
query_count <- 0
fail_count <- 0

for (ed in education_levels) {
  for (yr in years) {
    for (qtr in quarters) {
      url <- paste0(
        base_url,
        "?get=HirA,Sep,TurnOvrS,EarnS,Emp",
        "&for=state:", all_fips,
        "&year=", yr,
        "&quarter=", qtr,
        "&ownercode=A05",
        "&sex=0",
        "&agegrp=A00",
        "&education=", ed,
        key_param
      )

      resp <- tryCatch({
        Sys.sleep(0.12)
        httr::GET(url, httr::timeout(30))
      }, error = function(e) {
        NULL
      })

      if (is.null(resp) || httr::status_code(resp) != 200) {
        fail_count <- fail_count + 1
        next
      }

      json <- httr::content(resp, as = "text", encoding = "UTF-8")
      parsed <- jsonlite::fromJSON(json)

      if (is.null(parsed) || nrow(parsed) < 2) next

      df <- as.data.frame(parsed[-1, , drop = FALSE], stringsAsFactors = FALSE)
      names(df) <- parsed[1, ]

      all_qwi[[length(all_qwi) + 1]] <- df
      query_count <- query_count + 1

      if (query_count %% 40 == 0) {
        cat("Fetched", query_count, "queries (ed:", ed, "yr:", yr, "Q", qtr, ") |",
            fail_count, "failures\n")
      }
    }
  }
  cat("Completed education level", ed, "| Total queries:", query_count, "\n")
}

cat("Total QWI queries completed:", query_count, "| Failures:", fail_count, "\n")

if (length(all_qwi) == 0) {
  stop("FATAL: No QWI data fetched. Cannot proceed.")
}

qwi_dt <- rbindlist(all_qwi, fill = TRUE)

## Convert numeric columns
num_cols <- c("HirA", "Sep", "TurnOvrS", "EarnS", "Emp")
for (col in num_cols) {
  if (col %in% names(qwi_dt)) {
    qwi_dt[, (col) := as.numeric(get(col))]
  }
}

fwrite(qwi_dt, "../data/qwi_state_education.csv")
cat("Saved qwi_state_education.csv with", nrow(qwi_dt), "rows.\n")
cat("States:", uniqueN(qwi_dt$state), "\n")
cat("Education levels:", paste(unique(qwi_dt$education), collapse = ", "), "\n")
cat("Year range:", min(as.numeric(qwi_dt$year), na.rm = TRUE), "-",
    max(as.numeric(qwi_dt$year), na.rm = TRUE), "\n")

cat("\n=== Data fetch complete ===\n")
