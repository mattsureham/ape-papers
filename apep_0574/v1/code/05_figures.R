## 05_figures.R — Publication-quality figures
## APEP-0574: Gas Shock Import Substitution
## Inputs:  CSVs from data/ (event studies, main results, robustness)
## Outputs: Figures 1-6 as PDF in ../figures/

source("00_packages.R")

data_dir <- "../data/"
fig_dir  <- "../figures/"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# Color palette
col_treat   <- "#C0392B"   # Red for treatment/energy-intensive
col_control <- "#2980B9"   # Blue for control/non-EI
col_ci      <- "#BDC3C7"   # Light grey for CI bands
col_shock   <- "#E74C3C"   # Bright red for shock line
col_dark    <- "#2C3E50"   # Dark for main coefficients

# =====================================================================
# FIGURE 1: Monthly Production Event Study (Main Figure)
# =====================================================================
cat("=== Figure 1: Production event study ===\n")

es_prod <- fread(file.path(data_dir, "event_study_production.csv"))

fig1 <- ggplot(es_prod, aes(x = rel_month, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.4) +
  geom_vline(xintercept = 0, linetype = "dashed", color = col_shock, linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              fill = col_ci, alpha = 0.5) +
  geom_line(color = col_dark, linewidth = 0.7) +
  geom_point(color = col_dark, size = 1.2) +
  annotate("text", x = 1.5, y = max(es_prod$ci_upper, na.rm = TRUE) * 0.9,
           label = "Russia invades\nUkraine (Feb 2022)",
           hjust = 0, size = 3, color = col_shock, fontface = "italic") +
  scale_x_continuous(
    breaks = seq(-24, 30, by = 6),
    labels = function(x) {
      dates <- as.Date("2022-02-01") %m+% months(x)
      format(dates, "%b\n%Y")
    }
  ) +
  labs(
    x = "Months relative to February 2022",
    y = expression(hat(beta)[t] ~ "(Gas dependence" %*% "Energy-intensive" %*% "Month)"),
    title = NULL
  ) +
  theme(
    panel.grid.major.x = element_blank(),
    axis.text.x = element_text(size = 8)
  )

ggsave(file.path(fig_dir, "fig1_production_event_study.pdf"),
       fig1, width = 8, height = 5.5)
cat("  Saved fig1_production_event_study.pdf\n")

# =====================================================================
# FIGURE 2: Annual Extra-EU Import Trends (Raw Data)
# =====================================================================
cat("=== Figure 2: Annual import trends ===\n")

trade_panel <- fread(file.path(data_dir, "trade_panel.csv"))

# Classify countries into high vs low gas dependence (median split)
med_gas <- median(unique(trade_panel[, .(geo, gas_dep)])$gas_dep)
trade_panel[, gas_group := ifelse(gas_dep > med_gas, "High gas dependence", "Low gas dependence")]

# Aggregate: mean imports by year × SITC × gas group
trend_data <- trade_panel[, .(
  mean_imports = mean(import_mio_eur, na.rm = TRUE)
), by = .(year, sitc06, product_label, ei, gas_group)]

# Normalize to 2021 = 100 for comparability
trend_data <- merge(
  trend_data,
  trend_data[year == 2021, .(sitc06, gas_group, base = mean_imports)],
  by = c("sitc06", "gas_group")
)
trend_data[, import_index := 100 * mean_imports / base]

# Separate energy-intensive and non-EI for clarity
trend_data[, sector_type := ifelse(ei == 1, "Energy-intensive", "Non-energy-intensive")]

fig2 <- ggplot(trend_data, aes(x = year, y = import_index,
                                color = sector_type, linetype = sector_type)) +
  geom_vline(xintercept = 2022, linetype = "dashed", color = col_shock, linewidth = 0.4) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.8) +
  facet_wrap(~gas_group) +
  scale_color_manual(values = c("Energy-intensive" = col_treat,
                                 "Non-energy-intensive" = col_control),
                      name = "Product type") +
  scale_linetype_manual(values = c("Energy-intensive" = "solid",
                                    "Non-energy-intensive" = "dashed"),
                         name = "Product type") +
  scale_x_continuous(breaks = 2017:2024) +
  labs(
    x = NULL,
    y = "Mean extra-EU imports (2021 = 100)"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
    legend.position = "bottom"
  )

ggsave(file.path(fig_dir, "fig2_import_trends.pdf"),
       fig2, width = 8, height = 5)
cat("  Saved fig2_import_trends.pdf\n")

# =====================================================================
# FIGURE 3: Triple-Diff Coefficients (Bar Chart)
# =====================================================================
cat("=== Figure 3: Triple-diff coefficients ===\n")

r1 <- fread(file.path(data_dir, "main_tripleDiD_results.csv"))

# Filter to triple-interaction terms only
triple_coefs <- r1[grepl("gas_dep.*ei.*post|gas_exposure.*ei.*post|gas_dep_binary.*ei.*post", term)]
triple_coefs[, ci_lower := estimate - 1.96 * se]
triple_coefs[, ci_upper := estimate + 1.96 * se]

# Clean model names for display
triple_coefs[, model_label := fcase(
  model == "triple_did_main", "Main\n(continuous)",
  model == "triple_did_clean", "Absorbed FE\n(clean)",
  model == "triple_did_exposure", "Gas exposure\n(share x TPES)",
  model == "triple_did_binary", "Binary\n(above median)"
)]
triple_coefs[, model_label := factor(model_label,
  levels = c("Main\n(continuous)", "Absorbed FE\n(clean)",
             "Gas exposure\n(share x TPES)", "Binary\n(above median)"))]

fig3 <- ggplot(triple_coefs, aes(x = model_label, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_col(fill = col_dark, width = 0.6, alpha = 0.8) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper),
                width = 0.2, linewidth = 0.6, color = col_treat) +
  labs(
    x = "Specification",
    y = expression(hat(beta) ~ "(Triple-difference coefficient)")
  ) +
  theme(
    axis.text.x = element_text(size = 9)
  )

ggsave(file.path(fig_dir, "fig3_triple_diff_coefficients.pdf"),
       fig3, width = 7, height = 5)
cat("  Saved fig3_triple_diff_coefficients.pdf\n")

# =====================================================================
# FIGURE 4: BEC Intermediate Imports Event Study
# =====================================================================
cat("=== Figure 4: BEC event study ===\n")

bec_es <- fread(file.path(data_dir, "bec_event_study.csv"))

fig4 <- ggplot(bec_es, aes(x = rel_month, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.4) +
  geom_vline(xintercept = 0, linetype = "dashed", color = col_shock, linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              fill = col_ci, alpha = 0.5) +
  geom_line(color = col_control, linewidth = 0.7) +
  geom_point(color = col_control, size = 1.2) +
  annotate("text", x = 1.5, y = max(bec_es$ci_upper, na.rm = TRUE) * 0.85,
           label = "Invasion",
           hjust = 0, size = 3, color = col_shock, fontface = "italic") +
  scale_x_continuous(
    breaks = seq(-24, 30, by = 6),
    labels = function(x) {
      dates <- as.Date("2022-02-01") %m+% months(x)
      format(dates, "%b\n%Y")
    }
  ) +
  labs(
    x = "Months relative to February 2022",
    y = expression(hat(beta)[t] ~ "(Gas dep." %*% "Intermediate goods" %*% "Month)")
  ) +
  theme(
    panel.grid.major.x = element_blank(),
    axis.text.x = element_text(size = 8)
  )

ggsave(file.path(fig_dir, "fig4_bec_event_study.pdf"),
       fig4, width = 8, height = 5.5)
cat("  Saved fig4_bec_event_study.pdf\n")

# =====================================================================
# FIGURE 5: Persistence — Shock vs Post-Normalization Effects
# =====================================================================
cat("=== Figure 5: Persistence ===\n")

persist <- fread(file.path(data_dir, "persistence_results.csv"))

# Extract triple-interaction coefficients
persist_triple <- persist[grepl("gas_dep.*ei.*(shock|post_norm)", term)]
persist_triple[, ci_lower := estimate - 1.96 * se]
persist_triple[, ci_upper := estimate + 1.96 * se]

# Label periods
persist_triple[, period := fcase(
  grepl("shock_year", term) | grepl("shock_phase", term), "Shock\n(2022)",
  grepl("post_norm", term), "Post-normalization\n(2023-2024)"
)]
persist_triple[, panel := fcase(
  grepl("trade", model), "Trade panel",
  grepl("production", model), "Production panel"
)]

# Trade panel only (production persistence in appendix)
persist_trade <- persist_triple[panel == "Trade panel"]

fig5 <- ggplot(persist_trade, aes(x = period, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_col(width = 0.5, alpha = 0.85, fill = col_dark) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper),
                width = 0.15, linewidth = 0.5) +
  labs(
    x = NULL,
    y = expression(hat(beta) ~ "(Triple-diff coefficient)")
  )

ggsave(file.path(fig_dir, "fig5_persistence.pdf"),
       fig5, width = 7, height = 5)
cat("  Saved fig5_persistence.pdf\n")

# =====================================================================
# FIGURE 6: Leave-One-Out Robustness
# =====================================================================
cat("=== Figure 6: Leave-one-out robustness ===\n")

loo <- fread(file.path(data_dir, "robustness_loo.csv"))
loo[, ci_lower := estimate - 1.96 * se]
loo[, ci_upper := estimate + 1.96 * se]

# Get full-sample estimate
full_est <- loo[dropped_country == "none"]$estimate
loo_plot <- loo[dropped_country != "none"]
loo_plot <- loo_plot[order(estimate)]
loo_plot[, dropped_country := factor(dropped_country, levels = dropped_country)]

fig6 <- ggplot(loo_plot, aes(x = dropped_country, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.4) +
  geom_hline(yintercept = full_est, linetype = "solid", color = col_treat,
             linewidth = 0.5, alpha = 0.7) +
  geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper),
                  color = col_dark, size = 0.3, linewidth = 0.4) +
  annotate("text", x = 2, y = full_est,
           label = "Full sample", color = col_treat, size = 3,
           vjust = -0.7, fontface = "italic") +
  labs(
    x = "Dropped country",
    y = expression(hat(beta) ~ "(Triple-diff coefficient)")
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 7)
  )

ggsave(file.path(fig_dir, "fig6_leave_one_out.pdf"),
       fig6, width = 9, height = 5)
cat("  Saved fig6_leave_one_out.pdf\n")

# =====================================================================
# SUMMARY
# =====================================================================
cat("\n=== ALL FIGURES COMPLETE ===\n")
cat(sprintf("Saved %d figures to %s\n",
            length(list.files(fig_dir, pattern = "\\.pdf$")), fig_dir))
