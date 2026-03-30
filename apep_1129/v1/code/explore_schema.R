# Quick schema exploration of ARCOS data
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (nchar(line) == 0 || startsWith(line, "#")) next
  line <- sub("^export\\s+", "", line)
  eq_pos <- regexpr("=", line, fixed = TRUE)
  if (eq_pos > 0) {
    key <- substr(line, 1, eq_pos - 1)
    val <- substr(line, eq_pos + 1, nchar(line))
    val <- gsub('^["\'](.*)["\']+$', "\\1", val)
    do.call(Sys.setenv, setNames(list(val), key))
  }
}

library(duckdb)
library(DBI)
source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()

# Check schema
schema <- DBI::dbGetQuery(con, "DESCRIBE SELECT * FROM 'az://raw/arcos/arcos_transactions.parquet' LIMIT 1")
print(schema)

# Check a sample row
sample_row <- DBI::dbGetQuery(con, "SELECT * FROM 'az://raw/arcos/arcos_transactions.parquet' LIMIT 3")
print(names(sample_row))
for (col in names(sample_row)) {
  cat(col, ":", class(sample_row[[col]]), "->", head(sample_row[[col]], 1), "\n")
}

DBI::dbDisconnect(con, shutdown = TRUE)
