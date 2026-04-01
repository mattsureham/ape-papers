## 01_fetch_data.R — Extract NSW PSI data from nested ZIPs
## apep_1281: Pricing to the Cap
##
## NSW Valuer General Property Sales Information (PSI) — bulk download
## Annual ZIPs contain weekly ZIPs; weekly ZIPs contain DAT files per district.
## B-records hold sale data (semicolon-delimited).

source("00_packages.R")

data_dir <- "../data"
years <- 2018:2025

## ---- Download if not present ----
for (yr in years) {
  zf <- file.path(data_dir, paste0(yr, ".zip"))
  if (!file.exists(zf)) {
    url <- paste0("https://www.valuergeneral.nsw.gov.au/__psi/yearly/", yr, ".zip")
    cat("Downloading", yr, "...\n")
    download.file(url, zf, mode = "wb", quiet = TRUE)
  }
}

## ---- Extract all B records ----
cat("Extracting B records from nested ZIPs...\n")

extract_b_records <- function(year_zip) {
  tmp_outer <- tempdir()
  # List weekly ZIPs inside annual ZIP
  weekly_zips <- unzip(year_zip, list = TRUE)$Name
  weekly_zips <- weekly_zips[grepl("\\.zip$", weekly_zips, ignore.case = TRUE)]

  all_rows <- list()
  idx <- 1L

  for (wz in weekly_zips) {
    # Extract weekly ZIP to temp
    unzip(year_zip, files = wz, exdir = tmp_outer, overwrite = TRUE)
    wz_path <- file.path(tmp_outer, wz)

    # List DAT files inside weekly ZIP
    dat_files <- unzip(wz_path, list = TRUE)$Name
    dat_files <- dat_files[grepl("\\.DAT$", dat_files, ignore.case = TRUE)]

    if (length(dat_files) == 0) next

    tmp_inner <- file.path(tmp_outer, paste0("inner_", basename(wz)))
    dir.create(tmp_inner, showWarnings = FALSE)
    unzip(wz_path, files = dat_files, exdir = tmp_inner, overwrite = TRUE)

    for (df in dat_files) {
      fp <- file.path(tmp_inner, df)
      if (!file.exists(fp)) next
      lines <- readLines(fp, warn = FALSE)
      b_lines <- lines[startsWith(lines, "B;")]
      if (length(b_lines) == 0) next
      all_rows[[idx]] <- b_lines
      idx <- idx + 1L
    }
    unlink(tmp_inner, recursive = TRUE)
    unlink(wz_path)
  }

  unlist(all_rows)
}

all_b <- character(0)
for (yr in years) {
  cat("  Processing", yr, "... ")
  zf <- file.path(data_dir, paste0(yr, ".zip"))
  rows <- extract_b_records(zf)
  cat(length(rows), "records\n")
  all_b <- c(all_b, rows)
}

cat("Total B records:", length(all_b), "\n")
stopifnot("No B records extracted" = length(all_b) > 10000)

## ---- Parse B records ----
## B-record fields (semicolon-separated, 1-indexed):
## 1:RecordType, 2:DistrictCode, 3:PropertyID, 4:SaleCounter, 5:DownloadDate,
## 6:UnitNumber, 7:HouseNumber, 8:StreetNumber, 9:StreetName, 10:Locality,
## 11:Postcode, 12:Area, 13:AreaType, 14:ContractDate, 15:SettlementDate,
## 16:PurchasePrice, 17:ZoneCode, 18:NatureOfProperty, 19:PrimaryPurpose,
## 20:StrataLot, 21:CompCode, 22:SaleCode, 23:PercentInterest, 24:DealingNumber

cat("Parsing fields...\n")

# Split all records
split_records <- strsplit(all_b, ";", fixed = TRUE)

# Extract key fields
dt <- data.table(
  district_code   = vapply(split_records, `[`, character(1), 2),
  property_id     = vapply(split_records, `[`, character(1), 3),
  contract_date   = vapply(split_records, `[`, character(1), 14),
  settlement_date = vapply(split_records, `[`, character(1), 15),
  purchase_price  = vapply(split_records, `[`, character(1), 16),
  zone_code       = vapply(split_records, `[`, character(1), 17),
  nature          = vapply(split_records, `[`, character(1), 18),
  primary_purpose = vapply(split_records, `[`, character(1), 19),
  postcode        = vapply(split_records, `[`, character(1), 11),
  locality        = vapply(split_records, `[`, character(1), 10)
)

# Convert types
dt[, purchase_price := as.numeric(purchase_price)]
dt[, contract_date := as.Date(contract_date, format = "%Y%m%d")]

# Drop records with missing price or date
dt <- dt[!is.na(purchase_price) & !is.na(contract_date)]

# Drop zero/negative prices
dt <- dt[purchase_price > 0]

cat("Parsed records:", nrow(dt), "\n")
cat("Date range:", as.character(range(dt$contract_date)), "\n")
cat("Price range:", range(dt$purchase_price), "\n")
cat("Primary purpose counts:\n")
print(table(dt$primary_purpose))

## ---- Save ----
fwrite(dt, file.path(data_dir, "nsw_psi_2018_2025.csv"))
cat("Saved to", file.path(data_dir, "nsw_psi_2018_2025.csv"), "\n")
cat("DONE: 01_fetch_data.R\n")
