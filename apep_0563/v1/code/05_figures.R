## ============================================================================
## 05_figures.R — All Figure Generation
## Japan Dual-Rate Consumption Tax Paper (apep_0563)
## ============================================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

cpi <- fread(file.path(data_dir, "cpi_analysis.csv"))
cpi[, date := as.Date(date)]
es_coefs <- fread(file.path(data_dir, "event_study_coefs.csv"))

## Palette
eat_in_color   <- "#E63946"
takeout_color  <- "#457B9D"
alcohol_color  <- "#2A9D8F"

## ============================================================================
## FIGURE 1: CPI Indices by Food Category (2015-2024)
## ============================================================================
cat("=== Figure 1: CPI Time Series ===\n")

cpi_plot <- melt(cpi, id.vars = c("date", "yyyymm"),
                 measure.vars = c("eating_out", "cooked_food", "alcoholic_beverages"),
                 variable.name = "category", value.name = "index")
cpi_plot[, category_label := factor(category,
  levels = c("eating_out", "cooked_food", "alcoholic_beverages"),
  labels = c("Eating out (10%)", "Cooked food (8%)", "Alcoholic beverages (10%)"))]

p1 <- ggplot(cpi_plot, aes(x = date, y = index, color = category_label)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = as.Date("2019-10-01"), linetype = "dashed",
             color = "gray40", linewidth = 0.6) +
  annotate("text", x = as.Date("2019-10-01"), y = max(cpi_plot$index, na.rm = TRUE) + 1,
           label = "Oct 2019\nDual-rate reform", size = 3, hjust = -0.05, color = "gray30") +
  annotate("rect", xmin = as.Date("2020-02-01"), xmax = as.Date("2020-06-01"),
           ymin = -Inf, ymax = Inf, alpha = 0.1, fill = "gray50") +
  annotate("text", x = as.Date("2020-04-01"), y = min(cpi_plot$index, na.rm = TRUE) - 1,
           label = "COVID-19", size = 2.5, color = "gray40") +
  scale_color_manual(values = c(eat_in_color, takeout_color, alcohol_color)) +
  labs(x = NULL, y = "CPI Index (2020 = 100)",
       title = "Consumer Price Indices by Food Category",
       subtitle = "Monthly, chain-linked (2020 base). Tax rates in parentheses.",
       color = NULL) +
  theme(legend.position = "bottom") +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y")

ggsave(file.path(fig_dir, "fig1_cpi_timeseries.pdf"), p1, width = 8, height = 5)
ggsave(file.path(fig_dir, "fig1_cpi_timeseries.png"), p1, width = 8, height = 5, dpi = 300)

## ============================================================================
## FIGURE 2: Relative Price (Eating Out / Cooked Food)
## ============================================================================
cat("=== Figure 2: Relative Price ===\n")

p2 <- ggplot(cpi, aes(x = date, y = relative_eatin_takeout)) +
  geom_line(color = eat_in_color, linewidth = 0.8) +
  geom_vline(xintercept = as.Date("2019-10-01"), linetype = "dashed",
             color = "gray40", linewidth = 0.6) +
  annotate("text", x = as.Date("2019-10-01"), y = max(cpi$relative_eatin_takeout) + 0.3,
           label = "Oct 2019\nDual-rate reform", size = 3, hjust = -0.05, color = "gray30") +
  annotate("rect", xmin = as.Date("2020-02-01"), xmax = as.Date("2020-06-01"),
           ymin = -Inf, ymax = Inf, alpha = 0.1, fill = "gray50") +
  labs(x = NULL, y = "Relative Price Index\n(Eating Out / Cooked Food × 100)",
       title = "Relative Price of Eat-in vs. Takeout Food",
       subtitle = "A persistent upward shift indicates differential tax pass-through") +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y")

ggsave(file.path(fig_dir, "fig2_relative_price.pdf"), p2, width = 8, height = 5)
ggsave(file.path(fig_dir, "fig2_relative_price.png"), p2, width = 8, height = 5, dpi = 300)

## ============================================================================
## FIGURE 3: Event Study
## ============================================================================
cat("=== Figure 3: Event Study ===\n")

p3 <- ggplot(es_coefs, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, color = "gray60", linewidth = 0.4) +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "gray40") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = eat_in_color) +
  geom_point(color = eat_in_color, size = 1.5) +
  geom_line(color = eat_in_color, linewidth = 0.5) +
  annotate("text", x = -0.5, y = max(es_coefs$ci_upper, na.rm = TRUE) * 1.1,
           label = "Treatment", size = 3, hjust = 1.1, color = "gray30") +
  labs(x = "Months Relative to October 2019",
       y = "Coefficient (log relative price)",
       title = "Event Study: Relative Price of Eat-in vs. Takeout Food",
       subtitle = "Omitted period: September 2019 (t = -1). 95% CIs with Newey-West SEs.") +
  scale_x_continuous(breaks = seq(-24, 24, 6))

ggsave(file.path(fig_dir, "fig3_event_study.pdf"), p3, width = 8, height = 5)
ggsave(file.path(fig_dir, "fig3_event_study.png"), p3, width = 8, height = 5, dpi = 300)

## ============================================================================
## FIGURE 4: Tax Pass-Through Decomposition (Bar Chart)
## ============================================================================
cat("=== Figure 4: Pass-Through Decomposition ===\n")

magnitude <- fread(file.path(data_dir, "magnitude_decomposition.csv"))

# Month-over-month at impact
mom <- magnitude[1]
pass_data <- data.table(
  Category = c("Eating out\n(10% rate)", "Cooked food\n(8% rate)",
               "Alcohol\n(10% rate)", "Predicted\ndifferential"),
  Change = c(mom$eating_out_pct, mom$cooked_food_pct,
             mom$alcohol_pct, 1.85),
  Type = c("Observed", "Observed", "Observed", "Predicted")
)

p4 <- ggplot(pass_data, aes(x = Category, y = Change, fill = Type)) +
  geom_col(width = 0.6) +
  geom_hline(yintercept = 0, color = "gray60") +
  scale_fill_manual(values = c("Observed" = eat_in_color, "Predicted" = "gray70")) +
  labs(x = NULL, y = "Price Change (%)\nOctober vs. September 2019",
       title = "Tax Pass-Through at Impact",
       subtitle = "Month-over-month price change at the dual-rate reform",
       fill = NULL) +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig4_passthrough.pdf"), p4, width = 6, height = 5)
ggsave(file.path(fig_dir, "fig4_passthrough.png"), p4, width = 6, height = 5, dpi = 300)

## ============================================================================
## FIGURE 5: Bandwidth Sensitivity
## ============================================================================
cat("=== Figure 5: Bandwidth Sensitivity ===\n")

bw <- fread(file.path(data_dir, "bandwidth_sensitivity.csv"))
bw <- bw[!is.na(se)]  # Remove ±6 which has no SE

p5 <- ggplot(bw, aes(x = factor(bandwidth), y = estimate)) +
  geom_hline(yintercept = 0, color = "gray60") +
  geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper),
                  color = eat_in_color, size = 0.5) +
  labs(x = "Bandwidth (months pre and post)",
       y = "DD Estimate\n(log relative price)",
       title = "Sensitivity to Bandwidth Choice",
       subtitle = "Point estimates with 95% CIs (Newey-West SEs)")

ggsave(file.path(fig_dir, "fig5_bandwidth.pdf"), p5, width = 6, height = 4)
ggsave(file.path(fig_dir, "fig5_bandwidth.png"), p5, width = 6, height = 4, dpi = 300)

## ============================================================================
## FIGURE 6: Pre-Period Trends (Triple Comparison)
## ============================================================================
cat("=== Figure 6: Pre-period Trends ===\n")

# Normalize all three series to Jan 2017 = 100
base_date <- as.Date("2017-01-01")
cpi_norm <- copy(cpi)
base_vals <- cpi_norm[date == base_date]
cpi_norm[, eating_out_norm := eating_out / base_vals$eating_out * 100]
cpi_norm[, cooked_food_norm := cooked_food / base_vals$cooked_food * 100]
cpi_norm[, alcohol_norm := alcoholic_beverages / base_vals$alcoholic_beverages * 100]

norm_long <- melt(cpi_norm[date >= base_date & date <= as.Date("2021-12-01")],
  id.vars = c("date"),
  measure.vars = c("eating_out_norm", "cooked_food_norm", "alcohol_norm"),
  variable.name = "category", value.name = "index_norm")
norm_long[, category_label := factor(category,
  levels = c("eating_out_norm", "cooked_food_norm", "alcohol_norm"),
  labels = c("Eating out (10%)", "Cooked food (8%)", "Alcohol (10%)"))]

p6 <- ggplot(norm_long, aes(x = date, y = index_norm, color = category_label)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = as.Date("2019-10-01"), linetype = "dashed", color = "gray40") +
  scale_color_manual(values = c(eat_in_color, takeout_color, alcohol_color)) +
  labs(x = NULL, y = "Index (January 2017 = 100)",
       title = "Food Category CPI Trends",
       subtitle = "Parallel trends in the pre-period, divergence after October 2019",
       color = NULL) +
  theme(legend.position = "bottom") +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y")

ggsave(file.path(fig_dir, "fig6_pretrends.pdf"), p6, width = 8, height = 5)
ggsave(file.path(fig_dir, "fig6_pretrends.png"), p6, width = 8, height = 5, dpi = 300)

## ============================================================================
## FIGURE 7: Placebo-in-Time Distribution
## ============================================================================
cat("=== Figure 7: Placebo-in-Time Distribution ===\n")

placebo_dist <- fread(file.path(data_dir, "placebo_distribution.csv"))
placebo_dist[, is_treatment := placebo_month == 201910]

p7 <- ggplot(placebo_dist, aes(x = estimate)) +
  geom_histogram(data = placebo_dist[is_treatment == FALSE],
                 bins = 20, fill = "gray70", color = "white", alpha = 0.8) +
  geom_vline(xintercept = placebo_dist[is_treatment == TRUE, estimate],
             color = eat_in_color, linewidth = 1.2, linetype = "solid") +
  annotate("text", x = placebo_dist[is_treatment == TRUE, estimate] + 0.001,
           y = Inf, vjust = 2, hjust = 0,
           label = "Oct 2019\n(actual reform)", color = eat_in_color, size = 3.5) +
  labs(x = "DD Estimate (log relative price)",
       y = "Count",
       title = "Placebo-in-Time Distribution",
       subtitle = "DD estimates at every pre-period month vs. actual October 2019") +
  geom_hline(yintercept = 0, color = "gray60")

ggsave(file.path(fig_dir, "fig7_placebo_dist.pdf"), p7, width = 7, height = 4)
ggsave(file.path(fig_dir, "fig7_placebo_dist.png"), p7, width = 7, height = 4, dpi = 300)

cat("\n✓ All figures generated.\n")
