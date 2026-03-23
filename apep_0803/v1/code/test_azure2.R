## Test Azure with account name/key directly
library(duckdb)
library(DBI)

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure; LOAD azure; INSTALL httpfs; LOAD httpfs;")

## Load .env
lines <- readLines("../../../../.env", warn = FALSE)
conn_str <- ""
for (line in lines) {
  line <- trimws(line)
  if (grepl("^AZURE_STORAGE_CONNECTION_STRING=", line)) {
    conn_str <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    break
  }
}

## Parse account name and key
acct <- sub(".*AccountName=([^;]+).*", "\\1", conn_str)
key_raw <- sub(".*AccountKey=([^;]+).*", "\\1", conn_str)
cat("Account:", acct, "\n")
cat("Key length:", nchar(key_raw), "\n")

## Create secret with explicit account name and key
q <- sprintf("CREATE SECRET azure_secret (TYPE azure, ACCOUNT_NAME '%s', ACCOUNT_KEY '%s')",
             acct, key_raw)
dbExecute(con, q)

## Try a simple read of a single state file
cat("Trying CA healthcare QWI...\n")
r <- try(dbGetQuery(con, "SELECT * FROM 'az://derived/qwi/rh/ns/CA.parquet' LIMIT 5"),
         silent = FALSE)
if (!inherits(r, "try-error")) {
  cat(sprintf("SUCCESS! %d rows, %d cols\n", nrow(r), ncol(r)))
  cat(sprintf("Columns: %s\n", paste(names(r), collapse = ", ")))
} else {
  cat("CA failed. Trying with container prefix...\n")
  r2 <- try(dbGetQuery(con, "SELECT * FROM 'az://apepdata/derived/qwi/rh/ns/CA.parquet' LIMIT 5"),
            silent = FALSE)
  if (!inherits(r2, "try-error")) {
    cat(sprintf("SUCCESS with container prefix! %d rows\n", nrow(r2)))
  }
}

dbDisconnect(con, shutdown = TRUE)
