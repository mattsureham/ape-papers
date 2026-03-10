# 05_figures.R — Generate all figures
# apep_0582: The Resilience Puzzle — European Manufacturing and the Russian Gas Shock

source("00_packages.R")

# ============================================================================
# FIGURE 1: European Gas Price and Russian Supply (Motivation)
# ============================================================================
cat("Figure 1: Gas price and supply timeline\n")

# Create TTF price timeline data (key benchmark prices, EUR/MWh)
ttf_data <- data.table(
  date = as.Date(c("2021-01-01", "2021-04-01", "2021-07-01", "2021-10-01",
                    "2022-01-01", "2022-02-01", "2022-03-01", "2022-04-01",
                    "2022-05-01", "2022-06-01", "2022-07-01", "2022-08-01",
                    "2022-09-01", "2022-10-01", "2022-11-01", "2022-12-01",
                    "2023-01-01", "2023-03-01", "2023-06-01", "2023-09-01",
                    "2023-12-01", "2024-03-01", "2024-06-01", "2024-09-01")),
  ttf_price = c(19, 25, 36, 75, 80, 82, 125, 100, 95, 130, 180, 342,
                200, 125, 115, 90, 65, 45, 35, 38, 40, 30, 32, 35)
)

p1 <- ggplot(ttf_data, aes(x = date, y = ttf_price)) +
  geom_line(linewidth = 1, color = "#2C3E50") +
  geom_point(size = 1.5, color = "#2C3E50") +
  geom_vline(xintercept = as.Date("2022-02-24"), linetype = "dashed", color = "#E74C3C", linewidth = 0.7) +
  geom_vline(xintercept = as.Date("2022-09-26"), linetype = "dashed", color = "#E74C3C", linewidth = 0.7) +
  annotate("text", x = as.Date("2022-02-24"), y = 330, label = "Invasion", hjust = -0.1,
           size = 3, color = "#E74C3C", fontface = "italic") +
  annotate("text", x = as.Date("2022-09-26"), y = 330, label = "Nord Stream\nsabotage",
           hjust = -0.1, size = 3, color = "#E74C3C", fontface = "italic") +
  annotate("text", x = as.Date("2022-08-01"), y = 342, label = "Peak: 342 EUR/MWh",
           vjust = -0.5, size = 3, fontface = "bold") +
  scale_y_continuous(labels = scales::comma_format(suffix = " EUR")) +
  labs(x = NULL, y = "TTF Natural Gas Price (EUR/MWh)",
       title = NULL) +
  coord_cartesian(ylim = c(0, 380))

ggsave(file.path(fig_dir, "fig1_gas_price_timeline.pdf"), p1, width = 7, height = 4)
ggsave(file.path(fig_dir, "fig1_gas_price_timeline.png"), p1, width = 7, height = 4, dpi = 300)

# ============================================================================
# FIGURE 2: Russian Gas Dependence Map (Cross-country variation)
# ============================================================================
cat("Figure 2: Russian gas dependence by country\n")

gas_wide <- fread(file.path(data_dir, "gas_imports_2021.csv"))
gas_plot <- gas_wide[!is.na(russian_gas_share) & russian_gas_share > 0]
gas_plot[, geo_label := geo]

# Country name mapping for readability
country_names <- c(
  AT = "Austria", BE = "Belgium", BG = "Bulgaria", CZ = "Czechia",
  DE = "Germany", DK = "Denmark", EE = "Estonia", EL = "Greece",
  ES = "Spain", FI = "Finland", FR = "France", HR = "Croatia",
  HU = "Hungary", IT = "Italy", LT = "Lithuania", LV = "Latvia",
  NL = "Netherlands", PL = "Poland", PT = "Portugal", RO = "Romania",
  SE = "Sweden", SI = "Slovenia", SK = "Slovakia", TR = "Turkey",
  RS = "Serbia", NO = "Norway", UK = "United Kingdom", LU = "Luxembourg",
  IE = "Ireland", CY = "Cyprus", MT = "Malta"
)
gas_plot[, country := country_names[geo]]
gas_plot <- gas_plot[!is.na(country)]

p2 <- ggplot(gas_plot[order(russian_gas_share)],
             aes(x = reorder(country, russian_gas_share), y = russian_gas_share * 100)) +
  geom_col(aes(fill = russian_gas_share), show.legend = FALSE) +
  scale_fill_viridis_c(option = "inferno", direction = -1, begin = 0.2, end = 0.9) +
  coord_flip() +
  labs(x = NULL, y = "Russian Gas Share of Total Imports, 2021 (%)",
       title = NULL) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05)))

ggsave(file.path(fig_dir, "fig2_gas_dependence.pdf"), p2, width = 6, height = 7)
ggsave(file.path(fig_dir, "fig2_gas_dependence.png"), p2, width = 6, height = 7, dpi = 300)

# ============================================================================
# FIGURE 3: Production Trends by Exposure Group
# ============================================================================
cat("Figure 3: Production trends\n")

trends <- fread(file.path(data_dir, "production_trends.csv"))
trends[, date := as.Date(date)]

p3 <- ggplot(trends[!is.na(exposure_group)],
             aes(x = date, y = mean_prod, color = exposure_group)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = as.Date("2022-02-24"), linetype = "dashed", color = "grey40") +
  annotate("text", x = as.Date("2022-02-24"), y = max(trends$mean_prod, na.rm = TRUE) * 1.02,
           label = "Invasion", hjust = -0.1, size = 3, color = "grey40") +
  scale_color_manual(values = c("Low (<15%)" = "#2ECC71", "Medium (15-40%)" = "#F39C12",
                                 "High (>40%)" = "#E74C3C"),
                      name = "Russian Gas\nDependence") +
  labs(x = NULL, y = "Industrial Production Index (2015 = 100)",
       title = NULL)

ggsave(file.path(fig_dir, "fig3_production_trends.pdf"), p3, width = 8, height = 5)
ggsave(file.path(fig_dir, "fig3_production_trends.png"), p3, width = 8, height = 5, dpi = 300)

# Gas-intensive sectors only
trends_gas <- fread(file.path(data_dir, "production_trends_gas_intensive.csv"))
trends_gas[, date := as.Date(date)]

p3b <- ggplot(trends_gas[!is.na(exposure_group)],
              aes(x = date, y = mean_prod, color = exposure_group)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = as.Date("2022-02-24"), linetype = "dashed", color = "grey40") +
  scale_color_manual(values = c("Low (<15%)" = "#2ECC71", "Medium (15-40%)" = "#F39C12",
                                 "High (>40%)" = "#E74C3C"),
                      name = "Russian Gas\nDependence") +
  labs(x = NULL, y = "Industrial Production Index (2015 = 100)",
       subtitle = "Gas-intensive sectors only (chemicals, metals, non-metallic minerals)",
       title = NULL)

ggsave(file.path(fig_dir, "fig3b_production_trends_gas_intensive.pdf"), p3b, width = 8, height = 5)
ggsave(file.path(fig_dir, "fig3b_production_trends_gas_intensive.png"), p3b, width = 8, height = 5, dpi = 300)

# ============================================================================
# FIGURE 4: Event Study
# ============================================================================
cat("Figure 4: Event study\n")

es_coefs <- fread(file.path(data_dir, "event_study_coefs.csv"))

p4 <- ggplot(es_coefs, aes(x = rel_month, y = coef)) +
  geom_hline(yintercept = 0, color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "#E74C3C", linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "#3498DB", alpha = 0.2) +
  geom_point(size = 1.5, color = "#2C3E50") +
  geom_line(color = "#2C3E50", linewidth = 0.5) +
  labs(x = "Months Relative to March 2022",
       y = "Coefficient on Gas Exposure",
       title = NULL) +
  annotate("text", x = -18, y = max(es_coefs$ci_hi) * 0.9,
           label = "Pre-treatment", hjust = 0, size = 3, color = "grey40") +
  annotate("text", x = 6, y = max(es_coefs$ci_hi) * 0.9,
           label = "Post-treatment", hjust = 0, size = 3, color = "grey40")

ggsave(file.path(fig_dir, "fig4_event_study.pdf"), p4, width = 8, height = 5)
ggsave(file.path(fig_dir, "fig4_event_study.png"), p4, width = 8, height = 5, dpi = 300)

# ============================================================================
# FIGURE 5: Leave-One-Out Sensitivity
# ============================================================================
cat("Figure 5: Leave-one-out\n")

loo_dt <- fread(file.path(data_dir, "leave_one_out.csv"))
loo_dt[, country := country_names[dropped_country]]
loo_dt[is.na(country), country := dropped_country]

# Add main estimate line
main_res <- fread(file.path(data_dir, "main_results.csv"))
main_coef <- main_res[spec == "Triple FE", coef_exposure_post]

p5 <- ggplot(loo_dt, aes(x = reorder(country, coef), y = coef)) +
  geom_hline(yintercept = 0, color = "grey50", linewidth = 0.5) +
  geom_hline(yintercept = main_coef, linetype = "dashed", color = "#E74C3C", linewidth = 0.5) +
  geom_point(size = 2.5, color = "#2C3E50") +
  geom_errorbar(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
                width = 0.3, color = "#2C3E50") +
  coord_flip() +
  labs(x = "Country Dropped", y = "Coefficient on Gas Exposure × Post",
       title = NULL) +
  annotate("text", x = 1, y = main_coef,
           label = "Full sample", hjust = -0.1, vjust = -0.5,
           size = 3, color = "#E74C3C")

ggsave(file.path(fig_dir, "fig5_leave_one_out.pdf"), p5, width = 7, height = 7)
ggsave(file.path(fig_dir, "fig5_leave_one_out.png"), p5, width = 7, height = 7, dpi = 300)

# ============================================================================
# FIGURE 6: Randomization Inference Distribution
# ============================================================================
cat("Figure 6: Randomization inference\n")

ri_data <- fread(file.path(data_dir, "ri_distribution.csv"))
ri_meta <- fread(file.path(data_dir, "randomization_inference.csv"))

p6 <- ggplot(ri_data, aes(x = perm_coef)) +
  geom_histogram(bins = 40, fill = "#BDC3C7", color = "white") +
  geom_vline(xintercept = ri_meta$actual_coef, color = "#E74C3C", linewidth = 1) +
  annotate("text", x = ri_meta$actual_coef, y = Inf,
           label = paste0("Actual: ", round(ri_meta$actual_coef, 3),
                          "\nRI p = ", round(ri_meta$ri_p_value, 3)),
           hjust = -0.1, vjust = 1.5, size = 3.5, color = "#E74C3C", fontface = "bold") +
  labs(x = "Permuted Coefficient", y = "Count",
       title = NULL)

ggsave(file.path(fig_dir, "fig6_randomization_inference.pdf"), p6, width = 7, height = 4.5)
ggsave(file.path(fig_dir, "fig6_randomization_inference.png"), p6, width = 7, height = 4.5, dpi = 300)

# ============================================================================
# FIGURE 7: Fiscal Shield — Subsidy vs. Production Decline
# ============================================================================
cat("Figure 7: Fiscal shield scatter\n")

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, date := as.Date(date)]

# Calculate country-level production change for gas-intensive sectors
gas_intensive_change <- panel[gas_intensity > 0.5,
                               .(prod_pre = mean(prod_index[date < as.Date("2022-03-01")], na.rm = TRUE),
                                 prod_post = mean(prod_index[date >= as.Date("2022-06-01") &
                                                               date <= as.Date("2023-06-01")], na.rm = TRUE),
                                 russian_gas_share = first(russian_gas_share),
                                 subsidy_pct_gdp = first(subsidy_pct_gdp)),
                               by = geo]
gas_intensive_change[, pct_change := (prod_post - prod_pre) / prod_pre * 100]
gas_intensive_change[, country := country_names[geo]]
gas_intensive_change[is.na(country), country := geo]

# Only plot countries with meaningful gas exposure
plot_data <- gas_intensive_change[russian_gas_share > 0.05 & !is.na(subsidy_pct_gdp)]

p7 <- ggplot(plot_data, aes(x = subsidy_pct_gdp, y = pct_change)) +
  geom_hline(yintercept = 0, color = "grey50", linewidth = 0.5) +
  geom_point(aes(size = russian_gas_share * 100), color = "#2C3E50", alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, color = "#3498DB", fill = "#3498DB", alpha = 0.15) +
  geom_text(aes(label = country), size = 2.5, vjust = -1, hjust = 0.5, check_overlap = TRUE) +
  scale_size_continuous(name = "Russian Gas\nShare (%)", range = c(2, 8)) +
  labs(x = "Energy Subsidies (% of GDP, cumulative 2021-2023)",
       y = "Production Change in Gas-Intensive Sectors (%)",
       title = NULL)

ggsave(file.path(fig_dir, "fig7_fiscal_shield.pdf"), p7, width = 8, height = 6)
ggsave(file.path(fig_dir, "fig7_fiscal_shield.png"), p7, width = 8, height = 6, dpi = 300)

cat("\nAll figures generated.\n")
