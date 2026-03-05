# ============================================================================
# 05_figures.R — Generate all figures from saved data
# APEP-0525: Tax Borders and the Rich
# ============================================================================

source("00_packages.R")

# ============================================================================
# Figure 1: RDD Plot — High-income share vs. distance to border
# ============================================================================

df <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
df <- df[!is.na(high_share) & total_returns >= 10]

# Binned scatter plot
df30 <- df[abs(dist_to_border_km) <= 30]
df30[, dist_bin := cut(dist_to_border_km, breaks = seq(-30, 30, by = 2), include.lowest = TRUE)]
bin_means <- df30[, .(
  mean_high_share = mean(high_share, na.rm = TRUE),
  se = sd(high_share, na.rm = TRUE) / sqrt(.N),
  n = .N,
  mid = mean(dist_to_border_km)
), by = dist_bin]
bin_means <- bin_means[!is.na(dist_bin)]

# Fit separate linear trends on each side
df_left <- df30[dist_to_border_km < 0]
df_right <- df30[dist_to_border_km >= 0]

p1 <- ggplot() +
  geom_point(data = bin_means, aes(x = mid, y = mean_high_share),
             size = 2, alpha = 0.8, color = "grey30") +
  geom_smooth(data = df_left, aes(x = dist_to_border_km, y = high_share),
              method = "lm", se = TRUE, color = "#d62728", fill = "#d62728", alpha = 0.2) +
  geom_smooth(data = df_right, aes(x = dist_to_border_km, y = high_share),
              method = "lm", se = TRUE, color = "#1f77b4", fill = "#1f77b4", alpha = 0.2) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  annotate("text", x = -15, y = max(bin_means$mean_high_share) * 0.95,
           label = "High-Tax Side", color = "#d62728", fontface = "bold", size = 4) +
  annotate("text", x = 15, y = max(bin_means$mean_high_share) * 0.95,
           label = "Low-Tax Side", color = "#1f77b4", fontface = "bold", size = 4) +
  scale_y_continuous(labels = percent_format(accuracy = 0.1)) +
  labs(
    x = "Distance to State Border (km)",
    y = "Share of Returns with AGI \u2265 $200K",
    title = "Geographic Discontinuity in High-Income Filer Density at Tax Borders"
  )

ggsave(file.path(FIG_DIR, "fig1_rdd_plot.pdf"), p1, width = 8, height = 5.5)
cat("Figure 1 saved\n")

# ============================================================================
# Figure 2: Placebo — Low-income share (same plot)
# ============================================================================

bin_means_low <- df30[, .(
  mean_low_share = mean(low_share, na.rm = TRUE),
  mid = mean(dist_to_border_km)
), by = dist_bin]
bin_means_low <- bin_means_low[!is.na(dist_bin)]

p2 <- ggplot() +
  geom_point(data = bin_means_low, aes(x = mid, y = mean_low_share),
             size = 2, alpha = 0.8, color = "grey30") +
  geom_smooth(data = df_left, aes(x = dist_to_border_km, y = low_share),
              method = "lm", se = TRUE, color = "#d62728", fill = "#d62728", alpha = 0.2) +
  geom_smooth(data = df_right, aes(x = dist_to_border_km, y = low_share),
              method = "lm", se = TRUE, color = "#1f77b4", fill = "#1f77b4", alpha = 0.2) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  annotate("text", x = -15, y = max(bin_means_low$mean_low_share, na.rm = TRUE) * 0.95,
           label = "High-Tax Side", color = "#d62728", fontface = "bold", size = 4) +
  annotate("text", x = 15, y = max(bin_means_low$mean_low_share, na.rm = TRUE) * 0.95,
           label = "Low-Tax Side", color = "#1f77b4", fontface = "bold", size = 4) +
  scale_y_continuous(labels = percent_format(accuracy = 0.1)) +
  labs(
    x = "Distance to State Border (km)",
    y = "Share of Returns with AGI < $50K",
    title = "Placebo: No Discontinuity in Low-Income Filer Density at Tax Borders"
  )

ggsave(file.path(FIG_DIR, "fig2_placebo_rdd.pdf"), p2, width = 8, height = 5.5)
cat("Figure 2 saved\n")

# ============================================================================
# Figure 3: Event Study — SALT cap effect
# ============================================================================

es_coefs <- fread(file.path(DATA_DIR, "event_study_coefs.csv"))

p3 <- ggplot(es_coefs, aes(x = year, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
  geom_vline(xintercept = 2017.5, color = "#e6550d", linetype = "dashed", linewidth = 0.7) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "#1f77b4") +
  geom_point(size = 3, color = "#1f77b4") +
  geom_line(color = "#1f77b4", linewidth = 0.8) +
  annotate("text", x = 2018.5, y = max(es_coefs$ci_upper, na.rm = TRUE) * 0.9,
           label = "SALT Cap\n(Jan 2018)", color = "#e6550d", fontface = "bold",
           hjust = 0, size = 3.5) +
  scale_x_continuous(breaks = 2012:2021) +
  labs(
    x = "Year",
    y = "High-Tax Side \u00d7 Year (Base: 2017)",
    title = "Event Study: SALT Deduction Cap and Border Sorting of High-Income Filers"
  )

ggsave(file.path(FIG_DIR, "fig3_event_study.pdf"), p3, width = 8, height = 5.5)
cat("Figure 3 saved\n")

# ============================================================================
# Figure 4: Bandwidth Sensitivity
# ============================================================================

bw_dt <- fread(file.path(DATA_DIR, "bandwidth_sensitivity.csv"))

p4 <- ggplot(bw_dt, aes(x = bandwidth_km, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "#1f77b4") +
  geom_point(size = 3, color = "#1f77b4") +
  geom_line(color = "#1f77b4", linewidth = 0.8) +
  labs(
    x = "Bandwidth (km from Border)",
    y = "RDD Estimate: High-Tax Side Effect on High-Income Share",
    title = "Bandwidth Sensitivity"
  )

ggsave(file.path(FIG_DIR, "fig4_bandwidth.pdf"), p4, width = 7, height = 5)
cat("Figure 4 saved\n")

# ============================================================================
# Figure 5: Border-Pair Heterogeneity
# ============================================================================

pair_dt <- fread(file.path(DATA_DIR, "pair_rdd_results.csv"))

if (nrow(pair_dt) > 0) {
  pair_dt[, ci_lower := estimate - 1.96 * se_robust]
  pair_dt[, ci_upper := estimate + 1.96 * se_robust]
  setorder(pair_dt, -tax_diff)

  p5 <- ggplot(pair_dt, aes(x = reorder(pair_label, tax_diff), y = estimate)) +
    geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
    geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper), color = "#1f77b4", size = 0.8) +
    coord_flip() +
    labs(
      x = "",
      y = "RDD Estimate: Effect on High-Income Share",
      title = "Border-Pair Heterogeneity in Tax Sorting"
    )

  ggsave(file.path(FIG_DIR, "fig5_pair_heterogeneity.pdf"), p5, width = 7, height = 5)
  cat("Figure 5 saved\n")
}

# ============================================================================
# Figure 6: Period-Specific RDD Estimates
# ============================================================================

period_dt <- fread(file.path(DATA_DIR, "period_rdd_results.csv"))

if (nrow(period_dt) > 0) {
  period_dt[, period := factor(period, levels = c("Pre-SALT", "Post-SALT/Pre-COVID", "COVID"))]
  period_dt[, ci_lower := estimate - 1.96 * se_robust]
  period_dt[, ci_upper := estimate + 1.96 * se_robust]

  p6 <- ggplot(period_dt, aes(x = period, y = estimate)) +
    geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
    geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper), color = "#1f77b4", size = 0.8) +
    labs(
      x = "",
      y = "RDD Estimate: Effect on High-Income Share",
      title = "Period-Specific RDD: Pre-SALT vs. Post-SALT vs. COVID"
    )

  ggsave(file.path(FIG_DIR, "fig6_period_rdd.pdf"), p6, width = 7, height = 5)
  cat("Figure 6 saved\n")
}

# ============================================================================
# Figure 7: Donut Sensitivity
# ============================================================================

donut_dt <- fread(file.path(DATA_DIR, "donut_sensitivity.csv"))

if (nrow(donut_dt) > 0) {
  p7 <- ggplot(donut_dt, aes(x = donut_km, y = estimate)) +
    geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "#1f77b4") +
    geom_point(size = 3, color = "#1f77b4") +
    geom_line(color = "#1f77b4", linewidth = 0.8) +
    labs(
      x = "Donut Radius (km excluded from border)",
      y = "RDD Estimate",
      title = "Donut Design Sensitivity"
    )

  ggsave(file.path(FIG_DIR, "fig7_donut.pdf"), p7, width = 7, height = 5)
  cat("Figure 7 saved\n")
}

# ============================================================================
# Figure 8: DDD Event Study — Income × Side × Year
# ============================================================================

ddd_es_coefs <- tryCatch(fread(file.path(DATA_DIR, "ddd_event_study_coefs.csv")), error = function(e) NULL)

if (!is.null(ddd_es_coefs) && nrow(ddd_es_coefs) > 0) {
  p8 <- ggplot(ddd_es_coefs, aes(x = year, y = estimate)) +
    geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
    geom_vline(xintercept = 2017.5, color = "#e6550d", linetype = "dashed", linewidth = 0.7) +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "#2ca02c") +
    geom_point(size = 3, color = "#2ca02c") +
    geom_line(color = "#2ca02c", linewidth = 0.8) +
    annotate("text", x = 2018.5, y = max(ddd_es_coefs$ci_upper, na.rm = TRUE) * 0.9,
             label = "SALT Cap\n(Jan 2018)", color = "#e6550d", fontface = "bold",
             hjust = 0, size = 3.5) +
    scale_x_continuous(breaks = 2012:2021) +
    labs(
      x = "Year",
      y = expression(beta[t] * ": High-Tax Side " %*% " High Income " %*% " Year"),
      title = "Triple-Difference Event Study: Parallel Pre-Trends Test"
    )

  ggsave(file.path(FIG_DIR, "fig8_ddd_event_study.pdf"), p8, width = 8, height = 5.5)
  cat("Figure 8 (DDD event study) saved\n")
}

cat("\n=== ALL FIGURES GENERATED ===\n")
