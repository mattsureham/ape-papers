## 05_figures.R — All V2 Figures
## apep_0727 v2: German Solar PV Bunching at 10 kWp Threshold

source("00_packages.R")

cat("Loading data for figures...\n")
dt_10 <- fread("../data/solar_clean_10.csv")
dt_30 <- fread("../data/solar_clean_30.csv")
dt_gm <- fread("../data/solar_gm_10.csv")
annual <- fread("../data/bunching_10_annual.csv")
period_10 <- fread("../data/bunching_10_by_period.csv")

# Theme for all figures
theme_apep <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    legend.position = "bottom",
    legend.title = element_blank()
  )

# Period colors
period_colors <- c(
  "Pre-FIT (2008-2011)" = "#999999",
  "FIT Kink (2012-2013)" = "#56B4E9",
  "Surcharge (2014-2020)" = "#D55E00",
  "Post-Reform (2021-2024)" = "#009E73"
)

period_labels <- c(
  "1_pre_fit_tier" = "Pre-FIT (2008-2011)",
  "2_fit_kink" = "FIT Kink (2012-2013)",
  "3_surcharge" = "Surcharge (2014-2020)",
  "4_post_reform" = "Post-Reform (2021-2024)"
)

# ============================================================
# FIGURE 1: Local Density at 10 kWp (Money Figure A)
# ============================================================

cat("Figure 1: Local density at 10 kWp...\n")

# Compute density per period, normalized by total installations in period
fig1_data <- dt_10[capacity_kwp >= 8 & capacity_kwp <= 12]
fig1_data[, bin := floor(capacity_kwp * 10) / 10]
fig1_data[, period_label := period_labels[period]]

# Bin counts
fig1_bins <- fig1_data[, .(count = .N), by = .(bin, period_label)]
# Normalize: share of installations in each bin (within period)
fig1_bins[, total := sum(count), by = period_label]
fig1_bins[, share := count / total]

# Order periods
fig1_bins[, period_label := factor(period_label, levels = names(period_colors))]

p1 <- ggplot(fig1_bins, aes(x = bin, y = share, color = period_label)) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 0.8) +
  geom_vline(xintercept = 10.0, linetype = "dashed", color = "black", linewidth = 0.4) +
  scale_color_manual(values = period_colors) +
  scale_x_continuous(breaks = seq(8, 12, 0.5),
                     labels = function(x) sprintf("%.1f", x)) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
  labs(
    title = "Density of Solar Installations Near 10 kWp Threshold",
    subtitle = "Rooftop installations, 0.1 kWp bins, share of period total",
    x = "Installed Capacity (kWp)",
    y = "Share of Installations"
  ) +
  annotate("text", x = 10.0, y = max(fig1_bins$share) * 0.95,
           label = "10 kWp\nthreshold", hjust = -0.1, size = 3, color = "black") +
  theme_apep

ggsave("../figures/fig1_density_10kwp.pdf", p1, width = 8, height = 5)
ggsave("../figures/fig1_density_10kwp.png", p1, width = 8, height = 5, dpi = 300)

# ============================================================
# FIGURE 2: Local Density at 30 kWp (Money Figure B)
# ============================================================

cat("Figure 2: Local density at 30 kWp...\n")

fig2_data <- dt_30[capacity_kwp >= 28 & capacity_kwp <= 32]
fig2_data[, bin := floor(capacity_kwp * 10) / 10]
fig2_data[, period_label := period_labels[period]]

fig2_bins <- fig2_data[, .(count = .N), by = .(bin, period_label)]
fig2_bins[, total := sum(count), by = period_label]
fig2_bins[, share := count / total]
fig2_bins[, period_label := factor(period_label, levels = names(period_colors))]

p2 <- ggplot(fig2_bins, aes(x = bin, y = share, color = period_label)) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 0.8) +
  geom_vline(xintercept = 30.0, linetype = "dashed", color = "black", linewidth = 0.4) +
  scale_color_manual(values = period_colors) +
  scale_x_continuous(breaks = seq(28, 32, 0.5)) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
  labs(
    title = "Density of Solar Installations Near 30 kWp Threshold",
    subtitle = "Rooftop installations, 0.1 kWp bins, share of period total",
    x = "Installed Capacity (kWp)",
    y = "Share of Installations"
  ) +
  annotate("text", x = 30.0, y = max(fig2_bins$share, na.rm = TRUE) * 0.95,
           label = "30 kWp\nthreshold", hjust = -0.1, size = 3, color = "black") +
  theme_apep

ggsave("../figures/fig2_density_30kwp.pdf", p2, width = 8, height = 5)
ggsave("../figures/fig2_density_30kwp.png", p2, width = 8, height = 5, dpi = 300)

# ============================================================
# FIGURE 3: Annual Bunching Ratio Time Series
# ============================================================

cat("Figure 3: Annual bunching ratio...\n")

annual[, phase := fcase(
  year <= 2011, "No threshold",
  year <= 2013, "FIT kink",
  year <= 2020, "Surcharge notch",
  default = "Post-reform"
)]
annual[, phase := factor(phase, levels = c("No threshold", "FIT kink",
                                            "Surcharge notch", "Post-reform"))]

phase_colors <- c("No threshold" = "#999999", "FIT kink" = "#56B4E9",
                   "Surcharge notch" = "#D55E00", "Post-reform" = "#009E73")

p3 <- ggplot(annual, aes(x = year, y = bunching_ratio, fill = phase)) +
  geom_col(width = 0.8) +
  geom_vline(xintercept = 2011.5, linetype = "dashed", color = "grey50", linewidth = 0.3) +
  geom_vline(xintercept = 2013.5, linetype = "dashed", color = "grey50", linewidth = 0.3) +
  geom_vline(xintercept = 2020.5, linetype = "dashed", color = "grey50", linewidth = 0.3) +
  scale_fill_manual(values = phase_colors) +
  scale_x_continuous(breaks = 2008:2024) +
  labs(
    title = "Bunching Ratio at 10 kWp by Year",
    subtitle = "Kleven-Waseem estimate, rooftop installations, polynomial degree 7",
    x = NULL,
    y = "Bunching Ratio (b)"
  ) +
  annotate("text", x = 2009.5, y = max(annual$bunching_ratio) * 0.95,
           label = "No\nthreshold", size = 2.5, color = "grey40") +
  annotate("text", x = 2012.5, y = max(annual$bunching_ratio) * 0.95,
           label = "FIT\nkink", size = 2.5, color = "#56B4E9") +
  annotate("text", x = 2017, y = max(annual$bunching_ratio) * 0.95,
           label = "Surcharge\nnotch", size = 2.5, color = "#D55E00") +
  annotate("text", x = 2022.5, y = max(annual$bunching_ratio) * 0.95,
           label = "Post-\nreform", size = 2.5, color = "#009E73") +
  theme_apep +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8))

ggsave("../figures/fig3_annual_bunching.pdf", p3, width = 9, height = 5)
ggsave("../figures/fig3_annual_bunching.png", p3, width = 9, height = 5, dpi = 300)

# ============================================================
# FIGURE 4: Counterfactual vs Observed (Surcharge Period)
# ============================================================

cat("Figure 4: Counterfactual vs observed...\n")

# Re-estimate for the surcharge period to get the counterfactual density
all_bins_int <- data.table(bin_int = 30L:199L)
sur_bins <- dt_10[period == "3_surcharge", .(count = .N),
                   by = .(bin_int = as.integer(floor(capacity_kwp * 10)))]
sur_bins <- merge(all_bins_int, sur_bins, by = "bin_int", all.x = TRUE)
sur_bins[is.na(count), count := 0L]

# Fit counterfactual
sur_bins[, excluded := bin_int >= 90L & bin_int < 110L]
sur_bins[, z := bin_int - 100L]
for (p in 1:7) sur_bins[, paste0("z", p) := z^p]
formula_str <- paste0("count ~ ", paste(paste0("z", 1:7), collapse = " + "))
fit <- lm(as.formula(formula_str), data = sur_bins[excluded == FALSE])
sur_bins[, counterfactual := pmax(predict(fit, newdata = sur_bins), 0)]
sur_bins[, kwp := bin_int / 10]

# Restrict to main window for plotting
plot_data <- sur_bins[kwp >= 5 & kwp <= 15]
plot_long <- melt(plot_data, id.vars = "kwp",
                  measure.vars = c("count", "counterfactual"),
                  variable.name = "type", value.name = "installations")
plot_long[, type := ifelse(type == "count", "Observed", "Counterfactual")]

p4 <- ggplot() +
  geom_area(data = plot_data[excluded == TRUE],
            aes(x = kwp, y = pmax(count - counterfactual, 0)),
            fill = "#D55E00", alpha = 0.3) +
  geom_line(data = plot_long, aes(x = kwp, y = installations, linetype = type),
            linewidth = 0.6) +
  geom_vline(xintercept = 10.0, linetype = "dashed", color = "black", linewidth = 0.3) +
  scale_linetype_manual(values = c("Observed" = "solid", "Counterfactual" = "dashed")) +
  scale_x_continuous(breaks = 5:15) +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Observed vs. Counterfactual Density (Surcharge Period, 2014-2020)",
    subtitle = "7th-degree polynomial counterfactual, [9.0, 11.0) exclusion window",
    x = "Installed Capacity (kWp)",
    y = "Number of Installations (0.1 kWp bins)"
  ) +
  annotate("text", x = 9.5, y = max(plot_data$count) * 0.7,
           label = "Excess\nmass", size = 3, color = "#D55E00") +
  theme_apep

ggsave("../figures/fig4_counterfactual.pdf", p4, width = 8, height = 5)
ggsave("../figures/fig4_counterfactual.png", p4, width = 8, height = 5, dpi = 300)

# ============================================================
# FIGURE 5: Module Count Distribution Near Threshold
# ============================================================

cat("Figure 5: Module count distribution...\n")

# Surcharge period, near 10 kWp, with module data
dt_mod <- dt_10[period == "3_surcharge" & !is.na(n_modules) &
                 capacity_kwp >= 8 & capacity_kwp <= 12 &
                 n_modules >= 10 & n_modules <= 50]
dt_mod[, below_threshold := capacity_kwp < 10]

p5 <- ggplot(dt_mod, aes(x = n_modules, fill = below_threshold)) +
  geom_histogram(binwidth = 1, position = "identity", alpha = 0.6) +
  scale_fill_manual(values = c("TRUE" = "#D55E00", "FALSE" = "#56B4E9"),
                    labels = c("TRUE" = "Below 10 kWp", "FALSE" = "At/Above 10 kWp")) +
  labs(
    title = "Module Count: Systems Near 10 kWp Threshold",
    subtitle = "Surcharge period (2014-2020), rooftop installations",
    x = "Number of Solar Modules",
    y = "Number of Installations"
  ) +
  theme_apep

ggsave("../figures/fig5_module_count.pdf", p5, width = 8, height = 5)
ggsave("../figures/fig5_module_count.png", p5, width = 8, height = 5, dpi = 300)

# ============================================================
# FIGURE 6: Rooftop vs Ground-Mount Placebo
# ============================================================

cat("Figure 6: Rooftop vs ground-mount...\n")

# Rooftop (surcharge period)
roof_bins <- dt_10[period == "3_surcharge" & capacity_kwp >= 8 & capacity_kwp <= 12,
                    .(count = .N), by = .(bin = floor(capacity_kwp * 10) / 10)]
roof_bins[, total := sum(count)]
roof_bins[, share := count / total]
roof_bins[, type := "Rooftop"]

# Ground-mount (surcharge period)
gm_bins <- dt_gm[period == "3_surcharge" & capacity_kwp >= 8 & capacity_kwp <= 12,
                   .(count = .N), by = .(bin = floor(capacity_kwp * 10) / 10)]
gm_bins[, total := sum(count)]
gm_bins[, share := count / total]
gm_bins[, type := "Ground-mount"]

placebo_data <- rbind(roof_bins, gm_bins)

p6 <- ggplot(placebo_data, aes(x = bin, y = share, color = type)) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 1) +
  geom_vline(xintercept = 10.0, linetype = "dashed", color = "black", linewidth = 0.3) +
  scale_color_manual(values = c("Rooftop" = "#D55E00", "Ground-mount" = "#56B4E9")) +
  scale_x_continuous(breaks = seq(8, 12, 0.5)) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
  labs(
    title = "Installation Type Placebo: Rooftop vs. Ground-Mount",
    subtitle = "Surcharge period (2014-2020), 0.1 kWp bins, share of type total",
    x = "Installed Capacity (kWp)",
    y = "Share of Installations"
  ) +
  theme_apep

ggsave("../figures/fig6_placebo_type.pdf", p6, width = 8, height = 5)
ggsave("../figures/fig6_placebo_type.png", p6, width = 8, height = 5, dpi = 300)

# ============================================================
# FIGURE 7: State-Level Bunching Heterogeneity (Forest Plot)
# ============================================================

cat("Figure 7: State-level heterogeneity...\n")

# Estimate bunching by state for surcharge period
states <- dt_10[period == "3_surcharge", .N, by = federal_state][N > 5000, federal_state]
all_bins_int_st <- data.table(bin_int = 30L:199L)

state_results <- list()
for (st in states) {
  st_bins <- dt_10[period == "3_surcharge" & federal_state == st,
                    .(count = .N), by = .(bin_int = as.integer(floor(capacity_kwp * 10)))]
  st_bins <- merge(all_bins_int_st, st_bins, by = "bin_int", all.x = TRUE)
  st_bins[is.na(count), count := 0L]

  st_bins[, excluded := bin_int >= 90L & bin_int < 110L]
  st_bins[, z := bin_int - 100L]
  for (p in 1:7) st_bins[, paste0("z", p) := z^p]
  fit <- tryCatch(lm(as.formula(paste0("count ~ ", paste(paste0("z", 1:7), collapse = " + "))),
                      data = st_bins[excluded == FALSE]),
                  error = function(e) NULL)
  if (is.null(fit)) next

  st_bins[, counterfactual := pmax(predict(fit, newdata = st_bins), 0)]
  excess <- sum(st_bins[excluded == TRUE, count - counterfactual])
  f0 <- st_bins[bin_int == 100L, counterfactual]
  if (length(f0) == 0 || is.na(f0) || f0 <= 0) f0 <- mean(st_bins[excluded == FALSE]$counterfactual)
  b <- excess / f0

  state_results[[st]] <- data.table(
    state = st,
    bunching_ratio = b,
    n = dt_10[period == "3_surcharge" & federal_state == st, .N]
  )
}

state_dt <- rbindlist(state_results)
state_dt <- state_dt[order(bunching_ratio)]
state_dt[, state := factor(state, levels = state)]

p7 <- ggplot(state_dt, aes(x = bunching_ratio, y = state)) +
  geom_point(size = 2.5, color = "#D55E00") +
  geom_vline(xintercept = period_10[period == "3_surcharge", bunching_ratio],
             linetype = "dashed", color = "grey50") +
  labs(
    title = "Bunching Ratio by Federal State",
    subtitle = "Surcharge period (2014-2020), rooftop installations",
    x = "Bunching Ratio (b)",
    y = NULL
  ) +
  theme_apep +
  theme(panel.grid.major.y = element_line(color = "grey90"))

ggsave("../figures/fig7_state_heterogeneity.pdf", p7, width = 7, height = 6)
ggsave("../figures/fig7_state_heterogeneity.png", p7, width = 7, height = 6, dpi = 300)

# Save state results for tables
fwrite(state_dt, "../data/state_bunching.csv")

cat("\nAll figures saved to figures/\n")
cat("Files:\n")
cat(paste(" ", list.files("../figures/"), collapse = "\n"), "\n")
