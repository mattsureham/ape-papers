## =============================================================================
## 05_figures.R — Generate all figures
## =============================================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

## ---------------------------------------------------------------------------
## Figure 1: Map of Nigeria showing terminals, markets, and distances
## ---------------------------------------------------------------------------

cat("=== Figure 1: Map ===\n")

market_dists <- fread(file.path(data_dir, "market_distances.csv"))
terminals <- fread(file.path(data_dir, "terminals.csv"))

fig1 <- ggplot() +
  geom_point(data = market_dists,
             aes(x = lon, y = lat, color = dist_nearest, size = 2),
             alpha = 0.7, show.legend = TRUE) +
  geom_point(data = terminals,
             aes(x = lon, y = lat), shape = 17, size = 5, color = "red") +
  geom_text(data = terminals,
            aes(x = lon, y = lat, label = terminal),
            hjust = -0.2, vjust = -0.5, size = 3, fontface = "bold") +
  scale_color_viridis_c(name = "Distance to\nNearest Terminal\n(km)",
                         option = "plasma") +
  labs(title = "Panel A: Markets and Petroleum Import Terminals",
       x = "Longitude", y = "Latitude") +
  guides(size = "none") +
  theme(legend.position = "right")

ggsave(file.path(fig_dir, "fig1_map.pdf"), fig1, width = 8, height = 6)
cat("Figure 1 saved.\n")

## ---------------------------------------------------------------------------
## Figure 2: Event study — Petrol price × distance interaction
## ---------------------------------------------------------------------------

cat("=== Figure 2: Event Study ===\n")

es_coefs <- fread(file.path(data_dir, "event_study_petrol.csv"))

fig2 <- ggplot(es_coefs, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", alpha = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "steelblue", alpha = 0.2) +
  geom_point(color = "steelblue", size = 2) +
  geom_line(color = "steelblue", linewidth = 0.5) +
  annotate("text", x = -6, y = max(es_coefs$ci_hi, na.rm = TRUE) * 0.9,
           label = "Pre-reform", hjust = 0.5, size = 3.5, color = "gray40") +
  annotate("text", x = 8, y = max(es_coefs$ci_hi, na.rm = TRUE) * 0.9,
           label = "Post-reform", hjust = 0.5, size = 3.5, color = "gray40") +
  scale_x_continuous(breaks = seq(-12, 18, 3)) +
  labs(
    title = "Effect of Distance on Petrol Prices Over Time",
    subtitle = "Coefficient on Distance (100km) × Month Dummies, relative to t = −1",
    x = "Months Relative to Subsidy Removal (June 2023)",
    y = expression(beta[t] ~ "(Log Petrol Price × Distance)")
  )

ggsave(file.path(fig_dir, "fig2_event_study.pdf"), fig2, width = 8, height = 5)
cat("Figure 2 saved.\n")

## ---------------------------------------------------------------------------
## Figure 3: Petrol price time series by distance tercile
## ---------------------------------------------------------------------------

cat("=== Figure 3: Price Trajectories ===\n")

rtep <- fread(file.path(data_dir, "rtep_clean.csv"))
rtep[, date := as.Date(date)]

# Create distance terciles
market_dists_rtep <- unique(rtep[, .(mkt_name, dist_nearest)])
market_dists_rtep[, dist_tercile := cut(dist_nearest,
                                         breaks = quantile(dist_nearest, c(0, 1/3, 2/3, 1)),
                                         labels = c("Close (<Q33)", "Middle", "Far (>Q67)"),
                                         include.lowest = TRUE)]
rtep <- merge(rtep, market_dists_rtep[, .(mkt_name, dist_tercile)],
              by = "mkt_name", all.x = TRUE)

# Monthly averages by tercile
tercile_avg <- rtep[, .(
  avg_price = mean(o_fuel_petrol_gasoline, na.rm = TRUE),
  se_price = sd(o_fuel_petrol_gasoline, na.rm = TRUE) / sqrt(.N)
), by = .(date, dist_tercile)]

fig3 <- ggplot(tercile_avg, aes(x = date, y = avg_price, color = dist_tercile,
                                 fill = dist_tercile)) +
  geom_vline(xintercept = as.Date("2023-05-29"), linetype = "dashed",
             color = "red", alpha = 0.5) +
  geom_ribbon(aes(ymin = avg_price - 1.96 * se_price,
                  ymax = avg_price + 1.96 * se_price), alpha = 0.15, color = NA) +
  geom_line(linewidth = 1) +
  annotate("text", x = as.Date("2023-05-29"), y = max(tercile_avg$avg_price) * 1.05,
           label = "Subsidy\nRemoved", hjust = 1.1, size = 3, color = "red") +
  scale_color_manual(values = c("#2166AC", "#F4A582", "#B2182B"),
                     name = "Distance\nTercile") +
  scale_fill_manual(values = c("#2166AC", "#F4A582", "#B2182B"),
                    name = "Distance\nTercile") +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +
  labs(
    title = "Petrol Prices Diverge by Distance After Subsidy Removal",
    subtitle = "Monthly average PMS price by distance tercile (from nearest import terminal)",
    x = "", y = "Average PMS Price (₦/Litre)"
  )

ggsave(file.path(fig_dir, "fig3_price_trajectories.pdf"), fig3, width = 9, height = 5.5)
cat("Figure 3 saved.\n")

## ---------------------------------------------------------------------------
## Figure 4: Cross-sectional scatter — distance vs. price change
## ---------------------------------------------------------------------------

cat("=== Figure 4: Distance-Price Gradient ===\n")

# Average price pre vs post by market
market_changes <- rtep[, .(
  pre_price = mean(o_fuel_petrol_gasoline[post == 0], na.rm = TRUE),
  post_price = mean(o_fuel_petrol_gasoline[post == 1], na.rm = TRUE),
  dist_nearest = first(dist_nearest),
  state = first(adm1_name)
), by = mkt_name]
market_changes[, price_change := post_price - pre_price]
market_changes[, pct_change := (post_price / pre_price - 1) * 100]

fig4 <- ggplot(market_changes, aes(x = dist_nearest, y = pct_change)) +
  geom_point(aes(color = state), size = 3, alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, color = "black", linewidth = 1) +
  labs(
    title = "Markets Farther from Terminals Experience Larger Price Increases",
    subtitle = "Percentage change in average PMS price (pre vs. post reform)",
    x = "Distance to Nearest Import Terminal (km)",
    y = "PMS Price Change (%)"
  ) +
  theme(legend.position = "right",
        legend.text = element_text(size = 8))

ggsave(file.path(fig_dir, "fig4_scatter.pdf"), fig4, width = 9, height = 6)
fwrite(market_changes, file.path(data_dir, "market_changes.csv"))
cat("Figure 4 saved.\n")

## ---------------------------------------------------------------------------
## Figure 5: Leave-one-out stability
## ---------------------------------------------------------------------------

cat("=== Figure 5: Leave-One-Out ===\n")

loo_dt <- fread(file.path(data_dir, "robustness_loo.csv"))

# Get full sample estimate for reference
load(file.path(data_dir, "main_models.RData"))
full_est <- coef(m_a2)["dist_post_100"]
full_se <- se(m_a2)["dist_post_100"]

fig5 <- ggplot(loo_dt, aes(x = reorder(dropped_state, estimate), y = estimate)) +
  geom_hline(yintercept = full_est, linetype = "solid", color = "steelblue") +
  geom_hline(yintercept = full_est + 1.96 * full_se, linetype = "dashed",
             color = "steelblue", alpha = 0.5) +
  geom_hline(yintercept = full_est - 1.96 * full_se, linetype = "dashed",
             color = "steelblue", alpha = 0.5) +
  geom_point(size = 2.5) +
  geom_errorbar(aes(ymin = estimate - 1.96 * se, ymax = estimate + 1.96 * se),
                width = 0.3) +
  coord_flip() +
  labs(
    title = "Results Robust to Dropping Any Single State",
    subtitle = "Leave-one-out estimates; blue line = full sample; dashed = 95% CI",
    x = "State Dropped", y = "Coefficient on Post × Distance (100km)"
  )

ggsave(file.path(fig_dir, "fig5_loo.pdf"), fig5, width = 7, height = 6)
cat("Figure 5 saved.\n")

## ---------------------------------------------------------------------------
## Figure 6: Randomization inference distribution
## ---------------------------------------------------------------------------

cat("=== Figure 6: Randomization Inference ===\n")

ri_dist <- fread(file.path(data_dir, "ri_distribution.csv"))
ri_result <- fread(file.path(data_dir, "robustness_ri.csv"))

fig6 <- ggplot(ri_dist, aes(x = perm_coef)) +
  geom_histogram(bins = 50, fill = "gray70", color = "gray50") +
  geom_vline(xintercept = ri_result$actual_coef, color = "red",
             linewidth = 1.2, linetype = "solid") +
  annotate("text", x = ri_result$actual_coef, y = Inf,
           label = paste0("Actual = ", round(ri_result$actual_coef, 4),
                          "\nRI p = ", round(ri_result$ri_p_value, 3)),
           hjust = -0.1, vjust = 1.5, color = "red", size = 3.5) +
  labs(
    title = "Randomization Inference: Actual Estimate vs. Permutation Distribution",
    subtitle = paste0(ri_result$n_perms, " permutations of market-distance assignments"),
    x = "Coefficient on Post × Distance (100km)",
    y = "Count"
  )

ggsave(file.path(fig_dir, "fig6_ri.pdf"), fig6, width = 8, height = 5)
cat("Figure 6 saved.\n")

## ---------------------------------------------------------------------------
## Figure 7: Food price pass-through by commodity group
## ---------------------------------------------------------------------------

cat("=== Figure 7: Food Price Heterogeneity ===\n")

wfp <- fread(file.path(data_dir, "wfp_clean.csv"))
wfp[, date := as.Date(date)]
wfp_food <- wfp[is_fuel == FALSE & !is.na(dist_nearest)]

# Run regressions by commodity group
groups <- unique(wfp_food[commodity_group != "Other"]$commodity_group)
group_results <- list()

for (g in groups) {
  m <- tryCatch({
    feols(log_price ~ dist_post_100 | market_commodity + date,
          data = wfp_food[commodity_group == g], cluster = ~admin1)
  }, error = function(e) NULL)

  if (!is.null(m)) {
    group_results[[g]] <- data.table(
      group = g,
      estimate = coef(m)["dist_post_100"],
      se = se(m)["dist_post_100"],
      n = nobs(m)
    )
  }
}

group_dt <- rbindlist(group_results)
group_dt[, ci_lo := estimate - 1.96 * se]
group_dt[, ci_hi := estimate + 1.96 * se]
group_dt[, significant := as.integer(ci_lo > 0 | ci_hi < 0)]

fig7 <- ggplot(group_dt, aes(x = reorder(group, estimate), y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_point(aes(color = factor(significant)), size = 3) +
  geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi,
                    color = factor(significant)), width = 0.2) +
  scale_color_manual(values = c("0" = "gray50", "1" = "steelblue"),
                     guide = "none") +
  coord_flip() +
  labs(
    title = "Food Price Pass-Through by Commodity Group",
    subtitle = "Effect of Post × Distance (100km) on log food prices",
    x = "", y = "Coefficient on Post × Distance (100km)"
  )

ggsave(file.path(fig_dir, "fig7_food_hetero.pdf"), fig7, width = 7, height = 5)
fwrite(group_dt, file.path(data_dir, "food_group_estimates.csv"))
cat("Figure 7 saved.\n")

## ---------------------------------------------------------------------------
## Figure 8: Event study — Food prices (Cereals) × distance interaction
## ---------------------------------------------------------------------------

cat("=== Figure 8: Food Event Study (Cereals) ===\n")

es_food_coefs <- fread(file.path(data_dir, "event_study_food_cereals.csv"))

fig8 <- ggplot(es_food_coefs, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red", alpha = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "steelblue", alpha = 0.2) +
  geom_point(color = "steelblue", size = 2) +
  geom_line(color = "steelblue", linewidth = 0.5) +
  annotate("text", x = -9, y = max(es_food_coefs$ci_hi, na.rm = TRUE) * 0.9,
           label = "Pre-reform", hjust = 0.5, size = 3.5, color = "gray40") +
  annotate("text", x = 9, y = max(es_food_coefs$ci_hi, na.rm = TRUE) * 0.9,
           label = "Post-reform", hjust = 0.5, size = 3.5, color = "gray40") +
  scale_x_continuous(breaks = seq(-18, 18, 3)) +
  labs(
    title = "Effect of Distance on Cereal Prices Over Time",
    subtitle = "Coefficient on Distance (100km) × Month Dummies, relative to t = −1",
    x = "Months Relative to Subsidy Removal (June 2023)",
    y = expression(beta[t] ~ "(Log Cereal Price × Distance)")
  )

ggsave(file.path(fig_dir, "fig8_food_event_study.pdf"), fig8, width = 8, height = 5)
cat("Figure 8 saved.\n")

cat("\n=== All figures generated ===\n")
