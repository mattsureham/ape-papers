# 01_fetch_data.R — Fetch WFP food price data from HDX
# APEP paper apep_0797: ECOWAS Sanctions and Food Market Fragmentation in Niger

source("00_packages.R")

# ---- Configuration ----
data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

# WFP food prices are available via HDX (Humanitarian Data Exchange)
# Each country has a CSV with all market-commodity-month observations

# Niger (NER) — HDX resource (verified URL from CKAN API)
niger_url <- "https://data.humdata.org/dataset/9c2f8da3-c0a5-476d-9035-b9b59172b922/resource/87334563-5dae-4125-9bcc-e9418283a8c9/download/wfp_food_prices_ner.csv"

# Burkina Faso (BFA) — HDX resource (verified URL from CKAN API)
bfa_url <- "https://data.humdata.org/dataset/bfd82e1f-0296-48a8-ac28-c11e028be5ed/resource/0eca67d6-e297-4f5e-9132-7dc42891b749/download/wfp_food_prices_bfa.csv"

# ---- Download Niger data ----
message("Fetching Niger food price data from HDX...")
niger_file <- file.path(data_dir, "wfp_niger_raw.csv")
download.file(niger_url, niger_file, mode = "wb", quiet = FALSE)
if (!file.exists(niger_file) || file.size(niger_file) < 1000) {
  stop("FATAL: Niger data download failed or file is empty. Cannot proceed with simulated data.")
}
message(sprintf("Niger data: %s bytes", file.size(niger_file)))

# ---- Download Burkina Faso data ----
message("Fetching Burkina Faso food price data from HDX...")
bfa_file <- file.path(data_dir, "wfp_bfa_raw.csv")
download.file(bfa_url, bfa_file, mode = "wb", quiet = FALSE)
if (!file.exists(bfa_file) || file.size(bfa_file) < 1000) {
  stop("FATAL: Burkina Faso data download failed or file is empty. Cannot proceed with simulated data.")
}
message(sprintf("Burkina Faso data: %s bytes", file.size(bfa_file)))

# ---- Read and validate ----
niger_raw <- fread(niger_file)
bfa_raw <- fread(bfa_file)

message(sprintf("Niger: %d rows, %d columns", nrow(niger_raw), ncol(niger_raw)))
message(sprintf("Burkina Faso: %d rows, %d columns", nrow(bfa_raw), ncol(bfa_raw)))
message(sprintf("Niger columns: %s", paste(names(niger_raw), collapse = ", ")))

# Validate we have actual data
stopifnot("Niger data has zero rows" = nrow(niger_raw) > 0)
stopifnot("Burkina Faso data has zero rows" = nrow(bfa_raw) > 0)

# ---- Save raw data ----
fwrite(niger_raw, file.path(data_dir, "niger_raw.csv"))
fwrite(bfa_raw, file.path(data_dir, "bfa_raw.csv"))

message("Data fetch complete. Files saved to data/")
message(sprintf("Niger markets: %d", length(unique(niger_raw$market))))
message(sprintf("BFA markets: %d", length(unique(bfa_raw$market))))
