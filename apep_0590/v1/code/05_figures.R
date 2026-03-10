## =============================================================================
## 05_figures.R — apep_0590
## All figures for the paper
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

# Color palette
cols <- c(
  "Cohort 2019" = "#E63946",
  "Cohort 2020" = "#457B9D",
  "Cohort 2021" = "#2A9D8F",
  "Never treated" = "#6C757D"
)

# =============================================================================
# Figure 1: Treatment Rollout Map
# =============================================================================
cat("Figure 1: Treatment rollout map\n")

panel <- fread(file.path(data_dir, "clean_panel.csv"))
muni_sf <- readRDS(file.path(data_dir, "gadm_mex_2.rds"))

# Merge treatment info
muni_treat <- panel[year == 2019, .(GID_2, first_treat, NAME_1)]
muni_sf <- merge(muni_sf, muni_treat, by = "GID_2", all.x = TRUE)
muni_sf$cohort_label <- ifelse(
  is.na(muni_sf$first_treat) | muni_sf$first_treat == 0,
  "Never treated",
  paste0("Cohort ", muni_sf$first_treat)
)
muni_sf$cohort_label <- factor(muni_sf$cohort_label,
  levels = c("Cohort 2019", "Cohort 2020", "Cohort 2021", "Never treated"))

p1 <- ggplot(muni_sf) +
  geom_sf(aes(fill = cohort_label), color = NA, linewidth = 0.01) +
  scale_fill_manual(values = cols, name = NULL, na.value = "#E0E0E0") +
  labs(
    title = "Sembrando Vida Program Rollout by Municipality",
    subtitle = "Treatment cohorts based on state-level program introduction year"
  ) +
  theme_apep() +
  theme(
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank(),
    legend.position = "bottom"
  )

ggsave(file.path(fig_dir, "fig1_treatment_map.pdf"), p1,
       width = 10, height = 6.5, device = cairo_pdf)
ggsave(file.path(fig_dir, "fig1_treatment_map.png"), p1,
       width = 10, height = 6.5, dpi = 300)

# =============================================================================
# Figure 2: Cohort Average Outcomes Over Time
# =============================================================================
cat("Figure 2: Cohort means over time\n")

cohort_means <- fread(file.path(data_dir, "cohort_means.csv"))

p2 <- ggplot(cohort_means, aes(x = year, y = mean_asinh_loss, color = cohort)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_vline(xintercept = c(2019, 2020, 2021),
             linetype = "dashed", alpha = 0.4, color = "grey40") +
  annotate("text", x = 2019.2, y = max(cohort_means$mean_asinh_loss) * 0.95,
           label = "SV\n2019", size = 2.5, hjust = 0, color = "grey40") +
  scale_color_manual(values = cols, name = NULL) +
  labs(
    x = "Year",
    y = "Mean asinh(tree cover loss, ha)",
    title = "Average Tree Cover Loss by Treatment Cohort",
    subtitle = "Vertical lines mark program introduction years"
  ) +
  theme_apep()

ggsave(file.path(fig_dir, "fig2_cohort_means.pdf"), p2,
       width = 8, height = 5, device = cairo_pdf)
ggsave(file.path(fig_dir, "fig2_cohort_means.png"), p2,
       width = 8, height = 5, dpi = 300)

# =============================================================================
# Figure 3: Main Event Study (Primary Result)
# =============================================================================
cat("Figure 3: Event study (asinh)\n")

es <- fread(file.path(data_dir, "event_study_asinh.csv"))

p3 <- ggplot(es, aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey70") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15, fill = "#E63946") +
  geom_line(color = "#E63946", linewidth = 0.8) +
  geom_point(color = "#E63946", size = 2.5) +
  labs(
    x = "Years Relative to Sembrando Vida Introduction",
    y = "ATT: asinh(tree cover loss, ha)",
    title = "Dynamic Treatment Effects of Sembrando Vida on Deforestation",
    subtitle = "Callaway-Sant'Anna estimator, never-treated controls, 95% CI"
  ) +
  scale_x_continuous(breaks = seq(-10, 5, 2)) +
  theme_apep()

ggsave(file.path(fig_dir, "fig3_event_study.pdf"), p3,
       width = 8, height = 5.5, device = cairo_pdf)
ggsave(file.path(fig_dir, "fig3_event_study.png"), p3,
       width = 8, height = 5.5, dpi = 300)

# =============================================================================
# Figure 4: Event Study in Levels (Hectares)
# =============================================================================
cat("Figure 4: Event study (levels)\n")

es_level <- fread(file.path(data_dir, "event_study_level.csv"))

p4 <- ggplot(es_level, aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey70") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15, fill = "#457B9D") +
  geom_line(color = "#457B9D", linewidth = 0.8) +
  geom_point(color = "#457B9D", size = 2.5) +
  labs(
    x = "Years Relative to Sembrando Vida Introduction",
    y = "ATT: Tree Cover Loss (hectares)",
    title = "Dynamic Treatment Effects on Tree Cover Loss (Level)",
    subtitle = "Callaway-Sant'Anna estimator, never-treated controls, 95% CI"
  ) +
  scale_x_continuous(breaks = seq(-10, 5, 2)) +
  theme_apep()

ggsave(file.path(fig_dir, "fig4_event_study_level.pdf"), p4,
       width = 8, height = 5.5, device = cairo_pdf)
ggsave(file.path(fig_dir, "fig4_event_study_level.png"), p4,
       width = 8, height = 5.5, dpi = 300)

# =============================================================================
# Figure 5: Heterogeneity by Ecosystem
# =============================================================================
cat("Figure 5: Ecosystem heterogeneity\n")

eco <- fread(file.path(data_dir, "heterogeneity_ecosystem.csv"))

p5 <- ggplot(eco, aes(x = reorder(ecosystem, att), y = att)) +
  geom_hline(yintercept = 0, color = "grey50", linewidth = 0.5) +
  geom_pointrange(aes(ymin = att - 1.96 * se, ymax = att + 1.96 * se),
                  color = "#2A9D8F", size = 0.8) +
  coord_flip() +
  labs(
    x = NULL,
    y = "ATT: asinh(tree cover loss, ha)",
    title = "Treatment Effects by Ecosystem Type",
    subtitle = "Callaway-Sant'Anna estimates with 95% CI"
  ) +
  theme_apep()

ggsave(file.path(fig_dir, "fig5_ecosystem_heterogeneity.pdf"), p5,
       width = 7, height = 4.5, device = cairo_pdf)
ggsave(file.path(fig_dir, "fig5_ecosystem_heterogeneity.png"), p5,
       width = 7, height = 4.5, dpi = 300)

# =============================================================================
# Figure 6: Leave-One-State-Out
# =============================================================================
cat("Figure 6: Leave-one-state-out\n")

loo <- fread(file.path(data_dir, "leave_one_state_out.csv"))
main_att <- fread(file.path(data_dir, "main_results_summary.csv"))
main_est <- main_att[specification == "CS-DiD asinh(loss)", estimate]

p6 <- ggplot(loo, aes(x = reorder(excluded_state, att), y = att)) +
  geom_hline(yintercept = main_est, color = "#E63946", linetype = "dashed",
             linewidth = 0.5) +
  geom_pointrange(aes(ymin = att - 1.96 * se, ymax = att + 1.96 * se),
                  color = "#457B9D", size = 0.4) +
  coord_flip() +
  labs(
    x = "Excluded State",
    y = "ATT: asinh(tree cover loss, ha)",
    title = "Leave-One-State-Out Sensitivity",
    subtitle = "Red dashed line = full-sample estimate"
  ) +
  theme_apep(base_size = 9)

ggsave(file.path(fig_dir, "fig6_leave_one_out.pdf"), p6,
       width = 7, height = 8, device = cairo_pdf)
ggsave(file.path(fig_dir, "fig6_leave_one_out.png"), p6,
       width = 7, height = 8, dpi = 300)

# =============================================================================
# Figure 7: Placebo Event Study
# =============================================================================
cat("Figure 7: Placebo event study\n")

if (file.exists(file.path(data_dir, "placebo_event_study.csv"))) {
  placebo <- fread(file.path(data_dir, "placebo_event_study.csv"))

  p7 <- ggplot(placebo, aes(x = event_time, y = att)) +
    geom_hline(yintercept = 0, color = "grey50", linewidth = 0.5) +
    geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey70") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15, fill = "#6C757D") +
    geom_line(color = "#6C757D", linewidth = 0.8) +
    geom_point(color = "#6C757D", size = 2.5) +
    labs(
      x = "Years Relative to Placebo Treatment",
      y = "ATT: asinh(tree cover loss, ha)",
      title = "Placebo Test: Fake Treatment 4 Years Before Actual",
      subtitle = "No significant pre-treatment effects expected"
    ) +
    theme_apep()

  ggsave(file.path(fig_dir, "fig7_placebo.pdf"), p7,
         width = 8, height = 5.5, device = cairo_pdf)
  ggsave(file.path(fig_dir, "fig7_placebo.png"), p7,
         width = 8, height = 5.5, dpi = 300)
}

# =============================================================================
# Figure 8: Bacon Decomposition
# =============================================================================
cat("Figure 8: Bacon decomposition\n")

if (file.exists(file.path(data_dir, "bacon_decomposition.csv"))) {
  bacon <- fread(file.path(data_dir, "bacon_decomposition.csv"))

  p8 <- ggplot(bacon, aes(x = weight, y = estimate, color = type)) +
    geom_hline(yintercept = 0, color = "grey50") +
    geom_point(alpha = 0.7, size = 2) +
    scale_color_brewer(palette = "Set2", name = "Comparison Type") +
    labs(
      x = "Weight",
      y = "2x2 DiD Estimate",
      title = "Goodman-Bacon Decomposition of TWFE Estimate",
      subtitle = "Each point is a 2×2 comparison; size reflects weight in TWFE"
    ) +
    theme_apep()

  ggsave(file.path(fig_dir, "fig8_bacon.pdf"), p8,
         width = 8, height = 5, device = cairo_pdf)
  ggsave(file.path(fig_dir, "fig8_bacon.png"), p8,
         width = 8, height = 5, dpi = 300)
}

cat("\nAll figures generated.\n")
