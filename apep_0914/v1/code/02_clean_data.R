# =============================================================================
# 02_clean_data.R — Construct analysis variables
# Paper: AAA Cotton Displacement and Black Occupational Scarring
# =============================================================================

source("00_packages.R")

# --- 1. Load raw data ---
panel <- as.data.table(readRDS("../data/panel_raw.rds"))
county_treat <- as.data.table(readRDS("../data/county_treatment.rds"))

cat("Raw panel: ", nrow(panel), " individuals\n")
cat("Columns: ", paste(names(panel), collapse = ", "), "\n")

# --- 2. Identify farm workers in 1930 ---
# farm_1930 == 2 indicates farm/plantation worker in IPUMS coding
panel[, is_farm_1930 := (farm_1930 == 2)]
cat("Farm workers in 1930: ", sum(panel$is_farm_1930), "\n")
cat("Non-farm in 1930: ", sum(!panel$is_farm_1930), "\n")

# --- 3. Construct race indicator ---
# race_1930: 1=White, 2=Black/African American
panel[, black := as.integer(race_1930 == 2)]
cat("\nRace distribution among farm workers:\n")
print(panel[is_farm_1930 == TRUE, .N, by = .(race_label = ifelse(black == 1, "Black", "White"))])

# --- 4. Merge county-level treatment ---
panel <- merge(panel, county_treat[, .(statefip_1930, countyicp_1930, farm_share, n_total)],
               by = c("statefip_1930", "countyicp_1930"),
               all.x = TRUE)

# Drop individuals in counties with too few observations for reliable treatment
panel <- panel[!is.na(farm_share)]
cat("\nAfter county merge: ", nrow(panel), " individuals\n")

# --- 5. Filter to farm workers only ---
farm_panel <- panel[is_farm_1930 == TRUE]
cat("Farm worker panel: ", nrow(farm_panel), " individuals\n")

# --- 6. Reshape to long format (person x wave) ---
# Columns: occscore_1930, occscore_1940, occscore_1950
id_vars <- c("histid_1930", "statefip_1930", "countyicp_1930",
             "black", "farm_share", "n_total", "mover_40_50")

# Check which occscore columns exist
occ_cols <- grep("^occscore_", names(farm_panel), value = TRUE)
cat("Occupational score columns: ", paste(occ_cols, collapse = ", "), "\n")

# Reshape
long <- melt(farm_panel,
             id.vars = id_vars,
             measure.vars = occ_cols,
             variable.name = "wave_var",
             value.name = "occscore")

# Extract year from variable name
long[, year := as.integer(gsub("occscore_", "", wave_var))]
long[, wave_var := NULL]

# --- 7. Construct DDD variables ---
long[, post := as.integer(year > 1930)]
long[, post1940 := as.integer(year == 1940)]
long[, post1950 := as.integer(year == 1950)]

# Triple interaction: farm_share x black x post
long[, treat_triple := farm_share * black * post]
long[, treat_double_farm_post := farm_share * post]
long[, treat_double_black_post := black * post]

# County identifier for clustering
long[, county_id := paste0(statefip_1930, "_", countyicp_1930)]

# Individual identifier
long[, pid := histid_1930]

# --- 8. Summary statistics ---
cat("\n=== Summary Statistics ===\n")
cat("\nBy race (1930 farm workers):\n")
summ <- farm_panel[, .(
  N = .N,
  occscore_1930 = mean(occscore_1930, na.rm = TRUE),
  occscore_1940 = mean(occscore_1940, na.rm = TRUE),
  occscore_1950 = mean(occscore_1950, na.rm = TRUE),
  gain_30_50 = mean(occscore_1950 - occscore_1930, na.rm = TRUE),
  pct_migrated = mean(mover_40_50, na.rm = TRUE) * 100,
  farm_share_mean = mean(farm_share, na.rm = TRUE)
), by = .(Race = ifelse(black == 1, "Black", "White"))]
print(summ)

cat("\nCounty-level treatment distribution:\n")
print(summary(county_treat$farm_share))

cat("\nNumber of unique counties: ", length(unique(long$county_id)), "\n")
cat("Number of unique individuals: ", length(unique(long$pid)), "\n")
cat("Number of observations (long): ", nrow(long), "\n")

# --- 9. Validate data quality ---
stopifnot("No missing occscore" = sum(is.na(long$occscore)) / nrow(long) < 0.05)
stopifnot("Both races present" = length(unique(long$black)) == 2)
stopifnot("Three waves present" = length(unique(long$year)) == 3)
stopifnot("Sufficient counties" = length(unique(long$county_id)) >= 100)

# --- 10. Save cleaned data ---
saveRDS(long, "../data/panel_long.rds")
saveRDS(farm_panel, "../data/farm_panel_wide.rds")
saveRDS(summ, "../data/summary_stats.rds")

cat("\nCleaned data saved.\n")
cat("  Long panel: ", nrow(long), " obs (", length(unique(long$pid)), " individuals x 3 waves)\n")
