# 05_figures.R — Generate all figures for Egypt devaluation paper
# APEP-0569: Egypt Devaluation Import Compression

source("00_packages.R")
DATA_DIR <- "../data"
FIG_DIR <- "../figures"
dir.create(FIG_DIR, showWarnings = FALSE)

# Color palette
bec_colors <- c("Intermediate" = "#2166AC", "Capital" = "#66BD63", "Final" = "#D6604D")

# ============================================================
# Figure 1: Exchange rate time series
# ============================================================
cat("Figure 1: Exchange rate...\n")

fx <- fread(file.path(DATA_DIR, "egypt_exchange_rate.csv"))

p1 <- ggplot(fx[year >= 2010 & year <= 2023], aes(x = year, y = exchange_rate)) +
  geom_line(linewidth = 1, color = "#2166AC") +
  geom_point(size = 2, color = "#2166AC") +
  geom_vline(xintercept = 2016.85, linetype = "dashed", color = "red", linewidth = 0.7) +
  annotate("text", x = 2017.3, y = max(fx[year <= 2023, exchange_rate]) * 0.5,
    label = "Float\n(Nov 2016)", hjust = 0, size = 3.5, color = "red") +
  labs(
    x = NULL, y = "EGP per USD",
    title = "Egyptian Pound Exchange Rate, 2010\u20132023"
  ) +
  scale_x_continuous(breaks = seq(2010, 2023, 2)) +
  theme(panel.grid.major.x = element_line(color = "grey90"))

ggsave(file.path(FIG_DIR, "fig1_exchange_rate.pdf"), p1, width = 7, height = 4.5)

# ============================================================
# Figure 2: Import trends by BEC category (indexed to 2015=100)
# ============================================================
cat("Figure 2: Import trends by BEC...\n")

agg <- fread(file.path(DATA_DIR, "agg_annual_bec.csv"))
agg[, bec_label := factor(
  fifelse(bec3 == "intermediate", "Intermediate",
    fifelse(bec3 == "capital", "Capital", "Final")),
  levels = c("Intermediate", "Capital", "Final")
)]

p2 <- ggplot(agg, aes(x = year, y = index_100, color = bec_label, shape = bec_label)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2.5) +
  geom_vline(xintercept = 2016.85, linetype = "dashed", color = "grey40", linewidth = 0.5) +
  geom_hline(yintercept = 100, linetype = "dotted", color = "grey60") +
  scale_color_manual(values = bec_colors) +
  labs(
    x = NULL, y = "Import Value Index (2015 = 100)",
    title = "Total Import Value by End-Use Category, 2010\u20132023",
    color = "BEC Category", shape = "BEC Category"
  ) +
  scale_x_continuous(breaks = seq(2010, 2023, 2)) +
  annotate("text", x = 2017.3, y = 105,
    label = "Float", hjust = 0, size = 3, color = "grey40")

ggsave(file.path(FIG_DIR, "fig2_import_trends_bec.pdf"), p2, width = 7, height = 5)

# ============================================================
# Figure 3: Event study coefficients (KEY FIGURE)
# ============================================================
cat("Figure 3: Event study...\n")

es <- fread(file.path(DATA_DIR, "event_study_coefs.csv"))
es[, bec_type := factor(bec_type, levels = c("Intermediate", "Capital"))]

p3 <- ggplot(es, aes(x = yr, y = estimate, color = bec_type, shape = bec_type)) +
  geom_hline(yintercept = 0, linetype = "solid", color = "grey70") +
  geom_vline(xintercept = 2016.5, linetype = "dashed", color = "grey40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi, fill = bec_type),
    alpha = 0.15, color = NA) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.5) +
  scale_color_manual(values = c("Intermediate" = "#2166AC", "Capital" = "#66BD63")) +
  scale_fill_manual(values = c("Intermediate" = "#2166AC", "Capital" = "#66BD63")) +
  labs(
    x = NULL, y = "Coefficient (relative to final goods, 2015 = 0)",
    title = "Event Study: Differential Import Response by End-Use Category",
    color = "vs. Final Goods", shape = "vs. Final Goods", fill = "vs. Final Goods"
  ) +
  scale_x_continuous(breaks = seq(2010, 2023, 2)) +
  annotate("text", x = 2016.8, y = min(es$ci_lo, na.rm = TRUE) * 0.9,
    label = "Float", hjust = 0, size = 3, color = "grey40")

ggsave(file.path(FIG_DIR, "fig3_event_study.pdf"), p3, width = 8, height = 5)

# ============================================================
# Figure 4: Monthly dynamics around devaluation
# ============================================================
cat("Figure 4: Monthly dynamics...\n")

if (file.exists(file.path(DATA_DIR, "monthly_agg_bec.csv"))) {
  monthly <- fread(file.path(DATA_DIR, "monthly_agg_bec.csv"))
  monthly[, bec_label := factor(
    fifelse(bec3 == "intermediate", "Intermediate",
      fifelse(bec3 == "capital", "Capital", "Final")),
    levels = c("Intermediate", "Capital", "Final")
  )]

  p4 <- ggplot(monthly[!is.na(index_100)],
    aes(x = months_from_deval, y = index_100, color = bec_label)) +
    geom_line(linewidth = 0.7) +
    geom_point(size = 1.5) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "red", linewidth = 0.5) +
    geom_hline(yintercept = 100, linetype = "dotted", color = "grey60") +
    scale_color_manual(values = bec_colors) +
    labs(
      x = "Months from Devaluation (Nov 2016 = 0)",
      y = "Import Value Index (Oct 2016 = 100)",
      title = "Monthly Import Dynamics Around the Float",
      color = "BEC Category"
    ) +
    annotate("text", x = 0.5, y = 60, label = "Float\n(Nov 2016)",
      hjust = 0, size = 3, color = "red")

  ggsave(file.path(FIG_DIR, "fig4_monthly_dynamics.pdf"), p4, width = 8, height = 5)
} else {
  cat("  Skipped (no monthly data)\n")
}

# ============================================================
# Figure 5: Trade diversion by currency zone
# ============================================================
cat("Figure 5: Trade diversion...\n")

if (file.exists(file.path(DATA_DIR, "bilateral_agg_currency.csv"))) {
  bilateral <- fread(file.path(DATA_DIR, "bilateral_agg_currency.csv"))
  bilateral[, currency_zone := factor(currency_zone,
    levels = c("dollar", "euro", "yuan", "other"))]

  currency_colors <- c("dollar" = "#2166AC", "euro" = "#B2182B",
                        "yuan" = "#D6604D", "other" = "grey60")

  p5 <- ggplot(bilateral[!is.na(index_100)],
    aes(x = year, y = index_100, color = currency_zone)) +
    geom_line(linewidth = 0.9) +
    geom_point(size = 2) +
    geom_vline(xintercept = 2016.85, linetype = "dashed", color = "grey40") +
    geom_hline(yintercept = 100, linetype = "dotted", color = "grey60") +
    scale_color_manual(values = currency_colors,
      labels = c("Dollar zone", "Euro zone", "Yuan (China)", "Other")) +
    labs(
      x = NULL, y = "Import Value Index (2015 = 100)",
      title = "Import Trends by Partner Currency Zone",
      color = "Source"
    )

  ggsave(file.path(FIG_DIR, "fig5_trade_diversion.pdf"), p5, width = 7, height = 5)
} else {
  cat("  Skipped (no bilateral data)\n")
}

# ============================================================
# Figure 6: Product variety counts
# ============================================================
cat("Figure 6: Product varieties...\n")

if (file.exists(file.path(DATA_DIR, "variety_counts.csv"))) {
  varieties <- fread(file.path(DATA_DIR, "variety_counts.csv"))
  varieties[, bec_label := factor(
    fifelse(bec3 == "intermediate", "Intermediate",
      fifelse(bec3 == "capital", "Capital", "Final")),
    levels = c("Intermediate", "Capital", "Final")
  )]

  # Index to 2015
  base_v <- varieties[year == 2015, .(bec_label, base = n_varieties)]
  varieties <- merge(varieties, base_v, by = "bec_label", all.x = TRUE)
  varieties[, index_100 := n_varieties / base * 100]

  p6 <- ggplot(varieties[!is.na(index_100)],
    aes(x = year, y = index_100, color = bec_label, shape = bec_label)) +
    geom_line(linewidth = 0.8) +
    geom_point(size = 2) +
    geom_vline(xintercept = 2016.85, linetype = "dashed", color = "grey40") +
    geom_hline(yintercept = 100, linetype = "dotted", color = "grey60") +
    scale_color_manual(values = bec_colors) +
    labs(
      x = NULL, y = "Number of Imported Varieties (2015 = 100)",
      title = "Extensive Margin: Product Variety by End-Use Category",
      color = "BEC Category", shape = "BEC Category"
    ) +
    scale_x_continuous(breaks = seq(2010, 2023, 2))

  ggsave(file.path(FIG_DIR, "fig6_varieties.pdf"), p6, width = 7, height = 5)
}

# ============================================================
# Figure C.1: Randomization inference distribution
# ============================================================
cat("Figure C.1: RI distribution...\n")

if (file.exists(file.path(DATA_DIR, "robustness_ri.csv"))) {
  ri <- fread(file.path(DATA_DIR, "robustness_ri.csv"))
  true_b <- ri$true_beta[1]

  p_ri <- ggplot(ri[!is.na(beta_int)], aes(x = beta_int)) +
    geom_histogram(bins = 40, fill = "grey70", color = "white") +
    geom_vline(xintercept = true_b, color = "red", linewidth = 1) +
    annotate("text", x = true_b, y = Inf, label = "Actual estimate",
      vjust = 2, hjust = -0.1, color = "red", size = 3.5) +
    labs(
      x = "Placebo coefficient (intermediate × post)",
      y = "Count",
      title = "Randomization Inference: Distribution of Placebo Coefficients"
    )

  ggsave(file.path(FIG_DIR, "figC1_ri_distribution.pdf"), p_ri, width = 7, height = 4.5)
}

# ============================================================
# Figure C.2: Leave-one-out HS2
# ============================================================
cat("Figure C.2: Leave-one-out...\n")

if (file.exists(file.path(DATA_DIR, "robustness_loo_hs2.csv"))) {
  loo <- fread(file.path(DATA_DIR, "robustness_loo_hs2.csv"))

  # Full sample estimate
  load(file.path(DATA_DIR, "models.RData"))
  full_beta <- coeftable(m1b)["post:is_intermediate", "Estimate"]

  loo[, dropped_hs2 := factor(dropped_hs2, levels = dropped_hs2[order(beta_int)])]

  p_loo <- ggplot(loo, aes(x = dropped_hs2, y = beta_int)) +
    geom_point(size = 1.5) +
    geom_errorbar(aes(ymin = beta_int - 1.96 * se_int,
      ymax = beta_int + 1.96 * se_int), width = 0.3, linewidth = 0.3) +
    geom_hline(yintercept = full_beta, color = "red", linetype = "dashed") +
    labs(
      x = "Dropped HS2 Chapter",
      y = "Coefficient (intermediate × post)",
      title = "Leave-One-Out: Stability of Main Estimate"
    ) +
    theme(axis.text.x = element_text(angle = 90, size = 5))

  ggsave(file.path(FIG_DIR, "figC2_loo.pdf"), p_loo, width = 10, height = 5)
}

cat("\n=== All figures generated ===\n")
