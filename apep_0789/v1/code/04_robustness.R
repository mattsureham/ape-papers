# 04_robustness.R — Robustness checks and placebo tests
library(data.table)
library(fixest)
library(did)
library(boot)
library(lubridate)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(normalizePath(sub("--file=", "", args[grep("--file=", args)])))
setwd(dirname(script_dir))

panel <- readRDS("data/analysis_panel.rds")
results <- readRDS("data/main_results.rds")

cat("=== ROBUSTNESS CHECKS ===\n\n")

# ─── 1. Wild Cluster Bootstrap ────────────────────────────────────────────
cat("--- 1. Wild Cluster Bootstrap (6-point Webb distribution) ---\n")

# Manual wild cluster bootstrap for TWFE
set.seed(12345)
n_boot <- 9999
region_ids <- unique(panel$region_id)
n_clusters <- length(region_ids)

# Fit restricted and unrestricted models
twfe_full <- feols(price_mean ~ post | region_id + time_int, data = panel)
twfe_null <- feols(price_mean ~ 1 | region_id + time_int, data = panel)
resid_null <- residuals(twfe_null)
beta_hat <- coef(twfe_full)["postTRUE"]

# Webb 6-point distribution weights
webb_weights <- c(-sqrt(3/2), -sqrt(2/2), -sqrt(1/2),
                   sqrt(1/2),  sqrt(2/2),  sqrt(3/2))

boot_betas <- numeric(n_boot)
for (b in seq_len(n_boot)) {
  # Draw cluster-level weights
  w <- sample(webb_weights, n_clusters, replace = TRUE)
  # Map to observations
  panel[, boot_w := w[match(region_id, region_ids)]]
  # Create bootstrapped outcome
  panel[, y_boot := fitted(twfe_null) + resid_null * boot_w]
  # Re-estimate
  boot_fit <- feols(y_boot ~ post | region_id + time_int, data = panel)
  boot_betas[b] <- coef(boot_fit)["postTRUE"]
}

wcb_pval <- mean(abs(boot_betas) >= abs(beta_hat))
cat(sprintf("WCB p-value (two-sided): %.4f\n", wcb_pval))
cat(sprintf("WCB 95%% CI: [%.3f, %.3f]\n",
            quantile(boot_betas, 0.025), quantile(boot_betas, 0.975)))

# ─── 2. Randomization Inference ───────────────────────────────────────────
cat("\n--- 2. Randomization Inference ---\n")
set.seed(54321)

# Permute treatment assignment across regions
n_treated <- 5
n_perm <- 5000  # All C(9,5)=126 permutations + resampling

# Get all possible combinations
all_combos <- combn(region_ids, n_treated, simplify = FALSE)
cat(sprintf("Total exact permutations: %d\n", length(all_combos)))

# Exact RI (all 126 permutations)
ri_betas <- numeric(length(all_combos))
first_restart_dt <- readRDS("data/first_restart.rds")
treated_regions <- panel[treated == TRUE, unique(region_id)]

for (i in seq_along(all_combos)) {
  # Assign fake treatment to permuted regions
  fake_treated <- all_combos[[i]]
  panel[, fake_post := FALSE]

  # For permuted treated regions, assign same timing structure
  # Map real treated region timings to fake regions
  real_timing <- panel[region_id %in% treated_regions,
                       .(treat_month = unique(treat_month)), by = region_id]
  real_timing <- real_timing[order(region_id)]

  for (j in seq_len(n_treated)) {
    real_month <- real_timing$treat_month[j]
    fake_id <- fake_treated[j]
    panel[region_id == fake_id & year_month >= real_month, fake_post := TRUE]
  }

  ri_fit <- feols(price_mean ~ fake_post | region_id + time_int, data = panel)
  ri_betas[i] <- coef(ri_fit)["fake_postTRUE"]
}

ri_pval <- mean(abs(ri_betas) >= abs(beta_hat))
cat(sprintf("Exact RI p-value (two-sided): %.4f\n", ri_pval))
cat(sprintf("RI distribution: mean=%.3f, sd=%.3f\n", mean(ri_betas), sd(ri_betas)))

# ─── 3. Alternative Time Aggregation (Weekly) ────────────────────────────
cat("\n--- 3. Weekly Aggregation ---\n")
jepx_long <- readRDS("data/jepx_long.rds")
regions_info <- readRDS("data/regions.rds")
first_restart <- readRDS("data/first_restart.rds")

jepx_long[, week := floor_date(date, "week")]
weekly <- jepx_long[, .(
  price_mean = mean(price_yen_kwh, na.rm = TRUE)
), by = .(region, week)]

weekly <- merge(weekly, regions_info[, .(region, treated)], by = "region", all.x = TRUE)
weekly <- merge(weekly, first_restart[, .(region, first_restart_date)],
                by = "region", all.x = TRUE)
weekly[, treat_week := floor_date(first_restart_date, "week")]
weekly[, post := week >= treat_week]
weekly[is.na(post), post := FALSE]
weekly[, region_id := as.integer(factor(region))]
weekly[, week_int := as.integer(difftime(week, min(week), units = "weeks"))]
weekly <- weekly[week >= "2012-01-01" & week <= "2025-12-31"]

twfe_weekly <- feols(price_mean ~ post | region_id + week_int,
                     data = weekly, cluster = ~region_id)
cat("TWFE (weekly):\n")
print(summary(twfe_weekly))

# ─── 4. Donut Specification (exclude transition months) ──────────────────
cat("\n--- 4. Donut Specification ---\n")
# Exclude 3 months before and after first restart (ramp-up period)
panel[, months_to_treat := as.numeric(difftime(year_month, treat_month, units = "days")) / 30]
donut <- panel[is.na(months_to_treat) | abs(months_to_treat) > 3]
cat(sprintf("Donut sample: %d obs (dropped %d transition months)\n",
            nrow(donut), nrow(panel) - nrow(donut)))

twfe_donut <- feols(price_mean ~ post | region_id + time_int,
                    data = donut, cluster = ~region_id)
cat("TWFE (donut):\n")
print(summary(twfe_donut))

# ─── 5. Median Prices (robust to outliers) ───────────────────────────────
cat("\n--- 5. Median Price ---\n")
twfe_median <- feols(price_median ~ post | region_id + time_int,
                     data = panel, cluster = ~region_id)
cat("TWFE (median price):\n")
print(summary(twfe_median))

# ─── 6. Price Volatility ─────────────────────────────────────────────────
cat("\n--- 6. Price Volatility (SD) ---\n")
twfe_vol <- feols(price_sd ~ post | region_id + time_int,
                  data = panel, cluster = ~region_id)
cat("TWFE (price volatility):\n")
print(summary(twfe_vol))

# ─── 7. Capacity-weighted treatment ──────────────────────────────────────
cat("\n--- 7. Capacity-Weighted Treatment ---\n")
restart_data <- readRDS("data/restart_timeline.rds")

# Compute cumulative restarted capacity per region per month
panel[, cum_capacity_gw := 0.0]
for (r in unique(restart_data$region)) {
  restarts_r <- restart_data[region == r]
  for (i in seq_len(nrow(restarts_r))) {
    restart_mo <- floor_date(restarts_r$restart_date[i], "month")
    cap_gw <- restarts_r$capacity_mw[i] / 1000
    panel[region == r & year_month >= restart_mo,
          cum_capacity_gw := cum_capacity_gw + cap_gw]
  }
}

twfe_dosage <- feols(price_mean ~ cum_capacity_gw | region_id + time_int,
                     data = panel, cluster = ~region_id)
cat("TWFE (capacity dosage):\n")
print(summary(twfe_dosage))

# ─── Save robustness results ─────────────────────────────────────────────
robust <- list(
  wcb_pval = wcb_pval,
  ri_pval = ri_pval,
  ri_n_perms = length(all_combos),
  weekly_coef = coef(twfe_weekly)["postTRUE"],
  weekly_se = se(twfe_weekly)["postTRUE"],
  donut_coef = coef(twfe_donut)["postTRUE"],
  donut_se = se(twfe_donut)["postTRUE"],
  median_coef = coef(twfe_median)["postTRUE"],
  median_se = se(twfe_median)["postTRUE"],
  vol_coef = coef(twfe_vol)["postTRUE"],
  vol_se = se(twfe_vol)["postTRUE"],
  dosage_coef = coef(twfe_dosage)["cum_capacity_gw"],
  dosage_se = se(twfe_dosage)["cum_capacity_gw"]
)

saveRDS(robust, "data/robustness_results.rds")
saveRDS(panel, "data/analysis_panel.rds")  # Save with cum_capacity_gw

cat("\n=== ROBUSTNESS SUMMARY ===\n")
cat(sprintf("WCB p-value: %.4f\n", robust$wcb_pval))
cat(sprintf("Exact RI p-value: %.4f (from %d permutations)\n", robust$ri_pval, robust$ri_n_perms))
cat(sprintf("Weekly: %.3f (%.3f)\n", robust$weekly_coef, robust$weekly_se))
cat(sprintf("Donut: %.3f (%.3f)\n", robust$donut_coef, robust$donut_se))
cat(sprintf("Median: %.3f (%.3f)\n", robust$median_coef, robust$median_se))
cat(sprintf("Volatility: %.3f (%.3f)\n", robust$vol_coef, robust$vol_se))
cat(sprintf("Dosage (per GW): %.3f (%.3f)\n", robust$dosage_coef, robust$dosage_se))
cat("\nRobustness checks complete.\n")
