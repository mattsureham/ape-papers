# ==============================================================================
# 02_clean_data.R — Construct analysis variables
# ==============================================================================

source("00_packages.R")

women <- setDT(readRDS("../data/women_1920_1930.rds"))
exposure <- setDT(readRDS("../data/county_exposure.rds"))

cat("Raw women sample:", nrow(women), "\n")

# --------------------------------------------------------------------------
# Construct variables
# --------------------------------------------------------------------------

# LFP indicator: OCCSCORE > 0 means person reports an occupation
women[, lfp_1920 := as.integer(occscore_1920 > 0)]
women[, lfp_1930 := as.integer(occscore_1930 > 0)]
women[, d_lfp := lfp_1930 - lfp_1920]

# Domestic service indicator (OCC1950 codes: 820=housekeepers private,
# 821=laundresses private, 822=servants private)
women[, domestic_1920 := as.integer(occ1950_1920 %in% c(820, 821, 822, 825))]
women[, domestic_1930 := as.integer(occ1950_1930 %in% c(820, 821, 822, 825))]
women[, d_domestic := domestic_1930 - domestic_1920]

# Occupational score change
women[, d_occscore := occscore_1930 - occscore_1920]

# Married indicator (marst 1-2 = married spouse present/absent)
women[, married_1920 := as.integer(marst_1920 %in% c(1, 2))]

# Homeownership change
women[, own_1920 := as.integer(ownershp_1920 == 1)]
women[, own_1930 := as.integer(ownershp_1930 == 1)]

# Urban proxy: farm status
women[, urban_1920 := as.integer(farm_1920 != 2)]

# --------------------------------------------------------------------------
# Merge exposure
# --------------------------------------------------------------------------
women <- merge(women, exposure[, .(statefip, countyicp, exposure, exposure_domestic,
                                    n_se_euro, total_pop, n_se_euro_female_domestics)],
               by.x = c("statefip_1920", "countyicp_1920"),
               by.y = c("statefip", "countyicp"),
               all.x = TRUE)

# Drop counties with missing exposure (shouldn't happen, but be safe)
women <- women[!is.na(exposure)]
cat("After merge:", nrow(women), "women\n")

# Create exposure quartiles
women[, exposure_q := cut(exposure,
                          breaks = quantile(exposure, probs = c(0, 0.25, 0.5, 0.75, 1)),
                          labels = c("Q1", "Q2", "Q3", "Q4"),
                          include.lowest = TRUE)]

# County identifier for clustering
women[, county_id := paste0(statefip_1920, "_", countyicp_1920)]

# State FE
women[, state := as.factor(statefip_1920)]

cat("Final analysis sample:", nrow(women), "women\n")
cat("  Married:", sum(women$married_1920), "(", round(100*mean(women$married_1920),1), "%)\n")
cat("  LFP 1920:", sum(women$lfp_1920), "(", round(100*mean(women$lfp_1920),1), "%)\n")
cat("  LFP 1930:", sum(women$lfp_1930), "(", round(100*mean(women$lfp_1930),1), "%)\n")
cat("  Mean exposure:", round(mean(women$exposure), 4), "\n")
cat("  SD exposure:", round(sd(women$exposure), 4), "\n")
cat("  Unique counties:", uniqueN(women$county_id), "\n")

saveRDS(women, "../data/analysis_sample.rds")

# --------------------------------------------------------------------------
# Prepare placebo sample
# --------------------------------------------------------------------------
placebo <- setDT(readRDS("../data/women_1910_1920.rds"))
exposure_1910 <- setDT(readRDS("../data/county_exposure_1910.rds"))

placebo[, lfp_1910 := as.integer(occscore_1910 > 0)]
placebo[, lfp_1920 := as.integer(occscore_1920 > 0)]
placebo[, d_lfp := lfp_1920 - lfp_1910]
placebo[, married_1910 := as.integer(marst_1910 %in% c(1, 2))]
placebo[, domestic_1910 := as.integer(occ1950_1910 %in% c(820, 821, 822, 825))]
placebo[, domestic_1920 := as.integer(occ1950_1920 %in% c(820, 821, 822, 825))]
placebo[, d_domestic := domestic_1920 - domestic_1910]

placebo <- merge(placebo, exposure_1910[, .(statefip, countyicp, exposure)],
                 by.x = c("statefip_1910", "countyicp_1910"),
                 by.y = c("statefip", "countyicp"),
                 all.x = TRUE)
placebo <- placebo[!is.na(exposure)]
placebo[, county_id := paste0(statefip_1910, "_", countyicp_1910)]
placebo[, state := as.factor(statefip_1910)]

cat("Placebo sample:", nrow(placebo), "women\n")
saveRDS(placebo, "../data/placebo_sample.rds")

cat("Data cleaning complete.\n")
