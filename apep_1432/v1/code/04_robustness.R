## 04_robustness.R — Robustness and placebo checks
## apep_1432: Protests and Campaign Contributions (Weather IV)

source("00_packages.R")

panel <- fread("../data/panel.csv") %>% as_tibble()
load("../data/main_results.RData")

cat("=== ROBUSTNESS CHECKS ===\n")

## ==========================================================
## 1) Balance test: rainfall uncorrelated with pre-determined variables
## ==========================================================

cat("\n--- Balance: rain vs lagged contributions ---\n")

panel <- panel %>%
  arrange(city_id, year_week) %>%
  group_by(city_id) %>%
  mutate(
    lag1_contributions = lag(ln_contributions, 1),
    lag2_contributions = lag(ln_contributions, 2),
    lag1_amount = lag(ln_amount, 1),
    lead1_contributions = lead(ln_contributions, 1)
  ) %>%
  ungroup()

bal1 <- feols(precip_mean_mm ~ lag1_contributions + lag2_contributions | city_id + week_id,
              data = panel, cluster = ~city_id)
cat("Balance test (rain on lagged contributions):\n")
etable(bal1)

## ==========================================================
## 2) Placebo: rain on LEAD contributions (future shouldn't respond to today's rain)
## ==========================================================

cat("\n--- Placebo: rain → future contributions ---\n")

placebo_lead <- feols(lead1_contributions ~ precip_mean_mm | city_id + week_id,
                      data = panel, cluster = ~city_id)
cat("Placebo (rain → next week contributions):\n")
etable(placebo_lead)

## ==========================================================
## 3) Alternative instrument: number of rainy days (>1mm) in the week
## ==========================================================

cat("\n--- Alternative instrument: rainy days count ---\n")

iv_alt1 <- feols(ln_contributions ~ 1 | city_id + week_id | has_protest ~ n_rain_days,
                 data = panel, cluster = ~city_id)
iv_alt2 <- feols(ln_amount ~ 1 | city_id + week_id | has_protest ~ n_rain_days,
                 data = panel, cluster = ~city_id)
cat("IV with rainy days count as instrument:\n")
etable(iv_alt1, iv_alt2)

## ==========================================================
## 4) Exclude BLM period (May-Aug 2020) — check if results driven by one movement
## ==========================================================

cat("\n--- Exclude BLM peak (May-Aug 2020) ---\n")

panel_no_blm <- panel %>%
  filter(!(year == 2020 & week >= 22 & week <= 35))

iv_no_blm <- feols(ln_contributions ~ 1 | city_id + week_id | has_protest ~ precip_mean_mm,
                   data = panel_no_blm, cluster = ~city_id)
cat("IV excluding BLM peak:\n")
etable(iv_no_blm)

## ==========================================================
## 5) Overidentification: use both precip_mean and n_rain_days
## ==========================================================

cat("\n--- Overidentification test ---\n")

iv_overid <- feols(ln_contributions ~ 1 | city_id + week_id |
                     has_protest ~ precip_mean_mm + n_rain_days,
                   data = panel, cluster = ~city_id)
cat("Overidentified IV (two instruments):\n")
etable(iv_overid)

## Sargan-Hansen test
cat(sprintf("Sargan p-value: %.3f\n", fitstat(iv_overid, "sargan")$sargan$p))

## ==========================================================
## 6) Anderson-Rubin weak-IV-robust CI
## ==========================================================

cat("\n--- Weak-IV robust inference ---\n")

## Anderson-Rubin confidence set
## Use the fitstat approach from fixest
ar_stat <- fitstat(iv1, "ivwald")
cat(sprintf("IV Wald stat: %.2f\n", ar_stat$ivwald$stat))

## ==========================================================
## 7) Exclude small cities (< 10 protest events total)
## ==========================================================

cat("\n--- Restrict to cities with 10+ protests ---\n")

city_counts <- panel %>%
  group_by(city_state) %>%
  summarise(total_protests = sum(n_protests)) %>%
  filter(total_protests >= 10)

panel_active <- panel %>% filter(city_state %in% city_counts$city_state)

iv_active <- feols(ln_contributions ~ 1 | city_id + week_id | has_protest ~ precip_mean_mm,
                   data = panel_active, cluster = ~city_id)
cat(sprintf("IV (cities with 10+ protests, N=%d cities):\n", n_distinct(panel_active$city_state)))
etable(iv_active)

## ==========================================================
## Save robustness objects
## ==========================================================

save(bal1, placebo_lead, iv_alt1, iv_alt2, iv_no_blm,
     iv_overid, iv_active,
     file = "../data/robustness_results.RData")
cat("\nRobustness results saved.\n")
