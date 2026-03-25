## 02_clean_data.R — Clean and prepare analysis dataset
## apep_0913: Wilderness spatial RDD

source("00_packages.R")
data_dir <- file.path(dirname(getwd()), "data")

cat("Loading data...\n")
analysis_df <- readRDS(file.path(data_dir, "analysis_full.rds"))
cat("Loaded", nrow(analysis_df), "observations\n")

# ============================================================
# Variable construction
# ============================================================

# 1. Distance bins for binned scatter plots
analysis_df$dist_bin_100m <- round(analysis_df$dist_m / 100) * 100
analysis_df$dist_bin_250m <- round(analysis_df$dist_m / 250) * 250
analysis_df$dist_bin_500m <- round(analysis_df$dist_m / 500) * 500

# 2. Bandwidth indicators
analysis_df$within_2km <- abs(analysis_df$dist_km) <= 2
analysis_df$within_3km <- abs(analysis_df$dist_km) <= 3
analysis_df$within_5km <- abs(analysis_df$dist_km) <= 5

# 3. Elevation quintiles (for heterogeneity)
if (any(!is.na(analysis_df$elevation))) {
  analysis_df$elev_quintile <- ntile(analysis_df$elevation, 5)
} else {
  analysis_df$elev_quintile <- NA_integer_
}

# 4. Baseline tree cover categories
analysis_df$tc_cat <- cut(analysis_df$treecover2000,
                          breaks = c(-1, 10, 25, 50, 75, 100),
                          labels = c("0-10", "10-25", "25-50", "50-75", "75-100"))

# 5. High-forest indicator (treecover >= 50%)
analysis_df$high_forest <- as.integer(analysis_df$treecover2000 >= 50)

# 6. Treatment indicator (for clarity in regression notation)
analysis_df$wilderness <- as.integer(analysis_df$inside_wilderness)

# ============================================================
# Sample restrictions
# ============================================================

# Primary sample: forested pixels (treecover >= 25%)
cat("\nSample construction:\n")
cat("  All pixels:", nrow(analysis_df), "\n")
cat("  Forested (>= 25%):", sum(analysis_df$forested, na.rm = TRUE), "\n")
cat("  High forest (>= 50%):", sum(analysis_df$high_forest, na.rm = TRUE), "\n")

# ============================================================
# Summary statistics
# ============================================================

cat("\n=== SUMMARY STATISTICS ===\n")

# By treatment status
summary_by_treat <- analysis_df %>%
  filter(forested == 1, within_5km) %>%
  group_by(wilderness) %>%
  summarise(
    n = n(),
    mean_loss = mean(any_loss, na.rm = TRUE),
    mean_tc2000 = mean(treecover2000, na.rm = TRUE),
    mean_elev = mean(elevation, na.rm = TRUE),
    .groups = "drop"
  )

print(summary_by_treat)

# Binned means for RDD visualization
binned_means <- analysis_df %>%
  filter(forested == 1, within_5km) %>%
  group_by(dist_bin_250m) %>%
  summarise(
    n = n(),
    mean_loss = mean(any_loss, na.rm = TRUE),
    mean_tc2000 = mean(treecover2000, na.rm = TRUE),
    mean_elev = mean(elevation, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(n >= 50)  # Require minimum observations per bin

saveRDS(binned_means, file.path(data_dir, "binned_means.rds"))

# ============================================================
# Save cleaned data
# ============================================================
saveRDS(analysis_df, file.path(data_dir, "analysis_clean.rds"))

cat("\nCleaned dataset saved:", nrow(analysis_df), "observations\n")
cat("Variables:", paste(names(analysis_df), collapse = ", "), "\n")
