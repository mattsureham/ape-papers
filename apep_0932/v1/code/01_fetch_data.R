# 01_fetch_data.R — Load MLP 3-decade panel + Fishback New Deal spending
# Uses 128GB RAM to load full 34.7M row panel into memory

source("00_packages.R")
source("../../../../scripts/lib/azure_data.R")

cat("Connecting to Azure...\n")
con <- apep_azure_connect()

# =============================================================================
# 1. Load MLP 3-decade linked panel (1920→1930→1940)
# =============================================================================
cat("Loading MLP linked_1920_1930_1940 panel (34.7M rows, ~5GB)...\n")
cat("  128GB unified memory allows full in-memory load.\n")

mlp <- DBI::dbGetQuery(con, "
  SELECT
    histid_1920, histid_1930, histid_1940,
    statefip_1920, statefip_1930, statefip_1940,
    countyicp_1920, countyicp_1930, countyicp_1940,
    age_1920, age_1930, age_1940,
    sex_1920, sex_1930, sex_1940,
    race_1920, race_1930, race_1940,
    bpl_1920, bpl_1930, bpl_1940,
    nativity_1920, nativity_1930, nativity_1940,
    marst_1920, marst_1930, marst_1940,
    occ1950_1920, occ1950_1930, occ1950_1940,
    ind1950_1920, ind1950_1930, ind1950_1940,
    occscore_1920, occscore_1930, occscore_1940,
    sei_1920, sei_1930, sei_1940,
    classwkr_1920, classwkr_1930, classwkr_1940,
    farm_1920, farm_1930, farm_1940,
    ownershp_1920, ownershp_1930, ownershp_1940,
    school_1920, school_1930, school_1940,
    mover_20_30, mover_30_40, mover_20_40
  FROM 'az://derived/mlp_panel/linked_1920_1930_1940.parquet'
")
setDT(mlp)
cat(sprintf("  Loaded %s individuals.\n", format(nrow(mlp), big.mark = ",")))

# Validate: no NULLs in key IDs
stopifnot(sum(is.na(mlp$histid_1930)) == 0)
stopifnot(sum(is.na(mlp$histid_1940)) == 0)
stopifnot(nrow(mlp) > 30000000)  # Expect ~34.7M

# =============================================================================
# 2. Also load 1940 INCWAGE (only available in raw 1940 census)
# =============================================================================
cat("Loading 1940 INCWAGE from raw census...\n")
incwage <- DBI::dbGetQuery(con, "
  SELECT HISTID as histid_1940, INCWAGE
  FROM 'az://raw/ipums_fullcount/us1940b.parquet'
  WHERE INCWAGE IS NOT NULL AND INCWAGE < 999998
")
setDT(incwage)
cat(sprintf("  Loaded %s wage records.\n", format(nrow(incwage), big.mark = ",")))

apep_azure_disconnect(con)

# =============================================================================
# 3. Load Fishback New Deal county spending data
# =============================================================================
cat("Loading Fishback New Deal county spending data...\n")

# The patriotism.tab uses tab-separated values
fishback <- fread("../data/patriotism.tab", sep = "\t")
cat(sprintf("  Loaded %d counties from Fishback data.\n", nrow(fishback)))

# Key variable: NDEXP_PC (total New Deal grants per capita)
stopifnot("NDEXP_PC" %in% names(fishback))
cat(sprintf("  NDEXP_PC: mean=%.1f, sd=%.1f, min=%.1f, max=%.1f\n",
            mean(fishback$NDEXP_PC, na.rm = TRUE),
            sd(fishback$NDEXP_PC, na.rm = TRUE),
            min(fishback$NDEXP_PC, na.rm = TRUE),
            max(fishback$NDEXP_PC, na.rm = TRUE)))

# Load ICPSR-to-FIPS bridge (for reference, but MLP uses countyicp directly)
bridge <- fread("../data/Bridge-FIPS-ICPRS.tab", sep = "\t")
cat(sprintf("  Bridge file: %d crosswalk rows.\n", nrow(bridge)))

# =============================================================================
# 4. Save raw data for downstream scripts
# =============================================================================
saveRDS(mlp, "../data/mlp_panel.rds")
saveRDS(incwage, "../data/incwage_1940.rds")
saveRDS(fishback, "../data/fishback_nd.rds")
saveRDS(bridge, "../data/bridge_fips_icpsr.rds")

cat("\nData fetch complete. Files saved to data/\n")
cat(sprintf("  MLP panel: %s rows\n", format(nrow(mlp), big.mark = ",")))
cat(sprintf("  INCWAGE 1940: %s rows\n", format(nrow(incwage), big.mark = ",")))
cat(sprintf("  Fishback: %d counties\n", nrow(fishback)))
