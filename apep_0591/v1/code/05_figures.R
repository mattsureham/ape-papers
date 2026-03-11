# =============================================================================
# 05_figures.R — All figure generation
# APEP-0591: The Erasmus Drain
# =============================================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir  <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

panel    <- fread(file.path(data_dir, "analysis_panel.csv"))
cross    <- fread(file.path(data_dir, "analysis_cross_section.csv"))
results  <- readRDS(file.path(data_dir, "main_results.rds"))
robust   <- tryCatch(readRDS(file.path(data_dir, "robustness_results.rds")),
                     error = function(e) { cat("Warning: robustness_results.rds not found\n"); list() })

# ---------------------------------------------------------------
# Figure 1: Map of net Erasmus flows (pre-period)
# ---------------------------------------------------------------
# Aggregate net outflows by NUTS2 region in pre-period
net_pre <- panel[year %in% 2014:2019,
                 .(mean_net_out = mean(net_out, na.rm = TRUE)),
                 by = nuts2]

# Get NUTS2 shapefile
tryCatch({
  nuts2_sf <- get_eurostat_geospatial(resolution = "20", nuts_level = 2,
                                       year = 2021)
  nuts2_sf <- merge(nuts2_sf, net_pre, by.x = "NUTS_ID", by.y = "nuts2",
                    all.x = TRUE)

  p1 <- ggplot(nuts2_sf) +
    geom_sf(aes(fill = mean_net_out), color = "grey80", size = 0.1) +
    scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B",
                         midpoint = 0, na.value = "grey90",
                         name = "Mean annual\nnet Erasmus outflow",
                         labels = scales::comma) +
    coord_sf(xlim = c(-12, 35), ylim = c(35, 72)) +
    labs(title = "Net Erasmus+ Student Outflows by NUTS2 Region, 2014-2019",
         subtitle = "Red = net sender (brain drain); Blue = net receiver (brain gain)") +
    theme_void(base_size = 11) +
    theme(legend.position = "right",
          plot.title = element_text(face = "bold", size = 13))

  ggsave(file.path(fig_dir, "fig1_map_net_flows.pdf"), p1,
         width = 10, height = 8)
  ggsave(file.path(fig_dir, "fig1_map_net_flows.png"), p1,
         width = 10, height = 8, dpi = 300)
  cat("Figure 1 saved\n")
}, error = function(e) {
  cat("Map generation failed (shapefile unavailable):", e$message, "\n")
  cat("Generating alternative scatter plot instead.\n")

  # Alternative: scatter of net outflow vs GDP
  gdp_pre <- panel[year %in% 2014:2016 & !is.na(gdp_pc),
                   .(gdp_pc_pre = mean(gdp_pc, na.rm = TRUE)), by = nuts2]
  net_pre <- merge(net_pre, gdp_pre, by = "nuts2")

  p1 <- ggplot(net_pre, aes(x = gdp_pc_pre / 1000, y = mean_net_out)) +
    geom_point(alpha = 0.5, size = 2) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
    geom_smooth(method = "lm", se = TRUE, color = "#2166AC") +
    labs(x = "GDP per capita (EUR thousands, 2014-2016 avg)",
         y = "Mean annual net Erasmus outflow (students)",
         title = "Net Erasmus Outflows vs. Regional Economic Development",
         subtitle = "NUTS2 regions, 2014-2019 average") +
    theme_minimal(base_size = 12)

  ggsave(file.path(fig_dir, "fig1_scatter_netflow_gdp.pdf"), p1,
         width = 8, height = 6)
  ggsave(file.path(fig_dir, "fig1_scatter_netflow_gdp.png"), p1,
         width = 8, height = 6, dpi = 300)
  cat("Figure 1 (alt) saved\n")
})

# ---------------------------------------------------------------
# Figure 2: First stage binscatter — predicted_out_rate vs out_rate
# ---------------------------------------------------------------
# Residualized scatter: out_rate ~ predicted_out_rate (after region + year FE)
fs_data <- panel[!is.na(predicted_out_rate) & !is.na(out_rate) &
                 !is.na(tert_share_25_34)]

# Demean predicted_out_rate and out_rate by region and year
fs_data[, pred_dm := predicted_out_rate - mean(predicted_out_rate, na.rm = TRUE),
        by = nuts2]
fs_data[, pred_dm := pred_dm - mean(pred_dm, na.rm = TRUE),
        by = year]
fs_data[, outrate_dm := out_rate - mean(out_rate, na.rm = TRUE),
        by = nuts2]
fs_data[, outrate_dm := outrate_dm - mean(outrate_dm, na.rm = TRUE),
        by = year]

# Binscatter (20 equal-sized bins)
fs_data[, bin := cut(pred_dm, breaks = quantile(pred_dm, probs = seq(0, 1, 0.05),
                     na.rm = TRUE), include.lowest = TRUE, labels = FALSE)]
binscatter_fs <- fs_data[!is.na(bin),
                         .(pred_dm = mean(pred_dm, na.rm = TRUE),
                           outrate_dm = mean(outrate_dm, na.rm = TRUE)),
                         by = bin]

p2 <- ggplot(binscatter_fs, aes(x = pred_dm, y = outrate_dm)) +
  geom_point(size = 3, color = "#2166AC") +
  geom_smooth(method = "lm", se = TRUE, color = "#B2182B", linetype = "solid") +
  labs(x = "Predicted outflow rate (residualized)",
       y = "Erasmus outflow rate (residualized)",
       title = "First Stage: Predicted Outflow Rate and Actual Outflows",
       subtitle = "Binscatter after region and year fixed effects") +
  theme_minimal(base_size = 12)

ggsave(file.path(fig_dir, "fig2_first_stage.pdf"), p2, width = 7, height = 5.5)
ggsave(file.path(fig_dir, "fig2_first_stage.png"), p2, width = 7, height = 5.5, dpi = 300)

# Save underlying data
fwrite(binscatter_fs, file.path(data_dir, "fig2_binscatter_data.csv"))
cat("Figure 2 saved\n")

# ---------------------------------------------------------------
# Figure 3: Reduced form — predicted_out_rate vs tertiary share
# ---------------------------------------------------------------
# Demean tertiary share by region + year
fs_data[, tert_dm := tert_share_25_34 - mean(tert_share_25_34, na.rm = TRUE),
        by = nuts2]
fs_data[, tert_dm := tert_dm - mean(tert_dm, na.rm = TRUE),
        by = year]

binscatter_rf <- fs_data[!is.na(bin),
                         .(pred_dm = mean(pred_dm, na.rm = TRUE),
                           tert_dm = mean(tert_dm, na.rm = TRUE)),
                         by = bin]

p3 <- ggplot(binscatter_rf, aes(x = pred_dm, y = tert_dm)) +
  geom_point(size = 3, color = "#2166AC") +
  geom_smooth(method = "lm", se = TRUE, color = "#B2182B") +
  labs(x = "Predicted outflow rate (residualized)",
       y = "Tertiary share, 25-34 (residualized, pp)",
       title = "Reduced Form: Predicted Outflows and Tertiary Education",
       subtitle = "Binscatter after region and year fixed effects") +
  theme_minimal(base_size = 12)

ggsave(file.path(fig_dir, "fig3_reduced_form.pdf"), p3, width = 7, height = 5.5)
ggsave(file.path(fig_dir, "fig3_reduced_form.png"), p3, width = 7, height = 5.5, dpi = 300)
fwrite(binscatter_rf, file.path(data_dir, "fig3_binscatter_data.csv"))
cat("Figure 3 saved\n")

# ---------------------------------------------------------------
# Figure 4: Placebo — Young (25-34) vs Broad cohort (25-64)
# ---------------------------------------------------------------
# iv_tert = young cohort outcome, iv_placebo = broad cohort outcome
# Both use fit_out_rate as the coefficient key
placebo_data <- tryCatch({
  data.table(
    cohort = c("25-34\n(Erasmus-affected)", "25-64\n(Placebo)"),
    beta = c(coef(results$iv_tert)["fit_out_rate"],
             coef(results$iv_placebo)["fit_out_rate"]),
    se = c(se(results$iv_tert)["fit_out_rate"],
           se(results$iv_placebo)["fit_out_rate"])
  )
}, error = function(e) {
  cat("Warning: Could not extract placebo coefficients:", e$message, "\n")
  # Try alternative coefficient names as fallback
  tryCatch({
    data.table(
      cohort = c("25-34\n(Erasmus-affected)", "25-64\n(Placebo)"),
      beta = c(coef(results$iv_tert)["fit_net_out_rate"],
               coef(results$iv_placebo)["fit_net_out_rate"]),
      se = c(se(results$iv_tert)["fit_net_out_rate"],
             se(results$iv_placebo)["fit_net_out_rate"])
    )
  }, error = function(e2) {
    cat("Warning: Fallback coefficient extraction also failed:", e2$message, "\n")
    NULL
  })
})

if (!is.null(placebo_data)) {
  placebo_data[, ci_lo := beta - 1.96 * se]
  placebo_data[, ci_hi := beta + 1.96 * se]

  p4 <- ggplot(placebo_data, aes(x = cohort, y = beta)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_point(size = 4, color = c("#B2182B", "#2166AC")) +
    geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0.1,
                  color = c("#B2182B", "#2166AC"), linewidth = 1) +
    labs(x = "", y = "2SLS coefficient on outflow rate",
         title = "Placebo Test: Erasmus-Affected vs. Broader Cohort",
         subtitle = "Effect on tertiary education share; 95% CI shown") +
    theme_minimal(base_size = 12)

  ggsave(file.path(fig_dir, "fig4_placebo.pdf"), p4, width = 6, height = 5)
  ggsave(file.path(fig_dir, "fig4_placebo.png"), p4, width = 6, height = 5, dpi = 300)
  fwrite(placebo_data, file.path(data_dir, "fig4_placebo_data.csv"))
  cat("Figure 4 saved\n")
} else {
  cat("Figure 4 skipped — coefficient extraction failed\n")
}

# ---------------------------------------------------------------
# Figure 5: Randomization inference distribution
# ---------------------------------------------------------------
tryCatch({
  ri_coefs <- fread(file.path(data_dir, "ri_coefficients.csv"))

  # Extract observed coefficient and RI p-value from robust object
  obs_coef_val <- tryCatch(robust$obs_coef, error = function(e) NA)
  ri_pval      <- tryCatch(robust$ri_pvalue, error = function(e) NA)

  # If robust fields are missing, compute from ri_coefs + results
  if (is.null(obs_coef_val) || is.na(obs_coef_val)) {
    obs_coef_val <- tryCatch(coef(results$iv_tert)["fit_out_rate"],
                             error = function(e) {
                               tryCatch(coef(results$iv_tert)["fit_net_out_rate"],
                                        error = function(e2) NA)
                             })
  }
  if (is.null(ri_pval) || is.na(ri_pval)) {
    ri_pval <- mean(abs(ri_coefs$coef) >= abs(obs_coef_val), na.rm = TRUE)
  }

  p5 <- ggplot(ri_coefs[!is.na(coef)], aes(x = coef)) +
    geom_histogram(bins = 50, fill = "grey70", color = "white") +
    geom_vline(xintercept = obs_coef_val, color = "#B2182B",
               linewidth = 1.2, linetype = "solid") +
    annotate("text", x = obs_coef_val, y = Inf, vjust = 2,
             label = paste0("Observed: ", round(obs_coef_val, 3)),
             color = "#B2182B", fontface = "bold", size = 4) +
    labs(x = "2SLS coefficient under permuted destination shocks",
         y = "Frequency",
         title = "Randomization Inference: Permuting Destination Shocks",
         subtitle = paste0("500 permutations; RI p-value = ",
                           round(ri_pval, 3))) +
    theme_minimal(base_size = 12)

  ggsave(file.path(fig_dir, "fig5_ri.pdf"), p5, width = 7, height = 5)
  ggsave(file.path(fig_dir, "fig5_ri.png"), p5, width = 7, height = 5, dpi = 300)
  cat("Figure 5 saved\n")
}, error = function(e) {
  cat("Figure 5 skipped — ri_coefficients.csv not found:", e$message, "\n")
})

# ---------------------------------------------------------------
# Figure 6: Leave-one-out stability
# ---------------------------------------------------------------
tryCatch({
  loo <- fread(file.path(data_dir, "loo_country_results.csv"))
  loo[, ci_lo := beta - 1.96 * se]
  loo[, ci_hi := beta + 1.96 * se]
  loo <- loo[order(beta)]
  loo[, dropped := factor(dropped, levels = dropped)]

  # Full-sample coefficient for reference
  full_beta <- tryCatch(coef(results$iv_tert)["fit_out_rate"],
                        error = function(e) {
                          tryCatch(coef(results$iv_tert)["fit_net_out_rate"],
                                   error = function(e2) NA)
                        })

  p6 <- ggplot(loo, aes(x = dropped, y = beta)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_hline(yintercept = full_beta, linetype = "dotted", color = "#B2182B") +
    geom_point(size = 2.5, color = "#2166AC") +
    geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0.2,
                  color = "#2166AC", linewidth = 0.5) +
    coord_flip() +
    labs(x = "Country dropped", y = "2SLS coefficient on outflow rate",
         title = "Leave-One-Country-Out Stability",
         subtitle = "Dashed red = full-sample estimate") +
    theme_minimal(base_size = 11)

  ggsave(file.path(fig_dir, "fig6_loo.pdf"), p6, width = 7, height = 8)
  ggsave(file.path(fig_dir, "fig6_loo.png"), p6, width = 7, height = 8, dpi = 300)
  cat("Figure 6 saved\n")
}, error = function(e) {
  cat("Figure 6 skipped — loo_country_results.csv not found:", e$message, "\n")
})

# ---------------------------------------------------------------
# Figure 7: Heterogeneity — Core vs Peripheral
# ---------------------------------------------------------------
tryCatch({
  # Try primary field names from robust object
  het_beta_periph <- tryCatch(coef(robust$iv_peripheral)["fit_out_rate"],
                              error = function(e) {
                                tryCatch(coef(robust$iv_peripheral)["fit_net_out_rate"],
                                         error = function(e2) NA)
                              })
  het_se_periph <- tryCatch(se(robust$iv_peripheral)["fit_out_rate"],
                            error = function(e) {
                              tryCatch(se(robust$iv_peripheral)["fit_net_out_rate"],
                                       error = function(e2) NA)
                            })
  het_beta_core <- tryCatch(coef(robust$iv_core)["fit_out_rate"],
                            error = function(e) {
                              tryCatch(coef(robust$iv_core)["fit_net_out_rate"],
                                       error = function(e2) NA)
                            })
  het_se_core <- tryCatch(se(robust$iv_core)["fit_out_rate"],
                          error = function(e) {
                            tryCatch(se(robust$iv_core)["fit_net_out_rate"],
                                     error = function(e2) NA)
                          })

  if (any(is.na(c(het_beta_periph, het_se_periph, het_beta_core, het_se_core)))) {
    stop("Could not extract heterogeneity coefficients")
  }

  het_data <- data.table(
    group = c("Peripheral\n(below-median GDP)", "Core\n(above-median GDP)"),
    beta = c(het_beta_periph, het_beta_core),
    se = c(het_se_periph, het_se_core)
  )
  het_data[, ci_lo := beta - 1.96 * se]
  het_data[, ci_hi := beta + 1.96 * se]

  p7 <- ggplot(het_data, aes(x = group, y = beta)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_point(size = 4, color = c("#B2182B", "#2166AC")) +
    geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0.1,
                  color = c("#B2182B", "#2166AC"), linewidth = 1) +
    labs(x = "", y = "2SLS coefficient on outflow rate",
         title = "Heterogeneity: Peripheral vs. Core Regions",
         subtitle = "Effect on tertiary share (25-34); 95% CI shown") +
    theme_minimal(base_size = 12)

  ggsave(file.path(fig_dir, "fig7_heterogeneity.pdf"), p7, width = 6, height = 5)
  ggsave(file.path(fig_dir, "fig7_heterogeneity.png"), p7, width = 6, height = 5, dpi = 300)
  fwrite(het_data, file.path(data_dir, "fig7_heterogeneity_data.csv"))
  cat("Figure 7 saved\n")
}, error = function(e) {
  cat("Figure 7 skipped — heterogeneity extraction failed:", e$message, "\n")
})

cat("\n=== ALL FIGURES GENERATED ===\n")
