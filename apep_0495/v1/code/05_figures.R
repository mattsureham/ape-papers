## 05_figures.R — Publication-quality figures
## apep_0495: Private School VAT and State School Housing Premium

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

cat("=== GENERATING FIGURES ===\n")

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, date_transfer := as.Date(date_transfer)]
panel[, year_month_date := as.Date(paste0(year_month, "-01"))]
la_treatment <- fread(file.path(data_dir, "la_treatment_intensity.csv"))

load(file.path(data_dir, "main_models.RData"))

## Color palette
col_treat <- "#2171B5"    # Blue for treated
col_control <- "#CB181D"  # Red for control
col_grey <- "grey60"
col_announce <- "#7F2704"  # Dark orange for policy dates

## =========================================================================
## Figure 1: Treatment Intensity Map (LA-level private school share)
## =========================================================================
cat("--- Figure 1: Treatment Intensity Distribution ---\n")

fig1 <- ggplot(la_treatment, aes(x = private_share * 100)) +
  geom_histogram(bins = 40, fill = col_treat, color = "white", alpha = 0.8) +
  geom_vline(xintercept = median(la_treatment$private_share, na.rm = TRUE) * 100,
             linetype = "dashed", color = col_announce, linewidth = 0.8) +
  annotate("text", x = median(la_treatment$private_share, na.rm = TRUE) * 100 + 1,
           y = Inf, vjust = 2, hjust = 0, label = "Median", color = col_announce, size = 3.5) +
  labs(x = "Private School Pupil Share (%)",
       y = "Number of Local Authorities",
       title = "Distribution of Treatment Intensity Across Local Authorities",
       subtitle = "Private school pupils as share of total pupils, by LA") +
  scale_x_continuous(breaks = seq(0, 30, 5)) +
  theme_apep
ggsave(file.path(fig_dir, "fig1_treatment_distribution.pdf"), fig1,
       width = 7, height = 5, device = pdf)
cat("  Saved fig1_treatment_distribution.pdf\n")

## =========================================================================
## Figure 2: Raw Trends — Mean log price by treatment group × school quality
## =========================================================================
cat("--- Figure 2: Raw Price Trends ---\n")

trends <- panel[, .(
  mean_log_price = mean(log_price, na.rm = TRUE),
  n = .N
), by = .(year_month, year_month_date, high_private, near_good_school)]

## Create group labels
trends[, group := fcase(
  high_private == 1 & near_good_school == 1, "High Private, Near Good School",
  high_private == 1 & near_good_school == 0, "High Private, Not Near Good School",
  high_private == 0 & near_good_school == 1, "Low Private, Near Good School",
  high_private == 0 & near_good_school == 0, "Low Private, Not Near Good School"
)]

fig2 <- ggplot(trends[!is.na(group)],
               aes(x = year_month_date, y = mean_log_price, color = group)) +
  geom_line(linewidth = 0.6) +
  geom_vline(xintercept = as.Date("2024-07-04"), linetype = "dashed",
             color = col_announce, alpha = 0.7) +
  geom_vline(xintercept = as.Date("2025-01-01"), linetype = "solid",
             color = col_announce, alpha = 0.7) +
  annotate("text", x = as.Date("2024-07-04"), y = Inf, vjust = 2,
           label = "Election", color = col_announce, size = 2.5, hjust = 1.1) +
  annotate("text", x = as.Date("2025-01-01"), y = Inf, vjust = 2,
           label = "VAT Start", color = col_announce, size = 2.5, hjust = -0.1) +
  scale_color_manual(values = c(
    "High Private, Near Good School" = col_treat,
    "High Private, Not Near Good School" = "#6BAED6",
    "Low Private, Near Good School" = col_control,
    "Low Private, Not Near Good School" = "#FC9272"
  )) +
  labs(x = "", y = "Mean Log Transaction Price",
       title = "House Price Trends by Treatment Group and School Quality",
       subtitle = "Monthly means, 2015\u20132026",
       color = "") +
  theme_apep +
  theme(legend.position = "bottom",
        legend.text = element_text(size = 8))
ggsave(file.path(fig_dir, "fig2_raw_trends.pdf"), fig2,
       width = 8, height = 6, device = pdf)
cat("  Saved fig2_raw_trends.pdf\n")

## =========================================================================
## Figure 3: DDD Event Study
## =========================================================================
cat("--- Figure 3: DDD Event Study ---\n")

es_coefs <- fread(file.path(data_dir, "event_study_ddd_coefs.csv"))

## Add reference period
ref_row <- data.table(term = "ref", estimate = 0, se = 0, tstat = 0,
                      pvalue = 1, rel_month = -1)
es_coefs <- rbind(es_coefs, ref_row, fill = TRUE)
es_coefs <- es_coefs[order(rel_month)]
es_coefs[, ci_lo := estimate - 1.96 * se]
es_coefs[, ci_hi := estimate + 1.96 * se]

fig3 <- ggplot(es_coefs, aes(x = rel_month, y = estimate)) +
  geom_hline(yintercept = 0, color = col_grey, linewidth = 0.5) +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = col_announce) +
  ## Shaded anticipation period (election to implementation)
  annotate("rect", xmin = -6, xmax = -0.5, ymin = -Inf, ymax = Inf,
           fill = col_announce, alpha = 0.05) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = col_treat, alpha = 0.15) +
  geom_point(size = 1.8, color = col_treat) +
  geom_line(color = col_treat, linewidth = 0.4) +
  annotate("text", x = -3, y = Inf, vjust = 2, label = "Anticipation",
           color = col_announce, size = 3, fontface = "italic") +
  annotate("text", x = 7, y = Inf, vjust = 2, label = "Post-VAT",
           color = col_treat, size = 3, fontface = "italic") +
  labs(x = "Months Relative to VAT Implementation (January 2025)",
       y = "DDD Coefficient (log price)",
       title = "Event Study: State School Quality Premium in High-Private-School Areas",
       subtitle = "Triple-difference: High Private Share \u00d7 Near Good School \u00d7 Month") +
  scale_x_continuous(breaks = seq(-36, 14, 6)) +
  theme_apep
ggsave(file.path(fig_dir, "fig3_event_study_ddd.pdf"), fig3,
       width = 8, height = 5.5, device = pdf)
cat("  Saved fig3_event_study_ddd.pdf\n")

## =========================================================================
## Figure 4: Distance Cutoff Sensitivity
## =========================================================================
cat("--- Figure 4: Distance Cutoff Sensitivity ---\n")

cutoff_results <- fread(file.path(data_dir, "distance_cutoff_sensitivity.csv"))
cutoff_results[, ci_lo := coef - 1.96 * se]
cutoff_results[, ci_hi := coef + 1.96 * se]

fig4 <- ggplot(cutoff_results, aes(x = cutoff_km, y = coef)) +
  geom_hline(yintercept = 0, color = col_grey) +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi), color = col_treat, size = 0.6) +
  labs(x = "Distance to Nearest Good School Cutoff (km)",
       y = "DDD Coefficient (log price)",
       title = "Sensitivity to School Proximity Definition",
       subtitle = "DDD coefficient at varying distance cutoffs") +
  scale_x_continuous(breaks = cutoff_results$cutoff_km) +
  theme_apep
ggsave(file.path(fig_dir, "fig4_distance_sensitivity.pdf"), fig4,
       width = 6.5, height = 5, device = pdf)
cat("  Saved fig4_distance_sensitivity.pdf\n")

## =========================================================================
## Figure 5: Leave-One-Region-Out
## =========================================================================
cat("--- Figure 5: Leave-One-Region-Out ---\n")

loo <- fread(file.path(data_dir, "leave_one_region_out.csv"))

if (nrow(loo) > 0 && "coef" %in% names(loo)) {
  loo[, ci_lo := coef - 1.96 * se]
  loo[, ci_hi := coef + 1.96 * se]

  load(file.path(data_dir, "main_models.RData"))
  ## Find DDD coef name in model m2
  m2_cn <- names(coef(m2))
  m2_ddd <- m2_cn[grepl("high_private", m2_cn) & grepl("near_good", m2_cn) & grepl("post_vat", m2_cn)]
  baseline_coef <- if (length(m2_ddd) > 0) coef(m2)[m2_ddd[1]] else 0

  fig5 <- ggplot(loo, aes(x = reorder(excluded_region, coef), y = coef)) +
    geom_hline(yintercept = 0, color = col_grey) +
    geom_hline(yintercept = baseline_coef, color = col_treat, linetype = "dashed") +
    geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi), color = col_treat, size = 0.5) +
    labs(x = "Excluded Region",
         y = "DDD Coefficient (log price)",
         title = "Leave-One-Region-Out Sensitivity",
         subtitle = "Dashed line shows full-sample estimate") +
    coord_flip() +
    theme_apep
  ggsave(file.path(fig_dir, "fig5_leave_one_out.pdf"), fig5,
         width = 7, height = 5, device = pdf)
  cat("  Saved fig5_leave_one_out.pdf\n")
} else {
  cat("  Skipping LOO figure (no data)\n")
}

## =========================================================================
## Figure 6: Within-LA Price Dispersion
## =========================================================================
cat("--- Figure 6: Price Dispersion ---\n")

la_month <- fread(file.path(data_dir, "la_month_panel.csv"))
la_month[, year_month_date := as.Date(paste0(year_month, "-01"))]

## Aggregate by treatment group and month
disp_trends <- la_month[n_transactions >= 20, .(
  mean_p90_p10 = weighted.mean(p90_p10_ratio, n_transactions, na.rm = TRUE)
), by = .(year_month_date, high_private)]
disp_trends[, group := ifelse(high_private == 1, "High Private", "Low Private")]

fig6 <- ggplot(disp_trends[!is.na(group)],
               aes(x = year_month_date, y = mean_p90_p10, color = group)) +
  geom_line(linewidth = 0.6) +
  geom_vline(xintercept = as.Date("2025-01-01"), linetype = "dashed",
             color = col_announce) +
  scale_color_manual(values = c("High Private" = col_treat, "Low Private" = col_control)) +
  labs(x = "", y = "P90/P10 Price Ratio",
       title = "Within-LA Price Dispersion by Treatment Group",
       subtitle = "Higher values indicate greater within-LA inequality",
       color = "") +
  theme_apep
ggsave(file.path(fig_dir, "fig6_price_dispersion.pdf"), fig6,
       width = 7, height = 5, device = pdf)
cat("  Saved fig6_price_dispersion.pdf\n")

## =========================================================================
## Figure 7: Announcement Decomposition
## =========================================================================
cat("--- Figure 7: Announcement Decomposition ---\n")

## Extract multi-period coefficients from m4
if (!exists("m4")) load(file.path(data_dir, "main_models.RData"))
m4_coefs <- as.data.table(coeftable(m4), keep.rownames = "term")
setnames(m4_coefs, c("term", "estimate", "se", "tstat", "pvalue"))

## Get the three DDD interaction coefficients (terms contain high_private + near_good + post)
announce_terms <- m4_coefs[grepl("high_private", term) & grepl("near_good", term) & grepl("post", term)]
announce_terms[, period := fcase(
  grepl("post_announce", term), "Election\n(Jul 2024)",
  grepl("post_budget", term), "Budget\n(Oct 2024)",
  grepl("post_vat", term), "VAT Start\n(Jan 2025)"
)]
announce_terms[, ci_lo := estimate - 1.96 * se]
announce_terms[, ci_hi := estimate + 1.96 * se]
announce_terms[, period := factor(period,
  levels = c("Election\n(Jul 2024)", "Budget\n(Oct 2024)", "VAT Start\n(Jan 2025)"))]

fig7 <- ggplot(announce_terms[!is.na(period)],
               aes(x = period, y = estimate)) +
  geom_hline(yintercept = 0, color = col_grey) +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi), color = col_treat, size = 0.7) +
  labs(x = "Policy Event",
       y = "DDD Coefficient (log price)",
       title = "Decomposing the Policy Effect: Announcement vs. Implementation",
       subtitle = "High Private \u00d7 Near Good School \u00d7 Post-Event") +
  theme_apep
ggsave(file.path(fig_dir, "fig7_announcement_decomp.pdf"), fig7,
       width = 6, height = 5, device = pdf)
cat("  Saved fig7_announcement_decomp.pdf\n")

cat("\n=== ALL FIGURES GENERATED ===\n")
