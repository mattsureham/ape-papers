# ==============================================================================
# 04_robustness.R — Robustness checks and sensitivity analysis
# Paper: Trade Protection by Fiat (apep_0595)
# ==============================================================================

source("00_packages.R")

# --- Load data ---
nga_rice <- fread(file.path(DATA_DIR, "nga_rice.csv"))
nga_rice[, year_month := as.Date(year_month)]

# ==============================================================================
# 1. ALTERNATIVE WINDOWS
# ==============================================================================

windows <- list(
  "12m" = c(-12, 12),
  "18m" = c(-18, 17),
  "24m" = c(-24, 17)
)

window_results <- list()
for (wname in names(windows)) {
  w <- windows[[wname]]
  wdata <- nga_rice[event_time >= w[1] & event_time <= w[2]]
  wmodel <- feols(log_price ~ border_market:post | market + year_month,
                  data = wdata, cluster = ~market)
  window_results[[wname]] <- data.table(
    window = wname,
    estimate = coef(wmodel)["border_market:post"],
    se = se(wmodel)["border_market:post"],
    n = nobs(wmodel),
    n_markets = n_distinct(wdata$market)
  )
}
window_results_dt <- rbindlist(window_results)
fwrite(window_results_dt, file.path(DATA_DIR, "robustness_windows.csv"))

cat("=== Alternative Windows ===\n")
print(window_results_dt)

# ==============================================================================
# 2. LEAVE-ONE-MARKET-OUT
# ==============================================================================

markets <- unique(nga_rice$market)
lomo_results <- list()

for (m in markets) {
  lomo_data <- nga_rice[market != m]
  lomo_model <- feols(log_price ~ border_market:post | market + year_month,
                      data = lomo_data, cluster = ~market)
  lomo_results[[m]] <- data.table(
    dropped_market = m,
    estimate = coef(lomo_model)["border_market:post"],
    se = se(lomo_model)["border_market:post"]
  )
}

lomo_dt <- rbindlist(lomo_results)
fwrite(lomo_dt, file.path(DATA_DIR, "robustness_lomo.csv"))

cat("\n=== Leave-One-Market-Out ===\n")
cat("Estimate range:", round(min(lomo_dt$estimate, na.rm = TRUE), 4),
    "to", round(max(lomo_dt$estimate, na.rm = TRUE), 4), "\n")
cat("Main estimate:", round(lomo_dt[1, estimate], 4), "\n")

# ==============================================================================
# 3. WILD CLUSTER BOOTSTRAP (given modest cluster count)
# ==============================================================================

m_main <- readRDS(file.path(DATA_DIR, "model_main_basic.rds"))

tryCatch({
  boot_result <- boottest(m_main, param = "border_market:post",
                          clustid = "market", B = 9999,
                          type = "mammen")
  cat("\n=== Wild Cluster Bootstrap ===\n")
  print(boot_result)

  boot_summary <- data.table(
    method = "wild_cluster_bootstrap",
    p_value = boot_result$p_val,
    ci_lower = boot_result$conf_int[1],
    ci_upper = boot_result$conf_int[2]
  )
  fwrite(boot_summary, file.path(DATA_DIR, "robustness_wcb.csv"))
}, error = function(e) {
  cat("\nWild cluster bootstrap failed:", e$message, "\n")
  cat("Proceeding without WCB.\n")
  fwrite(data.table(method = "wild_cluster_bootstrap", p_value = NA),
         file.path(DATA_DIR, "robustness_wcb.csv"))
})

# ==============================================================================
# 4. RANDOMIZATION INFERENCE
# ==============================================================================

set.seed(20190820)  # Border closure date
n_perms <- 1000

# Get actual estimate
actual_est <- coef(m_main)["border_market:post"]

# Market-level permutation of border_market assignment
market_treat <- unique(nga_rice[, .(market, border_market)])
n_treated <- sum(market_treat$border_market)

ri_estimates <- numeric(n_perms)
for (i in seq_len(n_perms)) {
  # Permute treatment assignment across markets
  perm_treat <- market_treat[, .(market, border_market_perm = sample(border_market))]
  perm_data <- merge(nga_rice[, !c("border_market")], perm_treat, by = "market")

  perm_model <- feols(log_price ~ border_market_perm:post | market + year_month,
                      data = perm_data, cluster = ~market)
  ri_estimates[i] <- coef(perm_model)["border_market_perm:post"]

  if (i %% 100 == 0) cat("RI permutation", i, "/", n_perms, "\n")
}

ri_p_value <- mean(abs(ri_estimates) >= abs(actual_est))
cat("\n=== Randomization Inference ===\n")
cat("Actual estimate:", round(actual_est, 4), "\n")
cat("RI p-value:", round(ri_p_value, 4), "\n")

ri_summary <- data.table(
  actual_estimate = actual_est,
  ri_p_value = ri_p_value,
  n_permutations = n_perms,
  ri_mean = mean(ri_estimates),
  ri_sd = sd(ri_estimates)
)
fwrite(ri_summary, file.path(DATA_DIR, "robustness_ri.csv"))

# Save RI distribution for plotting
fwrite(data.table(perm_estimate = ri_estimates),
       file.path(DATA_DIR, "ri_distribution.csv"))

# ==============================================================================
# 5. PLACEBO TIMING (pre-treatment fake shock)
# ==============================================================================

# Fake closure 12 months before actual
placebo_date <- as.Date("2018-08-01")
nga_rice_pre <- nga_rice[year_month < as.Date("2019-08-01")]
nga_rice_pre[, placebo_post := as.integer(year_month >= placebo_date)]

m_placebo_timing <- feols(log_price ~ border_market:placebo_post | market + year_month,
                          data = nga_rice_pre, cluster = ~market)

cat("\n=== Placebo Timing (fake shock Aug 2018) ===\n")
summary(m_placebo_timing)

placebo_timing <- data.table(
  test = "placebo_timing_aug2018",
  estimate = coef(m_placebo_timing)["border_market:placebo_post"],
  se = se(m_placebo_timing)["border_market:placebo_post"],
  n = nobs(m_placebo_timing)
)
fwrite(placebo_timing, file.path(DATA_DIR, "robustness_placebo_timing.csv"))

# ==============================================================================
# 6. ALTERNATIVE TREATMENT THRESHOLDS
# ==============================================================================

thresholds <- c(100, 150, 200, 250)
threshold_results <- list()

for (thresh in thresholds) {
  nga_rice[, border_alt := as.integer(dist_to_border_km < thresh)]
  alt_model <- feols(log_price ~ border_alt:post | market + year_month,
                     data = nga_rice, cluster = ~market)
  threshold_results[[as.character(thresh)]] <- data.table(
    threshold_km = thresh,
    estimate = coef(alt_model)["border_alt:post"],
    se = se(alt_model)["border_alt:post"],
    n_treated = sum(nga_rice[, .(bm = first(border_alt)), by = market]$bm),
    n_control = sum(!nga_rice[, .(bm = first(border_alt)), by = market]$bm)
  )
}

threshold_dt <- rbindlist(threshold_results)
fwrite(threshold_dt, file.path(DATA_DIR, "robustness_thresholds.csv"))

cat("\n=== Alternative Treatment Thresholds ===\n")
print(threshold_dt)

# ==============================================================================
# 7. HONESTDID SENSITIVITY (Rambachan-Roth 2023)
# ==============================================================================

tryCatch({
  m_es <- readRDS(file.path(DATA_DIR, "model_event_study.rds"))

  # Extract event study for HonestDiD
  betahat <- coef(m_es)
  sigma <- vcov(m_es)

  # Identify pre-treatment and post-treatment coefficients
  coef_names <- names(betahat)
  pre_idx <- grep("event_time.*::-[0-9]", coef_names)
  post_idx <- grep("event_time.*::[0-9]", coef_names)

  if (length(pre_idx) > 0 & length(post_idx) > 0) {
    # Relative magnitudes approach
    honest_result <- HonestDiD::createSensitivityResults(
      betahat = betahat,
      sigma = sigma,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 0.5, by = 0.1)
    )

    cat("\n=== HonestDiD Sensitivity ===\n")
    print(honest_result)

    fwrite(as.data.table(honest_result),
           file.path(DATA_DIR, "robustness_honestdid.csv"))
  }
}, error = function(e) {
  cat("\nHonestDiD failed:", e$message, "\n")
  cat("Proceeding without HonestDiD sensitivity.\n")
})

cat("\n=== All robustness checks complete ===\n")
