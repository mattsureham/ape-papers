## 04_robustness.R — Robustness checks: radius, brownfield, LOSO, HonestDiD
## apep_1143: Solar Footprint

source("./code/00_packages.R")

DATA_DIR <- "./data"

# Load base data
panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, route_num := as.integer(factor(route_id))]
panel[, state_num := as.integer(sub("_.*", "", route_id))]
panel[, ln_farm := log(total_count_farmland + 1)]

# Load USPVDB and routes for re-matching at different radii
uspvdb <- fread(file.path(DATA_DIR, "uspvdb_v3_0_20250430.csv"))
routes <- fread(file.path(DATA_DIR, "Routes.csv"))
routes_us <- routes[CountryNum == 840]
routes_us[, route_id := paste0(StateNum, "_", Route)]

# Project coordinates
routes_sf <- st_as_sf(routes_us, coords = c("Longitude", "Latitude"), crs = 4326)
solar_sf <- st_as_sf(uspvdb[!is.na(ylat) & !is.na(xlong)],
                      coords = c("xlong", "ylat"), crs = 4326)
routes_proj <- st_transform(routes_sf, 5070)
solar_proj <- st_transform(solar_sf, 5070)
route_coords <- st_coordinates(routes_proj)
solar_coords <- st_coordinates(solar_proj)

# ============================================================
# 1. Radius variation: 5 km and 20 km
# ============================================================
cat("\n=== RADIUS VARIATION ===\n")

for (radius_km in c(5, 20)) {
  radius_m <- radius_km * 1000
  cat(sprintf("\n--- %d km radius ---\n", radius_km))

  # Find treated routes at this radius
  treated_routes <- character(0)
  for (i in 1:nrow(route_coords)) {
    dx <- solar_coords[, 1] - route_coords[i, 1]
    dy <- solar_coords[, 2] - route_coords[i, 2]
    dist <- sqrt(dx^2 + dy^2)
    if (any(dist <= radius_m)) {
      treated_routes <- c(treated_routes, routes_us$route_id[i])
    }
  }

  cat("Treated routes:", length(treated_routes), "\n")

  # Create binary treatment
  panel_r <- copy(panel)
  panel_r[, treated_r := as.integer(route_id %in% treated_routes)]

  # Simple TWFE
  twfe_r <- fixest::feols(
    ln_farm ~ treated_r:post | route_num + year,
    data = panel_r,
    cluster = ~state_num
  )
  cat(sprintf("TWFE: coef=%.4f, SE=%.4f, t=%.2f\n",
              coef(twfe_r)[1], sqrt(vcov(twfe_r)[1,1]),
              coef(twfe_r)[1] / sqrt(vcov(twfe_r)[1,1])))
}

# ============================================================
# 2. Brownfield placebo
# ============================================================
cat("\n=== BROWNFIELD PLACEBO ===\n")

# Separate greenfield and brownfield solar
green_solar <- uspvdb[p_type == "greenfield" & !is.na(ylat)]
brown_solar <- uspvdb[p_type %in% c("landfill", "RCRA", "AML", "superfund", "PCSC", "landfill named")
                       & !is.na(ylat)]
cat("Greenfield facilities:", nrow(green_solar), "\n")
cat("Brownfield/landfill:", nrow(brown_solar), "\n")

# Find routes near ONLY brownfield (not greenfield)
brown_sf <- st_as_sf(brown_solar, coords = c("xlong", "ylat"), crs = 4326)
brown_proj <- st_transform(brown_sf, 5070)
brown_coords <- st_coordinates(brown_proj)

brown_routes <- character(0)
for (i in 1:nrow(route_coords)) {
  dx <- brown_coords[, 1] - route_coords[i, 1]
  dy <- brown_coords[, 2] - route_coords[i, 2]
  dist <- sqrt(dx^2 + dy^2)
  if (any(dist <= 10000)) {
    brown_routes <- c(brown_routes, routes_us$route_id[i])
  }
}
# Exclude routes also near greenfield
green_proj_coords <- st_coordinates(st_transform(
  st_as_sf(green_solar, coords = c("xlong", "ylat"), crs = 4326), 5070))
green_routes <- character(0)
for (i in 1:nrow(route_coords)) {
  dx <- green_proj_coords[, 1] - route_coords[i, 1]
  dy <- green_proj_coords[, 2] - route_coords[i, 2]
  dist <- sqrt(dx^2 + dy^2)
  if (any(dist <= 10000)) {
    green_routes <- c(green_routes, routes_us$route_id[i])
  }
}
brown_only <- setdiff(brown_routes, green_routes)
cat("Routes near brownfield only (10km):", length(brown_only), "\n")

if (length(brown_only) >= 10) {
  panel_b <- copy(panel)
  panel_b[, treated_b := as.integer(route_id %in% brown_only)]
  twfe_b <- fixest::feols(
    ln_farm ~ treated_b:post | route_num + year,
    data = panel_b,
    cluster = ~state_num
  )
  cat(sprintf("Brownfield TWFE: coef=%.4f, SE=%.4f, t=%.2f\n",
              coef(twfe_b)[1], sqrt(vcov(twfe_b)[1,1]),
              coef(twfe_b)[1] / sqrt(vcov(twfe_b)[1,1])))
} else {
  cat("Too few brownfield-only routes for analysis\n")
}

# ============================================================
# 3. Leave-one-state-out (LOSO)
# ============================================================
cat("\n=== LOSO JACKKNIFE ===\n")
states <- sort(unique(panel$state_num))
loso_coefs <- numeric(length(states))
for (j in seq_along(states)) {
  sub <- panel[state_num != states[j]]
  sub[, rn := as.integer(factor(route_id))]
  m <- fixest::feols(ln_farm ~ post | rn + year, data = sub, cluster = ~state_num)
  loso_coefs[j] <- coef(m)["post"]
}
cat("LOSO coefficient range:", round(range(loso_coefs), 4), "\n")
cat("LOSO mean:", round(mean(loso_coefs), 4), "\n")
cat("LOSO SD:", round(sd(loso_coefs), 4), "\n")

# ============================================================
# 4. Quantify bound: what decline can we rule out?
# ============================================================
cat("\n=== POWER / BOUND ANALYSIS ===\n")
# Main TWFE with state×year: -0.053 (SE=0.032)
# 95% CI upper bound: -0.053 + 1.96*0.032 = 0.0097
# 95% CI lower bound: -0.053 - 1.96*0.032 = -0.1157

# In farmland bird count terms:
mean_ln <- panel[, mean(ln_farm, na.rm=TRUE)]
mean_count <- panel[, mean(total_count_farmland, na.rm=TRUE)]
sd_count <- panel[, sd(total_count_farmland, na.rm=TRUE)]

# The 95% CI for the TWFE binary coefficient is approximately [-0.10, 0.01]
# In proportional terms: exp(-0.053) - 1 = -5.2% (point estimate)
# Lower bound: exp(-0.10) - 1 = -9.5%
# Upper bound: exp(0.01) - 1 = +1.0%

cat("TWFE point estimate (log): -0.053\n")
cat("  Proportional change: ", round((exp(-0.053) - 1) * 100, 1), "%\n")
cat("  95% CI lower (proportional): ", round((exp(-0.053 - 1.96*0.032) - 1) * 100, 1), "%\n")
cat("  95% CI upper (proportional): ", round((exp(-0.053 + 1.96*0.032) - 1) * 100, 1), "%\n")
cat("  Mean farmland count:", round(mean_count, 1), "\n")
cat("  SD farmland count:", round(sd_count, 1), "\n")

# Save robustness results
rob <- list(
  radius_tested = c(5, 10, 20),
  loso_range = range(loso_coefs),
  loso_mean = mean(loso_coefs),
  prop_change_pct = round((exp(-0.053) - 1) * 100, 1),
  ci_lower_pct = round((exp(-0.053 - 1.96*0.032) - 1) * 100, 1),
  ci_upper_pct = round((exp(-0.053 + 1.96*0.032) - 1) * 100, 1)
)
jsonlite::write_json(rob, file.path(DATA_DIR, "robustness_results.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("\n=== ROBUSTNESS COMPLETE ===\n")
