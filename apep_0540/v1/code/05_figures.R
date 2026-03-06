# 05_figures.R — Generate all figures
# APEP-0540: Grand Paris Express Construction-Phase Capitalization

source("00_packages.R")

cat("=== PHASE 5: FIGURES ===\n")

# ──────────────────────────────────────────────────────────────────
# Figure 1: GPE Station Map with Treatment Rings
# ──────────────────────────────────────────────────────────────────

cat("Figure 1: GPE station map...\n")

stations <- fread(file.path(DATA_DIR, "gpe_stations.csv"))
milestones <- fread(file.path(DATA_DIR, "gpe_milestones.csv"))

stations_m <- merge(stations, milestones[, .(line, opening_date, construction_start)],
                    by = "line", all.x = TRUE)
stations_m[, opening_year := year(as.Date(opening_date))]
# Replace NA opening year with "TBD" for display
stations_m[, opening_label := fifelse(is.na(opening_year), "TBD", as.character(opening_year))]

p1 <- ggplot(stations_m, aes(x = lon, y = lat, color = opening_label)) +
  geom_point(size = 2.5, alpha = 0.9) +
  scale_color_viridis_d(name = "Opening Year", option = "plasma", na.value = "grey50") +
  labs(title = "Grand Paris Express Stations",
       subtitle = "69 new stations across 4 metro lines, opening 2024-2031",
       x = "Longitude", y = "Latitude") +
  coord_fixed(ratio = 1.3) +
  theme(legend.position = "right")

ggsave(file.path(FIG_DIR, "fig1_station_map.pdf"), p1, width = 8, height = 6)
cat("  Saved fig1_station_map.pdf\n")

# ──────────────────────────────────────────────────────────────────
# Figure 2: Treatment Rollout Timeline
# ──────────────────────────────────────────────────────────────────

cat("Figure 2: Treatment rollout...\n")

rollout_data <- milestones[, .(line_label, dup_date, construction_start, opening_date)]
rollout_long <- melt(rollout_data,
                     id.vars = "line_label",
                     variable.name = "milestone",
                     value.name = "date")
rollout_long[, date := as.Date(date)]
rollout_long[, milestone := factor(milestone,
  levels = c("dup_date", "construction_start", "opening_date"),
  labels = c("DUP", "Construction Start", "Opening"))]

p2 <- ggplot(rollout_long, aes(x = date, y = reorder(line_label, as.numeric(date)),
                                 color = milestone, shape = milestone)) +
  geom_point(size = 3) +
  scale_color_manual(values = c("DUP" = "#2166AC", "Construction Start" = "#B2182B",
                                 "Opening" = "#1B7837")) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  geom_vline(xintercept = as.Date("2020-01-01"), linetype = "dashed", alpha = 0.5) +
  annotate("text", x = as.Date("2020-01-01"), y = 0.5, label = "DVF data start",
           hjust = -0.1, size = 3, alpha = 0.6) +
  labs(title = "Grand Paris Express: Staggered Treatment Timeline",
       subtitle = "Three milestone types per line segment",
       x = "", y = "", color = "Milestone", shape = "Milestone") +
  theme(legend.position = "bottom")

ggsave(file.path(FIG_DIR, "fig2_rollout_timeline.pdf"), p2, width = 9, height = 5)
cat("  Saved fig2_rollout_timeline.pdf\n")

# ──────────────────────────────────────────────────────────────────
# Figure 3: Raw Price Trends by Treatment Ring
# ──────────────────────────────────────────────────────────────────

cat("Figure 3: Raw price trends...\n")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
panel[, date := as.Date(date)]
panel[, year_quarter_date := floor_date(date, "quarter")]

# Assign ring label
panel[, ring_label := "Buffer (excluded)"]
panel[ring_500m == TRUE, ring_label := "Within 500m"]
panel[ring_1km == TRUE & ring_500m == FALSE, ring_label := "500m-1km"]
panel[control == TRUE, ring_label := "Control (>2km)"]

trends <- panel[ring_label != "Buffer (excluded)",
  .(mean_price_m2 = mean(price_m2, na.rm = TRUE),
    median_price_m2 = median(price_m2, na.rm = TRUE),
    n = .N),
  by = .(year_quarter_date, ring_label)]

p3 <- ggplot(trends, aes(x = year_quarter_date, y = mean_price_m2, color = ring_label)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5, alpha = 0.7) +
  scale_color_manual(values = c("Within 500m" = "#D73027", "500m-1km" = "#FC8D59",
                                 "Control (>2km)" = "#4575B4")) +
  scale_y_continuous(labels = scales::comma_format(prefix = "\u20AC")) +
  labs(title = "Mean Transaction Price per m\u00B2 by Distance to Nearest GPE Station",
       subtitle = "Ile-de-France residential transactions",
       x = "", y = "Price per m\u00B2 (\u20AC)", color = "Distance Ring") +
  theme(legend.position = "bottom")

ggsave(file.path(FIG_DIR, "fig3_raw_trends.pdf"), p3, width = 9, height = 6)
cat("  Saved fig3_raw_trends.pdf\n")

# ──────────────────────────────────────────────────────────────────
# Figure 4: Event Study (Main Specification)
# ──────────────────────────────────────────────────────────────────

cat("Figure 4: Event study...\n")

es_dt <- fread(file.path(DATA_DIR, "event_study_coefficients.csv"))

p4 <- ggplot(es_dt, aes(x = event_quarter, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "red", alpha = 0.7) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_high), alpha = 0.2, fill = "#2166AC") +
  geom_point(size = 2, color = "#2166AC") +
  geom_line(color = "#2166AC", linewidth = 0.5) +
  annotate("text", x = -0.5, y = max(es_dt$ci_high, na.rm = TRUE),
           label = "Construction\nStart", hjust = 1.1, size = 3, color = "red") +
  scale_x_continuous(breaks = seq(-16, 20, by = 4)) +
  labs(title = "Event Study: Property Prices Near GPE Stations",
       subtitle = "Relative to construction start quarter (1km ring, commune + quarter FE)",
       x = "Quarters Relative to Construction Start",
       y = "Coefficient (log price per m\u00B2)") +
  theme(panel.grid.major.x = element_blank())

ggsave(file.path(FIG_DIR, "fig4_event_study.pdf"), p4, width = 9, height = 6)
cat("  Saved fig4_event_study.pdf\n")

# ──────────────────────────────────────────────────────────────────
# Figure 5: Phase Decomposition
# ──────────────────────────────────────────────────────────────────

cat("Figure 5: Phase decomposition...\n")

main_results <- fread(file.path(DATA_DIR, "main_results.csv"))
phase_data <- main_results[specification %like% "Phase"]
phase_data[, phase := gsub("Phase: ", "", specification)]
phase_data[, phase := factor(phase, levels = c("post-DUP", "construction", "opened"))]
phase_data[, ci_low := estimate - 1.96 * se]
phase_data[, ci_high := estimate + 1.96 * se]

p5 <- ggplot(phase_data, aes(x = phase, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  geom_pointrange(aes(ymin = ci_low, ymax = ci_high),
                  color = "#2166AC", size = 0.8) +
  labs(title = "Capitalization by Infrastructure Phase",
       subtitle = "Within 1km of GPE station, relative to pre-announcement period",
       x = "", y = "Effect on log(price per m\u00B2)") +
  theme(axis.text.x = element_text(size = 11))

ggsave(file.path(FIG_DIR, "fig5_phase_decomposition.pdf"), p5, width = 7, height = 5)
cat("  Saved fig5_phase_decomposition.pdf\n")

# ──────────────────────────────────────────────────────────────────
# Figure 6: Distance Gradient
# ──────────────────────────────────────────────────────────────────

cat("Figure 6: Distance gradient...\n")

dist_grad <- fread(file.path(DATA_DIR, "distance_gradient.csv"))

p6 <- ggplot(dist_grad, aes(x = ring_km, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  geom_pointrange(aes(ymin = ci_low, ymax = ci_high),
                  color = "#D73027", size = 0.8) +
  scale_x_continuous(breaks = c(0.5, 1.0, 1.5),
                     labels = c("0-500m", "0-1km", "0-1.5km")) +
  labs(title = "Construction-Phase Capitalization by Distance",
       subtitle = "Effect decays with distance from nearest GPE station",
       x = "Treatment Ring", y = "Effect on log(price per m\u00B2)")

ggsave(file.path(FIG_DIR, "fig6_distance_gradient.pdf"), p6, width = 7, height = 5)
cat("  Saved fig6_distance_gradient.pdf\n")

# ──────────────────────────────────────────────────────────────────
# Figure 7: CS-DiD vs TWFE Event Study Comparison
# ──────────────────────────────────────────────────────────────────

cat("Figure 7: CS-DiD vs TWFE comparison...\n")

cs_file <- file.path(DATA_DIR, "cs_did_event_study.csv")
if (file.exists(cs_file)) {
  cs_es <- fread(cs_file)
  cs_es[, estimator := "Callaway-Sant'Anna"]
  setnames(cs_es, "att", "estimate")
  setnames(cs_es, "event_time", "event_quarter")

  twfe_es <- es_dt[, .(event_quarter, estimate, se, ci_low, ci_high)]
  twfe_es[, estimator := "TWFE"]

  combined_es <- rbind(cs_es[, .(event_quarter, estimate, ci_low, ci_high, estimator)],
                       twfe_es[, .(event_quarter, estimate, ci_low, ci_high, estimator)])

  p7 <- ggplot(combined_es, aes(x = event_quarter, y = estimate, color = estimator)) +
    geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
    geom_vline(xintercept = -0.5, linetype = "dotted", alpha = 0.5) +
    geom_ribbon(aes(ymin = ci_low, ymax = ci_high, fill = estimator), alpha = 0.15) +
    geom_point(size = 1.5) +
    geom_line(linewidth = 0.5) +
    scale_color_manual(values = c("TWFE" = "#2166AC", "Callaway-Sant'Anna" = "#B2182B")) +
    scale_fill_manual(values = c("TWFE" = "#2166AC", "Callaway-Sant'Anna" = "#B2182B")) +
    labs(title = "Event Study: TWFE vs. Callaway-Sant'Anna",
         subtitle = "Checking for heterogeneous treatment effect bias",
         x = "Quarters Relative to Construction Start",
         y = "Coefficient", color = "Estimator", fill = "Estimator") +
    theme(legend.position = "bottom")

  ggsave(file.path(FIG_DIR, "fig7_cs_vs_twfe.pdf"), p7, width = 9, height = 6)
  cat("  Saved fig7_cs_vs_twfe.pdf\n")
} else {
  cat("  CS-DiD results not available. Skipping fig7.\n")
}

# ──────────────────────────────────────────────────────────────────
# Figure 8: Leave-One-Line-Out
# ──────────────────────────────────────────────────────────────────

cat("Figure 8: Leave-one-line-out...\n")

lolo_file <- file.path(DATA_DIR, "leave_one_line_out.csv")
if (file.exists(lolo_file)) {
  lolo <- fread(lolo_file)

  p8 <- ggplot(lolo, aes(x = reorder(dropped_line, estimate), y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
    geom_pointrange(aes(ymin = ci_low, ymax = ci_high), color = "#2166AC", size = 0.6) +
    coord_flip() +
    labs(title = "Leave-One-Line-Out Sensitivity",
         subtitle = "Main DiD estimate dropping each GPE line",
         x = "Dropped Line", y = "Effect on log(price per m\u00B2)")

  ggsave(file.path(FIG_DIR, "fig8_leave_one_line_out.pdf"), p8, width = 7, height = 5)
  cat("  Saved fig8_leave_one_line_out.pdf\n")
}

cat("\n=== FIGURES COMPLETE ===\n")
