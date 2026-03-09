# =============================================================================
# 05_figures.R — All Figure Generation
# APEP Paper apep_0547: No-Fault Eviction Abolition and Private Rental Supply
# =============================================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

# =============================================================================
# LOAD DATA (all from CSV — data-first rule)
# =============================================================================
agg_trends <- fread(file.path(data_dir, "aggregate_trends.csv"))
agg_trends[, ym := as.Date(ym)]

es_coefs <- fread(file.path(data_dir, "event_study_coefs.csv"))

key_results <- fread(file.path(data_dir, "key_results.csv"))

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, ym := as.Date(ym)]

# Try to load robustness data
perm_dist <- tryCatch(fread(file.path(data_dir, "permutation_distribution.csv")), error = function(e) NULL)
loo_results <- tryCatch(fread(file.path(data_dir, "leave_one_out.csv")), error = function(e) NULL)
es_border <- tryCatch(fread(file.path(data_dir, "es_border_coefs.csv")), error = function(e) NULL)

# =============================================================================
# FIGURE 1: Aggregate Transaction Trends (Wales vs England)
# =============================================================================
cat("Creating Figure 1: Aggregate trends...\n")

# Index to Jan 2018 = 100
agg_trends[, idx := mean_n / mean_n[ym == as.Date("2018-01-01")] * 100,
            by = country]

p1 <- ggplot(agg_trends, aes(x = ym, y = idx, color = country)) +
  geom_vline(xintercept = as.Date("2022-12-01"), linetype = "dashed",
             color = "grey40", linewidth = 0.5) +
  geom_line(linewidth = 0.7) +
  annotate("text", x = as.Date("2023-01-01"), y = max(agg_trends$idx, na.rm = TRUE) * 0.95,
           label = "Renting Homes Act\nimplemented", hjust = 0, size = 3, color = "grey40") +
  scale_color_manual(values = apep_colors[c("Wales", "England")]) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(x = NULL, y = "Transaction Volume (Jan 2018 = 100)",
       title = "Residential Transaction Volumes: Wales vs. England",
       subtitle = "Monthly LA-level averages, indexed to January 2018",
       color = NULL) +
  theme(legend.position = c(0.15, 0.85))

ggsave(file.path(fig_dir, "fig1_trends.pdf"), p1, width = 7, height = 4.5)
ggsave(file.path(fig_dir, "fig1_trends.png"), p1, width = 7, height = 4.5, dpi = 300)
cat("  Saved fig1_trends.pdf\n")

# =============================================================================
# FIGURE 2: Event Study (Main Result)
# =============================================================================
cat("Creating Figure 2: Event study...\n")

es_plot_data <- es_coefs[t >= -24 & t <= 30]
es_plot_data[, ci_lo := estimate - 1.96 * se]
es_plot_data[, ci_hi := estimate + 1.96 * se]

p2 <- ggplot(es_plot_data, aes(x = t, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey60", linewidth = 0.3) +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40", linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = apep_colors["Wales"], alpha = 0.15) +
  geom_point(size = 1.5, color = apep_colors["Wales"]) +
  geom_line(linewidth = 0.4, color = apep_colors["Wales"]) +
  annotate("text", x = -12, y = max(es_plot_data$ci_hi, na.rm = TRUE) * 0.9,
           label = "Pre-treatment", size = 3, color = "grey50") +
  annotate("text", x = 15, y = max(es_plot_data$ci_hi, na.rm = TRUE) * 0.9,
           label = "Post-treatment", size = 3, color = "grey50") +
  scale_x_continuous(breaks = seq(-24, 30, by = 6)) +
  labs(x = "Months Relative to December 2022",
       y = "Coefficient (log transactions)",
       title = "Event Study: Effect of Renting Homes Act on Transaction Volumes",
       subtitle = "Wales vs. England, LA × month panel with LA and time FE; 95% CI shown")

ggsave(file.path(fig_dir, "fig2_event_study.pdf"), p2, width = 7, height = 4.5)
ggsave(file.path(fig_dir, "fig2_event_study.png"), p2, width = 7, height = 4.5, dpi = 300)
cat("  Saved fig2_event_study.pdf\n")

# =============================================================================
# FIGURE 3: Permutation Inference Distribution
# =============================================================================
if (!is.null(perm_dist)) {
  cat("Creating Figure 3: Permutation inference...\n")

  actual_val <- perm_dist$actual[1]

  p3 <- ggplot(perm_dist, aes(x = beta)) +
    geom_histogram(bins = 50, fill = "grey70", color = "grey50", linewidth = 0.2) +
    geom_vline(xintercept = actual_val, color = apep_colors["Wales"],
               linewidth = 1, linetype = "solid") +
    geom_vline(xintercept = -actual_val, color = apep_colors["Wales"],
               linewidth = 0.7, linetype = "dashed") +
    annotate("text", x = actual_val, y = Inf,
             label = paste0("Actual\n\u03B2 = ", round(actual_val, 3)),
             hjust = -0.1, vjust = 1.5, size = 3, color = apep_colors["Wales"]) +
    labs(x = "Placebo Treatment Effect",
         y = "Count",
         title = "Permutation Inference: Distribution of Placebo Effects",
         subtitle = paste0("1,000 random assignments of 22 'treated' LAs; ",
                           "exact p = ", round(mean(abs(perm_dist$beta) >= abs(actual_val)), 3)))

  ggsave(file.path(fig_dir, "fig3_permutation.pdf"), p3, width = 7, height = 4.5)
  ggsave(file.path(fig_dir, "fig3_permutation.png"), p3, width = 7, height = 4.5, dpi = 300)
  cat("  Saved fig3_permutation.pdf\n")
}

# =============================================================================
# FIGURE 4: Leave-One-Out
# =============================================================================
if (!is.null(loo_results)) {
  cat("Creating Figure 4: Leave-one-out...\n")

  full_sample_est <- key_results[model == "DiD (log transactions)", estimate]

  loo_results[, ci_lo := estimate - 1.96 * se]
  loo_results[, ci_hi := estimate + 1.96 * se]

  # Order by estimate
  loo_results[, dropped_la := factor(dropped_la, levels = dropped_la[order(estimate)])]

  p4 <- ggplot(loo_results, aes(x = dropped_la, y = estimate)) +
    geom_hline(yintercept = 0, color = "grey60", linewidth = 0.3) +
    geom_hline(yintercept = full_sample_est, color = apep_colors["Wales"],
               linetype = "dashed", linewidth = 0.5) +
    geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                    size = 0.3, color = "grey30") +
    coord_flip() +
    labs(x = "Dropped Welsh LA",
         y = "DiD Estimate (log transactions)",
         title = "Leave-One-Out: Sensitivity to Individual Welsh LAs",
         subtitle = "Dashed line = full-sample estimate; error bars = 95% CI")

  ggsave(file.path(fig_dir, "fig4_leave_one_out.pdf"), p4, width = 7, height = 6)
  ggsave(file.path(fig_dir, "fig4_leave_one_out.png"), p4, width = 7, height = 6, dpi = 300)
  cat("  Saved fig4_leave_one_out.pdf\n")
}

# =============================================================================
# FIGURE 5: Composition Analysis — Category B Share Event Study
# =============================================================================
cat("Creating Figure 5: Composition event study...\n")

# Run category B share event study
es_catb <- feols(cat_b_share ~ i(t_rel, wales, ref = -1) | la_id + ym_id,
                  data = panel[t_rel >= -24 & t_rel <= 24],
                  cluster = ~la_id)

catb_coefs <- as.data.table(coeftable(es_catb))
catb_coefs[, term := rownames(coeftable(es_catb))]
catb_coefs[, t := as.integer(str_extract(term, "-?\\d+"))]
catb_coefs <- catb_coefs[!is.na(t)]
setnames(catb_coefs, c("estimate", "se", "t_stat", "p_value", "term", "t"))
catb_coefs <- rbind(catb_coefs,
                     data.table(estimate = 0, se = 0, t_stat = NA, p_value = NA,
                                term = "ref", t = -1))
setorder(catb_coefs, t)
catb_coefs[, ci_lo := estimate - 1.96 * se]
catb_coefs[, ci_hi := estimate + 1.96 * se]

fwrite(catb_coefs, file.path(data_dir, "es_catb_coefs.csv"))

p5 <- ggplot(catb_coefs, aes(x = t, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey60", linewidth = 0.3) +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40", linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = apep_colors["England"], alpha = 0.15) +
  geom_point(size = 1.5, color = apep_colors["England"]) +
  geom_line(linewidth = 0.4, color = apep_colors["England"]) +
  scale_x_continuous(breaks = seq(-24, 24, by = 6)) +
  labs(x = "Months Relative to December 2022",
       y = "Coefficient (Category B share)",
       title = "Event Study: Category B Transaction Share (Buy-to-Let Proxy)",
       subtitle = "Wales vs. England; higher share = more investment property sales")

ggsave(file.path(fig_dir, "fig5_catb_event_study.pdf"), p5, width = 7, height = 4.5)
ggsave(file.path(fig_dir, "fig5_catb_event_study.png"), p5, width = 7, height = 4.5, dpi = 300)
cat("  Saved fig5_catb_event_study.pdf\n")

# =============================================================================
# FIGURE 6: Border County Event Study
# =============================================================================
if (!is.null(es_border) && nrow(es_border) > 0) {
  cat("Creating Figure 6: Border county event study...\n")

  es_border[, ci_lo := estimate - 1.96 * se]
  es_border[, ci_hi := estimate + 1.96 * se]

  p6 <- ggplot(es_border, aes(x = t, y = estimate)) +
    geom_hline(yintercept = 0, color = "grey60", linewidth = 0.3) +
    geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40", linewidth = 0.5) +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = apep_colors["Border"], alpha = 0.15) +
    geom_point(size = 1.5, color = apep_colors["Border"]) +
    geom_line(linewidth = 0.4, color = apep_colors["Border"]) +
    scale_x_continuous(breaks = seq(-24, 24, by = 6)) +
    labs(x = "Months Relative to December 2022",
         y = "Coefficient (log transactions)",
         title = "Event Study: Border-County Subsample",
         subtitle = "Wales vs. adjacent English LAs only; tighter geographic control")

  ggsave(file.path(fig_dir, "fig6_border_event_study.pdf"), p6, width = 7, height = 4.5)
  ggsave(file.path(fig_dir, "fig6_border_event_study.png"), p6, width = 7, height = 4.5, dpi = 300)
  cat("  Saved fig6_border_event_study.pdf\n")
}

# =============================================================================
# FIGURE 7: DDD Heterogeneity by PRS Share
# =============================================================================
cat("Creating Figure 7: DDD heterogeneity...\n")

# Event study by PRS tercile
ddd_coefs_list <- list()
for (terc in c("Low PRS", "Mid PRS", "High PRS")) {
  sub <- panel[prs_tercile == terc & t_rel >= -24 & t_rel <= 24]
  if (nrow(sub) > 0 && uniqueN(sub[wales == 1, la]) > 0) {
    es_terc <- tryCatch(
      feols(log_n ~ i(t_rel, wales, ref = -1) | la_id + ym_id,
            data = sub, cluster = ~la_id),
      error = function(e) NULL
    )
    if (!is.null(es_terc)) {
      tc <- as.data.table(coeftable(es_terc))
      tc[, term := rownames(coeftable(es_terc))]
      tc[, t := as.integer(str_extract(term, "-?\\d+"))]
      tc <- tc[!is.na(t)]
      setnames(tc, c("estimate", "se", "t_stat", "p_value", "term", "t"))
      tc <- rbind(tc, data.table(estimate = 0, se = 0, t_stat = NA,
                                  p_value = NA, term = "ref", t = -1))
      tc[, tercile := terc]
      ddd_coefs_list[[terc]] <- tc
    }
  }
}

if (length(ddd_coefs_list) > 0) {
  ddd_coefs <- rbindlist(ddd_coefs_list)
  ddd_coefs[, ci_lo := estimate - 1.96 * se]
  ddd_coefs[, ci_hi := estimate + 1.96 * se]
  fwrite(ddd_coefs, file.path(data_dir, "ddd_tercile_coefs.csv"))

  p7 <- ggplot(ddd_coefs, aes(x = t, y = estimate, color = tercile, fill = tercile)) +
    geom_hline(yintercept = 0, color = "grey60", linewidth = 0.3) +
    geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40", linewidth = 0.5) +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.1, color = NA) +
    geom_point(size = 1, alpha = 0.8) +
    geom_line(linewidth = 0.4, alpha = 0.8) +
    facet_wrap(~tercile, ncol = 1) +
    scale_color_manual(values = c("Low PRS" = "#1F77B4", "Mid PRS" = "#FF7F0E",
                                   "High PRS" = "#D62728")) +
    scale_fill_manual(values = c("Low PRS" = "#1F77B4", "Mid PRS" = "#FF7F0E",
                                  "High PRS" = "#D62728")) +
    scale_x_continuous(breaks = seq(-24, 24, by = 6)) +
    labs(x = "Months Relative to December 2022",
         y = "Coefficient (log transactions)",
         title = "Event Study by Pre-Reform PRS Share Tercile",
         subtitle = "Effect concentrated in high-PRS areas supports landlord-exit channel") +
    theme(legend.position = "none")

  ggsave(file.path(fig_dir, "fig7_ddd_terciles.pdf"), p7, width = 7, height = 8)
  ggsave(file.path(fig_dir, "fig7_ddd_terciles.png"), p7, width = 7, height = 8, dpi = 300)
  cat("  Saved fig7_ddd_terciles.pdf\n")
}

# =============================================================================
# FIGURE 8: Price Event Study
# =============================================================================
cat("Creating Figure 8: Price event study...\n")

price_es_coefs <- tryCatch(fread(file.path(data_dir, "price_event_study_coefs.csv")), error = function(e) NULL)

if (!is.null(price_es_coefs)) {
  price_es_plot <- price_es_coefs[t >= -24 & t <= 30]
  price_es_plot[, ci_lo := estimate - 1.96 * se]
  price_es_plot[, ci_hi := estimate + 1.96 * se]

  p8 <- ggplot(price_es_plot, aes(x = t, y = estimate)) +
    geom_hline(yintercept = 0, color = "grey60", linewidth = 0.3) +
    geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40", linewidth = 0.5) +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = apep_colors["England"], alpha = 0.15) +
    geom_point(size = 1.5, color = apep_colors["England"]) +
    geom_line(linewidth = 0.4, color = apep_colors["England"]) +
    annotate("text", x = -12, y = max(price_es_plot$ci_hi, na.rm = TRUE) * 0.9,
             label = "Pre-treatment", size = 3, color = "grey50") +
    annotate("text", x = 15, y = max(price_es_plot$ci_hi, na.rm = TRUE) * 0.9,
             label = "Post-treatment", size = 3, color = "grey50") +
    scale_x_continuous(breaks = seq(-24, 30, by = 6)) +
    labs(x = "Months Relative to December 2022",
         y = "Coefficient (log mean price)",
         title = "Event Study: Effect of Renting Homes Act on Transaction Prices",
         subtitle = "Wales vs. England, LA x month panel with LA and time FE; 95% CI shown")

  ggsave(file.path(fig_dir, "fig8_price_event_study.pdf"), p8, width = 7, height = 4.5)
  ggsave(file.path(fig_dir, "fig8_price_event_study.png"), p8, width = 7, height = 4.5, dpi = 300)
  cat("  Saved fig8_price_event_study.pdf\n")
}

cat("\n=== All figures generated ===\n")
