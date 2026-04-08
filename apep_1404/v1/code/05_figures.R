# 05_figures.R — Generate all figures for Pipeline Scars paper
source("00_packages.R")

analysis <- readRDS("../data/analysis.rds")
df <- readRDS("../data/incidents_clean.rds")
results <- readRDS("../data/main_results.rds")

fig_dir <- "../figures"

# -------------------------------------------------------
# Figure 1: Distribution of incidents by normalized cost
# -------------------------------------------------------
cat("Figure 1: Cost distribution...\n")

# Histogram with density
p1 <- ggplot(df[norm_cost > 0 & norm_cost < 3], aes(x = norm_cost)) +
  geom_histogram(aes(y = after_stat(density)), bins = 60, fill = "steelblue", alpha = 0.7, color = "white") +
  geom_vline(xintercept = 1, linetype = "dashed", color = "red", linewidth = 0.8) +
  annotate("text", x = 1.05, y = Inf, label = "Significant\nthreshold", hjust = 0, vjust = 1.5, color = "red", size = 3.5) +
  labs(
    x = "Normalized Incident Cost (cost / CPI-adjusted threshold)",
    y = "Density",
    title = "Distribution of Pipeline Incidents by Normalized Cost"
  ) +
  scale_x_continuous(breaks = seq(0, 3, 0.5))

ggsave(file.path(fig_dir, "fig1_cost_distribution.pdf"), p1, width = 8, height = 5)

# -------------------------------------------------------
# Figure 2: McCrary density test
# -------------------------------------------------------
cat("Figure 2: McCrary density...\n")

density_test <- rddensity(X = analysis$norm_cost_centered, c = 0)
pdf(file.path(fig_dir, "fig2_mccrary.pdf"), width = 8, height = 5)
rdplotdensity(density_test, analysis$norm_cost_centered,
  title = "McCrary Density Test at Significant Incident Threshold",
  xlabel = "Normalized Cost (centered at threshold)",
  ylabel = "Density",
  lcol = c("steelblue", "firebrick"),
  CIcol = c(rgb(70/255, 130/255, 180/255, 0.2), rgb(178/255, 34/255, 34/255, 0.2))
)
dev.off()

# -------------------------------------------------------
# Figure 3: First stage — significant flag by normalized cost
# -------------------------------------------------------
cat("Figure 3: First stage...\n")

# Bin scatter
bin_width <- 0.02
bins_df <- df[norm_cost > 0.5 & norm_cost < 1.5, .(
  pct_significant = mean(significant),
  n = .N
), by = .(bin = floor(norm_cost / bin_width) * bin_width)]
bins_df[, bin_center := bin + bin_width / 2]

p3 <- ggplot(bins_df, aes(x = bin_center, y = pct_significant)) +
  geom_point(aes(size = n), color = "steelblue", alpha = 0.7) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "red", linewidth = 0.8) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
  scale_size_continuous(range = c(1, 5), guide = "none") +
  labs(
    x = "Normalized Incident Cost",
    y = "Fraction Labeled 'Significant'",
    title = "First Stage: Significant Incident Label by Normalized Cost"
  )

ggsave(file.path(fig_dir, "fig3_first_stage.pdf"), p3, width = 8, height = 5)

# -------------------------------------------------------
# Figure 4: RD plot — future incidents
# -------------------------------------------------------
cat("Figure 4: RD plot future incidents...\n")

pdf(file.path(fig_dir, "fig4_rd_future_incidents.pdf"), width = 8, height = 5)
rdplot(
  y = analysis$future_incidents,
  x = analysis$norm_cost_centered,
  c = 0,
  title = "Effect of Significant Label on Future Incidents (t+1 to t+3)",
  x.label = "Normalized Cost (centered at threshold)",
  y.label = "Number of Incidents in Next 3 Years",
  col.dots = "steelblue",
  col.lines = "firebrick"
)
dev.off()

# -------------------------------------------------------
# Figure 5: RD plot — future cost
# -------------------------------------------------------
cat("Figure 5: RD plot future cost...\n")

pdf(file.path(fig_dir, "fig5_rd_future_cost.pdf"), width = 8, height = 5)
rdplot(
  y = log1p(analysis$future_cost),
  x = analysis$norm_cost_centered,
  c = 0,
  title = "Effect of Significant Label on Future Incident Costs (log)",
  x.label = "Normalized Cost (centered at threshold)",
  y.label = "Log(1 + Future Total Cost)",
  col.dots = "steelblue",
  col.lines = "firebrick"
)
dev.off()

# -------------------------------------------------------
# Figure 6: Bandwidth sensitivity
# -------------------------------------------------------
cat("Figure 6: Bandwidth sensitivity...\n")

rob <- readRDS("../data/robustness_results.rds")
bw_tab <- rob$bandwidth_sensitivity

p6 <- ggplot(bw_tab, aes(x = bandwidth, y = coef)) +
  geom_point(size = 3, color = "steelblue") +
  geom_errorbar(aes(ymin = ci_low, ymax = ci_high), width = 0.005, color = "steelblue") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  labs(
    x = "Bandwidth",
    y = "RD Estimate (Future Incidents)",
    title = "Bandwidth Sensitivity of Main RD Estimate"
  ) +
  annotate("text", x = bw_tab[frac == 1, bandwidth], y = bw_tab[frac == 1, ci_high] + 0.2,
    label = "CCT optimal", color = "firebrick", size = 3.5)

ggsave(file.path(fig_dir, "fig6_bandwidth_sensitivity.pdf"), p6, width = 8, height = 5)

# -------------------------------------------------------
# Figure 7: Placebo thresholds
# -------------------------------------------------------
cat("Figure 7: Placebo thresholds...\n")

placebo_tab <- rob$placebo
if (nrow(placebo_tab) > 0) {
  # Add true estimate
  true_est <- data.table(
    cutoff = 1.0,
    coef = results$main_rd$coef,
    se = results$main_rd$se_robust,
    p_value = 2 * pnorm(-abs(results$main_rd$coef / results$main_rd$se_robust))
  )
  plot_tab <- rbind(placebo_tab, true_est)
  plot_tab[, is_true := cutoff == 1.0]

  p7 <- ggplot(plot_tab, aes(x = cutoff, y = coef, color = is_true)) +
    geom_point(size = 3) +
    geom_errorbar(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se), width = 0.02) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    scale_color_manual(values = c("TRUE" = "firebrick", "FALSE" = "steelblue"), guide = "none") +
    labs(
      x = "Threshold (normalized cost)",
      y = "RD Estimate",
      title = "Placebo Threshold Tests"
    )

  ggsave(file.path(fig_dir, "fig7_placebo_thresholds.pdf"), p7, width = 8, height = 5)
}

# -------------------------------------------------------
# Figure 8: Covariate balance — cause distribution
# -------------------------------------------------------
cat("Figure 8: Covariate balance...\n")

cause_col <- grep("cause|CAUSE", names(df), value = TRUE, ignore.case = TRUE)[1]
if (!is.na(cause_col) && !is.null(cause_col)) {
  near_df <- df[norm_cost > 0.8 & norm_cost < 1.2]
  near_df[, side := ifelse(norm_cost < 1, "Below", "Above")]
  cause_dist <- near_df[, .N, by = c(cause_col, "side")]
  setnames(cause_dist, cause_col, "cause")
  cause_totals <- cause_dist[, .(total = sum(N)), by = side]
  cause_dist <- merge(cause_dist, cause_totals, by = "side")
  cause_dist[, share := N / total]

  # Top 6 causes
  top_causes <- cause_dist[, .(total = sum(N)), by = cause][order(-total)][1:6, cause]
  cause_dist <- cause_dist[cause %in% top_causes]

  p8 <- ggplot(cause_dist, aes(x = cause, y = share, fill = side)) +
    geom_col(position = "dodge", alpha = 0.8) +
    scale_fill_manual(values = c("Below" = "steelblue", "Above" = "firebrick")) +
    scale_y_continuous(labels = scales::percent) +
    labs(
      x = "Incident Cause",
      y = "Share of Incidents",
      fill = "Side of\nThreshold",
      title = "Covariate Balance: Cause Distribution Near Threshold"
    ) +
    theme(axis.text.x = element_text(angle = 30, hjust = 1, size = 8))

  ggsave(file.path(fig_dir, "fig8_cause_balance.pdf"), p8, width = 8, height = 5)
}

cat("All figures saved to", fig_dir, "\n")
