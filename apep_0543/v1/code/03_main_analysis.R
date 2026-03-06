##============================================================
## 03_main_analysis.R — Main regression analysis
## APEP-0543: Rent Control and Property Values in France
##============================================================

source("00_packages.R")

data_dir <- "../data/"

## ─── Load data ───────────────────────────────────────────
analysis <- as.data.table(read_parquet(file.path(data_dir, "dvf_analysis.parquet")))
panel <- as.data.table(read_parquet(file.path(data_dir, "dvf_panel.parquet")))

cat("Loaded", nrow(analysis), "transactions\n")
cat("Loaded", nrow(panel), "commune-quarter observations\n")

## ─── Log price ───────────────────────────────────────────
analysis[, log_price := log(valeur_fonciere)]
analysis[, log_price_sqm := log(price_sqm)]

## ──────────────────────────────────────────────────────────
## SPECIFICATION 1: Simple DiD (no property-type interaction)
## Tests whether rent control affects ALL property prices
## ──────────────────────────────────────────────────────────

cat("\n=== SPECIFICATION 1: Simple DiD ===\n")

## Identified sample excludes always-treated cities (defined below)
## TWFE baseline (identified sample)
## Note: always_treated defined in Spec 2 below; we define it here too
always_treated_cities <- c("Paris", "Lille")
identified_twfe <- analysis[is.na(treat_city) | !(treat_city %in% always_treated_cities)]

spec1_twfe <- feols(
  log_price ~ post_treatment |
    code_commune + year_quarter,
  data = identified_twfe,
  cluster = ~code_commune
)
summary(spec1_twfe)

## With property controls (identified sample)
spec1_controls <- feols(
  log_price ~ post_treatment + investment_type +
    surface_reelle_bati + I(surface_reelle_bati^2) +
    nombre_pieces_principales |
    code_commune + year_quarter,
  data = identified_twfe[!is.na(surface_reelle_bati)],
  cluster = ~code_commune
)
summary(spec1_controls)

## ──────────────────────────────────────────────────────────
## SPECIFICATION 2: DDD (Triple-Difference)
## IDENTIFIED SAMPLE: Exclude Paris & Lille (no pre-treatment data)
## ──────────────────────────────────────────────────────────

cat("\n=== SPECIFICATION 2: Triple-Difference (DDD) — IDENTIFIED SAMPLE ===\n")

## Identified sample: cities with pre-treatment data only
always_treated <- c("Paris", "Lille")
identified <- analysis[is.na(treat_city) | !(treat_city %in% always_treated)]
cat("Identified sample:", nrow(identified), "transactions\n")
cat("  Treated communes:", sum(identified$treated_commune), "\n")
cat("  Control cities:", sum(identified$control_city), "\n")

## β₂ = Differential effect on investment-type properties (identified sample)
spec2_ddd <- feols(
  log_price ~ post_treatment * investment_type |
    code_commune + year_quarter,
  data = identified,
  cluster = ~code_commune
)
summary(spec2_ddd)

## DDD with property controls (identified sample)
spec2_ddd_controls <- feols(
  log_price ~ post_treatment * investment_type +
    surface_reelle_bati + I(surface_reelle_bati^2) +
    nombre_pieces_principales |
    code_commune + year_quarter,
  data = identified[!is.na(surface_reelle_bati)],
  cluster = ~code_commune
)
summary(spec2_ddd_controls)

## DDD with price per sqm (identified sample)
spec2_ddd_sqm <- feols(
  log_price_sqm ~ post_treatment * investment_type |
    code_commune + year_quarter,
  data = identified[!is.na(price_sqm)],
  cluster = ~code_commune
)
summary(spec2_ddd_sqm)

## ──────────────────────────────────────────────────────────
## SPECIFICATION 2b: Full-sample DDD (including Paris & Lille)
## Reported as supplementary — NOT the headline result
## ──────────────────────────────────────────────────────────

cat("\n=== SPECIFICATION 2b: Full-Sample DDD (supplementary) ===\n")

spec2_full <- feols(
  log_price ~ post_treatment * investment_type |
    code_commune + year_quarter,
  data = analysis,
  cluster = ~code_commune
)
summary(spec2_full)

## ──────────────────────────────────────────────────────────
## SPECIFICATION 3: Continuous rental exposure score (identified sample)
## ──────────────────────────────────────────────────────────

cat("\n=== SPECIFICATION 3: Continuous Rental Score ===\n")

spec3_cont <- feols(
  log_price ~ post_treatment * rental_score |
    code_commune + year_quarter,
  data = identified,
  cluster = ~code_commune
)
summary(spec3_cont)

## ──────────────────────────────────────────────────────────
## SPECIFICATION 4: Event study (staggered DiD)
## Using relative time to treatment
## ──────────────────────────────────────────────────────────

cat("\n=== SPECIFICATION 4: Event Study ===\n")

## Create relative time variable (in quarters)
analysis[, treat_date_num := as.numeric(treat_date)]
analysis[, mutation_date_num := as.numeric(date_mutation)]

## For treated communes: quarters relative to treatment
analysis[treated_commune == TRUE,
         rel_quarter := floor(as.numeric(difftime(date_mutation, treat_date,
                                                   units = "days")) / 91.25)]
analysis[treated_commune == FALSE, rel_quarter := NA_integer_]

## Bin relative time: -8 to +12 quarters (cap at extremes)
analysis[, rel_quarter_binned := pmax(-8, pmin(12, rel_quarter))]

## Event study using i() for relative time (identified sample only)
## Create relative year variable for identified sample
identified[treated_commune == TRUE,
           rel_year := year - year(treat_date)]
identified[treated_commune == FALSE, rel_year := NA_integer_]
identified[, rel_year_binned := pmax(-2, pmin(3, rel_year))]

cat("Relative year distribution (identified sample):\n")
print(table(identified[treated_commune == TRUE, rel_year_binned]))

## Event study: Investment properties (identified sample)
es_invest <- feols(
  log_price ~ i(rel_year_binned, treated_commune, ref = -1) |
    code_commune + year,
  data = identified[investment_type == TRUE],
  cluster = ~code_commune
)
summary(es_invest)

## Event study: Owner-occupier properties (identified sample, placebo)
es_owner <- feols(
  log_price ~ i(rel_year_binned, treated_commune, ref = -1) |
    code_commune + year,
  data = identified[investment_type == FALSE],
  cluster = ~code_commune
)
summary(es_owner)

## Save event study coefficients as clean CSV for 05_figures.R
es_invest_coefs <- as.data.table(coeftable(es_invest), keep.rownames = TRUE)
setnames(es_invest_coefs, "rn", "term")
## Extract relative year from term name
es_invest_coefs[, rel_period := as.numeric(gsub(".*::(-?[0-9]+):.*", "\\1", term))]
es_invest_coefs[, type := "Investment Properties"]

es_owner_coefs <- as.data.table(coeftable(es_owner), keep.rownames = TRUE)
setnames(es_owner_coefs, "rn", "term")
es_owner_coefs[, rel_period := as.numeric(gsub(".*::(-?[0-9]+):.*", "\\1", term))]
es_owner_coefs[, type := "Owner-Occupier Properties"]

es_plot_data <- rbind(es_invest_coefs, es_owner_coefs)
setnames(es_plot_data, c("Estimate", "Std. Error"), c("estimate", "se"))
es_plot_data[, ci_low := estimate - 1.96 * se]
es_plot_data[, ci_high := estimate + 1.96 * se]
fwrite(es_plot_data[, .(rel_period, estimate, se, ci_low, ci_high, type)],
       file.path(data_dir, "event_study_plot_data.csv"))

## ──────────────────────────────────────────────────────────
## SPECIFICATION 5: City-by-city estimates
## ──────────────────────────────────────────────────────────

cat("\n=== SPECIFICATION 5: City-by-City ===\n")

city_results <- list()
treated_cities <- unique(analysis[treated_commune == TRUE, treat_city])
control_data <- analysis[control_city == TRUE]

for (city in treated_cities) {
  cat("  Estimating for:", city, "... ")
  city_data <- rbind(
    analysis[treat_city == city],
    control_data
  )

  tryCatch({
    city_reg <- feols(
      log_price ~ post_treatment * investment_type |
        code_commune + year_quarter,
      data = city_data,
      cluster = ~code_commune
    )

    coefs <- coeftable(city_reg)
    ddd_row <- coefs["post_treatmentTRUE:investment_typeTRUE", ]

    city_results[[city]] <- data.table(
      city = city,
      ddd_coef = ddd_row["Estimate"],
      ddd_se = ddd_row["Std. Error"],
      ddd_pval = ddd_row["Pr(>|t|)"],
      n_obs = nrow(city_data),
      n_treated = sum(city_data$treated_commune)
    )
    cat("done (β =", round(ddd_row["Estimate"], 4), ")\n")
  }, error = function(e) {
    cat("FAILED:", e$message, "\n")
  })
}

city_results_dt <- rbindlist(city_results)
fwrite(city_results_dt, file.path(data_dir, "city_by_city_results.csv"))

cat("\nCity-by-city results:\n")
print(city_results_dt)

## ──────────────────────────────────────────────────────────
## SPECIFICATION 6: Stacked DiD (robust to TWFE bias)
## Addresses Goodman-Bacon (2021) concern about staggered timing
## ──────────────────────────────────────────────────────────

cat("\n=== SPECIFICATION 6: Stacked DiD ===\n")

## Stack: each cohort paired with never-treated controls
cohort_dates <- unique(identified[treated_commune == TRUE, .(treat_city, treat_date)])
control_obs <- identified[control_city == TRUE]

stacked_list <- list()
for (j in seq_len(nrow(cohort_dates))) {
  city_j <- cohort_dates$treat_city[j]
  treated_j <- identified[treat_city == city_j]
  sub_j <- rbind(treated_j, control_obs)
  sub_j[, cohort := city_j]
  stacked_list[[j]] <- sub_j
}
stacked <- rbindlist(stacked_list)
stacked[, cohort_commune := paste0(cohort, "_", code_commune)]

spec6_stacked <- feols(
  log_price ~ post_treatment * investment_type |
    cohort_commune + cohort^year_quarter,
  data = stacked,
  cluster = ~code_commune
)
summary(spec6_stacked)
cat("Stacked DDD (robust to TWFE bias):",
    round(coef(spec6_stacked)["post_treatmentTRUE:investment_typeTRUE"], 4), "\n")

rm(stacked, stacked_list)

## ──────────────────────────────────────────────────────────
## SAVE ALL RESULTS
## ──────────────────────────────────────────────────────────

## Main results table
results_list <- list(
  "TWFE" = spec1_twfe,
  "TWFE + Controls" = spec1_controls,
  "DDD" = spec2_ddd,
  "DDD + Controls" = spec2_ddd_controls,
  "DDD (per sqm)" = spec2_ddd_sqm,
  "Continuous Score" = spec3_cont,
  "Full-Sample DDD" = spec2_full
)

## Save coefficient summaries
coef_summary <- lapply(names(results_list), function(nm) {
  mod <- results_list[[nm]]
  ct <- coeftable(mod)
  data.table(
    spec = nm,
    term = rownames(ct),
    estimate = ct[, "Estimate"],
    se = ct[, "Std. Error"],
    pval = ct[, "Pr(>|t|)"],
    n = mod$nobs
  )
})
coef_summary <- rbindlist(coef_summary)
fwrite(coef_summary, file.path(data_dir, "main_results.csv"))

## Save event study coefficients
es_invest_dt <- as.data.table(coeftable(es_invest))
es_invest_dt[, type := "Investment"]
es_owner_dt <- as.data.table(coeftable(es_owner))
es_owner_dt[, type := "Owner-Occupier"]
es_combined <- rbind(es_invest_dt, es_owner_dt, fill = TRUE)
fwrite(es_combined, file.path(data_dir, "event_study_results.csv"))

## Save models for table generation
saveRDS(results_list, file.path(data_dir, "main_models.rds"))
saveRDS(es_invest, file.path(data_dir, "es_invest_model.rds"))
saveRDS(es_owner, file.path(data_dir, "es_owner_model.rds"))

cat("\n03_main_analysis.R complete.\n")
cat("Main results saved to data/main_results.csv\n")
cat("Event study results saved to data/event_study_results.csv\n")
