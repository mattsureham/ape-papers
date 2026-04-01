# 04_robustness.R — Robustness checks for Swiss CO2 levy paper

source("00_packages.R")
load("../data/models.RData")

cat("=== Robustness Checks ===\n")

# ─── 1. Wild Cluster Bootstrap (26 clusters) ───
cat("\n=== 1. Wild Cluster Bootstrap ===\n")

# Main spec: oil_pct ~ treatment | canton + year
boot_oil <- tryCatch(
  boottest(m1_oil, param = "treatment", B = 9999, clustid = "canton",
           type = "mammen"),
  error = function(e) { cat("Bootstrap error:", e$message, "\n"); NULL }
)

if (!is.null(boot_oil)) {
  cat("Oil - WCB p-value:", boot_oil$p_val, "\n")
  cat("Oil - WCB CI:", boot_oil$conf_int, "\n")
}

boot_gas <- tryCatch(
  boottest(m1_gas, param = "treatment", B = 9999, clustid = "canton",
           type = "mammen"),
  error = function(e) { cat("Bootstrap error:", e$message, "\n"); NULL }
)

if (!is.null(boot_gas)) {
  cat("Gas - WCB p-value:", boot_gas$p_val, "\n")
  cat("Gas - WCB CI:", boot_gas$conf_int, "\n")
}

boot_hp <- tryCatch(
  boottest(m1_hp, param = "treatment", B = 9999, clustid = "canton",
           type = "mammen"),
  error = function(e) { cat("Bootstrap error:", e$message, "\n"); NULL }
)

if (!is.null(boot_hp)) {
  cat("HP - WCB p-value:", boot_hp$p_val, "\n")
  cat("HP - WCB CI:", boot_hp$conf_int, "\n")
}

# ─── 2. Placebo outcomes (electricity and wood should NOT respond) ───
cat("\n=== 2. Placebo Outcomes ===\n")

# Electric heating has no CO2 levy. Wood/biomass has no CO2 levy.
# These should not respond to the oil-share × levy interaction.
m_elec <- feols(elec_pct ~ treatment | canton + year, data = panel,
                cluster = ~canton)
cat("\nElectricity (PLACEBO):\n")
summary(m_elec)

cat("\nWood (PLACEBO):\n")
summary(m1_wood)

# ─── 3. Placebo treatment: use initial GAS share instead of oil share ───
cat("\n=== 3. Placebo Treatment ===\n")

# If effect is specific to oil taxation, then cantons with high GAS share
# should NOT show differential oil decline (gas share is correlated with
# urban/infrastructure, not oil dependency)
panel$gas_share_2000 <- panel$gas_pct[match(paste0(panel$canton, "2000"),
                                             paste0(panel$canton, panel$year))]
# Use initial gas share as treatment
panel_gas_treat <- panel %>%
  group_by(canton) %>%
  mutate(gas_share_2000 = gas_pct[year == 2000] / 100) %>%
  ungroup() %>%
  mutate(treatment_gas = gas_share_2000 * levy_chf_per_ton)

m_placebo_gas <- feols(oil_pct ~ treatment_gas | canton + year,
                       data = panel_gas_treat, cluster = ~canton)
cat("\nOil ~ GasShare2000 × Levy (PLACEBO):\n")
summary(m_placebo_gas)

# ─── 4. Leave-one-out ───
cat("\n=== 4. Leave-One-Out ===\n")

cantons_all <- unique(panel$canton)
loo_results <- data.frame(
  dropped = character(),
  coef_oil = numeric(),
  se_oil = numeric(),
  coef_hp = numeric(),
  se_hp = numeric(),
  coef_gas = numeric(),
  se_gas = numeric(),
  stringsAsFactors = FALSE
)

for (ct in cantons_all) {
  panel_loo <- panel %>% filter(canton != ct)
  m_loo_oil <- feols(oil_pct ~ treatment | canton + year, data = panel_loo,
                     cluster = ~canton)
  m_loo_hp <- feols(hp_pct ~ treatment | canton + year, data = panel_loo,
                    cluster = ~canton)
  m_loo_gas <- feols(gas_pct ~ treatment | canton + year, data = panel_loo,
                     cluster = ~canton)

  loo_results <- rbind(loo_results, data.frame(
    dropped = ct,
    coef_oil = coef(m_loo_oil)["treatment"],
    se_oil = summary(m_loo_oil)$se["treatment"],
    coef_hp = coef(m_loo_hp)["treatment"],
    se_hp = summary(m_loo_hp)$se["treatment"],
    coef_gas = coef(m_loo_gas)["treatment"],
    se_gas = summary(m_loo_gas)$se["treatment"],
    stringsAsFactors = FALSE
  ))
}

cat("\nLeave-One-Out: Oil coefficient range:",
    round(range(loo_results$coef_oil), 3), "\n")
cat("Leave-One-Out: HP coefficient range:",
    round(range(loo_results$coef_hp), 3), "\n")
cat("Leave-One-Out: Gas coefficient range:",
    round(range(loo_results$coef_gas), 3), "\n")

# Most influential canton
cat("\nMost influential canton for gas result:\n")
loo_results %>%
  mutate(change = abs(coef_gas - coef(m1_gas)["treatment"])) %>%
  arrange(desc(change)) %>%
  head(3) %>%
  print()

# ─── 5. Alternative specification: treatment as post × oil_share ───
cat("\n=== 5. Post × OilShare (binary treatment timing) ===\n")

panel$post <- as.numeric(panel$year >= 2021)
m_binary <- feols(oil_pct ~ post:oil_share_2000 | canton + year,
                  data = panel, cluster = ~canton)
cat("\nOil ~ Post × OilShare2000:\n")
summary(m_binary)

m_binary_hp <- feols(hp_pct ~ post:oil_share_2000 | canton + year,
                     data = panel, cluster = ~canton)
cat("\nHP ~ Post × OilShare2000:\n")
summary(m_binary_hp)

m_binary_gas <- feols(gas_pct ~ post:oil_share_2000 | canton + year,
                      data = panel, cluster = ~canton)
cat("\nGas ~ Post × OilShare2000:\n")
summary(m_binary_gas)

# ─── Save robustness objects ───
save(boot_oil, boot_gas, boot_hp,
     m_elec, m_placebo_gas,
     loo_results,
     m_binary, m_binary_hp, m_binary_gas,
     file = "../data/robustness.RData")

cat("\n=== Robustness checks complete ===\n")
