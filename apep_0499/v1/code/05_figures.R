## 05_figures.R — Generate all figures
## apep_0499: Action Cœur de Ville and Property Markets

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

# ==============================================================
# 1. Load data
# ==============================================================
panel <- readRDS(file.path(data_dir, "commune_year_panel.rds"))

# ==============================================================
# 2. Figure 1: Raw Price Trends (ACV vs Control)
# ==============================================================
cat("Generating Figure 1: Raw Price Trends...\n")

trends <- panel %>%
  mutate(group = if_else(treated, "ACV Cities", "Control Cities")) %>%
  group_by(group, year) %>%
  summarise(
    mean_price_m2 = weighted.mean(mean_price_m2, n_transactions, na.rm = TRUE),
    ci_low = mean_price_m2 - 1.96 * sd(mean_price_m2, na.rm = TRUE) / sqrt(n()),
    ci_high = mean_price_m2 + 1.96 * sd(mean_price_m2, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )

fig1 <- ggplot(trends, aes(x = year, y = mean_price_m2, color = group, fill = group)) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_high), alpha = 0.15, color = NA) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_vline(xintercept = 2017.5, linetype = "dashed", color = "gray40") +
  annotate("text", x = 2017.7, y = max(trends$mean_price_m2) * 0.95,
           label = "ACV Announcement", hjust = 0, size = 3, color = "gray40") +
  scale_color_manual(values = c("ACV Cities" = "#2166AC", "Control Cities" = "#B2182B")) +
  scale_fill_manual(values = c("ACV Cities" = "#2166AC", "Control Cities" = "#B2182B")) +
  scale_y_continuous(labels = scales::label_comma(prefix = "\u20ac")) +
  labs(
    x = "Year",
    y = expression(paste("Mean Price per ", m^2, " (\u20ac)")),
    color = NULL, fill = NULL,
    title = "Residential Property Prices: ACV vs. Control Cities",
    subtitle = "Transaction-weighted mean price per square meter"
  ) +
  theme(legend.position = c(0.15, 0.85))

ggsave(file.path(fig_dir, "fig1_price_trends.pdf"), fig1, width = 8, height = 5,
       device = cairo_pdf)

# ==============================================================
# 3. Figure 2: Event Study
# ==============================================================
cat("Generating Figure 2: Event Study...\n")

es_coefs <- read_csv(file.path(tables_dir, "event_study_coefs.csv"), show_col_types = FALSE)

fig2 <- ggplot(es_coefs, aes(x = rel_year, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "solid", color = "gray70") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "gray40") +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_high), fill = "#2166AC", alpha = 0.2) +
  geom_point(size = 2.5, color = "#2166AC") +
  geom_line(color = "#2166AC", linewidth = 0.8) +
  annotate("text", x = -0.3, y = min(es_coefs$ci_low) * 0.9,
           label = "ACV\nAnnouncement", hjust = 0, size = 3, color = "gray40") +
  labs(
    x = "Years Relative to ACV Announcement (2018)",
    y = "DiD Coefficient (log price/m²)",
    title = "Event Study: Effect of ACV on Residential Property Prices",
    subtitle = "Commune and year fixed effects; clustered SEs at commune level"
  )

ggsave(file.path(fig_dir, "fig2_event_study.pdf"), fig2, width = 8, height = 5)

# ==============================================================
# 4. Figure 3: Transaction Volume Trends
# ==============================================================
cat("Generating Figure 3: Transaction Volume...\n")

vol_trends <- panel %>%
  mutate(group = if_else(treated, "ACV Cities", "Control Cities")) %>%
  group_by(group, year) %>%
  summarise(
    mean_trans = mean(n_transactions, na.rm = TRUE),
    .groups = "drop"
  )

# Normalize to 2017 = 100
vol_trends <- vol_trends %>%
  group_by(group) %>%
  mutate(
    base = mean_trans[year == 2017],
    index = 100 * mean_trans / base
  ) %>%
  ungroup()

fig3 <- ggplot(vol_trends, aes(x = year, y = index, color = group)) +
  geom_hline(yintercept = 100, linetype = "dotted", color = "gray70") +
  geom_vline(xintercept = 2017.5, linetype = "dashed", color = "gray40") +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_color_manual(values = c("ACV Cities" = "#2166AC", "Control Cities" = "#B2182B")) +
  labs(
    x = "Year",
    y = "Transaction Volume Index (2017 = 100)",
    color = NULL,
    title = "Property Transaction Volume: ACV vs. Control Cities",
    subtitle = "Mean transactions per commune, indexed to 2017"
  ) +
  theme(legend.position = c(0.15, 0.85))

ggsave(file.path(fig_dir, "fig3_volume_trends.pdf"), fig3, width = 8, height = 5)

# ==============================================================
# 5. Figure 4: Leave-One-Region-Out
# ==============================================================
cat("Generating Figure 4: Leave-One-Region-Out...\n")

loo <- tryCatch({
  read_csv(file.path(tables_dir, "leave_one_region_out.csv"), show_col_types = FALSE)
}, error = function(e) NULL)

if (!is.null(loo) && nrow(loo) > 0) {
  loo <- loo %>%
    mutate(
      ci_low = coefficient - 1.96 * std_error,
      ci_high = coefficient + 1.96 * std_error
    )

  fig4 <- ggplot(loo, aes(x = reorder(excluded_region, coefficient), y = coefficient)) +
    geom_hline(yintercept = 0, linetype = "solid", color = "gray70") +
    geom_pointrange(aes(ymin = ci_low, ymax = ci_high), color = "#2166AC") +
    coord_flip() +
    labs(
      x = "Excluded Region",
      y = "DiD Coefficient (log price/m²)",
      title = "Leave-One-Region-Out Sensitivity",
      subtitle = "Main coefficient stability when each region is dropped"
    )

  ggsave(file.path(fig_dir, "fig4_loo_regions.pdf"), fig4, width = 8, height = 5)
}

# ==============================================================
# 6. Figure 5: Callaway-Sant'Anna Event Study (if available)
# ==============================================================
cat("Generating Figure 5: CS-DiD Event Study...\n")

cs_coefs <- tryCatch({
  read_csv(file.path(tables_dir, "cs_did_event_study.csv"), show_col_types = FALSE)
}, error = function(e) NULL)

if (!is.null(cs_coefs) && nrow(cs_coefs) > 0) {
  fig5 <- ggplot(cs_coefs, aes(x = rel_year, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "solid", color = "gray70") +
    geom_vline(xintercept = -0.5, linetype = "dashed", color = "gray40") +
    geom_ribbon(aes(ymin = ci_low, ymax = ci_high), fill = "#4DAF4A", alpha = 0.2) +
    geom_point(size = 2.5, color = "#4DAF4A") +
    geom_line(color = "#4DAF4A", linewidth = 0.8) +
    labs(
      x = "Years Relative to Treatment",
      y = "ATT (log price/m²)",
      title = "Callaway-Sant'Anna Event Study",
      subtitle = "Doubly robust, never-treated control group"
    )

  ggsave(file.path(fig_dir, "fig5_cs_did_event_study.pdf"), fig5, width = 8, height = 5)
}

# ==============================================================
# 7. Figure 6: Placebo Test Results
# ==============================================================
cat("Generating Figure 6: Placebo Tests...\n")

placebo <- tryCatch({
  read_csv(file.path(tables_dir, "placebo_fake_dates.csv"), show_col_types = FALSE)
}, error = function(e) NULL)

if (!is.null(placebo) && nrow(placebo) > 0) {
  # Get the real effect for comparison
  main_results <- tryCatch({
    read_csv(file.path(tables_dir, "main_results.csv"), show_col_types = FALSE)
  }, error = function(e) NULL)

  real_coef <- if (!is.null(main_results)) {
    main_results$coefficient[main_results$model == "Commune + Year FE"]
  } else NA

  placebo_plot <- placebo %>%
    mutate(
      ci_low = coefficient - 1.96 * std_error,
      ci_high = coefficient + 1.96 * std_error,
      type = "Placebo"
    )

  if (!is.na(real_coef)) {
    real_se <- main_results$std_error[main_results$model == "Commune + Year FE"]
    placebo_plot <- bind_rows(
      placebo_plot,
      tibble(fake_year = 2018, coefficient = real_coef,
             std_error = real_se,
             ci_low = real_coef - 1.96 * real_se,
             ci_high = real_coef + 1.96 * real_se,
             p_value = NA, type = "Real Treatment")
    )
  }

  fig6 <- ggplot(placebo_plot, aes(x = factor(fake_year), y = coefficient,
                                    color = type)) +
    geom_hline(yintercept = 0, linetype = "solid", color = "gray70") +
    geom_pointrange(aes(ymin = ci_low, ymax = ci_high), size = 0.8) +
    scale_color_manual(values = c("Placebo" = "#B2182B", "Real Treatment" = "#2166AC")) +
    labs(
      x = "Treatment Year",
      y = "DiD Coefficient (log price/m²)",
      color = NULL,
      title = "Placebo Tests: Fake Treatment Dates vs. Real",
      subtitle = "Placebo tests use pre-treatment data only (2014-2017)"
    )

  ggsave(file.path(fig_dir, "fig6_placebo_tests.pdf"), fig6, width = 7, height = 5)
}

cat("\n=== ALL FIGURES GENERATED ===\n")
cat(sprintf("Figures saved to: %s\n", fig_dir))
