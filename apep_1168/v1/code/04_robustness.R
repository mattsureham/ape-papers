##############################################################################
# 04_robustness.R — Robustness checks
# apep_1168: Contagious NIMBYism
##############################################################################

source("00_packages.R")
DATA_DIR <- "../data"

load(file.path(DATA_DIR, "regressions.RData"))
# Ensure fips is character everywhere
panel[, fips := as.character(fips)]
if (nchar(panel$fips[1]) < 5) panel[, fips := sprintf("%05d", as.integer(fips))]
panel_no_turb[, fips := as.character(fips)]
if (nchar(panel_no_turb$fips[1]) < 5) panel_no_turb[, fips := sprintf("%05d", as.integer(fips))]
cat("Loaded regression objects. Panel:", nrow(panel), "obs, fips class:", class(panel$fips), "\n")

# ============================================================================
# 1. State × Year FE (absorb state-level trends)
# ============================================================================
cat("\n=== Robustness: State × Year FE ===\n")

r1 <- feols(ordinance_adopted ~ sci_exposure_turbines + geo_exposure_turbines +
              own_turbines |
              fips + state_fips^year,
            data = panel, cluster = ~state_fips)
cat("State × Year FE:\n")
summary(r1)

# ============================================================================
# 2. Logit / Probit for binary outcome
# ============================================================================
cat("\n=== Robustness: Logit ===\n")

# Can't use county FE with logit (perfect prediction), use state FE
r2_logit <- feglm(ordinance_adopted ~ sci_exposure_turbines + geo_exposure_turbines +
                    own_turbines + log_pop + college_share + gop_share |
                    state_fips + year,
                  data = panel[!is.na(gop_share)],
                  family = binomial(link = "logit"),
                  cluster = ~state_fips)
cat("Logit (state FE):\n")
summary(r2_logit)

# ============================================================================
# 3. Distance bins: at what range does geographic exposure matter?
# ============================================================================
cat("\n=== Robustness: Distance-band exposure ===\n")

centroids <- fread(file.path(DATA_DIR, "county_centroids.csv"))
centroids[, fips := sprintf("%05d", as.integer(fips))]

# Construct exposure at different distance bands using DuckDB
con <- dbConnect(duckdb())

# Load turbine panel
turb_data <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
turb_for_db <- unique(turb_data[, .(fips, year, own_turbines)])
centroids_db <- copy(centroids[, .(fips, lon, lat)])
# Ensure consistent types for DuckDB
turb_for_db[, fips_int := as.integer(fips)]
centroids_db[, fips_int := as.integer(fips)]
dbWriteTable(con, "turb_panel", turb_for_db[, .(fips_int, year, own_turbines)])
dbWriteTable(con, "centroids", centroids_db[, .(fips_int, lon, lat)])

# Compute distance-band weighted exposure: 0-100km, 100-200km, 200-500km
cat("  Computing distance-band exposures...\n")
dist_band_exposure <- dbGetQuery(con, "
  WITH dist AS (
    SELECT
      a.fips_int AS fips_i,
      b.fips_int AS fips_j,
      SQRT(
        POWER((b.lon - a.lon) * COS(RADIANS((a.lat + b.lat) / 2)) * 111.32, 2) +
        POWER((b.lat - a.lat) * 111.32, 2)
      ) AS dist_km
    FROM centroids a
    CROSS JOIN centroids b
    WHERE a.fips_int != b.fips_int
      AND ABS(b.lon - a.lon) < 10
      AND ABS(b.lat - a.lat) < 10
  )
  SELECT
    d.fips_i AS fips,
    t.year,
    SUM(CASE WHEN d.dist_km <= 100 THEN t.own_turbines ELSE 0 END) AS turb_0_100km,
    SUM(CASE WHEN d.dist_km > 100 AND d.dist_km <= 200 THEN t.own_turbines ELSE 0 END) AS turb_100_200km,
    SUM(CASE WHEN d.dist_km > 200 AND d.dist_km <= 500 THEN t.own_turbines ELSE 0 END) AS turb_200_500km
  FROM dist d
  JOIN turb_panel t ON d.fips_j = t.fips_int
  WHERE d.dist_km <= 500
  GROUP BY d.fips_i, t.year
")
dbDisconnect(con, shutdown = TRUE)

dist_band <- as.data.table(dist_band_exposure)
# Force fips to 5-digit character to match panel
dist_band[, fips := sprintf("%05d", as.numeric(fips))]
dist_band[, year := as.integer(year)]
cat("  dist_band fips class:", class(dist_band$fips), "| panel fips class:", class(panel$fips), "\n")
panel_db <- merge(panel, dist_band, by = c("fips", "year"), all.x = TRUE)
for (col in c("turb_0_100km", "turb_100_200km", "turb_200_500km")) {
  panel_db[is.na(get(col)), (col) := 0]
}

r3_dist <- feols(ordinance_adopted ~ turb_0_100km + turb_100_200km + turb_200_500km |
                   fips + year,
                 data = panel_db, cluster = ~state_fips)
cat("Distance-band effects:\n")
summary(r3_dist)

# ============================================================================
# 4. Exclude states with state-level siting preemption
# ============================================================================
cat("\n=== Robustness: Exclude preemption states ===\n")

# States that preempt local siting authority (e.g., OR, WA, TX to some extent)
# These states have fewer county-level ordinances by design
preemption_states <- c("41", "53")  # Oregon, Washington — state siting boards
r4 <- feols(ordinance_adopted ~ sci_exposure_turbines + geo_exposure_turbines +
              own_turbines |
              fips + year,
            data = panel[!state_fips %in% preemption_states],
            cluster = ~state_fips)
cat("Excluding preemption states:\n")
summary(r4)

# ============================================================================
# 5. Placebo: use SCI exposure to predict outcomes that shouldn't respond
# ============================================================================
cat("\n=== Placebo: SCI exposure → own turbines (should be null) ===\n")

# SCI-weighted turbines in connected counties shouldn't predict YOUR turbine count
r5_placebo <- feols(own_turbines ~ sci_exposure_turbines |
                      fips + year,
                    data = panel, cluster = ~state_fips)
summary(r5_placebo)

# ============================================================================
# 6. Leave-one-state-out for shift-share
# ============================================================================
cat("\n=== Leave-one-state-out ===\n")

states <- unique(panel$state_fips)
loo_coefs <- data.table(
  state_dropped = character(),
  beta_geo = numeric(),
  se_geo = numeric()
)

for (s in states) {
  m_loo <- feols(ordinance_adopted ~ sci_exposure_turbines + geo_exposure_turbines +
                   own_turbines |
                   fips + year,
                 data = panel[state_fips != s], cluster = ~state_fips,
                 warn = FALSE)
  loo_coefs <- rbind(loo_coefs, data.table(
    state_dropped = s,
    beta_geo = coef(m_loo)["geo_exposure_turbines"],
    se_geo = se(m_loo)["geo_exposure_turbines"]
  ))
}

cat("Leave-one-out geo_exposure range:", range(loo_coefs$beta_geo), "\n")
cat("All positive:", all(loo_coefs$beta_geo > 0), "\n")
cat("Min/Max:", min(loo_coefs$beta_geo), "/", max(loo_coefs$beta_geo), "\n")

# Save robustness objects
save(r1, r2_logit, r3_dist, r4, r5_placebo, loo_coefs, panel_db,
     file = file.path(DATA_DIR, "robustness.RData"))

cat("\nRobustness checks complete.\n")
