## 05_figures.R — Generate all figures
## APEP-0596: Panama Canal Drought and US Port Trade Diversion

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, date := as.Date(date)]

# ============================================================
# FIGURE 1: Canal Transit Restrictions Timeline
# ============================================================

cat("Figure 1: Canal transit timeline...\n")

canal <- fread(file.path(data_dir, "canal_transits.csv"))
canal[, date := as.Date(paste0(year_month, "-01"))]

fig1 <- ggplot(canal, aes(x = date, y = daily_transits)) +
  geom_line(linewidth = 0.8, color = "#333333") +
  geom_ribbon(aes(ymin = 0, ymax = daily_transits),
              fill = "#E64B35", alpha = 0.15) +
  geom_vline(xintercept = as.Date("2023-07-01"),
             linetype = "dashed", color = "#E64B35", linewidth = 0.5) +
  geom_vline(xintercept = as.Date("2024-08-01"),
             linetype = "dashed", color = "#4DBBD5", linewidth = 0.5) +
  annotate("text", x = as.Date("2023-07-01"), y = 40,
           label = "Drought onset", hjust = -0.1, size = 3, color = "#E64B35") +
  annotate("text", x = as.Date("2024-08-01"), y = 40,
           label = "Full recovery", hjust = -0.1, size = 3, color = "#4DBBD5") +
  annotate("rect",
           xmin = as.Date("2023-07-01"), xmax = as.Date("2024-08-01"),
           ymin = 0, ymax = Inf, fill = "#E64B35", alpha = 0.05) +
  scale_y_continuous(limits = c(0, 42), breaks = seq(0, 40, 10)) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +
  labs(
    title = "Panama Canal Daily Ship Transits, 2019-2024",
    subtitle = "El Nino drought reduced daily transits from 37 to 18 (51% decline)",
    x = NULL, y = "Average daily transits"
  ) +
  theme_apep()

ggsave(file.path(fig_dir, "fig1_canal_transits.pdf"), fig1,
       width = 8, height = 5)

# ============================================================
# FIGURE 2: Event Study — Main Effect
# ============================================================

cat("Figure 2: Event study...\n")

es_data <- fread(file.path(data_dir, "event_study_coefs.csv"))

fig2 <- ggplot(es_data, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "solid", color = "grey60", linewidth = 0.3) +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "#E64B35",
             linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_high),
              fill = "#4DBBD5", alpha = 0.2) +
  geom_point(size = 2, color = "#333333") +
  geom_line(linewidth = 0.5, color = "#333333") +
  annotate("text", x = -12, y = max(es_data$ci_high, na.rm = TRUE) * 0.9,
           label = "Pre-drought", size = 3, color = "grey40") +
  annotate("text", x = 7, y = max(es_data$ci_high, na.rm = TRUE) * 0.9,
           label = "Drought period", size = 3, color = "#E64B35") +
  scale_x_continuous(breaks = seq(-24, 14, 4)) +
  labs(
    title = "Event Study: Effect of Canal Dependence on Port Imports",
    subtitle = "Coefficients on canal share x event-time dummies (ref = t-1)",
    x = "Months relative to drought onset (July 2023)",
    y = "Coefficient (log imports)"
  ) +
  theme_apep()

ggsave(file.path(fig_dir, "fig2_event_study.pdf"), fig2,
       width = 8, height = 5.5)

# ============================================================
# FIGURE 3: Imports by Coast Over Time
# ============================================================

cat("Figure 3: Imports by coast...\n")

coast_trends <- panel[, .(
  mean_imports = mean(total_imports, na.rm = TRUE),
  mean_canal_imports = mean(Canal_dependent, na.rm = TRUE),
  total_imports = sum(total_imports, na.rm = TRUE)
), by = .(year_month, coast, date)]

coast_trends[, coast := factor(coast, levels = c("East Coast", "Gulf Coast", "West Coast"))]

# Normalize to Jan 2019 = 100
baseline <- coast_trends[year_month == "2019-01", .(coast, base = total_imports)]
coast_trends <- merge(coast_trends, baseline, by = "coast")
coast_trends[, index := total_imports / base * 100]

fig3 <- ggplot(coast_trends, aes(x = date, y = index, color = coast)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = as.Date("2023-07-01"),
             linetype = "dashed", color = "grey40", linewidth = 0.5) +
  annotate("rect",
           xmin = as.Date("2023-07-01"), xmax = as.Date("2024-08-01"),
           ymin = -Inf, ymax = Inf, fill = "#E64B35", alpha = 0.05) +
  scale_color_manual(values = apep_colors) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b\n%Y") +
  labs(
    title = "Total Merchandise Imports by US Coastal Region",
    subtitle = "Indexed to January 2019 = 100",
    x = NULL, y = "Import index (Jan 2019 = 100)",
    color = NULL
  ) +
  theme_apep() +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig3_imports_by_coast.pdf"), fig3,
       width = 8, height = 5.5)

# ============================================================
# FIGURE 4: Canal-Origin Imports — Treatment vs Control
# ============================================================

cat("Figure 4: Canal-origin imports by treatment...\n")

treat_trends <- panel[, .(
  mean_canal = mean(Canal_dependent, na.rm = TRUE)
), by = .(year_month, high_canal, date)]

treat_trends[, group := fifelse(high_canal == 1,
                                 "High Canal Dependence", "Low Canal Dependence")]

# Normalize to Jan 2019
baseline_t <- treat_trends[year_month == "2019-01",
                            .(group, base_canal = mean_canal)]
treat_trends <- merge(treat_trends, baseline_t, by = "group")
treat_trends[, canal_index := mean_canal / base_canal * 100]

fig4 <- ggplot(treat_trends, aes(x = date, y = canal_index,
                                  color = group)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = as.Date("2023-07-01"),
             linetype = "dashed", color = "grey40", linewidth = 0.5) +
  annotate("rect",
           xmin = as.Date("2023-07-01"), xmax = as.Date("2024-08-01"),
           ymin = -Inf, ymax = Inf, fill = "#E64B35", alpha = 0.05) +
  scale_color_manual(values = c("High Canal Dependence" = "#E64B35",
                                 "Low Canal Dependence" = "#4DBBD5")) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b\n%Y") +
  labs(
    title = "Asian-Origin Imports: High vs Low Canal Dependence Ports",
    subtitle = "Indexed to January 2019 = 100",
    x = NULL, y = "Canal-origin import index",
    color = NULL
  ) +
  theme_apep() +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig4_canal_imports_treatment.pdf"), fig4,
       width = 8, height = 5.5)

# ============================================================
# FIGURE 5: Leave-One-Out Stability
# ============================================================

cat("Figure 5: Leave-one-out...\n")

loo <- fread(file.path(data_dir, "loo_results.csv"))
main_coef <- fread(file.path(data_dir, "main_results.csv"))[spec == "Continuous Intensity", coef]

loo[, excluded_port_name := gsub(",.*", "", excluded_port_name)]
loo <- loo[order(coef)]
loo[, idx := .I]

fig5 <- ggplot(loo, aes(x = idx, y = coef)) +
  geom_hline(yintercept = main_coef, linetype = "dashed",
             color = "#E64B35", linewidth = 0.5) +
  geom_errorbar(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
                width = 0, color = "grey60") +
  geom_point(size = 2, color = "#333333") +
  annotate("text", x = max(loo$idx) * 0.8, y = main_coef,
           label = "Full sample", vjust = -0.5, size = 3, color = "#E64B35") +
  labs(
    title = "Leave-One-Out Stability Test",
    subtitle = "Each point drops one port from the sample",
    x = "Excluded port (sorted by coefficient)",
    y = "Coefficient on treatment"
  ) +
  theme_apep() +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())

ggsave(file.path(fig_dir, "fig5_loo.pdf"), fig5,
       width = 8, height = 5)

# ============================================================
# FIGURE 6: Randomization Inference Distribution
# ============================================================

cat("Figure 6: RI distribution...\n")

ri_data <- fread(file.path(data_dir, "ri_permutation_coefs.csv"))
true_coef_val <- ri_data[1, true_coef]

fig6 <- ggplot(ri_data, aes(x = perm_coef)) +
  geom_histogram(bins = 50, fill = "grey80", color = "grey60") +
  geom_vline(xintercept = true_coef_val, color = "#E64B35",
             linewidth = 0.8, linetype = "solid") +
  annotate("text", x = true_coef_val, y = Inf,
           label = sprintf("True = %.3f", true_coef_val),
           vjust = 2, hjust = -0.1, size = 3.5, color = "#E64B35") +
  labs(
    title = "Randomization Inference: Permutation Distribution",
    subtitle = "999 random reassignments of Canal share across ports",
    x = "Permuted coefficient",
    y = "Count"
  ) +
  theme_apep()

ggsave(file.path(fig_dir, "fig6_ri_distribution.pdf"), fig6,
       width = 7, height = 5)

# ============================================================
# FIGURE 7: Treatment Intensity Map (Canal Share by Port)
# ============================================================

cat("Figure 7: Canal share by port...\n")

port_summary <- fread(file.path(data_dir, "port_summary.csv"))
port_summary <- port_summary[order(-canal_share)]

# Top 20 ports by trade volume
top_ports <- port_summary[order(-mean_monthly_imports)][1:min(20, .N)]
top_ports[, port_label := gsub(",.*", "", PORT_NAME)]
top_ports[, port_label := factor(port_label, levels = rev(port_label))]

fig7 <- ggplot(top_ports, aes(x = canal_share, y = port_label, fill = coast)) +
  geom_col() +
  scale_fill_manual(values = apep_colors) +
  scale_x_continuous(labels = percent_format(), limits = c(0, NA)) +
  labs(
    title = "Pre-Drought Canal Dependence by Port",
    subtitle = "Share of imports from Canal-dependent Asian origins (2019-2022)",
    x = "Canal share of imports", y = NULL,
    fill = "Coast"
  ) +
  theme_apep() +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig7_canal_share.pdf"), fig7,
       width = 7, height = 6)

# ============================================================
# FIGURE A1: Drought Intensity Measure
# ============================================================

cat("Figure A1: Drought intensity...\n")

figA1 <- ggplot(canal, aes(x = date, y = drought_intensity)) +
  geom_area(fill = "#E64B35", alpha = 0.3) +
  geom_line(color = "#E64B35", linewidth = 0.8) +
  scale_y_continuous(labels = percent_format(), limits = c(0, 0.55)) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +
  labs(
    title = "Panama Canal Drought Intensity Measure",
    subtitle = "1 - (actual transits / normal capacity); 0 = normal, higher = more disrupted",
    x = NULL, y = "Drought intensity"
  ) +
  theme_apep()

ggsave(file.path(fig_dir, "figA1_drought_intensity.pdf"), figA1,
       width = 8, height = 4.5)

cat("\n=== All figures generated ===\n")
