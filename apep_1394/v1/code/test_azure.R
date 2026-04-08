library(duckdb)
con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con, "INSTALL azure;")
DBI::dbExecute(con, "LOAD azure;")

lines <- readLines("../../../../.env", warn = FALSE)
conn_str <- ""
for (l in lines) {
  l <- trimws(l)
  if (startsWith(l, "AZURE_STORAGE_CONNECTION_STRING=")) {
    conn_str <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", l)
    conn_str <- gsub("^[\"']|[\"']$", "", conn_str)
    break
  }
}
sql <- paste0("CREATE SECRET apep (TYPE azure, CONNECTION_STRING '", conn_str, "');")
DBI::dbExecute(con, sql)

test_path <- function(path) {
  tryCatch({
    r <- DBI::dbGetQuery(con, paste0("SELECT COUNT(*) as n FROM '", path, "' LIMIT 1"))
    cat(path, "-> OK, n =", r$n, "\n")
  }, error = function(e) {
    cat(path, "-> ERROR:", conditionMessage(e), "\n")
  })
}

test_path("az://derived/qwi/sa/ns/*.parquet")
test_path("az://raw/qwi/sa/ns/*.parquet")
test_path("az://raw/arcos/arcos_county_annual.parquet")

# List what's in the derived container
tryCatch({
  r <- DBI::dbGetQuery(con, "SELECT DISTINCT industry, geo_level, COUNT(*) as n FROM 'az://derived/qwi/sa/ns/*.parquet' GROUP BY industry, geo_level LIMIT 10")
  print(r)
}, error = function(e) cat("List error:", conditionMessage(e), "\n"))

DBI::dbDisconnect(con, shutdown = TRUE)
