## 05_figures.R — Generate all figures
## apep_0575: BRRD Bail-In Risk and Household Deposit Structure

source("00_packages.R")

data_dir <- "../data/"
fig_dir <- "../figures/"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

hh <- fread(paste0(data_dir, "hh_panel.csv"))
hh[, date := as.Date(date)]
brrd <- fread(paste0(data_dir, "brrd_transposition_dates.csv"))
brrd[, transposition_date := as.Date(transposition_date)]

# ===========================================================================
# FIGURE 1: Treatment Rollout — BRRD Transposition Timeline
# ===========================================================================

brrd_sorted <- brrd[order(transposition_date)]
brrd_sorted[, country_label := paste0(country_name, " (", country, ")")]
brrd_sorted[, country_label := factor(country_label,
  levels = rev(brrd_sorted$country_label))]

fig1 <- ggplot(brrd_sorted, aes(x = transposition_date, y = country_label)) +
  geom_point(size = 2.5, color = "#2166AC") +
  geom_vline(xintercept = as.Date("2014-12-31"), linetype = "dashed",
             color = "red", linewidth = 0.5) +
  geom_vline(xintercept = as.Date("2016-01-01"), linetype = "dotted",
             color = "darkred", linewidth = 0.5) +
  annotate("text", x = as.Date("2014-12-31"), y = 28, label = "Transposition\ndeadline",
           hjust = 1.1, size = 2.8, color = "red") +
  annotate("text", x = as.Date("2016-01-01"), y = 28, label = "Bail-in tool\nmandatory",
           hjust = -0.1, size = 2.8, color = "darkred") +
  scale_x_date(date_labels = "%b %Y", date_breaks = "3 months") +
  labs(x = NULL, y = NULL,
       title = "BRRD National Transposition Dates",
       subtitle = "Directive 2014/59/EU transposition across 27 EU member states") +
  theme(axis.text.y = element_text(size = 7),
        axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(paste0(fig_dir, "fig1_treatment_rollout.pdf"), fig1,
       width = 7, height = 8)
cat("Figure 1 saved: treatment rollout\n")

# ===========================================================================
# FIGURE 2: Event Study — Overnight Deposit Share (CS-DiD)
# ===========================================================================

es_file <- paste0(data_dir, "cs_event_study_overnight.csv")
if (file.exists(es_file)) {
  cs_es <- fread(es_file)

  fig2 <- ggplot(cs_es, aes(x = rel_time, y = att)) +
    geom_hline(yintercept = 0, color = "grey60", linewidth = 0.3) +
    geom_vline(xintercept = -0.5, linetype = "dashed", color = "red",
               linewidth = 0.4) +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
                fill = "#2166AC", alpha = 0.15) +
    geom_line(color = "#2166AC", linewidth = 0.6) +
    geom_point(color = "#2166AC", size = 1.5) +
    scale_x_continuous(breaks = seq(-24, 24, 6)) +
    labs(x = "Months relative to BRRD transposition",
         y = "ATT (pp)",
         title = "Event Study: Household Overnight Deposit Share",
         subtitle = "Callaway-Sant'Anna estimates, not-yet-treated comparison group") +
    theme(plot.margin = margin(5, 10, 5, 5))

  ggsave(paste0(fig_dir, "fig2_event_study_overnight.pdf"), fig2,
         width = 7, height = 4.5)
  cat("Figure 2 saved: event study overnight\n")
}

# ===========================================================================
# FIGURE 3: Event Study — Agreed Maturity Share
# ===========================================================================

es_agreed_file <- paste0(data_dir, "cs_event_study_agreed.csv")
if (file.exists(es_agreed_file)) {
  cs_es_agreed <- fread(es_agreed_file)

  fig3 <- ggplot(cs_es_agreed, aes(x = rel_time, y = att)) +
    geom_hline(yintercept = 0, color = "grey60", linewidth = 0.3) +
    geom_vline(xintercept = -0.5, linetype = "dashed", color = "red",
               linewidth = 0.4) +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
                fill = "#B2182B", alpha = 0.15) +
    geom_line(color = "#B2182B", linewidth = 0.6) +
    geom_point(color = "#B2182B", size = 1.5) +
    scale_x_continuous(breaks = seq(-24, 24, 6)) +
    labs(x = "Months relative to BRRD transposition",
         y = "ATT (pp)",
         title = "Event Study: Household Agreed-Maturity Deposit Share",
         subtitle = "Callaway-Sant'Anna estimates, not-yet-treated comparison group") +
    theme(plot.margin = margin(5, 10, 5, 5))

  ggsave(paste0(fig_dir, "fig3_event_study_agreed.pdf"), fig3,
         width = 7, height = 4.5)
  cat("Figure 3 saved: event study agreed maturity\n")
}

# ===========================================================================
# FIGURE 4: Deposit Composition Trends by Early vs Late Transposers
# ===========================================================================

# Split countries into early (before median) and late (after median) transposers
median_date <- median(brrd$transposition_date)
brrd[, timing_group := fifelse(transposition_date <= median_date, "Early", "Late")]

hh <- merge(hh, brrd[, .(country, timing_group)], by = "country", all.x = TRUE)

trends <- hh[, .(
  mean_overnight = mean(share_overnight, na.rm = TRUE),
  mean_agreed = mean(share_agreed, na.rm = TRUE)
), by = .(date, timing_group)]

fig4a <- ggplot(trends, aes(x = date, y = mean_overnight, color = timing_group)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = as.Date("2014-12-31"), linetype = "dashed",
             color = "grey40", linewidth = 0.4) +
  annotate("text", x = as.Date("2014-12-31"), y = max(trends$mean_overnight),
           label = "Deadline", hjust = 1.1, size = 2.8, color = "grey40") +
  scale_color_manual(values = c("Early" = "#2166AC", "Late" = "#B2182B"),
                     name = "Transposition timing") +
  labs(x = NULL, y = "Share of total deposits",
       title = "Overnight Deposit Share: Early vs. Late Transposers") +
  theme(legend.position = c(0.15, 0.85))

fig4b <- ggplot(trends, aes(x = date, y = mean_agreed, color = timing_group)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = as.Date("2014-12-31"), linetype = "dashed",
             color = "grey40", linewidth = 0.4) +
  scale_color_manual(values = c("Early" = "#2166AC", "Late" = "#B2182B"),
                     name = "Transposition timing") +
  labs(x = NULL, y = "Share of total deposits",
       title = "Agreed-Maturity Deposit Share: Early vs. Late Transposers") +
  theme(legend.position = c(0.85, 0.85))

ggsave(paste0(fig_dir, "fig4a_trends_overnight.pdf"), fig4a,
       width = 7, height = 4)
ggsave(paste0(fig_dir, "fig4b_trends_agreed.pdf"), fig4b,
       width = 7, height = 4)
cat("Figure 4 saved: composition trends\n")

# ===========================================================================
# FIGURE 5: Treatment Intensity — Scatter
# ===========================================================================

# Post-BRRD change in overnight share vs pre-BRRD uninsured share
change_data <- hh[, .(
  pre_overnight = mean(share_overnight[pre_brrd == 1], na.rm = TRUE),
  post_overnight = mean(share_overnight[post_brrd == 1], na.rm = TRUE)
), by = .(country, uninsured_share, country_name)]
change_data[, change_overnight := post_overnight - pre_overnight]

fig5 <- ggplot(change_data, aes(x = uninsured_share, y = change_overnight)) +
  geom_hline(yintercept = 0, color = "grey60", linewidth = 0.3) +
  geom_smooth(method = "lm", se = TRUE, color = "#2166AC",
              fill = "#2166AC", alpha = 0.15, linewidth = 0.6) +
  geom_point(size = 2, color = "#2166AC") +
  geom_text(aes(label = country), size = 2.3, nudge_y = 0.003, color = "grey30") +
  scale_x_continuous(labels = scales::percent_format()) +
  labs(x = "Pre-BRRD uninsured deposit share",
       y = "Change in overnight share (pp)",
       title = "Treatment Intensity: Deposit Restructuring vs. Bail-In Exposure",
       subtitle = NULL) +
  theme(plot.margin = margin(5, 10, 5, 5))

ggsave(paste0(fig_dir, "fig5_intensity_scatter.pdf"), fig5,
       width = 7, height = 5)
cat("Figure 5 saved: intensity scatter\n")

# ===========================================================================
# FIGURE 6: Household vs Corporate Placebo
# ===========================================================================

nfc <- fread(paste0(data_dir, "nfc_panel.csv"))
nfc[, date := as.Date(date)]

hh_trend <- hh[, .(overnight_share = mean(share_overnight, na.rm = TRUE)),
               by = .(date)]
hh_trend[, sector := "Households"]

nfc_trend <- nfc[, .(overnight_share = mean(share_overnight, na.rm = TRUE)),
                 by = .(date)]
nfc_trend[, sector := "Non-financial corporations"]

both <- rbind(hh_trend, nfc_trend)

fig6 <- ggplot(both, aes(x = date, y = overnight_share, color = sector)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = as.Date("2014-12-31"), linetype = "dashed",
             color = "grey40", linewidth = 0.4) +
  scale_color_manual(values = c("Households" = "#2166AC",
                                 "Non-financial corporations" = "#B2182B"),
                     name = NULL) +
  labs(x = NULL, y = "Overnight deposit share",
       title = "Household vs. Corporate Overnight Deposit Share",
       subtitle = NULL) +
  theme(legend.position = c(0.3, 0.85))

ggsave(paste0(fig_dir, "fig6_placebo_sectors.pdf"), fig6,
       width = 7, height = 4.5)
cat("Figure 6 saved: sector placebo\n")

# ===========================================================================
# FIGURE 7: Leave-One-Out Sensitivity
# ===========================================================================

loo_file <- paste0(data_dir, "loo_results.csv")
if (file.exists(loo_file)) {
  loo <- fread(loo_file)
  main_est <- fread(paste0(data_dir, "main_results.csv"))
  baseline <- main_est[specification == "TWFE Overnight", as.numeric(estimate)]

  fig7 <- ggplot(loo, aes(x = reorder(dropped, estimate), y = estimate)) +
    geom_hline(yintercept = baseline, linetype = "dashed", color = "red",
               linewidth = 0.4) +
    geom_point(size = 2, color = "#2166AC") +
    geom_errorbar(aes(ymin = estimate - 1.96 * se, ymax = estimate + 1.96 * se),
                  width = 0.2, color = "#2166AC", linewidth = 0.3) +
    coord_flip() +
    labs(x = "Dropped country", y = "Estimate (pp)",
         title = "Leave-One-Out Sensitivity",
         subtitle = "Dashed line: full-sample estimate") +
    theme(axis.text.y = element_text(size = 7))

  ggsave(paste0(fig_dir, "fig7_leave_one_out.pdf"), fig7,
         width = 6, height = 7)
  cat("Figure 7 saved: leave-one-out\n")
}

# ===========================================================================
# FIGURE 8: Randomization Inference Distribution
# ===========================================================================

ri_dist_file <- paste0(data_dir, "ri_distribution.csv")
if (file.exists(ri_dist_file)) {
  ri_dist <- fread(ri_dist_file)
  ri_meta <- fread(paste0(data_dir, "ri_results.csv"))

  fig8 <- ggplot(ri_dist, aes(x = estimate)) +
    geom_histogram(bins = 50, fill = "grey80", color = "grey60") +
    geom_vline(xintercept = ri_meta$actual, color = "red",
               linewidth = 0.8, linetype = "solid") +
    annotate("text", x = ri_meta$actual, y = Inf, label = "Actual estimate",
             hjust = -0.1, vjust = 2, color = "red", size = 3) +
    labs(x = "Permuted estimates",
         y = "Count",
         title = "Randomization Inference Distribution",
         subtitle = sprintf("p = %.3f (two-sided, %d permutations)",
                            ri_meta$ri_p_value, ri_meta$n_perms))

  ggsave(paste0(fig_dir, "fig8_ri_distribution.pdf"), fig8,
         width = 6, height = 4)
  cat("Figure 8 saved: RI distribution\n")
}

cat("\nAll figures generated.\n")
