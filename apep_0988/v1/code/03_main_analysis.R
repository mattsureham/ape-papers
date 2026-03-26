# 03_main_analysis.R — Main analysis for Poland Sunday Trading Ban
# Continuous treatment DiD: trade share × phase intensity → employment outcomes

source("00_packages.R")

panel <- readRDS("../data/panel_main.rds")

cat("=== MAIN ANALYSIS: Poland Sunday Trading Ban ===\n")
cat(sprintf("Panel: %d obs, %d regions, %d years (2014-2019)\n",
            nrow(panel), n_distinct(panel$geo), n_distinct(panel$year)))
cat(sprintf("Clustering: %d NUTS-2 regions\n", n_distinct(panel$nuts2)))

# ============================================================================
# Model 1: Continuous treatment DiD (main specification)
# log(trade_emp) = alpha_i + gamma_t + beta * (trade_share_2017 * ban_intensity) + eps
# ============================================================================

cat("\n--- Model 1: Continuous treatment DiD ---\n")

m1 <- feols(log_emp_trade ~ treatment | geo + year,
            data = panel, cluster = ~nuts2)
summary(m1)

# ============================================================================
# Model 2: Phase-specific effects
# Separate coefficients for each phase to test dose-response
# ============================================================================

cat("\n--- Model 2: Phase-specific effects ---\n")

m2 <- feols(log_emp_trade ~ treat_phase1 + treat_phase2 | geo + year,
            data = panel, cluster = ~nuts2)
summary(m2)

# ============================================================================
# Model 3: Binary high-exposure DiD
# Compare above-median vs below-median trade share regions
# ============================================================================

cat("\n--- Model 3: Binary high-exposure DiD ---\n")

m3 <- feols(log_emp_trade ~ high_trade:post | geo + year,
            data = panel, cluster = ~nuts2)
summary(m3)

# ============================================================================
# Model 4: Total employment (spillover test)
# Does the ban reduce total employment or just reallocate?
# ============================================================================

cat("\n--- Model 4: Total employment ---\n")

m4 <- feols(log_emp_total ~ treatment | geo + year,
            data = panel, cluster = ~nuts2)
summary(m4)

# ============================================================================
# Model 5: Phase-specific on total employment
# ============================================================================

cat("\n--- Model 5: Phase-specific total employment ---\n")

m5 <- feols(log_emp_total ~ treat_phase1 + treat_phase2 | geo + year,
            data = panel, cluster = ~nuts2)
summary(m5)

# ============================================================================
# Model 6: Cross-country DiD (Poland vs Czech Republic + Slovakia)
# ============================================================================

cat("\n--- Model 6: Cross-country DiD ---\n")

cc <- readRDS("../data/cross_country.rds") %>%
  filter(year >= 2014 & year <= 2019)

m6 <- feols(log_emp_trade ~ treat_x_post | geo + year,
            data = cc, cluster = ~nuts2)
summary(m6)

# ============================================================================
# Model 7: GDP per capita (economic activity proxy)
# ============================================================================

cat("\n--- Model 7: GDP per capita ---\n")

panel_gdp <- panel %>% filter(!is.na(gdp_mio) & gdp_mio > 0)
if (nrow(panel_gdp) > 0) {
  m7 <- feols(log(gdp_mio) ~ treatment | geo + year,
              data = panel_gdp, cluster = ~nuts2)
  summary(m7)
} else {
  cat("No GDP data available.\n")
  m7 <- NULL
}

# ============================================================================
# Save results
# ============================================================================

cat("\n=== RESULTS SUMMARY ===\n")

results <- list(
  m1_continuous = m1,
  m2_phase = m2,
  m3_binary = m3,
  m4_total_emp = m4,
  m5_total_phase = m5,
  m6_cross_country = m6,
  m7_gdp = m7
)

saveRDS(results, "../data/main_results.rds")

# Summary table
cat("\nKey coefficients:\n")
cat(sprintf("  M1 (continuous treatment → trade emp): %.4f (SE: %.4f, p: %.4f)\n",
            coef(m1)["treatment"], se(m1)["treatment"], pvalue(m1)["treatment"]))
cat(sprintf("  M2 Phase 1 → trade emp: %.4f (SE: %.4f)\n",
            coef(m2)["treat_phase1"], se(m2)["treat_phase1"]))
cat(sprintf("  M2 Phase 2 → trade emp: %.4f (SE: %.4f)\n",
            coef(m2)["treat_phase2"], se(m2)["treat_phase2"]))
cat(sprintf("  M4 (treatment → total emp): %.4f (SE: %.4f, p: %.4f)\n",
            coef(m4)["treatment"], se(m4)["treatment"], pvalue(m4)["treatment"]))
cat(sprintf("  M6 (cross-country): %.4f (SE: %.4f, p: %.4f)\n",
            coef(m6)["treat_x_post"], se(m6)["treat_x_post"], pvalue(m6)["treat_x_post"]))

# ============================================================================
# Diagnostics for validation
# ============================================================================

diag_info <- list(
  n_treated = n_distinct(panel$geo[panel$treatment > 0]),
  n_pre = n_distinct(panel$year[panel$year < 2018]),
  n_obs = nrow(panel),
  n_regions = n_distinct(panel$geo),
  n_clusters = n_distinct(panel$nuts2),
  sd_y_pre = sd(panel$log_emp_trade[panel$year < 2018], na.rm = TRUE),
  mean_y_pre = mean(panel$log_emp_trade[panel$year < 2018], na.rm = TRUE),
  coef_m1 = as.numeric(coef(m1)["treatment"]),
  se_m1 = as.numeric(se(m1)["treatment"]),
  sd_treatment = sd(panel$treatment[panel$treatment > 0], na.rm = TRUE)
)

jsonlite::write_json(diag_info, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics written to data/diagnostics.json\n")

cat("\nMain analysis complete.\n")
