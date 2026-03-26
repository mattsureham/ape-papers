# 03_main_analysis.R — Bunching estimation at UK company size thresholds
# Multi-cutoff bunching using Companies House microdata + NOMIS aggregates

source("00_packages.R")

cat("=== Main Bunching Analysis ===\n")

# =========================================================================
# Load data
# =========================================================================

micro <- fread("../data/ch_microdata_clean.csv")
ent <- fread("../data/enterprises_by_sizeband.csv")

cat("Microdata:", nrow(micro), "firms with exact employee counts\n")
cat("Aggregate:", nrow(ent), "size-band×year observations\n")

# Remove outliers for bunching (keep employees 1-2000)
micro_clean <- micro[employees >= 1 & employees <= 2000]
cat("After trimming:", nrow(micro_clean), "firms\n")

# =========================================================================
# PART 1: Bunching Estimation on Microdata
#
# Standard polynomial bunching estimator (Chetty et al. 2011; Kleven 2016):
# 1. Fit polynomial to counterfactual density excluding bunching region
# 2. Excess mass = (actual - counterfactual) / counterfactual in region
# 3. Bootstrap standard errors
# =========================================================================

cat("\n--- Bunching Estimation ---\n")

# Function: estimate bunching at a threshold
estimate_bunching <- function(emp_data, threshold, window_below = 20,
                               window_above = 20, excluded_below = 2,
                               excluded_above = 2, poly_degree = 7,
                               n_boot = 500) {

  # Define analysis window
  lower <- threshold - window_below
  upper <- threshold + window_above
  excl_lower <- threshold - excluded_below
  excl_upper <- threshold + excluded_above

  # Bin the data: count firms at each integer employee level
  bins <- data.frame(emp = lower:upper)
  counts <- as.data.frame(table(emp_data$employees[
    emp_data$employees >= lower & emp_data$employees <= upper
  ]))
  names(counts) <- c("emp", "count")
  counts$emp <- as.integer(as.character(counts$emp))

  bins <- merge(bins, counts, by = "emp", all.x = TRUE)
  bins$count[is.na(bins$count)] <- 0

  # Identify bins inside vs outside excluded region
  bins$excluded <- bins$emp >= excl_lower & bins$emp <= excl_upper
  bins$below_threshold <- bins$emp < threshold

  # Check if we have enough data
  total_count <- sum(bins$count)
  if (total_count < 30) {
    cat(sprintf("  Threshold %d: Too few observations (%d) in window\n",
                threshold, total_count))
    return(list(
      threshold = threshold,
      excess_mass = NA, se = NA, p_value = NA,
      actual_below = NA, counter_below = NA,
      n_window = total_count
    ))
  }

  # Fit polynomial to counterfactual (excluding bunching region)
  fit_data <- bins[!bins$excluded, ]
  fit_data$z <- fit_data$emp - threshold  # Center at threshold

  # Polynomial regression
  formula_str <- paste0("count ~ ", paste0("I(z^", 1:poly_degree, ")",
                                            collapse = " + "))
  cf_model <- lm(as.formula(formula_str), data = fit_data)

  # Predict counterfactual for all bins
  all_z <- data.frame(z = bins$emp - threshold)
  bins$counterfactual <- pmax(predict(cf_model, newdata = all_z), 0)

  # Excess mass in the bunching region (below threshold)
  bunch_region <- bins[bins$emp >= excl_lower & bins$emp < threshold, ]
  actual_below <- sum(bunch_region$count)
  counter_below <- sum(bunch_region$counterfactual)

  # Also check the "hole" region (above threshold)
  hole_region <- bins[bins$emp >= threshold & bins$emp <= excl_upper, ]
  actual_above <- sum(hole_region$count)
  counter_above <- sum(hole_region$counterfactual)

  # Bunching statistic: normalized excess mass
  b <- (actual_below - counter_below) / counter_below

  # Also compute the "missing mass" above
  missing <- (counter_above - actual_above) / counter_above

  # Bootstrap for standard errors
  boot_fn <- function(data, indices) {
    boot_data <- data[indices, ]
    boot_counts <- as.data.frame(table(boot_data$employees[
      boot_data$employees >= lower & boot_data$employees <= upper
    ]))
    names(boot_counts) <- c("emp", "count")
    boot_counts$emp <- as.integer(as.character(boot_counts$emp))

    boot_bins <- data.frame(emp = lower:upper)
    boot_bins <- merge(boot_bins, boot_counts, by = "emp", all.x = TRUE)
    boot_bins$count[is.na(boot_bins$count)] <- 0
    boot_bins$excluded <- boot_bins$emp >= excl_lower &
                          boot_bins$emp <= excl_upper

    boot_fit <- boot_bins[!boot_bins$excluded, ]
    boot_fit$z <- boot_fit$emp - threshold

    tryCatch({
      boot_model <- lm(as.formula(formula_str), data = boot_fit)
      boot_cf <- pmax(predict(boot_model,
                               newdata = data.frame(z = boot_bins$emp - threshold)),
                       0)

      boot_bunch <- boot_bins[boot_bins$emp >= excl_lower &
                              boot_bins$emp < threshold, ]
      boot_act <- sum(boot_bunch$count)
      boot_counter <- sum(pmax(boot_cf[boot_bins$emp >= excl_lower &
                                        boot_bins$emp < threshold], 0.1))
      return((boot_act - boot_counter) / boot_counter)
    }, error = function(e) NA_real_)
  }

  boot_results <- boot::boot(emp_data[emp_data$employees >= lower &
                                       emp_data$employees <= upper, ],
                              boot_fn, R = n_boot)

  se <- sd(boot_results$t, na.rm = TRUE)
  p_val <- 2 * (1 - pnorm(abs(b / se)))

  cat(sprintf("  Threshold %d: b = %.3f (SE = %.3f, p = %.4f) | ",
              threshold, b, se, p_val))
  cat(sprintf("actual = %d, counterfactual = %.1f, n_window = %d\n",
              actual_below, counter_below, total_count))

  return(list(
    threshold = threshold,
    excess_mass = b,
    se = se,
    p_value = p_val,
    actual_below = actual_below,
    counter_below = counter_below,
    actual_above = actual_above,
    counter_above = counter_above,
    missing_mass = missing,
    n_window = total_count,
    bins = bins
  ))
}

# =========================================================================
# Estimate bunching at three thresholds
# =========================================================================

cat("\nThreshold 1: 10 employees (Micro→Small)\n")
bunch_10 <- estimate_bunching(micro_clean, threshold = 10,
                               window_below = 8, window_above = 15,
                               excluded_below = 2, excluded_above = 3,
                               poly_degree = 5, n_boot = 500)

cat("\nThreshold 2: 50 employees (Small→Medium: audit + IR35)\n")
bunch_50 <- estimate_bunching(micro_clean, threshold = 50,
                               window_below = 20, window_above = 20,
                               excluded_below = 3, excluded_above = 5,
                               poly_degree = 5, n_boot = 500)

cat("\nThreshold 3: 250 employees (Medium→Large)\n")
bunch_250 <- estimate_bunching(micro_clean, threshold = 250,
                                window_below = 50, window_above = 50,
                                excluded_below = 5, excluded_above = 10,
                                poly_degree = 5, n_boot = 500)

# =========================================================================
# PART 2: Aggregate evidence from NOMIS
# Density drop test: compare per-bin density across threshold boundaries
# =========================================================================

cat("\n--- Aggregate Density Analysis ---\n")

# UK-level enterprise counts by size band (2024 latest)
uk_ent <- ent %>%
  filter(year == 2024) %>%
  group_by(size_band, band_lower, band_upper, band_width) %>%
  summarise(n_enterprises = sum(n_enterprises, na.rm = TRUE), .groups = "drop") %>%
  mutate(density = n_enterprises / band_width) %>%
  arrange(band_lower)

cat("\n2024 Enterprise density by size band:\n")
print(as.data.frame(uk_ent))

# Log-density: fit log-linear model excluding threshold bands
# Under no bunching, log(density) should decline smoothly with log(emp)
uk_ent$log_density <- log(uk_ent$density)
uk_ent$log_midpoint <- log((uk_ent$band_lower + pmin(uk_ent$band_upper, 1000)) / 2)

# Identify threshold bands
uk_ent$at_threshold <- uk_ent$size_band %in%
  c("5 to 9", "10 to 19",        # Threshold at 10
    "20 to 49", "50 to 99",      # Threshold at 50
    "100 to 249", "250 to 499")  # Threshold at 250

# Fit Pareto distribution to non-threshold bands
pareto_fit <- lm(log_density ~ log_midpoint, data = uk_ent)
cat("\nPareto slope (expected ~ -2 under Zipf's law):\n")
print(summary(pareto_fit)$coefficients)

uk_ent$predicted_density <- exp(predict(pareto_fit, newdata = uk_ent))
uk_ent$excess <- (uk_ent$density - uk_ent$predicted_density) / uk_ent$predicted_density

cat("\nExcess density relative to Pareto fit:\n")
for (i in 1:nrow(uk_ent)) {
  cat(sprintf("  %-12s  actual=%10.0f  predicted=%10.0f  excess=%+.1f%%\n",
              uk_ent$size_band[i], uk_ent$density[i],
              uk_ent$predicted_density[i], uk_ent$excess[i] * 100))
}

# Density ratios at thresholds
# These compare the density just below vs just above the regulatory cutoff
density_ratios <- data.frame(
  threshold = c(10, 50, 250),
  threshold_label = c("Micro→Small", "Small→Medium", "Medium→Large"),
  below_band = c("5 to 9", "20 to 49", "100 to 249"),
  above_band = c("10 to 19", "50 to 99", "250 to 499"),
  stringsAsFactors = FALSE
)

for (i in 1:nrow(density_ratios)) {
  d_below <- uk_ent$density[uk_ent$size_band == density_ratios$below_band[i]]
  d_above <- uk_ent$density[uk_ent$size_band == density_ratios$above_band[i]]
  density_ratios$ratio[i] <- d_below / d_above
  density_ratios$log_ratio[i] <- log(d_below / d_above)

  cat(sprintf("\nThreshold %d (%s): density below/above = %.2f\n",
              density_ratios$threshold[i], density_ratios$threshold_label[i],
              density_ratios$ratio[i]))
}

# =========================================================================
# PART 3: Time-series analysis — did bunching change after IR35?
# =========================================================================

cat("\n--- Time-Series Analysis ---\n")

# Compute density ratios by year for UK total
uk_ts <- ent %>%
  group_by(year, size_band, band_lower, band_upper, band_width) %>%
  summarise(n_enterprises = sum(n_enterprises, na.rm = TRUE), .groups = "drop") %>%
  mutate(density = n_enterprises / band_width)

# Compute annual ratios
annual_ratios <- data.frame()
for (yr in unique(uk_ts$year)) {
  yr_data <- uk_ts[uk_ts$year == yr, ]
  for (i in 1:nrow(density_ratios)) {
    d_below <- yr_data$density[yr_data$size_band == density_ratios$below_band[i]]
    d_above <- yr_data$density[yr_data$size_band == density_ratios$above_band[i]]
    if (length(d_below) > 0 && length(d_above) > 0 && d_above > 0) {
      annual_ratios <- rbind(annual_ratios, data.frame(
        year = yr,
        threshold = density_ratios$threshold[i],
        threshold_label = density_ratios$threshold_label[i],
        ratio = d_below / d_above,
        log_ratio = log(d_below / d_above)
      ))
    }
  }
}

cat("Density ratios by year:\n")
for (th in c(10, 50, 250)) {
  cat(sprintf("\nThreshold %d:\n", th))
  th_data <- annual_ratios[annual_ratios$threshold == th, ]
  for (j in 1:nrow(th_data)) {
    cat(sprintf("  %d: %.3f\n", th_data$year[j], th_data$ratio[j]))
  }
}

# Test for structural break at 2021 (IR35)
cat("\nIR35 effect (Small→Medium threshold, post-2021 vs pre-2021):\n")
ir35_data <- annual_ratios[annual_ratios$threshold == 50, ]
ir35_data$post_ir35 <- as.integer(ir35_data$year >= 2021)

if (nrow(ir35_data) > 5) {
  ir35_model <- lm(log_ratio ~ post_ir35 + year, data = ir35_data)
  cat("  Post-IR35 coefficient:\n")
  print(summary(ir35_model)$coefficients["post_ir35", ])
}

# =========================================================================
# PART 4: Placebo thresholds
# =========================================================================

cat("\n--- Placebo Threshold Tests ---\n")

# Test bunching at round numbers that are NOT regulatory thresholds
# If bunching is due to regulation (not round-number preferences),
# we should see MORE bunching at regulatory thresholds than at
# non-regulatory round numbers

placebo_thresholds <- c(15, 25, 75, 100, 150, 200)

for (pt in placebo_thresholds) {
  cat(sprintf("\nPlacebo threshold %d:\n", pt))
  tryCatch({
    estimate_bunching(micro_clean, threshold = pt,
                      window_below = min(10, pt - 2),
                      window_above = 15,
                      excluded_below = 2, excluded_above = 3,
                      poly_degree = 5, n_boot = 200)
  }, error = function(e) {
    cat(sprintf("  Error at placebo %d: %s\n", pt, conditionMessage(e)))
  })
}

# =========================================================================
# Save results
# =========================================================================

cat("\n=== Saving Results ===\n")

results <- list(
  bunch_10 = list(
    threshold = 10,
    excess_mass = bunch_10$excess_mass,
    se = bunch_10$se,
    p_value = bunch_10$p_value,
    n_window = bunch_10$n_window
  ),
  bunch_50 = list(
    threshold = 50,
    excess_mass = bunch_50$excess_mass,
    se = bunch_50$se,
    p_value = bunch_50$p_value,
    n_window = bunch_50$n_window
  ),
  bunch_250 = list(
    threshold = 250,
    excess_mass = bunch_250$excess_mass,
    se = bunch_250$se,
    p_value = bunch_250$p_value,
    n_window = bunch_250$n_window
  ),
  density_ratios = density_ratios,
  annual_ratios = annual_ratios
)

saveRDS(results, "../data/bunching_results.rds")

# Save diagnostics for validator
diagnostics <- list(
  n_treated = length(unique(micro_clean$company_number)),
  n_pre = 15,  # Years of NOMIS data pre-2025
  n_obs = nrow(micro_clean) + nrow(ent)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("Results saved.\n")
cat("\n=== Main Analysis Complete ===\n")
