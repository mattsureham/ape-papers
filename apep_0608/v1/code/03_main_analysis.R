## 03_main_analysis.R — Main RDD analysis
## apep_0608: Japan Women's Participation Disclosure RDD
##
## Design: Sharp threshold comparison + parametric RDD at 301 employees
## Running variable: firm size category (binned midpoints)
## First stage: disclosure compliance jumps 75pp at threshold
## Outcomes: gender wage gap, female manager share

source("00_packages.R")

data_dir <- "../data"
df_primary <- readRDS(file.path(data_dir, "analysis_primary.rds"))
df_extended <- readRDS(file.path(data_dir, "analysis_extended.rds"))

cat("Primary sample:", nrow(df_primary), "firms\n")
cat("Extended sample:", nrow(df_extended), "firms\n")

## ===========================================================================
## 1. FIRST STAGE: Disclosure compliance at the threshold
## ===========================================================================

cat("\n=== FIRST STAGE ===\n")

fs_wage <- feols(discloses_wage_gap ~ above_301, data = df_primary, vcov = "HC1")
fs_mgr  <- feols(discloses_manager ~ above_301, data = df_primary, vcov = "HC1")

cat("\nWage gap disclosure jump:", round(coef(fs_wage)["above_301"] * 100, 1), "pp\n")
cat("Manager disclosure jump:", round(coef(fs_mgr)["above_301"] * 100, 1), "pp\n")
cat("F-stat (wage):", round(fitstat(fs_wage, "f")$f$stat, 1), "\n")

# First stage with FE
fs_wage_fe <- feols(discloses_wage_gap ~ above_301 | industry_clean + prefecture,
                    data = df_primary, vcov = "HC1")
cat("\nFirst stage with FE:", round(coef(fs_wage_fe)["above_301"] * 100, 1), "pp\n")

## ===========================================================================
## 2. COVARIATE BALANCE
## ===========================================================================

cat("\n=== COVARIATE BALANCE ===\n")

balance_df <- df_primary %>%
  group_by(above_301) %>%
  summarise(
    n = n(),
    pct_listed = mean(is_listed) * 100,
    pct_tokyo = mean(prefecture == "東京都", na.rm = TRUE) * 100,
    pct_healthcare = mean(industry_clean == "医療、福祉", na.rm = TRUE) * 100,
    pct_manufacturing = mean(industry_clean == "その他製造業", na.rm = TRUE) * 100,
    pct_retail = mean(industry_clean == "卸売業、小売業", na.rm = TRUE) * 100,
    .groups = "drop"
  )
print(balance_df)

## ===========================================================================
## 3. REDUCED FORM (ITT): Adjacent-bin comparison
## ===========================================================================

cat("\n=== REDUCED FORM: Primary (101-300 vs 301-500) ===\n")

# Without controls
rf1 <- feols(wage_gap ~ above_301, data = df_primary, vcov = "HC1")
rf2 <- feols(wage_gap_reg ~ above_301, data = df_primary, vcov = "HC1")
rf3 <- feols(fem_manager ~ above_301, data = df_primary, vcov = "HC1")
rf4 <- feols(fem_section ~ above_301, data = df_primary, vcov = "HC1")
rf5 <- feols(fem_board ~ above_301, data = df_primary, vcov = "HC1")

# With industry + prefecture FE
rf1_fe <- feols(wage_gap ~ above_301 | industry_clean + prefecture,
                data = df_primary, vcov = "HC1")
rf2_fe <- feols(wage_gap_reg ~ above_301 | industry_clean + prefecture,
                data = df_primary, vcov = "HC1")
rf3_fe <- feols(fem_manager ~ above_301 | industry_clean + prefecture,
                data = df_primary, vcov = "HC1")
rf4_fe <- feols(fem_section ~ above_301 | industry_clean + prefecture,
                data = df_primary, vcov = "HC1")
rf5_fe <- feols(fem_board ~ above_301 | industry_clean + prefecture,
                data = df_primary, vcov = "HC1")

cat("\nResults without controls:\n")
for (m in list(rf1, rf2, rf3, rf4, rf5)) {
  cat(sprintf("  %-20s: %6.2f (SE=%5.2f, p=%s)\n",
              as.character(m$fml[[2]]),
              coef(m)["above_301"],
              se(m)["above_301"],
              format.pval(pvalue(m)["above_301"], digits = 3)))
}

cat("\nResults with industry + prefecture FE:\n")
for (m in list(rf1_fe, rf2_fe, rf3_fe, rf4_fe, rf5_fe)) {
  cat(sprintf("  %-20s: %6.2f (SE=%5.2f, p=%s)\n",
              as.character(m$fml[[2]]),
              coef(m)["above_301"],
              se(m)["above_301"],
              format.pval(fixest::pvalue(m)["above_301"], digits = 3)))
}

## ===========================================================================
## 4. PARAMETRIC RDD: All bins with polynomial in firm size
## ===========================================================================

cat("\n=== PARAMETRIC RDD (all bins) ===\n")

# The key question: is the size-outcome gradient smooth, or does it jump at 301?
# If smooth, the reduced form captures threshold effect + size gradient
# Parametric RDD controls for the size gradient

df_ext <- df_extended %>%
  mutate(
    size_centered_sq = size_centered^2,
    # Interaction terms for different slopes on each side
    size_below = ifelse(above_301 == 0, size_centered, 0),
    size_above = ifelse(above_301 == 1, size_centered, 0)
  )

# Model A: Linear, common slope
param_a1 <- feols(wage_gap ~ above_301 + size_centered, data = df_ext, vcov = "HC1")
param_a2 <- feols(fem_manager ~ above_301 + size_centered, data = df_ext, vcov = "HC1")

# Model B: Linear, different slopes each side
param_b1 <- feols(wage_gap ~ above_301 + size_below + size_above, data = df_ext, vcov = "HC1")
param_b2 <- feols(fem_manager ~ above_301 + size_below + size_above, data = df_ext, vcov = "HC1")

# Model C: Linear, different slopes + FE
param_c1 <- feols(wage_gap ~ above_301 + size_below + size_above | industry_clean + prefecture,
                  data = df_ext, vcov = "HC1")
param_c2 <- feols(fem_manager ~ above_301 + size_below + size_above | industry_clean + prefecture,
                  data = df_ext, vcov = "HC1")

cat("\nParametric RDD — Wage gap:\n")
for (m in list(param_a1, param_b1, param_c1)) {
  cat(sprintf("  above_301: %6.2f (SE=%5.2f, p=%s)\n",
              coef(m)["above_301"],
              se(m)["above_301"],
              format.pval(fixest::pvalue(m)["above_301"], digits = 3)))
}

cat("\nParametric RDD — Female manager share:\n")
for (m in list(param_a2, param_b2, param_c2)) {
  cat(sprintf("  above_301: %6.2f (SE=%5.2f, p=%s)\n",
              coef(m)["above_301"],
              se(m)["above_301"],
              format.pval(fixest::pvalue(m)["above_301"], digits = 3)))
}

## ===========================================================================
## 5. SELECTION ANALYSIS: Who discloses voluntarily?
## ===========================================================================

cat("\n=== SELECTION INTO DISCLOSURE ===\n")

# Among 101-300 firms: compare voluntary disclosers to non-disclosers
below <- df_primary %>% filter(above_301 == 0)

sel_test <- below %>%
  group_by(discloses_wage_gap) %>%
  summarise(
    n = n(),
    pct_listed = mean(is_listed) * 100,
    pct_tokyo = mean(prefecture == "東京都", na.rm = TRUE) * 100,
    .groups = "drop"
  )
cat("\nBelow-threshold firms by voluntary disclosure:\n")
print(sel_test)

# Among those who disclose: compare outcomes above vs below threshold
# This subgroup comparison avoids the composition issue
disclosers_only <- df_primary %>% filter(discloses_wage_gap == 1)
cat("\nDisclosers-only sample:", nrow(disclosers_only), "firms\n")
cat("  Below 301:", sum(disclosers_only$above_301 == 0), "\n")
cat("  Above 301:", sum(disclosers_only$above_301 == 1), "\n")

rf_disc <- feols(wage_gap ~ above_301, data = disclosers_only, vcov = "HC1")
rf_disc_fe <- feols(wage_gap ~ above_301 | industry_clean + prefecture,
                    data = disclosers_only, vcov = "HC1")

cat("\nAmong disclosers only — Wage gap:\n")
cat("  No controls:", round(coef(rf_disc)["above_301"], 2),
    "(SE=", round(se(rf_disc)["above_301"], 2), ")\n")
cat("  With FE:", round(coef(rf_disc_fe)["above_301"], 2),
    "(SE=", round(se(rf_disc_fe)["above_301"], 2), ")\n")

# Same for female manager share
disclosers_mgr <- df_primary %>% filter(discloses_manager == 1)
rf_disc_mgr <- feols(fem_manager ~ above_301, data = disclosers_mgr, vcov = "HC1")
rf_disc_mgr_fe <- feols(fem_manager ~ above_301 | industry_clean + prefecture,
                        data = disclosers_mgr, vcov = "HC1")

cat("\nAmong disclosers only — Female manager share:\n")
cat("  No controls:", round(coef(rf_disc_mgr)["above_301"], 2),
    "(SE=", round(se(rf_disc_mgr)["above_301"], 2), ")\n")
cat("  With FE:", round(coef(rf_disc_mgr_fe)["above_301"], 2),
    "(SE=", round(se(rf_disc_mgr_fe)["above_301"], 2), ")\n")

## ===========================================================================
## 6. WALD ESTIMATOR (manual LATE)
## ===========================================================================

cat("\n=== WALD ESTIMATOR ===\n")

# RF / FS = LATE for compliers
rf_coef_wage <- coef(rf1)["above_301"]
fs_coef_wage <- coef(fs_wage)["above_301"]
wald_wage <- rf_coef_wage / fs_coef_wage

rf_coef_mgr <- coef(rf3)["above_301"]
fs_coef_mgr <- coef(fs_mgr)["above_301"]
wald_mgr <- rf_coef_mgr / fs_coef_mgr

# Delta method SE for Wald
# SE(LATE) ≈ SE(RF) / FS (first-order approximation, valid when FS is precisely estimated)
se_wald_wage <- se(rf1)["above_301"] / abs(fs_coef_wage)
se_wald_mgr <- se(rf3)["above_301"] / abs(fs_coef_mgr)

cat("Wald (wage gap):   ", round(wald_wage, 2), " (SE ≈", round(se_wald_wage, 2), ")\n")
cat("Wald (fem manager):", round(wald_mgr, 2), " (SE ≈", round(se_wald_mgr, 2), ")\n")

## ===========================================================================
## 7. OUTCOME MEANS by bin (for visual/table)
## ===========================================================================

cat("\n=== BIN MEANS ===\n")

bin_means <- df_extended %>%
  filter(!is.na(size_cat)) %>%
  group_by(size_cat, size_midpoint, above_301) %>%
  summarise(
    n = n(),
    wage_gap_mean = mean(wage_gap, na.rm = TRUE),
    wage_gap_n = sum(!is.na(wage_gap)),
    fem_mgr_mean = mean(fem_manager, na.rm = TRUE),
    fem_mgr_n = sum(!is.na(fem_manager)),
    disclosure_rate = mean(discloses_wage_gap) * 100,
    .groups = "drop"
  ) %>%
  arrange(size_midpoint)

cat("\nBin-level summary:\n")
print(bin_means, n = 10)

## ===========================================================================
## 8. DIAGNOSTICS
## ===========================================================================

diagnostics <- list(
  n_treated = sum(df_primary$above_301 == 1),
  n_pre = 7,  # Cross-sectional RDD: 7 size bins serve as 'periods' for parametric fit
  n_obs = nrow(df_primary),
  n_obs_wage = sum(!is.na(df_primary$wage_gap)),
  n_obs_mgr = sum(!is.na(df_primary$fem_manager)),
  first_stage_wage = round(coef(fs_wage)["above_301"] * 100, 1),
  rf_wage_gap = round(coef(rf1)["above_301"], 2),
  rf_fem_mgr = round(coef(rf3)["above_301"], 2),
  wald_wage = round(wald_wage, 2),
  wald_mgr = round(wald_mgr, 2)
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics saved.\n")

## ===========================================================================
## 9. SAVE RESULTS
## ===========================================================================

save(
  fs_wage, fs_mgr, fs_wage_fe,
  rf1, rf2, rf3, rf4, rf5,
  rf1_fe, rf2_fe, rf3_fe, rf4_fe, rf5_fe,
  param_a1, param_a2, param_b1, param_b2, param_c1, param_c2,
  rf_disc, rf_disc_fe, rf_disc_mgr, rf_disc_mgr_fe,
  wald_wage, wald_mgr, se_wald_wage, se_wald_mgr,
  bin_means, balance_df,
  file = file.path(data_dir, "regression_results.RData")
)
cat("Results saved.\n")
