# ==============================================================================
# 01_fetch_data.R — Fetch ARCOS from Azure, CDC WONDER, and ACS controls
# ==============================================================================

source("00_packages.R")

# Load .env directly (bash source truncates at semicolons)
env_lines <- readLines("../../../../.env", warn = FALSE)
for (line in env_lines) {
  line <- trimws(line)
  if (nchar(line) == 0 || startsWith(line, "#")) next
  line <- sub("^export\\s+", "", line)
  eq_pos <- regexpr("=", line, fixed = TRUE)
  if (eq_pos > 0) {
    key <- substr(line, 1, eq_pos - 1)
    val <- substr(line, eq_pos + 1, nchar(line))
    val <- gsub('^["\'](.*)["\']+$', "\\1", val)
    do.call(Sys.setenv, setNames(list(val), key))
  }
}

source("../../../../scripts/lib/azure_data.R")

# --- 1. ARCOS data from Azure ---
# TRANSACTION_DATE is BIGINT in MMDDYYYY format
# BUYER_STATE is 2-letter abbreviation, BUYER_COUNTY is county name (not FIPS)
cat("Connecting to Azure for ARCOS data...\n")
con <- apep_azure_connect()

# Aggregate to county-distributor-year level
cat("Aggregating ARCOS data at county-distributor-year level via DuckDB...\n")
arcos_agg <- DBI::dbGetQuery(con, "
  SELECT
    BUYER_STATE AS state_abbr,
    BUYER_COUNTY AS county_name,
    Reporter_family AS distributor,
    CAST(TRANSACTION_DATE % 10000 AS INTEGER) AS year,
    SUM(DOSAGE_UNIT) AS total_pills,
    COUNT(*) AS n_transactions
  FROM 'az://raw/arcos/arcos_transactions.parquet'
  WHERE CAST(TRANSACTION_DATE % 10000 AS INTEGER) BETWEEN 2006 AND 2012
  GROUP BY BUYER_STATE, BUYER_COUNTY, Reporter_family,
    CAST(TRANSACTION_DATE % 10000 AS INTEGER)
")
cat(sprintf("ARCOS aggregated: %d county-distributor-year rows\n", nrow(arcos_agg)))

# County-year totals
arcos_cy <- DBI::dbGetQuery(con, "
  SELECT
    BUYER_STATE AS state_abbr,
    BUYER_COUNTY AS county_name,
    CAST(TRANSACTION_DATE % 10000 AS INTEGER) AS year,
    SUM(DOSAGE_UNIT) AS total_pills,
    COUNT(DISTINCT Reporter_family) AS n_distributors
  FROM 'az://raw/arcos/arcos_transactions.parquet'
  WHERE CAST(TRANSACTION_DATE % 10000 AS INTEGER) BETWEEN 2006 AND 2012
  GROUP BY BUYER_STATE, BUYER_COUNTY,
    CAST(TRANSACTION_DATE % 10000 AS INTEGER)
")
cat(sprintf("County-year totals: %d rows\n", nrow(arcos_cy)))

# Drug-type split (for robustness)
cat("Fetching drug-type split...\n")
drug_split <- DBI::dbGetQuery(con, "
  SELECT
    BUYER_STATE AS state_abbr,
    BUYER_COUNTY AS county_name,
    CAST(TRANSACTION_DATE % 10000 AS INTEGER) AS year,
    DRUG_NAME AS drug_type,
    SUM(DOSAGE_UNIT) AS pills
  FROM 'az://raw/arcos/arcos_transactions.parquet'
  WHERE CAST(TRANSACTION_DATE % 10000 AS INTEGER) BETWEEN 2006 AND 2012
  GROUP BY BUYER_STATE, BUYER_COUNTY,
    CAST(TRANSACTION_DATE % 10000 AS INTEGER), DRUG_NAME
")
cat(sprintf("Drug split: %d rows\n", nrow(drug_split)))

apep_azure_disconnect(con)

# Save ARCOS aggregates
setDT(arcos_agg)
setDT(arcos_cy)
setDT(drug_split)
fwrite(arcos_agg, "../data/arcos_county_distributor_year.csv")
fwrite(arcos_cy, "../data/arcos_county_year.csv")
fwrite(drug_split, "../data/arcos_drug_split.csv")

# --- 2. Build state-county-name to FIPS crosswalk ---
cat("Building county name to FIPS crosswalk...\n")

census_key <- Sys.getenv("CENSUS_API_KEY", "")
if (nchar(census_key) > 0) {
  tidycensus::census_api_key(census_key, install = FALSE)
}

# Get county FIPS codes from 2010 decennial
fips_xw <- tidycensus::fips_codes
setDT(fips_xw)
fips_xw[, fips := paste0(state_code, county_code)]
fips_xw[, county_clean := toupper(gsub(" County$| Parish$| Borough$| Census Area$| Municipality$| city$", "",
                                        county))]
fips_xw[, county_clean := trimws(county_clean)]

# ARCOS uses uppercase county names without "County" suffix
arcos_counties <- unique(arcos_agg[, .(state_abbr, county_name)])
arcos_counties[, county_clean := toupper(trimws(county_name))]

# Merge
county_xw <- merge(arcos_counties, fips_xw[, .(state, county_clean, fips)],
                    by.x = c("state_abbr", "county_clean"),
                    by.y = c("state", "county_clean"),
                    all.x = TRUE)

match_rate <- mean(!is.na(county_xw$fips))
cat(sprintf("FIPS match rate: %.1f%% (%d/%d counties)\n",
            100 * match_rate, sum(!is.na(county_xw$fips)), nrow(county_xw)))

fwrite(county_xw, "../data/county_fips_crosswalk.csv")

# --- 3. ACS county-level controls ---
cat("Fetching ACS county-level controls...\n")

acs_vars <- c(
  total_pop = "B01001_001",
  median_income = "B19013_001",
  white_pop = "B02001_002",
  hs_plus = "B06009_003"   # High school grad or higher
)

acs_list <- list()
for (yr in 2009:2012) {
  tryCatch({
    df <- tidycensus::get_acs(
      geography = "county",
      variables = acs_vars,
      year = yr,
      survey = "acs5",
      output = "wide",
      geometry = FALSE
    )
    df$year <- yr
    acs_list[[as.character(yr)]] <- as.data.table(df)
    cat(sprintf("  ACS %d: %d counties\n", yr, nrow(df)))
  }, error = function(e) {
    cat(sprintf("  ACS %d failed: %s\n", yr, e$message))
  })
}

acs_controls <- rbindlist(acs_list, fill = TRUE)
setnames(acs_controls,
  c("total_popE", "median_incomeE", "white_popE", "hs_plusE"),
  c("population", "median_income", "white_pop", "hs_pop"),
  skip_absent = TRUE
)
acs_controls[, fips := GEOID]

fwrite(acs_controls, "../data/acs_controls.csv")
cat(sprintf("ACS controls saved: %d county-year rows\n", nrow(acs_controls)))

# --- 4. CDC WONDER overdose mortality ---
cat("Fetching CDC WONDER overdose data...\n")

# Use NCHS drug poisoning estimates (county-level, model-based)
# Try multiple CDC endpoints
cdc_urls <- c(
  "https://data.cdc.gov/api/views/rpvx-m2md/rows.csv?accessType=DOWNLOAD",
  "https://data.cdc.gov/api/views/jx6g-fdh6/rows.csv?accessType=DOWNLOAD",
  "https://data.cdc.gov/api/views/p56q-lcp4/rows.csv?accessType=DOWNLOAD"
)

cdc_fetched <- FALSE
for (url in cdc_urls) {
  tryCatch({
    wonder_raw <- fread(url, showProgress = FALSE)
    cat(sprintf("CDC overdose data: %d rows, %d cols\n", nrow(wonder_raw), ncol(wonder_raw)))
    cat(sprintf("Columns: %s\n", paste(names(wonder_raw), collapse = ", ")))
    fwrite(wonder_raw, "../data/cdc_overdose_raw.csv")
    cdc_fetched <- TRUE
    break
  }, error = function(e) {
    cat(sprintf("CDC URL failed: %s\n", e$message))
  })
}
if (!cdc_fetched) {
  cat("All CDC WONDER endpoints failed. Proceeding without mortality outcome.\n")
  cat("Pills per capita from ARCOS is the primary outcome.\n")
}

cat("Data fetch complete.\n")
