# =============================================================================
# 02_clean_data.R — Load saved data, additional cleaning, summary statistics
# Paper: When the Banks Broke (apep_0916)
# =============================================================================

source("00_packages.R")

df <- fread("../data/analysis_panel.csv")
cat("Loaded analysis panel:", nrow(df), "rows\n")

# ─────────────────────────────────────────────────────────────────────────────
# Additional variable construction
# ─────────────────────────────────────────────────────────────────────────────

# Age bins for heterogeneity
df[, age_bin := fcase(
  age_1920 >= 18 & age_1920 <= 25, "18-25",
  age_1920 >= 26 & age_1920 <= 35, "26-35",
  age_1920 >= 36 & age_1920 <= 45, "36-45",
  age_1920 >= 46 & age_1920 <= 55, "46-55"
)]

# Occupational categories (1950 classification)
df[, occ_cat := fcase(
  occ1950_1920 %in% 0:99,   "Professional/Technical",
  occ1950_1920 %in% 100:199, "Managers/Officials",
  occ1950_1920 %in% 200:299, "Clerical",
  occ1950_1920 %in% 300:399, "Sales",
  occ1950_1920 %in% 400:499, "Craftsmen",
  occ1950_1920 %in% 500:599, "Operatives",
  occ1950_1920 %in% 600:699, "Service",
  occ1950_1920 %in% 700:799, "Farm laborers",
  occ1950_1920 %in% 800:899, "Laborers",
  occ1950_1920 >= 100 & occ1950_1920 <= 979, "Other",
  default = "Other"
)]

# Farmer indicator (more precise than farm_1920)
df[, farmer_1920 := as.integer(occ1950_1920 %in% 100:123 |
                                 occ1950_1920 %in% 700:799)]

# County identifier (composite)
df[, county_id := paste0(statefip_1920, "_", countyicp_1920)]

# High agricultural share indicator (above median)
median_ag <- median(df$ag_share, na.rm = TRUE)
df[, high_ag := as.integer(ag_share > median_ag)]

# Interaction: unit banking × high agriculture
df[, ub_x_high_ag := unit_banking * high_ag]

# ─────────────────────────────────────────────────────────────────────────────
# Remove missing values for key variables
# ─────────────────────────────────────────────────────────────────────────────
df <- df[!is.na(ag_share)]
df <- df[!is.na(delta_occscore_20_40)]
cat("After removing NAs:", nrow(df), "rows\n")

# ─────────────────────────────────────────────────────────────────────────────
# Summary statistics table
# ─────────────────────────────────────────────────────────────────────────────
cat("\n=== Summary Statistics by Unit Banking Status ===\n")
summ <- df[, .(
  N = .N,
  occscore_1920 = mean(occscore_1920),
  occscore_1940 = mean(occscore_1940),
  delta_occ = mean(delta_occscore_20_40),
  sd_delta_occ = sd(delta_occscore_20_40),
  pct_downgrade = mean(occ_downgrade),
  pct_migrated = mean(migrated),
  pct_lost_home = mean(lost_home),
  pct_farm_exit = mean(farm_exit),
  ag_share = mean(ag_share),
  age = mean(age_1920),
  pct_white = mean(white),
  pct_foreign = mean(foreign_born),
  pct_married = mean(married_1920),
  pct_farmer = mean(farmer_1920)
), by = unit_banking]
print(summ)

# Overall summary
cat("\n=== Overall Summary ===\n")
overall <- df[, .(
  N = .N,
  mean_occscore_1920 = mean(occscore_1920),
  sd_occscore_1920 = sd(occscore_1920),
  mean_occscore_1940 = mean(occscore_1940),
  sd_occscore_1940 = sd(occscore_1940),
  mean_delta = mean(delta_occscore_20_40),
  sd_delta = sd(delta_occscore_20_40),
  pct_downgrade = mean(occ_downgrade),
  pct_migrated = mean(migrated),
  pct_lost_home = mean(lost_home),
  n_counties = uniqueN(county_id),
  n_states = uniqueN(statefip_1920)
)]
print(overall)

# Save cleaned data
fwrite(df, "../data/analysis_clean.csv")
saveRDS(df, "../data/analysis_clean.rds")
cat("\nSaved analysis_clean.csv/rds (", nrow(df), "rows)\n")
