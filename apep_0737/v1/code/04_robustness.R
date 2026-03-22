## 04_robustness.R — Robustness checks and placebo tests
## APEP paper apep_0737: Dodd-Frank $10B Bunching

source("00_packages.R")

# Source main analysis to get estimate_bunching()
# (This re-runs the function definition, not the full analysis)
# We need to re-define the function here to avoid re-running everything
bank_data <- readRDS("../data/bank_data_clean.rds")
results <- readRDS("../data/bunching_results.rds")

# Copy the estimate_bunching function
estimate_bunching <- function(data, threshold = 10, bin_width = 0.25,
                              lower = 5, upper = 15,
                              excluded_lower = 9, excluded_upper = 11,
                              poly_order = 5, n_boot = 200) {

  n_quarters <- n_distinct(data$yearq)

  bins <- data %>%
    filter(total_assets_B >= lower, total_assets_B < upper) %>%
    mutate(bin = floor(total_assets_B / bin_width) * bin_width + bin_width / 2) %>%
    group_by(bin) %>%
    summarise(total_count = n(), .groups = "drop") %>%
    mutate(count = total_count / n_quarters) %>%
    right_join(
      tibble(bin = seq(lower + bin_width / 2, upper - bin_width / 2, by = bin_width)),
      by = "bin"
    ) %>%
    mutate(count = replace_na(count, 0), total_count = replace_na(total_count, 0)) %>%
    arrange(bin)

  bins <- bins %>%
    mutate(
      excluded = as.integer(bin >= excluded_lower & bin < excluded_upper),
      bin_centered = bin - threshold
    )

  bins_fit <- bins %>% filter(excluded == 0)
  if (nrow(bins_fit) < poly_order + 2) return(list(b_hat = NA, se_b = NA, t_stat = NA))

  fit <- lm(count ~ poly(bin_centered, poly_order, raw = TRUE), data = bins_fit)
  bins$counterfactual <- pmax(predict(fit, newdata = bins), 0)

  below_excl <- bins %>% filter(excluded == 1, bin < threshold)
  B_actual_below <- sum(below_excl$count)
  B_cf_below <- sum(below_excl$counterfactual)
  b_hat <- if (B_cf_below > 0) (B_actual_below - B_cf_below) / B_cf_below else 0

  # Bootstrap
  analysis_data <- data %>% filter(total_assets_B >= lower, total_assets_B < upper)
  bank_ids <- unique(analysis_data$cert)
  boot_b <- numeric(n_boot)

  for (i in seq_len(n_boot)) {
    boot_banks <- sample(bank_ids, length(bank_ids), replace = TRUE)
    boot_sample <- bind_rows(lapply(boot_banks, function(b) analysis_data %>% filter(cert == b)))
    boot_bins <- boot_sample %>%
      mutate(bin = floor(total_assets_B / bin_width) * bin_width + bin_width / 2) %>%
      group_by(bin) %>%
      summarise(count = n() / n_quarters, .groups = "drop") %>%
      right_join(tibble(bin = seq(lower + bin_width / 2, upper - bin_width / 2, by = bin_width)), by = "bin") %>%
      mutate(count = replace_na(count, 0),
             excluded = as.integer(bin >= excluded_lower & bin < excluded_upper),
             bin_centered = bin - threshold)
    boot_fit <- tryCatch(
      lm(count ~ poly(bin_centered, poly_order, raw = TRUE), data = boot_bins %>% filter(excluded == 0)),
      error = function(e) NULL)
    if (is.null(boot_fit)) { boot_b[i] <- NA; next }
    boot_bins$cf <- pmax(predict(boot_fit, newdata = boot_bins), 0)
    bb <- boot_bins %>% filter(excluded == 1, bin < threshold)
    cf_sum <- sum(bb$cf)
    boot_b[i] <- if (cf_sum > 0) (sum(bb$count) - cf_sum) / cf_sum else NA
  }
  boot_b <- boot_b[!is.na(boot_b)]
  se_b <- sd(boot_b)

  list(bins = bins, b_hat = b_hat, se_b = se_b,
       t_stat = b_hat / se_b, p_value = 2 * pnorm(-abs(b_hat / se_b)))
}

cat("=== ROBUSTNESS CHECKS ===\n")

# ============================================================
# 1. PLACEBO THRESHOLDS
# ============================================================

cat("\n--- Placebo Thresholds (Post-Dodd-Frank) ---\n")
post_data <- bank_data %>% filter(period == "post_dodd_frank")

placebo_thresholds <- c(7, 8, 13, 15)
placebo_results <- list()

for (thresh in placebo_thresholds) {
  lower <- max(thresh - 5, 1)
  upper <- min(thresh + 5, 25)
  excl_lower <- thresh - 1
  excl_upper <- thresh + 1

  res <- estimate_bunching(post_data, threshold = thresh, lower = lower, upper = upper,
                           excluded_lower = excl_lower, excluded_upper = excl_upper, n_boot = 200)
  placebo_results[[as.character(thresh)]] <- res
  cat(sprintf("  $%dB: b = %.3f (SE: %.3f, t: %.2f)\n",
              thresh, res$b_hat, res$se_b, res$t_stat))
}

# ============================================================
# 2. POLYNOMIAL ORDER SENSITIVITY
# ============================================================

cat("\n--- Polynomial Order Sensitivity ---\n")
poly_results <- list()

for (p in c(3, 4, 5, 6, 7)) {
  res <- estimate_bunching(post_data, poly_order = p, n_boot = 200)
  poly_results[[as.character(p)]] <- res
  cat(sprintf("  Order %d: b = %.3f (SE: %.3f)\n", p, res$b_hat, res$se_b))
}

# ============================================================
# 3. BIN WIDTH SENSITIVITY
# ============================================================

cat("\n--- Bin Width Sensitivity ---\n")
bin_results <- list()

for (bw in c(0.1, 0.25, 0.5, 1.0)) {
  res <- estimate_bunching(post_data, bin_width = bw, n_boot = 200)
  bin_results[[as.character(bw)]] <- res
  cat(sprintf("  $%.0fM: b = %.3f (SE: %.3f)\n", bw * 1000, res$b_hat, res$se_b))
}

# ============================================================
# 4. EXCLUDED REGION SENSITIVITY
# ============================================================

cat("\n--- Excluded Region Sensitivity ---\n")
window_results <- list()

for (excl in list(c(9, 11), c(8.5, 11.5), c(9.5, 10.5), c(8, 12))) {
  label <- sprintf("[%.1f, %.1f)", excl[1], excl[2])
  res <- estimate_bunching(post_data, excluded_lower = excl[1], excluded_upper = excl[2], n_boot = 200)
  window_results[[label]] <- res
  cat(sprintf("  %s: b = %.3f (SE: %.3f)\n", label, res$b_hat, res$se_b))
}

# ============================================================
# 5. YEAR-BY-YEAR EVOLUTION
# ============================================================

cat("\n--- Year-by-Year Bunching ---\n")
yearly_results <- list()

for (yr in 2003:2024) {
  yr_data <- bank_data %>% filter(year == yr)
  if (nrow(yr_data) < 50) next

  res <- estimate_bunching(yr_data, n_boot = 100)
  yearly_results[[as.character(yr)]] <- list(
    year = yr,
    b_hat = res$b_hat,
    se_b = res$se_b
  )
  cat(sprintf("  %d: b = %.3f (SE: %.3f)\n", yr, res$b_hat, res$se_b))
}

# ============================================================
# 6. McCRARY-STYLE DENSITY TEST
# ============================================================

cat("\n--- Density Discontinuity at $10B ---\n")

post_bins <- post_data %>%
  filter(total_assets_B >= 7, total_assets_B <= 13) %>%
  mutate(bin = floor(total_assets_B / 0.25) * 0.25 + 0.125) %>%
  group_by(bin) %>%
  summarise(count = n() / n_distinct(post_data$yearq), .groups = "drop") %>%
  mutate(
    above = as.integer(bin >= 10),
    dist = bin - 10
  )

mccrary_fit <- lm(log(count + 0.1) ~ dist * above, data = post_bins)
cat(sprintf("  Log-density jump at $10B: %.3f (SE: %.3f, t: %.2f)\n",
            coef(mccrary_fit)["above"],
            summary(mccrary_fit)$coefficients["above", "Std. Error"],
            summary(mccrary_fit)$coefficients["above", "t value"]))

# ============================================================
# 7. SHARE-BASED PLACEBO (Pre-period)
# ============================================================

cat("\n--- Pre-Period Share Test (No Policy) ---\n")
# Use 2005 as a fake "treatment date" in the pre-period
pre_data <- bank_data %>%
  filter(year >= 2001, year <= 2009, total_assets_B >= 8, total_assets_B <= 12) %>%
  mutate(post_2005 = as.integer(year >= 2005))

pre_placebo <- feols(below_10B ~ post_2005 | quarter, data = pre_data, vcov = "hetero")
cat("  Placebo (pre-period only, fake treatment 2005):\n")
cat(sprintf("  post_2005: %.4f (SE: %.4f, t: %.2f)\n",
            coef(pre_placebo)["post_2005"],
            sqrt(vcov(pre_placebo)["post_2005", "post_2005"]),
            coef(pre_placebo)["post_2005"] / sqrt(vcov(pre_placebo)["post_2005", "post_2005"])))

# ============================================================
# SAVE
# ============================================================

robustness <- list(
  placebo = placebo_results,
  polynomial = poly_results,
  bin_width = bin_results,
  window = window_results,
  yearly = yearly_results,
  mccrary = mccrary_fit
)
saveRDS(robustness, "../data/robustness_results.rds")

yearly_df <- bind_rows(yearly_results) %>%
  mutate(period = case_when(
    year <= 2009 ~ "Pre-Dodd-Frank",
    year == 2010 ~ "Transition",
    year >= 2011 & year <= 2017 ~ "Post-Dodd-Frank",
    year == 2018 ~ "EGRRCPA",
    year >= 2019 ~ "Post-EGRRCPA"
  ))
saveRDS(yearly_df, "../data/yearly_bunching.rds")

cat("\nRobustness results saved.\n")
