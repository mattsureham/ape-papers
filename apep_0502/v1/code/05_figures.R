# ==============================================================================
# 05_figures.R — Generate all figures
# Clean Air, Dirty Power? NAAQS Nonattainment and the Clean Energy Transition
# ==============================================================================

source("00_packages.R")

# Load data
cs <- readRDS(file.path(data_dir, "cross_section_rdd.rds"))
analysis <- tryCatch(
  readRDS(file.path(data_dir, "analysis_with_energy.rds")),
  error = function(e) readRDS(file.path(data_dir, "analysis_panel.rds"))
)

cat("=== Generating Figures ===\n\n")

# ==============================================================================
# Figure 1: Distribution of PM2.5 Design Values
# ==============================================================================

cat("Figure 1: PM2.5 design value distribution\n")

fig1_data <- analysis[Year >= 2012 & !is.na(design_value)]

fig1 <- ggplot(fig1_data, aes(x = design_value)) +
  geom_histogram(binwidth = 0.5, fill = "steelblue", color = "white", alpha = 0.8) +
  geom_vline(xintercept = 12, linetype = "dashed", color = "red", linewidth = 1) +
  geom_vline(xintercept = 9, linetype = "dotted", color = "darkred", linewidth = 0.8) +
  annotate("text", x = 12.3, y = Inf, label = "2012 NAAQS\n(12 μg/m³)",
           vjust = 1.5, hjust = 0, color = "red", size = 3.5) +
  annotate("text", x = 9.3, y = Inf, label = "2024 NAAQS\n(9 μg/m³)",
           vjust = 1.5, hjust = 0, color = "darkred", size = 3.5) +
  labs(
    title = "Distribution of County PM2.5 Design Values",
    subtitle = "Annual mean concentration (3-year average), 2012-2023",
    x = "PM2.5 Design Value (μg/m³)",
    y = "County-Year Observations"
  ) +
  scale_x_continuous(breaks = seq(4, 20, 2)) +
  theme(plot.title = element_text(size = 13))

ggsave(file.path(fig_dir, "fig1_pm25_distribution.pdf"), fig1, width = 8, height = 5)
cat("  Saved fig1_pm25_distribution.pdf\n")

# ==============================================================================
# Figure 2: McCrary Density Plot
# ==============================================================================

cat("Figure 2: McCrary density test\n")

tryCatch({
  dv_12 <- analysis[Year >= 2012 & !is.na(running_12)]$running_12
  density_test <- rddensity(X = dv_12, c = 0)

  pdf(file.path(fig_dir, "fig2_mccrary_density.pdf"), width = 8, height = 5)
  rdp <- rdplotdensity(density_test, dv_12,
                       title = "McCrary Density Test at 12 μg/m³ Cutoff",
                       xlabel = "PM2.5 Design Value - 12 (μg/m³)",
                       ylabel = "Density")
  dev.off()
  cat("  Saved fig2_mccrary_density.pdf\n")
}, error = function(e) {
  cat(sprintf("  McCrary plot error: %s\n", e$message))
})

# ==============================================================================
# Figure 3: RDD Plot — PM2.5 Outcomes
# ==============================================================================

cat("Figure 3: RDD plot — PM2.5 next-year levels\n")

analysis[, pm25_fwd := shift(pm25_mean, n = -1, type = "lead"), by = county_fips]

rdd_pm25 <- analysis[Year >= 2012 & !is.na(running_12) & !is.na(pm25_fwd)]

tryCatch({
  pdf(file.path(fig_dir, "fig3_rdd_pm25.pdf"), width = 8, height = 5)
  rdp <- rdplot(
    y = rdd_pm25$pm25_fwd,
    x = rdd_pm25$running_12,
    c = 0,
    title = "Effect of Nonattainment on Next-Year PM2.5",
    x.label = "PM2.5 Design Value - 12 μg/m³ (Running Variable)",
    y.label = "Next-Year PM2.5 (μg/m³)",
    ci = 95
  )
  dev.off()
  cat("  Saved fig3_rdd_pm25.pdf\n")
}, error = function(e) {
  cat(sprintf("  RDD PM2.5 plot error: %s\n", e$message))
})

# ==============================================================================
# Figure 4: RDD Plot — Fossil Capacity
# ==============================================================================

if ("fossil_capacity" %in% names(cs)) {
  cat("Figure 4: RDD plot — fossil capacity (cross-sectional)\n")

  rdd_cs <- cs[!is.na(running_12)]

  tryCatch({
    pdf(file.path(fig_dir, "fig4_rdd_fossil_capacity.pdf"), width = 8, height = 5)
    rdp <- rdplot(
      y = rdd_cs$fossil_capacity,
      x = rdd_cs$running_12,
      c = 0,
      title = "Effect of Nonattainment on Fossil Fuel Capacity",
      x.label = "PM2.5 Design Value - 12 μg/m³ (Running Variable)",
      y.label = "Fossil Fuel Capacity (MW)",
      ci = 95
    )
    dev.off()
    cat("  Saved fig4_rdd_fossil_capacity.pdf\n")
  }, error = function(e) {
    cat(sprintf("  RDD fossil plot error: %s\n", e$message))
  })

  # ==============================================================================
  # Figure 5: RDD Plot — Renewable Capacity (Placebo)
  # ==============================================================================

  cat("Figure 5: RDD plot — renewable capacity (placebo, cross-sectional)\n")

  tryCatch({
    pdf(file.path(fig_dir, "fig5_rdd_renewable_placebo.pdf"), width = 8, height = 5)
    rdp <- rdplot(
      y = rdd_cs$renewable_capacity,
      x = rdd_cs$running_12,
      c = 0,
      title = "Placebo: Effect of Nonattainment on Renewable Capacity",
      x.label = "PM2.5 Design Value - 12 μg/m³ (Running Variable)",
      y.label = "Renewable Capacity (MW)",
      ci = 95
    )
    dev.off()
    cat("  Saved fig5_rdd_renewable_placebo.pdf\n")
  }, error = function(e) {
    cat(sprintf("  RDD renewable plot error: %s\n", e$message))
  })
}

# ==============================================================================
# Figure 6: Bandwidth Sensitivity
# ==============================================================================

cat("Figure 6: Bandwidth sensitivity\n")

bw_dt <- tryCatch(readRDS(file.path(data_dir, "robustness_bandwidth.rds")), error = function(e) NULL)

if (!is.null(bw_dt) && nrow(bw_dt) > 0) {
  fig6 <- ggplot(bw_dt, aes(x = bandwidth, y = coef)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_errorbar(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
                  width = 0.1, color = "steelblue") +
    geom_point(size = 3, color = "steelblue") +
    geom_vline(xintercept = bw_dt[bandwidth_mult == 1.0]$bandwidth,
               linetype = "dotted", color = "red") +
    labs(
      title = "RDD Estimates Across Bandwidths",
      subtitle = "Vertical line: MSE-optimal bandwidth",
      x = "Bandwidth (μg/m³)",
      y = "RDD Estimate"
    )

  ggsave(file.path(fig_dir, "fig6_bandwidth_sensitivity.pdf"), fig6, width = 8, height = 5)
  cat("  Saved fig6_bandwidth_sensitivity.pdf\n")
}

# ==============================================================================
# Figure 7: Placebo Cutoff Tests
# ==============================================================================

cat("Figure 7: Placebo cutoff tests\n")

placebo_dt <- tryCatch(readRDS(file.path(data_dir, "robustness_placebos.rds")), error = function(e) NULL)

if (!is.null(placebo_dt) && nrow(placebo_dt) > 0) {
  # Add the true cutoff result
  tryCatch({
    rd_true <- rdrobust(
      y = analysis[Year >= 2012 & !is.na(running_12)][[
        if ("fossil_capacity" %in% names(analysis)) "fossil_capacity" else "pm25_mean"
      ]],
      x = analysis[Year >= 2012 & !is.na(running_12)]$running_12,
      c = 0, kernel = "triangular", bwselect = "mserd"
    )
    true_result <- data.table(
      cutoff_shift = 0,
      coef = rd_true$coef["Conventional", ],
      se = rd_true$se["Conventional", ],
      pvalue = rd_true$pv["Conventional", ]
    )
    placebo_plot_dt <- rbind(true_result, placebo_dt)
  }, error = function(e) {
    placebo_plot_dt <- placebo_dt
  })

  fig7 <- ggplot(placebo_plot_dt, aes(x = cutoff_shift, y = coef)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_errorbar(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
                  width = 0.3, color = ifelse(placebo_plot_dt$cutoff_shift == 0, "red", "grey40")) +
    geom_point(size = 3, color = ifelse(placebo_plot_dt$cutoff_shift == 0, "red", "grey40")) +
    labs(
      title = "Placebo Cutoff Tests",
      subtitle = "Red: true cutoff (c=0). Grey: placebo cutoffs.",
      x = "Cutoff Shift from True Threshold (μg/m³)",
      y = "RDD Estimate"
    ) +
    scale_x_continuous(breaks = seq(-4, 4, 1))

  ggsave(file.path(fig_dir, "fig7_placebo_cutoffs.pdf"), fig7, width = 8, height = 5)
  cat("  Saved fig7_placebo_cutoffs.pdf\n")
}

# ==============================================================================
# Figure 8: Covariate Balance
# ==============================================================================

cat("Figure 8: Covariate balance\n")

balance_dt <- tryCatch(readRDS(file.path(data_dir, "balance_test_results.rds")), error = function(e) NULL)

if (!is.null(balance_dt) && nrow(balance_dt) > 0) {
  # Normalize coefficients for display
  balance_dt[, std_coef := coef / se]

  fig8 <- ggplot(balance_dt, aes(x = reorder(variable, abs(std_coef)), y = std_coef)) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    geom_hline(yintercept = c(-1.96, 1.96), linetype = "dotted", color = "red") +
    geom_point(size = 3, color = "steelblue") +
    geom_errorbar(aes(ymin = std_coef - 1.96, ymax = std_coef + 1.96),
                  width = 0.2, color = "steelblue") +
    coord_flip() +
    labs(
      title = "Covariate Balance at 12 μg/m³ Cutoff",
      subtitle = "T-statistics from local polynomial RDD. Red lines: ±1.96.",
      x = "",
      y = "T-Statistic"
    )

  ggsave(file.path(fig_dir, "fig8_covariate_balance.pdf"), fig8, width = 8, height = 5)
  cat("  Saved fig8_covariate_balance.pdf\n")
}

cat("\n=== All figures generated ===\n")
