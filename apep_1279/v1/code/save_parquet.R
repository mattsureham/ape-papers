# Save MLP data to local parquet for efficient access
library(duckdb)
library(DBI)

env_file <- "../../../../.env"
env_lines <- readLines(env_file, warn = FALSE)
conn_str <- ""
for (line in env_lines) {
  line <- trimws(line)
  if (startsWith(line, "AZURE_STORAGE_CONNECTION_STRING=")) {
    conn_str <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    conn_str <- gsub("^[\"']|[\"']$", "", conn_str)
    break
  }
}

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure; LOAD azure;")
dbExecute(con, sprintf("CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '%s');", conn_str))

dbExecute(con, "
COPY (
  SELECT
    histid_1910, histid_1920,
    statefip_1910, countyicp_1910, age_1910, sex_1910,
    race_1910, bpl_1910, nativity_1910, marst_1910,
    occ1950_1910, ind1950_1910, farm_1910, classwkr_1910,
    occscore_1910, lit_1910, ownershp_1910,
    statefip_1920, countyicp_1920, age_1920,
    race_1920, nativity_1920, marst_1920,
    occ1950_1920, ind1950_1920, farm_1920, classwkr_1920,
    occscore_1920, lit_1920, ownershp_1920,
    mover
  FROM 'az://derived/mlp_panel/linked_1910_1920.parquet'
  WHERE sex_1910 = 1
    AND age_1910 BETWEEN 8 AND 30
) TO '../data/mlp_men_1910_1920.parquet' (FORMAT PARQUET);
")

n <- dbGetQuery(con, "SELECT COUNT(*) as n FROM '../data/mlp_men_1910_1920.parquet'")
cat(sprintf("Saved %s rows to parquet\n", format(n$n, big.mark = ",")))
dbDisconnect(con)
