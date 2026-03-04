## ============================================================================
## 05_figures.R — All figures for the paper
## apep_0503: DPE Energy Labels + Rental Ban Multi-Cutoff RDD
## ============================================================================

source("00_packages.R")

DATA_DIR <- "../data"
FIGURES_DIR <- "../figures"
RESULTS_DIR <- "../tables"
dir.create(FIGURES_DIR, showWarnings = FALSE, recursive = TRUE)

cat("=== Loading data ===\n")
analysis <- arrow::read_parquet(file.path(DATA_DIR, "analysis.parquet"))

## ============================================================================
## FIGURE 1: DPE label distribution and regulatory timeline
## ============================================================================

cat("  Figure 1: DPE distribution...\n")

# Panel A: DPE distribution histogram with cutoff lines
fig1a <- analysis %>%
  filter(nearest_cutoff %in% c("F", "E", "D", "C")) %>%
  ggplot(aes(x = energy_kwh_m2, fill = dpe_label)) +
  geom_histogram(binwidth = 5, alpha = 0.8, color = "white", linewidth = 0.1) +
  geom_vline(xintercept = DPE_ENERGY_CUTS, linetype = "dashed", color = "grey30", linewidth = 0.5) +
  scale_fill_manual(values = DPE_COLORS, name = "DPE Label") +
  annotate("text", x = DPE_ENERGY_CUTS + 2, y = Inf, vjust = 1.5,
           label = paste0(names(DPE_ENERGY_CUTS), "/", c("B","C","D","E","F","G")),
           size = 3, fontface = "bold", angle = 90, hjust = 1) +
  labs(
    title = "A. Distribution of DPE Energy Scores",
    x = expression("Primary Energy Consumption (kWh/m"^2*"/year)"),
    y = "Number of Transactions"
  ) +
  scale_y_continuous(labels = comma) +
  coord_cartesian(xlim = c(50, 500))

# Panel B: Regulatory timeline
timeline_data <- tibble(
  label = c("G ban\n(extreme)", "G ban\n(all)", "F ban", "E ban"),
  date = as.Date(c("2023-01-01", "2025-01-01", "2028-01-01", "2034-01-01")),
  y = c(1, 1.3, 1, 1.3),
  color = c("G", "G", "F", "E")
)

fig1b <- ggplot(timeline_data, aes(x = date, y = y)) +
  geom_segment(aes(x = date, xend = date, y = 0.8, yend = y),
               linetype = "dotted", color = "grey50") +
  geom_point(aes(color = color), size = 4) +
  geom_text(aes(label = label), vjust = -0.8, size = 3, fontface = "bold") +
  scale_color_manual(values = DPE_COLORS[c("G", "F", "E")], guide = "none") +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y",
               limits = as.Date(c("2021-01-01", "2036-01-01"))) +
  labs(
    title = "B. Phased Rental Ban Timeline",
    x = "", y = ""
  ) +
  theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(),
        panel.grid.major.y = element_blank()) +
  coord_cartesian(ylim = c(0.6, 2))

fig1 <- fig1a / fig1b + plot_layout(heights = c(3, 1))

ggsave(file.path(FIGURES_DIR, "fig1_dpe_distribution.pdf"),
       fig1, width = 8, height = 8, device = cairo_pdf)

## ============================================================================
## FIGURE 2: RDD plots at each cutoff
## ============================================================================

cat("  Figure 2: RDD scatter plots at each cutoff...\n")

rdd_panels <- list()

for (cut_name in c("F", "E", "D", "C")) {
  cut_val <- DPE_ENERGY_CUTS[cut_name]
  worse_label <- c(F = "G", E = "F", D = "E", C = "D")[cut_name]

  df_cut <- analysis %>%
    filter(nearest_cutoff == cut_name,
           abs(energy_kwh_m2 - cut_val) <= 35)

  if (nrow(df_cut) < 100) next

  # Bin scatter: mean log price by 2-kWh bins
  bin_data <- df_cut %>%
    mutate(energy_bin = round(energy_kwh_m2 / 2) * 2) %>%
    group_by(energy_bin) %>%
    summarise(
      mean_log_price = mean(log_price_m2, na.rm = TRUE),
      se_log_price = sd(log_price_m2, na.rm = TRUE) / sqrt(n()),
      n = n(),
      .groups = "drop"
    ) %>%
    filter(n >= 10)  # Only plot bins with enough observations

  cutoff_type_label <- case_when(
    cut_name == "F" ~ "Active Ban (G/F)",
    cut_name == "E" ~ "Anticipated Ban 2028 (F/E)",
    cut_name == "D" ~ "Anticipated Ban 2034 (E/D)",
    cut_name == "C" ~ "Information Only (D/C)"
  )

  p <- ggplot(bin_data, aes(x = energy_bin, y = mean_log_price)) +
    geom_point(color = "grey30", size = 1.5, alpha = 0.7) +
    geom_vline(xintercept = cut_val, linetype = "dashed", color = "red", linewidth = 0.7) +
    geom_smooth(data = filter(bin_data, energy_bin < cut_val),
                method = "lm", se = TRUE, color = DPE_COLORS[cut_name],
                fill = DPE_COLORS[cut_name], alpha = 0.2) +
    geom_smooth(data = filter(bin_data, energy_bin >= cut_val),
                method = "lm", se = TRUE, color = DPE_COLORS[worse_label],
                fill = DPE_COLORS[worse_label], alpha = 0.2) +
    labs(
      title = cutoff_type_label,
      x = expression("Energy (kWh/m"^2*"/yr)"),
      y = expression("Log Price/m"^2)
    ) +
    annotate("text", x = cut_val - 15, y = Inf, vjust = 1.5,
             label = cut_name, fontface = "bold", color = DPE_COLORS[cut_name], size = 5) +
    annotate("text", x = cut_val + 15, y = Inf, vjust = 1.5,
             label = worse_label, fontface = "bold", color = DPE_COLORS[worse_label], size = 5)

  rdd_panels[[cut_name]] <- p
}

if (length(rdd_panels) >= 4) {
  fig2 <- wrap_plots(rdd_panels, ncol = 2) +
    plot_annotation(
      title = "RDD Estimates at DPE Band Boundaries",
      subtitle = "Bin scatter of log price per m² vs. energy consumption"
    )

  ggsave(file.path(FIGURES_DIR, "fig2_rdd_plots.pdf"),
         fig2, width = 10, height = 8, device = cairo_pdf)
}

## ============================================================================
## FIGURE 3: McCrary density plots
## ============================================================================

cat("  Figure 3: McCrary density plots...\n")

density_panels <- list()

for (cut_name in c("F", "E", "D", "C")) {
  cut_val <- DPE_ENERGY_CUTS[cut_name]
  df_cut <- analysis %>% filter(nearest_cutoff == cut_name)

  if (nrow(df_cut) < 200) next

  tryCatch({
    dens_test <- rddensity(
      X = df_cut$energy_kwh_m2,
      c = cut_val,
      kernel = "triangular"
    )

    pdf_null <- file.path(FIGURES_DIR, sprintf("density_%s.pdf", cut_name))
    pdf(pdf_null)
    plot_result <- rdplotdensity(dens_test, df_cut$energy_kwh_m2,
                                  title = sprintf("%s/%s Cutoff (%d kWh)",
                                                  cut_name,
                                                  c(F="G",E="F",D="E",C="D")[cut_name],
                                                  cut_val),
                                  xlabel = "Energy Consumption (kWh/m²/yr)",
                                  ylabel = "Density")
    dev.off()

    # Also create ggplot version for combined figure
    p_dens <- df_cut %>%
      ggplot(aes(x = energy_kwh_m2)) +
      geom_histogram(aes(y = after_stat(density)), binwidth = 2,
                     fill = "grey70", color = "white", linewidth = 0.1) +
      geom_vline(xintercept = cut_val, color = "red", linetype = "dashed", linewidth = 0.7) +
      labs(
        title = sprintf("%s/%s (%d kWh)",
                        cut_name,
                        c(F="G",E="F",D="E",C="D")[cut_name],
                        cut_val),
        x = expression("kWh/m"^2*"/yr"),
        y = "Density"
      ) +
      annotate("text", x = cut_val, y = Inf, vjust = 1.5,
               label = sprintf("p=%.3f", dens_test$test$p_jk),
               size = 3, fontface = "italic")

    density_panels[[cut_name]] <- p_dens

  }, error = function(e) {
    cat(sprintf("    %s density plot failed: %s\n", cut_name, e$message))
  })
}

if (length(density_panels) >= 4) {
  fig3 <- wrap_plots(density_panels, ncol = 2) +
    plot_annotation(
      title = "McCrary Density Tests at DPE Cutoffs",
      subtitle = "Testing for manipulation/bunching in the running variable"
    )

  ggsave(file.path(FIGURES_DIR, "fig3_mccrary_density.pdf"),
         fig3, width = 10, height = 8, device = cairo_pdf)
}

## ============================================================================
## FIGURE 4: Multi-cutoff comparison (coefficient plot)
## ============================================================================

cat("  Figure 4: Multi-cutoff coefficient plot...\n")

main_results <- read_csv(file.path(RESULTS_DIR, "rdd_main_results.csv"),
                          show_col_types = FALSE)

if (nrow(main_results) > 0) {
  main_results <- main_results %>%
    mutate(
      cutoff_type = case_when(
        cutoff == "F" ~ "Active Ban\n(G/F)",
        cutoff == "E" ~ "Ban 2028\n(F/E)",
        cutoff == "D" ~ "Ban 2034\n(E/D)",
        cutoff == "C" ~ "Info Only\n(D/C)",
        cutoff == "B" ~ "Info Only\n(C/B)",
        cutoff == "A" ~ "Info Only\n(B/A)"
      ),
      is_regulatory = cutoff %in% c("F", "E", "D"),
      cutoff_order = match(cutoff, c("F", "E", "D", "C", "B", "A"))
    ) %>%
    arrange(cutoff_order)

  fig4 <- ggplot(main_results, aes(x = reorder(cutoff_type, cutoff_order),
                                     y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper,
                         color = is_regulatory),
                     size = 0.8, linewidth = 0.7) +
    scale_color_manual(values = c("TRUE" = "#D1191F", "FALSE" = "#319834"),
                       labels = c("Information Only", "Regulatory"),
                       name = "Cutoff Type") +
    labs(
      title = "RDD Estimates Across DPE Band Boundaries",
      subtitle = "Discontinuity in log price per m² (robust bias-corrected 95% CI)",
      x = "",
      y = expression("Discontinuity in Log Price/m"^2)
    ) +
    coord_flip()

  ggsave(file.path(FIGURES_DIR, "fig4_coefficient_plot.pdf"),
         fig4, width = 8, height = 5, device = cairo_pdf)
}

## ============================================================================
## FIGURE 5: Pre-ban vs. post-ban at G/F cutoff
## ============================================================================

cat("  Figure 5: Pre-ban vs post-ban...\n")

df_gf <- analysis %>%
  filter(nearest_cutoff == "F", period %in% c("pre_ban", "post_ban"))

if (nrow(df_gf) > 200) {
  # Bin scatter by period
  bin_data_period <- df_gf %>%
    mutate(energy_bin = round(energy_kwh_m2 / 2) * 2) %>%
    group_by(energy_bin, period) %>%
    summarise(
      mean_log_price = mean(log_price_m2, na.rm = TRUE),
      n = n(),
      .groups = "drop"
    ) %>%
    filter(n >= 5, abs(energy_bin - 420) <= 35)

  fig5 <- ggplot(bin_data_period, aes(x = energy_bin, y = mean_log_price,
                                        color = period, shape = period)) +
    geom_point(size = 2, alpha = 0.7) +
    geom_vline(xintercept = 420, linetype = "dashed", color = "grey30", linewidth = 0.7) +
    geom_smooth(data = filter(bin_data_period, energy_bin < 420),
                method = "lm", se = TRUE, alpha = 0.15) +
    geom_smooth(data = filter(bin_data_period, energy_bin >= 420),
                method = "lm", se = TRUE, alpha = 0.15) +
    scale_color_manual(values = c("pre_ban" = "#4292C6", "post_ban" = "#D1191F"),
                       labels = c("Pre-Ban (2021-2022)", "Post-Ban (2025)"),
                       name = "") +
    scale_shape_manual(values = c(16, 17),
                       labels = c("Pre-Ban (2021-2022)", "Post-Ban (2025)"),
                       name = "") +
    labs(
      title = "Price Discontinuity at G/F Boundary: Before vs. After Rental Ban",
      x = expression("Primary Energy Consumption (kWh/m"^2*"/year)"),
      y = expression("Log Price per m"^2)
    ) +
    annotate("text", x = 405, y = Inf, vjust = 1.5,
             label = "F (legal)", fontface = "bold", color = DPE_COLORS["F"], size = 4) +
    annotate("text", x = 435, y = Inf, vjust = 1.5,
             label = "G (banned)", fontface = "bold", color = DPE_COLORS["G"], size = 4)

  ggsave(file.path(FIGURES_DIR, "fig5_pre_post_ban.pdf"),
         fig5, width = 8, height = 5.5, device = cairo_pdf)
}

## ============================================================================
## FIGURE 6: Bandwidth sensitivity plot
## ============================================================================

cat("  Figure 6: Bandwidth sensitivity...\n")

bw_file <- file.path(RESULTS_DIR, "bandwidth_sensitivity.csv")
if (file.exists(bw_file)) {
  bw_data <- read_csv(bw_file, show_col_types = FALSE)

  fig6 <- ggplot(bw_data %>% filter(cutoff == "F"),
                  aes(x = bw_multiplier, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_pointrange(aes(ymin = estimate - 1.96 * se_bc,
                         ymax = estimate + 1.96 * se_bc),
                     color = DPE_COLORS["G"]) +
    geom_vline(xintercept = 1, linetype = "dotted", color = "grey60") +
    labs(
      title = "Bandwidth Sensitivity: G/F Cutoff",
      subtitle = "RDD estimates at different bandwidth multiples (1.0 = MSE-optimal)",
      x = "Bandwidth Multiplier",
      y = expression("Discontinuity in Log Price/m"^2)
    )

  ggsave(file.path(FIGURES_DIR, "fig6_bandwidth_sensitivity.pdf"),
         fig6, width = 7, height = 5, device = cairo_pdf)
}

cat("\n=== All figures generated ===\n")
cat("Output directory:", FIGURES_DIR, "\n")
cat("Files:", paste(list.files(FIGURES_DIR, pattern = "*.pdf"), collapse = ", "), "\n")
