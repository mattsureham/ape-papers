# =============================================================================
# 03_main_analysis.R — Main IV and OLS regressions
# apep_1068: Last Hired, Not First Fired
# =============================================================================

source("00_packages.R")

dt <- fread("../data/analysis_sample.csv")
cat(sprintf("Loaded %s observations.\n", format(nrow(dt), big.mark = ",")))

# ============================================================================
# BLACK SAMPLE — Main Analysis
# ============================================================================
black <- dt[black == 1]
cat(sprintf("\nBlack sample: %s observations\n", format(nrow(black), big.mark = ",")))
cat(sprintf("  Migrants: %s\n", format(sum(black$migrant == 1), big.mark = ",")))
cat(sprintf("  Stayers: %s\n", format(sum(black$migrant == 0), big.mark = ",")))

# ---- OLS — Depression-era occupational change ----
cat("\n=== OLS: Depression-Era Occupational Change (Black) ===\n")

ols1 <- feols(occ_change_bust ~ migrant,
              data = black, cluster = ~origin_county)

ols2 <- feols(occ_change_bust ~ migrant + age_1920 + age_sq + in_school +
                farm_orig + married_1920 + occscore_1920,
              data = black, cluster = ~origin_county)

cat("OLS results:\n")
etable(ols1, ols2, se.below = TRUE)

# ---- First Stage ----
cat("\n=== First Stage: Instrument -> Migration ===\n")

fs1 <- feols(migrant ~ log_instrument,
             data = black, cluster = ~origin_county)

fs2 <- feols(migrant ~ log_instrument + age_1920 + age_sq + in_school +
               farm_orig + married_1920 + occscore_1920,
             data = black, cluster = ~origin_county)

cat("First stage:\n")
etable(fs1, fs2, se.below = TRUE)

# F-stat from first stage: t^2 for single instrument
fs2_t <- coef(fs2)["log_instrument"] / se(fs2)["log_instrument"]
fs2_F <- fs2_t^2
cat(sprintf("\nFirst-stage F-stat (preferred): %.1f\n", fs2_F))

# ---- IV/2SLS — Main Results ----
cat("\n=== IV/2SLS: Depression-Era Occupational Resilience ===\n")

iv1 <- feols(occ_change_bust ~ 1 | migrant ~ log_instrument,
             data = black, cluster = ~origin_county)

iv2 <- feols(occ_change_bust ~ age_1920 + age_sq + in_school +
               farm_orig + married_1920 + occscore_1920 | migrant ~ log_instrument,
             data = black, cluster = ~origin_county)

cat("IV results:\n")
etable(iv1, iv2, se.below = TRUE)

# ---- Reduced Form ----
cat("\n=== Reduced Form: Instrument -> Occupational Change ===\n")

rf1 <- feols(occ_change_bust ~ log_instrument + age_1920 + age_sq + in_school +
               farm_orig + married_1920 + occscore_1920,
             data = black, cluster = ~origin_county)
cat("Reduced form:\n")
etable(rf1, se.below = TRUE)

# ============================================================================
# WHITE SAMPLE — Placebo
# ============================================================================
white <- dt[black == 0]
cat(sprintf("\n\n=== PLACEBO: White Sample (%s observations) ===\n",
            format(nrow(white), big.mark = ",")))

# White OLS
ols_w <- feols(occ_change_bust ~ migrant + age_1920 + age_sq + in_school +
                 farm_orig + married_1920 + occscore_1920,
               data = white, cluster = ~origin_county)

# White IV
iv_w <- feols(occ_change_bust ~ age_1920 + age_sq + in_school +
                farm_orig + married_1920 + occscore_1920 |
                migrant ~ log_instrument,
              data = white, cluster = ~origin_county)

cat("White OLS:\n")
etable(ols_w, se.below = TRUE)
cat("White IV:\n")
etable(iv_w, se.below = TRUE)

# ============================================================================
# BOOM PERIOD — Validation (should show positive migration premium)
# ============================================================================
cat("\n=== Validation: 1920s Boom Period ===\n")

boom_ols <- feols(occ_change_boom ~ migrant + age_1920 + age_sq + in_school +
                    farm_orig + married_1920 + occscore_1920,
                  data = black, cluster = ~origin_county)

boom_iv <- feols(occ_change_boom ~ age_1920 + age_sq + in_school +
                   farm_orig + married_1920 + occscore_1920 |
                   migrant ~ log_instrument,
                 data = black, cluster = ~origin_county)

cat("Boom OLS:\n")
etable(boom_ols, se.below = TRUE)
cat("Boom IV:\n")
etable(boom_iv, se.below = TRUE)

# ============================================================================
# TOTAL PERIOD — Full 1920-1940 change
# ============================================================================
cat("\n=== Total Period: 1920-1940 ===\n")

iv_total <- feols(occ_change_total ~ age_1920 + age_sq + in_school +
                    farm_orig + married_1920 + occscore_1920 |
                    migrant ~ log_instrument,
                  data = black, cluster = ~origin_county)
cat("Total IV:\n")
etable(iv_total, se.below = TRUE)

# ============================================================================
# Save model objects for tables
# ============================================================================
save(ols1, ols2, fs1, fs2, iv1, iv2, rf1,
     ols_w, iv_w, boom_ols, boom_iv, iv_total,
     file = "../data/main_models.RData")

# ============================================================================
# Diagnostics JSON
# ============================================================================
diag <- list(
  n_treated = sum(black$migrant == 1),
  n_pre = 1L,  # 1 decade pre-period (1920-1930)
  n_obs = nrow(black),
  n_total = nrow(dt),
  n_white_migrants = sum(white$migrant == 1),
  n_origin_counties = length(unique(black$origin_county)),
  first_stage_f = round(fs2_F, 1)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")
cat(sprintf("  n_treated: %d\n", diag$n_treated))
cat(sprintf("  n_obs: %d\n", diag$n_obs))
cat(sprintf("  First-stage F: %.1f\n", diag$first_stage_f))

cat("\nMain analysis complete.\n")
