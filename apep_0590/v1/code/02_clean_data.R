## =============================================================================
## 02_clean_data.R — apep_0590
## Panel construction, variable creation, sample restrictions
## =============================================================================

source("00_packages.R")

data_dir <- "../data"

# Load panel
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
cat("Loaded panel:", nrow(panel), "rows\n")

# =============================================================================
# Variable Construction
# =============================================================================

# 1. Log tree cover loss (adding small constant for zeros)
panel[, log_loss := log(tree_cover_loss_ha + 1)]

# 2. Tree cover loss as share of baseline forest area (intensive margin)
panel[, loss_share := fifelse(
  forest_area_ha_2000 > 0,
  tree_cover_loss_ha / forest_area_ha_2000 * 100,
  0
)]

# 3. Asinh transformation (handles zeros without arbitrary constant)
panel[, asinh_loss := asinh(tree_cover_loss_ha)]

# 4. Municipality area in hectares (from total pixel count)
pixel_ha <- 0.09
panel[, muni_area_ha := total_pixels * pixel_ha]

# 5. Loss rate per 1000 hectares of municipality area
panel[, loss_rate := tree_cover_loss_ha / (muni_area_ha / 1000)]

# 6. Forest share in 2000 (baseline)
panel[, forest_share_2000 := forest_area_ha_2000 / muni_area_ha * 100]

# 7. Pre-treatment average loss (2001-2018) for each municipality
pre_treat <- panel[year <= 2018, .(
  pre_mean_loss = mean(tree_cover_loss_ha, na.rm = TRUE),
  pre_sd_loss = sd(tree_cover_loss_ha, na.rm = TRUE),
  pre_mean_loss_rate = mean(loss_rate, na.rm = TRUE)
), by = GID_2]

panel <- merge(panel, pre_treat, by = "GID_2", all.x = TRUE)

# 8. Standardized loss (z-score relative to municipality pre-treatment mean)
panel[, z_loss := fifelse(
  pre_sd_loss > 0,
  (tree_cover_loss_ha - pre_mean_loss) / pre_sd_loss,
  0
)]

# =============================================================================
# Ecosystem Classification
# =============================================================================

# Classify municipalities by baseline forest share
# Use forest_share_2000 (computed from forest_area_ha / muni_area_ha)
# since treecover2000_pct has extraction issues
panel[, ecosystem := fcase(
  forest_share_2000 >= 50, "Tropical moist",
  forest_share_2000 >= 25, "Tropical dry / mixed",
  forest_share_2000 >= 10, "Semi-arid woodland",
  default = "Arid / sparse"
)]

# =============================================================================
# Treatment Variable Refinement
# =============================================================================

# For Callaway-Sant'Anna, need first_treat variable
# 0 = never treated; year = first treatment year
panel[, first_treat := sv_cohort_year]

# Event time (relative to treatment)
panel[, event_time := fifelse(
  first_treat > 0,
  year - first_treat,
  NA_integer_
)]

# =============================================================================
# Sample Restrictions
# =============================================================================

# Drop municipalities with zero forest area in 2000 (no forest to lose)
# These are desert/urban municipalities with no meaningful outcome variation
n_before <- uniqueN(panel$GID_2)
panel <- panel[forest_area_ha_2000 > 0]
n_after <- uniqueN(panel$GID_2)
cat("Dropped", n_before - n_after, "municipalities with zero baseline forest\n")
cat("Remaining:", n_after, "municipalities\n")

# =============================================================================
# Summary Statistics
# =============================================================================

cat("\n=== Summary Statistics ===\n")

# By treatment status
sumstats <- panel[year <= 2018, .(
  N_munis = uniqueN(GID_2),
  mean_loss_ha = mean(tree_cover_loss_ha, na.rm = TRUE),
  sd_loss_ha = sd(tree_cover_loss_ha, na.rm = TRUE),
  mean_forest_ha = mean(forest_area_ha_2000, na.rm = TRUE),
  mean_treecover_pct = mean(treecover2000_pct, na.rm = TRUE),
  mean_loss_rate = mean(loss_rate, na.rm = TRUE)
), by = .(treated_ever = first_treat > 0)]

print(sumstats)

# By cohort
cohort_stats <- panel[year <= 2018, .(
  N_munis = uniqueN(GID_2),
  mean_loss_ha = round(mean(tree_cover_loss_ha, na.rm = TRUE), 2),
  mean_forest_ha = round(mean(forest_area_ha_2000, na.rm = TRUE), 0),
  mean_treecover = round(mean(treecover2000_pct, na.rm = TRUE), 1)
), by = first_treat]

cat("\nPre-treatment means by cohort:\n")
print(cohort_stats)

# Save summary stats for tables
fwrite(sumstats, file.path(data_dir, "summary_stats_by_treatment.csv"))
fwrite(cohort_stats, file.path(data_dir, "summary_stats_by_cohort.csv"))

# =============================================================================
# Save Clean Panel
# =============================================================================

fwrite(panel, file.path(data_dir, "clean_panel.csv"))
cat("\nClean panel saved:", nrow(panel), "rows,",
    uniqueN(panel$GID_2), "municipalities,",
    uniqueN(panel$year), "years\n")

# Validation
stopifnot("Expected 1500+ municipalities" = uniqueN(panel$GID_2) >= 1500)
stopifnot("Panel is balanced" = all(
  panel[, .N, by = GID_2]$N == uniqueN(panel$year)
))
cat("Panel is balanced. DONE.\n")
