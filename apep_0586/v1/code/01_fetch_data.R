# ==============================================================================
# 01_fetch_data.R — Fetch data from Azure MLP panel
# apep_0586: Winning the Peace
# ==============================================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

cat("Connecting to Azure...\n")
con <- apep_azure_connect()

# ------------------------------------------------------------------------------
# 1. Extract draft-age men AND control cohorts from 3-decade panel
# Draft-eligible: born 1915-1922 (age 18-25 in 1940)
# Older control: born 1905-1914 (age 26-35 in 1940)
# Age placebo: born 1895-1904 (age 36-45 in 1940, low draft probability)
# All male (sex_1940 = 1)
# Birth year = 1940 - age_1940
# ------------------------------------------------------------------------------

cat("Fetching individual-level panel data...\n")
panel <- dbGetQuery(con, "
  SELECT
    histid_1930,
    histid_1940,
    histid_1950,
    -- 1930 variables
    statefip_1930,
    age_1930,
    occscore_1930,
    occ1950_1930,
    ind1950_1930,
    race_1930,
    bpl_1930,
    nativity_1930,
    marst_1930,
    farm_1930,
    sei_1930,
    -- 1940 variables
    statefip_1940,
    countyicp_1940,
    age_1940,
    occscore_1940,
    occ1950_1940,
    ind1950_1940,
    race_1940,
    bpl_1940,
    nativity_1940,
    marst_1940,
    farm_1940,
    educ_1940,
    incwage_1940,
    empstat_1940,
    classwkr_1940,
    sei_1940,
    perwt_1940,
    -- 1950 variables
    statefip_1950,
    age_1950,
    occscore_1950,
    occ1950_1950,
    ind1950_1950,
    race_1950,
    marst_1950,
    farm_1950,
    educ_1950,
    incwage_1950,
    empstat_1950,
    classwkr_1950,
    perwt_1950,
    -- Derived
    mover_40_50,
    mover_30_40,
    1940 - age_1940 AS birth_year
  FROM 'az://derived/mlp_panel/linked_1930_1940_1950.parquet'
  WHERE sex_1940 = 1
    AND age_1940 BETWEEN 18 AND 45
")

panel <- as.data.table(panel)
cat("Fetched", nrow(panel), "records\n")

# ------------------------------------------------------------------------------
# 2. Construct state-level agricultural employment share (mobilization instrument)
# Using the FULL 1940 census for all men 18-44 (not just linked panel)
# Agriculture = IND1950 codes 105-126
# ------------------------------------------------------------------------------

cat("Computing state-level mobilization instrument from 1940 census...\n")
state_ag <- dbGetQuery(con, "
  SELECT
    STATEFIP AS statefip,
    COUNT(*) AS total_men_18_44,
    SUM(CASE WHEN IND1950 BETWEEN 105 AND 126 THEN 1 ELSE 0 END) AS ag_men,
    SUM(CASE WHEN IND1950 BETWEEN 105 AND 126 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS ag_share,
    SUM(CASE WHEN IND1950 BETWEEN 306 AND 499 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS mfg_share,
    AVG(OCCSCORE) AS mean_occscore_1940_state,
    AVG(CASE WHEN INCWAGE > 0 AND INCWAGE < 999998 THEN INCWAGE END) AS mean_incwage_1940_state
  FROM 'az://raw/ipums_fullcount/us1940b.parquet'
  WHERE SEX = 1
    AND AGE BETWEEN 18 AND 44
    AND STATEFIP <= 56
  GROUP BY STATEFIP
  HAVING COUNT(*) > 1000
")
state_ag <- as.data.table(state_ag)

# Mobilization exposure = 1 - ag_share (higher ag → lower mobilization)
state_ag[, mob_exposure := 1 - ag_share]

# Standardize
state_ag[, mob_exposure_std := (mob_exposure - mean(mob_exposure)) / sd(mob_exposure)]

cat("State-level instrument computed for", nrow(state_ag), "states\n")
cat("Ag share range:", round(range(state_ag$ag_share), 3), "\n")
cat("Mob exposure range:", round(range(state_ag$mob_exposure), 3), "\n")

apep_azure_disconnect(con)

# ------------------------------------------------------------------------------
# 3. Save raw data
# ------------------------------------------------------------------------------

fwrite(panel, "../data/panel_raw.csv")
fwrite(state_ag, "../data/state_instrument.csv")

cat("\n=== DATA VALIDATION ===\n")
stopifnot("Expected 10M+ records" = nrow(panel) > 10000000)
stopifnot("Expected 45+ states" = length(unique(panel$statefip_1940)) >= 45)
stopifnot("Expected birth years 1895-1922" =
            min(panel$birth_year) <= 1895 & max(panel$birth_year) >= 1922)
stopifnot("State instrument has 45+ states" = nrow(state_ag) >= 45)
cat("Data validation passed:", nrow(panel), "rows,",
    length(unique(panel$statefip_1940)), "states,",
    "birth years", min(panel$birth_year), "-", max(panel$birth_year), "\n")
