# ==============================================================================
# 05_figures.R — Generate all figures from saved data
# APEP-0570: Malaysia GST-to-SST Tax Pass-Through
# ==============================================================================

source("00_packages.R")

panel <- fread("../data/analysis_panel.csv")
panel[, date := as.Date(date)]
class_map <- fread("../data/class_map.csv")

# Color palette
col_A <- "#E64B35"   # Red - Group A (full cycle)
col_B <- "#4DBBD5"   # Blue - Group B (permanent windfall)
col_C <- "#00A087"   # Green - Group C (control)
col_treat <- "#3C5488"  # Dark blue - treated (A+B combined)

# Vertical lines for key dates
vline_gst_intro <- as.Date("2015-04-01")
vline_gst_zero <- as.Date("2018-06-01")
vline_sst <- as.Date("2018-09-01")

# ==============================================================================
# FIGURE 1: Average CPI by Product Group
# ==============================================================================

cat("--- Figure 1: CPI by group ---\n")

avg_cpi <- panel[, .(mean_cpi = mean(index, na.rm = TRUE)), by = .(date, group)]

fig1 <- ggplot(avg_cpi, aes(x = date, y = mean_cpi, color = group)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = vline_gst_intro, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  geom_vline(xintercept = vline_gst_zero, linetype = "solid", color = "grey30", linewidth = 0.7) +
  geom_vline(xintercept = vline_sst, linetype = "dotted", color = "grey30", linewidth = 0.7) +
  annotate("text", x = vline_gst_intro, y = Inf, label = "GST\nintroduced",
           vjust = 1.5, hjust = -0.1, size = 2.8, color = "grey40") +
  annotate("text", x = vline_gst_zero, y = Inf, label = "GST\nzeroed",
           vjust = 1.5, hjust = -0.1, size = 2.8, color = "grey30") +
  annotate("text", x = vline_sst, y = Inf, label = "SST\nimposed",
           vjust = 1.5, hjust = -0.1, size = 2.8, color = "grey30") +
  scale_color_manual(
    values = c("A" = col_A, "B" = col_B, "C" = col_C),
    labels = c("A" = "Group A: GST-taxed, SST-covered",
               "B" = "Group B: GST-taxed, no SST",
               "C" = "Group C: Zero-rated/Exempt (Control)")
  ) +
  labs(
    title = "Consumer Price Indices by Tax Treatment Group",
    subtitle = "Malaysia, 101 product classes (COICOP 4-digit), monthly 2010\u20132026",
    x = NULL, y = "CPI (2010 = 100)", color = NULL
  ) +
  theme(legend.position = "bottom",
        legend.text = element_text(size = 9))

ggsave("../figures/fig1_cpi_by_group.pdf", fig1, width = 10, height = 6)
ggsave("../figures/fig1_cpi_by_group.png", fig1, width = 10, height = 6, dpi = 300)

# ==============================================================================
# FIGURE 2: Event Study — DiD (Treated vs Control)
# ==============================================================================

cat("--- Figure 2: Event study ---\n")

es_coefs <- fread("../data/event_study_coefs.csv")

# Add reference period
es_coefs <- rbind(
  es_coefs,
  data.table(event_month = 0, estimate = 0, se = 0, ci_lo = 0, ci_hi = 0)
)

fig2 <- ggplot(es_coefs, aes(x = event_month, y = estimate)) +
  geom_hline(yintercept = 0, color = "grey50", linewidth = 0.3) +
  geom_vline(xintercept = 0.5, linetype = "solid", color = "grey30", linewidth = 0.6) +
  geom_vline(xintercept = 3.5, linetype = "dotted", color = "grey30", linewidth = 0.6) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, fill = col_treat) +
  geom_line(color = col_treat, linewidth = 0.7) +
  geom_point(color = col_treat, size = 1.2) +
  annotate("text", x = 1, y = Inf, label = "GST zeroed",
           vjust = 1.5, hjust = -0.1, size = 2.8, color = "grey30") +
  annotate("text", x = 4, y = Inf, label = "SST imposed",
           vjust = 1.5, hjust = -0.1, size = 2.8, color = "grey30") +
  scale_x_continuous(breaks = seq(-36, 36, 6)) +
  labs(
    title = "Event Study: Effect of GST Zeroing on Standard-Rated Products",
    subtitle = "Coefficients relative to May 2018 (last month of GST at 6%); 95% CIs",
    x = "Months relative to June 2018",
    y = "log(CPI) relative to control"
  )

ggsave("../figures/fig2_event_study.pdf", fig2, width = 10, height = 6)
ggsave("../figures/fig2_event_study.png", fig2, width = 10, height = 6, dpi = 300)

# ==============================================================================
# FIGURE 3: Event Study by Group (A vs B)
# ==============================================================================

cat("--- Figure 3: Event study by group ---\n")

es_group <- fread("../data/event_study_by_group.csv")

# Add reference periods
es_group <- rbind(
  es_group,
  data.table(event_month = 0, estimate = 0, se = 0, ci_lo = 0, ci_hi = 0, group = "A"),
  data.table(event_month = 0, estimate = 0, se = 0, ci_lo = 0, ci_hi = 0, group = "B")
)

fig3 <- ggplot(es_group, aes(x = event_month, y = estimate, color = group, fill = group)) +
  geom_hline(yintercept = 0, color = "grey50", linewidth = 0.3) +
  geom_vline(xintercept = 0.5, linetype = "solid", color = "grey30", linewidth = 0.6) +
  geom_vline(xintercept = 3.5, linetype = "dotted", color = "grey30", linewidth = 0.6) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.1, color = NA) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 1) +
  annotate("text", x = 1, y = Inf, label = "GST zeroed",
           vjust = 1.5, hjust = -0.1, size = 2.8, color = "grey30") +
  annotate("text", x = 4, y = Inf, label = "SST imposed",
           vjust = 1.5, hjust = -0.1, size = 2.8, color = "grey30") +
  scale_color_manual(
    values = c("A" = col_A, "B" = col_B),
    labels = c("A" = "Group A: SST-covered (price recovery expected)",
               "B" = "Group B: No SST (permanent reduction)")
  ) +
  scale_fill_manual(
    values = c("A" = col_A, "B" = col_B),
    labels = c("A" = "Group A: SST-covered (price recovery expected)",
               "B" = "Group B: No SST (permanent reduction)")
  ) +
  scale_x_continuous(breaks = seq(-36, 36, 6)) +
  labs(
    title = "Event Study by Tax Treatment Group",
    subtitle = "Within-group variation relative to May 2018; 95% CIs",
    x = "Months relative to June 2018",
    y = "log(CPI) relative to pre-treatment",
    color = NULL, fill = NULL
  ) +
  theme(legend.position = "bottom",
        legend.text = element_text(size = 9))

ggsave("../figures/fig3_event_study_groups.pdf", fig3, width = 10, height = 6)
ggsave("../figures/fig3_event_study_groups.png", fig3, width = 10, height = 6, dpi = 300)

# ==============================================================================
# FIGURE 4: Leave-One-Out Stability
# ==============================================================================

cat("--- Figure 4: Leave-one-out ---\n")

loo <- fread("../data/loo_results.csv")
full_est <- fread("../data/passthrough_estimates.csv")[parameter == "beta_removal", estimate]

fig4 <- ggplot(loo, aes(x = reorder(excluded_class, estimate), y = estimate)) +
  geom_hline(yintercept = full_est, linetype = "dashed", color = "red", linewidth = 0.5) +
  geom_point(size = 1.5, color = col_treat) +
  geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0, linewidth = 0.3,
                color = col_treat, alpha = 0.5) +
  coord_flip() +
  labs(
    title = "Leave-One-Class-Out Stability",
    subtitle = paste0("Full-sample estimate (dashed red): ",
                     sprintf("%.4f", full_est)),
    x = "Excluded product class",
    y = "DiD estimate (log CPI)"
  ) +
  theme(axis.text.y = element_text(size = 5))

ggsave("../figures/fig4_loo.pdf", fig4, width = 8, height = 12)
ggsave("../figures/fig4_loo.png", fig4, width = 8, height = 12, dpi = 300)

# ==============================================================================
# FIGURE 5: Randomization Inference Distribution
# ==============================================================================

cat("--- Figure 5: Randomization inference ---\n")

ri <- fread("../data/ri_estimates.csv")
ri_summ <- fread("../data/ri_summary.csv")
actual <- ri_summ$actual_estimate

fig5 <- ggplot(ri, aes(x = estimate)) +
  geom_histogram(bins = 50, fill = "grey70", color = "white", linewidth = 0.2) +
  geom_vline(xintercept = actual, color = "red", linewidth = 1) +
  annotate("text", x = actual, y = Inf,
           label = sprintf("Actual = %.4f\nRI p = %.3f", actual, ri_summ$ri_pvalue),
           vjust = 1.5, hjust = -0.1, size = 3.5, color = "red") +
  labs(
    title = "Randomization Inference: Distribution of Placebo Estimates",
    subtitle = paste0(ri_summ$n_permutations, " random permutations of treatment assignment"),
    x = "Permuted DiD estimate",
    y = "Frequency"
  )

ggsave("../figures/fig5_ri.pdf", fig5, width = 8, height = 5)
ggsave("../figures/fig5_ri.png", fig5, width = 8, height = 5, dpi = 300)

# ==============================================================================
# FIGURE 6: Zoomed view around June-September 2018
# ==============================================================================

cat("--- Figure 6: Zoomed view ---\n")

zoom_data <- panel[date >= "2018-01-01" & date <= "2019-06-01",
                   .(mean_cpi = mean(index, na.rm = TRUE)), by = .(date, group)]

# Normalize to January 2018 = 100 for each group
jan2018 <- zoom_data[date == as.Date("2018-01-01")]
setnames(jan2018, "mean_cpi", "base_cpi")
zoom_data <- merge(zoom_data, jan2018[, .(group, base_cpi)], by = "group")
zoom_data[, normalized_cpi := (mean_cpi / base_cpi) * 100]

fig6 <- ggplot(zoom_data, aes(x = date, y = normalized_cpi, color = group)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_vline(xintercept = vline_gst_zero, linetype = "solid", color = "grey30", linewidth = 0.7) +
  geom_vline(xintercept = vline_sst, linetype = "dotted", color = "grey30", linewidth = 0.7) +
  annotate("rect", xmin = vline_gst_zero, xmax = vline_sst,
           ymin = -Inf, ymax = Inf, fill = "gold", alpha = 0.1) +
  annotate("text", x = as.Date("2018-07-15"), y = Inf,
           label = "Tax\nholiday", vjust = 1.5, size = 3, color = "goldenrod4") +
  scale_color_manual(
    values = c("A" = col_A, "B" = col_B, "C" = col_C),
    labels = c("A" = "Group A: GST+SST",
               "B" = "Group B: GST only",
               "C" = "Group C: Control")
  ) +
  labs(
    title = "Price Dynamics Around the Tax Regime Change",
    subtitle = "Normalized to January 2018 = 100",
    x = NULL, y = "CPI (Jan 2018 = 100)", color = NULL
  ) +
  theme(legend.position = "bottom")

ggsave("../figures/fig6_zoom.pdf", fig6, width = 10, height = 6)
ggsave("../figures/fig6_zoom.png", fig6, width = 10, height = 6, dpi = 300)

# ==============================================================================
# FIGURE 7: Product-level pass-through heterogeneity
# ==============================================================================

cat("--- Figure 7: Pass-through heterogeneity ---\n")

# Estimate product-specific effects
product_effects <- panel[!is.na(log_cpi), {
  if (.N > 20 & uniqueN(date[post_june == 0]) > 5 & uniqueN(date[post_june == 1]) > 5) {
    m <- lm(log_cpi ~ post_june + factor(date))
    ct <- coef(summary(m))
    if ("post_june" %in% rownames(ct)) {
      list(beta = ct["post_june", "Estimate"],
           se = ct["post_june", "Std. Error"])
    } else {
      list(beta = NA_real_, se = NA_real_)
    }
  } else {
    list(beta = NA_real_, se = NA_real_)
  }
}, by = .(class, group)]

product_effects <- product_effects[!is.na(beta)]
product_effects[, `:=`(ci_lo = beta - 1.96 * se, ci_hi = beta + 1.96 * se)]

fig7 <- ggplot(product_effects[group %in% c("A", "B")],
               aes(x = reorder(class, beta), y = beta, color = group)) +
  geom_hline(yintercept = 0, color = "grey50", linewidth = 0.3) +
  geom_hline(yintercept = -log(1.06), linetype = "dashed", color = "grey40",
             linewidth = 0.4) +
  geom_point(size = 1.5) +
  geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0, linewidth = 0.3, alpha = 0.5) +
  coord_flip() +
  scale_color_manual(
    values = c("A" = col_A, "B" = col_B),
    labels = c("A" = "SST-covered", "B" = "No SST")
  ) +
  annotate("text", x = 1, y = -log(1.06), label = "Full 6% pass-through",
           hjust = -0.1, vjust = -0.5, size = 2.5, color = "grey40") +
  labs(
    title = "Product-Level Pass-Through Rates",
    subtitle = "Each point = one product class; dashed line = full 6% GST pass-through",
    x = "Product class", y = "Estimated price effect (log CPI)",
    color = NULL
  ) +
  theme(axis.text.y = element_text(size = 5),
        legend.position = "bottom")

ggsave("../figures/fig7_heterogeneity.pdf", fig7, width = 8, height = 10)
ggsave("../figures/fig7_heterogeneity.png", fig7, width = 8, height = 10, dpi = 300)

fwrite(product_effects, "../data/product_effects.csv")

# ==============================================================================
# FIGURE 8: Placebo timing
# ==============================================================================

cat("--- Figure 8: Placebo timing ---\n")

placebo <- fread("../data/placebo_timing.csv")
# Add actual estimate
actual_dt <- data.table(
  placebo_year = 2018,
  estimate = full_est,
  se = fread("../data/passthrough_estimates.csv")[parameter == "beta_removal", se],
  significant = TRUE
)
actual_dt[, `:=`(ci_lo = estimate - 1.96 * se, ci_hi = estimate + 1.96 * se)]

placebo_plot <- rbind(placebo, actual_dt, fill = TRUE)

fig8 <- ggplot(placebo_plot, aes(x = factor(placebo_year), y = estimate)) +
  geom_hline(yintercept = 0, color = "grey50", linewidth = 0.3) +
  geom_point(aes(color = placebo_year == 2018), size = 3) +
  geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi, color = placebo_year == 2018),
                width = 0.2, linewidth = 0.8) +
  scale_color_manual(values = c("TRUE" = "red", "FALSE" = "grey50"),
                     guide = "none") +
  labs(
    title = "Placebo Timing Tests",
    subtitle = "Red = actual treatment (June 2018); grey = placebo years (pre-treatment sample only)",
    x = "Placebo treatment year (June)", y = "DiD estimate (log CPI)"
  )

ggsave("../figures/fig8_placebo.pdf", fig8, width = 7, height = 5)
ggsave("../figures/fig8_placebo.png", fig8, width = 7, height = 5, dpi = 300)

cat("\n=== All figures generated ===\n")
cat("Saved to figures/\n")
