# ==============================================================================
# 01_fetch_data.R — Fetch MLP 1920-1930-1940 panel from Azure
# Paper: Flood, Flight, and Fortune (apep_1287)
# ==============================================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

# Override: manually load the full connection string from .env
# (The default loader truncates at the first semicolon in some configs)
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (nchar(line) == 0 || startsWith(line, "#")) next
  line <- sub("^export ", "", line)
  eq_pos <- regexpr("=", line, fixed = TRUE)
  if (eq_pos > 0) {
    key <- substr(line, 1, eq_pos - 1)
    val <- substr(line, eq_pos + 1, nchar(line))
    val <- gsub('^["\'](.*)["\'"]$', "\\1", val)
    if (key == "AZURE_STORAGE_CONNECTION_STRING") {
      Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    }
  }
}

con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure;")
dbExecute(con, "LOAD azure;")
conn_str <- Sys.getenv("AZURE_STORAGE_CONNECTION_STRING")
dbExecute(con, sprintf("CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '%s');", conn_str))
cat("Connected to Azure.\n")

# --------------------------------------------------------------------------
# Query MLP panel for Mississippi (28), Arkansas (5), Louisiana (22)
# All individuals (need both Black and White for falsification test)
# Filter to farm workers in 1920 (farm_1920 == 1)
# --------------------------------------------------------------------------
cat("Querying MLP 1920-1930-1940 panel from Azure...\n")

query <- "
SELECT
  histid_1920,
  statefip_1920,
  countyicp_1920,
  age_1920,
  sex_1920,
  race_1920,
  farm_1920,
  occscore_1920,
  sei_1920,
  occscore_1930,
  sei_1930,
  farm_1930,
  statefip_1930,
  countyicp_1930,
  mover_20_30,
  occscore_1940,
  sei_1940,
  farm_1940,
  statefip_1940,
  countyicp_1940,
  mover_30_40
FROM 'az://derived/mlp_panel/linked_1920_1930_1940.parquet'
WHERE statefip_1920 IN (5, 22, 28)
  AND farm_1920 = 1
  AND age_1920 BETWEEN 15 AND 60
"

df <- DBI::dbGetQuery(con, query)

cat(sprintf("Fetched %d farm workers from MS/AR/LA.\n", nrow(df)))
cat(sprintf("  Black farm workers: %d\n", sum(df$race_1920 == 2)))
cat(sprintf("  White farm workers: %d\n", sum(df$race_1920 == 1)))
cat(sprintf("  Counties: %d\n", length(unique(paste(df$statefip_1920, df$countyicp_1920)))))

# Validate: no empty result
stopifnot("No data returned from Azure query" = nrow(df) > 0)
stopifnot("No Black farm workers found" = sum(df$race_1920 == 2) > 1000)

# Save locally
arrow::write_parquet(df, "../data/mlp_delta_farm_workers.parquet")
cat("Saved to data/mlp_delta_farm_workers.parquet\n")

# --------------------------------------------------------------------------
# Summary statistics for validation
# --------------------------------------------------------------------------
cat("\n=== Data Validation ===\n")
cat(sprintf("Total farm workers: %d\n", nrow(df)))
cat(sprintf("Black farm workers: %d (%.1f%%)\n",
            sum(df$race_1920 == 2),
            100 * mean(df$race_1920 == 2)))
cat(sprintf("Mover rate (Black): %.1f%%\n",
            100 * mean(df$mover_20_30[df$race_1920 == 2])))
cat(sprintf("Mover rate (White): %.1f%%\n",
            100 * mean(df$mover_20_30[df$race_1920 == 1])))
cat(sprintf("Mean occscore_1920 (Black): %.2f\n",
            mean(df$occscore_1920[df$race_1920 == 2], na.rm = TRUE)))
cat(sprintf("Mean occscore_1930 (Black): %.2f\n",
            mean(df$occscore_1930[df$race_1920 == 2], na.rm = TRUE)))
cat(sprintf("Counties per state:\n"))
print(table(df$statefip_1920))

dbDisconnect(con, shutdown = TRUE)
cat("Done.\n")
