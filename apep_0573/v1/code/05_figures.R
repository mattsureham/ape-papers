## ============================================================
## 05_figures.R — All figure generation
## apep_0573: EU Procurement Reform and Competition
## ============================================================

source(file.path(dirname(sys.frame(1)$ofile), "00_packages.R"))

cat("=== Loading data for figures ===\n")
panel <- fread(file.path(data_dir, "panel_country_quarter.csv"))
transposition <- fread(file.path(data_dir, "transposition_dates.csv"))

# ============================================================
# Figure 1: Transposition timeline
# ============================================================
cat("  Figure 1: Transposition timeline\n")

trans_plot <- transposition[order(transposition_date)]
trans_plot[, country_label := iso2]
trans_plot[, country_label := factor(country_label, levels = rev(trans_plot$country_label))]

# Country names for nicer labels
trans_plot[, country_name := countrycode(iso2, "iso2c", "country.name")]
trans_plot[iso2 == "EL", country_name := "Greece"]
trans_plot[iso2 == "UK", country_name := "United Kingdom"]
trans_plot[, country_name := factor(country_name, levels = rev(trans_plot$country_name))]

p1 <- ggplot(trans_plot, aes(x = transposition_date, y = country_name,
                              color = on_time)) +
  geom_vline(xintercept = as.Date("2016-04-18"), linetype = "dashed",
             color = "grey50", linewidth = 0.5) +
  geom_point(size = 3) +
  scale_color_manual(values = c("TRUE" = "#2166AC", "FALSE" = "#B2182B"),
                     labels = c("TRUE" = "On time", "FALSE" = "Late"),
                     name = "") +
  annotate("text", x = as.Date("2016-04-18"), y = 0.5,
           label = "Deadline: April 18, 2016", hjust = -0.05, size = 3, color = "grey50") +
  labs(x = "Transposition date", y = "",
       title = "Staggered Transposition of the 2014 Public Procurement Directives",
       subtitle = "National transposition of Directive 2014/24/EU across EU-28 member states") +
  theme(legend.position = c(0.8, 0.15))

ggsave(file.path(fig_dir, "fig1_transposition_timeline.pdf"), p1,
       width = 8, height = 8)
ggsave(file.path(fig_dir, "fig1_transposition_timeline.png"), p1,
       width = 8, height = 8, dpi = 300)

# ============================================================
# Figure 2: Event study — single-bidder share (C-S)
# ============================================================
cat("  Figure 2: Event study (single-bidder share)\n")

es_file <- file.path(data_dir, "cs_event_study_single_bidder.csv")
if (file.exists(es_file)) {
  es_data <- fread(es_file)

  p2 <- ggplot(es_data, aes(x = event_time, y = att)) +
    geom_hline(yintercept = 0, color = "grey70") +
    geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey50") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "#2166AC") +
    geom_point(size = 2, color = "#2166AC") +
    geom_line(color = "#2166AC") +
    labs(x = "Quarters relative to transposition",
         y = "ATT on single-bidder share",
         title = "Event Study: Effect of Procurement Reform on Single-Bidder Contracts",
         subtitle = "Callaway-Sant'Anna estimator, not-yet-treated control group") +
    scale_x_continuous(breaks = seq(-8, 12, 2)) +
    annotate("text", x = -4, y = max(es_data$ci_upper, na.rm = TRUE) * 0.9,
             label = "Pre-treatment", size = 3, color = "grey50") +
    annotate("text", x = 6, y = max(es_data$ci_upper, na.rm = TRUE) * 0.9,
             label = "Post-treatment", size = 3, color = "grey50")

  ggsave(file.path(fig_dir, "fig2_event_study_single_bidder.pdf"), p2,
         width = 8, height = 5.5)
  ggsave(file.path(fig_dir, "fig2_event_study_single_bidder.png"), p2,
         width = 8, height = 5.5, dpi = 300)
} else {
  cat("    Event study data not found, using fixest event study\n")
  # Fallback: plot fixest event study
  panel[, et_trim := pmin(pmax(event_time, -8), 12)]
  es_model <- feols(single_bidder_share ~ i(et_trim, ref = -1) | country + time_period,
                    data = panel, cluster = ~country, weights = ~n_contracts)

  es_coefs <- as.data.table(coeftable(es_model))
  es_coefs[, event_time := as.numeric(gsub("et_trim::", "", rownames(coeftable(es_model))))]
  setnames(es_coefs, c("Estimate", "Std. Error"), c("att", "se"))
  es_coefs[, ci_lower := att - 1.96 * se]
  es_coefs[, ci_upper := att + 1.96 * se]

  # Add reference point
  es_coefs <- rbind(es_coefs[, .(event_time, att, se, ci_lower, ci_upper)],
                    data.table(event_time = -1, att = 0, se = 0, ci_lower = 0, ci_upper = 0))
  es_coefs <- es_coefs[order(event_time)]

  fwrite(es_coefs, file.path(data_dir, "cs_event_study_single_bidder.csv"))

  p2 <- ggplot(es_coefs, aes(x = event_time, y = att)) +
    geom_hline(yintercept = 0, color = "grey70") +
    geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey50") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "#2166AC") +
    geom_point(size = 2, color = "#2166AC") +
    geom_line(color = "#2166AC") +
    labs(x = "Quarters relative to transposition",
         y = "Effect on single-bidder share",
         title = "Event Study: Effect of Procurement Reform on Single-Bidder Contracts",
         subtitle = "Two-way fixed effects event study, clustered at country level") +
    scale_x_continuous(breaks = seq(-8, 12, 2))

  ggsave(file.path(fig_dir, "fig2_event_study_single_bidder.pdf"), p2,
         width = 8, height = 5.5)
  ggsave(file.path(fig_dir, "fig2_event_study_single_bidder.png"), p2,
         width = 8, height = 5.5, dpi = 300)
}

# ============================================================
# Figure 3: Event study — log bids
# ============================================================
cat("  Figure 3: Event study (log bids)\n")

es_bids_file <- file.path(data_dir, "cs_event_study_log_bids.csv")
if (file.exists(es_bids_file)) {
  es_bids <- fread(es_bids_file)

  p3 <- ggplot(es_bids, aes(x = event_time, y = att)) +
    geom_hline(yintercept = 0, color = "grey70") +
    geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey50") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "#B2182B") +
    geom_point(size = 2, color = "#B2182B") +
    geom_line(color = "#B2182B") +
    labs(x = "Quarters relative to transposition",
         y = "ATT on log(mean bids)",
         title = "Event Study: Effect of Procurement Reform on Competitive Intensity",
         subtitle = "Callaway-Sant'Anna estimator, not-yet-treated control group") +
    scale_x_continuous(breaks = seq(-8, 12, 2))

  ggsave(file.path(fig_dir, "fig3_event_study_log_bids.pdf"), p3,
         width = 8, height = 5.5)
  ggsave(file.path(fig_dir, "fig3_event_study_log_bids.png"), p3,
         width = 8, height = 5.5, dpi = 300)
}

# ============================================================
# Figure 4: Heterogeneity by administrative capacity
# ============================================================
cat("  Figure 4: Heterogeneity by capacity\n")

het_data <- fread(file.path(data_dir, "heterogeneity_capacity.csv"))
het_data[, ci_lower := coef - 1.96 * se]
het_data[, ci_upper := coef + 1.96 * se]

p4 <- ggplot(het_data, aes(x = group, y = coef)) +
  geom_hline(yintercept = 0, color = "grey70") +
  geom_point(size = 3, color = "#2166AC") +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.1, color = "#2166AC") +
  labs(x = "", y = "Effect on single-bidder share",
       title = "Heterogeneity by Administrative Capacity",
       subtitle = "Split at median World Bank Government Effectiveness (2014)") +
  coord_flip()

ggsave(file.path(fig_dir, "fig4_heterogeneity_capacity.pdf"), p4,
       width = 7, height = 4)
ggsave(file.path(fig_dir, "fig4_heterogeneity_capacity.png"), p4,
       width = 7, height = 4, dpi = 300)

# ============================================================
# Figure 5: Leave-one-out
# ============================================================
cat("  Figure 5: Leave-one-out\n")

loo_data <- fread(file.path(data_dir, "leave_one_out.csv"))
loo_data[, dropped := factor(dropped, levels = loo_data[order(coef)]$dropped)]

# Get full-sample estimate
twfe_results <- fread(file.path(data_dir, "twfe_results.csv"))
full_est <- twfe_results[outcome == "single_bidder_share", coef]

p5 <- ggplot(loo_data, aes(x = dropped, y = coef)) +
  geom_hline(yintercept = full_est, color = "#2166AC", linetype = "dashed") +
  geom_hline(yintercept = 0, color = "grey70") +
  geom_point(size = 2) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.3, linewidth = 0.3) +
  labs(x = "Country dropped", y = "Coefficient on treated",
       title = "Leave-One-Out Sensitivity",
       subtitle = "Each point drops one country; dashed line = full sample estimate") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 7))

ggsave(file.path(fig_dir, "fig5_leave_one_out.pdf"), p5,
       width = 9, height = 5)
ggsave(file.path(fig_dir, "fig5_leave_one_out.png"), p5,
       width = 9, height = 5, dpi = 300)

# ============================================================
# Figure 6: Randomization Inference
# ============================================================
cat("  Figure 6: Randomization inference\n")

ri_file <- file.path(data_dir, "ri_permutation_dist.csv")
if (file.exists(ri_file)) {
  ri_data <- fread(ri_file)

  p6 <- ggplot(ri_data, aes(x = perm_att)) +
    geom_histogram(bins = 50, fill = "grey80", color = "grey60") +
    geom_vline(xintercept = full_est, color = "#B2182B", linewidth = 1) +
    geom_vline(xintercept = -full_est, color = "#B2182B", linewidth = 1, linetype = "dashed") +
    labs(x = "Permuted treatment effect", y = "Count",
         title = "Randomization Inference Distribution",
         subtitle = paste0("Red line = observed estimate; two-sided RI p-value based on ",
                           nrow(ri_data), " permutations")) +
    annotate("text", x = full_est, y = Inf, label = paste0("Observed: ", round(full_est, 4)),
             hjust = -0.1, vjust = 2, color = "#B2182B", size = 3.5)

  ggsave(file.path(fig_dir, "fig6_randomization_inference.pdf"), p6,
         width = 7, height = 5)
  ggsave(file.path(fig_dir, "fig6_randomization_inference.png"), p6,
         width = 7, height = 5, dpi = 300)
}

# ============================================================
# Figure 7: Raw trends — single-bidder share by cohort
# ============================================================
cat("  Figure 7: Raw trends by cohort\n")

panel[, cohort := fifelse(on_time == TRUE, "On-time (8 states)", "Late transposers (20 states)")]

trend_data <- panel[, .(
  single_bidder_share = weighted.mean(single_bidder_share, n_contracts, na.rm = TRUE),
  mean_bids = weighted.mean(mean_bids, n_contracts, na.rm = TRUE)
), by = .(contract_year, cohort)]
fwrite(trend_data, file.path(data_dir, "trend_by_cohort.csv"))

p7 <- ggplot(trend_data, aes(x = contract_year, y = single_bidder_share, color = cohort)) +
  geom_vline(xintercept = 2016.25, linetype = "dashed", color = "grey50") +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  scale_color_manual(values = c("On-time (8 states)" = "#2166AC",
                                 "Late transposers (20 states)" = "#B2182B")) +
  labs(x = "Year", y = "Single-bidder share",
       title = "Single-Bidder Contract Share by Transposition Cohort",
       subtitle = "Weighted by number of contracts; vertical line at April 2016 deadline",
       color = "") +
  scale_x_continuous(breaks = seq(2009, 2023, 2)) +
  theme(legend.position = c(0.3, 0.85))

ggsave(file.path(fig_dir, "fig7_raw_trends_cohort.pdf"), p7,
       width = 8, height = 5.5)
ggsave(file.path(fig_dir, "fig7_raw_trends_cohort.png"), p7,
       width = 8, height = 5.5, dpi = 300)

# ============================================================
# Figure A1: SME event study (Appendix)
# ============================================================
cat("  Figure A1: SME event study (appendix)\n")

es_sme_file <- file.path(data_dir, "cs_event_study_sme.csv")
if (file.exists(es_sme_file)) {
  es_sme <- fread(es_sme_file)

  pa1 <- ggplot(es_sme, aes(x = event_time, y = att)) +
    geom_hline(yintercept = 0, color = "grey70") +
    geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey50") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "#4DAF4A") +
    geom_point(size = 2, color = "#4DAF4A") +
    geom_line(color = "#4DAF4A") +
    labs(x = "Quarters relative to transposition",
         y = "ATT on SME winner share",
         title = "Event Study: Effect on SME Contract Awards",
         subtitle = "Callaway-Sant'Anna estimator") +
    scale_x_continuous(breaks = seq(-8, 12, 2))

  ggsave(file.path(fig_dir, "figA1_event_study_sme.pdf"), pa1,
         width = 8, height = 5.5)
  ggsave(file.path(fig_dir, "figA1_event_study_sme.png"), pa1,
         width = 8, height = 5.5, dpi = 300)
}

cat("\n05_figures.R complete.\n")
