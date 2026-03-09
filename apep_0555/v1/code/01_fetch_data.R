## ============================================================================
## 01_fetch_data.R — Fetch WFP food price data from Humanitarian Data Exchange
## Paper: Demonetization by Design (apep_0555)
## ============================================================================

source(file.path(here::here(), "output", "apep_0555", "v1", "code", "00_packages.R"))

## --- 1. WFP Nigeria Food Prices (HDX) ---
wfp_url <- "https://data.humdata.org/dataset/42db041f-7aaf-4ab4-961f-2a12096861e7/resource/12b51155-0cd3-4806-9924-61ede4077591/download/wfp_food_prices_nga.csv"
wfp_file <- file.path(data_dir, "wfp_food_prices_nga.csv")

if (!file.exists(wfp_file)) {
  cat("Downloading WFP Nigeria food prices...\n")
  tryCatch({
    download.file(wfp_url, wfp_file, mode = "wb", quiet = FALSE)
  }, error = function(e) {
    stop("WFP data unavailable: ", e$message,
         "\nThis is the primary dataset. Cannot proceed without it.")
  })
}

wfp <- fread(wfp_file)
cat("WFP data loaded:", nrow(wfp), "rows\n")

## --- 2. WFP Benin Food Prices (cross-border validation) ---
benin_url <- "https://data.humdata.org/dataset/4fdcd4dc-5c2f-43af-a1e4-93c9b6539571/resource/5a42b386-3dca-4b97-9e66-0f5c5e834f60/download/wfp_food_prices_ben.csv"
benin_file <- file.path(data_dir, "wfp_food_prices_ben.csv")

if (!file.exists(benin_file)) {
  cat("Downloading WFP Benin food prices (cross-border validation)...\n")
  tryCatch({
    download.file(benin_url, benin_file, mode = "wb", quiet = FALSE)
  }, error = function(e) {
    warning("Benin cross-border data unavailable: ", e$message,
            "\nCross-border analysis will be excluded. Core analysis proceeds.")
  })
}

if (file.exists(benin_file)) {
  benin <- fread(benin_file)
  cat("Benin data loaded:", nrow(benin), "rows\n")
  fwrite(benin, file.path(data_dir, "benin_prices_raw.csv"))
}

## --- 3. WFP Niger Food Prices (cross-border validation) ---
niger_url <- "https://data.humdata.org/dataset/3e087bdb-a640-4b6c-ba6f-0533e015e605/resource/e0151be4-2b07-4637-8fcd-ad3eda2bc404/download/wfp_food_prices_ner.csv"
niger_file <- file.path(data_dir, "wfp_food_prices_ner.csv")

if (!file.exists(niger_file)) {
  cat("Downloading WFP Niger food prices (cross-border validation)...\n")
  tryCatch({
    download.file(niger_url, niger_file, mode = "wb", quiet = FALSE)
  }, error = function(e) {
    warning("Niger cross-border data unavailable: ", e$message,
            "\nCross-border analysis will be excluded. Core analysis proceeds.")
  })
}

if (file.exists(niger_file)) {
  niger <- fread(niger_file)
  cat("Niger data loaded:", nrow(niger), "rows\n")
  fwrite(niger, file.path(data_dir, "niger_prices_raw.csv"))
}

## --- 4. CBN Currency in Circulation (for recovery analysis) ---
## CBN publishes monetary aggregates in their Statistical Bulletin
## We construct monthly currency-in-circulation from publicly available CBN data
## Using World Bank API as backup for broader monetary aggregates
wb_url <- "https://api.worldbank.org/v2/country/NGA/indicator/FM.LBL.CUSE.CN?format=json&per_page=100&date=2015:2025"
cat("Fetching World Bank monetary data for Nigeria...\n")
tryCatch({
  wb_resp <- httr::GET(wb_url)
  if (httr::status_code(wb_resp) == 200) {
    wb_json <- jsonlite::fromJSON(httr::content(wb_resp, "text", encoding = "UTF-8"))
    if (length(wb_json) >= 2 && !is.null(wb_json[[2]])) {
      wb_money <- as.data.table(wb_json[[2]])
      wb_money <- wb_money[!is.na(value), .(year = as.integer(date), currency_outside_banks = as.numeric(value))]
      fwrite(wb_money, file.path(data_dir, "wb_money_supply.csv"))
      cat("World Bank monetary data saved:", nrow(wb_money), "rows\n")
    }
  }
}, error = function(e) {
  warning("World Bank monetary data unavailable: ", e$message)
})

## --- 5. ACLED Conflict Data (for robustness — exclude conflict-affected markets) ---
acled_email <- Sys.getenv("ACLED_EMAIL")
acled_password <- Sys.getenv("ACLED_PASSWORD")

if (nzchar(acled_email) && nzchar(acled_password)) {
  cat("Fetching ACLED conflict data for Nigeria (2020-2024)...\n")

  ## ACLED v4 API uses direct authentication
  acled_url <- paste0(
    "https://api.acleddata.com/acled/read?",
    "key=", acled_password,
    "&email=", acled_email,
    "&country=Nigeria",
    "&year=2020|2021|2022|2023|2024",
    "&limit=0"
  )

  tryCatch({
    acled_resp <- httr::GET(acled_url, httr::timeout(120))
    if (httr::status_code(acled_resp) == 200) {
      acled_json <- jsonlite::fromJSON(httr::content(acled_resp, "text", encoding = "UTF-8"))
      if (!is.null(acled_json$data) && length(acled_json$data) > 0) {
        acled_dt <- as.data.table(acled_json$data)
        acled_dt <- acled_dt[, .(
          event_date = as.Date(event_date),
          year = as.integer(year),
          event_type,
          admin1,
          admin2,
          latitude = as.numeric(latitude),
          longitude = as.numeric(longitude),
          fatalities = as.integer(fatalities)
        )]
        fwrite(acled_dt, file.path(data_dir, "acled_nigeria_2020_2024.csv"))
        cat("ACLED data saved:", nrow(acled_dt), "events\n")
      } else {
        warning("ACLED returned empty data.")
      }
    } else {
      warning("ACLED API returned status: ", httr::status_code(acled_resp))
    }
  }, error = function(e) {
    warning("ACLED data fetch failed: ", e$message,
            "\nConflict robustness check will use state-level classification instead.")
  })
} else {
  cat("ACLED credentials not found. Will use state-level conflict classification.\n")
}

## --- 6. Save primary dataset ---
fwrite(wfp, file.path(data_dir, "wfp_prices_raw.csv"))

## === DATA VALIDATION (required) ===
stopifnot("Expected 50+ markets" = n_distinct(wfp$market) >= 50)
stopifnot("Expected 30+ commodities" = n_distinct(wfp$commodity) >= 30)
stopifnot("Expected 10+ states" = n_distinct(wfp$admin1) >= 10)
stopifnot("Expected 40000+ observations" = nrow(wfp) >= 40000)

cat("\n=== DATA VALIDATION PASSED ===\n")
cat("Total rows:", nrow(wfp), "\n")
cat("Markets:", n_distinct(wfp$market), "\n")
cat("States:", n_distinct(wfp$admin1), "\n")
cat("Commodities:", n_distinct(wfp$commodity), "\n")
cat("Date range:", min(wfp$date), "to", max(wfp$date), "\n")
