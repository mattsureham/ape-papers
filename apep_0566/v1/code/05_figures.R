# ============================================================================
# 05_figures.R — Generate all figures from saved data
# APEP Paper apep_0566
# ============================================================================

source("00_packages.R")

data_dir <- "../data/"
fig_dir  <- "../figures/"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(paste0(data_dir, "analysis_panel.csv"))
panel_states <- panel[is_state == TRUE]

# ============================================================================
# Figure 1: Treatment Rollout
# ============================================================================

cat("Figure 1: Treatment rollout...\n")

reform_dates <- fread(paste0(data_dir, "reform_dates.csv"))
# Only include states in the estimation sample (excludes D.C.)
reform_dates <- merge(reform_dates,
                      unique(panel_states[, .(state_abbr, state_fips)]),
                      by = "state_abbr")

rollout_df <- reform_dates[order(reform_year, state_abbr)]
rollout_df[, state_label := factor(state_abbr, levels = rev(state_abbr))]
rollout_df[, intensity_label := factor(reform_intensity,
                                        levels = c(1, 2, 3),
                                        labels = c("Burden Raised", "Conviction Required", "Abolished"))]

p1 <- ggplot(rollout_df, aes(x = reform_year, y = state_label, color = intensity_label)) +
  geom_point(size = 3) +
  scale_color_manual(values = c("Burden Raised" = "#4292c6",
                                "Conviction Required" = "#ef6548",
                                "Abolished" = "#252525"),
                     name = "Reform Type") +
  scale_x_continuous(breaks = 2014:2021) +
  labs(x = "Year of Reform", y = "",
       title = "Staggered Adoption of Civil Asset Forfeiture Reform",
       subtitle = "26 states in estimation sample (D.C. excluded), reforms enacted 2014--2021") +
  theme(axis.text.y = element_text(size = 7))

ggsave(paste0(fig_dir, "fig1_rollout.pdf"), p1, width = 8, height = 9)

# ============================================================================
# Figure 2: Raw Trends by Treatment Status
# ============================================================================

cat("Figure 2: Raw outcome trends...\n")

trends <- panel_states[, .(
  mean_rate = mean(drug_od_rate, na.rm = TRUE),
  se_rate = sd(drug_od_rate, na.rm = TRUE) / sqrt(.N)
), by = .(year, treated_ever)]

trends[, group := ifelse(treated_ever, "Reformed States", "Never-Reformed States")]

p2 <- ggplot(trends, aes(x = year, y = mean_rate, color = group, linetype = group)) +
  geom_line(linewidth = 1) +
  geom_ribbon(aes(ymin = mean_rate - 1.96 * se_rate,
                  ymax = mean_rate + 1.96 * se_rate, fill = group),
              alpha = 0.15, color = NA) +
  geom_vline(xintercept = 2014, linetype = "dashed", color = "gray50") +
  annotate("text", x = 2014.3, y = max(trends$mean_rate) * 0.95,
           label = "First reform\n(2014)", size = 3, hjust = 0) +
  scale_color_manual(values = c("Reformed States" = "#d94801",
                                "Never-Reformed States" = "#2171b5")) +
  scale_fill_manual(values = c("Reformed States" = "#d94801",
                               "Never-Reformed States" = "#2171b5")) +
  labs(x = "Year", y = "Drug Overdose Death Rate (per 100K)",
       title = "Drug Overdose Mortality Trends",
       subtitle = "Age-adjusted rates, reformed vs. never-reformed states",
       color = "", fill = "", linetype = "") +
  scale_x_continuous(breaks = seq(2000, 2022, 2))

fwrite(trends, paste0(data_dir, "fig2_trends.csv"))
ggsave(paste0(fig_dir, "fig2_trends.pdf"), p2, width = 8, height = 5)

# ============================================================================
# Figure 3: CS-DiD Event Study
# ============================================================================

cat("Figure 3: Event study...\n")

es_df <- fread(paste0(data_dir, "cs_event_study.csv"))

p3 <- ggplot(es_df, aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, color = "gray70") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "gray50") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), fill = "#4292c6", alpha = 0.2) +
  geom_line(color = "#2171b5", linewidth = 0.8) +
  geom_point(color = "#2171b5", size = 2) +
  labs(x = "Years Relative to Reform",
       y = "ATT (Drug Overdose Death Rate per 100K)",
       title = "Event Study: Effect of Forfeiture Reform on Drug Overdose Mortality",
       subtitle = "Callaway-Sant'Anna estimator, not-yet-treated controls") +
  scale_x_continuous(breaks = seq(-8, 6, 1)) +
  annotate("text", x = -4, y = max(es_df$ci_upper, na.rm = TRUE) * 0.9,
           label = "Pre-reform", size = 3, color = "gray40") +
  annotate("text", x = 3, y = max(es_df$ci_upper, na.rm = TRUE) * 0.9,
           label = "Post-reform", size = 3, color = "gray40")

ggsave(paste0(fig_dir, "fig3_event_study.pdf"), p3, width = 8, height = 5)

# ============================================================================
# Figure 4: Randomization Inference Distribution
# ============================================================================

cat("Figure 4: RI distribution...\n")

if (file.exists(paste0(data_dir, "ri_distribution.csv"))) {
  ri_dist <- fread(paste0(data_dir, "ri_distribution.csv"))
  ri_meta <- fread(paste0(data_dir, "ri_results.csv"))

  p4 <- ggplot(ri_dist, aes(x = perm_att)) +
    geom_histogram(bins = 40, fill = "#bdbdbd", color = "white") +
    geom_vline(xintercept = ri_meta$actual_att, color = "#d94801",
               linewidth = 1.2, linetype = "solid") +
    labs(x = "Permuted ATT", y = "Count",
         title = "Randomization Inference",
         subtitle = paste0("Actual ATT = ", round(ri_meta$actual_att, 3),
                          ", RI p-value = ", round(ri_meta$ri_p_value, 3),
                          " (", ri_meta$n_permutations, " permutations)"))

  ggsave(paste0(fig_dir, "fig4_ri.pdf"), p4, width = 7, height = 4.5)
}

# ============================================================================
# Figure 5: Leave-One-Out
# ============================================================================

cat("Figure 5: Leave-one-out...\n")

if (file.exists(paste0(data_dir, "leave_one_out.csv"))) {
  loo_df <- fread(paste0(data_dir, "leave_one_out.csv"))
  main_res <- fread(paste0(data_dir, "main_results.csv"))
  actual_att <- main_res[spec == "CS-DiD (levels)"]$estimate

  loo_df <- loo_df[order(att)]
  loo_df[, state_label := factor(state_abbr, levels = state_abbr)]

  p5 <- ggplot(loo_df, aes(x = state_label, y = att)) +
    geom_hline(yintercept = actual_att, color = "#d94801", linewidth = 0.8) +
    geom_hline(yintercept = 0, color = "gray70") +
    geom_errorbar(aes(ymin = att - 1.96 * se, ymax = att + 1.96 * se),
                  width = 0.3, color = "#4292c6") +
    geom_point(color = "#2171b5", size = 1.5) +
    labs(x = "Dropped State", y = "ATT",
         title = "Leave-One-Out Sensitivity",
         subtitle = "Orange line = full sample estimate") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, size = 6))

  ggsave(paste0(fig_dir, "fig5_loo.pdf"), p5, width = 10, height = 5)
}

# ============================================================================
# Figure 6: Dose-Response by Reform Intensity
# ============================================================================

cat("Figure 6: Dose-response...\n")

if (file.exists(paste0(data_dir, "dose_response.csv"))) {
  dose_df <- fread(paste0(data_dir, "dose_response.csv"))
  dose_df[, intensity_label := factor(intensity,
                                       levels = c("Burden Raised", "Conviction Required", "Abolished"))]

  p6 <- ggplot(dose_df, aes(x = intensity_label, y = estimate)) +
    geom_hline(yintercept = 0, color = "gray70") +
    geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.2, linewidth = 0.8) +
    geom_point(size = 4, color = "#2171b5") +
    labs(x = "Reform Intensity",
         y = "Effect on Drug Overdose Rate (per 100K)",
         title = "Dose-Response: Reform Intensity and Drug Overdose Mortality",
         subtitle = "TWFE estimates with state and year FE, clustered at state level")

  ggsave(paste0(fig_dir, "fig6_dose_response.pdf"), p6, width = 7, height = 5)
}

# ============================================================================
# Figure 7: Cohort-Specific ATTs
# ============================================================================

cat("Figure 7: Cohort ATTs...\n")

if (file.exists(paste0(data_dir, "cs_cohort_atts.csv"))) {
  cohort_df <- fread(paste0(data_dir, "cs_cohort_atts.csv"))

  p7 <- ggplot(cohort_df, aes(x = factor(cohort), y = att)) +
    geom_hline(yintercept = 0, color = "gray70") +
    geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.2) +
    geom_point(size = 3, color = "#2171b5") +
    labs(x = "Reform Cohort (Year)", y = "Cohort-Specific ATT",
         title = "Treatment Effects by Reform Cohort",
         subtitle = "Callaway-Sant'Anna group-specific ATTs")

  ggsave(paste0(fig_dir, "fig7_cohort_atts.pdf"), p7, width = 7, height = 5)
}

cat("\nAll figures generated.\n")
