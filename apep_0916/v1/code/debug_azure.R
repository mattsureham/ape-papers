# Debug Azure connection
library(duckdb)
library(DBI)

# Load env manually
lines <- readLines("../../../../.env", warn = FALSE)
for (line in lines) {
  line <- trimws(line)
  if (nchar(line) == 0 || startsWith(line, "#")) next
  line <- sub("^export ", "", line)
  eq_pos <- regexpr("=", line, fixed = TRUE)
  if (eq_pos > 0) {
    key <- substr(line, 1, eq_pos - 1)
    val <- substr(line, eq_pos + 1, nchar(line))
    val <- gsub('^["\'](.*)["\'"]$', "\\1", val)
    if (key == "AZURE_STORAGE_CONNECTION_STRING") {
      cat("Key:", key, "\n")
      cat("Value length:", nchar(val), "\n")
      cat("First 80 chars:", substr(val, 1, 80), "\n")
      Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    }
  }
}

conn_str <- Sys.getenv("AZURE_STORAGE_CONNECTION_STRING")
cat("Env var length:", nchar(conn_str), "\n")

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure;")
dbExecute(con, "LOAD azure;")

query <- sprintf("CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '%s');", conn_str)
dbExecute(con, query)

# Test: read schema
tryCatch({
  result <- dbGetQuery(con, "
    SELECT column_name, column_type
    FROM (DESCRIBE SELECT * FROM 'az://derived/mlp_panel/linked_1920_1930_1940.parquet')
  ")
  print(result)
}, error = function(e) {
  cat("Error:", e$message, "\n")
})

dbDisconnect(con, shutdown = TRUE)
