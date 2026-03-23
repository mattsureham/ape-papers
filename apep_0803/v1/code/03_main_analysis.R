## 03_main_analysis.R — Main regressions for apep_0803
## Who Gets the New Jobs? Medicaid Expansion and Racial Employment in Healthcare

source("00_packages.R")

data_dir <- "../data/"

cat("=== MAIN ANALYSIS ===\n")

## ─────────────────────────────────────────────────────────
## 1. Load analysis-ready data
## ─────────────────────────────────────────────────────────
state_race <- fread(file.path(data_dir, "panel_state_race.csv"))
state_all <- fread(file.path(data_dir, "panel_state_all.csv"))
ddd <- fread(file.path(data_dir, "panel_ddd.csv"))
retail <- fread(file.path(data_dir, "panel_retail.csv"))

## Create year-quarter time index
state_race[, t := (year - 2001) * 4 + quarter]
state_all[, t := (year - 2001) * 4 + quarter]
ddd[, t := (year - 2001) * 4 + quarter]

## Annual panels for cleaner analysis
annual_race <- state_race[, .(
  emp = sum(emp, na.rm = TRUE),
  hires = sum(hires, na.rm = TRUE),
  separations = sum(separations, na.rm = TRUE)
), by = .(state, state_fips, year, race, race_label, expansion_year, expanded, cohort)]

annual_race[, post := fifelse(expanded & year >= expansion_year, 1L, 0L)]
annual_race[, time_to_treat := fifelse(expanded, year - expansion_year, NA_integer_)]
annual_race[emp > 0, log_emp := log(emp)]
annual_race[hires > 0, log_hires := log(hires)]

annual_all <- state_all[, .(
  emp = sum(emp, na.rm = TRUE),
  hires = sum(hires, na.rm = TRUE),
  separations = sum(separations, na.rm = TRUE)
), by = .(state, state_fips, year, expansion_year, expanded, cohort)]
annual_all[, post := fifelse(expanded & year >= expansion_year, 1L, 0L)]
annual_all[emp > 0, log_emp := log(emp)]

annual_ddd <- ddd[, .(
  emp_White = sum(emp_White, na.rm = TRUE),
  emp_Black = sum(emp_Black, na.rm = TRUE),
  hires_White = sum(hires_White, na.rm = TRUE),
  hires_Black = sum(hires_Black, na.rm = TRUE)
), by = .(state, state_fips, year, expansion_year, expanded, cohort)]
annual_ddd[, post := fifelse(expanded & year >= expansion_year, 1L, 0L)]
annual_ddd[emp_White > 0 & emp_Black > 0, log_gap := log(emp_Black) - log(emp_White)]
annual_ddd[emp_White > 0 & emp_Black > 0, black_share := emp_Black / (emp_Black + emp_White)]
annual_ddd[hires_White > 0 & hires_Black > 0, hires_gap := log(hires_Black) - log(hires_White)]

annual_retail <- retail[, .(
  emp_retail = sum(emp_retail, na.rm = TRUE),
  hires_retail = sum(hires_retail, na.rm = TRUE)
), by = .(state, state_fips, year, expansion_year, expanded)]
annual_retail[, post := fifelse(expanded & year >= expansion_year, 1L, 0L)]
annual_retail[emp_retail > 0, log_emp_retail := log(emp_retail)]

## ─────────────────────────────────────────────────────────
## 2. TWFE DiD: Aggregate healthcare employment
## ─────────────────────────────────────────────────────────
cat("\n--- 2. Aggregate DiD ---\n")

## Basic TWFE
m1_twfe <- feols(log_emp ~ post | state + year, data = annual_all, cluster = ~state)
cat("TWFE Aggregate:\n")
print(summary(m1_twfe))

## ─────────────────────────────────────────────────────────
## 3. Race-specific DiD: White vs Black
## ─────────────────────────────────────────────────────────
cat("\n--- 3. Race-Specific DiD ---\n")

## White healthcare employment
m2_white <- feols(log_emp ~ post | state + year,
                  data = annual_race[race == "A1"],
                  cluster = ~state)

## Black healthcare employment
m2_black <- feols(log_emp ~ post | state + year,
                  data = annual_race[race == "A2"],
                  cluster = ~state)

## Asian healthcare employment
m2_asian <- feols(log_emp ~ post | state + year,
                  data = annual_race[race == "A4"],
                  cluster = ~state)

cat("White:", coef(m2_white)["post"], "SE:", se(m2_white)["post"], "\n")
cat("Black:", coef(m2_black)["post"], "SE:", se(m2_black)["post"], "\n")
cat("Asian:", coef(m2_asian)["post"], "SE:", se(m2_asian)["post"], "\n")

## ─────────────────────────────────────────────────────────
## 4. DDD: Black-White gap × Expansion
## ─────────────────────────────────────────────────────────
cat("\n--- 4. Triple-Difference ---\n")

## Stack Black and White rows
stack <- annual_race[race %in% c("A1", "A2")]
stack[, black := as.integer(race == "A2")]

## DDD: log_emp ~ post × black | state×race + year×race + state×year
m3_ddd <- feols(log_emp ~ post:black | state^race + year^race + state^year,
                data = stack, cluster = ~state)
cat("DDD (Black × Post):\n")
print(summary(m3_ddd))

## ─────────────────────────────────────────────────────────
## 5. DDD on Black employment share
## ─────────────────────────────────────────────────────────
cat("\n--- 5. Black Share ---\n")

m4_share <- feols(black_share ~ post | state + year,
                  data = annual_ddd, cluster = ~state)
cat("Black share of healthcare employment:\n")
print(summary(m4_share))

## ─────────────────────────────────────────────────────────
## 6. Decomposition: Hires vs Employment
## ─────────────────────────────────────────────────────────
cat("\n--- 6. Hires Decomposition ---\n")

## Black hires
m5_hires_b <- feols(log_hires ~ post | state + year,
                    data = annual_race[race == "A2" & hires > 0],
                    cluster = ~state)

## White hires
m5_hires_w <- feols(log_hires ~ post | state + year,
                    data = annual_race[race == "A1" & hires > 0],
                    cluster = ~state)

## Hires gap (DDD variant)
m5_hires_ddd <- feols(log_hires ~ post:black | state^race + year^race + state^year,
                      data = stack[hires > 0], cluster = ~state)

cat("Black hires:", coef(m5_hires_b)["post"], "\n")
cat("White hires:", coef(m5_hires_w)["post"], "\n")
cat("Hires DDD:", coef(m5_hires_ddd), "\n")

## ─────────────────────────────────────────────────────────
## 7. Event study (annual)
## ─────────────────────────────────────────────────────────
cat("\n--- 7. Event Study ---\n")

## Restrict to states with expansion_year 2014 and never-treated
es_sample <- annual_race[race %in% c("A1", "A2") &
                           (expansion_year == 2014 | is.na(expansion_year))]
es_sample[, black := as.integer(race == "A2")]
es_sample[is.na(time_to_treat), time_to_treat := -999L]

## Create event time indicators (bin at -5 and +8)
es_sample[, evt := pmax(-5L, pmin(8L, time_to_treat))]
es_sample[time_to_treat == -999L, evt := -1L]  ## Never-treated = reference
es_sample[, treated := as.integer(expanded)]

## Event study: interact event-time with treated indicator
m6_es <- feols(log_emp ~ i(evt, treated, ref = -1) | state^race + year^race,
               data = es_sample, cluster = ~state)
cat("Event study coefficients:\n")
print(coeftable(m6_es))

## ─────────────────────────────────────────────────────────
## 8. Save results
## ─────────────────────────────────────────────────────────
results <- list(
  twfe_agg = m1_twfe,
  white = m2_white,
  black = m2_black,
  asian = m2_asian,
  ddd = m3_ddd,
  black_share = m4_share,
  hires_black = m5_hires_b,
  hires_white = m5_hires_w,
  hires_ddd = m5_hires_ddd,
  event_study = m6_es
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

## Diagnostics for validate_v1.py
n_treated_states <- length(unique(annual_all[expanded == TRUE]$state))
n_pre <- length(unique(annual_all[year < 2014]$year))
n_obs <- nrow(annual_all)

diagnostics <- list(
  n_treated = n_treated_states,
  n_pre = n_pre,
  n_obs = n_obs
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
cat(sprintf("  n_treated states: %d\n", n_treated_states))
cat(sprintf("  n_pre years: %d\n", n_pre))
cat(sprintf("  n_obs: %d\n", n_obs))
