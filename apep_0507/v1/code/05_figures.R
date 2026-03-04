# =============================================================================
# 05_figures.R — All figures
# Swiss Municipal Mergers and Democratic Participation
# =============================================================================

source("00_packages.R")

# =============================================================================
# Load data and results
# =============================================================================

panel <- fread(file.path(DATA_DIR, "panel_vote.csv"))
annual <- fread(file.path(DATA_DIR, "panel_annual.csv"))
panel[, vote_date := as.Date(vote_date)]
results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
es_coefs <- fread(file.path(DATA_DIR, "event_study_coefs.csv"))

# =============================================================================
# Figure 1: Event-study plot (Sun-Abraham)
# =============================================================================

cat("\n=== Figure 1: Event study ===\n")

es_plot_data <- es_coefs[rel_year >= -10 & rel_year <= 15]
es_plot_data[, ci_lo := estimate - 1.96 * se]
es_plot_data[, ci_hi := estimate + 1.96 * se]

fig1 <- ggplot(es_plot_data, aes(x = rel_year, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "red3", linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, fill = "steelblue") +
  geom_point(size = 2, color = "steelblue") +
  geom_line(color = "steelblue", linewidth = 0.5) +
  labs(
    x = "Years relative to merger",
    y = "Effect on voter turnout (pp)",
    title = "Effect of Municipal Mergers on Referendum Turnout",
    subtitle = "Sun-Abraham interaction-weighted estimator, municipality + canton×year FE"
  ) +
  scale_x_continuous(breaks = seq(-10, 15, by = 2)) +
  annotate("text", x = -5, y = max(es_plot_data$ci_hi) * 0.9,
           label = "Pre-merger", hjust = 0.5, size = 3.5, color = "gray40") +
  annotate("text", x = 7, y = max(es_plot_data$ci_hi) * 0.9,
           label = "Post-merger", hjust = 0.5, size = 3.5, color = "gray40")

ggsave(file.path(FIG_DIR, "fig1_event_study.pdf"), fig1,
       width = 8, height = 5, device = cairo_pdf)
cat("  Saved fig1_event_study.pdf\n")

# =============================================================================
# Figure 2: Callaway-Sant'Anna event study (if available)
# =============================================================================

cat("\n=== Figure 2: CS-DiD event study ===\n")

cs_es_file <- file.path(DATA_DIR, "cs_es.rds")
if (file.exists(cs_es_file)) {
  cs_es <- readRDS(cs_es_file)

  cs_es_dt <- data.table(
    rel_year = cs_es$egt,
    estimate = cs_es$att.egt,
    se = cs_es$se.egt
  )
  cs_es_dt[, ci_lo := estimate - 1.96 * se]
  cs_es_dt[, ci_hi := estimate + 1.96 * se]
  cs_es_dt <- cs_es_dt[rel_year >= -10 & rel_year <= 15]

  fig2 <- ggplot(cs_es_dt, aes(x = rel_year, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "red3", linewidth = 0.5) +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, fill = "darkred") +
    geom_point(size = 2, color = "darkred") +
    geom_line(color = "darkred", linewidth = 0.5) +
    labs(
      x = "Years relative to merger",
      y = "Effect on voter turnout (pp)",
      title = "Effect of Municipal Mergers on Referendum Turnout",
      subtitle = "Callaway and Sant'Anna (2021) estimator"
    ) +
    scale_x_continuous(breaks = seq(-10, 15, by = 2))

  ggsave(file.path(FIG_DIR, "fig2_cs_event_study.pdf"), fig2,
         width = 8, height = 5, device = cairo_pdf)
  cat("  Saved fig2_cs_event_study.pdf\n")
} else {
  cat("  CS-DiD results not available, skipping\n")
}

# =============================================================================
# Figure 3: Treatment cohort distribution
# =============================================================================

cat("\n=== Figure 3: Cohort distribution ===\n")

cohort_data <- annual[g > 0, .(n_units = uniqueN(current_bfs)), by = g]
setnames(cohort_data, "g", "merger_year")

fig3 <- ggplot(cohort_data, aes(x = merger_year, y = n_units)) +
  geom_col(fill = "steelblue", alpha = 0.8) +
  labs(
    x = "Year of merger",
    y = "Number of municipalities",
    title = "Distribution of Municipal Merger Cohorts",
    subtitle = "Number of treated municipalities by first merger year"
  ) +
  scale_x_continuous(breaks = seq(1990, 2024, by = 2)) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(FIG_DIR, "fig3_cohort_distribution.pdf"), fig3,
       width = 8, height = 5, device = cairo_pdf)
cat("  Saved fig3_cohort_distribution.pdf\n")

# =============================================================================
# Figure 4: Raw turnout trends (treated vs control)
# =============================================================================

cat("\n=== Figure 4: Raw turnout trends ===\n")

trends <- annual[vote_year >= 1995, .(
  mean_turnout = mean(turnout_pct, na.rm = TRUE),
  se_turnout = sd(turnout_pct, na.rm = TRUE) / sqrt(.N),
  n = .N
), by = .(vote_year, ever_merged)]

trends[, group := fifelse(ever_merged, "Eventually merged", "Never merged")]

fig4 <- ggplot(trends, aes(x = vote_year, y = mean_turnout, color = group)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_ribbon(aes(ymin = mean_turnout - 1.96 * se_turnout,
                  ymax = mean_turnout + 1.96 * se_turnout,
                  fill = group), alpha = 0.1, color = NA) +
  scale_color_manual(values = c("Eventually merged" = "red3",
                                 "Never merged" = "steelblue")) +
  scale_fill_manual(values = c("Eventually merged" = "red3",
                                "Never merged" = "steelblue")) +
  labs(
    x = "Year",
    y = "Mean turnout (%)",
    color = NULL, fill = NULL,
    title = "Referendum Turnout Trends",
    subtitle = "Eventually merged vs. never merged municipalities"
  ) +
  theme(legend.position = "bottom")

ggsave(file.path(FIG_DIR, "fig4_raw_trends.pdf"), fig4,
       width = 8, height = 5, device = cairo_pdf)
cat("  Saved fig4_raw_trends.pdf\n")

# =============================================================================
# Figure 5: Heterogeneity by merger size
# =============================================================================

cat("\n=== Figure 5: Heterogeneity by merger size ===\n")

merger_xwalk <- fread(file.path(DATA_DIR, "merger_crosswalk.csv"))
merger_size <- merger_xwalk[, .(n_dissolved = .N), by = successor_code]

# Merge with panel
het_data <- merge(annual[g > 0], merger_size,
                  by.x = "current_bfs", by.y = "successor_code", all.x = TRUE)
het_data[is.na(n_dissolved), n_dissolved := 1L]
het_data[, size_group := fifelse(n_dissolved <= 2, "Small (2 municipalities)",
                                  fifelse(n_dissolved <= 4, "Medium (3-4)",
                                          "Large (5+)"))]
het_data[, size_group := factor(size_group,
                                levels = c("Small (2 municipalities)", "Medium (3-4)", "Large (5+)"))]

# Run separate event studies by size group
het_results <- list()
for (sg in levels(het_data$size_group)) {
  sub_data <- het_data[size_group == sg]
  sub_data[, cohort := g]
  sub_data[, current_bfs_f := as.factor(current_bfs)]
  tryCatch({
    sub_model <- feols(turnout_pct ~ sunab(cohort, vote_year) | current_bfs_f + vote_year,
                       data = sub_data, cluster = ~current_bfs_f)
    sub_coefs <- as.data.table(summary(sub_model)$coeftable, keep.rownames = TRUE)
    setnames(sub_coefs, c("term", "estimate", "se", "tstat", "pvalue"))
    sub_coefs[, rel_year := as.integer(gsub(".*::(-?[0-9]+)$", "\\1", term))]
    sub_coefs <- sub_coefs[!is.na(rel_year)]
    sub_coefs[, size_group := sg]
    het_results[[sg]] <- sub_coefs
  }, error = function(e) {
    cat("  Skipping", sg, ":", e$message, "\n")
  })
}

if (length(het_results) > 0) {
  het_es <- rbindlist(het_results)
  het_es <- het_es[rel_year >= -8 & rel_year <= 12]
  het_es[, ci_lo := estimate - 1.96 * se]
  het_es[, ci_hi := estimate + 1.96 * se]

  fig5 <- ggplot(het_es, aes(x = rel_year, y = estimate, color = size_group)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "gray70") +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi, fill = size_group), alpha = 0.1, color = NA) +
    geom_line(linewidth = 0.5) +
    geom_point(size = 1.5) +
    labs(
      x = "Years relative to merger",
      y = "Effect on voter turnout (pp)",
      color = "Merger size", fill = "Merger size",
      title = "Heterogeneous Effects by Merger Size",
      subtitle = "Sun-Abraham estimates, municipality + year FE"
    ) +
    scale_x_continuous(breaks = seq(-8, 12, by = 2)) +
    theme(legend.position = "bottom")

  ggsave(file.path(FIG_DIR, "fig5_heterogeneity_size.pdf"), fig5,
         width = 8, height = 5, device = cairo_pdf)
  cat("  Saved fig5_heterogeneity_size.pdf\n")
}

# =============================================================================
# Figure 6: CS-DiD group-level ATTs by cohort
# =============================================================================

cat("\n=== Figure 6: Group-level ATTs ===\n")

cs_group_file <- file.path(DATA_DIR, "cs_group.rds")
if (file.exists(cs_group_file)) {
  cs_group <- readRDS(cs_group_file)

  group_dt <- data.table(
    cohort = cs_group$egt,
    att = cs_group$att.egt,
    se = cs_group$se.egt
  )
  group_dt[, ci_lo := att - 1.96 * se]
  group_dt[, ci_hi := att + 1.96 * se]

  fig6 <- ggplot(group_dt, aes(x = cohort, y = att)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi), color = "steelblue", size = 0.5) +
    labs(
      x = "Merger cohort (year)",
      y = "Average treatment effect (pp)",
      title = "Treatment Effects by Merger Cohort",
      subtitle = "Callaway and Sant'Anna group-specific ATTs"
    ) +
    scale_x_continuous(breaks = seq(1990, 2024, by = 2)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  ggsave(file.path(FIG_DIR, "fig6_group_atts.pdf"), fig6,
         width = 8, height = 5, device = cairo_pdf)
  cat("  Saved fig6_group_atts.pdf\n")
}

cat("\nAll figures generated.\n")
