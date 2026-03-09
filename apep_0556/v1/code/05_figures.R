## ============================================================
## 05_figures.R — Generate all figures
## APEP Paper: India's NRHM and Neonatal Mortality Transition
## ============================================================

source("00_packages.R")
data_dir <- "../data"
fig_dir  <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

panel    <- fread(file.path(data_dir, "analysis_panel.csv"))
srs      <- fread(file.path(data_dir, "srs_analysis_panel.csv"))
wb       <- fread(file.path(data_dir, "wb_national_indicators.csv"))
es_dhs   <- fread(file.path(data_dir, "event_study_dhs.csv"))
loo      <- fread(file.path(data_dir, "robustness_loo.csv"))
ri_dist  <- fread(file.path(data_dir, "robustness_perm_dist.csv"))
ri_res   <- fread(file.path(data_dir, "robustness_ri.csv"))

## ── Figure 1: Treatment Timing and Design ──────────────────────

cat("Figure 1: Policy Timeline...\n")

timeline <- data.table(
  event = c("NRHM Launch\n(Phase 1: 18 states)", "JSY Scale-Up",
            "Phase 2 States\nASHA Deployment", "NFHS-3", "NFHS-4", "NFHS-5"),
  year = c(2005, 2006, 2009, 2006, 2016, 2020),
  y = c(1, 0.7, 1, -0.5, -0.5, -0.5),
  type = c("Policy", "Policy", "Policy", "Data", "Data", "Data")
)

p1 <- ggplot(timeline, aes(x = year, y = y)) +
  geom_segment(aes(x = year, xend = year, y = 0, yend = y),
               linetype = "dashed", color = "grey60") +
  geom_point(aes(color = type), size = 3) +
  geom_text(aes(label = event), size = 3, vjust = ifelse(timeline$y > 0, -0.5, 1.5),
            lineheight = 0.9) +
  geom_hline(yintercept = 0, linewidth = 0.5) +
  scale_x_continuous(breaks = seq(2004, 2022, 2), limits = c(2003, 2022)) +
  scale_color_manual(values = c(Policy = "#c0392b", Data = "#2980b9")) +
  labs(title = "NRHM Policy Timeline and Data Coverage",
       x = "Year", y = "", color = "") +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(),
        panel.grid.major.y = element_blank())

ggsave(file.path(fig_dir, "fig1_timeline.pdf"), p1, width = 8, height = 3.5)


## ── Figure 2: Raw Trends — Institutional Delivery ──────────────

cat("Figure 2: Raw trends...\n")

# Compute group means
trends <- panel[!is.na(inst_delivery), .(
  mean_delivery = mean(inst_delivery, na.rm = TRUE),
  se_delivery = sd(inst_delivery, na.rm = TRUE) / sqrt(.N),
  n = .N
), by = .(SurveyYear, Group = fifelse(high_focus == 1, "High-Focus (Phase 1)",
                                        "Non-High-Focus (Phase 2)"))]

p2 <- ggplot(trends, aes(x = SurveyYear, y = mean_delivery,
                          color = Group, shape = Group)) +
  geom_vline(xintercept = 2005, linetype = "dashed", color = "grey50", linewidth = 0.4) +
  annotate("text", x = 2005.5, y = 95, label = "NRHM Launch",
           size = 2.8, color = "grey40", hjust = 0) +
  geom_ribbon(aes(ymin = mean_delivery - 1.96 * se_delivery,
                  ymax = mean_delivery + 1.96 * se_delivery,
                  fill = Group), alpha = 0.15, color = NA) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.5) +
  scale_color_manual(values = c("High-Focus (Phase 1)" = "#c0392b",
                                  "Non-High-Focus (Phase 2)" = "#2980b9")) +
  scale_fill_manual(values = c("High-Focus (Phase 1)" = "#c0392b",
                                 "Non-High-Focus (Phase 2)" = "#2980b9")) +
  scale_x_continuous(breaks = c(1993, 1999, 2006, 2015, 2020)) +
  labs(title = "Institutional Delivery Rates by NRHM Treatment Group",
       subtitle = "Mean percentage of births at health facilities",
       x = "NFHS Survey Year", y = "Institutional Delivery (%)",
       color = "", fill = "", shape = "") +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig2_raw_trends.pdf"), p2, width = 7, height = 5)


## ── Figure 3: Event Study (DHS) ───────────────────────────────

cat("Figure 3: Event study...\n")

# Add reference period (2006 = 0)
ref_row <- data.table(period = 2006, coef = 0, se = 0, ci_lo = 0, ci_hi = 0)
es_plot <- rbind(es_dhs, ref_row)
es_plot <- es_plot[order(period)]

p3 <- ggplot(es_plot, aes(x = period, y = coef)) +
  geom_hline(yintercept = 0, color = "grey60", linewidth = 0.4) +
  geom_vline(xintercept = 2005, linetype = "dashed", color = "grey50", linewidth = 0.4) +
  annotate("text", x = 2004.5, y = max(es_plot$ci_hi, na.rm = TRUE) * 0.9,
           label = "NRHM\nLaunch", size = 2.5, color = "grey40", hjust = 1) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "#c0392b", alpha = 0.15) +
  geom_line(color = "#c0392b", linewidth = 0.7) +
  geom_point(color = "#c0392b", size = 2.5) +
  geom_point(data = ref_row, color = "#c0392b", size = 3, shape = 18) +
  scale_x_continuous(breaks = c(1993, 1999, 2006, 2015, 2020),
                     labels = c("1993\n(NFHS-1)", "1999\n(NFHS-2)",
                                "2006\n(NFHS-3)", "2015\n(NFHS-4)",
                                "2020\n(NFHS-5)")) +
  labs(title = "Event Study: Differential Institutional Delivery",
       subtitle = "High-focus vs. non-high-focus states, reference = NFHS-3 (2006)",
       x = "", y = "DiD Coefficient (pp)") +
  theme(axis.text.x = element_text(size = 8))

ggsave(file.path(fig_dir, "fig3_event_study.pdf"), p3, width = 7, height = 5)


## ── Figure 4: National NMR Decline ─────────────────────────────

cat("Figure 4: National NMR...\n")

nmr <- wb[indicator_id == "SH.DYN.NMRT"]

p4 <- ggplot(nmr, aes(x = year, y = value)) +
  geom_vline(xintercept = 2005, linetype = "dashed", color = "#c0392b", linewidth = 0.4) +
  annotate("text", x = 2005.5, y = 48, label = "NRHM Launch",
           size = 2.8, color = "#c0392b", hjust = 0) +
  geom_line(color = "#2c3e50", linewidth = 0.8) +
  geom_point(color = "#2c3e50", size = 1.5) +
  annotate("rect", xmin = 2005, xmax = 2022, ymin = -Inf, ymax = Inf,
           fill = "#c0392b", alpha = 0.05) +
  scale_x_continuous(breaks = seq(1990, 2022, 4)) +
  labs(title = "India's Neonatal Mortality Rate, 1990-2022",
       subtitle = "Deaths per 1,000 live births (World Bank/UN IGME estimates)",
       x = "Year", y = "NMR (per 1,000 live births)")

ggsave(file.path(fig_dir, "fig4_nmr_national.pdf"), p4, width = 7, height = 4.5)


## ── Figure 5: Leave-One-Out ───────────────────────────────────

cat("Figure 5: Leave-one-out...\n")

p5 <- ggplot(loo, aes(x = reorder(dropped_state, coef), y = coef)) +
  geom_hline(yintercept = 0, color = "grey60", linewidth = 0.4) +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi), color = "#c0392b", size = 0.4) +
  coord_flip() +
  labs(title = "Leave-One-Out Stability",
       subtitle = "Main DiD coefficient after dropping each high-focus state",
       x = "Dropped State", y = "DiD Coefficient (pp)")

ggsave(file.path(fig_dir, "fig5_loo.pdf"), p5, width = 6, height = 5)


## ── Figure 6: Randomization Inference ──────────────────────────

cat("Figure 6: RI distribution...\n")

actual_coef <- ri_res$actual_coef

p6 <- ggplot(ri_dist, aes(x = coef)) +
  geom_histogram(bins = 40, fill = "grey70", color = "grey50", linewidth = 0.2) +
  geom_vline(xintercept = actual_coef, color = "#c0392b", linewidth = 0.8,
             linetype = "solid") +
  annotate("text", x = actual_coef + 1, y = Inf,
           label = sprintf("Actual = %.1f\np = %.3f", actual_coef, ri_res$ri_pval),
           hjust = 0, vjust = 1.5, size = 3, color = "#c0392b") +
  labs(title = "Randomization Inference",
       subtitle = "Distribution of placebo DiD coefficients (1,000 permutations)",
       x = "Placebo DiD Coefficient (pp)", y = "Count")

ggsave(file.path(fig_dir, "fig6_ri.pdf"), p6, width = 6, height = 4.5)


## ── Figure 7: State-Level Scatter ──────────────────────────────

cat("Figure 7: State scatter...\n")

# Compute change in delivery by state
state_change <- panel[SurveyYear %in% c(2006, 2015) & !is.na(inst_delivery)]
state_wide <- dcast(state_change, state + high_focus ~ SurveyYear,
                    value.var = "inst_delivery")
setnames(state_wide, c("2006", "2015"), c("delivery_2006", "delivery_2015"))
state_wide[, change := delivery_2015 - delivery_2006]
state_wide <- state_wide[!is.na(change)]

p7 <- ggplot(state_wide, aes(x = delivery_2006, y = change,
                               color = factor(high_focus))) +
  geom_point(size = 2.5, alpha = 0.8) +
  geom_smooth(method = "lm", se = FALSE, linetype = "dashed", linewidth = 0.5) +
  geom_text(aes(label = substr(state, 1, 3)), size = 2, vjust = -0.8,
            show.legend = FALSE) +
  scale_color_manual(values = c("0" = "#2980b9", "1" = "#c0392b"),
                     labels = c("Non-High-Focus", "High-Focus")) +
  labs(title = "Convergence in Institutional Delivery",
       subtitle = "Change (2006-2015) vs. baseline level (2006)",
       x = "Baseline Delivery Rate (NFHS-3, 2006, %)",
       y = "Change in Delivery Rate (pp)",
       color = "") +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig7_scatter.pdf"), p7, width = 7, height = 5.5)

cat("\n✓ All 7 figures saved to ../figures/\n")
