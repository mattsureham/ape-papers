# ==============================================================================
# 02_clean_data.R — Construct flood instrument and analysis variables
# Paper: Flood, Flight, and Fortune (apep_1287)
# ==============================================================================

source("00_packages.R")

df <- arrow::read_parquet("../data/mlp_delta_farm_workers.parquet")
cat(sprintf("Loaded %d farm workers.\n", nrow(df)))

# --------------------------------------------------------------------------
# Construct flood instrument: Mississippi Alluvial Plain counties
# --------------------------------------------------------------------------
# The 1927 Great Mississippi Flood inundated counties in the Mississippi
# Alluvial Plain (MAP) — a well-defined geomorphological region. Counties
# within the MAP experienced severe flooding; counties in the adjacent
# uplands (Loess Bluffs, Piney Woods, Ozark Plateau) did not.
#
# Classification source: USDA Economic Research Service "Delta" region
# counties, refined to the alluvial plain proper using USGS geomorphological
# boundaries. This is geographic fact, not estimation.
#
# ICPSR county codes = FIPS county code × 10 (standard IPUMS mapping).
# --------------------------------------------------------------------------

# Mississippi alluvial plain counties (Yazoo-Mississippi Delta)
# FIPS: 011, 015, 027, 033, 043, 051, 053, 055, 083, 107, 119, 125, 133,
#       135, 137, 143, 149, 151, 163
ms_flood_icp <- c(110, 150, 270, 330, 430, 510, 530, 550, 830,
                  1070, 1190, 1250, 1330, 1350, 1370, 1430, 1490,
                  1510, 1630)

# Arkansas alluvial plain counties (eastern lowlands)
# FIPS: 001, 003, 017, 021, 031, 035, 037, 041, 043, 069, 077, 079, 085,
#       093, 095, 107, 111, 117, 123, 145, 147
ar_flood_icp <- c(10, 30, 170, 210, 310, 350, 370, 410, 430,
                  690, 770, 790, 850, 930, 950, 1070, 1110, 1170,
                  1230, 1450, 1470)

# Louisiana alluvial plain counties (Mississippi River corridor + Atchafalaya)
# FIPS: 005, 009, 025, 029, 035, 041, 043, 045, 047, 065, 067, 073, 077,
#       079, 083, 097, 099, 101, 107, 113, 115, 117
la_flood_icp <- c(50, 90, 250, 290, 350, 410, 430, 450, 470,
                  650, 670, 730, 770, 790, 830, 970, 990, 1010,
                  1070, 1130, 1150, 1170)

# Assign binary flood instrument
df$flood_exposed <- 0L
df$flood_exposed[df$statefip_1920 == 28 &
                   df$countyicp_1920 %in% ms_flood_icp] <- 1L
df$flood_exposed[df$statefip_1920 == 5 &
                   df$countyicp_1920 %in% ar_flood_icp] <- 1L
df$flood_exposed[df$statefip_1920 == 22 &
                   df$countyicp_1920 %in% la_flood_icp] <- 1L

cat(sprintf("Flood-exposed counties: %d individuals (%.1f%%)\n",
            sum(df$flood_exposed == 1),
            100 * mean(df$flood_exposed)))
cat(sprintf("Non-flood counties: %d individuals\n",
            sum(df$flood_exposed == 0)))

# Validate: need variation in instrument
stopifnot("No flood-exposed individuals found" = sum(df$flood_exposed) > 0)
stopifnot("No non-flood individuals found" = sum(df$flood_exposed == 0) > 0)

# --------------------------------------------------------------------------
# Construct analysis variables
# --------------------------------------------------------------------------

# Occupational upgrading (change in occscore)
df$delta_occ_30 <- df$occscore_1930 - df$occscore_1920
df$delta_occ_40 <- df$occscore_1940 - df$occscore_1920

# SEI change
df$delta_sei_30 <- df$sei_1930 - df$sei_1920
df$delta_sei_40 <- df$sei_1940 - df$sei_1920

# Exit from farming (IPUMS: farm=1 means on farm, farm=2 means not on farm)
df$left_farm_30 <- as.integer(df$farm_1920 == 1 & df$farm_1930 == 2)
df$left_farm_40 <- as.integer(df$farm_1920 == 1 & df$farm_1940 == 2)

# County identifier for clustering
df$county_id <- paste0(df$statefip_1920, "_", df$countyicp_1920)

# Age bins (for heterogeneity)
df$age_bin <- cut(df$age_1920, breaks = c(14, 25, 35, 45, 60),
                  labels = c("15-25", "26-35", "36-45", "46-60"))

# Create subsamples
black <- df[df$race_1920 == 2, ]
white <- df[df$race_1920 == 1, ]

cat(sprintf("\n=== Black Farm Workers ===\n"))
cat(sprintf("N = %d\n", nrow(black)))
cat(sprintf("Flood-exposed: %d (%.1f%%)\n",
            sum(black$flood_exposed), 100 * mean(black$flood_exposed)))
cat(sprintf("Mover rate (flood): %.1f%%\n",
            100 * mean(black$mover_20_30[black$flood_exposed == 1])))
cat(sprintf("Mover rate (no flood): %.1f%%\n",
            100 * mean(black$mover_20_30[black$flood_exposed == 0])))
cat(sprintf("Counties: %d\n", length(unique(black$county_id))))
cat(sprintf("Counties with flood: %d\n",
            length(unique(black$county_id[black$flood_exposed == 1]))))

cat(sprintf("\n=== White Farm Workers (falsification) ===\n"))
cat(sprintf("N = %d\n", nrow(white)))
cat(sprintf("Flood-exposed: %d (%.1f%%)\n",
            sum(white$flood_exposed), 100 * mean(white$flood_exposed)))

# Save analysis datasets
arrow::write_parquet(black, "../data/analysis_black.parquet")
arrow::write_parquet(white, "../data/analysis_white.parquet")
arrow::write_parquet(df, "../data/analysis_all.parquet")

cat("\nSaved analysis datasets.\n")
