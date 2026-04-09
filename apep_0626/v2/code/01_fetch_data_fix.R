## Quick fix: the azure_data.R helper has a quoting issue with the connection string.
## This wrapper loads it correctly by reading .env directly.
library(DBI)
library(duckdb)
library(data.table)
library(jsonlite)

data_dir <- "data"
dir.create(data_dir, showWarnings = FALSE)

## --- Connect to Azure ---
con <- dbConnect(duckdb())
dbExecute(con, "INSTALL azure;")
dbExecute(con, "LOAD azure;")

lines <- readLines(file.path(system("git rev-parse --show-toplevel", intern=TRUE), ".env"), warn=FALSE)
conn_str <- ""
for (line in lines) {
  if (grepl("^AZURE_STORAGE_CONNECTION_STRING=", line)) {
    conn_str <- sub("^AZURE_STORAGE_CONNECTION_STRING=", "", line)
    conn_str <- gsub("^[\"']|[\"']$", "", conn_str)
    break
  }
}
dbExecute(con, sprintf("CREATE SECRET apep_azure (TYPE azure, CONNECTION_STRING '%s');", conn_str))
cat("Connected to Azure\n")

az_query <- function(sql) {
  as.data.table(dbGetQuery(con, sql))
}

## ============================================================================
## 1. County-level quota exposure from 1920 full-count census
## ============================================================================
cat("=== 1. Computing 1920 county exposure ===\n")

if (!file.exists(file.path(data_dir, "county_exposure.rds"))) {
  county_exp <- az_query("
    SELECT STATEFIP, COUNTYICP, COUNT(*) as total_pop,
      SUM(CASE WHEN NATIVITY >= 5 THEN 1 ELSE 0 END) as total_fb,
      SUM(CASE WHEN NATIVITY >= 5 AND BPL IN (453,465,410,450,454,452) THEN 1 ELSE 0 END) as restricted_fb_core,
      SUM(CASE WHEN NATIVITY >= 5 AND BPL IN (453,465,410,450,454,452,455,456,457,458,459,460,461,462,466,467,468) THEN 1 ELSE 0 END) as restricted_fb_broad,
      SUM(CASE WHEN NATIVITY >= 5 AND BPL = 453 THEN 1 ELSE 0 END) as fb_italy,
      SUM(CASE WHEN NATIVITY >= 5 AND BPL = 465 THEN 1 ELSE 0 END) as fb_russia,
      SUM(CASE WHEN NATIVITY >= 5 AND BPL = 410 THEN 1 ELSE 0 END) as fb_poland,
      SUM(CASE WHEN NATIVITY >= 5 AND BPL = 450 THEN 1 ELSE 0 END) as fb_austria,
      SUM(CASE WHEN NATIVITY >= 5 AND BPL = 454 THEN 1 ELSE 0 END) as fb_hungary,
      SUM(CASE WHEN NATIVITY >= 5 AND BPL = 452 THEN 1 ELSE 0 END) as fb_czech
    FROM read_parquet('az://raw/ipums_fullcount/us1920c.parquet')
    WHERE STATEFIP < 57
    GROUP BY STATEFIP, COUNTYICP
    HAVING COUNT(*) >= 1000
  ")
  county_exp[, quota_exposure := restricted_fb_core / total_pop]
  county_exp[, quota_exposure_broad := restricted_fb_broad / total_pop]
  county_exp[, fb_share := total_fb / total_pop]
  for (origin in c("italy","russia","poland","austria","hungary","czech")) {
    county_exp[, paste0("share_", origin) := get(paste0("fb_", origin)) / total_pop]
  }
  cat(sprintf("  Counties: %d, mean exposure: %.3f\n", nrow(county_exp), mean(county_exp$quota_exposure)))
  saveRDS(county_exp, file.path(data_dir, "county_exposure.rds"))
} else { cat("  Cached\n") }

## ============================================================================
## 2. Analysis sample: 1920-1930 linked panel
## ============================================================================
cat("=== 2. Extracting 1920-1930 linked panel ===\n")

## The MLP crosswalk links individuals across censuses.
## We need to join crosswalk with both census years.
if (!file.exists(file.path(data_dir, "analysis_1920_1930.rds"))) {
  ## Check if pre-built linked panel exists
  has_linked <- tryCatch({
    n <- az_query("SELECT COUNT(*) as n FROM read_parquet('az://derived/mlp_panel/linked_1920_1930.parquet') LIMIT 1")
    n$n > 0
  }, error = function(e) FALSE)

  if (has_linked) {
    cat("  Using pre-built linked panel...\n")
    dt <- az_query("
      SELECT histid_1920, statefip_1920, countyicp_1920, age_1920, sex_1920, race_1920,
        lit_1920, farm_1920, occscore_1920, occ1950_1920, sei_1920, classwkr_1920, ownershp_1920,
        statefip_1930, countyicp_1930, occscore_1930, occ1950_1930, sei_1930, farm_1930,
        classwkr_1930, ownershp_1930, mover
      FROM read_parquet('az://derived/mlp_panel/linked_1920_1930.parquet')
      WHERE bpl_1920 < 100 AND age_1920 BETWEEN 18 AND 55
        AND occscore_1920 > 0 AND occscore_1930 > 0 AND sex_1920 = 1
    ")
  } else {
    cat("  No pre-built panel. Building from crosswalk + full-count censuses...\n")
    ## Use MLP crosswalk v2 + full-count censuses
    dt <- az_query("
      WITH xw AS (
        SELECT histid_a AS histid_1920, histid_b AS histid_1930
        FROM read_parquet('az://raw/ipums_mlp/v2/mlp_crosswalk_v2.parquet')
        WHERE year_a = 1920 AND year_b = 1930
      ),
      c20 AS (
        SELECT HISTID, STATEFIP, COUNTYICP, AGE, SEX, RACE, LIT, FARM, OCCSCORE,
               OCC1950, SEI, CLASSWKR, OWNERSHP, BPL, NATIVITY
        FROM read_parquet('az://raw/ipums_fullcount/us1920c.parquet')
      ),
      c30 AS (
        SELECT HISTID, STATEFIP, COUNTYICP, OCCSCORE, OCC1950, SEI, FARM, CLASSWKR, OWNERSHP
        FROM read_parquet('az://raw/ipums_fullcount/us1930d.parquet')
      )
      SELECT
        xw.histid_1920, c20.STATEFIP as statefip_1920, c20.COUNTYICP as countyicp_1920,
        c20.AGE as age_1920, c20.SEX as sex_1920, c20.RACE as race_1920, c20.LIT as lit_1920,
        c20.FARM as farm_1920, c20.OCCSCORE as occscore_1920, c20.OCC1950 as occ1950_1920,
        c20.SEI as sei_1920, c20.CLASSWKR as classwkr_1920, c20.OWNERSHP as ownershp_1920,
        c30.STATEFIP as statefip_1930, c30.COUNTYICP as countyicp_1930,
        c30.OCCSCORE as occscore_1930, c30.OCC1950 as occ1950_1930, c30.SEI as sei_1930,
        c30.FARM as farm_1930, c30.CLASSWKR as classwkr_1930, c30.OWNERSHP as ownershp_1930,
        CASE WHEN c20.STATEFIP != c30.STATEFIP OR c20.COUNTYICP != c30.COUNTYICP THEN 1 ELSE 0 END as mover
      FROM xw
      JOIN c20 ON xw.histid_1920 = c20.HISTID
      JOIN c30 ON xw.histid_1930 = c30.HISTID
      WHERE c20.BPL < 100 AND c20.AGE BETWEEN 18 AND 55
        AND c20.OCCSCORE > 0 AND c30.OCCSCORE > 0 AND c20.SEX = 1
    ")
  }
  cat(sprintf("  Analysis sample: %s rows\n", format(nrow(dt), big.mark=",")))
  saveRDS(dt, file.path(data_dir, "analysis_1920_1930.rds"))
  rm(dt); gc()
} else { cat("  Cached\n") }

## ============================================================================
## 3. Placebo sample: 1910-1920 linked panel
## ============================================================================
cat("=== 3. Extracting 1910-1920 placebo panel ===\n")

if (!file.exists(file.path(data_dir, "placebo_1910_1920.rds"))) {
  has_linked_1910 <- tryCatch({
    n <- az_query("SELECT COUNT(*) as n FROM read_parquet('az://derived/mlp_panel/linked_1910_1920.parquet') LIMIT 1")
    n$n > 0
  }, error = function(e) FALSE)

  if (has_linked_1910) {
    cat("  Using pre-built 1910-1920 panel...\n")
    dt_p <- az_query("
      SELECT histid_1910, statefip_1910, countyicp_1910, age_1910, sex_1910, race_1910,
        lit_1910, farm_1910, occscore_1910, occ1950_1910, classwkr_1910,
        statefip_1920, countyicp_1920, occscore_1920, occ1950_1920, farm_1920, classwkr_1920, mover
      FROM read_parquet('az://derived/mlp_panel/linked_1910_1920.parquet')
      WHERE bpl_1910 < 100 AND age_1910 BETWEEN 18 AND 55
        AND occscore_1910 > 0 AND occscore_1920 > 0 AND sex_1910 = 1
    ")
  } else {
    cat("  Building from crosswalk + censuses...\n")
    dt_p <- az_query("
      WITH xw AS (
        SELECT histid_a AS histid_1910, histid_b AS histid_1920
        FROM read_parquet('az://raw/ipums_mlp/v2/mlp_crosswalk_v2.parquet')
        WHERE year_a = 1910 AND year_b = 1920
      ),
      c10 AS (
        SELECT HISTID, STATEFIP, COUNTYICP, AGE, SEX, RACE, LIT, FARM, OCCSCORE,
               OCC1950, CLASSWKR, BPL
        FROM read_parquet('az://raw/ipums_fullcount/us1910m.parquet')
      ),
      c20 AS (
        SELECT HISTID, STATEFIP, COUNTYICP, OCCSCORE, OCC1950, FARM, CLASSWKR
        FROM read_parquet('az://raw/ipums_fullcount/us1920c.parquet')
      )
      SELECT
        xw.histid_1910, c10.STATEFIP as statefip_1910, c10.COUNTYICP as countyicp_1910,
        c10.AGE as age_1910, c10.SEX as sex_1910, c10.RACE as race_1910, c10.LIT as lit_1910,
        c10.FARM as farm_1910, c10.OCCSCORE as occscore_1910, c10.OCC1950 as occ1950_1910,
        c10.CLASSWKR as classwkr_1910,
        c20.STATEFIP as statefip_1920, c20.COUNTYICP as countyicp_1920,
        c20.OCCSCORE as occscore_1920, c20.OCC1950 as occ1950_1920,
        c20.FARM as farm_1920, c20.CLASSWKR as classwkr_1920,
        CASE WHEN c10.STATEFIP != c20.STATEFIP OR c10.COUNTYICP != c20.COUNTYICP THEN 1 ELSE 0 END as mover
      FROM xw
      JOIN c10 ON xw.histid_1910 = c10.HISTID
      JOIN c20 ON xw.histid_1920 = c20.HISTID
      WHERE c10.BPL < 100 AND c10.AGE BETWEEN 18 AND 55
        AND c10.OCCSCORE > 0 AND c20.OCCSCORE > 0 AND c10.SEX = 1
    ")
  }
  cat(sprintf("  Placebo sample: %s rows\n", format(nrow(dt_p), big.mark=",")))
  saveRDS(dt_p, file.path(data_dir, "placebo_1910_1920.rds"))
  rm(dt_p); gc()
} else { cat("  Cached\n") }

## ============================================================================
## 4. 1910 county exposure
## ============================================================================
cat("=== 4. Computing 1910 county exposure ===\n")

if (!file.exists(file.path(data_dir, "county_exposure_1910.rds"))) {
  county_exp_1910 <- az_query("
    SELECT STATEFIP, COUNTYICP, COUNT(*) as total_pop,
      SUM(CASE WHEN NATIVITY >= 5 AND BPL IN (453,465,410,450,454,452) THEN 1 ELSE 0 END) as restricted_fb_core
    FROM read_parquet('az://raw/ipums_fullcount/us1910m.parquet')
    WHERE STATEFIP < 57
    GROUP BY STATEFIP, COUNTYICP
    HAVING COUNT(*) >= 1000
  ")
  county_exp_1910[, quota_exposure_1910 := restricted_fb_core / total_pop]
  cat(sprintf("  1910 exposure: %d counties\n", nrow(county_exp_1910)))
  saveRDS(county_exp_1910, file.path(data_dir, "county_exposure_1910.rds"))
} else { cat("  Cached\n") }

## ============================================================================
## 5. V2: 1930 county foreign-born (first stage)
## ============================================================================
cat("=== 5. Computing 1930 county FB shares (first stage) ===\n")

if (!file.exists(file.path(data_dir, "county_fb_1930.rds"))) {
  county_fb_1930 <- az_query("
    SELECT STATEFIP, COUNTYICP, COUNT(*) as total_pop_1930,
      SUM(CASE WHEN NATIVITY >= 5 THEN 1 ELSE 0 END) as total_fb_1930,
      SUM(CASE WHEN NATIVITY >= 5 AND BPL IN (453,465,410,450,454,452) THEN 1 ELSE 0 END) as restricted_fb_1930
    FROM read_parquet('az://raw/ipums_fullcount/us1930d.parquet')
    WHERE STATEFIP < 57
    GROUP BY STATEFIP, COUNTYICP
    HAVING COUNT(*) >= 1000
  ")
  county_fb_1930[, fb_share_1930 := total_fb_1930 / total_pop_1930]
  county_fb_1930[, restricted_share_1930 := restricted_fb_1930 / total_pop_1930]
  cat(sprintf("  1930 FB data: %d counties\n", nrow(county_fb_1930)))
  saveRDS(county_fb_1930, file.path(data_dir, "county_fb_1930.rds"))
} else { cat("  Cached\n") }

## ============================================================================
## Done
## ============================================================================
dbDisconnect(con, shutdown=TRUE)
cat("\n=== All data fetched ===\n")
for (f in list.files(data_dir, pattern="\\.rds$")) {
  cat(sprintf("  %s: %s bytes\n", f, format(file.size(file.path(data_dir, f)), big.mark=",")))
}
