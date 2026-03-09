## ============================================================================
## 05_figures.R — Generate all figures from saved CSVs
## Paper: Demonetization by Design (apep_0555)
## ============================================================================

source(file.path(here::here(), "output", "apep_0555", "v1", "code", "00_packages.R"))

## =========================================================================
## FIGURE 1: Raw price trends — Local rice vs Imported rice (motivating figure)
## =========================================================================

panel <- fread(file.path(data_dir, "panel.csv"))
rice_raw <- panel[commodity %in% c("Rice (local)", "Rice (imported)")]

## Monthly averages across markets
rice_trends <- rice_raw[, .(
  mean_price = mean(price, na.rm = TRUE),
  sd_price = sd(price, na.rm = TRUE),
  n = .N
), by = .(commodity, year, month)]
rice_trends[, date := as.Date(paste(year, month, "15", sep = "-"))]

fig1 <- ggplot(rice_trends, aes(x = date, y = mean_price, color = commodity)) +
  geom_line(linewidth = 0.9) +
  geom_ribbon(aes(ymin = mean_price - sd_price / sqrt(n),
                  ymax = mean_price + sd_price / sqrt(n),
                  fill = commodity), alpha = 0.15, color = NA) +
  geom_vline(xintercept = as.Date("2022-10-26"), linetype = "dashed", color = "grey40") +
  geom_vline(xintercept = as.Date("2023-01-31"), linetype = "solid", color = "red3", alpha = 0.7) +
  geom_vline(xintercept = as.Date("2023-03-03"), linetype = "dotted", color = "blue3", alpha = 0.7) +
  annotate("text", x = as.Date("2022-10-26"), y = Inf, label = "Announced",
           hjust = 1.1, vjust = 1.5, size = 3, color = "grey40") +
  annotate("text", x = as.Date("2023-01-31"), y = Inf, label = "Demonetized",
           hjust = -0.1, vjust = 1.5, size = 3, color = "red3") +
  annotate("text", x = as.Date("2023-03-03"), y = Inf, label = "Court reversal",
           hjust = -0.1, vjust = 3, size = 3, color = "blue3") +
  scale_color_manual(values = c("Rice (imported)" = "#2166AC", "Rice (local)" = "#B2182B")) +
  scale_fill_manual(values = c("Rice (imported)" = "#2166AC", "Rice (local)" = "#B2182B")) +
  labs(
    title = "Local vs. Imported Rice Prices Around the Naira Redesign",
    subtitle = "Monthly averages across WFP-monitored markets (NGN/kg)",
    x = NULL, y = "Price (NGN/kg)",
    color = NULL, fill = NULL
  ) +
  theme(legend.position = c(0.2, 0.85))

ggsave(file.path(fig_dir, "fig1_rice_price_trends.pdf"), fig1,
       width = 8, height = 5, device = cairo_pdf)
cat("Figure 1 saved.\n")

## =========================================================================
## FIGURE 2: Event study — Main specification (all commodities)
## =========================================================================

es_coefs <- fread(file.path(data_dir, "event_study_coefs.csv"))

fig2 <- ggplot(es_coefs, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "solid", color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red3", alpha = 0.7) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "#2166AC", alpha = 0.2) +
  geom_line(color = "#2166AC", linewidth = 0.7) +
  geom_point(color = "#2166AC", size = 1.5) +
  annotate("text", x = 0, y = max(es_coefs$ci_hi, na.rm = TRUE) * 0.9,
           label = "Cash crisis begins", hjust = -0.1, size = 3, color = "red3") +
  scale_x_continuous(breaks = seq(-24, 18, by = 6)) +
  labs(
    title = "Event Study: Cash-Mediation Price Premium",
    subtitle = "Coefficient on High CMI x Month (ref = Jan 2023)",
    x = "Months relative to February 2023",
    y = expression(hat(beta)[t])
  )

ggsave(file.path(fig_dir, "fig2_event_study_main.pdf"), fig2,
       width = 8, height = 5, device = cairo_pdf)
cat("Figure 2 saved.\n")

## =========================================================================
## FIGURE 3: Event study — Rice-only specification
## =========================================================================

es_rice <- fread(file.path(data_dir, "event_study_rice_coefs.csv"))

fig3 <- ggplot(es_rice, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "solid", color = "grey60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "red3", alpha = 0.7) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "#B2182B", alpha = 0.2) +
  geom_line(color = "#B2182B", linewidth = 0.7) +
  geom_point(color = "#B2182B", size = 1.5) +
  annotate("text", x = 0, y = max(es_rice$ci_hi, na.rm = TRUE) * 0.9,
           label = "Cash crisis begins", hjust = -0.1, size = 3, color = "red3") +
  scale_x_continuous(breaks = seq(-24, 18, by = 6)) +
  labs(
    title = "Event Study: Local vs. Imported Rice (Within-Market)",
    subtitle = "Coefficient on Local Rice x Month (ref = Jan 2023)",
    x = "Months relative to February 2023",
    y = expression(hat(beta)[t])
  )

ggsave(file.path(fig_dir, "fig3_event_study_rice.pdf"), fig3,
       width = 8, height = 5, device = cairo_pdf)
cat("Figure 3 saved.\n")

## =========================================================================
## FIGURE 4: Leave-one-state-out sensitivity
## =========================================================================

loo_state <- fread(file.path(data_dir, "loo_state.csv"))

## Get main estimate for reference
main_results <- fread(file.path(data_dir, "main_results.csv"))
main_est <- main_results[specification == "Acute crisis", estimate]

fig4 <- ggplot(loo_state, aes(x = reorder(dropped, estimate), y = estimate)) +
  geom_hline(yintercept = main_est, linetype = "dashed", color = "red3") +
  geom_hline(yintercept = 0, linetype = "solid", color = "grey60") +
  geom_pointrange(aes(ymin = estimate - 1.96 * se, ymax = estimate + 1.96 * se),
                  color = "#2166AC", size = 0.4) +
  coord_flip() +
  labs(
    title = "Leave-One-State-Out Sensitivity",
    subtitle = "Dashed red line = full-sample estimate",
    x = "Dropped state", y = expression(hat(beta))
  )

ggsave(file.path(fig_dir, "fig4_loo_state.pdf"), fig4,
       width = 7, height = 5, device = cairo_pdf)
cat("Figure 4 saved.\n")

## =========================================================================
## FIGURE 5: Randomization inference distribution
## =========================================================================

ri <- fread(file.path(data_dir, "ri_distribution.csv"))

fig5 <- ggplot(ri, aes(x = estimate)) +
  geom_histogram(bins = 50, fill = "grey70", color = "grey50", alpha = 0.7) +
  geom_vline(xintercept = ri$actual[1], color = "red3", linewidth = 1.2) +
  annotate("text", x = ri$actual[1], y = Inf,
           label = paste0("Actual estimate\np(RI) = ",
                          sprintf("%.3f", mean(abs(ri$estimate) >= abs(ri$actual[1])))),
           hjust = -0.15, vjust = 1.5, size = 3.5, color = "red3") +
  labs(
    title = "Randomization Inference: Permutation Distribution",
    subtitle = "500 permutations of crisis timing",
    x = expression(hat(beta)[permuted]),
    y = "Count"
  )

ggsave(file.path(fig_dir, "fig5_ri_distribution.pdf"), fig5,
       width = 7, height = 5, device = cairo_pdf)
cat("Figure 5 saved.\n")

## =========================================================================
## FIGURE 6: Price trends by CMI group (motivating overview)
## =========================================================================

## Normalize within each commodity to January 2023 = 0 (in log prices),
## then average across commodities within each CMI group.
## This avoids composition effects from commodities with different price levels.
cmi_by_comm <- panel[!is.na(cmi) & cmi %in% c("high", "low"), .(
  mean_log_price = mean(log_price, na.rm = TRUE),
  n = .N
), by = .(cmi, commodity, year, month)]

## Normalize each commodity to its own Jan 2023 value
cmi_by_comm[, base_log := mean_log_price[year == 2023 & month == 1], by = .(cmi, commodity)]
cmi_by_comm <- cmi_by_comm[!is.na(base_log)]
cmi_by_comm[, normalized := mean_log_price - base_log]

## Average across commodities within each CMI group
cmi_trends <- cmi_by_comm[, .(
  normalized = mean(normalized, na.rm = TRUE),
  se = sd(normalized, na.rm = TRUE) / sqrt(.N),
  n_commodities = .N
), by = .(cmi, year, month)]
cmi_trends[, date := as.Date(paste(year, month, "15", sep = "-"))]

fig6 <- ggplot(cmi_trends, aes(x = date, y = normalized, color = cmi)) +
  geom_ribbon(aes(ymin = normalized - 1.96 * se, ymax = normalized + 1.96 * se,
                  fill = cmi), alpha = 0.12, color = NA) +
  geom_line(linewidth = 0.9) +
  geom_hline(yintercept = 0, linetype = "solid", color = "grey60") +
  geom_vline(xintercept = as.Date("2022-10-26"), linetype = "dashed", color = "grey40") +
  geom_vline(xintercept = as.Date("2023-01-31"), linetype = "solid", color = "red3", alpha = 0.7) +
  annotate("text", x = as.Date("2022-10-26"), y = Inf, label = "Announced",
           hjust = 1.1, vjust = 1.5, size = 3, color = "grey40") +
  annotate("text", x = as.Date("2023-01-31"), y = Inf, label = "Demonetized",
           hjust = -0.1, vjust = 1.5, size = 3, color = "red3") +
  scale_color_manual(
    values = c("high" = "#B2182B", "low" = "#2166AC"),
    labels = c("high" = "Cash-mediated (local staples)", "low" = "Banking-mediated (imports)")
  ) +
  scale_fill_manual(
    values = c("high" = "#B2182B", "low" = "#2166AC"),
    labels = c("high" = "Cash-mediated (local staples)", "low" = "Banking-mediated (imports)")
  ) +
  labs(
    title = "Price Dynamics by Cash-Mediation Intensity",
    subtitle = "Within-commodity normalized log prices (Jan 2023 = 0)",
    x = NULL, y = "Mean change in log price from Jan 2023",
    color = NULL, fill = NULL
  ) +
  theme(legend.position = c(0.3, 0.15))

ggsave(file.path(fig_dir, "fig6_cmi_price_trends.pdf"), fig6,
       width = 8, height = 5, device = cairo_pdf)
cat("Figure 6 saved.\n")

## =========================================================================
## FIGURE 7: Leave-one-commodity-out sensitivity
## =========================================================================

loo_commodity <- fread(file.path(data_dir, "loo_commodity.csv"))

fig7 <- ggplot(loo_commodity, aes(x = reorder(dropped, estimate), y = estimate)) +
  geom_hline(yintercept = main_est, linetype = "dashed", color = "red3") +
  geom_hline(yintercept = 0, linetype = "solid", color = "grey60") +
  geom_pointrange(aes(ymin = estimate - 1.96 * se, ymax = estimate + 1.96 * se),
                  color = "#2166AC", size = 0.3) +
  coord_flip() +
  labs(
    title = "Leave-One-Commodity-Out Sensitivity",
    subtitle = "Dashed red line = full-sample estimate",
    x = "Dropped commodity", y = expression(hat(beta))
  ) +
  theme(axis.text.y = element_text(size = 7))

ggsave(file.path(fig_dir, "fig7_loo_commodity.pdf"), fig7,
       width = 7, height = 7, device = cairo_pdf)
cat("Figure 7 saved.\n")

cat("\n=== ALL FIGURES GENERATED ===\n")
