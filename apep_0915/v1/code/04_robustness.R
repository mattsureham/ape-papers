## 04_robustness.R — Robustness checks and placebo tests
## apep_0915: HAP Emission Bunching at CAA Thresholds

source("00_packages.R")

data_dir <- "../data"

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "analysis_results.rds"))

## ================================================================
## ROBUSTNESS 1: Alternative bunching windows
## ================================================================
cat("=== Robustness 1: Alternative bunching windows ===\n")

# Source the bunching estimator from main analysis
fit_counterfactual <- function(bins, excl_lo, excl_hi, poly_order = 5) {
  fit_data <- bins[ton_bin < excl_lo | ton_bin > excl_hi]
  fit_data[, log_count := log(count + 1)]
  model <- lm(log_count ~ poly(ton_bin, poly_order, raw = TRUE), data = fit_data)
  all_bins <- bins[, .(ton_bin)]
  all_bins[, cf_log := predict(model, newdata = all_bins)]
  all_bins[, cf_count := exp(cf_log)]
  result <- merge(bins, all_bins, by = "ton_bin")
  bunching_region <- result[ton_bin >= excl_lo & ton_bin <= excl_hi]
  excess <- sum(bunching_region$count) - sum(bunching_region$cf_count)
  norm_excess <- excess / sum(bunching_region$cf_count)
  list(normalized_excess = norm_excess, excess_mass = excess)
}

# Test multiple excluded windows around 10-ton threshold
windows <- list(
  c(7, 11),   # narrow
  c(8, 12),   # baseline
  c(9, 13),   # shifted right
  c(7, 13),   # wide
  c(8, 14)    # very wide
)

bunching_data <- panel[max_single_hap_tons >= 0.1 & max_single_hap_tons <= 30]
bunching_data[, ton_bin := floor(max_single_hap_tons * 2) / 2]
bin_counts <- bunching_data[, .(count = .N), by = .(ton_bin, post_oiai)]
bins_pre <- bin_counts[post_oiai == 0][order(ton_bin)]
bins_post <- bin_counts[post_oiai == 1][order(ton_bin)]

robust_windows <- data.table(
  window = character(),
  pre_excess = numeric(),
  post_excess = numeric(),
  dib = numeric()
)

for (w in windows) {
  pre_est <- fit_counterfactual(bins_pre, w[1], w[2])
  post_est <- fit_counterfactual(bins_post, w[1], w[2])
  robust_windows <- rbind(robust_windows, data.table(
    window = paste0("[", w[1], ", ", w[2], "]"),
    pre_excess = pre_est$normalized_excess,
    post_excess = post_est$normalized_excess,
    dib = post_est$normalized_excess - pre_est$normalized_excess
  ))
}

cat("  Window sensitivity:\n")
print(robust_windows)

## ================================================================
## ROBUSTNESS 2: Alternative polynomial orders
## ================================================================
cat("\n=== Robustness 2: Polynomial order sensitivity ===\n")

robust_poly <- data.table(
  poly_order = integer(),
  pre_excess = numeric(),
  post_excess = numeric(),
  dib = numeric()
)

for (p in 3:7) {
  pre_est <- fit_counterfactual(bins_pre, 8, 12, poly_order = p)
  post_est <- fit_counterfactual(bins_post, 8, 12, poly_order = p)
  robust_poly <- rbind(robust_poly, data.table(
    poly_order = p,
    pre_excess = pre_est$normalized_excess,
    post_excess = post_est$normalized_excess,
    dib = post_est$normalized_excess - pre_est$normalized_excess
  ))
}

cat("  Polynomial order sensitivity:\n")
print(robust_poly)

## ================================================================
## ROBUSTNESS 3: Placebo cutoffs (5 tons, 15 tons, 20 tons)
## ================================================================
cat("\n=== Robustness 3: Placebo cutoffs ===\n")

placebo_cutoffs <- c(5, 15, 20)
placebo_results <- data.table(
  cutoff = numeric(),
  pre_excess = numeric(),
  post_excess = numeric(),
  dib = numeric()
)

for (cutoff in placebo_cutoffs) {
  # Define window around placebo cutoff
  excl_lo <- cutoff - 2
  excl_hi <- cutoff + 2
  window_data <- panel[max_single_hap_tons >= (cutoff - 10) &
                         max_single_hap_tons <= (cutoff + 10) &
                         max_single_hap_tons > 0.1]
  window_data[, ton_bin := floor(max_single_hap_tons * 2) / 2]

  p_bins <- window_data[, .(count = .N), by = .(ton_bin, post_oiai)]
  p_pre <- p_bins[post_oiai == 0][order(ton_bin)]
  p_post <- p_bins[post_oiai == 1][order(ton_bin)]

  if (nrow(p_pre) < 10 || nrow(p_post) < 10) {
    cat("  Cutoff", cutoff, ": insufficient data\n")
    next
  }

  pre_est <- tryCatch(
    fit_counterfactual(p_pre, excl_lo, excl_hi),
    error = function(e) list(normalized_excess = NA)
  )
  post_est <- tryCatch(
    fit_counterfactual(p_post, excl_lo, excl_hi),
    error = function(e) list(normalized_excess = NA)
  )

  placebo_results <- rbind(placebo_results, data.table(
    cutoff = cutoff,
    pre_excess = pre_est$normalized_excess,
    post_excess = post_est$normalized_excess,
    dib = post_est$normalized_excess - pre_est$normalized_excess
  ))
}

cat("  Placebo cutoff results:\n")
print(placebo_results)

## ================================================================
## ROBUSTNESS 4: Donut approach (exclude observations near threshold)
## ================================================================
cat("\n=== Robustness 4: Donut DiD ===\n")

did_data <- panel[max_single_hap_tons >= 3 & max_single_hap_tons <= 25]
did_data[, below_10 := as.integer(max_single_hap_tons < 10)]

# Construct near_threshold from pre-period avg
pre_avg <- did_data[nei_year < 2018, .(pre_avg_hap = mean(max_single_hap_tons, na.rm = TRUE)), by = facility_id]
did_data <- merge(did_data, pre_avg, by = "facility_id", all.x = TRUE)
did_data[is.na(pre_avg_hap), pre_avg_hap := max_single_hap_tons]
did_data[, near_threshold := as.integer(pre_avg_hap >= 7 & pre_avg_hap <= 13)]

# Donut: exclude 9-11 ton range
donut_data <- did_data[max_single_hap_tons < 9 | max_single_hap_tons > 11]
donut_did <- feols(below_10 ~ near_threshold:post_oiai | facility_id + nei_year,
                   data = donut_data, cluster = ~state)
cat("  Donut DiD estimate:", round(coef(donut_did), 4),
    "(SE:", round(se(donut_did), 4), ")\n")

## ================================================================
## ROBUSTNESS 5: Alternative clustering
## ================================================================
cat("\n=== Robustness 5: Alternative clustering ===\n")

# Baseline: state-clustered
did_state <- feols(below_10 ~ near_threshold:post_oiai | facility_id + nei_year,
                   data = did_data, cluster = ~state)

# Facility-clustered
did_fac <- feols(below_10 ~ near_threshold:post_oiai | facility_id + nei_year,
                 data = did_data, cluster = ~facility_id)

# NAICS-clustered
did_data[, naics_2digit := substr(as.character(naics), 1, 2)]
did_naics <- feols(below_10 ~ near_threshold:post_oiai | facility_id + nei_year,
                   data = did_data, cluster = ~naics_2digit)

cat("  State-clustered SE:", round(se(did_state), 4), "\n")
cat("  Facility-clustered SE:", round(se(did_fac), 4), "\n")
cat("  NAICS-clustered SE:", round(se(did_naics), 4), "\n")

## ================================================================
## ROBUSTNESS 6: Pre-period falsification (fake treatment at 2015)
## ================================================================
cat("\n=== Robustness 6: Placebo treatment timing ===\n")

pre_only <- did_data[nei_year <= 2016]  # only pre-period years
pre_only[, fake_post := as.integer(nei_year >= 2015)]

placebo_time <- feols(below_10 ~ near_threshold:fake_post | facility_id + nei_year,
                      data = pre_only, cluster = ~state)
cat("  Placebo (2015) coefficient:", round(coef(placebo_time), 4),
    "(SE:", round(se(placebo_time), 4), ")\n")

## --- Save robustness results ---
robust_results <- list(
  windows = robust_windows,
  poly_orders = robust_poly,
  placebo_cutoffs = placebo_results,
  donut = donut_did,
  clustering = list(state = did_state, facility = did_fac, naics = did_naics),
  placebo_time = placebo_time
)

saveRDS(robust_results, file.path(data_dir, "robustness_results.rds"))
cat("\nRobustness results saved.\n")
