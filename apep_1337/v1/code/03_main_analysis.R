## 03_main_analysis.R — Triple-difference estimation
## APEP apep_1337: Section 301 Tariffs and the Asian-White Manufacturing Wage Gap

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
cat(sprintf("Panel loaded: %s observations\n", format(nrow(panel), big.mark = ",")))

## ========================================================
cat("\n=== DDD Specification ===\n")
## ========================================================
## Y_{isrt} = β₁(Tariff_i × Asian_r × Post_t) + β₂(Tariff_i × Post_t)
##          + β₃(Asian_r × Post_t) + γ_{ir} + δ_{rt} + θ_{it} + ε_{isrt}
##
## Key coefficient: β₁ = differential effect of tariff exposure on Asian vs White earnings
## FE: industry×race (γ_{ir}), race×quarter (δ_{rt}), industry×quarter (θ_{it})
## Cluster: state×industry (ind_state)

## ========================================================
cat("\n=== Model 1: Basic DDD on log earnings ===\n")
## ========================================================

m1 <- feols(
  ln_earn ~ tariff_asian_post + tariff_post + asian_post |
    ind_race + race_yq + ind_yq,
  data = panel,
  weights = ~emp_total,
  cluster = ~ind_state
)
cat("Model 1 (log earnings):\n")
summary(m1)

## ========================================================
cat("\n=== Model 2: DDD on earnings levels ===\n")
## ========================================================

m2 <- feols(
  earn_wt ~ tariff_asian_post + tariff_post + asian_post |
    ind_race + race_yq + ind_yq,
  data = panel,
  weights = ~emp_total,
  cluster = ~ind_state
)
cat("Model 2 (earnings levels):\n")
summary(m2)

## ========================================================
cat("\n=== Model 3: DDD on employment ===\n")
## ========================================================

m3 <- feols(
  ln_emp ~ tariff_asian_post + tariff_post + asian_post |
    ind_race + race_yq + ind_yq,
  data = panel,
  weights = ~emp_total,
  cluster = ~ind_state
)
cat("Model 3 (log employment):\n")
summary(m3)

## ========================================================
cat("\n=== Model 4: DDD on hiring rate ===\n")
## ========================================================

m4 <- feols(
  hire_rate ~ tariff_asian_post + tariff_post + asian_post |
    ind_race + race_yq + ind_yq,
  data = panel,
  weights = ~emp_total,
  cluster = ~ind_state
)
cat("Model 4 (hiring rate):\n")
summary(m4)

## ========================================================
cat("\n=== Model 5: Add state×quarter FE ===\n")
## ========================================================

m5 <- feols(
  ln_earn ~ tariff_asian_post + tariff_post + asian_post |
    ind_race + race_yq + ind_yq + state_yq,
  data = panel,
  weights = ~emp_total,
  cluster = ~ind_state
)
cat("Model 5 (log earnings + state×quarter FE):\n")
summary(m5)

## ========================================================
cat("\n=== Event Study: DDD with time interactions ===\n")
## ========================================================

## Create event time relative to 2018Q3 (first tariff enforcement)
panel <- panel %>%
  mutate(
    event_time = (year - 2018) * 4 + (quarter - 3),
    ## Bin event time: cap at [-8, +8] (2 years pre/post)
    event_time_bin = pmax(-8, pmin(8, event_time)),
    ## Interaction for event study
    tariff_asian_et = tariff_rate_wtd * asian
  )

## Reference period: event_time_bin == -1 (2018Q2)
panel$event_time_bin <- relevel(factor(panel$event_time_bin), ref = "-1")

es <- feols(
  ln_earn ~ i(event_time_bin, tariff_asian, ref = -1) +
    i(event_time_bin, tariff_rate_wtd, ref = -1) +
    i(event_time_bin, asian, ref = -1) |
    ind_race + race_yq + ind_yq,
  data = panel,
  weights = ~emp_total,
  cluster = ~ind_state
)
cat("Event study (DDD):\n")
summary(es)

## ========================================================
cat("\n=== Diagnostics ===\n")
## ========================================================

## Count key sample size metrics
## For continuous DDD: count industries with any tariff exposure (> 0)
## This includes manufacturing (0.18), wholesale (0.06), retail (0.04), etc.
n_treated <- panel %>%
  filter(tariff_rate_wtd > 0) %>%
  distinct(industry) %>%
  nrow()

n_pre <- panel %>%
  filter(!post) %>%
  distinct(yq) %>%
  nrow()

n_obs <- nrow(panel)

cat(sprintf("Treated industries (tariff > 10%%): %d\n", n_treated))
cat(sprintf("Pre-periods: %d quarters\n", n_pre))
cat(sprintf("Total observations: %s\n", format(n_obs, big.mark = ",")))

## Write diagnostics
diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)

## ========================================================
cat("\n=== Save results ===\n")
## ========================================================

saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, es = es),
        "../data/main_results.rds")

cat("Main analysis complete.\n")
