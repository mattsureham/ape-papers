## 05_figures.R — Generate all figures
## apep_0501: Municipal Mergers and Direct Democracy in Switzerland

source("00_packages.R")

DATA_DIR <- "../data"
FIG_DIR <- "../figures"
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, vote_date := as.Date(vote_date)]
merger_timeline <- fread(file.path(DATA_DIR, "merger_timeline.csv"))
results <- readRDS(file.path(DATA_DIR, "main_results.rds"))

# =============================================================================
# FIGURE 1: MERGER TIMELINE
# =============================================================================

cat("Figure 1: Merger timeline\n")

merger_by_year <- merger_timeline[, .(n_mergers = .N), by = merger_year][order(merger_year)]

# Cumulative mergers
merger_by_year[, cumulative := cumsum(n_mergers)]

p1 <- ggplot(merger_by_year[merger_year >= 1960 & merger_year <= 2025],
             aes(x = merger_year, y = n_mergers)) +
  geom_col(fill = apep_colors["treated"], alpha = 0.8) +
  geom_line(aes(y = cumulative / 15), color = apep_colors["control"],
            linewidth = 0.8) +
  scale_y_continuous(
    name = "Mergers per Year",
    sec.axis = sec_axis(~.*15, name = "Cumulative Mergers")
  ) +
  labs(x = "Year",
       title = "Swiss Municipal Mergers, 1960--2025",
       subtitle = "Bars: annual merger count | Line: cumulative mergers") +
  theme(axis.title.y.right = element_text(color = apep_colors["control"]))

ggsave(file.path(FIG_DIR, "fig1_merger_timeline.pdf"), p1,
       width = 7, height = 4.5)

# =============================================================================
# FIGURE 2: TURNOUT TRENDS (TREATED vs CONTROL)
# =============================================================================

cat("Figure 2: Turnout trends\n")

turnout_trends <- panel[, .(
  mean_turnout = mean(turnout_final, na.rm = TRUE),
  se = sd(turnout_final, na.rm = TRUE) / sqrt(.N),
  n = .N
), by = .(vote_year, treated)]

p2 <- ggplot(turnout_trends[vote_year >= 1980],
             aes(x = vote_year, y = mean_turnout,
                 color = factor(treated, labels = c("Never merged", "Eventually merged")),
                 fill = factor(treated, labels = c("Never merged", "Eventually merged")))) +
  geom_ribbon(aes(ymin = mean_turnout - 1.96 * se,
                  ymax = mean_turnout + 1.96 * se),
              alpha = 0.15, color = NA) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 1, alpha = 0.5) +
  scale_color_manual(values = c(apep_colors["control"], apep_colors["treated"])) +
  scale_fill_manual(values = c(apep_colors["control"], apep_colors["treated"])) +
  labs(x = "Year", y = "Mean Turnout (%)",
       color = NULL, fill = NULL,
       title = "Federal Referendum Turnout by Merger Status",
       subtitle = "Commune-level means with 95% confidence bands") +
  theme(legend.position = c(0.75, 0.9))

ggsave(file.path(FIG_DIR, "fig2_turnout_trends.pdf"), p2,
       width = 7, height = 4.5)

# =============================================================================
# FIGURE 3: EVENT STUDY (TWFE)
# =============================================================================

cat("Figure 3: Event study\n")

es_twfe <- fread(file.path(DATA_DIR, "event_study_twfe.csv"))

# Add reference point (event_time = -1, estimate = 0)
ref_row <- data.table(term = "ref", estimate = 0, se = 0, tstat = 0,
                       pvalue = 1, event_time = -1)
es_plot <- rbind(es_twfe, ref_row, fill = TRUE)
es_plot[, ci_lower := estimate - 1.96 * se]
es_plot[, ci_upper := estimate + 1.96 * se]
es_plot <- es_plot[order(event_time)]

p3 <- ggplot(es_plot, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey70") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              fill = apep_colors["ci"], alpha = 0.5) +
  geom_point(color = apep_colors["treated"], size = 2) +
  geom_line(color = apep_colors["treated"], linewidth = 0.5) +
  labs(x = "Years Relative to Merger",
       y = "Effect on Turnout (pp)",
       title = "Event Study: Municipal Mergers and Referendum Turnout",
       subtitle = "TWFE estimates with 95% CI. Reference period: t = -1.") +
  annotate("text", x = -5, y = max(es_plot$ci_upper, na.rm = TRUE) * 0.9,
           label = "Pre-merger", fontface = "italic", color = "grey50") +
  annotate("text", x = 5, y = max(es_plot$ci_upper, na.rm = TRUE) * 0.9,
           label = "Post-merger", fontface = "italic", color = "grey50")

ggsave(file.path(FIG_DIR, "fig3_event_study.pdf"), p3,
       width = 7, height = 4.5)

# =============================================================================
# FIGURE 4: PLACEBO DISTRIBUTION
# =============================================================================

cat("Figure 4: Placebo distribution\n")

placebo_file <- file.path(DATA_DIR, "placebo_atts.rds")
if (file.exists(placebo_file)) {
  placebo_atts <- readRDS(placebo_file)
  real_att <- results$att_twfe

  p4 <- ggplot(data.frame(att = placebo_atts), aes(x = att)) +
    geom_histogram(bins = 30, fill = "grey70", color = "white") +
    geom_vline(xintercept = real_att, color = apep_colors["treated"],
               linewidth = 1, linetype = "solid") +
    labs(x = "Placebo ATT (pp)",
         y = "Frequency",
         title = "Randomization Inference: Actual vs. Placebo Effects",
         subtitle = sprintf("Red line: actual ATT = %.3f pp | RI p-value = %.3f",
                            real_att, results$ri_pval))

  ggsave(file.path(FIG_DIR, "fig4_placebo.pdf"), p4,
         width = 7, height = 4.5)
} else {
  cat("  Placebo data not available, skipping.\n")
}

# =============================================================================
# FIGURE 5: DOSE-RESPONSE (SIZE EFFECT)
# =============================================================================

cat("Figure 5: Dose-response\n")

# Compute log_size_ratio if not already present
if (!"log_size_ratio" %in% names(panel)) {
  panel[, eligible_num := as.numeric(eligible)]
  size_change <- panel[treated == TRUE, .(
    pre_eligible = mean(eligible_num[post == FALSE], na.rm = TRUE),
    post_eligible = mean(eligible_num[post == TRUE], na.rm = TRUE)
  ), by = commune_code]
  size_change[, log_size_ratio := log(post_eligible / pre_eligible)]
  size_change <- size_change[is.finite(log_size_ratio)]
  panel <- merge(panel, size_change[, .(commune_code, log_size_ratio)],
                 by = "commune_code", all.x = TRUE)
  panel[is.na(log_size_ratio), log_size_ratio := 0]
}

treated_only <- panel[treated == TRUE & post == TRUE & !is.na(log_size_ratio) & log_size_ratio != 0]
if (nrow(treated_only) > 0) {
  treated_only[, size_quartile := cut(log_size_ratio,
                                       breaks = quantile(log_size_ratio, c(0, 0.25, 0.5, 0.75, 1)),
                                       include.lowest = TRUE,
                                       labels = c("Q1 (small)", "Q2", "Q3", "Q4 (large)"))]

  dose_means <- treated_only[!is.na(size_quartile), .(
    mean_turnout_change = mean(turnout_final, na.rm = TRUE) -
      mean(panel[treated == FALSE & vote_year %in% treated_only$vote_year, turnout_final], na.rm = TRUE),
    n = .N
  ), by = size_quartile]

  if (nrow(dose_means) > 1) {
    p5 <- ggplot(dose_means, aes(x = size_quartile, y = mean_turnout_change)) +
      geom_col(fill = apep_colors["treated"], alpha = 0.8) +
      geom_hline(yintercept = 0, linetype = "dashed") +
      labs(x = "Size Increase Quartile",
           y = "Turnout Difference vs. Controls (pp)",
           title = "Dose-Response: Merger Size and Turnout Change",
           subtitle = "Larger mergers (Q4) should show stronger effects if scale channel dominates")

    ggsave(file.path(FIG_DIR, "fig5_dose_response.pdf"), p5,
           width = 6, height = 4.5)
  }
}

# =============================================================================
# FIGURE 6: STACKED DiD EVENT STUDY (COHORT-SPECIFIC)
# =============================================================================

cat("Figure 6: Pre-trend visualization\n")

# Show pre-trend patterns by treatment cohort
pre_trends <- panel[treated == TRUE & event_year >= -10 & event_year <= 10, .(
  mean_turnout = mean(turnout_final, na.rm = TRUE),
  se = sd(turnout_final, na.rm = TRUE) / sqrt(.N),
  n = .N
), by = event_year]

control_mean <- mean(panel[treated == FALSE, turnout_final], na.rm = TRUE)
pre_trends[, diff_from_control := mean_turnout - control_mean]

p6 <- ggplot(pre_trends, aes(x = event_year, y = mean_turnout)) +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey70") +
  geom_ribbon(aes(ymin = mean_turnout - 1.96 * se,
                  ymax = mean_turnout + 1.96 * se),
              fill = apep_colors["ci"], alpha = 0.4) +
  geom_line(color = apep_colors["treated"], linewidth = 0.7) +
  geom_point(color = apep_colors["treated"], size = 2) +
  labs(x = "Years Relative to Merger",
       y = "Mean Turnout (%)",
       title = "Turnout Trajectory of Eventually-Merged Communes",
       subtitle = "Raw means around merger date with 95% CI")

ggsave(file.path(FIG_DIR, "fig6_raw_trajectory.pdf"), p6,
       width = 7, height = 4.5)

cat("All figures generated.\n")
