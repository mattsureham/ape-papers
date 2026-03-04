## ============================================================
## 05_figures.R — Generate all figures
## apep_0505: Council Tax Support Localization
## ============================================================

source("00_packages.R")

## ============================================================
## Load Data and Results
## ============================================================
panel <- readRDS(file.path(DATA_DIR, "analysis_panel_final.rds"))
results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
robustness <- readRDS(file.path(DATA_DIR, "robustness_results.rds"))
treatment <- readRDS(file.path(DATA_DIR, "treatment_2018.rds"))

## ============================================================
## Figure 1: Treatment Variable Distribution
## ============================================================
cat("Figure 1: Treatment distribution\n")

fig1 <- ggplot(treatment[!is.na(cts_wa_per_cap) & cts_wa_per_cap > 0],
               aes(x = cts_wa_per_cap)) +
  geom_histogram(bins = 40, fill = "#2171b5", alpha = 0.85, color = "white") +
  geom_vline(xintercept = median(treatment$cts_wa_per_cap, na.rm = TRUE),
             linetype = "dashed", color = "red", linewidth = 0.7) +
  annotate("text", x = median(treatment$cts_wa_per_cap, na.rm = TRUE) + 30,
           y = Inf, label = "Median", hjust = 0, vjust = 1.5, color = "red",
           size = 3.5) +
  labs(x = "CTS Working-Age Expenditure per Capita (£, 2017/18)",
       y = "Number of Local Authorities") +
  theme(plot.margin = margin(10, 15, 10, 10))

ggsave(file.path(FIG_DIR, "fig1_treatment_distribution.pdf"),
       fig1, width = 7, height = 4.5)

## ============================================================
## Figure 2: Event Study — JSA Claimant Rate
## ============================================================
cat("Figure 2: Event study JSA\n")

es_jsa_coefs <- coeftable(results$es_jsa)
es_jsa_df <- data.frame(
  event_time = as.integer(gsub(".*::([-0-9]+):.*", "\\1", rownames(es_jsa_coefs))),
  estimate = es_jsa_coefs[, 1],
  se = es_jsa_coefs[, 2]
)
## Add reference period
es_jsa_df <- rbind(es_jsa_df,
                   data.frame(event_time = -1, estimate = 0, se = 0))
es_jsa_df <- es_jsa_df[order(es_jsa_df$event_time), ]
es_jsa_df$ci_lo <- es_jsa_df$estimate - 1.96 * es_jsa_df$se
es_jsa_df$ci_hi <- es_jsa_df$estimate + 1.96 * es_jsa_df$se

fig2 <- ggplot(es_jsa_df, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "solid", color = "gray70") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "gray50") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "#2171b5", alpha = 0.2) +
  geom_line(color = "#2171b5", linewidth = 0.8) +
  geom_point(color = "#2171b5", size = 2) +
  annotate("text", x = -3, y = max(es_jsa_df$ci_hi) * 0.9,
           label = "Pre-reform", hjust = 0.5, size = 3, color = "gray40") +
  annotate("text", x = 3, y = max(es_jsa_df$ci_hi) * 0.9,
           label = "Post-reform", hjust = 0.5, size = 3, color = "gray40") +
  scale_x_continuous(breaks = -5:6) +
  labs(x = "Years Relative to CTS Reform (2013)",
       y = expression("Cut Intensity" %*% "Year Effect on JSA Rate")) +
  theme(plot.margin = margin(10, 15, 10, 10))

ggsave(file.path(FIG_DIR, "fig2_event_study_jsa.pdf"),
       fig2, width = 8, height = 5)

## ============================================================
## Figure 3: Event Study — Property Prices
## ============================================================
cat("Figure 3: Event study property prices\n")

es_price_coefs <- coeftable(results$es_price)
es_price_df <- data.frame(
  event_time = as.integer(gsub(".*::([-0-9]+):.*", "\\1", rownames(es_price_coefs))),
  estimate = es_price_coefs[, 1],
  se = es_price_coefs[, 2]
)
es_price_df <- rbind(es_price_df,
                     data.frame(event_time = -1, estimate = 0, se = 0))
es_price_df <- es_price_df[order(es_price_df$event_time), ]
es_price_df$ci_lo <- es_price_df$estimate - 1.96 * es_price_df$se
es_price_df$ci_hi <- es_price_df$estimate + 1.96 * es_price_df$se

fig3 <- ggplot(es_price_df, aes(x = event_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "solid", color = "gray70") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "gray50") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "#e6550d", alpha = 0.2) +
  geom_line(color = "#e6550d", linewidth = 0.8) +
  geom_point(color = "#e6550d", size = 2) +
  annotate("text", x = -3, y = max(es_price_df$ci_hi) * 0.9,
           label = "Pre-reform", hjust = 0.5, size = 3, color = "gray40") +
  annotate("text", x = 3, y = max(es_price_df$ci_hi) * 0.9,
           label = "Post-reform", hjust = 0.5, size = 3, color = "gray40") +
  scale_x_continuous(breaks = -5:6) +
  labs(x = "Years Relative to CTS Reform (2013)",
       y = expression("Cut Intensity" %*% "Year Effect on Log Price")) +
  theme(plot.margin = margin(10, 15, 10, 10))

ggsave(file.path(FIG_DIR, "fig3_event_study_price.pdf"),
       fig3, width = 8, height = 5)

## ============================================================
## Figure 4: Dose-Response (Treatment Quartiles × Outcomes)
## ============================================================
cat("Figure 4: Dose-response\n")

## Mean outcomes by quartile and year
dose_data <- panel[, .(
  mean_jsa = mean(jsa_rate, na.rm = TRUE),
  mean_log_price = mean(mean_log_price, na.rm = TRUE)
), by = .(treat_quartile, year)]

## Normalize to 2012 (last pre-reform year)
base_2012 <- dose_data[year == 2012]
dose_data <- merge(dose_data, base_2012[, .(treat_quartile,
                                             jsa_2012 = mean_jsa,
                                             price_2012 = mean_log_price)],
                   by = "treat_quartile")
dose_data[, jsa_normalized := mean_jsa - jsa_2012]
dose_data[, price_normalized := mean_log_price - price_2012]

## JSA panel
fig4a <- ggplot(dose_data, aes(x = year, y = jsa_normalized,
                                color = treat_quartile, group = treat_quartile)) +
  geom_vline(xintercept = 2012.5, linetype = "dashed", color = "gray50") +
  geom_line(linewidth = 0.7) +
  geom_point(size = 1.5) +
  scale_color_manual(
    values = c("Q1_least_generous" = "#d73027",
               "Q2" = "#fc8d59",
               "Q3" = "#91bfdb",
               "Q4_most_generous" = "#4575b4"),
    labels = c("Q1 (Least Generous)", "Q2", "Q3", "Q4 (Most Generous)")
  ) +
  scale_x_continuous(breaks = 2008:2019, limits = c(2008, 2019)) +
  labs(x = NULL, y = "JSA Rate\n(Change from 2012)",
       color = "CTS Generosity\nQuartile") +
  theme(legend.position = "bottom",
        legend.title = element_text(size = 9),
        plot.margin = margin(10, 15, 5, 10))

## Price panel
fig4b <- ggplot(dose_data[!is.na(price_normalized)],
                aes(x = year, y = price_normalized,
                    color = treat_quartile, group = treat_quartile)) +
  geom_vline(xintercept = 2012.5, linetype = "dashed", color = "gray50") +
  geom_line(linewidth = 0.7) +
  geom_point(size = 1.5) +
  scale_color_manual(
    values = c("Q1_least_generous" = "#d73027",
               "Q2" = "#fc8d59",
               "Q3" = "#91bfdb",
               "Q4_most_generous" = "#4575b4"),
    labels = c("Q1 (Least Generous)", "Q2", "Q3", "Q4 (Most Generous)")
  ) +
  scale_x_continuous(breaks = 2008:2019, limits = c(2008, 2019)) +
  labs(x = NULL, y = "Log Price\n(Change from 2012)",
       color = "CTS Generosity\nQuartile") +
  theme(legend.position = "bottom",
        legend.title = element_text(size = 9),
        plot.margin = margin(10, 15, 5, 10))

fig4 <- fig4a / fig4b + plot_layout(guides = "collect") &
  theme(legend.position = "bottom")

ggsave(file.path(FIG_DIR, "fig4_dose_response.pdf"),
       fig4, width = 8, height = 8)

## ============================================================
## Figure 5: HonestDiD Sensitivity Plot
## ============================================================
cat("Figure 5: HonestDiD sensitivity\n")

honest_jsa <- tryCatch(readRDS(file.path(DATA_DIR, "honestdid_jsa.rds")), error = function(e) NULL)
honest_price <- tryCatch(readRDS(file.path(DATA_DIR, "honestdid_price.rds")), error = function(e) NULL)

if (!is.null(honest_jsa) && !is.null(honest_price)) {
  hd_jsa <- as.data.frame(honest_jsa)
  hd_jsa$outcome <- "JSA Claimant Rate"
  hd_price <- as.data.frame(honest_price)
  hd_price$outcome <- "Log Property Price"

  hd_both <- rbind(hd_jsa, hd_price)

  fig5 <- ggplot(hd_both, aes(x = Mbar, y = (lb + ub) / 2)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
    geom_ribbon(aes(ymin = lb, ymax = ub), alpha = 0.3, fill = "#2171b5") +
    geom_line(color = "#2171b5", linewidth = 0.8) +
    geom_point(color = "#2171b5", size = 2) +
    facet_wrap(~outcome, scales = "free_y", ncol = 2) +
    labs(x = expression(bar(M) ~ "(Relative Magnitude of Violations)"),
         y = "95% Confidence Interval") +
    theme(strip.text = element_text(face = "bold"),
          plot.margin = margin(10, 15, 10, 10))

  ggsave(file.path(FIG_DIR, "fig5_honestdid.pdf"),
         fig5, width = 9, height = 4.5)
}

## ============================================================
## Figure 6: Map of Treatment Intensity (Optional)
## ============================================================
## Skip spatial figure if sf boundary data not available
## This would require downloading LA boundary shapefiles

## ============================================================
## Figure 7: Horse Race Coefficient Comparison
## ============================================================
cat("Figure 7: Horse race\n")

## Collect robustness coefficients for property prices
rob_coefs <- data.frame(
  model = c("Baseline", "Restricted\nPre-Period", "Symmetric\nWindow",
            "LA-Specific\nTrends", "Excl.\nLondon",
            "Horse Race:\nWA CTS", "Horse Race:\nPensioner CTS"),
  estimate = c(
    coef(results$m2_price),
    coef(robustness$r1_price),
    coef(robustness$r2_price),
    coef(robustness$r3_price),
    coef(robustness$r5_price),
    coef(robustness$r4_horse_price)[1],
    coef(robustness$r4_horse_price)[2]
  ),
  se = c(
    se(results$m2_price),
    se(robustness$r1_price),
    se(robustness$r2_price),
    se(robustness$r3_price),
    se(robustness$r5_price),
    se(robustness$r4_horse_price)[1],
    se(robustness$r4_horse_price)[2]
  )
)

rob_coefs$ci_lo <- rob_coefs$estimate - 1.96 * rob_coefs$se
rob_coefs$ci_hi <- rob_coefs$estimate + 1.96 * rob_coefs$se
rob_coefs$model <- factor(rob_coefs$model, levels = rev(rob_coefs$model))

fig7 <- ggplot(rob_coefs, aes(x = estimate, y = model)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  geom_errorbarh(aes(xmin = ci_lo, xmax = ci_hi), height = 0.2,
                 color = "#2171b5") +
  geom_point(color = "#2171b5", size = 2.5) +
  labs(x = "Coefficient on Cut Intensity × Post\n(Log Property Price)",
       y = NULL) +
  theme(plot.margin = margin(10, 15, 10, 10))

ggsave(file.path(FIG_DIR, "fig7_robustness_prices.pdf"),
       fig7, width = 7, height = 5)

## ============================================================
## Done
## ============================================================
cat("\nAll figures saved to:", FIG_DIR, "\n")
cat("Files:", paste(list.files(FIG_DIR), collapse = ", "), "\n")
