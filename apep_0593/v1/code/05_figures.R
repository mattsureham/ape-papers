# ============================================================================
# 05_figures.R — All figure generation (reads from CSVs, not in-memory)
# APEP-0593: Roaming Abolition and Cross-Border Tourism
# ============================================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel_main <- panel[time >= 2012 & time <= 2019]

# -----------------------------------------------------------------------
# Figure 1: Event Study — Binary Border Treatment
# -----------------------------------------------------------------------
es_coefs <- fread(file.path(data_dir, "event_study_coefs.csv"))

p1 <- ggplot(es_coefs, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray60") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "red3", linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_high), alpha = 0.15, fill = "steelblue") +
  geom_point(size = 2.5, color = "steelblue") +
  geom_line(color = "steelblue", linewidth = 0.5) +
  scale_x_continuous(breaks = sort(unique(es_coefs$event_time))) +
  labs(x = "Years relative to RLAH (June 2017)",
       y = "Coefficient (log foreign nights)",
       title = NULL) +
  annotate("text", x = -3, y = max(es_coefs$ci_high, na.rm = TRUE) * 0.9,
           label = "Pre-RLAH", hjust = 0.5, size = 3, color = "gray50") +
  annotate("text", x = 1, y = max(es_coefs$ci_high, na.rm = TRUE) * 0.9,
           label = "Post-RLAH", hjust = 0.5, size = 3, color = "gray50")

ggsave(file.path(fig_dir, "fig1_event_study.pdf"), p1,
       width = 7, height = 4.5, device = cairo_pdf)
cat("Figure 1: Event study saved.\n")

# -----------------------------------------------------------------------
# Figure 2: Event Study — Continuous Treatment (pre-treatment share)
# -----------------------------------------------------------------------
es_cont <- fread(file.path(data_dir, "event_study_cont_coefs.csv"))

p2 <- ggplot(es_cont, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray60") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "red3", linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_high), alpha = 0.15, fill = "darkorange") +
  geom_point(size = 2.5, color = "darkorange") +
  geom_line(color = "darkorange", linewidth = 0.5) +
  labs(x = "Years relative to RLAH (June 2017)",
       y = "Coefficient (log foreign nights)",
       title = NULL)

ggsave(file.path(fig_dir, "fig2_event_study_continuous.pdf"), p2,
       width = 7, height = 4.5, device = cairo_pdf)
cat("Figure 2: Continuous treatment event study saved.\n")

# -----------------------------------------------------------------------
# Figure 3: Raw trends — Border vs Interior foreign tourist nights
# -----------------------------------------------------------------------
# Use only regions with non-missing data in both foreign AND domestic
# to avoid the 2012 domestic near-zero artifact
trends <- panel_main[border_type %in% c("internal_border", "interior") &
                       !is.na(foreign_nights) & foreign_nights > 0 &
                       !is.na(domestic_nights) & domestic_nights > 0,
                     .(mean_foreign = mean(foreign_nights, na.rm = TRUE),
                       mean_domestic = mean(domestic_nights, na.rm = TRUE),
                       n_regions = .N),
                     by = .(time, border_type)]

# Normalize to 2016 = 100
trends <- merge(trends,
                trends[time == 2016, .(border_type,
                                       base_foreign = mean_foreign,
                                       base_domestic = mean_domestic)],
                by = "border_type")
trends[, idx_foreign := mean_foreign / base_foreign * 100]
trends[, idx_domestic := mean_domestic / base_domestic * 100]

p3 <- ggplot(trends, aes(x = time, y = idx_foreign, color = border_type,
                          shape = border_type)) +
  geom_vline(xintercept = 2016.5, linetype = "dotted", color = "red3", linewidth = 0.5) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 2.5) +
  scale_color_manual(values = c("internal_border" = "steelblue",
                                 "interior" = "gray50"),
                     labels = c("Border regions", "Interior regions")) +
  scale_shape_manual(values = c("internal_border" = 16, "interior" = 17),
                     labels = c("Border regions", "Interior regions")) +
  labs(x = "Year", y = "Foreign tourist nights (2016 = 100)",
       color = NULL, shape = NULL,
       title = NULL) +
  annotate("text", x = 2016.7, y = min(trends$idx_foreign) * 0.97,
           label = "RLAH", hjust = 0, size = 3, color = "red3")

ggsave(file.path(fig_dir, "fig3_raw_trends.pdf"), p3,
       width = 7, height = 4.5, device = cairo_pdf)
cat("Figure 3: Raw trends saved.\n")

# -----------------------------------------------------------------------
# Figure 4: Placebo — Domestic tourism trends (no effect expected)
# -----------------------------------------------------------------------
p4 <- ggplot(trends, aes(x = time, y = idx_domestic, color = border_type,
                          shape = border_type)) +
  geom_vline(xintercept = 2016.5, linetype = "dotted", color = "red3", linewidth = 0.5) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 2.5) +
  scale_color_manual(values = c("internal_border" = "steelblue",
                                 "interior" = "gray50"),
                     labels = c("Border regions", "Interior regions")) +
  scale_shape_manual(values = c("internal_border" = 16, "interior" = 17),
                     labels = c("Border regions", "Interior regions")) +
  labs(x = "Year", y = "Domestic tourist nights (2016 = 100)",
       color = NULL, shape = NULL, title = NULL) +
  annotate("text", x = 2016.7, y = min(trends$idx_domestic, na.rm = TRUE) * 0.97,
           label = "RLAH", hjust = 0, size = 3, color = "red3")

ggsave(file.path(fig_dir, "fig4_placebo_domestic.pdf"), p4,
       width = 7, height = 4.5, device = cairo_pdf)
cat("Figure 4: Domestic placebo saved.\n")

# -----------------------------------------------------------------------
# Figure 5: Leave-one-country-out stability
# -----------------------------------------------------------------------
loo <- fread(file.path(data_dir, "loo_results.csv"))

# Get full-sample estimate for reference line
main_results <- fread(file.path(data_dir, "main_results.csv"))
full_beta <- main_results[model == "Binary DiD (log)"]$beta

p5 <- ggplot(loo, aes(x = reorder(excluded, beta), y = beta)) +
  geom_hline(yintercept = full_beta, linetype = "dashed", color = "steelblue") +
  geom_hline(yintercept = 0, linetype = "solid", color = "gray70") +
  geom_point(size = 3, color = "darkorange") +
  geom_errorbar(aes(ymin = beta - 1.96 * se, ymax = beta + 1.96 * se),
                width = 0.3, color = "darkorange") +
  coord_flip() +
  labs(x = "Country excluded", y = "Border × Post coefficient (log foreign nights)",
       title = NULL)

ggsave(file.path(fig_dir, "fig5_leave_one_out.pdf"), p5,
       width = 6, height = 5, device = cairo_pdf)
cat("Figure 5: Leave-one-out saved.\n")

# -----------------------------------------------------------------------
# Figure 6: Map of border classification
# -----------------------------------------------------------------------
tryCatch({
  nuts2_sf <- sf::st_read(file.path(data_dir, "nuts2_2016.gpkg"), quiet = TRUE)
  border_class <- fread(file.path(data_dir, "border_classification.csv"))

  nuts2_map <- merge(nuts2_sf, border_class, by.x = "id", by.y = "geo", all.x = TRUE)
  nuts2_map$border_type[is.na(nuts2_map$border_type)] <- "non-EU"

  # Filter to continental Europe for visibility
  nuts2_map <- nuts2_map[!grepl("^(FRY|ES70|PT20|PT30)", nuts2_map$id), ]

  p6 <- ggplot(nuts2_map) +
    geom_sf(aes(fill = border_type), color = "white", linewidth = 0.1) +
    scale_fill_manual(
      values = c("internal_border" = "steelblue",
                 "external_border" = "darkorange",
                 "interior" = "gray85",
                 "non-EU" = "gray95"),
      labels = c("Internal EU border", "External EU border",
                 "Interior", "Non-EU"),
      name = NULL
    ) +
    coord_sf(xlim = c(-12, 35), ylim = c(35, 72)) +
    labs(title = NULL) +
    theme_void() +
    theme(legend.position = "bottom")

  ggsave(file.path(fig_dir, "fig6_border_map.pdf"), p6,
         width = 7, height = 6, device = cairo_pdf)
  cat("Figure 6: Border map saved.\n")
}, error = function(e) {
  cat("Figure 6 skipped (map generation error):", e$message, "\n")
})

# Save trends data for reproducibility
fwrite(trends, file.path(data_dir, "figure_trends_data.csv"))

cat("\nAll figures generated.\n")
