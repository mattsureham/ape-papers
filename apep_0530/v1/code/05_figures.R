## 05_figures.R — All figures (read from CSV, never from in-memory objects)

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

# ── Figure 1: Year-by-year boundary discontinuity ────────────────────────────
cat("Figure 1: Year-by-year estimates...\n")
es <- fread(file.path(data_dir, "event_study.csv"))

if (nrow(es) > 0) {
  es[, group_label := factor(group,
    levels = c("gained", "retained"),
    labels = c("Gained QPV Status", "Retained QPV")
  )]

  fig1 <- ggplot(es, aes(x = year, y = estimate, color = group_label, fill = group_label)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15, color = NA) +
    geom_point(size = 2.5) +
    geom_line(linewidth = 0.8) +
    scale_color_manual(values = c("#2166AC", "#636363")) +
    scale_fill_manual(values = c("#2166AC", "#636363")) +
    labs(
      title = "Boundary Price Discontinuity by Year",
      subtitle = "Inside vs. outside zone boundary, relative to first year",
      x = NULL, y = "Log price per sqm (inside - outside)",
      color = NULL, fill = NULL
    ) +
    theme(legend.position = "bottom")

  ggsave(file.path(fig_dir, "event_study.pdf"), fig1, width = 8, height = 5.5)
  ggsave(file.path(fig_dir, "event_study.png"), fig1, width = 8, height = 5.5, dpi = 300)
  cat("  Saved event_study.pdf\n")
}

# ── Figure 2: Bandwidth sensitivity ─────────────────────────────────────────
cat("Figure 2: Bandwidth sensitivity...\n")
bw_sens <- fread(file.path(data_dir, "bw_sensitivity.csv"))

if (nrow(bw_sens) > 0) {
  bw_sens[, group_label := factor(coefficient,
    levels = c("gained", "retained"),
    labels = c("Gained QPV", "Retained QPV")
  )]

  fig2 <- ggplot(bw_sens, aes(x = bandwidth, y = estimate, color = group_label)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 30, linewidth = 0.6) +
    geom_point(size = 3) +
    geom_line(linewidth = 0.7) +
    scale_color_manual(values = c("#2166AC", "#636363")) +
    scale_x_continuous(breaks = c(200, 500, 1000, 1500, 2000)) +
    labs(
      title = "Sensitivity to Bandwidth Choice",
      subtitle = "Boundary discontinuity estimates at different distance thresholds",
      x = "Bandwidth (meters)", y = "Estimate (inside x group)",
      color = NULL
    ) +
    theme(legend.position = "bottom")

  ggsave(file.path(fig_dir, "bw_sensitivity.pdf"), fig2, width = 7, height = 5)
  ggsave(file.path(fig_dir, "bw_sensitivity.png"), fig2, width = 7, height = 5, dpi = 300)
  cat("  Saved bw_sensitivity.pdf\n")
}

# ── Figure 3: McCrary density test ──────────────────────────────────────────
cat("Figure 3: McCrary density test...\n")
density <- fread(file.path(data_dir, "density_test.csv"))

if (nrow(density) > 0) {
  density[, group_label := factor(group,
    levels = c("gained", "retained"),
    labels = c("Gained QPV", "Retained")
  )]

  fig3 <- ggplot(density, aes(x = dist_bin, y = N)) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "red", linewidth = 0.5) +
    geom_col(fill = "#4393C3", alpha = 0.7, width = 45) +
    facet_wrap(~group_label, scales = "free_y", ncol = 2) +
    labs(
      title = "Transaction Density at Zone Boundaries",
      subtitle = "No discontinuous bunching expected under valid RDD",
      x = "Signed distance to boundary (m, negative = inside)",
      y = "Number of transactions"
    )

  ggsave(file.path(fig_dir, "density_test.pdf"), fig3, width = 8, height = 4)
  ggsave(file.path(fig_dir, "density_test.png"), fig3, width = 8, height = 4, dpi = 300)
  cat("  Saved density_test.pdf\n")
}

# ── Figure 4: RDD plots ─────────────────────────────────────────────────────
cat("Figure 4: RDD scatter plots...\n")
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

if (nrow(panel) > 0) {
  rdd_plot_data <- panel[dist_to_boundary <= 1000]
  rdd_plot_data[, dist_bin := round(signed_dist / 25) * 25]

  binned <- rdd_plot_data[, .(
    mean_log_price = mean(log_price_sqm, na.rm = TRUE),
    se = sd(log_price_sqm, na.rm = TRUE) / sqrt(.N),
    n = .N
  ), by = .(nearest_group, dist_bin)]

  binned[, group_label := factor(nearest_group,
    levels = c("gained", "retained"),
    labels = c("Gained QPV", "Retained QPV")
  )]

  fig4 <- ggplot(binned[n >= 5], aes(x = dist_bin, y = mean_log_price)) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "red", linewidth = 0.5) +
    geom_point(aes(size = n), color = "#4393C3", alpha = 0.6) +
    geom_smooth(data = binned[n >= 5 & dist_bin < 0],
                method = "loess", se = TRUE, color = "#2166AC", fill = "#2166AC", alpha = 0.2) +
    geom_smooth(data = binned[n >= 5 & dist_bin > 0],
                method = "loess", se = TRUE, color = "#B2182B", fill = "#B2182B", alpha = 0.2) +
    facet_wrap(~group_label, scales = "free_y", ncol = 2) +
    scale_size_continuous(range = c(0.5, 3), guide = "none") +
    labs(
      title = "Property Prices at Zone Boundaries",
      subtitle = "Binned scatter with local polynomial fit. Left of line = inside zone.",
      x = "Signed distance to boundary (m)",
      y = "Mean log price per sqm"
    )

  ggsave(file.path(fig_dir, "rdd_scatter.pdf"), fig4, width = 8, height = 4.5)
  ggsave(file.path(fig_dir, "rdd_scatter.png"), fig4, width = 8, height = 4.5, dpi = 300)
  cat("  Saved rdd_scatter.pdf\n")
}

# ── Figure 5: Type heterogeneity ────────────────────────────────────────────
cat("Figure 5: Property type heterogeneity...\n")
type_het <- fread(file.path(data_dir, "type_heterogeneity.csv"))

if (nrow(type_het) > 0) {
  type_het[, group := gsub("inside_x_", "", coefficient)]
  type_het[, group_label := factor(group,
    levels = c("gained", "retained"),
    labels = c("Gained QPV", "Retained")
  )]
  type_het[, ci_lower := estimate - 1.96 * se]
  type_het[, ci_upper := estimate + 1.96 * se]

  fig5 <- ggplot(type_het, aes(x = group_label, y = estimate,
                               color = property_type, shape = property_type)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper),
                    position = position_dodge(width = 0.3), size = 0.8) +
    scale_color_manual(values = c("#2166AC", "#B2182B")) +
    labs(
      title = "Designation Effects by Property Type",
      subtitle = "Apartments (rental proxy) vs. houses (owner-occupied proxy)",
      x = NULL, y = "Boundary discontinuity estimate",
      color = NULL, shape = NULL
    ) +
    theme(legend.position = "bottom")

  ggsave(file.path(fig_dir, "type_heterogeneity.pdf"), fig5, width = 6, height = 5)
  ggsave(file.path(fig_dir, "type_heterogeneity.png"), fig5, width = 6, height = 5, dpi = 300)
  cat("  Saved type_heterogeneity.pdf\n")
}

cat("\n=== All figures generated ===\n")
