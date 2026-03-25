## 01_fetch_data.R — Fetch DLUHC planning statistics and brownfield data
## APEP paper apep_0933: BNG and Housing Development in England

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

cat("=== Fetching DLUHC Planning Application Statistics ===\n")

# ---- 1. PS2: Planning decisions by LA and quarter ----
# Source: DLUHC Live Table PS2 — quarterly planning decisions
# https://www.gov.uk/government/statistical-data-sets/live-tables-on-planning-application-statistics
ps2_url <- "https://assets.publishing.service.gov.uk/media/69b97b36635612b767a4667e/PS2_data_-_open_data_table__202512_.csv"

cat("Downloading PS2 (planning decisions)...\n")
ps2_path <- file.path(data_dir, "ps2_raw.csv")
resp <- httr2::request(ps2_url) |>
  httr2::req_timeout(120) |>
  httr2::req_perform()

if (httr2::resp_status(resp) != 200) {
  stop("FATAL: PS2 download failed with status ", httr2::resp_status(resp))
}
writeBin(httr2::resp_body_raw(resp), ps2_path)
cat("PS2 saved:", ps2_path, "\n")

# Validate PS2 downloaded correctly
ps2_raw <- readr::read_csv(ps2_path, show_col_types = FALSE)
stopifnot("PS2 has no rows" = nrow(ps2_raw) > 1000)
cat("PS2 rows:", nrow(ps2_raw), "\n")
cat("PS2 columns:", paste(names(ps2_raw), collapse = ", "), "\n")

# ---- 2. PS1: Planning applications received ----
ps1_url <- "https://assets.publishing.service.gov.uk/media/69b97b4ac06ba9576435ab75/PS1_data_-_open_data_table__202512_.csv"

cat("Downloading PS1 (applications received)...\n")
ps1_path <- file.path(data_dir, "ps1_raw.csv")
resp1 <- httr2::request(ps1_url) |>
  httr2::req_timeout(120) |>
  httr2::req_perform()

if (httr2::resp_status(resp1) != 200) {
  stop("FATAL: PS1 download failed with status ", httr2::resp_status(resp1))
}
writeBin(httr2::resp_body_raw(resp1), ps1_path)
cat("PS1 saved:", ps1_path, "\n")

ps1_raw <- readr::read_csv(ps1_path, show_col_types = FALSE)
stopifnot("PS1 has no rows" = nrow(ps1_raw) > 1000)
cat("PS1 rows:", nrow(ps1_raw), "\n")

# ---- 3. Brownfield Land Register (consolidated national dataset) ----
# Source: data.gov.uk — DLUHC publishes a consolidated national brownfield register
blr_url <- "https://files.planning.data.gov.uk/dataset/brownfield-land.csv"

cat("Downloading Brownfield Land Register...\n")
blr_path <- file.path(data_dir, "brownfield_land.csv")
resp_blr <- httr2::request(blr_url) |>
  httr2::req_timeout(120) |>
  httr2::req_perform()

if (httr2::resp_status(resp_blr) != 200) {
  stop("FATAL: Brownfield Land Register download failed with status ", httr2::resp_status(resp_blr))
}
writeBin(httr2::resp_body_raw(resp_blr), blr_path)
cat("BLR saved:", blr_path, "\n")

blr_raw <- readr::read_csv(blr_path, show_col_types = FALSE, guess_max = 50000)
stopifnot("BLR has no rows" = nrow(blr_raw) > 100)
cat("BLR rows:", nrow(blr_raw), "\n")
cat("BLR columns:", paste(names(blr_raw), collapse = ", "), "\n")

cat("\n=== All data fetched successfully ===\n")
cat("PS2:", nrow(ps2_raw), "rows\n")
cat("PS1:", nrow(ps1_raw), "rows\n")
cat("BLR:", nrow(blr_raw), "rows\n")
