# 02_clean_data.R — Construct analysis panel
source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# 1. Load raw data
# ============================================================================
cat("=== Loading raw data ===\n")

viirs <- read.csv(file.path(data_dir, "viirs_district_annual.csv"))
mfi <- read.csv(file.path(data_dir, "mfi_revocations.csv"))
pop <- read.csv(file.path(data_dir, "region_population.csv"))
ghana_sf <- readRDS(file.path(data_dir, "ghana_districts.rds"))

cat(sprintf("  VIIRS: %d obs, %d districts, %d years\n",
            nrow(viirs), n_distinct(viirs$gid), n_distinct(viirs$year)))

# ============================================================================
# 2. Construct treatment intensity at district level
# ============================================================================
cat("\n=== Constructing treatment variable ===\n")

# Count districts per region
districts_per_region <- ghana_sf %>%
  st_drop_geometry() %>%
  count(region, name = "n_districts")

# Merge MFI revocations with district counts
treatment <- mfi %>%
  left_join(districts_per_region, by = "region") %>%
  left_join(pop, by = "region") %>%
  mutate(
    # Distribute regional revocations evenly across districts in region
    mfi_per_district = n_revoked / n_districts,
    # Treatment intensity: revoked MFIs per 100k population (regional)
    intensity_regional = n_revoked / (pop_2021 / 1e5),
    # Per-district intensity (distributing pop proportionally)
    pop_per_district = pop_2021 / n_districts,
    intensity_district = mfi_per_district / (pop_per_district / 1e5)
  )

cat("  Treatment intensity by region:\n")
treatment %>%
  select(region, n_revoked, n_districts, intensity_regional) %>%
  arrange(desc(intensity_regional)) %>%
  print()

# Merge treatment intensity to district panel
# Each district gets its region's treatment intensity
district_treatment <- ghana_sf %>%
  st_drop_geometry() %>%
  select(gid, region, district) %>%
  left_join(treatment %>% select(region, n_revoked, intensity_regional,
                                  mfi_per_district, intensity_district),
            by = "region")

# ============================================================================
# 3. Construct analysis panel
# ============================================================================
cat("\n=== Constructing analysis panel ===\n")

panel <- viirs %>%
  left_join(district_treatment, by = c("gid", "region", "district")) %>%
  mutate(
    # Post-treatment indicator (treatment: May 2019 → annual = 2019+)
    # Since annual data, 2019 is partially treated. Code 2020+ as clean post.
    post = as.integer(year >= 2020),
    post_incl_2019 = as.integer(year >= 2019),
    # Log nighttime lights (add small constant to handle zeros)
    log_ntl = log(ntl_mean + 0.01),
    # Treatment interaction
    treat_post = intensity_regional * post,
    treat_post_incl = intensity_regional * post_incl_2019,
    # Binary treatment (above median intensity)
    high_treatment = as.integer(intensity_regional >
                                 median(unique(intensity_regional))),
    high_treat_post = high_treatment * post,
    # Standardize treatment intensity for interpretation
    intensity_std = (intensity_regional - mean(unique(intensity_regional))) /
                     sd(unique(intensity_regional))
  )

# Check for NAs
na_check <- colSums(is.na(panel))
if (any(na_check > 0)) {
  cat("  WARNING: NAs found:\n")
  print(na_check[na_check > 0])
}

cat(sprintf("  Panel: %d observations\n", nrow(panel)))
cat(sprintf("  Districts: %d\n", n_distinct(panel$gid)))
cat(sprintf("  Years: %s\n", paste(sort(unique(panel$year)), collapse = ", ")))
cat(sprintf("  Pre-period: %d years\n", sum(unique(panel$year) < 2019)))
cat(sprintf("  Post-period: %d years\n", sum(unique(panel$year) >= 2020)))

# ============================================================================
# 4. Summary statistics
# ============================================================================
cat("\n=== Summary Statistics ===\n")

# Pre-treatment summary
pre_stats <- panel %>%
  filter(year < 2019) %>%
  summarize(
    mean_ntl = mean(ntl_mean, na.rm = TRUE),
    sd_ntl = sd(ntl_mean, na.rm = TRUE),
    median_ntl = median(ntl_mean, na.rm = TRUE),
    mean_log_ntl = mean(log_ntl, na.rm = TRUE),
    sd_log_ntl = sd(log_ntl, na.rm = TRUE),
    n_obs = n(),
    n_districts = n_distinct(gid)
  )

cat("  Pre-treatment (2014-2018):\n")
print(pre_stats)

# By treatment group
cat("\n  Pre-treatment by treatment group:\n")
panel %>%
  filter(year < 2019) %>%
  group_by(high_treatment) %>%
  summarize(
    n_districts = n_distinct(gid),
    mean_ntl = mean(ntl_mean, na.rm = TRUE),
    sd_ntl = sd(ntl_mean, na.rm = TRUE),
    mean_intensity = mean(intensity_regional, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# ============================================================================
# 5. Save analysis dataset
# ============================================================================
cat("\n=== Saving analysis dataset ===\n")

write.csv(panel, file.path(data_dir, "analysis_panel.csv"), row.names = FALSE)
cat(sprintf("  Saved: %d observations\n", nrow(panel)))

# Save district-level treatment data for diagnostics
write.csv(district_treatment,
          file.path(data_dir, "district_treatment.csv"), row.names = FALSE)
cat(sprintf("  Saved district treatment: %d districts\n", nrow(district_treatment)))

cat("\nData cleaning complete.\n")
