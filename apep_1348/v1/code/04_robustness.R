# 04_robustness.R — Robustness checks
# apep_1348: Groningen Regulatory Rebound

source("00_packages.R")

data_dir <- "../data/"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("=== Robustness Checks ===\n")

# ============================================================
# 1. Placebo Epicenters
# ============================================================
cat("\nRunning placebo epicenter tests...\n")

set.seed(20260403)

# Generate 500 random epicenters within the Netherlands
# Netherlands bbox: lat 50.75-53.47, lon 3.36-7.21
n_placebos <- 500
placebo_lats <- runif(n_placebos, 50.75, 53.47)
placebo_lons <- runif(n_placebos, 3.36, 7.21)

centroids <- readRDS(file.path(data_dir, "municipality_centroids.rds"))

# Transform from RD New to WGS84 if needed
if (max(centroids$lon, na.rm = TRUE) > 180) {
  centroids_sf <- st_as_sf(centroids, coords = c("lon", "lat"), crs = 28992)
  centroids_sf <- st_transform(centroids_sf, 4326)
  centroids$lon <- st_coordinates(centroids_sf)[, 1]
  centroids$lat <- st_coordinates(centroids_sf)[, 2]
}

# For each placebo, compute the treatment effect
placebo_coefs <- numeric(n_placebos)
for (i in seq_len(n_placebos)) {
  # Compute distance to placebo epicenter
  placebo_dist <- geosphere::distHaversine(
    cbind(centroids$lon, centroids$lat),
    c(placebo_lons[i], placebo_lats[i])
  ) / 1000

  # Create treatment intensity
  centroids_tmp <- centroids %>%
    mutate(
      placebo_intensity = 1 / placebo_dist,
      gem_code = ifelse(grepl("^GM", gem_code), gem_code, paste0("GM", gem_code))
    )

  panel_tmp <- panel %>%
    left_join(
      centroids_tmp %>% select(gem_code, placebo_intensity),
      by = c("region_code" = "gem_code")
    )

  if (any(is.na(panel_tmp$placebo_intensity))) next

  m <- tryCatch(
    feols(
      log_price ~ post_huizinge:placebo_intensity | region_code + year,
      data = panel_tmp, cluster = ~region_code
    ),
    error = function(e) NULL
  )

  if (!is.null(m)) {
    placebo_coefs[i] <- coef(m)[1]
  }
}

placebo_coefs <- placebo_coefs[placebo_coefs != 0]
cat(sprintf("  Completed %d placebo regressions\n", length(placebo_coefs)))

# Get real coefficient for comparison
models <- readRDS(file.path(data_dir, "models.rds"))
real_coef <- coef(models$did1)[1]

# P-value: fraction of placebos with |coef| >= |real coef|
placebo_pval <- mean(abs(placebo_coefs) >= abs(real_coef))
cat(sprintf("  Real coefficient: %.4f\n", real_coef))
cat(sprintf("  Placebo p-value: %.3f\n", placebo_pval))

saveRDS(list(coefs = placebo_coefs, real = real_coef, pval = placebo_pval),
        file.path(data_dir, "placebo_results.rds"))

# ============================================================
# 2. Pre-trend Test (formal)
# ============================================================
cat("\nFormal pre-trend test...\n")

panel_pre <- panel %>% filter(year <= 2012)

pre_trend <- feols(
  log_price ~ i(year, treat_intensity) | region_code + year,
  data = panel_pre,
  cluster = ~region_code
)

# Joint F-test of all pre-period interactions
pre_ftest <- wald(pre_trend)
cat(sprintf("  Joint pre-trend F-test p-value: %.4f\n", pre_ftest$p))

saveRDS(list(model = pre_trend, ftest = pre_ftest),
        file.path(data_dir, "pretrend_results.rds"))

# ============================================================
# 3. Alternative Distance Thresholds
# ============================================================
cat("\nAlternative distance thresholds...\n")

thresholds <- c(15, 25, 30, 40, 75)
threshold_results <- lapply(thresholds, function(d) {
  panel_tmp <- panel %>%
    mutate(treated = as.integer(dist_km <= d))

  m <- feols(
    log_price ~ i(post_huizinge, treated) | region_code + year,
    data = panel_tmp, cluster = ~region_code
  )

  data.frame(
    threshold_km = d,
    coef = coef(m)[1],
    se = se(m)[1],
    n_treated = n_distinct(panel_tmp$region_code[panel_tmp$treated == 1])
  )
}) %>% bind_rows()

cat("  Distance threshold results:\n")
print(threshold_results)

saveRDS(threshold_results, file.path(data_dir, "threshold_robustness.rds"))

# ============================================================
# 4. Leave-One-Out (Province Level)
# ============================================================
cat("\nLeave-one-out by province...\n")

# Assign provinces based on distance bins (approximation)
# Groningen province municipalities are within ~60km
panel <- panel %>%
  mutate(
    province_approx = case_when(
      dist_km <= 60 ~ "Groningen",
      dist_km <= 80 & lon < 6.5 ~ "Friesland",
      dist_km <= 80 ~ "Drenthe",
      TRUE ~ "Other"
    )
  )

loo_results <- lapply(unique(panel$province_approx), function(prov) {
  panel_loo <- panel %>% filter(province_approx != prov)
  m <- feols(
    log_price ~ post_huizinge:treat_intensity | region_code + year,
    data = panel_loo, cluster = ~region_code
  )
  data.frame(
    dropped = prov,
    coef = coef(m)[1],
    se = se(m)[1]
  )
}) %>% bind_rows()

cat("  Leave-one-out results:\n")
print(loo_results)

saveRDS(loo_results, file.path(data_dir, "loo_results.rds"))

cat("\n=== Robustness checks complete ===\n")
