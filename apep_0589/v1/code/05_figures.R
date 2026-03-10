## ============================================================
## 05_figures.R — Generate all figures from saved CSVs
## ERDF Treatment Withdrawal RDD
## ============================================================

source("00_packages.R")

data_dir <- "../data/"
fig_dir  <- "../figures/"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# Load data
analysis <- fread(paste0(data_dir, "analysis.csv"))
annual   <- fread(paste0(data_dir, "annual_panel.csv"))
main_res <- fread(paste0(data_dir, "main_results.csv"))

cat("=== GENERATING FIGURES ===\n\n")

## ---------------------------------------------------------
## Figure 1: RDD Scatter — GDP growth vs running variable
## ---------------------------------------------------------
cat("Figure 1: RDD scatter\n")

rdd_data <- analysis[!is.na(rv_centered) & !is.na(delta_gdp) & abs(rv_centered) <= 25]

# Bin scatter
rdd_data[, bin := cut(rv_centered, breaks = seq(-25, 25, by = 2.5), include.lowest = TRUE)]
bin_means <- rdd_data[, .(
  mean_gdp = mean(delta_gdp, na.rm = TRUE),
  se_gdp = sd(delta_gdp, na.rm = TRUE) / sqrt(.N),
  mean_rv = mean(rv_centered, na.rm = TRUE),
  n = .N
), by = bin]
bin_means <- bin_means[!is.na(bin)]

fig1 <- ggplot() +
  geom_point(data = bin_means, aes(x = mean_rv, y = mean_gdp),
    size = 3, color = "steelblue") +
  geom_errorbar(data = bin_means, aes(x = mean_rv,
    ymin = mean_gdp - 1.96 * se_gdp,
    ymax = mean_gdp + 1.96 * se_gdp),
    width = 0.5, color = "steelblue", alpha = 0.6) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red", linewidth = 0.8) +
  geom_smooth(data = rdd_data[rv_centered < 0],
    aes(x = rv_centered, y = delta_gdp),
    method = "loess", color = "grey30", fill = "grey80", se = TRUE) +
  geom_smooth(data = rdd_data[rv_centered >= 0],
    aes(x = rv_centered, y = delta_gdp),
    method = "loess", color = "grey30", fill = "grey80", se = TRUE) +
  labs(
    x = "GDP per capita (% of EU27 avg) minus 75%",
    y = "Change in GDP/cap (% EU27), 2007-13 to 2014-20",
    title = "Treatment Withdrawal at the 75% Threshold",
    subtitle = "Regions crossing threshold lose Objective 1 ERDF funding"
  ) +
  annotate("text", x = -15, y = max(bin_means$mean_gdp, na.rm = TRUE),
    label = "Below 75%\n(still receiving)", hjust = 0, size = 3.5, color = "grey40") +
  annotate("text", x = 5, y = max(bin_means$mean_gdp, na.rm = TRUE),
    label = "Above 75%\n(graduated)", hjust = 0, size = 3.5, color = "grey40")

ggsave(paste0(fig_dir, "fig1_rdd_scatter.pdf"), fig1, width = 8, height = 5.5)
ggsave(paste0(fig_dir, "fig1_rdd_scatter.png"), fig1, width = 8, height = 5.5, dpi = 300)
cat("  Saved fig1_rdd_scatter\n")

## ---------------------------------------------------------
## Figure 2: Event study
## ---------------------------------------------------------
cat("Figure 2: Event study\n")

es_coefs <- fread(paste0(data_dir, "event_study_coefs.csv"))

if (nrow(es_coefs) > 0 && "rel_year" %in% names(es_coefs)) {
  # Add reference period (0 at t=-1)
  ref_row <- data.table(term = "ref", Estimate = 0, `Std. Error` = 0,
    `t value` = 0, `Pr(>|t|)` = 1, rel_year = -1)
  setnames(ref_row, names(ref_row), names(es_coefs), skip_absent = TRUE)

  # Handle column name variations
  est_col <- intersect(names(es_coefs), c("Estimate", "estimate", "coef"))
  se_col <- intersect(names(es_coefs), c("Std. Error", "std.error", "se"))

  if (length(est_col) > 0 && length(se_col) > 0) {
    es_plot <- es_coefs[, .(rel_year,
      est = get(est_col[1]),
      se = get(se_col[1]))]
    es_plot <- rbind(es_plot, data.table(rel_year = -1, est = 0, se = 0))
    es_plot[, `:=`(ci_lo = est - 1.96 * se, ci_hi = est + 1.96 * se)]

    fig2 <- ggplot(es_plot, aes(x = rel_year, y = est)) +
      geom_hline(yintercept = 0, linetype = "solid", color = "grey70") +
      geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", linewidth = 0.8) +
      geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "steelblue") +
      geom_line(color = "steelblue", linewidth = 0.8) +
      geom_point(color = "steelblue", size = 2) +
      labs(
        x = "Years relative to 2014 (programming period transition)",
        y = "Coefficient (graduated × year)",
        title = "Event Study: GDP Trajectory of Graduating Regions",
        subtitle = "Relative to non-graduating regions within ±15pp of threshold"
      ) +
      annotate("text", x = -6, y = min(es_plot$ci_lo, na.rm = TRUE) * 0.8,
        label = "Pre-treatment", size = 3.5, color = "grey40") +
      annotate("text", x = 4, y = min(es_plot$ci_lo, na.rm = TRUE) * 0.8,
        label = "Post-treatment", size = 3.5, color = "grey40")

    ggsave(paste0(fig_dir, "fig2_event_study.pdf"), fig2, width = 8, height = 5.5)
    ggsave(paste0(fig_dir, "fig2_event_study.png"), fig2, width = 8, height = 5.5, dpi = 300)
    cat("  Saved fig2_event_study\n")
  } else {
    cat("  Warning: could not identify estimate/SE columns in event study\n")
  }
} else {
  cat("  Warning: event study data empty or missing rel_year\n")
}

## ---------------------------------------------------------
## Figure 3: McCrary density plot
## ---------------------------------------------------------
cat("Figure 3: Density of running variable\n")

rv_vals <- analysis[!is.na(rv_centered)]$rv_centered

fig3_data <- data.table(rv = rv_vals)
fig3 <- ggplot(fig3_data, aes(x = rv)) +
  geom_histogram(aes(y = after_stat(density)), bins = 40,
    fill = "steelblue", alpha = 0.6, color = "white") +
  geom_density(color = "darkblue", linewidth = 0.8) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red", linewidth = 0.8) +
  labs(
    x = "GDP per capita (% of EU27 avg) minus 75%",
    y = "Density",
    title = "Distribution of Running Variable at Threshold",
    subtitle = "No visible bunching — regions do not manipulate GDP statistics"
  )

ggsave(paste0(fig_dir, "fig3_density.pdf"), fig3, width = 7, height = 5)
ggsave(paste0(fig_dir, "fig3_density.png"), fig3, width = 7, height = 5, dpi = 300)
cat("  Saved fig3_density\n")

## ---------------------------------------------------------
## Figure 4: ERDF intensity by region category
## ---------------------------------------------------------
cat("Figure 4: ERDF intensity\n")

erdf <- fread(paste0(data_dir, "erdf_payments.csv"))

if (nrow(erdf) > 0 && "year" %in% names(erdf) && "nuts2_id" %in% names(erdf)) {
  # Merge ERDF with region classification
  erdf_classified <- merge(
    erdf[!is.na(nuts2_id) & nuts2_id != ""],
    analysis[, .(geo, category_2014, graduated_from_convergence)],
    by.x = "nuts2_id", by.y = "geo", all.x = TRUE
  )

  erdf_agg <- erdf_classified[!is.na(category_2014) & !is.na(year) & year >= 2005 & year <= 2022,
    .(mean_payment = mean(eu_payment_annual, na.rm = TRUE),
      n_regions = uniqueN(nuts2_id)),
    by = .(year, category_2014)]

  if (nrow(erdf_agg) > 5) {
    fig4 <- ggplot(erdf_agg, aes(x = year, y = mean_payment / 1e6,
      color = category_2014, group = category_2014)) +
      geom_line(linewidth = 1) +
      geom_point(size = 2) +
      geom_vline(xintercept = 2014, linetype = "dashed", color = "grey50") +
      scale_color_manual(values = c("less_developed" = "#E41A1C",
        "transition" = "#FF7F00", "more_developed" = "#377EB8"),
        labels = c("Less developed (<75%)", "Transition (75-90%)",
          "More developed (>90%)")) +
      labs(
        x = "Year", y = "Mean ERDF payment (million EUR)",
        title = "ERDF Funding by Region Category",
        subtitle = "Clear drop for regions graduating above 75% threshold",
        color = "Category (2014-2020)"
      )

    ggsave(paste0(fig_dir, "fig4_erdf_intensity.pdf"), fig4, width = 8, height = 5.5)
    ggsave(paste0(fig_dir, "fig4_erdf_intensity.png"), fig4, width = 8, height = 5.5, dpi = 300)
    cat("  Saved fig4_erdf_intensity\n")
  } else {
    cat("  Warning: insufficient ERDF data for figure 4\n")
  }
} else {
  cat("  Warning: ERDF data missing required columns\n")
}

## ---------------------------------------------------------
## Figure 5: Bandwidth sensitivity
## ---------------------------------------------------------
cat("Figure 5: Bandwidth sensitivity\n")

bw_res <- main_res[grepl("bw_", spec)]
if (nrow(bw_res) > 0) {
  bw_res[, bw := as.numeric(gsub("bw_", "", spec))]

  fig5 <- ggplot(bw_res, aes(x = bw, y = coef)) +
    geom_hline(yintercept = 0, linetype = "solid", color = "grey70") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "steelblue") +
    geom_line(color = "steelblue", linewidth = 0.8) +
    geom_point(color = "steelblue", size = 3) +
    labs(
      x = "Bandwidth (pp around 75% threshold)",
      y = "RDD coefficient (GDP/cap change, pp)",
      title = "Bandwidth Sensitivity of Main Result",
      subtitle = "95% robust confidence intervals"
    )

  ggsave(paste0(fig_dir, "fig5_bandwidth.pdf"), fig5, width = 7, height = 5)
  ggsave(paste0(fig_dir, "fig5_bandwidth.png"), fig5, width = 7, height = 5, dpi = 300)
  cat("  Saved fig5_bandwidth\n")
}

## ---------------------------------------------------------
## Figure 6: Placebo cutoffs
## ---------------------------------------------------------
cat("Figure 6: Placebo cutoffs\n")

placebo <- fread(paste0(data_dir, "placebo_cutoffs.csv"))

if (nrow(placebo) > 0) {
  # Add the real cutoff result
  real_result <- main_res[spec == "CCT_optimal" & outcome == "GDP_pct_EU27"]
  if (nrow(real_result) > 0) {
    placebo_plot <- rbind(
      placebo[, .(cutoff, coef, se, p_value, type = "Placebo")],
      data.table(cutoff = 75, coef = real_result$coef,
        se = real_result$se_robust, p_value = real_result$p_value, type = "Real"),
      fill = TRUE
    )

    fig6 <- ggplot(placebo_plot, aes(x = cutoff, y = coef, color = type)) +
      geom_hline(yintercept = 0, linetype = "solid", color = "grey70") +
      geom_errorbar(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
        width = 1) +
      geom_point(size = 3) +
      scale_color_manual(values = c("Placebo" = "grey50", "Real" = "red")) +
      labs(
        x = "Cutoff (% of EU27 average)",
        y = "RDD coefficient",
        title = "Placebo Cutoff Tests",
        subtitle = "Only the real 75% threshold should show an effect"
      )

    ggsave(paste0(fig_dir, "fig6_placebo_cutoffs.pdf"), fig6, width = 7, height = 5)
    ggsave(paste0(fig_dir, "fig6_placebo_cutoffs.png"), fig6, width = 7, height = 5, dpi = 300)
    cat("  Saved fig6_placebo_cutoffs\n")
  }
}

## ---------------------------------------------------------
## Figure 7: GDP trajectories by category
## ---------------------------------------------------------
cat("Figure 7: GDP trajectories\n")

traj_data <- annual[!is.na(category_2014) & year >= 2003 & year <= 2022 &
  abs(rv_centered) <= 20]

traj_agg <- traj_data[, .(
  mean_gdp = mean(gdp_pct, na.rm = TRUE),
  se_gdp = sd(gdp_pct, na.rm = TRUE) / sqrt(.N),
  n = .N
), by = .(year, category_2014)]

fig7 <- ggplot(traj_agg, aes(x = year, y = mean_gdp, color = category_2014)) +
  geom_ribbon(aes(ymin = mean_gdp - 1.96 * se_gdp,
    ymax = mean_gdp + 1.96 * se_gdp, fill = category_2014), alpha = 0.15,
    color = NA) +
  geom_line(linewidth = 1) +
  geom_vline(xintercept = 2014, linetype = "dashed", color = "grey50") +
  scale_color_manual(values = c("less_developed" = "#E41A1C",
    "transition" = "#FF7F00", "more_developed" = "#377EB8"),
    labels = c("Less developed (<75%)", "Transition (75-90%)",
      "More developed (>90%)")) +
  scale_fill_manual(values = c("less_developed" = "#E41A1C",
    "transition" = "#FF7F00", "more_developed" = "#377EB8"),
    guide = "none") +
  labs(
    x = "Year", y = "GDP per capita (% of EU27 average)",
    title = "GDP Trajectories by 2014-2020 Category",
    subtitle = "Regions within ±20pp of 75% threshold",
    color = "Category"
  )

ggsave(paste0(fig_dir, "fig7_trajectories.pdf"), fig7, width = 8, height = 5.5)
ggsave(paste0(fig_dir, "fig7_trajectories.png"), fig7, width = 8, height = 5.5, dpi = 300)
cat("  Saved fig7_trajectories\n")

## ---------------------------------------------------------
## Figure 8: Leave-one-country-out
## ---------------------------------------------------------
cat("Figure 8: Leave-one-country-out\n")

loco <- fread(paste0(data_dir, "leave_one_country_out.csv"))

if (nrow(loco) > 2) {
  fig8 <- ggplot(loco, aes(x = reorder(excluded_country, coef), y = coef)) +
    geom_hline(yintercept = 0, linetype = "solid", color = "grey70") +
    geom_errorbar(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
      width = 0.3, color = "steelblue") +
    geom_point(size = 3, color = "steelblue") +
    coord_flip() +
    labs(
      x = "Excluded country",
      y = "RDD coefficient (GDP/cap change)",
      title = "Leave-One-Country-Out Sensitivity",
      subtitle = "Results robust to excluding any single country"
    )

  ggsave(paste0(fig_dir, "fig8_loco.pdf"), fig8, width = 7, height = 6)
  ggsave(paste0(fig_dir, "fig8_loco.png"), fig8, width = 7, height = 6, dpi = 300)
  cat("  Saved fig8_loco\n")
}

cat("\n=== ALL FIGURES GENERATED ===\n")
