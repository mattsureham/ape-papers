# =============================================================================
# 04_robustness.R — Robustness Checks and Mechanism Tests
# Paper: apep_0886 — Childcare Stabilization Grants and Maternal Labor Supply
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")

# ---- 1. Within-Childcare DD (Female vs Male in 624 only) ---- #
# No cross-industry comparison — just test whether the female/male gap
# in childcare changed after ARP
cat("=== 1. Within-Childcare DD (NAICS 624 only) ===\n")

df_624 <- panel %>% filter(industry_code == "624")

r1_emp <- feols(
  log_emp ~ post:female | state_fips^female + state_fips^yq,
  data = df_624,
  cluster = ~state_fips
)
cat("Female × Post (624 only, log emp):", round(coef(r1_emp)["post:female"], 4),
    " SE:", round(se(r1_emp)["post:female"], 4), "\n")

r1_earn <- feols(
  earn ~ post:female | state_fips^female + state_fips^yq,
  data = df_624,
  cluster = ~state_fips
)
cat("Female × Post (624 only, earnings):", round(coef(r1_earn)["post:female"], 2),
    " SE:", round(se(r1_earn)["post:female"], 2), "\n")

# ---- 2. Placebo: Manufacturing only (311 + 332) ---- #
# If our design is valid, manufacturing shouldn't show a female-specific
# break at the ARP date
cat("\n=== 2. Placebo: Manufacturing DD ===\n")

df_mfg <- panel %>% filter(industry_code %in% c("311", "332"))

r2 <- feols(
  log_emp ~ post:female | state_fips^female + state_fips^yq,
  data = df_mfg,
  cluster = ~state_fips
)
cat("Female × Post (Manufacturing, log emp):", round(coef(r2)["post:female"], 4),
    " SE:", round(se(r2)["post:female"], 4), "\n")

# ---- 3. Pre-COVID only: Restrict pre-period to 2019Q1-2020Q1 ---- #
cat("\n=== 3. Pre-COVID Pre-Period ===\n")

df_precovid <- panel %>%
  filter(industry_code %in% c("624", "311", "332")) %>%
  filter(!(year == 2020 & quarter >= 2) & !(year == 2021 & quarter <= 3)) %>%
  mutate(ddd = post * female * childcare)

r3 <- feols(
  log_emp ~ ddd + post:female + post:childcare + female:childcare |
    cell_id + industry_code^yq + state_fips^yq,
  data = df_precovid,
  cluster = ~state_fips
)
cat("DDD (excluding COVID quarters):", round(coef(r3)["ddd"], 4),
    " SE:", round(se(r3)["ddd"], 4), "\n")

# ---- 4. Dose-Response Heterogeneity ---- #
# Split by above/below median allocation per capita
cat("\n=== 4. Dose-Response: High vs Low Allocation ===\n")

df_ddd <- panel %>% filter(industry_code %in% c("624", "311", "332"))

r4_high <- feols(
  log_emp ~ ddd + post:female + post:childcare + female:childcare |
    cell_id + industry_code^yq + state_fips^yq,
  data = df_ddd %>% filter(high_alloc == 1),
  cluster = ~state_fips
)

r4_low <- feols(
  log_emp ~ ddd + post:female + post:childcare + female:childcare |
    cell_id + industry_code^yq + state_fips^yq,
  data = df_ddd %>% filter(high_alloc == 0),
  cluster = ~state_fips
)

cat("DDD (High allocation):", round(coef(r4_high)["ddd"], 4),
    " SE:", round(se(r4_high)["ddd"], 4), "\n")
cat("DDD (Low allocation):", round(coef(r4_low)["ddd"], 4),
    " SE:", round(se(r4_low)["ddd"], 4), "\n")

# ---- 5. Grant Expiration Test ---- #
# After September 2023, grants expired — did the effect reverse?
cat("\n=== 5. Grant Expiration Test ===\n")

df_expiry <- panel %>%
  filter(industry_code %in% c("624", "311", "332")) %>%
  mutate(
    active_grant = as.integer(post == 1 & post_expiry == 0),
    expired_grant = as.integer(post_expiry == 1),
    ddd_active = active_grant * female * childcare,
    ddd_expired = expired_grant * female * childcare
  )

r5 <- feols(
  log_emp ~ ddd_active + ddd_expired +
    active_grant:female + expired_grant:female +
    active_grant:childcare + expired_grant:childcare +
    female:childcare |
    cell_id + industry_code^yq + state_fips^yq,
  data = df_expiry,
  cluster = ~state_fips
)

cat("DDD (Active grants):", round(coef(r5)["ddd_active"], 4),
    " SE:", round(se(r5)["ddd_active"], 4), "\n")
cat("DDD (Expired grants):", round(coef(r5)["ddd_expired"], 4),
    " SE:", round(se(r5)["ddd_expired"], 4), "\n")

# ---- 6. Leave-One-Out: Drop each state ---- #
cat("\n=== 6. Leave-One-Out State Test ===\n")

df_loo <- panel %>% filter(industry_code %in% c("624", "311", "332"))
states <- unique(df_loo$state_fips)

loo_coefs <- sapply(states, function(s) {
  m <- feols(
    log_emp ~ ddd + post:female + post:childcare + female:childcare |
      cell_id + industry_code^yq + state_fips^yq,
    data = df_loo %>% filter(state_fips != s),
    cluster = ~state_fips
  )
  coef(m)["ddd"]
})

cat("Leave-one-out DDD range:", round(min(loo_coefs), 4),
    "to", round(max(loo_coefs), 4), "\n")
cat("Mean:", round(mean(loo_coefs), 4), " SD:", round(sd(loo_coefs), 4), "\n")

# ---- 7. Separations DDD ---- #
# Did female separations from childcare change?
cat("\n=== 7. Separations DDD ===\n")

r7 <- feols(
  log(separations + 1) ~ ddd + post:female + post:childcare + female:childcare |
    cell_id + industry_code^yq + state_fips^yq,
  data = panel %>% filter(industry_code %in% c("624", "311", "332")),
  cluster = ~state_fips
)
cat("DDD (log separations):", round(coef(r7)["ddd"], 4),
    " SE:", round(se(r7)["ddd"], 4), "\n")

# ---- Save all robustness results ---- #
results_robust <- list(
  r1_within_624_emp = r1_emp,
  r1_within_624_earn = r1_earn,
  r2_placebo_mfg = r2,
  r3_precovid = r3,
  r4_high_alloc = r4_high,
  r4_low_alloc = r4_low,
  r5_expiry = r5,
  r7_separations = r7
)
saveRDS(results_robust, "../data/results_robust.rds")

cat("\nAll robustness results saved.\n")
