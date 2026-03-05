# ==============================================================================
# 05_figures.R — All figure generation
# apep_0532: Extreme Weather and Climate Beliefs in India
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))

# ==============================================================================
# Figure 1: Google Trends climate search over time (national + selected states)
# ==============================================================================
cat("Figure 1: Time series of climate search interest\n")

# National trends
gt_nat <- fread(file.path(data_dir, "google_trends_national.csv"))
gt_nat[, hits_num := as.numeric(ifelse(hits == "<1", 0.5, hits))]
gt_nat[, date := as.Date(date)]
gt_nat_climate <- gt_nat[keyword %in% c("global warming", "climate change"),
  .(search = mean(hits_num, na.rm = TRUE)),
  by = date
]

# State-level: pick 4 illustrative states (high/low ag, high/low internet)
illustrative_states <- c("Maharashtra", "Kerala", "Bihar", "Rajasthan")
state_ts <- panel[state %in% illustrative_states,
  .(climate_search = mean(climate_search, na.rm = TRUE),
    tavg_anomaly = mean(tavg_anomaly, na.rm = TRUE)),
  by = .(state, year, month)
]
state_ts[, date := as.Date(paste(year, month, "01", sep = "-"))]

p1a <- ggplot(gt_nat_climate, aes(x = date, y = search)) +
  geom_line(alpha = 0.4) +
  geom_smooth(method = "loess", span = 0.15, se = FALSE, color = "steelblue", linewidth = 1) +
  labs(x = NULL, y = "Google Trends Index",
       title = "A. National Climate Search Interest (India)") +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y")

p1b <- ggplot(state_ts, aes(x = date, y = climate_search, color = state)) +
  geom_line(alpha = 0.5) +
  geom_smooth(method = "loess", span = 0.2, se = FALSE, linewidth = 0.8) +
  labs(x = NULL, y = "Google Trends Index",
       title = "B. State-Level Climate Search Interest",
       color = "State") +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  scale_color_viridis_d()

fig1 <- p1a / p1b
ggsave(file.path(fig_dir, "fig1_time_series.pdf"), fig1,
       width = 8, height = 8, device = cairo_pdf)

# ==============================================================================
# Figure 2: Temperature anomalies over time
# ==============================================================================
cat("Figure 2: Temperature anomalies\n")

wx_annual <- panel[, .(
  tavg_anomaly = mean(tavg_anomaly, na.rm = TRUE),
  heat_share = mean(heat_extreme, na.rm = TRUE)
), by = year]

p2 <- ggplot(wx_annual, aes(x = year, y = tavg_anomaly)) +
  geom_col(aes(fill = tavg_anomaly > 0), alpha = 0.8) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  scale_fill_manual(values = c("TRUE" = "#d73027", "FALSE" = "#4575b4"),
                    labels = c("TRUE" = "Above Normal", "FALSE" = "Below Normal")) +
  labs(x = NULL, y = "Temperature Anomaly (\u00B0C)",
       title = "Annual Mean Temperature Anomaly Across Indian States",
       fill = NULL) +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig2_temp_anomalies.pdf"), p2,
       width = 8, height = 5, device = cairo_pdf)

# ==============================================================================
# Figure 3: Binscatter — Temperature anomaly vs Climate search
# ==============================================================================
cat("Figure 3: Binscatter\n")

# Residualize both variables on state + time FE
panel[, tavg_resid := resid(feols(tavg_anomaly ~ 1 | state_id + time_id, data = .SD))]
panel[, search_resid := resid(feols(climate_search ~ 1 | state_id + time_id, data = .SD))]

# Create bins
n_bins <- 20
panel[, tavg_bin := cut(tavg_resid, breaks = n_bins, labels = FALSE)]
binscatter <- panel[!is.na(tavg_bin), .(
  tavg = mean(tavg_resid, na.rm = TRUE),
  search = mean(search_resid, na.rm = TRUE),
  n = .N
), by = tavg_bin]

p3 <- ggplot(binscatter, aes(x = tavg, y = search)) +
  geom_point(size = 3, color = "steelblue") +
  geom_smooth(method = "lm", se = TRUE, color = "firebrick", linewidth = 0.8) +
  labs(x = "Residualized Temperature Anomaly (\u00B0C)",
       y = "Residualized Climate Search Index",
       title = "Temperature Anomalies and Climate Awareness",
       subtitle = "Binscatter after absorbing state and month-year fixed effects") +
  geom_hline(yintercept = 0, linetype = "dotted", alpha = 0.5) +
  geom_vline(xintercept = 0, linetype = "dotted", alpha = 0.5)

ggsave(file.path(fig_dir, "fig3_binscatter.pdf"), p3,
       width = 7, height = 5, device = cairo_pdf)

# ==============================================================================
# Figure 4: Agricultural amplification — effect by ag share
# ==============================================================================
cat("Figure 4: Agricultural amplification\n")

# Marginal effect at different ag_share values
ag_grid <- seq(0.15, 0.90, by = 0.05)
m5 <- feols(climate_search ~ tavg_anomaly + tavg_x_ag | state_id + time_id,
            data = panel, cluster = ~state_id)

# From model 5: effect = beta_tavg + beta_interaction * ag_share
beta_tavg <- coef(m5)["tavg_anomaly"]
beta_int <- coef(m5)["tavg_x_ag"]
vcov_m5 <- vcov(m5)

marginal_effects <- data.table(
  ag_share = ag_grid,
  effect = beta_tavg + beta_int * ag_grid
)

# Standard error of marginal effect: SE(b1 + b2*x) = sqrt(V(b1) + x^2*V(b2) + 2*x*Cov(b1,b2))
marginal_effects[, se := sqrt(
  vcov_m5["tavg_anomaly", "tavg_anomaly"] +
  ag_share^2 * vcov_m5["tavg_x_ag", "tavg_x_ag"] +
  2 * ag_share * vcov_m5["tavg_anomaly", "tavg_x_ag"]
)]
marginal_effects[, ci_lo := effect - 1.96 * se]
marginal_effects[, ci_hi := effect + 1.96 * se]

fwrite(marginal_effects, file.path(data_dir, "marginal_effects_ag.csv"))

# Add state positions
state_ag <- panel[, .(ag_share = mean(ag_share)), by = state]

p4 <- ggplot(marginal_effects, aes(x = ag_share, y = effect)) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "steelblue", alpha = 0.2) +
  geom_line(color = "steelblue", linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_rug(data = state_ag, aes(x = ag_share, y = NULL), sides = "b", alpha = 0.5) +
  labs(x = "Pre-Period Agricultural Share of Cultivated Area",
       y = "Marginal Effect of 1\u00B0C Temperature Anomaly\non Climate Search Index",
       title = "Agricultural Exposure Amplifies Weather-Beliefs Link",
       subtitle = "States with higher crop dependence show stronger negative responses to warming") +
  annotate("text", x = 0.20, y = 0.8, label = "Urban states:\nwarming increases\nclimate searches",
           size = 3, hjust = 0, color = "grey40") +
  annotate("text", x = 0.75, y = -1.0, label = "Agricultural states:\nwarming decreases\nclimate searches",
           size = 3, hjust = 0, color = "grey40")

ggsave(file.path(fig_dir, "fig4_ag_amplification.pdf"), p4,
       width = 8, height = 5.5, device = cairo_pdf)

# ==============================================================================
# Figure 5: Persistence — Distributed lag coefficients
# ==============================================================================
cat("Figure 5: Persistence\n")

lag_results <- fread(file.path(data_dir, "table4_persistence.csv"))

p5 <- ggplot(lag_results, aes(x = lag, y = coef)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0.5, color = "steelblue") +
  geom_point(size = 3, color = "steelblue") +
  scale_x_continuous(breaks = c(0, 1, 3, 6, 12),
                     labels = c("t", "t-1", "t-3", "t-6", "t-12")) +
  labs(x = "Lag (months)", y = "Coefficient on Temperature Anomaly",
       title = "Persistence of Weather Effects on Climate Search Interest",
       subtitle = "Distributed lag coefficients with 95% CIs (state-clustered)")

ggsave(file.path(fig_dir, "fig5_persistence.pdf"), p5,
       width = 7, height = 5, device = cairo_pdf)

# ==============================================================================
# Figure 6: Map — Agricultural share across states
# ==============================================================================
cat("Figure 6: Crop share variation\n")

crop_shares <- fread(file.path(data_dir, "india_crop_shares.csv"))
crop_long <- melt(crop_shares[, .(state, rice_share, wheat_share, pulse_share,
                                   oilseed_share, cotton_share, sugarcane_share)],
                   id.vars = "state", variable.name = "crop", value.name = "share")
crop_long[, crop := gsub("_share", "", crop)]

p6 <- ggplot(crop_long, aes(x = reorder(state, -share), y = share, fill = crop)) +
  geom_col() +
  coord_flip() +
  scale_fill_viridis_d(option = "D") +
  labs(x = NULL, y = "Share of Cultivated Area",
       title = "Agricultural Crop Composition by State",
       subtitle = "Pre-period (triennium ending 2000) shares used as Bartik weights",
       fill = "Crop") +
  theme(axis.text.y = element_text(size = 8))

ggsave(file.path(fig_dir, "fig6_crop_shares.pdf"), p6,
       width = 8, height = 7, device = cairo_pdf)

cat("\n=== All figures generated ===\n")
cat("Figures saved to:", fig_dir, "\n")
