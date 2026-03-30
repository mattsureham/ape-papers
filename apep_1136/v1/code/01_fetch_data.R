## 01_fetch_data.R — apep_1136: Fetch BoE consumer credit data
## Data: Bank of England Statistical Interactive Database

source("00_packages.R")

data_dir <- "../data"
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)

## ============================================================
## 1. Bank of England monthly series via IADB CSV API
## ============================================================

fetch_boe_series <- function(series_code, description) {
  cat(sprintf("Fetching BoE series %s (%s)...\n", series_code, description))

  url <- sprintf(
    "https://www.bankofengland.co.uk/boeapps/database/_iadb-fromshowcolumns.asp?csv.x=yes&Datefrom=01/Jan/2005&Dateto=31/Dec/2025&SeriesCodes=%s&CSVF=TN&UsingCodes=Y&VPD=Y&VFD=N",
    series_code
  )

  resp <- httr::GET(url, httr::timeout(60))
  if (httr::status_code(resp) != 200) {
    stop(sprintf("HTTP %d for series %s", httr::status_code(resp), series_code))
  }

  raw_text <- httr::content(resp, as = "text", encoding = "UTF-8")

  ## Check for HTML error page
  if (grepl("<!DOCTYPE", raw_text, fixed = TRUE)) {
    stop(sprintf("Series %s returned HTML error page", series_code))
  }

  df <- read.csv(text = raw_text, stringsAsFactors = FALSE, check.names = FALSE)
  if (nrow(df) == 0) stop(sprintf("No data for series %s", series_code))

  names(df) <- c("date_str", "value")
  df$date <- as.Date(df$date_str, format = "%d %b %Y")
  df$value <- as.numeric(gsub("[^0-9.\\-]", "", df$value))
  df$series <- series_code
  df$description <- description
  df <- df[!is.na(df$date) & !is.na(df$value), ]

  cat(sprintf("  -> %d obs, %s to %s, range: %.0f to %.0f\n",
              nrow(df), min(df$date), max(df$date), min(df$value), max(df$value)))
  return(df[, c("date", "value", "series", "description")])
}

## Key BoE series (LPM prefix for current database)
series_list <- list(
  ## Amounts outstanding (£m, monthly, seasonally adjusted)
  list(code = "LPMVZRJ", desc = "Credit card amounts outstanding"),
  list(code = "LPMVZRI", desc = "Other consumer credit outstanding"),
  list(code = "LPMAUYN", desc = "Total consumer credit outstanding"),
  ## Net lending flows (£m, monthly, seasonally adjusted)
  list(code = "LPMVZQX", desc = "Credit card net lending"),
  list(code = "LPMVZQW", desc = "Other consumer credit net lending"),
  ## Gross lending (£m, monthly)
  list(code = "LPMVZQO", desc = "Credit card gross lending"),
  ## Write-offs (£m, quarterly)
  list(code = "RPQTFHE", desc = "Credit card write-offs"),
  list(code = "LPMB3QE", desc = "Credit card write-offs monthly"),
  list(code = "LPMB3QG", desc = "Other consumer credit write-offs monthly"),
  ## Effective interest rates (%, monthly)
  list(code = "IUMCCTL", desc = "Credit card effective interest rate"),
  list(code = "IUMTLMV", desc = "Personal loan effective interest rate"),
  ## Number of accounts / cards (check if available)
  list(code = "LPMB3SB", desc = "Credit card new business volumes"),
  list(code = "LPMB3SE", desc = "Dealership finance outstanding"),
  list(code = "LPMB3SF", desc = "Student loans outstanding"),
  list(code = "LPMB3SG", desc = "Credit card repayments")
)

all_boe <- list()
for (s in series_list) {
  tryCatch({
    df <- fetch_boe_series(s$code, s$desc)
    all_boe[[s$code]] <- df
  }, error = function(e) {
    warning(sprintf("Failed to fetch %s: %s", s$code, e$message))
  })
}

boe_data <- do.call(rbind, all_boe)
rownames(boe_data) <- NULL

cat(sprintf("\nTotal: %d observations across %d series\n",
            nrow(boe_data), length(unique(boe_data$series))))
cat("Series found:", paste(unique(boe_data$series), collapse = ", "), "\n")

## ============================================================
## 2. Validation — critical series must exist
## ============================================================
stopifnot("LPMVZRJ" %in% boe_data$series)  # Credit card outstanding — MUST HAVE
stopifnot("LPMVZRI" %in% boe_data$series)  # Other consumer credit — MUST HAVE
stopifnot(sum(boe_data$series == "LPMVZRJ") >= 100)  # At least 100 months

## Quick summary for key series
cat("\n=== KEY SERIES SUMMARY ===\n")
for (s in c("LPMVZRJ", "LPMVZRI", "LPMVZQX", "IUMCCTL", "IUMTLMV")) {
  sub <- boe_data[boe_data$series == s, ]
  if (nrow(sub) > 0) {
    ## Value around treatment date
    val_2018_09 <- sub$value[which.min(abs(sub$date - as.Date("2018-09-01")))]
    val_2020_03 <- sub$value[which.min(abs(sub$date - as.Date("2020-03-01")))]
    cat(sprintf("%s: n=%d, Sep2018=%.0f, Mar2020=%.0f\n",
                s, nrow(sub), val_2018_09, val_2020_03))
  }
}

## Save
saveRDS(boe_data, file.path(data_dir, "boe_consumer_credit.rds"))
cat("\nSaved: boe_consumer_credit.rds\n")
cat("Data fetch complete.\n")
