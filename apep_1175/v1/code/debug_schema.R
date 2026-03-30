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
library(duckdb)
library(DBI)
source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()

# Check schema
row1 <- DBI::dbGetQuery(con, "SELECT * FROM 'az://raw/arcos/arcos_transactions.parquet' LIMIT 1")
cat("Columns:\n")
for (col in names(row1)) {
  cat(sprintf("  %s: %s = %s\n", col, class(row1[[col]]), as.character(row1[[col]][1])))
}
