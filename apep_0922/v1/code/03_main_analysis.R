## 03_main_analysis.R — Main DiD analysis
## APEP paper apep_0922: Alkaline Hydrolysis and Funeral Industry Competition

source("00_packages.R")

## ── Load data ────────────────────────────────────────────────────────────────
county <- readRDS("../data/county_panel.rds")
state_panel <- readRDS("../data/state_panel.rds")

## ── ANALYSIS 1: County-level establishments (CS-DiD) ─────────────────────────
## Only include cohorts with pre-treatment data (2017+) and never-treated (0)
county_did <- county[cohort == 0 | cohort >= 2017]
message(sprintf("County DiD sample: %d obs, %d counties, %d states",
                nrow(county_did), uniqueN(county_did$county_fips),
                uniqueN(county_did$state_fips)))

## Create numeric county ID for did package
county_did[, county_id := as.numeric(as.factor(county_fips))]

## Callaway-Sant'Anna (2021)
## gname = first treatment year (0 = never treated)
## idname = unit identifier
## tname = time variable
## yname = outcome
## control_group = "notyettreated" preferred
cs_estabs <- att_gt(
  yname = "estabs",
  tname = "year",
  idname = "county_id",
  gname = "cohort",
  data = as.data.frame(county_did),
  control_group = "notyettreated",
  clustervars = "state_fips",
  base_period = "universal",
  anticipation = 0
)

## Aggregate to overall ATT
agg_estabs <- aggte(cs_estabs, type = "simple")
message("\n=== COUNTY ESTABLISHMENTS: Overall ATT ===")
summary(agg_estabs)

## Event study aggregation
es_estabs <- aggte(cs_estabs, type = "dynamic", min_e = -5, max_e = 5)
message("\n=== COUNTY ESTABLISHMENTS: Event Study ===")
summary(es_estabs)

## ── ANALYSIS 2: State-level employment (CS-DiD) ─────────────────────────────
state_did <- state_panel[cohort == 0 | cohort >= 2017]

## Remove states with zero or missing employment
state_did <- state_did[employment > 0 & !is.na(ln_empl)]
state_did[, state_id := as.numeric(as.factor(state_fips))]

message(sprintf("\nState DiD sample: %d obs, %d states",
                nrow(state_did), uniqueN(state_did$state_fips)))

cs_empl <- att_gt(
  yname = "ln_empl",
  tname = "year",
  idname = "state_id",
  gname = "cohort",
  data = as.data.frame(state_did),
  control_group = "notyettreated",
  base_period = "universal",
  anticipation = 0
)

agg_empl <- aggte(cs_empl, type = "simple")
message("\n=== STATE EMPLOYMENT (log): Overall ATT ===")
summary(agg_empl)

es_empl <- aggte(cs_empl, type = "dynamic", min_e = -5, max_e = 5)

## ── ANALYSIS 3: State-level wages (CS-DiD) ──────────────────────────────────
state_did_wage <- state_did[avg_wkly_wage > 0 & !is.na(ln_wage)]

cs_wage <- att_gt(
  yname = "ln_wage",
  tname = "year",
  idname = "state_id",
  gname = "cohort",
  data = as.data.frame(state_did_wage),
  control_group = "notyettreated",
  base_period = "universal",
  anticipation = 0
)

agg_wage <- aggte(cs_wage, type = "simple")
message("\n=== STATE WAGES (log): Overall ATT ===")
summary(agg_wage)

es_wage <- aggte(cs_wage, type = "dynamic", min_e = -5, max_e = 5)

## ── ANALYSIS 4: TWFE comparison (for discussion) ────────────────────────────
## County-level TWFE
twfe_estabs <- feols(estabs ~ treated | county_fips + year,
                     data = county_did, cluster = ~state_fips)
message("\n=== TWFE: County establishments ===")
summary(twfe_estabs)

## State-level TWFE
twfe_empl <- feols(ln_empl ~ treated | state_fips + year,
                   data = state_did, cluster = ~state_fips)
twfe_wage <- feols(ln_wage ~ treated | state_fips + year,
                   data = state_did_wage, cluster = ~state_fips)

## ── Save results ─────────────────────────────────────────────────────────────
results <- list(
  cs_estabs = cs_estabs, agg_estabs = agg_estabs, es_estabs = es_estabs,
  cs_empl = cs_empl, agg_empl = agg_empl, es_empl = es_empl,
  cs_wage = cs_wage, agg_wage = agg_wage, es_wage = es_wage,
  twfe_estabs = twfe_estabs, twfe_empl = twfe_empl, twfe_wage = twfe_wage,
  county_did = county_did, state_did = state_did
)
saveRDS(results, "../data/main_results.rds")

## ── Write diagnostics.json ───────────────────────────────────────────────────
## n_treated = number of treated COUNTIES (not states)
## n_pre = median pre-periods across cohorts (most have 5+)
treated_counties <- uniqueN(county_did[cohort > 0, county_fips])
cohort_years <- unique(county_did[cohort > 0, cohort])
median_pre <- median(cohort_years - 2014)

diagnostics <- list(
  n_treated = treated_counties,
  n_pre = as.integer(median_pre),
  n_obs = nrow(county_did),
  n_counties = uniqueN(county_did$county_fips),
  n_states = uniqueN(county_did$state_fips),
  n_state_obs = nrow(state_did),
  att_estabs = agg_estabs$overall.att,
  se_estabs = agg_estabs$overall.se,
  att_empl = agg_empl$overall.att,
  se_empl = agg_empl$overall.se,
  att_wage = agg_wage$overall.att,
  se_wage = agg_wage$overall.se
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
message("\nDiagnostics written to data/diagnostics.json")
message("Main analysis complete.")
