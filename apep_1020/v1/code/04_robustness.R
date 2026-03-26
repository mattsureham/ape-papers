# 04_robustness.R — Robustness for round-number-adjusted bunching
# apep_1020/v1

source("00_packages.R")

data_dir <- "../data/"
tables_dir <- "../tables/"

ppd_all <- fread(file.path(data_dir, "ppd_combined.csv"))
ppd_all[, date_transfer := as.Date(date_transfer)]
ppd_eng <- fread(file.path(data_dir, "ppd_england.csv"))
ppd_eng[, date_transfer := as.Date(date_transfer)]

ppd_eng[, regime := fcase(
  date_transfer >= as.Date("2023-01-01") & date_transfer <= as.Date("2024-09-30"), "pre",
  date_transfer >= as.Date("2025-05-01"), "post",
  default = NA_character_
)]

ppd_all[, regime := fcase(
  date_transfer >= as.Date("2023-01-01") & date_transfer <= as.Date("2024-09-30"), "pre",
  date_transfer >= as.Date("2025-05-01"), "post",
  default = NA_character_
)]

# Helpers
sdlt_thresholds <- c(125000, 250000, 300000, 425000, 500000, 625000, 925000, 1500000)
round_5k <- seq(50000, 1100000, by = 5000)

get_controls <- function(th, n = 6) {
  candidates <- round_5k[!round_5k %in% sdlt_thresholds]
  dists <- abs(candidates - th)
  return(candidates[order(dists)][1:n])
}

compute_ratio_from_data <- function(dt, threshold, ctrls, regime_val) {
  dt_r <- dt[regime == regime_val]
  dt_r[, bin := floor(price / 1000) * 1000]
  th_n <- dt_r[bin == threshold, .N]
  ctrl_n <- dt_r[bin %in% ctrls, .N] / length(ctrls)
  if (ctrl_n == 0) return(NA_real_)
  return(th_n / ctrl_n)
}

bootstrap_dir_from_data <- function(dt, threshold, ctrls, n_boot = 1000) {
  dt[, bin := floor(price / 1000) * 1000]

  pre_dt <- dt[regime == "pre"]
  post_dt <- dt[regime == "post"]

  th_pre <- pre_dt[bin == threshold, .N]
  th_post <- post_dt[bin == threshold, .N]
  ctrl_pre <- pre_dt[bin %in% ctrls, .N] / length(ctrls)
  ctrl_post <- post_dt[bin %in% ctrls, .N] / length(ctrls)

  set.seed(42)
  boot_vals <- numeric(n_boot)
  for (b in 1:n_boot) {
    r_pre <- rpois(1, th_pre) / mean(rpois(length(ctrls),
      sapply(ctrls, function(c) pre_dt[bin == c, .N])))
    r_post <- rpois(1, th_post) / mean(rpois(length(ctrls),
      sapply(ctrls, function(c) post_dt[bin == c, .N])))
    boot_vals[b] <- r_post - r_pre
  }
  return(sd(boot_vals, na.rm = TRUE))
}

# ============================================================
# 1. Number of control points sensitivity
# ============================================================
cat("\n=== Robustness: Number of control points ===\n")

ctrl_sens <- list()
for (n_ctrl in c(4, 6, 8, 10)) {
  ctrls <- get_controls(250000, n = n_ctrl)
  r_pre <- compute_ratio_from_data(ppd_eng, 250000, ctrls, "pre")
  r_post <- compute_ratio_from_data(ppd_eng, 250000, ctrls, "post")
  dir_val <- r_post - r_pre
  cat("  N controls =", n_ctrl, ": ratio_pre =", round(r_pre, 3),
      ", ratio_post =", round(r_post, 3), ", DiR =", round(dir_val, 3), "\n")
  ctrl_sens[[length(ctrl_sens) + 1]] <- data.table(
    n_controls = n_ctrl, ratio_pre = r_pre, ratio_post = r_post, dir = dir_val
  )
}
ctrl_dt <- rbindlist(ctrl_sens)
fwrite(ctrl_dt, file.path(data_dir, "robustness_n_controls.csv"))

# ============================================================
# 2. Property type heterogeneity at £250K
# ============================================================
cat("\n=== Heterogeneity: Property type at £250K ===\n")

ctrls_250 <- get_controls(250000)
prop_results <- list()

for (pt in c("D", "S", "T", "F")) {
  pt_label <- c(D = "Detached", S = "Semi-detached",
                T = "Terraced", F = "Flat")[pt]
  ppd_pt <- ppd_eng[property_type == pt & !is.na(regime)]

  r_pre <- compute_ratio_from_data(ppd_pt, 250000, ctrls_250, "pre")
  r_post <- compute_ratio_from_data(ppd_pt, 250000, ctrls_250, "post")
  dir_val <- r_post - r_pre

  # Bootstrap SE
  ppd_pt[, bin := floor(price / 1000) * 1000]
  th_pre <- ppd_pt[regime == "pre" & bin == 250000, .N]
  th_post <- ppd_pt[regime == "post" & bin == 250000, .N]

  set.seed(42)
  boot_dir <- numeric(500)
  for (b in 1:500) {
    ctrl_pre_b <- sapply(ctrls_250, function(c) ppd_pt[regime == "pre" & bin == c, .N])
    ctrl_post_b <- sapply(ctrls_250, function(c) ppd_pt[regime == "post" & bin == c, .N])
    r_pre_b <- rpois(1, th_pre) / mean(rpois(length(ctrls_250), ctrl_pre_b))
    r_post_b <- rpois(1, th_post) / mean(rpois(length(ctrls_250), ctrl_post_b))
    boot_dir[b] <- r_post_b - r_pre_b
  }
  se_val <- sd(boot_dir, na.rm = TRUE)

  cat("  ", pt_label, ": Pre =", round(r_pre, 3),
      ", Post =", round(r_post, 3), ", DiR =", round(dir_val, 3),
      " (SE =", round(se_val, 3), ", t =", round(dir_val/se_val, 2), ")\n")

  prop_results[[length(prop_results) + 1]] <- data.table(
    property_type = pt_label,
    ratio_pre = r_pre, ratio_post = r_post,
    dir = dir_val, dir_se = se_val
  )
}
prop_dt <- rbindlist(prop_results)
fwrite(prop_dt, file.path(data_dir, "robustness_property_type.csv"))

# ============================================================
# 3. Wales geographic placebo at £250K
# ============================================================
cat("\n=== Wales Placebo ===\n")

ppd_wales <- ppd_all[country == "Wales" & !is.na(regime)]
cat("Wales transactions:", nrow(ppd_wales), "\n")

# Wales uses LTT with £225K nil-rate — £250K is NOT a special threshold in Wales
r_pre_w <- compute_ratio_from_data(ppd_wales, 250000, ctrls_250, "pre")
r_post_w <- compute_ratio_from_data(ppd_wales, 250000, ctrls_250, "post")
dir_wales <- r_post_w - r_pre_w

# Bootstrap
ppd_wales[, bin := floor(price / 1000) * 1000]
th_pre_w <- ppd_wales[regime == "pre" & bin == 250000, .N]
th_post_w <- ppd_wales[regime == "post" & bin == 250000, .N]
set.seed(42)
boot_w <- numeric(500)
for (b in 1:500) {
  ctrl_pre_w <- sapply(ctrls_250, function(c) ppd_wales[regime == "pre" & bin == c, .N])
  ctrl_post_w <- sapply(ctrls_250, function(c) ppd_wales[regime == "post" & bin == c, .N])
  r_pre_wb <- rpois(1, th_pre_w) / mean(rpois(length(ctrls_250), ctrl_pre_w))
  r_post_wb <- rpois(1, th_post_w) / mean(rpois(length(ctrls_250), ctrl_post_w))
  boot_w[b] <- r_post_wb - r_pre_wb
}
se_wales <- sd(boot_w, na.rm = TRUE)

cat("  Wales £250K: Pre =", round(r_pre_w, 3),
    ", Post =", round(r_post_w, 3), ", DiR =", round(dir_wales, 3),
    " (SE =", round(se_wales, 3), ")\n")

wales_dt <- data.table(
  test = "Wales £250K placebo",
  ratio_pre = r_pre_w, ratio_post = r_post_w,
  dir = dir_wales, dir_se = se_wales
)
fwrite(wales_dt, file.path(data_dir, "robustness_wales_placebo.csv"))

# ============================================================
# 4. Bin width sensitivity (£500, £1K, £2.5K, £5K)
# ============================================================
cat("\n=== Robustness: Bin Width ===\n")

bw_results <- list()
for (bw in c(500, 1000, 2500, 5000)) {
  ppd_bw <- ppd_eng[!is.na(regime)]
  ppd_bw[, bin := floor(price / bw) * bw]

  # Redefine round-number controls based on bin width
  if (bw >= 5000) {
    th_bin <- 250000
    ctrl_bins <- seq(230000, 270000, by = bw)
    ctrl_bins <- ctrl_bins[!ctrl_bins %in% c(250000)]
  } else {
    th_bin <- 250000
    ctrl_bins <- c(245000, 255000, 240000, 260000, 235000, 265000)
  }

  th_pre <- ppd_bw[regime == "pre" & bin == th_bin, .N]
  th_post <- ppd_bw[regime == "post" & bin == th_bin, .N]
  ctrl_pre_avg <- mean(sapply(ctrl_bins, function(c) ppd_bw[regime == "pre" & bin == c, .N]))
  ctrl_post_avg <- mean(sapply(ctrl_bins, function(c) ppd_bw[regime == "post" & bin == c, .N]))

  r_pre_bw <- th_pre / ctrl_pre_avg
  r_post_bw <- th_post / ctrl_post_avg
  dir_bw <- r_post_bw - r_pre_bw

  cat("  Bin £", bw, ": Pre =", round(r_pre_bw, 3),
      ", Post =", round(r_post_bw, 3), ", DiR =", round(dir_bw, 3), "\n")

  bw_results[[length(bw_results) + 1]] <- data.table(
    bin_width = bw, ratio_pre = r_pre_bw, ratio_post = r_post_bw, dir = dir_bw
  )
}
bw_dt <- rbindlist(bw_results)
fwrite(bw_dt, file.path(data_dir, "robustness_bin_width.csv"))

cat("\nAll robustness checks complete.\n")
