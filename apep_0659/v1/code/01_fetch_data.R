# ==============================================================================
# 01_fetch_data.R — Fetch MLP three-decade panel from Azure
# The Enclave as Insurance and Trap
# ==============================================================================

source("00_packages.R")

# Force-read connection string from .env (shell truncates at semicolons)
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

# --------------------------------------------------------------------------
# 1. Fetch three-decade linked panel (1920-1930-1940)
#    European-born males aged 25-45 in 1920
# --------------------------------------------------------------------------

cat("Fetching MLP 1920-1930-1940 panel from Azure...\n")

panel <- dbGetQuery(con, "
  SELECT
    histid_1920, histid_1930, histid_1940,
    age_1920, sex_1920, race_1920, bpl_1920, nativity_1920,
    statefip_1920, countyicp_1920,
    occ1950_1920, occscore_1920, sei_1920,
    farm_1920, ownershp_1920, classwkr_1920, school_1920,
    ind1950_1920,
    age_1930, bpl_1930, statefip_1930, countyicp_1930,
    occ1950_1930, occscore_1930, sei_1930,
    farm_1930, ownershp_1930, classwkr_1930,
    ind1950_1930,
    age_1940, bpl_1940, statefip_1940, countyicp_1940,
    occ1950_1940, occscore_1940, sei_1940,
    farm_1940, ownershp_1940, classwkr_1940,
    ind1950_1940,
    mover_20_30, mover_30_40
  FROM 'az://derived/mlp_panel/linked_1920_1930_1940.parquet'
  WHERE bpl_1920 BETWEEN 400 AND 499
    AND sex_1920 = 1
    AND age_1920 BETWEEN 25 AND 45
")

cat(sprintf("Fetched %s European-born males aged 25-45 in 1920.\n",
            format(nrow(panel), big.mark = ",")))

stopifnot("No data returned from Azure query" = nrow(panel) > 0)
stopifnot("Expected >500K observations" = nrow(panel) > 500000)

# --------------------------------------------------------------------------
# 2. Fetch county-level co-ethnic shares from 1920 full-count census
# --------------------------------------------------------------------------

cat("Computing county-level co-ethnic shares from 1920 full-count census...\n")

# Full-count census has uppercase column names
county_pops <- dbGetQuery(con, "
  SELECT
    STATEFIP AS statefip_1920,
    COUNTYICP AS countyicp_1920,
    BPL AS bpl_1920,
    COUNT(*) AS n_coethnic,
    SUM(CASE WHEN CLASSWKR IN (1, 2) THEN 1 ELSE 0 END) AS n_selfemployed,
    SUM(CASE WHEN LIT = 4 THEN 1 ELSE 0 END) AS n_literate
  FROM 'az://raw/ipums_fullcount/us1920c.parquet'
  WHERE BPL BETWEEN 400 AND 499
    AND SEX = 1
    AND AGE BETWEEN 18 AND 65
  GROUP BY STATEFIP, COUNTYICP, BPL
")

county_totals <- dbGetQuery(con, "
  SELECT
    STATEFIP AS statefip_1920,
    COUNTYICP AS countyicp_1920,
    COUNT(*) AS county_pop
  FROM 'az://raw/ipums_fullcount/us1920c.parquet'
  WHERE SEX = 1
    AND AGE BETWEEN 18 AND 65
  GROUP BY STATEFIP, COUNTYICP
")

cat(sprintf("County-nationality cells: %s\n", format(nrow(county_pops), big.mark = ",")))
cat(sprintf("Counties with population data: %s\n", format(nrow(county_totals), big.mark = ",")))

stopifnot("No county population data" = nrow(county_totals) > 0)

# --------------------------------------------------------------------------
# 3. Fetch 1920-1930 two-decade panel for boom-period placebo
# --------------------------------------------------------------------------

cat("Fetching 1920-1930 panel for boom-period validation...\n")

panel_boom <- dbGetQuery(con, "
  SELECT
    histid_1920,
    age_1920, sex_1920, race_1920, bpl_1920,
    statefip_1920, countyicp_1920,
    occ1950_1920, occscore_1920, sei_1920,
    farm_1920, ownershp_1920, classwkr_1920, school_1920,
    age_1930, bpl_1930, statefip_1930, countyicp_1930,
    occ1950_1930, occscore_1930, sei_1930,
    farm_1930, ownershp_1930, classwkr_1930
  FROM 'az://derived/mlp_panel/linked_1920_1930.parquet'
  WHERE bpl_1920 BETWEEN 400 AND 499
    AND sex_1920 = 1
    AND age_1920 BETWEEN 25 AND 45
")

cat(sprintf("Boom-period panel: %s observations.\n",
            format(nrow(panel_boom), big.mark = ",")))

apep_azure_disconnect(con)

# --------------------------------------------------------------------------
# 4. Save raw data
# --------------------------------------------------------------------------

saveRDS(panel, "../data/panel_3decade.rds")
saveRDS(panel_boom, "../data/panel_boom.rds")
saveRDS(county_pops, "../data/county_coethnic_1920.rds")
saveRDS(county_totals, "../data/county_totals_1920.rds")

cat("All data saved to data/ directory.\n")
cat(sprintf("Three-decade panel: %s obs\n", format(nrow(panel), big.mark = ",")))
cat(sprintf("Boom panel: %s obs\n", format(nrow(panel_boom), big.mark = ",")))
