# ==============================================================================
# 01_fetch_data.R — Fetch WFP food price data from Humanitarian Data Exchange
# Paper: Trade Protection by Fiat (apep_0595)
# ==============================================================================

source("00_packages.R")

# --- Download WFP food prices for Nigeria ---
nga_url <- "https://data.humdata.org/dataset/42db041f-7aaf-4ab4-961f-2a12096861e7/resource/12b51155-0cd3-4806-9924-61ede4077591/download/wfp_food_prices_nga.csv"
nga_file <- file.path(DATA_DIR, "wfp_food_prices_nga.csv")

if (!file.exists(nga_file)) {
  tryCatch({
    download.file(nga_url, nga_file, mode = "wb", quiet = FALSE)
  }, error = function(e) {
    stop("Nigeria WFP data unavailable: ", e$message,
         "\nPivot research question or fix the source.")
  })
}

nga_raw <- fread(nga_file)
cat("Nigeria raw data:", nrow(nga_raw), "rows,",
    n_distinct(nga_raw$market), "markets,",
    n_distinct(nga_raw$commodity), "commodities\n")

# --- Download WFP food prices for Benin (cross-border validation) ---
ben_url <- "https://data.humdata.org/dataset/66c7d54e-0c3b-45e5-9a46-07ea6f195093/resource/7da1ea0a-56c7-450a-af2c-d477745fc856/download/wfp_food_prices_ben.csv"
ben_file <- file.path(DATA_DIR, "wfp_food_prices_ben.csv")

if (!file.exists(ben_file)) {
  tryCatch({
    download.file(ben_url, ben_file, mode = "wb", quiet = FALSE)
  }, error = function(e) {
    stop("Benin WFP data unavailable: ", e$message,
         "\nPivot research question or fix the source.")
  })
}

ben_raw <- fread(ben_file)
cat("Benin raw data:", nrow(ben_raw), "rows,",
    n_distinct(ben_raw$market), "markets\n")

# --- Download WFP food prices for Niger (cross-border validation) ---
ner_url <- "https://data.humdata.org/dataset/9c2f8da3-c0a5-476d-9035-b9b59172b922/resource/87334563-5dae-4125-9bcc-e9418283a8c9/download/wfp_food_prices_ner.csv"
ner_file <- file.path(DATA_DIR, "wfp_food_prices_ner.csv")

if (!file.exists(ner_file)) {
  tryCatch({
    download.file(ner_url, ner_file, mode = "wb", quiet = FALSE)
  }, error = function(e) {
    stop("Niger WFP data unavailable: ", e$message,
         "\nPivot research question or fix the source.")
  })
}

ner_raw <- fread(ner_file)
cat("Niger raw data:", nrow(ner_raw), "rows,",
    n_distinct(ner_raw$market), "markets\n")

# --- Save raw data ---
fwrite(nga_raw, file.path(DATA_DIR, "nga_raw.csv"))
fwrite(ben_raw, file.path(DATA_DIR, "ben_raw.csv"))
fwrite(ner_raw, file.path(DATA_DIR, "ner_raw.csv"))

# === DATA VALIDATION (required) ===
stopifnot("Expected 50+ markets in Nigeria" = n_distinct(nga_raw$market) >= 50)
stopifnot("Expected data spanning 2017-2021" = all(
  c(2017, 2018, 2019, 2020, 2021) %in% year(as.Date(nga_raw$date))
))
stopifnot("Expected Benin data" = nrow(ben_raw) > 100)
stopifnot("Expected Niger data" = nrow(ner_raw) > 100)
stopifnot("Expected latitude/longitude in Nigeria data" = all(c("latitude", "longitude") %in% names(nga_raw)))

cat("Data validation passed:", nrow(nga_raw), "NGA rows,",
    nrow(ben_raw), "BEN rows,", nrow(ner_raw), "NER rows\n")
cat("Data fetch complete.\n")
