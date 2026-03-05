## 05_figures.R — Publication-quality figures
## apep_0519: MuKEn 2014 Building Energy Codes and Heat Pump Adoption
## ---------------------------------------------------------------

source("00_packages.R")

fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

data_dir <- "../data"

# ---------------------------------------------------------------
# Load data
# ---------------------------------------------------------------

panel   <- fread(file.path(data_dir, "analysis_panel.csv"))
results <- fread(file.path(data_dir, "main_results.csv"))
longdif <- fread(file.path(data_dir, "long_difference.csv"))
surface <- fread(file.path(data_dir, "surface_panel.csv"))
muken   <- fread(file.path(data_dir, "muken_adoption.csv"))

# ---------------------------------------------------------------
# Colour palettes
# ---------------------------------------------------------------

col_early <- "#2166AC"   # blue — early adopters
col_late  <- "#B2182B"   # red  — late adopters
col_never <- "#636363"   # grey — never (SO)

cohort_cols <- c(
  "2017" = "#08519C", "2018" = "#2171B5", "2019" = "#4292C6",

"2020" = "#6BAED6", "2021" = "#9ECAE1", "2022" = "#C6DBEF",
  "2023" = "#DEEBF7", "2024" = "#F7FBFF", "Never" = "#636363"
)

# ---------------------------------------------------------------
# Figure 1 — Heat pump share trends by adoption cohort
# ---------------------------------------------------------------

# Classify cantons — cantons adopting after 2022 are effectively never-treated
# in the building-count panel (which ends in 2022), so group them with control
panel[, cohort_group := fifelse(
  is.na(adoption_year) | adoption_year == Inf | adoption_year > 2022,
  "Control (never treated in sample)",
  fifelse(adoption_year <= 2019, "Early adopters (<=2019)",
          "Late adopters (2020-2022)")
)]

# Compute mean heat pump share by cohort-group x year
trend_dt <- panel[!is.na(share_heat_pump),
                  .(mean_hp = mean(share_heat_pump, na.rm = TRUE),
                    se_hp   = sd(share_heat_pump, na.rm = TRUE) / sqrt(.N),
                    n = .N),
                  by = .(year, cohort_group)]

# Observed years: 2009-2015 and 2021-2022; gap in 2016-2020
# We plot observed data with solid lines and add dashed segments for the gap
trend_pre  <- trend_dt[year <= 2015]
trend_post <- trend_dt[year >= 2021]

# Bridge points: last pre (2015) and first post (2021) for each group
bridge <- rbind(trend_dt[year == 2015], trend_dt[year == 2021])

p1 <- ggplot() +
  # Pre-period solid lines
  geom_line(data = trend_pre,
            aes(x = year, y = mean_hp, colour = cohort_group),
            linewidth = 0.9) +
  geom_point(data = trend_pre,
             aes(x = year, y = mean_hp, colour = cohort_group),
             size = 1.8) +
  # Post-period solid lines
  geom_line(data = trend_post,
            aes(x = year, y = mean_hp, colour = cohort_group),
            linewidth = 0.9) +
  geom_point(data = trend_post,
             aes(x = year, y = mean_hp, colour = cohort_group),
             size = 1.8) +
  # Dashed bridge across 2016-2020 gap
  geom_line(data = bridge,
            aes(x = year, y = mean_hp, colour = cohort_group),
            linetype = "dashed", linewidth = 0.5) +
  # Shaded gap region
  annotate("rect", xmin = 2015.5, xmax = 2020.5,
           ymin = -Inf, ymax = Inf,
           fill = "grey90", alpha = 0.5) +
  annotate("text", x = 2018, y = max(trend_dt$mean_hp, na.rm = TRUE) * 0.98,
           label = "No survey\n2016\u20132020", size = 3, colour = "grey50") +
  scale_colour_manual(
    values = c("Early adopters (<=2019)"          = col_early,
               "Late adopters (2020-2022)"         = col_late,
               "Control (never treated in sample)" = col_never),
    name = NULL
  ) +
  scale_x_continuous(breaks = c(2009:2015, 2021:2022)) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(
    title    = "Heat Pump Share by MuKEn 2014 Adoption Cohort",
    subtitle = "Mean share of residential buildings with heat pump as primary heating",
    x = NULL, y = "Heat pump share"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(fig_dir, "fig1_trends.pdf"), p1, width = 7, height = 5)
cat("Saved fig1_trends.pdf\n")

# ---------------------------------------------------------------
# Figure 2 — Adoption year by canton (horizontal bar chart)
# ---------------------------------------------------------------

# Merge adoption info
muken_plot <- copy(muken)
muken_plot[, adoption_year_plot := fifelse(is.na(adoption_year), 2025, adoption_year)]
muken_plot[, adoption_label := fifelse(is.na(adoption_year), "Not adopted", as.character(adoption_year))]

# Colour grouping
muken_plot[, year_group := fifelse(is.na(adoption_year), "Never",
                            fifelse(adoption_year <= 2018, "2017-2018",
                              fifelse(adoption_year <= 2020, "2019-2020",
                                fifelse(adoption_year <= 2022, "2021-2022",
                                        "2023-2024"))))]

# Sort by adoption year then canton name
muken_plot[, canton := factor(canton, levels = muken_plot[order(-adoption_year_plot, canton)]$canton)]

bar_cols <- c(
  "2017-2018" = "#08519C",
  "2019-2020" = "#4292C6",
  "2021-2022" = "#9ECAE1",
  "2023-2024" = "#DEEBF7",
  "Never"     = "#636363"
)

p2 <- ggplot(muken_plot, aes(x = canton, y = adoption_year_plot, fill = year_group)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = adoption_label), hjust = -0.1, size = 2.8) +
  coord_flip() +
  scale_fill_manual(values = bar_cols, name = "Adoption period") +
  scale_y_continuous(limits = c(2015, 2027), breaks = seq(2017, 2025, 1)) +
  labs(
    title    = "MuKEn 2014 Adoption Year by Canton",
    subtitle = "Horizontal bars show year each canton enacted MuKEn 2014 building codes",
    x = NULL, y = "Year of adoption"
  )

ggsave(file.path(fig_dir, "fig2_treatment_map.pdf"), p2, width = 7, height = 5)
cat("Saved fig2_treatment_map.pdf\n")

# ---------------------------------------------------------------
# Figure 3 — Long-difference scatter
# ---------------------------------------------------------------

longdif_plot <- copy(longdif)
longdif_plot <- longdif_plot[!is.na(years_exposed) & !is.na(delta_hp_share)]

p3 <- ggplot(longdif_plot, aes(x = years_exposed, y = delta_hp_share)) +
  geom_smooth(method = "lm", se = TRUE, colour = col_early,
              fill = col_early, alpha = 0.15, linewidth = 0.8) +
  geom_point(size = 2.5, colour = col_early, alpha = 0.8) +
  geom_text(aes(label = canton), hjust = -0.15, vjust = 0.4,
            size = 2.8, colour = "grey30") +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(
    title    = "Long-Difference: Heat Pump Share Change vs. MuKEn Exposure",
    subtitle = "Each point is a canton; change from pre-mean (2009-2015) to post-mean (2021-2022)",
    x = "Years of exposure to MuKEn 2014",
    y = "Change in heat pump share (pp)"
  )

ggsave(file.path(fig_dir, "fig3_long_diff.pdf"), p3, width = 7, height = 5)
cat("Saved fig3_long_diff.pdf\n")

# ---------------------------------------------------------------
# Figure 4 — Coefficient plot (main TWFE results)
# ---------------------------------------------------------------

# Select the TWFE outcome models
twfe_rows <- results[grepl("^TWFE:", model)]
twfe_rows[, outcome := gsub("^TWFE:\\s*", "", model)]

# Order outcomes logically
outcome_order <- c("HP Share", "Oil Share", "Gas Share",
                   "Fossil Share", "Wood Share", "District")
twfe_rows[, outcome := factor(outcome, levels = rev(outcome_order))]

p4 <- ggplot(twfe_rows, aes(x = coef, y = outcome)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey50") +
  geom_errorbarh(aes(xmin = ci_lo, xmax = ci_hi),
                 height = 0.2, linewidth = 0.6, colour = "grey30") +
  geom_point(aes(colour = pval < 0.05), size = 3) +
  scale_colour_manual(
    values = c("TRUE" = col_early, "FALSE" = "grey50"),
    labels = c("TRUE" = "p < 0.05", "FALSE" = "p >= 0.05"),
    name = NULL
  ) +
  labs(
    title    = "TWFE Estimates: Effect of MuKEn 2014 on Heating Shares",
    subtitle = "Point estimates with 95% confidence intervals (cluster-robust SE)",
    x = "Coefficient (share, percentage points)",
    y = NULL
  )

ggsave(file.path(fig_dir, "fig4_coefficient_plot.pdf"), p4, width = 7, height = 5)
cat("Saved fig4_coefficient_plot.pdf\n")

# ---------------------------------------------------------------
# Figure 5 — Surface area heat pump share by canton (2021-2023)
# ---------------------------------------------------------------

surface_plot <- surface[year %in% 2021:2023 & !is.na(pct_heat_pump_surface)]

# Merge adoption year for colouring
surface_plot <- merge(surface_plot,
                      muken[, .(canton, adoption_year)],
                      by = "canton", all.x = TRUE,
                      suffixes = c("", "_muken"))

# Handle column name conflict — use the muken adoption_year if both exist
if ("adoption_year_muken" %in% names(surface_plot)) {
  surface_plot[, adoption_year_colour := adoption_year_muken]
} else {
  surface_plot[, adoption_year_colour := adoption_year]
}

surface_plot[, adopt_label := fifelse(is.na(adoption_year_colour),
                                      "Never",
                                      as.character(adoption_year_colour))]

p5 <- ggplot(surface_plot,
             aes(x = year, y = pct_heat_pump_surface,
                 group = canton, colour = adopt_label)) +
  geom_line(linewidth = 0.7, alpha = 0.8) +
  geom_point(size = 1.5) +
  geom_text(data = surface_plot[year == max(year)],
            aes(label = canton), hjust = -0.15, size = 2.5,
            show.legend = FALSE) +
  scale_colour_manual(values = cohort_cols, name = "Adoption year") +
  scale_x_continuous(breaks = 2021:2023,
                     limits = c(2021, 2023.5)) +
  labs(
    title    = "Heat Pump Surface Share by Canton, 2021\u20132023",
    subtitle = "Percentage of heated surface area served by heat pumps",
    x = NULL,
    y = "Heat pump surface share (%)"
  ) +
  guides(colour = guide_legend(ncol = 4))

ggsave(file.path(fig_dir, "fig5_surface_trends.pdf"), p5, width = 7, height = 5)
cat("Saved fig5_surface_trends.pdf\n")

cat("\nAll figures saved to", fig_dir, "\n")
