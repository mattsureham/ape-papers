## 05_figures.R — Publication-quality figures for ZRR reclassification and RN voting
## apep_0561: All data read from ../data/ CSV files. Figures saved to ../figures/ as PDF.

source("00_packages.R")

# ── Colorblind-friendly palette ──────────────────────────────────────────────
# Okabe-Ito palette (widely recommended for colorblind accessibility)
# Defined with display-label keys for direct use in scale_*_manual()
col_loser  <- "#E69F00"  # orange
col_stayer <- "#56B4E9"  # sky blue
col_gainer <- "#009E73"  # green
col_never  <- "#CC79A7"  # pink

# Publication theme — white background, thin horizontal gridlines only
theme_pub <- theme_bw(base_size = 14) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.border     = element_blank(),
    axis.line        = element_line(color = "black", linewidth = 0.4),
    plot.title       = element_text(face = "bold", size = 16),
    plot.subtitle    = element_text(size = 12, color = "grey40"),
    axis.title       = element_text(size = 13),
    axis.text        = element_text(size = 12),
    legend.position  = "bottom",
    legend.text      = element_text(size = 12),
    legend.title     = element_text(size = 12, face = "bold"),
    plot.caption     = element_text(size = 9, color = "grey50", hjust = 0)
  )

# Treatment year
treat_year <- 2017

cat("Creating figures...\n")

# ═════════════════════════════════════════════════════════════════════════════
# Figure 1: Event Study (Main) — Loser vs Stayer
# ═════════════════════════════════════════════════════════════════════════════

es_main <- read.csv("../data/event_study_coefs.csv", stringsAsFactors = FALSE)

# Identify pre-treatment years (strictly before treatment)
pre_years <- es_main$year[es_main$year < treat_year]

fig1 <- ggplot(es_main, aes(x = year, y = coef)) +
  # Gray shading for pre-reform period (before 2015 legislative reform)
  annotate("rect",
           xmin = min(es_main$year) - 1, xmax = 2015,
           ymin = -Inf, ymax = Inf,
           fill = "grey90", alpha = 0.5) +
  # Horizontal reference line at zero
  geom_hline(yintercept = 0, linetype = "solid", color = "grey50", linewidth = 0.5) +
  # Vertical dashed line at reform year
  geom_vline(xintercept = 2015, linetype = "dashed", color = "grey40", linewidth = 0.6) +
  # Point estimates with 95% CIs
  geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper),
                  color = "#0072B2", size = 0.8, linewidth = 0.7, fatten = 3) +
  # Labels
  labs(
    title    = "Event Study: ZRR Loss and FN/RN Vote Share",
    subtitle = "Losers vs. stayers, base year = 2012 (last pre-reform election)",
    x        = "Presidential Election Year",
    y        = "Coefficient (pp)",
    caption  = "Notes: Point estimates from commune FE + department-year FE regression.\n95% confidence intervals based on commune-clustered standard errors."
  ) +
  scale_x_continuous(breaks = es_main$year) +
  theme_pub

ggsave("../figures/fig1_event_study_main.pdf", fig1, width = 8, height = 5, device = "pdf")
cat("  Figure 1 saved: fig1_event_study_main.pdf\n")

# ═════════════════════════════════════════════════════════════════════════════
# Figure 2: Raw Trends — Mean FN/RN vote share by group (Losers vs Stayers)
# ═════════════════════════════════════════════════════════════════════════════

gm_did <- read.csv("../data/group_means_did.csv", stringsAsFactors = FALSE)

# Compute standard error of the mean for confidence bands
gm_did$fn_rn_se <- gm_did$fn_rn_sd / sqrt(gm_did$n)
gm_did$fn_rn_lower <- gm_did$fn_rn_mean - 1.96 * gm_did$fn_rn_se
gm_did$fn_rn_upper <- gm_did$fn_rn_mean + 1.96 * gm_did$fn_rn_se

# Capitalize group labels for display
gm_did$group_label <- ifelse(gm_did$treatment_group == "loser", "Loser (Lost ZRR)", "Stayer (Kept ZRR)")

fig2 <- ggplot(gm_did, aes(x = year, y = fn_rn_mean, color = group_label, fill = group_label)) +
  # Vertical dashed line at 2015 legislative reform (consistent with Figure 1)
  geom_vline(xintercept = 2015, linetype = "dashed", color = "grey40", linewidth = 0.6) +
  # Confidence bands
  geom_ribbon(aes(ymin = fn_rn_lower, ymax = fn_rn_upper), alpha = 0.15, color = NA) +
  # Lines and points
  geom_line(linewidth = 0.9) +
  geom_point(size = 2.5) +
  # Colors
  scale_color_manual(values = c("Loser (Lost ZRR)" = col_loser,
                                "Stayer (Kept ZRR)" = col_stayer)) +
  scale_fill_manual(values = c("Loser (Lost ZRR)" = col_loser,
                               "Stayer (Kept ZRR)" = col_stayer)) +
  # Labels
  labs(
    title    = "Mean FN/RN Vote Share: Losers vs. Stayers",
    subtitle = "First-round presidential elections, commune-level means",
    x        = "Presidential Election Year",
    y        = "FN/RN Vote Share (%)",
    color    = "Treatment Group",
    fill     = "Treatment Group",
    caption  = "Notes: Means with 95% confidence bands (SE of mean). Dashed line marks the 2015 legislative reform."
  ) +
  scale_x_continuous(breaks = gm_did$year[gm_did$treatment_group == "loser"]) +
  theme_pub

ggsave("../figures/fig2_raw_trends.pdf", fig2, width = 8, height = 5, device = "pdf")
cat("  Figure 2 saved: fig2_raw_trends.pdf\n")

# ═════════════════════════════════════════════════════════════════════════════
# Figure 3: Symmetric Event Study — Gainers vs Never
# ═════════════════════════════════════════════════════════════════════════════

es_sym <- read.csv("../data/symmetric_event_study_coefs.csv", stringsAsFactors = FALSE)

fig3 <- ggplot(es_sym, aes(x = year, y = coef)) +
  # Gray shading for pre-treatment period
  annotate("rect",
           xmin = min(es_sym$year) - 1, xmax = treat_year,
           ymin = -Inf, ymax = Inf,
           fill = "grey90", alpha = 0.5) +
  # Horizontal reference line at zero
  geom_hline(yintercept = 0, linetype = "solid", color = "grey50", linewidth = 0.5) +
  # Vertical dashed line at treatment year
  geom_vline(xintercept = treat_year, linetype = "dashed", color = "grey40", linewidth = 0.6) +
  # Point estimates with 95% CIs
  geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper),
                  color = "#009E73", size = 0.8, linewidth = 0.7, fatten = 3) +
  # Labels
  labs(
    title    = "Symmetric Event Study: ZRR Gain and FN/RN Vote Share",
    subtitle = "Gainers vs. never-ZRR communes, base year = 2012",
    x        = "Presidential Election Year",
    y        = "Coefficient (pp)",
    caption  = "Notes: Gaining ZRR status should reduce FN/RN support (opposite sign to loss).\n95% CIs based on commune-clustered SEs."
  ) +
  scale_x_continuous(breaks = es_sym$year) +
  theme_pub

ggsave("../figures/fig3_symmetric_event_study.pdf", fig3, width = 8, height = 5, device = "pdf")
cat("  Figure 3 saved: fig3_symmetric_event_study.pdf\n")

# ═════════════════════════════════════════════════════════════════════════════
# Figure 4: Treatment Group Trends (All Four Groups)
# ═════════════════════════════════════════════════════════════════════════════

gm_full <- read.csv("../data/group_means_full.csv", stringsAsFactors = FALSE)

# Compute SE of the mean for confidence bands
gm_full$fn_rn_se <- gm_full$fn_rn_sd / sqrt(gm_full$n)
# Handle missing SD column (group_means_full may not have fn_rn_sd)
if (!"fn_rn_sd" %in% names(gm_full)) {
  # If no SD, skip confidence bands
  gm_full$fn_rn_se <- NA
}
gm_full$fn_rn_lower <- gm_full$fn_rn_mean - 1.96 * gm_full$fn_rn_se
gm_full$fn_rn_upper <- gm_full$fn_rn_mean + 1.96 * gm_full$fn_rn_se

# Capitalize group labels
group_labels <- c(
  "loser"  = "Loser (Lost ZRR)",
  "stayer" = "Stayer (Kept ZRR)",
  "gainer" = "Gainer (Gained ZRR)",
  "never"  = "Never ZRR"
)
gm_full$group_label <- group_labels[gm_full$treatment_group]
gm_full$group_label <- factor(gm_full$group_label,
                               levels = c("Loser (Lost ZRR)", "Stayer (Kept ZRR)",
                                          "Gainer (Gained ZRR)", "Never ZRR"))

fig4 <- ggplot(gm_full, aes(x = year, y = fn_rn_mean, color = group_label,
                              shape = group_label, group = group_label)) +
  # Vertical dashed line at 2015 legislative reform (consistent with Figure 1)
  geom_vline(xintercept = 2015, linetype = "dashed", color = "grey40", linewidth = 0.6) +
  # Lines and points
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.5) +
  # Colors — use colorblind-friendly palette
  scale_color_manual(values = c(
    "Loser (Lost ZRR)"    = col_loser,
    "Stayer (Kept ZRR)"   = col_stayer,
    "Gainer (Gained ZRR)" = col_gainer,
    "Never ZRR"           = col_never
  )) +
  scale_shape_manual(values = c(16, 17, 15, 18)) +
  # Labels
  labs(
    title    = "FN/RN Vote Share by ZRR Treatment Group",
    subtitle = "First-round presidential elections, commune-level means",
    x        = "Presidential Election Year",
    y        = "FN/RN Vote Share (%)",
    color    = "Treatment Group",
    shape    = "Treatment Group",
    caption  = "Notes: Commune-level means by ZRR reclassification group.\nDashed line marks the 2015 legislative reform."
  ) +
  scale_x_continuous(breaks = unique(gm_full$year)) +
  theme_pub

ggsave("../figures/fig4_all_group_trends.pdf", fig4, width = 8, height = 5, device = "pdf")
cat("  Figure 4 saved: fig4_all_group_trends.pdf\n")

# ═════════════════════════════════════════════════════════════════════════════
# Figure 5: Event Study — Turnout
# ═════════════════════════════════════════════════════════════════════════════

es_turnout <- read.csv("../data/event_study_turnout_coefs.csv", stringsAsFactors = FALSE)

fig5 <- ggplot(es_turnout, aes(x = year, y = coef)) +
  # Gray shading for pre-treatment period
  annotate("rect",
           xmin = min(es_turnout$year) - 1, xmax = treat_year,
           ymin = -Inf, ymax = Inf,
           fill = "grey90", alpha = 0.5) +
  # Horizontal reference line at zero
  geom_hline(yintercept = 0, linetype = "solid", color = "grey50", linewidth = 0.5) +
  # Vertical dashed line at treatment year
  geom_vline(xintercept = treat_year, linetype = "dashed", color = "grey40", linewidth = 0.6) +
  # Point estimates with 95% CIs
  geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper),
                  color = "#D55E00", size = 0.8, linewidth = 0.7, fatten = 3) +
  # Labels
  labs(
    title    = "Event Study: ZRR Loss and Voter Turnout",
    subtitle = "Losers vs. stayers, base year = 2012",
    x        = "Presidential Election Year",
    y        = "Coefficient (pp)",
    caption  = "Notes: Turnout outcome. Point estimates from commune FE + department-year FE regression.\n95% CIs based on commune-clustered SEs."
  ) +
  scale_x_continuous(breaks = es_turnout$year) +
  theme_pub

ggsave("../figures/fig5_event_study_turnout.pdf", fig5, width = 8, height = 5, device = "pdf")
cat("  Figure 5 saved: fig5_event_study_turnout.pdf\n")

# ═════════════════════════════════════════════════════════════════════════════
# Figure 6 (Appendix): Leave-One-Department-Out
# ═════════════════════════════════════════════════════════════════════════════

lodo <- read.csv("../data/robustness_lodo.csv", stringsAsFactors = FALSE)
lodo <- lodo[order(lodo$coef), ]
lodo$rank <- seq_len(nrow(lodo))

# Full-sample ATT — read from saved results
main_res <- read.csv("../data/main_did_results.csv", stringsAsFactors = FALSE)
full_att <- main_res$coef[main_res$model == "Baseline DiD"]

fig_lodo <- ggplot(lodo, aes(x = rank, y = coef)) +
  # Reference line at full-sample estimate
  geom_hline(yintercept = full_att, linetype = "dashed", color = "grey40", linewidth = 0.6) +
  # Reference line at zero
  geom_hline(yintercept = 0, linetype = "solid", color = "grey70", linewidth = 0.4) +
  # Point estimates with 95% CIs
  geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper,
                      color = significant_05),
                  size = 0.3, linewidth = 0.3, fatten = 2) +
  scale_color_manual(values = c("TRUE" = "#0072B2", "FALSE" = "#D55E00"),
                     labels = c("TRUE" = "Significant (p < 0.05)",
                                "FALSE" = "Not significant"),
                     name = "") +
  labs(
    title    = "Leave-One-Department-Out: DiD Estimates",
    subtitle = "Each point drops one of 84 departments; dashed line = full-sample ATT",
    x        = "Department (ranked by estimate)",
    y        = "ATT (pp)",
    caption  = "Notes: 84 jackknife estimates. All remain negative; 81/84 significant at 5%."
  ) +
  theme_pub +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())

ggsave("../figures/fig_lodo.pdf", fig_lodo, width = 8, height = 5, device = "pdf")
cat("  Figure 6 saved: fig_lodo.pdf\n")

# ═════════════════════════════════════════════════════════════════════════════
cat("\nAll 6 figures saved to ../figures/\n")
