# =============================================================================
# 01_fetch_data.R — Fetch MLP triple-linked panel from Azure
# Paper: AAA Cotton Displacement and Black Occupational Scarring
# =============================================================================

source("00_packages.R")

# --- Fix Azure connection string (semicolons in .env cause parsing issues) ---
env_path <- "../../../../.env"
lines <- readLines(env_path, warn = FALSE)
conn_str <- ""
for (line in lines) {
  line <- trimws(line)
  if (startsWith(line, "AZURE_STORAGE_CONNECTION_STRING=")) {
    conn_str <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    conn_str <- gsub('^["\'](.*)["\']+$', "\\1", conn_str)
    break
  }
}
stopifnot("Azure connection string not found" = nchar(conn_str) > 50)
cat("Azure connection string loaded (", nchar(conn_str), " chars)\n")

# --- Connect to Azure via DuckDB ---
con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con, "INSTALL azure;")
DBI::dbExecute(con, "LOAD azure;")
DBI::dbExecute(con, sprintf("CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '%s');", conn_str))
cat("Connected to Azure.\n")

# --- 1. Explore schema ---
cat("Checking MLP panel schema...\n")
schema <- DBI::dbGetQuery(con, "
  SELECT column_name, column_type
  FROM (DESCRIBE SELECT * FROM 'az://derived/mlp_panel/linked_1930_1940_1950.parquet')
")
cat("Available columns (", nrow(schema), " total):\n")
print(schema$column_name)

# --- 2. Define cotton-belt states (11 states, 1930 FIPS) ---
cotton_states <- c(1, 5, 12, 13, 22, 28, 37, 40, 45, 47, 48)
cotton_fips_str <- paste(cotton_states, collapse = ", ")

# --- 3. Pull individual-level data for cotton-belt states ---
cat("Fetching individuals from cotton-belt states...\n")
cat("This may take a few minutes for ~6 GB of data...\n")

panel <- DBI::dbGetQuery(con, sprintf("
  SELECT
    histid_1930, statefip_1930, countyicp_1930,
    race_1930, farm_1930, sex_1930, age_1930,
    occscore_1930, occscore_1940, occscore_1950,
    occ1950_1930, occ1950_1940, occ1950_1950,
    sei_1930, sei_1940,
    statefip_1940, statefip_1950,
    marst_1930, nativity_1930, bpl_1930,
    school_1930, mover_40_50, mover_30_40,
    classwkr_1930, incwage_1940
  FROM 'az://derived/mlp_panel/linked_1930_1940_1950.parquet'
  WHERE statefip_1930 IN (%s)
    AND sex_1930 = 1
", cotton_fips_str))

cat("Fetched: ", nrow(panel), " rows, ", ncol(panel), " columns\n")

# --- 4. mover_40_50 already in the data (from MLP panel) ---
cat("Migration indicator present: mover_40_50\n")
cat("  Migrated (1940-1950): ", sum(panel$mover_40_50, na.rm = TRUE), " of ", nrow(panel), "\n")

# --- 5. Compute county-level treatment intensity ---
cat("Computing county-level treatment intensity...\n")

county_treat <- DBI::dbGetQuery(con, sprintf("
  SELECT
    statefip_1930,
    countyicp_1930,
    COUNT(*) as n_total,
    SUM(CASE WHEN farm_1930 = 2 THEN 1 ELSE 0 END) as n_farm,
    AVG(CASE WHEN farm_1930 = 2 THEN 1.0 ELSE 0.0 END) as farm_share,
    AVG(CASE WHEN race_1930 = 2 THEN 1.0 ELSE 0.0 END) as black_share
  FROM 'az://derived/mlp_panel/linked_1930_1940_1950.parquet'
  WHERE statefip_1930 IN (%s)
    AND sex_1930 = 1
  GROUP BY statefip_1930, countyicp_1930
  HAVING COUNT(*) >= 50
", cotton_fips_str))

cat("County-level treatment data: ", nrow(county_treat), " counties\n")
cat("Farm share distribution:\n")
print(summary(county_treat$farm_share))

# --- 6. Disconnect ---
DBI::dbDisconnect(con, shutdown = TRUE)
cat("Disconnected from Azure.\n")

# --- 7. Save raw data ---
saveRDS(panel, "../data/panel_raw.rds")
saveRDS(county_treat, "../data/county_treatment.rds")

cat("\nData fetch complete.\n")
cat("  Individuals: ", nrow(panel), "\n")
cat("  Counties:    ", nrow(county_treat), "\n")
cat("  States:      ", length(unique(panel$statefip_1930)), "\n")
