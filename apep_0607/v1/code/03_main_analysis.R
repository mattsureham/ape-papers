# 03_main_analysis.R — Main DiD analysis
# APEP Working Paper apep_0607

source("00_packages.R")

# ============================================================
# Load analysis panel
# ============================================================
panel <- readRDS("../data/analysis_panel.rds")
cat("Panel loaded:", nrow(panel), "obs,", n_distinct(panel$muni_code_6), "municipalities\n")

# ============================================================
# 1. Main Specification: Continuous-Treatment DiD
# ============================================================
# Y_{it} = α_i + γ_{st} + β × (FarmingShare2008_i × Post_t) + ε_{it}
#
# β captures: for a one-unit increase in pre-2008 farming share,
# how much did agricultural outcomes change differentially after 2012?

cat("\n=== Main Results: Continuous-Treatment DiD ===\n")

# Outcome 1: Log soybean planted area
m1_soy <- feols(log_soy_area ~ treatment_x_post | muni_code_6 + state_year,
                data = panel, cluster = ~muni_code_6)

# Outcome 2: Log total temporary crop area
m1_temp <- feols(log_temp_crop ~ treatment_x_post | muni_code_6 + state_year,
                 data = panel, cluster = ~muni_code_6)

# Outcome 3: Log cattle herd
m1_cattle <- feols(log_cattle ~ treatment_x_post | muni_code_6 + state_year,
                   data = panel, cluster = ~muni_code_6)

# Outcome 4: Log soybean production value
m1_value <- feols(log_soy_value ~ treatment_x_post | muni_code_6 + state_year,
                  data = panel, cluster = ~muni_code_6)

# Print results
cat("\n--- Soybean Area ---\n")
print(summary(m1_soy))
cat("\n--- Temp Crop Area ---\n")
print(summary(m1_temp))
cat("\n--- Cattle Herd ---\n")
print(summary(m1_cattle))
cat("\n--- Soybean Value ---\n")
print(summary(m1_value))

# ============================================================
# 2. Event Study Specification
# ============================================================
cat("\n=== Event Study ===\n")

# Create year dummies interacted with treatment intensity
# Omit 2011 as reference year (last pre-treatment year)
panel <- panel %>%
  mutate(
    event_time = year - 2012,
    year_factor = factor(year)
  )

# Use fixest's i() for event study
es_soy <- feols(log_soy_area ~ i(year, farming_share_2008, ref = 2011) |
                  muni_code_6 + state_year,
                data = panel, cluster = ~muni_code_6)

es_temp <- feols(log_temp_crop ~ i(year, farming_share_2008, ref = 2011) |
                   muni_code_6 + state_year,
                 data = panel, cluster = ~muni_code_6)

es_cattle <- feols(log_cattle ~ i(year, farming_share_2008, ref = 2011) |
                     muni_code_6 + state_year,
                   data = panel, cluster = ~muni_code_6)

cat("\n--- Event Study: Soybean Area ---\n")
print(summary(es_soy))

# Save event study results for figures
saveRDS(es_soy, "../data/es_soy.rds")
saveRDS(es_temp, "../data/es_temp.rds")
saveRDS(es_cattle, "../data/es_cattle.rds")

# ============================================================
# 3. Alternative treatment variable: Forest loss share
# ============================================================
cat("\n=== Robustness: Forest Loss Treatment ===\n")

if ("forest_loss_share" %in% names(panel)) {
  panel <- panel %>%
    mutate(forest_loss_x_post = forest_loss_share * post)

  m2_soy <- feols(log_soy_area ~ forest_loss_x_post | muni_code_6 + state_year,
                  data = panel, cluster = ~muni_code_6)
  m2_cattle <- feols(log_cattle ~ forest_loss_x_post | muni_code_6 + state_year,
                     data = panel, cluster = ~muni_code_6)

  cat("\n--- Forest Loss Treatment: Soy ---\n")
  print(summary(m2_soy))
  cat("\n--- Forest Loss Treatment: Cattle ---\n")
  print(summary(m2_cattle))

  saveRDS(m2_soy, "../data/m2_soy.rds")
  saveRDS(m2_cattle, "../data/m2_cattle.rds")
}

# ============================================================
# 4. Mechanism: Extensification vs. Intensification
# ============================================================
cat("\n=== Mechanism: Extensification vs. Intensification ===\n")

# If soy yield is available
if ("log_soy_yield" %in% names(panel)) {
  m_yield <- feols(log_soy_yield ~ treatment_x_post | muni_code_6 + state_year,
                   data = panel %>% filter(is.finite(log_soy_yield)),
                   cluster = ~muni_code_6)
  cat("\n--- Soy Yield ---\n")
  print(summary(m_yield))
  saveRDS(m_yield, "../data/m_yield.rds")
}

# ============================================================
# 5. Biome Heterogeneity
# ============================================================
cat("\n=== Biome Heterogeneity ===\n")

if ("biome" %in% names(panel)) {
  biome_results <- list()
  for (b in unique(panel$biome)) {
    sub <- panel %>% filter(biome == b)
    if (n_distinct(sub$muni_code_6) >= 30) {
      m <- feols(log_soy_area ~ treatment_x_post | muni_code_6 + year,
                 data = sub, cluster = ~muni_code_6)
      biome_results[[b]] <- m
      cat("\n--- Biome:", b, "(N munis:", n_distinct(sub$muni_code_6), ") ---\n")
      cat("  Coef:", round(coef(m)["treatment_x_post"], 4),
          "SE:", round(se(m)["treatment_x_post"], 4),
          "p:", round(pvalue(m)["treatment_x_post"], 4), "\n")
    }
  }
  saveRDS(biome_results, "../data/biome_results.rds")
}

# ============================================================
# 6. Save main model objects
# ============================================================
saveRDS(m1_soy, "../data/m1_soy.rds")
saveRDS(m1_temp, "../data/m1_temp.rds")
saveRDS(m1_cattle, "../data/m1_cattle.rds")
saveRDS(m1_value, "../data/m1_value.rds")

# ============================================================
# 7. Write diagnostics.json for validator
# ============================================================
diag <- list(
  n_treated = n_distinct(panel$muni_code_6[panel$farming_share_2008 > median(panel$farming_share_2008, na.rm = TRUE)]),
  n_pre = length(unique(panel$year[panel$year < 2012])),
  n_obs = nrow(panel)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics:", jsonlite::toJSON(diag, auto_unbox = TRUE), "\n")

cat("\n=== Main Analysis Complete ===\n")
