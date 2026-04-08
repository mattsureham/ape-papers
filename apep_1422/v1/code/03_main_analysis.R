# 03_main_analysis.R — Main regression analysis
# apep_1422: When Bugs Hatch Early

source("00_packages.R")

cat("=== Main Analysis ===\n")

panel <- readRDS("../data/panel.rds")

# ─── Specification 1: Schlenker-Roberts replication (benchmark) ──────
cat("\n--- Spec 1: Total temperature effect (Schlenker-Roberts style) ---\n")

# Combined GDD: total growing degree-days (pest + heat combined)
panel$total_gdd <- panel$pest_gdd + panel$heat_stress

m1 <- feols(
  ln_yield ~ total_gdd | fips + year,
  data = panel,
  cluster = ~fips
)
cat("Model 1: Total GDD\n")
summary(m1)

# ─── Specification 2: Decomposed model (main contribution) ──────────
cat("\n--- Spec 2: Decomposed (PestGDD + HeatStress separately) ---\n")

m2 <- feols(
  ln_yield ~ pest_gdd + heat_stress | fips + year,
  data = panel,
  cluster = ~fips
)
cat("Model 2: Decomposed\n")
summary(m2)

# ─── Specification 3: With annual mean temperature control ───────────
cat("\n--- Spec 3: With annual mean temperature control ---\n")

m3 <- feols(
  ln_yield ~ pest_gdd + heat_stress + tmean_annual | fips + year,
  data = panel,
  cluster = ~fips
)
cat("Model 3: + annual mean temp\n")
summary(m3)

# ─── Specification 4: Interaction (PestGDD × HeatStress) ─────────────
cat("\n--- Spec 4: Interaction ---\n")

m4 <- feols(
  ln_yield ~ pest_gdd + heat_stress + I(pest_gdd * heat_stress / 1000) | fips + year,
  data = panel,
  cluster = ~fips
)
cat("Model 4: + Interaction\n")
summary(m4)

# ─── Specification 5: Standardized coefficients ─────────────────────
cat("\n--- Spec 5: Standardized (z-scores) ---\n")

m5 <- feols(
  ln_yield ~ pest_gdd_z + heat_stress_z | fips + year,
  data = panel,
  cluster = ~fips
)
cat("Model 5: Standardized\n")
summary(m5)

# ─── Decomposition calculation ──────────────────────────────────────
cat("\n=== Decomposition ===\n")

beta_pest <- coef(m2)["pest_gdd"]
beta_heat <- coef(m2)["heat_stress"]
sd_pest <- sd(panel$pest_gdd)
sd_heat <- sd(panel$heat_stress)

# Effect of 1-SD increase in each
effect_pest <- beta_pest * sd_pest
effect_heat <- beta_heat * sd_heat

# Share of total temperature damage attributable to pests
# Using absolute standardized effects
total_effect <- abs(effect_pest) + abs(effect_heat)
pest_share <- abs(effect_pest) / total_effect * 100
heat_share <- abs(effect_heat) / total_effect * 100

cat(sprintf("β_pest = %.6f (per degree-day)\n", beta_pest))
cat(sprintf("β_heat = %.6f (per degree-day)\n", beta_heat))
cat(sprintf("\n1-SD effect of PestGDD: %.4f log points (%.2f%% yield)\n",
            effect_pest, (exp(effect_pest) - 1) * 100))
cat(sprintf("1-SD effect of HeatStress: %.4f log points (%.2f%% yield)\n",
            effect_heat, (exp(effect_heat) - 1) * 100))
cat(sprintf("\nPest share of temperature damage: %.1f%%\n", pest_share))
cat(sprintf("Heat share of temperature damage: %.1f%%\n", heat_share))

# ─── VIF check ──────────────────────────────────────────────────────
cat("\n--- VIF check ---\n")
cor_raw <- cor(panel$pest_gdd, panel$heat_stress)
vif <- 1 / (1 - cor_raw^2)
cat(sprintf("Raw correlation: %.3f\n", cor_raw))
cat(sprintf("VIF: %.2f\n", vif))

# Within-county correlation
panel_dm <- panel %>%
  group_by(fips) %>%
  mutate(
    pest_dm = pest_gdd - mean(pest_gdd),
    heat_dm = heat_stress - mean(heat_stress)
  ) %>% ungroup()
cor_within <- cor(panel_dm$pest_dm, panel_dm$heat_dm)
vif_within <- 1 / (1 - cor_within^2)
cat(sprintf("Within-county correlation: %.3f\n", cor_within))
cat(sprintf("Within-county VIF: %.2f\n", vif_within))

# ─── Save results ──────────────────────────────────────────────────
results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
  beta_pest = beta_pest, beta_heat = beta_heat,
  sd_pest = sd_pest, sd_heat = sd_heat,
  effect_pest = effect_pest, effect_heat = effect_heat,
  pest_share = pest_share, heat_share = heat_share,
  cor_raw = cor_raw, cor_within = cor_within
)
saveRDS(results, "../data/main_results.rds")

# ─── Diagnostics for validator ──────────────────────────────────────
jsonlite::write_json(
  list(
    n_treated = n_distinct(panel$fips),
    n_pre = length(unique(panel$year)),
    n_obs = nrow(panel)
  ),
  "../data/diagnostics.json",
  auto_unbox = TRUE
)

cat(sprintf("\nDiagnostics: n_counties=%d, n_years=%d, n_obs=%d\n",
            n_distinct(panel$fips), n_distinct(panel$year), nrow(panel)))
cat("Main analysis complete.\n")
