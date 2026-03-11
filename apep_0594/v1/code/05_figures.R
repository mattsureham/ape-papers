## 05_figures.R — Generate all figures
## apep_0594: Spain's 2022 Temporary Contract Ban

source("00_packages.R")

cat("=== Generating Figures ===\n")

# Load data
dt <- fread(file.path(data_dir, "analysis_panel.csv"))
dt_national <- fread(file.path(data_dir, "national_aggregates.csv"))
dt_sector <- fread(file.path(data_dir, "sector_panel.csv"))
es_coefs <- fread(file.path(data_dir, "event_study_coefs.csv"))
es_perm_coefs <- fread(file.path(data_dir, "event_study_perm_coefs.csv"))
es_emp_coefs <- fread(file.path(data_dir, "event_study_emp_coefs.csv"))
loo_dt <- fread(file.path(data_dir, "loo_results.csv"))
ri_dist <- fread(file.path(data_dir, "ri_distribution.csv"))
ri_results <- fread(file.path(data_dir, "ri_results.csv"))
alt_specs <- fread(file.path(data_dir, "robustness_alt_specs.csv"))

# Reform line helper
reform_vline <- geom_vline(xintercept = -0.5, linetype = "dashed",
                           color = "red", linewidth = 0.5)

# =============================================================================
# FIGURE 1: National temporary employment share over time
# =============================================================================

cat("Figure 1: National trends\n")

dt_national[, date_num := year + (quarter - 1) / 4]

fig1 <- ggplot(dt_national, aes(x = date_num)) +
  geom_line(aes(y = nat_temp_share, color = "Temporary"), linewidth = 0.8) +
  geom_line(aes(y = nat_perm_share, color = "Permanent"), linewidth = 0.8) +
  geom_vline(xintercept = 2022.25, linetype = "dashed", color = "red",
             linewidth = 0.5) +
  annotate("text", x = 2022.25, y = 0.82, label = "Reform\n(2022Q2)",
           hjust = -0.1, size = 3, color = "red") +
  scale_color_manual(values = c("Temporary" = "#E74C3C", "Permanent" = "#2980B9"),
                     name = NULL) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    title = "Contract Composition of Spanish Wage Earners, 2010\u20132025",
    subtitle = "Share of total wage earners by contract type",
    x = NULL, y = "Share of Wage Earners"
  ) +
  theme(legend.position = c(0.8, 0.5))

ggsave(file.path(fig_dir, "fig1_national_trends.pdf"), fig1,
       width = 8, height = 5)

# =============================================================================
# FIGURE 2: Pre-reform temporary share by region (treatment intensity)
# =============================================================================

cat("Figure 2: Treatment intensity\n")

pre_reform <- fread(file.path(data_dir, "pre_reform_treatment.csv"))
pre_reform[, region_short := str_replace(region, ", .*$", "")]

fig2 <- ggplot(pre_reform[order(pre_temp_share)],
               aes(x = reorder(region_short, pre_temp_share),
                   y = pre_temp_share)) +
  geom_col(fill = "#3498DB", alpha = 0.8) +
  geom_hline(yintercept = mean(pre_reform$pre_temp_share),
             linetype = "dashed", color = "gray40") +
  annotate("text", x = 3, y = mean(pre_reform$pre_temp_share) + 0.01,
           label = "Mean", size = 3, color = "gray40") +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  coord_flip() +
  labs(
    title = "Pre-Reform Temporary Employment Share by Region (2021 Average)",
    subtitle = "Treatment intensity for the shift-share DiD design",
    x = NULL, y = "Temporary Employment Share"
  )

ggsave(file.path(fig_dir, "fig2_treatment_intensity.pdf"), fig2,
       width = 8, height = 6)

# =============================================================================
# FIGURE 3: Event study — temporary share
# =============================================================================

cat("Figure 3: Event study\n")

es_plot <- es_coefs[event_time >= -20 & event_time <= 13]

fig3 <- ggplot(es_plot, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, color = "gray60") +
  reform_vline +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#2980B9") +
  geom_point(size = 1.8, color = "#2980B9") +
  geom_line(color = "#2980B9", linewidth = 0.5) +
  annotate("text", x = -0.5, y = min(es_plot$ci_lo, na.rm = TRUE) * 0.9,
           label = "Reform", hjust = 1.1, size = 3, color = "red") +
  labs(
    title = "Event Study: Effect of Treatment Intensity on Temporary Employment Share",
    subtitle = "Interaction of pre-reform temporary share with quarter dummies; reference: t = \u22121",
    x = "Quarters Relative to Reform (2022Q2)",
    y = "Coefficient on Pre-Reform Temp Share \u00d7 Quarter"
  )

ggsave(file.path(fig_dir, "fig3_event_study_temp.pdf"), fig3,
       width = 8, height = 5)

# =============================================================================
# FIGURE 4: Event study — permanent share (relabeling test)
# =============================================================================

cat("Figure 4: Event study permanent\n")

es_perm_plot <- es_perm_coefs[event_time >= -20 & event_time <= 13]

fig4 <- ggplot(es_perm_plot, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, color = "gray60") +
  reform_vline +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#27AE60") +
  geom_point(size = 1.8, color = "#27AE60") +
  geom_line(color = "#27AE60", linewidth = 0.5) +
  labs(
    title = "Event Study: Effect on Permanent Employment Share",
    subtitle = "Mirror image of temporary share decline confirms relabeling",
    x = "Quarters Relative to Reform (2022Q2)",
    y = "Coefficient on Pre-Reform Temp Share \u00d7 Quarter"
  )

ggsave(file.path(fig_dir, "fig4_event_study_perm.pdf"), fig4,
       width = 8, height = 5)

# =============================================================================
# FIGURE 5: Sector-level decomposition
# =============================================================================

cat("Figure 5: Sector decomposition\n")

dt_sector[, date_num := year + (quarter - 1) / 4]
dt_sector_plot <- dt_sector[sector != "Total"]

fig5 <- ggplot(dt_sector_plot, aes(x = date_num, y = sector_temp_share,
                                    color = sector)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = 2022.25, linetype = "dashed", color = "red",
             linewidth = 0.5) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  scale_color_manual(values = c("Agriculture" = "#E67E22", "Construction" = "#8E44AD",
                                "Industry" = "#2C3E50", "Services" = "#1ABC9C"),
                     name = "Sector") +
  labs(
    title = "Temporary Employment Share by Sector, 2010\u20132025",
    subtitle = "Agriculture and construction show largest declines",
    x = NULL, y = "Temporary Share of Wage Earners"
  )

ggsave(file.path(fig_dir, "fig5_sector_trends.pdf"), fig5,
       width = 8, height = 5)

# =============================================================================
# FIGURE 6: Leave-one-out robustness
# =============================================================================

cat("Figure 6: Leave-one-out\n")

baseline_beta <- fread(file.path(data_dir, "main_results.csv"))$beta[1]
loo_dt[, region_short := str_replace(dropped_region, ", .*$", "")]

fig6 <- ggplot(loo_dt, aes(x = reorder(region_short, beta), y = beta)) +
  geom_hline(yintercept = baseline_beta, linetype = "dashed", color = "red",
             linewidth = 0.5) +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi), size = 0.3,
                  color = "#2980B9") +
  coord_flip() +
  labs(
    title = "Leave-One-Out Sensitivity",
    subtitle = "Each point drops one region; dashed line = baseline estimate",
    x = NULL, y = "Coefficient on Treatment Intensity"
  )

ggsave(file.path(fig_dir, "fig6_loo.pdf"), fig6,
       width = 8, height = 6)

# =============================================================================
# FIGURE 7: Randomization inference distribution
# =============================================================================

cat("Figure 7: RI distribution\n")

fig7 <- ggplot(ri_dist, aes(x = beta)) +
  geom_histogram(bins = 50, fill = "gray70", color = "white") +
  geom_vline(xintercept = ri_results$observed_beta, color = "#E74C3C",
             linewidth = 0.8, linetype = "solid") +
  annotate("text", x = ri_results$observed_beta,
           y = Inf, label = paste0("Observed\n(\u03b2 = ",
                                    round(ri_results$observed_beta, 3), ")"),
           vjust = 1.5, hjust = -0.1, size = 3, color = "#E74C3C") +
  labs(
    title = "Randomization Inference: Distribution of Placebo Treatment Effects",
    subtitle = paste0("1,000 permutations of treatment intensity; RI p-value = ",
                      round(ri_results$ri_pvalue, 3)),
    x = "Placebo Coefficient", y = "Frequency"
  )

ggsave(file.path(fig_dir, "fig7_ri_distribution.pdf"), fig7,
       width = 8, height = 5)

# =============================================================================
# FIGURE 8: Region-level scatter (pre-reform temp share vs. change)
# =============================================================================

cat("Figure 8: Region scatter\n")

dt_change <- dt[, .(
  pre_temp_share = first(pre_temp_share),
  pre_temp = mean(temp_share[year <= 2021], na.rm = TRUE),
  post_temp = mean(temp_share[year >= 2023], na.rm = TRUE)
), by = region]
dt_change[, change := post_temp - pre_temp]
dt_change[, region_short := str_replace(region, ", .*$", "")]

fig8 <- ggplot(dt_change, aes(x = pre_temp_share, y = change)) +
  geom_smooth(method = "lm", se = TRUE, color = "#2980B9", linewidth = 0.5,
              alpha = 0.1) +
  geom_point(size = 2.5, color = "#E74C3C") +
  geom_text(aes(label = region_short), size = 2.2, nudge_y = 0.003,
            check_overlap = TRUE) +
  geom_hline(yintercept = 0, color = "gray60") +
  scale_x_continuous(labels = percent_format(accuracy = 1)) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    title = "Pre-Reform Temporary Share vs. Post-Reform Change",
    subtitle = "Negative slope confirms higher-exposure regions reduced temporary employment more",
    x = "Pre-Reform Temporary Employment Share (2021 Average)",
    y = "Change in Temporary Share (Post 2022 \u2212 Pre 2022)"
  )

ggsave(file.path(fig_dir, "fig8_scatter.pdf"), fig8,
       width = 8, height = 6)

# =============================================================================
# FIGURE C1 (Appendix): Alternative specification coefficients
# =============================================================================

cat("Figure C1: Alternative specs\n")

figC1 <- ggplot(alt_specs, aes(x = specification, y = beta)) +
  geom_hline(yintercept = 0, color = "gray60") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi), size = 0.4,
                  color = "#2980B9") +
  coord_flip() +
  labs(
    title = "Robustness: Alternative Specifications",
    x = NULL, y = "Coefficient on Treatment Intensity"
  )

ggsave(file.path(fig_dir, "figC1_alt_specs.pdf"), figC1,
       width = 8, height = 4)

cat("\n=== All figures saved to", fig_dir, "===\n")
