## 01_fetch_data.R — Download Land Registry Price Paid Data
## Data source: HM Land Registry, OGL v3 licence
## URL: https://www.gov.uk/government/statistical-data-sets/price-paid-data-downloads

library(data.table)
library(httr)

out_dir <- "data/"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

## Download yearly PPD files (2010-2019) — each is ~50-100 MB CSV
base_url <- "http://prod.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com"

years <- 2010:2019
col_names <- c("txn_id", "price", "date", "postcode", "prop_type",
               "new_build", "estate_type", "saon", "paon", "street",
               "locality", "town", "district", "county", "txn_category",
               "status")

all_data <- list()

for (yr in years) {
  fname <- file.path(out_dir, paste0("ppd_", yr, ".csv"))
  url <- paste0(base_url, "/pp-", yr, ".csv")

  if (!file.exists(fname)) {
    cat("Downloading PPD", yr, "...\n")
    res <- GET(url, write_disk(fname, overwrite = TRUE), timeout(600))
    if (status_code(res) != 200) {
      stop("Failed to download PPD for year ", yr, ": HTTP ", status_code(res))
    }
    cat("  Downloaded:", round(file.size(fname) / 1e6, 1), "MB\n")
  } else {
    cat("PPD", yr, "already exists:", round(file.size(fname) / 1e6, 1), "MB\n")
  }

  dt <- fread(fname, header = FALSE,
              select = c(2, 3, 5, 6, 7, 13, 15),
              col.names = c("price", "date", "prop_type", "new_build",
                            "estate_type", "district", "txn_category"))
  dt[, date := as.Date(date)]
  dt[, year := year(date)]
  dt[, month := month(date)]
  dt[, ym := year * 100L + month]
  all_data[[as.character(yr)]] <- dt
  cat("  Parsed", nrow(dt), "transactions for", yr, "\n")
}

ppd <- rbindlist(all_data)
cat("\nTotal transactions loaded:", format(nrow(ppd), big.mark = ","), "\n")
cat("Date range:", as.character(min(ppd$date)), "to", as.character(max(ppd$date)), "\n")
cat("Unique districts:", uniqueN(ppd$district), "\n")

## Validate: no missing critical fields
stopifnot(sum(is.na(ppd$price)) == 0)
stopifnot(sum(is.na(ppd$date)) == 0)
stopifnot(sum(ppd$district == "") == 0)

## Save compressed
fwrite(ppd, file.path(out_dir, "ppd_2010_2019.csv.gz"))
cat("Saved ppd_2010_2019.csv.gz:", round(file.size(file.path(out_dir, "ppd_2010_2019.csv.gz")) / 1e6, 1), "MB\n")
