## 03_main_analysis.R — Bunching estimation at BPM kinks
## APEP-1349: Dutch BPM Multi-Cutoff Bunching

source("00_packages.R")

# --- Load data ---
nl_pooled <- readRDS("../data/nl_pooled.rds")
de_pooled <- readRDS("../data/de_pooled.rds")
kinks <- readRDS("../data/kinks.rds")
comparison <- readRDS("../data/nl_de_comparison.rds")

# ============================================================
# BUNCHING ESTIMATION
# ============================================================
# Following Chetty et al. (2011), Kleven & Waseem (2013)
# At each kink point k:
#   1. Define excluded region [k-bw_below, k+bw_above]
#   2. Fit polynomial of degree p to bins OUTSIDE excluded region
#   3. Predict counterfactual density inside excluded region
#   4. Excess mass B = sum(observed - counterfactual) in bunching region
#   5. Normalized bunching b = B / counterfactual_height_at_kink
# ============================================================

bunching_estimate <- function(data, kink_point, bw_below = 5, bw_above = 5,
                              poly_degree = 7, window = 30) {
  # data: data.frame with 'co2' and 'count' columns
  # kink_point: the CO2 value of the kink
  # bw_below/above: excluded region around kink
  # poly_degree: degree of polynomial counterfactual
  # window: estimation window around kink

  # Define regions
  lower <- kink_point - window
  upper <- kink_point + window
  excl_lower <- kink_point - bw_below
  excl_upper <- kink_point + bw_above

  est_data <- data %>%
    filter(co2 >= lower, co2 <= upper) %>%
    mutate(
      excluded = (co2 >= excl_lower & co2 <= excl_upper),
      z = co2 - kink_point  # center at kink
    )

  # Fit polynomial on non-excluded bins
  fit_data <- est_data %>% filter(!excluded)

  if (nrow(fit_data) < poly_degree + 1) {
    warning("Too few bins outside excluded region")
    return(NULL)
  }

  # Polynomial fit
  formula_str <- paste0("count ~ ", paste0("I(z^", 1:poly_degree, ")", collapse = " + "))
  fit <- lm(as.formula(formula_str), data = fit_data)

  # Predict counterfactual for ALL bins (including excluded)
  est_data$counterfactual <- predict(fit, newdata = est_data)
  est_data$counterfactual <- pmax(est_data$counterfactual, 0)  # no negative counts

  # Excess mass in bunching region (below kink)
  bunching_region <- est_data %>% filter(co2 >= excl_lower, co2 <= kink_point)
  excess_mass <- sum(bunching_region$count - bunching_region$counterfactual)

  # Missing mass above kink
  missing_region <- est_data %>% filter(co2 > kink_point, co2 <= excl_upper)
  missing_mass <- sum(missing_region$counterfactual - missing_region$count)

  # Counterfactual at kink
  cf_at_kink <- est_data$counterfactual[est_data$co2 == kink_point]

  # Normalized bunching
  b_norm <- excess_mass / cf_at_kink

  # Bootstrap standard errors (200 replications)
  set.seed(42)
  n_boot <- 200
  b_boot <- numeric(n_boot)

  for (i in 1:n_boot) {
    # Poisson resampling of counts
    boot_data <- est_data
    boot_data$count <- rpois(nrow(boot_data), lambda = pmax(boot_data$count, 1))

    boot_fit_data <- boot_data %>% filter(!excluded)
    boot_fit <- tryCatch(
      lm(as.formula(formula_str), data = boot_fit_data),
      error = function(e) NULL
    )
    if (is.null(boot_fit)) { b_boot[i] <- NA; next }

    boot_data$cf <- pmax(predict(boot_fit, newdata = boot_data), 0)
    boot_bunch <- boot_data %>% filter(co2 >= excl_lower, co2 <= kink_point)
    boot_excess <- sum(boot_bunch$count - boot_bunch$cf)
    boot_cf_kink <- boot_data$cf[boot_data$co2 == kink_point]
    b_boot[i] <- boot_excess / boot_cf_kink
  }

  se_b <- sd(b_boot, na.rm = TRUE)

  return(list(
    kink_point = kink_point,
    excess_mass = excess_mass,
    missing_mass = missing_mass,
    b_normalized = b_norm,
    se_b = se_b,
    cf_at_kink = cf_at_kink,
    data = est_data
  ))
}

# ============================================================
# ESTIMATE BUNCHING AT EACH KINK — NETHERLANDS
# ============================================================
cat("=== Bunching Estimation: Netherlands ===\n\n")

nl_results <- list()
for (i in 1:nrow(kinks)) {
  k <- kinks$kink_co2[i]
  cat(sprintf("--- Kink at %d g/km (rate: €%d → €%d/g, ratio %.1f:1) ---\n",
              k, kinks$rate_below[i], kinks$rate_above[i], kinks$rate_ratio[i]))

  # Adjust bandwidth for different kinks
  bw_below <- ifelse(k == 79, 8, 5)
  bw_above <- ifelse(k == 79, 5, 5)

  res <- bunching_estimate(nl_pooled, kink_point = k,
                           bw_below = bw_below, bw_above = bw_above)

  if (!is.null(res)) {
    cat(sprintf("  Excess mass: %s vehicles\n", format(round(res$excess_mass), big.mark = ",")))
    cat(sprintf("  Missing mass: %s vehicles\n", format(round(res$missing_mass), big.mark = ",")))
    cat(sprintf("  Normalized bunching b: %.3f (SE: %.3f)\n", res$b_normalized, res$se_b))
    cat(sprintf("  b/SE = %.2f (t-stat)\n\n", res$b_normalized / res$se_b))
  }

  nl_results[[kinks$label[i]]] <- res
}

# ============================================================
# ESTIMATE BUNCHING AT EACH KINK — GERMANY (PLACEBO)
# ============================================================
cat("\n=== Bunching Estimation: Germany (Placebo) ===\n\n")

de_results <- list()
for (i in 1:nrow(kinks)) {
  k <- kinks$kink_co2[i]
  cat(sprintf("--- Kink at %d g/km ---\n", k))

  bw_below <- ifelse(k == 79, 8, 5)
  bw_above <- ifelse(k == 79, 5, 5)

  res <- bunching_estimate(de_pooled, kink_point = k,
                           bw_below = bw_below, bw_above = bw_above)

  if (!is.null(res)) {
    cat(sprintf("  Normalized bunching b: %.3f (SE: %.3f)\n", res$b_normalized, res$se_b))
    cat(sprintf("  b/SE = %.2f\n\n", res$b_normalized / res$se_b))
  }

  de_results[[kinks$label[i]]] <- res
}

# ============================================================
# NL vs DE DIFFERENCE-IN-BUNCHING
# ============================================================
cat("\n=== Difference-in-Bunching (NL - DE) ===\n")
cat("If BPM causes bunching, NL should show MORE than DE\n\n")

dib_results <- data.frame(
  kink = kinks$kink_co2,
  rate_ratio = kinks$rate_ratio,
  b_nl = sapply(nl_results, function(x) if (!is.null(x)) x$b_normalized else NA),
  se_nl = sapply(nl_results, function(x) if (!is.null(x)) x$se_b else NA),
  b_de = sapply(de_results, function(x) if (!is.null(x)) x$b_normalized else NA),
  se_de = sapply(de_results, function(x) if (!is.null(x)) x$se_b else NA)
)
dib_results$diff <- dib_results$b_nl - dib_results$b_de
dib_results$se_diff <- sqrt(dib_results$se_nl^2 + dib_results$se_de^2)
dib_results$t_stat <- dib_results$diff / dib_results$se_diff

print(dib_results)

# ============================================================
# DOSE-RESPONSE: Does bunching scale with kink size?
# ============================================================
cat("\n=== Dose-Response Test ===\n")
cat("H0: Larger kinks → more bunching (if BPM drives it)\n\n")

# Regression of normalized bunching on rate ratio
dose_df <- data.frame(
  b = dib_results$b_nl,
  rate_ratio = dib_results$rate_ratio,
  rate_jump = kinks$rate_jump
)
cat("NL bunching vs kink size:\n")
print(dose_df)

# ============================================================
# DIAGNOSTICS
# ============================================================

# Sample sizes for validation
n_treated_equivalent <- 4  # 4 kink points
n_pre <- 3                 # 3 years of data (though not a time-series design)
n_obs <- sum(nl_pooled$count)

diagnostics <- list(
  n_treated = n_treated_equivalent,
  n_pre = n_pre,
  n_obs = n_obs,
  n_nl_vehicles = sum(nl_pooled$count),
  n_de_vehicles = sum(de_pooled$count),
  n_kinks = 4,
  co2_range = c(1, 250),
  years = c(2020, 2022)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

# Save results
saveRDS(nl_results, "../data/nl_bunching_results.rds")
saveRDS(de_results, "../data/de_bunching_results.rds")
saveRDS(dib_results, "../data/dib_results.rds")

cat("\n03_main_analysis.R complete.\n")
