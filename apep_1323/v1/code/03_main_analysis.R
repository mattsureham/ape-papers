## 03_main_analysis.R — Main DiD analysis: Nigeria cashless policy
## APEP Working Paper apep_1323
##
## Design: Cross-country DiD, Nigeria (treated 2012) vs 10 SSA peers
## Primary outcome: ATMs per 100k, bank branches per 100k
## Method: TWFE DiD + event study + permutation inference

source("00_packages.R")

data_dir <- "../data/"
panel <- readRDS(file.path(data_dir, "panel_clean.rds"))

cat(sprintf("Panel: %d obs, %d countries, years %d-%d\n",
            nrow(panel), n_distinct(panel$country),
            min(panel$year), max(panel$year)))

## ============================================================
## 1. MAIN SPECIFICATION: TWFE DiD
## ============================================================
cat("\n=== Main DiD Results ===\n")

## Spec 1: ATMs per 100k
m1_atm <- feols(
  atm_per_100k ~ treat | country_id + year,
  data = panel,
  cluster = ~country_id
)
cat("\n--- ATMs per 100k ---\n")
print(summary(m1_atm))

## Spec 2: Log ATMs
m2_log_atm <- feols(
  log_atm ~ treat | country_id + year,
  data = panel,
  cluster = ~country_id
)
cat("\n--- Log ATMs ---\n")
print(summary(m2_log_atm))

## Spec 3: Bank branches per 100k
m3_branches <- feols(
  branches_per_100k ~ treat | country_id + year,
  data = panel,
  cluster = ~country_id
)
cat("\n--- Bank branches per 100k ---\n")
print(summary(m3_branches))

## Spec 4: Log branches
m4_log_br <- feols(
  log_branches ~ treat | country_id + year,
  data = panel,
  cluster = ~country_id
)
cat("\n--- Log branches ---\n")
print(summary(m4_log_br))

## Spec 5: With time-varying controls
m5_atm_ctrl <- feols(
  atm_per_100k ~ treat + gdp_growth + inflation + log_gdp_pc + mobile_subs | country_id + year,
  data = panel,
  cluster = ~country_id
)
cat("\n--- ATMs per 100k (with controls) ---\n")
print(summary(m5_atm_ctrl))

m6_br_ctrl <- feols(
  branches_per_100k ~ treat + gdp_growth + inflation + log_gdp_pc + mobile_subs | country_id + year,
  data = panel,
  cluster = ~country_id
)
cat("\n--- Branches per 100k (with controls) ---\n")
print(summary(m6_br_ctrl))

## ============================================================
## 2. EVENT STUDY
## ============================================================
cat("\n=== Event Study ===\n")

## Create event-time dummies interacted with Nigeria
## Reference period: year before treatment (event_time = -1)
panel <- panel %>%
  mutate(
    et = event_time,
    ## Bin endpoints
    et_binned = case_when(
      et <= -5 ~ -5L,
      et >= 8  ~ 8L,
      TRUE     ~ as.integer(et)
    )
  )

## Event study: ATMs per 100k
es_atm <- feols(
  atm_per_100k ~ i(et_binned, nigeria, ref = -1) | country_id + year,
  data = panel,
  cluster = ~country_id
)
cat("\n--- Event Study: ATMs per 100k ---\n")
print(summary(es_atm))

## Event study: Bank branches per 100k
es_br <- feols(
  branches_per_100k ~ i(et_binned, nigeria, ref = -1) | country_id + year,
  data = panel,
  cluster = ~country_id
)
cat("\n--- Event Study: Branches per 100k ---\n")
print(summary(es_br))

## ============================================================
## 3. PERMUTATION INFERENCE (Placebo-in-Space)
## ============================================================
cat("\n=== Permutation Inference ===\n")

## For each control country, pretend it was treated and re-estimate
## Then compare Nigeria's effect to the distribution of placebos

countries <- unique(panel$country)
n_countries <- length(countries)

## Store placebo estimates
placebo_atm <- numeric(n_countries)
placebo_br <- numeric(n_countries)
names(placebo_atm) <- countries
names(placebo_br) <- countries

for (cc in countries) {
  panel_p <- panel %>%
    mutate(
      placebo_treat = as.integer(country == cc & year >= 2012)
    )

  fit_atm <- feols(
    atm_per_100k ~ placebo_treat | country_id + year,
    data = panel_p,
    cluster = ~country_id
  )
  placebo_atm[cc] <- coef(fit_atm)["placebo_treat"]

  fit_br <- feols(
    branches_per_100k ~ placebo_treat | country_id + year,
    data = panel_p,
    cluster = ~country_id
  )
  placebo_br[cc] <- coef(fit_br)["placebo_treat"]
}

## Nigeria's actual effect
nga_atm_effect <- placebo_atm["NG"]
nga_br_effect <- placebo_br["NG"]

## P-values: fraction of placebos with |effect| >= |Nigeria|
p_atm <- mean(abs(placebo_atm) >= abs(nga_atm_effect))
p_br <- mean(abs(placebo_br) >= abs(nga_br_effect))

cat(sprintf("\nPermutation inference (ATMs per 100k):\n"))
cat(sprintf("  Nigeria effect: %.3f\n", nga_atm_effect))
cat(sprintf("  Placebo distribution: [%.3f, %.3f]\n",
            min(placebo_atm), max(placebo_atm)))
cat(sprintf("  Permutation p-value: %.3f\n", p_atm))

cat(sprintf("\nPermutation inference (Branches per 100k):\n"))
cat(sprintf("  Nigeria effect: %.3f\n", nga_br_effect))
cat(sprintf("  Placebo distribution: [%.3f, %.3f]\n",
            min(placebo_br), max(placebo_br)))
cat(sprintf("  Permutation p-value: %.3f\n", p_br))

## ============================================================
## 4. SAVE RESULTS
## ============================================================

results <- list(
  main_atm = m1_atm,
  main_log_atm = m2_log_atm,
  main_branches = m3_branches,
  main_log_branches = m4_log_br,
  main_atm_ctrl = m5_atm_ctrl,
  main_branches_ctrl = m6_br_ctrl,
  es_atm = es_atm,
  es_br = es_br,
  placebo_atm = placebo_atm,
  placebo_br = placebo_br,
  perm_p_atm = p_atm,
  perm_p_br = p_br
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

## Diagnostics for validator
diagnostics <- list(
  n_treated = 1L,  # Nigeria is the single treated country
  n_pre = sum(panel$year[panel$country == "NG"] < 2012),
  n_obs = nrow(panel),
  n_countries = n_distinct(panel$country),
  n_years = n_distinct(panel$year),
  treat_year = 2012L,
  outcomes = c("atm_per_100k", "branches_per_100k"),
  method = "cross-country DiD with permutation inference"
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("\nMain analysis complete. Results saved.\n")
