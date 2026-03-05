## ============================================================================
## 05_figures.R — All figures for 340B × Medicaid RDD paper
## ============================================================================

source("00_packages.R")

DATA <- "../data"
FIGS <- "../figures"
dir.create(FIGS, showWarnings = FALSE, recursive = TRUE)

analysis_xs <- readRDS(file.path(DATA, "analysis_xs.rds"))
analysis <- readRDS(file.path(DATA, "analysis_panel.rds"))

## ============================================================================
## Figure 1: DSH Distribution with Threshold
## ============================================================================

cat("Figure 1: DSH Distribution\n")

fig1 <- ggplot(analysis_xs, aes(x = dsh_pct)) +
  geom_histogram(binwidth = 1, fill = "gray70", color = "white", linewidth = 0.3) +
  geom_vline(xintercept = 11.75, color = "red", linetype = "dashed", linewidth = 0.8) +
  annotate("text", x = 12.5, y = Inf, label = "340B Threshold\n(11.75%)",
           hjust = 0, vjust = 1.5, color = "red", size = 3.5) +
  labs(x = "DSH Adjustment Percentage (%)",
       y = "Number of Hospitals",
       title = "Distribution of Hospital DSH Adjustment Percentages",
       subtitle = "General acute care hospitals, HCRIS 2019-2023 average") +
  scale_x_continuous(breaks = seq(0, 80, by = 10)) +
  coord_cartesian(xlim = c(0, 80))

ggsave(file.path(FIGS, "fig1_dsh_distribution.pdf"), fig1, width = 8, height = 5)

## ============================================================================
## Figure 2: McCrary Density Plot
## ============================================================================

cat("Figure 2: McCrary Density\n")

density_test <- rddensity(X = analysis_xs$dsh_centered)
density_plot <- rdplotdensity(density_test, analysis_xs$dsh_centered,
                               plotN = 50, plotRange = c(-15, 30))

# Extract plot and customize
fig2 <- density_plot$Estplot +
  geom_vline(xintercept = 0, color = "red", linetype = "dashed") +
  labs(x = "DSH Percentage Relative to 11.75% Threshold",
       y = "Density",
       title = "McCrary Density Test at 340B Eligibility Threshold",
       subtitle = sprintf("p-value = %.3f (no evidence of manipulation)",
                          density_test$test$p_jk))

ggsave(file.path(FIGS, "fig2_mccrary.pdf"), fig2, width = 8, height = 5)

## ============================================================================
## Figure 3: RDD Plot — Medicaid Drug Spending
## ============================================================================

cat("Figure 3: RDD Plot - Medicaid Drugs\n")

# Binned scatter with rdplot
rdd_data <- analysis_xs[abs(dsh_centered) <= 15 & !is.na(asinh_mcaid_drug)]

rdplot_mcaid <- rdplot(y = rdd_data$asinh_mcaid_drug,
                        x = rdd_data$dsh_centered,
                        binselect = "es",
                        p = 1,
                        kernel = "triangular",
                        title = "",
                        x.label = "",
                        y.label = "")

fig3 <- rdplot_mcaid$rdplot +
  geom_vline(xintercept = 0, color = "red", linetype = "dashed", linewidth = 0.5) +
  labs(x = "DSH % Relative to 11.75% Threshold",
       y = "Medicaid Drug Spending (asinh)",
       title = "340B Eligibility and Medicaid Drug Administration",
       subtitle = "Binned means with local linear fit")

ggsave(file.path(FIGS, "fig3_rdd_medicaid_drugs.pdf"), fig3, width = 8, height = 6)

## ============================================================================
## Figure 4: RDD Plot — Medicare Drug Spending (Comparison)
## ============================================================================

cat("Figure 4: RDD Plot - Medicare Drugs\n")

rdd_data2 <- analysis_xs[abs(dsh_centered) <= 15 & !is.na(asinh_mcare_drug)]

rdplot_mcare <- rdplot(y = rdd_data2$asinh_mcare_drug,
                        x = rdd_data2$dsh_centered,
                        binselect = "es",
                        p = 1,
                        kernel = "triangular",
                        title = "",
                        x.label = "",
                        y.label = "")

fig4 <- rdplot_mcare$rdplot +
  geom_vline(xintercept = 0, color = "red", linetype = "dashed", linewidth = 0.5) +
  labs(x = "DSH % Relative to 11.75% Threshold",
       y = "Medicare Drug Spending (asinh)",
       title = "340B Eligibility and Medicare Drug Administration",
       subtitle = "Zip-level physician drug billing")

ggsave(file.path(FIGS, "fig4_rdd_medicare_drugs.pdf"), fig4, width = 8, height = 6)

## ============================================================================
## Figure 5: Bandwidth Sensitivity
## ============================================================================

cat("Figure 5: Bandwidth Sensitivity\n")

robustness <- readRDS("../results/robustness.rds")
bw_df <- rbindlist(robustness$bandwidth)
bw_df[, ci_lower := coef - 1.96 * se]
bw_df[, ci_upper := coef + 1.96 * se]

fig5 <- ggplot(bw_df, aes(x = bw, y = coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = pal_340b["Medicaid"]) +
  geom_line(color = pal_340b["Medicaid"], linewidth = 0.8) +
  geom_point(color = pal_340b["Medicaid"], size = 2.5) +
  labs(x = "Bandwidth (percentage points)",
       y = "RD Estimate (asinh Medicaid drug spending)",
       title = "Bandwidth Sensitivity of 340B Effect on Medicaid Drugs",
       subtitle = "Point estimates and 95% CIs across fixed bandwidths") +
  scale_x_continuous(breaks = c(2, 3, 4, 5, 7, 10))

ggsave(file.path(FIGS, "fig5_bandwidth_sensitivity.pdf"), fig5, width = 8, height = 5)

## ============================================================================
## Figure 6: Placebo Cutoff Tests
## ============================================================================

cat("Figure 6: Placebo Cutoffs\n")

placebo_df <- rbindlist(robustness$placebo_cutoffs)
placebo_df[, ci_lower := coef - 1.96 * se]
placebo_df[, ci_upper := coef + 1.96 * se]
placebo_df[, is_true := cutoff == 11.75]

# Add true cutoff from main results
main_results <- readRDS("../results/main_results.rds")
true_row <- data.table(
  cutoff = 11.75,
  coef = main_results$mcaid_drug$coef,
  se = main_results$mcaid_drug$se,
  pval = main_results$mcaid_drug$pval,
  ci_lower = main_results$mcaid_drug$coef - 1.96 * main_results$mcaid_drug$se,
  ci_upper = main_results$mcaid_drug$coef + 1.96 * main_results$mcaid_drug$se,
  is_true = TRUE
)
placebo_df[, is_true := FALSE]
placebo_all <- rbind(placebo_df, true_row, fill = TRUE)

fig6 <- ggplot(placebo_all, aes(x = cutoff, y = coef, color = is_true)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper), size = 0.5) +
  scale_color_manual(values = c("FALSE" = "gray50", "TRUE" = "red"),
                     labels = c("Placebo", "True (11.75%)"), name = "") +
  labs(x = "DSH Cutoff (%)",
       y = "RD Estimate (asinh Medicaid drug spending)",
       title = "Placebo Cutoff Tests",
       subtitle = "RDD estimates at true and false thresholds")

ggsave(file.path(FIGS, "fig6_placebo_cutoffs.pdf"), fig6, width = 8, height = 5)

## ============================================================================
## Figure 7: Year-by-Year Estimates
## ============================================================================

cat("Figure 7: Year-by-Year\n")

yearly_df <- rbindlist(robustness$yearly)
yearly_df[, ci_lower := coef - 1.96 * se]
yearly_df[, ci_upper := coef + 1.96 * se]

fig7 <- ggplot(yearly_df, aes(x = year, y = coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = pal_340b["Medicaid"]) +
  geom_line(color = pal_340b["Medicaid"], linewidth = 0.8) +
  geom_point(color = pal_340b["Medicaid"], size = 2.5) +
  labs(x = "Fiscal Year",
       y = "RD Estimate (asinh Medicaid drug spending)",
       title = "Year-by-Year RDD Estimates",
       subtitle = "340B effect on Medicaid drug spending by fiscal year") +
  scale_x_continuous(breaks = yearly_df$year)

ggsave(file.path(FIGS, "fig7_yearly_estimates.pdf"), fig7, width = 8, height = 5)

## ============================================================================
## Figure 8: RDD Plot — Placebo Outcome (Non-Drug Billing)
## ============================================================================

cat("Figure 8: Placebo Outcome\n")

rdd_data3 <- analysis_xs[abs(dsh_centered) <= 15]
rdd_data3[, asinh_nondrug := asinh(mcaid_nondrug_paid)]

rdplot_nondrug <- rdplot(y = rdd_data3$asinh_nondrug,
                          x = rdd_data3$dsh_centered,
                          binselect = "es",
                          p = 1,
                          kernel = "triangular",
                          title = "",
                          x.label = "",
                          y.label = "")

fig8 <- rdplot_nondrug$rdplot +
  geom_vline(xintercept = 0, color = "red", linetype = "dashed", linewidth = 0.5) +
  labs(x = "DSH % Relative to 11.75% Threshold",
       y = "Non-Drug Medicaid Spending (asinh)",
       title = "Placebo: 340B Eligibility and Non-Drug Medicaid Billing",
       subtitle = "No discontinuity expected for non-drug services")

ggsave(file.path(FIGS, "fig8_placebo_nondrug.pdf"), fig8, width = 8, height = 6)

## ============================================================================
## Figure 9: Panel Binned Scatter (Residualized)
## ============================================================================

cat("Figure 9: Panel Binned Scatter\n")

panel_data <- analysis[!is.na(dsh_centered) & abs(dsh_centered) <= 10]
panel_data[, asinh_mcaid_drug := asinh(mcaid_drug_paid)]

# Residualize by year FE
panel_data[, year_mean := mean(asinh_mcaid_drug), by = fiscal_year]
panel_data[, resid_drug := asinh_mcaid_drug - year_mean + mean(asinh_mcaid_drug)]

# Create bins
panel_data[, dsh_bin := cut(dsh_centered,
                             breaks = seq(-10, 10, by = 1),
                             include.lowest = TRUE)]
bin_means <- panel_data[!is.na(dsh_bin), .(
  y = mean(resid_drug),
  x = mean(dsh_centered),
  n = .N
), by = dsh_bin]

fig9 <- ggplot(bin_means, aes(x = x, y = y)) +
  geom_vline(xintercept = 0, color = "red", linetype = "dashed", linewidth = 0.5) +
  geom_point(aes(size = n), color = pal_340b["Medicaid"], alpha = 0.8) +
  geom_smooth(data = bin_means[x < 0], method = "lm", se = TRUE,
              color = pal_340b["Medicaid"], fill = pal_340b["Medicaid"], alpha = 0.15) +
  geom_smooth(data = bin_means[x >= 0], method = "lm", se = TRUE,
              color = pal_340b["Medicaid"], fill = pal_340b["Medicaid"], alpha = 0.15) +
  labs(x = "DSH % Relative to 11.75% Threshold",
       y = "Medicaid Drug Spending (asinh, year-demeaned)",
       title = "Panel Binned Scatter: 340B and Medicaid Drug Administration",
       subtitle = "Hospital-year observations, year effects removed, ±10pp window") +
  scale_size_continuous(name = "Obs per bin", range = c(2, 6)) +
  theme(legend.position = "right")

ggsave(file.path(FIGS, "fig9_panel_binned.pdf"), fig9, width = 8, height = 6)

cat("\n=== All figures saved ===\n")
