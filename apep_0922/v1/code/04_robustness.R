## 04_robustness.R — Robustness checks and mechanism tests
## APEP paper apep_0922: Alkaline Hydrolysis and Funeral Industry Competition

source("00_packages.R")

## ── Load data ────────────────────────────────────────────────────────────────
results <- readRDS("../data/main_results.rds")
county_did <- results$county_did
state_did <- results$state_did
county_220 <- readRDS("../data/county_panel_220.rds")
state_220 <- readRDS("../data/state_panel_220.rds")

## ── ROBUSTNESS 1: Leave-one-cohort-out ───────────────────────────────────────
cohorts <- unique(county_did[cohort > 0, cohort])
loo_results <- lapply(cohorts, function(g) {
  message(sprintf("Leave-one-out: dropping cohort %d", g))
  sub <- county_did[cohort != g]
  sub[, county_id := as.numeric(as.factor(county_fips))]

  cs_loo <- tryCatch(
    att_gt(yname = "estabs", tname = "year", idname = "county_id",
           gname = "cohort", data = as.data.frame(sub),
           control_group = "notyettreated", base_period = "universal",
           anticipation = 0, clustervars = "state_fips"),
    error = function(e) { message("  CS-DiD failed: ", e$message); NULL }
  )
  if (is.null(cs_loo)) return(data.table(dropped_cohort = g, att = NA_real_, se = NA_real_))

  agg <- aggte(cs_loo, type = "simple")
  data.table(dropped_cohort = g, att = agg$overall.att, se = agg$overall.se)
})
loo_dt <- rbindlist(loo_results)
message("\n=== Leave-one-cohort-out results ===")
print(loo_dt)

## ── ROBUSTNESS 2: Never-treated only as control group ────────────────────────
county_did[, county_id := as.numeric(as.factor(county_fips))]

cs_never <- tryCatch(
  att_gt(yname = "estabs", tname = "year", idname = "county_id",
         gname = "cohort", data = as.data.frame(county_did),
         control_group = "nevertreated", base_period = "universal",
         anticipation = 0, clustervars = "state_fips"),
  error = function(e) { message("Never-treated CS-DiD failed: ", e$message); NULL }
)
if (!is.null(cs_never)) {
  agg_never <- aggte(cs_never, type = "simple")
  message("\n=== Never-treated control: Overall ATT ===")
  summary(agg_never)
}

## ── MECHANISM 1: NAICS 812220 (Cemeteries/Crematories) ──────────────────────
## If AH substitutes for cremation, we might see effects on crematories
county_220_did <- county_220[cohort == 0 | cohort >= 2017]
county_220_did <- county_220_did[nchar(area_fips) == 5 & !grepl("000$", area_fips)]
county_220_did[, county_id := as.numeric(as.factor(county_fips))]
county_220_did[, estabs := as.numeric(annual_avg_estabs)]

cs_220 <- tryCatch(
  att_gt(yname = "estabs", tname = "year", idname = "county_id",
         gname = "cohort", data = as.data.frame(county_220_did),
         control_group = "notyettreated", base_period = "universal",
         anticipation = 0, clustervars = "state_fips"),
  error = function(e) { message("812220 CS-DiD failed: ", e$message); NULL }
)
if (!is.null(cs_220)) {
  agg_220 <- aggte(cs_220, type = "simple")
  message("\n=== NAICS 812220 (Cemeteries/Crematories): Overall ATT ===")
  summary(agg_220)
}

## State-level 812220 employment
state_220_did <- state_220[cohort == 0 | cohort >= 2017]
state_220_did[, employment := as.numeric(annual_avg_emplvl)]
state_220_did <- state_220_did[employment > 0]
state_220_did[, ln_empl := log(employment)]
state_220_did[, state_id := as.numeric(as.factor(state_fips))]
state_220_did[, treated := as.integer(cohort > 0 & year >= cohort)]

twfe_220_empl <- feols(ln_empl ~ treated | state_fips + year,
                       data = state_220_did, cluster = ~state_fips)
message("\n=== TWFE 812220 employment ===")
summary(twfe_220_empl)

## ── MECHANISM 2: Heterogeneity by urbanicity ────────────────────────────────
## Use state_fips to approximate metro vs. non-metro
## Counties in top-population states (CA, NY, TX, FL, IL) vs. others
large_states <- c("06", "36", "48", "12", "17")
county_did[, large_state := as.integer(state_fips %in% large_states)]

## Split by state population size (proxy for urbanicity)
twfe_large <- feols(estabs ~ treated | county_fips + year,
                    data = county_did[large_state == 1], cluster = ~state_fips)
twfe_small <- feols(estabs ~ treated | county_fips + year,
                    data = county_did[large_state == 0], cluster = ~state_fips)

message("\n=== Heterogeneity: Large states ===")
summary(twfe_large)
message("\n=== Heterogeneity: Small states ===")
summary(twfe_small)

## ── ROBUSTNESS 3: State-level establishments (no suppression concern) ────────
state_panel <- readRDS("../data/state_panel.rds")
state_estabs <- state_panel[cohort == 0 | cohort >= 2017]
state_estabs[, state_id := as.numeric(as.factor(state_fips))]

cs_state_estabs <- tryCatch(
  att_gt(yname = "estabs", tname = "year", idname = "state_id",
         gname = "cohort", data = as.data.frame(state_estabs),
         control_group = "notyettreated", base_period = "universal",
         anticipation = 0),
  error = function(e) { message("State estabs CS-DiD failed: ", e$message); NULL }
)
if (!is.null(cs_state_estabs)) {
  agg_state_estabs <- aggte(cs_state_estabs, type = "simple")
  message("\n=== State-level establishments: Overall ATT ===")
  summary(agg_state_estabs)
}

## ── Save robustness results ──────────────────────────────────────────────────
robust <- list(
  loo_dt = loo_dt,
  cs_never = cs_never,
  agg_never = if (exists("agg_never")) agg_never else NULL,
  cs_220 = cs_220,
  agg_220 = if (exists("agg_220")) agg_220 else NULL,
  twfe_220_empl = twfe_220_empl,
  twfe_large = twfe_large,
  twfe_small = twfe_small,
  cs_state_estabs = cs_state_estabs,
  agg_state_estabs = if (exists("agg_state_estabs")) agg_state_estabs else NULL
)
saveRDS(robust, "../data/robustness_results.rds")
message("\nRobustness analysis complete.")
