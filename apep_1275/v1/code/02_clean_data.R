# 02_clean_data.R — Construct analysis panel for Pakistan 2022 Floods paper

source("00_packages.R")
sf::sf_use_s2(FALSE)

data_dir <- "../data"

# ============================================================================
# 1. Load data
# ============================================================================
cat("=== Loading data ===\n")

flood_intensity <- readRDS(file.path(data_dir, "flood_intensity.rds"))
ndvi_seasonal <- readRDS(file.path(data_dir, "ndvi_tehsil.rds"))

cat("  Flood intensity:", nrow(flood_intensity), "admin units\n")
cat("  NDVI seasonal:", nrow(ndvi_seasonal), "observations\n")

# ============================================================================
# 2. Construct treatment variables
# ============================================================================
cat("\n=== Constructing treatment variables ===\n")

# Continuous treatment: % flooded (0-100)
# Binary treatment groups for heterogeneity
flood_intensity[, flood_group := fcase(
  pct_flooded < 5, "control",
  pct_flooded >= 5 & pct_flooded < 20, "low",
  pct_flooded >= 20 & pct_flooded < 50, "moderate",
  pct_flooded >= 50, "severe"
)]
flood_intensity[, flood_group := factor(flood_group,
  levels = c("control", "low", "moderate", "severe"))]

# Standardized treatment (0-1 scale for interpretation)
flood_intensity[, flood_std := pct_flooded / 100]

cat("  Treatment group distribution:\n")
print(table(flood_intensity$flood_group))
cat("\n  Treatment intensity summary:\n")
print(flood_intensity[, .(n = .N,
  mean_pct = round(mean(pct_flooded), 1),
  sd_pct = round(sd(pct_flooded), 1),
  max_pct = round(max(pct_flooded), 1)),
  by = flood_group][order(flood_group)])

# ============================================================================
# 3. Merge flood intensity with NDVI panel
# ============================================================================
cat("\n=== Merging flood intensity with NDVI panel ===\n")

panel <- merge(ndvi_seasonal, flood_intensity[, .(tehsil_id, pct_flooded,
  flood_group, flood_std, total_area_km2, province, district)],
  by = "tehsil_id", suffixes = c("", "_flood"))

# Use province from flood_intensity (more reliable)
panel[, province := province_flood]
panel[, province_flood := NULL]

# Create post-flood indicator
# Flood occurred July-October 2022
# Kharif 2022 = during flood, Rabi 2022/23 = first post-flood recovery
panel[, post := as.integer(
  (season_type == "kharif" & year >= 2022) |
  (season_type == "rabi" & year >= 2022)
)]

# Create interaction terms
panel[, flood_x_post := pct_flooded * post]
panel[, flood_sq_x_post := (pct_flooded^2) * post]

# Season-year fixed effect
panel[, season_year := paste(season_type, year, sep = "_")]

# Province-specific time trends
panel[, prov_trend := as.integer(factor(season_year)) * as.integer(factor(province))]

cat("  Panel dimensions:", nrow(panel), "rows ×", ncol(panel), "columns\n")
cat("  Tehsils:", length(unique(panel$tehsil_id)), "\n")
cat("  Season-years:", length(unique(panel$season_year)), "\n")
cat("  Post observations:", sum(panel$post), "\n")
cat("  Pre observations:", sum(1 - panel$post), "\n")

# ============================================================================
# 4. Pre-treatment NDVI summary stats (for SDE normalization)
# ============================================================================
cat("\n=== Pre-treatment NDVI statistics ===\n")

pre_stats <- panel[post == 0, .(
  mean_ndvi = mean(ndvi_mean, na.rm = TRUE),
  sd_ndvi = sd(ndvi_mean, na.rm = TRUE),
  n = .N
), by = season_type]

cat("  Pre-treatment NDVI:\n")
print(pre_stats)

# Overall pre-treatment SD (for SDE calculation)
overall_pre_sd <- panel[post == 0, sd(ndvi_mean, na.rm = TRUE)]
cat("  Overall pre-treatment SD(NDVI):", round(overall_pre_sd, 4), "\n")

# Save pre-treatment SD for later use
saveRDS(overall_pre_sd, file.path(data_dir, "pre_sd_ndvi.rds"))

# ============================================================================
# 5. Save analysis panel
# ============================================================================
cat("\n=== Saving analysis panel ===\n")

saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
cat("  Saved:", nrow(panel), "observations\n")

# ============================================================================
# 6. Descriptive statistics table
# ============================================================================
cat("\n=== Descriptive Statistics ===\n")

desc_stats <- panel[, .(
  N = .N,
  Mean_NDVI = round(mean(ndvi_mean, na.rm = TRUE), 3),
  SD_NDVI = round(sd(ndvi_mean, na.rm = TRUE), 3),
  Mean_Flood_Pct = round(mean(pct_flooded), 1),
  SD_Flood_Pct = round(sd(pct_flooded), 1)
), by = .(season_type, Period = ifelse(post == 1, "Post", "Pre"))]

print(desc_stats[order(season_type, Period)])

cat("\n=== Data cleaning complete ===\n")
