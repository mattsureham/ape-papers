source("00_packages.R")

env_path <- normalizePath(file.path("..", "..", "..", "..", ".env"), mustWork = FALSE)
env_lines <- readLines(env_path, warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (startsWith(line, "AZURE_STORAGE_CONNECTION_STRING=")) {
    val <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    break
  }
}

source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()

# Try different naming conventions
for (name in c("08", "CO", "co", "Colorado")) {
  path <- sprintf("az://derived/qwi/rh/n3/%s.parquet", name)
  tryCatch({
    schema <- DBI::dbGetQuery(con, sprintf("DESCRIBE SELECT * FROM '%s' LIMIT 1", path))
    cat(sprintf("SUCCESS with: %s\n\nSchema:\n", path))
    print(schema)

    race_vals <- DBI::dbGetQuery(con, sprintf("SELECT DISTINCT race FROM '%s'", path))
    cat("\nRace values:\n")
    print(race_vals)
    break
  }, error = function(e) {
    cat(sprintf("FAILED: %s -> %s\n", path, e$message))
  })
}

# Also try wildcard
tryCatch({
  test <- DBI::dbGetQuery(con, "SELECT DISTINCT race FROM 'az://derived/qwi/rh/n3/*.parquet' LIMIT 20")
  cat("\nWildcard race values:\n")
  print(test)
}, error = function(e) {
  cat(sprintf("Wildcard failed: %s\n", e$message))
})

apep_azure_disconnect(con)
