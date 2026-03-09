# =============================================================================
# 05_figures.R — Generate all figures from saved data
# APEP Paper apep_0552: Stranded by the Label?
# =============================================================================

source("00_packages.R")

# =============================================================================
# Figure 1: Mean Price by DPE Rating, Pre vs Post Reform
# =============================================================================

cat("=== Figure 1: Price by DPE rating ===\n")

sumstats <- fread(file.path(data_dir, "sumstats_prepost.csv"))
sumstats[, Period := ifelse(post_reform == 0, "Pre-reform\n(2018\u20132021H1)",
                             "Post-reform\n(2021H2\u20132024)")]
sumstats[, dpe_rating := factor(dpe_rating, levels = c("A", "B", "C", "D", "E", "F", "G"))]

fig1 <- ggplot(sumstats[dpe_rating %in% c("C", "D", "E", "F", "G")],
               aes(x = dpe_rating, y = Mean_PriceSqm, fill = Period)) +
  geom_col(position = "dodge", width = 0.7) +
  scale_fill_manual(values = c("#4575b4", "#d73027")) +
  scale_y_continuous(labels = scales::comma_format()) +
  labs(x = "DPE Energy Rating",
       y = "Mean Price per m\u00b2 (\u20ac)",
       title = "Property Prices by Energy Performance Rating",
       subtitle = "Before and after the 2021 DPE reform and rental ban announcement") +
  theme(legend.title = element_blank())

ggsave(file.path(fig_dir, "fig1_prices_by_rating.pdf"), fig1,
       width = 8, height = 5, dpi = 300)
cat("Figure 1 saved.\n")

# =============================================================================
# Figure 2: Event Study — G-Rating Discount Over Time
# =============================================================================

cat("=== Figure 2: Event study ===\n")

event_coefs <- fread(file.path(data_dir, "event_study_coefs.csv"))

# Convert semester to date for x-axis
event_coefs[, date_label := as.Date("2021-07-01") + semester * 182.5]

fig2 <- ggplot(event_coefs, aes(x = semester, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "#4575b4") +
  geom_point(size = 2.5, color = "#4575b4") +
  geom_line(linewidth = 0.8, color = "#4575b4") +
  annotate("text", x = -0.5, y = max(event_coefs$ci_upper, na.rm = TRUE) * 0.9,
           label = "Reform\n(July 2021)", hjust = 1.1, size = 3, color = "red") +
  scale_x_continuous(breaks = seq(-6, 6, 2)) +
  labs(x = "Semesters Relative to DPE Reform (July 2021)",
       y = "Log Price Difference (G vs D)",
       title = "Dynamic Treatment Effect of G-Rating on Property Prices",
       subtitle = "Relative to one semester before reform; 95% confidence intervals") +
  theme(panel.grid.major.x = element_blank())

ggsave(file.path(fig_dir, "fig2_event_study.pdf"), fig2,
       width = 8, height = 5, dpi = 300)
cat("Figure 2 saved.\n")

# =============================================================================
# Figure 3: RDD at G/F Threshold
# =============================================================================

cat("=== Figure 3: RDD plot ===\n")

df <- arrow::read_parquet(file.path(data_dir, "analysis_panel.parquet"))
setDT(df)

if ("kwh_m2_year" %in% names(df)) {
  # Post-reform sample
  df_rdd <- df[post_reform == 1 & !is.na(kwh_m2_year) &
                 kwh_m2_year >= 300 & kwh_m2_year <= 550]

  # Bin means
  df_rdd[, kwh_bin := round(kwh_m2_year / 5) * 5]
  bin_means <- df_rdd[, .(mean_log_price = mean(log_price),
                           se = sd(log_price) / sqrt(.N),
                           n = .N),
                       by = kwh_bin]

  fig3 <- ggplot(bin_means, aes(x = kwh_bin, y = mean_log_price)) +
    geom_vline(xintercept = 420, linetype = "dashed", color = "red", linewidth = 0.8) +
    geom_point(aes(size = n), alpha = 0.6, color = "#4575b4") +
    geom_smooth(data = bin_means[kwh_bin < 420], method = "lm", se = TRUE,
                color = "#2166ac", fill = "#2166ac", alpha = 0.15) +
    geom_smooth(data = bin_means[kwh_bin >= 420], method = "lm", se = TRUE,
                color = "#b2182b", fill = "#b2182b", alpha = 0.15) +
    annotate("text", x = 420, y = min(bin_means$mean_log_price),
             label = "G/F Threshold\n(420 kWh/m\u00b2)", hjust = -0.1, size = 3, color = "red") +
    annotate("text", x = 380, y = max(bin_means$mean_log_price) * 0.99,
             label = "F-rated\n(ban 2028)", size = 3, color = "#2166ac") +
    annotate("text", x = 460, y = max(bin_means$mean_log_price) * 0.99,
             label = "G-rated\n(ban 2025)", size = 3, color = "#b2182b") +
    scale_size_continuous(guide = "none") +
    labs(x = "Energy Consumption (kWh/m\u00b2/year)",
         y = "Mean Log Price",
         title = "Regression Discontinuity at the G/F Threshold",
         subtitle = "Post-reform transactions (2021H2\u20132024); 5 kWh bins") +
    theme(panel.grid.major.x = element_blank())

  ggsave(file.path(fig_dir, "fig3_rdd_threshold.pdf"), fig3,
         width = 8, height = 5, dpi = 300)
  cat("Figure 3 saved.\n")
}

# =============================================================================
# Figure 4: Triple-Diff — G Discount by Rental Share
# =============================================================================

cat("=== Figure 4: Triple-diff by rental share ===\n")

# Compute DiD coefficient by rental-share decile
df_GD <- df[dpe_rating %in% c("G", "D") & !is.na(pct_rental)]
df_GD[, rental_decile := as.integer(cut(pct_rental, breaks = quantile(pct_rental, probs = seq(0, 1, 0.1), na.rm = TRUE), include.lowest = TRUE))]

decile_results <- list()
for (d in 1:10) {
  m <- feols(log_price ~ is_G * post_reform +
               surface_reelle_bati + nombre_pieces_principales + is_apartment |
               code_commune + yq,
             data = df_GD[rental_decile == d],
             cluster = ~code_commune)

  decile_results[[d]] <- data.table(
    Decile = d,
    Mean_Rental = df_GD[rental_decile == d, mean(pct_rental)],
    Estimate = coef(m)["is_G:post_reform"],
    SE = se(m)["is_G:post_reform"]
  )
}

decile_dt <- rbindlist(decile_results)
decile_dt[, ci_lower := Estimate - 1.96 * SE]
decile_dt[, ci_upper := Estimate + 1.96 * SE]
fwrite(decile_dt, file.path(data_dir, "triple_diff_by_decile.csv"))

fig4 <- ggplot(decile_dt, aes(x = Mean_Rental, y = Estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "#d73027") +
  geom_point(size = 3, color = "#d73027") +
  geom_smooth(method = "lm", se = FALSE, color = "#d73027", linetype = "solid") +
  scale_x_continuous(labels = scales::percent_format()) +
  labs(x = "Commune Rental Share",
       y = "DiD Coefficient: G-Rating \u00d7 Post-Reform",
       title = "Regulatory vs. Informational Effect",
       subtitle = "G-rating discount by commune rental exposure; points = decile estimates") +
  theme(panel.grid.major.x = element_blank())

ggsave(file.path(fig_dir, "fig4_triple_diff_rental.pdf"), fig4,
       width = 8, height = 5, dpi = 300)
cat("Figure 4 saved.\n")

# =============================================================================
# Figure 5: Multi-Cutoff RDD Comparison
# =============================================================================

cat("=== Figure 5: Multi-cutoff comparison ===\n")

rdd_results <- fread(file.path(data_dir, "rdd_results.csv"))

if (nrow(rdd_results) > 0) {
  rdd_results[, ci_lower := Estimate - 1.96 * SE_robust]
  rdd_results[, ci_upper := Estimate + 1.96 * SE_robust]
  rdd_results[, Boundary := factor(Threshold,
                                    levels = c(250, 330, 420),
                                    labels = c("D/C (250)\nNo ban",
                                               "F/E (330)\nBan 2028",
                                               "G/F (420)\nBan 2025"))]

  fig5 <- ggplot(rdd_results, aes(x = Boundary, y = Estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper),
                    size = 1, color = "#4575b4", linewidth = 1) +
    labs(x = "DPE Threshold",
         y = "RDD Estimate (Log Price Discontinuity)",
         title = "Multi-Cutoff RDD: Regulatory Gradient",
         subtitle = "Larger discontinuities at boundaries with imminent rental bans") +
    theme(panel.grid.major.x = element_blank())

  ggsave(file.path(fig_dir, "fig5_multi_cutoff.pdf"), fig5,
         width = 6, height = 5, dpi = 300)
  cat("Figure 5 saved.\n")
}

# =============================================================================
# Figure 6: McCrary Density Plot
# =============================================================================

cat("=== Figure 6: Density around threshold ===\n")

if ("kwh_m2_year" %in% names(df)) {
  df_post <- df[post_reform == 1 & !is.na(kwh_m2_year) &
                  kwh_m2_year >= 300 & kwh_m2_year <= 550]

  fig6 <- ggplot(df_post, aes(x = kwh_m2_year)) +
    geom_histogram(binwidth = 5, fill = "#4575b4", alpha = 0.7, color = "white") +
    geom_vline(xintercept = 420, linetype = "dashed", color = "red", linewidth = 0.8) +
    annotate("text", x = 420, y = Inf, label = "G/F Threshold",
             hjust = -0.1, vjust = 2, size = 3.5, color = "red") +
    labs(x = "Energy Consumption (kWh/m\u00b2/year)",
         y = "Number of Transactions",
         title = "Distribution of Energy Consumption Near G/F Threshold",
         subtitle = "Post-reform period; potential manipulation would show bunching below 420") +
    theme(panel.grid.major.x = element_blank())

  ggsave(file.path(fig_dir, "fig6_density.pdf"), fig6,
         width = 8, height = 5, dpi = 300)
  cat("Figure 6 saved.\n")
}

# =============================================================================
# Figure 7: Bandwidth Sensitivity
# =============================================================================

cat("=== Figure 7: BW sensitivity ===\n")

bw_sens <- fread(file.path(data_dir, "rdd_bw_sensitivity.csv"))

if (nrow(bw_sens) > 0) {
  fig7 <- ggplot(bw_sens, aes(x = Bandwidth, y = Estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "#4575b4") +
    geom_point(size = 3, color = "#4575b4") +
    geom_line(color = "#4575b4", linewidth = 0.8) +
    labs(x = "Bandwidth (kWh/m\u00b2)",
         y = "RDD Estimate",
         title = "RDD Sensitivity to Bandwidth Choice",
         subtitle = "G/F threshold (420 kWh/m\u00b2); triangular kernel, linear fit")

  ggsave(file.path(fig_dir, "fig7_bw_sensitivity.pdf"), fig7,
         width = 7, height = 5, dpi = 300)
  cat("Figure 7 saved.\n")
}

cat("\n=== All figures generated ===\n")
