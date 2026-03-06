## 05_figures.R — All figures for the paper
## apep_0534 v2: Green Patent Examiner Leniency IV (Application-Level)

source("00_packages.R")

dt <- fread(file.path(DATA_DIR, "analysis_dataset.csv"))
main_res <- fread(file.path(DATA_DIR, "main_results.csv"))
hetero_dom <- fread(file.path(DATA_DIR, "heterogeneity_domain.csv"))
hetero_era <- fread(file.path(DATA_DIR, "heterogeneity_era.csv"))
fs_res <- fread(file.path(DATA_DIR, "first_stage_results.csv"))

dt[, grant_rate_std := (loo_grant_rate_i - mean(loo_grant_rate_i, na.rm = TRUE)) /
     sd(loo_grant_rate_i, na.rm = TRUE)]

# ── Figure 1: Y02 Patent Filing Trends ──────────────────────────────────
cat("Figure 1: Y02 trends\n")
fig1_data <- dt[, .(N_apps = .N, N_grants = sum(granted)), by = .(filing_year, y02_domain)]
fig1_total <- dt[, .(N_apps = .N, N_grants = sum(granted), Grant_Rate = mean(granted)), by = filing_year]

p1a <- ggplot(fig1_total, aes(filing_year, N_apps)) +
  geom_line(linewidth = 0.8, color = "#2c7bb6") +
  geom_point(size = 1.5, color = "#2c7bb6") +
  scale_y_continuous(labels = comma) +
  labs(x = "Filing Year", y = "Y02 Applications",
       title = "A. Total Green Patent Applications") +
  theme(plot.title = element_text(size = 10))

p1b <- ggplot(fig1_data, aes(filing_year, N_apps, fill = y02_domain)) +
  geom_area(alpha = 0.7) +
  scale_fill_brewer(palette = "Set2", name = "Domain") +
  scale_y_continuous(labels = comma) +
  labs(x = "Filing Year", y = "Y02 Applications",
       title = "B. By Technology Domain") +
  theme(plot.title = element_text(size = 10),
        legend.position = "right", legend.text = element_text(size = 7))

fig1 <- p1a + p1b + plot_layout(widths = c(1, 1.3))
ggsave(file.path(FIG_DIR, "fig1_y02_trends.pdf"), fig1, width = 10, height = 4)
cat("  Figure 1 saved.\n")

# ── Figure 2: Examiner Grant Rate Distribution ──────────────────────────
cat("Figure 2: Grant rate distribution\n")
p2 <- ggplot(dt, aes(loo_grant_rate_i)) +
  geom_histogram(bins = 60, fill = "#2c7bb6", alpha = 0.7, color = "white") +
  geom_vline(xintercept = mean(dt$loo_grant_rate_i, na.rm = TRUE),
             linetype = "dashed", color = "red", linewidth = 0.6) +
  labs(x = "Leave-One-Out Examiner Grant Rate",
       y = "Number of Applications",
       title = "Distribution of Examiner Grant Rate (Within Art-Unit x Filing-Year)") +
  annotate("text", x = mean(dt$loo_grant_rate_i, na.rm = TRUE) + 0.03,
           y = Inf, vjust = 2, label = "Mean", color = "red", size = 3)

ggsave(file.path(FIG_DIR, "fig2_grant_rate_dist.pdf"), p2, width = 7, height = 4.5)
cat("  Figure 2 saved.\n")

# ── Figure 3: First Stage — Binscatter ──────────────────────────────────
cat("Figure 3: First stage binscatter\n")

# Residualize: partial out AU×FY fixed effects
dt[, granted_resid := resid(feols(granted ~ 1 | au_fy, data = dt))]
dt[, rate_resid := resid(feols(loo_grant_rate_i ~ 1 | au_fy, data = dt))]

# Create 20 bins of residualized grant rate
dt[, rate_bin := cut(rate_resid,
                      breaks = quantile(rate_resid, probs = seq(0, 1, 0.05), na.rm = TRUE),
                      include.lowest = TRUE, labels = FALSE)]
bin_means <- dt[!is.na(rate_bin), .(mean_granted = mean(granted_resid),
                                      mean_rate = mean(rate_resid),
                                      n = .N), by = rate_bin]

p3 <- ggplot(bin_means, aes(mean_rate, mean_granted)) +
  geom_point(size = 2.5, color = "#2c7bb6") +
  geom_smooth(method = "lm", se = TRUE, color = "#d7191c", linewidth = 0.7, alpha = 0.15) +
  labs(x = "Examiner Grant Rate (residualized, art-unit x year FE)",
       y = "Application Granted (residualized)",
       title = "First Stage: Examiner Grant Rate Predicts Grant Probability") +
  annotate("text", x = min(bin_means$mean_rate) * 0.5,
           y = max(bin_means$mean_granted) * 0.9,
           label = sprintf("F = %.0f", fs_res[spec == "baseline"]$f_stat),
           size = 4, fontface = "bold")

ggsave(file.path(FIG_DIR, "fig3_first_stage.pdf"), p3, width = 7, height = 5)
cat("  Figure 3 saved.\n")

# ── Figure 4: Balance Test ──────────────────────────────────────────────
cat("Figure 4: Balance test\n")
balance <- fread(file.path(DATA_DIR, "balance_test.csv"))
balance[, variable := gsub("log_", "", variable)]
balance[, ci_lo := coef - 1.96 * se]
balance[, ci_hi := coef + 1.96 * se]

p4 <- ggplot(balance, aes(x = variable, y = coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  color = "#2c7bb6", size = 0.8) +
  coord_flip() +
  labs(x = "", y = "Coefficient on Examiner Grant Rate (1 SD)",
       title = "Balance Test: Application Characteristics on Examiner Grant Rate")

ggsave(file.path(FIG_DIR, "fig4_balance.pdf"), p4, width = 7, height = 3.5)
cat("  Figure 4 saved.\n")

# ── Figure 5: Main Results — Coefficient Plot ───────────────────────────
cat("Figure 5: Main results\n")
ctrl <- main_res[spec == "baseline"]
ctrl[, outcome_label := fcase(
  outcome == "followon_3yr", "3-Year Follow-on",
  outcome == "followon_5yr", "5-Year Follow-on",
  outcome == "followon_10yr", "10-Year Follow-on",
  outcome == "fwd_citations", "Forward Citations",
  default = outcome
)]
ctrl[, ci_lo := coef - 1.96 * se]
ctrl[, ci_hi := coef + 1.96 * se]
ctrl[, is_citation := grepl("Citation", outcome_label)]

p5 <- ggplot(ctrl, aes(x = outcome_label, y = coef, color = is_citation)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi), size = 0.8) +
  scale_color_manual(values = c("FALSE" = "#2c7bb6", "TRUE" = "#d7191c"), guide = "none") +
  coord_flip() +
  labs(x = "", y = "Effect of 1 SD Increase in Examiner Grant Rate\n(log outcome)",
       title = "Effect of Examiner Grant Rate on Innovation Outcomes")

ggsave(file.path(FIG_DIR, "fig5_main_results.pdf"), p5, width = 7, height = 4)
cat("  Figure 5 saved.\n")

# ── Figure 6: Heterogeneity by Technology Domain ────────────────────────
cat("Figure 6: Heterogeneity by domain\n")
hetero_dom[, ci_lo := coef - 1.96 * se]
hetero_dom[, ci_hi := coef + 1.96 * se]

p6 <- ggplot(hetero_dom, aes(x = reorder(domain, coef), y = coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  color = "#d7191c", size = 0.7) +
  coord_flip() +
  labs(x = "", y = "Effect of 1 SD Increase in Examiner Grant Rate\n(log forward citations)",
       title = "Heterogeneity by Y02 Technology Domain: Forward Citations")

ggsave(file.path(FIG_DIR, "fig6_hetero_domain.pdf"), p6, width = 7, height = 4)
cat("  Figure 6 saved.\n")

# ── Figure 7: Permutation Distribution ──────────────────────────────────
cat("Figure 7: Permutation inference\n")
perm_file <- file.path(DATA_DIR, "permutation_dist.csv")
if (file.exists(perm_file)) {
  perm_dist <- fread(perm_file)
  perm_res <- fread(file.path(DATA_DIR, "permutation_results.csv"))

  p7 <- ggplot(perm_dist, aes(perm_coef)) +
    geom_histogram(bins = 40, fill = "gray70", alpha = 0.8, color = "white") +
    geom_vline(xintercept = perm_res$real_coef, color = "#d7191c",
               linewidth = 0.8, linetype = "solid") +
    labs(x = "Coefficient on Examiner Grant Rate (permuted)",
         y = "Count",
         title = "Permutation Inference: Follow-on 5yr Patenting") +
    annotate("text", x = perm_res$real_coef, y = Inf, vjust = 2,
             label = sprintf("Observed\n(p = %.3f)", perm_res$perm_p),
             color = "#d7191c", size = 3.5, fontface = "bold")

  ggsave(file.path(FIG_DIR, "fig7_permutation.pdf"), p7, width = 7, height = 4.5)
  cat("  Figure 7 saved.\n")
} else {
  cat("  Permutation data not available — skipping.\n")
}

# ── Figure 8: Temporal Evolution ─────────────────────────────────────────
cat("Figure 8: Temporal evolution\n")
hetero_era[, ci_lo := coef - 1.96 * se]
hetero_era[, ci_hi := coef + 1.96 * se]
hetero_era[, era_mid := fcase(
  era == "2001-2004", 2002.5,
  era == "2005-2008", 2006.5,
  era == "2009-2012", 2010.5,
  default = NA_real_
)]

p8 <- ggplot(hetero_era[!is.na(era_mid)], aes(era_mid, coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#2c7bb6") +
  geom_point(size = 3, color = "#2c7bb6") +
  geom_line(linewidth = 0.6, color = "#2c7bb6") +
  labs(x = "Filing Period (Midpoint)", y = "Effect of Examiner Grant Rate",
       title = "Effect of Examiner Grant Rate Over Time")

ggsave(file.path(FIG_DIR, "fig8_temporal.pdf"), p8, width = 7, height = 4.5)
cat("  Figure 8 saved.\n")

cat("\nAll figures complete.\n")
