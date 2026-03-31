# Quick schema check
library(DBI)
library(duckdb)

env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (startsWith(line, "AZURE_STORAGE_CONNECTION_STRING=")) {
    val <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    val <- gsub('^["\'](.*)["\']+$', "\\1", val)
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    break
  }
}

source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()

schema <- dbGetQuery(con, "SELECT column_name, column_type FROM (DESCRIBE SELECT * FROM 'az://derived/qwi/rh/ns/ca.parquet')")
print(schema)

sample <- dbGetQuery(con, "SELECT * FROM 'az://derived/qwi/rh/ns/ca.parquet' LIMIT 3")
print(names(sample))
print(head(sample))

apep_azure_disconnect(con)
