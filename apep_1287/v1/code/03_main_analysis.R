# ==============================================================================
# 03_main_analysis.R — First stage, reduced form, and IV/2SLS estimation
# Paper: Flood, Flight, and Fortune (apep_1287)
# ==============================================================================

source("00_packages.R")

black <- arrow::read_parquet("../data/analysis_black.parquet")
cat(sprintf("Loaded %d Black farm workers.\n", nrow(black)))

# --------------------------------------------------------------------------
# Panel A: First Stage — Flood exposure → Migration
# --------------------------------------------------------------------------
cat("\n=== FIRST STAGE ===\n")

# (1) Raw first stage (no controls)
fs_raw <- feols(mover_20_30 ~ flood_exposed,
                data = black, cluster = ~county_id)

# (2) With age FE
fs_age <- feols(mover_20_30 ~ flood_exposed | age_1920,
                data = black, cluster = ~county_id)

# (3) With age FE + pre-flood controls
fs_full <- feols(mover_20_30 ~ flood_exposed + occscore_1920 + sei_1920 |
                   age_1920,
                 data = black, cluster = ~county_id)

cat("First stage coefficients:\n")
cat(sprintf("  Raw:  %.4f (SE: %.4f)\n", coef(fs_raw)["flood_exposed"],
            se(fs_raw)["flood_exposed"]))
cat(sprintf("  +Age: %.4f (SE: %.4f)\n", coef(fs_age)["flood_exposed"],
            se(fs_age)["flood_exposed"]))
cat(sprintf("  Full: %.4f (SE: %.4f)\n", coef(fs_full)["flood_exposed"],
            se(fs_full)["flood_exposed"]))

# First-stage t-stat squared (for single instrument, equivalent to F)
t_stat <- coef(fs_raw)["flood_exposed"] / se(fs_raw)["flood_exposed"]
cat(sprintf("  First-stage t: %.2f (effective F ≈ %.1f)\n", t_stat, t_stat^2))

# --------------------------------------------------------------------------
# Panel B: Reduced Form (ITT) — Flood exposure → Outcomes
# --------------------------------------------------------------------------
cat("\n=== REDUCED FORM (ITT) ===\n")

# Occscore change 1920-1930
rf_occ30 <- feols(delta_occ_30 ~ flood_exposed + occscore_1920 + sei_1920 |
                    age_1920,
                  data = black, cluster = ~county_id)

# Occscore change 1920-1940
rf_occ40 <- feols(delta_occ_40 ~ flood_exposed + occscore_1920 + sei_1920 |
                    age_1920,
                  data = black, cluster = ~county_id)

# SEI change 1920-1930
rf_sei30 <- feols(delta_sei_30 ~ flood_exposed + occscore_1920 + sei_1920 |
                    age_1920,
                  data = black, cluster = ~county_id)

# SEI change 1920-1940
rf_sei40 <- feols(delta_sei_40 ~ flood_exposed + occscore_1920 + sei_1920 |
                    age_1920,
                  data = black, cluster = ~county_id)

# Left farming by 1930
rf_farm30 <- feols(left_farm_30 ~ flood_exposed + occscore_1920 + sei_1920 |
                     age_1920,
                   data = black, cluster = ~county_id)

# Left farming by 1940
rf_farm40 <- feols(left_farm_40 ~ flood_exposed + occscore_1920 + sei_1920 |
                     age_1920,
                   data = black, cluster = ~county_id)

cat("Reduced form (flood_exposed → outcomes):\n")
cat(sprintf("  Δoccscore 1930: %.4f (SE: %.4f)\n",
            coef(rf_occ30)["flood_exposed"], se(rf_occ30)["flood_exposed"]))
cat(sprintf("  Δoccscore 1940: %.4f (SE: %.4f)\n",
            coef(rf_occ40)["flood_exposed"], se(rf_occ40)["flood_exposed"]))
cat(sprintf("  ΔSEI 1930:      %.4f (SE: %.4f)\n",
            coef(rf_sei30)["flood_exposed"], se(rf_sei30)["flood_exposed"]))
cat(sprintf("  ΔSEI 1940:      %.4f (SE: %.4f)\n",
            coef(rf_sei40)["flood_exposed"], se(rf_sei40)["flood_exposed"]))
cat(sprintf("  Left farm 1930: %.4f (SE: %.4f)\n",
            coef(rf_farm30)["flood_exposed"], se(rf_farm30)["flood_exposed"]))
cat(sprintf("  Left farm 1940: %.4f (SE: %.4f)\n",
            coef(rf_farm40)["flood_exposed"], se(rf_farm40)["flood_exposed"]))

# --------------------------------------------------------------------------
# Panel C: IV/2SLS — Migration (instrumented) → Outcomes
# --------------------------------------------------------------------------
cat("\n=== IV/2SLS ESTIMATION ===\n")

# fixest IV syntax: y ~ controls | FE | endogenous ~ instrument

# Occscore change 1920-1930
iv_occ30 <- feols(delta_occ_30 ~ occscore_1920 + sei_1920 | age_1920 |
                    mover_20_30 ~ flood_exposed,
                  data = black, cluster = ~county_id)

# Occscore change 1920-1940
iv_occ40 <- feols(delta_occ_40 ~ occscore_1920 + sei_1920 | age_1920 |
                    mover_20_30 ~ flood_exposed,
                  data = black, cluster = ~county_id)

# SEI change 1920-1930
iv_sei30 <- feols(delta_sei_30 ~ occscore_1920 + sei_1920 | age_1920 |
                    mover_20_30 ~ flood_exposed,
                  data = black, cluster = ~county_id)

# SEI change 1920-1940
iv_sei40 <- feols(delta_sei_40 ~ occscore_1920 + sei_1920 | age_1920 |
                    mover_20_30 ~ flood_exposed,
                  data = black, cluster = ~county_id)

# Left farming by 1930
iv_farm30 <- feols(left_farm_30 ~ occscore_1920 + sei_1920 | age_1920 |
                     mover_20_30 ~ flood_exposed,
                   data = black, cluster = ~county_id)

# Left farming by 1940
iv_farm40 <- feols(left_farm_40 ~ occscore_1920 + sei_1920 | age_1920 |
                     mover_20_30 ~ flood_exposed,
                   data = black, cluster = ~county_id)

cat("IV/2SLS (migration → outcomes, LATE):\n")
cat(sprintf("  Δoccscore 1930: %.4f (SE: %.4f)\n",
            coef(iv_occ30)["fit_mover_20_30"],
            se(iv_occ30)["fit_mover_20_30"]))
cat(sprintf("  Δoccscore 1940: %.4f (SE: %.4f)\n",
            coef(iv_occ40)["fit_mover_20_30"],
            se(iv_occ40)["fit_mover_20_30"]))
cat(sprintf("  ΔSEI 1930:      %.4f (SE: %.4f)\n",
            coef(iv_sei30)["fit_mover_20_30"],
            se(iv_sei30)["fit_mover_20_30"]))
cat(sprintf("  ΔSEI 1940:      %.4f (SE: %.4f)\n",
            coef(iv_sei40)["fit_mover_20_30"],
            se(iv_sei40)["fit_mover_20_30"]))
cat(sprintf("  Left farm 1930: %.4f (SE: %.4f)\n",
            coef(iv_farm30)["fit_mover_20_30"],
            se(iv_farm30)["fit_mover_20_30"]))
cat(sprintf("  Left farm 1940: %.4f (SE: %.4f)\n",
            coef(iv_farm40)["fit_mover_20_30"],
            se(iv_farm40)["fit_mover_20_30"]))

# First-stage F from IV
cat(sprintf("\n  IV first-stage F (Δocc30 spec): %.1f\n",
            fitstat(iv_occ30, "ivf")$ivf1$stat))

# --------------------------------------------------------------------------
# Save all model objects for tables
# --------------------------------------------------------------------------
save(fs_raw, fs_age, fs_full,
     rf_occ30, rf_occ40, rf_sei30, rf_sei40, rf_farm30, rf_farm40,
     iv_occ30, iv_occ40, iv_sei30, iv_sei40, iv_farm30, iv_farm40,
     file = "../data/main_models.RData")

# --------------------------------------------------------------------------
# Write diagnostics.json for validator
# --------------------------------------------------------------------------
n_counties <- length(unique(black$county_id))
n_treated <- length(unique(black$county_id[black$flood_exposed == 1]))
n_control <- length(unique(black$county_id[black$flood_exposed == 0]))

diagnostics <- list(
  n_treated = n_treated,
  n_pre = 1L,  # 1920 census is the pre-period (one cross-section)
  n_obs = nrow(black),
  n_counties = n_counties,
  n_control_counties = n_control,
  first_stage_f = fitstat(iv_occ30, "ivf")$ivf1$stat,
  mover_rate_flood = mean(black$mover_20_30[black$flood_exposed == 1]),
  mover_rate_noflood = mean(black$mover_20_30[black$flood_exposed == 0])
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json",
                     auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics written to data/diagnostics.json\n")
cat("Done.\n")
