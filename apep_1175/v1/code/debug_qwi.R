env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (nchar(line) == 0 || startsWith(line, "#")) next
  eq_pos <- regexpr("=", line, fixed = TRUE)
  if (eq_pos > 0) {
    key <- substr(line, 1, eq_pos - 1)
    val <- substr(line, eq_pos + 1, nchar(line))
    val <- gsub('^["\'](.*)["\']$', "\\1", val)
    do.call(Sys.setenv, setNames(list(val), key))
  }
}
library(duckdb); library(DBI)
source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()

# Try different paths
paths_to_try <- c(
  "derived/qwi/sa/ns/al.parquet",
  "derived/qwi/sa/ns/AL.parquet",
  "derived/qwi/sa/ns/01.parquet",
  "derived/qwi/sa_ns_01.parquet"
)

for (p in paths_to_try) {
  cat(sprintf("Trying: az://%s ... ", p))
  res <- tryCatch({
    r <- DBI::dbGetQuery(con, sprintf("SELECT COUNT(*) as n FROM 'az://%s'", p))
    cat(sprintf("OK: %d rows\n", r$n))
  }, error = function(e) {
    cat(sprintf("FAIL\n"))
  })
}

# Try listing blobs under derived/qwi
cat("\nListing derived/qwi/ blobs:\n")
tryCatch({
  files <- DBI::dbGetQuery(con, "SELECT file FROM glob('az://derived/qwi/*/*/*.parquet') LIMIT 5")
  print(files)
}, error = function(e) {
  cat("Glob failed:", e$message, "\n")
})

# Try with just a wildcard
tryCatch({
  files <- DBI::dbGetQuery(con, "SELECT file FROM glob('az://derived/qwi/*') LIMIT 10")
  print(files)
}, error = function(e) {
  cat("Top-level glob failed:", e$message, "\n")
})

# Try reading the county aggregate ARCOS to verify Azure still works
cat("\nVerifying Azure with ARCOS aggregate:\n")
tryCatch({
  r <- DBI::dbGetQuery(con, "SELECT COUNT(*) as n FROM 'az://raw/arcos/arcos_county_annual.parquet'")
  cat(sprintf("ARCOS aggregate: %d rows\n", r$n))
}, error = function(e) {
  cat("ARCOS failed:", e$message, "\n")
})
