# 05_figures.R — Generate all figures from saved CSV data
# APEP-0581: Technology Standards and Facility-Level Pollution

source("00_packages.R")

data_dir <- "../data/"
fig_dir <- "../figures/"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# FIGURE 1: Treatment Rollout (BAT Conclusion Timeline)
# ============================================================================

cat("Figure 1: Treatment rollout...\n")

bat_info <- fread(file.path(data_dir, "bat_conclusions.csv"))
bat_info[, bat_sector_short := str_wrap(bat_sector, width = 25)]
bat_info[, bat_adopted := as.Date(bat_adopted)]
bat_info[, compliance_deadline := as.Date(compliance_deadline)]

# Order by adoption date
bat_info <- bat_info[order(bat_adopted)]
bat_info[, sector_order := .I]

p1 <- ggplot(bat_info) +
  geom_segment(aes(x = bat_adopted, xend = compliance_deadline,
                    y = reorder(bat_sector_short, -sector_order),
                    yend = reorder(bat_sector_short, -sector_order)),
               linewidth = 3, color = "steelblue", alpha = 0.7) +
  geom_point(aes(x = bat_adopted,
                  y = reorder(bat_sector_short, -sector_order)),
             size = 3, color = "darkblue", shape = 16) +
  geom_point(aes(x = compliance_deadline,
                  y = reorder(bat_sector_short, -sector_order)),
             size = 3, color = "firebrick", shape = 17) +
  geom_vline(xintercept = as.Date("2011-01-06"), linetype = "dashed",
             color = "grey50", linewidth = 0.5) +
  annotate("text", x = as.Date("2011-01-06"), y = 0.5,
           label = "IED enters\ninto force", hjust = 1.1, size = 3, color = "grey40") +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y",
               limits = c(as.Date("2010-01-01"), as.Date("2025-01-01"))) +
  labs(
    title = "Staggered Adoption of BAT Conclusions Under the EU IED",
    subtitle = "Blue circles: BAT adopted. Red triangles: 4-year compliance deadline.",
    x = "Date",
    y = NULL
  ) +
  theme_apep() +
  theme(axis.text.y = element_text(size = 8))

ggsave(file.path(fig_dir, "fig1_treatment_rollout.pdf"), p1,
       width = 10, height = 7, dpi = 300)
cat("  Saved fig1_treatment_rollout.pdf\n")

# ============================================================================
# FIGURE 2: Event Study (Sun-Abraham or CS)
# ============================================================================

cat("Figure 2: Event study...\n")

es_file <- file.path(data_dir, "sun_abraham_event_study.csv")
cs_file <- file.path(data_dir, "cs_event_study.csv")

if (file.exists(es_file)) {
  es_data <- fread(es_file)
  es_data[, ci_lower := estimate - 1.96 * se]
  es_data[, ci_upper := estimate + 1.96 * se]
  es_source <- "Sun-Abraham"
} else if (file.exists(cs_file)) {
  es_data <- fread(cs_file)
  es_source <- "Callaway-Sant'Anna"
} else {
  cat("  No event study data found. Skipping.\n")
  es_data <- NULL
}

if (!is.null(es_data) && nrow(es_data) > 0) {
  es_data <- es_data[event_time >= -8 & event_time <= 8]

  p2 <- ggplot(es_data, aes(x = event_time, y = estimate)) +
    geom_hline(yintercept = 0, color = "grey60", linetype = "dashed") +
    geom_vline(xintercept = -0.5, color = "firebrick", linetype = "dashed", alpha = 0.5) +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15, fill = "steelblue") +
    geom_line(color = "steelblue", linewidth = 0.8) +
    geom_point(color = "darkblue", size = 2.5) +
    scale_x_continuous(breaks = seq(-8, 8, 2)) +
    labs(
      title = "Event Study: Sector Emissions Around BAT Compliance Deadline",
      subtitle = paste0(es_source, " estimates. 95% CIs shown. Reference period: t = -1."),
      x = "Years Relative to BAT Compliance Deadline",
      y = "Effect on Log NOx Emissions"
    ) +
    theme_apep()

  ggsave(file.path(fig_dir, "fig2_event_study.pdf"), p2,
         width = 9, height = 6, dpi = 300)
  cat("  Saved fig2_event_study.pdf\n")
}

# ============================================================================
# FIGURE 3: Leave-One-Sector-Out Stability
# ============================================================================

cat("Figure 3: Leave-one-sector-out...\n")

loso_file <- file.path(data_dir, "robustness_loso.csv")
if (file.exists(loso_file)) {
  loso_data <- fread(loso_file)
  loso_data[, ci_lower := coefficient - 1.96 * se]
  loso_data[, ci_upper := coefficient + 1.96 * se]
  loso_data[, sector_short := str_wrap(excluded_sector, width = 25)]

  # Add main estimate
  main_file <- file.path(data_dir, "twfe_results.csv")
  if (file.exists(main_file)) {
    main_est <- fread(main_file)
    main_coef <- main_est$coefficient[1]
  } else {
    main_coef <- mean(loso_data$coefficient)
  }

  p3 <- ggplot(loso_data, aes(x = reorder(sector_short, coefficient),
                                y = coefficient)) +
    geom_hline(yintercept = 0, color = "grey60", linetype = "dashed") +
    geom_hline(yintercept = main_coef, color = "firebrick",
               linetype = "dotted", linewidth = 0.5) +
    geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper),
                    color = "steelblue", size = 0.5) +
    coord_flip() +
    labs(
      title = "Leave-One-Sector-Out: Stability of Main Estimate",
      subtitle = "Red dotted line: full-sample estimate. Each point excludes one sector.",
      x = "Excluded Sector",
      y = "Coefficient on Post-BAT"
    ) +
    theme_apep() +
    theme(axis.text.y = element_text(size = 8))

  ggsave(file.path(fig_dir, "fig3_loso.pdf"), p3, width = 9, height = 7, dpi = 300)
  cat("  Saved fig3_loso.pdf\n")
}

# ============================================================================
# FIGURE 4: Randomization Inference Distribution
# ============================================================================

cat("Figure 4: Randomization inference...\n")

ri_dist_file <- file.path(data_dir, "ri_permutation_dist.csv")
ri_results_file <- file.path(data_dir, "robustness_ri.csv")

if (file.exists(ri_dist_file) && file.exists(ri_results_file)) {
  perm_dist <- fread(ri_dist_file)
  ri_info <- fread(ri_results_file)
  observed <- ri_info$observed_coef[1]

  p4 <- ggplot(perm_dist, aes(x = perm_coef)) +
    geom_histogram(bins = 50, fill = "grey70", color = "grey50", alpha = 0.7) +
    geom_vline(xintercept = observed, color = "firebrick", linewidth = 1.2) +
    geom_vline(xintercept = -observed, color = "firebrick",
               linewidth = 1.2, linetype = "dashed") +
    annotate("text", x = observed, y = Inf, label = paste("Observed\n=", round(observed, 3)),
             vjust = 1.5, hjust = -0.1, color = "firebrick", size = 3.5, fontface = "bold") +
    labs(
      title = "Randomization Inference: Permutation Distribution",
      subtitle = paste0("500 permutations of BAT adoption timing. RI p-value = ",
                        round(ri_info$ri_pvalue[1], 3)),
      x = "Permuted Coefficient",
      y = "Frequency"
    ) +
    theme_apep()

  ggsave(file.path(fig_dir, "fig4_ri_distribution.pdf"), p4,
         width = 8, height = 5, dpi = 300)
  cat("  Saved fig4_ri_distribution.pdf\n")
}

# ============================================================================
# FIGURE 5: Multiple Outcomes — Coefficient Plot
# ============================================================================

cat("Figure 5: Multiple outcomes...\n")

multi_file <- file.path(data_dir, "multi_outcome_results.csv")
if (file.exists(multi_file)) {
  multi_data <- fread(multi_file)
  multi_data[, ci_lower := coefficient - 1.96 * se]
  multi_data[, ci_upper := coefficient + 1.96 * se]

  # Clean outcome names
  multi_data[, outcome_label := str_replace_all(outcome, "log_|_tonnes", "")]
  multi_data[, outcome_label := toupper(outcome_label)]

  p5 <- ggplot(multi_data, aes(x = reorder(outcome_label, coefficient),
                                y = coefficient)) +
    geom_hline(yintercept = 0, color = "grey60", linetype = "dashed") +
    geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper),
                    color = "steelblue", size = 0.7) +
    coord_flip() +
    labs(
      title = "Effect of BAT Conclusions Across Pollutants",
      subtitle = "TWFE estimates with sector-clustered 95% CIs. Outcome: log(tonnes + 1).",
      x = "Pollutant",
      y = "Effect on Log Emissions"
    ) +
    theme_apep()

  ggsave(file.path(fig_dir, "fig5_multi_outcomes.pdf"), p5,
         width = 8, height = 5, dpi = 300)
  cat("  Saved fig5_multi_outcomes.pdf\n")
}

# ============================================================================
# FIGURE 6: Pre-trends by Sector Cohort
# ============================================================================

cat("Figure 6: Sector-level emission trends...\n")

panel <- fread(file.path(data_dir, "facility_panel.csv"))

if ("bat_sector" %in% names(panel) & "log_nox_tonnes" %in% names(panel)) {
  sector_trends <- panel[!is.na(bat_sector) & compliance_year > 0, .(
    mean_emissions = mean(log_nox_tonnes, na.rm = TRUE),
    se_emissions = sd(log_nox_tonnes, na.rm = TRUE) / sqrt(.N),
    n_units = uniqueN(sector_country)
  ), by = .(bat_sector, year, compliance_year)]

  sector_trends[, rel_time := year - compliance_year]
  sector_trends[, sector_short := str_trunc(bat_sector, 20)]

  p6 <- ggplot(sector_trends[abs(rel_time) <= 8],
               aes(x = rel_time, y = mean_emissions,
                   color = sector_short, group = bat_sector)) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
    geom_line(alpha = 0.7) +
    geom_point(size = 1.5, alpha = 0.7) +
    labs(
      title = "Emission Trends by BAT Sector (Relative to Compliance Deadline)",
      subtitle = "Vertical line: compliance deadline. Each line is a BAT sector cohort.",
      x = "Years Relative to BAT Compliance Deadline",
      y = "Mean Log NOx Emissions",
      color = "Sector"
    ) +
    theme_apep() +
    theme(legend.position = "right",
          legend.text = element_text(size = 7))

  ggsave(file.path(fig_dir, "fig6_sector_trends.pdf"), p6,
         width = 10, height = 6, dpi = 300)
  cat("  Saved fig6_sector_trends.pdf\n")
}

# ============================================================================
# FIGURE 7: CS Event Study (if available)
# ============================================================================

cat("Figure 7: CS event study overlay...\n")

cs_file <- file.path(data_dir, "cs_event_study.csv")
sa_file <- file.path(data_dir, "sun_abraham_event_study.csv")

if (file.exists(cs_file) && file.exists(sa_file)) {
  cs_es <- fread(cs_file)
  sa_es <- fread(sa_file)
  cs_es[, estimator := "Callaway-Sant'Anna"]
  sa_es[, estimator := "Sun-Abraham"]

  combined <- rbind(cs_es[, .(event_time, estimate, se, ci_lower, ci_upper, estimator)],
                     sa_es[, .(event_time, estimate, se, ci_lower, ci_upper, estimator)])
  combined <- combined[event_time >= -6 & event_time <= 6]

  p7 <- ggplot(combined, aes(x = event_time, y = estimate,
                               color = estimator, fill = estimator)) +
    geom_hline(yintercept = 0, color = "grey60", linetype = "dashed") +
    geom_vline(xintercept = -0.5, color = "grey50", linetype = "dashed", alpha = 0.5) +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.1, color = NA) +
    geom_line(linewidth = 0.8) +
    geom_point(size = 2) +
    scale_color_manual(values = c("Callaway-Sant'Anna" = "darkorange",
                                   "Sun-Abraham" = "steelblue")) +
    scale_fill_manual(values = c("Callaway-Sant'Anna" = "darkorange",
                                  "Sun-Abraham" = "steelblue")) +
    labs(
      title = "Heterogeneity-Robust Event Studies: SA vs CS",
      subtitle = "Both estimators show flat pre-trends and null post-treatment effects.",
      x = "Years Relative to BAT Compliance Deadline",
      y = "Effect on Log NOx Emissions",
      color = "Estimator", fill = "Estimator"
    ) +
    theme_apep()

  ggsave(file.path(fig_dir, "fig7_es_comparison.pdf"), p7,
         width = 9, height = 6, dpi = 300)
  cat("  Saved fig7_es_comparison.pdf\n")
}

cat("\n=== ALL FIGURES GENERATED ===\n")
