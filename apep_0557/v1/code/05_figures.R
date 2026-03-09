## ============================================================
## 05_figures.R — All figures for the paper
## Paper: Does Foreign Aid Buffer Oil Revenue Shocks?
##        Geocoded Evidence from Nigeria
## ============================================================

source("00_packages.R")

DATA_DIR <- "../data"
FIG_DIR  <- "../figures"
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)

## ============================================================
## Figure 1: Oil prices and conflict timeline
## ============================================================

cat("--- Figure 1: Oil price and conflict timeline ---\n")

national_ts  <- fread(file.path(DATA_DIR, "national_monthly.csv"))
national_ts[, ym := as.Date(ym)]

## Dual-axis plot: oil price (left) and conflict events (right)
scale_factor <- max(national_ts$total_events, na.rm = TRUE) /
                max(national_ts$mean_oil_price, na.rm = TRUE)

p1 <- ggplot(national_ts, aes(x = ym)) +
  geom_rect(aes(xmin = as.Date("2008-09-01"), xmax = as.Date("2009-06-01"),
                ymin = -Inf, ymax = Inf),
            fill = "grey90", alpha = 0.5) +
  geom_line(aes(y = mean_oil_price * scale_factor, color = "Oil Price ($/bbl)"),
            linewidth = 0.7) +
  geom_line(aes(y = total_events, color = "Conflict Events"),
            linewidth = 0.5) +
  scale_y_continuous(
    name = "Conflict Events (monthly)",
    sec.axis = sec_axis(~ . / scale_factor, name = "Brent Crude ($/bbl)")
  ) +
  scale_color_manual(values = c("Oil Price ($/bbl)" = "darkgoldenrod3",
                                 "Conflict Events" = "firebrick3")) +
  annotate("text", x = as.Date("2008-11-01"), y = max(national_ts$total_events) * 0.95,
           label = "Oil Crisis", fontface = "italic", size = 3, hjust = 0) +
  labs(x = NULL, color = NULL,
       title = "Oil Prices and Conflict in Nigeria, 1997\u20132014") +
  theme(legend.position = c(0.15, 0.9))

ggsave(file.path(FIG_DIR, "fig1_oil_conflict_timeline.pdf"), p1,
       width = 8, height = 4.5)
cat("Saved fig1_oil_conflict_timeline.pdf\n")

## ============================================================
## Figure 2: Map of aid projects and conflict
## ============================================================

cat("--- Figure 2: Aid distribution across states ---\n")

state_summary <- fread(file.path(DATA_DIR, "state_summary.csv"))

## Bar chart of aid projects by state
p2 <- ggplot(state_summary[order(-aid_projects)][1:25],
             aes(x = reorder(state, aid_projects), y = aid_projects)) +
  geom_col(aes(fill = factor(oil_producing)),
           width = 0.7) +
  scale_fill_manual(values = c("0" = "steelblue3", "1" = "darkgoldenrod3"),
                    labels = c("Non-oil", "Oil-producing"),
                    name = NULL) +
  coord_flip() +
  labs(x = NULL, y = "Cumulative Aid Projects (as of 2007)",
       title = "Geographic Distribution of Foreign Aid in Nigeria") +
  theme(legend.position = c(0.7, 0.2))

ggsave(file.path(FIG_DIR, "fig2_aid_distribution.pdf"), p2,
       width = 7, height = 6)
cat("Saved fig2_aid_distribution.pdf\n")

## ============================================================
## Figure 3: Event study
## ============================================================

cat("--- Figure 3: Event study ---\n")

es_coefs <- fread(file.path(DATA_DIR, "event_study_coefs.csv"))

## Add reference period at 0
ref_row <- data.table(term = "ref", estimate = 0, se = 0, tstat = 0,
                      pval = NA, event_time = -1, ci_lo = 0, ci_hi = 0)
es_plot <- rbind(es_coefs, ref_row, fill = TRUE)

p3 <- ggplot(es_plot, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "solid", color = "firebrick3",
             linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "steelblue3", alpha = 0.2) +
  geom_point(size = 1.5, color = "steelblue4") +
  geom_line(linewidth = 0.4, color = "steelblue4") +
  annotate("text", x = 0.5, y = max(es_plot$ci_hi, na.rm = TRUE) * 0.9,
           label = "Oil crisis\nbegins", fontface = "italic",
           size = 2.8, hjust = 0, color = "firebrick3") +
  labs(x = "Months Relative to Oil Crisis (Sep 2008)",
       y = expression(beta[t] ~ "(Log Aid " %*% " Month Indicator)"),
       title = "Event Study: Aid Exposure and Conflict") +
  scale_x_continuous(breaks = seq(-24, 24, by = 6))

ggsave(file.path(FIG_DIR, "fig3_event_study.pdf"), p3,
       width = 7, height = 4.5)
cat("Saved fig3_event_study.pdf\n")

## ============================================================
## Figure 4: Main coefficient comparison
## ============================================================

cat("--- Figure 4: Main coefficient comparison ---\n")

main_coefs <- fread(file.path(DATA_DIR, "main_coefs.csv"))

p4 <- ggplot(main_coefs, aes(x = reorder(spec, estimate), y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  color = "steelblue4", size = 0.5) +
  coord_flip() +
  labs(x = NULL, y = "Coefficient Estimate (95% CI)",
       title = "Main DiD Estimates Across Specifications")

ggsave(file.path(FIG_DIR, "fig4_main_coefs.pdf"), p4,
       width = 7, height = 4)
cat("Saved fig4_main_coefs.pdf\n")

## ============================================================
## Figure 5: Outcome heterogeneity
## ============================================================

cat("--- Figure 5: Outcome heterogeneity ---\n")

outcome_coefs <- fread(file.path(DATA_DIR, "outcome_coefs.csv"))

p5 <- ggplot(outcome_coefs, aes(x = reorder(outcome, estimate), y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  color = "steelblue4", size = 0.5) +
  coord_flip() +
  labs(x = NULL, y = "Coefficient Estimate (95% CI)",
       title = "Effect of Aid Exposure by Conflict Type")

ggsave(file.path(FIG_DIR, "fig5_outcome_heterogeneity.pdf"), p5,
       width = 7, height = 3.5)
cat("Saved fig5_outcome_heterogeneity.pdf\n")

## ============================================================
## Figure 6: Randomization inference distribution
## ============================================================

cat("--- Figure 6: Randomization inference ---\n")

ri_dist <- fread(file.path(DATA_DIR, "ri_permutation_dist.csv"))
ri_res  <- fread(file.path(DATA_DIR, "ri_results.csv"))
orig_coef <- ri_res$original_coef[1]

p6 <- ggplot(ri_dist, aes(x = perm_coef)) +
  geom_histogram(bins = 50, fill = "grey70", color = "grey50") +
  geom_vline(xintercept = orig_coef, color = "firebrick3",
             linewidth = 0.8, linetype = "dashed") +
  annotate("text", x = orig_coef, y = Inf,
           label = sprintf("Actual: %.3f\nRI p = %.3f",
                           orig_coef, ri_res$ri_pvalue[1]),
           vjust = 2, hjust = -0.1, size = 3, color = "firebrick3") +
  labs(x = "Permuted Coefficient", y = "Count",
       title = "Randomization Inference: Permutation Distribution")

ggsave(file.path(FIG_DIR, "fig6_ri_distribution.pdf"), p6,
       width = 6, height = 4)
cat("Saved fig6_ri_distribution.pdf\n")

## ============================================================
## Figure 7: Leave-one-out sensitivity
## ============================================================

cat("--- Figure 7: Leave-one-out ---\n")

loo <- fread(file.path(DATA_DIR, "loo_results.csv"))

p7 <- ggplot(loo, aes(x = reorder(dropped_state, estimate), y = estimate)) +
  geom_hline(yintercept = orig_coef, color = "firebrick3",
             linetype = "dashed", linewidth = 0.5) +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  color = "steelblue4", size = 0.3) +
  coord_flip() +
  labs(x = "Dropped State", y = "Coefficient Estimate",
       title = "Leave-One-Out Sensitivity",
       subtitle = "Dashed red line = full sample estimate")

ggsave(file.path(FIG_DIR, "fig7_leave_one_out.pdf"), p7,
       width = 7, height = 8)
cat("Saved fig7_leave_one_out.pdf\n")

## ============================================================
## Figure 8: Conflict trends by aid group
## ============================================================

cat("--- Figure 8: Parallel trends ---\n")

panel <- readRDS(file.path(DATA_DIR, "analysis_panel.rds"))

## Monthly conflict by high/low aid groups
group_ts <- panel[, .(
  mean_events = mean(n_events),
  mean_log_events = mean(log_events)
), by = .(ym, high_aid)]

group_ts[, aid_group := factor(high_aid,
  levels = c(0, 1),
  labels = c("Low Aid Exposure", "High Aid Exposure")
)]

p8 <- ggplot(group_ts, aes(x = ym, y = mean_log_events,
                            color = aid_group, linetype = aid_group)) +
  geom_vline(xintercept = as.Date("2008-09-01"), color = "grey50",
             linetype = "solid", linewidth = 0.5) +
  geom_line(linewidth = 0.6) +
  scale_color_manual(values = c("steelblue3", "firebrick3")) +
  annotate("text", x = as.Date("2008-11-01"),
           y = max(group_ts$mean_log_events) * 0.95,
           label = "Oil crisis", fontface = "italic", size = 2.8,
           hjust = 0) +
  labs(x = NULL, y = "Mean Log(Events + 1)",
       color = NULL, linetype = NULL,
       title = "Conflict Trends by Pre-Shock Aid Exposure") +
  theme(legend.position = c(0.2, 0.9))

ggsave(file.path(FIG_DIR, "fig8_parallel_trends.pdf"), p8,
       width = 8, height = 4.5)
cat("Saved fig8_parallel_trends.pdf\n")

## ============================================================
## Figure A1: Placebo and alternative shock dates
## ============================================================

cat("--- Figure A1: Placebo and alternative shocks ---\n")

placebos   <- fread(file.path(DATA_DIR, "placebo_results.csv"))
alt_shocks <- fread(file.path(DATA_DIR, "alt_shock_results.csv"))

## Combine for plotting
placebos[, type := "Placebo"]
setnames(placebos, "placebo_date", "date")
alt_shocks[, type := "Alternative"]
setnames(alt_shocks, "shock_date", "date")

combined <- rbind(placebos[, .(date, estimate, ci_lo, ci_hi, type)],
                  alt_shocks[, .(date, estimate, ci_lo, ci_hi, type)])
combined[, date := as.Date(date)]

## Add actual estimate
actual <- data.table(date = as.Date("2008-09-01"),
                     estimate = orig_coef,
                     ci_lo = orig_coef - 1.96 * ri_res$perm_sd[1],
                     ci_hi = orig_coef + 1.96 * ri_res$perm_sd[1],
                     type = "Actual")
combined <- rbind(combined, actual)

pA1 <- ggplot(combined, aes(x = date, y = estimate, color = type, shape = type)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi), size = 0.5) +
  scale_color_manual(values = c("Actual" = "firebrick3",
                                "Alternative" = "steelblue3",
                                "Placebo" = "grey50")) +
  labs(x = "Shock Date", y = "Coefficient Estimate",
       color = NULL, shape = NULL,
       title = "Sensitivity to Shock Timing and Placebo Tests")

ggsave(file.path(FIG_DIR, "figA1_placebo_alt_shocks.pdf"), pA1,
       width = 7, height = 4)
cat("Saved figA1_placebo_alt_shocks.pdf\n")

cat("\nAll figures complete.\n")
