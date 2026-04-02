## 03_main_analysis.R — Bunching estimation at three thresholds
## APEP-1329: UK FIT Triple-Threshold Bunching

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

df <- readRDS(file.path(data_dir, "fit_solar_clean.rds"))

# ── Filter to FIT period (2010-2019) ──
df <- df %>% filter(year >= 2010 & year <= 2019)
cat(sprintf("FIT period (2010-2019): %d installations\n", nrow(df)))

# ── Define analysis windows around each threshold ──
# Following Kleven & Waseem (2013): fit polynomial to distribution
# excluding a window around the kink, then compute excess mass

# Helper: compute bunching statistics for a given threshold
estimate_bunching <- function(data, threshold, bin_width = 0.1,
                              window_low = NULL, window_high = NULL,
                              poly_order = 7, label = "") {
  # Default windows
  if (is.null(window_low)) window_low <- threshold * 0.5
  if (is.null(window_high)) window_high <- threshold * 1.5

  # Subset to analysis window
  d <- data %>%
    filter(capacity_kw >= window_low & capacity_kw <= window_high)

  # Create bins
  d <- d %>%
    mutate(bin = round(capacity_kw / bin_width) * bin_width)

  # Count installations per bin
  bin_counts <- d %>%
    count(bin) %>%
    complete(bin = seq(window_low, window_high, by = bin_width), fill = list(n = 0))

  # Exclude bunching region: [threshold - 2*bin_width, threshold]
  bunching_region <- bin_counts$bin >= (threshold - 2 * bin_width) &
    bin_counts$bin <= threshold
  # Also exclude the "missing mass" region just above threshold
  missing_region <- bin_counts$bin > threshold &
    bin_counts$bin <= (threshold + 5 * bin_width)

  exclude <- bunching_region | missing_region

  # Fit polynomial to non-bunching region
  fit_data <- bin_counts %>%
    filter(!exclude) %>%
    mutate(z = bin - threshold)

  fit <- lm(n ~ poly(z, poly_order, raw = TRUE), data = fit_data)

  # Predict counterfactual for all bins
  bin_counts <- bin_counts %>%
    mutate(
      z = bin - threshold,
      counterfactual = pmax(predict(fit, newdata = data.frame(z = z)), 0)
    )

  # Excess mass in bunching region
  bunch_bins <- bin_counts %>% filter(bunching_region)
  B_hat <- sum(bunch_bins$n) - sum(bunch_bins$counterfactual)
  h0 <- mean(bin_counts$counterfactual[!exclude])  # average counterfactual height

  # Normalized excess mass
  b_hat <- B_hat / h0

  # Standard error via bootstrap
  set.seed(42)
  n_boot <- 200
  b_boot <- numeric(n_boot)

  for (boot in 1:n_boot) {
    # Resample residuals
    resid <- bin_counts$n[!exclude] - bin_counts$counterfactual[!exclude]
    boot_resid <- sample(resid, sum(!exclude), replace = TRUE)
    boot_counts <- bin_counts
    boot_counts$n[!exclude] <- boot_counts$counterfactual[!exclude] + boot_resid
    boot_counts$n <- pmax(boot_counts$n, 0)

    # Refit
    boot_fit_data <- boot_counts %>% filter(!exclude)
    boot_lm <- lm(n ~ poly(z, poly_order, raw = TRUE), data = boot_fit_data)
    boot_counts$cf_boot <- pmax(predict(boot_lm, newdata = data.frame(z = boot_counts$z)), 0)

    b_bunch <- boot_counts %>% filter(bunching_region)
    B_b <- sum(b_bunch$n) - sum(b_bunch$cf_boot)
    h0_b <- mean(boot_counts$cf_boot[!exclude])
    b_boot[boot] <- B_b / h0_b
  }

  se_b <- sd(b_boot)

  cat(sprintf("\n=== %s: Threshold = %.0f kW ===\n", label, threshold))
  cat(sprintf("  Installations in window: %d\n", nrow(d)))
  cat(sprintf("  At threshold: %d\n", sum(d$capacity_kw == threshold)))
  cat(sprintf("  Excess mass (B_hat): %.0f\n", B_hat))
  cat(sprintf("  Normalized excess mass (b_hat): %.2f (SE: %.2f)\n", b_hat, se_b))

  list(
    threshold = threshold,
    label = label,
    b_hat = b_hat,
    se_b = se_b,
    B_hat = B_hat,
    n_window = nrow(d),
    n_at_threshold = sum(d$capacity_kw == threshold),
    bin_counts = bin_counts,
    bunching_region = bunching_region,
    exclude = exclude
  )
}

# ── Estimate bunching at all three thresholds ──

# 4 kW — residential installations, largest volume
# Window: 2-6 kW, bin width 0.05 kW
res_4kw <- estimate_bunching(df, threshold = 4, bin_width = 0.05,
                              window_low = 2, window_high = 6,
                              poly_order = 7, label = "4 kW (Full period)")

# 10 kW — small commercial
# Window: 5-15 kW, bin width 0.1 kW
res_10kw <- estimate_bunching(df, threshold = 10, bin_width = 0.1,
                               window_low = 5, window_high = 15,
                               poly_order = 7, label = "10 kW")

# 50 kW — commercial threshold
# Window: 25-75 kW, bin width 0.5 kW
res_50kw <- estimate_bunching(df, threshold = 50, bin_width = 0.5,
                               window_low = 25, window_high = 75,
                               poly_order = 7, label = "50 kW")

# ── 4 kW: Pre- vs Post-merger comparison ──
df_pre <- df %>% filter(pre_merger)
df_post <- df %>% filter(post_merger)

res_4kw_pre <- estimate_bunching(df_pre, threshold = 4, bin_width = 0.05,
                                  window_low = 2, window_high = 6,
                                  poly_order = 7, label = "4 kW (Pre-merger)")

res_4kw_post <- estimate_bunching(df_post, threshold = 4, bin_width = 0.05,
                                   window_low = 2, window_high = 6,
                                   poly_order = 7, label = "4 kW (Post-merger)")

# ── Estimate implied elasticities ──
# For a kink (not a notch), the bunching formula is:
#   b = e * log(1-t_above) / log(1-t_below)  (approximately)
# But we need the tariff differentials. Use representative tariff rates.

# Representative tariff rates (pence/kWh) — from Ofgem published schedules
# Period 1 (April 2010): <=4kW = 41.3p, 4-10kW = 36.1p, 10-50kW = 31.4p, >50kW = 29.3p
# Period 7 (Jan 2013): <=4kW = 15.44p, 4-10kW = 13.99p, 10-50kW = 13.03p
# Post-2016 (after merger): <=10kW uniform rate

# For the kink at 4 kW: the marginal tariff drops from t_below to t_above
# This is a downward kink in the budget set
# Implied elasticity from Saez (2010): b_hat ≈ e * Δlog(1-t) / (bin_width * f0)
# For FIT: the "tax" is really a subsidy reduction above the threshold

cat("\n\n=== SUMMARY OF BUNCHING ESTIMATES ===\n")
results <- data.frame(
  Threshold = c("4 kW (full)", "4 kW (pre-merger)", "4 kW (post-merger)",
                "10 kW", "50 kW"),
  N_window = c(res_4kw$n_window, res_4kw_pre$n_window, res_4kw_post$n_window,
               res_10kw$n_window, res_50kw$n_window),
  N_at = c(res_4kw$n_at_threshold, res_4kw_pre$n_at_threshold,
           res_4kw_post$n_at_threshold, res_10kw$n_at_threshold,
           res_50kw$n_at_threshold),
  Excess_mass = c(res_4kw$B_hat, res_4kw_pre$B_hat, res_4kw_post$B_hat,
                  res_10kw$B_hat, res_50kw$B_hat),
  b_hat = c(res_4kw$b_hat, res_4kw_pre$b_hat, res_4kw_post$b_hat,
            res_10kw$b_hat, res_50kw$b_hat),
  se = c(res_4kw$se_b, res_4kw_pre$se_b, res_4kw_post$se_b,
         res_10kw$se_b, res_50kw$se_b)
)
results$t_stat <- results$b_hat / results$se
print(results, digits = 3)

# ── Save results for tables ──
saveRDS(list(
  res_4kw = res_4kw,
  res_4kw_pre = res_4kw_pre,
  res_4kw_post = res_4kw_post,
  res_10kw = res_10kw,
  res_50kw = res_50kw,
  summary = results
), file.path(data_dir, "bunching_results.rds"))

# ── Write diagnostics.json ──
diag <- list(
  n_treated = nrow(df),  # all installations face the tariff structure
  n_pre = sum(df$pre_merger),
  n_obs = nrow(df),
  n_at_4kw = res_4kw$n_at_threshold,
  n_at_10kw = res_10kw$n_at_threshold,
  n_at_50kw = res_50kw$n_at_threshold
)
write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")
cat("DONE: Main analysis complete.\n")
