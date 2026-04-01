# =============================================================================
# 01_fetch_data.R — Fetch MLP linked panel from Azure
# Paper: The Inertia Break (apep_1279)
# =============================================================================

source("00_packages.R")

cat("Connecting to Azure via DuckDB...\n")

# Load .env to get connection string
env_file <- "../../../../.env"
stopifnot("Cannot find .env" = file.exists(env_file))
env_lines <- readLines(env_file, warn = FALSE)
conn_str <- ""
for (line in env_lines) {
  line <- trimws(line)
  if (startsWith(line, "AZURE_STORAGE_CONNECTION_STRING=")) {
    conn_str <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    conn_str <- gsub('^["\']|["\']$', '', conn_str)
    break
  }
}
stopifnot("AZURE_STORAGE_CONNECTION_STRING not found in .env" = nchar(conn_str) > 0)

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure;")
dbExecute(con, "LOAD azure;")
dbExecute(con, sprintf("CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '%s');", conn_str))
cat("Connected.\n")

# -----------------------------------------------------------------------
# Query MLP 1910-1920 linked panel — men only, ages 8-30 in 1910
# Covers RD bandwidth around draft-eligibility cutoff at age 14
# -----------------------------------------------------------------------
cat("Querying MLP 1910-1920 panel (men, ages 8-30 in 1910)...\n")

query <- "
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
"

t0 <- Sys.time()
dt <- as.data.table(dbGetQuery(con, query))
t1 <- Sys.time()
cat(sprintf("Fetched %s rows in %.1f minutes\n", format(nrow(dt), big.mark = ","), difftime(t1, t0, units = "mins")))

# Validate: must have real data with adequate sample size
stopifnot("Data fetch returned 0 rows" = nrow(dt) > 0)
stopifnot("Fewer than 1M rows — unexpected for full-count linked census" = nrow(dt) > 1e6)

cat("\nAge distribution (1910):\n")
print(dt[, .N, by = age_1910][order(age_1910)])

cat("\nNativity distribution (1910) for draft-age men (14-23):\n")
print(dt[age_1910 %between% c(14, 23), .N, by = nativity_1910][order(nativity_1910)])

cat("\nFarm status (1910):\n")
print(dt[, .(n = .N, pct_farm = round(mean(farm_1910 == 2, na.rm = TRUE) * 100, 1)), by = age_1910][order(age_1910)])

# Save locally
fwrite(dt, "../data/mlp_men_1910_1920.csv")
cat(sprintf("\nSaved to data/mlp_men_1910_1920.csv (%s rows)\n", format(nrow(dt), big.mark = ",")))

dbDisconnect(con)
cat("Done.\n")
