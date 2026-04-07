## 05_figures.R — Generate all figures (≥5 required)
source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

df <- fread(file.path(data_dir, "panel_clean.csv"))
results <- readRDS(file.path(data_dir, "results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

# Color palette
col_treat <- "#D55E00"  # Appendix B
col_ctrl  <- "#0072B2"  # Non-Appendix B
col_ci    <- "#999999"

# ── Figure 1: RDD Plot — Binscatter of TCR vs employees (2024, Appendix B) ──
message("Figure 1: RDD binscatter")
post_b <- df[year == 2024 & appendix_b == 1 & !is.na(tcr) & emp >= 50 & emp <= 200]

# Create bins
post_b[, emp_bin := cut(emp, breaks = seq(50, 200, by = 5), include.lowest = TRUE, labels = FALSE)]
post_b[, emp_bin_mid := seq(52.5, 197.5, by = 5)[emp_bin]]

bin_means <- post_b[, .(tcr_mean = mean(tcr, na.rm = TRUE),
                         n = .N), by = emp_bin_mid]

p1 <- ggplot(bin_means, aes(x = emp_bin_mid, y = tcr_mean)) +
  geom_point(aes(size = n), color = col_treat, alpha = 0.7) +
  geom_vline(xintercept = 100, linetype = "dashed", color = "black", linewidth = 0.8) +
  geom_smooth(data = bin_means[emp_bin_mid < 100], method = "lm", formula = y ~ x,
              se = TRUE, color = col_treat, fill = col_treat, alpha = 0.2) +
  geom_smooth(data = bin_means[emp_bin_mid >= 100], method = "lm", formula = y ~ x,
              se = TRUE, color = col_treat, fill = col_treat, alpha = 0.2) +
  labs(x = "Annual Average Employees",
       y = "Total Case Rate (per 100 FTE)",
       title = "Injury Rates at the 100-Employee Threshold",
       subtitle = "Appendix B Industries, 2024") +
  scale_size_continuous(guide = "none") +
  annotate("text", x = 102, y = max(bin_means$tcr_mean, na.rm = TRUE) * 0.95,
           label = "Reporting\nthreshold", hjust = 0, size = 3.5) +
  theme(plot.subtitle = element_text(color = "gray40"))

ggsave(file.path(fig_dir, "fig1_rdd_binscatter.pdf"), p1, width = 8, height = 5.5)

# ── Figure 2: DinD — Appendix B vs Non-Appendix B ──
message("Figure 2: DinD comparison")
comp_df <- df[year == 2024 & !is.na(tcr) & emp >= 50 & emp <= 200]
comp_df[, emp_bin := cut(emp, breaks = seq(50, 200, by = 5), include.lowest = TRUE, labels = FALSE)]
comp_df[, emp_bin_mid := seq(52.5, 197.5, by = 5)[emp_bin]]
comp_df[, group := ifelse(appendix_b == 1, "Appendix B (treated)", "Non-Appendix B (control)")]

bin2 <- comp_df[, .(tcr_mean = mean(tcr, na.rm = TRUE),
                     n = .N), by = .(emp_bin_mid, group)]

p2 <- ggplot(bin2, aes(x = emp_bin_mid, y = tcr_mean, color = group)) +
  geom_point(aes(size = n), alpha = 0.6) +
  geom_vline(xintercept = 100, linetype = "dashed", linewidth = 0.8) +
  geom_smooth(data = bin2[emp_bin_mid < 100], method = "lm", formula = y ~ x,
              se = FALSE, linewidth = 0.8) +
  geom_smooth(data = bin2[emp_bin_mid >= 100], method = "lm", formula = y ~ x,
              se = FALSE, linewidth = 0.8) +
  scale_color_manual(values = c("Appendix B (treated)" = col_treat,
                                "Non-Appendix B (control)" = col_ctrl)) +
  labs(x = "Annual Average Employees",
       y = "Total Case Rate (per 100 FTE)",
       title = "Difference-in-Discontinuities: Treated vs. Control Industries",
       subtitle = "2024",
       color = NULL) +
  scale_size_continuous(guide = "none") +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig2_dind_comparison.pdf"), p2, width = 8, height = 5.5)

# ── Figure 3: Event Study — Year-by-year RDD estimates ──
message("Figure 3: Event study")
es_df <- results$rd_by_year[outcome == "tcr"]
es_df[, ci_lo := coef - 1.96 * se]
es_df[, ci_hi := coef + 1.96 * se]

p3 <- ggplot(es_df, aes(x = year, y = coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = 2023.5, linetype = "dotted", color = "red", linewidth = 0.8) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = col_treat, alpha = 0.2) +
  geom_point(color = col_treat, size = 3) +
  geom_line(color = col_treat, linewidth = 0.8) +
  labs(x = "Year",
       y = "RDD Estimate (TCR)",
       title = "Event Study: Discontinuity at 100 Employees Over Time",
       subtitle = "Appendix B industries; vertical line = rule effective Jan 2024") +
  scale_x_continuous(breaks = sort(unique(es_df$year))) +
  theme(plot.subtitle = element_text(color = "gray40"))

ggsave(file.path(fig_dir, "fig3_event_study.pdf"), p3, width = 8, height = 5.5)

# ── Figure 4: McCrary Density Test ──
message("Figure 4: Density plots")
dens_data <- rbind(
  df[year == 2024 & appendix_b == 1 & emp >= 50 & emp <= 200,
     .(emp, period = "2024 (post)", group = "Appendix B")],
  df[year == 2023 & appendix_b == 1 & emp >= 50 & emp <= 200,
     .(emp, period = "2023 (pre)", group = "Appendix B")],
  df[year == 2024 & appendix_b == 0 & emp >= 50 & emp <= 200,
     .(emp, period = "2024 (post)", group = "Non-Appendix B")]
)

p4 <- ggplot(dens_data, aes(x = emp, fill = period)) +
  geom_histogram(aes(y = after_stat(density)), binwidth = 2, alpha = 0.5,
                 position = "identity") +
  geom_vline(xintercept = 100, linetype = "dashed", linewidth = 0.8) +
  facet_wrap(~group, ncol = 1, scales = "free_y") +
  scale_fill_manual(values = c("2024 (post)" = col_treat, "2023 (pre)" = col_ctrl,
                                "Non-Appendix B" = col_ci)) +
  labs(x = "Annual Average Employees",
       y = "Density",
       title = "Employee Count Distribution Around the 100-Employee Threshold",
       subtitle = "Testing for manipulation (bunching)",
       fill = NULL) +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig4_density.pdf"), p4, width = 8, height = 8)

# ── Figure 5: Bandwidth Sensitivity ──
message("Figure 5: Bandwidth sensitivity")
bw_df <- rob_results$bandwidth_sensitivity
if (!is.null(bw_df) && nrow(bw_df) > 0) {
  bw_df[, ci_lo := coef - 1.96 * se]
  bw_df[, ci_hi := coef + 1.96 * se]

  p5 <- ggplot(bw_df, aes(x = bandwidth, y = coef)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = col_treat, alpha = 0.2) +
    geom_point(color = col_treat, size = 3) +
    geom_line(color = col_treat, linewidth = 0.8) +
    labs(x = "Bandwidth (employees from cutoff)",
         y = "RDD Estimate (TCR)",
         title = "Bandwidth Sensitivity",
         subtitle = "RDD estimates at varying bandwidths") +
    theme(plot.subtitle = element_text(color = "gray40"))

  ggsave(file.path(fig_dir, "fig5_bandwidth.pdf"), p5, width = 7, height = 5)
}

# ── Figure 6: Placebo Cutoffs ──
message("Figure 6: Placebo cutoffs")
plac_df <- rob_results$placebo_cutoffs
if (!is.null(plac_df) && nrow(plac_df) > 0) {
  plac_df[, ci_lo := coef - 1.96 * se]
  plac_df[, ci_hi := coef + 1.96 * se]
  plac_df[, is_real := cutoff == 100]

  # Add the real cutoff estimate from 2024 data
  real_2024 <- results$rd_by_year[outcome == "tcr" & year == 2024]
  if (nrow(real_2024) > 0) {
    plac_df <- rbind(plac_df, data.table(
      cutoff = 100, coef = real_2024$coef, se = real_2024$se,
      pval = real_2024$pval,
      ci_lo = real_2024$coef - 1.96 * real_2024$se,
      ci_hi = real_2024$coef + 1.96 * real_2024$se,
      is_real = TRUE
    ))
  }

  p6 <- ggplot(plac_df, aes(x = cutoff, y = coef, color = is_real)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 2) +
    geom_point(size = 3) +
    scale_color_manual(values = c("TRUE" = col_treat, "FALSE" = col_ctrl),
                       labels = c("TRUE" = "100 (actual)", "FALSE" = "Placebo"),
                       guide = "none") +
    labs(x = "Cutoff (number of employees)",
         y = "RDD Estimate (TCR)",
         title = "Placebo Cutoff Tests",
         subtitle = "Red = actual threshold; blue = placebo") +
    theme(plot.subtitle = element_text(color = "gray40"))

  ggsave(file.path(fig_dir, "fig6_placebo_cutoffs.pdf"), p6, width = 7, height = 5)
}

# ── Figure 7: DART rate RDD ──
message("Figure 7: DART RDD binscatter")
post_b_dart <- df[year == 2024 & appendix_b == 1 & !is.na(dart_rate) & emp >= 50 & emp <= 200]
post_b_dart[, emp_bin := cut(emp, breaks = seq(50, 200, by = 5), include.lowest = TRUE, labels = FALSE)]
post_b_dart[, emp_bin_mid := seq(52.5, 197.5, by = 5)[emp_bin]]

bin7 <- post_b_dart[, .(dart_mean = mean(dart_rate, na.rm = TRUE),
                         n = .N), by = emp_bin_mid]

p7 <- ggplot(bin7, aes(x = emp_bin_mid, y = dart_mean)) +
  geom_point(aes(size = n), color = col_treat, alpha = 0.7) +
  geom_vline(xintercept = 100, linetype = "dashed", linewidth = 0.8) +
  geom_smooth(data = bin7[emp_bin_mid < 100], method = "lm", formula = y ~ x,
              se = TRUE, color = col_treat, fill = col_treat, alpha = 0.2) +
  geom_smooth(data = bin7[emp_bin_mid >= 100], method = "lm", formula = y ~ x,
              se = TRUE, color = col_treat, fill = col_treat, alpha = 0.2) +
  labs(x = "Annual Average Employees",
       y = "DART Rate (per 100 FTE)",
       title = "DART Rate at the 100-Employee Threshold",
       subtitle = "Appendix B Industries, 2024") +
  scale_size_continuous(guide = "none") +
  theme(plot.subtitle = element_text(color = "gray40"))

ggsave(file.path(fig_dir, "fig7_dart_rdd.pdf"), p7, width = 8, height = 5.5)

message("\nAll figures saved to ", fig_dir)
message("Total figures: ", length(list.files(fig_dir, pattern = "\\.pdf$")))
