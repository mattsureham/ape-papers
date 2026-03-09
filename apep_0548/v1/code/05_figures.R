## 05_figures.R — Generate all figures from saved analysis data
## APEP-0548: Selective Licensing and Housing Markets in England

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

## ===================================================================
## FIGURE 1: Treatment Rollout Timeline
## ===================================================================
cat("Figure 1: Treatment rollout timeline...\n")

licensing <- fread(file.path(data_dir, "licensing_adoption_dates.csv"))

fig1_data <- licensing[, .N, by = licensing_year]
setnames(fig1_data, c("year", "n_new"))
fig1_data <- fig1_data[order(year)]
fig1_data[, cumulative := cumsum(n_new)]

p1 <- ggplot(fig1_data, aes(x = year)) +
  geom_col(aes(y = n_new), fill = "#2166AC", alpha = 0.7, width = 0.7) +
  geom_line(aes(y = cumulative), color = "#B2182B", linewidth = 1.2) +
  geom_point(aes(y = cumulative), color = "#B2182B", size = 2.5) +
  scale_y_continuous("Count", sec.axis = sec_axis(~., name = "Cumulative")) +
  scale_x_continuous("Year", breaks = seq(2008, 2024, 2)) +
  labs(title = "Selective Licensing Adoption Across English Local Authorities",
       subtitle = "Bars: new adoptions per year. Line: cumulative total.") +
  theme(plot.title = element_text(size = 13))

ggsave(file.path(fig_dir, "fig1_rollout_timeline.pdf"), p1,
       width = 8, height = 5)

## ===================================================================
## FIGURE 2: Event Study (Callaway-Sant'Anna)
## ===================================================================
cat("Figure 2: CS-DiD event study...\n")

es_file <- file.path(data_dir, "cs_did_event_study.csv")
if (file.exists(es_file)) {
  es_dt <- fread(es_file)

  p2 <- ggplot(es_dt, aes(x = rel_year, y = att)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey40") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
                fill = "#2166AC", alpha = 0.2) +
    geom_point(size = 2.5, color = "#2166AC") +
    geom_line(color = "#2166AC", linewidth = 0.8) +
    scale_x_continuous("Years Relative to Licensing Adoption",
                       breaks = seq(-5, 8, 1)) +
    scale_y_continuous("ATT (Log Property Price)") +
    labs(title = "Event Study: Effect of Selective Licensing on Property Prices",
         subtitle = "Callaway-Sant'Anna (2021). 95% confidence intervals.") +
    annotate("text", x = -3, y = max(es_dt$ci_upper, na.rm = TRUE) * 0.9,
             label = "Pre-treatment", hjust = 0.5, size = 3.5, color = "grey40") +
    annotate("text", x = 3, y = max(es_dt$ci_upper, na.rm = TRUE) * 0.9,
             label = "Post-treatment", hjust = 0.5, size = 3.5, color = "grey40")

  ggsave(file.path(fig_dir, "fig2_event_study_cs.pdf"), p2,
         width = 8, height = 5.5)
}

## ===================================================================
## FIGURE 3: Sun & Abraham Event Study (Robustness)
## ===================================================================
cat("Figure 3: Sun-Abraham event study...\n")

sa_file <- file.path(data_dir, "sun_abraham_event_study.csv")
if (file.exists(sa_file)) {
  sa_dt <- fread(sa_file)

  p3 <- ggplot(sa_dt, aes(x = rel_year, y = att)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey40") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
                fill = "#D6604D", alpha = 0.2) +
    geom_point(size = 2.5, color = "#D6604D") +
    geom_line(color = "#D6604D", linewidth = 0.8) +
    scale_x_continuous("Years Relative to Licensing Adoption",
                       breaks = seq(-5, 8, 1)) +
    scale_y_continuous("Coefficient (Log Property Price)") +
    labs(title = "Event Study: Sun & Abraham (2021) Interaction-Weighted Estimator",
         subtitle = "95% confidence intervals. Reference period: t = -1.")

  ggsave(file.path(fig_dir, "fig3_event_study_sa.pdf"), p3,
         width = 8, height = 5.5)
}

## ===================================================================
## FIGURE 4: Placebo by Property Type
## ===================================================================
cat("Figure 4: Placebo by property type...\n")

placebo_file <- file.path(data_dir, "placebo_property_type.csv")
if (file.exists(placebo_file)) {
  placebo_dt <- fread(placebo_file)

  p4 <- ggplot(placebo_dt, aes(x = reorder(label, coef), y = coef)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_point(size = 3, color = "#2166AC") +
    geom_errorbar(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
                  width = 0.15, color = "#2166AC") +
    coord_flip() +
    labs(x = "Property Type",
         y = "Treatment Effect (Log Price)",
         title = "Treatment Effect by Property Type",
         subtitle = "Flats (most PRS-exposed) vs. detached (least exposed). TWFE estimates.") +
    theme(plot.title = element_text(size = 13))

  ggsave(file.path(fig_dir, "fig4_placebo_property_type.pdf"), p4,
         width = 7, height = 4.5)
}

## ===================================================================
## FIGURE 5: Leave-One-Out Sensitivity
## ===================================================================
cat("Figure 5: Leave-one-out...\n")

loo_file <- file.path(data_dir, "leave_one_out.csv")
if (file.exists(loo_file)) {
  loo_dt <- fread(loo_file)

  ## Get full sample estimate
  twfe_full <- fread(file.path(data_dir, "twfe_results.csv"))
  full_coef <- twfe_full$coef[1]

  p5 <- ggplot(loo_dt, aes(x = reorder(dropped_la, coef), y = coef)) +
    geom_hline(yintercept = full_coef, linetype = "solid",
               color = "#B2182B", linewidth = 0.8) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_point(size = 1.5, color = "#2166AC", alpha = 0.7) +
    labs(x = "Dropped Local Authority (rank-ordered)",
         y = "Treatment Effect (Log Price)",
         title = "Leave-One-Out Sensitivity",
         subtitle = "Each point drops one treated LA. Red line: full-sample estimate.") +
    theme(axis.text.x = element_blank(),
          axis.ticks.x = element_blank())

  ggsave(file.path(fig_dir, "fig5_leave_one_out.pdf"), p5,
         width = 8, height = 5)
}

## ===================================================================
## FIGURE 6: Randomization Inference Distribution
## ===================================================================
cat("Figure 6: Randomization inference...\n")

ri_file <- file.path(data_dir, "ri_permutation_coefs.csv")
ri_summary_file <- file.path(data_dir, "ri_summary.csv")
if (file.exists(ri_file) && file.exists(ri_summary_file)) {
  ri_dt <- fread(ri_file)
  ri_sum <- fread(ri_summary_file)

  p6 <- ggplot(ri_dt, aes(x = ri_coefs)) +
    geom_histogram(bins = 40, fill = "grey70", color = "grey50", alpha = 0.8) +
    geom_vline(xintercept = ri_sum$actual_coef, color = "#B2182B",
               linewidth = 1.2, linetype = "solid") +
    annotate("text", x = ri_sum$actual_coef, y = Inf,
             label = paste0("Actual\n(p = ", round(ri_sum$ri_pval, 3), ")"),
             hjust = -0.15, vjust = 1.5, color = "#B2182B", size = 3.5,
             fontface = "bold") +
    labs(x = "Permuted Treatment Effect",
         y = "Count",
         title = "Randomization Inference",
         subtitle = paste0(nrow(ri_dt), " permutations of treatment assignment."))

  ggsave(file.path(fig_dir, "fig6_randomization_inference.pdf"), p6,
         width = 7, height = 5)
}

## ===================================================================
## FIGURE 7: Dose-Response by PRS Share
## ===================================================================
cat("Figure 7: Dose-response...\n")

dose_file <- file.path(data_dir, "dose_response_results.csv")
if (file.exists(dose_file)) {
  dose_dt <- fread(dose_file)

  p7 <- ggplot(dose_dt[model != "Dose-response (continuous)"],
               aes(x = model, y = coef_treated)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_point(size = 3.5, color = "#2166AC") +
    geom_errorbar(aes(ymin = coef_treated - 1.96 * se_treated,
                      ymax = coef_treated + 1.96 * se_treated),
                  width = 0.15, color = "#2166AC") +
    labs(x = "", y = "Treatment Effect (Log Price)",
         title = "Treatment Effect by PRS Exposure",
         subtitle = "LAs split at median PRS share from Census 2021.") +
    coord_flip()

  ggsave(file.path(fig_dir, "fig7_dose_response.pdf"), p7,
         width = 7, height = 4)
}

## ===================================================================
## FIGURE 8: Raw Price Trends (Treated vs Control)
## ===================================================================
cat("Figure 8: Raw price trends...\n")

la_qtr_plot <- fread(file.path(data_dir, "la_quarter_panel.csv"))
la_qtr_plot[, qtr_date := as.Date(qtr_date)]

trends <- la_qtr_plot[year >= 2005 & year <= 2024,
                       .(mean_log_price = mean(mean_log_price, na.rm = TRUE),
                         se = sd(mean_log_price, na.rm = TRUE) / sqrt(.N)),
                       by = .(year, treated_ever)]

p8 <- ggplot(trends, aes(x = year, y = mean_log_price,
                           color = factor(treated_ever),
                           fill = factor(treated_ever))) +
  geom_ribbon(aes(ymin = mean_log_price - 1.96 * se,
                  ymax = mean_log_price + 1.96 * se),
              alpha = 0.15, color = NA) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_color_manual(values = c("FALSE" = "#4393C3", "TRUE" = "#D6604D"),
                     labels = c("Never licensed", "Ever licensed")) +
  scale_fill_manual(values = c("FALSE" = "#4393C3", "TRUE" = "#D6604D"),
                    labels = c("Never licensed", "Ever licensed")) +
  scale_x_continuous(breaks = seq(2005, 2024, 2)) +
  labs(x = "Year", y = "Mean Log Transaction Price",
       color = "", fill = "",
       title = "Property Price Trends: Licensed vs. Non-Licensed Local Authorities",
       subtitle = "Mean log transaction price by treatment group. 95% CIs.") +
  theme(legend.position = c(0.2, 0.85))

ggsave(file.path(fig_dir, "fig8_raw_trends.pdf"), p8,
       width = 8, height = 5.5)

## ===================================================================
## FIGURE 9: Goodman-Bacon Decomposition (if available)
## ===================================================================
cat("Figure 9: Bacon decomposition...\n")

bacon_file <- file.path(data_dir, "bacon_decomposition.csv")
if (file.exists(bacon_file)) {
  bacon_dt <- fread(bacon_file)

  if ("weight" %in% names(bacon_dt) && "estimate" %in% names(bacon_dt)) {
    p9 <- ggplot(bacon_dt, aes(x = weight, y = estimate, color = type)) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
      geom_point(size = 3, alpha = 0.7) +
      labs(x = "Weight", y = "2x2 DiD Estimate",
           color = "Comparison Type",
           title = "Goodman-Bacon Decomposition of TWFE Estimate") +
      theme(legend.position = "bottom")

    ggsave(file.path(fig_dir, "fig9_bacon_decomposition.pdf"), p9,
           width = 8, height = 5.5)
  }
}

cat("\n=== All figures generated ===\n")
cat("Figures saved to: ", fig_dir, "\n")
