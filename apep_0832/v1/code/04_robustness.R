## 04_robustness.R — Robustness checks
## apep_0832: The Access Cost of Fraud Prevention

source("00_packages.R")
setwd(gsub("/code$", "", getwd()))

panel <- fread("data/analysis_panel.csv")

## ============================================================
## 1. State-Specific Linear Trends
## ============================================================
cat("=== Robustness 1: State-Specific Linear Trends ===\n")

panel[, state_trend := as.numeric(as.factor(state_code)) * year]
twfe_trend <- feols(lbw_rate_pct ~ post_ebt | state_code + year + state_code[year],
                    data = panel, cluster = ~state_code)
cat("With state trends: beta =", round(coef(twfe_trend)["post_ebt"], 4),
    " (SE =", round(se(twfe_trend)["post_ebt"], 4), ")\n")

## ============================================================
## 2. Restricted Sample — Drop Early Adopters
## ============================================================
cat("\n=== Robustness 2: Drop Early Adopters (pre-2010) ===\n")
## States adopting before 2010 have no pre-treatment periods in our panel
late_panel <- panel[ebt_year >= 2011]
cat("Sample: ", nrow(late_panel), "obs,", uniqueN(late_panel$state_code), "states\n")

twfe_late <- feols(lbw_rate_pct ~ post_ebt | state_code + year,
                   data = late_panel, cluster = ~state_code)
cat("Late adopters only: beta =", round(coef(twfe_late)["post_ebt"], 4),
    " (SE =", round(se(twfe_late)["post_ebt"], 4), ")\n")

## CS-DiD on late adopters
late_panel[, state_id := as.integer(as.factor(state_code))]
cs_late <- tryCatch({
  att_gt(
    yname = "lbw_rate_pct",
    tname = "year",
    idname = "state_id",
    gname = "cohort_year",
    data = as.data.frame(late_panel),
    control_group = "notyettreated",
    est_method = "dr",
    bstrap = TRUE,
    biters = 1000
  )
}, error = function(e) { cat("Error:", conditionMessage(e), "\n"); NULL })

if (!is.null(cs_late)) {
  cs_late_agg <- aggte(cs_late, type = "simple")
  cat("CS-DiD (late): ATT =", round(cs_late_agg$overall.att, 4),
      " (SE =", round(cs_late_agg$overall.se, 4), ")\n")
}

## ============================================================
## 3. Narrow Window (+/- 3 years around treatment)
## ============================================================
cat("\n=== Robustness 3: Narrow Window (+/- 3 years) ===\n")
narrow <- panel[abs(years_since_ebt) <= 3]
cat("Sample:", nrow(narrow), "obs\n")

twfe_narrow <- feols(lbw_rate_pct ~ post_ebt | state_code + year,
                     data = narrow, cluster = ~state_code)
cat("Narrow window: beta =", round(coef(twfe_narrow)["post_ebt"], 4),
    " (SE =", round(se(twfe_narrow)["post_ebt"], 4), ")\n")

## ============================================================
## 4. Intensity Design — Early vs Late Adopters
## ============================================================
cat("\n=== Robustness 4: Continuous Treatment Intensity ===\n")
## Treatment intensity = years of EBT exposure
panel[, ebt_exposure := pmax(0, year - 2 - ebt_year)]

twfe_intensity <- feols(lbw_rate_pct ~ ebt_exposure | state_code + year,
                        data = panel, cluster = ~state_code)
cat("Exposure intensity: beta =", round(coef(twfe_intensity)["ebt_exposure"], 5),
    " (SE =", round(se(twfe_intensity)["ebt_exposure"], 5), ")\n")

## ============================================================
## 5. Placebo: Pre-Treatment Only
## ============================================================
cat("\n=== Robustness 5: Placebo (Pre-Treatment Period Only) ===\n")
## Fake treatment 3 years before actual EBT adoption
panel[, fake_post := as.integer((year - 2) >= (ebt_year - 3))]
pre_only <- panel[year - 2 < ebt_year]  # Only pre-treatment observations
cat("Pre-treatment obs:", nrow(pre_only), "\n")

if (nrow(pre_only) > 50) {
  twfe_placebo <- feols(lbw_rate_pct ~ fake_post | state_code + year,
                        data = pre_only, cluster = ~state_code)
  cat("Placebo (fake treatment -3 years): beta =",
      round(coef(twfe_placebo)["fake_post"], 4),
      " (SE =", round(se(twfe_placebo)["fake_post"], 4), ")\n")
}

## ============================================================
## 6. Wild Cluster Bootstrap
## ============================================================
cat("\n=== Robustness 6: Wild Cluster Bootstrap ===\n")
## With 51 clusters, wild bootstrap provides better inference
## Using fixest's boottest functionality

## Main TWFE with wild cluster bootstrap p-value
twfe_main <- feols(lbw_rate_pct ~ post_ebt | state_code + year,
                   data = panel, cluster = ~state_code)

## Calculate wild bootstrap CI using the boot package approach
set.seed(42)
n_boot <- 999
boot_coefs <- numeric(n_boot)

states <- unique(panel$state_code)
for (b in 1:n_boot) {
  ## Resample states (cluster bootstrap)
  boot_states <- sample(states, length(states), replace = TRUE)
  boot_data <- rbindlist(lapply(seq_along(boot_states), function(i) {
    d <- panel[state_code == boot_states[i]]
    d <- copy(d)
    d[, state_code := paste0(boot_states[i], "_", i)]
    d
  }))

  boot_fit <- tryCatch(
    feols(lbw_rate_pct ~ post_ebt | state_code + year,
          data = boot_data),
    error = function(e) NULL
  )
  if (!is.null(boot_fit)) {
    boot_coefs[b] <- coef(boot_fit)["post_ebt"]
  } else {
    boot_coefs[b] <- NA
  }
}

boot_coefs <- boot_coefs[!is.na(boot_coefs)]
boot_se <- sd(boot_coefs)
boot_ci <- quantile(boot_coefs, c(0.025, 0.975))

cat("TWFE coefficient:", round(coef(twfe_main)["post_ebt"], 4), "\n")
cat("Cluster-robust SE:", round(se(twfe_main)["post_ebt"], 4), "\n")
cat("Bootstrap SE:", round(boot_se, 4), "\n")
cat("Bootstrap 95% CI: [", round(boot_ci[1], 4), ",", round(boot_ci[2], 4), "]\n")

## ============================================================
## 7. HonestDiD Sensitivity (Rambachan-Roth)
## ============================================================
cat("\n=== Robustness 7: HonestDiD Sensitivity ===\n")

## Create rel_time variable
panel[, rel_time := pmin(pmax(years_since_ebt, -5), 5)]

## Run event study for HonestDiD
es_for_honest <- feols(
  lbw_rate_pct ~ i(rel_time, ref = -1) | state_code + year,
  data = panel[cohort_year > min(year) & !is.na(rel_time)],
  cluster = ~state_code
)

## Extract coefficients and vcov for HonestDiD
tryCatch({
  ## Get the post-treatment coefficients
  coef_names <- names(coef(es_for_honest))
  post_idx <- grep("rel_time::[0-9]", coef_names)
  pre_idx <- grep("rel_time::-[0-9]", coef_names)

  if (length(post_idx) > 0 && length(pre_idx) > 0) {
    ## Extract betahat and sigma
    betahat <- coef(es_for_honest)
    sigma <- vcov(es_for_honest)

    cat("HonestDiD: Running sensitivity analysis...\n")
    honest_result <- tryCatch({
      HonestDiD::createSensitivityResults(
        betahat = betahat,
        sigma = sigma,
        numPrePeriods = length(pre_idx),
        numPostPeriods = length(post_idx),
        Mvec = seq(0, 0.05, by = 0.01)
      )
    }, error = function(e) {
      cat("HonestDiD error:", conditionMessage(e), "\n")
      NULL
    })

    if (!is.null(honest_result)) {
      cat("HonestDiD results (Relative Magnitudes):\n")
      print(honest_result)
    }
  }
}, error = function(e) {
  cat("HonestDiD setup error:", conditionMessage(e), "\n")
})

## ============================================================
## Save robustness results
## ============================================================
rob_results <- list(
  twfe_trend = list(
    coef = coef(twfe_trend)["post_ebt"],
    se = se(twfe_trend)["post_ebt"]
  ),
  twfe_late = list(
    coef = coef(twfe_late)["post_ebt"],
    se = se(twfe_late)["post_ebt"]
  ),
  cs_late_att = if (!is.null(cs_late)) cs_late_agg$overall.att else NA,
  twfe_narrow = list(
    coef = coef(twfe_narrow)["post_ebt"],
    se = se(twfe_narrow)["post_ebt"]
  ),
  twfe_intensity = list(
    coef = coef(twfe_intensity)["ebt_exposure"],
    se = se(twfe_intensity)["ebt_exposure"]
  ),
  boot_se = boot_se,
  boot_ci = boot_ci
)

saveRDS(rob_results, "data/robustness_results.rds")
cat("\nRobustness results saved.\n")
