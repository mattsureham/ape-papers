# 04_robustness.R — Robustness checks and placebo tests
source("00_packages.R")

cat("=== Robustness Checks ===\n")

analysis <- readRDS("../data/analysis.rds")
results <- readRDS("../data/results.rds")

# Source the bunching function
estimate_bunching <- function(data, threshold, bin_width = 0.5,
                               exclude_lower = 2, exclude_upper = 2,
                               poly_order = 7, window = 20) {
  data <- data %>%
    mutate(bin = floor(pct_change / bin_width) * bin_width + bin_width / 2)

  bin_counts <- data %>%
    filter(bin >= (threshold - window) & bin <= (threshold + window)) %>%
    count(bin) %>%
    mutate(
      dist = bin - threshold,
      in_bunching_region = dist >= -exclude_lower & dist <= exclude_upper,
      below_threshold = dist >= -exclude_lower & dist < 0,
      above_threshold = dist >= 0 & dist <= exclude_upper
    )

  fit_data <- bin_counts %>% filter(!in_bunching_region)
  if (nrow(fit_data) < poly_order + 1) return(NULL)

  poly_fit <- lm(n ~ poly(dist, poly_order, raw = TRUE), data = fit_data)
  bin_counts <- bin_counts %>%
    mutate(counterfactual = predict(poly_fit, newdata = .))

  bunching_region <- bin_counts %>% filter(in_bunching_region)
  B_observed <- sum(bunching_region$n)
  B_counterfactual <- sum(bunching_region$counterfactual)
  b <- (B_observed - B_counterfactual) / B_counterfactual

  below_region <- bin_counts %>% filter(below_threshold)
  b_below <- (sum(below_region$n) - sum(below_region$counterfactual)) / sum(below_region$counterfactual)

  list(threshold = threshold, b = b, b_below = b_below,
       B_observed = B_observed, B_counterfactual = B_counterfactual)
}

bootstrap_bunching <- function(data, threshold, n_boot = 200, ...) {
  b_vec <- numeric(n_boot)
  for (i in seq_len(n_boot)) {
    boot_data <- data[sample(nrow(data), replace = TRUE), ]
    result <- estimate_bunching(boot_data, threshold, ...)
    if (!is.null(result)) b_vec[i] <- result$b
  }
  list(se_b = sd(b_vec, na.rm = TRUE))
}

pre_data  <- analysis %>% filter(year <= 2016)
post_data <- analysis %>% filter(year >= 2018)

# ==================================================================
# 1. PLACEBO THRESHOLDS: Test bunching at non-policy thresholds
# ==================================================================
cat("\n--- Placebo thresholds (should show no differential bunching) ---\n")

placebo_thresholds <- c(5, 7, 13, 15, 20, 25)
set.seed(42)

placebo_results <- lapply(placebo_thresholds, function(th) {
  pre  <- estimate_bunching(pre_data,  threshold = th)
  post <- estimate_bunching(post_data, threshold = th)

  if (is.null(pre) || is.null(post)) return(NULL)

  boot_pre  <- bootstrap_bunching(pre_data,  threshold = th, n_boot = 200)
  boot_post <- bootstrap_bunching(post_data, threshold = th, n_boot = 200)

  tibble(
    threshold = th,
    b_pre = pre$b,
    b_post = post$b,
    diff = post$b - pre$b,
    se_pre = boot_pre$se_b,
    se_post = boot_post$se_b
  )
}) %>%
  bind_rows()

cat("Placebo threshold results:\n")
print(placebo_results)

# ==================================================================
# 2. ALTERNATIVE BIN WIDTHS
# ==================================================================
cat("\n--- Alternative bin widths ---\n")

bin_widths <- c(0.25, 0.5, 1.0, 2.0)
binwidth_results <- lapply(bin_widths, function(bw) {
  pre  <- estimate_bunching(pre_data,  threshold = 10, bin_width = bw)
  post <- estimate_bunching(post_data, threshold = 10, bin_width = bw)

  tibble(
    bin_width = bw,
    b_pre = pre$b,
    b_post = post$b,
    diff = post$b - pre$b
  )
}) %>%
  bind_rows()

cat("Bin width sensitivity:\n")
print(binwidth_results)

# ==================================================================
# 3. ALTERNATIVE POLYNOMIAL ORDERS
# ==================================================================
cat("\n--- Alternative polynomial orders ---\n")

poly_orders <- c(5, 6, 7, 8, 9)
polyord_results <- lapply(poly_orders, function(p) {
  pre  <- estimate_bunching(pre_data,  threshold = 10, poly_order = p)
  post <- estimate_bunching(post_data, threshold = 10, poly_order = p)

  tibble(
    poly_order = p,
    b_pre = pre$b,
    b_post = post$b,
    diff = post$b - pre$b
  )
}) %>%
  bind_rows()

cat("Polynomial order sensitivity:\n")
print(polyord_results)

# ==================================================================
# 4. DONUT ESTIMATES (exclude narrow window around threshold)
# ==================================================================
cat("\n--- Donut estimates ---\n")

donut_results <- lapply(c(0.5, 1.0, 1.5, 2.0, 3.0), function(excl) {
  pre  <- estimate_bunching(pre_data,  threshold = 10,
                             exclude_lower = excl, exclude_upper = excl)
  post <- estimate_bunching(post_data, threshold = 10,
                             exclude_lower = excl, exclude_upper = excl)

  tibble(
    exclude_width = excl,
    b_pre = pre$b,
    b_post = post$b,
    diff = post$b - pre$b
  )
}) %>%
  bind_rows()

cat("Donut estimate sensitivity:\n")
print(donut_results)

# ==================================================================
# 5. HIGH-PRICE vs LOW-PRICE DRUGS
# ==================================================================
cat("\n--- Heterogeneity: high-price vs low-price drugs ---\n")

median_price <- median(analysis$price_lag, na.rm = TRUE)

high_pre  <- analysis %>% filter(year <= 2016, price_lag >= median_price)
high_post <- analysis %>% filter(year >= 2018, price_lag >= median_price)
low_pre   <- analysis %>% filter(year <= 2016, price_lag <  median_price)
low_post  <- analysis %>% filter(year >= 2018, price_lag <  median_price)

bunch_high_pre  <- estimate_bunching(high_pre,  threshold = 10)
bunch_high_post <- estimate_bunching(high_post, threshold = 10)
bunch_low_pre   <- estimate_bunching(low_pre,   threshold = 10)
bunch_low_post  <- estimate_bunching(low_post,  threshold = 10)

cat(sprintf("High-price drugs: pre b=%.3f, post b=%.3f, diff=%.3f\n",
            bunch_high_pre$b, bunch_high_post$b,
            bunch_high_post$b - bunch_high_pre$b))
cat(sprintf("Low-price drugs:  pre b=%.3f, post b=%.3f, diff=%.3f\n",
            bunch_low_pre$b, bunch_low_post$b,
            bunch_low_post$b - bunch_low_pre$b))

# ==================================================================
# 6. PERIOD-BY-PERIOD bunching estimates (event study analog)
# ==================================================================
cat("\n--- Period-by-period bunching at 10% ---\n")

unique_periods <- sort(unique(analysis$period))
period_bunching <- lapply(unique_periods, function(pd) {
  pd_data <- analysis %>% filter(period == pd)
  if (nrow(pd_data) < 100) return(NULL)

  result <- estimate_bunching(pd_data, threshold = 10)
  if (is.null(result)) return(NULL)

  boot <- bootstrap_bunching(pd_data, threshold = 10, n_boot = 200)

  tibble(
    period = pd,
    year = floor(pd),
    half = ifelse(pd == floor(pd), 1L, 2L),
    b = result$b,
    se = boot$se_b,
    n = nrow(pd_data)
  )
}) %>%
  bind_rows()

cat("Period-by-period bunching:\n")
print(period_bunching)

# ==================================================================
# Save all robustness results
# ==================================================================
robustness <- list(
  placebo = placebo_results,
  binwidth = binwidth_results,
  polyord = polyord_results,
  donut = donut_results,
  heterogeneity = list(
    high_pre = bunch_high_pre, high_post = bunch_high_post,
    low_pre = bunch_low_pre, low_post = bunch_low_post
  ),
  period_bunching = period_bunching
)

saveRDS(robustness, "../data/robustness.rds")
cat("\nSaved: ../data/robustness.rds\n")
