# ==============================================================================
# 01_fetch_data.R — Fetch MLP linked panels from Azure
# ==============================================================================
# Data: derived/mlp_panel/linked_1920_1930.parquet (4.9 GB)
#        derived/mlp_panel/linked_1910_1920.parquet (4.0 GB, placebo)
# ==============================================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")
con <- apep_azure_connect()

# --------------------------------------------------------------------------
# Define S/E European birthplace codes (IPUMS BPL)
# Restricted-origin countries under 1924 Johnson-Reed Act
# --------------------------------------------------------------------------
# Italy=434, Poland=456, Russia/USSR=465, Hungary=454, Austria=450,
# Czechoslovakia=452, Yugoslavia=457, Romania=455, Greece=433, Lithuania=460,
# Latvia=459, Bulgaria=431, Portugal=436, Turkey=437, Albania=430, Finland=401
se_euro_bpl <- c(434, 456, 465, 454, 450, 452, 457, 455, 433, 460, 459, 431, 436, 437, 430, 401)
se_euro_str <- paste(se_euro_bpl, collapse = ", ")

# --------------------------------------------------------------------------
# Step 1: Build county-level exposure measure from 1920 census
# Count restricted-origin foreign-born persons per county
# --------------------------------------------------------------------------
cat("Building county-level exposure from 1920 full-count census...\n")

exposure <- DBI::dbGetQuery(con, sprintf("
  SELECT
    statefip_1920 AS statefip,
    countyicp_1920 AS countyicp,
    COUNT(*) AS total_pop,
    SUM(CASE WHEN nativity_1920 >= 4 AND bpl_1920 IN (%s) THEN 1 ELSE 0 END) AS n_se_euro,
    SUM(CASE WHEN sex_1920 = 2 AND nativity_1920 >= 4 AND bpl_1920 IN (%s)
             AND occ1950_1920 IN (820, 821, 822, 825) THEN 1 ELSE 0 END) AS n_se_euro_female_domestics,
    SUM(CASE WHEN nativity_1920 >= 4 AND bpl_1920 IN (%s)
             AND occ1950_1920 IN (820, 821, 822, 825) THEN 1 ELSE 0 END) AS n_se_euro_domestics
  FROM 'az://derived/mlp_panel/linked_1920_1930.parquet'
  GROUP BY statefip_1920, countyicp_1920
", se_euro_str, se_euro_str, se_euro_str))

exposure$exposure <- exposure$n_se_euro / exposure$total_pop
exposure$exposure_domestic <- exposure$n_se_euro_female_domestics / exposure$total_pop
cat("Exposure measure built:", nrow(exposure), "counties\n")

# Save exposure
saveRDS(exposure, "../data/county_exposure.rds")

# --------------------------------------------------------------------------
# Step 2: Fetch main analysis sample — native-born white women aged 18-55
# --------------------------------------------------------------------------
cat("Fetching main sample: native-born white women 18-55...\n")

women <- DBI::dbGetQuery(con, "
  SELECT
    histid_1920, histid_1930,
    statefip_1920, countyicp_1920,
    age_1920, age_1930,
    marst_1920, marst_1930,
    occ1950_1920, occ1950_1930,
    occscore_1920, occscore_1930,
    farm_1920, farm_1930,
    nchild_1920, nchild_1930,
    lit_1920,
    ownershp_1920, ownershp_1930,
    mover,
    relate_1920
  FROM 'az://derived/mlp_panel/linked_1920_1930.parquet'
  WHERE sex_1920 = 2
    AND race_1920 = 1
    AND nativity_1920 <= 1
    AND age_1920 BETWEEN 18 AND 55
")

cat("Main sample:", nrow(women), "women\n")
stopifnot("Main sample must exceed 1M" = nrow(women) > 1000000)

saveRDS(women, "../data/women_1920_1930.rds")

# --------------------------------------------------------------------------
# Step 3: Fetch placebo sample — 1910-1920 (pre-Act period)
# --------------------------------------------------------------------------
cat("Fetching placebo sample: native-born white women 18-55, 1910-1920...\n")

# Check column names for 1910-1920 panel
placebo_cols <- DBI::dbGetQuery(con, "
  SELECT * FROM 'az://derived/mlp_panel/linked_1910_1920.parquet' LIMIT 1
")
cat("Placebo columns:", paste(names(placebo_cols), collapse = ", "), "\n")

placebo <- DBI::dbGetQuery(con, "
  SELECT
    histid_1910, histid_1920,
    statefip_1910, countyicp_1910,
    age_1910, age_1920,
    marst_1910, marst_1920,
    occ1950_1910, occ1950_1920,
    occscore_1910, occscore_1920,
    farm_1910, farm_1920,
    nchild_1910, nchild_1920,
    lit_1910,
    mover
  FROM 'az://derived/mlp_panel/linked_1910_1920.parquet'
  WHERE sex_1910 = 2
    AND race_1910 = 1
    AND nativity_1910 <= 1
    AND age_1910 BETWEEN 18 AND 55
")

cat("Placebo sample:", nrow(placebo), "women\n")
saveRDS(placebo, "../data/women_1910_1920.rds")

# --------------------------------------------------------------------------
# Step 4: Build exposure for 1910 census (placebo exposure)
# --------------------------------------------------------------------------
cat("Building placebo exposure from 1910 census...\n")

exposure_1910 <- DBI::dbGetQuery(con, sprintf("
  SELECT
    statefip_1910 AS statefip,
    countyicp_1910 AS countyicp,
    COUNT(*) AS total_pop,
    SUM(CASE WHEN nativity_1910 >= 4 AND bpl_1910 IN (%s) THEN 1 ELSE 0 END) AS n_se_euro
  FROM 'az://derived/mlp_panel/linked_1910_1920.parquet'
  GROUP BY statefip_1910, countyicp_1910
", se_euro_str))

exposure_1910$exposure <- exposure_1910$n_se_euro / exposure_1910$total_pop
saveRDS(exposure_1910, "../data/county_exposure_1910.rds")

apep_azure_disconnect(con)
cat("Data fetch complete.\n")
