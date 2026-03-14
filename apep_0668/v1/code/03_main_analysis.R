## 03_main_analysis.R — Triple-difference estimation
## apep_0668: The Pollinator Penalty
## Packages: fixest, dplyr, jsonlite

source("code/00_packages.R")

cat("=== Main Analysis: Triple-Difference ===\n")

panel <- readRDS("data/analysis_panel.rds")

# ==================================================================
# 1. MAIN SPECIFICATION: DDD with continuous PDR
# ==================================================================
# log(Yield_{ckt}) = β₁ Post × PDR × Derog + αck + αkt + αct + ε
#
# Country×crop FE absorb: PDR × Derog, level differences
# Crop×year FE absorb: Post × PDR (common crop shocks)
# Country×year FE absorb: Post × Derog (common country shocks)
# Only the triple interaction β₁ remains
# ==================================================================

cat("\n--- Model 1: Full DDD (continuous PDR) ---\n")
m1 <- feols(
  log_yield ~ post_ban:pdr:derog |
    country_crop + crop_year + country_year,
  data = panel,
  cluster = ~country
)
summary(m1)

# ==================================================================
# 2. DD: Post × PDR across ALL countries (pollinator recovery)
# ==================================================================
# Tests whether high-PDR crops gained relative to low-PDR crops
# after the ban, across all countries

cat("\n--- Model 2: DD (Post × PDR, all countries) ---\n")
m2 <- feols(
  log_yield ~ post_ban:pdr | country_crop + country_year,
  data = panel,
  cluster = ~country
)
summary(m2)

# ==================================================================
# 3. DD: Post × Derog for sugar beet only (derogation effect)
# ==================================================================
# Tests whether derogation countries maintained sugar beet yields

cat("\n--- Model 3: Sugar beet DD ---\n")
sugar_beet <- panel |> filter(crop_code == "R2000")
m3 <- feols(
  log_yield ~ post_ban:derog | country + as.factor(year),
  data = sugar_beet,
  cluster = ~country
)
summary(m3)

# ==================================================================
# 4. DDD with binary PDR (high vs zero)
# ==================================================================

cat("\n--- Model 4: DDD with binary PDR ---\n")
panel_binary <- panel |>
  mutate(high_pdr = as.integer(pdr > 0))

m4 <- feols(
  log_yield ~ post_ban:high_pdr:derog |
    country_crop + crop_year + country_year,
  data = panel_binary,
  cluster = ~country
)
summary(m4)

# ==================================================================
# 5. Derogation period only (2019-2022) vs post-ECJ (2023)
# ==================================================================

cat("\n--- Model 5: Derogation vs post-ECJ periods ---\n")
m5 <- feols(
  log_yield ~ derog_period:pdr:derog + post_ecj:pdr:derog |
    country_crop + crop_year + country_year,
  data = panel,
  cluster = ~country
)
summary(m5)

# ==================================================================
# 6. Event study: year-by-year DDD interactions
# ==================================================================

cat("\n--- Model 6: Event study ---\n")

# Create year dummies relative to 2018 (last pre-ban year)
panel_es <- panel |>
  filter(year >= 2010) |>
  mutate(
    rel_year = year - 2018,
    pdr_derog = pdr * derog
  )

# Event study with DDD structure
m6 <- feols(
  log_yield ~ i(rel_year, I(pdr * derog), ref = 0) |
    country_crop + crop_year + country_year,
  data = panel_es,
  cluster = ~country
)
summary(m6)

# ==================================================================
# 7. Save results and diagnostics
# ==================================================================

cat("\n=== Saving results ===\n")

# Save model objects
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m6 = m6),
        "data/model_results.rds")

# Write diagnostics.json
# n_treated = number of country-crop-year observations with treatment
# (derogation country × post-ban period)
n_treated_obs <- nrow(panel |> filter(derog == 1, post_ban == 1))
n_treated_countries <- n_distinct(panel$country[panel$derog == 1])
n_control_countries <- n_distinct(panel$country[panel$derog == 0])
n_pre_years <- length(unique(panel$year[panel$year < 2019]))
n_post_years <- length(unique(panel$year[panel$year >= 2019]))

diagnostics <- list(
  n_treated = n_treated_obs,
  n_control = n_control_countries,
  n_pre = n_pre_years,
  n_post = n_post_years,
  n_obs = nrow(panel),
  n_countries = n_distinct(panel$country),
  n_crops = n_distinct(panel$crop_code),
  n_years = n_distinct(panel$year),
  n_country_crop_pairs = n_distinct(panel$country_crop),
  ddd_coef = coef(m1)[[1]],
  ddd_se = sqrt(diag(vcov(m1)))[[1]],
  ddd_pvalue = summary(m1)$coeftable[1, 4]
)

write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("Saved data/diagnostics.json\n")

# Print key results
cat("\n=== KEY RESULTS ===\n")
cat(sprintf("DDD coefficient (Post × PDR × Derog): %.4f (SE: %.4f)\n",
            diagnostics$ddd_coef, diagnostics$ddd_se))
cat(sprintf("p-value: %.4f\n", diagnostics$ddd_pvalue))
cat(sprintf("Observations: %d\n", diagnostics$n_obs))
cat(sprintf("Countries: %d (%d derogation, %d non-derogation)\n",
            diagnostics$n_countries, diagnostics$n_treated, diagnostics$n_control))
cat(sprintf("Crops: %d\n", diagnostics$n_crops))
cat(sprintf("Pre-periods: %d, Post-periods: %d\n",
            diagnostics$n_pre, diagnostics$n_post))
