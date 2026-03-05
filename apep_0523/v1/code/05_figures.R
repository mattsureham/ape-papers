## 05_figures.R — Generate all figures
## TLV Vacancy Tax Expansion — apep_0523

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# ===========================================================================
# Figure 1: Treatment Map — Transaction Volumes by Group Over Time
# ===========================================================================
cat("=== Figure 1: Raw trends by treatment group ===\n")

panel <- fread(file.path(data_dir, "balanced_panel.csv"))

# Aggregate to group-quarter level
trends <- panel[group %in% c("newly_treated_2023", "never_treated", "always_treated"),
                .(mean_trans = mean(n_transactions, na.rm = TRUE),
                  mean_prix_m2 = mean(median_prix_m2, na.rm = TRUE),
                  n_communes = uniqueN(codgeo)),
                by = .(group, quarter, year_q)]

# Rename groups for display
trends[, group_label := fcase(
  group == "newly_treated_2023", "Newly Treated (2023)",
  group == "never_treated", "Never Treated",
  group == "always_treated", "Always Treated (since 2013)"
)]

# Panel A: Transaction volume
fig1a <- ggplot(trends, aes(x = year_q, y = mean_trans, color = group_label, linetype = group_label)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_vline(xintercept = 2023.75, linetype = "dashed", color = "grey40", linewidth = 0.5) +
  annotate("text", x = 2023.75, y = max(trends$mean_trans, na.rm = TRUE) * 0.95,
           label = "Decree\n(Aug 2023)", hjust = -0.1, size = 3, color = "grey40") +
  geom_vline(xintercept = 2024, linetype = "dotted", color = "grey40", linewidth = 0.5) +
  annotate("text", x = 2024, y = max(trends$mean_trans, na.rm = TRUE) * 0.85,
           label = "Tax Year\n(Jan 2024)", hjust = -0.1, size = 3, color = "grey40") +
  scale_color_manual(values = c("Newly Treated (2023)" = "#d62728",
                                "Never Treated" = "#1f77b4",
                                "Always Treated (since 2013)" = "#2ca02c")) +
  scale_linetype_manual(values = c("Newly Treated (2023)" = "solid",
                                   "Never Treated" = "solid",
                                   "Always Treated (since 2013)" = "dashed")) +
  labs(x = "", y = "Mean Transactions per Commune-Quarter",
       title = "Panel A: Transaction Volume",
       color = NULL, linetype = NULL) +
  theme(legend.position = "bottom")

# Panel B: Prices
fig1b <- ggplot(trends[!is.na(mean_prix_m2)],
                aes(x = year_q, y = mean_prix_m2, color = group_label, linetype = group_label)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_vline(xintercept = 2023.75, linetype = "dashed", color = "grey40", linewidth = 0.5) +
  geom_vline(xintercept = 2024, linetype = "dotted", color = "grey40", linewidth = 0.5) +
  scale_color_manual(values = c("Newly Treated (2023)" = "#d62728",
                                "Never Treated" = "#1f77b4",
                                "Always Treated (since 2013)" = "#2ca02c")) +
  scale_linetype_manual(values = c("Newly Treated (2023)" = "solid",
                                   "Never Treated" = "solid",
                                   "Always Treated (since 2013)" = "dashed")) +
  scale_y_continuous(labels = scales::comma) +
  labs(x = "", y = expression("Median Price per m"^2*" (\u20ac)"),
       title = "Panel B: Transaction Prices",
       color = NULL, linetype = NULL) +
  theme(legend.position = "bottom")

fig1 <- fig1a / fig1b + plot_annotation(
  title = "Raw Trends by TLV Treatment Group",
  subtitle = "Commune-quarter means, 2020\u20132025"
)

ggsave(file.path(fig_dir, "fig1_raw_trends.pdf"), fig1, width = 8, height = 10)
cat("Saved fig1_raw_trends.pdf\n")

# ===========================================================================
# Figure 2: Event Study
# ===========================================================================
cat("\n=== Figure 2: Event Study ===\n")

es_coefs <- fread(file.path(data_dir, "event_study_coefs.csv"))

# Add reference period
ref_rows <- data.table(
  rel_time = c(-1, -1),
  estimate = c(0, 0),
  se = c(0, 0),
  ci_lower = c(0, 0),
  ci_upper = c(0, 0),
  outcome = c("log_transactions", "log_price_m2")
)
es_plot <- rbind(es_coefs, ref_rows)

# Panel A: Volume
fig2a <- ggplot(es_plot[outcome == "log_transactions"],
                aes(x = rel_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), fill = "#d62728", alpha = 0.15) +
  geom_point(color = "#d62728", size = 2) +
  geom_line(color = "#d62728", linewidth = 0.6) +
  labs(x = "Quarters Relative to Treatment (2024Q1 = 0)",
       y = "Estimated Effect on Log(Transactions + 1)",
       title = "Panel A: Transaction Volume") +
  scale_x_continuous(breaks = seq(-8, 6, 2))

# Panel B: Prices
fig2b <- ggplot(es_plot[outcome == "log_price_m2"],
                aes(x = rel_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), fill = "#1f77b4", alpha = 0.15) +
  geom_point(color = "#1f77b4", size = 2) +
  geom_line(color = "#1f77b4", linewidth = 0.6) +
  labs(x = "Quarters Relative to Treatment (2024Q1 = 0)",
       y = expression("Estimated Effect on Log(Price/m"^2*")"),
       title = "Panel B: Transaction Prices") +
  scale_x_continuous(breaks = seq(-8, 6, 2))

fig2 <- fig2a / fig2b + plot_annotation(
  title = "Event Study: Effect of TLV Expansion",
  subtitle = "Newly treated vs. never-treated communes. Reference period: q-1."
)

ggsave(file.path(fig_dir, "fig2_event_study.pdf"), fig2, width = 8, height = 10)
cat("Saved fig2_event_study.pdf\n")

# ===========================================================================
# Figure 3: CS Event Study (if available)
# ===========================================================================
cat("\n=== Figure 3: CS Event Study ===\n")

cs_file <- file.path(data_dir, "cs_event_study_coefs.csv")
if (file.exists(cs_file)) {
  cs_coefs <- fread(cs_file)

  fig3 <- ggplot(cs_coefs, aes(x = rel_time, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
    geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), fill = "#9467bd", alpha = 0.15) +
    geom_point(color = "#9467bd", size = 2) +
    geom_line(color = "#9467bd", linewidth = 0.6) +
    labs(x = "Quarters Relative to Treatment",
         y = "ATT (Callaway-Sant'Anna)",
         title = "Callaway-Sant'Anna Event Study: Transaction Volume",
         subtitle = "Doubly-robust, never-treated as control") +
    scale_x_continuous(breaks = seq(-8, 6, 2))

  ggsave(file.path(fig_dir, "fig3_cs_event_study.pdf"), fig3, width = 8, height = 5.5)
  cat("Saved fig3_cs_event_study.pdf\n")
} else {
  cat("CS coefficients not found, skipping Figure 3.\n")
}

# ===========================================================================
# Figure 4: Randomization Inference
# ===========================================================================
cat("\n=== Figure 4: Randomization Inference ===\n")

ri_file <- file.path(data_dir, "ri_distribution.csv")
ri_sum_file <- file.path(data_dir, "ri_summary.csv")

if (file.exists(ri_file) && file.exists(ri_sum_file)) {
  ri_dist <- fread(ri_file)
  ri_sum <- fread(ri_sum_file)

  fig4 <- ggplot(ri_dist, aes(x = ri_coefs)) +
    geom_histogram(bins = 50, fill = "grey70", color = "grey50", alpha = 0.7) +
    geom_vline(xintercept = ri_sum$actual_coef, color = "#d62728", linewidth = 1) +
    annotate("text", x = ri_sum$actual_coef, y = Inf,
             label = sprintf("Actual = %.4f\nRI p = %.3f", ri_sum$actual_coef, ri_sum$ri_pval),
             hjust = -0.1, vjust = 1.5, color = "#d62728", size = 3.5) +
    labs(x = "Placebo Treatment Effect",
         y = "Count",
         title = "Randomization Inference: Transaction Volume",
         subtitle = sprintf("%d permutations of commune treatment assignment", ri_sum$n_perms))

  ggsave(file.path(fig_dir, "fig4_ri_distribution.pdf"), fig4, width = 7, height = 5)
  cat("Saved fig4_ri_distribution.pdf\n")
} else {
  cat("RI results not found, skipping Figure 4.\n")
}

# ===========================================================================
# Figure 5: Heterogeneity — Zone Type
# ===========================================================================
cat("\n=== Figure 5: Robustness coefficient plot ===\n")

rob_file <- file.path(data_dir, "robustness_summary.csv")
if (file.exists(rob_file)) {
  rob <- fread(rob_file)
  rob[, ci_lower := coef - 1.96 * se]
  rob[, ci_upper := coef + 1.96 * se]

  # Volume tests only
  rob_vol <- rob[grepl("volume|Volume", test)]
  rob_vol[, test := gsub(" \\(volume\\)", "", test)]

  fig5 <- ggplot(rob_vol, aes(x = reorder(test, coef), y = coef)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
    geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper), color = "#d62728", size = 0.5) +
    coord_flip() +
    labs(x = NULL, y = "Estimated Effect on Log(Transactions + 1)",
         title = "Robustness Checks: Transaction Volume",
         subtitle = "Point estimates with 95% confidence intervals")

  ggsave(file.path(fig_dir, "fig5_robustness.pdf"), fig5, width = 8, height = 5)
  cat("Saved fig5_robustness.pdf\n")
}

cat("\nAll figures generated.\n")
