## ============================================================================
## 05_figures.R — All figures for paper
## Schengen Border Controls and Regional Economic Activity
## ============================================================================

source("00_packages.R")

data_dir <- "../data/"
fig_dir <- "../figures/"
tables_dir <- "../tables/"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel_balanced.csv"))

cat("=== Generating Figures ===\n")

## ---------------------------------------------------------------------------
## Figure 1: Treatment timing and border segments
## ---------------------------------------------------------------------------
cat("Figure 1: Treatment timing...\n")

treatment <- fread(file.path(data_dir, "treatment_assignment.csv"))

treat_summary <- treatment[, .(
  n_regions = .N,
  treat_date = first(treat_date)
), by = .(border_segment, cohort)]
treat_summary <- treat_summary[order(treat_date)]

fig1 <- ggplot(treat_summary, aes(x = reorder(border_segment, cohort),
                                   y = n_regions, fill = as.factor(cohort))) +
  geom_col(width = 0.7) +
  geom_text(aes(label = treat_date), vjust = -0.5, size = 3) +
  scale_fill_viridis_d(name = "Cohort Year", option = "D") +
  labs(x = "Border Segment",
       y = "Number of Treated NUTS3 Regions",
       title = NULL) +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

ggsave(file.path(fig_dir, "fig1_treatment_timing.pdf"), fig1,
       width = 8, height = 5)

## ---------------------------------------------------------------------------
## Figure 2: Pre-treatment trends (parallel trends visual)
## ---------------------------------------------------------------------------
cat("Figure 2: Pre-treatment trends...\n")

trends <- panel[, .(
  mean_log_gdp = mean(log_gdp_pc, na.rm = TRUE),
  se_log_gdp = sd(log_gdp_pc, na.rm = TRUE) / sqrt(.N)
), by = .(year, region_type)]

# Save for data-first rule
fwrite(trends, file.path(data_dir, "pretrends_data.csv"))

fig2 <- ggplot(trends, aes(x = year, y = mean_log_gdp,
                            color = region_type, linetype = region_type)) +
  geom_line(linewidth = 0.8) +
  geom_ribbon(aes(ymin = mean_log_gdp - 1.96 * se_log_gdp,
                  ymax = mean_log_gdp + 1.96 * se_log_gdp,
                  fill = region_type), alpha = 0.15, linetype = 0) +
  geom_vline(xintercept = 2014.5, linetype = "dashed", color = "grey40") +
  annotate("text", x = 2014.5, y = Inf, label = "Border controls\nreintroduced",
           hjust = 1.1, vjust = 1.5, size = 3, color = "grey40") +
  scale_color_manual(values = c("treated_border" = "#D55E00",
                                "control_border" = "#0072B2",
                                "interior" = "#999999"),
                     labels = c("Treated border", "Control border", "Interior")) +
  scale_fill_manual(values = c("treated_border" = "#D55E00",
                               "control_border" = "#0072B2",
                               "interior" = "#999999"),
                    labels = c("Treated border", "Control border", "Interior")) +
  scale_linetype_manual(values = c("treated_border" = "solid",
                                   "control_border" = "dashed",
                                   "interior" = "dotted"),
                        labels = c("Treated border", "Control border", "Interior")) +
  labs(x = "Year", y = "Mean Log GDP per Capita",
       color = "Region Type", fill = "Region Type", linetype = "Region Type") +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig2_pretrends.pdf"), fig2,
       width = 8, height = 5.5)

## ---------------------------------------------------------------------------
## Figure 3: Callaway-Sant'Anna dynamic event study
## ---------------------------------------------------------------------------
cat("Figure 3: CS event study...\n")

cs_dynamic <- fread(file.path(tables_dir, "cs_dynamic_coefs.csv"))

# Save for data-first rule
fwrite(cs_dynamic, file.path(data_dir, "cs_event_study_data.csv"))

fig3 <- ggplot(cs_dynamic, aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
  geom_vline(xintercept = -0.5, color = "grey50", linetype = "dashed") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "#0072B2") +
  geom_point(size = 2, color = "#0072B2") +
  geom_line(color = "#0072B2", linewidth = 0.5) +
  labs(x = "Years Relative to Border Control Reintroduction",
       y = "ATT (Log GDP per Capita)",
       title = NULL) +
  scale_x_continuous(breaks = seq(-12, 8, by = 2))

ggsave(file.path(fig_dir, "fig3_cs_event_study.pdf"), fig3,
       width = 8, height = 5)

## ---------------------------------------------------------------------------
## Figure 4: Heterogeneity by border segment
## ---------------------------------------------------------------------------
cat("Figure 4: Heterogeneity by segment...\n")

het <- fread(file.path(tables_dir, "tab4_heterogeneity.csv"))

# Save for data-first rule
fwrite(het, file.path(data_dir, "heterogeneity_data.csv"))

fig4 <- ggplot(het, aes(x = reorder(segment, estimate), y = estimate)) +
  geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
  geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper),
                  color = "#D55E00", size = 0.5) +
  geom_text(aes(label = paste0("n=", n_treated)),
            hjust = -0.3, size = 3, color = "grey40") +
  coord_flip() +
  labs(x = "Border Segment", y = "Effect on Log GDP per Capita")

ggsave(file.path(fig_dir, "fig4_heterogeneity.pdf"), fig4,
       width = 7, height = 4.5)

## ---------------------------------------------------------------------------
## Figure 5: Randomization inference distribution
## ---------------------------------------------------------------------------
cat("Figure 5: RI distribution...\n")

if (file.exists(file.path(data_dir, "ri_distribution.csv"))) {
  ri <- fread(file.path(data_dir, "ri_distribution.csv"))

  # Load main estimate
  main_results <- fread(file.path(tables_dir, "tab2_main_results.csv"))
  true_coef <- main_results[outcome == "Log GDP pc", estimate]

  fig5 <- ggplot(ri, aes(x = ri_coef)) +
    geom_histogram(bins = 50, fill = "grey70", color = "white") +
    geom_vline(xintercept = true_coef, color = "#D55E00", linewidth = 1,
               linetype = "solid") +
    geom_vline(xintercept = -true_coef, color = "#D55E00", linewidth = 1,
               linetype = "dashed") +
    annotate("text", x = true_coef, y = Inf,
             label = paste("True estimate:", round(true_coef, 4)),
             hjust = -0.1, vjust = 1.5, size = 3.5, color = "#D55E00") +
    labs(x = "Placebo Coefficient", y = "Count",
         title = NULL)

  ggsave(file.path(fig_dir, "fig5_ri_distribution.pdf"), fig5,
         width = 7, height = 4.5)
}

## ---------------------------------------------------------------------------
## Figure 6: Sun-Abraham TWFE event study
## ---------------------------------------------------------------------------
cat("Figure 6: Sun-Abraham event study...\n")

es_coefs <- fread(file.path(tables_dir, "tab3_event_study.csv"))

# Save for data-first rule
fwrite(es_coefs, file.path(data_dir, "sa_event_study_data.csv"))

fig6 <- ggplot(es_coefs, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
  geom_vline(xintercept = -0.5, color = "grey50", linetype = "dashed") +
  geom_ribbon(aes(ymin = estimate - 1.96 * se, ymax = estimate + 1.96 * se),
              alpha = 0.2, fill = "#009E73") +
  geom_point(size = 2, color = "#009E73") +
  geom_line(color = "#009E73", linewidth = 0.5) +
  labs(x = "Years Relative to Border Control Reintroduction",
       y = "Coefficient (Log GDP per Capita)",
       title = NULL) +
  scale_x_continuous(breaks = seq(-12, 8, by = 2))

ggsave(file.path(fig_dir, "fig6_sa_event_study.pdf"), fig6,
       width = 8, height = 5)

## ---------------------------------------------------------------------------
## Figure 7: Robustness coefficient plot
## ---------------------------------------------------------------------------
cat("Figure 7: Robustness summary...\n")

rob <- fread(file.path(tables_dir, "tab5_robustness.csv"))
rob <- rob[!is.na(ci_lower)]

# Save for data-first rule
fwrite(rob, file.path(data_dir, "robustness_plot_data.csv"))

fig7 <- ggplot(rob, aes(x = reorder(check, estimate), y = estimate)) +
  geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
  geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper),
                  color = "#0072B2", size = 0.5) +
  coord_flip() +
  labs(x = NULL, y = "Coefficient on Border Control Treatment")

ggsave(file.path(fig_dir, "fig7_robustness.pdf"), fig7,
       width = 7, height = 5)

cat("\n05_figures.R complete.\n")
