## 03_main_analysis.R — Main DiD regressions
## apep_0832: The Access Cost of Fraud Prevention

source("00_packages.R")
setwd(gsub("/code$", "", getwd()))

panel <- fread("data/analysis_panel.csv")
cat("Panel loaded:", nrow(panel), "obs,", uniqueN(panel$state_code), "states,",
    length(unique(panel$year)), "years\n")

## ============================================================
## 1. Summary Statistics
## ============================================================
cat("\n=== Summary Statistics ===\n")

## Pre-treatment means
pre <- panel[post_ebt == 0]
post <- panel[post_ebt == 1]

cat("Pre-EBT LBW rate: mean =", round(mean(pre$lbw_rate_pct, na.rm=TRUE), 3),
    "%, SD =", round(sd(pre$lbw_rate_pct, na.rm=TRUE), 3), "%\n")
cat("Post-EBT LBW rate: mean =", round(mean(post$lbw_rate_pct, na.rm=TRUE), 3),
    "%, SD =", round(sd(post$lbw_rate_pct, na.rm=TRUE), 3), "%\n")

## ============================================================
## 2. TWFE (Baseline Specification)
## ============================================================
cat("\n=== TWFE Baseline ===\n")

## Main specification: LBW rate ~ EBT adoption + state FE + year FE
twfe_lbw <- feols(lbw_rate_pct ~ post_ebt | state_code + year,
                  data = panel, cluster = ~state_code)
summary(twfe_lbw)

## ============================================================
## 3. Callaway-Sant'Anna Staggered DiD
## ============================================================
cat("\n=== Callaway-Sant'Anna ===\n")

## For CS-DiD, we need: yname, tname, idname, gname
## Drop always-treated states (cohort <= 2010 = our first panel year)
## These states have no pre-treatment periods
cs_panel <- panel[cohort_year > min(year)]

## Recode never-treated: set cohort_year = 0 for states that could serve as controls
## But ALL states eventually adopt EBT. So we use "not-yet-treated" as comparison.

## Actually, all states adopted by 2019 in our data. The latest cohort is 2021.
## For CS-DiD, states are "not yet treated" until their cohort year.

## Create numeric state ID
cs_panel[, state_id := as.integer(as.factor(state_code))]

## Run CS-DiD
cs_result <- tryCatch({
  att_gt(
    yname = "lbw_rate_pct",
    tname = "year",
    idname = "state_id",
    gname = "cohort_year",
    data = as.data.frame(cs_panel),
    control_group = "notyettreated",
    est_method = "dr",
    bstrap = TRUE,
    cband = TRUE,
    biters = 1000
  )
}, error = function(e) {
  cat("CS-DiD error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(cs_result)) {
  cat("\nCS-DiD Group-Time ATTs:\n")
  summary(cs_result)

  ## Aggregate to overall ATT
  cs_agg <- aggte(cs_result, type = "simple")
  cat("\nOverall ATT:", round(cs_agg$overall.att, 4),
      "(SE:", round(cs_agg$overall.se, 4), ")\n")

  ## Dynamic effects (event study)
  cs_dynamic <- aggte(cs_result, type = "dynamic")
  cat("\nDynamic ATTs:\n")
  summary(cs_dynamic)
}

## ============================================================
## 4. Event Study (TWFE with leads/lags)
## ============================================================
cat("\n=== Event Study ===\n")

## Create relative time indicators
## Bin endpoints at -5 and +5
panel[, rel_time := pmin(pmax(years_since_ebt, -5), 5)]

## Drop the -1 period (reference)
panel[, rel_time_f := factor(rel_time)]

## Event study with fixest sunab()
## sunab() implements Sun-Abraham (2021) interaction-weighted estimator
es_model <- feols(lbw_rate_pct ~ sunab(cohort_year, year) | state_code + year,
                  data = panel[cohort_year > min(year)],
                  cluster = ~state_code)
cat("\nSun-Abraham Event Study:\n")
summary(es_model)

## ============================================================
## 5. Store key results
## ============================================================
results <- list(
  twfe_coef = coef(twfe_lbw)["post_ebt"],
  twfe_se = se(twfe_lbw)["post_ebt"],
  twfe_pval = pvalue(twfe_lbw)["post_ebt"],
  cs_att = if (!is.null(cs_result)) cs_agg$overall.att else NA,
  cs_se = if (!is.null(cs_result)) cs_agg$overall.se else NA,
  n_obs = nrow(panel),
  n_states = uniqueN(panel$state_code),
  n_years = length(unique(panel$year)),
  n_treated = sum(panel$post_ebt == 1),
  sd_lbw_pre = sd(panel$lbw_rate_pct[panel$post_ebt == 0], na.rm = TRUE),
  mean_lbw = mean(panel$lbw_rate_pct, na.rm = TRUE)
)

cat("\n=== Key Results ===\n")
cat("TWFE: beta =", round(results$twfe_coef, 4),
    " (SE =", round(results$twfe_se, 4),
    ", p =", round(results$twfe_pval, 4), ")\n")
cat("CS ATT:", round(results$cs_att, 4),
    " (SE =", round(results$cs_se, 4), ")\n")
cat("SDE (TWFE):", round(results$twfe_coef / results$sd_lbw_pre, 3), "\n")
cat("Pre-treatment SD(LBW):", round(results$sd_lbw_pre, 3), "%\n")

## Save results
saveRDS(results, "data/main_results.rds")

## Diagnostics for validator
jsonlite::write_json(list(
  n_treated = uniqueN(panel$state_code[panel$post_ebt == 1]),
  n_pre = length(unique(panel$year[panel$year < median(panel$cohort_year)])),
  n_obs = nrow(panel)
), "data/diagnostics.json", auto_unbox = TRUE)

cat("\nDiagnostics saved: n_treated =", uniqueN(panel$state_code[panel$post_ebt == 1]),
    ", n_pre =", length(unique(panel$year[panel$year < median(panel$cohort_year)])),
    ", n_obs =", nrow(panel), "\n")
