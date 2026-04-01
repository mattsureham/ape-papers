# =============================================================================
# 02_clean_data.R — Construct analysis variables
# Paper: The Inertia Break (apep_1279)
# =============================================================================

source("00_packages.R")

cat("Loading data...\n")
con_local <- dbConnect(duckdb())
dt <- as.data.table(dbGetQuery(con_local, "SELECT * FROM '../data/mlp_men_1910_1920.parquet'"))
dbDisconnect(con_local)
cat(sprintf("Loaded %s rows\n", format(nrow(dt), big.mark = ",")))

# -----------------------------------------------------------------------
# Key variables for WWI draft RD
# -----------------------------------------------------------------------

# Birth year (approximate from age in 1910 census, taken April 15, 1910)
dt[, birth_year := 1910 - age_1910]

# Draft eligibility: men aged 21-30 on June 5, 1917 (first registration)
# Age 21 in June 1917 = born ~1896 = age 14 in 1910
# Age 30 in June 1917 = born ~1887 = age 23 in 1910
# RD cutoff: age 14 in 1910 (born ~1896) is the youngest first-draft eligible
# Men aged 13 in 1910 (born ~1897) were NOT eligible until third registration
# (September 12, 1918, which expanded to ages 18-45, but war ended Nov 1918)
dt[, draft_eligible := as.integer(age_1910 >= 14)]

# Draft-core: ages 14-23 in 1910 (21-30 in 1917, the primary draft ages)
dt[, draft_core := as.integer(age_1910 %between% c(14, 23))]

# Running variable for RD: centered at cutoff age 14
dt[, age_centered := age_1910 - 14]

# -----------------------------------------------------------------------
# Outcome variables
# -----------------------------------------------------------------------

# Farm status: farm_1910/farm_1920 uses IPUMS coding (2 = farm, 1 = non-farm)
dt[, on_farm_1910 := as.integer(farm_1910 == 2)]
dt[, on_farm_1920 := as.integer(farm_1920 == 2)]
dt[, farm_exit := as.integer(on_farm_1910 == 1 & on_farm_1920 == 0)]

# Occupational income score change
dt[, delta_occscore := occscore_1920 - occscore_1910]

# Geographic mobility (different county)
dt[, moved_county := as.integer(
  statefip_1910 != statefip_1920 | countyicp_1910 != countyicp_1920
)]

# Manufacturing entry (conditional on farm in 1910)
# OCC1950 manufacturing codes: broadly 500-699 (craftsmen, operatives, laborers in manufacturing)
# IND1950 manufacturing: 306-499
dt[, manuf_1920 := as.integer(ind1950_1920 %between% c(306, 499))]
dt[, farm_to_manuf := as.integer(on_farm_1910 == 1 & manuf_1920 == 1)]

# -----------------------------------------------------------------------
# Nativity for DiD (native-born faced draft, foreign-born non-citizens exempt)
# IPUMS nativity: 1 = native-born native parents, 2 = native-born foreign parents
# 3 = native-born parents unknown, 4 = foreign-born, 5 = foreign-born parents unknown
# -----------------------------------------------------------------------
dt[, native_born := as.integer(nativity_1910 %in% c(1, 2, 3))]
dt[, foreign_born := as.integer(nativity_1910 %in% c(4, 5))]

# Race
dt[, white := as.integer(race_1910 == 1)]
dt[, black := as.integer(race_1910 == 2)]

# Literacy
dt[, literate := as.integer(lit_1910 == 4)]  # IPUMS: 4 = literate

# Married
dt[, married_1910 := as.integer(marst_1910 %in% c(1, 2))]  # 1=married spouse present, 2=married spouse absent

# County agricultural share in 1910 (for heterogeneity)
county_ag <- dt[age_1910 %between% c(20, 40),
                .(ag_share = mean(on_farm_1910, na.rm = TRUE)),
                by = .(statefip_1910, countyicp_1910)]
dt <- merge(dt, county_ag, by = c("statefip_1910", "countyicp_1910"), all.x = TRUE)
dt[, high_ag := as.integer(ag_share > median(ag_share, na.rm = TRUE))]

# -----------------------------------------------------------------------
# Sample restrictions
# -----------------------------------------------------------------------

# Remove obs with missing key variables
dt <- dt[!is.na(on_farm_1910) & !is.na(on_farm_1920)]
dt <- dt[!is.na(occscore_1910) & !is.na(occscore_1920)]

cat(sprintf("After cleaning: %s rows\n", format(nrow(dt), big.mark = ",")))

cat("\nKey summary stats:\n")
cat(sprintf("  Farm exit rate (all):     %.1f%%\n", mean(dt$farm_exit) * 100))
cat(sprintf("  Farm exit (draft-elig):   %.1f%%\n", mean(dt[draft_eligible == 1]$farm_exit) * 100))
cat(sprintf("  Farm exit (not elig):     %.1f%%\n", mean(dt[draft_eligible == 0]$farm_exit) * 100))
cat(sprintf("  Mean Δoccscore:           %.2f\n", mean(dt$delta_occscore)))
cat(sprintf("  Moved county rate:        %.1f%%\n", mean(dt$moved_county) * 100))
cat(sprintf("  Native-born share:        %.1f%%\n", mean(dt$native_born) * 100))

# -----------------------------------------------------------------------
# Save analysis dataset
# -----------------------------------------------------------------------
con_local <- dbConnect(duckdb())
duckdb_register(con_local, "dt_tbl", dt)
dbExecute(con_local, "COPY dt_tbl TO '../data/analysis.parquet' (FORMAT PARQUET)")
duckdb_unregister(con_local, "dt_tbl")
dbDisconnect(con_local)

cat(sprintf("\nSaved analysis dataset: %s rows\n", format(nrow(dt), big.mark = ",")))
cat("Done.\n")
