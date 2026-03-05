#' 05_figures.R — Generate all figures
#' Publication-quality exhibits for APEP-0517

source("00_packages.R")

DATA_DIR <- "../data"
FIG_DIR <- "../figures"
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)

# ===================================================================
# Figure 1: Officer change heatmap by force
# ===================================================================
cat("=== Figure 1: Officer changes by force ===\n")

wf_change <- fread(file.path(DATA_DIR, "workforce_change.csv"))

if (nrow(wf_change) > 0) {
  fig1_data <- wf_change[order(pct_change)]
  fig1_data[, force := factor(force, levels = force)]

  p1 <- ggplot(fig1_data, aes(x = pct_change, y = force,
                                fill = pct_change)) +
    geom_col() +
    scale_fill_gradient2(low = "#D55E00", mid = "grey90", high = "#009E73",
                         midpoint = 0, name = "% Change") +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
    labs(
      title = "Police Officer Changes by Force, 2010-2018",
      subtitle = "Percentage change in officer numbers during austerity period",
      x = "Change in Officers (%)",
      y = NULL,
      caption = "Source: Home Office Police Workforce Statistics"
    ) +
    theme_apep() +
    theme(legend.position = "none",
          axis.text.y = element_text(size = 7))

  ggsave(file.path(FIG_DIR, "fig1_officer_changes.pdf"), p1,
         width = 8, height = 10, device = cairo_pdf)
  cat("  Saved fig1_officer_changes.pdf\n")
}

# ===================================================================
# Figure 2: RDD plot — Total crime at boundary
# ===================================================================
cat("\n=== Figure 2: RDD plot ===\n")

bdd_panel <- fread(file.path(DATA_DIR, "bdd_panel.csv"))

if (nrow(bdd_panel) > 0) {
  # Post-austerity period
  bdd_post <- bdd_panel[year >= 2015 & year <= 2023 &
                          !is.na(signed_dist_km) & !is.na(log_total_crime)]

  # Bin the data for visualization
  bdd_post[, dist_bin := round(signed_dist_km * 2) / 2]  # 0.5km bins
  bin_means <- bdd_post[abs(dist_bin) <= 10,
    .(mean_crime = mean(log_total_crime, na.rm = TRUE),
      se_crime = sd(log_total_crime, na.rm = TRUE) / sqrt(.N),
      n = .N),
    by = dist_bin]

  p2 <- ggplot(bin_means, aes(x = dist_bin, y = mean_crime)) +
    geom_point(aes(size = n), alpha = 0.6, color = "grey40") +
    geom_smooth(data = bin_means[dist_bin < 0],
                method = "lm", formula = y ~ poly(x, 2),
                color = apep_colors[2], fill = apep_colors[2], alpha = 0.15,
                se = TRUE) +
    geom_smooth(data = bin_means[dist_bin >= 0],
                method = "lm", formula = y ~ poly(x, 2),
                color = apep_colors[1], fill = apep_colors[1], alpha = 0.15,
                se = TRUE) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "red", linewidth = 0.8) +
    scale_size_continuous(range = c(1, 4), guide = "none") +
    labs(
      title = "Crime at Police Force Boundaries",
      subtitle = "Post-austerity period (2015-2023). Positive distance = high-cut force side.",
      x = "Signed Distance to PFA Boundary (km)",
      y = "Log(Total Crime + 1)",
      caption = "Source: data.police.uk. Bins = 0.5km. Fitted: local quadratic."
    ) +
    theme_apep() +
    annotate("text", x = -5, y = max(bin_means$mean_crime, na.rm = TRUE),
             label = "Low-cut side", color = apep_colors[2], fontface = "bold", size = 4) +
    annotate("text", x = 5, y = max(bin_means$mean_crime, na.rm = TRUE),
             label = "High-cut side", color = apep_colors[1], fontface = "bold", size = 4)

  ggsave(file.path(FIG_DIR, "fig2_rdd_plot.pdf"), p2,
         width = 8, height = 5.5, device = cairo_pdf)
  cat("  Saved fig2_rdd_plot.pdf\n")
}

# ===================================================================
# Figure 3: Event study — RDD coefficient by year
# ===================================================================
cat("\n=== Figure 3: Event study ===\n")

event_file <- file.path(DATA_DIR, "rdd_event_study.csv")
if (file.exists(event_file)) {
  event_dt <- fread(event_file)

  if (nrow(event_dt) > 0) {
    p3 <- ggplot(event_dt, aes(x = year, y = coef)) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
      geom_vline(xintercept = 2012.5, linetype = "dotted", color = "red",
                 linewidth = 0.6) +
      geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
                  fill = apep_colors[1], alpha = 0.2) +
      geom_line(color = apep_colors[1], linewidth = 0.8) +
      geom_point(color = apep_colors[1], size = 2.5) +
      annotate("text", x = 2012, y = max(event_dt$ci_upper, na.rm = TRUE) * 0.9,
               label = "Austerity\nbegins", color = "red", size = 3,
               fontface = "italic", hjust = 1) +
      labs(
        title = "Boundary Discontinuity Over Time",
        subtitle = "Year-specific RDD estimates of log crime at PFA boundaries",
        x = "Year",
        y = "RDD Coefficient (log crime)",
        caption = "Source: data.police.uk. MSE-optimal bandwidth, triangular kernel."
      ) +
      theme_apep() +
      scale_x_continuous(breaks = seq(2011, 2024, 2))

    ggsave(file.path(FIG_DIR, "fig3_event_study.pdf"), p3,
           width = 8, height = 5, device = cairo_pdf)
    cat("  Saved fig3_event_study.pdf\n")
  }
}

# ===================================================================
# Figure 4: Crime type decomposition
# ===================================================================
cat("\n=== Figure 4: Crime type decomposition ===\n")

type_file <- file.path(DATA_DIR, "rdd_by_crime_type.csv")
if (file.exists(type_file)) {
  type_dt <- fread(type_file)

  # Drop rows with NA p-values or zero SE (failed estimation)
  type_dt <- type_dt[!is.na(p_value) & se > 0]

  if (nrow(type_dt) > 0) {
    # Clean outcome names for display
    type_dt[, crime_label := gsub("^log_", "", outcome)]
    type_dt[, crime_label := gsub("_", " ", crime_label)]
    type_dt[, crime_label := tools::toTitleCase(crime_label)]

    type_dt[, ci_lower := coef - 1.96 * se]
    type_dt[, ci_upper := coef + 1.96 * se]
    type_dt[, sig := p_value < 0.05]

    # Order by coefficient
    type_dt <- type_dt[order(coef)]
    type_dt[, crime_label := factor(crime_label, levels = crime_label)]

    p4 <- ggplot(type_dt, aes(x = coef, y = crime_label)) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "grey60") +
      geom_errorbarh(aes(xmin = ci_lower, xmax = ci_upper),
                     height = 0.2, color = "grey50") +
      geom_point(aes(color = sig), size = 3) +
      scale_color_manual(values = c("TRUE" = apep_colors[1],
                                     "FALSE" = "grey60"),
                          labels = c("TRUE" = "p < 0.05",
                                     "FALSE" = "p >= 0.05"),
                          name = "Significance") +
      labs(
        title = "Crime Type Decomposition at PFA Boundaries",
        subtitle = "RDD coefficients by crime category (2015-2023)",
        x = "RDD Coefficient (log crime)",
        y = NULL,
        caption = "Fixed 2km bandwidth, triangular kernel, clustered by boundary pair."
      ) +
      theme_apep()

    ggsave(file.path(FIG_DIR, "fig4_crime_types.pdf"), p4,
           width = 8, height = 6, device = cairo_pdf)
    cat("  Saved fig4_crime_types.pdf\n")
  }
}

# ===================================================================
# Figure 5: Bandwidth sensitivity
# ===================================================================
cat("\n=== Figure 5: Bandwidth sensitivity ===\n")

bw_file <- file.path(DATA_DIR, "bandwidth_sensitivity.csv")
if (file.exists(bw_file)) {
  bw_dt <- fread(bw_file)

  if (nrow(bw_dt) > 0) {
    bw_dt[, ci_lower := coef - 1.96 * se]
    bw_dt[, ci_upper := coef + 1.96 * se]
    bw_dt[, optimal := bw_multiplier == 1.0]

    p5 <- ggplot(bw_dt, aes(x = bandwidth_km, y = coef)) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
      geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
                  fill = apep_colors[1], alpha = 0.2) +
      geom_line(color = apep_colors[1], linewidth = 0.8) +
      geom_point(aes(shape = optimal, size = optimal), color = apep_colors[1]) +
      scale_shape_manual(values = c("TRUE" = 18, "FALSE" = 16), guide = "none") +
      scale_size_manual(values = c("TRUE" = 4, "FALSE" = 2.5), guide = "none") +
      labs(
        title = "Bandwidth Sensitivity",
        subtitle = "RDD coefficient for total crime across bandwidth choices",
        x = "Bandwidth (km)",
        y = "RDD Coefficient",
        caption = "Diamond = MSE-optimal bandwidth. Triangular kernel."
      ) +
      theme_apep()

    ggsave(file.path(FIG_DIR, "fig5_bandwidth.pdf"), p5,
           width = 7, height = 5, device = cairo_pdf)
    cat("  Saved fig5_bandwidth.pdf\n")
  }
}

# ===================================================================
# Figure 6: McCrary density plot
# ===================================================================
cat("\n=== Figure 6: McCrary density ===\n")

if (nrow(bdd_panel) > 0) {
  bdd_latest <- bdd_panel[year == max(year) & !is.na(signed_dist_km)]

  if (nrow(bdd_latest) > 100) {
    density_est <- rddensity(bdd_latest$signed_dist_km, c = 0)
    pdf(file.path(FIG_DIR, "fig6_mccrary.pdf"), width = 7, height = 5)
    rdplotdensity(density_est, bdd_latest$signed_dist_km,
                  title = "McCrary Density Test at PFA Boundary",
                  xlabel = "Signed Distance to Boundary (km)",
                  ylabel = "Density")
    dev.off()
    cat("  Saved fig6_mccrary.pdf\n")
  }
}

cat("\n=== All figures generated ===\n")
