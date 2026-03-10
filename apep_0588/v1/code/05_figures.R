# ==============================================================================
# 05_figures.R — All Figures for apep_0588
# ==============================================================================

source("00_packages.R")

data_dir <- "../data/"
fig_dir <- "../figures/"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

dt <- fread(paste0(data_dir, "panel_total.csv"))
gas_dep <- fread(paste0(data_dir, "gas_dependence.csv"))

# ==============================================================================
# Figure 1: Gas Dependence Map / Bar Chart
# ==============================================================================
cat("Figure 1: Gas dependence by country...\n")

gas_dep_plot <- gas_dep[order(-gas_dep_2021)]
gas_dep_plot[, geo_label := geo]
gas_dep_plot[, gas_group := fcase(
  gas_dep_2021 >= 0.50, "High (>50%)",
  gas_dep_2021 >= 0.25, "Medium (25-50%)",
  default = "Low (<25%)"
)]

p1 <- ggplot(gas_dep_plot, aes(x = reorder(geo_label, gas_dep_2021),
                                y = gas_dep_2021 * 100, fill = gas_group)) +
  geom_col() +
  coord_flip() +
  scale_fill_manual(values = c("Low (<25%)" = "#4575b4",
                                "Medium (25-50%)" = "#fc8d59",
                                "High (>50%)" = "#d73027")) +
  labs(x = NULL, y = "Russian Gas Share of Total Gas Supply, 2021 (%)",
       fill = "Dependence Group") +
  theme(legend.position = c(0.7, 0.3))

ggsave(paste0(fig_dir, "fig1_gas_dependence.pdf"), p1, width = 7, height = 8)

# ==============================================================================
# Figure 2: HICP Energy Prices by Dependence Group
# ==============================================================================
cat("Figure 2: Energy price trajectories...\n")

dt_hicp <- fread(paste0(data_dir, "panel_hicp.csv"))
dt_hicp[, gas_group := fcase(
  gas_dep_2021 >= 0.50, "High (>50%)",
  gas_dep_2021 >= 0.25, "Medium (25-50%)",
  default = "Low (<25%)"
)]
dt_hicp[, date := as.Date(paste0(time, "-01"))]

hicp_group <- dt_hicp[!is.na(hicp_energy),
                      .(hicp_mean = mean(hicp_energy, na.rm = TRUE),
                        hicp_p25 = quantile(hicp_energy, 0.25, na.rm = TRUE),
                        hicp_p75 = quantile(hicp_energy, 0.75, na.rm = TRUE)),
                      by = .(date, gas_group)]

p2 <- ggplot(hicp_group, aes(x = date, y = hicp_mean, color = gas_group)) +
  geom_ribbon(aes(ymin = hicp_p25, ymax = hicp_p75, fill = gas_group),
              alpha = 0.15, color = NA) +
  geom_line(linewidth = 1) +
  geom_vline(xintercept = as.Date("2022-02-24"), linetype = "dashed",
             color = "gray40") +
  annotate("text", x = as.Date("2022-02-24"), y = max(hicp_group$hicp_p75, na.rm = TRUE),
           label = "Russia\ninvades\nUkraine", hjust = 1.1, size = 3, color = "gray40") +
  scale_color_manual(values = c("Low (<25%)" = "#4575b4",
                                 "Medium (25-50%)" = "#fc8d59",
                                 "High (>50%)" = "#d73027")) +
  scale_fill_manual(values = c("Low (<25%)" = "#4575b4",
                                "Medium (25-50%)" = "#fc8d59",
                                "High (>50%)" = "#d73027")) +
  labs(x = NULL, y = "HICP Energy Index (2015 = 100)",
       color = "Russian Gas\nDependence", fill = "Russian Gas\nDependence") +
  theme(legend.position = c(0.15, 0.75))

ggsave(paste0(fig_dir, "fig2_hicp_energy.pdf"), p2, width = 9, height = 5.5)

# ==============================================================================
# Figure 3: Event Study — Dynamic Effects
# ==============================================================================
cat("Figure 3: Event study...\n")

es <- fread(paste0(data_dir, "results_event_study.csv"))

p3 <- ggplot(es, aes(x = rel_winter, y = coef)) +
  geom_hline(yintercept = 0, color = "gray60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "gray40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "#4575b4", alpha = 0.2) +
  geom_point(size = 2.5, color = "#4575b4") +
  geom_line(color = "#4575b4", linewidth = 0.8) +
  annotate("text", x = -0.5, y = max(es$ci_hi) * 0.9,
           label = "Gas\nShock", hjust = 1.1, size = 3, color = "gray40") +
  scale_x_continuous(breaks = sort(unique(es$rel_winter)),
                     labels = function(x) {
                       yr <- x + 2022
                       paste0("'", substr(yr, 3, 4), "/", substr(yr + 1, 3, 4))
                     }) +
  labs(x = "Winter (relative to 2022/23 shock)",
       y = expression("Coefficient: " * hat(beta) * " (Gas Dep" * times * "Post)"),
       title = NULL) +
  theme(axis.text.x = element_text(size = 9))

ggsave(paste0(fig_dir, "fig3_event_study.pdf"), p3, width = 8, height = 5)

# ==============================================================================
# Figure 4: Age Gradient — Mechanism Test
# ==============================================================================
cat("Figure 4: Age gradient...\n")

age_res <- fread(paste0(data_dir, "results_age_gradient.csv"))

# Order age groups
age_order <- c("0-19", "20-64", "65-74", "75-84", "85+")
age_res[, age_group := factor(age_group, levels = age_order)]
age_res <- age_res[!is.na(age_group)]
age_res[, ci_lo := coef - 1.96 * se]
age_res[, ci_hi := coef + 1.96 * se]

p4 <- ggplot(age_res, aes(x = age_group, y = coef)) +
  geom_hline(yintercept = 0, color = "gray60") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  color = "#d73027", size = 0.8, linewidth = 0.8) +
  labs(x = "Age Group",
       y = expression("Coefficient: " * hat(beta) * " (Gas Dep" * times * "Post)"),
       title = NULL) +
  theme(axis.text.x = element_text(size = 11))

ggsave(paste0(fig_dir, "fig4_age_gradient.pdf"), p4, width = 6, height = 5)

# ==============================================================================
# Figure 5: Randomization Inference Distribution
# ==============================================================================
cat("Figure 5: RI distribution...\n")

ri_dist <- fread(paste0(data_dir, "ri_distribution.csv"))
ri_res <- fread(paste0(data_dir, "results_ri.csv"))
beta_obs <- ri_res$beta_main

p5 <- ggplot(ri_dist, aes(x = beta_perm)) +
  geom_histogram(bins = 50, fill = "gray80", color = "gray60") +
  geom_vline(xintercept = beta_obs, color = "#d73027", linewidth = 1.2, linetype = "solid") +
  geom_vline(xintercept = -beta_obs, color = "#d73027", linewidth = 0.8, linetype = "dashed") +
  annotate("text", x = beta_obs, y = Inf, label = paste0("Observed\n", round(beta_obs, 2)),
           vjust = 1.5, hjust = -0.1, color = "#d73027", fontface = "bold", size = 3.5) +
  labs(x = expression("Permuted " * hat(beta)),
       y = "Count",
       title = NULL) +
  annotate("text", x = max(ri_dist$beta_perm) * 0.7, y = Inf,
           label = paste0("RI p = ", round(ri_res$pval, 3)),
           vjust = 2, size = 4, fontface = "italic")

ggsave(paste0(fig_dir, "fig5_ri_distribution.pdf"), p5, width = 7, height = 4.5)

# ==============================================================================
# Figure 6: Leave-One-Out Stability
# ==============================================================================
cat("Figure 6: Leave-one-out...\n")

loo <- fread(paste0(data_dir, "results_loo.csv"))
loo[, ci_lo := coef - 1.96 * se]
loo[, ci_hi := coef + 1.96 * se]
loo[, dropped := factor(dropped, levels = loo[order(gas_dep), dropped])]

# Mark high-dependence countries
loo[, highlight := gas_dep >= 0.50]

p6 <- ggplot(loo, aes(x = dropped, y = coef, color = highlight)) +
  geom_hline(yintercept = 0, color = "gray60") +
  geom_hline(yintercept = coef(feols(deaths_pc ~ gas_post | geo + yw,
                                      data = dt[dt$geo %in% gas_dep$geo],
                                      cluster = "geo"))["gas_post"],
             linetype = "dashed", color = "gray40") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi), size = 0.5, linewidth = 0.5) +
  scale_color_manual(values = c("FALSE" = "#4575b4", "TRUE" = "#d73027"),
                     labels = c("Low/Medium Dep.", "High Dep. (>50%)")) +
  coord_flip() +
  labs(x = "Country Dropped", y = expression(hat(beta) * " (Gas Dep x Post)"),
       color = NULL) +
  theme(legend.position = c(0.75, 0.2))

ggsave(paste0(fig_dir, "fig6_loo.pdf"), p6, width = 7, height = 7)

# ==============================================================================
# Figure 7: Mortality Time Series by Dependence Group
# ==============================================================================
cat("Figure 7: Mortality time series...\n")

dt[, gas_group := fcase(
  gas_dep_2021 >= 0.50, "High (>50%)",
  gas_dep_2021 >= 0.25, "Medium (25-50%)",
  default = "Low (<25%)"
)]

# Aggregate weekly deaths per 100k by group
ts_group <- dt[, .(deaths_pc_mean = mean(deaths_pc, na.rm = TRUE)),
               by = .(year, week, gas_group)]

# Create date for plotting
ts_group[, date := as.Date(paste0(year, "-01-01")) + (week - 1) * 7]

p7 <- ggplot(ts_group[year >= 2018], aes(x = date, y = deaths_pc_mean,
                                          color = gas_group)) +
  geom_line(alpha = 0.7, linewidth = 0.5) +
  geom_smooth(method = "loess", span = 0.1, se = FALSE, linewidth = 1.2) +
  geom_vline(xintercept = as.Date("2022-02-24"), linetype = "dashed",
             color = "gray40") +
  scale_color_manual(values = c("Low (<25%)" = "#4575b4",
                                 "Medium (25-50%)" = "#fc8d59",
                                 "High (>50%)" = "#d73027")) +
  labs(x = NULL, y = "Weekly Deaths per 100,000",
       color = "Russian Gas\nDependence") +
  theme(legend.position = c(0.85, 0.8))

ggsave(paste0(fig_dir, "fig7_mortality_ts.pdf"), p7, width = 10, height = 5)

# ==============================================================================
# Figure A1: Scatter — Gas Dependence vs. Excess Winter Mortality Change
# ==============================================================================
cat("Figure A1: Cross-country scatter...\n")

# Compute excess winter deaths change: post-shock vs pre-shock winters
winter_mort <- dt[heating_season == TRUE,
                  .(deaths_pc = mean(deaths_pc, na.rm = TRUE)),
                  by = .(geo, post_winter, gas_dep_2021)]

winter_wide <- dcast(winter_mort, geo + gas_dep_2021 ~ post_winter,
                     value.var = "deaths_pc")
setnames(winter_wide, c("FALSE", "TRUE"), c("pre_winter", "post_winter"))
winter_wide[, excess_change := post_winter - pre_winter]

pa1 <- ggplot(winter_wide, aes(x = gas_dep_2021 * 100, y = excess_change)) +
  geom_point(size = 3, color = "#d73027", alpha = 0.8) +
  geom_smooth(method = "lm", se = TRUE, color = "#4575b4", fill = "#4575b4",
              alpha = 0.15) +
  geom_text(aes(label = geo), hjust = -0.2, vjust = -0.3, size = 3) +
  geom_hline(yintercept = 0, color = "gray60") +
  labs(x = "Russian Gas Dependence, 2021 (%)",
       y = "Change in Winter Deaths per 100,000\n(Post-Shock minus Pre-Shock)")

ggsave(paste0(fig_dir, "figA1_scatter.pdf"), pa1, width = 8, height = 6)

# Save scatter data for replication
fwrite(winter_wide, paste0(data_dir, "scatter_data.csv"))

cat("\nAll figures generated.\n")
