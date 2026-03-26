## 01_fetch_data.R — Fetch MAFF cultivated land data from e-Stat API
## apep_0978: From Rice Paddies to Solar Panels

source("00_packages.R")

## Load e-Stat API key from .env
dotenv_path <- file.path(dirname(dirname(getwd())), "..", "..", ".env")
if (file.exists(dotenv_path)) {
  envs <- readLines(dotenv_path, warn = FALSE)
  for (line in envs) {
    if (grepl("^ESTAT_APP_ID=", line)) {
      Sys.setenv(ESTAT_APP_ID = sub("^ESTAT_APP_ID=", "", line))
    }
  }
}

estat_key <- Sys.getenv("ESTAT_APP_ID")
if (nchar(estat_key) == 0) stop("ESTAT_APP_ID not found in .env — cannot fetch data")
cat("e-Stat API key loaded.\n")

## -------------------------------------------------------------------------
## 1. FIT rate schedule (hand-coded from official METI data, public record)
## -------------------------------------------------------------------------
fit_rates <- tibble(
  fiscal_year = 2012:2022,
  fit_rate_yen_kwh = c(40, 36, 32, 29, 27, 24, 21, 18, 14, 12, 11)
)
cat("FIT rate schedule: 2012-2022\n")

## -------------------------------------------------------------------------
## 2. Cultivated land area by prefecture (MAFF Cultivated Land Survey)
## e-Stat table ID: 0003421057 — Cultivated land area by prefecture
## Columns: paddy (ta), upland (hatake), total
## -------------------------------------------------------------------------

## Helper: query e-Stat JSON API
query_estat <- function(stats_data_id, params = list()) {
  base_url <- "https://api.e-stat.go.jp/rest/3.0/app/json/getStatsData"
  params$appId <- estat_key
  params$statsDataId <- stats_data_id
  params$lang <- "E"  # English

  resp <- httr::GET(base_url, query = params)
  if (httr::status_code(resp) != 200) {
    stop(sprintf("e-Stat API returned HTTP %d for table %s",
                 httr::status_code(resp), stats_data_id))
  }

  content <- httr::content(resp, as = "text", encoding = "UTF-8")
  parsed <- jsonlite::fromJSON(content, simplifyVector = FALSE)

  ## Check for API-level errors
  status <- parsed$GET_STATS_DATA$RESULT$STATUS
  if (!is.null(status) && status != 0) {
    msg <- parsed$GET_STATS_DATA$RESULT$ERROR_MSG %||% "Unknown API error"
    stop(sprintf("e-Stat API error (status %s): %s", status, msg))
  }

  parsed
}

## Try the cultivated land survey table
## Table 0003421057: Cultivated land area by prefecture and type
## Fallback: 0003413429 (older format)
cat("Fetching cultivated land data from e-Stat...\n")

## We'll try multiple table IDs since they change across survey years
cultivated_tables <- c("0003421057", "0003413429", "0003422561")

fetch_cultivated_land <- function() {
  for (table_id in cultivated_tables) {
    cat(sprintf("  Trying table %s...\n", table_id))
    tryCatch({
      result <- query_estat(table_id)
      values <- result$GET_STATS_DATA$STATISTICAL_DATA$DATA_INF$VALUE
      if (length(values) > 0) {
        cat(sprintf("  Success: %d records from table %s\n", length(values), table_id))
        return(list(data = values, table_id = table_id))
      }
    }, error = function(e) {
      cat(sprintf("  Table %s failed: %s\n", table_id, e$message))
    })
  }
  return(NULL)
}

estat_result <- fetch_cultivated_land()

## -------------------------------------------------------------------------
## 3. Parse e-Stat response OR fall back to direct MAFF yearbook download
## -------------------------------------------------------------------------

if (!is.null(estat_result)) {
  ## Parse the e-Stat JSON response
  cat("Parsing e-Stat cultivated land data...\n")

  raw_values <- estat_result$data

  ## Convert list of lists to data frame
  df_raw <- bind_rows(lapply(raw_values, function(v) {
    as_tibble(v)
  }))

  cat(sprintf("Raw data: %d rows, %d cols\n", nrow(df_raw), ncol(df_raw)))
  cat("Columns:", paste(names(df_raw), collapse = ", "), "\n")

  ## Save raw for debugging
  write_csv(df_raw, "../data/estat_cultivated_raw.csv")
  cat("Saved raw data to data/estat_cultivated_raw.csv\n")

} else {
  cat("e-Stat API tables not available. Falling back to direct MAFF download...\n")
}

## -------------------------------------------------------------------------
## 4. Alternative: Fetch from MAFF website directly
## The MAFF yearbook tables are publicly available as Excel files
## -------------------------------------------------------------------------

## Regardless of e-Stat success, also fetch the direct MAFF data for validation
## MAFF Cultivated Land Area: published annually in Statistics of Agriculture
## URL pattern for cultivated land by prefecture

cat("\nFetching MAFF cultivated land area (direct download)...\n")

## MAFF publishes time series data at:
## https://www.maff.go.jp/j/tokei/kouhyou/sakumotu/menseki/
## The English data portal has CSV downloads

## Use e-Stat bulk download for table 0003421057
## This gives us cultivated land by prefecture, paddy vs upland, annually

## Alternative approach: use the e-Stat getStatsList to find the right table
cat("Searching for cultivated land survey tables...\n")
search_resp <- httr::GET(
  "https://api.e-stat.go.jp/rest/3.0/app/json/getStatsList",
  query = list(
    appId = estat_key,
    searchWord = "cultivated land area prefecture",
    lang = "E",
    limit = 5
  )
)

if (httr::status_code(search_resp) == 200) {
  search_content <- httr::content(search_resp, as = "text", encoding = "UTF-8")
  search_parsed <- jsonlite::fromJSON(search_content, simplifyVector = FALSE)
  tables <- search_parsed$GET_STATS_LIST$DATALIST_INF$TABLE_INF
  if (length(tables) > 0) {
    cat(sprintf("Found %d candidate tables:\n", length(tables)))
    for (i in seq_along(tables)) {
      tbl <- tables[[i]]
      tid <- tbl$`@id` %||% "unknown"
      title <- tbl$TITLE %||% tbl$TITLE_SPEC$TABLE_NAME %||% "unknown"
      if (is.list(title)) title <- title[[1]] %||% "unknown"
      cat(sprintf("  [%d] ID=%s: %s\n", i, tid, substr(as.character(title), 1, 80)))
    }
  }
}

## -------------------------------------------------------------------------
## 5. Also search in Japanese to find MAFF tables
## -------------------------------------------------------------------------
cat("\nSearching for 耕地面積 (cultivated area) tables...\n")
search_jp <- httr::GET(
  "https://api.e-stat.go.jp/rest/3.0/app/json/getStatsList",
  query = list(
    appId = estat_key,
    searchWord = "耕地面積 都道府県",
    lang = "J",
    limit = 10
  )
)

jp_table_ids <- c()
if (httr::status_code(search_jp) == 200) {
  jp_content <- httr::content(search_jp, as = "text", encoding = "UTF-8")
  jp_parsed <- jsonlite::fromJSON(jp_content, simplifyVector = FALSE)
  jp_tables <- jp_parsed$GET_STATS_LIST$DATALIST_INF$TABLE_INF
  if (length(jp_tables) > 0) {
    cat(sprintf("Found %d Japanese tables:\n", min(length(jp_tables), 10)))
    for (i in seq_along(jp_tables[1:min(10, length(jp_tables))])) {
      tbl <- jp_tables[[i]]
      tid <- tbl$`@id` %||% "unknown"
      title_obj <- tbl$TITLE_SPEC$TABLE_NAME %||% tbl$TITLE %||% "unknown"
      if (is.list(title_obj)) title_obj <- title_obj[[1]] %||% "unknown"
      cat(sprintf("  [%d] ID=%s: %s\n", i, tid, substr(as.character(title_obj), 1, 80)))
      jp_table_ids <- c(jp_table_ids, tid)
    }
  }
}

## -------------------------------------------------------------------------
## 6. Fetch the best available table
## -------------------------------------------------------------------------
cat("\nAttempting to fetch data from discovered tables...\n")

all_candidate_ids <- unique(c(cultivated_tables, jp_table_ids))
cultivated_df <- NULL

for (tid in all_candidate_ids) {
  cat(sprintf("  Trying table %s...\n", tid))
  tryCatch({
    result <- query_estat(tid)
    values <- result$GET_STATS_DATA$STATISTICAL_DATA$DATA_INF$VALUE
    if (length(values) > 10) {
      cat(sprintf("  Got %d records. Parsing...\n", length(values)))

      df_temp <- bind_rows(lapply(values, function(v) {
        as_tibble(v)
      }))

      cat(sprintf("  Parsed: %d rows x %d cols\n", nrow(df_temp), ncol(df_temp)))
      cat("  Columns:", paste(names(df_temp), collapse = ", "), "\n")
      cat("  First few values:\n")
      print(head(df_temp, 3))

      ## Save this result
      write_csv(df_temp, sprintf("../data/estat_table_%s_raw.csv", tid))

      if (is.null(cultivated_df) || nrow(df_temp) > nrow(cultivated_df)) {
        cultivated_df <- df_temp
        cat(sprintf("  ** Best table so far: %s with %d rows **\n", tid, nrow(df_temp)))
      }
    }
  }, error = function(e) {
    cat(sprintf("  Failed: %s\n", e$message))
  })
}

## -------------------------------------------------------------------------
## 7. Construct the analysis dataset
## -------------------------------------------------------------------------

if (is.null(cultivated_df) || nrow(cultivated_df) == 0) {
  ## Last resort: construct from MAFF yearbook data published on web
  ## The smoke test confirmed these URLs work
  cat("\n** All e-Stat tables failed. Constructing from known MAFF data. **\n")
  cat("Using smoke-test confirmed data from MAFF yearbook.\n")

  ## MAFF publishes cultivated land data annually. The smoke test confirmed:
  ## - HTTP 200 from MAFF yearbook
  ## - Hokkaido: 1,143,000 ha (80.6% upland), Niigata: 168,200 ha (11.2% upland)
  ## - FY2020: 16,065.8 ha national land diversion

  ## Try one more approach: MAFF direct download
  maff_url <- "https://www.e-stat.go.jp/stat-search/file-download?statInfId=000040181838&fileKind=0"
  cat(sprintf("Trying direct MAFF download: %s\n", maff_url))

  tryCatch({
    temp_file <- tempfile(fileext = ".xlsx")
    download.file(maff_url, temp_file, mode = "wb", quiet = TRUE)
    maff_data <- readxl::read_excel(temp_file, sheet = 1)
    cat(sprintf("Direct download: %d rows x %d cols\n", nrow(maff_data), ncol(maff_data)))
    write_csv(maff_data, "../data/maff_direct_download.csv")
  }, error = function(e) {
    cat(sprintf("Direct download failed: %s\n", e$message))
  })
}

## -------------------------------------------------------------------------
## 8. If we have cultivated data, parse into panel
## -------------------------------------------------------------------------

## Save the FIT rates
write_csv(fit_rates, "../data/fit_rates.csv")
cat("\nFIT rates saved.\n")

## Check what we got
data_files <- list.files("../data", pattern = "\\.csv$", full.names = TRUE)
cat("\nData files in data/:\n")
for (f in data_files) {
  sz <- file.info(f)$size
  cat(sprintf("  %s (%s bytes)\n", basename(f), format(sz, big.mark = ",")))
}

## -------------------------------------------------------------------------
## 9. Search for alternative data: agricultural statistics
## -------------------------------------------------------------------------
cat("\n=== Searching for agricultural statistics with prefecture detail ===\n")

## Search for 作物統計 (crop statistics) with prefecture breakdown
search_crop <- httr::GET(
  "https://api.e-stat.go.jp/rest/3.0/app/json/getStatsList",
  query = list(
    appId = estat_key,
    searchWord = "耕地面積",
    statsCode = "00500209",  # MAFF statistics code
    lang = "J",
    limit = 20
  )
)

crop_table_ids <- c()
if (httr::status_code(search_crop) == 200) {
  crop_content <- httr::content(search_crop, as = "text", encoding = "UTF-8")
  crop_parsed <- jsonlite::fromJSON(crop_content, simplifyVector = FALSE)
  crop_tables <- crop_parsed$GET_STATS_LIST$DATALIST_INF$TABLE_INF
  if (!is.null(crop_tables) && length(crop_tables) > 0) {
    cat(sprintf("Found %d MAFF crop/land tables:\n", length(crop_tables)))
    for (i in seq_along(crop_tables[1:min(20, length(crop_tables))])) {
      tbl <- crop_tables[[i]]
      tid <- tbl$`@id` %||% "unknown"
      title_obj <- tbl$TITLE_SPEC$TABLE_NAME %||% "unknown"
      if (is.list(title_obj)) title_obj <- title_obj[[1]] %||% "unknown"
      cycle <- tbl$CYCLE %||% ""
      survey_date <- tbl$SURVEY_DATE %||% ""
      cat(sprintf("  [%d] ID=%s (%s, %s): %s\n", i, tid, cycle, survey_date,
                  substr(as.character(title_obj), 1, 100)))
      crop_table_ids <- c(crop_table_ids, tid)
    }
  } else {
    cat("No MAFF tables found with statsCode 00500209\n")
  }
}

## -------------------------------------------------------------------------
## 10. Try fetching from the best crop/land tables
## -------------------------------------------------------------------------
if (length(crop_table_ids) > 0) {
  cat("\nFetching from discovered MAFF cultivated land tables...\n")
  best_df <- NULL
  best_id <- NULL

  for (tid in crop_table_ids[1:min(5, length(crop_table_ids))]) {
    cat(sprintf("  Trying %s...\n", tid))
    tryCatch({
      result <- query_estat(tid)
      values <- result$GET_STATS_DATA$STATISTICAL_DATA$DATA_INF$VALUE
      if (length(values) > 0) {
        df_temp <- bind_rows(lapply(values, function(v) as_tibble(v)))
        cat(sprintf("  -> %d rows x %d cols\n", nrow(df_temp), ncol(df_temp)))

        ## Check if this has prefecture-level data (should have ~47 unique areas)
        area_cols <- grep("area|地域|都道府県", names(df_temp), value = TRUE, ignore.case = TRUE)
        cat(sprintf("  Area-like columns: %s\n", paste(area_cols, collapse = ", ")))

        write_csv(df_temp, sprintf("../data/maff_table_%s.csv", tid))

        if (is.null(best_df) || nrow(df_temp) > nrow(best_df)) {
          best_df <- df_temp
          best_id <- tid
        }
      }
    }, error = function(e) {
      cat(sprintf("  Failed: %s\n", e$message))
    })
  }

  if (!is.null(best_df)) {
    cat(sprintf("\nBest MAFF table: %s (%d rows)\n", best_id, nrow(best_df)))
    cat("Column names:\n")
    cat(paste(names(best_df), collapse = "\n"), "\n")
    cat("\nSample rows:\n")
    print(head(best_df, 10))

    ## Save as main dataset
    write_csv(best_df, "../data/cultivated_land_raw.csv")
    cat("Saved to data/cultivated_land_raw.csv\n")
  }
}

cat("\n=== Data fetch complete ===\n")
cat("Next step: 02_clean_data.R will parse and construct the analysis panel.\n")
