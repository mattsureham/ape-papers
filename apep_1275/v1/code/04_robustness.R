# 04_robustness.R — Robustness checks for Pakistan 2022 Floods paper

source("00_packages.R")

data_dir <- "../data"

# ============================================================================
# 1. Load data
# ============================================================================
cat("=== Loading analysis panel ===\n")

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
panel[, tehsil_id := as.factor(tehsil_id)]
panel[, season_year := as.factor(season_year)]
panel[, district := as.factor(district)]

cat("  Panel:", nrow(panel), "observations\n")

# ============================================================================
# 2. Placebo test: 2020 as fake treatment year
# ============================================================================
cat("\n=== Placebo Test: 2020 as Fake Treatment Year ===\n")

# Use only pre-2022 data
panel_pre <- panel[year <= 2021]

# Create placebo post indicator (2020 kharif onward)
panel_pre[, placebo_post := as.integer(
  (season_type == "kharif" & year >= 2020) |
  (season_type == "rabi" & year >= 2020)
)]

panel_pre[, placebo_flood_x_post := pct_flooded * placebo_post]
panel_pre[, placebo_flood_sq_x_post := (pct_flooded^2) * placebo_post]

placebo_lin <- fixest::feols(
  ndvi_mean ~ placebo_flood_x_post | tehsil_id + season_year,
  data = panel_pre, cluster = ~district
)

placebo_quad <- fixest::feols(
  ndvi_mean ~ placebo_flood_x_post + placebo_flood_sq_x_post | tehsil_id + season_year,
  data = panel_pre, cluster = ~district
)

cat("  Placebo linear (should be null):\n")
print(summary(placebo_lin))
cat("\n  Placebo quadratic (should be null):\n")
print(summary(placebo_quad))

# ============================================================================
# 3. Province-specific time trends
# ============================================================================
cat("\n=== Province-Specific Time Trends ===\n")

# Add province-specific linear trends
panel[, time_idx := as.integer(factor(season_year))]
panel[, prov_id := as.integer(factor(province))]

trend_model <- fixest::feols(
  ndvi_mean ~ flood_x_post + flood_sq_x_post + i(prov_id, time_idx) |
    tehsil_id + season_year,
  data = panel, cluster = ~district
)

cat("  With province trends:\n")
print(summary(trend_model, keep = c("flood_x_post", "flood_sq_x_post")))

# ============================================================================
# 4. Drop extreme flooded units (>95% flooded)
# ============================================================================
cat("\n=== Drop Extreme Floods (>95% flooded) ===\n")

panel_trim <- panel[pct_flooded <= 95]

trim_model <- fixest::feols(
  ndvi_mean ~ flood_x_post + flood_sq_x_post | tehsil_id + season_year,
  data = panel_trim, cluster = ~district
)

cat("  Trimmed sample:\n")
print(summary(trim_model))

# ============================================================================
# 5. Leave-one-province-out
# ============================================================================
cat("\n=== Leave-One-Province-Out ===\n")

provinces <- unique(panel$province)
lopo_results <- data.table::data.table(
  dropped_province = character(),
  beta_linear = numeric(),
  se_linear = numeric(),
  beta_quad = numeric(),
  se_quad = numeric()
)

for (prov in provinces) {
  panel_sub <- panel[province != prov]
  m <- fixest::feols(
    ndvi_mean ~ flood_x_post + flood_sq_x_post | tehsil_id + season_year,
    data = panel_sub, cluster = ~district
  )
  coefs <- coef(m)
  ses <- sqrt(diag(vcov(m)))

  lopo_results <- rbind(lopo_results, data.table::data.table(
    dropped_province = prov,
    beta_linear = coefs["flood_x_post"],
    se_linear = ses["flood_x_post"],
    beta_quad = coefs["flood_sq_x_post"],
    se_quad = ses["flood_sq_x_post"]
  ))
}

cat("  Leave-one-province-out results:\n")
print(lopo_results)

# ============================================================================
# 6. Alternative clustering: province level
# ============================================================================
cat("\n=== Alternative Clustering ===\n")

alt_cluster <- fixest::feols(
  ndvi_mean ~ flood_x_post + flood_sq_x_post | tehsil_id + season_year,
  data = panel, cluster = ~province
)

cat("  Province-level clustering:\n")
print(summary(alt_cluster))

# ============================================================================
# 7. Using max NDVI instead of mean (robustness to cloud contamination)
# ============================================================================
cat("\n=== Alternative Outcome: Max NDVI ===\n")

panel[, flood_x_post_max := pct_flooded * post]
panel[, flood_sq_x_post_max := (pct_flooded^2) * post]

max_model <- fixest::feols(
  ndvi_max ~ flood_x_post_max + flood_sq_x_post_max | tehsil_id + season_year,
  data = panel, cluster = ~district
)

cat("  Max NDVI model:\n")
print(summary(max_model))

# ============================================================================
# 8. Save robustness results
# ============================================================================
cat("\n=== Saving robustness results ===\n")

robust_results <- list(
  placebo_lin = placebo_lin,
  placebo_quad = placebo_quad,
  trend_model = trend_model,
  trim_model = trim_model,
  lopo_results = lopo_results,
  alt_cluster = alt_cluster,
  max_model = max_model
)

saveRDS(robust_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
