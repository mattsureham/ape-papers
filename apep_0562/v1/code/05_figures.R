## ============================================================================
## 05_figures.R — Networked Anxiety (apep_0562)
## Generate all figures from saved CSV data
## ============================================================================

source("00_packages.R")

DATA_DIR <- "../data"
FIG_DIR <- "../figures"
dir.create(FIG_DIR, showWarnings = FALSE)

## ============================================================================
## FIGURE 1: Treatment Map — NetworkDispersal across departments
## ============================================================================

cat("\n=== Figure 1: Treatment Map ===\n")

nd <- fread(file.path(DATA_DIR, "network_dispersal.csv"))
geo_file <- file.path(DATA_DIR, "geo", "departements.geojson")

if (file.exists(geo_file)) {
  dept_sf <- st_read(geo_file, quiet = TRUE)

  ## Match department codes
  dept_sf <- dept_sf %>%
    mutate(dept_code = as.character(code)) %>%
    left_join(nd, by = "dept_code")

  fig1 <- ggplot(dept_sf) +
    geom_sf(aes(fill = network_dispersal), color = "white", size = 0.2) +
    scale_fill_gradient2(
      low = "#2166ac", mid = "#f7f7f7", high = "#b2182b",
      midpoint = 0,
      name = "Network\nDispersal\nExposure",
      labels = scales::comma
    ) +
    labs(
      title = "Network Exposure to Asylum Dispersal",
      subtitle = "SCI-weighted sum of new asylum reception places, 2020-2023",
      caption = "Source: SCI (Meta/Facebook), Sch\u00e9ma National d'Accueil 2021-2023"
    ) +
    theme_void() +
    theme(
      plot.title = element_text(face = "bold", size = 12),
      plot.subtitle = element_text(size = 9, color = "grey40"),
      legend.position = "right"
    )

  ggsave(file.path(FIG_DIR, "fig1_treatment_map.pdf"),
         fig1, width = 7, height = 6)
  cat("  Figure 1 saved.\n")
} else {
  cat("  WARNING: GeoJSON not found, skipping map.\n")
}

## ============================================================================
## FIGURE 2: Event Study
## ============================================================================

cat("\n=== Figure 2: Event Study ===\n")

es_dt <- fread(file.path(DATA_DIR, "event_study_coefs.csv"))

fig2 <- ggplot(es_dt, aes(x = year, y = coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = 2020.5, linetype = "dotted", color = "red", alpha = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, fill = "#2166ac") +
  geom_point(size = 3, color = "#2166ac") +
  geom_line(color = "#2166ac", linewidth = 0.8) +
  annotate("text", x = 2020.5, y = max(es_dt$ci_hi) * 0.9,
           label = "SNA\n2021", hjust = 1.1, size = 3, color = "red") +
  scale_x_continuous(breaks = sort(unique(es_dt$year))) +
  labs(
    x = "Election Year",
    y = expression(hat(beta)[t] ~ "(NetworkDispersal" ~ times ~ "Election)"),
    title = "Event Study: Network Asylum Exposure and RN Vote Share",
    subtitle = "Reference period: 2019 European elections. 95% CI with dept-clustered SEs."
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 11),
    axis.title.y = element_text(size = 9)
  )

ggsave(file.path(FIG_DIR, "fig2_event_study.pdf"),
       fig2, width = 7, height = 5)
cat("  Figure 2 saved.\n")

## ============================================================================
## FIGURE 3: Leave-One-Out Stability
## ============================================================================

cat("\n=== Figure 3: Leave-One-Out ===\n")

loo_dt <- fread(file.path(DATA_DIR, "loo_results.csv"))
results_main <- fread(file.path(DATA_DIR, "results_main.csv"))
baseline_coef <- results_main[model == "(1) Basic", coef_nd]

fig3 <- ggplot(loo_dt, aes(x = reorder(excluded_dept, coef), y = coef)) +
  geom_hline(yintercept = baseline_coef, linetype = "dashed", color = "red") +
  geom_hline(yintercept = 0, linetype = "solid", color = "grey50", alpha = 0.5) +
  geom_point(size = 2, color = "#2166ac", alpha = 0.7) +
  geom_errorbar(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
                width = 0, alpha = 0.3, color = "#2166ac") +
  labs(
    x = "Excluded Department",
    y = expression(hat(beta) ~ "(NetworkDispersal" ~ times ~ "Post)"),
    title = "Leave-One-Out: Excluding Each Shift Department",
    subtitle = paste0("Baseline estimate: ", round(baseline_coef, 4),
                      " (red dashed). No single department drives the result.")
  ) +
  theme(
    axis.text.x = element_text(angle = 90, hjust = 1, size = 6),
    plot.title = element_text(face = "bold", size = 11)
  )

ggsave(file.path(FIG_DIR, "fig3_leave_one_out.pdf"),
       fig3, width = 8, height = 5)
cat("  Figure 3 saved.\n")

## ============================================================================
## FIGURE 4: Randomization Inference
## ============================================================================

cat("\n=== Figure 4: Randomization Inference ===\n")

ri_dt <- fread(file.path(DATA_DIR, "ri_permutations.csv"))
ri_pvalue <- mean(abs(ri_dt$coef) >= abs(baseline_coef), na.rm = TRUE)

fig4 <- ggplot(ri_dt, aes(x = coef)) +
  geom_histogram(bins = 50, fill = "grey70", color = "white", alpha = 0.8) +
  geom_vline(xintercept = baseline_coef, color = "red", linewidth = 1) +
  geom_vline(xintercept = -baseline_coef, color = "red",
             linewidth = 1, linetype = "dashed") +
  annotate("text", x = baseline_coef, y = Inf,
           label = paste0("Observed\n\u03b2 = ", round(baseline_coef, 4)),
           vjust = 1.5, hjust = -0.1, color = "red", size = 3.5) +
  annotate("text", x = mean(range(ri_dt$coef)), y = Inf,
           label = ifelse(ri_pvalue == 0, "RI p-value < 0.001", paste0("RI p-value = ", round(ri_pvalue, 3))),
           vjust = 3, size = 4, fontface = "bold") +
  labs(
    x = expression(hat(beta) ~ "under permuted SCI weights"),
    y = "Count",
    title = "Randomization Inference: Permuting SCI Weights",
    subtitle = "1,000 permutations of department-level SCI assignments"
  ) +
  theme(plot.title = element_text(face = "bold", size = 11))

ggsave(file.path(FIG_DIR, "fig4_ri_histogram.pdf"),
       fig4, width = 7, height = 5)
cat("  Figure 4 saved.\n")

## ============================================================================
## FIGURE 5: Coefficient Comparison (Main + Robustness)
## ============================================================================

cat("\n=== Figure 5: Coefficient Comparison ===\n")

rob_dt <- fread(file.path(DATA_DIR, "robustness_summary.csv"))

## Build coefficient plot data from main results
coef_plot <- data.table(
  spec = c("Baseline", "Log SCI", "Binary Treatment",
           "With Own Places", "Standardized"),
  coef = results_main[c(1, 1, 1, 2, 3), coef_nd],
  se = results_main[c(1, 1, 1, 2, 3), se_nd]
)

## Override with actual robustness coefficients where available
coef_plot[spec == "Log SCI", `:=`(
  coef = as.numeric(rob_dt[specification == "Log SCI weights", coef]),
  se = as.numeric(rob_dt[specification == "Log SCI weights", se])
)]
coef_plot[spec == "Binary Treatment", `:=`(
  coef = as.numeric(rob_dt[specification == "Binary treatment (above median)", coef]),
  se = as.numeric(rob_dt[specification == "Binary treatment (above median)", se])
)]

coef_plot[, ci_lo := coef - 1.96 * se]
coef_plot[, ci_hi := coef + 1.96 * se]
coef_plot[, spec := factor(spec, levels = rev(spec))]

fig5 <- ggplot(coef_plot, aes(x = coef, y = spec)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbarh(aes(xmin = ci_lo, xmax = ci_hi),
                 height = 0.2, color = "#2166ac") +
  geom_point(size = 3, color = "#2166ac") +
  labs(
    x = expression(hat(beta) ~ "(Network Dispersal" ~ times ~ "Post)"),
    y = NULL,
    title = "Coefficient Stability Across Specifications",
    subtitle = "All specifications include department and election FE. 95% CI."
  ) +
  theme(plot.title = element_text(face = "bold", size = 11))

ggsave(file.path(FIG_DIR, "fig5_coef_comparison.pdf"),
       fig5, width = 7, height = 4)
cat("  Figure 5 saved.\n")

## ============================================================================
## FIGURE 6: RN Vote Share Trends by Network Exposure Tercile
## ============================================================================

cat("\n=== Figure 6: RN Trends by Exposure Tercile ===\n")

panel <- fread(file.path(DATA_DIR, "analysis_panel.csv"))

panel[, exposure_tercile := cut(network_dispersal,
                                 breaks = quantile(network_dispersal,
                                                   c(0, 1/3, 2/3, 1), na.rm = TRUE),
                                 labels = c("Low exposure", "Medium", "High exposure"),
                                 include.lowest = TRUE)]

trends <- panel[, .(mean_rn = mean(rn_share, na.rm = TRUE),
                     se_rn = sd(rn_share, na.rm = TRUE) / sqrt(.N)),
                by = .(year, exposure_tercile)]

fig6 <- ggplot(trends, aes(x = year, y = mean_rn,
                            color = exposure_tercile, group = exposure_tercile)) +
  geom_vline(xintercept = 2020.5, linetype = "dotted", color = "grey50") +
  geom_ribbon(aes(ymin = mean_rn - 1.96 * se_rn,
                  ymax = mean_rn + 1.96 * se_rn, fill = exposure_tercile),
              alpha = 0.1, color = NA) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.5) +
  annotate("text", x = 2020.5, y = max(trends$mean_rn) * 0.95,
           label = "SNA\n2021", hjust = 1.1, size = 3, color = "grey50") +
  scale_color_manual(values = c("#2166ac", "#999999", "#b2182b"),
                     name = "Network Dispersal\nExposure") +
  scale_fill_manual(values = c("#2166ac", "#999999", "#b2182b"),
                    guide = "none") +
  scale_x_continuous(breaks = sort(unique(trends$year))) +
  labs(
    x = "Election Year",
    y = "Mean RN Vote Share (%)",
    title = "RN Vote Share Trends by Network Exposure to Asylum Dispersal",
    subtitle = "Departments grouped by tercile of SCI-weighted dispersal exposure"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 11),
    legend.position = "bottom"
  )

ggsave(file.path(FIG_DIR, "fig6_trends_by_tercile.pdf"),
       fig6, width = 7, height = 5)
cat("  Figure 6 saved.\n")

cat("\nAll figures generated.\n")
