# ============================================================================
# apep_1201: When the Anchor Drops
# 00_packages.R - Load packages and set global options
# ============================================================================

suppressPackageStartupMessages({
  library(data.table)
  library(arrow)
  library(DBI)
  library(duckdb)
  library(httr2)
  library(jsonlite)
  library(lubridate)
  library(stringr)
  library(sf)
  library(fixest)
  library(did)
  library(janitor)
})

options(
  scipen = 999,
  datatable.print.nrows = 200,
  datatable.print.topn = 20
)

Sys.setenv(TZ = "UTC")
sf::sf_use_s2(FALSE)

dir.create("data", showWarnings = FALSE)
dir.create("data/raw", showWarnings = FALSE, recursive = TRUE)
dir.create("data/derived", showWarnings = FALSE, recursive = TRUE)
dir.create("tables", showWarnings = FALSE, recursive = TRUE)
dir.create("logs", showWarnings = FALSE, recursive = TRUE)

chain_windows <- data.table(
  chain = c("A_AND_P", "TOPS", "WINN_DIXIE", "BI_LO", "HARVEYS"),
  shock_year = c(2015L, 2018L, 2018L, 2018L, 2018L)
)

valid_store_types <- c(
  "Supermarket",
  "Super Store",
  "Large Grocery Store",
  "Medium Grocery Store",
  "Combination Grocery/Other"
)

safe_write_parquet <- function(dt, path) {
  arrow::write_parquet(as.data.frame(dt), path)
}

safe_read_parquet <- function(path) {
  as.data.table(arrow::read_parquet(path))
}

pad_county <- function(x) {
  sprintf("%03d", as.integer(x))
}

write_lines_utf8 <- function(lines, path) {
  writeLines(enc2utf8(lines), path, useBytes = TRUE)
}

insert_table_label <- function(path, label) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  cap_idx <- grep("\\\\caption\\{", lines)[1]
  if (length(cap_idx) == 1L && !any(grepl(sprintf("\\\\label\\{%s\\}", label), lines, fixed = FALSE))) {
    lines <- append(lines, sprintf("   \\label{%s}", label), after = cap_idx)
    writeLines(lines, path, useBytes = TRUE)
  }
}

cat("Packages loaded for apep_1201.\n")
