## Test Azure — debug the connection
library(duckdb)
library(DBI)

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure; LOAD azure; INSTALL httpfs; LOAD httpfs;")

## Check Azure extension details
exts <- dbGetQuery(con, "SELECT extension_name, extension_version, installed, loaded FROM duckdb_extensions() WHERE extension_name = 'azure'")
cat("Azure extension:\n")
print(exts)

## Load .env and get connection string
lines <- readLines("../../../../.env", warn = FALSE)
conn_str <- ""
for (line in lines) {
  line <- trimws(line)
  if (grepl("^AZURE_STORAGE_CONNECTION_STRING=", line)) {
    conn_str <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    break
  }
}
cat("Connection string length:", nchar(conn_str), "\n")

## Try creating secret the way apep_azure_connect does
sql <- sprintf("CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '%s');", conn_str)
cat("SQL length:", nchar(sql), "\n")
result <- try(dbExecute(con, sql), silent = FALSE)
cat("Secret creation result:", result, "\n")

## Now check what secrets exist
secrets <- try(dbGetQuery(con, "SELECT * FROM duckdb_secrets()"), silent = TRUE)
if (!inherits(secrets, "try-error")) {
  cat("Secrets:\n")
  print(secrets)
}

## Try direct Azure HTTP URL instead of az:// protocol
acct <- sub(".*AccountName=([^;]+).*", "\\1", conn_str)
cat("\nTrying HTTP URL format...\n")
http_url <- sprintf("https://%s.blob.core.windows.net/derived/qwi/rh/ns/CA.parquet", acct)
cat("URL:", http_url, "\n")
r <- try(dbGetQuery(con, sprintf("SELECT * FROM '%s' LIMIT 3", http_url)), silent = FALSE)
if (!inherits(r, "try-error")) {
  cat("HTTP URL works!\n")
  print(head(r, 2))
}

## Also try az:// with just the container name
cat("\nTrying az:// variations...\n")
for (path in c("az://derived/qwi/rh/ns/CA.parquet",
               "az://apepdata/derived/qwi/rh/ns/CA.parquet",
               "azure://derived/qwi/rh/ns/CA.parquet")) {
  cat(sprintf("  %s: ", path))
  r <- try(dbGetQuery(con, sprintf("SELECT COUNT(*) FROM '%s'", path)), silent = TRUE)
  if (!inherits(r, "try-error")) {
    cat(sprintf("OK (%s)\n", r[[1]]))
  } else {
    msg <- conditionMessage(attr(r, "condition"))
    cat(sprintf("FAIL: %s\n", substr(msg, 1, 80)))
  }
}

dbDisconnect(con, shutdown = TRUE)
