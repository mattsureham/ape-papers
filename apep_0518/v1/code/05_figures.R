## =============================================================================
## 05_figures.R — All figures for the paper
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

## ---- Figure 1: Event Study Plot ----
cat("=== Figure 1: Event Study ===\n")

es_coefs <- fread(file.path(data_dir, "event_study_coefs.csv"))

fig1 <- ggplot(es_coefs, aes(x = rel_year, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
  geom_vline(xintercept = -0.5, color = "grey70", linetype = "dotted") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#E63946") +
  geom_point(size = 2.5, color = "#E63946") +
  geom_line(color = "#E63946", linewidth = 0.6) +
  annotate("text", x = -3, y = max(es_coefs$ci_hi, na.rm = TRUE) * 0.9,
           label = "Pre-treatment", hjust = 0, size = 3.5, color = "grey40") +
  annotate("text", x = 2, y = max(es_coefs$ci_hi, na.rm = TRUE) * 0.9,
           label = "Post-treatment", hjust = 0, size = 3.5, color = "grey40") +
  labs(
    x = "Years Relative to QPV Redesignation (2015)",
    y = "Effect on Firm Creation (establishments/year)",
    title = "Effect of Losing Priority Neighborhood Status on Firm Creation",
    subtitle = "Event study: lost-status ZUS vs. kept-status (ZUS→QPV), excluding ZFU"
  ) +
  scale_x_continuous(breaks = seq(-5, 9, 1)) +
  theme(plot.title = element_text(size = 12))

ggsave(file.path(fig_dir, "fig1_event_study.pdf"), fig1, width = 8, height = 5)
ggsave(file.path(fig_dir, "fig1_event_study.png"), fig1, width = 8, height = 5, dpi = 300)
cat("Figure 1 saved.\n")

## ---- Figure 2: Event Study (Log) ----
cat("=== Figure 2: Event Study (Log) ===\n")

es_log_coefs <- fread(file.path(data_dir, "event_study_log_coefs.csv"))

fig2 <- ggplot(es_log_coefs, aes(x = rel_year, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
  geom_vline(xintercept = -0.5, color = "grey70", linetype = "dotted") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#457B9D") +
  geom_point(size = 2.5, color = "#457B9D") +
  geom_line(color = "#457B9D", linewidth = 0.6) +
  labs(
    x = "Years Relative to QPV Redesignation (2015)",
    y = "Effect on Log(Firm Creation + 1)",
    title = "Effect on Log Firm Creation",
    subtitle = "Event study: lost-status ZUS vs. kept-status (ZUS→QPV), excluding ZFU"
  ) +
  scale_x_continuous(breaks = seq(-5, 9, 1))

ggsave(file.path(fig_dir, "fig2_event_study_log.pdf"), fig2, width = 8, height = 5)
ggsave(file.path(fig_dir, "fig2_event_study_log.png"), fig2, width = 8, height = 5, dpi = 300)
cat("Figure 2 saved.\n")

## ---- Figure 3: Raw Trends ----
cat("=== Figure 3: Raw Trends ===\n")

panel_nozfu <- fread(file.path(data_dir, "panel_nozfu.csv"))

trends <- panel_nozfu[, .(mean_firms = mean(n_firms_created)),
                       by = .(year, Group = fifelse(lost_status == 1,
                                                     "Lost Status", "Kept Status"))]

fig3 <- ggplot(trends, aes(x = year, y = mean_firms, color = Group)) +
  geom_vline(xintercept = 2014.5, color = "grey70", linetype = "dotted", linewidth = 0.8) +
  geom_point(size = 2) +
  geom_line(linewidth = 0.8) +
  scale_color_manual(values = c("Lost Status" = "#E63946", "Kept Status" = "#457B9D")) +
  annotate("text", x = 2014.5, y = max(trends$mean_firms) * 1.05,
           label = "QPV\nRedesignation", hjust = 0.5, size = 3, color = "grey40") +
  labs(
    x = "Year",
    y = "Mean Firm Creations per Neighborhood",
    title = "Firm Creation Trends: Lost vs. Kept Priority Status",
    subtitle = "Former ZUS neighborhoods, excluding ZFU"
  )

ggsave(file.path(fig_dir, "fig3_raw_trends.pdf"), fig3, width = 8, height = 5)
ggsave(file.path(fig_dir, "fig3_raw_trends.png"), fig3, width = 8, height = 5, dpi = 300)
cat("Figure 3 saved.\n")

## ---- Figure 4: Threshold Sensitivity ----
cat("=== Figure 4: Threshold Sensitivity ===\n")

if (file.exists(file.path(data_dir, "threshold_sensitivity.csv"))) {
  thresh_dt <- fread(file.path(data_dir, "threshold_sensitivity.csv"))

  fig4 <- ggplot(thresh_dt[kept_threshold == 0.50],
                 aes(x = lost_threshold, y = coef)) +
    geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
    geom_pointrange(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
                    color = "#E63946", size = 0.5) +
    labs(
      x = "Lost-Status Overlap Threshold",
      y = "DiD Coefficient",
      title = "Sensitivity to Overlap Threshold Definition",
      subtitle = "Kept-status threshold fixed at 50%"
    )

  ggsave(file.path(fig_dir, "fig4_threshold_sensitivity.pdf"), fig4, width = 7, height = 5)
  ggsave(file.path(fig_dir, "fig4_threshold_sensitivity.png"), fig4, width = 7, height = 5, dpi = 300)
  cat("Figure 4 saved.\n")
} else {
  cat("Threshold sensitivity data not found. Skipping Figure 4.\n")
}

## ---- Figure 5: Dynamic Effects ----
cat("=== Figure 5: Dynamic Effects ===\n")

if (file.exists(file.path(data_dir, "dynamic_effects.csv"))) {
  dyn_dt <- fread(file.path(data_dir, "dynamic_effects.csv"))
  dyn_dt[, period_f := factor(period, levels = c("Short (2015-17)", "Medium (2018-20)", "Long (2021-24)"))]

  fig5 <- ggplot(dyn_dt, aes(x = period_f, y = coef)) +
    geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
    geom_pointrange(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
                    color = "#E63946", size = 0.8) +
    labs(
      x = "Post-Treatment Period",
      y = "DiD Coefficient",
      title = "Dynamic Treatment Effects",
      subtitle = "Short-run, medium-run, and long-run effects of losing priority status"
    )

  ggsave(file.path(fig_dir, "fig5_dynamic_effects.pdf"), fig5, width = 7, height = 5)
  ggsave(file.path(fig_dir, "fig5_dynamic_effects.png"), fig5, width = 7, height = 5, dpi = 300)
  cat("Figure 5 saved.\n")
}

## ---- Figure 6: Placebo Tests ----
cat("=== Figure 6: Placebo Tests ===\n")

if (file.exists(file.path(data_dir, "placebo_timing.csv"))) {
  placebo_dt <- fread(file.path(data_dir, "placebo_timing.csv"))
  main_result <- fread(file.path(data_dir, "did_static_results.csv"))

  all_tests <- rbind(
    placebo_dt[, .(test, coef, se)],
    data.table(test = "Actual (2015)", coef = main_result[specification == "Levels", coef],
               se = main_result[specification == "Levels", se])
  )
  all_tests[, is_actual := test == "Actual (2015)"]

  fig6 <- ggplot(all_tests, aes(x = test, y = coef, color = is_actual)) +
    geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
    geom_pointrange(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se), size = 0.8) +
    scale_color_manual(values = c("FALSE" = "grey50", "TRUE" = "#E63946"), guide = "none") +
    labs(
      x = "",
      y = "DiD Coefficient",
      title = "Placebo Timing Tests",
      subtitle = "Placebo treatments at 2012 and 2013 vs. actual treatment at 2015"
    )

  ggsave(file.path(fig_dir, "fig6_placebo.pdf"), fig6, width = 7, height = 5)
  ggsave(file.path(fig_dir, "fig6_placebo.png"), fig6, width = 7, height = 5, dpi = 300)
  cat("Figure 6 saved.\n")
}

cat("\nAll figures generated.\n")
