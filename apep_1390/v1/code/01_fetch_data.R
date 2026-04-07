# ==============================================================================
# 01_fetch_data.R — Fetch MLP 1930-1940-1950 linked panel from Azure
# ==============================================================================

source("00_packages.R")

# Parse Azure connection string directly (the .env parser truncates at semicolons)
env_lines <- readLines("../../../../.env", warn = FALSE)
azure_line <- grep("^AZURE_STORAGE_CONNECTION_STRING", env_lines, value = TRUE)
eq_pos <- regexpr("=", azure_line, fixed = TRUE)
azure_cs <- substr(azure_line, eq_pos + 1, nchar(azure_line))
stopifnot("Azure connection string not found" = nchar(azure_cs) > 50)

con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con, "INSTALL azure;")
DBI::dbExecute(con, "LOAD azure;")
DBI::dbExecute(con, sprintf("CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '%s');", azure_cs))
cat("Connected to Azure.\n")

cat("Querying MLP 1930-1940-1950 panel from Azure...\n")

# Birth year = 1930 - age_1930
# Focus on birth cohorts 1900-1935 (age 0-30 in 1930, i.e., age <= 30)
df <- DBI::dbGetQuery(con, "
  SELECT
    histid_1930,
    (1930 - age_1930) as birthyr,
    sex_1930,
    race_1930,
    bpl_1930,
    farm_1930,
    statefip_1930,
    age_1930,
    educ_1940,
    incwage_1940,
    educ_1950,
    incwage_1950,
    occscore_1950,
    occ1950_1950,
    empstat_1950,
    statefip_1950,
    age_1950,
    mover_30_50,
    nchild_1950,
    marst_1950
  FROM 'az://derived/mlp_panel/linked_1930_1940_1950.parquet'
  WHERE age_1930 BETWEEN 0 AND 30
")

cat(sprintf("Fetched %s rows, %d columns\n", format(nrow(df), big.mark = ","), ncol(df)))

# Validate: data must exist and have real records
stopifnot("No data returned from Azure query" = nrow(df) > 0)
stopifnot("Missing birth year" = !all(is.na(df$birthyr)))
stopifnot("Missing birth place" = !all(is.na(df$bpl_1930)))

# Save locally
arrow::write_parquet(as.data.frame(df), "../data/mlp_panel_raw.parquet")
cat("Saved to data/mlp_panel_raw.parquet\n")

DBI::dbDisconnect(con)
cat("Done.\n")
