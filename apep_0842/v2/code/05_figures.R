# 05_figures.R — Event study and visual evidence
# apep_0842 v2: The Designation Illusion

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
robustness <- readRDS("../data/robustness_results.rds")
sco_timing <- readRDS("../data/event_study_panel.rds")

# APEP standard theme
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

# ============================================================
# Figure 1: Event Study — Recognition Rate
# ============================================================

cat("=== Figure 1: Event Study ===\n")

m_es <- results$m_es

# Extract event study coefficients from fixest
es_coefs <- as.data.frame(coef(m_es))
es_se <- as.data.frame(se(m_es))

# Parse event time from coefficient names
coef_names <- names(coef(m_es))
event_times <- as.integer(gsub("event_time_binned::", "", coef_names))

es_df <- data.frame(
  event_time = event_times,
  coef = as.numeric(coef(m_es)),
  se = as.numeric(se(m_es))
) %>%
  # Add the reference period (t = -1) with coefficient = 0
  bind_rows(data.frame(event_time = -1L, coef = 0, se = 0)) %>%
  arrange(event_time) %>%
  mutate(
    ci_lo = coef - 1.96 * se,
    ci_hi = coef + 1.96 * se
  )

cat(sprintf("  Event time range: %d to %d\n", min(es_df$event_time), max(es_df$event_time)))
cat(sprintf("  Coefficients:\n"))
print(es_df)

p1 <- ggplot(es_df, aes(x = event_time, y = coef)) +
  # Zero reference line
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.4) +
  # Vertical line at treatment
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey40", linewidth = 0.4) +
  # Confidence intervals
  geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi),
                width = 0.2, color = "#0072B2", linewidth = 0.5) +
  # Point estimates
  geom_point(aes(shape = ifelse(event_time == -1, "Reference", "Estimate")),
             color = "#0072B2", size = 2.5) +
  scale_shape_manual(values = c("Reference" = 1, "Estimate" = 16), guide = "none") +
  # Labels
  labs(
    x = "Years Relative to SCO Designation",
    y = "Effect on Recognition Rate",
    caption = paste0("Notes: Coefficients from triple-difference with pair, destination\u00d7year FE. ",
                     "Reference period: t = \u22121. Bars show 95% CIs. SEs clustered by destination.")
  ) +
  scale_x_continuous(breaks = seq(-4, 5, 1),
                     labels = c(expression("" <= -4), "-3", "-2", "-1", "0", "1", "2", "3", "4", expression("" >= 5))) +
  theme_apep()

ggsave("../figures/fig1_event_study.pdf", p1, width = 7, height = 4.5)
ggsave("../figures/fig1_event_study.png", p1, width = 7, height = 4.5, dpi = 300)

cat("  Saved fig1_event_study.pdf\n")

# ============================================================
# Figure 2: Randomization Inference Distribution
# ============================================================

cat("\n=== Figure 2: Randomization Inference ===\n")

if (!is.null(robustness$ri)) {
  ri_df <- data.frame(beta = robustness$ri$betas)
  actual_beta <- coef(results$m2)["sco"]

  p2 <- ggplot(ri_df, aes(x = beta)) +
    geom_histogram(aes(y = after_stat(density)), bins = 50,
                   fill = "grey80", color = "grey60", linewidth = 0.3) +
    geom_vline(xintercept = actual_beta, color = "#D55E00", linewidth = 0.8,
               linetype = "solid") +
    geom_vline(xintercept = -actual_beta, color = "#D55E00", linewidth = 0.8,
               linetype = "dashed") +
    annotate("text", x = actual_beta, y = Inf, label = paste0("Actual: ", round(actual_beta, 3)),
             vjust = 2, hjust = -0.1, color = "#D55E00", size = 3.5) +
    labs(
      x = latex2exp::TeX("Placebo $\\hat{\\beta}$"),
      y = "Density",
      caption = paste0("Notes: Distribution of 999 placebo estimates from randomization inference. ",
                       "Vertical lines: actual estimate (solid) and its mirror (dashed). ",
                       "RI p-value: ", sprintf("%.3f", robustness$ri$p), ".")
    ) +
    theme_apep()

  ggsave("../figures/fig2_ri_distribution.pdf", p2, width = 7, height = 4.5)
  cat("  Saved fig2_ri_distribution.pdf\n")
} else {
  cat("  Skipping RI figure (no RI results)\n")
}

cat("\n=== All figures saved ===\n")
