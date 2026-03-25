# 02_clean_data.R — Construct analysis sample and treatment variables
# apep_0932: New Deal WPA and Racial Occupational Mobility

source("00_packages.R")

cat("Loading saved data...\n")
mlp <- readRDS("../data/mlp_panel.rds")
incwage <- readRDS("../data/incwage_1940.rds")
fishback <- readRDS("../data/fishback_nd.rds")
bridge <- readRDS("../data/bridge_fips_icpsr.rds")

# =============================================================================
# 1. Restrict sample: men aged 18-55 in 1930
# =============================================================================
cat("Restricting sample: men aged 18-55 in 1930...\n")
df <- mlp[sex_1930 == 1 & age_1930 >= 18 & age_1930 <= 55]
cat(sprintf("  After sex/age filter: %s\n", format(nrow(df), big.mark = ",")))

# Race: keep White (1) and Black (2) only
df <- df[race_1930 %in% c(1, 2)]
cat(sprintf("  After race filter (White/Black): %s\n", format(nrow(df), big.mark = ",")))

# Must have valid county in 1930
df <- df[!is.na(countyicp_1930) & countyicp_1930 > 0]
cat(sprintf("  After county filter: %s\n", format(nrow(df), big.mark = ",")))

# Must have valid occupation scores in both 1930 and 1940
df <- df[!is.na(occscore_1930) & !is.na(occscore_1940) & occscore_1930 > 0 & occscore_1940 > 0]
cat(sprintf("  After occscore filter: %s\n", format(nrow(df), big.mark = ",")))

# =============================================================================
# 2. Merge Fishback New Deal spending
# =============================================================================
# Fishback data uses ICPSR codes: need to match to MLP's countyicp_1930
# =============================================================================
# Fishback data uses stateicpsr + countynd columns
# Bridge file maps FIPSTATE/FIPSCNTY to ICPSR1950_STATEN/ICPSR1950_COUNTY
# MLP panel uses statefip (FIPS) + countyicp (ICPSR county codes)
# Strategy: use bridge to map MLP FIPS state → ICPSR state, then merge with
# Fishback on ICPSR state + ICPSR county
# =============================================================================

cat("\nFishback columns: stateicpsr, countynd\n")
fishback_merge <- fishback[!is.na(NDEXP_PC), .(
  stateicpsr = as.integer(stateicpsr),
  countynd = as.integer(countynd),
  ndexp_pc = NDEXP_PC
)]
cat(sprintf("Fishback merge table: %d counties with New Deal spending.\n", nrow(fishback_merge)))

# Build FIPS state → ICPSR state mapping from bridge file
cat("Bridge columns: ", paste(names(bridge), collapse = ", "), "\n")
state_map <- unique(bridge[, .(
  fips_state = as.integer(FIPSTATE),
  icpsr_state = as.integer(ICPSR1950_STATEN)
)])
cat(sprintf("State map: %d FIPS→ICPSR mappings.\n", nrow(state_map)))

# Map MLP's FIPS statefip to ICPSR state code
df <- merge(df, state_map, by.x = "statefip_1930", by.y = "fips_state", all.x = TRUE)
cat(sprintf("  ICPSR state mapped: %s of %s\n",
            format(sum(!is.na(df$icpsr_state)), big.mark = ","),
            format(nrow(df), big.mark = ",")))

# For any unmatched: FIPS == ICPSR for most states
df[is.na(icpsr_state), icpsr_state := statefip_1930]

# MLP's countyicp_1930 is ICPSR county code = Fishback's countynd
# Merge on ICPSR state + county
df <- merge(df, fishback_merge,
            by.x = c("icpsr_state", "countyicp_1930"),
            by.y = c("stateicpsr", "countynd"),
            all.x = TRUE)

n_matched <- sum(!is.na(df$ndexp_pc))
cat(sprintf("Fishback merge: %s matched (%0.1f%% of sample)\n",
            format(n_matched, big.mark = ","),
            100 * n_matched / nrow(df)))

# Keep only matched counties
df <- df[!is.na(ndexp_pc)]
cat(sprintf("  After dropping unmatched: %s\n", format(nrow(df), big.mark = ",")))
stopifnot(nrow(df) > 100000)  # Must have substantial sample

# =============================================================================
# 3. Construct treatment and outcome variables
# =============================================================================
cat("\nConstructing variables...\n")

# Binary race indicator
df[, black := as.integer(race_1930 == 2)]

# Occupational score changes
df[, d_occscore_30_40 := occscore_1940 - occscore_1930]
df[, d_occscore_20_30 := occscore_1930 - occscore_1920]

# SEI changes
df[, d_sei_30_40 := sei_1940 - sei_1930]
df[, d_sei_20_30 := sei_1930 - sei_1920]

# New Deal spending terciles
df[, nd_tercile := cut(ndexp_pc,
                        breaks = quantile(ndexp_pc, probs = c(0, 1/3, 2/3, 1), na.rm = TRUE),
                        labels = c("Low", "Medium", "High"),
                        include.lowest = TRUE)]
df[, high_nd := as.integer(nd_tercile == "High")]

# Standardized New Deal spending (for continuous treatment)
df[, ndexp_std := (ndexp_pc - mean(ndexp_pc, na.rm = TRUE)) / sd(ndexp_pc, na.rm = TRUE)]

# County identifier for FE and clustering (state × county)
df[, county_id := paste0(statefip_1930, "_", countyicp_1930)]

# South indicator (former Confederate states + border)
south_fips <- c(1, 5, 10, 12, 13, 21, 22, 24, 28, 37, 40, 45, 47, 48, 51, 54)
df[, south := as.integer(statefip_1930 %in% south_fips)]

# Age bins for controls
df[, age_bin_1930 := cut(age_1930, breaks = c(17, 25, 35, 45, 56),
                          labels = c("18-25", "26-35", "36-45", "46-55"))]

# Farm worker indicator (1930)
df[, farm_worker_1930 := as.integer(farm_1930 == 2)]

# Geographic mobility
df[, moved_30_40 := as.integer(mover_30_40 == 1)]

# =============================================================================
# 4. Merge 1940 INCWAGE
# =============================================================================
cat("Merging 1940 INCWAGE...\n")
df <- merge(df, incwage, by = "histid_1940", all.x = TRUE)
n_wage <- sum(!is.na(df$INCWAGE) & df$INCWAGE > 0)
cat(sprintf("  %s individuals with positive INCWAGE.\n", format(n_wage, big.mark = ",")))
df[, log_incwage := ifelse(INCWAGE > 0, log(INCWAGE), NA_real_)]

# =============================================================================
# 5. Summary statistics
# =============================================================================
cat("\n=== SAMPLE SUMMARY ===\n")
cat(sprintf("Total sample: %s\n", format(nrow(df), big.mark = ",")))
cat(sprintf("White men: %s\n", format(sum(df$black == 0), big.mark = ",")))
cat(sprintf("Black men: %s\n", format(sum(df$black == 1), big.mark = ",")))
cat(sprintf("Southern: %s\n", format(sum(df$south == 1), big.mark = ",")))
cat(sprintf("Unique counties: %d\n", uniqueN(df$county_id)))

cat("\nOccupational score by race and decade:\n")
print(df[, .(
  mean_occ_1920 = mean(occscore_1920, na.rm = TRUE),
  mean_occ_1930 = mean(occscore_1930, na.rm = TRUE),
  mean_occ_1940 = mean(occscore_1940, na.rm = TRUE),
  d_occ_20_30 = mean(d_occscore_20_30, na.rm = TRUE),
  d_occ_30_40 = mean(d_occscore_30_40, na.rm = TRUE),
  n = .N
), by = .(Race = ifelse(black == 1, "Black", "White"))])

cat("\nNew Deal spending by tercile:\n")
print(df[, .(
  mean_ndexp = mean(ndexp_pc, na.rm = TRUE),
  n_white = sum(black == 0),
  n_black = sum(black == 1)
), by = nd_tercile][order(nd_tercile)])

# =============================================================================
# 6. Save analysis dataset
# =============================================================================
saveRDS(df, "../data/analysis_sample.rds")
cat(sprintf("\nAnalysis sample saved: %s rows.\n", format(nrow(df), big.mark = ",")))
