# ==============================================================================
# 05_figures.R — Generate all figures
# apep_0600: EU Mortgage Credit Directive
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# Load pre-computed results
es_rate <- fread(file.path(data_dir, "es_rate_results.csv"))
es_hpi <- fread(file.path(data_dir, "es_hpi_results.csv"))
loo_rate <- fread(file.path(data_dir, "loo_rate.csv"))
ri_rate <- fread(file.path(data_dir, "ri_rate.csv"))
mir_panel <- fread(file.path(data_dir, "mir_panel.csv"))
hpi_panel <- fread(file.path(data_dir, "hpi_panel.csv"))
transposition <- fread(file.path(data_dir, "mcd_transposition.csv"))
transposition[, transposition_date := as.Date(transposition_date)]

# Color palette
treat_col <- "#2166AC"
ctrl_col <- "#B2182B"
ci_col <- "#92C5DE"

# ==============================================================================
# Figure 1: Transposition Timeline
# ==============================================================================
cat("Figure 1: Transposition timeline\n")

trans_plot <- transposition[!is.na(transposition_date)][order(transposition_date)]
trans_plot[, country_label := factor(iso2, levels = rev(iso2))]
trans_plot[, year_trans := year(transposition_date)]
trans_plot[, on_time := transposition_date <= as.Date("2016-03-21")]

fig1 <- ggplot(trans_plot, aes(x = transposition_date, y = country_label)) +
  geom_segment(aes(xend = as.Date("2016-03-21"), yend = country_label),
               color = "grey80", linewidth = 0.3) +
  geom_point(aes(color = on_time), size = 2.5) +
  geom_vline(xintercept = as.Date("2016-03-21"), linetype = "dashed",
             color = "red", linewidth = 0.5) +
  annotate("text", x = as.Date("2016-03-21"), y = 0.5,
           label = "Deadline: March 21, 2016", color = "red",
           hjust = 0.5, vjust = -0.5, size = 3) +
  scale_color_manual(values = c("TRUE" = treat_col, "FALSE" = ctrl_col),
                     labels = c("TRUE" = "On time", "FALSE" = "Late"),
                     name = "") +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(x = "Transposition Date", y = "",
       title = "Staggered Transposition of the Mortgage Credit Directive") +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig1_transposition.pdf"), fig1,
       width = 7, height = 8, device = "pdf")
ggsave(file.path(fig_dir, "fig1_transposition.png"), fig1,
       width = 7, height = 8, dpi = 300)

# ==============================================================================
# Figure 2: Event Study — Mortgage Rates
# ==============================================================================
cat("Figure 2: Event study — mortgage rates\n")

fig2 <- ggplot(es_rate, aes(x = rel_time, y = att)) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), fill = ci_col, alpha = 0.3) +
  geom_line(color = treat_col, linewidth = 0.7) +
  geom_point(color = treat_col, size = 1.5) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "red") +
  labs(x = "Quarters Relative to MCD Transposition",
       y = "ATT (Percentage Points)",
       title = "Event Study: Effect of MCD on Mortgage Lending Rates") +
  scale_x_continuous(breaks = seq(-24, 36, by = 4))

ggsave(file.path(fig_dir, "fig2_es_rate.pdf"), fig2,
       width = 8, height = 5, device = "pdf")
ggsave(file.path(fig_dir, "fig2_es_rate.png"), fig2,
       width = 8, height = 5, dpi = 300)

# ==============================================================================
# Figure 3: Event Study — House Price Index
# ==============================================================================
cat("Figure 3: Event study — HPI\n")

fig3 <- ggplot(es_hpi, aes(x = rel_time, y = att)) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), fill = ci_col, alpha = 0.3) +
  geom_line(color = treat_col, linewidth = 0.7) +
  geom_point(color = treat_col, size = 1.5) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "red") +
  labs(x = "Quarters Relative to MCD Transposition",
       y = "ATT (Log Points)",
       title = "Event Study: Effect of MCD on House Prices") +
  scale_x_continuous(breaks = seq(-12, 16, by = 2))

ggsave(file.path(fig_dir, "fig3_es_hpi.pdf"), fig3,
       width = 8, height = 5, device = "pdf")
ggsave(file.path(fig_dir, "fig3_es_hpi.png"), fig3,
       width = 8, height = 5, dpi = 300)

# ==============================================================================
# Figure 4: Consumer Credit Placebo
# ==============================================================================
cat("Figure 4: Consumer credit placebo\n")

es_consumer_file <- file.path(data_dir, "es_consumer_placebo.csv")
if (file.exists(es_consumer_file)) {
  es_consumer <- fread(es_consumer_file)

  fig4 <- ggplot(es_consumer, aes(x = rel_time, y = att)) +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), fill = "#FDAE6B", alpha = 0.3) +
    geom_line(color = "#E6550D", linewidth = 0.7) +
    geom_point(color = "#E6550D", size = 1.5) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "red") +
    labs(x = "Quarters Relative to MCD Transposition",
         y = "ATT (Percentage Points)",
         title = "Placebo: Effect of MCD on Consumer Credit Rates (Not Covered)") +
    scale_x_continuous(breaks = seq(-24, 36, by = 4))

  ggsave(file.path(fig_dir, "fig4_placebo_consumer.pdf"), fig4,
         width = 8, height = 5, device = "pdf")
  ggsave(file.path(fig_dir, "fig4_placebo_consumer.png"), fig4,
         width = 8, height = 5, dpi = 300)
}

# ==============================================================================
# Figure 5: Leave-One-Out
# ==============================================================================
cat("Figure 5: Leave-one-out\n")

# Get full-sample estimate from TWFE
full_est <- fread(file.path(data_dir, "overall_rate.csv"))$att[1]

fig5 <- ggplot(loo_rate, aes(x = reorder(excluded, estimate), y = estimate)) +
  geom_point(size = 2, color = treat_col) +
  geom_errorbar(aes(ymin = estimate - 1.96 * se, ymax = estimate + 1.96 * se),
                width = 0.3, color = treat_col) +
  geom_hline(yintercept = full_est, linetype = "dashed", color = "red") +
  geom_hline(yintercept = 0, linetype = "solid", color = "grey60") +
  coord_flip() +
  labs(x = "Country Excluded", y = "TWFE Estimate (pp)",
       title = "Leave-One-Out: Sensitivity of Mortgage Rate Estimate")

ggsave(file.path(fig_dir, "fig5_loo.pdf"), fig5,
       width = 7, height = 6, device = "pdf")
ggsave(file.path(fig_dir, "fig5_loo.png"), fig5,
       width = 7, height = 6, dpi = 300)

# ==============================================================================
# Figure 6: Randomization Inference
# ==============================================================================
cat("Figure 6: Randomization inference\n")

actual <- ri_rate$actual[1]

fig6 <- ggplot(ri_rate, aes(x = coef)) +
  geom_histogram(bins = 50, fill = "grey70", color = "grey50", alpha = 0.8) +
  geom_vline(xintercept = actual, color = "red", linewidth = 1) +
  annotate("text", x = actual, y = Inf,
           label = paste0("Actual = ", round(actual, 3)),
           hjust = -0.1, vjust = 1.5, color = "red", size = 3.5) +
  labs(x = "Permuted Treatment Effect",
       y = "Count",
       title = paste0("Randomization Inference (p = ",
                       round(ri_rate$ri_p[1], 3), ")"))

ggsave(file.path(fig_dir, "fig6_ri.pdf"), fig6,
       width = 7, height = 4.5, device = "pdf")
ggsave(file.path(fig_dir, "fig6_ri.png"), fig6,
       width = 7, height = 4.5, dpi = 300)

# ==============================================================================
# Figure 7: Raw Trends — Mortgage Rates by Cohort
# ==============================================================================
cat("Figure 7: Raw mortgage rate trends\n")

mir_panel[, date := as.Date(date)]
mir_panel[, transposition_date := as.Date(transposition_date)]

# Classify into early (before deadline), on-time, and late
mir_panel[, cohort_group := fcase(
  is.na(transposition_date), "Never treated",
  transposition_date <= as.Date("2016-03-21"), "On-time (by Mar 2016)",
  transposition_date <= as.Date("2017-06-30"), "Late (2016-2017)",
  default = "Very late (2018-2019)"
)]

trend_data <- mir_panel[!is.na(rate) & date >= "2012-01-01" & date <= "2020-12-31",
                        .(mean_rate = mean(rate, na.rm = TRUE)),
                        by = .(date, cohort_group)]

fig7 <- ggplot(trend_data, aes(x = date, y = mean_rate, color = cohort_group)) +
  geom_line(linewidth = 0.7) +
  geom_vline(xintercept = as.Date("2016-03-21"), linetype = "dashed", color = "grey40") +
  annotate("text", x = as.Date("2016-03-21"), y = max(trend_data$mean_rate, na.rm = TRUE),
           label = "MCD Deadline", hjust = -0.1, size = 3, color = "grey40") +
  scale_color_brewer(palette = "Set1", name = "Transposition Cohort") +
  labs(x = "", y = "Mean Mortgage Rate (%)",
       title = "Mortgage Lending Rates by Transposition Cohort") +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig7_trends.pdf"), fig7,
       width = 8, height = 5, device = "pdf")
ggsave(file.path(fig_dir, "fig7_trends.png"), fig7,
       width = 8, height = 5, dpi = 300)

cat("\nAll figures generated.\n")
