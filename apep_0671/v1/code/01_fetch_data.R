# =============================================================================
# 01_fetch_data.R — Fetch MLP linked panel data from Azure
# =============================================================================
# Data sources (all in APEP Azure Blob Storage):
#   - derived/mlp_panel/linked_1920_1930.parquet (53.6M linked individuals)
#   - derived/mlp_panel/linked_1910_1920.parquet (43.9M for placebo)
#   - raw/ipums_fullcount/us1920c.parquet (105M+ for county exposure)
# =============================================================================

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

con <- apep_azure_connect()

# ─────────────────────────────────────────────────────────────────────────────
# Step 1: Compute county-level restricted-origin foreign-born share from 1920
# ─────────────────────────────────────────────────────────────────────────────
# 1920 full-count uses UPPERCASE columns: STATEFIP, COUNTYICP, BPL
# Restricted-origin countries (Johnson-Reed quotas):
# Italy (BPL=453), Russia (BPL=465), Poland (BPL=410), Austria (BPL=450),
# Hungary (BPL=454), Czechoslovakia (BPL=452), Lithuania (BPL=433),
# Yugoslavia (BPL=457), Romania (BPL=455), Greece (BPL=434),
# Albania (BPL=436), Bulgaria (BPL=456)

cat("Computing county-level restricted-origin foreign-born shares from 1920 full-count...\n")

county_exposure <- apep_azure_query(con, "
  SELECT
    STATEFIP AS statefip,
    COUNTYICP AS countyicp,
    COUNT(*) AS total_pop,
    SUM(CASE WHEN BPL IN (453, 465, 410, 450, 454, 452, 433, 457, 455, 434, 436, 456)
         THEN 1 ELSE 0 END) AS restricted_fb,
    SUM(CASE WHEN BPL >= 400 THEN 1 ELSE 0 END) AS total_fb
  FROM 'az://raw/ipums_fullcount/us1920c.parquet'
  WHERE STATEFIP < 57
  GROUP BY STATEFIP, COUNTYICP
")

county_exposure <- as.data.table(county_exposure)
county_exposure[, restricted_share := restricted_fb / total_pop]
county_exposure[, fb_share := total_fb / total_pop]

cat(sprintf("County exposure computed: %d counties\n", nrow(county_exposure)))
cat(sprintf("  Mean restricted share: %.3f\n", mean(county_exposure$restricted_share)))
cat(sprintf("  P50: %.3f, P90: %.3f, Max: %.3f\n",
            quantile(county_exposure$restricted_share, 0.5),
            quantile(county_exposure$restricted_share, 0.9),
            max(county_exposure$restricted_share)))

fwrite(county_exposure, "../data/county_exposure_1920.csv")

# ─────────────────────────────────────────────────────────────────────────────
# Step 2: Load 1920-1930 linked panel (main analysis)
# ─────────────────────────────────────────────────────────────────────────────
# Linked panel uses lowercase with year suffix: statefip_1920, occscore_1930, etc.

cat("\nLoading 1920-1930 linked panel from Azure...\n")

main_panel <- apep_azure_query(con, "
  SELECT
    histid_1920 AS histid,
    statefip_1920, countyicp_1920,
    statefip_1930, countyicp_1930,
    age_1920, age_1930,
    sex_1920,
    race_1920,
    bpl_1920,
    lit_1920,
    occ1950_1920, occ1950_1930,
    occscore_1920, occscore_1930,
    sei_1920, sei_1930,
    ind1950_1920, ind1950_1930,
    classwkr_1920, classwkr_1930,
    farm_1920, farm_1930
  FROM 'az://derived/mlp_panel/linked_1920_1930.parquet'
  WHERE sex_1920 = 1
    AND age_1920 BETWEEN 18 AND 55
    AND bpl_1920 < 100
    AND statefip_1920 < 57
    AND occ1950_1920 IS NOT NULL AND occ1950_1920 > 0
    AND occ1950_1930 IS NOT NULL AND occ1950_1930 > 0
    AND occscore_1920 IS NOT NULL
    AND occscore_1930 IS NOT NULL
")

main_panel <- as.data.table(main_panel)
cat(sprintf("Main panel loaded: %s native-born working-age men\n", format(nrow(main_panel), big.mark=",")))

fwrite(main_panel, "../data/main_panel_1920_1930.csv")

# ─────────────────────────────────────────────────────────────────────────────
# Step 3: Load 1910-1920 linked panel (placebo)
# ─────────────────────────────────────────────────────────────────────────────
# Uses _1910 and _1920 suffixes. Note: sei_1910 does not exist in this panel.

cat("\nLoading 1910-1920 linked panel (placebo) from Azure...\n")

placebo_panel <- apep_azure_query(con, "
  SELECT
    histid_1910 AS histid,
    statefip_1910, countyicp_1910,
    statefip_1920, countyicp_1920,
    age_1910, age_1920,
    sex_1910,
    race_1910,
    bpl_1910,
    lit_1910,
    occ1950_1910, occ1950_1920,
    occscore_1910, occscore_1920,
    farm_1910, farm_1920
  FROM 'az://derived/mlp_panel/linked_1910_1920.parquet'
  WHERE sex_1910 = 1
    AND age_1910 BETWEEN 18 AND 55
    AND bpl_1910 < 100
    AND statefip_1910 < 57
    AND occ1950_1910 IS NOT NULL AND occ1950_1910 > 0
    AND occ1950_1920 IS NOT NULL AND occ1950_1920 > 0
    AND occscore_1910 IS NOT NULL
    AND occscore_1920 IS NOT NULL
")

placebo_panel <- as.data.table(placebo_panel)
cat(sprintf("Placebo panel loaded: %s native-born working-age men\n", format(nrow(placebo_panel), big.mark=",")))

fwrite(placebo_panel, "../data/placebo_panel_1910_1920.csv")

# ─────────────────────────────────────────────────────────────────────────────
# Step 4: Validate data
# ─────────────────────────────────────────────────────────────────────────────
cat("\n=== DATA VALIDATION ===\n")

if (sd(county_exposure$restricted_share) < 0.001) {
  stop("FATAL: No variation in county restricted-origin shares!")
}
if (nrow(main_panel) < 1000000) {
  stop("FATAL: Main panel has fewer than 1M observations!")
}
if (nrow(placebo_panel) < 500000) {
  stop("FATAL: Placebo panel has fewer than 500K observations!")
}

cat(sprintf("\nData fetch complete.\n"))
cat(sprintf("  Counties with exposure data: %d\n", nrow(county_exposure)))
cat(sprintf("  Main panel (1920-1930): %s observations\n", format(nrow(main_panel), big.mark=",")))
cat(sprintf("  Placebo panel (1910-1920): %s observations\n", format(nrow(placebo_panel), big.mark=",")))

apep_azure_disconnect(con)
