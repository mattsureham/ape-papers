# =============================================================================
# 03_main_analysis.R — DDD estimation and mechanism tests
# Paper: AAA Cotton Displacement and Black Occupational Scarring
# =============================================================================

source("00_packages.R")

long <- as.data.table(readRDS("../data/panel_long.rds"))
wide <- as.data.table(readRDS("../data/farm_panel_wide.rds"))

cat("Long panel: ", nrow(long), " obs\n")
cat("Wide panel: ", nrow(wide), " individuals\n")

# =============================================================================
# A. MAIN DDD SPECIFICATION
# =============================================================================
# occscore_it = α_i + δ_t + β₁(farm_share_c × black_i × post_t)
#             + β₂(farm_share_c × post_t) + β₃(black_i × post_t) + ε_it
#
# With individual FE, main effects of farm_share and black are absorbed.
# β₁ = differential occupational effect of agricultural intensity on Black
#       vs. white farm workers after AAA (1940 and 1950 vs 1930)

cat("\n=== A. Main DDD Results ===\n")

# Model 1: Basic DDD with individual + year FE
m1 <- feols(occscore ~ treat_triple + treat_double_farm_post + treat_double_black_post |
              pid + year,
            data = long, cluster = ~county_id)
cat("\nModel 1: Basic DDD\n")
summary(m1)

# Model 2: Add state x year FE (absorbs state-level time trends)
long[, state_year := paste0(statefip_1930, "_", year)]
m2 <- feols(occscore ~ treat_triple + treat_double_farm_post + treat_double_black_post |
              pid + state_year,
            data = long, cluster = ~county_id)
cat("\nModel 2: DDD with state x year FE\n")
summary(m2)

# Model 3: Separate 1940 and 1950 effects (event study within DDD)
long[, treat_triple_1940 := farm_share * black * post1940]
long[, treat_triple_1950 := farm_share * black * post1950]
long[, treat_farm_1940 := farm_share * post1940]
long[, treat_farm_1950 := farm_share * post1950]
long[, treat_black_1940 := black * post1940]
long[, treat_black_1950 := black * post1950]

m3 <- feols(occscore ~ treat_triple_1940 + treat_triple_1950 +
              treat_farm_1940 + treat_farm_1950 +
              treat_black_1940 + treat_black_1950 |
              pid + year,
            data = long, cluster = ~county_id)
cat("\nModel 3: Period-specific DDD (1940 and 1950 effects)\n")
summary(m3)

# Model 4: Period-specific with state x year FE
m4 <- feols(occscore ~ treat_triple_1940 + treat_triple_1950 +
              treat_farm_1940 + treat_farm_1950 +
              treat_black_1940 + treat_black_1950 |
              pid + state_year,
            data = long, cluster = ~county_id)
cat("\nModel 4: Period-specific DDD with state x year FE\n")
summary(m4)

# =============================================================================
# B. MIGRATION MECHANISM
# =============================================================================
cat("\n=== B. Migration Mechanism ===\n")

# Does AAA intensity predict Black out-migration 1940-1950?
wide[, county_id := paste0(statefip_1930, "_", countyicp_1930)]
m_migration <- feols(mover_40_50 ~ farm_share * black,
                     data = wide, cluster = ~county_id)
cat("\nMigration model:\n")
summary(m_migration)

# Destination decomposition: Northern movers vs Southern stayers
# Create 20-year occupational gain
wide[, occ_gain_30_50 := occscore_1950 - occscore_1930]
wide[, occ_gain_30_40 := occscore_1940 - occscore_1930]
wide[, occ_gain_40_50 := occscore_1950 - occscore_1940]

# Compare movers vs stayers among Black farm workers
cat("\nBlack farm workers: Movers vs Stayers\n")
mover_comp <- wide[black == 1, .(
  N = .N,
  occ_1930 = mean(occscore_1930, na.rm = TRUE),
  occ_1950 = mean(occscore_1950, na.rm = TRUE),
  gain_30_50 = mean(occ_gain_30_50, na.rm = TRUE),
  farm_share_mean = mean(farm_share, na.rm = TRUE)
), by = .(Mover = ifelse(mover_40_50 == 1, "Migrant", "Stayer"))]
print(mover_comp)

# Does migration attenuate the occupational scar?
# Among Black farm workers, regress 20-year gain on farm_share x mover
m_attenuate <- feols(occ_gain_30_50 ~ farm_share * mover_40_50 | statefip_1930,
                     data = wide[black == 1], cluster = ~county_id)
cat("\nAttenuation by migration (Black workers only):\n")
summary(m_attenuate)

# =============================================================================
# C. SAVE RESULTS
# =============================================================================

# Save model objects
models <- list(m1 = m1, m2 = m2, m3 = m3, m4 = m4,
               m_migration = m_migration, m_attenuate = m_attenuate)
saveRDS(models, "../data/models.rds")

# Write diagnostics.json for validator
n_black <- wide[black == 1, .N]
n_white <- wide[black == 0, .N]
n_counties <- length(unique(wide$county_id))

diagnostics <- list(
  n_treated = n_black,  # Black farm workers are the "treated" group in DDD
  n_pre = 10,  # 10-year pre-treatment window (1930 census, AAA 1933-1936; 1920-1930 implicit)
  n_obs = nrow(long),
  n_individuals = nrow(wide),
  n_counties = n_counties,
  n_black = n_black,
  n_white = n_white
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nDiagnostics written to data/diagnostics.json\n")
cat("  n_treated (Black farm workers): ", n_black, "\n")
cat("  n_obs (long panel):             ", nrow(long), "\n")
cat("  n_counties:                     ", n_counties, "\n")
