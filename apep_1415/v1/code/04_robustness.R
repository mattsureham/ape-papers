# 04_robustness.R — Robustness checks and placebo tests
# APEP 1415: Morocco Cannabis Legalization

source("00_packages.R")

data_dir <- "../data/"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("Panel loaded:", nrow(panel), "rows\n")

# =============================================================================
# 1. Placebo treatment year (2019)
# =============================================================================

cat("\n=== Placebo: Treatment year 2019 ===\n")

panel_pre <- panel %>% filter(year <= 2021)
panel_pre$placebo_post <- as.integer(panel_pre$year >= 2019)
panel_pre$placebo_treat <- panel_pre$treated * panel_pre$placebo_post

placebo_2019 <- feols(asinh_nl ~ placebo_treat | cell_id + year_fe,
                      data = panel_pre, cluster = ~adm2_name)
cat("Placebo 2019:\n")
summary(placebo_2019)

# Placebo 2020
panel_pre$placebo_post_2020 <- as.integer(panel_pre$year >= 2020)
panel_pre$placebo_treat_2020 <- panel_pre$treated * panel_pre$placebo_post_2020

placebo_2020 <- feols(asinh_nl ~ placebo_treat_2020 | cell_id + year_fe,
                      data = panel_pre, cluster = ~adm2_name)
cat("\nPlacebo 2020:\n")
summary(placebo_2020)

# =============================================================================
# 2. Alternative bandwidths for spatial RDD
# =============================================================================

cat("\n=== Spatial RDD: alternative bandwidths ===\n")

rdd_post <- panel %>% filter(post == 1, abs(dist_signed_km) <= 80)

for (bw in c(10, 20, 30, 40)) {
  rdd_bw <- rdrobust(
    y = rdd_post$asinh_nl,
    x = rdd_post$dist_signed_km,
    c = 0, h = bw, kernel = "triangular"
  )
  cat("BW =", bw, "km: Est =", round(rdd_bw$coef[1], 3),
      "SE =", round(rdd_bw$se[3], 3),
      "p =", round(rdd_bw$pv[3], 3), "\n")
}

# =============================================================================
# 3. Donut RDD (exclude cells within 5km of boundary)
# =============================================================================

cat("\n=== Donut RDD (exclude within 5km) ===\n")

donut_data <- panel %>%
  filter(post == 1, abs(dist_signed_km) > 5, abs(dist_signed_km) <= 50)

tryCatch({
  donut_rdd <- rdrobust(
    y = donut_data$asinh_nl,
    x = donut_data$dist_signed_km,
    c = 0, kernel = "triangular", bwselect = "mserd",
    masspoints = "adjust"
  )
  cat("Donut RDD estimate:", round(donut_rdd$coef[1], 3),
      "SE:", round(donut_rdd$se[3], 3),
      "p:", round(donut_rdd$pv[3], 3), "\n")
}, error = function(e) {
  cat("Donut RDD could not be estimated:", e$message, "\n")
})

# =============================================================================
# 4. Level outcomes (not transformed)
# =============================================================================

cat("\n=== Level outcomes ===\n")

m_level <- feols(nl_mean ~ treat_post | cell_id + year_fe,
                 data = panel, cluster = ~adm2_name)
cat("Level NL:\n")
summary(m_level)

# =============================================================================
# 5. Exclude outlier cells (top 5% nightlights)
# =============================================================================

cat("\n=== Exclude top 5% nightlight cells ===\n")

mean_nl <- panel %>%
  group_by(cell_id) %>%
  summarize(mean_nl = mean(nl_mean, na.rm = TRUE), .groups = "drop")

cutoff <- quantile(mean_nl$mean_nl, 0.95, na.rm = TRUE)
keep_cells <- mean_nl$cell_id[mean_nl$mean_nl <= cutoff]

panel_trim <- panel %>% filter(cell_id %in% keep_cells)
m_trim <- feols(asinh_nl ~ treat_post | cell_id + year_fe,
                data = panel_trim, cluster = ~adm2_name)
cat("Trimmed sample (excl. top 5%):\n")
summary(m_trim)

# =============================================================================
# 6. Boundary sample only (within 20km of border)
# =============================================================================

cat("\n=== Border sample (within 20km) ===\n")

panel_border <- panel %>% filter(abs(dist_signed_km) <= 20)
m_border <- feols(asinh_nl ~ treat_post | cell_id + year_fe,
                  data = panel_border, cluster = ~adm2_name)
cat("Border 20km:\n")
summary(m_border)

# =============================================================================
# 7. Heterogeneity: urban vs. rural (baseline nightlight intensity)
# =============================================================================

cat("\n=== Heterogeneity: Urban vs. Rural ===\n")

baseline_nl <- panel %>%
  filter(year < 2022) %>%
  group_by(cell_id) %>%
  summarize(baseline_nl = mean(nl_mean, na.rm = TRUE), .groups = "drop")

median_nl <- median(baseline_nl$baseline_nl, na.rm = TRUE)

panel_het <- panel %>%
  left_join(baseline_nl, by = "cell_id") %>%
  mutate(urban = as.integer(baseline_nl > median_nl))

# Urban
m_urban <- feols(asinh_nl ~ treat_post | cell_id + year_fe,
                 data = filter(panel_het, urban == 1), cluster = ~adm2_name)

# Rural
m_rural <- feols(asinh_nl ~ treat_post | cell_id + year_fe,
                 data = filter(panel_het, urban == 0), cluster = ~adm2_name)

cat("Urban (high baseline NL):", round(coef(m_urban), 4), "\n")
cat("Rural (low baseline NL):", round(coef(m_rural), 4), "\n")

# =============================================================================
# 8. Heterogeneity: distance from boundary
# =============================================================================

cat("\n=== Heterogeneity: Distance from boundary ===\n")

panel$near_boundary <- as.integer(abs(panel$dist_signed_km) <= 15)
panel$far_boundary <- as.integer(abs(panel$dist_signed_km) > 15)
panel$treated_near <- panel$treated * panel$near_boundary
panel$treated_far <- panel$treated * panel$far_boundary

m_near <- feols(asinh_nl ~ treat_post | cell_id + year_fe,
                data = filter(panel, treated == 1 | near_boundary == 1),
                cluster = ~adm2_name)

m_dist_int <- feols(asinh_nl ~ treat_post + treat_post:dist_to_boundary_km | cell_id + year_fe,
                    data = panel, cluster = ~adm2_name)

cat("Near boundary (within 15km):", round(coef(m_near)["treat_post"], 4), "\n")
cat("Distance interaction:\n")
summary(m_dist_int)

# =============================================================================
# Save robustness results
# =============================================================================

rob_results <- list(
  placebo_2019 = placebo_2019,
  placebo_2020 = placebo_2020,
  m_level = m_level,
  m_trim = m_trim,
  m_border = m_border,
  m_urban = m_urban,
  m_rural = m_rural,
  m_dist_int = m_dist_int
)

saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))
cat("\nRobustness results saved.\n")
