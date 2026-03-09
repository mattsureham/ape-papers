## =============================================================================
## 05_figures.R — Generate All Figures from Saved CSV Data
## Paper: The Economic Integration Lottery
## =============================================================================

source("00_packages.R")

data_dir <- "../data/"
fig_dir <- "../figures/"
dir.create(fig_dir, showWarnings = FALSE)

## ---------------------------------------------------------------------------
## Figure 1: Within-Court Judge Leniency Variation
## ---------------------------------------------------------------------------

cat("Figure 1: Judge leniency variation...\n")

# Use scraped judge-court assignment data
jca <- fread(file.path(data_dir, "judge_court_assignments.csv"))
jca[, court_city_state := paste0(court_name, ", ", court_state)]

# Compute judge-level grant rate per court
# Keep courts with 5+ judges for meaningful boxes
court_judge_counts <- jca[, .(n_judges = .N, total_hearings = sum(court_hearings)),
                           by = court_city_state]
top_courts <- court_judge_counts[n_judges >= 5][order(-total_hearings)][1:min(25, .N)]$court_city_state

judge_top <- jca[court_city_state %in% top_courts & court_hearings >= 100]
# Ensure at least 3 judges per court for meaningful boxplots
judge_counts_filtered <- judge_top[, .N, by = court_city_state]
valid_courts <- judge_counts_filtered[N >= 3]$court_city_state
judge_top <- judge_top[court_city_state %in% valid_courts]

# Save figure data
fwrite(judge_top, file.path(data_dir, "fig1_judge_leniency.csv"))

p1 <- ggplot(judge_top, aes(x = reorder(court_city_state, judge_grant_rate / 100,
                                          FUN = median),
                              y = judge_grant_rate / 100)) +
  geom_boxplot(fill = "steelblue", alpha = 0.6, outlier.size = 0.8) +
  coord_flip() +
  labs(
    title = "Within-Court Immigration Judge Leniency Variation",
    subtitle = "Asylum grant rates by judge (judges with 100+ hearings at court)",
    x = "Immigration Court",
    y = "Judge-Level Asylum Grant Rate"
  ) +
  scale_y_continuous(labels = percent_format()) +
  theme_apep()

ggsave(file.path(fig_dir, "fig1_judge_leniency.pdf"), p1, width = 8, height = 8)
cat("  Saved fig1_judge_leniency.pdf\n")

## ---------------------------------------------------------------------------
## Figure 2: First Stage — Judge Leniency vs Court Grant Rate
## ---------------------------------------------------------------------------

cat("Figure 2: First stage scatter...\n")

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel <- panel[!is.na(avg_judge_leniency) & !is.na(court_grant_rate)]

# Cross-sectional first stage: average across years per court
court_cross <- panel[, .(
  court_grant_rate = mean(court_grant_rate),
  avg_judge_leniency = mean(avg_judge_leniency),
  n_judges = mean(n_judges)
), by = court_city]

# Save figure data
fwrite(court_cross, file.path(data_dir, "fig2_first_stage.csv"))

p2 <- ggplot(court_cross, aes(x = avg_judge_leniency, y = court_grant_rate)) +
  geom_point(aes(size = n_judges), color = "steelblue", alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, color = "firebrick", linewidth = 1) +
  labs(
    title = "First Stage: Judge Leniency Predicts Court-Level Asylum Grant Rates",
    subtitle = "Cross-sectional relationship across immigration courts",
    x = "Average Judge Leniency (caseload-weighted grant rate of judges)",
    y = "Court-Level Asylum Grant Rate",
    size = "Judges at Court"
  ) +
  scale_x_continuous(labels = percent_format()) +
  scale_y_continuous(labels = percent_format()) +
  theme_apep() +
  theme(legend.position = c(0.85, 0.25))

ggsave(file.path(fig_dir, "fig2_first_stage.pdf"), p2, width = 7, height = 6)
cat("  Saved fig2_first_stage.pdf\n")

## ---------------------------------------------------------------------------
## Figure 3: IV Results — Coefficient Plot
## ---------------------------------------------------------------------------

cat("Figure 3: IV coefficient plot...\n")

iv_results <- fread(file.path(data_dir, "iv_results.csv"))

if (nrow(iv_results) > 0) {
  # Order outcomes
  iv_results[, outcome := factor(outcome, levels = rev(c(
    "Log Total Employment", "Log Weekly Wage", "Log Establishments",
    "Log Accommodation Emp", "Log Admin Services Emp",
    "Log Finance Emp (Placebo)", "Log Professional Emp (Placebo)",
    "Noncitizen Share"
  )))]

  # Add placebo indicator
  iv_results[, is_placebo := grepl("Placebo", outcome)]

  # Save figure data
  fwrite(iv_results, file.path(data_dir, "fig3_iv_coefs.csv"))

  p3 <- ggplot(iv_results[!is.na(outcome)],
               aes(x = coef_iv, y = outcome,
                   color = is_placebo)) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
    geom_point(size = 3) +
    geom_errorbarh(aes(xmin = coef_iv - 1.96 * se_iv,
                        xmax = coef_iv + 1.96 * se_iv),
                    height = 0.2) +
    scale_color_manual(values = c("FALSE" = "steelblue", "TRUE" = "grey60"),
                       labels = c("Treatment Outcome", "Placebo Outcome"),
                       name = "") +
    labs(
      title = "IV Estimates: Effect of Asylum Grants on Local Labor Markets",
      subtitle = "2SLS using judge leniency instrument, year fixed effects",
      x = "IV Coefficient (effect of 1 pp increase in grant rate)",
      y = ""
    ) +
    theme_apep() +
    theme(legend.position = "bottom")

  ggsave(file.path(fig_dir, "fig3_iv_coefficients.pdf"), p3, width = 8, height = 6)
  cat("  Saved fig3_iv_coefficients.pdf\n")
}

## ---------------------------------------------------------------------------
## Figure 4: Placebo Test Comparison
## ---------------------------------------------------------------------------

cat("Figure 4: Placebo comparison...\n")

# Combine treatment and placebo IV results
if (file.exists(file.path(data_dir, "iv_results.csv")) &&
    file.exists(file.path(data_dir, "placebo_results.csv"))) {

  iv_all <- fread(file.path(data_dir, "iv_results.csv"))
  placebo <- fread(file.path(data_dir, "placebo_results.csv"))

  # Treatment outcomes
  treatment <- iv_all[grepl("Accom|Admin|Total Emp|Wage|Estab", outcome)]
  treatment[, type := "Treatment"]

  # Placebo outcomes
  if (nrow(placebo) > 0) {
    placebo[, type := "Placebo"]

    comparison <- rbind(
      treatment[, .(outcome, coef = coef_iv, se = se_iv, type)],
      placebo[, .(outcome, coef = coef_iv, se = se_iv, type)]
    )
    comparison[, outcome := factor(outcome, levels = rev(outcome))]

    fwrite(comparison, file.path(data_dir, "fig4_placebo_comparison.csv"))

    p4 <- ggplot(comparison, aes(x = coef, y = outcome, color = type)) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
      geom_point(size = 3) +
      geom_errorbarh(aes(xmin = coef - 1.96 * se, xmax = coef + 1.96 * se),
                      height = 0.2) +
      scale_color_manual(values = c("Treatment" = "steelblue", "Placebo" = "grey60"),
                         name = "") +
      labs(
        title = "Placebo Test: Low-Wage vs High-Wage Sector Response",
        subtitle = "Treatment sectors (accommodation, admin) vs placebo sectors (finance, professional)",
        x = "IV Coefficient",
        y = ""
      ) +
      theme_apep() +
      theme(legend.position = "bottom")

    ggsave(file.path(fig_dir, "fig4_placebo.pdf"), p4, width = 7, height = 5)
    cat("  Saved fig4_placebo.pdf\n")
  }
}

## ---------------------------------------------------------------------------
## Figure 5: Leave-One-Court-Out Stability
## ---------------------------------------------------------------------------

cat("Figure 5: Leave-one-court-out...\n")

loco_file <- file.path(data_dir, "loco_results.csv")
if (file.exists(loco_file)) {
  loco <- fread(loco_file)

  if (nrow(loco) > 0) {
    loco[, excluded_court := reorder(excluded_court, coef_iv)]

    # Get full-sample estimate
    full_iv <- fread(file.path(data_dir, "iv_results.csv"))
    full_coef <- full_iv[outcome_var == "log_total"]$coef_iv
    if (length(full_coef) == 0) full_coef <- mean(loco$coef_iv)

    p5 <- ggplot(loco, aes(x = excluded_court, y = coef_iv)) +
      geom_hline(yintercept = full_coef, linetype = "solid", color = "steelblue",
                 linewidth = 1) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
      geom_point(size = 2, color = "grey30") +
      geom_errorbar(aes(ymin = coef_iv - 1.96 * se_iv,
                         ymax = coef_iv + 1.96 * se_iv),
                    width = 0.3, color = "grey50") +
      labs(
        title = "Leave-One-Court-Out Stability",
        subtitle = "IV estimate for log total employment, dropping each court",
        x = "Dropped Court",
        y = "IV Coefficient"
      ) +
      theme_apep() +
      theme(axis.text.x = element_text(angle = 90, hjust = 1, size = 6))

    ggsave(file.path(fig_dir, "fig5_loco.pdf"), p5, width = 10, height = 6)
    cat("  Saved fig5_loco.pdf\n")
  }
}

## ---------------------------------------------------------------------------
## Figure 6: Alternative FE Specifications
## ---------------------------------------------------------------------------

cat("Figure 6: Alternative FE robustness...\n")

fe_file <- file.path(data_dir, "alt_fe_results.csv")
if (file.exists(fe_file)) {
  fe_dt <- fread(fe_file)

  if (nrow(fe_dt) > 0) {
    fe_dt[, specification := factor(specification, levels = rev(specification))]

    p6 <- ggplot(fe_dt, aes(x = coef_iv, y = specification)) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
      geom_point(size = 3, color = "steelblue") +
      geom_errorbarh(aes(xmin = coef_iv - 1.96 * se_iv,
                          xmax = coef_iv + 1.96 * se_iv),
                      height = 0.2, color = "steelblue") +
      labs(
        title = "Robustness: Alternative Fixed Effects Specifications",
        subtitle = "IV estimate for log total employment",
        x = "IV Coefficient",
        y = ""
      ) +
      theme_apep()

    ggsave(file.path(fig_dir, "fig6_alt_fe.pdf"), p6, width = 7, height = 5)
    cat("  Saved fig6_alt_fe.pdf\n")
  }
}

## ---------------------------------------------------------------------------
## Figure 7: Leniency Distribution Across Courts
## ---------------------------------------------------------------------------

cat("Figure 7: Leniency distribution...\n")

p7 <- ggplot(court_cross, aes(x = avg_judge_leniency)) +
  geom_histogram(bins = 20, fill = "steelblue", alpha = 0.7, color = "white") +
  geom_vline(xintercept = mean(court_cross$avg_judge_leniency),
             linetype = "dashed", color = "firebrick", linewidth = 1) +
  labs(
    title = "Distribution of Court-Level Judge Leniency",
    subtitle = "Caseload-weighted average grant rate of judges at each court",
    x = "Court-Level Judge Leniency",
    y = "Number of Courts"
  ) +
  scale_x_continuous(labels = percent_format()) +
  theme_apep()

ggsave(file.path(fig_dir, "fig7_leniency_distribution.pdf"), p7, width = 7, height = 5)
cat("  Saved fig7_leniency_distribution.pdf\n")

cat("\n=== ALL FIGURES GENERATED ===\n")
