# =============================================================================
# 05_figures.R — All figure generation for v2
# APEP-0591 v2: The Erasmus Drain
# =============================================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir  <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

nuts3_cross <- fread(file.path(data_dir, "nuts3_cross_section.csv"))
panel_n2    <- fread(file.path(data_dir, "nuts2_panel.csv"))
panel_n3    <- fread(file.path(data_dir, "nuts3_panel.csv"))
results     <- readRDS(file.path(data_dir, "main_results.rds"))
robust      <- tryCatch(readRDS(file.path(data_dir, "robustness_results.rds")),
                         error = function(e) list())

has_long_diff <- "delta_youth_share" %in% names(nuts3_cross) &&
                  sum(!is.na(nuts3_cross$delta_youth_share)) > 100

# ---------------------------------------------------------------
# Figure 1: Map of net Erasmus flows at NUTS3
# ---------------------------------------------------------------
cat("Figure 1: NUTS3 net flows map...\n")

tryCatch({
  nuts3_sf <- get_eurostat_geospatial(resolution = "20", nuts_level = 3, year = 2021)

  map_data <- nuts3_cross[, .(nuts3, mean_net_out)]
  nuts3_sf <- merge(nuts3_sf, map_data, by.x = "NUTS_ID", by.y = "nuts3", all.x = TRUE)

  p1 <- ggplot(nuts3_sf) +
    geom_sf(aes(fill = mean_net_out), color = NA, size = 0.05) +
    scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B",
                          midpoint = 0, na.value = "grey90",
                          name = "Mean annual\nnet outflow",
                          labels = scales::comma) +
    coord_sf(xlim = c(-12, 35), ylim = c(35, 72)) +
    labs(title = "Net Erasmus+ Student Outflows by NUTS3 Region",
         subtitle = "Red = net sender; Blue = net receiver. Annual average, 2014-2022.") +
    theme_void(base_size = 11) +
    theme(legend.position = "right",
          plot.title = element_text(face = "bold", size = 13))

  ggsave(file.path(fig_dir, "fig1_map_nuts3.pdf"), p1, width = 10, height = 8)
  ggsave(file.path(fig_dir, "fig1_map_nuts3.png"), p1, width = 10, height = 8, dpi = 300)
  cat("  Saved\n")
}, error = function(e) {
  cat("  Map failed:", e$message, "\n")
  cat("  Generating scatter alternative...\n")

  p1 <- ggplot(nuts3_cross[!is.na(gdp_pc_pre) & !is.na(mean_net_out)],
               aes(x = gdp_pc_pre / 1000, y = mean_net_out)) +
    geom_point(alpha = 0.3, size = 1.5) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
    geom_smooth(method = "lm", se = TRUE, color = "#2166AC") +
    labs(x = "GDP per capita (EUR thousands, 2011-2015 avg)",
         y = "Mean annual net Erasmus outflow",
         title = "Net Erasmus Outflows vs. Regional Development (NUTS3)",
         subtitle = paste0(sum(!is.na(nuts3_cross$mean_net_out)), " NUTS3 regions")) +
    theme_minimal(base_size = 12)

  ggsave(file.path(fig_dir, "fig1_scatter_nuts3.pdf"), p1, width = 8, height = 6)
  ggsave(file.path(fig_dir, "fig1_scatter_nuts3.png"), p1, width = 8, height = 6, dpi = 300)
  cat("  Saved (scatter)\n")
})

# ---------------------------------------------------------------
# Figure 2: First stage — NUTS3 cross-section
# ---------------------------------------------------------------
cat("Figure 2: First stage (NUTS3)...\n")

if (sum(!is.na(nuts3_cross$bartik_avg) & !is.na(nuts3_cross$out_rate)) > 50) {
  # Residualize by country FE
  fs_dt <- nuts3_cross[!is.na(bartik_avg) & !is.na(out_rate) & !is.na(country)]
  fs_dt[, bartik_resid := bartik_avg - mean(bartik_avg, na.rm = TRUE), by = country]
  fs_dt[, outrate_resid := out_rate - mean(out_rate, na.rm = TRUE), by = country]

  # Binscatter
  fs_dt[, bin := cut(bartik_resid,
                      breaks = quantile(bartik_resid, probs = seq(0, 1, 0.05), na.rm = TRUE),
                      include.lowest = TRUE, labels = FALSE)]
  binsc_fs <- fs_dt[!is.na(bin),
                     .(bartik_resid = mean(bartik_resid, na.rm = TRUE),
                       outrate_resid = mean(outrate_resid, na.rm = TRUE)),
                     by = bin]

  p2 <- ggplot(binsc_fs, aes(x = bartik_resid, y = outrate_resid)) +
    geom_point(size = 3, color = "#2166AC") +
    geom_smooth(method = "lm", se = TRUE, color = "#B2182B") +
    labs(x = "Bartik instrument (residualized, within-country)",
         y = "Erasmus outflow rate (residualized)",
         title = "First Stage: Bartik Instrument and Outflow Rate (NUTS3)",
         subtitle = "Binscatter after country fixed effects") +
    theme_minimal(base_size = 12)

  ggsave(file.path(fig_dir, "fig2_first_stage_nuts3.pdf"), p2, width = 7, height = 5.5)
  ggsave(file.path(fig_dir, "fig2_first_stage_nuts3.png"), p2, width = 7, height = 5.5, dpi = 300)
  fwrite(binsc_fs, file.path(data_dir, "fig2_binscatter.csv"))
  cat("  Saved\n")
}

# ---------------------------------------------------------------
# Figure 3: Reduced form — NUTS3 long-difference
# ---------------------------------------------------------------
cat("Figure 3: Reduced form (NUTS3)...\n")

if (has_long_diff) {
  rf_dt <- nuts3_cross[!is.na(bartik_avg) & !is.na(delta_youth_share) & !is.na(country)]
  rf_dt[, bartik_resid := bartik_avg - mean(bartik_avg, na.rm = TRUE), by = country]
  rf_dt[, delta_resid := delta_youth_share - mean(delta_youth_share, na.rm = TRUE), by = country]

  rf_dt[, bin := cut(bartik_resid,
                      breaks = quantile(bartik_resid, probs = seq(0, 1, 0.05), na.rm = TRUE),
                      include.lowest = TRUE, labels = FALSE)]
  binsc_rf <- rf_dt[!is.na(bin),
                     .(bartik_resid = mean(bartik_resid, na.rm = TRUE),
                       delta_resid = mean(delta_resid, na.rm = TRUE)),
                     by = bin]

  p3 <- ggplot(binsc_rf, aes(x = bartik_resid, y = delta_resid)) +
    geom_point(size = 3, color = "#2166AC") +
    geom_smooth(method = "lm", se = TRUE, color = "#B2182B") +
    labs(x = "Bartik instrument (residualized, within-country)",
         y = expression(Delta * "(youth share 25-34, pp)"),
         title = "Reduced Form: Bartik Instrument and Youth Population Change",
         subtitle = "Binscatter after country fixed effects") +
    theme_minimal(base_size = 12)

  ggsave(file.path(fig_dir, "fig3_reduced_form_nuts3.pdf"), p3, width = 7, height = 5.5)
  ggsave(file.path(fig_dir, "fig3_reduced_form_nuts3.png"), p3, width = 7, height = 5.5, dpi = 300)
  fwrite(binsc_rf, file.path(data_dir, "fig3_binscatter.csv"))
  cat("  Saved\n")
}

# ---------------------------------------------------------------
# Figure 4: RI distribution (NUTS3 and NUTS2)
# ---------------------------------------------------------------
cat("Figure 4: Randomization inference...\n")

# NUTS3 RI
ri_n3 <- tryCatch(fread(file.path(data_dir, "ri_coefficients_nuts3.csv")),
                   error = function(e) NULL)
ri_n2 <- tryCatch(fread(file.path(data_dir, "ri_coefficients_nuts2.csv")),
                   error = function(e) NULL)

if (!is.null(ri_n3) && !is.null(robust$obs_coef_n3) && !is.na(robust$obs_coef_n3)) {
  ri_plot_data <- rbind(
    ri_n3[!is.na(coef), .(coef, panel = "NUTS3 (long-difference)")],
    if (!is.null(ri_n2)) ri_n2[!is.na(coef), .(coef, panel = "NUTS2 (panel)")] else NULL
  )

  obs_lines <- data.table(
    panel = c("NUTS3 (long-difference)", "NUTS2 (panel)"),
    obs = c(robust$obs_coef_n3, robust$obs_coef_n2)
  )

  p4 <- ggplot(ri_plot_data, aes(x = coef)) +
    geom_histogram(bins = 40, fill = "grey70", color = "white") +
    geom_vline(data = obs_lines, aes(xintercept = obs),
               color = "#B2182B", linewidth = 1.2) +
    facet_wrap(~panel, scales = "free", ncol = 1) +
    labs(x = "2SLS coefficient under permuted destination shocks",
         y = "Frequency",
         title = "Randomization Inference",
         subtitle = paste0("500 permutations. Red line = observed estimate. ",
                           "NUTS3 RI p = ", round(robust$ri_pvalue_n3, 3),
                           "; NUTS2 RI p = ", round(robust$ri_pvalue_n2, 3))) +
    theme_minimal(base_size = 12)

  ggsave(file.path(fig_dir, "fig4_ri.pdf"), p4, width = 7, height = 8)
  ggsave(file.path(fig_dir, "fig4_ri.png"), p4, width = 7, height = 8, dpi = 300)
  cat("  Saved\n")
} else if (!is.null(ri_n2)) {
  p4 <- ggplot(ri_n2[!is.na(coef)], aes(x = coef)) +
    geom_histogram(bins = 40, fill = "grey70", color = "white") +
    geom_vline(xintercept = robust$obs_coef_n2, color = "#B2182B", linewidth = 1.2) +
    labs(x = "2SLS coefficient under permuted destination shocks",
         y = "Frequency",
         title = "Randomization Inference (NUTS2 Panel)",
         subtitle = paste0("500 permutations. RI p = ", round(robust$ri_pvalue_n2, 3))) +
    theme_minimal(base_size = 12)

  ggsave(file.path(fig_dir, "fig4_ri.pdf"), p4, width = 7, height = 5)
  ggsave(file.path(fig_dir, "fig4_ri.png"), p4, width = 7, height = 5, dpi = 300)
  cat("  Saved (NUTS2 only)\n")
}

# ---------------------------------------------------------------
# Figure 5: Leave-one-out stability
# ---------------------------------------------------------------
cat("Figure 5: Leave-one-out...\n")

loo_n3 <- tryCatch(fread(file.path(data_dir, "loo_country_nuts3.csv")),
                    error = function(e) NULL)
loo_n2 <- tryCatch(fread(file.path(data_dir, "loo_country_nuts2.csv")),
                    error = function(e) NULL)

if (!is.null(loo_n2) && nrow(loo_n2) > 0) {
  loo_plot <- copy(loo_n2)
  loo_plot[, ci_lo := beta - 1.96 * se]
  loo_plot[, ci_hi := beta + 1.96 * se]
  loo_plot <- loo_plot[order(beta)]
  loo_plot[, dropped := factor(dropped, levels = dropped)]

  full_beta <- coef(results$iv_n2_main)["fit_out_rate"]

  p5 <- ggplot(loo_plot, aes(x = dropped, y = beta)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_hline(yintercept = full_beta, linetype = "dotted", color = "#B2182B") +
    geom_point(size = 2.5, color = "#2166AC") +
    geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0.2,
                  color = "#2166AC", linewidth = 0.5) +
    coord_flip() +
    labs(x = "Country dropped", y = "2SLS coefficient",
         title = "Leave-One-Country-Out Stability (NUTS2 Panel)",
         subtitle = "Dashed red = full-sample estimate") +
    theme_minimal(base_size = 11)

  ggsave(file.path(fig_dir, "fig5_loo.pdf"), p5, width = 7, height = 8)
  ggsave(file.path(fig_dir, "fig5_loo.png"), p5, width = 7, height = 8, dpi = 300)
  cat("  Saved\n")
}

# ---------------------------------------------------------------
# Figure 6: Heterogeneity — Peripheral vs Core (both NUTS3 and NUTS2)
# ---------------------------------------------------------------
cat("Figure 6: Heterogeneity...\n")

het_data <- data.table()

# NUTS3 heterogeneity
if (!is.null(robust$iv_periph_n3) && !is.null(robust$iv_core_n3)) {
  het_data <- rbind(het_data, data.table(
    panel = "NUTS3",
    group = c("Peripheral", "Core"),
    beta = c(coef(robust$iv_periph_n3)["fit_out_rate"],
             coef(robust$iv_core_n3)["fit_out_rate"]),
    se = c(se(robust$iv_periph_n3)["fit_out_rate"],
           se(robust$iv_core_n3)["fit_out_rate"])
  ))
}

# NUTS2 heterogeneity
if (!is.null(robust$iv_periph_n2) && !is.null(robust$iv_core_n2)) {
  het_data <- rbind(het_data, data.table(
    panel = "NUTS2",
    group = c("Peripheral", "Core"),
    beta = c(coef(robust$iv_periph_n2)["fit_out_rate"],
             coef(robust$iv_core_n2)["fit_out_rate"]),
    se = c(se(robust$iv_periph_n2)["fit_out_rate"],
           se(robust$iv_core_n2)["fit_out_rate"])
  ))
}

if (nrow(het_data) > 0) {
  het_data[, ci_lo := beta - 1.96 * se]
  het_data[, ci_hi := beta + 1.96 * se]
  het_data[, label := paste0(panel, "\n", group)]

  p6 <- ggplot(het_data, aes(x = label, y = beta, color = group)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_point(size = 4) +
    geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0.1, linewidth = 1) +
    scale_color_manual(values = c("Peripheral" = "#B2182B", "Core" = "#2166AC")) +
    labs(x = "", y = "2SLS coefficient on outflow rate",
         title = "Heterogeneity: Peripheral vs. Core Regions",
         subtitle = "Effects on tertiary education share; 95% CI shown") +
    guides(color = "none") +
    theme_minimal(base_size = 12)

  ggsave(file.path(fig_dir, "fig6_heterogeneity.pdf"), p6, width = 7, height = 5.5)
  ggsave(file.path(fig_dir, "fig6_heterogeneity.png"), p6, width = 7, height = 5.5, dpi = 300)
  cat("  Saved\n")
}

# ---------------------------------------------------------------
# Figure 7: Placebo — young vs broad cohort
# ---------------------------------------------------------------
cat("Figure 7: Placebo test...\n")

placebo_data <- data.table()

# NUTS2 placebo
if (!is.null(results$iv_n2_main) && !is.null(results$iv_n2_placebo)) {
  placebo_data <- data.table(
    cohort = c("25-34\n(Erasmus-affected)", "25-64\n(Placebo)"),
    beta = c(coef(results$iv_n2_main)["fit_out_rate"],
             coef(results$iv_n2_placebo)["fit_out_rate"]),
    se = c(se(results$iv_n2_main)["fit_out_rate"],
           se(results$iv_n2_placebo)["fit_out_rate"])
  )

  placebo_data[, ci_lo := beta - 1.96 * se]
  placebo_data[, ci_hi := beta + 1.96 * se]

  p7 <- ggplot(placebo_data, aes(x = cohort, y = beta)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_point(size = 4, color = c("#B2182B", "#2166AC")) +
    geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0.1,
                  color = c("#B2182B", "#2166AC"), linewidth = 1) +
    labs(x = "", y = "2SLS coefficient on outflow rate",
         title = "Placebo Test: Erasmus-Affected vs. Broader Cohort",
         subtitle = "NUTS2 panel; 95% CI shown") +
    theme_minimal(base_size = 12)

  ggsave(file.path(fig_dir, "fig7_placebo.pdf"), p7, width = 6, height = 5)
  ggsave(file.path(fig_dir, "fig7_placebo.png"), p7, width = 6, height = 5, dpi = 300)
  cat("  Saved\n")
}

# ---------------------------------------------------------------
# Figure 8: Receiver-side (NEW)
# ---------------------------------------------------------------
cat("Figure 8: Receiver-side analysis...\n")

if ("in_rate" %in% names(panel_n2) && !is.null(results$ols_inflow)) {
  # Binscatter: inflow rate vs tertiary share (residualized)
  recv_dt <- panel_n2[!is.na(in_rate) & !is.na(tert_share_25_34)]
  recv_dt[, in_dm := in_rate - mean(in_rate, na.rm = TRUE), by = nuts2]
  recv_dt[, in_dm := in_dm - mean(in_dm, na.rm = TRUE), by = year]
  recv_dt[, tert_dm := tert_share_25_34 - mean(tert_share_25_34, na.rm = TRUE), by = nuts2]
  recv_dt[, tert_dm := tert_dm - mean(tert_dm, na.rm = TRUE), by = year]

  recv_dt[, bin := cut(in_dm, breaks = quantile(in_dm, probs = seq(0, 1, 0.05), na.rm = TRUE),
                        include.lowest = TRUE, labels = FALSE)]
  binsc_recv <- recv_dt[!is.na(bin),
                         .(in_dm = mean(in_dm, na.rm = TRUE),
                           tert_dm = mean(tert_dm, na.rm = TRUE)),
                         by = bin]

  p8 <- ggplot(binsc_recv, aes(x = in_dm, y = tert_dm)) +
    geom_point(size = 3, color = "#2166AC") +
    geom_smooth(method = "lm", se = TRUE, color = "#4DAF4A") +
    labs(x = "Erasmus inflow rate (residualized)",
         y = "Tertiary share, 25-34 (residualized, pp)",
         title = "Receiver Side: Erasmus Inflows and Human Capital",
         subtitle = "NUTS2 regions; after region and year FE") +
    theme_minimal(base_size = 12)

  ggsave(file.path(fig_dir, "fig8_receiver.pdf"), p8, width = 7, height = 5.5)
  ggsave(file.path(fig_dir, "fig8_receiver.png"), p8, width = 7, height = 5.5, dpi = 300)
  cat("  Saved\n")
}

cat("\n=== ALL FIGURES GENERATED ===\n")
