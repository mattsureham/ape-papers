# =============================================================================
# 05_figures.R — Publication-quality figures (≥5 required)
# =============================================================================

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
rob_results <- readRDS("../data/robustness_results.rds")
sq <- results$sa_bal  # Balanced panel
pfl_states <- readRDS("../data/pfl_states.rds")

# --- APEP theme ---
theme_apep <- function() {
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "grey90", linewidth = 0.3),
    axis.line = element_line(color = "grey30", linewidth = 0.4),
    axis.ticks = element_line(color = "grey30", linewidth = 0.3),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 10, color = "grey30"),
    legend.position = "bottom",
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 9),
    plot.title = element_text(size = 13, face = "bold", hjust = 0),
    plot.subtitle = element_text(size = 10, color = "grey40", hjust = 0),
    plot.caption = element_text(size = 8, color = "grey50", hjust = 1),
    plot.margin = margin(10, 15, 10, 10)
  )
}

apep_blue <- "#0072B2"
apep_orange <- "#D55E00"
apep_green <- "#009E73"

# ============================================================================
# Figure 1: Event study — log(Black/White hire ratio)
# ============================================================================

es <- results$es_hira
es_df <- tibble(
  e = es$egt,
  att = es$att.egt,
  se = es$se.egt
) %>%
  mutate(
    ci_lo = att - 1.96 * se,
    ci_hi = att + 1.96 * se,
    e_year = e
  ) %>%
  filter(e_year >= -5, e_year <= 5)

fig1 <- ggplot(es_df, aes(x = e_year, y = att)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_vline(xintercept = -0.125, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = apep_blue) +
  geom_line(color = apep_blue, linewidth = 0.8) +
  geom_point(color = apep_blue, size = 2) +
  labs(
    title = "Event Study: Black/White Hiring Ratio",
    subtitle = "Callaway-Sant'Anna estimates, relative to PFL adoption",
    x = "Years relative to PFL adoption",
    y = "ATT: log(Black hires / White hires)",
    caption = "Notes: 95% pointwise CIs. Never-treated states as control. DR estimator."
  ) +
  theme_apep()

ggsave("../figures/fig1_event_study_ratio.pdf", fig1, width = 8, height = 5.5)
cat("Figure 1 saved.\n")

# ============================================================================
# Figure 2: Decomposition — Black and White hires separately
# ============================================================================

es_b <- results$es_black
es_w <- results$es_white

es_decomp <- bind_rows(
  tibble(e = es_b$egt, att = es_b$att.egt, se = es_b$se.egt, group = "Black hires"),
  tibble(e = es_w$egt, att = es_w$att.egt, se = es_w$se.egt, group = "White hires")
) %>%
  mutate(
    ci_lo = att - 1.96 * se,
    ci_hi = att + 1.96 * se,
    e_year = e
  ) %>%
  filter(e_year >= -5, e_year <= 5)

fig2 <- ggplot(es_decomp, aes(x = e_year, y = att, color = group, fill = group)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_vline(xintercept = -0.125, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, color = NA) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  scale_color_manual(values = c("Black hires" = apep_blue, "White hires" = apep_orange)) +
  scale_fill_manual(values = c("Black hires" = apep_blue, "White hires" = apep_orange)) +
  labs(
    title = "Decomposition: Black vs. White New Hires",
    subtitle = "Separate CS-DiD event studies, relative to PFL adoption",
    x = "Years relative to PFL adoption",
    y = "ATT: log(new hires)",
    color = NULL, fill = NULL,
    caption = "Notes: 95% pointwise CIs. Never-treated states as control."
  ) +
  theme_apep()

ggsave("../figures/fig2_decomposition.pdf", fig2, width = 8, height = 5.5)
cat("Figure 2 saved.\n")

# ============================================================================
# Figure 3: Raw trends — treated vs. control states
# ============================================================================

trends <- sq %>%
  mutate(group = ifelse(treated == 1, "PFL states", "Non-PFL states")) %>%
  group_by(group, year) %>%
  summarise(
    mean_ratio = mean(log_hira_ratio, na.rm = TRUE),
    se_ratio = sd(log_hira_ratio, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )

fig3 <- ggplot(trends, aes(x = year, y = mean_ratio, color = group)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_ribbon(aes(ymin = mean_ratio - 1.96*se_ratio,
                  ymax = mean_ratio + 1.96*se_ratio, fill = group),
              alpha = 0.1, color = NA) +
  scale_color_manual(values = c("PFL states" = apep_blue, "Non-PFL states" = apep_orange)) +
  scale_fill_manual(values = c("PFL states" = apep_blue, "Non-PFL states" = apep_orange)) +
  labs(
    title = "Raw Trends: Black/White Hiring Ratio",
    subtitle = "PFL vs. non-PFL states (annual averages of quarterly data)",
    x = "Year",
    y = "Mean log(Black hires / White hires)",
    color = NULL, fill = NULL,
    caption = "Notes: Shaded bands show ±1.96 SE of state-level mean."
  ) +
  theme_apep()

ggsave("../figures/fig3_raw_trends.pdf", fig3, width = 8, height = 5.5)
cat("Figure 3 saved.\n")

# ============================================================================
# Figure 4: Earnings ratio event study
# ============================================================================

es_e <- results$es_earn
es_earn_df <- tibble(
  e = es_e$egt,
  att = es_e$att.egt,
  se = es_e$se.egt
) %>%
  mutate(
    ci_lo = att - 1.96 * se,
    ci_hi = att + 1.96 * se,
    e_year = e
  ) %>%
  filter(e_year >= -5, e_year <= 5)

fig4 <- ggplot(es_earn_df, aes(x = e_year, y = att)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_vline(xintercept = -0.125, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = apep_green) +
  geom_line(color = apep_green, linewidth = 0.8) +
  geom_point(color = apep_green, size = 2) +
  labs(
    title = "Event Study: Black/White Earnings Ratio",
    subtitle = "Callaway-Sant'Anna estimates, relative to PFL adoption",
    x = "Years relative to PFL adoption",
    y = "ATT: log(Black earnings / White earnings)",
    caption = "Notes: 95% pointwise CIs. Never-treated states as control."
  ) +
  theme_apep()

ggsave("../figures/fig4_earnings_event_study.pdf", fig4, width = 8, height = 5.5)
cat("Figure 4 saved.\n")

# ============================================================================
# Figure 5: Not-yet-treated sensitivity
# ============================================================================

es_nyt <- rob_results$es_nyt
es_nyt_df <- tibble(
  e = es_nyt$egt,
  att = es_nyt$att.egt,
  se = es_nyt$se.egt
) %>%
  mutate(
    ci_lo = att - 1.96 * se,
    ci_hi = att + 1.96 * se,
    e_year = e
  ) %>%
  filter(e_year >= -5, e_year <= 5)

# Combine with main estimate
es_compare <- bind_rows(
  es_df %>% mutate(control = "Never-treated"),
  es_nyt_df %>% mutate(control = "Not-yet-treated")
)

fig5 <- ggplot(es_compare, aes(x = e_year, y = att, color = control, fill = control)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_vline(xintercept = -0.125, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.1, color = NA) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 1.5) +
  scale_color_manual(values = c("Never-treated" = apep_blue, "Not-yet-treated" = apep_orange)) +
  scale_fill_manual(values = c("Never-treated" = apep_blue, "Not-yet-treated" = apep_orange)) +
  labs(
    title = "Sensitivity: Control Group Comparison",
    subtitle = "Never-treated vs. not-yet-treated as comparison group",
    x = "Years relative to PFL adoption",
    y = "ATT: log(Black hires / White hires)",
    color = "Control group", fill = "Control group",
    caption = "Notes: 95% pointwise CIs. DR estimator."
  ) +
  theme_apep()

ggsave("../figures/fig5_control_sensitivity.pdf", fig5, width = 8, height = 5.5)
cat("Figure 5 saved.\n")

# ============================================================================
# Figure 6: Heterogeneity coefficient plot (policy design features)
# ============================================================================

hetero_df <- tibble(
  label = c("Overall", "High generosity", "Low generosity",
            "Job protection", "No job protection",
            "Early adopters (≤2014)", "Late adopters (>2014)"),
  att = c(results$agg_hira$overall.att,
          rob_results$agg_high$overall.att, rob_results$agg_low$overall.att,
          rob_results$agg_jp_yes$overall.att, rob_results$agg_jp_no$overall.att,
          rob_results$agg_early$overall.att, rob_results$agg_late$overall.att),
  se = c(results$agg_hira$overall.se,
         rob_results$agg_high$overall.se, rob_results$agg_low$overall.se,
         rob_results$agg_jp_yes$overall.se, rob_results$agg_jp_no$overall.se,
         rob_results$agg_early$overall.se, rob_results$agg_late$overall.se)
) %>%
  mutate(
    ci_lo = att - 1.96 * se,
    ci_hi = att + 1.96 * se
  )

hetero_df$label <- factor(hetero_df$label, levels = rev(hetero_df$label))

fig6 <- ggplot(hetero_df, aes(x = att, y = label)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey60") +
  geom_errorbarh(aes(xmin = ci_lo, xmax = ci_hi), height = 0.2, color = apep_blue) +
  geom_point(size = 3, color = apep_blue) +
  labs(
    title = "Heterogeneity: PFL Effect by Policy Design",
    subtitle = "CS-DiD ATT on log(Black/White hire ratio)",
    x = "ATT: log(Black hires / White hires)",
    y = NULL,
    caption = "Notes: 95% CIs. Never-treated states as control. DR estimator."
  ) +
  theme_apep()

ggsave("../figures/fig6_heterogeneity.pdf", fig6, width = 8, height = 5)
cat("Figure 6 saved.\n")

# ============================================================================
# Figure 7: Cohort-specific ATTs
# ============================================================================

cs_hira <- results$cs_hira
cohort_df <- tibble(
  group = cs_hira$group,
  time = cs_hira$t,
  att = cs_hira$att,
  se = cs_hira$se
) %>%
  mutate(
    cohort_year = group,
    ci_lo = att - 1.96 * se,
    ci_hi = att + 1.96 * se,
    post = as.integer(time >= group)
  )

# Average by cohort for post-treatment periods
cohort_avg <- cohort_df %>%
  filter(post == 1) %>%
  group_by(cohort_year) %>%
  summarise(
    att = mean(att, na.rm = TRUE),
    se = sqrt(mean(se^2, na.rm = TRUE) / n()),
    n_periods = n(),
    .groups = "drop"
  ) %>%
  mutate(
    ci_lo = att - 1.96 * se,
    ci_hi = att + 1.96 * se
  )

pfl_labels <- c("2004" = "CA", "2009" = "NJ", "2014" = "RI",
                "2018" = "NY", "2020" = "WA/DC", "2021" = "MA", "2022" = "CT")

fig7 <- ggplot(cohort_avg, aes(x = factor(cohort_year), y = att)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0.2, color = apep_blue) +
  geom_point(size = 3, color = apep_blue) +
  labs(
    title = "Cohort-Specific Post-Treatment ATTs",
    subtitle = "Average treatment effect by PFL adoption cohort",
    x = "PFL adoption year",
    y = "Mean post-treatment ATT: log(Black/White hires)",
    caption = "Notes: 95% CIs. Bars show average of group-time ATTs for post-treatment periods."
  ) +
  theme_apep()

ggsave("../figures/fig7_cohort_atts.pdf", fig7, width = 8, height = 5)
cat("Figure 7 saved.\n")

cat("All figures generated.\n")
