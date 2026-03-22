## 03_main_analysis.R — Bunching estimation
## APEP paper apep_0737: Dodd-Frank $10B Bunching
## Implements Kleven-Waseem (2013) polynomial bunching estimator

source("00_packages.R")

bank_data <- readRDS("../data/bank_data_clean.rds")

cat("=== Main Bunching Analysis ===\n")

# ============================================================
# BUNCHING ESTIMATION FUNCTION (Kleven-Waseem 2013)
# ============================================================
# Uses average banks per quarter per bin (normalizes across
# periods with different numbers of quarters)

estimate_bunching <- function(data, threshold = 10, bin_width = 0.25,
                              lower = 5, upper = 15,
                              excluded_lower = 9, excluded_upper = 11,
                              poly_order = 5, n_boot = 500) {

  n_quarters <- n_distinct(data$yearq)

  # Create bin counts: average banks per quarter per bin
  bins <- data %>%
    filter(total_assets_B >= lower, total_assets_B < upper) %>%
    mutate(bin = floor(total_assets_B / bin_width) * bin_width + bin_width / 2) %>%
    group_by(bin) %>%
    summarise(total_count = n(), .groups = "drop") %>%
    mutate(count = total_count / n_quarters) %>%
    # Ensure all bins present
    right_join(
      tibble(bin = seq(lower + bin_width / 2, upper - bin_width / 2, by = bin_width)),
      by = "bin"
    ) %>%
    mutate(
      count = replace_na(count, 0),
      total_count = replace_na(total_count, 0)
    ) %>%
    arrange(bin)

  # Mark excluded region
  bins <- bins %>%
    mutate(
      excluded = as.integer(bin >= excluded_lower & bin < excluded_upper),
      bin_centered = bin - threshold
    )

  # Fit polynomial to non-excluded region
  bins_fit <- bins %>% filter(excluded == 0)

  if (nrow(bins_fit) < poly_order + 2) {
    stop("Not enough non-excluded bins for polynomial order")
  }

  fit <- lm(count ~ poly(bin_centered, poly_order, raw = TRUE), data = bins_fit)
  bins$counterfactual <- pmax(predict(fit, newdata = bins), 0)

  # Compute excess mass below threshold
  below_excl <- bins %>% filter(excluded == 1, bin < threshold)
  above_excl <- bins %>% filter(excluded == 1, bin >= threshold)

  B_actual_below <- sum(below_excl$count)
  B_cf_below <- sum(below_excl$counterfactual)
  B_actual_above <- sum(above_excl$count)
  B_cf_above <- sum(above_excl$counterfactual)

  excess_mass <- B_actual_below - B_cf_below
  missing_mass <- B_cf_above - B_actual_above

  # Normalized excess mass
  b_hat <- if (B_cf_below > 0) excess_mass / B_cf_below else 0

  # Bootstrap standard errors
  # Resample bank-quarter observations within the analysis window
  analysis_data <- data %>%
    filter(total_assets_B >= lower, total_assets_B < upper)
  bank_ids <- unique(analysis_data$cert)

  boot_b <- numeric(n_boot)
  for (i in seq_len(n_boot)) {
    # Block bootstrap by bank (preserves within-bank correlation)
    boot_banks <- sample(bank_ids, length(bank_ids), replace = TRUE)
    boot_sample <- bind_rows(lapply(boot_banks, function(b) {
      analysis_data %>% filter(cert == b)
    }))

    boot_bins <- boot_sample %>%
      mutate(bin = floor(total_assets_B / bin_width) * bin_width + bin_width / 2) %>%
      group_by(bin) %>%
      summarise(count = n() / n_quarters, .groups = "drop") %>%
      right_join(
        tibble(bin = seq(lower + bin_width / 2, upper - bin_width / 2, by = bin_width)),
        by = "bin"
      ) %>%
      mutate(
        count = replace_na(count, 0),
        excluded = as.integer(bin >= excluded_lower & bin < excluded_upper),
        bin_centered = bin - threshold
      )

    boot_fit_data <- boot_bins %>% filter(excluded == 0)
    boot_fit <- tryCatch(
      lm(count ~ poly(bin_centered, poly_order, raw = TRUE), data = boot_fit_data),
      error = function(e) NULL
    )
    if (is.null(boot_fit)) { boot_b[i] <- NA; next }

    boot_bins$cf <- pmax(predict(boot_fit, newdata = boot_bins), 0)
    boot_below <- boot_bins %>% filter(excluded == 1, bin < threshold)
    cf_sum <- sum(boot_below$cf)
    boot_b[i] <- if (cf_sum > 0) (sum(boot_below$count) - cf_sum) / cf_sum else NA
  }

  boot_b <- boot_b[!is.na(boot_b)]
  se_b <- sd(boot_b)

  list(
    bins = bins,
    b_hat = b_hat,
    se_b = se_b,
    excess_mass = excess_mass,
    missing_mass = missing_mass,
    B_cf_below = B_cf_below,
    B_cf_above = B_cf_above,
    t_stat = b_hat / se_b,
    p_value = 2 * pnorm(-abs(b_hat / se_b)),
    n_obs = nrow(analysis_data),
    n_banks = n_distinct(analysis_data$cert),
    n_quarters = n_quarters
  )
}

# ============================================================
# MAIN RESULTS
# ============================================================

# Pre-Dodd-Frank (2001-2009)
pre_data <- bank_data %>% filter(period == "pre_dodd_frank")
cat(sprintf("\nPre-Dodd-Frank: %d obs, %d banks, %d quarters\n",
            nrow(pre_data), n_distinct(pre_data$cert), n_distinct(pre_data$yearq)))
pre_result <- estimate_bunching(pre_data, n_boot = 500)
cat(sprintf("  Excess mass (b): %.3f (SE: %.3f, t: %.2f, p: %.3f)\n",
            pre_result$b_hat, pre_result$se_b, pre_result$t_stat, pre_result$p_value))

# Post-Dodd-Frank (2011-2017)
post_data <- bank_data %>% filter(period == "post_dodd_frank")
cat(sprintf("\nPost-Dodd-Frank: %d obs, %d banks, %d quarters\n",
            nrow(post_data), n_distinct(post_data$cert), n_distinct(post_data$yearq)))
post_result <- estimate_bunching(post_data, n_boot = 500)
cat(sprintf("  Excess mass (b): %.3f (SE: %.3f, t: %.2f, p: %.3f)\n",
            post_result$b_hat, post_result$se_b, post_result$t_stat, post_result$p_value))

# Post-EGRRCPA (2019-2024)
egrrcpa_data <- bank_data %>% filter(period == "post_egrrcpa")
cat(sprintf("\nPost-EGRRCPA: %d obs, %d banks, %d quarters\n",
            nrow(egrrcpa_data), n_distinct(egrrcpa_data$cert), n_distinct(egrrcpa_data$yearq)))
egrrcpa_result <- estimate_bunching(egrrcpa_data, n_boot = 500)
cat(sprintf("  Excess mass (b): %.3f (SE: %.3f, t: %.2f, p: %.3f)\n",
            egrrcpa_result$b_hat, egrrcpa_result$se_b, egrrcpa_result$t_stat, egrrcpa_result$p_value))

# ============================================================
# DIFFERENCE-IN-BUNCHING
# ============================================================

cat("\n=== Difference-in-Bunching ===\n")
dib <- post_result$b_hat - pre_result$b_hat
dib_se <- sqrt(post_result$se_b^2 + pre_result$se_b^2)
cat(sprintf("DiB (Post - Pre): %.3f (SE: %.3f, t: %.2f)\n",
            dib, dib_se, dib / dib_se))

deb <- egrrcpa_result$b_hat - post_result$b_hat
deb_se <- sqrt(egrrcpa_result$se_b^2 + post_result$se_b^2)
cat(sprintf("De-Bunching (EGRRCPA - DF): %.3f (SE: %.3f, t: %.2f)\n",
            deb, deb_se, deb / deb_se))

# ============================================================
# SHARE-BASED TEST (simpler, more robust)
# ============================================================

cat("\n=== Share Below $10B in $8B-$12B Window ===\n")

window_data <- bank_data %>%
  filter(total_assets_B >= 8, total_assets_B <= 12)

share_by_period <- window_data %>%
  group_by(period) %>%
  summarise(
    n = n(),
    n_below = sum(below_10B),
    share_below = mean(below_10B),
    se = sqrt(mean(below_10B) * (1 - mean(below_10B)) / n()),
    .groups = "drop"
  )
print(share_by_period)

# Regression: share below ~ post indicator (with quarter FE)
window_data <- window_data %>%
  mutate(
    post_df = as.integer(period == "post_dodd_frank"),
    post_egrrcpa = as.integer(period == "post_egrrcpa")
  )

# DiD-style regression: below_10B ~ post_df + post_egrrcpa | quarter
share_reg <- feols(below_10B ~ post_df + post_egrrcpa | quarter,
                   data = window_data, vcov = "hetero")
cat("\nShare regression (base = pre-Dodd-Frank):\n")
print(summary(share_reg))

# ============================================================
# SAVE
# ============================================================

results <- list(
  pre = pre_result,
  post = post_result,
  egrrcpa = egrrcpa_result,
  dib = list(estimate = dib, se = dib_se, t = dib / dib_se),
  deb = list(estimate = deb, se = deb_se, t = deb / deb_se),
  share_reg = share_reg,
  share_by_period = share_by_period
)

saveRDS(results, "../data/bunching_results.rds")

# Diagnostics for validator
diagnostics <- list(
  n_treated = n_distinct(post_data$cert[post_data$total_assets_B >= 8 &
                                         post_data$total_assets_B <= 12]),
  n_pre = n_distinct(pre_data$yearq),
  n_obs = nrow(bank_data)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nResults saved.\n")
