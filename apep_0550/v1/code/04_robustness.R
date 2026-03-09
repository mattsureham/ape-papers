## 04_robustness.R — Robustness checks
## apep_0550: India Farm Laws Symmetric Natural Experiment

source("00_packages.R")

DATA_DIR <- file.path(dirname(getwd()), "data")

monthly <- fread(file.path(DATA_DIR, "monthly_panel.csv"))
monthly[, ym := as.Date(ym)]
monthly[, high_apmc := as.integer(apmc_stringency > median(apmc_stringency, na.rm = TRUE))]

cat("Robustness checks on", nrow(monthly), "monthly observations\n\n")

## ================================================================
## R1: DROP PROTEST-AFFECTED STATES (Punjab, Haryana)
## ================================================================
## Punjab had massive farmer protests. Haryana blocked highways.
## If results hold without these states, they're not driven by protest disruption.

no_protest <- monthly[!state %in% c("Punjab", "Haryana")]

fit_no_protest <- feols(
  log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
    state_commodity + commodity_month,
  data = no_protest,
  cluster = ~state
)

cat("R1: Drop Punjab/Haryana\n")
print(summary(fit_no_protest))

## ================================================================
## R2: DROP BLOCKED STATES (Punjab, Rajasthan, Chhattisgarh)
## ================================================================
## These states passed counter-legislation — they are not "treated"
## Even without formal blocking, they may have undermined implementation

no_blocked <- monthly[blocked_farm_laws == 0]

fit_no_blocked <- feols(
  log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
    state_commodity + commodity_month,
  data = no_blocked,
  cluster = ~state
)

cat("\nR2: Drop states with counter-legislation\n")
print(summary(fit_no_blocked))

## ================================================================
## R3: EXCLUDE BIHAR AND KERALA (already deregulated baseline)
## ================================================================
## These states have APMC stringency = 0, contributing to control group.
## Check that results aren't driven by their inclusion.

no_baseline <- monthly[apmc_abolished == 0 & apmc_stringency > 0]

fit_no_baseline <- feols(
  log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
    state_commodity + commodity_month,
  data = no_baseline,
  cluster = ~state
)

cat("\nR3: Exclude Bihar/Kerala (deregulated baseline)\n")
print(summary(fit_no_baseline))

## ================================================================
## R4: ALTERNATIVE BANDWIDTH — NARROW WINDOW (2019-2022)
## ================================================================

narrow <- monthly[year >= 2019 & year <= 2022]

fit_narrow <- feols(
  log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
    state_commodity + commodity_month,
  data = narrow,
  cluster = ~state
)

cat("\nR4: Narrow bandwidth (2019-2022)\n")
print(summary(fit_narrow))

## ================================================================
## R5: LEAVE-ONE-STATE-OUT
## ================================================================
## Check robustness to dropping each state one at a time

states <- unique(monthly$state)
loso_results <- list()

for (s in states) {
  fit_loso <- tryCatch(
    feols(
      log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
        state_commodity + commodity_month,
      data = monthly[state != s],
      cluster = ~state
    ),
    error = function(e) NULL
  )

  if (!is.null(fit_loso) && length(coef(fit_loso)) >= 2) {
    loso_results[[s]] <- data.table(
      dropped_state = s,
      on_estimate = coef(fit_loso)[1],
      on_se = se(fit_loso)[1],
      off_estimate = coef(fit_loso)[2],
      off_se = se(fit_loso)[2]
    )
  }
}

loso_dt <- rbindlist(loso_results)
fwrite(loso_dt, file.path(DATA_DIR, "loso_results.csv"))

cat("\nR5: Leave-one-state-out\n")
cat("ON coefficient range:", round(range(loso_dt$on_estimate), 4), "\n")
cat("OFF coefficient range:", round(range(loso_dt$off_estimate), 4), "\n")

## ================================================================
## R6: PERMUTATION INFERENCE (Randomization Inference)
## ================================================================
## Randomly reassign APMC stringency across states 1000 times
## to construct the distribution under the null

set.seed(42)
n_perm <- 1000
perm_on  <- numeric(n_perm)
perm_off <- numeric(n_perm)

## Get actual coefficients
actual_on  <- coef(feols(
  log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
    state_commodity + commodity_month,
  data = monthly, cluster = ~state
))[1]
actual_off <- coef(feols(
  log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
    state_commodity + commodity_month,
  data = monthly, cluster = ~state
))[2]

## State-level permutation (shuffle APMC stringency across states)
state_apmc <- unique(monthly[, .(state, apmc_stringency)])

for (i in 1:n_perm) {
  if (i %% 100 == 0) cat("  Permutation", i, "/", n_perm, "\n")

  ## Shuffle stringency across states
  perm_stringency <- state_apmc[, .(state, apmc_perm = sample(apmc_stringency))]
  monthly_perm <- merge(monthly, perm_stringency, by = "state")

  fit_perm <- tryCatch(
    feols(
      log_mean_price ~ apmc_perm:on_phase + apmc_perm:off_phase |
        state_commodity + commodity_month,
      data = monthly_perm, cluster = ~state
    ),
    error = function(e) NULL
  )

  if (!is.null(fit_perm) && length(coef(fit_perm)) >= 2) {
    perm_on[i]  <- coef(fit_perm)[1]
    perm_off[i] <- coef(fit_perm)[2]
  }
}

## RI p-values
ri_p_on  <- mean(abs(perm_on) >= abs(actual_on))
ri_p_off <- mean(abs(perm_off) >= abs(actual_off))

cat("\nR6: Randomization Inference\n")
cat("ON coefficient:", round(actual_on, 4), ", RI p-value:", round(ri_p_on, 3), "\n")
cat("OFF coefficient:", round(actual_off, 4), ", RI p-value:", round(ri_p_off, 3), "\n")

perm_dt <- data.table(
  perm_on = perm_on,
  perm_off = perm_off
)
fwrite(perm_dt, file.path(DATA_DIR, "ri_permutations.csv"))

ri_summary <- data.table(
  coefficient = c("ON", "OFF"),
  actual = c(actual_on, actual_off),
  ri_p_value = c(ri_p_on, ri_p_off),
  perm_mean = c(mean(perm_on), mean(perm_off)),
  perm_sd = c(sd(perm_on), sd(perm_off))
)
fwrite(ri_summary, file.path(DATA_DIR, "ri_summary.csv"))

## ================================================================
## R7: STATE-SPECIFIC LINEAR TRENDS (in robustness)
## ================================================================
monthly[, time_trend := as.integer(difftime(ym, min(ym), units = "days"))]

fit_state_trends <- tryCatch(
  feols(
    log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
      state_commodity + commodity_month + state[time_trend],
    data = monthly,
    cluster = ~state
  ),
  error = function(e) NULL
)

if (!is.null(fit_state_trends)) {
  cat("\nR7: State-specific linear trends\n")
  print(summary(fit_state_trends))
}

## ================================================================
## R8: BALANCED SAMPLE (cells observed in all phases)
## ================================================================
cell_phase <- monthly[, .(
  has_pre = any(on_phase == 0 & off_phase == 0),
  has_on  = any(on_phase == 1),
  has_off = any(off_phase == 1)
), by = .(state, commodity)]

balanced_cells <- cell_phase[has_pre == TRUE & has_on == TRUE & has_off == TRUE]
monthly_bal <- monthly[balanced_cells, on = .(state, commodity)]

fit_balanced <- feols(
  log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
    state_commodity + commodity_month,
  data = monthly_bal,
  cluster = ~state
)

cat("\nR8: Balanced sample\n")
print(summary(fit_balanced))

## ================================================================
## COLLECT ALL ROBUSTNESS RESULTS
## ================================================================

robust_results <- data.table(
  specification = c(
    "Baseline", "Baseline",
    "Drop Punjab/Haryana", "Drop Punjab/Haryana",
    "Drop blocked states", "Drop blocked states",
    "Exclude Bihar/Kerala", "Exclude Bihar/Kerala",
    "Narrow window (2019-22)", "Narrow window (2019-22)",
    "State-specific trends", "State-specific trends",
    "Balanced sample", "Balanced sample"
  ),
  phase = rep(c("ON", "OFF"), 7),
  estimate = c(
    actual_on, actual_off,
    coef(fit_no_protest), coef(fit_no_blocked),
    coef(fit_no_baseline), coef(fit_narrow),
    if (!is.null(fit_state_trends)) coef(fit_state_trends) else c(NA, NA),
    coef(fit_balanced)
  ),
  se = c(
    se(feols(log_mean_price ~ apmc_stringency:on_phase +
               apmc_stringency:off_phase |
               state_commodity + commodity_month,
             data = monthly, cluster = ~state)),
    se(fit_no_protest), se(fit_no_blocked),
    se(fit_no_baseline), se(fit_narrow),
    if (!is.null(fit_state_trends)) se(fit_state_trends) else c(NA, NA),
    se(fit_balanced)
  )
)
robust_results[, `:=`(
  ci_lo = estimate - 1.96 * se,
  ci_hi = estimate + 1.96 * se
)]
fwrite(robust_results, file.path(DATA_DIR, "robustness_results.csv"))

cat("\n=== ROBUSTNESS SUMMARY ===\n")
print(robust_results[, .(specification, phase,
                          estimate = round(estimate, 4),
                          se = round(se, 4))])

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
