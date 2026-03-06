##============================================================
## 04_robustness.R — Robustness checks and placebo tests
## APEP-0543: Rent Control and Property Values in France
##============================================================

source("00_packages.R")

data_dir <- "../data/"

## ─── Load data ───────────────────────────────────────────
analysis <- as.data.table(read_parquet(file.path(data_dir, "dvf_analysis.parquet")))
analysis[, log_price := log(valeur_fonciere)]
analysis[, log_price_sqm := log(price_sqm)]

cat("Loaded", nrow(analysis), "transactions\n")

## Identified sample: exclude always-treated cities
always_treated <- c("Paris", "Lille")
identified <- analysis[is.na(treat_city) | !(treat_city %in% always_treated)]
cat("Identified sample:", nrow(identified), "transactions\n")

## ──────────────────────────────────────────────────────────
## ROBUSTNESS 1: Leave-one-city-out (identified sample)
## Drop each treated city in turn
## ──────────────────────────────────────────────────────────

cat("\n=== ROBUSTNESS 1: Leave-One-Out ===\n")

treated_cities <- unique(identified[treated_commune == TRUE, treat_city])
loo_results <- list()

for (drop_city in treated_cities) {
  cat("  Dropping:", drop_city, "... ")
  loo_data <- identified[is.na(treat_city) | treat_city != drop_city]

  loo_reg <- feols(
    log_price ~ post_treatment * investment_type |
      code_commune + year_quarter,
    data = loo_data,
    cluster = ~code_commune
  )

  ct <- coeftable(loo_reg)
  ddd_row <- ct["post_treatmentTRUE:investment_typeTRUE", ]

  loo_results[[drop_city]] <- data.table(
    dropped_city = drop_city,
    ddd_coef = ddd_row["Estimate"],
    ddd_se = ddd_row["Std. Error"],
    ddd_pval = ddd_row["Pr(>|t|)"],
    n_obs = loo_reg$nobs
  )
  cat("β =", round(ddd_row["Estimate"], 4), "\n")
}

loo_dt <- rbindlist(loo_results)
fwrite(loo_dt, file.path(data_dir, "robustness_loo.csv"))

## ──────────────────────────────────────────────────────────
## ROBUSTNESS 2: Exclude COVID period (2020Q2-2020Q4)
## ──────────────────────────────────────────────────────────

cat("\n=== ROBUSTNESS 2: Exclude COVID ===\n")

identified[, covid_period := year_quarter %in% c("2020Q2", "2020Q3", "2020Q4")]

rob2_nocovid <- feols(
  log_price ~ post_treatment * investment_type |
    code_commune + year_quarter,
  data = identified[covid_period == FALSE],
  cluster = ~code_commune
)
summary(rob2_nocovid)

## ──────────────────────────────────────────────────────────
## ROBUSTNESS 3: Post-COVID cities only (Lyon, Bordeaux, Montpellier)
## These cities adopted rent control in 2021-2022, after COVID
## ──────────────────────────────────────────────────────────

cat("\n=== ROBUSTNESS 3: Post-COVID Cities Only ===\n")

postcovid_cities <- c("Lyon-Villeurbanne", "Montpellier", "Bordeaux")

rob3_postcovid <- feols(
  log_price ~ post_treatment * investment_type |
    code_commune + year_quarter,
  data = identified[treat_city %in% postcovid_cities | control_city == TRUE],
  cluster = ~code_commune
)
summary(rob3_postcovid)

## ──────────────────────────────────────────────────────────
## ROBUSTNESS 4: Property size bins (within apartments)
## Compare studios vs 2-room vs 3+ room apartments
## ──────────────────────────────────────────────────────────

cat("\n=== ROBUSTNESS 4: Size Heterogeneity ===\n")

identified[type_local == "Appartement", apt_size := fcase(
  nombre_pieces_principales <= 1, "Studio/1-room",
  nombre_pieces_principales == 2, "2-room",
  nombre_pieces_principales == 3, "3-room",
  nombre_pieces_principales >= 4, "4+-room"
)]

rob4_size <- feols(
  log_price ~ post_treatment * apt_size |
    code_commune + year_quarter,
  data = identified[type_local == "Appartement" & !is.na(apt_size)],
  cluster = ~code_commune
)
summary(rob4_size)

## Save size heterogeneity
rob4_ct <- as.data.table(coeftable(rob4_size), keep.rownames = TRUE)
rob4_ct[, spec := "size_heterogeneity"]
fwrite(rob4_ct, file.path(data_dir, "robustness_size_het.csv"))

## ──────────────────────────────────────────────────────────
## ROBUSTNESS 5: Wild cluster bootstrap (few treated clusters)
## ──────────────────────────────────────────────────────────

## ──────────────────────────────────────────────────────────
## ROBUSTNESS 4b: Stacked DiD (addresses TWFE bias concern)
## Stack each cohort × clean-control pair
## ──────────────────────────────────────────────────────────

cat("\n=== ROBUSTNESS 4b: Stacked DiD ===\n")

## Get cohort groups (identified sample only)
cohort_dates <- unique(identified[treated_commune == TRUE, .(treat_city, treat_date)])
control_obs <- identified[control_city == TRUE]

stacked_list <- list()
for (j in seq_len(nrow(cohort_dates))) {
  city_j <- cohort_dates$treat_city[j]
  date_j <- cohort_dates$treat_date[j]

  ## Treated communes for this cohort
  treated_j <- identified[treat_city == city_j]

  ## Combine with never-treated controls
  sub_j <- rbind(treated_j, control_obs)
  sub_j[, cohort := city_j]

  stacked_list[[j]] <- sub_j
}

stacked <- rbindlist(stacked_list)
stacked[, cohort_commune := paste0(cohort, "_", code_commune)]

## Stacked DDD with cohort-specific commune and time FEs
rob4b_stacked <- feols(
  log_price ~ post_treatment * investment_type |
    cohort_commune + cohort^year_quarter,
  data = stacked,
  cluster = ~code_commune
)
summary(rob4b_stacked)

stacked_ct <- coeftable(rob4b_stacked)
stacked_ddd <- stacked_ct["post_treatmentTRUE:investment_typeTRUE", ]
cat("Stacked DDD coefficient:", round(stacked_ddd["Estimate"], 4),
    "SE:", round(stacked_ddd["Std. Error"], 4),
    "p:", round(stacked_ddd["Pr(>|t|)"], 4), "\n")

## Save stacked result
stacked_result <- data.table(
  spec = "Stacked DDD",
  estimate = stacked_ddd["Estimate"],
  se = stacked_ddd["Std. Error"],
  pval = stacked_ddd["Pr(>|t|)"],
  n = rob4b_stacked$nobs
)
fwrite(stacked_result, file.path(data_dir, "robustness_stacked.csv"))

rm(stacked, stacked_list)  # free memory

cat("\n=== ROBUSTNESS 5: Wild Cluster Bootstrap ===\n")

## Run DDD on aggregated data (commune-quarter level) for WCB feasibility
panel <- as.data.table(read_parquet(file.path(data_dir, "dvf_panel.parquet")))
panel[!is.na(price_gap), log_gap := price_gap]

## Exclude always-treated cities from panel too
panel_identified <- panel[is.na(treat_city) | !(treat_city %in% always_treated)]

## WCB on the investment-owner price gap (identified sample)
tryCatch({
  wcb_model <- feols(
    log_gap ~ post |
      code_commune + year_quarter,
    data = panel_identified[!is.na(log_gap) & (treated_commune | control_city)],
    cluster = ~treat_city
  )

  ## boottest for WCB p-value
  wcb_result <- boot_aggregate(wcb_model, B = 999, param = "postTRUE",
                                clustid = ~treat_city)
  cat("WCB p-value:", wcb_result$p_val, "\n")

  saveRDS(wcb_result, file.path(data_dir, "wcb_result.rds"))
}, error = function(e) {
  cat("WCB failed (expected with few clusters):", e$message, "\n")
  cat("Will use randomization inference instead.\n")
})

## ──────────────────────────────────────────────────────────
## ROBUSTNESS 6: Randomization inference
## Permute treatment timing across cities
## ──────────────────────────────────────────────────────────

cat("\n=== ROBUSTNESS 6: Randomization Inference ===\n")

## Get actual DDD coefficient (identified sample)
actual_model <- feols(
  log_price ~ post_treatment * investment_type |
    code_commune + year_quarter,
  data = identified,
  cluster = ~code_commune
)
actual_coef <- coef(actual_model)["post_treatmentTRUE:investment_typeTRUE"]
cat("Actual DDD coefficient:", actual_coef, "\n")

## Permute: randomly shift treatment dates for identified cities
set.seed(42)
n_perms <- 500
perm_coefs <- numeric(n_perms)

## Simple permutation: shuffle the post_treatment indicator within communes
## by randomly reassigning treatment dates
for (i in seq_len(n_perms)) {
  if (i %% 100 == 0) cat("  Permutation", i, "/", n_perms, "\n")

  ## Randomly shift treatment dates by +/- 1-3 years
  shift_days <- sample(c(-1095:-365, 365:1095), 1)
  identified[, perm_post := FALSE]
  identified[treated_commune == TRUE,
             perm_post := date_mutation >= (treat_date + shift_days)]

  perm_model <- feols(
    log_price ~ perm_post * investment_type |
      code_commune + year_quarter,
    data = identified,
    cluster = ~code_commune,
    warn = FALSE
  )

  perm_coefs[i] <- tryCatch(
    coef(perm_model)["perm_postTRUE:investment_typeTRUE"],
    error = function(e) NA_real_
  )
}

identified[, perm_post := NULL]

## RI p-value
ri_pval <- mean(abs(perm_coefs) >= abs(actual_coef), na.rm = TRUE)
cat("RI p-value (two-sided):", ri_pval, "\n")

ri_results <- data.table(
  actual_coef = actual_coef,
  ri_pval = ri_pval,
  n_permutations = n_perms,
  perm_mean = mean(perm_coefs, na.rm = TRUE),
  perm_sd = sd(perm_coefs, na.rm = TRUE)
)
fwrite(ri_results, file.path(data_dir, "ri_results.csv"))

## Save permutation distribution
fwrite(data.table(perm_coef = perm_coefs), file.path(data_dir, "ri_distribution.csv"))

## ──────────────────────────────────────────────────────────
## ROBUSTNESS 7: HonestDiD sensitivity analysis
## ──────────────────────────────────────────────────────────

cat("\n=== ROBUSTNESS 7: HonestDiD Sensitivity ===\n")

## Run on a simplified event study for HonestDiD compatibility
## Need to use feols with i() for relative time (identified sample)
identified[treated_commune == TRUE,
           rel_year := year - year(treat_date)]
identified[treated_commune == FALSE, rel_year := NA_integer_]
identified[, rel_year_binned := pmax(-5, pmin(5, rel_year))]

## Event study for investment properties (identified sample)
es_for_honest <- feols(
  log_price ~ i(rel_year_binned, treated_commune, ref = -1) |
    code_commune + year,
  data = identified[investment_type == TRUE &
                    !is.na(rel_year_binned) |
                    (!treated_commune & investment_type == TRUE)],
  cluster = ~code_commune
)

tryCatch({
  ## Extract pre-treatment and post-treatment coefficients
  betahat <- coef(es_for_honest)
  sigma <- vcov(es_for_honest)

  ## Identify pre and post indices
  coef_names <- names(betahat)
  pre_idx <- grep("rel_year_binned::-[2-5]:", coef_names)
  post_idx <- grep("rel_year_binned::[0-5]:", coef_names)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    honest_result <- HonestDiD::createSensitivityResults(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 0.05, by = 0.01)
    )
    saveRDS(honest_result, file.path(data_dir, "honest_did_result.rds"))
    cat("HonestDiD sensitivity analysis complete.\n")
  } else {
    cat("Not enough pre/post periods for HonestDiD.\n")
  }
}, error = function(e) {
  cat("HonestDiD failed:", e$message, "\n")
})

## ──────────────────────────────────────────────────────────
## ROBUSTNESS 8: DDD with surface-only controls (no rooms)
## Addresses concern that room-count controls overlap with
## investment-type classification
## ──────────────────────────────────────────────────────────

cat("\n=== ROBUSTNESS 8: Surface-Only Controls ===\n")

rob8_surface <- feols(
  log_price ~ post_treatment * investment_type +
    surface_reelle_bati + I(surface_reelle_bati^2) |
    code_commune + year_quarter,
  data = identified[!is.na(surface_reelle_bati)],
  cluster = ~code_commune
)
summary(rob8_surface)

rob8_ct <- coeftable(rob8_surface)
rob8_ddd <- rob8_ct["post_treatmentTRUE:investment_typeTRUE", ]
cat("DDD with surface-only controls:", round(rob8_ddd["Estimate"], 4),
    "SE:", round(rob8_ddd["Std. Error"], 4),
    "p:", round(rob8_ddd["Pr(>|t|)"], 4), "\n")

## ──────────────────────────────────────────────────────────
## ROBUSTNESS 9: Commune × Investment-Type FE
## Saturated specification absorbing baseline price gaps
## between property types within each commune
## ──────────────────────────────────────────────────────────

cat("\n=== ROBUSTNESS 9: Commune × Investment FE ===\n")

identified[, commune_invest := paste0(code_commune, "_", investment_type)]

rob9_satfe <- feols(
  log_price ~ post_treatment : investment_type |
    commune_invest + year_quarter,
  data = identified,
  cluster = ~code_commune
)
summary(rob9_satfe)

rob9_ct <- coeftable(rob9_satfe)
cat("Commune×Invest FE DDD:\n")
print(rob9_ct)

## ──────────────────────────────────────────────────────────
## ROBUSTNESS 10: Stacked DDD with controls
## ──────────────────────────────────────────────────────────

cat("\n=== ROBUSTNESS 10: Stacked DDD + Controls ===\n")

## Rebuild stacked data
cohort_dates2 <- unique(identified[treated_commune == TRUE, .(treat_city, treat_date)])
control_obs2 <- identified[control_city == TRUE]

stacked_list2 <- list()
for (j in seq_len(nrow(cohort_dates2))) {
  city_j <- cohort_dates2$treat_city[j]
  treated_j <- identified[treat_city == city_j]
  sub_j <- rbind(treated_j, control_obs2)
  sub_j[, cohort := city_j]
  stacked_list2[[j]] <- sub_j
}
stacked2 <- rbindlist(stacked_list2)
stacked2[, cohort_commune := paste0(cohort, "_", code_commune)]

rob10_stacked_ctrl <- feols(
  log_price ~ post_treatment * investment_type +
    surface_reelle_bati + I(surface_reelle_bati^2) +
    nombre_pieces_principales |
    cohort_commune + cohort^year_quarter,
  data = stacked2[!is.na(surface_reelle_bati)],
  cluster = ~code_commune
)
summary(rob10_stacked_ctrl)

rob10_ct <- coeftable(rob10_stacked_ctrl)
rob10_ddd <- rob10_ct["post_treatmentTRUE:investment_typeTRUE", ]
cat("Stacked DDD + Controls:", round(rob10_ddd["Estimate"], 4),
    "SE:", round(rob10_ddd["Std. Error"], 4),
    "p:", round(rob10_ddd["Pr(>|t|)"], 4), "\n")

rm(stacked2, stacked_list2)

## ──────────────────────────────────────────────────────────
## ROBUSTNESS 11: RI on controlled specification
## ──────────────────────────────────────────────────────────

cat("\n=== ROBUSTNESS 11: RI on Controlled DDD ===\n")

actual_ctrl_model <- feols(
  log_price ~ post_treatment * investment_type +
    surface_reelle_bati + I(surface_reelle_bati^2) +
    nombre_pieces_principales |
    code_commune + year_quarter,
  data = identified[!is.na(surface_reelle_bati)],
  cluster = ~code_commune
)
actual_ctrl_coef <- coef(actual_ctrl_model)["post_treatmentTRUE:investment_typeTRUE"]
cat("Actual controlled DDD coefficient:", actual_ctrl_coef, "\n")

set.seed(123)
n_perms_ctrl <- 500
perm_ctrl_coefs <- numeric(n_perms_ctrl)

for (i in seq_len(n_perms_ctrl)) {
  if (i %% 100 == 0) cat("  Permutation", i, "/", n_perms_ctrl, "\n")
  shift_days <- sample(c(-1095:-365, 365:1095), 1)
  identified[, perm_post_ctrl := FALSE]
  identified[treated_commune == TRUE,
             perm_post_ctrl := date_mutation >= (treat_date + shift_days)]

  perm_ctrl_model <- feols(
    log_price ~ perm_post_ctrl * investment_type +
      surface_reelle_bati + I(surface_reelle_bati^2) +
      nombre_pieces_principales |
      code_commune + year_quarter,
    data = identified[!is.na(surface_reelle_bati)],
    cluster = ~code_commune,
    warn = FALSE
  )

  perm_ctrl_coefs[i] <- tryCatch(
    coef(perm_ctrl_model)["perm_post_ctrlTRUE:investment_typeTRUE"],
    error = function(e) NA_real_
  )
}

identified[, perm_post_ctrl := NULL]

ri_ctrl_pval <- mean(abs(perm_ctrl_coefs) >= abs(actual_ctrl_coef), na.rm = TRUE)
cat("RI p-value (controlled, two-sided):", ri_ctrl_pval, "\n")

ri_ctrl_results <- data.table(
  actual_coef = actual_ctrl_coef,
  ri_pval = ri_ctrl_pval,
  n_permutations = n_perms_ctrl,
  perm_mean = mean(perm_ctrl_coefs, na.rm = TRUE),
  perm_sd = sd(perm_ctrl_coefs, na.rm = TRUE)
)
fwrite(ri_ctrl_results, file.path(data_dir, "ri_controlled_results.csv"))

## Save RI controlled distribution
fwrite(data.table(perm_coef = perm_ctrl_coefs),
       file.path(data_dir, "ri_controlled_distribution.csv"))

## ──────────────────────────────────────────────────────────
## Save all robustness results
## ──────────────────────────────────────────────────────────

rob_models <- list(
  "No COVID" = rob2_nocovid,
  "Post-COVID cities" = rob3_postcovid,
  "Size heterogeneity" = rob4_size,
  "Surface-only controls" = rob8_surface,
  "Commune x Invest FE" = rob9_satfe,
  "Stacked DDD + Controls" = rob10_stacked_ctrl
)
saveRDS(rob_models, file.path(data_dir, "robustness_models.rds"))

cat("\n04_robustness.R complete.\n")
