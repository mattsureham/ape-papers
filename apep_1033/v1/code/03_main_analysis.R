## 03_main_analysis.R — Main DiD estimation
## APEP-1033: Pouring Risk — Raw Milk Legalization and Foodborne Illness

source("00_packages.R")

cat("=== Main Analysis ===\n")

## ---- Load data ----
panel    <- read_csv("../data/panel.csv", show_col_types = FALSE)
panel_cs <- read_csv("../data/panel_cs.csv", show_col_types = FALSE)

## Create numeric state ID for CS
panel_cs <- panel_cs %>%
  mutate(state_id = as.integer(as.factor(state)))

## ---- 1. TWFE Poisson — Full Panel (Main Specification) ----
cat("\n--- TWFE Poisson: Full Panel ---\n")

## Main outcome: unpasteurized dairy outbreaks
m1_pois <- fepois(outbreaks_unpast ~ legal | state_abbr + year,
                  data = panel, cluster = ~state_abbr)
cat("TWFE Poisson — Outbreaks:\n")
summary(m1_pois)

## Illnesses
m2_pois <- fepois(illnesses_unpast ~ legal | state_abbr + year,
                  data = panel, cluster = ~state_abbr)
cat("\nTWFE Poisson — Illnesses:\n")
summary(m2_pois)

## Hospitalizations
m3_pois <- fepois(hosp_unpast ~ legal | state_abbr + year,
                  data = panel, cluster = ~state_abbr)
cat("\nTWFE Poisson — Hospitalizations:\n")
summary(m3_pois)

## ---- 2. TWFE Poisson — CS Sample Only (Newly-treated + Never-treated) ----
cat("\n--- TWFE Poisson: CS Sample (newly-treated + never-treated) ---\n")

m4_pois <- fepois(outbreaks_unpast ~ post | state_abbr + year,
                  data = panel_cs, cluster = ~state_abbr)
cat("TWFE Poisson (CS sample) — Outbreaks:\n")
summary(m4_pois)

## ---- 3. OLS on binary outcome (extensive margin) ----
cat("\n--- OLS: Any outbreak (extensive margin) ---\n")

panel_cs <- panel_cs %>%
  mutate(any_outbreak = as.integer(outbreaks_unpast > 0))

m5_ols <- feols(any_outbreak ~ post | state_abbr + year,
                data = panel_cs, cluster = ~state_abbr)
cat("OLS — Any outbreak:\n")
summary(m5_ols)

## ---- 4. Callaway-Sant'Anna ----
cat("\n--- Callaway-Sant'Anna ---\n")

## CS requires first_treat_cs > 0 for treated, = 0 for never-treated
## Outcome: binary (any outbreak) for CS since counts violate parallel trends in levels
cs_data <- panel_cs %>%
  filter(!is.na(first_treat_cs)) %>%
  mutate(first_treat_cs = as.integer(first_treat_cs))

cat("CS data:", nrow(cs_data), "obs,",
    n_distinct(cs_data$state_id), "states\n")
cat("Treatment groups:\n")
print(table(cs_data$first_treat_cs[cs_data$year == 2000]))

## CS on binary outcome
cs_out <- tryCatch({
  att_gt(
    yname    = "any_outbreak",
    tname    = "year",
    idname   = "state_id",
    gname    = "first_treat_cs",
    data     = as.data.frame(cs_data),
    control_group = "nevertreated",
    base_period   = "universal"
  )
}, error = function(e) {
  cat("CS estimation error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_out)) {
  cat("\nCS group-time ATTs:\n")
  print(summary(cs_out))

  ## Aggregate to overall ATT
  cs_agg <- aggte(cs_out, type = "simple")
  cat("\nCS Overall ATT:\n")
  print(summary(cs_agg))

  ## Event study aggregation
  cs_es <- aggte(cs_out, type = "dynamic", min_e = -7, max_e = 10)
  cat("\nCS Event Study:\n")
  print(summary(cs_es))

  ## Save CS results
  saveRDS(cs_out, "../data/cs_results.rds")
  saveRDS(cs_es,  "../data/cs_event_study.rds")
}

## ---- 5. Event Study — TWFE Poisson ----
cat("\n--- Event Study: TWFE Poisson ---\n")

## Create event time for newly-treated states
panel_es <- panel_cs %>%
  filter(first_treat_cs > 0 | first_treat_cs == 0) %>%
  mutate(
    event_time = ifelse(first_treat_cs > 0, year - first_treat_cs, NA_integer_)
  )

## For never-treated, event_time stays NA (they serve as controls in fixest)
## Bin endpoints
panel_es <- panel_es %>%
  mutate(
    event_time_binned = case_when(
      is.na(event_time)   ~ NA_integer_,
      event_time <= -7     ~ -7L,
      event_time >= 10     ~ 10L,
      TRUE                 ~ as.integer(event_time)
    )
  )

## TWFE Poisson event study using Sun-Abraham via fixest
## sunab() requires cohort and year
m_es_pois <- tryCatch({
  fepois(outbreaks_unpast ~ sunab(first_treat_cs, year) | state_abbr + year,
         data = panel_cs %>% filter(first_treat_cs != 0 | first_treat_cs == 0),
         cluster = ~state_abbr)
}, error = function(e) {
  cat("sunab Poisson failed:", conditionMessage(e), "\n")
  ## Fallback: manual event-time dummies
  NULL
})

if (!is.null(m_es_pois)) {
  cat("Sun-Abraham Poisson event study:\n")
  summary(m_es_pois)
  saveRDS(m_es_pois, "../data/es_poisson.rds")
}

## ---- 6. Negative Binomial (robustness for overdispersion) ----
cat("\n--- Negative Binomial ---\n")
m_nb <- tryCatch({
  femlm(outbreaks_unpast ~ legal | state_abbr + year,
        data = panel, family = "negbin", cluster = ~state_abbr)
}, error = function(e) {
  cat("NegBin failed:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(m_nb)) {
  cat("Negative Binomial:\n")
  summary(m_nb)
}

## ---- Save main results ----
results <- list(
  twfe_pois_outbreaks  = m1_pois,
  twfe_pois_illnesses  = m2_pois,
  twfe_pois_hosp       = m3_pois,
  twfe_pois_cs_sample  = m4_pois,
  ols_any_outbreak     = m5_ols,
  negbin               = m_nb
)
saveRDS(results, "../data/main_results.rds")

## ---- Diagnostics JSON ----
cat("\n=== Writing diagnostics.json ===\n")

## n_treated: states with any legal raw milk (always + newly treated)
n_treated_all <- n_distinct(panel$state_abbr[panel$legal == 1])
## n_treated identifying: newly treated states (changed during sample)
n_treated_cs  <- n_distinct(panel_cs$state_abbr[panel_cs$first_treat_cs > 0])
## n_pre: max pre-treatment periods for earliest cohort (2005 - 1998 = 7)
n_pre <- min(panel_cs$first_treat_cs[panel_cs$first_treat_cs > 0]) - min(panel_cs$year)

diag <- list(
  n_treated  = n_treated_all,
  n_treated_identifying = n_treated_cs,
  n_pre      = n_pre,
  n_obs      = nrow(panel),
  n_clusters = n_distinct(panel$state_abbr),
  outcome_mean = mean(panel$outbreaks_unpast),
  outcome_sd   = sd(panel$outbreaks_unpast),
  zero_share   = mean(panel$outbreaks_unpast == 0)
)

jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("diagnostics.json written:\n")
print(diag)

cat("\n=== Main analysis complete ===\n")
