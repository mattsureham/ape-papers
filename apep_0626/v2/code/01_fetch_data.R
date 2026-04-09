## ============================================================================
## 01_fetch_data.R — Data Acquisition for apep_0626
## MLP Linked Panels + Full-Count 1920 Census from Azure Blob Storage
## ============================================================================
## REPLICATION NOTE:
## - Pre-built MLP linked panels and full-count census are in Azure Blob Storage
## - Requires AZURE_STORAGE_CONNECTION_STRING in .env
## - County-level quota exposure computed from full-count 1920 census
## ============================================================================

source("code/00_packages.R")

REPO_ROOT <- system("git rev-parse --show-toplevel", intern = TRUE)
source(file.path(REPO_ROOT, "scripts/lib/azure_data.R"))

data_dir <- "data"
dir.create(data_dir, showWarnings = FALSE)

con <- apep_azure_connect()

## --------------------------------------------------------------------------
## 1. Compute county-level quota exposure from full-count 1920 census
## --------------------------------------------------------------------------
## Restricted-origin countries (heavily quota-restricted by 1924 Act):
## Italy (453), Russia/USSR (465), Poland (410), Austria (450),
## Hungary (454), Czechoslovakia (452)
## Also include smaller origins: Greece, Romania, Lithuania, Yugoslavia,
## Albania, Bulgaria, Latvia, Estonia, Turkey, Portugal, Spain
## --------------------------------------------------------------------------

cat("=== Computing county-level quota exposure from 1920 full-count census ===\n")

county_exposure_file <- file.path(data_dir, "county_exposure.rds")

if (!file.exists(county_exposure_file)) {
  ## First, identify all BPL codes and their frequencies for foreign-born
  cat("Checking BPL code distribution for foreign-born...\n")
  bpl_dist <- apep_azure_query(con, "
    SELECT BPL, COUNT(*) as n
    FROM read_parquet('az://raw/ipums_fullcount/us1920c.parquet')
    WHERE NATIVITY >= 5  -- Foreign-born
    AND BPL >= 400       -- European
    GROUP BY BPL
    ORDER BY n DESC
    LIMIT 30
  ")
  setDT(bpl_dist)
  cat("Top 30 European foreign-born BPL codes:\n")
  print(bpl_dist)

  ## Compute county-level exposure
  cat("\nComputing county-level restricted-origin shares...\n")
  county_exp <- apep_azure_query(con, "
    SELECT
      STATEFIP,
      COUNTYICP,
      COUNT(*) as total_pop,
      SUM(CASE WHEN NATIVITY >= 5 THEN 1 ELSE 0 END) as total_fb,
      SUM(CASE WHEN NATIVITY >= 5 AND BPL IN (
        453,  -- Italy
        465,  -- Russia/USSR
        410,  -- Poland
        450,  -- Austria
        454,  -- Hungary
        452   -- Czechoslovakia
      ) THEN 1 ELSE 0 END) as restricted_fb_core,
      SUM(CASE WHEN NATIVITY >= 5 AND BPL IN (
        453, 465, 410, 450, 454, 452,  -- Core 6
        455, 456, 457, 458, 459,       -- Yugoslavia, Romania, Greece, Albania, Bulgaria
        460, 461,                       -- Portugal, Spain
        462,                            -- Turkey
        466, 467, 468                   -- Lithuania, Latvia, Estonia
      ) THEN 1 ELSE 0 END) as restricted_fb_broad,
      -- Individual origin shares for leave-one-out
      SUM(CASE WHEN NATIVITY >= 5 AND BPL = 453 THEN 1 ELSE 0 END) as fb_italy,
      SUM(CASE WHEN NATIVITY >= 5 AND BPL = 465 THEN 1 ELSE 0 END) as fb_russia,
      SUM(CASE WHEN NATIVITY >= 5 AND BPL = 410 THEN 1 ELSE 0 END) as fb_poland,
      SUM(CASE WHEN NATIVITY >= 5 AND BPL = 450 THEN 1 ELSE 0 END) as fb_austria,
      SUM(CASE WHEN NATIVITY >= 5 AND BPL = 454 THEN 1 ELSE 0 END) as fb_hungary,
      SUM(CASE WHEN NATIVITY >= 5 AND BPL = 452 THEN 1 ELSE 0 END) as fb_czech
    FROM read_parquet('az://raw/ipums_fullcount/us1920c.parquet')
    WHERE STATEFIP < 57  -- Exclude non-state territories
    GROUP BY STATEFIP, COUNTYICP
    HAVING COUNT(*) >= 1000  -- Minimum population
  ")
  setDT(county_exp)

  ## Compute shares
  county_exp[, quota_exposure := restricted_fb_core / total_pop]
  county_exp[, quota_exposure_broad := restricted_fb_broad / total_pop]
  county_exp[, fb_share := total_fb / total_pop]

  ## Individual origin shares for leave-one-out
  for (origin in c("italy", "russia", "poland", "austria", "hungary", "czech")) {
    county_exp[, paste0("share_", origin) := get(paste0("fb_", origin)) / total_pop]
  }

  cat(sprintf("County exposure computed: %d counties\n", nrow(county_exp)))
  cat(sprintf("Mean restricted FB share (core): %.3f\n", mean(county_exp$quota_exposure)))
  cat(sprintf("Median: %.3f, P75: %.3f, P90: %.3f, Max: %.3f\n",
      median(county_exp$quota_exposure),
      quantile(county_exp$quota_exposure, 0.75),
      quantile(county_exp$quota_exposure, 0.90),
      max(county_exp$quota_exposure)))

  saveRDS(county_exp, county_exposure_file)
  cat("Saved:", county_exposure_file, "\n")
} else {
  cat("County exposure already cached:", county_exposure_file, "\n")
  county_exp <- readRDS(county_exposure_file)
}

## --------------------------------------------------------------------------
## 2. Extract analysis sample from 1920-1930 linked panel
## --------------------------------------------------------------------------

cat("\n=== Extracting analysis sample from 1920-1930 linked panel ===\n")

analysis_file <- file.path(data_dir, "analysis_1920_1930.rds")

if (!file.exists(analysis_file)) {
  cat("Querying Azure for native-born workers...\n")

  ## Extract native-born workers aged 18-55 with valid occupations
  ## Keep only columns needed for analysis to minimize memory
  dt <- apep_azure_query(con, "
    SELECT
      histid_1920,
      statefip_1920,
      countyicp_1920,
      age_1920,
      sex_1920,
      race_1920,
      lit_1920,
      farm_1920,
      occscore_1920,
      occ1950_1920,
      sei_1920,
      classwkr_1920,
      ownershp_1920,
      statefip_1930,
      countyicp_1930,
      occscore_1930,
      occ1950_1930,
      sei_1930,
      farm_1930,
      classwkr_1930,
      ownershp_1930,
      mover
    FROM read_parquet('az://derived/mlp_panel/linked_1920_1930.parquet')
    WHERE bpl_1920 < 100           -- Native-born (US states)
      AND age_1920 BETWEEN 18 AND 55
      AND occscore_1920 > 0        -- Has occupation in 1920
      AND occscore_1930 > 0        -- Has occupation in 1930
      AND sex_1920 = 1             -- Men (women's labor force participation too low in 1920)
  ")
  setDT(dt)
  cat(sprintf("Analysis sample (1920-1930): %s rows\n", format(nrow(dt), big.mark = ",")))

  saveRDS(dt, analysis_file)
  cat("Saved:", analysis_file, "\n")
  rm(dt); gc()
} else {
  cat("Analysis sample already cached:", analysis_file, "\n")
}

## --------------------------------------------------------------------------
## 3. Extract placebo sample from 1910-1920 linked panel
## --------------------------------------------------------------------------

cat("\n=== Extracting placebo sample from 1910-1920 linked panel ===\n")

placebo_file <- file.path(data_dir, "placebo_1910_1920.rds")

if (!file.exists(placebo_file)) {
  cat("Querying Azure for 1910-1920 native-born workers...\n")

  ## Check columns available in 1910-1920 panel
  cols_1910 <- apep_azure_query(con, "
    SELECT column_name FROM (
      DESCRIBE SELECT * FROM read_parquet('az://derived/mlp_panel/linked_1910_1920.parquet') LIMIT 0
    )
  ")

  cat("Columns in 1910-1920 panel:\n")
  cat(paste(cols_1910$column_name, collapse = ", "), "\n")

  dt_placebo <- apep_azure_query(con, "
    SELECT
      histid_1910,
      statefip_1910,
      countyicp_1910,
      age_1910,
      sex_1910,
      race_1910,
      lit_1910,
      farm_1910,
      occscore_1910,
      occ1950_1910,
      classwkr_1910,
      statefip_1920,
      countyicp_1920,
      occscore_1920,
      occ1950_1920,
      farm_1920,
      classwkr_1920,
      mover
    FROM read_parquet('az://derived/mlp_panel/linked_1910_1920.parquet')
    WHERE bpl_1910 < 100
      AND age_1910 BETWEEN 18 AND 55
      AND occscore_1910 > 0
      AND occscore_1920 > 0
      AND sex_1910 = 1
  ")
  setDT(dt_placebo)
  cat(sprintf("Placebo sample (1910-1920): %s rows\n", format(nrow(dt_placebo), big.mark = ",")))

  saveRDS(dt_placebo, placebo_file)
  cat("Saved:", placebo_file, "\n")
  rm(dt_placebo); gc()
} else {
  cat("Placebo sample already cached:", placebo_file, "\n")
}

## --------------------------------------------------------------------------
## 4. Compute 1910 county exposure for placebo
## --------------------------------------------------------------------------

cat("\n=== Computing 1910 county exposure for placebo ===\n")

county_exp_1910_file <- file.path(data_dir, "county_exposure_1910.rds")

if (!file.exists(county_exp_1910_file)) {
  ## Use 1910 full-count census for 1910 exposure
  ## But we only have the linked panel for 1910, not full-count
  ## Use the linked panel itself to compute approximate county exposure
  ## (The full-count 1910 census is at raw/ipums_fullcount/us1910m.parquet)
  cat("Computing 1910 county exposure from full-count 1910 census...\n")
  county_exp_1910 <- apep_azure_query(con, "
    SELECT
      STATEFIP,
      COUNTYICP,
      COUNT(*) as total_pop,
      SUM(CASE WHEN NATIVITY >= 5 AND BPL IN (
        453, 465, 410, 450, 454, 452
      ) THEN 1 ELSE 0 END) as restricted_fb_core
    FROM read_parquet('az://raw/ipums_fullcount/us1910m.parquet')
    WHERE STATEFIP < 57
    GROUP BY STATEFIP, COUNTYICP
    HAVING COUNT(*) >= 1000
  ")
  setDT(county_exp_1910)
  county_exp_1910[, quota_exposure_1910 := restricted_fb_core / total_pop]

  cat(sprintf("1910 county exposure: %d counties\n", nrow(county_exp_1910)))
  saveRDS(county_exp_1910, county_exp_1910_file)
} else {
  cat("1910 county exposure already cached\n")
}

## --------------------------------------------------------------------------
## 5. V2: First-stage data — 1930 county-level foreign-born for
##    quantifying actual immigrant decline post-restriction
## --------------------------------------------------------------------------

cat("\n=== V2: Computing 1930 county foreign-born shares (first stage) ===\n")

county_fb_1930_file <- file.path(data_dir, "county_fb_1930.rds")

if (!file.exists(county_fb_1930_file)) {
  ## Check if 1930 full-count census exists in Azure
  has_1930 <- tryCatch({
    test <- apep_azure_query(con, "
      SELECT COUNT(*) as n
      FROM read_parquet('az://raw/ipums_fullcount/us1930c.parquet')
      LIMIT 1
    ")
    TRUE
  }, error = function(e) FALSE)

  if (has_1930) {
    cat("1930 full-count census found — computing county-level foreign-born shares...\n")
    county_fb_1930 <- apep_azure_query(con, "
      SELECT
        STATEFIP,
        COUNTYICP,
        COUNT(*) as total_pop_1930,
        SUM(CASE WHEN NATIVITY >= 5 THEN 1 ELSE 0 END) as total_fb_1930,
        SUM(CASE WHEN NATIVITY >= 5 AND BPL IN (
          453, 465, 410, 450, 454, 452
        ) THEN 1 ELSE 0 END) as restricted_fb_1930
      FROM read_parquet('az://raw/ipums_fullcount/us1930c.parquet')
      WHERE STATEFIP < 57
      GROUP BY STATEFIP, COUNTYICP
      HAVING COUNT(*) >= 1000
    ")
    setDT(county_fb_1930)
    county_fb_1930[, fb_share_1930 := total_fb_1930 / total_pop_1930]
    county_fb_1930[, restricted_share_1930 := restricted_fb_1930 / total_pop_1930]

    cat(sprintf("1930 county data: %d counties\n", nrow(county_fb_1930)))
    saveRDS(county_fb_1930, county_fb_1930_file)
  } else {
    cat("WARNING: 1930 full-count census not available in Azure.\n")
    cat("First-stage will use available data only.\n")
  }
} else {
  cat("1930 county FB data already cached\n")
}

## --------------------------------------------------------------------------
## 6. V2: Check for 1890 census (for exogenous exposure measure)
## --------------------------------------------------------------------------

cat("\n=== V2: Checking for 1890 census availability ===\n")

county_exp_1890_file <- file.path(data_dir, "county_exposure_1890.rds")

if (!file.exists(county_exp_1890_file)) {
  has_1890 <- tryCatch({
    test <- apep_azure_query(con, "
      SELECT COUNT(*) as n
      FROM read_parquet('az://raw/ipums_fullcount/us1890c.parquet')
      LIMIT 1
    ")
    TRUE
  }, error = function(e) {
    cat("  1890 census not found in Azure (expected: no surviving full-count exists).\n")
    cat("  Will use 1910 FB shares as robustness instead.\n")
    FALSE
  })

  if (has_1890) {
    cat("1890 census found — computing county exposure...\n")
    county_exp_1890 <- apep_azure_query(con, "
      SELECT
        STATEFIP, COUNTYICP,
        COUNT(*) as total_pop_1890,
        SUM(CASE WHEN NATIVITY >= 5 AND BPL IN (453, 465, 410, 450, 454, 452)
            THEN 1 ELSE 0 END) as restricted_fb_1890
      FROM read_parquet('az://raw/ipums_fullcount/us1890c.parquet')
      WHERE STATEFIP < 57
      GROUP BY STATEFIP, COUNTYICP
      HAVING COUNT(*) >= 500
    ")
    setDT(county_exp_1890)
    county_exp_1890[, quota_exposure_1890 := restricted_fb_1890 / total_pop_1890]
    saveRDS(county_exp_1890, county_exp_1890_file)
    cat(sprintf("1890 county exposure: %d counties\n", nrow(county_exp_1890)))
  }
} else {
  cat("1890 county exposure already cached\n")
}

apep_azure_disconnect(con)

cat("\n=== Data acquisition complete ===\n")
cat("Files created:\n")
for (f in list.files(data_dir, pattern = "\\.rds$")) {
  cat(sprintf("  %s: %s\n", f,
      format(file.size(file.path(data_dir, f)), big.mark = ",")))
}
