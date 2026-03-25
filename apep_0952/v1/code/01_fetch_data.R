## 01_fetch_data.R — Parse NSW Valuer General Property Sales .DAT files
## apep_0952: Australian Stamp Duty Threshold Bunching

source("00_packages.R")

## ---- Helper: Parse a single weekly ZIP file ----
parse_weekly_zip <- function(zip_path) {
  # Create temp dir, unzip, read all .DAT files
  tmp <- tempdir()
  subdir <- file.path(tmp, basename(zip_path))
  dir.create(subdir, showWarnings = FALSE, recursive = TRUE)

  tryCatch({
    unzip(zip_path, exdir = subdir, overwrite = TRUE)

    dat_files <- list.files(subdir, pattern = "\\.DAT$", full.names = TRUE,
                            recursive = TRUE)

    if (length(dat_files) == 0) return(data.table())

    all_lines <- lapply(dat_files, function(f) {
      lines <- readLines(f, warn = FALSE)
      # Keep only B records (sales data)
      b_lines <- lines[startsWith(lines, "B;")]
      if (length(b_lines) == 0) return(data.table())

      # Split by semicolon
      splits <- strsplit(b_lines, ";", fixed = TRUE)

      # Extract key fields (B record layout):
      # 1=type, 2=district, 3=property_id, 4=seq, 5=timestamp,
      # 6=?, 7=?, 8=street_num, 9=street, 10=suburb, 11=postcode,
      # 12=area, 13=area_unit, 14=contract_date, 15=settlement_date,
      # 16=purchase_price, 17=zoning, 18=nature, 19=description,
      # 20=?, 21=dealing_type
      dt <- data.table(
        district_code = sapply(splits, `[`, 2),
        property_id   = sapply(splits, `[`, 3),
        suburb        = sapply(splits, `[`, 10),
        postcode      = sapply(splits, `[`, 11),
        area          = sapply(splits, `[`, 12),
        area_unit     = sapply(splits, `[`, 13),
        contract_date = sapply(splits, `[`, 14),
        settlement_date = sapply(splits, `[`, 15),
        purchase_price = sapply(splits, `[`, 16),
        zoning        = sapply(splits, `[`, 17),
        nature        = sapply(splits, `[`, 18),
        description   = sapply(splits, `[`, 19),
        dealing_type  = sapply(splits, `[`, 21)
      )
      return(dt)
    })

    rbindlist(all_lines, fill = TRUE)
  }, error = function(e) {
    warning(paste("Error parsing", zip_path, ":", e$message))
    data.table()
  })
}

## ---- Parse all available data ----
data_dir <- "../data"
raw_dirs <- list.dirs(data_dir, recursive = FALSE)
raw_dirs <- raw_dirs[grepl("raw_20", raw_dirs)]

# Also check for nested weekly ZIPs inside yearly extractions
all_zips <- c()
for (rd in raw_dirs) {
  zips <- list.files(rd, pattern = "\\.zip$", full.names = TRUE)
  all_zips <- c(all_zips, zips)
}

cat("Found", length(all_zips), "weekly ZIP files to parse.\n")

# Parse all files
all_sales <- rbindlist(
  lapply(seq_along(all_zips), function(i) {
    if (i %% 10 == 0) cat("Parsing file", i, "of", length(all_zips), "\n")
    parse_weekly_zip(all_zips[i])
  }),
  fill = TRUE
)

cat("Total raw B records:", nrow(all_sales), "\n")

## ---- Clean and filter ----
# Convert types
all_sales[, purchase_price := as.numeric(purchase_price)]
all_sales[, area := as.numeric(area)]
all_sales[, contract_date := as.Date(contract_date, format = "%Y%m%d")]
all_sales[, settlement_date := as.Date(settlement_date, format = "%Y%m%d")]

# Filter: residential sales only, valid price and date
sales <- all_sales[
  nature == "R" &                    # Residential
  !is.na(purchase_price) &
  purchase_price > 0 &
  !is.na(contract_date) &
  contract_date >= as.Date("2017-01-01") &  # Keep 2017+ for analysis
  contract_date <= as.Date("2026-03-31")
]

# Remove duplicates (same property, same contract date, same price)
sales <- unique(sales, by = c("property_id", "contract_date", "purchase_price"))

cat("After filtering: ", nrow(sales), "residential sales\n")
cat("Date range:", as.character(min(sales$contract_date)),
    "to", as.character(max(sales$contract_date)), "\n")

# Save parsed data
fwrite(sales, "../data/nsw_residential_sales.csv")
cat("Saved to data/nsw_residential_sales.csv\n")

# Quick diagnostics
cat("\n--- Sales by year ---\n")
sales[, .(n = .N), by = year(contract_date)][order(year)]
print(sales[, .(n = .N), by = year(contract_date)][order(year)])

cat("\n--- Sales in $700K-$900K range by year ---\n")
print(sales[purchase_price >= 700000 & purchase_price <= 900000,
            .(n = .N), by = year(contract_date)][order(year)])

# Check around $800K threshold
cat("\n--- Sales in $790K-$810K by half-year ---\n")
sales[, half := ifelse(month(contract_date) <= 6, "H1", "H2")]
sales[, yr_half := paste0(year(contract_date), "-", half)]
print(sales[purchase_price >= 790000 & purchase_price <= 810000,
            .(n = .N), by = yr_half][order(yr_half)])
