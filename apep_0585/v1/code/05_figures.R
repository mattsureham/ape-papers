## 05_figures.R — All figures
## APEP-0585: EU Medical Device Regulation (MDR) and Innovation

source("00_packages.R")

data_dir <- "../data/"
fig_dir <- "../figures/"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# FIGURE 1: Raw Production Trends — C325 vs Control Sectors (EU Countries)
# ============================================================================

cat("=== Figure 1: Production trends ===\n")

panel <- fread(paste0(data_dir, "panel_production_with_intensity.csv"))

# Average across EU countries by sector and year
eu_trends <- panel[is_eu == TRUE & balanced == TRUE, .(
  mean_prod = mean(prod_index, na.rm = TRUE),
  se_prod = sd(prod_index, na.rm = TRUE) / sqrt(.N)
), by = .(year, nace, nace_label)]

sector_labels <- c(
  "C325" = "Medical Devices (C325)",
  "C21"  = "Pharmaceuticals (C21)",
  "C265" = "Measuring Instruments (C265)",
  "C26"  = "Electronics (C26)"
)

eu_trends[, sector_label := sector_labels[nace]]

# Only show CI for treatment group (C325) to reduce clutter
eu_trends[, is_treated := grepl("C325", sector_label)]

fig1 <- ggplot(eu_trends, aes(x = year, y = mean_prod, color = sector_label)) +
  geom_ribbon(data = eu_trends[is_treated == TRUE],
              aes(ymin = mean_prod - 1.96 * se_prod,
                  ymax = mean_prod + 1.96 * se_prod,
                  fill = sector_label), alpha = 0.15, color = NA) +
  geom_line(aes(linewidth = is_treated)) +
  geom_point(aes(size = is_treated)) +
  scale_linewidth_manual(values = c("FALSE" = 0.7, "TRUE" = 1.3), guide = "none") +
  scale_size_manual(values = c("FALSE" = 1.5, "TRUE" = 2.5), guide = "none") +
  geom_vline(xintercept = 2020.5, linetype = "dashed", color = "grey40", linewidth = 0.5) +
  annotate("text", x = 2020.7, y = max(eu_trends$mean_prod, na.rm = TRUE) * 0.98,
           label = "MDR\nMay 2021", hjust = 0, size = 3, color = "grey40") +
  scale_color_manual(values = apep_colors[1:4]) +
  scale_fill_manual(values = apep_colors[1:4]) +
  scale_x_continuous(breaks = 2015:2025) +
  labs(
    title = "Industrial Production Index by Sector, EU Countries",
    subtitle = "Annual index (2021 = 100), average across EU countries with C325 data",
    x = "Year",
    y = "Production Index (2021 = 100)",
    color = NULL,
    fill = NULL
  ) +
  theme_apep() +
  theme(legend.position = "bottom",
        axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(paste0(fig_dir, "fig1_production_trends.pdf"), fig1,
       width = 8, height = 5.5, dpi = 300)
cat("  Saved fig1_production_trends.pdf\n")


# ============================================================================
# FIGURE 2: Event Study
# ============================================================================

cat("=== Figure 2: Event study ===\n")

es_coefs <- fread(paste0(data_dir, "event_study_coefs.csv"))

# Parse event time from coefficient names
es_coefs[, event_time := as.numeric(str_extract(term, "-?\\d+"))]
es_coefs <- es_coefs[!is.na(event_time)]

# Add reference period (t = -1, coefficient = 0)
es_coefs <- rbind(es_coefs, data.frame(
  Estimate = 0, `Std. Error` = 0, `t value` = 0, `Pr(>|t|)` = NA,
  term = "ref", event_time = -1,
  check.names = FALSE
), fill = TRUE)

setnames(es_coefs, old = c("Estimate", "Std. Error"), new = c("coef", "se"), skip_absent = TRUE)

fig2 <- ggplot(es_coefs, aes(x = event_time, y = coef)) +
  geom_ribbon(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
              alpha = 0.15, fill = apep_colors[1]) +
  geom_line(color = apep_colors[1], linewidth = 0.8) +
  geom_point(color = apep_colors[1], size = 2.5) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey60") +
  annotate("text", x = -0.3, y = min(es_coefs$coef - 1.96 * es_coefs$se, na.rm = TRUE) * 0.9,
           label = "MDR", hjust = 0, size = 3, color = "grey40") +
  scale_x_continuous(breaks = seq(-6, 4, 1),
                     labels = function(x) ifelse(x == 0, "2021\n(MDR)", as.character(2021 + x))) +
  labs(
    title = "Event Study: Medical Devices vs. Control Sectors",
    subtitle = "Differential production index, reference period = 2020 (t = -1)",
    x = "Year",
    y = "Differential Production Index\n(Medical Devices vs. Controls)",
    caption = "95% confidence intervals. Clustered at country level."
  ) +
  theme_apep()

ggsave(paste0(fig_dir, "fig2_event_study.pdf"), fig2,
       width = 8, height = 5, dpi = 300)
cat("  Saved fig2_event_study.pdf\n")


# ============================================================================
# FIGURE 3: US vs EU Comparison (FDA 510(k) vs EU Production)
# ============================================================================

cat("=== Figure 3: US vs EU comparison ===\n")

fda <- fread(paste0(data_dir, "fda_510k_indexed.csv"))
fda_total <- fda[device_class == 0 & year >= 2015 & year <= 2025]

# EU average C325 production index
eu_c325 <- panel[is_eu == TRUE & nace == "C325" & balanced == TRUE, .(
  index = mean(prod_index, na.rm = TRUE)
), by = year]

compare_df <- rbind(
  data.frame(year = eu_c325$year, index = eu_c325$index, source = "EU Medical Devices\n(Eurostat C325)"),
  data.frame(year = fda_total$year, index = fda_total$index_2021, source = "US Medical Devices\n(FDA 510(k))")
)

fig3 <- ggplot(compare_df, aes(x = year, y = index, color = source)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  geom_vline(xintercept = 2020.5, linetype = "dashed", color = "grey40") +
  geom_hline(yintercept = 100, linetype = "dotted", color = "grey70") +
  annotate("text", x = 2020.7, y = 115,
           label = "MDR\nMay 2021", hjust = 0, size = 3, color = "grey40") +
  scale_color_manual(values = c(apep_colors[1], apep_colors[2])) +
  scale_x_continuous(breaks = 2015:2025) +
  labs(
    title = "Medical Device Production: EU vs. United States",
    subtitle = "Indexed to 2021 = 100",
    x = "Year",
    y = "Index (2021 = 100)",
    color = NULL
  ) +
  theme_apep() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(paste0(fig_dir, "fig3_eu_us_comparison.pdf"), fig3,
       width = 8, height = 5, dpi = 300)
cat("  Saved fig3_eu_us_comparison.pdf\n")


# ============================================================================
# FIGURE 4: EUDAMED Device Distribution by Risk Class
# ============================================================================

cat("=== Figure 4: EUDAMED risk class distribution ===\n")

risk_dist <- fread(paste0(data_dir, "eudamed_risk_distribution.csv"))

fig4 <- ggplot(risk_dist, aes(x = reorder(risk_class_clean, -total_devices),
                               y = total_devices / 1000)) +
  geom_col(fill = apep_colors[1], width = 0.6) +
  geom_text(aes(label = scales::comma(total_devices)),
            vjust = -0.5, size = 3.5) +
  scale_y_continuous(labels = scales::comma_format()) +
  labs(
    title = "EU Medical Devices by Risk Class (EUDAMED)",
    subtitle = "Total registered devices as of March 2026",
    x = "MDR Risk Class",
    y = "Number of Devices (thousands)",
    caption = "Source: EUDAMED UDI-DI database"
  ) +
  theme_apep()

ggsave(paste0(fig_dir, "fig4_eudamed_risk_dist.pdf"), fig4,
       width = 7, height = 5, dpi = 300)
cat("  Saved fig4_eudamed_risk_dist.pdf\n")


# ============================================================================
# FIGURE 5: Leave-One-Out Stability
# ============================================================================

cat("=== Figure 5: Leave-one-out ===\n")

loo <- fread(paste0(data_dir, "robustness_loo.csv"))

# Add full-sample estimate
main_results <- fread(paste0(data_dir, "main_results.csv"))
full_coef <- main_results[model == "DiD: Country-Year FE", coefficient]
full_se <- main_results[model == "DiD: Country-Year FE", se]

fig5 <- ggplot(loo, aes(x = reorder(dropped, coef), y = coef)) +
  geom_hline(yintercept = full_coef, linetype = "solid", color = apep_colors[1], linewidth = 0.5) +
  geom_hline(yintercept = full_coef + 1.96 * full_se, linetype = "dashed",
             color = apep_colors[1], linewidth = 0.3, alpha = 0.5) +
  geom_hline(yintercept = full_coef - 1.96 * full_se, linetype = "dashed",
             color = apep_colors[1], linewidth = 0.3, alpha = 0.5) +
  geom_pointrange(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
                  color = apep_colors[2], size = 0.6) +
  geom_hline(yintercept = 0, linetype = "dotted", color = "grey50") +
  coord_flip() +
  labs(
    title = "Leave-One-Country-Out Sensitivity",
    subtitle = "Blue line = full-sample estimate; orange = dropping indicated country",
    x = "Country Dropped",
    y = "DiD Coefficient"
  ) +
  theme_apep()

ggsave(paste0(fig_dir, "fig5_leave_one_out.pdf"), fig5,
       width = 7, height = 4.5, dpi = 300)
cat("  Saved fig5_leave_one_out.pdf\n")


# ============================================================================
# FIGURE 6: Randomization Inference Distribution
# ============================================================================

cat("=== Figure 6: Randomization inference ===\n")

ri <- fread(paste0(data_dir, "ri_distribution.csv"))
actual <- main_results[model == "DiD: Country-Year FE", coefficient]

fig6 <- ggplot(ri, aes(x = ri_coef)) +
  geom_histogram(bins = 50, fill = "grey80", color = "grey60") +
  geom_vline(xintercept = actual, color = apep_colors[1], linewidth = 1.2) +
  geom_vline(xintercept = -actual, color = apep_colors[1],
             linewidth = 1.2, linetype = "dashed") +
  annotate("text", x = actual, y = Inf,
           label = paste0("Actual = ", round(actual, 2)),
           hjust = -0.1, vjust = 2, color = apep_colors[1], size = 3.5) +
  labs(
    title = "Randomization Inference: Permutation Distribution",
    subtitle = "999 permutations of sector treatment assignment",
    x = "Placebo DiD Coefficient",
    y = "Count"
  ) +
  theme_apep()

ggsave(paste0(fig_dir, "fig6_randomization_inference.pdf"), fig6,
       width = 7, height = 4.5, dpi = 300)
cat("  Saved fig6_randomization_inference.pdf\n")


# ============================================================================
# FIGURE 7: Country-Level Production Trends for C325
# ============================================================================

cat("=== Figure 7: Country-level C325 trends ===\n")

country_c325 <- panel[nace == "C325" & balanced == TRUE]

fig7 <- ggplot(country_c325, aes(x = year, y = prod_index, color = geo)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_vline(xintercept = 2020.5, linetype = "dashed", color = "grey40") +
  facet_wrap(~ ifelse(is_eu, "EU Countries (Treated)", "Non-EU (Control)"),
             scales = "free_y") +
  scale_x_continuous(breaks = seq(2015, 2025, 2)) +
  scale_color_brewer(palette = "Set2") +
  labs(
    title = "Medical Device Production by Country (C325)",
    subtitle = "Production index (2021 = 100)",
    x = "Year",
    y = "Production Index",
    color = "Country"
  ) +
  theme_apep() +
  theme(legend.position = "right")

ggsave(paste0(fig_dir, "fig7_country_trends.pdf"), fig7,
       width = 10, height = 5, dpi = 300)
cat("  Saved fig7_country_trends.pdf\n")


# ============================================================================
# FIGURE 8: EUDAMED Manufacturer Country Distribution
# ============================================================================

cat("=== Figure 8: Manufacturer country distribution ===\n")

mfr_dist <- fread(paste0(data_dir, "eudamed_mfr_country_dist.csv"))
top_countries <- mfr_dist[1:min(15, nrow(mfr_dist))]

fig8 <- ggplot(top_countries, aes(x = reorder(mfr_country, n_devices), y = n_devices)) +
  geom_col(aes(fill = pct_higher_risk), width = 0.7) +
  coord_flip() +
  scale_fill_gradient(low = apep_colors[3], high = apep_colors[2],
                      name = "% Higher-Risk\nDevices") +
  labs(
    title = "Top 15 Manufacturer Countries in EUDAMED",
    subtitle = "Color indicates share of Class IIb/III (higher-risk) devices",
    x = NULL,
    y = "Number of Devices (sample)"
  ) +
  theme_apep() +
  theme(legend.position = "right")

ggsave(paste0(fig_dir, "fig8_manufacturer_countries.pdf"), fig8,
       width = 8, height = 5, dpi = 300)
cat("  Saved fig8_manufacturer_countries.pdf\n")

cat("\nAll figures generated.\n")
