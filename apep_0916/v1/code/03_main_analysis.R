# =============================================================================
# 03_main_analysis.R — Main regressions: effect of unit banking on outcomes
# Paper: When the Banks Broke (apep_0916)
# =============================================================================

source("00_packages.R")

df <- readRDS("../data/analysis_clean.rds")
cat("Loaded:", nrow(df), "observations\n")

# ─────────────────────────────────────────────────────────────────────────────
# Model 1: OLS Long-Difference — Occupational Income Score (1920→1940)
# ─────────────────────────────────────────────────────────────────────────────
cat("\n=== MODEL 1: OLS Long-Difference ===\n")

m1a <- feols(delta_occscore_20_40 ~ unit_banking,
             data = df, vcov = ~statefip_1920)

m1b <- feols(delta_occscore_20_40 ~ unit_banking + age_1920 + age_sq +
               white + foreign_born + married_1920 + farmer_1920 + occscore_1920,
             data = df, vcov = ~statefip_1920)

m1c <- feols(delta_occscore_20_40 ~ unit_banking + age_1920 + age_sq +
               white + foreign_born + married_1920 + farmer_1920 + occscore_1920 |
               region,
             data = df, vcov = ~statefip_1920)

m1d <- feols(delta_occscore_20_40 ~ unit_banking + ag_share + age_1920 + age_sq +
               white + foreign_born + married_1920 + farmer_1920 + occscore_1920 |
               region,
             data = df, vcov = ~statefip_1920)

cat("1a (raw):", round(coef(m1a)["unit_banking"], 4),
    "se:", round(se(m1a)["unit_banking"], 4), "\n")
cat("1b (controls):", round(coef(m1b)["unit_banking"], 4),
    "se:", round(se(m1b)["unit_banking"], 4), "\n")
cat("1c (region FE):", round(coef(m1c)["unit_banking"], 4),
    "se:", round(se(m1c)["unit_banking"], 4), "\n")
cat("1d (+ag share):", round(coef(m1d)["unit_banking"], 4),
    "se:", round(se(m1d)["unit_banking"], 4), "\n")

# ─────────────────────────────────────────────────────────────────────────────
# Model 2: Interaction Design — Unit Banking × Agricultural Share
# ─────────────────────────────────────────────────────────────────────────────
cat("\n=== MODEL 2: Interaction Design ===\n")

m2a <- feols(delta_occscore_20_40 ~ unit_banking * ag_share + age_1920 + age_sq +
               white + foreign_born + married_1920 + farmer_1920 + occscore_1920 |
               region,
             data = df, vcov = ~statefip_1920)

etable(m2a, se.below = TRUE,
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1))

# ─────────────────────────────────────────────────────────────────────────────
# Model 3: Multiple Outcomes — core scarring indicators
# ─────────────────────────────────────────────────────────────────────────────
cat("\n=== MODEL 3: Multiple Outcomes ===\n")

m3_downgrade <- feols(occ_downgrade ~ unit_banking * ag_share + age_1920 + age_sq +
                        white + foreign_born + married_1920 + farmer_1920 + occscore_1920 |
                        region,
                      data = df, vcov = ~statefip_1920)

m3_losthome <- feols(lost_home ~ unit_banking * ag_share + age_1920 + age_sq +
                       white + foreign_born + married_1920 + farmer_1920 + occscore_1920 |
                       region,
                     data = df, vcov = ~statefip_1920)

m3_migrate <- feols(migrated ~ unit_banking * ag_share + age_1920 + age_sq +
                      white + foreign_born + married_1920 + farmer_1920 + occscore_1920 |
                      region,
                    data = df, vcov = ~statefip_1920)

m3_farmexit <- feols(farm_exit ~ unit_banking * ag_share + age_1920 + age_sq +
                       white + foreign_born + married_1920 + farmer_1920 + occscore_1920 |
                       region,
                     data = df, vcov = ~statefip_1920)

cat("Outcomes table:\n")
etable(m2a, m3_downgrade, m3_losthome, m3_migrate, m3_farmexit,
       se.below = TRUE,
       headers = c("Delta OccScore", "Downgraded", "Lost Home", "Migrated", "Farm Exit"),
       keep = c("unit_banking", "ag_share", "unit_banking:ag_share"),
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1))

# ─────────────────────────────────────────────────────────────────────────────
# Model 4: Heterogeneity by Age (pre-filtering)
# ─────────────────────────────────────────────────────────────────────────────
cat("\n=== MODEL 4: Heterogeneity by Age ===\n")

df_young <- df[age_1920 <= 30]
m4_young <- feols(delta_occscore_20_40 ~ unit_banking * ag_share + age_1920 + age_sq +
                    white + foreign_born + married_1920 + farmer_1920 + occscore_1920 |
                    region,
                  data = df_young, vcov = ~statefip_1920)
rm(df_young); gc()

df_old <- df[age_1920 > 30]
m4_old <- feols(delta_occscore_20_40 ~ unit_banking * ag_share + age_1920 + age_sq +
                  white + foreign_born + married_1920 + farmer_1920 + occscore_1920 |
                  region,
                data = df_old, vcov = ~statefip_1920)
rm(df_old); gc()

cat("Young (UB×Ag):", round(coef(m4_young)["unit_banking:ag_share"], 4),
    "se:", round(se(m4_young)["unit_banking:ag_share"], 4), "\n")
cat("Old (UB×Ag):", round(coef(m4_old)["unit_banking:ag_share"], 4),
    "se:", round(se(m4_old)["unit_banking:ag_share"], 4), "\n")

# ─────────────────────────────────────────────────────────────────────────────
# Model 5: Heterogeneity by Initial Occupation
# ─────────────────────────────────────────────────────────────────────────────
cat("\n=== MODEL 5: Heterogeneity by Initial Occupation ===\n")

df_farmer <- df[farmer_1920 == 1]
m5_farmer <- feols(delta_occscore_20_40 ~ unit_banking * ag_share + age_1920 + age_sq +
                     white + foreign_born + married_1920 | region,
                   data = df_farmer, vcov = ~statefip_1920)
rm(df_farmer); gc()

df_nonfarm <- df[farmer_1920 == 0]
m5_nonfarm <- feols(delta_occscore_20_40 ~ unit_banking * ag_share + age_1920 + age_sq +
                      white + foreign_born + married_1920 + occscore_1920 | region,
                    data = df_nonfarm, vcov = ~statefip_1920)
rm(df_nonfarm); gc()

cat("Farmers (UB×Ag):", round(coef(m5_farmer)["unit_banking:ag_share"], 4),
    "se:", round(se(m5_farmer)["unit_banking:ag_share"], 4), "\n")
cat("Non-farmers (UB×Ag):", round(coef(m5_nonfarm)["unit_banking:ag_share"], 4),
    "se:", round(se(m5_nonfarm)["unit_banking:ag_share"], 4), "\n")

# ─────────────────────────────────────────────────────────────────────────────
# Model 6: Temporal Decomposition (1920-1930 vs 1930-1940) — memory efficient
# ─────────────────────────────────────────────────────────────────────────────
cat("\n=== MODEL 6: Temporal Decomposition ===\n")

# Use only needed columns to save memory
df_slim <- df[, .(delta_occscore_20_30, delta_occscore_30_40,
                   unit_banking, ag_share, age_1920, age_sq,
                   white, foreign_born, married_1920, farmer_1920,
                   occscore_1920, region, statefip_1920)]

m6_first <- feols(delta_occscore_20_30 ~ unit_banking * ag_share + age_1920 + age_sq +
                    white + foreign_born + married_1920 + farmer_1920 + occscore_1920 |
                    region,
                  data = df_slim, vcov = ~statefip_1920)

m6_second <- feols(delta_occscore_30_40 ~ unit_banking * ag_share + age_1920 + age_sq +
                     white + foreign_born + married_1920 + farmer_1920 + occscore_1920 |
                     region,
                   data = df_slim, vcov = ~statefip_1920)
rm(df_slim); gc()

cat("1920-1930 (UB×Ag):", round(coef(m6_first)["unit_banking:ag_share"], 4),
    "se:", round(se(m6_first)["unit_banking:ag_share"], 4), "\n")
cat("1930-1940 (UB×Ag):", round(coef(m6_second)["unit_banking:ag_share"], 4),
    "se:", round(se(m6_second)["unit_banking:ag_share"], 4), "\n")

# ─────────────────────────────────────────────────────────────────────────────
# Model 7: Homeownership loss — key scarring outcome
# ─────────────────────────────────────────────────────────────────────────────
cat("\n=== MODEL 7: Homeownership Regressions ===\n")

m7a <- feols(lost_home ~ unit_banking + age_1920 + age_sq +
               white + foreign_born + married_1920 + farmer_1920 + occscore_1920 |
               region,
             data = df, vcov = ~statefip_1920)

m7b <- feols(lost_home ~ unit_banking + ag_share + age_1920 + age_sq +
               white + foreign_born + married_1920 + farmer_1920 + occscore_1920 |
               region,
             data = df, vcov = ~statefip_1920)

cat("Lost home (UB only):", round(coef(m7a)["unit_banking"], 4),
    "se:", round(se(m7a)["unit_banking"], 4), "\n")
cat("Lost home (UB + ag):", round(coef(m7b)["unit_banking"], 4),
    "se:", round(se(m7b)["unit_banking"], 4), "\n")

# ─────────────────────────────────────────────────────────────────────────────
# Print full results summary
# ─────────────────────────────────────────────────────────────────────────────
cat("\n=== FULL MAIN RESULTS TABLE ===\n")
etable(m1a, m1b, m1c, m1d, m2a,
       se.below = TRUE,
       dict = c(unit_banking = "Unit Banking",
                ag_share = "Ag. Share",
                "unit_banking:ag_share" = "Unit Banking × Ag. Share"),
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1))

cat("\n=== TEMPORAL DECOMPOSITION ===\n")
etable(m6_first, m6_second,
       se.below = TRUE,
       headers = c("1920-1930", "1930-1940"),
       keep = c("unit_banking", "ag_share", "unit_banking:ag_share"),
       signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1))

# ─────────────────────────────────────────────────────────────────────────────
# Save model objects for table generation
# ─────────────────────────────────────────────────────────────────────────────
models <- list(
  m1a = m1a, m1b = m1b, m1c = m1c, m1d = m1d,
  m2a = m2a,
  m3_downgrade = m3_downgrade, m3_losthome = m3_losthome,
  m3_migrate = m3_migrate, m3_farmexit = m3_farmexit,
  m4_young = m4_young, m4_old = m4_old,
  m5_farmer = m5_farmer, m5_nonfarm = m5_nonfarm,
  m6_first = m6_first, m6_second = m6_second,
  m7a = m7a, m7b = m7b
)
saveRDS(models, "../data/model_objects.rds")

# ─────────────────────────────────────────────────────────────────────────────
# Diagnostics JSON (for validate_v1.py)
# ─────────────────────────────────────────────────────────────────────────────
diag <- list(
  n_treated = uniqueN(df$statefip_1920[df$unit_banking == 1]),
  n_pre = 1L,
  n_obs = as.integer(nrow(df))
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics:", jsonlite::toJSON(diag, auto_unbox = TRUE), "\n")

cat("\nMain analysis complete. Models saved.\n")
