# 03_main_analysis.R — Bunching analysis and main results
source("00_packages.R")

cat("=== Main Bunching Analysis ===\n")

analysis <- readRDS("../data/analysis.rds")

# ==================================================================
# 1. BUNCHING ESTIMATION AT KEY THRESHOLDS
# ==================================================================
# Kleven & Waseem (2013) approach:
# - Define bins around the threshold
# - Fit polynomial counterfactual excluding the bunching region
# - Excess mass = (observed - counterfactual) / counterfactual in bunching region

estimate_bunching <- function(data, threshold, bin_width = 0.5,
                               exclude_lower = 2, exclude_upper = 2,
                               poly_order = 7, window = 20) {

  # Create bins
  data <- data %>%
    mutate(bin = floor(pct_change / bin_width) * bin_width + bin_width / 2)

  # Restrict to window around threshold
  bin_counts <- data %>%
    filter(bin >= (threshold - window) & bin <= (threshold + window)) %>%
    count(bin) %>%
    mutate(
      # Distance from threshold
      dist = bin - threshold,
      # Indicator for excluded region
      in_bunching_region = dist >= -exclude_lower & dist <= exclude_upper,
      # Below threshold region (where bunching occurs)
      below_threshold = dist >= -exclude_lower & dist < 0,
      # Above threshold region (where hole appears)
      above_threshold = dist >= 0 & dist <= exclude_upper
    )

  # Fit polynomial counterfactual EXCLUDING bunching region
  fit_data <- bin_counts %>% filter(!in_bunching_region)

  if (nrow(fit_data) < poly_order + 1) {
    warning("Not enough bins for polynomial fit at threshold ", threshold)
    return(NULL)
  }

  poly_fit <- lm(n ~ poly(dist, poly_order, raw = TRUE), data = fit_data)

  # Predict counterfactual in bunching region
  bin_counts <- bin_counts %>%
    mutate(counterfactual = predict(poly_fit, newdata = .))

  # Excess mass
  bunching_region <- bin_counts %>% filter(in_bunching_region)
  B_observed <- sum(bunching_region$n)
  B_counterfactual <- sum(bunching_region$counterfactual)

  # Normalized excess mass
  b <- (B_observed - B_counterfactual) / B_counterfactual

  # Below-threshold excess specifically
  below_region <- bin_counts %>% filter(below_threshold)
  B_below_obs <- sum(below_region$n)
  B_below_cf <- sum(below_region$counterfactual)
  b_below <- (B_below_obs - B_below_cf) / B_below_cf

  # Above-threshold missing mass
  above_region <- bin_counts %>% filter(above_threshold)
  B_above_obs <- sum(above_region$n)
  B_above_cf <- sum(above_region$counterfactual)
  b_above <- (B_above_obs - B_above_cf) / B_above_cf

  list(
    threshold = threshold,
    b = b,
    b_below = b_below,
    b_above = b_above,
    B_observed = B_observed,
    B_counterfactual = B_counterfactual,
    n_total = nrow(data),
    bin_counts = bin_counts
  )
}

# Bootstrap standard errors for bunching estimate
bootstrap_bunching <- function(data, threshold, n_boot = 200, ...) {
  b_vec <- numeric(n_boot)
  b_below_vec <- numeric(n_boot)

  for (i in seq_len(n_boot)) {
    boot_data <- data[sample(nrow(data), replace = TRUE), ]
    result <- estimate_bunching(boot_data, threshold, ...)
    if (!is.null(result)) {
      b_vec[i] <- result$b
      b_below_vec[i] <- result$b_below
    }
  }

  list(
    se_b = sd(b_vec, na.rm = TRUE),
    se_b_below = sd(b_below_vec, na.rm = TRUE)
  )
}

# ==================================================================
# 2. MAIN RESULTS: Bunching at 10% threshold
# ==================================================================
cat("\n--- Bunching at 10% threshold ---\n")

# Pre-transparency (2014-2016) vs Post-transparency (2018+)
# Using semi-annual data
pre_data  <- analysis %>% filter(year <= 2016)
post_data <- analysis %>% filter(year >= 2018)

# Estimate bunching
bunch_pre_10  <- estimate_bunching(pre_data,  threshold = 10)
bunch_post_10 <- estimate_bunching(post_data, threshold = 10)

cat(sprintf("Pre-transparency at 10%%:  b = %.3f (excess below = %.3f)\n",
            bunch_pre_10$b, bunch_pre_10$b_below))
cat(sprintf("Post-transparency at 10%%: b = %.3f (excess below = %.3f)\n",
            bunch_post_10$b, bunch_post_10$b_below))

# Bootstrap SEs
cat("Computing bootstrap SEs (200 replications)...\n")
set.seed(42)
boot_pre_10  <- bootstrap_bunching(pre_data,  threshold = 10, n_boot = 200)
boot_post_10 <- bootstrap_bunching(post_data, threshold = 10, n_boot = 200)

cat(sprintf("Pre SE(b): %.3f, Post SE(b): %.3f\n",
            boot_pre_10$se_b, boot_post_10$se_b))

# ==================================================================
# 3. Bunching at 16% threshold (California)
# ==================================================================
cat("\n--- Bunching at 16% threshold ---\n")

data_2017 <- analysis %>% filter(year == 2017)

bunch_pre_16  <- estimate_bunching(pre_data,  threshold = 16)
bunch_2017_16 <- estimate_bunching(data_2017, threshold = 16)
bunch_post_16 <- estimate_bunching(post_data, threshold = 16)

cat(sprintf("Pre-transparency at 16%%:  b = %.3f\n", bunch_pre_16$b))
cat(sprintf("2017 (CA active) at 16%%:  b = %.3f\n", bunch_2017_16$b))
cat(sprintf("Post-Oregon at 16%%:      b = %.3f\n", bunch_post_16$b))

boot_2017_16 <- bootstrap_bunching(data_2017, threshold = 16, n_boot = 200)
boot_post_16 <- bootstrap_bunching(post_data, threshold = 16, n_boot = 200)

# ==================================================================
# 4. DiD: Share of increases above threshold, pre vs post
# ==================================================================
cat("\n--- Share above threshold DiD ---\n")

# Period-level panel of the share of price increases above each threshold
period_shares <- analysis %>%
  group_by(period) %>%
  summarise(
    n = n(),
    n_ndcs = n_distinct(ndc),
    year = first(year),
    half = first(half),
    mean_pct = mean(pct_change),
    sd_pct = sd(pct_change),
    share_above_5  = mean(pct_change > 5),
    share_above_10 = mean(pct_change > 10),
    share_above_16 = mean(pct_change > 16),
    share_above_20 = mean(pct_change > 20),
    share_8_to_10  = mean(pct_change > 8 & pct_change <= 10),
    share_10_to_12 = mean(pct_change > 10 & pct_change <= 12),
    .groups = "drop"
  ) %>%
  mutate(
    post_10 = year >= 2018,
    post_16 = year >= 2017
  )

cat("Period shares:\n")
print(period_shares %>% select(period, n, share_above_10, share_8_to_10), n = 30)

# ==================================================================
# 5. NDC-level regression
# ==================================================================
cat("\n--- NDC-level regressions ---\n")

# Main outcome: whether price increase is above 10%
# Treatment: post-2018 (when 10% threshold becomes binding)
analysis_reg <- analysis %>%
  filter(year >= 2014) %>%
  mutate(
    post = as.integer(year >= 2018),
    above_10 = as.integer(pct_change > 10),
    in_8_10 = as.integer(pct_change > 8 & pct_change <= 10),
    above_16 = as.integer(pct_change > 16)
  )

# Count number of active transparency law states per year
n_law_states <- c(
  "2013" = 0, "2014" = 0, "2015" = 0, "2016" = 1, "2017" = 3,
  "2018" = 4, "2019" = 6, "2020" = 8, "2021" = 12,
  "2022" = 15, "2023" = 18, "2024" = 21, "2025" = 21
)
analysis_reg <- analysis_reg %>%
  mutate(n_laws = n_law_states[as.character(year)])

reg1 <- feols(above_10 ~ post, data = analysis_reg, se = "hetero")
reg2 <- feols(above_10 ~ n_laws, data = analysis_reg, se = "hetero")
reg3 <- feols(in_8_10 ~ post, data = analysis_reg, se = "hetero")
reg4 <- feols(in_8_10 ~ n_laws, data = analysis_reg, se = "hetero")
reg5 <- feols(above_16 ~ post, data = analysis_reg, se = "hetero")

cat("Main regressions:\n")
etable(reg1, reg2, reg3, reg4, reg5,
       headers = c("Above 10%", "Above 10% (n_laws)",
                    "In [8,10%]", "In [8,10%] (n_laws)",
                    "Above 16%"))

# ==================================================================
# 6. Save results
# ==================================================================
results <- list(
  bunch_pre_10 = bunch_pre_10,
  bunch_post_10 = bunch_post_10,
  boot_pre_10 = boot_pre_10,
  boot_post_10 = boot_post_10,
  bunch_pre_16 = bunch_pre_16,
  bunch_2017_16 = bunch_2017_16,
  bunch_post_16 = bunch_post_16,
  boot_2017_16 = boot_2017_16,
  boot_post_16 = boot_post_16,
  period_shares = period_shares,
  reg1 = reg1,
  reg2 = reg2,
  reg3 = reg3,
  reg4 = reg4,
  reg5 = reg5
)

saveRDS(results, "../data/results.rds")
cat("Saved: ../data/results.rds\n")

# Write diagnostics.json for validator
# Semi-annual data: pre-periods are 2014H1..2017H2 = 8 half-years before 2018
diag <- list(
  n_treated = nrow(analysis_reg %>% filter(post == 1)),
  n_pre = length(unique(analysis_reg$period[analysis_reg$post == 0])),
  n_obs = nrow(analysis_reg)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE)
cat("Saved: ../data/diagnostics.json\n")
