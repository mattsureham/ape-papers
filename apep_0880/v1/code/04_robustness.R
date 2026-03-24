## 04_robustness.R — Robustness checks for CRMA diversification analysis
## APEP paper apep_0880

source("00_packages.R")

cat("=== Robustness Checks ===\n")

panel <- readRDS("../data/panel.rds")

# ---------------------------------------------------------------
# R1: Exclude transition-band minerals (50-65% concentration)
# ---------------------------------------------------------------
cat("\n--- R1: Exclude 50-65% band ---\n")

panel_clean <- panel %>%
  filter(concentration_bin != "Medium (50-65%)")

r1 <- feols(hhi ~ treat_continuous | hs_code + year,
            data = panel_clean,
            cluster = ~hs_code)
cat("Without medium-concentration minerals:\n")
print(summary(r1))

# ---------------------------------------------------------------
# R2: Drop rare earths (largest mover — check not driven by one mineral)
# ---------------------------------------------------------------
cat("\n--- R2: Drop Rare Earths ---\n")

r2 <- feols(hhi ~ treat_continuous | hs_code + year,
            data = panel %>% filter(mineral != "Rare earths"),
            cluster = ~hs_code)
cat("Without rare earths:\n")
print(summary(r2))

# ---------------------------------------------------------------
# R3: Use post_force (2024+) instead of post_crma (2023+)
# Tests whether response is to adoption vs proposal
# ---------------------------------------------------------------
cat("\n--- R3: Post-Force Date (2024+) ---\n")

r3 <- feols(hhi ~ treat_force | hs_code + year,
            data = panel,
            cluster = ~hs_code)
cat("Using May 2024 force date:\n")
print(summary(r3))

# ---------------------------------------------------------------
# R4: Placebo test — use pre-CRMA period split (2020 as fake treatment)
# ---------------------------------------------------------------
cat("\n--- R4: Placebo (2020 fake treatment) ---\n")

panel_pre <- panel %>%
  filter(year <= 2022) %>%
  mutate(
    placebo_post = as.integer(year >= 2020),
    placebo_treat = pre_hhi * placebo_post
  )

r4 <- feols(hhi ~ placebo_treat | hs_code + year,
            data = panel_pre,
            cluster = ~hs_code)
cat("Placebo (2020 fake treatment):\n")
print(summary(r4))

# ---------------------------------------------------------------
# R5: Alternative outcome — top-country share (levels)
# ---------------------------------------------------------------
cat("\n--- R5: Top-Country Share ---\n")

r5 <- feols(top_share ~ treat_continuous | hs_code + year,
            data = panel,
            cluster = ~hs_code)
cat("Top share outcome:\n")
print(summary(r5))

# ---------------------------------------------------------------
# R6: Value-weighted HHI (weight by trade value)
# ---------------------------------------------------------------
cat("\n--- R6: Value-Weighted ---\n")

r6 <- feols(hhi ~ treat_continuous | hs_code + year,
            data = panel,
            weights = ~total_value,
            cluster = ~hs_code)
cat("Value-weighted:\n")
print(summary(r6))

# ---------------------------------------------------------------
# R7: Leave-one-mineral-out
# ---------------------------------------------------------------
cat("\n--- R7: Leave-One-Mineral-Out ---\n")

loo_results <- tibble(
  excluded = character(),
  coef = numeric(),
  se = numeric(),
  p = numeric()
)

for (m in unique(panel$mineral)) {
  fit <- feols(hhi ~ treat_continuous | hs_code + year,
               data = panel %>% filter(mineral != m),
               cluster = ~hs_code)
  loo_results <- bind_rows(loo_results, tibble(
    excluded = m,
    coef = coef(fit)["treat_continuous"],
    se = se(fit)["treat_continuous"],
    p = pvalue(fit)["treat_continuous"]
  ))
}

cat("LOO coefficients (main = treat_continuous):\n")
print(loo_results, n = 25)
cat(sprintf("Range: [%.4f, %.4f]\n", min(loo_results$coef), max(loo_results$coef)))

# ---------------------------------------------------------------
# Save robustness results
# ---------------------------------------------------------------
rob_results <- list(
  r1_no_medium = r1,
  r2_no_rareearth = r2,
  r3_post_force = r3,
  r4_placebo = r4,
  r5_topshare = r5,
  r6_weighted = r6,
  loo = loo_results
)
saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
