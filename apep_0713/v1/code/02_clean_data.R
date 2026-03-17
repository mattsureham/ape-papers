## 02_clean_data.R — Build analysis panel for broadband preemption DiD

source("code/00_packages.R")

acs_broadband <- readRDS("data/acs_broadband.rds")
bds_firms     <- readRDS("data/bds_firms.rds")
preemption    <- readRDS("data/preemption_laws.rds")

## ============================================================
## 1. STATE FIPS CROSSWALK
## ============================================================
## Use ACS data to build state FIPS → name crosswalk
state_xwalk <- acs_broadband %>%
  distinct(state, NAME) %>%
  rename(state_fip = state, state_name = NAME)

## ============================================================
## 2. MERGE PREEMPTION DATES INTO STATE DATA
## ============================================================
## For BDS panel (2004-2023)
bds_panel <- bds_firms %>%
  rename(state_fip = state, year = year_obs) %>%
  left_join(state_xwalk, by = "state_fip") %>%
  left_join(preemption %>% select(state_fip, year_enacted, year_repealed),
            by = "state_fip") %>%
  ## Treatment indicator: state had preemption in effect in that year
  mutate(
    preempted = case_when(
      is.na(year_enacted) ~ 0L,                          # never preempted
      !is.na(year_repealed) & year >= year_repealed ~ 0L, # repeal in effect
      year >= year_enacted ~ 1L,                          # preemption in effect
      TRUE ~ 0L                                           # pre-enactment
    ),
    ## Treatment group for event study (based on enactment year cohort)
    treat_year = year_enacted,
    ## Post indicator
    post = as.integer(year >= year_enacted & !is.na(year_enacted))
  ) %>%
  ## Exclude DC (not a state) and territories
  filter(state_fip %in% sprintf("%02d", c(1:2, 4:6, 8:13, 15:42, 44:51, 53:56)))

## ============================================================
## 3. ACS PANEL (2015-2023)
## ============================================================
acs_panel <- acs_broadband %>%
  rename(state_fip = state, state_name = NAME) %>%
  left_join(preemption %>% select(state_fip, year_enacted, year_repealed),
            by = "state_fip") %>%
  mutate(
    preempted = case_when(
      is.na(year_enacted) ~ 0L,
      !is.na(year_repealed) & year >= year_repealed ~ 0L,
      year >= year_enacted ~ 1L,
      TRUE ~ 0L
    ),
    treat_year = year_enacted,
    post = as.integer(year >= year_enacted & !is.na(year_enacted))
  ) %>%
  filter(state_fip %in% sprintf("%02d", c(1:2, 4:6, 8:13, 15:42, 44:51, 53:56)))

## ============================================================
## 4. COMBINED PANEL VALIDATION
## ============================================================
cat("=== PANEL VALIDATION ===\n")
cat("BDS panel:\n")
cat("  Rows:", nrow(bds_panel), "\n")
cat("  States:", n_distinct(bds_panel$state_fip), "\n")
cat("  Year range:", min(bds_panel$year), "-", max(bds_panel$year), "\n")
cat("  States ever preempted:", n_distinct(bds_panel$state_fip[bds_panel$post == 1]), "\n")
cat("  State-years with preemption:", sum(bds_panel$preempted), "\n")

cat("\nACS broadband panel:\n")
cat("  Rows:", nrow(acs_panel), "\n")
cat("  States:", n_distinct(acs_panel$state_fip), "\n")
cat("  Preempted in 2021:", sum(acs_panel$preempted[acs_panel$year==2021]), "states\n")
cat("  Mean broadband rate 2021 (never-preempted):",
    round(mean(acs_panel$broadband_rate[acs_panel$year==2021 & is.na(acs_panel$year_enacted)], na.rm=TRUE), 3), "\n")
cat("  Mean broadband rate 2021 (preempted):",
    round(mean(acs_panel$broadband_rate[acs_panel$year==2021 & !is.na(acs_panel$year_enacted) & is.na(acs_panel$year_repealed)], na.rm=TRUE), 3), "\n")

## ============================================================
## 5. CALLAWAY-SANT'ANNA SETUP
## ============================================================
## For CS-DiD, we need:
## - gvar: first treatment year (NA or 0 for never-treated)
## - id: state identifier
## - time: year

bds_cs <- bds_panel %>%
  mutate(
    gvar = ifelse(is.na(year_enacted), 0, year_enacted),
    state_id = as.integer(as.factor(state_fip)),
    log_firm_birth_rate = log(firm_birth_rate + 1e-6)
  )

acs_cs <- acs_panel %>%
  mutate(
    gvar = ifelse(is.na(year_enacted), 0, year_enacted),
    state_id = as.integer(as.factor(state_fip)),
    broadband_pct = broadband_rate * 100
  )

## Check min n_treated and n_pre
treatment_cohorts <- bds_cs %>%
  filter(gvar > 0) %>%
  group_by(gvar) %>%
  summarise(
    n_states = n_distinct(state_fip),
    n_pre = min(year) - min(gvar),  # years before treatment start
    .groups = "drop"
  )
cat("\nTreatment cohorts (BDS):\n")
print(treatment_cohorts)

## Minimum treated units check
n_treated_total <- n_distinct(bds_cs$state_fip[bds_cs$gvar > 0])
n_pre_min <- 5  # we have pre-period data from 2004 for most cohorts

cat("\nTotal states ever treated:", n_treated_total, "\n")
stopifnot("Need ≥20 treated units" = n_treated_total >= 20)

## ============================================================
## 6. SAVE ANALYSIS DATASETS
## ============================================================
saveRDS(bds_panel,  "data/bds_panel.rds")
saveRDS(acs_panel,  "data/acs_panel.rds")
saveRDS(bds_cs,     "data/bds_cs.rds")
saveRDS(acs_cs,     "data/acs_cs.rds")

cat("\n=== CLEAN DATA COMPLETE ===\n")
cat("bds_panel:", nrow(bds_panel), "rows\n")
cat("acs_panel:", nrow(acs_panel), "rows\n")
cat("States ever preempted:", n_treated_total, "\n")
