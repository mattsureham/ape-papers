# 05_figures.R — Publication-ready figures
# APEP-0869 V2: Private Enforcement and the Reorganization of Industry

source("00_packages.R")
library(latex2exp)

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

apep_colors <- c("#0072B2", "#D55E00", "#009E73", "#CC79A7", "#F0E442", "#56B4E9")

# ============================================================
# Load data
# ============================================================

es_emp <- fread("../data/event_study_employment.csv")
es_estab <- fread("../data/event_study_establishments.csv")
sector_dt <- fread("../data/sector_specific_effects.csv")

# ============================================================
# Figure 1: Event Study — Employment
# ============================================================

cat("Figure 1: Event study — Employment\n")

# Trim to reasonable window
es_emp_plot <- es_emp[event_q >= -16 & event_q <= 20]

fig1 <- ggplot(es_emp_plot, aes(x = event_q, y = coef)) +
  geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
  geom_vline(xintercept = 0, color = "grey70", linetype = "dashed", linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = apep_colors[1], alpha = 0.2) +
  geom_line(color = apep_colors[1], linewidth = 0.8) +
  geom_point(color = apep_colors[1], size = 1.5) +
  annotate("text", x = 0.5, y = max(es_emp_plot$ci_hi, na.rm = TRUE) * 0.9,
           label = "Rosenbach\n(2019Q1)", hjust = 0, size = 3, color = "grey40") +
  labs(
    title = "The Litigation Tax on Employment",
    subtitle = expression(paste("Coefficients: ", Illinois[i] %*% Quarter[t] %*% BiometricExposure[j])),
    x = "Quarters Relative to Rosenbach Ruling",
    y = "Log Employment",
    caption = "Notes: Border counties only. 95% CIs from state-clustered SEs."
  ) +
  theme_apep()

ggsave("../figures/fig1_event_study_employment.pdf", fig1, width = 8, height = 5)

# ============================================================
# Figure 2: Event Study — Establishments
# ============================================================

cat("Figure 2: Event study — Establishments\n")

es_estab_plot <- es_estab[event_q >= -16 & event_q <= 20]

fig2 <- ggplot(es_estab_plot, aes(x = event_q, y = coef)) +
  geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
  geom_vline(xintercept = 0, color = "grey70", linetype = "dashed", linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = apep_colors[2], alpha = 0.2) +
  geom_line(color = apep_colors[2], linewidth = 0.8) +
  geom_point(color = apep_colors[2], size = 1.5) +
  annotate("text", x = 0.5, y = max(es_estab_plot$ci_hi, na.rm = TRUE) * 0.9,
           label = "Rosenbach\n(2019Q1)", hjust = 0, size = 3, color = "grey40") +
  labs(
    title = "Scale Compression: More Establishments, Fewer Workers",
    subtitle = expression(paste("Coefficients: ", Illinois[i] %*% Quarter[t] %*% BiometricExposure[j])),
    x = "Quarters Relative to Rosenbach Ruling",
    y = "Log Establishments",
    caption = "Notes: Border counties only. 95% CIs from state-clustered SEs."
  ) +
  theme_apep()

ggsave("../figures/fig2_event_study_establishments.pdf", fig2, width = 8, height = 5)

# ============================================================
# Figure 3: Sector-Specific Effects vs Exposure
# ============================================================

cat("Figure 3: Sector effects vs biometric exposure\n")

fig3 <- ggplot(sector_dt, aes(x = bio_exposure, y = coef)) +
  geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
  geom_errorbar(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
                width = 0.02, color = "grey60") +
  geom_point(size = 3, color = apep_colors[1]) +
  geom_text(aes(label = sector), hjust = -0.15, vjust = -0.5, size = 3) +
  geom_smooth(method = "lm", se = FALSE, color = apep_colors[2],
              linetype = "dashed", linewidth = 0.5) +
  labs(
    title = "Employment Effects Track Biometric Exposure",
    subtitle = "Sector-specific Illinois × Post coefficients vs. O*NET biometric intensity",
    x = "Biometric Exposure Index (0-1 scale)",
    y = "Employment Effect (log points)",
    caption = "Notes: Each point is a 2-digit NAICS sector. 95% CIs from state-clustered SEs."
  ) +
  theme_apep()

ggsave("../figures/fig3_exposure_gradient.pdf", fig3, width = 8, height = 6)

# ============================================================
# Figure 4: Randomization Inference Distribution
# ============================================================

cat("Figure 4: Randomization inference\n")

if (file.exists("../data/randomization_inference.csv")) {
  ri_data <- fread("../data/randomization_inference.csv")
  actual <- ri_data[type == "actual"]$coef
  placebos <- ri_data[type != "actual"]$coef

  fig4 <- ggplot(ri_data[type != "actual"], aes(x = coef)) +
    geom_histogram(bins = 20, fill = "grey70", color = "white") +
    geom_vline(xintercept = actual, color = apep_colors[2], linewidth = 1.2) +
    annotate("text", x = actual, y = Inf, label = "Actual\nestimate",
             hjust = -0.1, vjust = 1.5, size = 3.5, color = apep_colors[2], fontface = "bold") +
    labs(
      title = "Randomization Inference: Actual vs. Placebo Estimates",
      subtitle = "Distribution of placebo coefficients from permuting treatment state and timing",
      x = expression(paste("Triple-Difference Coefficient (", hat(beta), ")")),
      y = "Count",
      caption = sprintf("Notes: %d placebo permutations. Actual estimate = %.3f.",
                        nrow(ri_data[type != "actual"]), actual)
    ) +
    theme_apep()

  ggsave("../figures/fig4_randomization_inference.pdf", fig4, width = 8, height = 5)
} else {
  cat("  Skipped — RI data not yet available.\n")
}

# ============================================================
# Figure 5: Combined event study (employment + establishments)
# ============================================================

cat("Figure 5: Combined event study\n")

es_combined <- rbind(
  es_emp_plot[, .(event_q, coef, ci_lo, ci_hi, outcome = "Employment")],
  es_estab_plot[, .(event_q, coef, ci_lo, ci_hi, outcome = "Establishments")]
)

fig5 <- ggplot(es_combined, aes(x = event_q, y = coef, color = outcome, fill = outcome)) +
  geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
  geom_vline(xintercept = 0, color = "grey70", linetype = "dashed") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, color = NA) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.2) +
  scale_color_manual(values = c("Employment" = apep_colors[1], "Establishments" = apep_colors[2])) +
  scale_fill_manual(values = c("Employment" = apep_colors[1], "Establishments" = apep_colors[2])) +
  labs(
    title = "The Employment-Establishment Divergence",
    subtitle = "Employment falls while establishments rise in high-exposure industries",
    x = "Quarters Relative to Rosenbach Ruling",
    y = "Log Outcome",
    color = "Outcome", fill = "Outcome",
    caption = "Notes: Border counties, continuous exposure specification. 95% CIs."
  ) +
  theme_apep()

ggsave("../figures/fig5_divergence.pdf", fig5, width = 8, height = 5.5)

cat("\n=== FIGURES COMPLETE ===\n")
cat(sprintf("Figures saved to: %s\n", normalizePath("../figures/")))
