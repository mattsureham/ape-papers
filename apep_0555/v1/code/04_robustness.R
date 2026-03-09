## ============================================================================
## 04_robustness.R — Robustness checks and placebo tests
## Paper: Demonetization by Design (apep_0555)
## ============================================================================

source(file.path(here::here(), "output", "apep_0555", "v1", "code", "00_packages.R"))

panel <- fread(file.path(data_dir, "panel.csv"))
rice  <- fread(file.path(data_dir, "rice_panel.csv"))

robustness_results <- list()

## =========================================================================
## 1. EXCLUDE CONFLICT-AFFECTED STATES (Borno, Yobe, Adamawa)
## =========================================================================

panel_no_conflict <- panel[conflict_state == 0]

## Ensure sufficient variation remains
cat("Conflict exclusion: ", n_distinct(panel_no_conflict$market), "markets,",
    n_distinct(panel_no_conflict$state), "states,",
    sum(panel_no_conflict$high_cmi == 1), "high CMI obs,",
    sum(panel_no_conflict$high_cmi == 0), "low CMI obs\n")

tryCatch({
  rob_noconflict <- feols(
    log_price ~ high_cmi:cash_crisis_acute |
      market_commodity + market_id_num^time_idx,
    data = panel_no_conflict,
    cluster = ~state
  )
  robustness_results[["Excl. conflict states"]] <- data.table(
    check = "Excl. conflict states",
    estimate = coef(rob_noconflict),
    se = sqrt(diag(vcov(rob_noconflict))),
    n_obs = nobs(rob_noconflict),
    n_markets = n_distinct(panel_no_conflict$market)
  )
}, error = function(e) {
  cat("Conflict exclusion failed (collinearity after FE removal):", e$message, "\n")
  ## Try without market-time interaction FE
  tryCatch({
    rob_noconflict2 <- feols(
      log_price ~ high_cmi:cash_crisis_acute |
        market_commodity + time_idx,
      data = panel_no_conflict,
      cluster = ~state
    )
    robustness_results[["Excl. conflict states"]] <<- data.table(
      check = "Excl. conflict states (simpler FE)",
      estimate = coef(rob_noconflict2),
      se = sqrt(diag(vcov(rob_noconflict2))),
      n_obs = nobs(rob_noconflict2),
      n_markets = n_distinct(panel_no_conflict$market)
    )
  }, error = function(e2) {
    cat("Conflict exclusion failed entirely:", e2$message, "\n")
  })
})

## =========================================================================
## 2. ALTERNATIVE CRISIS WINDOWS
## =========================================================================

## Feb-March 2023 only (peak cash crisis)
panel[, crisis_peak := as.integer(year == 2023 & month %in% c(2, 3))]
rob_peak <- feols(
  log_price ~ high_cmi:crisis_peak |
    market_commodity + market_id_num^time_idx,
  data = panel,
  cluster = ~state
)

robustness_results[["Peak crisis (Feb-Mar)"]] <- data.table(
  check = "Peak crisis (Feb-Mar)",
  estimate = coef(rob_peak),
  se = sqrt(diag(vcov(rob_peak))),
  n_obs = nobs(rob_peak),
  n_markets = n_distinct(panel$market)
)

## Full year 2023
panel[, crisis_full_year := as.integer(year == 2023)]
rob_full_year <- feols(
  log_price ~ high_cmi:crisis_full_year |
    market_commodity + market_id_num^time_idx,
  data = panel,
  cluster = ~state
)

robustness_results[["Full year 2023"]] <- data.table(
  check = "Full year 2023",
  estimate = coef(rob_full_year),
  se = sqrt(diag(vcov(rob_full_year))),
  n_obs = nobs(rob_full_year),
  n_markets = n_distinct(panel$market)
)

## =========================================================================
## 3. PLACEBO TEST: Fake crisis in 2021
## =========================================================================

panel[, placebo_crisis := as.integer(year == 2021 & month >= 2 & month <= 5)]

rob_placebo <- feols(
  log_price ~ high_cmi:placebo_crisis |
    market_commodity + market_id_num^time_idx,
  data = panel,
  cluster = ~state
)

robustness_results[["Placebo (2021)"]] <- data.table(
  check = "Placebo (2021)",
  estimate = coef(rob_placebo),
  se = sqrt(diag(vcov(rob_placebo))),
  n_obs = nobs(rob_placebo),
  n_markets = n_distinct(panel$market)
)

## =========================================================================
## 4. LEAVE-ONE-COMMODITY-OUT
## =========================================================================

commodities_main <- panel[, unique(commodity)]
loo_commodity <- lapply(commodities_main, function(drop_c) {
  sub <- panel[commodity != drop_c]
  ## Ensure both CMI groups remain
  if (n_distinct(sub$cmi) < 2) return(NULL)
  m <- tryCatch({
    feols(
      log_price ~ high_cmi:cash_crisis_acute |
        market_commodity + market_id_num^time_idx,
      data = sub,
      cluster = ~state
    )
  }, error = function(e) NULL)
  if (is.null(m)) return(NULL)
  data.table(
    dropped = drop_c,
    estimate = coef(m),
    se = sqrt(diag(vcov(m))),
    n_obs = nobs(m)
  )
})
loo_commodity_dt <- rbindlist(loo_commodity)
fwrite(loo_commodity_dt, file.path(data_dir, "loo_commodity.csv"))

## =========================================================================
## 5. LEAVE-ONE-STATE-OUT
## =========================================================================

states <- panel[, unique(state)]
loo_state <- lapply(states, function(drop_s) {
  sub <- panel[state != drop_s]
  m <- tryCatch({
    feols(
      log_price ~ high_cmi:cash_crisis_acute |
        market_commodity + market_id_num^time_idx,
      data = sub,
      cluster = ~state
    )
  }, error = function(e) NULL)
  if (is.null(m)) return(NULL)
  data.table(
    dropped = drop_s,
    estimate = coef(m),
    se = sqrt(diag(vcov(m))),
    n_obs = nobs(m)
  )
})
loo_state_dt <- rbindlist(loo_state)
fwrite(loo_state_dt, file.path(data_dir, "loo_state.csv"))

## =========================================================================
## 6. WILD CLUSTER BOOTSTRAP (14 clusters — below threshold)
## =========================================================================

## Wild cluster bootstrap for main specification
cat("Running wild cluster bootstrap (may take a moment)...\n")
tryCatch({
  m_boot <- feols(
    log_price ~ high_cmi:cash_crisis_acute |
      market_commodity + market_id_num^time_idx,
    data = panel
  )
  boot_result <- boottest(
    m_boot,
    param = "high_cmi:cash_crisis_acute",
    clustid = "state",
    B = 9999,
    type = "webb"
  )
  boot_pval <- pval(boot_result)
  boot_ci <- confint(boot_result)
  cat("Wild bootstrap p-value:", boot_pval, "\n")
  cat("Wild bootstrap 95% CI:", boot_ci, "\n")

  robustness_results[["Wild bootstrap"]] <- data.table(
    check = "Wild bootstrap",
    estimate = coef(m_boot),
    se = NA_real_,
    n_obs = nobs(m_boot),
    n_markets = NA_integer_,
    boot_pval = boot_pval,
    boot_ci_lo = boot_ci[1],
    boot_ci_hi = boot_ci[2]
  )
}, error = function(e) {
  cat("Wild bootstrap failed:", e$message, "\n")
  cat("Proceeding with cluster-robust SEs.\n")
})

## =========================================================================
## 7. RANDOMIZATION INFERENCE
## =========================================================================

cat("Running randomization inference (500 permutations)...\n")

## Get actual estimate using simpler additive FE (RI with interaction FE causes singletons)
actual_model <- feols(
  log_price ~ high_cmi:cash_crisis_acute |
    market_commodity + time_idx,
  data = panel,
  cluster = ~state
)
actual_est <- coef(actual_model)
cat("Actual estimate (additive FE for RI):", actual_est, "\n")

## Permute crisis timing
set.seed(42)
n_perms <- 500
ri_estimates <- numeric(n_perms)

unique_times <- panel[, sort(unique(time_idx))]
crisis_months <- panel[cash_crisis_acute == 1, unique(time_idx)]
n_crisis <- length(crisis_months)

for (i in seq_len(n_perms)) {
  ## Randomly assign which months are "crisis" months
  fake_crisis <- sample(unique_times, n_crisis)
  panel[, fake_crisis_ri := as.integer(time_idx %in% fake_crisis)]

  m_ri <- tryCatch({
    feols(
      log_price ~ high_cmi:fake_crisis_ri |
        market_commodity + time_idx,
      data = panel
    )
  }, error = function(e) NULL)

  if (!is.null(m_ri) && length(coef(m_ri)) > 0) {
    ri_estimates[i] <- coef(m_ri)[1]
  } else {
    ri_estimates[i] <- NA
  }
  if (i %% 100 == 0) cat("  RI permutation", i, "of", n_perms, "\n")
}
panel[, fake_crisis_ri := NULL]

ri_estimates <- ri_estimates[!is.na(ri_estimates)]
ri_pval <- mean(abs(ri_estimates) >= abs(actual_est))
cat("RI p-value:", ri_pval, "(", sum(abs(ri_estimates) >= abs(actual_est)),
    "of", length(ri_estimates), "permutations)\n")

ri_dt <- data.table(
  permutation = seq_along(ri_estimates),
  estimate = ri_estimates,
  actual = actual_est
)
fwrite(ri_dt, file.path(data_dir, "ri_time_distribution.csv"))

robustness_results[["RI (time permutation)"]] <- data.table(
  check = "RI (time permutation, additive FE)",
  estimate = actual_est,
  se = NA_real_,
  n_obs = nobs(actual_model),
  n_markets = NA_integer_,
  ri_pval = ri_pval
)

## ---- Commodity-permutation RI ----
## More appropriate: permute which commodities are "high CMI"
## This tests: is the cash-crisis effect specific to cash-mediated commodities?
cat("\nRunning commodity-permutation RI (500 permutations)...\n")

actual_est_full <- coef(feols(
  log_price ~ high_cmi:cash_crisis_acute |
    market_commodity + market_id_num^time_idx,
  data = panel,
  cluster = ~state
))

set.seed(123)
n_perms_c <- 500
ri_c_estimates <- numeric(n_perms_c)
commodities <- panel[, unique(commodity)]
n_high <- panel[, sum(high_cmi == 1) / .N]  # proportion high

for (i in seq_len(n_perms_c)) {
  ## Randomly assign CMI labels (maintaining same proportion)
  fake_high <- sample(commodities, size = round(length(commodities) * n_high))
  panel[, fake_cmi := as.integer(commodity %in% fake_high)]

  m_ri_c <- tryCatch({
    feols(
      log_price ~ fake_cmi:cash_crisis_acute |
        market_commodity + market_id_num^time_idx,
      data = panel
    )
  }, error = function(e) NULL)

  if (!is.null(m_ri_c) && length(coef(m_ri_c)) > 0) {
    ri_c_estimates[i] <- coef(m_ri_c)[1]
  } else {
    ri_c_estimates[i] <- NA
  }
  if (i %% 100 == 0) cat("  Commodity RI permutation", i, "of", n_perms_c, "\n")
}
panel[, fake_cmi := NULL]

ri_c_estimates <- ri_c_estimates[!is.na(ri_c_estimates)]
ri_c_pval <- mean(abs(ri_c_estimates) >= abs(actual_est_full))
cat("Commodity RI p-value:", ri_c_pval, "(", sum(abs(ri_c_estimates) >= abs(actual_est_full)),
    "of", length(ri_c_estimates), "permutations)\n")

ri_c_dt <- data.table(
  permutation = seq_along(ri_c_estimates),
  estimate = ri_c_estimates,
  actual = actual_est_full
)
fwrite(ri_c_dt, file.path(data_dir, "ri_distribution.csv"))

robustness_results[["RI (commodity permutation)"]] <- data.table(
  check = "RI (commodity permutation)",
  estimate = actual_est_full,
  se = NA_real_,
  n_obs = nobs(actual_model),
  n_markets = NA_integer_,
  ri_pval = ri_c_pval
)

## =========================================================================
## 8. USD PRICES (exchange rate robustness)
## =========================================================================

panel[, log_usdprice := log(as.numeric(usdprice))]
panel_usd <- panel[!is.na(log_usdprice) & is.finite(log_usdprice)]

if (nrow(panel_usd) > 100) {
  rob_usd <- feols(
    log_usdprice ~ high_cmi:cash_crisis_acute |
      market_commodity + market_id_num^time_idx,
    data = panel_usd,
    cluster = ~state
  )
  robustness_results[["USD prices"]] <- data.table(
    check = "USD prices",
    estimate = coef(rob_usd),
    se = sqrt(diag(vcov(rob_usd))),
    n_obs = nobs(rob_usd),
    n_markets = n_distinct(panel_usd$market)
  )
  cat("\nUSD price result:\n")
  print(summary(rob_usd))
}

## =========================================================================
## 9. COMMODITY-GROUP x CALENDAR-MONTH SEASONALITY
## =========================================================================

cat("\nRunning commodity-group x month seasonality controls...\n")

## Create interaction: CMI group (high/low) x month-of-year
panel[, cmi_month := paste0(cmi, "_m", month)]

tryCatch({
  rob_season <- feols(
    log_price ~ high_cmi:cash_crisis_acute |
      market_commodity + market_id_num^time_idx + cmi_month,
    data = panel,
    cluster = ~state
  )
  robustness_results[["CMI x month seasonality"]] <- data.table(
    check = "CMI x month seasonality",
    estimate = coef(rob_season),
    se = sqrt(diag(vcov(rob_season))),
    n_obs = nobs(rob_season),
    n_markets = n_distinct(panel$market)
  )
  cat("CMI x month seasonality result:\n")
  print(summary(rob_season))
}, error = function(e) {
  cat("CMI x month seasonality failed:", e$message, "\n")
  ## Fallback: add cmi_month as additive FE with simpler market-time FE
  tryCatch({
    rob_season2 <- feols(
      log_price ~ high_cmi:cash_crisis_acute |
        market_commodity + time_idx + cmi_month,
      data = panel,
      cluster = ~state
    )
    robustness_results[["CMI x month seasonality"]] <<- data.table(
      check = "CMI x month seasonality (additive FE)",
      estimate = coef(rob_season2),
      se = sqrt(diag(vcov(rob_season2))),
      n_obs = nobs(rob_season2),
      n_markets = n_distinct(panel$market)
    )
    cat("CMI x month seasonality (additive FE) result:\n")
    print(summary(rob_season2))
  }, error = function(e2) {
    cat("CMI x month seasonality failed entirely:", e2$message, "\n")
  })
})

## =========================================================================
## 10. BALANCED-PANEL ROBUSTNESS (Feb-May 2023 crisis window)
## =========================================================================

cat("\nRunning balanced-panel robustness...\n")

## Identify market-commodity pairs observed in every month of Feb-May 2023
crisis_months <- c(2, 3, 4, 5)
n_crisis_months <- length(crisis_months)

balanced_ids <- panel[year == 2023 & month %in% crisis_months,
  .(n_months = n_distinct(month)), by = market_commodity
][n_months == n_crisis_months, market_commodity]

panel_balanced <- panel[market_commodity %in% balanced_ids]

cat("Balanced panel: ", length(balanced_ids), "market-commodity pairs,",
    nrow(panel_balanced), "obs,",
    n_distinct(panel_balanced$market), "markets,",
    n_distinct(panel_balanced$state), "states\n")

tryCatch({
  rob_balanced <- feols(
    log_price ~ high_cmi:cash_crisis_acute |
      market_commodity + market_id_num^time_idx,
    data = panel_balanced,
    cluster = ~state
  )
  robustness_results[["Balanced panel"]] <- data.table(
    check = "Balanced panel",
    estimate = coef(rob_balanced),
    se = sqrt(diag(vcov(rob_balanced))),
    n_obs = nobs(rob_balanced),
    n_markets = n_distinct(panel_balanced$market)
  )
  cat("Balanced panel result:\n")
  print(summary(rob_balanced))
}, error = function(e) {
  cat("Balanced panel failed:", e$message, "\n")
  ## Fallback: simpler FE
  tryCatch({
    rob_balanced2 <- feols(
      log_price ~ high_cmi:cash_crisis_acute |
        market_commodity + time_idx,
      data = panel_balanced,
      cluster = ~state
    )
    robustness_results[["Balanced panel"]] <<- data.table(
      check = "Balanced panel (additive FE)",
      estimate = coef(rob_balanced2),
      se = sqrt(diag(vcov(rob_balanced2))),
      n_obs = nobs(rob_balanced2),
      n_markets = n_distinct(panel_balanced$market)
    )
    cat("Balanced panel (additive FE) result:\n")
    print(summary(rob_balanced2))
  }, error = function(e2) {
    cat("Balanced panel failed entirely:", e2$message, "\n")
  })
})

## =========================================================================
## 11. CEREALS-ONLY COMPARISON
## =========================================================================

cat("\nRunning cereals-only robustness...\n")

## Cereals: Maize varieties, Millet, Sorghum varieties, Rice local vs Rice imported
cereal_commodities <- c(
  "Maize", "Maize (white)", "Maize (yellow)", "Maize flour",
  "Millet", "Millet (local)", "Millet (imported)",
  "Sorghum", "Sorghum (white)", "Sorghum (brown)", "Sorghum (red)",
  "Rice (local)", "Rice (milled, local)",
  "Rice (imported)"
)

panel_cereals <- panel[commodity %in% cereal_commodities]

cat("Cereals panel:", nrow(panel_cereals), "obs,",
    n_distinct(panel_cereals$commodity), "commodities,",
    n_distinct(panel_cereals$market), "markets,",
    "high CMI:", sum(panel_cereals$high_cmi == 1),
    "low CMI:", sum(panel_cereals$high_cmi == 0), "\n")

tryCatch({
  rob_cereals <- feols(
    log_price ~ high_cmi:cash_crisis_acute |
      market_commodity + market_id_num^time_idx,
    data = panel_cereals,
    cluster = ~state
  )
  robustness_results[["Cereals only"]] <- data.table(
    check = "Cereals only",
    estimate = coef(rob_cereals),
    se = sqrt(diag(vcov(rob_cereals))),
    n_obs = nobs(rob_cereals),
    n_markets = n_distinct(panel_cereals$market)
  )
  cat("Cereals only result:\n")
  print(summary(rob_cereals))
}, error = function(e) {
  cat("Cereals only failed:", e$message, "\n")
  ## Fallback: simpler FE
  tryCatch({
    rob_cereals2 <- feols(
      log_price ~ high_cmi:cash_crisis_acute |
        market_commodity + time_idx,
      data = panel_cereals,
      cluster = ~state
    )
    robustness_results[["Cereals only"]] <<- data.table(
      check = "Cereals only (additive FE)",
      estimate = coef(rob_cereals2),
      se = sqrt(diag(vcov(rob_cereals2))),
      n_obs = nobs(rob_cereals2),
      n_markets = n_distinct(panel_cereals$market)
    )
    cat("Cereals only (additive FE) result:\n")
    print(summary(rob_cereals2))
  }, error = function(e2) {
    cat("Cereals only failed entirely:", e2$message, "\n")
  })
})

## =========================================================================
## 12. COMPILE ROBUSTNESS TABLE
## =========================================================================

rob_table <- rbindlist(robustness_results, fill = TRUE)
fwrite(rob_table, file.path(data_dir, "robustness_results.csv"))

cat("\n=== ROBUSTNESS CHECKS COMPLETE ===\n")
print(rob_table[, .(check, estimate, se, n_obs)])
