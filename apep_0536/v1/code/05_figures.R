# ==============================================================================
# 05_figures.R — Generate all figures
# APEP apep_0536: FTTH, Polarization, and Misinformation in France
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

# ==============================================================================
# Figure 1: FTTH Rollout Across Departments Over Time
# ==============================================================================

cat("=== Figure 1: FTTH Rollout ===\n")

ftth <- fread(file.path(data_dir, "ftth_dept_quarter.csv"))
ftth[, date := as.Date(paste(year, quarter * 3, "01", sep = "-"))]

# National average + department-level spaghetti
ftth_nat <- ftth[, .(mean_coverage = mean(ftth_coverage, na.rm = TRUE),
                      p25 = quantile(ftth_coverage, 0.25, na.rm = TRUE),
                      p75 = quantile(ftth_coverage, 0.75, na.rm = TRUE)),
                  by = date]

p1 <- ggplot() +
  geom_line(data = ftth, aes(x = date, y = ftth_coverage, group = dept_code),
            color = "grey70", alpha = 0.3, linewidth = 0.3) +
  geom_ribbon(data = ftth_nat, aes(x = date, ymin = p25, ymax = p75),
              fill = "#2166ac", alpha = 0.2) +
  geom_line(data = ftth_nat, aes(x = date, y = mean_coverage),
            color = "#2166ac", linewidth = 1.2) +
  geom_vline(xintercept = as.Date("2022-04-10"), linetype = "dashed", color = "red", alpha = 0.5) +
  annotate("text", x = as.Date("2022-04-10"), y = 0.05,
           label = "2022\nPresidential", size = 2.5, hjust = -0.1, color = "red") +
  geom_vline(xintercept = as.Date("2024-06-09"), linetype = "dashed", color = "red", alpha = 0.5) +
  annotate("text", x = as.Date("2024-06-09"), y = 0.05,
           label = "2024\nEuropean", size = 2.5, hjust = -0.1, color = "red") +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
  labs(x = NULL, y = "FTTH Coverage Rate",
       title = "Staggered FTTH Rollout Across French Departments",
       subtitle = "Each grey line = one department; blue = national mean (IQR shaded)") +
  theme(plot.subtitle = element_text(size = 9, color = "grey40"))

ggsave(file.path(fig_dir, "fig1_ftth_rollout.pdf"), p1, width = 7, height = 4.5)
ggsave(file.path(fig_dir, "fig1_ftth_rollout.png"), p1, width = 7, height = 4.5, dpi = 300)
cat("  Saved fig1_ftth_rollout.pdf\n")

# ==============================================================================
# Figure 2: Anti-System Vote Share Over Time (by FTTH Speed)
# ==============================================================================

cat("=== Figure 2: Anti-System Trends ===\n")

panel <- fread(file.path(data_dir, "analysis_panel.csv"))

# Split departments into early vs late FTTH adoption (median split on 2022 coverage)
ftth_2022 <- fread(file.path(data_dir, "ftth_dept_quarter.csv"))[
  year == 2022 & quarter == 2, .(dept_code, ftth_2022 = ftth_coverage)]
panel <- merge(panel, ftth_2022, by = "dept_code", all.x = TRUE)
panel[, ftth_group := fifelse(ftth_2022 > median(ftth_2022, na.rm = TRUE),
                               "Early FTTH (above median)", "Late FTTH (below median)")]

trends <- panel[, .(mean_antisystem = mean(antisystem_share, na.rm = TRUE),
                      se = sd(antisystem_share, na.rm = TRUE) / sqrt(.N)),
                 by = .(election_year, ftth_group)]

p2 <- ggplot(trends, aes(x = election_year, y = mean_antisystem,
                           color = ftth_group, shape = ftth_group)) +
  geom_point(size = 2.5) +
  geom_line(linewidth = 0.8) +
  geom_errorbar(aes(ymin = mean_antisystem - 1.96 * se,
                      ymax = mean_antisystem + 1.96 * se), width = 0.3) +
  geom_vline(xintercept = 2017.5, linetype = "dashed", color = "grey50") +
  annotate("text", x = 2017.5, y = 0.02, label = "FTTH rollout\nbegins", size = 2.5,
           hjust = -0.1, color = "grey40") +
  scale_y_continuous(labels = scales::percent) +
  scale_color_manual(values = c("#d6604d", "#4393c3")) +
  labs(x = "Election Year", y = "Anti-System Vote Share (% of Registered)",
       title = "Anti-System Vote Trends by FTTH Adoption Speed",
       color = NULL, shape = NULL) +
  theme(legend.position = c(0.3, 0.85),
        legend.background = element_rect(fill = "white", color = NA))

ggsave(file.path(fig_dir, "fig2_antisystem_trends.pdf"), p2, width = 7, height = 5)
ggsave(file.path(fig_dir, "fig2_antisystem_trends.png"), p2, width = 7, height = 5, dpi = 300)
cat("  Saved fig2_antisystem_trends.pdf\n")

# ==============================================================================
# Figure 3: CS-DiD Event Study
# ==============================================================================

cat("=== Figure 3: Event Study ===\n")

es <- fread(file.path(data_dir, "cs_event_study.csv"))
es[, `:=`(
  ci_lower = estimate - 1.96 * se,
  ci_upper = estimate + 1.96 * se
)]

p3 <- ggplot(es, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey50", linewidth = 0.3) +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey60") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), fill = "#2166ac", alpha = 0.15) +
  geom_point(color = "#2166ac", size = 2) +
  geom_line(color = "#2166ac", linewidth = 0.6) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.2, color = "#2166ac") +
  scale_x_continuous(breaks = seq(-8, 2, 1)) +
  labs(x = "Elections Relative to FTTH Treatment",
       y = "ATT: Anti-System Vote Share",
       title = "Event Study: FTTH Coverage and Anti-System Voting",
       subtitle = "Callaway-Sant'Anna (2021), not-yet-treated comparison group") +
  theme(plot.subtitle = element_text(size = 9, color = "grey40"))

ggsave(file.path(fig_dir, "fig3_event_study.pdf"), p3, width = 7, height = 5)
ggsave(file.path(fig_dir, "fig3_event_study.png"), p3, width = 7, height = 5, dpi = 300)
cat("  Saved fig3_event_study.pdf\n")

# ==============================================================================
# Figure 4: FTTH Coverage Map (2022)
# ==============================================================================

cat("=== Figure 4: Coverage Map ===\n")

# Create a simple choropleth of FTTH coverage by department
# Use the administrative boundaries (sf)
tryCatch({
  france_url <- "https://raw.githubusercontent.com/gregoiredavid/france-geojson/master/departements.geojson"
  dept_sf <- sf::st_read(france_url, quiet = TRUE)

  # Match department codes
  ftth_map <- merge(dept_sf, ftth_2022, by.x = "code", by.y = "dept_code", all.x = TRUE)

  # Filter to metropolitan France
  ftth_map_metro <- ftth_map[ftth_map$code %in% c(sprintf("%02d", 1:19), "2A", "2B", sprintf("%02d", 21:95)), ]

  p4 <- ggplot(ftth_map_metro) +
    geom_sf(aes(fill = ftth_2022), color = "white", linewidth = 0.2) +
    scale_fill_viridis_c(option = "plasma", labels = scales::percent,
                          name = "FTTH\nCoverage", limits = c(0, 1)) +
    labs(title = "FTTH Coverage by Department (Q2 2022)",
         subtitle = "Source: ARCEP Observatory") +
    theme_void() +
    theme(plot.title = element_text(face = "bold", size = 12),
          plot.subtitle = element_text(size = 9, color = "grey40"),
          legend.position = c(0.15, 0.3))

  ggsave(file.path(fig_dir, "fig4_ftth_map.pdf"), p4, width = 6, height = 7)
  ggsave(file.path(fig_dir, "fig4_ftth_map.png"), p4, width = 6, height = 7, dpi = 300)
  cat("  Saved fig4_ftth_map.pdf\n")
}, error = function(e) {
  cat("  Map generation failed:", e$message, "\n")
  cat("  Skipping map figure.\n")
})

# ==============================================================================
# Figure 5: Jackknife Stability
# ==============================================================================

cat("=== Figure 5: Jackknife ===\n")

jack <- fread(file.path(data_dir, "jackknife_results.csv"))

p5 <- ggplot(jack, aes(x = reorder(dept_dropped, estimate), y = estimate)) +
  geom_point(size = 1, color = "#2166ac") +
  geom_hline(yintercept = mean(jack$estimate), color = "red", linetype = "dashed") +
  geom_hline(yintercept = 0, color = "grey50") +
  coord_flip() +
  labs(x = "Department Dropped", y = "TWFE Coefficient on FTTH Coverage",
       title = "Leave-One-Department-Out Jackknife",
       subtitle = "Red dashed = full-sample estimate") +
  theme(axis.text.y = element_text(size = 4),
        plot.subtitle = element_text(size = 9, color = "grey40"))

ggsave(file.path(fig_dir, "fig5_jackknife.pdf"), p5, width = 7, height = 8)
ggsave(file.path(fig_dir, "fig5_jackknife.png"), p5, width = 7, height = 8, dpi = 300)
cat("  Saved fig5_jackknife.pdf\n")

# ==============================================================================
# Figure 6: Balance Test Scatter
# ==============================================================================

cat("=== Figure 6: Balance Test ===\n")

balance <- fread(file.path(data_dir, "balance_test_results.csv"))

# Scatter: 2012 anti-system vs 2022 FTTH coverage
baseline_2012 <- panel[id_election == "2012_pres_t1",
  .(dept_code, baseline_antisystem = antisystem_share)]
balance_plot <- merge(baseline_2012, ftth_2022, by = "dept_code")

p6 <- ggplot(balance_plot, aes(x = baseline_antisystem, y = ftth_2022)) +
  geom_point(color = "#2166ac", alpha = 0.6, size = 2) +
  geom_smooth(method = "lm", color = "red", se = TRUE, alpha = 0.15) +
  scale_x_continuous(labels = scales::percent) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Anti-System Vote Share, 2012 Presidential",
       y = "FTTH Coverage, Q2 2022",
       title = "Balance: Baseline Polarization Does Not Predict FTTH Speed",
       subtitle = sprintf("Slope = %.3f (p = %.3f)",
                           balance[predictor == "baseline_antisystem", estimate],
                           balance[predictor == "baseline_antisystem", pvalue])) +
  theme(plot.subtitle = element_text(size = 9, color = "grey40"))

ggsave(file.path(fig_dir, "fig6_balance.pdf"), p6, width = 6, height = 5)
ggsave(file.path(fig_dir, "fig6_balance.png"), p6, width = 6, height = 5, dpi = 300)
cat("  Saved fig6_balance.pdf\n")

cat("\n05_figures.R complete.\n")
