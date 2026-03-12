## 05_figures.R — Generate all figures
## apep_0486 v2: Progressive Prosecutors, Incarceration, and Public Safety
## NEW in v2: Race-specific event study, US map, metro vs full comparison

source("00_packages.R")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, fips := str_pad(as.character(fips), width = 5, pad = "0")]

cat("=== FIGURE 1: Event Study — Jail Population Rate ===\n")

es_jail <- tryCatch(fread(file.path(DATA_DIR, "es_jail_rate.csv")), error = function(e) NULL)

if (!is.null(es_jail) && nrow(es_jail) > 0) {
  fig1 <- ggplot(es_jail, aes(x = event_time, y = att)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "gray70") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
                fill = APEP_COLORS["ci"], alpha = 0.4) +
    geom_point(color = APEP_COLORS["treated"], size = 2.5) +
    geom_line(color = APEP_COLORS["treated"], linewidth = 0.8) +
    labs(
      x = "Years Relative to DA Taking Office",
      y = "ATT (Jail Population per 100,000)"
    ) +
    scale_x_continuous(breaks = seq(-8, 6, 2)) +
    annotate("text", x = -6, y = max(es_jail$ci_upper, na.rm = TRUE) * 0.9,
             label = "Pre-treatment", hjust = 0, color = "gray40", size = 3.5) +
    annotate("text", x = 2, y = max(es_jail$ci_upper, na.rm = TRUE) * 0.9,
             label = "Post-treatment", hjust = 0, color = "gray40", size = 3.5)

  ggsave(file.path(FIGURE_DIR, "fig1_event_study_jail.pdf"),
         fig1, width = 8, height = 5)
  cat("Figure 1 saved\n")
}

cat("\n=== FIGURE 2: Event Study — Homicide Rate ===\n")

es_hom <- tryCatch(fread(file.path(DATA_DIR, "es_homicide_rate.csv")), error = function(e) NULL)

if (!is.null(es_hom) && nrow(es_hom) > 0) {
  fig2 <- ggplot(es_hom, aes(x = event_time, y = att)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "gray70") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
                fill = APEP_COLORS["ci"], alpha = 0.4) +
    geom_point(color = APEP_COLORS["control"], size = 2.5) +
    geom_line(color = APEP_COLORS["control"], linewidth = 0.8) +
    labs(
      x = "Years Relative to DA Taking Office",
      y = "ATT (Homicides per 100,000)"
    ) +
    scale_x_continuous(breaks = seq(-8, 6, 2))

  ggsave(file.path(FIGURE_DIR, "fig2_event_study_homicide.pdf"),
         fig2, width = 8, height = 5)
  cat("Figure 2 saved\n")
}

cat("\n=== FIGURE 3: Treatment Timing (promoted to main text) ===\n")

treatment <- fread(file.path(DATA_DIR, "progressive_da_treatment.csv"))
treatment[, fips := str_pad(as.character(fips), width = 5, pad = "0")]

fig3 <- ggplot(treatment, aes(x = treatment_year, y = reorder(county_name, -treatment_year))) +
  geom_point(size = 3, color = APEP_COLORS["treated"]) +
  geom_segment(aes(xend = 2024, yend = county_name),
               color = APEP_COLORS["treated"], alpha = 0.3) +
  labs(
    x = "Year DA Took Office",
    y = NULL
  ) +
  scale_x_continuous(breaks = seq(2015, 2023, 1)) +
  theme(axis.text.y = element_text(size = 8))

ggsave(file.path(FIGURE_DIR, "fig3_treatment_timing.pdf"),
       fig3, width = 7, height = 7)
cat("Figure 3 saved\n")

cat("\n=== FIGURE 4: Race-Specific CS-DiD Event Study (NEW v2 — KEY FIGURE) ===\n")

es_black <- tryCatch(fread(file.path(DATA_DIR, "es_black_jail_rate.csv")), error = function(e) NULL)
es_white <- tryCatch(fread(file.path(DATA_DIR, "es_white_jail_rate.csv")), error = function(e) NULL)

if (!is.null(es_black) && !is.null(es_white) && nrow(es_black) > 0 && nrow(es_white) > 0) {
  race_es <- rbind(es_black, es_white)

  fig4 <- ggplot(race_es, aes(x = event_time, y = att, color = race, fill = race)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "gray70") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.12, color = NA) +
    geom_line(linewidth = 0.9) +
    geom_point(size = 2.5) +
    scale_color_manual(values = c("Black" = APEP_COLORS["black"],
                                   "White" = APEP_COLORS["white"]),
                       labels = c("Black" = "Black Jail Rate",
                                  "White" = "White Jail Rate")) +
    scale_fill_manual(values = c("Black" = APEP_COLORS["black"],
                                  "White" = APEP_COLORS["white"]),
                      labels = c("Black" = "Black Jail Rate",
                                 "White" = "White Jail Rate")) +
    labs(
      x = "Years Relative to DA Taking Office",
      y = "ATT (Jail Rate per 100,000)"
    ) +
    scale_x_continuous(breaks = seq(-8, 6, 2)) +
    annotate("text", x = -6, y = max(race_es$ci_upper, na.rm = TRUE) * 0.85,
             label = "Pre-treatment", hjust = 0, color = "gray40", size = 3.5) +
    annotate("text", x = 2, y = max(race_es$ci_upper, na.rm = TRUE) * 0.85,
             label = "Post-treatment", hjust = 0, color = "gray40", size = 3.5)

  ggsave(file.path(FIGURE_DIR, "fig4_race_event_study.pdf"),
         fig4, width = 9, height = 5.5)
  cat("Figure 4 (Race-specific event study) saved\n")
} else {
  cat("Race-specific event study data not available; generating from raw trends\n")

  # Fallback: raw trends by race and treatment
  bw_trends <- panel[!is.na(black_jail_rate) & !is.na(white_jail_rate), .(
    mean_black = mean(black_jail_rate, na.rm = TRUE),
    mean_white = mean(white_jail_rate, na.rm = TRUE)
  ), by = .(year, ever_treated)]
  bw_trends[, group := fifelse(ever_treated == 1, "Progressive DA", "Other")]

  bw_long <- melt(bw_trends, id.vars = c("year", "group", "ever_treated"),
                  measure.vars = c("mean_black", "mean_white"),
                  variable.name = "race", value.name = "jail_rate")
  bw_long[, race := fifelse(race == "mean_black", "Black", "White")]

  fig4 <- ggplot(bw_long, aes(x = year, y = jail_rate, color = race, linetype = group)) +
    geom_line(linewidth = 0.9) +
    geom_point(size = 1.5) +
    scale_color_manual(values = c("Black" = APEP_COLORS["black"],
                                   "White" = "#2A9D8F")) +
    scale_linetype_manual(values = c("Progressive DA" = "solid", "Other" = "dashed")) +
    labs(
      x = "Year",
      y = "Mean Jail Rate (per 100,000)",
      color = "Race",
      linetype = "County Type"
    ) +
    scale_x_continuous(breaks = seq(2005, 2023, 2))

  ggsave(file.path(FIGURE_DIR, "fig4_race_event_study.pdf"),
         fig4, width = 9, height = 5.5)
  cat("Figure 4 (raw trends fallback) saved\n")
}

cat("\n=== FIGURE 5: Raw Trends — Treated vs Control ===\n")

trends <- panel[!is.na(jail_rate), .(
  mean_jail = mean(jail_rate, na.rm = TRUE),
  se_jail = sd(jail_rate, na.rm = TRUE) / sqrt(.N),
  n = .N
), by = .(year, ever_treated)]
trends[, group := fifelse(ever_treated == 1, "Progressive DA Counties", "Other Counties")]

fig5 <- ggplot(trends, aes(x = year, y = mean_jail, color = group)) +
  geom_line(linewidth = 1) +
  geom_point(size = 1.5) +
  geom_ribbon(aes(ymin = mean_jail - 1.96 * se_jail,
                  ymax = mean_jail + 1.96 * se_jail,
                  fill = group), alpha = 0.1, color = NA) +
  scale_color_manual(values = c("Progressive DA Counties" = APEP_COLORS["treated"],
                                 "Other Counties" = APEP_COLORS["control"])) +
  scale_fill_manual(values = c("Progressive DA Counties" = APEP_COLORS["treated"],
                                "Other Counties" = APEP_COLORS["control"])) +
  labs(
    x = "Year",
    y = "Mean Jail Population Rate (per 100,000)"
  ) +
  scale_x_continuous(breaks = seq(2005, 2023, 2))

ggsave(file.path(FIGURE_DIR, "fig5_raw_trends.pdf"),
       fig5, width = 8, height = 5)
cat("Figure 5 saved\n")

cat("\n=== FIGURE 6: Metro vs Full Sample Event Study Comparison (NEW v2) ===\n")

es_metro <- tryCatch(fread(file.path(DATA_DIR, "es_jail_rate_metro.csv")), error = function(e) NULL)

if (!is.null(es_jail) && !is.null(es_metro) && nrow(es_metro) > 0) {
  es_jail$sample <- "Full Sample"
  es_metro$sample <- "Metro Only"
  es_compare <- rbind(es_jail, es_metro)

  fig6 <- ggplot(es_compare, aes(x = event_time, y = att, color = sample, fill = sample)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "gray70") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.1, color = NA) +
    geom_line(linewidth = 0.8) +
    geom_point(size = 2) +
    scale_color_manual(values = c("Full Sample" = APEP_COLORS["treated"],
                                   "Metro Only" = APEP_COLORS["matched"])) +
    scale_fill_manual(values = c("Full Sample" = APEP_COLORS["treated"],
                                  "Metro Only" = APEP_COLORS["matched"])) +
    labs(
      x = "Years Relative to DA Taking Office",
      y = "ATT (Jail Rate per 100,000)"
    ) +
    scale_x_continuous(breaks = seq(-8, 6, 2))

  ggsave(file.path(FIGURE_DIR, "fig6_metro_comparison.pdf"),
         fig6, width = 9, height = 5.5)
  cat("Figure 6 (Metro comparison) saved\n")
} else {
  cat("Metro event study not available for comparison figure\n")
}

cat("\n=== FIGURE 7: Randomization Inference Distribution (NEW v2) ===\n")

ri_file <- file.path(DATA_DIR, "ri_distribution.csv")
if (file.exists(ri_file)) {
  ri_data <- fread(ri_file)

  results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
  actual_coef <- coef(results$twfe_jail)["treated"]

  fig7 <- ggplot(ri_data[!is.na(perm_coef)], aes(x = perm_coef)) +
    geom_histogram(bins = 50, fill = "gray70", color = "gray50", alpha = 0.7) +
    geom_vline(xintercept = actual_coef, color = APEP_COLORS["treated"],
               linewidth = 1.2, linetype = "solid") +
    labs(
      x = "Permuted Treatment Coefficient",
      y = "Frequency"
    ) +
    annotate("text", x = actual_coef, y = Inf,
             label = sprintf("Actual = %.0f", actual_coef),
             vjust = 2, hjust = -0.1, color = APEP_COLORS["treated"], fontface = "bold")

  ggsave(file.path(FIGURE_DIR, "fig7_ri_distribution.pdf"),
         fig7, width = 7, height = 4.5)
  cat("Figure 7 (RI distribution) saved\n")
}

cat("\n=== FIGURE 8: Leave-One-Out (moved to appendix) ===\n")

loo <- tryCatch(fread(file.path(DATA_DIR, "loo_results.csv")), error = function(e) NULL)
if (!is.null(loo) && nrow(loo) > 0) {
  results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
  full_coef <- coef(results$twfe_jail)["treated"]

  loo$dropped <- factor(loo$dropped, levels = rev(loo$dropped))

  fig8 <- ggplot(loo, aes(x = coef, y = dropped)) +
    geom_vline(xintercept = full_coef, linetype = "dashed", color = APEP_COLORS["treated"]) +
    geom_vline(xintercept = 0, linetype = "solid", color = "gray70") +
    geom_errorbarh(aes(xmin = coef - 1.96 * se, xmax = coef + 1.96 * se),
                   height = 0.2, color = APEP_COLORS["control"]) +
    geom_point(size = 3, color = APEP_COLORS["control"]) +
    labs(
      x = "TWFE Coefficient (Jail Rate per 100,000)",
      y = "Dropped County"
    )

  ggsave(file.path(FIGURE_DIR, "fig8_loo_influence.pdf"),
         fig8, width = 7, height = 4)
  cat("Figure 8 (LOO) saved\n")
}

cat("\n=== FIGURE 9: U.S. Map of Treated Counties (NEW v2) ===\n")

# Generate a simple dot map using lat/lon from Census
tryCatch({
  # Use county centroids from tigris/sf if available
  if (requireNamespace("sf", quietly = TRUE) && requireNamespace("tigris", quietly = TRUE)) {
    counties_sf <- tigris::counties(cb = TRUE, resolution = "20m", year = 2020)
    counties_sf$fips <- paste0(counties_sf$STATEFP, counties_sf$COUNTYFP)

    # Get centroids for treated counties
    treated_sf <- counties_sf[counties_sf$fips %in% treatment$fips, ]
    centroids <- sf::st_centroid(treated_sf)
    coords <- as.data.frame(sf::st_coordinates(centroids))
    coords$county_name <- treated_sf$NAME
    coords$fips <- treated_sf$fips
    coords <- merge(coords, treatment[, .(fips, treatment_year)], by = "fips")

    # Get all US counties for background
    us_map <- ggplot() +
      geom_sf(data = counties_sf, fill = "gray95", color = "gray80", linewidth = 0.1) +
      geom_point(data = coords, aes(x = X, y = Y, color = factor(treatment_year)),
                 size = 3, alpha = 0.9) +
      scale_color_viridis_d(option = "plasma", name = "Treatment Year") +
      coord_sf(xlim = c(-125, -65), ylim = c(24, 50)) +
      labs(x = NULL, y = NULL) +
      theme_minimal() +
      theme(
        panel.grid = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        legend.position = "bottom"
      )

    ggsave(file.path(FIGURE_DIR, "fig9_treatment_map.pdf"),
           us_map, width = 10, height = 6)
    cat("Figure 9 (Treatment map) saved\n")
  } else {
    cat("sf/tigris not available for map generation\n")
  }
}, error = function(e) {
  cat("Map generation failed:", e$message, "\n")
})

cat("\n=== FIGURES COMPLETE ===\n")
cat("Files in figures directory:\n")
cat(paste(list.files(FIGURE_DIR), collapse = "\n"), "\n")
