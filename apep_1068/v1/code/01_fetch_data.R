# =============================================================================
# 01_fetch_data.R — Fetch MLP linked census panel from Azure
# apep_1068: Last Hired, Not First Fired
# =============================================================================

source("00_packages.R")

# Fix Azure connection string (shell truncates at semicolons)
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  if (startsWith(trimws(line), "AZURE_STORAGE_CONNECTION_STRING=")) {
    val <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", trimws(line))
    Sys.setenv(AZURE_STORAGE_CONNECTION_STRING = val)
    break
  }
}

con <- apep_azure_connect()

# --- Fetch Black and White individuals from Southern states (1920 residence) ---
# Southern states: AL(1), AR(5), FL(12), GA(13), KY(21), LA(22), MS(28),
#   NC(37), OK(40), SC(45), TN(47), TX(48), VA(51)
southern_fips <- c(1, 5, 12, 13, 21, 22, 28, 37, 40, 45, 47, 48, 51)

cat("Fetching three-decade linked panel from Azure...\n")

df_raw <- DBI::dbGetQuery(con, sprintf("
  SELECT
    histid_1920 as histid,
    statefip_1920, statefip_1930, statefip_1940,
    countyicp_1920, countyicp_1930, countyicp_1940,
    age_1920, age_1930, age_1940,
    sex_1920,
    race_1920,
    occscore_1920, occscore_1930, occscore_1940,
    sei_1920, sei_1930, sei_1940,
    occ1950_1920, occ1950_1930, occ1950_1940,
    ind1950_1920, ind1950_1930, ind1950_1940,
    farm_1920, farm_1930, farm_1940,
    school_1920,
    marst_1920,
    classwkr_1920, classwkr_1930, classwkr_1940,
    bpl_1920
  FROM 'az://derived/mlp_panel/linked_1920_1930_1940.parquet'
  WHERE statefip_1920 IN (%s)
    AND sex_1920 = 1
    AND age_1920 BETWEEN 15 AND 55
", paste(southern_fips, collapse = ",")))

cat(sprintf("Fetched %s rows from Azure.\n", format(nrow(df_raw), big.mark = ",")))

# Validate: data must not be empty
stopifnot("No data returned from Azure" = nrow(df_raw) > 0)
stopifnot("Missing histid" = !any(is.na(df_raw$histid)))

# --- Define migration status ---
dt <- as.data.table(df_raw)
rm(df_raw); gc()

# Migrant = resided in South in 1920, resided in North/West by 1930
dt[, migrant := as.integer(
  statefip_1920 %in% southern_fips &
  !(statefip_1930 %in% southern_fips)
)]

# Race categories (IPUMS race codes: 1=White, 2=Black)
dt[, black := as.integer(race_1920 == 2)]

# Return migrant flag: went North by 1930, returned South by 1940
dt[, return_migrant := as.integer(
  migrant == 1 & statefip_1940 %in% southern_fips
)]

# --- Sample counts ---
cat("\n=== Sample Composition ===\n")
cat(sprintf("Total Southern-born males (15-55 in 1920): %s\n",
            format(nrow(dt), big.mark = ",")))
cat(sprintf("  Black: %s\n", format(sum(dt$black == 1), big.mark = ",")))
cat(sprintf("  White: %s\n", format(sum(dt$black == 0), big.mark = ",")))
cat(sprintf("  Black migrants (S->N): %s\n",
            format(sum(dt$black == 1 & dt$migrant == 1), big.mark = ",")))
cat(sprintf("  Black stayers: %s\n",
            format(sum(dt$black == 1 & dt$migrant == 0), big.mark = ",")))
cat(sprintf("  White migrants (S->N): %s\n",
            format(sum(dt$black == 0 & dt$migrant == 1), big.mark = ",")))
cat(sprintf("  Return migrants (Black): %s\n",
            format(sum(dt$black == 1 & dt$return_migrant == 1), big.mark = ",")))

# Save intermediate data
fwrite(dt, "../data/mlp_panel_south_origin.csv")
cat(sprintf("\nSaved panel to data/mlp_panel_south_origin.csv (%s rows)\n",
            format(nrow(dt), big.mark = ",")))

apep_azure_disconnect(con)
cat("Data fetch complete.\n")
