# =============================================================================
# 05_figures.R — Publication-ready figures
# Paper: From the Ballot Box to the Bureau (apep_1409)
# =============================================================================

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds") |>
  filter(foreign_pop > 0, !is.na(nat_rate), is.finite(nat_rate))

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

apep_colors <- c("#0072B2", "#D55E00", "#009E73", "#CC79A7")

# =============================================================================
# FIGURE 1: Raw Trends in Naturalization Rates
# =============================================================================

cat("Generating Figure 1: Raw trends...\n")

trends <- panel |>
  group_by(treatment_group, year) |>
  summarize(
    mean_nat_rate = mean(nat_rate, na.rm = TRUE),
    se = sd(nat_rate, na.rm = TRUE) / sqrt(n()),
    median_nat_rate = median(nat_rate, na.rm = TRUE),
    .groups = "drop"
  )

p1 <- ggplot(trends, aes(x = year, y = mean_nat_rate, color = treatment_group)) +
  geom_line(linewidth = 1) +
  geom_point(size = 1.5) +
  geom_vline(xintercept = 2003.5, linetype = "dashed", color = "grey40") +
  annotate("text", x = 2003.5, y = max(trends$mean_nat_rate) * 0.95,
           label = "BGE 129 I 232\n(July 2003)", hjust = 1.05, size = 3, color = "grey40") +
  scale_color_manual(values = apep_colors,
                     labels = c("Administrative cantons", "Ballot cantons"),
                     name = "") +
  labs(x = "Year", y = "Naturalization rate\n(per 1,000 foreign residents)",
       title = "Mean Naturalization Rates by Procedure Type, 1981-2024") +
  theme_apep()

ggsave("../figures/fig1_raw_trends.pdf", p1, width = 8, height = 5.5)
ggsave("../figures/fig1_raw_trends.png", p1, width = 8, height = 5.5, dpi = 300)

# =============================================================================
# FIGURE 2: Event Study (TWFE)
# =============================================================================

cat("Generating Figure 2: Event study...\n")

es_coefs <- readRDS("../data/event_study_coefs.rds")

p2 <- ggplot(es_coefs, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_high), fill = apep_colors[1], alpha = 0.15) +
  geom_point(color = apep_colors[1], size = 2) +
  geom_line(color = apep_colors[1], linewidth = 0.5) +
  annotate("text", x = -0.5, y = max(es_coefs$ci_high, na.rm = TRUE) * 0.9,
           label = "Ruling", hjust = 1.1, size = 3, color = "grey40") +
  labs(x = "Years relative to 2004",
       y = "Coefficient\n(naturalization rate per 1,000 foreign residents)",
       title = "Event Study: Effect of Abolishing Ballot Naturalization") +
  scale_x_continuous(breaks = seq(-10, 15, by = 5)) +
  theme_apep()

ggsave("../figures/fig2_event_study.pdf", p2, width = 8, height = 5.5)
ggsave("../figures/fig2_event_study.png", p2, width = 8, height = 5.5, dpi = 300)

# =============================================================================
# FIGURE 3: Callaway-Sant'Anna Event Study
# =============================================================================

cat("Generating Figure 3: C-S event study...\n")

cs_es <- readRDS("../data/cs_event_study.rds")

cs_plot_data <- data.frame(
  event_time = cs_es$egt,
  att = cs_es$att.egt,
  se = cs_es$se.egt
) |>
  mutate(ci_low = att - 1.96 * se,
         ci_high = att + 1.96 * se) |>
  filter(event_time >= -15 & event_time <= 20)

p3 <- ggplot(cs_plot_data, aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_high), fill = apep_colors[2], alpha = 0.15) +
  geom_point(color = apep_colors[2], size = 2) +
  geom_line(color = apep_colors[2], linewidth = 0.5) +
  annotate("text", x = -0.5, y = max(cs_plot_data$ci_high, na.rm = TRUE) * 0.85,
           label = "Ruling", hjust = 1.1, size = 3, color = "grey40") +
  labs(x = "Years relative to 2004",
       y = "ATT\n(naturalization rate per 1,000 foreign residents)",
       title = "Callaway-Sant'Anna Event Study") +
  scale_x_continuous(breaks = seq(-15, 20, by = 5)) +
  theme_apep()

ggsave("../figures/fig3_cs_event_study.pdf", p3, width = 8, height = 5.5)
ggsave("../figures/fig3_cs_event_study.png", p3, width = 8, height = 5.5, dpi = 300)

# =============================================================================
# FIGURE 4: Leave-One-Out Sensitivity
# =============================================================================

cat("Generating Figure 4: Leave-one-out...\n")

loo <- readRDS("../data/loo_results.rds") |>
  mutate(ci_low = estimate - 1.96 * se,
         ci_high = estimate + 1.96 * se) |>
  arrange(estimate)

# Add the full-sample estimate for reference
main_results <- readRDS("../data/main_results.rds")
full_est <- coef(main_results$m2)[1]
full_se <- se(main_results$m2)[1]

loo$dropped_canton <- factor(loo$dropped_canton, levels = loo$dropped_canton)

p4 <- ggplot(loo, aes(x = dropped_canton, y = estimate)) +
  geom_hline(yintercept = full_est, linetype = "dashed", color = apep_colors[1], linewidth = 0.8) +
  geom_hline(yintercept = 0, linetype = "dotted", color = "grey60") +
  geom_pointrange(aes(ymin = ci_low, ymax = ci_high), color = apep_colors[2], size = 0.5) +
  annotate("text", x = 1, y = full_est + 0.3, label = "Full sample",
           color = apep_colors[1], size = 3, hjust = 0) +
  labs(x = "Canton dropped", y = "Coefficient estimate",
       title = "Leave-One-Out: Dropping Each Ballot Canton") +
  theme_apep() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("../figures/fig4_loo.pdf", p4, width = 8, height = 5.5)
ggsave("../figures/fig4_loo.pdf", p4, width = 8, height = 5.5)
ggsave("../figures/fig4_loo.png", p4, width = 8, height = 5.5, dpi = 300)

# =============================================================================
# FIGURE 5: Size Heterogeneity
# =============================================================================

cat("Generating Figure 5: Size heterogeneity...\n")

# Compute pre-treatment median population
pre_median_pop <- panel |>
  filter(year < 2004) |>
  group_by(bfs_nr) |>
  summarize(median_pop = median(total_pop, na.rm = TRUE))

panel_size <- panel |>
  left_join(pre_median_pop, by = "bfs_nr") |>
  mutate(size_group = case_when(
    median_pop < quantile(pre_median_pop$median_pop, 0.25) ~ "Q1 (smallest)",
    median_pop < quantile(pre_median_pop$median_pop, 0.50) ~ "Q2",
    median_pop < quantile(pre_median_pop$median_pop, 0.75) ~ "Q3",
    TRUE ~ "Q4 (largest)"
  ))

trends_size <- panel_size |>
  group_by(size_group, treatment_group, year) |>
  summarize(mean_nat_rate = mean(nat_rate, na.rm = TRUE), .groups = "drop")

p5 <- ggplot(trends_size, aes(x = year, y = mean_nat_rate, color = treatment_group)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = 2003.5, linetype = "dashed", color = "grey40") +
  facet_wrap(~size_group, scales = "free_y") +
  scale_color_manual(values = apep_colors,
                     labels = c("Administrative", "Ballot"),
                     name = "") +
  labs(x = "Year", y = "Naturalization rate\n(per 1,000 foreign residents)",
       title = "Naturalization Trends by Municipality Size Quartile") +
  theme_apep() +
  theme(strip.text = element_text(face = "bold"))

ggsave("../figures/fig5_size_heterogeneity.pdf", p5, width = 10, height = 7)
ggsave("../figures/fig5_size_heterogeneity.png", p5, width = 10, height = 7, dpi = 300)

# =============================================================================
# FIGURE 6: Distribution of Naturalization Rates Pre vs Post
# =============================================================================

cat("Generating Figure 6: Distribution shift...\n")

panel_dist <- panel |>
  mutate(period = ifelse(year < 2004, "Pre-ruling (1981-2003)", "Post-ruling (2004-2024)"))

p6 <- ggplot(panel_dist |> filter(nat_rate < 150),
             aes(x = nat_rate, fill = period)) +
  geom_density(alpha = 0.4) +
  facet_wrap(~treatment_group,
             labeller = labeller(treatment_group = c(admin = "Administrative", ballot = "Ballot"))) +
  scale_fill_manual(values = c(apep_colors[1], apep_colors[2]), name = "") +
  labs(x = "Naturalization rate (per 1,000 foreign residents)",
       y = "Density",
       title = "Distribution of Municipal Naturalization Rates") +
  theme_apep() +
  theme(strip.text = element_text(face = "bold"))

ggsave("../figures/fig6_distribution.pdf", p6, width = 10, height = 5.5)
ggsave("../figures/fig6_distribution.png", p6, width = 10, height = 5.5, dpi = 300)

# =============================================================================
# FIGURE 7: HonestDiD Sensitivity Plot
# =============================================================================

cat("Generating Figure 7: HonestDiD sensitivity...\n")

if (file.exists("../data/honestdid_results.rds")) {
  honest <- readRDS("../data/honestdid_results.rds")

  p7 <- ggplot(honest, aes(x = M, ymin = lb, ymax = ub)) +
    geom_ribbon(fill = apep_colors[1], alpha = 0.2) +
    geom_line(aes(y = lb), color = apep_colors[1]) +
    geom_line(aes(y = ub), color = apep_colors[1]) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
    labs(x = expression(bar(M) ~ "(maximum deviation from parallel trends)"),
         y = "95% confidence interval",
         title = "HonestDiD Sensitivity: Bounds Under Parallel Trends Violations") +
    theme_apep()

  ggsave("../figures/fig7_honestdid.pdf", p7, width = 8, height = 5.5)
  ggsave("../figures/fig7_honestdid.png", p7, width = 8, height = 5.5, dpi = 300)
}

cat("\nAll figures generated.\n")
cat("05_figures.R complete.\n")
