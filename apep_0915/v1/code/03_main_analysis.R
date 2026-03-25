## 03_main_analysis.R — Bunching estimation and DiD analysis
## apep_0915: HAP Emission Bunching at CAA Thresholds
##
## Design: Difference-in-bunching around 10-ton single-HAP threshold
## Treatment: OIAI withdrawal (January 25, 2018)
## Pre-period: 2012-2017 | Post-period: 2018-2021

source("00_packages.R")

data_dir <- "../data"

## --- Load analysis panel ---
cat("=== Loading analysis panel ===\n")
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
cat("  Observations:", nrow(panel), "\n")
cat("  Facilities:", uniqueN(panel$facility_id), "\n")

## ================================================================
## PART 1: BUNCHING ESTIMATION (10-ton threshold)
## ================================================================
cat("\n=== PART 1: Bunching at 10-ton threshold ===\n")

# Bunching estimator following Kleven (2016)
# Key idea: compare density just below threshold vs counterfactual
# Use polynomial fit excluding bunching region to construct counterfactual

# Focus on facilities within a reasonable window of the 10-ton threshold
# Window: 0 to 30 tons (asymmetric to capture full distribution shape)
window_lo <- 0.1  # exclude near-zero
window_hi <- 30

bunching_data <- panel[max_single_hap_tons >= window_lo & max_single_hap_tons <= window_hi]
cat("  Facilities in 0.1-30 ton window:", nrow(bunching_data), "\n")

# Create 0.5-ton bins for the bunching analysis
bunching_data[, ton_bin := floor(max_single_hap_tons * 2) / 2]  # 0.5-ton bins

# Bunching region: define excluded window around threshold
# The threshold is 10 tons; facilities have incentive to be just below
# Excluded window: 8 to 12 tons (captures bunching zone)
bunching_lo <- 8
bunching_hi <- 12

# Construct bin-level counts by period
bin_counts <- bunching_data[, .(
  count = .N,
  n_facilities = uniqueN(facility_id)
), by = .(ton_bin, post_oiai)]

# Separate pre and post
bins_pre <- bin_counts[post_oiai == 0][order(ton_bin)]
bins_post <- bin_counts[post_oiai == 1][order(ton_bin)]

## --- Fit counterfactual polynomial (excluding bunching region) ---
fit_counterfactual <- function(bins, excl_lo, excl_hi, poly_order = 5) {
  # Exclude bunching region for fitting
  fit_data <- bins[ton_bin < excl_lo | ton_bin > excl_hi]

  # Fit polynomial to log counts
  fit_data[, log_count := log(count + 1)]

  model <- lm(log_count ~ poly(ton_bin, poly_order, raw = TRUE), data = fit_data)

  # Predict counterfactual for all bins (including excluded region)
  all_bins <- bins[, .(ton_bin)]
  all_bins[, cf_log := predict(model, newdata = all_bins)]
  all_bins[, cf_count := exp(cf_log)]

  # Merge back
  result <- merge(bins, all_bins, by = "ton_bin")

  # Excess mass = actual - counterfactual in bunching region
  bunching_region <- result[ton_bin >= excl_lo & ton_bin <= excl_hi]
  excess <- sum(bunching_region$count) - sum(bunching_region$cf_count)
  norm_excess <- excess / sum(bunching_region$cf_count)

  list(
    data = result,
    excess_mass = excess,
    normalized_excess = norm_excess,
    model = model,
    bunching_region_obs = sum(bunching_region$count),
    counterfactual_obs = sum(bunching_region$cf_count)
  )
}

# Estimate for pre and post periods
cat("\n--- Pre-OIAI bunching (2012-2017) ---\n")
pre_bunch <- fit_counterfactual(bins_pre, bunching_lo, bunching_hi)
cat("  Excess mass:", round(pre_bunch$excess_mass, 1), "\n")
cat("  Normalized excess:", round(pre_bunch$normalized_excess, 3), "\n")

cat("\n--- Post-OIAI bunching (2018-2021) ---\n")
post_bunch <- fit_counterfactual(bins_post, bunching_lo, bunching_hi)
cat("  Excess mass:", round(post_bunch$excess_mass, 1), "\n")
cat("  Normalized excess:", round(post_bunch$normalized_excess, 3), "\n")

# Difference-in-bunching
dib <- post_bunch$normalized_excess - pre_bunch$normalized_excess
cat("\n--- Difference-in-Bunching ---\n")
cat("  Change in normalized excess mass:", round(dib, 4), "\n")

## --- Bootstrap inference ---
cat("\n=== Bootstrap inference (500 replications) ===\n")

bootstrap_dib <- function(data, excl_lo, excl_hi, n_boot = 500) {
  facility_ids <- unique(data$facility_id)

  boot_results <- numeric(n_boot)

  for (b in seq_len(n_boot)) {
    # Resample facilities (with replacement)
    boot_facs <- sample(facility_ids, length(facility_ids), replace = TRUE)
    boot_data <- data[facility_id %in% boot_facs]

    # Recompute bin counts
    boot_bins <- boot_data[, .(count = .N), by = .(ton_bin, post_oiai)]

    boot_pre <- boot_bins[post_oiai == 0][order(ton_bin)]
    boot_post <- boot_bins[post_oiai == 1][order(ton_bin)]

    # Ensure all bins exist
    if (nrow(boot_pre) < 5 || nrow(boot_post) < 5) {
      boot_results[b] <- NA
      next
    }

    pre_est <- tryCatch(
      fit_counterfactual(boot_pre, excl_lo, excl_hi)$normalized_excess,
      error = function(e) NA
    )
    post_est <- tryCatch(
      fit_counterfactual(boot_post, excl_lo, excl_hi)$normalized_excess,
      error = function(e) NA
    )

    boot_results[b] <- post_est - pre_est
  }

  boot_results <- boot_results[!is.na(boot_results)]

  list(
    mean = mean(boot_results),
    se = sd(boot_results),
    ci_lo = quantile(boot_results, 0.025),
    ci_hi = quantile(boot_results, 0.975),
    n_valid = length(boot_results)
  )
}

boot_10ton <- bootstrap_dib(bunching_data, bunching_lo, bunching_hi, n_boot = 500)
cat("  DiB estimate:", round(dib, 4), "\n")
cat("  Bootstrap SE:", round(boot_10ton$se, 4), "\n")
cat("  95% CI: [", round(boot_10ton$ci_lo, 4), ",", round(boot_10ton$ci_hi, 4), "]\n")

## ================================================================
## PART 2: BUNCHING ESTIMATION (25-ton combined threshold)
## ================================================================
cat("\n=== PART 2: Bunching at 25-ton combined threshold ===\n")

# Use total HAP emissions for the 25-ton threshold
bunching_data_25 <- panel[total_hap_tons >= 1 & total_hap_tons <= 60]
bunching_data_25[, ton_bin := floor(total_hap_tons * 2) / 2]

bin_counts_25 <- bunching_data_25[, .(count = .N), by = .(ton_bin, post_oiai)]
bins_pre_25 <- bin_counts_25[post_oiai == 0][order(ton_bin)]
bins_post_25 <- bin_counts_25[post_oiai == 1][order(ton_bin)]

# Bunching region for 25-ton threshold: 20 to 30 tons
pre_bunch_25 <- fit_counterfactual(bins_pre_25, 20, 30)
post_bunch_25 <- fit_counterfactual(bins_post_25, 20, 30)

dib_25 <- post_bunch_25$normalized_excess - pre_bunch_25$normalized_excess
cat("  Pre-OIAI normalized excess:", round(pre_bunch_25$normalized_excess, 3), "\n")
cat("  Post-OIAI normalized excess:", round(post_bunch_25$normalized_excess, 3), "\n")
cat("  DiB:", round(dib_25, 4), "\n")

boot_25ton <- bootstrap_dib(bunching_data_25, 20, 30, n_boot = 500)
cat("  Bootstrap SE:", round(boot_25ton$se, 4), "\n")

## ================================================================
## PART 3: DiD REGRESSION APPROACH (complementary)
## ================================================================
cat("\n=== PART 3: DiD Regression ===\n")

# Focus on facilities near the 10-ton threshold
did_data <- panel[max_single_hap_tons >= 3 & max_single_hap_tons <= 25]

# Outcome: indicator for being below 10-ton threshold
did_data[, below_10 := as.integer(max_single_hap_tons < 10)]

# Define "near threshold" based on PRE-PERIOD average emissions
# Near = average pre-2018 emission was 7-13 tons (the "treatment" group)
# These are facilities with strongest incentive to respond to OIAI withdrawal
pre_avg <- did_data[nei_year < 2018, .(
  pre_avg_hap = mean(max_single_hap_tons, na.rm = TRUE)
), by = facility_id]

did_data <- merge(did_data, pre_avg, by = "facility_id", all.x = TRUE)
did_data[is.na(pre_avg_hap), pre_avg_hap := max_single_hap_tons]  # fallback for post-only

did_data[, near_threshold := as.integer(pre_avg_hap >= 7 & pre_avg_hap <= 13)]

# Main DiD: near_threshold × post_oiai with facility + year FE
# (main effects absorbed by FEs)
cat("\n--- Specification 1: Below-threshold indicator ---\n")
did1 <- feols(below_10 ~ near_threshold:post_oiai | facility_id + nei_year,
              data = did_data,
              cluster = ~state)
cat("  Near × Post effect on P(below 10 tons):\n")
print(summary(did1))

# Specification 2: Distance to threshold
cat("\n--- Specification 2: Distance to threshold ---\n")
did2 <- feols(dist_10ton ~ near_threshold:post_oiai | facility_id + nei_year,
              data = did_data,
              cluster = ~state)
cat("  Near × Post effect on distance to 10-ton threshold:\n")
print(summary(did2))

# Event study specification
cat("\n--- Specification 3: Event study ---\n")
# Use 2016 as reference year (last full pre-treatment year before 2018; 2017 missing)
did_data[, year_rel := nei_year - 2018]

did3 <- feols(below_10 ~ i(year_rel, near_threshold, ref = -2) | facility_id + nei_year,
              data = did_data,
              cluster = ~state)
cat("  Event study coefficients:\n")
print(summary(did3))

## ================================================================
## PART 4: HETEROGENEITY
## ================================================================
cat("\n=== PART 4: Heterogeneity ===\n")

# By NAICS sector (2-digit)
did_data[, naics_2digit := substr(as.character(naics), 1, 2)]

# Manufacturing (31-33) vs non-manufacturing
did_data[, manufacturing := as.integer(naics_2digit %in% c("31", "32", "33"))]

cat("\n--- Manufacturing vs Non-Manufacturing ---\n")
did_mfg <- feols(below_10 ~ near_threshold:post_oiai | facility_id + nei_year,
                 data = did_data[manufacturing == 1],
                 cluster = ~state)
did_nonmfg <- feols(below_10 ~ near_threshold:post_oiai | facility_id + nei_year,
                    data = did_data[manufacturing == 0],
                    cluster = ~state)

cat("  Manufacturing:", round(coef(did_mfg), 4), "(SE:",
    round(se(did_mfg), 4), ")\n")
cat("  Non-manufacturing:", round(coef(did_nonmfg), 4), "(SE:",
    round(se(did_nonmfg), 4), ")\n")

# By state regulatory stringency
strict_states <- c("CA", "NJ", "MA", "NY", "CT", "ME", "OR", "WA")
did_data[, strict_state := as.integer(state %in% strict_states)]

cat("\n--- Strict vs Non-strict state regulation ---\n")
did_strict <- feols(below_10 ~ near_threshold:post_oiai | facility_id + nei_year,
                    data = did_data[strict_state == 1],
                    cluster = ~state)
did_nonstrict <- feols(below_10 ~ near_threshold:post_oiai | facility_id + nei_year,
                       data = did_data[strict_state == 0],
                       cluster = ~state)

cat("  Strict states:", round(coef(did_strict), 4), "(SE:",
    round(se(did_strict), 4), ")\n")
cat("  Non-strict states:", round(coef(did_nonstrict), 4), "(SE:",
    round(se(did_nonstrict), 4), ")\n")

## ================================================================
## DIAGNOSTICS
## ================================================================
cat("\n=== Writing diagnostics ===\n")

diagnostics <- list(
  n_treated = sum(did_data$near_threshold == 1, na.rm = TRUE),
  n_pre = length(unique(did_data$nei_year[did_data$nei_year < 2018])),
  n_obs = nrow(did_data),
  n_facilities_total = uniqueN(panel$facility_id),
  n_facility_years_total = nrow(panel)
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)
cat("  diagnostics.json written\n")
cat("  n_treated:", diagnostics$n_treated, "\n")
cat("  n_pre:", diagnostics$n_pre, "\n")
cat("  n_obs:", diagnostics$n_obs, "\n")

## --- Save results for tables ---
results <- list(
  # Bunching results
  pre_bunch_10 = list(
    excess = pre_bunch$excess_mass,
    normalized = pre_bunch$normalized_excess,
    actual = pre_bunch$bunching_region_obs,
    cf = pre_bunch$counterfactual_obs
  ),
  post_bunch_10 = list(
    excess = post_bunch$excess_mass,
    normalized = post_bunch$normalized_excess,
    actual = post_bunch$bunching_region_obs,
    cf = post_bunch$counterfactual_obs
  ),
  dib_10 = dib,
  boot_10 = boot_10ton,
  pre_bunch_25 = list(
    excess = pre_bunch_25$excess_mass,
    normalized = pre_bunch_25$normalized_excess
  ),
  post_bunch_25 = list(
    excess = post_bunch_25$excess_mass,
    normalized = post_bunch_25$normalized_excess
  ),
  dib_25 = dib_25,
  boot_25 = boot_25ton,
  # DiD results
  did_main = did1,
  did_dist = did2,
  did_event = did3,
  did_mfg = did_mfg,
  did_nonmfg = did_nonmfg,
  did_strict = did_strict,
  did_nonstrict = did_nonstrict,
  # Sample info
  n_facilities_total = uniqueN(panel$facility_id),
  n_facility_years = nrow(panel),
  n_near_10 = nrow(did_data),
  sd_below10 = sd(did_data$below_10),
  sd_dist10 = sd(did_data$dist_10ton),
  mean_below10_pre = mean(did_data[post_oiai == 0]$below_10)
)

saveRDS(results, file.path(data_dir, "analysis_results.rds"))
cat("\nAll results saved to data/analysis_results.rds\n")
