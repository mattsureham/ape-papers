## 04_robustness.R — Robustness checks and event study for apep_0803

source("00_packages.R")

data_dir <- "../data/"

cat("=== ROBUSTNESS CHECKS ===\n")

## ─────────────────────────────────────────────────────────
## 1. Load data
## ─────────────────────────────────────────────────────────
state_race <- fread(file.path(data_dir, "panel_state_race.csv"))
annual_ddd <- fread(file.path(data_dir, "panel_ddd.csv"))
retail <- fread(file.path(data_dir, "panel_retail.csv"))

## Reconstruct annual panels
annual_race <- state_race[, .(
  emp = sum(emp, na.rm = TRUE),
  hires = sum(hires, na.rm = TRUE)
), by = .(state, state_fips, year, race, race_label, expansion_year, expanded, cohort)]

annual_race[, post := fifelse(expanded & year >= expansion_year, 1L, 0L)]
annual_race[, time_to_treat := fifelse(expanded, year - expansion_year, NA_integer_)]
annual_race[emp > 0, log_emp := log(emp)]

## Compute DDD variables annually
annual_ddd2 <- annual_ddd[, .(
  emp_White = sum(emp_White, na.rm = TRUE),
  emp_Black = sum(emp_Black, na.rm = TRUE)
), by = .(state, state_fips, year, expansion_year, expanded, cohort)]
annual_ddd2[, post := fifelse(expanded & year >= expansion_year, 1L, 0L)]
annual_ddd2[, black_share := emp_Black / (emp_Black + emp_White)]

## Retail
annual_retail <- retail[, .(
  emp_retail = sum(emp_retail, na.rm = TRUE)
), by = .(state, state_fips, year, expansion_year, expanded)]
annual_retail[, post := fifelse(expanded & year >= expansion_year, 1L, 0L)]
annual_retail[emp_retail > 0, log_emp_retail := log(emp_retail)]

## ─────────────────────────────────────────────────────────
## 2. Event Study: Black share of healthcare employment
## ─────────────────────────────────────────────────────────
cat("\n--- 2. Event Study (Black Share) ---\n")

## Use only 2014 cohort + never-treated for clean event study
es_data <- annual_ddd2[(expansion_year == 2014 | is.na(expansion_year)) & year >= 2006]
es_data[, time_to_treat := fifelse(expanded, year - expansion_year, NA_integer_)]

## Create event-time dummies (bin at -7 and +8)
es_data[, evt := fifelse(expanded,
                          pmax(-7L, pmin(8L, time_to_treat)),
                          NA_integer_)]

## For never-treated: set evt to reference category so they contribute to year FE only
es_data[is.na(evt), evt := -1L]
es_data[, treated := as.integer(expanded)]

## Event study on black_share — interact event time with treated indicator
m_es_share <- feols(black_share ~ i(evt, treated, ref = -1) | state + year,
                    data = es_data,
                    cluster = ~state)
cat("Event study (Black share):\n")
print(coeftable(m_es_share))

## ─────────────────────────────────────────────────────────
## 3. Retail Placebo
## ─────────────────────────────────────────────────────────
cat("\n--- 3. Retail Placebo ---\n")

m_retail <- feols(log_emp_retail ~ post | state + year,
                  data = annual_retail, cluster = ~state)
cat("Retail employment (placebo):\n")
cat(sprintf("  Estimate: %.4f, SE: %.4f, p: %.4f\n",
    coef(m_retail)["post"], se(m_retail)["post"],
    pvalue(m_retail)["post"]))

## ─────────────────────────────────────────────────────────
## 4. Callaway-Sant'Anna for staggered DiD
## ─────────────────────────────────────────────────────────
cat("\n--- 4. Staggered DiD (Sun-Abraham via fixest) ---\n")

## Use Sun-Abraham estimator (fixest's sunab())
## For Black share as outcome
sa_data <- annual_ddd2[year >= 2006]
sa_data[, cohort_sa := fifelse(expanded, expansion_year, 10000L)]

m_sa <- feols(black_share ~ sunab(cohort_sa, year) | state + year,
              data = sa_data, cluster = ~state)
cat("Sun-Abraham (Black share):\n")
summary(m_sa, agg = "ATT")

## For log employment by race
stack_annual <- annual_race[race %in% c("A1", "A2") & year >= 2006]
stack_annual[, black := as.integer(race == "A2")]
stack_annual[, cohort_sa := fifelse(expanded, expansion_year, 10000L)]

## Sun-Abraham for Black employment
m_sa_black <- feols(log_emp ~ sunab(cohort_sa, year) | state + year,
                    data = stack_annual[race == "A2"],
                    cluster = ~state)
cat("\nSun-Abraham Black employment:\n")
summary(m_sa_black, agg = "ATT")

## ─────────────────────────────────────────────────────────
## 5. Pre-trends test (formal)
## ─────────────────────────────────────────────────────────
cat("\n--- 5. Pre-Trends ---\n")

## Linear pre-trend test for Black share
pre_data <- annual_ddd2[year < 2014]
pre_data[, trend := year - 2013]
pre_data[, trend_expanded := trend * expanded]

m_pretrend <- feols(black_share ~ trend_expanded | state + year,
                    data = pre_data, cluster = ~state)
cat(sprintf("Pre-trend (Black share × expansion-trend): %.5f (SE: %.5f, p: %.4f)\n",
    coef(m_pretrend)["trend_expanded"],
    se(m_pretrend)["trend_expanded"],
    pvalue(m_pretrend)["trend_expanded"]))

## ─────────────────────────────────────────────────────────
## 6. Excluding early/late expanders
## ─────────────────────────────────────────────────────────
cat("\n--- 6. Excluding Late Expanders ---\n")

## Only 2014 cohort vs never-treated
only2014 <- annual_ddd2[expansion_year == 2014 | is.na(expansion_year)]
m_only2014 <- feols(black_share ~ post | state + year,
                    data = only2014, cluster = ~state)
cat(sprintf("Only 2014 cohort (Black share): %.4f (SE: %.4f, p: %.4f)\n",
    coef(m_only2014)["post"], se(m_only2014)["post"],
    pvalue(m_only2014)["post"]))

## ─────────────────────────────────────────────────────────
## 7. Hires Share (hiring flow DDD)
## ─────────────────────────────────────────────────────────
cat("\n--- 7. Hires Share ---\n")

annual_ddd2[, hires_White := 0]
annual_ddd2[, hires_Black := 0]

## Re-aggregate with hires
hires_ddd <- annual_ddd[, .(
  hires_White = sum(hires_White, na.rm = TRUE),
  hires_Black = sum(hires_Black, na.rm = TRUE)
), by = .(state, state_fips, year, expansion_year, expanded, cohort)]
hires_ddd[, post := fifelse(expanded & year >= expansion_year, 1L, 0L)]
hires_ddd[hires_White > 0 & hires_Black > 0,
          black_hires_share := hires_Black / (hires_Black + hires_White)]

m_hires_share <- feols(black_hires_share ~ post | state + year,
                       data = hires_ddd, cluster = ~state)
cat(sprintf("Black hiring share: %.4f (SE: %.4f, p: %.4f)\n",
    coef(m_hires_share)["post"], se(m_hires_share)["post"],
    pvalue(m_hires_share)["post"]))

## ─────────────────────────────────────────────────────────
## 8. Save all robustness results
## ─────────────────────────────────────────────────────────
rob_results <- list(
  es_share = m_es_share,
  retail = m_retail,
  sa_share = m_sa,
  sa_black = m_sa_black,
  pretrend = m_pretrend,
  only2014 = m_only2014,
  hires_share = m_hires_share
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
