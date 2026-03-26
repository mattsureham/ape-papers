# 03_main_analysis.R — Round-number-adjusted bunching estimation
# apep_1020/v1
#
# Key insight: Housing prices exhibit massive round-number bunching (every £5K).
# Standard polynomial counterfactuals struggle with this.
# We use a "ratio to adjacent round numbers" approach to isolate SDLT-specific
# excess mass above the round-number baseline, then difference across regimes.

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

ppd_eng <- fread(file.path(data_dir, "ppd_england.csv"))
ppd_eng[, date_transfer := as.Date(date_transfer)]

# ============================================================
# Define regimes
# ============================================================
ppd_eng[, regime := fcase(
  date_transfer >= as.Date("2023-01-01") & date_transfer <= as.Date("2024-09-30"), "pre",
  date_transfer >= as.Date("2024-10-01") & date_transfer <= as.Date("2025-03-31"), "anticipation",
  date_transfer >= as.Date("2025-05-01"), "post",
  default = NA_character_
)]

# ============================================================
# Create £1K bins and compute shares
# ============================================================
ppd_analysis <- ppd_eng[regime %in% c("pre", "post", "anticipation")]
ppd_analysis[, bin := floor(price / 1000) * 1000]

bin_counts <- ppd_analysis[, .(count = .N), by = .(bin, regime)]
totals <- ppd_analysis[, .(total = .N), by = regime]
bin_counts <- merge(bin_counts, totals, by = "regime")
bin_counts[, share_per_10k := count / total * 10000]

# Wide format
bin_wide <- dcast(bin_counts[, .(bin, regime, share_per_10k)],
                  bin ~ regime, value.var = "share_per_10k", fill = 0)

# Also compute raw counts wide
count_wide <- dcast(bin_counts[, .(bin, regime, count)],
                    bin ~ regime, value.var = "count", fill = 0)

cat("Pre-period total:", totals[regime == "pre", total], "\n")
cat("Post-period total:", totals[regime == "post", total], "\n")
cat("Anticipation total:", totals[regime == "anticipation", total], "\n")

# ============================================================
# Method: Round-Number-Adjusted Excess Mass
# ============================================================
# For each price p that is a £5K round number, compute:
#   ratio(p, regime) = count(p) / mean(count of 4 nearest £5K round numbers)
# The SDLT-specific excess is: ratio > 1 beyond what pure round-number effects produce
#
# Then: DiR(p) = ratio(p, post) - ratio(p, pre)

# Identify all £5K round numbers
round_5k <- seq(50000, 1100000, by = 5000)

compute_ratio <- function(counts_dt, threshold, control_points, regime_col) {
  th_count <- counts_dt[bin == threshold, get(regime_col)]
  if (length(th_count) == 0 || th_count == 0) return(NA_real_)

  ctrl_counts <- counts_dt[bin %in% control_points, get(regime_col)]
  ctrl_counts <- ctrl_counts[ctrl_counts > 0]
  if (length(ctrl_counts) < 2) return(NA_real_)

  return(th_count / mean(ctrl_counts))
}

# ============================================================
# Main Analysis: SDLT thresholds
# ============================================================
thresholds <- data.table(
  threshold = c(125000, 250000, 300000, 425000),
  label = c("\\pounds 125K", "\\pounds 250K", "\\pounds 300K", "\\pounds 425K"),
  label_clean = c("£125K (new nil-rate)", "£250K (old nil-rate)",
                  "£300K (new FTB)", "£425K (old FTB)"),
  pre_kink = c(0, 5, 0, 5),
  post_kink = c(2, 3, 5, 0),
  prediction = c("Ratio rises", "Ratio falls", "Ratio rises", "Ratio falls")
)

# Define control round numbers for each threshold
# Use 2 round numbers above and 2 below (excluding other SDLT thresholds)
sdlt_thresholds <- c(125000, 250000, 300000, 425000, 500000, 625000, 925000, 1500000)

get_controls <- function(th) {
  candidates <- round_5k[!round_5k %in% sdlt_thresholds]
  # Get 4 nearest
  dists <- abs(candidates - th)
  nearest <- candidates[order(dists)][1:6]
  return(nearest)
}

results <- list()

for (i in 1:nrow(thresholds)) {
  th <- thresholds$threshold[i]
  ctrls <- get_controls(th)
  cat("\n=== Threshold:", th/1000, "K ===\n")
  cat("  Controls:", paste(ctrls/1000, "K", collapse = ", "), "\n")

  # Ratios
  ratio_pre <- compute_ratio(count_wide, th, ctrls, "pre")
  ratio_post <- compute_ratio(count_wide, th, ctrls, "post")
  ratio_antic <- compute_ratio(count_wide, th, ctrls, "anticipation")

  dir <- ratio_post - ratio_pre

  cat("  Pre ratio:", round(ratio_pre, 3), "\n")
  cat("  Post ratio:", round(ratio_post, 3), "\n")
  cat("  Anticipation ratio:", round(ratio_antic, 3), "\n")
  cat("  Difference-in-ratios:", round(dir, 3), "\n")

  # Bootstrap SE for difference-in-ratios
  set.seed(42 + i)
  n_boot <- 1000
  boot_dir <- numeric(n_boot)

  pre_total <- totals[regime == "pre", total]
  post_total <- totals[regime == "post", total]

  # Get raw counts for threshold and control bins
  th_pre <- count_wide[bin == th, pre]
  th_post <- count_wide[bin == th, post]
  ctrl_pre <- count_wide[bin %in% ctrls, pre]
  ctrl_post <- count_wide[bin %in% ctrls, post]

  for (b in 1:n_boot) {
    # Poisson resampling of bin counts (standard for count data)
    th_pre_b <- rpois(1, th_pre)
    th_post_b <- rpois(1, th_post)
    ctrl_pre_b <- rpois(length(ctrl_pre), ctrl_pre)
    ctrl_post_b <- rpois(length(ctrl_post), ctrl_post)

    r_pre_b <- if (mean(ctrl_pre_b) > 0) th_pre_b / mean(ctrl_pre_b) else NA
    r_post_b <- if (mean(ctrl_post_b) > 0) th_post_b / mean(ctrl_post_b) else NA

    boot_dir[b] <- r_post_b - r_pre_b
  }

  se <- sd(boot_dir, na.rm = TRUE)
  cat("  SE:", round(se, 3), "\n")
  cat("  t-stat:", round(dir / se, 2), "\n")

  results[[i]] <- data.table(
    threshold = th,
    label = thresholds$label[i],
    label_clean = thresholds$label_clean[i],
    pre_kink_pp = thresholds$pre_kink[i],
    post_kink_pp = thresholds$post_kink[i],
    prediction = thresholds$prediction[i],
    ratio_pre = ratio_pre,
    ratio_post = ratio_post,
    ratio_antic = ratio_antic,
    dir = dir,
    dir_se = se,
    n_pre = th_pre,
    n_post = th_post
  )
}

results_dt <- rbindlist(results)

# ============================================================
# Placebo: £925K (unchanged 5pp kink)
# ============================================================
cat("\n=== Placebo: £925K (unchanged) ===\n")
ctrls_925 <- get_controls(925000)
ratio_pre_925 <- compute_ratio(count_wide, 925000, ctrls_925, "pre")
ratio_post_925 <- compute_ratio(count_wide, 925000, ctrls_925, "post")
dir_925 <- ratio_post_925 - ratio_pre_925

# Bootstrap SE
set.seed(99)
th_pre_925 <- count_wide[bin == 925000, pre]
th_post_925 <- count_wide[bin == 925000, post]
ctrl_pre_925 <- count_wide[bin %in% ctrls_925, pre]
ctrl_post_925 <- count_wide[bin %in% ctrls_925, post]
boot_925 <- numeric(1000)
for (b in 1:1000) {
  r_pre_b <- rpois(1, th_pre_925) / mean(rpois(length(ctrl_pre_925), ctrl_pre_925))
  r_post_b <- rpois(1, th_post_925) / mean(rpois(length(ctrl_post_925), ctrl_post_925))
  boot_925[b] <- r_post_b - r_pre_b
}
se_925 <- sd(boot_925, na.rm = TRUE)
cat("  Pre ratio:", round(ratio_pre_925, 3),
    "| Post ratio:", round(ratio_post_925, 3),
    "| DiR:", round(dir_925, 3), "(SE:", round(se_925, 3), ")\n")

placebo_row <- data.table(
  threshold = 925000,
  label = "\\pounds 925K",
  label_clean = "£925K (placebo)",
  pre_kink_pp = 5, post_kink_pp = 5,
  prediction = "No change",
  ratio_pre = ratio_pre_925, ratio_post = ratio_post_925,
  ratio_antic = NA,
  dir = dir_925, dir_se = se_925,
  n_pre = th_pre_925, n_post = th_post_925
)
results_dt <- rbind(results_dt, placebo_row)

# ============================================================
# Proportionality test
# ============================================================
cat("\n=== Proportionality ===\n")
results_dt[, delta_tau := post_kink_pp - pre_kink_pp]
main_thresholds <- results_dt[threshold != 925000]
main_thresholds[delta_tau != 0, ratio_per_pp := dir / delta_tau]
cat("DiR/Δτ by threshold:\n")
print(main_thresholds[, .(threshold, delta_tau, dir, ratio_per_pp)])

# ============================================================
# Additional: monthly time series at key thresholds
# ============================================================
cat("\n=== Monthly Time Series ===\n")
ppd_monthly <- ppd_eng[!is.na(regime)]
ppd_monthly[, bin := floor(price / 1000) * 1000]

monthly_250 <- ppd_monthly[bin == 250000, .(count = .N), by = ym][order(ym)]
monthly_ctrl <- ppd_monthly[bin %in% c(245000, 255000, 260000, 240000),
  .(ctrl_count = .N / 4), by = ym][order(ym)]
monthly_250 <- merge(monthly_250, monthly_ctrl, by = "ym")
monthly_250[, ratio := count / ctrl_count]
cat("Monthly ratio at £250K (last 6 months):\n")
print(tail(monthly_250, 8))

# ============================================================
# Save
# ============================================================
fwrite(results_dt, file.path(data_dir, "bunching_results.csv"))

# Diagnostics
diagnostics <- list(
  n_treated = as.integer(nrow(thresholds)),
  n_pre = as.integer(ppd_eng[regime == "pre", uniqueN(ym)]),
  n_obs = as.integer(nrow(ppd_eng[regime %in% c("pre", "post")])),
  n_transactions_pre = as.integer(nrow(ppd_eng[regime == "pre"])),
  n_transactions_post = as.integer(nrow(ppd_eng[regime == "post"])),
  n_thresholds = 5L,
  n_england = as.integer(nrow(ppd_eng[country == "England"]))
)
write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\nMain analysis complete.\n")
