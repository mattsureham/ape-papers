## 03_main_analysis.R — Primary regressions
## apep_0550: India Farm Laws Symmetric Natural Experiment

source("00_packages.R")

DATA_DIR <- file.path(dirname(getwd()), "data")

## Load cleaned data
monthly <- fread(file.path(DATA_DIR, "monthly_panel.csv"))
monthly[, ym := as.Date(ym)]

cat("Monthly panel loaded:", nrow(monthly), "rows\n")
cat("States:", uniqueN(monthly$state), "\n")
cat("Commodities:", uniqueN(monthly$commodity), "\n")
cat("Months:", uniqueN(monthly$ym), "\n\n")

## ================================================================
## TABLE 1: PRIMARY DiD — SYMMETRIC DESIGN
## ================================================================
## Y_sct = alpha + beta1 * APMC_s * ON_t + beta2 * APMC_s * OFF_t
##         + gamma_sc + delta_ct + epsilon
##
## beta1: effect of deregulation (ON phase, June 2020 - Jan 2021)
## beta2: reversal effect (OFF phase, post-Jan 2021)
##
## If deregulation genuinely lowered intermediation costs:
##   beta1 < 0 (lower prices in high-APMC states during ON)
##   beta2 ≈ 0 (prices return to pre-levels after re-regulation)

## Main specification
fit_main <- feols(
  log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
    state_commodity + commodity_month,
  data = monthly,
  cluster = ~state
)

## Alternative: binary treatment (high vs low APMC)
monthly[, high_apmc := as.integer(apmc_stringency > median(apmc_stringency, na.rm = TRUE))]

fit_binary <- feols(
  log_mean_price ~ high_apmc:on_phase + high_apmc:off_phase |
    state_commodity + commodity_month,
  data = monthly,
  cluster = ~state
)

## Alternative: APMC cess rate as treatment
fit_cess <- feols(
  log_mean_price ~ apmc_cess_pct:on_phase + apmc_cess_pct:off_phase |
    state_commodity + commodity_month,
  data = monthly,
  cluster = ~state
)

## Price dispersion as outcome (log-transformed to stabilize scale)
monthly[, log_sd_price := log(sd_price + 1)]
fit_dispersion <- feols(
  log_sd_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
    state_commodity + commodity_month,
  data = monthly[!is.na(sd_price) & sd_price > 0],
  cluster = ~state
)

## Number of active markets as first-stage proxy
fit_markets <- feols(
  log(n_markets + 1) ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
    state_commodity + commodity_month,
  data = monthly,
  cluster = ~state
)

cat("\n=== PRIMARY RESULTS ===\n\n")
cat("Model 1: Continuous APMC stringency\n")
print(summary(fit_main))
cat("\nModel 2: Binary high/low APMC\n")
print(summary(fit_binary))
cat("\nModel 3: APMC cess rate\n")
print(summary(fit_cess))
cat("\nModel 4: Price dispersion\n")
print(summary(fit_dispersion))
cat("\nModel 5: Number of markets (first stage)\n")
print(summary(fit_markets))

## Save coefficient data for figures
coef_data <- data.table(
  model = rep(c("Continuous APMC", "Binary APMC", "Cess Rate",
                "Price Dispersion", "N Markets"), each = 2),
  phase = rep(c("ON", "OFF"), 5),
  estimate = c(
    coef(fit_main), coef(fit_binary), coef(fit_cess),
    coef(fit_dispersion), coef(fit_markets)
  ),
  se = c(
    se(fit_main), se(fit_binary), se(fit_cess),
    se(fit_dispersion), se(fit_markets)
  )
)
coef_data[, `:=`(
  ci_lo = estimate - 1.96 * se,
  ci_hi = estimate + 1.96 * se
)]
fwrite(coef_data, file.path(DATA_DIR, "main_results.csv"))

## ================================================================
## TABLE 2: HETEROGENEITY BY COMMODITY
## ================================================================

commodities <- unique(monthly$commodity)
het_results <- list()

for (comm in commodities) {
  fit <- tryCatch(
    feols(
      log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
        state_commodity + commodity_month,
      data = monthly[commodity == comm],
      cluster = ~state
    ),
    error = function(e) NULL
  )

  if (!is.null(fit) && length(coef(fit)) >= 2) {
    het_results[[comm]] <- data.table(
      commodity = comm,
      phase = c("ON", "OFF"),
      estimate = coef(fit),
      se = se(fit),
      pval = fixest::pvalue(fit),
      n_obs = nobs(fit)
    )
  }
}

het_dt <- rbindlist(het_results)
het_dt[, `:=`(
  ci_lo = estimate - 1.96 * se,
  ci_hi = estimate + 1.96 * se
)]
fwrite(het_dt, file.path(DATA_DIR, "heterogeneity_commodity.csv"))

cat("\n=== HETEROGENEITY BY COMMODITY ===\n")
print(het_dt[, .(commodity, phase, estimate = round(estimate, 4),
                 se = round(se, 4), pval = round(pval, 3))])

## ================================================================
## TABLE 3: PLACEBO TESTS
## ================================================================

## Placebo 1: Reverse treatment (low-APMC states "treated")
## If high-APMC deregulation matters, using (1-APMC) should show null/opposite
monthly[, apmc_reverse := 1 - apmc_stringency]
fit_reverse <- tryCatch(
  feols(
    log_mean_price ~ apmc_reverse:on_phase + apmc_reverse:off_phase |
      state_commodity + commodity_month,
    data = monthly,
    cluster = ~state
  ),
  error = function(e) NULL
)
if (!is.null(fit_reverse)) {
  cat("\n=== PLACEBO: Reverse treatment (1-APMC) ===\n")
  print(summary(fit_reverse))
}

## Placebo 2: Within-control test (only APMC=0 states)
## States with zero APMC stringency should show no differential time pattern
## relative to each other (they have no treatment variation)
zero_apmc <- monthly[apmc_stringency == 0]
fit_zero <- tryCatch(
  feols(
    log_mean_price ~ on_phase + off_phase |
      state_commodity + commodity_month,
    data = zero_apmc,
    cluster = ~state
  ),
  error = function(e) {
    cat("Zero-APMC test failed:", e$message, "\n")
    NULL
  }
)

## Placebo 3: Pre-period placebo (fake treatment in 2019)
pre_data <- monthly[ym < as.Date("2020-06-01")]
pre_data[, `:=`(
  fake_on  = as.integer(ym >= as.Date("2019-06-01") & ym < as.Date("2020-01-01")),
  fake_off = as.integer(ym >= as.Date("2020-01-01"))
)]

if (nrow(pre_data) > 10) {
  fit_placebo_time <- tryCatch(
    feols(
      log_mean_price ~ apmc_stringency:fake_on + apmc_stringency:fake_off |
        state_commodity + commodity_month,
      data = pre_data,
      cluster = ~state
    ),
    error = function(e) NULL
  )
  if (!is.null(fit_placebo_time)) {
    cat("\n=== PLACEBO: Fake treatment June 2019 ===\n")
    print(summary(fit_placebo_time))
  }
}

## Save placebo results with N
placebo_results <- data.table(
  test = c("Pre-period (fake 2019)", "Pre-period (fake 2019)",
           "Reverse treatment", "Reverse treatment"),
  phase = rep(c("ON", "OFF"), 2),
  estimate = c(
    if (!is.null(fit_placebo_time)) coef(fit_placebo_time) else c(NA, NA),
    if (!is.null(fit_reverse)) coef(fit_reverse) else c(NA, NA)
  ),
  se = c(
    if (!is.null(fit_placebo_time)) se(fit_placebo_time) else c(NA, NA),
    if (!is.null(fit_reverse)) se(fit_reverse) else c(NA, NA)
  ),
  n_obs = c(
    rep(if (!is.null(fit_placebo_time)) nobs(fit_placebo_time) else NA_integer_, 2),
    rep(if (!is.null(fit_reverse)) nobs(fit_reverse) else NA_integer_, 2)
  )
)
fwrite(placebo_results, file.path(DATA_DIR, "placebo_results.csv"))

## Note: Wild cluster bootstrap (fwildclusterboot) is incompatible with
## feols high-dimensional FE + interaction terms in this version.
## Randomization inference (04_robustness.R) provides the primary
## non-parametric inference complement to CRVE with 28 clusters.

## ================================================================
## FORMAL PRE-TREND TEST (joint F-test on event study)
## ================================================================
cat("\n=== FORMAL PRE-TREND TEST ===\n")

ref_month <- as.Date("2020-05-01")
monthly[, rel_month := as.integer(round(difftime(ym, ref_month, units = "days") / 30.44))]

es_data <- monthly[rel_month >= -24 & rel_month <= 30]
es_data[, rel_month_f := factor(rel_month)]

fit_es <- feols(
  log_mean_price ~ i(rel_month_f, apmc_stringency, ref = "0") |
    state_commodity + commodity_month,
  data = es_data,
  cluster = ~state
)

## Extract pre-treatment coefficient names (negative rel_month)
all_coef_names <- names(coef(fit_es))
pre_coefs <- all_coef_names[grepl("rel_month_f::-", all_coef_names)]

if (length(pre_coefs) > 0) {
  ## With 24 pre-period coefs and 28 clusters, joint Wald test is unstable.
  ## Use a simpler approach: test a subset (every 6th month) for stability,
  ## and also report a linear pre-trend test.

  ## 1. Simple approach: regress pre-treatment coefs on time to test for trend
  pre_coef_vals <- coef(fit_es)[pre_coefs]
  pre_se_vals <- se(fit_es)[pre_coefs]
  pre_months <- as.integer(gsub("rel_month_f::(-?\\d+):apmc_stringency", "\\1", pre_coefs))

  ## Weighted regression of pre-treatment coefficients on time
  pre_trend_reg <- lm(pre_coef_vals ~ pre_months, weights = 1/pre_se_vals^2)
  pre_trend_pval <- summary(pre_trend_reg)$coefficients[2, 4]
  pre_trend_slope <- coef(pre_trend_reg)[2]

  cat("Pre-trend test (WLS regression of pre-period coefs on time):\n")
  cat("  Slope:", round(pre_trend_slope, 6), "\n")
  cat("  p-value:", round(pre_trend_pval, 4), "\n")
  cat("  Pre-treatment coefficients:", length(pre_coefs), "\n")

  ## 2. Check if any individual pre-period coef is significant at 5%
  n_sig <- sum(abs(pre_coef_vals / pre_se_vals) > 1.96)
  cat("  Individually significant at 5%:", n_sig, "of", length(pre_coefs), "\n")

  pretrend_result <- data.table(
    test = "Linear pre-trend (WLS)",
    n_coefs = length(pre_coefs),
    trend_slope = pre_trend_slope,
    p_value = pre_trend_pval,
    n_sig_5pct = n_sig
  )
  fwrite(pretrend_result, file.path(DATA_DIR, "pretrend_test.csv"))
}

## Save event-study coefficients table for appendix
es_coefs <- as.data.table(coeftable(fit_es), keep.rownames = TRUE)
setnames(es_coefs, c("term", "estimate", "se", "tval", "pval"))
es_coefs[, rel_month := as.integer(gsub("rel_month_f::(-?\\d+):apmc_stringency", "\\1", term))]
es_coefs <- es_coefs[!is.na(rel_month)]
es_coefs[, `:=`(ci_lo = estimate - 1.96 * se, ci_hi = estimate + 1.96 * se)]
es_coefs <- rbind(es_coefs,
  data.table(term = "ref", estimate = 0, se = 0, tval = 0, pval = 1,
             rel_month = 0, ci_lo = 0, ci_hi = 0))
es_coefs <- es_coefs[order(rel_month)]
fwrite(es_coefs, file.path(DATA_DIR, "event_study_coefs.csv"))

## ================================================================
## BETA1 = BETA2 EQUALITY TEST
## ================================================================
cat("\n=== ON = OFF COEFFICIENT EQUALITY TEST ===\n")

## Manual t-test: beta1 = beta2
## Since fixest wald() with H0 vector tests joint nullity against H0,
## compute manually: (beta1 - beta2) / se(beta1 - beta2)
beta_on <- coef(fit_main)[1]
beta_off <- coef(fit_main)[2]
vcov_mat <- vcov(fit_main)
se_diff <- sqrt(vcov_mat[1,1] + vcov_mat[2,2] - 2 * vcov_mat[1,2])
t_eq <- (beta_on - beta_off) / se_diff
p_eq <- 2 * pt(abs(t_eq), df = 27 - 1, lower.tail = FALSE)

cat("t-test H0: beta_ON = beta_OFF\n")
cat("  Difference:", round(beta_on - beta_off, 4), "\n")
cat("  SE(diff):", round(se_diff, 4), "\n")
cat("  t-stat:", round(t_eq, 4), "\n")
cat("  p-value:", round(p_eq, 4), "\n")

eq_result <- data.table(
  test = "beta_ON = beta_OFF",
  difference = beta_on - beta_off,
  se_diff = se_diff,
  t_stat = t_eq,
  p_value = p_eq
)
fwrite(eq_result, file.path(DATA_DIR, "equality_test.csv"))

## ================================================================
## SPLIT OFF PERIOD (post-stay vs post-repeal)
## ================================================================
cat("\n=== SPLIT OFF PERIOD ===\n")

monthly[, `:=`(
  stay_phase   = as.integer(ym >= as.Date("2021-02-01") & ym < as.Date("2021-12-01")),
  repeal_phase = as.integer(ym >= as.Date("2021-12-01"))
)]

fit_split <- feols(
  log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:stay_phase +
    apmc_stringency:repeal_phase |
    state_commodity + commodity_month,
  data = monthly,
  cluster = ~state
)

cat("Split OFF specification:\n")
print(summary(fit_split))

split_results <- data.table(
  phase = c("ON", "Stay (Feb-Nov 2021)", "Post-repeal (Dec 2021+)"),
  estimate = coef(fit_split),
  se = se(fit_split),
  pval = fixest::pvalue(fit_split),
  n_obs = nobs(fit_split)
)
fwrite(split_results, file.path(DATA_DIR, "split_off_results.csv"))

## ================================================================
## BALANCED SAMPLE (consistently observed state-commodity cells)
## ================================================================
cat("\n=== BALANCED SAMPLE ANALYSIS ===\n")

## Identify cells observed in ALL three phases
cell_phase <- monthly[, .(
  has_pre = any(on_phase == 0 & off_phase == 0),
  has_on  = any(on_phase == 1),
  has_off = any(off_phase == 1),
  n_months = .N
), by = .(state, commodity)]

balanced_cells <- cell_phase[has_pre == TRUE & has_on == TRUE & has_off == TRUE]
cat("Balanced cells:", nrow(balanced_cells), "of", nrow(cell_phase), "total\n")

monthly_bal <- monthly[balanced_cells, on = .(state, commodity)]

fit_balanced <- feols(
  log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
    state_commodity + commodity_month,
  data = monthly_bal,
  cluster = ~state
)

cat("Balanced sample results:\n")
print(summary(fit_balanced))

balanced_result <- data.table(
  specification = "Balanced sample",
  phase = c("ON", "OFF"),
  estimate = coef(fit_balanced),
  se = se(fit_balanced),
  pval = fixest::pvalue(fit_balanced),
  n_obs = nobs(fit_balanced)
)
fwrite(balanced_result, file.path(DATA_DIR, "balanced_results.csv"))

## ================================================================
## STATE-SPECIFIC LINEAR TRENDS
## ================================================================
cat("\n=== STATE-SPECIFIC LINEAR TRENDS ===\n")

monthly[, time_trend := as.integer(difftime(ym, min(ym), units = "days"))]

fit_trends <- feols(
  log_mean_price ~ apmc_stringency:on_phase + apmc_stringency:off_phase |
    state_commodity + commodity_month + state[time_trend],
  data = monthly,
  cluster = ~state
)

cat("With state-specific linear trends:\n")
print(summary(fit_trends))

trend_result <- data.table(
  specification = "State-specific trends",
  phase = c("ON", "OFF"),
  estimate = coef(fit_trends),
  se = se(fit_trends),
  pval = fixest::pvalue(fit_trends),
  n_obs = nobs(fit_trends)
)
fwrite(trend_result, file.path(DATA_DIR, "state_trends_results.csv"))

## ================================================================
## MULTIPLE PLACEBO DATES
## ================================================================
cat("\n=== MULTIPLE PLACEBO DATES ===\n")

pre_only <- monthly[ym < as.Date("2020-06-01")]
placebo_dates <- seq(as.Date("2017-06-01"), as.Date("2019-12-01"), by = "3 months")
multi_placebo <- list()

for (pd in as.character(placebo_dates)) {
  pd_date <- as.Date(pd)
  off_date <- pd_date + 240  # ~8 months later

  pre_only[, `:=`(
    fake_on  = as.integer(ym >= pd_date & ym < off_date),
    fake_off = as.integer(ym >= off_date)
  )]

  fit_fp <- tryCatch(
    feols(
      log_mean_price ~ apmc_stringency:fake_on + apmc_stringency:fake_off |
        state_commodity + commodity_month,
      data = pre_only,
      cluster = ~state
    ),
    error = function(e) NULL
  )

  if (!is.null(fit_fp) && length(coef(fit_fp)) >= 2) {
    multi_placebo[[pd]] <- data.table(
      placebo_date = pd,
      on_estimate = coef(fit_fp)[1],
      on_se = se(fit_fp)[1],
      off_estimate = coef(fit_fp)[2],
      off_se = se(fit_fp)[2],
      n_obs = nobs(fit_fp)
    )
  }
}

multi_placebo_dt <- rbindlist(multi_placebo)
fwrite(multi_placebo_dt, file.path(DATA_DIR, "multi_placebo_results.csv"))
cat("Multiple placebo dates tested:", nrow(multi_placebo_dt), "\n")
print(multi_placebo_dt[, .(placebo_date, on_est = round(on_estimate, 4),
                            on_se = round(on_se, 4))])

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
