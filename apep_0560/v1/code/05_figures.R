# =============================================================================
# 05_figures.R — Generate all figures
# APEP-0560: Market Discipline and Mining Safety
# =============================================================================

source("00_packages.R")

cat("=== Generating figures ===\n")

# =============================================================================
# Figure 1: Event Study — Overall Cumulative Abnormal Returns
# =============================================================================
cat("Figure 1: Overall event study...\n")

daily_ar <- fread("../data/daily_ar_overall.csv")

# Compute cumulative CARs with proper CIs
daily_ar[, `:=`(
  car_ci_upper = car + 1.96 * se_ar * sqrt(seq_len(.N)),
  car_ci_lower = car - 1.96 * se_ar * sqrt(seq_len(.N))
)]

p1 <- ggplot(daily_ar, aes(x = event_day, y = car * 100)) +
  geom_ribbon(aes(ymin = car_ci_lower * 100, ymax = car_ci_upper * 100),
              alpha = 0.2, fill = "steelblue") +
  geom_line(linewidth = 1, color = "steelblue") +
  geom_point(size = 2, color = "steelblue") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", alpha = 0.7) +
  geom_hline(yintercept = 0, linetype = "solid", color = "gray50") +
  annotate("text", x = -0.3, y = max(daily_ar$car_ci_upper * 100, na.rm = TRUE),
           label = "Event", hjust = 0, color = "red", size = 3.5) +
  scale_x_continuous(breaks = seq(-5, 10, 1)) +
  labs(
    title = "Cumulative Abnormal Returns Around Tailings Dam Failures",
    subtitle = "All peer mining firms, market model benchmark",
    x = "Trading Days Relative to Failure",
    y = "Cumulative Abnormal Return (%)",
    caption = "95% confidence intervals shown."
  )

ggsave("../figures/fig1_event_study_overall.pdf", p1, width = 8, height = 5)

# =============================================================================
# Figure 2: Event Study by Tailings Dam Ownership (H1)
# =============================================================================
cat("Figure 2: By tailings ownership...\n")

daily_tailings <- fread("../data/daily_ar_by_tailings.csv")

p2 <- ggplot(daily_tailings,
             aes(x = event_day, y = car * 100,
                 color = factor(has_tailings_dams,
                                labels = c("No Tailings Dams (Placebo)",
                                           "Operates Tailings Dams")))) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", alpha = 0.5) +
  geom_hline(yintercept = 0, color = "gray50") +
  scale_color_manual(values = c("No Tailings Dams (Placebo)" = "gray50",
                                "Operates Tailings Dams" = "darkred")) +
  scale_x_continuous(breaks = seq(-5, 10, 1)) +
  labs(
    title = "Contagion by Tailings Dam Exposure",
    subtitle = "Firms with tailings dams vs. streaming/royalty companies (built-in placebo)",
    x = "Trading Days Relative to Failure",
    y = "Cumulative Abnormal Return (%)",
    color = NULL
  )

ggsave("../figures/fig2_event_study_tailings.pdf", p2, width = 8, height = 5)

# =============================================================================
# Figure 3: Event Study by GISTM Period (H4)
# =============================================================================
cat("Figure 3: Pre vs post GISTM...\n")

daily_gistm <- fread("../data/daily_ar_by_gistm.csv")

p3 <- ggplot(daily_gistm,
             aes(x = event_day, y = car * 100,
                 color = factor(post_gistm,
                                labels = c("Pre-GISTM (before Aug 2020)",
                                           "Post-GISTM (Aug 2020+)")))) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", alpha = 0.5) +
  geom_hline(yintercept = 0, color = "gray50") +
  scale_color_manual(values = c("Pre-GISTM (before Aug 2020)" = "darkorange",
                                "Post-GISTM (Aug 2020+)" = "darkgreen")) +
  scale_x_continuous(breaks = seq(-5, 10, 1)) +
  labs(
    title = "Did GISTM Reduce Stock Market Contagion?",
    subtitle = "Peer firm CARs before vs. after voluntary safety standard adoption",
    x = "Trading Days Relative to Failure",
    y = "Cumulative Abnormal Return (%)",
    color = NULL
  )

ggsave("../figures/fig3_event_study_gistm.pdf", p3, width = 8, height = 5)

# =============================================================================
# Figure 4: Event Study by Commodity Match (H2)
# =============================================================================
cat("Figure 4: Same vs different commodity...\n")

daily_commodity <- fread("../data/daily_ar_by_commodity.csv")

p4 <- ggplot(daily_commodity,
             aes(x = event_day, y = car * 100,
                 color = factor(same_commodity,
                                labels = c("Different Commodity", "Same Commodity")))) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", alpha = 0.5) +
  geom_hline(yintercept = 0, color = "gray50") +
  scale_color_manual(values = c("Different Commodity" = "gray50",
                                "Same Commodity" = "purple4")) +
  scale_x_continuous(breaks = seq(-5, 10, 1)) +
  labs(
    title = "Contagion by Commodity Exposure",
    subtitle = "Peers mining the same commodity as the failure vs. different commodities",
    x = "Trading Days Relative to Failure",
    y = "Cumulative Abnormal Return (%)",
    color = NULL
  )

ggsave("../figures/fig4_event_study_commodity.pdf", p4, width = 8, height = 5)

# =============================================================================
# Figure 5: Event Study by Severity (H5)
# =============================================================================
cat("Figure 5: By event severity...\n")

daily_severity <- fread("../data/daily_ar_by_severity.csv")

p5 <- ggplot(daily_severity,
             aes(x = event_day, y = car * 100,
                 color = severity, linetype = severity)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", alpha = 0.5) +
  geom_hline(yintercept = 0, color = "gray50") +
  scale_color_manual(values = c("Major" = "darkred", "Fatal" = "darkorange",
                                "Other" = "gray50")) +
  scale_linetype_manual(values = c("Major" = "solid", "Fatal" = "dashed",
                                   "Other" = "dotted")) +
  scale_x_continuous(breaks = seq(-5, 10, 1)) +
  labs(
    title = "Contagion Intensity by Disaster Severity",
    subtitle = "Major (10+ deaths), Fatal (any deaths), Other (no deaths)",
    x = "Trading Days Relative to Failure",
    y = "Cumulative Abnormal Return (%)",
    color = "Severity", linetype = "Severity"
  )

ggsave("../figures/fig5_event_study_severity.pdf", p5, width = 8, height = 5)

# =============================================================================
# Figure 6: Placebo Distribution
# =============================================================================
cat("Figure 6: Placebo distribution...\n")

placebo_dt <- fread("../data/placebo_distribution.csv")
actual_result <- fread("../data/placebo_test_result.csv")

p6 <- ggplot(placebo_dt, aes(x = placebo_car)) +
  geom_histogram(bins = 40, fill = "gray70", color = "white", alpha = 0.8) +
  geom_vline(xintercept = actual_result$actual_car, color = "red",
             linewidth = 1.2, linetype = "dashed") +
  annotate("text", x = actual_result$actual_car,
           y = Inf, label = sprintf("Actual CAR = %.3f%%", actual_result$actual_car),
           hjust = -0.1, vjust = 2, color = "red", fontface = "bold", size = 4) +
  labs(
    title = "Placebo Test: Random Event Dates",
    subtitle = sprintf("200 permutations of pseudo-events | p-value = %.3f",
                        actual_result$p_value),
    x = "Mean CAR (%)",
    y = "Frequency"
  )

ggsave("../figures/fig6_placebo_distribution.pdf", p6, width = 8, height = 5)

# =============================================================================
# Figure 7: Leave-One-Event-Out Stability
# =============================================================================
cat("Figure 7: Leave-one-out...\n")

loo_dt <- fread("../data/loo_results.csv")

p7 <- ggplot(loo_dt, aes(x = reorder(factor(dropped_event), mean_car),
                          y = mean_car)) +
  geom_point(size = 2, color = "steelblue") +
  geom_hline(yintercept = mean(loo_dt$mean_car), linetype = "dashed",
             color = "red") +
  coord_flip() +
  labs(
    title = "Leave-One-Event-Out Stability",
    subtitle = "Mean CAR when each event is excluded; red line = full sample mean",
    x = "Excluded Event",
    y = "Mean CAR (%)"
  ) +
  theme(axis.text.y = element_text(size = 6))

ggsave("../figures/fig7_loo_stability.pdf", p7, width = 8, height = 7)

# =============================================================================
# Figure 8: Timeline of Events
# =============================================================================
cat("Figure 8: Event timeline...\n")

events <- fread("../data/events_analysis.csv")
events[, event_date := as.Date(event_date)]

p8 <- ggplot(events, aes(x = event_date, y = 1)) +
  geom_segment(aes(xend = event_date, yend = 0,
                    color = severity), alpha = 0.6) +
  geom_point(aes(size = ifelse(has_fatalities, fatality_count + 1, 1),
                 color = severity), alpha = 0.7) +
  geom_vline(xintercept = as.Date("2020-08-05"), linetype = "dashed",
             color = "darkgreen", linewidth = 0.8) +
  annotate("text", x = as.Date("2020-08-05"), y = 1.05,
           label = "GISTM Adopted\n(Aug 2020)", hjust = 0, size = 3,
           color = "darkgreen") +
  scale_color_manual(values = c("Major" = "darkred", "Fatal" = "darkorange",
                                "Large Release" = "steelblue", "Other" = "gray60")) +
  scale_size_continuous(range = c(1, 8), guide = "none") +
  scale_x_date(date_breaks = "5 years", date_labels = "%Y") +
  ylim(0, 1.15) +
  labs(
    title = "Timeline of Tailings Dam Failures in Analysis Sample",
    subtitle = "Size proportional to fatality count; dashed line marks GISTM adoption",
    x = NULL,
    y = NULL,
    color = "Severity"
  ) +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(),
        panel.grid.major.y = element_blank())

ggsave("../figures/fig8_event_timeline.pdf", p8, width = 10, height = 4)

cat("=== ALL FIGURES GENERATED ===\n")
