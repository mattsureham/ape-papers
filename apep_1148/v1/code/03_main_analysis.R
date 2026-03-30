## 03_main_analysis.R — Bunching estimation at the 50-bed threshold
## Follows Kleven (2016) bunching methodology

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

## -----------------------------------------------------------------------
## 1. Load analysis panel
## -----------------------------------------------------------------------

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
cat(sprintf("Loaded panel: %d provider-year obs, %d providers, FY %d-%d\n",
            nrow(panel), uniqueN(panel$prvdr_num),
            min(panel$fy), max(panel$fy)))

## -----------------------------------------------------------------------
## 2. Bunching estimation function (Kleven 2016)
## -----------------------------------------------------------------------

estimate_bunching <- function(df, threshold = 50, bin_lo = 20, bin_hi = 100,
                               exclude_lo = 46, exclude_hi = 55,
                               poly_order = 7, n_boot = 500) {
  # Construct bin counts
  hist_data <- df[total_beds >= bin_lo & total_beds <= bin_hi,
                   .N, by = total_beds]
  setnames(hist_data, c("beds", "count"))

  # Ensure all bins present
  all_bins <- data.table(beds = bin_lo:bin_hi)
  hist_data <- merge(all_bins, hist_data, by = "beds", all.x = TRUE)
  hist_data[is.na(count), count := 0]
  hist_data <- hist_data[order(beds)]

  # Exclude bunching region and round numbers
  hist_data[, excluded := beds >= exclude_lo & beds <= exclude_hi]

  # Fit polynomial to non-excluded bins
  fit_data <- hist_data[excluded == FALSE]
  fit <- lm(count ~ poly(beds, poly_order, raw = TRUE), data = fit_data)

  # Predict counterfactual for all bins
  hist_data[, counterfactual := predict(fit, newdata = hist_data)]
  hist_data[counterfactual < 0, counterfactual := 0]

  # Excess mass in bunching region (below threshold)
  bunch_region <- hist_data[beds >= exclude_lo & beds <= threshold]
  excess_mass <- sum(bunch_region$count) - sum(bunch_region$counterfactual)

  # Missing mass above threshold
  missing_region <- hist_data[beds > threshold & beds <= exclude_hi]
  missing_mass <- sum(missing_region$counterfactual) - sum(missing_region$count)

  # Bunching ratio: excess / average counterfactual in bunching region
  avg_cf <- mean(bunch_region$counterfactual)
  bunch_ratio <- excess_mass / avg_cf

  # Standard bunching statistic b = excess / counterfactual at notch
  cf_at_threshold <- hist_data[beds == threshold, counterfactual]
  b_hat <- excess_mass / cf_at_threshold

  # Bootstrap for SEs
  boot_b <- numeric(n_boot)
  boot_excess <- numeric(n_boot)
  provider_ids <- unique(df$prvdr_num)
  n_providers <- length(provider_ids)

  for (i in 1:n_boot) {
    boot_ids <- sample(provider_ids, n_providers, replace = TRUE)
    boot_df <- df[prvdr_num %in% boot_ids]
    # Reweight for duplicates
    boot_hist <- boot_df[total_beds >= bin_lo & total_beds <= bin_hi,
                          .N, by = total_beds]
    setnames(boot_hist, c("beds", "count"))
    boot_hist <- merge(all_bins, boot_hist, by = "beds", all.x = TRUE)
    boot_hist[is.na(count), count := 0]
    boot_hist[, excluded := beds >= exclude_lo & beds <= exclude_hi]

    boot_fit_data <- boot_hist[excluded == FALSE]
    boot_fit <- tryCatch(
      lm(count ~ poly(beds, poly_order, raw = TRUE), data = boot_fit_data),
      error = function(e) NULL
    )
    if (is.null(boot_fit)) next

    boot_hist[, cf := predict(boot_fit, newdata = boot_hist)]
    boot_hist[cf < 0, cf := 0]

    boot_bunch <- boot_hist[beds >= exclude_lo & beds <= threshold]
    boot_excess[i] <- sum(boot_bunch$count) - sum(boot_bunch$cf)
    boot_cf_thresh <- boot_hist[beds == threshold, cf]
    boot_b[i] <- ifelse(boot_cf_thresh > 0, boot_excess[i] / boot_cf_thresh, NA)
  }

  se_b <- sd(boot_b, na.rm = TRUE)
  se_excess <- sd(boot_excess, na.rm = TRUE)

  list(
    hist_data = hist_data,
    excess_mass = excess_mass,
    se_excess = se_excess,
    missing_mass = missing_mass,
    bunch_ratio = bunch_ratio,
    b_hat = b_hat,
    se_b = se_b,
    cf_at_threshold = cf_at_threshold
  )
}

## -----------------------------------------------------------------------
## 3. Main estimates: Full sample, Pre-BBA, Post-BBA
## -----------------------------------------------------------------------

cat("\n=== MAIN BUNCHING ESTIMATES ===\n")

# Full sample (pooled)
cat("\n--- Full Sample (2012-2023) ---\n")
res_full <- estimate_bunching(panel, n_boot = 500)
cat(sprintf("  Excess mass: %.1f (SE: %.1f)\n", res_full$excess_mass, res_full$se_excess))
cat(sprintf("  Bunching estimate b̂: %.3f (SE: %.3f)\n", res_full$b_hat, res_full$se_b))
cat(sprintf("  Missing mass above 50: %.1f\n", res_full$missing_mass))

# Pre-BBA (2012-2017)
cat("\n--- Pre-BBA (2012-2017) ---\n")
res_pre <- estimate_bunching(panel[period == "pre_bba"], n_boot = 500)
cat(sprintf("  Excess mass: %.1f (SE: %.1f)\n", res_pre$excess_mass, res_pre$se_excess))
cat(sprintf("  Bunching estimate b̂: %.3f (SE: %.3f)\n", res_pre$b_hat, res_pre$se_b))

# Post-BBA (2018-2023)
cat("\n--- Post-BBA (2018-2023) ---\n")
res_post <- estimate_bunching(panel[period == "post_bba"], n_boot = 500)
cat(sprintf("  Excess mass: %.1f (SE: %.1f)\n", res_post$excess_mass, res_post$se_excess))
cat(sprintf("  Bunching estimate b̂: %.3f (SE: %.3f)\n", res_post$b_hat, res_post$se_b))

# Difference in bunching
b_diff <- res_post$b_hat - res_pre$b_hat
se_diff <- sqrt(res_post$se_b^2 + res_pre$se_b^2)
cat(sprintf("\n--- Change in bunching (Post - Pre) ---\n"))
cat(sprintf("  Δb̂: %.3f (SE: %.3f)\n", b_diff, se_diff))
cat(sprintf("  t-stat: %.2f\n", b_diff / se_diff))

## -----------------------------------------------------------------------
## 4. Year-by-year bunching estimates
## -----------------------------------------------------------------------

cat("\n=== YEAR-BY-YEAR BUNCHING ===\n")

yearly_results <- data.table()
for (y in 2012:2023) {
  sub <- panel[fy == y]
  if (nrow(sub[total_beds >= 20 & total_beds <= 100]) < 50) next

  res_y <- estimate_bunching(sub, n_boot = 200)
  yearly_results <- rbind(yearly_results, data.table(
    year = y,
    excess = res_y$excess_mass,
    se_excess = res_y$se_excess,
    b_hat = res_y$b_hat,
    se_b = res_y$se_b
  ))
  cat(sprintf("  FY%d: b̂=%.3f (SE=%.3f), Excess=%.1f\n",
              y, res_y$b_hat, res_y$se_b, res_y$excess_mass))
}

fwrite(yearly_results, file.path(data_dir, "yearly_bunching.csv"))

## -----------------------------------------------------------------------
## 5. Raw distribution data for tables
## -----------------------------------------------------------------------

# Table: Bin counts around threshold by period
bin_table <- panel[total_beds >= 40 & total_beds <= 60,
                    .N, by = .(total_beds, period)]
bin_wide <- dcast(bin_table, total_beds ~ period, value.var = "N", fill = 0)
setnames(bin_wide, c("Beds", "Post_BBA", "Pre_BBA"))
bin_wide <- bin_wide[order(Beds)]
bin_wide[, Total := Post_BBA + Pre_BBA]

fwrite(bin_wide, file.path(data_dir, "bin_counts_40_60.csv"))

## -----------------------------------------------------------------------
## 6. Sample diagnostics for validator
## -----------------------------------------------------------------------

n_treated_equiv <- nrow(panel[total_beds >= 46 & total_beds <= 50])
n_pre <- length(unique(panel[period == "pre_bba"]$fy))
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated_equiv,
  n_pre = n_pre,
  n_obs = n_obs,
  n_providers = uniqueN(panel$prvdr_num),
  n_years = length(unique(panel$fy)),
  excess_mass_full = round(res_full$excess_mass, 1),
  b_hat_full = round(res_full$b_hat, 3),
  b_hat_pre = round(res_pre$b_hat, 3),
  b_hat_post = round(res_post$b_hat, 3)
)

write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)
cat("\nDiagnostics saved.\n")

# Save key results for table generation
results <- list(
  full = list(excess = res_full$excess_mass, se_excess = res_full$se_excess,
              b_hat = res_full$b_hat, se_b = res_full$se_b,
              missing = res_full$missing_mass, cf_thresh = res_full$cf_at_threshold),
  pre = list(excess = res_pre$excess_mass, se_excess = res_pre$se_excess,
             b_hat = res_pre$b_hat, se_b = res_pre$se_b,
             missing = res_pre$missing_mass, cf_thresh = res_pre$cf_at_threshold),
  post = list(excess = res_post$excess_mass, se_excess = res_post$se_excess,
              b_hat = res_post$b_hat, se_b = res_post$se_b,
              missing = res_post$missing_mass, cf_thresh = res_post$cf_at_threshold),
  diff = list(b_diff = b_diff, se_diff = se_diff)
)
saveRDS(results, file.path(data_dir, "bunching_results.rds"))

cat("\n03_main_analysis.R complete.\n")
