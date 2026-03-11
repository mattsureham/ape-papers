# ==============================================================================
# 05_figures.R — Generate all figures
# Paper: Trade Protection by Fiat (apep_0595)
# ==============================================================================

source("00_packages.R")

# --- Load data ---
nga_rice <- fread(file.path(DATA_DIR, "nga_rice.csv"))
nga_rice[, year_month := as.Date(year_month)]
market_coords <- fread(file.path(DATA_DIR, "market_coords.csv"))
es_coefs <- fread(file.path(DATA_DIR, "event_study_coefs.csv"))
commodity_results <- fread(file.path(DATA_DIR, "commodity_results.csv"))
lomo_dt <- fread(file.path(DATA_DIR, "robustness_lomo.csv"))
ri_dist <- fread(file.path(DATA_DIR, "ri_distribution.csv"))
ri_summary <- fread(file.path(DATA_DIR, "robustness_ri.csv"))

# ==============================================================================
# FIGURE 1: Treatment timing and market map
# ==============================================================================

# Panel A: Map of Nigerian markets with border/interior classification
fig1a <- ggplot(market_coords, aes(x = lon, y = lat)) +
  geom_point(aes(color = factor(border_market)),
             size = 3, alpha = 0.7) +
  scale_color_manual(values = c("0" = "steelblue", "1" = "firebrick"),
                     labels = c("Interior (>150km)", "Border (<150km)"),
                     name = "Market Type") +
  labs(title = "Nigerian Market Locations",
       subtitle = "WFP price monitoring markets classified by distance to land border",
       x = "Longitude", y = "Latitude") +
  theme_apep() +
  theme(legend.position = "right")

ggsave(file.path(FIG_DIR, "fig1a_market_map.pdf"), fig1a, width = 8, height = 6)

# Panel B: Average rice prices by border/interior over time
rice_trends <- nga_rice[, .(mean_price = mean(price_per_kg, na.rm = TRUE),
                            mean_log_price = mean(log_price, na.rm = TRUE),
                            n_markets = n_distinct(market)),
                        by = .(year_month, border_market)]

fig1b <- ggplot(rice_trends, aes(x = year_month, y = mean_log_price,
                                  color = factor(border_market))) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.2) +
  geom_vline(xintercept = as.Date("2019-08-01"), linetype = "dashed",
             color = "grey30", linewidth = 0.8) +
  annotate("text", x = as.Date("2019-09-01"), y = Inf,
           label = "Border Closure\nAug 2019", hjust = 0, vjust = 1.5,
           size = 3, color = "grey30") +
  annotate("text", x = as.Date("2020-12-15"), y = Inf,
           label = "Partial\nReopening", hjust = 0.5, vjust = 1.5,
           size = 2.5, color = "grey50") +
  geom_vline(xintercept = as.Date("2020-12-01"), linetype = "dotted",
             color = "grey50") +
  scale_color_manual(values = c("0" = "steelblue", "1" = "firebrick"),
                     labels = c("Interior Markets (>150km)",
                                "Border Markets (<150km)"),
                     name = "") +
  labs(title = "Average Rice Prices by Market Type",
       subtitle = "Log price (NGN/kg), monthly averages",
       x = "", y = "Log(Price)") +
  theme_apep()

ggsave(file.path(FIG_DIR, "fig1b_price_trends.pdf"), fig1b, width = 8, height = 5)

# Combined Figure 1
fig1 <- fig1a / fig1b +
  plot_annotation(title = "Treatment Design and Raw Price Trends",
                  theme = theme(plot.title = element_text(face = "bold", size = 14)))

ggsave(file.path(FIG_DIR, "fig1_design.pdf"), fig1, width = 8, height = 11)

# ==============================================================================
# FIGURE 2: Event study
# ==============================================================================

fig2 <- ggplot(es_coefs, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey30") +
  geom_ribbon(aes(ymin = estimate - 1.96 * se,
                  ymax = estimate + 1.96 * se),
              fill = "steelblue", alpha = 0.2) +
  geom_point(color = "steelblue", size = 2) +
  geom_line(color = "steelblue", linewidth = 0.6) +
  annotate("text", x = -6, y = Inf, label = "Pre-Closure",
           hjust = 0.5, vjust = 1.5, size = 3.5, fontface = "italic") +
  annotate("text", x = 8, y = Inf, label = "Post-Closure",
           hjust = 0.5, vjust = 1.5, size = 3.5, fontface = "italic") +
  labs(title = "Event Study: Effect of Border Closure on Rice Prices",
       subtitle = "Coefficients on Border Market × Event Time interactions, relative to t = -1",
       x = "Months Relative to Border Closure (August 2019)",
       y = "Coefficient (Log Price)",
       caption = "Notes: 95% confidence intervals shown. Standard errors clustered at market level.\nReference period: one month before closure (t = -1). Market and month fixed effects included.") +
  scale_x_continuous(breaks = seq(-12, 17, by = 3)) +
  theme_apep()

ggsave(file.path(FIG_DIR, "fig2_event_study.pdf"), fig2, width = 8, height = 5.5)

# ==============================================================================
# FIGURE 3: Commodity heterogeneity
# ==============================================================================

if (nrow(commodity_results) > 0) {
  commodity_results[, commodity := factor(commodity,
    levels = c("rice", "maize", "sorghum", "millet"))]

  fig3 <- ggplot(commodity_results[!is.na(estimate)],
                 aes(x = commodity, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_point(size = 3, color = "steelblue") +
    geom_errorbar(aes(ymin = estimate - 1.96 * se,
                      ymax = estimate + 1.96 * se),
                  width = 0.15, color = "steelblue") +
    labs(title = "Effect of Border Closure by Commodity",
         subtitle = "DiD estimates: Border Market × Post, each commodity estimated separately",
         x = "",
         y = "Coefficient (Log Price)",
         caption = "Notes: 95% confidence intervals shown. Standard errors clustered at market level.\nMarket and month fixed effects included. Reference: interior markets (>150km from border).") +
    theme_apep()

  ggsave(file.path(FIG_DIR, "fig3_commodity_heterogeneity.pdf"), fig3, width = 7, height = 5)
}

# ==============================================================================
# FIGURE 4: Distance gradient
# ==============================================================================

bin_coefs <- fread(file.path(DATA_DIR, "distance_bin_coefs.csv"))

if (nrow(bin_coefs) > 0) {
  setnames(bin_coefs, old = c("Estimate", "Std. Error"), new = c("estimate", "se"),
           skip_absent = TRUE)
  bin_coefs[, dist_bin := gsub(".*::(.*):post.*", "\\1", term)]
  bin_coefs <- bin_coefs[dist_bin %in% c("0-100km", "100-200km")]
  bin_coefs[, dist_bin := factor(dist_bin,
    levels = c("0-100km", "100-200km"))]

  fig4 <- ggplot(bin_coefs[!is.na(dist_bin)],
                 aes(x = dist_bin, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_point(size = 3, color = "firebrick") +
    geom_errorbar(aes(ymin = estimate - 1.96 * se,
                      ymax = estimate + 1.96 * se),
                  width = 0.15, color = "firebrick") +
    labs(title = "Distance Gradient: Price Effects by Proximity to Border",
         subtitle = "Reference category: 200+ km from border",
         x = "Distance to Nearest Land Border",
         y = "Coefficient (Log Price)",
         caption = "Notes: 95% confidence intervals shown. Standard errors clustered at market level.\nMarket and month fixed effects included.") +
    theme_apep()

  ggsave(file.path(FIG_DIR, "fig4_distance_gradient.pdf"), fig4, width = 7, height = 5)
}

# ==============================================================================
# FIGURE 5: Randomization inference
# ==============================================================================

actual_est <- ri_summary$actual_estimate

fig5 <- ggplot(ri_dist, aes(x = perm_estimate)) +
  geom_histogram(bins = 50, fill = "grey70", color = "grey90") +
  geom_vline(xintercept = actual_est, color = "firebrick",
             linewidth = 1, linetype = "solid") +
  annotate("text", x = actual_est, y = Inf,
           label = paste0("Actual estimate\np = ",
                          round(ri_summary$ri_p_value, 3)),
           hjust = -0.1, vjust = 1.5, color = "firebrick",
           size = 3.5, fontface = "bold") +
  labs(title = "Randomization Inference Distribution",
       subtitle = paste0("1,000 permutations of border/interior market assignment"),
       x = "Permuted DiD Estimate",
       y = "Count",
       caption = "Notes: Distribution of DiD estimates under random assignment of border/interior\nstatus across markets. Vertical line shows actual estimate.") +
  theme_apep()

ggsave(file.path(FIG_DIR, "fig5_ri_distribution.pdf"), fig5, width = 7, height = 5)

# ==============================================================================
# FIGURE 6: Leave-one-market-out stability
# ==============================================================================

# Get main estimate
m_main <- readRDS(file.path(DATA_DIR, "model_main_basic.rds"))
main_est <- coef(m_main)["border_market:post"]

fig6 <- ggplot(lomo_dt, aes(x = reorder(dropped_market, estimate), y = estimate)) +
  geom_hline(yintercept = main_est, color = "steelblue",
             linewidth = 0.8, linetype = "dashed") +
  geom_point(size = 1.5, color = "grey30") +
  geom_errorbar(aes(ymin = estimate - 1.96 * se,
                    ymax = estimate + 1.96 * se),
                width = 0.3, color = "grey50", linewidth = 0.3) +
  labs(title = "Leave-One-Market-Out Stability",
       subtitle = "Each point: DiD estimate dropping one market from the sample",
       x = "Dropped Market",
       y = "Coefficient (Log Price)",
       caption = "Notes: Dashed line shows full-sample estimate. 95% CIs shown.") +
  theme_apep() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, size = 6))

ggsave(file.path(FIG_DIR, "fig6_lomo.pdf"), fig6, width = 10, height = 5)

cat("All figures saved to:", FIG_DIR, "\n")
