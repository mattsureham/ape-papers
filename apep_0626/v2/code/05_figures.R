## ============================================================================
## 05_figures.R — V2 Figures for apep_0626
## "Closing the Golden Door" — The Restrictionist Mirage
## ============================================================================

source("code/00_packages.R")

data_dir <- "data"
fig_dir <- "figures"
dir.create(fig_dir, showWarnings = FALSE)

dt <- readRDS(file.path(data_dir, "clean_1920_1930.rds"))

## APEP figure theme
theme_apep <- function() {
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      axis.line = element_line(color = "gray30", linewidth = 0.3),
      axis.ticks = element_line(color = "gray30", linewidth = 0.3),
      plot.title = element_text(face = "bold", size = 12),
      plot.subtitle = element_text(size = 10, color = "gray40"),
      legend.position = "bottom",
      strip.text = element_text(face = "bold")
    )
}

## --------------------------------------------------------------------------
## Figure 1: Distribution of Quota Exposure
## --------------------------------------------------------------------------

cat("=== Figure 1: Exposure Distribution ===\n")

county_dt <- dt[, .(quota_exposure = mean(quota_exposure),
                     n = .N), by = .(statefip_1920, countyicp_1920)]

p1 <- ggplot(county_dt, aes(x = quota_exposure)) +
  geom_histogram(aes(weight = n), bins = 50, fill = "#2166ac", alpha = 0.8,
                 color = "white", linewidth = 0.2) +
  geom_vline(xintercept = median(county_dt$quota_exposure),
             linetype = "dashed", color = "gray40") +
  labs(
    title = "Distribution of County-Level Quota Exposure",
    subtitle = "Share of 1920 population from restricted-origin countries",
    x = "Quota Exposure (Share)",
    y = "Number of Individuals"
  ) +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_y_continuous(labels = scales::comma) +
  theme_apep()

ggsave(file.path(fig_dir, "fig1_exposure_dist.pdf"), p1,
       width = 6.5, height = 4, device = cairo_pdf)
cat("  Saved fig1_exposure_dist.pdf\n")

## --------------------------------------------------------------------------
## Figure 2: Multi-Wave Event Study — Occupational Change by Exposure
## --------------------------------------------------------------------------

cat("=== Figure 2: Multi-Wave Event Study ===\n")

## Main period (1920-1930)
main_models <- readRDS(file.path(data_dir, "main_models.rds"))
main_coef <- coef(main_models$m4)["quota_exposure"]
main_se <- se(main_models$m4)["quota_exposure"]

## Placebo period (1910-1920)
if (file.exists(file.path(data_dir, "placebo_models.rds"))) {
  placebo_models <- readRDS(file.path(data_dir, "placebo_models.rds"))
  placebo_coef <- coef(placebo_models$m_placebo_full)["quota_exposure"]
  placebo_se <- se(placebo_models$m_placebo_full)["quota_exposure"]
} else {
  placebo_coef <- NA
  placebo_se <- NA
}

event_dt <- data.table(
  period = c("1910-1920\n(Pre-Restriction)", "1920-1930\n(Post-Restriction)"),
  coef = c(placebo_coef, main_coef),
  se = c(placebo_se, main_se),
  x = c(1, 2)
)
event_dt[, ci_lo := coef - 1.96 * se]
event_dt[, ci_hi := coef + 1.96 * se]

p2 <- ggplot(event_dt, aes(x = x, y = coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray60") +
  geom_vline(xintercept = 1.5, linetype = "dotted", color = "#b2182b",
             linewidth = 0.8, alpha = 0.5) +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi), size = 0.8,
                  color = "#2166ac", fatten = 3) +
  annotate("text", x = 1.5, y = max(event_dt$ci_hi, na.rm = TRUE) * 1.1,
           label = "1924 Act", color = "#b2182b", size = 3, fontface = "italic") +
  scale_x_continuous(breaks = 1:2, labels = event_dt$period) +
  labs(
    title = "Occupational Mobility Before and After Restriction",
    subtitle = expression(paste("Coefficient on quota exposure (", beta, " from full specification)")),
    x = NULL,
    y = expression(paste("Effect on ", Delta, " OCCSCORE"))
  ) +
  theme_apep() +
  theme(panel.grid.major.x = element_blank())

ggsave(file.path(fig_dir, "fig2_event_study.pdf"), p2,
       width = 5, height = 4.5, device = cairo_pdf)
cat("  Saved fig2_event_study.pdf\n")

## --------------------------------------------------------------------------
## Figure 3: OCCSCORE Change Distribution by Exposure Quartile
## --------------------------------------------------------------------------

cat("=== Figure 3: OCCSCORE Distribution by Exposure ===\n")

## Cap at -30 to 30 for readability
dt_plot <- dt[delta_occscore >= -30 & delta_occscore <= 30]

p3 <- ggplot(dt_plot, aes(x = delta_occscore, fill = exp_quartile)) +
  geom_density(alpha = 0.3, color = NA) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray40") +
  labs(
    title = "Distribution of Occupational Score Changes",
    subtitle = "By county quota exposure quartile, 1920-1930",
    x = expression(paste(Delta, " OCCSCORE (1920 to 1930)")),
    y = "Density",
    fill = "Exposure"
  ) +
  scale_fill_brewer(palette = "RdYlBu", direction = -1) +
  theme_apep()

ggsave(file.path(fig_dir, "fig3_occscore_density.pdf"), p3,
       width = 7, height = 4.5, device = cairo_pdf)
cat("  Saved fig3_occscore_density.pdf\n")

## --------------------------------------------------------------------------
## Figure 4: Homeownership Transition by Exposure Quintile
## --------------------------------------------------------------------------

cat("=== Figure 4: Homeownership by Exposure ===\n")

owner_by_q <- dt[, .(
  became_owner_rate = mean(became_owner, na.rm = TRUE),
  lost_home_rate = mean(lost_home, na.rm = TRUE),
  net_owner_rate = mean(net_owner, na.rm = TRUE),
  n = .N,
  mean_exposure = mean(quota_exposure)
), by = exp_quintile]

## Compute SEs
owner_by_q[, se_became := sqrt(became_owner_rate * (1 - became_owner_rate) / n)]
owner_by_q[, se_lost := sqrt(lost_home_rate * (1 - lost_home_rate) / n)]

p4a <- ggplot(owner_by_q, aes(x = exp_quintile, y = became_owner_rate)) +
  geom_col(fill = "#2166ac", alpha = 0.8) +
  geom_errorbar(aes(ymin = became_owner_rate - 1.96 * se_became,
                     ymax = became_owner_rate + 1.96 * se_became),
                width = 0.2, color = "gray30") +
  labs(
    title = "Homeownership Transitions Decline with Exposure",
    subtitle = "Share of renters who became homeowners, 1920-1930",
    x = "Quota Exposure Quintile",
    y = "Became Homeowner (Rate)"
  ) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
  theme_apep()

ggsave(file.path(fig_dir, "fig4_homeownership.pdf"), p4a,
       width = 6, height = 4.5, device = cairo_pdf)
cat("  Saved fig4_homeownership.pdf\n")

## --------------------------------------------------------------------------
## Figure 5: First Stage — Change in Foreign-Born Share
## --------------------------------------------------------------------------

cat("=== Figure 5: First Stage ===\n")

if (file.exists(file.path(data_dir, "first_stage_models.rds"))) {
  fs_data <- readRDS(file.path(data_dir, "first_stage_models.rds"))
  fs_county <- fs_data$county_dt

  ## Bin scatterplot: delta_restricted_share vs quota_exposure
  ## Residualize on state FE for cleaner visualization
  fs_county[, exp_bin := cut(quota_exposure,
    breaks = quantile(quota_exposure, probs = seq(0, 1, 0.05)),
    include.lowest = TRUE)]

  fs_binned <- fs_county[!is.na(exp_bin), .(
    mean_exposure = weighted.mean(quota_exposure, n_individuals),
    mean_delta_restricted = weighted.mean(delta_restricted_share, n_individuals, na.rm = TRUE),
    n = sum(n_individuals)
  ), by = exp_bin]

  p5 <- ggplot(fs_binned, aes(x = mean_exposure, y = mean_delta_restricted)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray60") +
    geom_point(aes(size = n), color = "#2166ac", alpha = 0.7) +
    geom_smooth(method = "lm", se = TRUE, color = "#b2182b",
                linewidth = 0.8, fill = "#b2182b", alpha = 0.15) +
    labs(
      title = "First Stage: Restriction Reduced Immigrant Presence",
      subtitle = "Change in restricted-origin share (1920 to 1930) by initial exposure",
      x = "1920 Quota Exposure (County Share)",
      y = expression(paste(Delta, " Restricted-Origin Share (1920-1930)"))
    ) +
    scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
    scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
    scale_size_continuous(guide = "none") +
    theme_apep()

  ggsave(file.path(fig_dir, "fig5_first_stage.pdf"), p5,
         width = 6.5, height = 4.5, device = cairo_pdf)
  cat("  Saved fig5_first_stage.pdf\n")
} else {
  cat("  SKIPPED: No first-stage data\n")
}

## --------------------------------------------------------------------------
## Figure 6: Occupational Transition Matrix (Heatmap)
## --------------------------------------------------------------------------

cat("=== Figure 6: Transition Matrix ===\n")

## Compute transition probabilities for high vs low exposure
occ_cats_ordered <- c("Laborers (Non-Farm)", "Farm Workers", "Service Workers",
                       "Craftsmen/Operatives", "Clerical/Sales",
                       "Managers/Officials", "Professional/Technical")

dt_trans <- dt[occ_cat_1920 %in% occ_cats_ordered & occ_cat_1930 %in% occ_cats_ordered]
dt_trans[, high_exp := quota_exposure > median(quota_exposure)]

## Transition probabilities
trans <- dt_trans[, .N, by = .(occ_cat_1920, occ_cat_1930, high_exp)]
trans[, total := sum(N), by = .(occ_cat_1920, high_exp)]
trans[, prob := N / total]

## Difference in transition probabilities (high - low exposure)
trans_wide <- dcast(trans, occ_cat_1920 + occ_cat_1930 ~ high_exp,
                    value.var = "prob", fill = 0)
setnames(trans_wide, c("FALSE", "TRUE"), c("low_exp", "high_exp"))
trans_wide[, diff := high_exp - low_exp]

## Order factors
trans_wide[, occ_cat_1920 := factor(occ_cat_1920, levels = occ_cats_ordered)]
trans_wide[, occ_cat_1930 := factor(occ_cat_1930, levels = rev(occ_cats_ordered))]

p6 <- ggplot(trans_wide, aes(x = occ_cat_1920, y = occ_cat_1930, fill = diff)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = sprintf("%.1f", diff * 100)), size = 2.5) +
  scale_fill_gradient2(low = "#b2182b", mid = "white", high = "#2166ac",
                        midpoint = 0, limits = c(-0.03, 0.03),
                        labels = scales::percent_format(accuracy = 0.1)) +
  labs(
    title = "Occupational Transitions: High vs. Low Exposure Counties",
    subtitle = "Difference in transition probability (pp), 1920-1930",
    x = "Occupation in 1920",
    y = "Occupation in 1930",
    fill = "Diff (pp)"
  ) +
  theme_apep() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
        axis.text.y = element_text(size = 8))

ggsave(file.path(fig_dir, "fig6_transition_matrix.pdf"), p6,
       width = 8, height = 6, device = cairo_pdf)
cat("  Saved fig6_transition_matrix.pdf\n")

## --------------------------------------------------------------------------
## Figure 7: Leave-One-Origin-Out Robustness (Coefficient Plot)
## --------------------------------------------------------------------------

cat("=== Figure 7: Leave-One-Origin-Out ===\n")

loo <- readRDS(file.path(data_dir, "loo_results.rds"))
loo[, ci_lo := coef - 1.96 * se]
loo[, ci_hi := coef + 1.96 * se]
loo[, origin := tools::toTitleCase(dropped_origin)]

## Add baseline
baseline <- data.table(
  origin = "Baseline (All 6)",
  coef = coef(main_models$m4)["quota_exposure"],
  se = se(main_models$m4)["quota_exposure"]
)
baseline[, ci_lo := coef - 1.96 * se]
baseline[, ci_hi := coef + 1.96 * se]
baseline[, dropped_origin := "baseline"]
baseline[, n := nrow(dt)]

loo_plot <- rbind(loo, baseline, fill = TRUE)
loo_plot[, origin := factor(origin, levels = c("Baseline (All 6)",
  "Austria", "Czech", "Hungary", "Italy", "Poland", "Russia"))]

p7 <- ggplot(loo_plot, aes(x = origin, y = coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray60") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  color = ifelse(loo_plot$origin == "Baseline (All 6)", "#b2182b", "#2166ac"),
                  size = 0.6, fatten = 3) +
  labs(
    title = "Leave-One-Origin-Out Robustness",
    subtitle = "Coefficient on quota exposure when each origin is excluded",
    x = "Dropped Origin",
    y = expression(paste("Coefficient on ", Delta, " OCCSCORE"))
  ) +
  coord_flip() +
  theme_apep()

ggsave(file.path(fig_dir, "fig7_loo_robustness.pdf"), p7,
       width = 6, height = 4, device = cairo_pdf)
cat("  Saved fig7_loo_robustness.pdf\n")

## --------------------------------------------------------------------------
## Figure 8: Pre-Period Complementarity
## --------------------------------------------------------------------------

cat("=== Figure 8: Pre-Period Complementarity ===\n")

if (file.exists(file.path(data_dir, "clean_placebo.rds"))) {
  dt_p <- readRDS(file.path(data_dir, "clean_placebo.rds"))

  ## Binned scatter: delta_occscore (1910-1920) vs quota exposure (1920)
  dt_p[, exp_bin := cut(quota_exposure,
    breaks = quantile(quota_exposure, probs = seq(0, 1, 0.05), na.rm = TRUE),
    include.lowest = TRUE)]

  placebo_binned <- dt_p[!is.na(exp_bin), .(
    mean_exposure = mean(quota_exposure),
    mean_delta = mean(delta_occscore),
    se_delta = sd(delta_occscore) / sqrt(.N),
    n = .N
  ), by = exp_bin]

  p8 <- ggplot(placebo_binned, aes(x = mean_exposure, y = mean_delta)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray60") +
    geom_point(aes(size = n), color = "#4daf4a", alpha = 0.7) +
    geom_smooth(method = "lm", se = TRUE, color = "#4daf4a",
                linewidth = 0.8, fill = "#4daf4a", alpha = 0.15) +
    labs(
      title = "Pre-Restriction Complementarity: 1910-1920",
      subtitle = "Counties with more immigrants saw more native occupational upgrading",
      x = "1920 Quota Exposure (County Share)",
      y = expression(paste(Delta, " OCCSCORE (1910-1920)"))
    ) +
    scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
    scale_size_continuous(guide = "none") +
    theme_apep()

  ggsave(file.path(fig_dir, "fig8_complementarity.pdf"), p8,
         width = 6.5, height = 4.5, device = cairo_pdf)
  cat("  Saved fig8_complementarity.pdf\n")

  rm(dt_p); gc()
}

cat("\n=== All figures generated ===\n")
cat("Files in figures/:\n")
for (f in list.files(fig_dir, pattern = "\\.pdf$")) {
  cat(sprintf("  %s\n", f))
}
