source("00_packages.R")

# Fix Azure connection string
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  if (startsWith(trimws(line), "AZURE_STORAGE_CONNECTION_STRING=")) {
    val <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", trimws(line))
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    break
  }
}
cat("Conn string length:", nchar(Sys.getenv("AZURE_STORAGE_CONNECTION_STRING")), "\n")

con <- apep_azure_connect()

# Check if derived panel exists
result <- tryCatch(
  DBI::dbGetQuery(con, "SELECT COUNT(*) as n FROM 'az://derived/mlp_panel/linked_1920_1930_1940.parquet'"),
  error = function(e) { cat("Derived panel error:", e$message, "\n"); NULL }
)
if (!is.null(result)) { cat("Derived panel rows:", result$n, "\n") }

# Check raw crosswalk
result2 <- tryCatch(
  DBI::dbGetQuery(con, "SELECT COUNT(*) as n FROM 'az://raw/ipums_mlp/v2/mlp_crosswalk_v2.parquet'"),
  error = function(e) { cat("MLP crosswalk error:", e$message, "\n"); NULL }
)
if (!is.null(result2)) { cat("MLP crosswalk rows:", result2$n, "\n") }

apep_azure_disconnect(con)
