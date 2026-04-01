# Test Azure connection with manual env loading
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
      cat("Set conn string, length:", nchar(val), "\n")
    }
  }
}

library(duckdb)
con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con, "INSTALL azure;")
DBI::dbExecute(con, "LOAD azure;")

conn_str <- Sys.getenv("AZURE_STORAGE_CONNECTION_STRING")
cat("Conn string length:", nchar(conn_str), "\n")
cat("First 50 chars:", substr(conn_str, 1, 50), "\n")

q <- sprintf("CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '%s');", conn_str)
DBI::dbExecute(con, q)

# Test query
tryCatch({
  res <- DBI::dbGetQuery(con, "SELECT COUNT(*) as n FROM 'az://derived/mlp_panel/linked_1910_1920.parquet'")
  cat("Success! Row count:", res$n, "\n")
}, error = function(e) cat("Error:", e$message, "\n"))

DBI::dbDisconnect(con, shutdown = TRUE)
