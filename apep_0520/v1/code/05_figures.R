## ============================================================================
## 05_figures.R — All figures for the paper
## ============================================================================

source("00_packages.R")

DATA <- "../data"
FIGS <- "../figures"
dir.create(FIGS, showWarnings = FALSE)

main_sample <- readRDS(file.path(DATA, "main_sample.rds"))

## ---- Figure 1: Event Study — BH Providers (Main Result) ----
es_bh <- fread(file.path(DATA, "es_bh_providers.csv"))

fig1 <- ggplot(es_bh, aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red3", alpha = 0.6) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), fill = "steelblue", alpha = 0.2) +
  geom_point(size = 1.8, color = "steelblue") +
  geom_line(color = "steelblue", linewidth = 0.5) +
  labs(
    title = "Effect of 1115 SUD Waivers on Behavioral Health Provider Supply",
    subtitle = "Callaway-Sant'Anna ATT by months relative to waiver approval",
    x = "Months Relative to Waiver Approval",
    y = "ATT (Log Active BH Providers)",
    caption = "Notes: Shaded area = 95% CI. Red dashed line = waiver approval. Never-treated states as controls."
  ) +
  scale_x_continuous(breaks = seq(-12, 36, 6)) +
  theme(plot.caption = element_text(hjust = 0, size = 8))

ggsave(file.path(FIGS, "fig1_event_study_bh.pdf"), fig1, width = 8, height = 5)
ggsave(file.path(FIGS, "fig1_event_study_bh.png"), fig1, width = 8, height = 5, dpi = 300)

## ---- Figure 2: Event Study — SUD-Specific Providers ----
es_sud <- fread(file.path(DATA, "es_sud_providers.csv"))

fig2 <- ggplot(es_sud, aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red3", alpha = 0.6) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), fill = "darkgreen", alpha = 0.2) +
  geom_point(size = 1.8, color = "darkgreen") +
  geom_line(color = "darkgreen", linewidth = 0.5) +
  labs(
    title = "Effect on SUD-Specific Provider Supply",
    subtitle = "H-codes for detox, residential SUD, and methadone administration",
    x = "Months Relative to Waiver Approval",
    y = "ATT (Log SUD Providers)"
  ) +
  scale_x_continuous(breaks = seq(-12, 36, 6))

ggsave(file.path(FIGS, "fig2_event_study_sud.pdf"), fig2, width = 8, height = 5)
ggsave(file.path(FIGS, "fig2_event_study_sud.png"), fig2, width = 8, height = 5, dpi = 300)

## ---- Figure 3: Placebo — Personal Care T-codes ----
es_placebo <- fread(file.path(DATA, "es_placebo.csv"))

fig3 <- ggplot(es_placebo, aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red3", alpha = 0.6) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), fill = "gray60", alpha = 0.2) +
  geom_point(size = 1.8, color = "gray40") +
  geom_line(color = "gray40", linewidth = 0.5) +
  labs(
    title = "Placebo Test: Personal Care Providers (T-codes)",
    subtitle = "HCBS services unrelated to SUD — expect null effect",
    x = "Months Relative to Waiver Approval",
    y = "ATT (Log Personal Care Providers)"
  ) +
  scale_x_continuous(breaks = seq(-12, 36, 6))

ggsave(file.path(FIGS, "fig3_placebo.pdf"), fig3, width = 8, height = 5)
ggsave(file.path(FIGS, "fig3_placebo.png"), fig3, width = 8, height = 5, dpi = 300)

## ---- Figure 4: Multi-Panel Event Study (BH + SUD + MAT + Placebo) ----
es_mat <- fread(file.path(DATA, "es_mat_providers.csv"))

es_all <- rbindlist(list(es_bh, es_sud, es_mat, es_placebo))
es_all[, outcome := factor(outcome, levels = c(
  "BH Providers (log)", "SUD Providers (log)",
  "MAT Providers (log)", "Personal Care Providers (log) [PLACEBO]"
))]

fig4 <- ggplot(es_all, aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red3", alpha = 0.4) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), fill = "steelblue", alpha = 0.15) +
  geom_point(size = 1.2, color = "steelblue") +
  geom_line(color = "steelblue", linewidth = 0.4) +
  facet_wrap(~outcome, scales = "free_y", ncol = 2) +
  labs(
    title = "Event Study: All Outcomes",
    subtitle = "CS-DiD ATT by months relative to waiver; never-treated controls",
    x = "Months Relative to Waiver Approval",
    y = "ATT"
  ) +
  scale_x_continuous(breaks = seq(-12, 36, 12))

ggsave(file.path(FIGS, "fig4_multipanel_es.pdf"), fig4, width = 10, height = 7)
ggsave(file.path(FIGS, "fig4_multipanel_es.png"), fig4, width = 10, height = 7, dpi = 300)

## ---- Figure 5: Extensive vs. Intensive Margin ----
es_entry <- fread(file.path(DATA, "es_entry.csv"))
es_benef <- fread(file.path(DATA, "es_bh_beneficiaries.csv"))

es_mechanism <- rbindlist(list(es_entry, es_benef))
es_mechanism[, outcome := factor(outcome, levels = c(
  "New BH Provider Entry (log)", "BH Beneficiaries (log)"
))]

fig5 <- ggplot(es_mechanism, aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red3", alpha = 0.4) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), fill = "darkorange", alpha = 0.15) +
  geom_point(size = 1.5, color = "darkorange") +
  geom_line(color = "darkorange", linewidth = 0.4) +
  facet_wrap(~outcome, scales = "free_y") +
  labs(
    title = "Mechanism Decomposition: Entry and Access",
    subtitle = "New provider entry (extensive margin) and beneficiaries served",
    x = "Months Relative to Waiver Approval",
    y = "ATT"
  ) +
  scale_x_continuous(breaks = seq(-12, 36, 12))

ggsave(file.path(FIGS, "fig5_mechanism.pdf"), fig5, width = 10, height = 4.5)
ggsave(file.path(FIGS, "fig5_mechanism.png"), fig5, width = 10, height = 4.5, dpi = 300)

## ---- Figure 6: Randomization Inference Distribution ----
ri_dist <- fread(file.path(DATA, "ri_distribution.csv"))
ri_result <- fread(file.path(DATA, "ri_result.csv"))

fig6 <- ggplot(ri_dist, aes(x = coef)) +
  geom_histogram(bins = 50, fill = "gray70", color = "white") +
  geom_vline(xintercept = ri_result$observed_coef, color = "red3",
             linewidth = 1, linetype = "solid") +
  labs(
    title = "Randomization Inference: BH Provider Supply",
    subtitle = sprintf("Observed coefficient (red) vs. %d permutations. RI p = %.3f",
                       ri_result$n_permutations, ri_result$ri_p_value),
    x = "Permuted TWFE Coefficient",
    y = "Frequency"
  )

ggsave(file.path(FIGS, "fig6_ri.pdf"), fig6, width = 7, height = 4.5)
ggsave(file.path(FIGS, "fig6_ri.png"), fig6, width = 7, height = 4.5, dpi = 300)

## ---- Figure 7: Raw Trends (Treated vs. Control) ----
# Average outcome over time for treated (post-2018 waivers) vs. never-treated
trend_data <- main_sample[, .(
  bh_providers_avg = mean(bh_providers),
  sud_providers_avg = mean(sud_providers),
  pc_providers_avg = mean(pc_providers)
), by = .(month_date, group = fifelse(is.na(waiver_date), "Never Treated", "Treated (post-2018)"))]

fig7 <- ggplot(trend_data, aes(x = month_date, y = bh_providers_avg, color = group)) +
  geom_line(linewidth = 0.7) +
  scale_color_manual(values = c("Treated (post-2018)" = "steelblue", "Never Treated" = "gray50")) +
  labs(
    title = "Raw Trends: BH Providers by Treatment Status",
    subtitle = "Average active behavioral health billing providers per state",
    x = NULL,
    y = "Average BH Providers",
    color = NULL
  )

ggsave(file.path(FIGS, "fig7_raw_trends.pdf"), fig7, width = 8, height = 5)
ggsave(file.path(FIGS, "fig7_raw_trends.png"), fig7, width = 8, height = 5, dpi = 300)

## ---- Figure 8: Stacked DiD vs. CS-DiD Comparison ----
stacked_es <- fread(file.path(DATA, "stacked_es.csv"))

es_compare <- rbindlist(list(
  es_bh[, .(event_time, att, ci_lower, ci_upper, method = "CS-DiD")],
  stacked_es[, .(event_time, att, ci_lower, ci_upper, method = "Stacked DiD")]
))

fig8 <- ggplot(es_compare, aes(x = event_time, y = att, color = method, fill = method)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red3", alpha = 0.4) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.1, color = NA) +
  geom_point(size = 1.5, position = position_dodge(width = 0.5)) +
  geom_line(linewidth = 0.4, position = position_dodge(width = 0.5)) +
  scale_color_manual(values = c("CS-DiD" = "steelblue", "Stacked DiD" = "darkorange")) +
  scale_fill_manual(values = c("CS-DiD" = "steelblue", "Stacked DiD" = "darkorange")) +
  labs(
    title = "Estimator Comparison: CS-DiD vs. Stacked DiD",
    x = "Months Relative to Waiver Approval",
    y = "ATT (Log BH Providers)",
    color = NULL, fill = NULL
  ) +
  scale_x_continuous(breaks = seq(-12, 36, 12))

ggsave(file.path(FIGS, "fig8_estimator_comparison.pdf"), fig8, width = 8, height = 5)
ggsave(file.path(FIGS, "fig8_estimator_comparison.png"), fig8, width = 8, height = 5, dpi = 300)

## ---- Figure 9: Per Capita Event Study ----
if (file.exists(file.path(DATA, "es_percapita.csv"))) {
  es_pc <- fread(file.path(DATA, "es_percapita.csv"))

  fig9 <- ggplot(es_pc, aes(x = event_time, y = att)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_vline(xintercept = -0.5, linetype = "dashed", color = "red3", alpha = 0.6) +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), fill = "purple4", alpha = 0.15) +
    geom_point(size = 1.8, color = "purple4") +
    geom_line(color = "purple4", linewidth = 0.5) +
    labs(
      title = "Per Capita Effect: BH Providers per 100,000 Population",
      x = "Months Relative to Waiver Approval",
      y = "ATT (BH Providers per 100K)"
    ) +
    scale_x_continuous(breaks = seq(-12, 36, 6))

  ggsave(file.path(FIGS, "fig9_percapita.pdf"), fig9, width = 8, height = 5)
  ggsave(file.path(FIGS, "fig9_percapita.png"), fig9, width = 8, height = 5, dpi = 300)
}

## ---- Figure 10: Bacon Decomposition ----
if (file.exists(file.path(DATA, "bacon_decomposition.csv"))) {
  bacon_dt <- fread(file.path(DATA, "bacon_decomposition.csv"))

  fig10 <- ggplot(bacon_dt, aes(x = weight, y = estimate, color = type)) +
    geom_point(size = 2, alpha = 0.7) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    labs(
      title = "Bacon Decomposition: 2x2 DiD Weights",
      x = "Weight",
      y = "2x2 DiD Estimate",
      color = "Comparison Type"
    ) +
    scale_color_brewer(palette = "Set2")

  ggsave(file.path(FIGS, "fig10_bacon.pdf"), fig10, width = 8, height = 5)
  ggsave(file.path(FIGS, "fig10_bacon.png"), fig10, width = 8, height = 5, dpi = 300)
}

cat("\n=== All figures generated ===\n")
cat(sprintf("Figures saved to: %s\n", normalizePath(FIGS)))
