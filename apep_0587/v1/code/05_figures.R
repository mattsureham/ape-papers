## =============================================================================
## 05_figures.R — All figures for the paper
## APEP-0587: Bunching at the UK High Income Child Benefit Charge Notch
## =============================================================================
source("00_packages.R")

data_dir <- "../data"
fig_dir  <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

## ---- Load all analysis results ----------------------------------------------
spi_dens   <- fread(file.path(data_dir, "spi_density.csv"))
ashe_dens  <- fread(file.path(data_dir, "ashe_density.csv"))
bunching_spi  <- fread(file.path(data_dir, "bunching_by_year_spi.csv"))
bunching_ashe <- fread(file.path(data_dir, "bunching_by_year_ashe.csv"))
boot_results  <- fread(file.path(data_dir, "bunching_bootstrap.csv"))
dib           <- fread(file.path(data_dir, "difference_in_bunching.csv"))
cb_admin      <- fread(file.path(data_dir, "cb_admin.csv"))
poly_sens     <- fread(file.path(data_dir, "robustness_polynomial.csv"))
window_sens   <- fread(file.path(data_dir, "robustness_window.csv"))
placebo_all   <- fread(file.path(data_dir, "robustness_placebo.csv"))
timeseries    <- fread(file.path(data_dir, "robustness_timeseries.csv"))
gender_50k    <- fread(file.path(data_dir, "gender_density_50k.csv"))

w <- 6.5; h <- 4.5  # standard dimensions

## =============================================================================
## FIGURE 1: Income density — Pre-HICBC vs Post-HICBC
## The paper's key visual: excess mass near £50,000 after January 2013
## =============================================================================

# Average density across pre-HICBC years (2005-2012) and post-HICBC years (2013-2022)
avg_pre <- spi_dens[tax_year %in% 2005:2012,
                     .(density = mean(density, na.rm = TRUE)),
                     by = income_midpoint]
avg_pre[, period := "Pre-HICBC (2005\u20132012)"]

avg_post <- spi_dens[tax_year %in% 2013:2022,
                      .(density = mean(density, na.rm = TRUE)),
                      by = income_midpoint]
avg_post[, period := "Post-HICBC (2013\u20132022)"]

avg_both <- rbind(avg_pre, avg_post)

fig1 <- ggplot(avg_both[income_midpoint >= 30000 & income_midpoint <= 80000],
               aes(x = income_midpoint / 1000, y = density * 1e6,
                   color = period, linetype = period)) +
  geom_line(linewidth = 0.9) +
  geom_vline(xintercept = 50, linetype = "dashed", color = "gray40", linewidth = 0.5) +
  annotate("text", x = 51, y = max(avg_both[income_midpoint >= 30000 &
                                              income_midpoint <= 80000]$density * 1e6, na.rm = TRUE) * 0.95,
           label = "HICBC notch\n(\u00a350,000)", hjust = 0, size = 3, color = "gray30") +
  scale_x_continuous(labels = scales::label_comma(prefix = "\u00a3", suffix = "k"),
                     breaks = seq(30, 80, 10)) +
  scale_color_manual(values = c("Pre-HICBC (2005\u20132012)" = "#2166ac",
                                 "Post-HICBC (2013\u20132022)" = "#b2182b")) +
  scale_linetype_manual(values = c("Pre-HICBC (2005\u20132012)" = "dashed",
                                    "Post-HICBC (2013\u20132022)" = "solid")) +
  labs(x = "Total income before tax",
       y = expression(paste("Density (", "\u00d7", 10^{-6}, ")")),
       color = NULL, linetype = NULL) +
  theme(legend.position = c(0.8, 0.85))

ggsave(file.path(fig_dir, "fig1_density_comparison.pdf"), fig1, width = w, height = h,
       device = pdf)
cat("Figure 1 saved.\n")

## =============================================================================
## FIGURE 2: Year-by-year bunching estimates (event study)
## =============================================================================

ts_plot_data <- bunching_spi[tax_year >= 2005 & !is.na(b_hat)]

# Merge bootstrap SE where available
ts_plot_data <- merge(ts_plot_data, boot_results[, .(tax_year, se)],
                      by = "tax_year", all.x = TRUE)
ts_plot_data[, ci_lower := b_hat - 1.96 * se]
ts_plot_data[, ci_upper := b_hat + 1.96 * se]

fig2 <- ggplot(ts_plot_data, aes(x = tax_year, y = b_hat)) +
  geom_hline(yintercept = 0, color = "gray50", linewidth = 0.4) +
  geom_vline(xintercept = 2012.5, linetype = "dashed", color = "#d73027",
             linewidth = 0.5) +
  annotate("text", x = 2012.7, y = max(ts_plot_data$b_hat, na.rm = TRUE) * 0.95,
           label = "HICBC\nintroduced", hjust = 0, size = 2.8, color = "#d73027") +
  geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper),
                  size = 0.4, fatten = 2,
                  color = fifelse(ts_plot_data$tax_year < 2013, "#2166ac", "#b2182b")) +
  geom_line(color = "gray30", linewidth = 0.3) +
  scale_x_continuous(breaks = seq(2005, 2022, 2)) +
  labs(x = "Tax year (starting)",
       y = expression(hat(b) ~ "(excess mass ratio)")) +
  theme(panel.grid.major.x = element_blank())

ggsave(file.path(fig_dir, "fig2_event_study.pdf"), fig2, width = w, height = h,
       device = pdf)
cat("Figure 2 saved.\n")

## =============================================================================
## FIGURE 3: SPI vs ASHE bunching (channel decomposition)
## =============================================================================

dib_plot <- dib[tax_year >= 2005 & (!is.na(b_spi) | !is.na(b_ashe))]

fig3 <- ggplot(dib_plot, aes(x = tax_year)) +
  geom_hline(yintercept = 0, color = "gray50", linewidth = 0.4) +
  geom_vline(xintercept = 2012.5, linetype = "dashed", color = "#d73027",
             linewidth = 0.5) +
  geom_line(aes(y = b_spi, color = "All taxpayers (SPI)"),
            linewidth = 0.7, na.rm = TRUE) +
  geom_point(aes(y = b_spi, color = "All taxpayers (SPI)"),
             size = 1.5, na.rm = TRUE) +
  geom_line(aes(y = b_ashe, color = "PAYE employees (ASHE)"),
            linewidth = 0.7, na.rm = TRUE) +
  geom_point(aes(y = b_ashe, color = "PAYE employees (ASHE)"),
             size = 1.5, na.rm = TRUE) +
  scale_color_manual(values = c("All taxpayers (SPI)" = "#b2182b",
                                 "PAYE employees (ASHE)" = "#2166ac")) +
  scale_x_continuous(breaks = seq(2005, 2022, 2)) +
  labs(x = "Tax year", y = expression(hat(b) ~ "(excess mass ratio)"),
       color = NULL) +
  theme(legend.position = c(0.25, 0.85))

ggsave(file.path(fig_dir, "fig3_channel_decomposition.pdf"), fig3, width = w, height = h,
       device = pdf)
cat("Figure 3 saved.\n")

## =============================================================================
## FIGURE 4: Child Benefit opt-out rates (administrative evidence)
## =============================================================================

fig4 <- ggplot(cb_admin, aes(x = year, y = families_opted_out_k)) +
  geom_vline(xintercept = 2012.5, linetype = "dashed", color = "#d73027",
             linewidth = 0.5) +
  geom_vline(xintercept = 2024.25, linetype = "dashed", color = "#4daf4a",
             linewidth = 0.5) +
  geom_col(fill = "#2166ac", alpha = 0.7, width = 0.7) +
  annotate("text", x = 2012.7, y = max(cb_admin$families_opted_out_k, na.rm = TRUE) * 0.95,
           label = "HICBC\nintroduced", hjust = 0, size = 2.8, color = "#d73027") +
  annotate("text", x = 2023.4, y = max(cb_admin$families_opted_out_k, na.rm = TRUE) * 0.85,
           label = "Threshold\nraised", hjust = 1, size = 2.8, color = "#4daf4a") +
  scale_x_continuous(breaks = 2013:2024) +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(x = "Year (August snapshot)",
       y = "Families opted out (thousands)") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(fig_dir, "fig4_cb_optout.pdf"), fig4, width = w, height = h,
       device = pdf)
cat("Figure 4 saved.\n")

## =============================================================================
## FIGURE 5: Round-number placebo tests
## =============================================================================

placebo_summary <- placebo_all[, .(mean_b = mean(b_hat, na.rm = TRUE),
                                    se_b = sd(b_hat, na.rm = TRUE) / sqrt(.N)),
                                by = placebo_income]
placebo_summary[, is_notch := placebo_income == 50000]

fig5 <- ggplot(placebo_summary, aes(x = factor(placebo_income / 1000),
                                     y = mean_b, fill = is_notch)) +
  geom_hline(yintercept = 0, color = "gray50", linewidth = 0.4) +
  geom_col(width = 0.6, alpha = 0.8) +
  geom_errorbar(aes(ymin = mean_b - 1.96 * se_b, ymax = mean_b + 1.96 * se_b),
                width = 0.15, linewidth = 0.5) +
  scale_fill_manual(values = c("FALSE" = "#92c5de", "TRUE" = "#b2182b"),
                    guide = "none") +
  labs(x = "Income threshold (\u00a3k)",
       y = expression("Mean " * hat(b) * " (2013\u20132022)")) +
  theme(panel.grid.major.x = element_blank())

ggsave(file.path(fig_dir, "fig5_placebo_roundnumbers.pdf"), fig5, width = w, height = h,
       device = pdf)
cat("Figure 5 saved.\n")

## =============================================================================
## FIGURE C.1 (Appendix): Polynomial degree sensitivity
## =============================================================================

poly_avg <- poly_sens[, .(mean_b = mean(b_hat, na.rm = TRUE),
                           se_b = sd(b_hat, na.rm = TRUE) / sqrt(.N)),
                       by = poly_deg]

figC1 <- ggplot(poly_avg, aes(x = factor(poly_deg), y = mean_b)) +
  geom_hline(yintercept = 0, color = "gray50") +
  geom_col(fill = "#4393c3", alpha = 0.7, width = 0.5) +
  geom_errorbar(aes(ymin = mean_b - 1.96 * se_b, ymax = mean_b + 1.96 * se_b),
                width = 0.15) +
  labs(x = "Polynomial degree", y = expression("Mean " * hat(b))) +
  theme(panel.grid.major.x = element_blank())

ggsave(file.path(fig_dir, "figC1_polynomial_sensitivity.pdf"), figC1,
       width = 5, height = 3.5, device = pdf)
cat("Figure C.1 saved.\n")

## =============================================================================
## FIGURE C.2 (Appendix): Exclusion window sensitivity
## =============================================================================

win_avg <- window_sens[, .(mean_b = mean(b_hat, na.rm = TRUE),
                            se_b = sd(b_hat, na.rm = TRUE) / sqrt(.N)),
                        by = window]
win_avg[, window := factor(window, levels = c("pm3k", "pm5k", "pm7k", "pm10k"),
                           labels = c("\u00b1\u00a33k", "\u00b1\u00a35k",
                                      "\u00b1\u00a37k", "\u00b1\u00a310k"))]

figC2 <- ggplot(win_avg, aes(x = window, y = mean_b)) +
  geom_hline(yintercept = 0, color = "gray50") +
  geom_col(fill = "#4393c3", alpha = 0.7, width = 0.5) +
  geom_errorbar(aes(ymin = mean_b - 1.96 * se_b, ymax = mean_b + 1.96 * se_b),
                width = 0.15) +
  labs(x = "Exclusion window", y = expression("Mean " * hat(b))) +
  theme(panel.grid.major.x = element_blank())

ggsave(file.path(fig_dir, "figC2_window_sensitivity.pdf"), figC2,
       width = 5, height = 3.5, device = pdf)
cat("Figure C.2 saved.\n")

## =============================================================================
## FIGURE C.3 (Appendix): Gender decomposition at £50k
## =============================================================================

if (ncol(gender_50k) >= 3 && "Male" %in% names(gender_50k)) {
  gender_long <- melt(gender_50k[year >= 2005 & year <= 2022], id.vars = "year",
                      variable.name = "sex", value.name = "density")

  figC3 <- ggplot(gender_long[!is.na(density)], aes(x = year, y = density * 1e6,
                                                      color = sex)) +
    geom_vline(xintercept = 2012.5, linetype = "dashed", color = "#d73027") +
    geom_line(linewidth = 0.7) +
    geom_point(size = 1.5) +
    scale_color_manual(values = c("Male" = "#2166ac", "Female" = "#d6604d")) +
    labs(x = "Year", y = expression(paste("Density at \u00a350k (", "\u00d7", 10^{-6}, ")")),
         color = NULL) +
    theme(legend.position = c(0.85, 0.85))

  ggsave(file.path(fig_dir, "figC3_gender_density.pdf"), figC3,
         width = 5, height = 3.5, device = pdf)
  cat("Figure C.3 saved.\n")
}

cat("\nAll figures saved to", fig_dir, "\n")
