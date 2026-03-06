###############################################################################
# 05_figures.R — Generate all figures
# APEP-0541: How Many Generics Does It Take?
###############################################################################

source("00_packages.R")

data_dir <- "../data"
fig_dir  <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

# Load results
np_coefs   <- fread(file.path(data_dir, "nonparam_curve.csv"))
cross_by_n <- fread(file.path(data_dir, "cross_section_by_n.csv"))
compare    <- fread(file.path(data_dir, "cross_vs_within.csv"))
es_coefs   <- tryCatch(fread(file.path(data_dir, "event_study_coefficients.csv")),
                       error = function(e) NULL)
group_coefs <- tryCatch(fread(file.path(data_dir, "event_study_by_group.csv")),
                        error = function(e) NULL)

# ==========================================================================
# Figure 1: The Selection Gap (SIGNATURE FIGURE)
# Cross-sectional vs within-market competition curves
# ==========================================================================

cat("Figure 1: Selection gap\n")

fig1_data <- compare[n_competitors <= 15]
fig1_data[, ci_lo := estimate - 1.96 * se]
fig1_data[, ci_hi := estimate + 1.96 * se]
fig1_data[, spec_label := ifelse(specification == "cross_section",
                                  "Cross-Section (Week FE Only)",
                                  "Within-Market (Market + Week FE)")]

p1 <- ggplot(fig1_data, aes(x = n_competitors, y = estimate,
                              color = spec_label, fill = spec_label)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, color = NA) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  scale_color_manual(values = c(apep_colors[2], apep_colors[1]),
                     name = NULL) +
  scale_fill_manual(values = c(apep_colors[2], apep_colors[1]),
                    name = NULL) +
  scale_x_continuous(breaks = seq(2, 15, 2)) +
  labs(
    title = "Cross-Sectional vs. Within-Market Competition Curves",
    subtitle = "Effect of N competitors on log drug acquisition cost, relative to monopoly (N=1)",
    x = "Number of Generic Competitors",
    y = "Effect on Log Price (Relative to N = 1)",
    caption = paste0(
      "Notes: Cross-section estimates use calendar-week FE only. ",
      "Within-market estimates add drug-market FE.\n",
      "The gap between curves measures selection bias: ",
      "cheaper drugs attract more competitors.\n",
      "4,512 drug markets, 51,643 market-week observations. ",
      "SEs clustered by drug market. 95% CIs shaded."
    )
  ) +
  theme_apep() +
  theme(legend.position = c(0.7, 0.85))

ggsave(file.path(fig_dir, "fig1_selection_gap.pdf"), p1,
       width = 9, height = 6, device = cairo_pdf)
ggsave(file.path(fig_dir, "fig1_selection_gap.png"), p1,
       width = 9, height = 6, dpi = 300)

# ==========================================================================
# Figure 2: Raw cross-sectional price gradient
# ==========================================================================

cat("Figure 2: Cross-sectional gradient\n")

cs_data <- cross_by_n[n_competitors <= 25 & n_competitors >= 1]

p2 <- ggplot(cs_data, aes(x = n_competitors, y = med_price)) +
  geom_col(fill = apep_colors[1], alpha = 0.7, width = 0.7) +
  geom_text(aes(label = sprintf("$%.2f", med_price)),
            vjust = -0.5, size = 2.5, color = "grey30") +
  scale_x_continuous(breaks = seq(1, 25, 2)) +
  scale_y_continuous(labels = scales::dollar_format()) +
  labs(
    title = "Median Drug Acquisition Cost by Number of Generic Competitors",
    subtitle = "CMS NADAC, 2023-2024",
    x = "Number of Generic Competitors (Active NDCs)",
    y = "Median NADAC Per Unit ($)",
    caption = paste0("Notes: Each bar shows the median NADAC per-unit cost across ",
                     "all market-weeks with that number of competitors.\n",
                     "N = number of unique generic NDC codes observed for a given ",
                     "drug description in a given week.")
  ) +
  theme_apep()

ggsave(file.path(fig_dir, "fig2_cross_section.pdf"), p2,
       width = 9, height = 5.5, device = cairo_pdf)
ggsave(file.path(fig_dir, "fig2_cross_section.png"), p2,
       width = 9, height = 5.5, dpi = 300)

# ==========================================================================
# Figure 3: Event study — pooled
# ==========================================================================

if (!is.null(es_coefs) && nrow(es_coefs) > 0) {
  cat("Figure 3: Pooled event study\n")

  es_plot <- es_coefs[event_time >= -16 & event_time <= 30]

  p3 <- ggplot(es_plot, aes(x = event_time, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "red", alpha = 0.5) +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi),
                fill = apep_colors[1], alpha = 0.15) +
    geom_line(color = apep_colors[1], linewidth = 0.8) +
    geom_point(color = apep_colors[1], size = 1.5) +
    labs(
      title = "Price Dynamics Around New Competitor Entry",
      subtitle = "Pooled event study across 583 within-market entry events",
      x = "Weeks Relative to New Competitor Entry",
      y = "Change in Log Drug Acquisition Cost",
      caption = paste0(
        "Notes: Entry defined as first appearance of a new generic NDC ",
        "in a drug market.\n",
        "Reference period: event-week -1. Event and calendar-week FE. ",
        "SEs clustered by event. 95% CI shaded."
      )
    ) +
    theme_apep()

  ggsave(file.path(fig_dir, "fig3_event_study.pdf"), p3,
         width = 9, height = 5.5, device = cairo_pdf)
  ggsave(file.path(fig_dir, "fig3_event_study.png"), p3,
         width = 9, height = 5.5, dpi = 300)
}

# ==========================================================================
# Figure 4: Event study by competitor group
# ==========================================================================

if (!is.null(group_coefs) && nrow(group_coefs) > 0) {
  cat("Figure 4: Event study by group\n")

  grp_plot <- group_coefs[event_time >= -12 & event_time <= 25]
  grp_plot[, ci_lo := estimate - 1.96 * se]
  grp_plot[, ci_hi := estimate + 1.96 * se]

  p4 <- ggplot(grp_plot, aes(x = event_time, y = estimate,
                              color = n_group, fill = n_group)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "red", alpha = 0.5) +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.1, color = NA) +
    geom_line(linewidth = 0.7) +
    scale_color_manual(values = apep_colors[c(1, 3, 2)], name = "Pre-Entry N") +
    scale_fill_manual(values = apep_colors[c(1, 3, 2)], name = "Pre-Entry N") +
    labs(
      title = "Entry Effects by Market Concentration",
      subtitle = "Does the Nth competitor matter more in concentrated markets?",
      x = "Weeks Relative to Entry",
      y = "Change in Log Price",
      caption = paste0("Notes: Markets grouped by pre-entry competitor count. ",
                       "Low: 1-3, Medium: 4-8, High: 9+.\n",
                       "Event and calendar-week FE. SEs clustered by event.")
    ) +
    theme_apep()

  ggsave(file.path(fig_dir, "fig4_event_by_group.pdf"), p4,
         width = 9, height = 5.5, device = cairo_pdf)
  ggsave(file.path(fig_dir, "fig4_event_by_group.png"), p4,
         width = 9, height = 5.5, dpi = 300)
}

# ==========================================================================
# Figure 5: Within-market non-parametric curve with CIs
# ==========================================================================

cat("Figure 5: Within-market curve\n")

np_plot <- np_coefs[n_competitors <= 15]
np_plot[, ci_lo := estimate - 1.96 * se]
np_plot[, ci_hi := estimate + 1.96 * se]

p5 <- ggplot(np_plot, aes(x = n_competitors, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi),
              fill = apep_colors[1], alpha = 0.2) +
  geom_line(color = apep_colors[1], linewidth = 1) +
  geom_point(color = apep_colors[1], size = 3) +
  scale_x_continuous(breaks = 2:15) +
  labs(
    title = "Within-Market Competition Curve",
    subtitle = "Drug-market FE isolate the causal effect of additional competitors",
    x = "Number of Generic Competitors",
    y = "Effect on Log Price (Relative to N = 1)",
    caption = paste0("Notes: Non-parametric specification with drug-market and ",
                     "calendar-week FE.\n",
                     "All effects relative to monopoly (N = 1). ",
                     "4,512 markets, 51,643 market-weeks. ",
                     "SEs clustered by market.")
  ) +
  theme_apep()

ggsave(file.path(fig_dir, "fig5_within_market.pdf"), p5,
       width = 8, height = 5.5, device = cairo_pdf)
ggsave(file.path(fig_dir, "fig5_within_market.png"), p5,
       width = 8, height = 5.5, dpi = 300)

cat("\nAll figures saved to:", normalizePath(fig_dir), "\n")
