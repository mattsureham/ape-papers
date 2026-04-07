## 05_figures.R — Generate all figures
## apep_1393: Merger-Induced Branch Closures and Racial Mortgage Gaps

source("00_packages.R")


data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob <- readRDS(file.path(data_dir, "robustness_results.rds"))

# APEP theme
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10, color = "gray40"),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )

# ============================================================================
# Figure 1: Branch Closures Over Time (descriptive)
# ============================================================================
cat("Figure 1: Branch closures over time\n")

branches_by_year <- panel %>%
  group_by(year) %>%
  summarise(
    total_branches = sum(n_branches, na.rm = TRUE),
    mean_branches = mean(n_branches, na.rm = TRUE),
    .groups = "drop"
  )

p1 <- ggplot(branches_by_year, aes(x = year, y = total_branches / 1000)) +
  geom_line(linewidth = 1.2, color = "#2C3E50") +
  geom_point(size = 3, color = "#2C3E50") +
  scale_x_continuous(breaks = 2015:2023) +
  labs(
    title = "Bank Branch Decline in Sample Counties",
    subtitle = "Total branches across 20-state sample, 2015-2023",
    x = NULL, y = "Branches (thousands)"
  ) +
  theme_apep
ggsave(file.path(fig_dir, "fig1_branch_trends.pdf"), p1, width = 8, height = 5)

# ============================================================================
# Figure 2: First Stage — Merger Exposure vs Branch Change
# ============================================================================
cat("Figure 2: First stage binscatter\n")

# Residualize against state+year FE
panel$me_resid <- residuals(feols(merger_exposure ~ 1 | state_fips + year, data = panel))
panel$bc_resid <- residuals(feols(branch_change_pct ~ 1 | state_fips + year, data = panel))

# Create bins
panel <- panel %>%
  mutate(me_bin = ntile(me_resid, 20))

bin_means <- panel %>%
  group_by(me_bin) %>%
  summarise(
    me = mean(me_resid, na.rm = TRUE),
    bc = mean(bc_resid, na.rm = TRUE),
    .groups = "drop"
  )

p2 <- ggplot(bin_means, aes(x = me, y = bc)) +
  geom_point(size = 3, color = "#E74C3C") +
  geom_smooth(method = "lm", se = TRUE, color = "#2C3E50", fill = "#BDC3C7") +
  labs(
    title = "First Stage: Merger Exposure and Branch Closures",
    subtitle = "Binscatter (20 bins), residualized on state and year FE",
    x = "Merger Exposure (residualized)",
    y = "Branch Change Rate (residualized)"
  ) +
  theme_apep
ggsave(file.path(fig_dir, "fig2_first_stage.pdf"), p2, width = 8, height = 5)

# ============================================================================
# Figure 3: Reduced Form — Merger Exposure vs BW Denial Gap
# ============================================================================
cat("Figure 3: Reduced form binscatter\n")

panel$bg_resid <- residuals(feols(bw_denial_gap ~ 1 | state_fips + year, data = panel))

bin_means_rf <- panel %>%
  group_by(me_bin) %>%
  summarise(
    me = mean(me_resid, na.rm = TRUE),
    bg = mean(bg_resid, na.rm = TRUE),
    .groups = "drop"
  )

p3 <- ggplot(bin_means_rf, aes(x = me, y = bg)) +
  geom_point(size = 3, color = "#3498DB") +
  geom_smooth(method = "lm", se = TRUE, color = "#2C3E50", fill = "#BDC3C7") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  labs(
    title = "Reduced Form: Merger Exposure and Black-White Denial Gap",
    subtitle = "Binscatter (20 bins), residualized on state and year FE",
    x = "Merger Exposure (residualized)",
    y = "Black-White Denial Rate Gap (residualized)"
  ) +
  theme_apep
ggsave(file.path(fig_dir, "fig3_reduced_form.pdf"), p3, width = 8, height = 5)

# ============================================================================
# Figure 4: Event Study
# ============================================================================
cat("Figure 4: Event study\n")

if (!is.null(rob$event_study_bw)) {
  es_coefs <- broom::tidy(rob$event_study_bw, conf.int = TRUE) %>%
    mutate(event_time = as.integer(str_extract(term, "-?\\d+"))) %>%
    filter(!is.na(event_time))

  # Add reference period
  es_coefs <- bind_rows(
    es_coefs,
    tibble(event_time = -1, estimate = 0, conf.low = 0, conf.high = 0)
  ) %>%
    arrange(event_time)

  p4 <- ggplot(es_coefs, aes(x = event_time, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "gray70") +
    geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = 0.2, fill = "#3498DB") +
    geom_line(color = "#2C3E50", linewidth = 1) +
    geom_point(size = 3, color = "#2C3E50") +
    scale_x_continuous(breaks = -3:4) +
    labs(
      title = "Event Study: Black-White Denial Gap Around High Merger Exposure",
      subtitle = "Reference period: t = -1. 95% CI based on county-clustered SEs",
      x = "Years Relative to High Merger Exposure",
      y = "Black-White Denial Gap (pp)"
    ) +
    theme_apep
} else {
  # Fallback: plot raw trends by exposure group
  panel_grouped <- panel %>%
    mutate(high_exp = merger_exposure > median(merger_exposure, na.rm = TRUE))

  trends <- panel_grouped %>%
    group_by(year, high_exp) %>%
    summarise(mean_gap = mean(bw_denial_gap, na.rm = TRUE), .groups = "drop") %>%
    mutate(group = ifelse(high_exp, "High Merger Exposure", "Low Merger Exposure"))

  p4 <- ggplot(trends, aes(x = year, y = mean_gap, color = group)) +
    geom_line(linewidth = 1.2) +
    geom_point(size = 3) +
    scale_x_continuous(breaks = 2018:2023) +
    scale_color_manual(values = c("#E74C3C", "#3498DB")) +
    labs(
      title = "Black-White Denial Gap by Merger Exposure",
      subtitle = "Counties split at median merger exposure",
      x = NULL, y = "Black-White Denial Rate Gap (pp)",
      color = NULL
    ) +
    theme_apep
}
ggsave(file.path(fig_dir, "fig4_event_study.pdf"), p4, width = 8, height = 5)

# ============================================================================
# Figure 5: Heterogeneity — High vs Low Minority Share
# ============================================================================
cat("Figure 5: Heterogeneity by minority share\n")

panel <- panel %>%
  mutate(high_minority = (black_share + black_share) >
           median(black_share + black_share, na.rm = TRUE))

het_trends <- panel %>%
  mutate(high_exp = merger_exposure > median(merger_exposure, na.rm = TRUE)) %>%
  group_by(year, high_exp, high_minority) %>%
  summarise(mean_gap = mean(bw_denial_gap, na.rm = TRUE), .groups = "drop") %>%
  mutate(
    exposure = ifelse(high_exp, "High Merger Exposure", "Low Merger Exposure"),
    minority = ifelse(high_minority, "High Minority Share", "Low Minority Share")
  )

p5 <- ggplot(het_trends, aes(x = year, y = mean_gap, color = exposure, linetype = minority)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  scale_x_continuous(breaks = 2018:2023) +
  scale_color_manual(values = c("#E74C3C", "#3498DB")) +
  labs(
    title = "Heterogeneity: Denial Gap by Merger Exposure and Minority Share",
    subtitle = "Counties split at median merger exposure and median minority share",
    x = NULL, y = "Black-White Denial Rate Gap (pp)",
    color = NULL, linetype = NULL
  ) +
  theme_apep
ggsave(file.path(fig_dir, "fig5_heterogeneity.pdf"), p5, width = 9, height = 5.5)

# ============================================================================
# Figure 6: Distribution of Merger Exposure
# ============================================================================
cat("Figure 6: Merger exposure distribution\n")

p6 <- ggplot(panel, aes(x = merger_exposure)) +
  geom_histogram(bins = 50, fill = "#2C3E50", alpha = 0.8, color = "white") +
  geom_vline(xintercept = median(panel$merger_exposure, na.rm = TRUE),
             linetype = "dashed", color = "#E74C3C", linewidth = 1) +
  labs(
    title = "Distribution of Merger Exposure Across County-Years",
    subtitle = paste0("Red dashed line = median (",
                      round(median(panel$merger_exposure, na.rm = TRUE), 3), ")"),
    x = "Merger Exposure (share of branches at recently merged banks)",
    y = "Count"
  ) +
  theme_apep
ggsave(file.path(fig_dir, "fig6_exposure_dist.pdf"), p6, width = 8, height = 5)

# ============================================================================
# Figure 7: Balance Test Visualization
# ============================================================================
cat("Figure 7: Balance test\n")

if (!is.null(rob$balance) && nrow(rob$balance) > 0) {
  bal <- rob$balance %>%
    mutate(
      variable = case_when(
        variable == "mean_denial_gap" ~ "BW Denial Gap",
        variable == "mean_income_w" ~ "White Income",
        variable == "mean_income_b" ~ "Black Income",
        variable == "mean_branches" ~ "N Branches",
        variable == "mean_black_share" ~ "Black Share",
        TRUE ~ variable
      ),
      significant = p_value < 0.05
    )

  # Normalize differences for comparison
  bal <- bal %>%
    mutate(std_diff = diff / ((high_mean + low_mean) / 2))

  p7 <- ggplot(bal, aes(x = reorder(variable, abs(std_diff)), y = std_diff)) +
    geom_col(aes(fill = significant), width = 0.6) +
    geom_hline(yintercept = 0, color = "gray50") +
    coord_flip() +
    scale_fill_manual(values = c("FALSE" = "#3498DB", "TRUE" = "#E74C3C"),
                      labels = c("p > 0.05", "p < 0.05")) +
    labs(
      title = "Pre-Period Balance: High vs Low Merger Exposure Counties",
      subtitle = "Standardized mean differences in pre-2018 characteristics",
      x = NULL, y = "Standardized Difference",
      fill = NULL
    ) +
    theme_apep
  ggsave(file.path(fig_dir, "fig7_balance.pdf"), p7, width = 8, height = 5)
}

cat("\nAll figures saved to", fig_dir, "\n")
cat("Files:", list.files(fig_dir, pattern = "\\.pdf$"), "\n")
