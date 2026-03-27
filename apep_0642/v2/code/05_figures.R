## 05_figures.R — Generate all figures
## APEP-0642 v2: Regulatory Whack-a-Mole

source("00_packages.R")

data_dir <- "../data"
fig_dir  <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

# Load event study coefficients and models
es_coefs <- fread(file.path(data_dir, "event_study_coefs.csv"))
models   <- readRDS(file.path(data_dir, "models.rds"))

# ============================================================
# Theme
# ============================================================
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
      plot.title = element_text(size = 13, face = "bold", hjust = 0),
      plot.subtitle = element_text(size = 10, color = "grey40", hjust = 0),
      plot.caption = element_text(size = 8, color = "grey50", hjust = 1),
      plot.margin = margin(10, 15, 10, 10)
    )
}
apep_colors <- c("#0072B2", "#D55E00", "#009E73", "#CC79A7", "#F0E442", "#56B4E9")

# Helper: add reference line at t=-1 and zero line
es_base <- function(p) {
  p + geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey60")
}

# ============================================================
# Figure 1: Air vs Non-Air Event Study
# ============================================================
cat("=== Figure 1: Air vs Non-Air Event Study ===\n")

es_main <- es_coefs[medium %in% c("Air", "NonAir")]
# Add t=-1 reference point
ref_rows <- data.table(medium = c("Air", "NonAir"),
                       event_time = c(-1, -1),
                       estimate = c(0, 0), se = c(0, 0), pvalue = c(1, 1))
es_main <- rbind(es_main, ref_rows)
es_main[, ci_lo := estimate - 1.96 * se]
es_main[, ci_hi := estimate + 1.96 * se]
es_main[, medium_label := fifelse(medium == "Air", "Air Releases", "Non-Air Releases")]

p1 <- ggplot(es_main, aes(x = event_time, y = estimate,
                           color = medium_label, fill = medium_label)) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, color = NA) +
  geom_point(size = 2.5) +
  geom_line(linewidth = 0.8) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey60") +
  scale_color_manual(values = c("Air Releases" = apep_colors[1],
                                "Non-Air Releases" = apep_colors[2])) +
  scale_fill_manual(values = c("Air Releases" = apep_colors[1],
                               "Non-Air Releases" = apep_colors[2])) +
  scale_x_continuous(breaks = -5:5) +
  labs(x = "Years Relative to First CAA Inspection",
       y = "Coefficient (log releases)",
       title = "Event Study: Air vs. Non-Air Releases Around CAA Inspections",
       color = NULL, fill = NULL) +
  theme_apep()

ggsave(file.path(fig_dir, "fig1_event_study_main.pdf"), p1,
       width = 8, height = 5.5, device = cairo_pdf)
cat("  Saved fig1_event_study_main.pdf\n")

# ============================================================
# Figure 2: Medium-Specific Event Studies (4-panel)
# ============================================================
cat("=== Figure 2: Medium-Specific Event Studies ===\n")

es_medium <- es_coefs[medium %in% c("Air", "Water", "Land", "POTW")]
ref_rows2 <- data.table(medium = c("Air", "Water", "Land", "POTW"),
                        event_time = rep(-1, 4),
                        estimate = rep(0, 4), se = rep(0, 4), pvalue = rep(1, 4))
es_medium <- rbind(es_medium, ref_rows2)
es_medium[, ci_lo := estimate - 1.96 * se]
es_medium[, ci_hi := estimate + 1.96 * se]
es_medium[, medium := factor(medium, levels = c("Air", "Water", "Land", "POTW"))]

p2 <- ggplot(es_medium, aes(x = event_time, y = estimate)) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = apep_colors[1]) +
  geom_point(color = apep_colors[1], size = 2) +
  geom_line(color = apep_colors[1], linewidth = 0.7) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey60") +
  facet_wrap(~medium, scales = "free_y", ncol = 2) +
  scale_x_continuous(breaks = seq(-5, 5, by = 2)) +
  labs(x = "Years Relative to First CAA Inspection",
       y = "Coefficient (log releases)",
       title = "Medium-Specific Event Studies") +
  theme_apep() +
  theme(strip.text = element_text(face = "bold", size = 11))

ggsave(file.path(fig_dir, "fig2_event_study_medium.pdf"), p2,
       width = 9, height = 7, device = cairo_pdf)
cat("  Saved fig2_event_study_medium.pdf\n")

# ============================================================
# Figure 3: CAA vs Non-CAA Mechanism
# ============================================================
cat("=== Figure 3: CAA vs Non-CAA Mechanism ===\n")

# Extract coefficients from mechanism models
mech_data <- data.table(
  chemical = rep(c("CAA-Regulated", "Non-CAA"), each = 2),
  term = rep(c("Post × Air", "Post × Non-Air"), 2),
  estimate = c(coef(models$m_caa_noctl)["post_air"],
               coef(models$m_caa_noctl)["post_nonair"],
               coef(models$m_noncaa_noctl)["post_air"],
               coef(models$m_noncaa_noctl)["post_nonair"]),
  se = c(se(models$m_caa_noctl)["post_air"],
         se(models$m_caa_noctl)["post_nonair"],
         se(models$m_noncaa_noctl)["post_air"],
         se(models$m_noncaa_noctl)["post_nonair"])
)
mech_data[, ci_lo := estimate - 1.96 * se]
mech_data[, ci_hi := estimate + 1.96 * se]

p3 <- ggplot(mech_data, aes(x = term, y = estimate, color = chemical)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  position = position_dodge(width = 0.5), size = 0.8) +
  scale_color_manual(values = c("CAA-Regulated" = apep_colors[1],
                                "Non-CAA" = apep_colors[2])) +
  labs(x = NULL, y = "Coefficient (log releases)",
       title = "Mechanism Test: CAA vs. Non-CAA Chemicals",
       subtitle = "Cross-media substitution concentrated in CAA-regulated chemicals",
       color = NULL) +
  theme_apep() +
  theme(axis.text.x = element_text(size = 11))

ggsave(file.path(fig_dir, "fig3_mechanism_caa.pdf"), p3,
       width = 7, height = 5, device = cairo_pdf)
cat("  Saved fig3_mechanism_caa.pdf\n")

# ============================================================
# Figure 4: CWA-CAA Inspection Overlap
# ============================================================
cat("=== Figure 4: CWA-CAA Inspection Overlap ===\n")

# Load analysis panel to compute overlap statistics
df <- fread(file.path(data_dir, "analysis_panel.csv"))
if ("cwa_inspected" %in% names(df) && sum(df$cwa_inspected) > 0) {
  # Compute facility-year level overlap
  fac_year <- df[, .(caa_insp = max(inspected),
                     cwa_insp = max(cwa_inspected)),
                 by = .(frs_id, YEAR)]

  overlap_stats <- fac_year[, .(
    caa_only = sum(caa_insp == 1 & cwa_insp == 0),
    cwa_only = sum(caa_insp == 0 & cwa_insp == 1),
    both = sum(caa_insp == 1 & cwa_insp == 1),
    neither = sum(caa_insp == 0 & cwa_insp == 0)
  ), by = YEAR]

  overlap_long <- melt(overlap_stats, id.vars = "YEAR",
                       variable.name = "type", value.name = "count")
  overlap_long[, type := factor(type,
                                levels = c("neither", "caa_only", "cwa_only", "both"),
                                labels = c("Neither", "CAA Only", "CWA Only", "Both CAA + CWA"))]

  p4 <- ggplot(overlap_long, aes(x = YEAR, y = count, fill = type)) +
    geom_bar(stat = "identity", position = "stack") +
    scale_fill_manual(values = c("Neither" = "grey80",
                                 "CAA Only" = apep_colors[1],
                                 "CWA Only" = apep_colors[3],
                                 "Both CAA + CWA" = apep_colors[4])) +
    labs(x = "Year", y = "Facility-Year Observations",
         title = "CAA and CWA Inspection Overlap by Year",
         fill = NULL) +
    theme_apep()

  ggsave(file.path(fig_dir, "fig4_inspection_overlap.pdf"), p4,
         width = 8, height = 5, device = cairo_pdf)
  cat("  Saved fig4_inspection_overlap.pdf\n")
} else {
  cat("  Skipping Figure 4: no CWA inspection data available.\n")
  # Create placeholder
  p4_placeholder <- ggplot() +
    annotate("text", x = 0.5, y = 0.5, label = "CWA data not available", size = 6) +
    theme_void()
  ggsave(file.path(fig_dir, "fig4_inspection_overlap.pdf"), p4_placeholder,
         width = 8, height = 5, device = cairo_pdf)
}

# ============================================================
# Figure 5: Magnitudes — Offset Calculation
# ============================================================
cat("=== Figure 5: Magnitudes Visualization ===\n")

# Coefficient comparison: with and without CWA controls
coef_compare <- data.table(
  medium = rep(c("Air", "Water", "Land", "POTW"), 2),
  spec = rep(c("Without CWA/RCRA Controls", "With CWA/RCRA Controls"), each = 4),
  estimate = c(
    coef(models$medium_results_noctl$Air)["post"],
    coef(models$medium_results_noctl$Water)["post"],
    coef(models$medium_results_noctl$Land)["post"],
    coef(models$medium_results_noctl$POTW)["post"],
    coef(models$medium_results_ctl$Air)["post"],
    coef(models$medium_results_ctl$Water)["post"],
    coef(models$medium_results_ctl$Land)["post"],
    coef(models$medium_results_ctl$POTW)["post"]
  ),
  se = c(
    se(models$medium_results_noctl$Air)["post"],
    se(models$medium_results_noctl$Water)["post"],
    se(models$medium_results_noctl$Land)["post"],
    se(models$medium_results_noctl$POTW)["post"],
    se(models$medium_results_ctl$Air)["post"],
    se(models$medium_results_ctl$Water)["post"],
    se(models$medium_results_ctl$Land)["post"],
    se(models$medium_results_ctl$POTW)["post"]
  )
)
coef_compare[, ci_lo := estimate - 1.96 * se]
coef_compare[, ci_hi := estimate + 1.96 * se]
coef_compare[, medium := factor(medium, levels = c("Air", "Water", "Land", "POTW"))]

p5 <- ggplot(coef_compare, aes(x = medium, y = estimate, color = spec)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  position = position_dodge(width = 0.5), size = 0.8) +
  scale_color_manual(values = c("Without CWA/RCRA Controls" = apep_colors[2],
                                "With CWA/RCRA Controls" = apep_colors[1])) +
  labs(x = "Release Medium", y = "Post-Inspection Coefficient (log releases)",
       title = "Medium-Specific Effects: Before and After Controlling for CWA/RCRA Enforcement",
       color = NULL) +
  theme_apep()

ggsave(file.path(fig_dir, "fig5_magnitudes_comparison.pdf"), p5,
       width = 8, height = 5.5, device = cairo_pdf)
cat("  Saved fig5_magnitudes_comparison.pdf\n")

# ============================================================
# Appendix Figure A1: Randomization Inference (if available)
# ============================================================
ri_file <- file.path(data_dir, "ri_distribution.csv")
if (file.exists(ri_file)) {
  cat("=== Appendix Figure A1: Randomization Inference ===\n")
  ri_dist <- fread(ri_file)

  actual_coef <- coef(models$m1_baseline)["post_nonair"]

  pA1 <- ggplot(ri_dist, aes(x = coef_nonair)) +
    geom_histogram(bins = 50, fill = "grey70", color = "grey50") +
    geom_vline(xintercept = actual_coef, color = apep_colors[2], linewidth = 1.2) +
    annotate("text", x = actual_coef, y = Inf, vjust = 2,
             label = paste0("Actual = ", round(actual_coef, 4)),
             color = apep_colors[2], fontface = "bold") +
    labs(x = "Placebo Post × Non-Air Coefficient",
         y = "Count",
         title = "Randomization Inference: Non-Air Substitution") +
    theme_apep()

  ggsave(file.path(fig_dir, "figA1_randomization_inference.pdf"), pA1,
         width = 7, height = 5, device = cairo_pdf)
  cat("  Saved figA1_randomization_inference.pdf\n")
}

cat("\n=== All figures complete ===\n")
