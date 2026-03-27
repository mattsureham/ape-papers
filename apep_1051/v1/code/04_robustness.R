# 04_robustness.R — Robustness checks
# apep_1051: CRP Cap Reduction and Land-Use Transitions

source("00_packages.R")

data_dir <- "../data"
results <- readRDS(file.path(data_dir, "main_results.rds"))
panel <- results$panel

cat("Panel loaded:", nrow(panel), "obs\n")

# ============================================================
# 1. PLACEBO REFORM IN 2010
# ============================================================

cat("\n=== PLACEBO: FALSE REFORM IN 2010 ===\n")

panel_placebo <- panel %>%
  filter(year <= 2013) %>%
  mutate(
    placebo_post = as.integer(year >= 2010),
    placebo_treat = treatment * placebo_post
  )

p_total <- feols(total_planted ~ placebo_treat | fips + state_fips^year,
                 data = panel_placebo, cluster = "state_fips")

p_corn <- feols(corn ~ placebo_treat | fips + state_fips^year,
                data = panel_placebo, cluster = "state_fips")

cat("Placebo total planted: beta =", round(coef(p_total), 1),
    ", se =", round(sqrt(vcov(p_total)[1,1]), 1),
    ", p =", round(pvalue(p_total)[1], 3), "\n")

cat("Placebo corn: beta =", round(coef(p_corn), 1),
    ", se =", round(sqrt(vcov(p_corn)[1,1]), 1),
    ", p =", round(pvalue(p_corn)[1], 3), "\n")

# ============================================================
# 2. DOSE-RESPONSE BY TREATMENT QUARTILE
# ============================================================

cat("\n=== DOSE-RESPONSE BY QUARTILE ===\n")

# Create quartile indicators interacted with post
panel <- panel %>%
  mutate(
    q2_post = as.integer(treat_quartile == 2) * post,
    q3_post = as.integer(treat_quartile == 3) * post,
    q4_post = as.integer(treat_quartile == 4) * post
  )

dose_corn <- feols(corn ~ q2_post + q3_post + q4_post | fips + state_fips^year,
                   data = panel, cluster = "state_fips")

dose_total <- feols(total_planted ~ q2_post + q3_post + q4_post | fips + state_fips^year,
                    data = panel, cluster = "state_fips")

cat("Dose-response (corn):\n")
etable(dose_corn, headers = "Corn (Quartile DiD)")
cat("Dose-response (total planted):\n")
etable(dose_total, headers = "Total Planted (Quartile DiD)")

# ============================================================
# 3. ALTERNATIVE FEs — Year FE + State Trends
# ============================================================

cat("\n=== ALTERNATIVE FEs ===\n")

# Year FE only
alt1_corn <- feols(corn ~ treat_x_post | fips + year,
                   data = panel, cluster = "state_fips")

# Year FE + state linear trends
panel <- panel %>% mutate(state_trend = as.numeric(factor(state_fips)) * year)
alt2_corn <- feols(corn ~ treat_x_post + state_trend | fips + year,
                   data = panel, cluster = "state_fips")

cat("Alternative 1 (Year FE): beta =", round(coef(alt1_corn), 1), "\n")
cat("Alternative 2 (Year FE + State trends): beta =", round(coef(alt2_corn)["treat_x_post"], 1), "\n")

# ============================================================
# 4. RESTRICT TO CROP-BELT STATES (higher CRP exposure)
# ============================================================

cat("\n=== CROP BELT RESTRICTION ===\n")

# States with most CRP acreage: KS, TX, MT, ND, SD, CO, NE, MN, IA, MO
cropbelt_states <- c("20", "48", "30", "38", "46", "08", "31", "27", "19", "29")

panel_belt <- panel %>% filter(state_fips %in% cropbelt_states)
cat("Crop belt panel:", nrow(panel_belt), "obs,",
    n_distinct(panel_belt$fips), "counties\n")

belt_corn <- feols(corn ~ treat_x_post | fips + state_fips^year,
                   data = panel_belt, cluster = "state_fips")

belt_total <- feols(total_planted ~ treat_x_post | fips + state_fips^year,
                    data = panel_belt, cluster = "state_fips")

cat("Belt corn: beta =", round(coef(belt_corn), 1),
    ", se =", round(sqrt(vcov(belt_corn)[1,1]), 1), "\n")
cat("Belt total: beta =", round(coef(belt_total), 1),
    ", se =", round(sqrt(vcov(belt_total)[1,1]), 1), "\n")

# ============================================================
# 5. LEAVE-ONE-STATE-OUT
# ============================================================

cat("\n=== LEAVE-ONE-STATE-OUT (Corn) ===\n")

states <- unique(panel$state_fips)
loo_betas <- sapply(states, function(s) {
  d <- panel %>% filter(state_fips != s)
  m <- feols(corn ~ treat_x_post | fips + state_fips^year,
             data = d, cluster = "state_fips")
  coef(m)["treat_x_post"]
})

cat("LOO corn betas: min =", round(min(loo_betas), 1),
    ", max =", round(max(loo_betas), 1),
    ", mean =", round(mean(loo_betas), 1), "\n")
cat("All same sign:", all(loo_betas > 0), "\n")

# ============================================================
# 6. CRP ENROLLMENT CHANGE AS FIRST STAGE
# ============================================================

cat("\n=== CRP ENROLLMENT DECLINE (DESCRIPTIVE) ===\n")

crp <- readRDS(file.path(data_dir, "crp_enrollment.rds"))
crp_treat <- readRDS(file.path(data_dir, "crp_treatment.rds"))

# Verify treatment variation
cat("Treatment distribution (CRP loss / cropland):\n")
cat("  Q1:", round(quantile(crp_treat$treatment, 0.25), 4), "\n")
cat("  Median:", round(median(crp_treat$treatment), 4), "\n")
cat("  Q3:", round(quantile(crp_treat$treatment, 0.75), 4), "\n")
cat("  P90:", round(quantile(crp_treat$treatment, 0.90), 4), "\n")
cat("  Max:", round(max(crp_treat$treatment), 4), "\n")

# ============================================================
# 7. SAVE ROBUSTNESS RESULTS
# ============================================================

rob <- list(
  placebo_total = p_total,
  placebo_corn = p_corn,
  dose_corn = dose_corn,
  dose_total = dose_total,
  alt1_corn = alt1_corn,
  belt_corn = belt_corn,
  belt_total = belt_total,
  loo_betas = loo_betas
)

saveRDS(rob, file.path(data_dir, "robustness_results.rds"))
cat("\nRobustness results saved.\n")
