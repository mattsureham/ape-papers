## Test Azure connection
library(duckdb)
library(DBI)

## Load env
source("../../../../scripts/lib/azure_data.R")

con <- apep_azure_connect()

## Check what containers exist
cat("DuckDB version:", as.character(dbGetQuery(con, "SELECT version()")[[1]]), "\n")

## Try to list Azure parquet files at different paths
paths_to_try <- c(
  "apepdata/derived/qwi/rh/ns/",
  "apepdata/derived/qwi/",
  "apepdata/raw/",
  "apepdata/"
)

for (p in paths_to_try) {
  cat(sprintf("Path: az://%s\n", p))
  q <- sprintf("SELECT * FROM glob('az://%s*') LIMIT 3", p)
  r <- try(dbGetQuery(con, q), silent = TRUE)
  if (!inherits(r, "try-error")) {
    cat(sprintf("  Success! %d results\n", nrow(r)))
    if (nrow(r) > 0) print(r)
    break
  } else {
    msg <- conditionMessage(attr(r, "condition"))
    cat(sprintf("  Error: %s\n", substr(msg, 1, 120)))
  }
}

## Try the Azure MANIFEST to understand the path structure
cat("\nChecking Azure manifest...\n")
manifest_path <- "../../../../scripts/AZURE_MANIFEST.md"
if (file.exists(manifest_path)) {
  lines <- readLines(manifest_path, n = 50)
  cat(paste(lines, collapse = "\n"), "\n")
}

apep_azure_disconnect(con)
