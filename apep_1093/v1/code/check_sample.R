source("00_packages.R")

env_path <- normalizePath(file.path("..", "..", "..", "..", ".env"), mustWork = FALSE)
for (line in readLines(env_path, warn = FALSE)) {
  line <- trimws(line)
  if (startsWith(line, "AZURE_STORAGE_CONNECTION_STRING=")) {
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line))
    break
  }
}
source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()

# Use wildcard - check what data looks like
df <- DBI::dbGetQuery(con, "
  SELECT geography, year, quarter, industry, race, ethnicity,
         EarnHirAS, HirA, Sep, Emp, filename
  FROM 'az://derived/qwi/rh/n3/*.parquet'
  WHERE race IN ('A1', 'A2')
    AND year = 2022 AND quarter = 1
    AND industry IN ('541', '722')
  LIMIT 20
")

cat("Sample data:\n")
print(df)
cat(sprintf("\nRows: %d\n", nrow(df)))
cat("\nUnique filenames:\n")
print(unique(df$filename))

apep_azure_disconnect(con)
