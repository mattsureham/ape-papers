# ==============================================================================
# 05_figures.R — Publication-quality figures
# Paper: Protecting Landscapes, Punishing Renters (apep_0567)
# Switzerland's 2012 Second Homes Initiative (Lex Weber)
#
# All inputs are CSV files written by 03_main_analysis.R and 04_robustness.R.
# All outputs are PDF files saved to ../figures/.
# ==============================================================================

source("00_packages.R")

# --- Palette ---
col_treated  <- "#2C3E50"
col_control  <- "#E74C3C"
col_highlight <- "#3498DB"

# --- Paths ---
data_dir <- "../data"
fig_dir  <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# ==============================================================================
# Figure 1: Parallel Trends — Vacancy Rate by Treatment Status
# ==============================================================================
cat("Figure 1: Parallel trends plot\n")

trends <- read.csv(file.path(data_dir, "trends_by_treatment.csv"),
                   stringsAsFactors = FALSE)

# Drop rows with missing vacancy data (early years before vacancy series starts)
trends <- trends[!is.na(trends$mean_vacancy), ]

# Ensure treated is a factor with clear labels
trends$group <- ifelse(trends$treated == 1, "Treated (>20% second homes)",
                       "Control (\u226420% second homes)")

fig1 <- ggplot(trends, aes(x = year, y = mean_vacancy,
                           color = group, linetype = group)) +
  geom_vline(xintercept = 2013, color = "grey40", linewidth = 0.6) +
  annotate("text", x = 2013.15, y = max(trends$mean_vacancy, na.rm = TRUE),
           label = "Initiative\nadopted", hjust = 0, size = 3, color = "grey40") +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.8) +
  scale_color_manual(values = c(col_control, col_treated)) +
  scale_linetype_manual(values = c("dashed", "solid")) +
  labs(
    title = "Vacancy Rates in Treated vs. Control Municipalities",
    x = "Year",
    y = "Mean Vacancy Rate (%)",
    color = NULL,
    linetype = NULL
  ) +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig1_parallel_trends.pdf"), fig1,
       width = 7, height = 5, device = cairo_pdf)

# ==============================================================================
# Figure 2: Event Study — Vacancy Rate
# ==============================================================================
cat("Figure 2: Event study — vacancy rate\n")

es_vac <- read.csv(file.path(data_dir, "event_study_vacancy.csv"),
                   stringsAsFactors = FALSE)

fig2 <- ggplot(es_vac, aes(x = rel_year, y = coefficient)) +
  # Shaded post-treatment region
  annotate("rect", xmin = 0, xmax = max(es_vac$rel_year) + 0.5,
           ymin = -Inf, ymax = Inf, alpha = 0.06, fill = col_highlight) +
  # Reference and treatment lines
  geom_vline(xintercept = -1, linetype = "dashed", color = "grey50",
             linewidth = 0.5) +
  geom_vline(xintercept = 0, linetype = "solid", color = "grey30",
             linewidth = 0.6) +
  # Zero line
  geom_hline(yintercept = 0, color = "grey70", linewidth = 0.4) +
  # Confidence intervals
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper),
                width = 0.2, color = col_treated, linewidth = 0.5) +
  # Point estimates
  geom_point(color = col_treated, size = 2.2) +
  # Annotations
  annotate("text", x = -1, y = max(es_vac$ci_upper, na.rm = TRUE) * 1.05,
           label = "t = -1\n(reference)", size = 2.8, hjust = 1.1,
           color = "grey50") +
  annotate("text", x = 0, y = max(es_vac$ci_upper, na.rm = TRUE) * 1.05,
           label = "Treatment\nonset", size = 2.8, hjust = -0.1,
           color = "grey30") +
  labs(
    title = "Event Study: Effect on Vacancy Rate",
    x = "Years Relative to Treatment",
    y = "Coefficient Estimate"
  )

ggsave(file.path(fig_dir, "fig2_event_study_vacancy.pdf"), fig2,
       width = 7, height = 5, device = cairo_pdf)

# ==============================================================================
# Figure 3: Event Study — Log Population
# ==============================================================================
cat("Figure 3: Event study — log population\n")

es_pop <- read.csv(file.path(data_dir, "event_study_pop.csv"),
                   stringsAsFactors = FALSE)

fig3 <- ggplot(es_pop, aes(x = rel_year, y = coefficient)) +
  annotate("rect", xmin = 0, xmax = max(es_pop$rel_year) + 0.5,
           ymin = -Inf, ymax = Inf, alpha = 0.06, fill = col_highlight) +
  geom_vline(xintercept = -1, linetype = "dashed", color = "grey50",
             linewidth = 0.5) +
  geom_vline(xintercept = 0, linetype = "solid", color = "grey30",
             linewidth = 0.6) +
  geom_hline(yintercept = 0, color = "grey70", linewidth = 0.4) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper),
                width = 0.2, color = col_treated, linewidth = 0.5) +
  geom_point(color = col_treated, size = 2.2) +
  annotate("text", x = -1, y = max(es_pop$ci_upper, na.rm = TRUE) * 1.05,
           label = "t = -1\n(reference)", size = 2.8, hjust = 1.1,
           color = "grey50") +
  annotate("text", x = 0, y = max(es_pop$ci_upper, na.rm = TRUE) * 1.05,
           label = "Treatment\nonset", size = 2.8, hjust = -0.1,
           color = "grey30") +
  labs(
    title = "Event Study: Effect on Log Population",
    x = "Years Relative to Treatment",
    y = "Coefficient Estimate"
  )

ggsave(file.path(fig_dir, "fig3_event_study_population.pdf"), fig3,
       width = 7, height = 5, device = cairo_pdf)

# ==============================================================================
# Figure 4: RDD Plot at 20% Second-Home Threshold
# ==============================================================================
cat("Figure 4: RDD at 20% threshold\n")

# Construct RDD plot data from panel (post-treatment municipality-level means)
panel_rdd <- data.table::fread(file.path(data_dir, "panel.csv"))
rdd_dat <- panel_rdd[post == 1 & !is.na(second_home_share) & !is.na(vacancy_rate),
                     .(vacancy_rate = mean(vacancy_rate, na.rm = TRUE),
                       second_home_share = mean(second_home_share, na.rm = TRUE)),
                     by = gem_id]

# Center running variable at the cutoff for local polynomial
rdd_dat$centered <- rdd_dat$second_home_share - 20

fig4 <- ggplot(rdd_dat, aes(x = second_home_share, y = vacancy_rate)) +
  # Cutoff line
  geom_vline(xintercept = 20, linetype = "dashed", color = "grey40",
             linewidth = 0.6) +
  # Raw scatter (semi-transparent)
  geom_point(alpha = 0.25, size = 1.2, color = "grey50") +
  # Local polynomial fit — left of cutoff
  geom_smooth(data = subset(rdd_dat, second_home_share < 20),
              method = "loess", formula = y ~ x, se = TRUE,
              color = col_control, fill = col_control, alpha = 0.15,
              linewidth = 0.9) +
  # Local polynomial fit — right of cutoff
  geom_smooth(data = subset(rdd_dat, second_home_share >= 20),
              method = "loess", formula = y ~ x, se = TRUE,
              color = col_treated, fill = col_treated, alpha = 0.15,
              linewidth = 0.9) +
  annotate("text", x = 20.3, y = max(rdd_dat$vacancy_rate, na.rm = TRUE) * 0.95,
           label = "20% cutoff", hjust = 0, size = 3, color = "grey40") +
  labs(
    title = "Regression Discontinuity at 20% Second-Home Threshold",
    x = "Second-Home Share (%)",
    y = "Vacancy Rate (%, Post-Treatment)"
  )

ggsave(file.path(fig_dir, "fig4_rdd_threshold.pdf"), fig4,
       width = 7, height = 5, device = cairo_pdf)

# ==============================================================================
# Figure 5: Mechanism — Employment Effects by Sector
# ==============================================================================
cat("Figure 5: Mechanism — sectoral employment\n")

sectors <- read.csv(file.path(data_dir, "mechanism_sectors.csv"),
                    stringsAsFactors = FALSE)

# The CSV has columns: outcome, coefficient, se, t_stat, p_value, ...
# Create readable sector labels from outcome names
sectors$sector <- gsub("^log_emp_", "", sectors$outcome)
sectors$sector <- gsub("_", " ", sectors$sector)
sectors$sector <- tools::toTitleCase(sectors$sector)

# Compute 95% CI
sectors$ci_lower <- sectors$coefficient - 1.96 * sectors$se
sectors$ci_upper <- sectors$coefficient + 1.96 * sectors$se

# Order sectors by coefficient
sectors$sector <- factor(sectors$sector,
                         levels = sectors$sector[order(sectors$coefficient)])

fig5 <- ggplot(sectors, aes(x = coefficient, y = sector)) +
  geom_vline(xintercept = 0, color = "grey70", linewidth = 0.4) +
  geom_errorbarh(aes(xmin = ci_lower, xmax = ci_upper),
                 height = 0.2, color = col_treated, linewidth = 0.6) +
  geom_point(color = col_treated, size = 2.8) +
  labs(
    title = "Employment Effects by Sector (DiD Estimates)",
    x = "Coefficient Estimate",
    y = NULL
  )

ggsave(file.path(fig_dir, "fig5_mechanism_sectors.pdf"), fig5,
       width = 7, height = 4, device = cairo_pdf)

# ==============================================================================
# Figure 6: Heterogeneity by Tourism Intensity
# ==============================================================================
cat("Figure 6: Heterogeneity by tourism intensity\n")

hetero <- read.csv(file.path(data_dir, "heterogeneity.csv"),
                   stringsAsFactors = FALSE)

# Filter to vacancy_rate outcome and tourism_intensity dimension only
hetero <- hetero[hetero$outcome == "vacancy_rate" &
                 hetero$het_dim == "tourism_intensity", ]

# Create readable subgroup labels from het_group
hetero$subgroup <- gsub("^tourism_", "", hetero$het_group)
hetero$subgroup <- tools::toTitleCase(hetero$subgroup)

hetero$ci_lower <- hetero$coefficient - 1.96 * hetero$se
hetero$ci_upper <- hetero$coefficient + 1.96 * hetero$se

# Preserve intended ordering (High > Medium > Low)
hetero$subgroup <- factor(hetero$subgroup,
                          levels = rev(c("High", "Medium", "Low")))

fig6 <- ggplot(hetero, aes(x = coefficient, y = subgroup)) +
  geom_vline(xintercept = 0, color = "grey70", linewidth = 0.4) +
  geom_errorbarh(aes(xmin = ci_lower, xmax = ci_upper),
                 height = 0.2, color = col_highlight, linewidth = 0.6) +
  geom_point(color = col_highlight, size = 2.8) +
  labs(
    title = "Heterogeneous Effects by Tourism Intensity",
    x = "Coefficient Estimate (Vacancy Rate)",
    y = NULL
  )

ggsave(file.path(fig_dir, "fig6_heterogeneity_tourism.pdf"), fig6,
       width = 7, height = 4, device = cairo_pdf)

# ==============================================================================
# Figure 7: Randomization Inference
# ==============================================================================
cat("Figure 7: Randomization inference\n")

ri_file <- file.path(data_dir, "ri_distribution.csv")
ri_summ_file <- file.path(data_dir, "ri_summary.csv")

if (file.exists(ri_file) && file.exists(ri_summ_file)) {
  ri_dist <- read.csv(ri_file, stringsAsFactors = FALSE)
  ri_summ <- read.csv(ri_summ_file, stringsAsFactors = FALSE)

  real_coef  <- ri_summ$real_coef[1]
  ri_pvalue  <- ri_summ$ri_pvalue[1]

  # The CSV has column "coef" (from 04_robustness.R)
  fig7 <- ggplot(ri_dist, aes(x = coef)) +
    geom_histogram(bins = 50, fill = "grey80", color = "grey60",
                   linewidth = 0.3) +
    geom_vline(xintercept = real_coef, color = col_control,
               linewidth = 0.9, linetype = "solid") +
    annotate("text",
             x = real_coef,
             y = Inf,
             label = sprintf("Actual estimate = %.4f\nRI p-value = %.3f",
                             real_coef, ri_pvalue),
             hjust = ifelse(real_coef > median(ri_dist$coef, na.rm = TRUE), 1.1, -0.1),
             vjust = 1.5, size = 3.2, color = col_control) +
    labs(
      title = "Randomization Inference: Permutation Distribution",
      x = "Permuted Treatment Effect",
      y = "Frequency"
    )

  ggsave(file.path(fig_dir, "fig7_randomization_inference.pdf"), fig7,
         width = 7, height = 5, device = cairo_pdf)
} else {
  cat("  SKIPPED: ri_distribution.csv or ri_summary.csv not found (run 04_robustness.R first)\n")
}

# ==============================================================================
# Figure 8: Leave-One-Canton-Out Stability
# ==============================================================================
cat("Figure 8: Leave-one-canton-out\n")

loco_file <- file.path(data_dir, "leave_one_canton_out.csv")

if (file.exists(loco_file)) {
  loco <- read.csv(loco_file, stringsAsFactors = FALSE)

  # The CSV has columns: canton_dropped, coef, se, pvalue, n_treated, n_control
  loco$ci_lower <- loco$coef - 1.96 * loco$se
  loco$ci_upper <- loco$coef + 1.96 * loco$se

  # Drop rows with NA estimates
  loco <- loco[!is.na(loco$coef), ]

  # Order cantons alphabetically (top to bottom)
  loco$canton_dropped <- factor(loco$canton_dropped,
                                levels = rev(sort(unique(loco$canton_dropped))))

  # Compute full-sample estimate as the mean of all leave-one-out estimates
  full_est <- mean(loco$coef, na.rm = TRUE)

  fig8 <- ggplot(loco, aes(x = coef, y = canton_dropped)) +
    # Full-sample reference line
    geom_vline(xintercept = full_est, color = col_highlight,
               linetype = "dashed", linewidth = 0.5) +
    geom_vline(xintercept = 0, color = "grey70", linewidth = 0.4) +
    geom_errorbarh(aes(xmin = ci_lower, xmax = ci_upper),
                   height = 0.25, color = col_treated, linewidth = 0.5) +
    geom_point(color = col_treated, size = 2) +
    annotate("text",
             x = full_est,
             y = length(unique(loco$canton_dropped)) + 0.5,
             label = "Full-sample\nestimate",
             hjust = -0.1, size = 2.8, color = col_highlight) +
    labs(
      title = "Leave-One-Canton-Out: Estimate Stability",
      x = "Coefficient Estimate",
      y = "Canton Dropped"
    )

  ggsave(file.path(fig_dir, "fig8_leave_one_canton_out.pdf"), fig8,
         width = 7, height = max(4, 0.3 * length(unique(loco$canton_dropped)) + 1),
         device = cairo_pdf)
} else {
  cat("  SKIPPED: leave_one_canton_out.csv not found (run 04_robustness.R first)\n")
}

# ==============================================================================
cat("All figures saved to", fig_dir, "\n")
