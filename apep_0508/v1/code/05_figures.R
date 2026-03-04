## ============================================================
## 05_figures.R — All figures for the paper
## The Cost of Sponsorship: Kafala Reform and Firm Value
## ============================================================

source(file.path(dirname(normalizePath(sys.frame(1)$ofile)), "00_packages.R"))

results <- readRDS(file.path(data_dir, "main_results.rds"))
robust  <- readRDS(file.path(data_dir, "robustness_results.rds"))
dat     <- readRDS(file.path(data_dir, "analysis_ready.rds"))
dfm     <- dat$dfm
events  <- dat$events

## ===============================================================
## FIGURE 1: Event Study — Cumulative Abnormal Returns
## ===============================================================

## Compute CAAR by exposure group for the first event (law signing)
es_data <- results$es_cumulative %>%
  filter(event_id == 1) %>%
  mutate(
    group = ifelse(high_exposure, "High Exposure\n(Construction, Real Estate, Services)",
                   "Low Exposure\n(Banking, Insurance, Telecom)"),
    ci_lo = mean_cum_ar - 1.96 * se_cum_ar,
    ci_hi = mean_cum_ar + 1.96 * se_cum_ar
  )

fig1 <- ggplot(es_data, aes(x = event_time, y = mean_cum_ar * 100,
                              color = group, fill = group)) +
  geom_ribbon(aes(ymin = ci_lo * 100, ymax = ci_hi * 100), alpha = 0.15,
              color = NA) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40") +
  geom_hline(yintercept = 0, color = "grey60") +
  annotate("text", x = 0.5, y = max(es_data$ci_hi * 100, na.rm = TRUE) * 0.9,
           label = "Law\nSigned", hjust = 0, size = 3, color = "grey40") +
  scale_color_manual(values = c("#D55E00", "#0072B2")) +
  scale_fill_manual(values = c("#D55E00", "#0072B2")) +
  labs(
    title = "Cumulative Abnormal Returns Around Kafala Reform Announcement",
    subtitle = "Event: September 20, 2021 — Federal Decree-Law No. 33 Signed",
    x = "Trading Days Relative to Event",
    y = "Cumulative Abnormal Return (%)",
    color = NULL, fill = NULL
  ) +
  theme(legend.position = c(0.25, 0.2))

ggsave(file.path(fig_dir, "fig1_event_study.pdf"), fig1, width = 8, height = 5.5)
ggsave(file.path(fig_dir, "fig1_event_study.png"), fig1, width = 8, height = 5.5, dpi = 300)
cat("Figure 1 saved\n")

## ===============================================================
## FIGURE 2: Stacked Event Study — All Three Events
## ===============================================================

## Compute difference (High - Low) in CAAR for each event
es_diff <- results$es_cumulative %>%
  select(event_id, event_label, event_time, high_exposure, mean_cum_ar, se_cum_ar) %>%
  pivot_wider(names_from = high_exposure, values_from = c(mean_cum_ar, se_cum_ar),
              names_sep = "_") %>%
  mutate(
    diff = mean_cum_ar_TRUE - mean_cum_ar_FALSE,
    se_diff = sqrt(se_cum_ar_TRUE^2 + se_cum_ar_FALSE^2),
    ci_lo = diff - 1.96 * se_diff,
    ci_hi = diff + 1.96 * se_diff,
    event_label_short = case_when(
      event_id == 1 ~ "Event 1: Law Signed\n(Sept 20, 2021)",
      event_id == 2 ~ "Event 2: Regulations\n(Nov 15, 2021)",
      event_id == 3 ~ "Event 3: Effective Date\n(Feb 2, 2022)"
    )
  )

fig2 <- ggplot(es_diff, aes(x = event_time, y = diff * 100)) +
  geom_ribbon(aes(ymin = ci_lo * 100, ymax = ci_hi * 100), alpha = 0.15,
              fill = "#D55E00") +
  geom_line(color = "#D55E00", linewidth = 0.8) +
  geom_point(color = "#D55E00", size = 1.5) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40") +
  geom_hline(yintercept = 0, color = "grey60") +
  facet_wrap(~event_label_short, ncol = 3, scales = "free_y") +
  coord_cartesian(ylim = c(-30, 30)) +
  labs(
    title = "Differential Cumulative Abnormal Returns: High vs. Low Exposure Firms",
    subtitle = "Three kafala reform events. Negative values = high-exposure firms underperform.",
    x = "Trading Days Relative to Event",
    y = "Differential CAAR (%)\n(High Exposure minus Low Exposure)"
  )

ggsave(file.path(fig_dir, "fig2_stacked_events.pdf"), fig2, width = 10, height = 4.5)
ggsave(file.path(fig_dir, "fig2_stacked_events.png"), fig2, width = 10, height = 4.5, dpi = 300)
cat("Figure 2 saved\n")

## ===============================================================
## FIGURE 3: Dynamic DiD Coefficients
## ===============================================================

## Extract coefficients from the dynamic DiD
did_coefs <- as.data.frame(results$did_dynamic$coeftable)
did_coefs$term <- rownames(did_coefs)

# Parse the rel_week values from coefficient names
did_plot_data <- did_coefs %>%
  filter(grepl("rel_week", term)) %>%
  mutate(
    rel_week = as.numeric(gsub(".*::([-0-9]+):.*", "\\1", term)),
    ci_lo = Estimate - 1.96 * `Std. Error`,
    ci_hi = Estimate + 1.96 * `Std. Error`
  ) %>%
  arrange(rel_week)

fig3 <- ggplot(did_plot_data, aes(x = rel_week, y = Estimate * 100)) +
  geom_ribbon(aes(ymin = ci_lo * 100, ymax = ci_hi * 100), alpha = 0.15,
              fill = "#0072B2") +
  geom_line(color = "#0072B2", linewidth = 0.8) +
  geom_point(color = "#0072B2", size = 2) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40") +
  geom_hline(yintercept = 0, color = "grey60") +
  labs(
    title = "Dynamic Difference-in-Differences: High Exposure Firms",
    subtitle = "Bi-weekly bins. Reference period: [-10, 0) trading days before reform.",
    x = "Trading Days Relative to Reform (bi-weekly bins)",
    y = "Coefficient (percentage points)"
  )

ggsave(file.path(fig_dir, "fig3_dynamic_did.pdf"), fig3, width = 8, height = 5)
ggsave(file.path(fig_dir, "fig3_dynamic_did.png"), fig3, width = 8, height = 5, dpi = 300)
cat("Figure 3 saved\n")

## ===============================================================
## FIGURE 4: Randomization Inference Distribution
## ===============================================================

ri_df <- tibble(coef = robust$ri_coefs)

fig4 <- ggplot(ri_df, aes(x = coef * 100)) +
  geom_histogram(bins = 50, fill = "grey70", color = "grey50") +
  geom_vline(xintercept = robust$actual_coef * 100, color = "#D55E00",
             linewidth = 1, linetype = "solid") +
  annotate("text", x = robust$actual_coef * 100, y = Inf,
           label = paste0("Actual = ", round(robust$actual_coef * 100, 2), "%"),
           hjust = -0.1, vjust = 2, color = "#D55E00", fontface = "bold") +
  labs(
    title = "Randomization Inference: Null Distribution of Treatment Effects",
    subtitle = paste0("1,000 permutations of exposure labels. RI p-value = ",
                      round(robust$ri_pvalue, 3)),
    x = "Coefficient on High Exposure (%)",
    y = "Frequency"
  )

ggsave(file.path(fig_dir, "fig4_ri_distribution.pdf"), fig4, width = 7, height = 4.5)
ggsave(file.path(fig_dir, "fig4_ri_distribution.png"), fig4, width = 7, height = 4.5, dpi = 300)
cat("Figure 4 saved\n")

## ===============================================================
## FIGURE 5: Robustness — Alternative Event Windows
## ===============================================================

fig5 <- ggplot(robust$window_regs, aes(x = window, y = coef * 100)) +
  geom_point(size = 3, color = "#0072B2") +
  geom_errorbar(aes(ymin = ci_lo * 100, ymax = ci_hi * 100),
                width = 0.2, color = "#0072B2") +
  geom_hline(yintercept = 0, color = "grey60", linetype = "dashed") +
  coord_flip() +
  labs(
    title = "Robustness: CAR Estimates Across Alternative Event Windows",
    subtitle = "Coefficient on High Exposure indicator, 95% CI (firm-clustered SE)",
    x = "Event Window",
    y = "Differential CAR (%)"
  )

ggsave(file.path(fig_dir, "fig5_window_robustness.pdf"), fig5, width = 7, height = 4)
ggsave(file.path(fig_dir, "fig5_window_robustness.png"), fig5, width = 7, height = 4, dpi = 300)
cat("Figure 5 saved\n")

## ===============================================================
## FIGURE 6: Placebo Date Results
## ===============================================================

if (nrow(robust$placebo_results) > 0) {
  ## Compare actual vs placebo coefficients
  placebo_plot <- robust$placebo_results %>%
    mutate(type = "Placebo") %>%
    bind_rows(tibble(
      placebo_date = "Actual\n(Sept 20, 2021)",
      coef = robust$actual_coef,
      se = sqrt(diag(vcov(results$car_reg)))["high_exposureTRUE"],
      n = nobs(results$car_reg),
      ci_lo = robust$actual_coef - 1.96 * se,
      ci_hi = robust$actual_coef + 1.96 * se,
      significant = abs(robust$actual_coef / se) > 1.96,
      type = "Actual"
    )) %>%
    mutate(
      ci_lo = coef - 1.96 * se,
      ci_hi = coef + 1.96 * se
    )

  fig6 <- ggplot(placebo_plot, aes(x = placebo_date, y = coef * 100, color = type)) +
    geom_point(size = 3) +
    geom_errorbar(aes(ymin = ci_lo * 100, ymax = ci_hi * 100), width = 0.2) +
    geom_hline(yintercept = 0, color = "grey60", linetype = "dashed") +
    scale_color_manual(values = c("Actual" = "#D55E00", "Placebo" = "#0072B2")) +
    coord_flip() +
    labs(
      title = "Placebo Test: Actual vs. Non-Event Dates",
      subtitle = "High-exposure coefficient should only be significant at actual reform date",
      x = NULL,
      y = "Differential CAR (%)",
      color = NULL
    )

  ggsave(file.path(fig_dir, "fig6_placebo_dates.pdf"), fig6, width = 7, height = 4.5)
  ggsave(file.path(fig_dir, "fig6_placebo_dates.png"), fig6, width = 7, height = 4.5, dpi = 300)
  cat("Figure 6 saved\n")
}

## ===============================================================
## FIGURE 7: Time Series of Cumulative Returns by Group
## ===============================================================

## Long-horizon view: cumulative returns from Jan 2021 to June 2022
cum_ret <- dfm %>%
  filter(date >= as.Date("2021-01-01"), date <= as.Date("2022-06-30")) %>%
  arrange(ticker, date) %>%
  group_by(ticker) %>%
  mutate(cum_ret = cumprod(1 + ret_w) - 1) %>%
  ungroup() %>%
  group_by(date, high_exposure) %>%
  summarise(
    mean_cum_ret = mean(cum_ret, na.rm = TRUE),
    se = sd(cum_ret, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  ) %>%
  mutate(
    group = ifelse(high_exposure, "High Exposure", "Low Exposure"),
    ci_lo = mean_cum_ret - 1.96 * se,
    ci_hi = mean_cum_ret + 1.96 * se
  )

## Add 30-day moving average for smoothed trend
cum_ret <- cum_ret %>%
  arrange(group, date) %>%
  group_by(group) %>%
  mutate(ma30 = zoo::rollmean(mean_cum_ret, k = 30, fill = NA, align = "right")) %>%
  ungroup()

fig7 <- ggplot(cum_ret, aes(x = date, y = mean_cum_ret * 100, color = group, fill = group)) +
  geom_ribbon(aes(ymin = ci_lo * 100, ymax = ci_hi * 100), alpha = 0.1, color = NA) +
  geom_line(linewidth = 0.4, alpha = 0.4) +
  geom_line(aes(y = ma30 * 100), linewidth = 1.0) +
  geom_vline(xintercept = as.Date("2021-09-20"), linetype = "dashed",
             color = "grey40", linewidth = 0.5) +
  geom_vline(xintercept = as.Date("2021-11-15"), linetype = "dotted",
             color = "grey40", linewidth = 0.5) +
  geom_vline(xintercept = as.Date("2022-02-02"), linetype = "dashed",
             color = "grey40", linewidth = 0.5) +
  annotate("text", x = as.Date("2021-09-20"), y = Inf,
           label = "Law\nSigned", hjust = -0.1, vjust = 1.5, size = 2.5) +
  annotate("text", x = as.Date("2021-11-15"), y = Inf,
           label = "Regs", hjust = -0.1, vjust = 1.5, size = 2.5) +
  annotate("text", x = as.Date("2022-02-02"), y = Inf,
           label = "Effective", hjust = -0.1, vjust = 1.5, size = 2.5) +
  scale_color_manual(values = c("#D55E00", "#0072B2")) +
  scale_fill_manual(values = c("#D55E00", "#0072B2")) +
  labs(
    title = "Cumulative Returns: High vs. Low Kafala Exposure Firms",
    subtitle = "January 2021 to June 2022. Bold lines = 30-day moving average. Vertical lines mark reform milestones.",
    x = NULL,
    y = "Cumulative Return (%)",
    color = NULL, fill = NULL
  )

ggsave(file.path(fig_dir, "fig7_cumulative_returns.pdf"), fig7, width = 9, height = 5)
ggsave(file.path(fig_dir, "fig7_cumulative_returns.png"), fig7, width = 9, height = 5, dpi = 300)
cat("Figure 7 saved\n")

cat("\n=== ALL FIGURES GENERATED ===\n")
