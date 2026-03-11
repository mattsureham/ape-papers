# ==============================================================================
# 02_clean_data.R — Construct treatment, merge prohibition dates, create outcomes
# Paper: State Prohibition and Labor Market Restructuring (apep_0592)
# ==============================================================================

source("00_packages.R")

# Load data
panel <- fread("../data/panel_1910_1920.csv")
county_alc <- fread("../data/county_alcohol_shares.csv")
prohib <- fread("../data/prohibition_dates.csv")

# ==============================================================================
# 1. Merge County-Level Alcohol Shares
# ==============================================================================
panel <- merge(panel, county_alc[, .(statefip_1910, countyicp_1910, alc_share,
                                      bartender_share, bev_manuf_share, total_workers,
                                      mean_occscore_1910 = mean_occscore_1910)],
               by = c("statefip_1910", "countyicp_1910"), all.x = TRUE)

# Drop counties with missing alcohol data (very small counties < 100 workers)
panel <- panel[!is.na(alc_share)]

# ==============================================================================
# 2. Merge Prohibition Dates
# ==============================================================================
panel <- merge(panel, prohib[, .(statefip = statefip, prohib_year, dry_before_1910,
                                  dry_1910_1919, never_dry, prohib_years_by_1920)],
               by.x = "statefip_1910", by.y = "statefip", all.x = TRUE)

# Drop states not in our prohibition coding (territories, etc.)
panel <- panel[!is.na(prohib_year)]

# ==============================================================================
# 3. Construct Treatment Variables
# ==============================================================================

# Binary treatment: state went dry between 1910 and 1919
panel[, treated_state := as.integer(dry_1910_1919)]

# Continuous treatment: alcohol share × state prohibition
panel[, treatment := alc_share * treated_state]

# Dose-response: alcohol share × years of prohibition by 1920
panel[, treatment_years := alc_share * prohib_years_by_1920]

# Treatment groups for analysis
panel[, state_group := fifelse(dry_before_1910, "Already dry",
                        fifelse(dry_1910_1919, "Went dry 1910-1919",
                                "Wet until 1920"))]

# Quartiles of alcohol share (for heterogeneity)
panel[alc_share > 0, alc_quartile := cut(alc_share,
      breaks = quantile(alc_share, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE),
      labels = c("Q1 (Low)", "Q2", "Q3", "Q4 (High)"),
      include.lowest = TRUE)]
panel[alc_share == 0, alc_quartile := "Zero"]

# ==============================================================================
# 4. Construct Outcome Variables
# ==============================================================================

# Primary outcome: change in occupational income score
panel[, delta_occscore := occscore_1920 - occscore_1910]

# Occupational switching (different occ1950 code)
panel[, occ_switch := as.integer(occ1950_1910 != occ1950_1920)]

# Industry switching
panel[, ind_switch := as.integer(ind1950_1910 != ind1950_1920)]

# Self-employment transition
panel[, became_self_employed := as.integer(classwkr_1910 == 2 & classwkr_1920 == 1)]
panel[, self_employed_1910 := as.integer(classwkr_1910 == 1)]
panel[, self_employed_1920 := as.integer(classwkr_1920 == 1)]

# Home ownership change
panel[, became_homeowner := as.integer(ownershp_1910 != 1 & ownershp_1920 == 1)]

# Geographic mobility (already in data)
# mover = 1 if changed county between censuses

# Occupational upgrading/downgrading
panel[, occ_upgrade := as.integer(delta_occscore > 5)]
panel[, occ_downgrade := as.integer(delta_occscore < -5)]

# ==============================================================================
# 5. Pre-Prohibition Industry Categories (for mechanism tests)
# ==============================================================================
# Supply chain industries connected to alcohol production
# Supply chain: glass, cooperage, grain, transportation
# Using IND1950 codes confirmed in the data
panel[, supply_chain := as.integer(ind1950_1910 %in% c(
  # Grain/agriculture inputs (feeds into brewing)
  105,
  # Food/beverage manufacturing (includes brewing supply chain)
  206, 216, 226, 236,
  # Glass manufacturing
  346,
  # Transportation/shipping
  506, 516, 526, 536, 546
))]

# Retail/hospitality (would absorb saloon space/workers)
panel[, retail_hospitality := as.integer(ind1950_1910 %in% c(
  # Eating/drinking places (non-saloon — coded as 846, 847, 848, 849, 868)
  846, 847, 848, 849, 868,
  # Hotels/lodging
  836,
  # Retail trade
  606, 607, 608, 609, 616, 617, 618, 619, 626, 627, 636, 646
))]

# Manufacturing (general, for crowding effects)
panel[, manufacturing := as.integer(ind1950_1910 >= 200 & ind1950_1910 < 500)]

# ==============================================================================
# 6. Individual Controls
# ==============================================================================
panel[, age_sq := age_1910^2]
panel[, immigrant := as.integer(nativity_1910 >= 4)]
panel[, black := as.integer(race_1910 == 2)]
panel[, married := as.integer(marst_1910 %in% c(1, 2))]
panel[, literate := as.integer(lit_1910 == 4)]
panel[, male := as.integer(sex_1910 == 1)]

# Create county identifier for FE
panel[, county_id := paste0(statefip_1910, "_", countyicp_1910)]

# Census region (for region FE)
panel[, region := fcase(
  statefip_1910 %in% c(9, 23, 25, 33, 34, 36, 42, 44, 50), "Northeast",
  statefip_1910 %in% c(17, 18, 19, 20, 26, 27, 29, 31, 38, 39, 46, 55), "Midwest",
  statefip_1910 %in% c(1, 5, 10, 11, 12, 13, 21, 22, 24, 28, 37, 40, 45, 47, 48, 51, 54), "South",
  statefip_1910 %in% c(4, 6, 8, 16, 30, 32, 35, 41, 49, 53, 56), "West"
)]

# Non-Southern indicator (for preferred specification excluding South)
panel[, non_south := as.integer(region != "South")]

# ==============================================================================
# 7. Analysis Samples
# ==============================================================================

# Main sample: exclude already-dry states, focus on went-dry vs never-dry
main_sample <- panel[dry_before_1910 == FALSE]
cat("Main sample (excl. already-dry):", format(nrow(main_sample), big.mark = ","), "individuals\n")
cat("  Treated states (went dry 1910-1919):", uniqueN(main_sample[treated_state == 1, statefip_1910]), "\n")
cat("  Control states (wet until 1920):", uniqueN(main_sample[never_dry == TRUE, statefip_1910]), "\n")

# Non-South sample: preferred specification
nonsouth_sample <- main_sample[non_south == 1]
cat("Non-South sample:", format(nrow(nonsouth_sample), big.mark = ","), "individuals\n")

# Male-only sample (for comparability with typical historical labor studies)
male_sample <- main_sample[male == 1]
cat("Male sample:", format(nrow(male_sample), big.mark = ","), "individuals\n")

# Save
fwrite(main_sample, "../data/analysis_sample.csv")
fwrite(nonsouth_sample, "../data/nonsouth_sample.csv")

# Summary statistics
cat("\n=== TREATMENT VARIABLE SUMMARY ===\n")
cat("AlcShare: mean =", round(mean(main_sample$alc_share), 4),
    ", sd =", round(sd(main_sample$alc_share), 4),
    ", min =", round(min(main_sample$alc_share), 4),
    ", max =", round(max(main_sample$alc_share), 4), "\n")
cat("Treatment (AlcShare × Treated):\n")
cat("  Mean:", round(mean(main_sample$treatment), 5), "\n")
cat("  SD:", round(sd(main_sample$treatment), 5), "\n")
cat("Delta OCCSCORE: mean =", round(mean(main_sample$delta_occscore, na.rm = TRUE), 2),
    ", sd =", round(sd(main_sample$delta_occscore, na.rm = TRUE), 2), "\n")

# ==============================================================================
# 8. Prepare Pre-Trend Data (1900-1910)
# ==============================================================================
pretrend <- fread("../data/panel_1900_1910.csv")

# Need 1900 county-level alcohol shares
county_alc_1900 <- fread("../data/county_alcohol_shares_1900.csv")

pretrend <- merge(pretrend, county_alc_1900[, .(statefip_1900, countyicp_1900, alc_share_1900)],
                  by = c("statefip_1900", "countyicp_1900"), all.x = TRUE)
pretrend <- pretrend[!is.na(alc_share_1900)]

# Merge prohibition dates (using 1910 state)
pretrend <- merge(pretrend, prohib[, .(statefip, prohib_year, dry_before_1910, dry_1910_1919, never_dry)],
                  by.x = "statefip_1910", by.y = "statefip", all.x = TRUE)
pretrend <- pretrend[!is.na(prohib_year)]

# Exclude already-dry states
pretrend <- pretrend[dry_before_1910 == FALSE]

pretrend[, delta_occscore := occscore_1910 - occscore_1900]
pretrend[, treated_state := as.integer(dry_1910_1919)]
pretrend[, treatment := alc_share_1900 * treated_state]
pretrend[, county_id := paste0(statefip_1910, "_", countyicp_1910)]
pretrend[, occ_switch := as.integer(occ1950_1900 != occ1950_1910)]

# Controls
pretrend[, immigrant := as.integer(nativity_1900 >= 4)]
pretrend[, black := as.integer(race_1900 == 2)]
pretrend[, male := as.integer(sex_1900 == 1)]
pretrend[, age_sq := age_1900^2]

pretrend[, region := fcase(
  statefip_1910 %in% c(9, 23, 25, 33, 34, 36, 42, 44, 50), "Northeast",
  statefip_1910 %in% c(17, 18, 19, 20, 26, 27, 29, 31, 38, 39, 46, 55), "Midwest",
  statefip_1910 %in% c(1, 5, 10, 11, 12, 13, 21, 22, 24, 28, 37, 40, 45, 47, 48, 51, 54), "South",
  statefip_1910 %in% c(4, 6, 8, 16, 30, 32, 35, 41, 49, 53, 56), "West"
)]

fwrite(pretrend, "../data/pretrend_sample.csv")
cat("Pre-trend sample (1900-1910):", format(nrow(pretrend), big.mark = ","), "individuals\n")

# ==============================================================================
# 9. Prepare Long-Run Data (1920-1930)
# ==============================================================================
# Free memory before loading long-run panel
rm(panel, pretrend, main_sample, nonsouth_sample, male_sample)
gc()

longrun <- fread("../data/panel_1920_1930.csv")

# Merge 1910 county-level alcohol shares via 1920 county
# (workers may have moved between 1910 and 1920)
# Use county alcohol share based on where they were in 1920
county_alc_for_merge <- county_alc[, .(statefip_1910, countyicp_1910, alc_share)]
setnames(county_alc_for_merge, c("statefip_1910", "countyicp_1910"),
         c("statefip_1920", "countyicp_1920"))

longrun <- merge(longrun, county_alc_for_merge,
                 by = c("statefip_1920", "countyicp_1920"), all.x = TRUE)
longrun <- longrun[!is.na(alc_share)]

longrun <- merge(longrun, prohib[, .(statefip, prohib_year, dry_before_1910, dry_1910_1919, never_dry)],
                 by.x = "statefip_1920", by.y = "statefip", all.x = TRUE)
longrun <- longrun[!is.na(prohib_year) & dry_before_1910 == FALSE]

longrun[, delta_occscore := occscore_1930 - occscore_1920]
longrun[, treated_state := as.integer(dry_1910_1919)]
longrun[, treatment := alc_share * treated_state]
longrun[, county_id := paste0(statefip_1920, "_", countyicp_1920)]
longrun[, occ_switch := as.integer(occ1950_1920 != occ1950_1930)]
longrun[, immigrant := as.integer(nativity_1920 >= 4)]
longrun[, black := as.integer(race_1920 == 2)]
longrun[, male := as.integer(sex_1920 == 1)]
longrun[, age_sq := age_1920^2]

longrun[, region := fcase(
  statefip_1920 %in% c(9, 23, 25, 33, 34, 36, 42, 44, 50), "Northeast",
  statefip_1920 %in% c(17, 18, 19, 20, 26, 27, 29, 31, 38, 39, 46, 55), "Midwest",
  statefip_1920 %in% c(1, 5, 10, 11, 12, 13, 21, 22, 24, 28, 37, 40, 45, 47, 48, 51, 54), "South",
  statefip_1920 %in% c(4, 6, 8, 16, 30, 32, 35, 41, 49, 53, 56), "West"
)]

fwrite(longrun, "../data/longrun_sample.csv")
cat("Long-run sample (1920-1930):", format(nrow(longrun), big.mark = ","), "individuals\n")

cat("\nAll data cleaning complete.\n")
