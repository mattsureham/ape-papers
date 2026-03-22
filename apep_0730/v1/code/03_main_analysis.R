# 03_main_analysis.R — Main RDD analysis
# apep_0730: Time Zone Boundaries and Teen Morning Traffic Deaths

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

cat("=== Loading cleaned data ===\n")
df <- fread("fars_cleaned.csv")

# ============================================================
# 1. COUNTY-YEAR PANEL CONSTRUCTION
# ============================================================
# Aggregate crashes to county-year level for rate-based RDD
# This avoids the binary-outcome issue at crash level

cat("=== Building county-year panel ===\n")

# Compute county centroids from crash data (median lat/lon)
county_geo <- df[, .(
  county_lon = median(lon, na.rm = TRUE),
  county_lat = median(lat, na.rm = TRUE)
), by = fips]

# Assign each county to nearest TZ boundary
county_geo[, `:=`(
  dist_EC = county_lon - (-86.5),
  dist_CM = county_lon - (-104.05),
  dist_MP = county_lon - (-115.0)
)]
county_geo[, nearest_boundary := ifelse(
  abs(dist_EC) <= abs(dist_CM) & abs(dist_EC) <= abs(dist_MP), "EC",
  ifelse(abs(dist_CM) <= abs(dist_MP), "CM", "MP")
)]
county_geo[, dist_to_boundary := ifelse(
  nearest_boundary == "EC", dist_EC,
  ifelse(nearest_boundary == "CM", dist_CM, dist_MP)
)]
county_geo[, late_sunset := as.integer(dist_to_boundary < 0)]
county_geo[, dist_km := dist_to_boundary * 85]

# Count crashes by county-year-time_period
county_year <- df[, .(
  total_fatal = .N,
  morning_fatal = sum(morning),
  evening_fatal = sum(evening),
  teen_morning_fatal = sum(teen_morning_fatal),
  teen_fatal = sum(teen_fatal),
  adult_morning_fatal = sum(morning == 1 & n_adult_fatal > 0),
  weekend_morning_fatal = sum(morning == 1 & weekend == 1),
  weekday_morning_fatal = sum(morning == 1 & weekend == 0)
), by = .(fips, YEAR)]

# Merge geography
county_year <- merge(county_year, county_geo, by = "fips", all.x = TRUE)

# Merge population
pop <- fread("county_population.csv")
pop[, fips := paste0(state, county)]

# Map FARS years to nearest ACS year
county_year[, acs_year := fcase(
  YEAR <= 2016, 2014,
  YEAR <= 2021, 2019,
  default = 2023
)]
pop[, fips := as.character(fips)]
county_year[, fips := as.character(fips)]
county_year <- merge(county_year, pop[, .(fips, acs_year, total_pop, teen_pop)],
                     by = c("fips", "acs_year"), all.x = TRUE)

# Create per-capita rates (per 100,000)
county_year[total_pop > 0, `:=`(
  morning_rate = morning_fatal / total_pop * 100000,
  teen_morning_rate = teen_morning_fatal / teen_pop * 100000,
  evening_rate = evening_fatal / total_pop * 100000,
  total_rate = total_fatal / total_pop * 100000
)]

# RDD sample: counties within ±1.5° of a TZ boundary
bandwidth_deg <- 1.5
rdd_county <- county_year[abs(dist_to_boundary) <= bandwidth_deg & !is.na(total_pop)]

cat(sprintf("County-year panel: %d observations\n", nrow(rdd_county)))
cat(sprintf("Unique counties: %d\n", uniqueN(rdd_county$fips)))
cat(sprintf("Counties within ±%.1f° (±%.0fkm): %d county-years\n",
            bandwidth_deg, bandwidth_deg * 85, nrow(rdd_county)))

# ============================================================
# 2. MAIN RDD: CRASH-LEVEL (ALL-AGE MORNING FATALITIES)
# ============================================================
cat("\n=== Main RDD: All-age morning fatalities (crash-level) ===\n")

# Restrict to crashes near boundaries
rdd_df <- df[abs(dist_to_boundary) <= bandwidth_deg]

# RDD using rdrobust: morning fatality indicator
# Running variable: distance to boundary (degrees longitude)
# Treatment: late_sunset (west of boundary)
cat("Running crash-level RDD (morning indicator)...\n")

rdd_morning <- rdrobust(
  y = rdd_df$morning,
  x = rdd_df$dist_to_boundary,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd"
)
cat("Morning fatality RDD:\n")
summary(rdd_morning)

# ============================================================
# 3. COUNTY-LEVEL RDD: MORNING FATALITY RATE
# ============================================================
cat("\n=== County-level RDD: Morning fatality rate ===\n")

# Collapse to county means (pooling years for power)
county_means <- rdd_county[, .(
  morning_rate = mean(morning_rate, na.rm = TRUE),
  evening_rate = mean(evening_rate, na.rm = TRUE),
  teen_morning_rate = mean(teen_morning_rate, na.rm = TRUE),
  total_rate = mean(total_rate, na.rm = TRUE),
  total_pop = mean(total_pop, na.rm = TRUE),
  morning_fatal = sum(morning_fatal),
  teen_morning_fatal = sum(teen_morning_fatal),
  evening_fatal = sum(evening_fatal),
  n_years = .N
), by = .(fips, dist_to_boundary, late_sunset, nearest_boundary, dist_km)]

county_means <- county_means[!is.na(morning_rate) & is.finite(morning_rate)]

cat(sprintf("County means: %d counties\n", nrow(county_means)))

# Main RDD on county-level morning fatality rate
rdd_county_morning <- rdrobust(
  y = county_means$morning_rate,
  x = county_means$dist_to_boundary,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd"
)
cat("County-level morning fatality rate RDD:\n")
summary(rdd_county_morning)

# Falsification: Evening fatality rate (should show NO discontinuity)
rdd_county_evening <- rdrobust(
  y = county_means$evening_rate,
  x = county_means$dist_to_boundary,
  c = 0,
  kernel = "triangular",
  bwselect = "mserd"
)
cat("\nFalsification: Evening fatality rate RDD:\n")
summary(rdd_county_evening)

# ============================================================
# 4. TEEN-SPECIFIC RDD
# ============================================================
cat("\n=== Teen-specific RDD ===\n")

# Teen morning fatality rate
county_teen <- county_means[teen_morning_rate > 0 & is.finite(teen_morning_rate)]

if (nrow(county_teen) >= 50) {
  rdd_teen <- rdrobust(
    y = county_teen$teen_morning_rate,
    x = county_teen$dist_to_boundary,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
  cat("Teen morning fatality rate RDD:\n")
  summary(rdd_teen)
} else {
  cat(sprintf("Warning: Only %d counties with nonzero teen morning fatalities.\n", nrow(county_teen)))
  cat("Running teen analysis on crash-level data instead.\n")

  teen_crashes <- rdd_df[teen_fatal == 1]
  if (nrow(teen_crashes) >= 100) {
    rdd_teen <- rdrobust(
      y = teen_crashes$morning,
      x = teen_crashes$dist_to_boundary,
      c = 0,
      kernel = "triangular",
      bwselect = "mserd"
    )
    summary(rdd_teen)
  }
}

# ============================================================
# 4B. TEEN CRASH-LEVEL RDD
# ============================================================
cat("\n=== Teen crash-level RDD ===\n")

# Among all crashes with at least one teen fatality, test if morning share differs
teen_crashes <- rdd_df[teen_fatal == 1]
cat(sprintf("Teen fatal crashes near boundaries: %d\n", nrow(teen_crashes)))
cat(sprintf("  of which morning: %d\n", sum(teen_crashes$morning)))

if (nrow(teen_crashes) >= 100) {
  rdd_teen_crash <- rdrobust(
    y = teen_crashes$morning,
    x = teen_crashes$dist_to_boundary,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  )
  cat("Teen crash-level RDD (morning indicator among teen-fatal crashes):\n")
  summary(rdd_teen_crash)
} else {
  cat("Insufficient teen crashes for crash-level RDD.\n")
  rdd_teen_crash <- NULL
}

# Age interaction: full sample with teen interaction
rdd_df[, teen_involved := as.integer(teen_fatal == 1)]
cat("\n=== All-age vs Teen comparison (crash-level) ===\n")
cat(sprintf("Baseline morning share (all crashes): %.3f\n", mean(rdd_df$morning)))
cat(sprintf("Baseline morning share (teen-fatal crashes): %.3f\n", mean(teen_crashes$morning)))

# ============================================================
# 4C. MINIMUM DETECTABLE EFFECTS
# ============================================================
cat("\n=== Minimum Detectable Effects ===\n")

# For crash-level RDD: MDE at 80% power
# MDE = (z_alpha + z_beta) * SE = (1.96 + 0.84) * SE = 2.8 * SE
se_crash <- rdd_morning$se[3]  # robust SE
mde_crash <- 2.8 * se_crash
baseline_morning <- mean(rdd_df$morning)
mde_pct <- mde_crash / baseline_morning * 100

cat(sprintf("Crash-level RDD:\n"))
cat(sprintf("  Robust SE: %.4f\n", se_crash))
cat(sprintf("  MDE (80%% power): %.4f (= %.1f%% of baseline %.3f)\n",
            mde_crash, mde_pct, baseline_morning))

# For teen-specific
if (!is.null(rdd_teen_crash)) {
  se_teen <- rdd_teen_crash$se[3]
  mde_teen <- 2.8 * se_teen
  baseline_teen_morning <- mean(teen_crashes$morning)
  mde_teen_pct <- mde_teen / baseline_teen_morning * 100
  cat(sprintf("Teen crash-level RDD:\n"))
  cat(sprintf("  Robust SE: %.4f\n", se_teen))
  cat(sprintf("  MDE (80%% power): %.4f (= %.1f%% of baseline %.3f)\n",
              mde_teen, mde_teen_pct, baseline_teen_morning))
}

# ============================================================
# 5. McCRARY DENSITY TEST
# ============================================================
cat("\n=== McCrary density test ===\n")

density_test <- rddensity(X = rdd_df$dist_to_boundary, c = 0)
cat("McCrary density test:\n")
summary(density_test)

# ============================================================
# 6. PARAMETRIC SPECIFICATIONS (for table)
# ============================================================
cat("\n=== Parametric specifications ===\n")

# County-year panel regressions with FE
# Specification 1: Linear polynomial, no controls
spec1 <- feols(morning_rate ~ late_sunset * dist_to_boundary |
                 YEAR + nearest_boundary,
               data = rdd_county,
               cluster = ~fips)

# Specification 2: Quadratic polynomial
rdd_county[, dist_sq := dist_to_boundary^2]
spec2 <- feols(morning_rate ~ late_sunset * dist_to_boundary +
                 late_sunset * dist_sq |
                 YEAR + nearest_boundary,
               data = rdd_county,
               cluster = ~fips)

# Specification 3: Linear, narrower bandwidth (±1°)
narrow <- rdd_county[abs(dist_to_boundary) <= 1.0]
spec3 <- feols(morning_rate ~ late_sunset * dist_to_boundary |
                 YEAR + nearest_boundary,
               data = narrow,
               cluster = ~fips)

# Specification 4: Falsification — evening rate
spec4 <- feols(evening_rate ~ late_sunset * dist_to_boundary |
                 YEAR + nearest_boundary,
               data = rdd_county,
               cluster = ~fips)

cat("\n--- Parametric Results ---\n")
cat("Spec 1 (Linear, ±1.5°):\n")
print(summary(spec1))
cat("\nSpec 2 (Quadratic, ±1.5°):\n")
print(summary(spec2))
cat("\nSpec 3 (Linear, ±1.0°):\n")
print(summary(spec3))
cat("\nSpec 4 (Evening falsification):\n")
print(summary(spec4))

# ============================================================
# 7. SAVE RESULTS AND DIAGNOSTICS
# ============================================================

# Store key results
results <- list(
  rdd_morning = rdd_morning,
  rdd_county_morning = rdd_county_morning,
  rdd_county_evening = rdd_county_evening,
  rdd_teen_crash = rdd_teen_crash,
  density_test = density_test,
  spec1 = spec1,
  spec2 = spec2,
  spec3 = spec3,
  spec4 = spec4,
  mde_crash = mde_crash,
  mde_pct = mde_pct,
  baseline_morning = baseline_morning,
  mde_teen = if (!is.null(rdd_teen_crash)) mde_teen else NA,
  mde_teen_pct = if (!is.null(rdd_teen_crash)) mde_teen_pct else NA,
  baseline_teen_morning = if (!is.null(rdd_teen_crash)) baseline_teen_morning else NA
)
saveRDS(results, "main_results.rds")

# Diagnostics for validator
n_treated <- uniqueN(rdd_county[late_sunset == 1]$fips)
n_control <- uniqueN(rdd_county[late_sunset == 0]$fips)
n_pre <- 14  # years of data (cross-sectional RDD, not DiD)
n_obs <- nrow(rdd_county)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_control = n_control,
  n_crashes_rdd = nrow(rdd_df),
  n_morning_crashes = sum(rdd_df$morning),
  n_teen_morning_fatal = sum(rdd_df$teen_morning_fatal),
  rdd_bandwidth_opt = rdd_county_morning$bws[1, 1],
  rdd_coef = rdd_county_morning$coef[1],
  rdd_pval = rdd_county_morning$pv[1]
)

jsonlite::write_json(diagnostics, "diagnostics.json", auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
cat(sprintf("Key result: Morning fatality rate discontinuity = %.3f (p = %.3f)\n",
            rdd_county_morning$coef[1], rdd_county_morning$pv[1]))
cat(sprintf("Falsification (evening): discontinuity = %.3f (p = %.3f)\n",
            rdd_county_evening$coef[1], rdd_county_evening$pv[1]))
