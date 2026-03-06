# ==============================================================================
# 05_figures.R — All figures
# apep_0532 v2: Economic Structure and Climate Belief Formation
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
models <- readRDS(file.path(data_dir, "all_models.rds"))

# ==============================================================================
# FIGURE 1: Time series — Climate search by agricultural tercile
# ==============================================================================
cat("Figure 1: Time series by ag tercile\n")

panel[, ag_tercile := cut(ag_emp_share,
  breaks = quantile(ag_emp_share, c(0, 1/3, 2/3, 1), na.rm = TRUE),
  labels = c("Low Agriculture", "Medium Agriculture", "High Agriculture"),
  include.lowest = TRUE)]

ts_data <- panel[, .(climate = mean(climate_search, na.rm = TRUE),
                      agricultural = mean(agricultural, na.rm = TRUE)),
                  by = .(year, month, ag_tercile)]
ts_data[, date := as.Date(paste(year, month, "01", sep = "-"))]

fig1 <- ggplot(ts_data[!is.na(ag_tercile)],
               aes(x = date, y = climate, color = ag_tercile)) +
  geom_line(alpha = 0.5) +
  geom_smooth(method = "loess", span = 0.3, se = FALSE, linewidth = 1) +
  scale_color_manual(values = c("Low Agriculture" = "#2166AC",
                                 "Medium Agriculture" = "#999999",
                                 "High Agriculture" = "#B2182B")) +
  labs(x = "", y = "Climate Search Index",
       title = "Climate Search Interest by Agricultural Dependence",
       subtitle = "Google Trends monthly averages by state agricultural employment tercile",
       color = "State Group") +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig1_time_series.pdf"), fig1, width = 8, height = 5)
cat("  Saved fig1_time_series.pdf\n")

# ==============================================================================
# FIGURE 2: Binscatter — Temperature anomaly × Climate search by ag group
# ==============================================================================
cat("Figure 2: Binscatter\n")

# Residualize
panel[, climate_resid := residuals(feols(climate_search ~ 1 | state_id + time_id, data = panel))]
panel[, tavg_resid := residuals(feols(tavg_anomaly ~ 1 | state_id + time_id, data = panel))]

binscatter_data <- panel[!is.na(ag_tercile), {
  bins <- cut(tavg_resid, breaks = 20)
  .SD[, .(y_mean = mean(climate_resid, na.rm = TRUE),
          x_mean = mean(tavg_resid, na.rm = TRUE),
          n = .N), by = bins]
}, by = ag_tercile]

fig2 <- ggplot(binscatter_data, aes(x = x_mean, y = y_mean, color = ag_tercile)) +
  geom_point(aes(size = n), alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 1) +
  scale_color_manual(values = c("Low Agriculture" = "#2166AC",
                                 "Medium Agriculture" = "#999999",
                                 "High Agriculture" = "#B2182B")) +
  scale_size_continuous(range = c(1, 5), guide = "none") +
  labs(x = expression("Residualized Temperature Anomaly (" * degree * "C)"),
       y = "Residualized Climate Search Index",
       title = "Temperature and Climate Search Interest by Agricultural Dependence",
       subtitle = "Binscatter residualized on state and time fixed effects",
       color = "State Group") +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig2_binscatter.pdf"), fig2, width = 7, height = 5.5)
cat("  Saved fig2_binscatter.pdf\n")

# ==============================================================================
# FIGURE 3: Marginal effect plot — Temperature effect at different ag shares
# ==============================================================================
cat("Figure 3: Marginal effect\n")

m_main <- models$ols_main
b_tavg <- coef(m_main)["tavg_anomaly"]
b_int <- coef(m_main)["tavg_x_ag"]
v <- vcov(m_main)

ag_grid <- seq(0, 0.80, by = 0.02)
me_data <- data.table(
  ag_share = ag_grid,
  me = b_tavg + b_int * ag_grid,
  se = sqrt(v["tavg_anomaly", "tavg_anomaly"] +
              ag_grid^2 * v["tavg_x_ag", "tavg_x_ag"] +
              2 * ag_grid * v["tavg_anomaly", "tavg_x_ag"])
)
me_data[, ci_lo := me - 1.96 * se]
me_data[, ci_hi := me + 1.96 * se]

state_ag <- unique(panel[, .(state, ag_emp_share)])

fig3 <- ggplot(me_data, aes(x = ag_share, y = me)) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "#2166AC", alpha = 0.15) +
  geom_line(color = "#2166AC", linewidth = 1.2) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_rug(data = state_ag, aes(x = ag_emp_share, y = NULL),
           sides = "b", color = "#B2182B", alpha = 0.5, length = unit(0.03, "npc")) +
  scale_x_continuous(labels = scales::percent_format()) +
  labs(x = "State Agricultural Employment Share (Census 2001)",
       y = expression("Marginal Effect of 1" * degree * "C Anomaly"),
       title = "How Agricultural Dependence Mediates Weather Effects on Climate Attention",
       subtitle = "Marginal effect of temperature anomaly on climate search interest") +
  annotate("text", x = 0.08, y = me_data[ag_share == 0.08, me] + 0.5,
           label = "Weather as signal", color = "#2166AC", size = 3.5,
           fontface = "italic", family = "serif") +
  annotate("text", x = 0.72, y = me_data[ag_share == 0.72, me] - 0.5,
           label = "Weather as shock", color = "#B2182B", size = 3.5,
           fontface = "italic", family = "serif")

ggsave(file.path(fig_dir, "fig3_marginal_effect.pdf"), fig3, width = 7, height = 5.5)
fwrite(me_data, file.path(data_dir, "marginal_effects.csv"))
cat("  Saved fig3_marginal_effect.pdf\n")

# ==============================================================================
# FIGURE 4: Attention substitution — Climate vs Agricultural search
# ==============================================================================
cat("Figure 4: Substitution comparison\n")

sub_data <- data.table(
  outcome = c("Climate\nSearches", "Agricultural\nSearches", "Placebo\nSearches"),
  coef = c(coef(models$sub_climate)["tavg_x_ag"],
           coef(models$sub_agricultural)["tavg_x_ag"],
           coef(models$sub_placebo)["tavg_x_ag"]),
  se = c(se(models$sub_climate)["tavg_x_ag"],
         se(models$sub_agricultural)["tavg_x_ag"],
         se(models$sub_placebo)["tavg_x_ag"])
)
sub_data[, ci_lo := coef - 1.96 * se]
sub_data[, ci_hi := coef + 1.96 * se]
sub_data[, outcome := factor(outcome, levels = outcome)]

fig4 <- ggplot(sub_data, aes(x = outcome, y = coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0.15,
                linewidth = 0.8, color = "#2166AC") +
  geom_point(size = 4, color = "#2166AC") +
  labs(x = "", y = expression("Coefficient: Temperature " %*% " Agricultural Share"),
       title = "Attention Substitution During Heat Shocks",
       subtitle = "In agricultural states, heat redirects search from climate to livelihood topics")

ggsave(file.path(fig_dir, "fig4_substitution.pdf"), fig4, width = 6, height = 5)
cat("  Saved fig4_substitution.pdf\n")

# ==============================================================================
# FIGURE 5: Seasonal split — Monsoon vs Non-monsoon
# ==============================================================================
cat("Figure 5: Seasonal split\n")

seas_data <- data.table(
  season = c("Non-Monsoon\n(Oct-May)", "Monsoon\n(Jun-Sep)", "Hot Season\n(Mar-May)"),
  tavg_coef = c(coef(models$seas_nonmonsoon)["tavg_anomaly"],
                coef(models$seas_monsoon)["tavg_anomaly"],
                coef(models$seas_hot)["tavg_anomaly"]),
  tavg_se = c(se(models$seas_nonmonsoon)["tavg_anomaly"],
              se(models$seas_monsoon)["tavg_anomaly"],
              se(models$seas_hot)["tavg_anomaly"]),
  int_coef = c(coef(models$seas_nonmonsoon)["tavg_x_ag"],
               coef(models$seas_monsoon)["tavg_x_ag"],
               coef(models$seas_hot)["tavg_x_ag"]),
  int_se = c(se(models$seas_nonmonsoon)["tavg_x_ag"],
             se(models$seas_monsoon)["tavg_x_ag"],
             se(models$seas_hot)["tavg_x_ag"])
)
seas_data[, int_ci_lo := int_coef - 1.96 * int_se]
seas_data[, int_ci_hi := int_coef + 1.96 * int_se]
seas_data[, season := factor(season, levels = season)]

fig5 <- ggplot(seas_data, aes(x = season, y = int_coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbar(aes(ymin = int_ci_lo, ymax = int_ci_hi), width = 0.15,
                linewidth = 0.8, color = "#B2182B") +
  geom_point(size = 4, color = "#B2182B") +
  labs(x = "", y = expression("Coefficient: Temperature " %*% " Agricultural Share"),
       title = "Seasonal Heterogeneity in Weather-Attention Link",
       subtitle = "Interaction of temperature anomaly with agricultural employment share")

ggsave(file.path(fig_dir, "fig5_seasonal.pdf"), fig5, width = 6, height = 5)
cat("  Saved fig5_seasonal.pdf\n")

# ==============================================================================
# FIGURE 6: Temperature anomaly distribution
# ==============================================================================
cat("Figure 6: Temperature distribution\n")

fig6 <- ggplot(panel, aes(x = tavg_anomaly)) +
  geom_histogram(bins = 50, fill = "#2166AC", alpha = 0.7, color = "white") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
  labs(x = expression("Monthly Temperature Anomaly (" * degree * "C)"),
       y = "Count",
       title = "Distribution of State-Month Temperature Anomalies",
       subtitle = "Relative to 1981-2010 normals, NASA POWER gridded data")

ggsave(file.path(fig_dir, "fig6_temp_distribution.pdf"), fig6, width = 7, height = 4.5)
cat("  Saved fig6_temp_distribution.pdf\n")

cat("\n=== All figures complete ===\n")
