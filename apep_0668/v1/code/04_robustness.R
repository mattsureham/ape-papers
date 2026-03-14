## 04_robustness.R — Robustness checks and placebo tests
## apep_0668: The Pollinator Penalty

source("code/00_packages.R")

cat("=== Robustness Checks ===\n")

panel <- readRDS("data/analysis_panel.rds")

# ==================================================================
# 1. PLACEBO: Zero-PDR crops only (should show NO triple interaction)
# ==================================================================

cat("\n--- Placebo 1: Zero-PDR crops only ---\n")
zero_pdr <- panel |> filter(pdr == 0)

r1 <- feols(
  log_yield ~ post_ban:derog | country + crop_code + as.factor(year),
  data = zero_pdr,
  cluster = ~country
)
summary(r1)
cat(sprintf("Zero-PDR DD (Post × Derog): %.4f (SE: %.4f)\n",
            coef(r1)[[1]], sqrt(diag(vcov(r1)))[[1]]))

# ==================================================================
# 2. PLACEBO: Pre-ban fake treatment (2014 placebo ban)
# ==================================================================

cat("\n--- Placebo 2: Fake 2014 ban ---\n")
pre_panel <- panel |>
  filter(year >= 2006, year <= 2018) |>
  mutate(fake_post = as.integer(year >= 2014))

r2 <- feols(
  log_yield ~ fake_post:pdr:derog |
    country_crop + crop_year + country_year,
  data = pre_panel,
  cluster = ~country
)
summary(r2)

# ==================================================================
# 3. Alternative clustering: Country × crop
# ==================================================================

cat("\n--- Robustness 3: Country × crop clustering ---\n")
r3 <- feols(
  log_yield ~ post_ban:pdr:derog |
    country_crop + crop_year + country_year,
  data = panel,
  cluster = ~country_crop
)
summary(r3)

# ==================================================================
# 4. Exclude sugar beet (the directly derogated crop)
# ==================================================================

cat("\n--- Robustness 4: Exclude sugar beet ---\n")
no_sugar <- panel |> filter(crop_code != "R2000")

r4 <- feols(
  log_yield ~ post_ban:pdr:derog |
    country_crop + crop_year + country_year,
  data = no_sugar,
  cluster = ~country
)
summary(r4)

# ==================================================================
# 5. Area-weighted regression
# ==================================================================

cat("\n--- Robustness 5: Area-weighted ---\n")
panel_weighted <- panel |> filter(!is.na(area_ha), area_ha > 0)

r5 <- feols(
  log_yield ~ post_ban:pdr:derog |
    country_crop + crop_year + country_year,
  data = panel_weighted,
  weights = ~area_ha,
  cluster = ~country
)
summary(r5)

# ==================================================================
# 6. Leave-one-country-out
# ==================================================================

cat("\n--- Robustness 6: Leave-one-country-out ---\n")
countries <- unique(panel$country)
loco_results <- data.frame(
  excluded = character(),
  coef = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (cc in countries) {
  sub <- panel |> filter(country != cc)
  fit <- feols(
    log_yield ~ post_ban:pdr:derog |
      country_crop + crop_year + country_year,
    data = sub,
    cluster = ~country
  )
  loco_results <- rbind(loco_results, data.frame(
    excluded = cc,
    coef = coef(fit)[[1]],
    se = sqrt(diag(vcov(fit)))[[1]],
    stringsAsFactors = FALSE
  ))
}

cat("Leave-one-out range:\n")
cat(sprintf("  Min coef: %.4f (excluding %s)\n",
            min(loco_results$coef),
            loco_results$excluded[which.min(loco_results$coef)]))
cat(sprintf("  Max coef: %.4f (excluding %s)\n",
            max(loco_results$coef),
            loco_results$excluded[which.max(loco_results$coef)]))

# ==================================================================
# 7. Subsample: Cereals vs oilseeds (mechanism)
# ==================================================================

cat("\n--- Mechanism: Cereals vs Oilseeds ---\n")

cereals <- panel |> filter(crop_group == "Cereal")
oilseeds <- panel |> filter(crop_group == "Oilseed")

r7a <- feols(
  log_yield ~ post_ban:derog | country + as.factor(year),
  data = cereals,
  cluster = ~country
)

r7b <- feols(
  log_yield ~ post_ban:derog | country + as.factor(year),
  data = oilseeds,
  cluster = ~country
)

cat(sprintf("Cereals DD (Post × Derog): %.4f (SE: %.4f)\n",
            coef(r7a)[[1]], sqrt(diag(vcov(r7a)))[[1]]))
cat(sprintf("Oilseeds DD (Post × Derog): %.4f (SE: %.4f)\n",
            coef(r7b)[[1]], sqrt(diag(vcov(r7b)))[[1]]))

# ==================================================================
# 8. Save robustness results
# ==================================================================

saveRDS(list(
  r1_zero_pdr = r1,
  r2_placebo = r2,
  r3_altcluster = r3,
  r4_no_sugar = r4,
  r5_weighted = r5,
  r6_loco = loco_results,
  r7a_cereals = r7a,
  r7b_oilseeds = r7b
), "data/robustness_results.rds")

cat("\nSaved data/robustness_results.rds\n")
