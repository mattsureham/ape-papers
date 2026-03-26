# =============================================================================
# 01_fetch_data.R — Fetch MLP 1910-1920 linked panel from Azure
# apep_1015: The First Wage Floor for Women
# =============================================================================

source("00_packages.R")

# Read Azure connection string directly from .env (shell truncates at semicolons)
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (startsWith(line, "AZURE_STORAGE_CONNECTION_STRING=")) {
    val <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    val <- gsub('^["\'](.*)["\']$', "\\1", val)
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    break
  }
}

source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()

# ---------------------------------------------------------------------------
# Define minimum wage states (enacted by 1920)
# FIPS codes for the 14 states that enacted women's MW laws 1912-1920
# ---------------------------------------------------------------------------
# Massachusetts=25, California=6, Oregon=41, Washington=53, Minnesota=27,
# Wisconsin=55, Utah=49, Nebraska=31, Colorado=8, Arkansas=5, Kansas=20,
# Arizona=4, North Dakota=38, Texas=48
mw_states <- c(4, 5, 6, 8, 20, 25, 27, 31, 38, 41, 48, 49, 53, 55)
mw_sql <- paste(mw_states, collapse = ", ")

# ---------------------------------------------------------------------------
# Key columns needed (avoid fetching histid strings to save memory)
# ---------------------------------------------------------------------------
key_cols <- paste(c(
  "statefip_1910", "countyicp_1910", "age_1910", "sex_1910", "race_1910",
  "nativity_1910", "marst_1910", "occ1950_1910", "ind1950_1910",
  "farm_1910", "classwkr_1910", "occscore_1910", "lit_1910", "perwt_1910",
  "nchild_1910",
  "statefip_1920", "age_1920", "sex_1920", "occ1950_1920", "ind1950_1920",
  "farm_1920", "classwkr_1920", "occscore_1920", "marst_1920", "perwt_1920",
  "mover"
), collapse = ", ")

# ---------------------------------------------------------------------------
# Fetch women
# ---------------------------------------------------------------------------
cat("=== Fetching women from MLP 1910-1920 ===\n")
women <- dbGetQuery(con, sprintf("
  SELECT %s
  FROM 'az://derived/mlp_panel/linked_1910_1920.parquet'
  WHERE sex_1910 = 2
", key_cols))
cat(sprintf("Women rows: %s\n", format(nrow(women), big.mark = ",")))

arrow::write_parquet(women, "../data/women_1910_1920.parquet")
cat("Saved women data.\n")
rm(women)
gc()

# ---------------------------------------------------------------------------
# Fetch men (for placebo — only those in LF in 1910 in relevant industries)
# ---------------------------------------------------------------------------
cat("\n=== Fetching men for placebo ===\n")
men <- dbGetQuery(con, sprintf("
  SELECT %s
  FROM 'az://derived/mlp_panel/linked_1910_1920.parquet'
  WHERE sex_1910 = 1
    AND occ1950_1910 > 0
    AND occ1950_1910 < 979
", key_cols))
cat(sprintf("Men in LF rows: %s\n", format(nrow(men), big.mark = ",")))

arrow::write_parquet(men, "../data/men_1910_1920.parquet")
cat("Saved men data.\n")

apep_azure_disconnect(con)
cat("\nDone.\n")
