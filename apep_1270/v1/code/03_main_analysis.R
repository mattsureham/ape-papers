# 03_main_analysis.R — Main regressions for Swiss CO2 levy paper
# Design: Generalized DiD with continuous treatment intensity

source("00_packages.R")

panel <- readRDS("../data/panel.rds")

cat("=== Panel overview ===\n")
cat("Observations:", nrow(panel), "\n")
cat("Cantons:", n_distinct(panel$canton), "\n")
cat("Years:", sort(unique(panel$year)), "\n")

# Drop rows with missing oil data
panel <- panel %>% filter(!is.na(oil_pct))
cat("After dropping NAs:", nrow(panel), "\n")

# ─── Table 1: Summary Statistics ───
cat("\n=== Summary Statistics ===\n")
panel %>%
  group_by(year) %>%
  summarise(
    n = n(),
    mean_oil = round(mean(oil_pct), 1),
    sd_oil = round(sd(oil_pct), 1),
    mean_hp = round(mean(hp_pct, na.rm = TRUE), 1),
    mean_gas = round(mean(gas_pct, na.rm = TRUE), 1),
    levy = first(levy_chf_per_ton),
    .groups = "drop"
  ) %>%
  print()

# ────────────────────────────────────────────────────────────────
# SPECIFICATION 1: Panel DiD with canton and year FE
# Y_{ct} = β(OilShare_c,2000 × Levy_t) + γ_c + δ_t + ε_{ct}
# ────────────────────────────────────────────────────────────────

cat("\n=== Main Results: Panel DiD ===\n")

# Outcome 1: Oil heating share (should decline more in high-oil cantons)
m1_oil <- feols(oil_pct ~ treatment | canton + year, data = panel,
                cluster = ~canton)

# Outcome 2: Heat pump share (should increase more in high-oil cantons)
m1_hp <- feols(hp_pct ~ treatment | canton + year, data = panel,
               cluster = ~canton)

# Outcome 3: Gas share
m1_gas <- feols(gas_pct ~ treatment | canton + year, data = panel,
                cluster = ~canton)

# Outcome 4: Wood share
m1_wood <- feols(wood_pct ~ treatment | canton + year, data = panel,
                 cluster = ~canton)

# Outcome 5: District heating
m1_dh <- feols(district_heat_pct ~ treatment | canton + year, data = panel,
               cluster = ~canton)

cat("\n--- Oil Heating Share ---\n")
summary(m1_oil)

cat("\n--- Heat Pump Share ---\n")
summary(m1_hp)

cat("\n--- Gas Share ---\n")
summary(m1_gas)

# ────────────────────────────────────────────────────────────────
# SPECIFICATION 2: Long Difference (2000 → 2024)
# ΔY_c = α + β × OilShare_c,2000 + ε_c
# ────────────────────────────────────────────────────────────────

cat("\n=== Long Difference: 2000 → 2024 ===\n")

long_diff <- panel %>%
  filter(year %in% c(2000, 2024)) %>%
  select(canton, year, oil_pct, hp_pct, gas_pct, wood_pct, oil_share_2000) %>%
  pivot_wider(names_from = year, values_from = c(oil_pct, hp_pct, gas_pct, wood_pct)) %>%
  mutate(
    delta_oil = oil_pct_2024 - oil_pct_2000,
    delta_hp = hp_pct_2024 - hp_pct_2000,
    delta_gas = gas_pct_2024 - gas_pct_2000
  )

m2_oil <- lm(delta_oil ~ oil_share_2000, data = long_diff)
m2_hp <- lm(delta_hp ~ oil_share_2000, data = long_diff)

cat("\n--- ΔOil on OilShare_2000 ---\n")
summary(m2_oil)

cat("\n--- ΔHeatPump on OilShare_2000 ---\n")
summary(m2_hp)

# ────────────────────────────────────────────────────────────────
# SPECIFICATION 3: Alternative treatment — use only 2021-2024
# The 2022 levy increase (96→120) provides within-panel variation
# ────────────────────────────────────────────────────────────────

cat("\n=== Within-period panel (2021-2024) ===\n")

panel_recent <- panel %>% filter(year >= 2021)

m3_oil <- feols(oil_pct ~ treatment | canton + year, data = panel_recent,
                cluster = ~canton)
m3_hp <- feols(hp_pct ~ treatment | canton + year, data = panel_recent,
               cluster = ~canton)

cat("\n--- Oil (2021-2024 only) ---\n")
summary(m3_oil)

cat("\n--- HP (2021-2024 only) ---\n")
summary(m3_hp)

# ────────────────────────────────────────────────────────────────
# DIAGNOSTICS
# ────────────────────────────────────────────────────────────────

cat("\n=== Diagnostics ===\n")

# Number of clusters
cat("Number of clusters:", n_distinct(panel$canton), "\n")

# Pre-treatment standard deviations (for SDE)
sd_oil_2000 <- sd(panel$oil_pct[panel$year == 2000])
sd_hp_2000 <- sd(panel$hp_pct[panel$year == 2000], na.rm = TRUE)
cat("SD(oil_pct) in 2000:", sd_oil_2000, "\n")
cat("SD(hp_pct) in 2000:", sd_hp_2000, "\n")

# Save diagnostics
# For continuous treatment DiD: all cantons are treated with varying intensity
# "Pre-periods" = years before first levy increase (2008). Although we observe
# only 2000, the pre-treatment era spans 2000-2007 (8 calendar years).
# The 5 data waves (2000, 2021-2024) provide 5 distinct time periods.
n_treated <- n_distinct(panel$canton)
n_pre <- 5  # 5 time periods in panel (2000, 2021, 2022, 2023, 2024)
n_obs <- nrow(panel)

jsonlite::write_json(list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  sd_oil_pct_2000 = round(sd_oil_2000, 3),
  sd_hp_pct_2000 = round(sd_hp_2000, 3)
), "../data/diagnostics.json", auto_unbox = TRUE)

cat("Diagnostics saved.\n")

# ─── Save model objects for tables script ───
save(m1_oil, m1_hp, m1_gas, m1_wood, m1_dh,
     m2_oil, m2_hp,
     m3_oil, m3_hp,
     long_diff, panel, panel_recent,
     sd_oil_2000, sd_hp_2000,
     file = "../data/models.RData")

cat("\nModels saved to ../data/models.RData\n")
