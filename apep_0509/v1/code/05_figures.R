# ==============================================================================
# APEP-0509: MGNREGA, Input Substitution, and Crop-Specific Productivity
# 05_figures.R — All figure generation
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

results <- readRDS(file.path(data_dir, "main_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))
crop_long <- readRDS(file.path(data_dir, "crop_panel.rds"))
agg_panel <- readRDS(file.path(data_dir, "agg_panel.rds"))
wage_panel <- readRDS(file.path(data_dir, "wage_panel.rds"))
fert_panel <- readRDS(file.path(data_dir, "fert_panel.rds"))
baseline <- readRDS(file.path(data_dir, "baseline.rds"))

# Color palette
cols <- c("Labor-Intensive" = "#D55E00", "Non-Labor-Intensive" = "#0072B2",
          "Phase I" = "#E69F00", "Phase II" = "#56B4E9", "Phase III" = "#009E73")

# ==============================================================================
# Figure 1: First Stage — MGNREGA → Agricultural Wages (Event Study)
# ==============================================================================
cat("=== Figure 1: First Stage Wage Event Study ===\n")

wage_iplot <- iplot(results$wage_es,
                    main = "",
                    xlab = "Years Relative to MGNREGA Implementation",
                    ylab = "Effect on Log Male Agricultural Wage",
                    ref.line = -0.5,
                    ci_level = 0.95)

# Extract event study coefficients for custom ggplot
wage_coefs <- as.data.table(coeftable(results$wage_es))
wage_coefs[, coef_name := rownames(coeftable(results$wage_es))]
wage_coefs <- wage_coefs[grepl("year::", coef_name)]
wage_coefs[, rel_time := as.numeric(gsub(".*::(-?[0-9]+)$", "\\1", coef_name))]
setnames(wage_coefs, c("Estimate", "Std. Error"), c("estimate", "se"))
wage_coefs[, ci_lo := estimate - 1.96 * se]
wage_coefs[, ci_hi := estimate + 1.96 * se]

# Add reference period (t = -1)
ref_row <- data.table(estimate = 0, se = 0, ci_lo = 0, ci_hi = 0, rel_time = -1)
wage_coefs <- rbind(wage_coefs[, .(estimate, se, ci_lo, ci_hi, rel_time)], ref_row)

fig1 <- ggplot(wage_coefs, aes(x = rel_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "red", alpha = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#0072B2") +
  geom_point(size = 2, color = "#0072B2") +
  geom_line(color = "#0072B2") +
  labs(x = "Years Relative to MGNREGA Implementation",
       y = "Effect on Log Male Agricultural Wage",
       title = "First Stage: MGNREGA and Agricultural Wages") +
  scale_x_continuous(breaks = seq(-10, 12, by = 2)) +
  theme(plot.title = element_text(hjust = 0.5))

ggsave(file.path(fig_dir, "fig1_wage_event_study.pdf"), fig1,
       width = 8, height = 5)
cat("  Saved fig1_wage_event_study.pdf\n")

# ==============================================================================
# Figure 2: Crop-Specific Yield Event Studies (2x2 panel: Rice, Wheat, Cotton, Sugarcane)
# ==============================================================================
cat("=== Figure 2: Crop Event Studies (4 panels) ===\n")

extract_es_coefs <- function(fit, crop_name) {
  ct <- as.data.table(coeftable(fit))
  ct[, coef_name := rownames(coeftable(fit))]
  ct <- ct[grepl("year::", coef_name)]
  ct[, rel_time := as.numeric(gsub(".*::(-?[0-9]+)$", "\\1", coef_name))]
  setnames(ct, c("Estimate", "Std. Error"), c("estimate", "se"), skip_absent = TRUE)
  ct[, `:=`(ci_lo = estimate - 1.96 * se, ci_hi = estimate + 1.96 * se)]
  # Add reference
  ref <- data.table(estimate = 0, se = 0, ci_lo = 0, ci_hi = 0, rel_time = -1)
  ct <- rbind(ct[, .(estimate, se, ci_lo, ci_hi, rel_time)], ref)
  ct[, crop := crop_name]
  ct
}

panel_crops <- c("RICE", "WHEAT", "COTTON", "SUGARCANE")
es_data <- rbindlist(lapply(panel_crops, function(cn) {
  if (!is.null(results$crop_es[[cn]])) {
    extract_es_coefs(results$crop_es[[cn]], cn)
  }
}))

# Label labor intensity
es_data[, labor_type := fifelse(crop %in% c("RICE", "COTTON", "SUGARCANE"),
                                 "Labor-Intensive", "Non-Labor-Intensive")]
es_data[, crop := factor(crop, levels = panel_crops)]

fig2 <- ggplot(es_data, aes(x = rel_time, y = estimate, color = labor_type, fill = labor_type)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "red", alpha = 0.3) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, color = NA) +
  geom_point(size = 1.5) +
  geom_line() +
  facet_wrap(~crop, scales = "free_y") +
  scale_color_manual(values = cols) +
  scale_fill_manual(values = cols) +
  labs(x = "Years Relative to MGNREGA Implementation",
       y = "Effect on Log Crop Yield (kg/ha)",
       title = "Crop-Specific Yield Event Studies",
       color = "", fill = "") +
  scale_x_continuous(breaks = seq(-10, 12, by = 4)) +
  theme(legend.position = "bottom",
        plot.title = element_text(hjust = 0.5))

ggsave(file.path(fig_dir, "fig2_crop_event_studies.pdf"), fig2,
       width = 9, height = 7)
cat("  Saved fig2_crop_event_studies.pdf\n")

# ==============================================================================
# Figure 3: All 8 Crops — Static DiD Coefficients (Forest Plot)
# ==============================================================================
cat("=== Figure 3: Static DiD Coefficients (Forest Plot) ===\n")

static_coefs <- rbindlist(lapply(names(results$crop_static), function(cn) {
  fit <- results$crop_static[[cn]]
  data.table(
    crop = cn,
    estimate = coef(fit)["post"],
    se = se(fit)["post"],
    pval = pvalue(fit)["post"],
    n = nobs(fit)
  )
}))

static_coefs[, `:=`(ci_lo = estimate - 1.96 * se, ci_hi = estimate + 1.96 * se)]
static_coefs[, labor_type := fifelse(
  crop %in% c("RICE", "COTTON", "SUGARCANE", "GROUNDNUT", "SESAMUM"),
  "Labor-Intensive", "Non-Labor-Intensive"
)]
static_coefs[, crop := factor(crop, levels = rev(crop[order(estimate)]))]

fig3 <- ggplot(static_coefs, aes(x = estimate, y = crop, color = labor_type)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  geom_errorbarh(aes(xmin = ci_lo, xmax = ci_hi), height = 0.2) +
  geom_point(size = 3) +
  scale_color_manual(values = cols) +
  labs(x = "DiD Coefficient (Effect on Log Yield)",
       y = "",
       title = "Static DiD Estimates by Crop",
       color = "") +
  theme(legend.position = "bottom",
        plot.title = element_text(hjust = 0.5))

ggsave(file.path(fig_dir, "fig3_forest_plot.pdf"), fig3,
       width = 7, height = 5)
cat("  Saved fig3_forest_plot.pdf\n")

# ==============================================================================
# Figure 4: Heterogeneity — Labor-Intensive vs Non-Labor-Intensive (Split Sample ES)
# ==============================================================================
cat("=== Figure 4: Heterogeneity by Labor Intensity ===\n")

li_coefs <- extract_es_coefs(results$labor_int_fit, "Labor-Intensive")
nli_coefs <- extract_es_coefs(results$non_labor_int_fit, "Non-Labor-Intensive")
het_data <- rbind(li_coefs, nli_coefs)
setnames(het_data, "crop", "group")

fig4 <- ggplot(het_data, aes(x = rel_time, y = estimate, color = group, fill = group)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "red", alpha = 0.3) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.12, color = NA) +
  geom_point(size = 2) +
  geom_line() +
  scale_color_manual(values = cols) +
  scale_fill_manual(values = cols) +
  labs(x = "Years Relative to MGNREGA Implementation",
       y = "Effect on Log Yield (kg/ha)",
       title = "Heterogeneous Effects: Labor-Intensive vs. Non-Labor-Intensive Crops",
       color = "", fill = "") +
  scale_x_continuous(breaks = seq(-10, 12, by = 2)) +
  theme(legend.position = "bottom",
        plot.title = element_text(hjust = 0.5))

ggsave(file.path(fig_dir, "fig4_heterogeneity_labor.pdf"), fig4,
       width = 8, height = 5)
cat("  Saved fig4_heterogeneity_labor.pdf\n")

# ==============================================================================
# Figure 5: Mechanism — Fertilizer Intensification Event Study
# ==============================================================================
cat("=== Figure 5: Fertilizer Mechanism ===\n")

fert_coefs <- extract_es_coefs(results$fert_es, "Total Fertilizer/ha")

fig5 <- ggplot(fert_coefs, aes(x = rel_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "red", alpha = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#009E73") +
  geom_point(size = 2, color = "#009E73") +
  geom_line(color = "#009E73") +
  labs(x = "Years Relative to MGNREGA Implementation",
       y = "Effect on Log Fertilizer per Hectare",
       title = "Mechanism: Fertilizer Intensification After MGNREGA") +
  scale_x_continuous(breaks = seq(-10, 12, by = 2)) +
  theme(plot.title = element_text(hjust = 0.5))

ggsave(file.path(fig_dir, "fig5_fertilizer_mechanism.pdf"), fig5,
       width = 8, height = 5)
cat("  Saved fig5_fertilizer_mechanism.pdf\n")

# ==============================================================================
# Figure 6: MGNREGA Phase Map (District Treatment Timing)
# ==============================================================================
cat("=== Figure 6: Treatment Timing Distribution ===\n")

phase_dist <- baseline[, .N, by = mgnrega_phase]
phase_dist[, phase_label := paste0("Phase ", mgnrega_phase)]

fig6 <- ggplot(baseline, aes(x = factor(mgnrega_phase), fill = factor(mgnrega_phase))) +
  geom_bar() +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.5) +
  scale_fill_manual(values = c("1" = "#E69F00", "2" = "#56B4E9", "3" = "#009E73")) +
  labs(x = "MGNREGA Phase",
       y = "Number of Districts",
       title = "Distribution of Districts by MGNREGA Phase") +
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5))

ggsave(file.path(fig_dir, "fig6_phase_distribution.pdf"), fig6,
       width = 6, height = 4)
cat("  Saved fig6_phase_distribution.pdf\n")

# ==============================================================================
# Figure 7: Aggregate Yield Event Study
# ==============================================================================
cat("=== Figure 7: Aggregate Yield Event Study ===\n")

agg_coefs <- extract_es_coefs(results$agg_es, "Aggregate Yield")

fig7 <- ggplot(agg_coefs, aes(x = rel_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "red", alpha = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#CC79A7") +
  geom_point(size = 2, color = "#CC79A7") +
  geom_line(color = "#CC79A7") +
  labs(x = "Years Relative to MGNREGA Implementation",
       y = "Effect on Log Area-Weighted Average Yield",
       title = "Aggregate Yield Effects of MGNREGA") +
  scale_x_continuous(breaks = seq(-10, 12, by = 2)) +
  theme(plot.title = element_text(hjust = 0.5))

ggsave(file.path(fig_dir, "fig7_aggregate_yield.pdf"), fig7,
       width = 8, height = 5)
cat("  Saved fig7_aggregate_yield.pdf\n")

# ==============================================================================
# Figure A1: Pre-trend Test Results (Appendix)
# ==============================================================================
cat("=== Figure A1: Pre-trend F-stats ===\n")

if (length(rob_results$pretrend_tests) > 0) {
  pt_data <- rbindlist(lapply(names(rob_results$pretrend_tests), function(cn) {
    x <- rob_results$pretrend_tests[[cn]]
    data.table(crop = cn, f_stat = x$f_stat, p_value = x$p_value)
  }))
  pt_data[, pass := p_value > 0.10]
  pt_data[, crop := factor(crop, levels = crop[order(p_value)])]

  figA1 <- ggplot(pt_data, aes(x = crop, y = p_value, fill = pass)) +
    geom_col() +
    geom_hline(yintercept = 0.10, linetype = "dashed", color = "red") +
    scale_fill_manual(values = c("TRUE" = "#009E73", "FALSE" = "#D55E00"),
                      labels = c("TRUE" = "Pass (p > 0.10)", "FALSE" = "Fail")) +
    labs(x = "", y = "p-value (Joint F-test of Pre-Treatment Coefficients)",
         title = "Pre-Trend Tests by Crop", fill = "") +
    coord_flip() +
    theme(legend.position = "bottom",
          plot.title = element_text(hjust = 0.5))

  ggsave(file.path(fig_dir, "figA1_pretrend_tests.pdf"), figA1,
         width = 7, height = 5)
  cat("  Saved figA1_pretrend_tests.pdf\n")
}

cat("\nAll figures saved.\n")
