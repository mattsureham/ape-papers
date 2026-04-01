# Check MLP panel schema
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (nchar(line) == 0 || startsWith(line, "#")) next
  line <- sub("^export\\s+", "", line)
  eq_pos <- regexpr("=", line, fixed = TRUE)
  if (eq_pos > 0) {
    key <- substr(line, 1, eq_pos - 1)
    val <- substr(line, eq_pos + 1, nchar(line))
    val <- gsub('^["\'](.*)["\'"]$', "\\1", val)
    if (key == "AZURE_STORAGE_CONNECTION_STRING") {
      Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    }
  }
}

library(duckdb)
con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con, "INSTALL azure;")
DBI::dbExecute(con, "LOAD azure;")
DBI::dbExecute(con, sprintf("CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '%s');",
  Sys.getenv("AZURE_STORAGE_CONNECTION_STRING")))

# Get column names and types
cat("=== linked_1910_1920.parquet schema ===\n")
schema <- DBI::dbGetQuery(con, "DESCRIBE SELECT * FROM 'az://derived/mlp_panel/linked_1910_1920.parquet' LIMIT 0")
print(schema)

cat("\n=== linked_1900_1910.parquet schema ===\n")
schema2 <- DBI::dbGetQuery(con, "DESCRIBE SELECT * FROM 'az://derived/mlp_panel/linked_1900_1910.parquet' LIMIT 0")
print(schema2)

# Sample a few rows
cat("\n=== Sample rows (1910-1920) ===\n")
sample <- DBI::dbGetQuery(con, "SELECT * FROM 'az://derived/mlp_panel/linked_1910_1920.parquet' LIMIT 3")
print(t(sample))

DBI::dbDisconnect(con, shutdown = TRUE)
