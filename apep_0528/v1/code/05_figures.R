## 05_figures.R — All figures
## APEP-0528: Do Administrative Borders Tax Electricity?

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

# ===========================================================================
# Figure 1: Tariff distribution and spatial variation
# ===========================================================================
cat("=== Figure 1: Tariff distribution ===\n")

panel <- fread(file.path(data_dir, "panel.csv"))
latest_year <- max(panel$year, na.rm = TRUE)

# Panel A: Distribution of total tariff
fig1a_data <- panel[year == latest_year & !is.na(total)]
p1a <- ggplot(fig1a_data, aes(x = total)) +
  geom_histogram(bins = 60, fill = "#2166AC", alpha = 0.7, color = "white", linewidth = 0.2) +
  geom_vline(xintercept = median(fig1a_data$total, na.rm = TRUE),
             linetype = "dashed", color = "red") +
  labs(x = "Total Tariff (Rp/kWh)", y = "Number of Municipalities",
       title = "A. Distribution of Electricity Tariffs") +
  annotate("text", x = median(fig1a_data$total, na.rm = TRUE) + 2,
           y = Inf, vjust = 2, hjust = 0, size = 3,
           label = paste0("Median: ", round(median(fig1a_data$total, na.rm = TRUE), 1)))

# Panel B: Component shares
comp_shares <- panel[year == latest_year, .(
  Energy = mean(energy, na.rm = TRUE),
  Grid = mean(gridusage, na.rm = TRUE),
  `Federal Aid` = mean(aidfee, na.rm = TRUE),
  Charges = mean(charge, na.rm = TRUE)
)]
comp_long <- melt(comp_shares, measure.vars = names(comp_shares),
                  variable.name = "Component", value.name = "Mean_Rp")
comp_long[, share := Mean_Rp / sum(Mean_Rp)]

p1b <- ggplot(comp_long, aes(x = reorder(Component, -Mean_Rp), y = Mean_Rp, fill = Component)) +
  geom_col(alpha = 0.85) +
  geom_text(aes(label = paste0(round(share * 100, 1), "%")), vjust = -0.5, size = 3) +
  scale_fill_manual(values = c("Energy" = "#2166AC", "Grid" = "#67A9CF",
                                "Federal Aid" = "#D1E5F0", "Charges" = "#B2182B")) +
  labs(x = "", y = "Mean Tariff Component (Rp/kWh)",
       title = "B. Tariff Decomposition") +
  theme(legend.position = "none")

fig1 <- p1a / p1b
ggsave(file.path(fig_dir, "fig1_tariff_distribution.pdf"), fig1, width = 7, height = 9)
cat("  Saved fig1_tariff_distribution.pdf\n")

# ===========================================================================
# Figure 2: Event study — Component decomposition
# ===========================================================================
cat("=== Figure 2: Event study ===\n")

es_data <- fread(file.path(data_dir, "event_study_results.csv"))

if (nrow(es_data) > 0) {
  # Add reference period (0 at t=-1)
  ref_row <- data.table(
    component = unique(es_data$component),
    event_time = -1L,
    estimate = 0, se = 0, ci_lo = 0, ci_hi = 0
  )
  es_plot <- rbind(es_data, ref_row)

  # Rename components for display
  comp_labels <- c(
    "total" = "Total Tariff",
    "charge" = "Cantonal/Municipal Charges",
    "energy" = "Energy Cost",
    "gridusage" = "Grid Usage",
    "aidfee" = "Federal Aid Fee (Placebo)"
  )
  es_plot[, Component := comp_labels[component]]
  es_plot[, Component := factor(Component, levels = comp_labels)]

  # Use faceted panels for clarity (avoid spaghetti plot)
  color_map <- c(
    "Total Tariff" = "#1B7837",
    "Cantonal/Municipal Charges" = "#B2182B",
    "Energy Cost" = "#2166AC",
    "Grid Usage" = "#67A9CF",
    "Federal Aid Fee (Placebo)" = "#999999"
  )

  p2 <- ggplot(es_plot[!is.na(Component)],
               aes(x = event_time, y = estimate, color = Component, fill = Component)) +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, color = NA) +
    geom_line(linewidth = 0.8) +
    geom_point(size = 1.2) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "gray30") +
    facet_wrap(~Component, scales = "free_y", ncol = 2) +
    scale_color_manual(values = color_map) +
    scale_fill_manual(values = color_map) +
    labs(x = "Years Since Energy Law Reform",
         y = "Effect (Rp/kWh)") +
    theme(legend.position = "none",
          strip.text = element_text(size = 8, face = "bold"))

  ggsave(file.path(fig_dir, "fig2_event_study.pdf"), p2, width = 8, height = 7)
  cat("  Saved fig2_event_study.pdf\n")
}

# ===========================================================================
# Figure 3: Spatial RDD — Tariff discontinuity at borders
# ===========================================================================
cat("=== Figure 3: Spatial RDD plot ===\n")

# Create binned means by distance to border
reform_dates <- fread(file.path(data_dir, "reform_dates.csv"))
reform_cantons_vec <- reform_dates$canton

rdd_data <- panel[dist_to_border_km <= 20 & !is.na(border_pair)]
rdd_data[, signed_dist := fifelse(canton %in% reform_cantons_vec, dist_to_border_km, -dist_to_border_km)]

# Residualize against year FE to remove temporal composition effects
# This ensures the binscatter shows spatial discontinuity, not time trends
for (v in c("charge", "total", "aidfee")) {
  yr_means <- rdd_data[, .(yr_mean = mean(get(v), na.rm = TRUE)), by = year]
  grand_mean <- mean(rdd_data[[v]], na.rm = TRUE)
  rdd_data <- merge(rdd_data, yr_means, by = "year", all.x = TRUE)
  rdd_data[, paste0(v, "_resid") := get(v) - yr_mean + grand_mean]
  rdd_data[, yr_mean := NULL]
}

# Bin signed distance into 1km bins
rdd_data[, dist_bin := round(signed_dist)]

# Compute bin means using year-residualized values
bin_means <- rdd_data[, .(
  mean_charge = mean(charge_resid, na.rm = TRUE),
  mean_total = mean(total_resid, na.rm = TRUE),
  mean_aidfee = mean(aidfee_resid, na.rm = TRUE),
  se_charge = sd(charge_resid, na.rm = TRUE) / sqrt(.N),
  se_total = sd(total_resid, na.rm = TRUE) / sqrt(.N),
  n = .N
), by = dist_bin]

fwrite(bin_means, file.path(data_dir, "rdd_bin_means.csv"))

if (nrow(bin_means) > 5) {
  # Panel A: Charges component
  p3a <- ggplot(bin_means, aes(x = dist_bin, y = mean_charge)) +
    geom_point(aes(size = n), alpha = 0.6, color = "#B2182B") +
    geom_smooth(data = bin_means[dist_bin < 0], method = "lm", se = TRUE,
                color = "#2166AC", fill = "#D1E5F0") +
    geom_smooth(data = bin_means[dist_bin >= 0], method = "lm", se = TRUE,
                color = "#B2182B", fill = "#FDDBC7") +
    geom_vline(xintercept = 0, linetype = "dashed") +
    scale_size_continuous(range = c(1, 4), guide = "none") +
    labs(x = "Distance to Border (km, positive = reform canton)",
         y = "Cantonal/Municipal Charges (Rp/kWh)",
         title = "A. Charges Component at Cantonal Borders")

  # Panel B: Federal aid fee (placebo)
  p3b <- ggplot(bin_means, aes(x = dist_bin, y = mean_aidfee)) +
    geom_point(aes(size = n), alpha = 0.6, color = "#999999") +
    geom_smooth(data = bin_means[dist_bin < 0], method = "lm", se = TRUE,
                color = "#666666", fill = "#CCCCCC") +
    geom_smooth(data = bin_means[dist_bin >= 0], method = "lm", se = TRUE,
                color = "#666666", fill = "#CCCCCC") +
    geom_vline(xintercept = 0, linetype = "dashed") +
    scale_size_continuous(range = c(1, 4), guide = "none") +
    labs(x = "Distance to Border (km, positive = reform canton)",
         y = "Federal Aid Fee (Rp/kWh)",
         title = "B. Federal Aid Fee (Placebo) at Cantonal Borders")

  fig3 <- p3a / p3b
  ggsave(file.path(fig_dir, "fig3_rdd_discontinuity.pdf"), fig3, width = 7, height = 9)
  cat("  Saved fig3_rdd_discontinuity.pdf\n")
}

# ===========================================================================
# Figure 4: Border-pair-specific estimates
# ===========================================================================
cat("=== Figure 4: Border-pair estimates ===\n")

bp_est <- tryCatch(fread(file.path(data_dir, "border_pair_estimates.csv")), error = function(e) NULL)

if (!is.null(bp_est) && nrow(bp_est) > 0) {
  bp_est[, ci_lo := did_coef - 1.96 * did_se]
  bp_est[, ci_hi := did_coef + 1.96 * did_se]

  p4 <- ggplot(bp_est[order(did_coef)],
               aes(x = reorder(border_pair, did_coef), y = did_coef)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi), size = 0.3, color = "#B2182B") +
    coord_flip() +
    labs(x = "", y = "DiD Estimate: Reform Effect on Charges (Rp/kWh)",
         title = "Border-Pair-Specific Estimates of Energy Law Reform Effect") +
    theme(axis.text.y = element_text(size = 7))

  ggsave(file.path(fig_dir, "fig4_border_pair_estimates.pdf"), p4,
         width = 7, height = max(5, nrow(bp_est) * 0.3))
  cat("  Saved fig4_border_pair_estimates.pdf\n")
}

# ===========================================================================
# Figure 5: Bandwidth sensitivity
# ===========================================================================
cat("=== Figure 5: Bandwidth sensitivity ===\n")

bw_data <- tryCatch(fread(file.path(data_dir, "robustness_bandwidth.csv")), error = function(e) NULL)

if (!is.null(bw_data) && nrow(bw_data) > 0) {
  bw_data[, ci_lo := coef - 1.96 * se]
  bw_data[, ci_hi := coef + 1.96 * se]

  p5 <- ggplot(bw_data[component == "charge"],
               aes(x = bandwidth_km, y = coef)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#B2182B") +
    geom_line(color = "#B2182B", linewidth = 0.8) +
    geom_point(color = "#B2182B", size = 2) +
    labs(x = "Bandwidth (km)", y = "Reform Effect on Charges (Rp/kWh)",
         title = "Bandwidth Sensitivity: Charges Component") +
    scale_x_continuous(breaks = c(5, 10, 15, 20, 30))

  ggsave(file.path(fig_dir, "fig5_bandwidth_sensitivity.pdf"), p5, width = 6, height = 4)
  cat("  Saved fig5_bandwidth_sensitivity.pdf\n")
}

# ===========================================================================
# Figure 6: Variance decomposition
# ===========================================================================
cat("=== Figure 6: Variance decomposition ===\n")

var_data <- tryCatch(fread(file.path(data_dir, "variance_decomposition.csv")), error = function(e) NULL)

if (!is.null(var_data) && nrow(var_data) > 0) {
  var_long <- data.table(
    Component = c("Energy", "Grid", "Federal Aid", "Charges"),
    Share = c(var_data$share_energy, var_data$share_grid,
              var_data$share_aidfee, var_data$share_charge)
  )
  var_long[, Component := factor(Component, levels = Component[order(-Share)])]

  p6 <- ggplot(var_long, aes(x = Component, y = Share * 100, fill = Component)) +
    geom_col(alpha = 0.85) +
    geom_text(aes(label = paste0(round(Share * 100, 1), "%")), vjust = -0.5, size = 3.5) +
    scale_fill_manual(values = c("Energy" = "#2166AC", "Grid" = "#67A9CF",
                                  "Federal Aid" = "#D1E5F0", "Charges" = "#B2182B")) +
    labs(x = "", y = "Share of Total Tariff Variance (%)",
         title = "What Drives Electricity Price Variation?") +
    theme(legend.position = "none") +
    ylim(0, max(var_long$Share * 100) * 1.15)

  ggsave(file.path(fig_dir, "fig6_variance_decomposition.pdf"), p6, width = 6, height = 4.5)
  cat("  Saved fig6_variance_decomposition.pdf\n")
}

cat("\n=== All figures generated ===\n")
