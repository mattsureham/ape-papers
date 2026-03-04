## =============================================================================
## 05_figures.R — All figures for the paper
## apep_0496: Education Priority Labels and Housing Markets in France
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
tables_dir <- "../tables"
dir.create(fig_dir, showWarnings = FALSE)

## ---------------------------------------------------------------------------
## Load data
## ---------------------------------------------------------------------------

dt <- readRDS(file.path(data_dir, "analysis_data.rds"))
dt_near <- dt[abs(dist_signed) <= 2000]
dt_near[, log_price_m2 := log(price_m2)]

## ---------------------------------------------------------------------------
## Figure 1: RDD Plot — Price discontinuity at REP boundary
## ---------------------------------------------------------------------------

cat("=== Figure 1: RDD Plot ===\n")

dt_near[, dist_bin := round(dist_signed / 50) * 50]

bin_means <- dt_near[, .(
  mean_log_price = mean(log_price_m2, na.rm = TRUE),
  mean_price_m2 = mean(price_m2, na.rm = TRUE),
  se = sd(log_price_m2, na.rm = TRUE) / sqrt(.N),
  n = .N
), by = dist_bin]

fig1 <- ggplot(bin_means[abs(dist_bin) <= 2000 & n >= 10],
               aes(x = dist_bin, y = mean_log_price)) +
  geom_point(aes(size = n), alpha = 0.5, color = "grey40") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red", linewidth = 0.5) +
  geom_smooth(data = bin_means[dist_bin < 0 & abs(dist_bin) <= 2000 & n >= 10],
              method = "loess", se = TRUE, color = "#E41A1C", fill = "#E41A1C",
              alpha = 0.15, span = 0.5) +
  geom_smooth(data = bin_means[dist_bin >= 0 & abs(dist_bin) <= 2000 & n >= 10],
              method = "loess", se = TRUE, color = "#377EB8", fill = "#377EB8",
              alpha = 0.15, span = 0.5) +
  scale_size_continuous(range = c(0.5, 3), guide = "none") +
  annotate("text", x = -1000, y = max(bin_means$mean_log_price, na.rm = TRUE),
           label = "Non-REP Side", color = "#E41A1C", fontface = "bold", size = 3.5) +
  annotate("text", x = 1000, y = max(bin_means$mean_log_price, na.rm = TRUE),
           label = "REP Side", color = "#377EB8", fontface = "bold", size = 3.5) +
  labs(
    x = "Distance to REP/Non-REP Boundary (meters)",
    y = "Log Price per m²",
    title = "Property Prices at Education Priority Zone Boundaries",
    subtitle = "Each dot represents a 50m bin; size proportional to transaction count"
  ) +
  theme(plot.title = element_text(size = 11))

ggsave(file.path(fig_dir, "fig1_rdd_plot.pdf"), fig1,
       width = 8, height = 5.5, dpi = 300)
cat("  Saved fig1_rdd_plot.pdf\n")

## ---------------------------------------------------------------------------
## Figure 2: Event study — Year-by-year boundary gaps
## ---------------------------------------------------------------------------

cat("=== Figure 2: Event Study ===\n")

year_results <- fread(file.path(tables_dir, "year_by_year_rdd.csv"))

if (nrow(year_results) > 0) {
  fig2 <- ggplot(year_results, aes(x = year, y = coef)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
                fill = "#377EB8", alpha = 0.15) +
    geom_line(color = "#377EB8", linewidth = 0.7) +
    geom_point(color = "#377EB8", size = 2) +
    labs(
      x = "Year",
      y = "Boundary Gap (log price per m²)",
      title = "Education Priority Label and Housing Prices: Annual Boundary Gaps",
      subtitle = "RDD estimates at REP/non-REP catchment boundaries by year"
    ) +
    scale_x_continuous(
      breaks = sort(unique(year_results$year)),
      labels = function(x) ifelse(x == 2025, "2025\n(partial)", as.character(x))
    ) +
    theme(plot.title = element_text(size = 11))

  ggsave(file.path(fig_dir, "fig2_event_study.pdf"), fig2,
         width = 8, height = 5.5, dpi = 300)
  cat("  Saved fig2_event_study.pdf\n")
}

## ---------------------------------------------------------------------------
## Figure 3: McCrary density test
## ---------------------------------------------------------------------------

cat("=== Figure 3: Density Test ===\n")

fig3 <- ggplot(dt_near[abs(dist_signed) <= 2000],
               aes(x = dist_signed)) +
  geom_histogram(binwidth = 50, alpha = 0.7, fill = "#377EB8",
                 color = "white", linewidth = 0.1) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
  labs(
    x = "Distance to Boundary (meters, positive = REP side)",
    y = "Number of Transactions",
    title = "Transaction Density at REP/Non-REP Boundaries",
    subtitle = "McCrary density test for sorting at the boundary"
  ) +
  theme(plot.title = element_text(size = 11))

ggsave(file.path(fig_dir, "fig3_density.pdf"), fig3,
       width = 8, height = 5.5, dpi = 300)
cat("  Saved fig3_density.pdf\n")

## ---------------------------------------------------------------------------
## Figure 4: Bandwidth sensitivity
## ---------------------------------------------------------------------------

cat("=== Figure 4: Bandwidth Sensitivity ===\n")

bw_results <- fread(file.path(tables_dir, "bandwidth_sensitivity.csv"))

if (nrow(bw_results) > 0) {
  fig4 <- ggplot(bw_results, aes(x = bandwidth, y = coef)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
                fill = "#377EB8", alpha = 0.15) +
    geom_line(color = "#377EB8", linewidth = 0.7) +
    geom_point(color = "#377EB8", size = 2) +
    labs(
      x = "Bandwidth (meters)",
      y = "RDD Coefficient",
      title = "Bandwidth Sensitivity of Boundary Estimates",
      subtitle = "Optimal bandwidth and multiples (0.5x to 2x)"
    ) +
    theme(plot.title = element_text(size = 11))

  ggsave(file.path(fig_dir, "fig4_bandwidth.pdf"), fig4,
         width = 7, height = 5, dpi = 300)
  cat("  Saved fig4_bandwidth.pdf\n")
}

## ---------------------------------------------------------------------------
## Figure 5: Covariate balance at boundary
## ---------------------------------------------------------------------------

cat("=== Figure 5: Covariate Balance ===\n")

balance_dt <- dt_near[abs(dist_signed) <= 2000,
                       .(mean_surface = mean(surface_reelle_bati, na.rm = TRUE),
                         pct_apt = mean(type_local == "Appartement", na.rm = TRUE),
                         n = .N),
                       by = dist_bin]

fig5a <- ggplot(balance_dt[n >= 10], aes(x = dist_bin, y = mean_surface)) +
  geom_point(alpha = 0.5, color = "grey40", size = 1) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
  geom_smooth(data = balance_dt[dist_bin < 0 & n >= 10],
              method = "loess", color = "#E41A1C", se = FALSE) +
  geom_smooth(data = balance_dt[dist_bin >= 0 & n >= 10],
              method = "loess", color = "#377EB8", se = FALSE) +
  labs(x = "Distance to Boundary (m)", y = "Mean Surface (m²)",
       title = "Surface Area") +
  theme(plot.title = element_text(size = 10))

fig5b <- ggplot(balance_dt[n >= 10], aes(x = dist_bin, y = pct_apt)) +
  geom_point(alpha = 0.5, color = "grey40", size = 1) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
  geom_smooth(data = balance_dt[dist_bin < 0 & n >= 10],
              method = "loess", color = "#E41A1C", se = FALSE) +
  geom_smooth(data = balance_dt[dist_bin >= 0 & n >= 10],
              method = "loess", color = "#377EB8", se = FALSE) +
  labs(x = "Distance to Boundary (m)", y = "Share Apartments",
       title = "Property Type Composition") +
  theme(plot.title = element_text(size = 10))

fig5 <- fig5a + fig5b +
  plot_annotation(
    title = "Covariate Balance at REP/Non-REP Boundaries",
    subtitle = "Smoothness tests: no discontinuity expected if boundary is quasi-random",
    theme = theme(plot.title = element_text(face = "bold", size = 11))
  )

ggsave(file.path(fig_dir, "fig5_balance.pdf"), fig5,
       width = 10, height = 5, dpi = 300)
cat("  Saved fig5_balance.pdf\n")

## ---------------------------------------------------------------------------
## Figure 6: Private school mechanism
## ---------------------------------------------------------------------------

cat("=== Figure 6: Private School Mechanism ===\n")

if ("high_private" %in% names(dt_near)) {
  # Bin means by private school density
  bin_by_priv <- dt_near[, .(
    mean_log_price = mean(log_price_m2, na.rm = TRUE),
    n = .N
  ), by = .(dist_bin, high_private)]

  fig6 <- ggplot(bin_by_priv[abs(dist_bin) <= 2000 & n >= 10],
                 aes(x = dist_bin, y = mean_log_price,
                     color = factor(high_private))) +
    geom_point(alpha = 0.3, size = 0.8) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey40") +
    geom_smooth(method = "loess", se = FALSE, span = 0.5, linewidth = 0.8) +
    scale_color_manual(values = c("0" = "#E41A1C", "1" = "#377EB8"),
                       labels = c("Low Private Density", "High Private Density"),
                       name = "Private School\nAvailability") +
    labs(
      x = "Distance to Boundary (meters)",
      y = "Log Price per m²",
      title = "REP Boundary Gap by Private School Availability",
      subtitle = "Areas with more private schools show attenuated boundary effects"
    ) +
    theme(legend.position = c(0.82, 0.15),
          plot.title = element_text(size = 11))

  ggsave(file.path(fig_dir, "fig6_mechanism.pdf"), fig6,
         width = 8, height = 5.5, dpi = 300)
  cat("  Saved fig6_mechanism.pdf\n")
}

cat("\nAll figures generated.\n")
