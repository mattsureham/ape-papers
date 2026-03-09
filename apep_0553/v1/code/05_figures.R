## 05_figures.R — Generate all figures for the paper
## apep_0553: Do Export Controls Have Teeth?

source("00_packages.R")

DATA_DIR <- "../data"
FIG_DIR <- "../figures"
dir.create(FIG_DIR, showWarnings = FALSE)

## ============================================================
## Load data
## ============================================================

panel <- fread(file.path(DATA_DIR, "panel_hs6.csv"))
es_coefs <- fread(file.path(DATA_DIR, "event_study_coefs.csv"))
loo_dt <- tryCatch(fread(file.path(DATA_DIR, "leave_one_out.csv")), error = function(e) NULL)

## ============================================================
## FIGURE 1: Aggregate rerouting — Transit vs Control
## ============================================================

has_control <- any(panel$role == "control")

if (has_control) {
  fig1_data <- panel[role %in% c("transit", "control"), .(
    total_trade = sum(fob_value, na.rm = TRUE) / 1e6
  ), by = .(year, role, is_chpl)]
  fig1_data[, product_type := ifelse(is_chpl, "CHPL Products", "Non-CHPL Products")]
  p1 <- ggplot(fig1_data, aes(x = year, y = total_trade, color = role, linetype = product_type)) +
    geom_line(linewidth = 0.9) + geom_point(size = 2) +
    geom_vline(xintercept = 2021.5, linetype = "dashed", color = "grey40", linewidth = 0.5) +
    geom_vline(xintercept = 2023.4, linetype = "dotted", color = "red3", linewidth = 0.5) +
    annotate("text", x = 2021.5, y = max(fig1_data$total_trade) * 0.95,
             label = "Sanctions", hjust = 1.1, size = 3, color = "grey40") +
    annotate("text", x = 2023.4, y = max(fig1_data$total_trade) * 0.85,
             label = "CHPL", hjust = -0.1, size = 3, color = "red3") +
    scale_color_manual(values = c("transit" = "#2166AC", "control" = "#B2182B"),
                       labels = c("Transit Countries", "Control Countries")) +
    scale_x_continuous(breaks = 2015:2024) +
    labs(x = NULL, y = "Total Exports to Russia ($ Millions)",
         color = NULL, linetype = NULL,
         title = "Exports to Russia by Country Role and Product Type") +
    theme(legend.position = "bottom", axis.text.x = element_text(angle = 45, hjust = 1))
} else {
  fig1_data <- panel[role == "transit", .(
    total_trade = sum(fob_value, na.rm = TRUE) / 1e6
  ), by = .(year, is_chpl)]
  fig1_data[, product_type := ifelse(is_chpl, "CHPL Products", "Non-CHPL Products")]
  p1 <- ggplot(fig1_data, aes(x = year, y = total_trade, color = product_type)) +
    geom_line(linewidth = 0.9) + geom_point(size = 2) +
    geom_vline(xintercept = 2021.5, linetype = "dashed", color = "grey40", linewidth = 0.5) +
    geom_vline(xintercept = 2023.4, linetype = "dotted", color = "red3", linewidth = 0.5) +
    annotate("text", x = 2021.5, y = max(fig1_data$total_trade) * 0.95,
             label = "Sanctions", hjust = 1.1, size = 3, color = "grey40") +
    annotate("text", x = 2023.4, y = max(fig1_data$total_trade) * 0.85,
             label = "CHPL", hjust = -0.1, size = 3, color = "red3") +
    scale_color_manual(values = c("CHPL Products" = "#D6604D", "Non-CHPL Products" = "#4393C3")) +
    scale_x_continuous(breaks = 2015:2024) +
    labs(x = NULL, y = "Transit Country Exports to Russia ($ Millions)",
         color = NULL,
         title = "CHPL vs Non-CHPL Exports to Russia Through Transit Countries") +
    theme(legend.position = "bottom", axis.text.x = element_text(angle = 45, hjust = 1))
}

ggsave(file.path(FIG_DIR, "fig1_aggregate_rerouting.pdf"), p1,
       width = 8, height = 5.5)
cat("Figure 1 saved.\n")

## ============================================================
## FIGURE 2: Event Study — DDD Coefficients
## ============================================================

if (nrow(es_coefs) > 0 && "event_year" %in% names(es_coefs)) {

  # Add the reference year (0 by definition)
  ref_row <- data.table(event_year = -1, estimate = 0, se = 0,
                        ci_lower = 0, ci_upper = 0)
  es_plot <- rbind(es_coefs[, .(event_year, estimate, se, ci_lower, ci_upper)],
                   ref_row, fill = TRUE)
  es_plot <- es_plot[order(event_year)]

  p2 <- ggplot(es_plot, aes(x = event_year, y = estimate)) +
    geom_hline(yintercept = 0, color = "grey50", linewidth = 0.3) +
    geom_vline(xintercept = -0.5, linetype = "dashed", color = "grey40") +
    geom_vline(xintercept = 1.5, linetype = "dotted", color = "red3") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15, fill = "#2166AC") +
    geom_line(color = "#2166AC", linewidth = 0.8) +
    geom_point(color = "#2166AC", size = 2.5) +
    annotate("text", x = -0.5, y = max(es_plot$ci_upper, na.rm = TRUE) * 0.9,
             label = "Sanctions", hjust = 1.1, size = 3) +
    annotate("text", x = 1.5, y = max(es_plot$ci_upper, na.rm = TRUE) * 0.9,
             label = "CHPL", hjust = -0.1, size = 3, color = "red3") +
    scale_x_continuous(breaks = -7:2,
                       labels = c(paste0(2015:2021), "2022\n(sanctions)", "2023", "2024\n(CHPL)")) +
    labs(x = "Year",
         y = ifelse(has_control, "Coefficient (Transit x CHPL x Year)", "Coefficient (CHPL x Year)"),
         title = "Event Study: Differential CHPL Rerouting Through Transit Countries") +
    theme(axis.text.x = element_text(size = 8))

  ggsave(file.path(FIG_DIR, "fig2_event_study.pdf"), p2,
         width = 8, height = 5)
  cat("Figure 2 saved.\n")
}

## ============================================================
## FIGURE 3: Transit Country Decomposition (Top Products)
## ============================================================

# Top CHPL products by rerouting magnitude
chpl_rerouting <- panel[role == "transit" & is_chpl == TRUE, .(
  pre_avg = mean(fob_value[year <= 2021]),
  peak_2023 = sum(fob_value[year == 2023]),
  post_chpl_2024 = sum(fob_value[year == 2024])
), by = hs6]

chpl_rerouting[, rerouting_magnitude := peak_2023 - pre_avg]
chpl_rerouting[, enforcement_drop := peak_2023 - post_chpl_2024]
setorder(chpl_rerouting, -rerouting_magnitude)

top_products <- head(chpl_rerouting[rerouting_magnitude > 0], 10)

if (nrow(top_products) > 0) {
  top_ts <- panel[role == "transit" & hs6 %in% top_products$hs6, .(
    total = sum(fob_value, na.rm = TRUE) / 1e6
  ), by = .(year, hs6)]

  p3 <- ggplot(top_ts, aes(x = year, y = total, color = hs6)) +
    geom_line(linewidth = 0.7) +
    geom_point(size = 1.5) +
    geom_vline(xintercept = 2021.5, linetype = "dashed", color = "grey40") +
    geom_vline(xintercept = 2023.4, linetype = "dotted", color = "red3") +
    scale_x_continuous(breaks = 2015:2024) +
    labs(x = NULL, y = "Transit Country Exports to Russia ($ Millions)",
         color = "HS6 Code",
         title = "Top CHPL Products: Rerouting Spike and Enforcement Collapse") +
    theme(legend.position = "right",
          axis.text.x = element_text(angle = 45, hjust = 1))

  ggsave(file.path(FIG_DIR, "figA_top_products.pdf"), p3,
         width = 9, height = 5.5)
  cat("Appendix figure (top products) saved.\n")
}

## ============================================================
## FIGURE 4: Country-Level Rerouting Heterogeneity
## ============================================================

transit_by_country <- panel[role == "transit" & is_chpl == TRUE, .(
  total = sum(fob_value, na.rm = TRUE) / 1e6
), by = .(year, reporter_name)]

if (nrow(transit_by_country) > 0 && length(unique(transit_by_country$reporter_name)) > 1) {
  p4 <- ggplot(transit_by_country, aes(x = year, y = total)) +
    geom_line(color = "#2166AC", linewidth = 0.9) +
    geom_point(color = "#2166AC", size = 2) +
    geom_vline(xintercept = 2021.5, linetype = "dashed", color = "grey40", linewidth = 0.4) +
    geom_vline(xintercept = 2023.4, linetype = "dotted", color = "red3", linewidth = 0.4) +
    facet_wrap(~reporter_name, scales = "free_y", ncol = 3) +
    scale_x_continuous(breaks = seq(2015, 2024, 3)) +
    labs(x = NULL, y = "CHPL Exports to Russia ($ Millions)",
         title = "CHPL Technology Rerouting by Transit Country") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
          strip.text = element_text(size = 10))

  ggsave(file.path(FIG_DIR, "fig4_country_decomposition.pdf"), p4,
         width = 8, height = 5.5)
  cat("Figure 4 saved.\n")
}

## ============================================================
## FIGURE 5: Leave-One-Out Stability
## ============================================================

if (!is.null(loo_dt) && nrow(loo_dt) > 0) {
  # Use beta2 (enforcement coefficient) for the LOO plot
  # LOO data has columns: dropped, beta1_est, beta1_se, beta2_est, beta2_se
  main_est <- -3.619  # From main regression
  main_se <- 0.851

  p5 <- ggplot(loo_dt, aes(x = reorder(dropped, beta2_est), y = beta2_est)) +
    geom_hline(yintercept = main_est, color = "#2166AC", linewidth = 0.5) +
    geom_hline(yintercept = 0, color = "grey50", linewidth = 0.3) +
    annotate("rect", xmin = -Inf, xmax = Inf,
             ymin = main_est - 1.96 * main_se,
             ymax = main_est + 1.96 * main_se,
             fill = "#2166AC", alpha = 0.1) +
    geom_point(size = 3, color = "#B2182B") +
    geom_errorbar(aes(ymin = beta2_est - 1.96 * beta2_se,
                      ymax = beta2_est + 1.96 * beta2_se),
                  width = 0.2, color = "#B2182B") +
    coord_flip() +
    labs(x = "Country Dropped", y = expression(hat(beta)[2] ~ "(Enforcement Effect)"),
         title = "Leave-One-Out: Stability of CHPL Enforcement Coefficient") +
    theme(panel.grid.major.y = element_blank())

  ggsave(file.path(FIG_DIR, "fig5_leave_one_out.pdf"), p5,
         width = 7, height = 4.5)
  cat("Figure 5 saved.\n")
}

## ============================================================
## APPENDIX FIGURE: Permutation Distribution (if available)
## ============================================================

perm_dist <- tryCatch(fread(file.path(DATA_DIR, "permutation_distribution.csv")), error = function(e) NULL)
perm_summary <- tryCatch(fread(file.path(DATA_DIR, "permutation_inference.csv")), error = function(e) NULL)

if (!is.null(perm_dist) && !is.null(perm_summary) && nrow(perm_dist) > 0) {
  actual_b2 <- perm_summary$actual_beta2[1]
  perm_p <- perm_summary$perm_p_twosided[1]

  p_perm <- ggplot(perm_dist, aes(x = perm_beta2)) +
    geom_histogram(bins = 50, fill = "grey70", color = "grey50", linewidth = 0.2) +
    geom_vline(xintercept = actual_b2, color = "#D6604D", linewidth = 1, linetype = "solid") +
    annotate("text", x = actual_b2, y = Inf,
             label = sprintf("Actual beta[2] == %.2f", actual_b2),
             hjust = ifelse(actual_b2 < 0, 1.1, -0.1), vjust = 2,
             size = 3.5, color = "#D6604D", parse = FALSE) +
    labs(x = expression(hat(beta)[2] ~ "(Permuted CHPL Assignment)"),
         y = "Frequency",
         title = "Randomization Inference: Distribution Under the Null",
         subtitle = sprintf("Permutation p-value = %.3f (N = %d permutations)",
                           perm_p, nrow(perm_dist))) +
    theme(plot.subtitle = element_text(size = 9))

  ggsave(file.path(FIG_DIR, "figA_permutation_dist.pdf"), p_perm,
         width = 7, height = 4.5)
  cat("Appendix permutation figure saved.\n")
}

cat("\n=== ALL FIGURES GENERATED ===\n")
