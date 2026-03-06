## 05_figures.R — All figures for the paper
## apep_0534: Green Patent Examiner Leniency IV

source("00_packages.R")

dt <- fread(file.path(DATA_DIR, "analysis_dataset.csv"))
main_res <- fread(file.path(DATA_DIR, "main_results.csv"))
hetero_dom <- fread(file.path(DATA_DIR, "heterogeneity_domain.csv"))
hetero_era <- fread(file.path(DATA_DIR, "heterogeneity_era.csv"))
mono <- fread(file.path(DATA_DIR, "monotonicity.csv"))

# ── Figure 1: Y02 Patent Filing Trends ──────────────────────────────────
fig1_data <- dt[, .N, by = .(filing_year, y02_domain)]
fig1_total <- dt[, .(N = .N), by = filing_year]

p1a <- ggplot(fig1_total, aes(filing_year, N)) +
  geom_line(linewidth = 0.8, color = "#2c7bb6") +
  geom_point(size = 1.5, color = "#2c7bb6") +
  scale_y_continuous(labels = comma) +
  labs(x = "Filing Year", y = "Y02 Patent Applications",
       title = "A. Total Green Patent Filings") +
  theme(plot.title = element_text(size = 10))

p1b <- ggplot(fig1_data, aes(filing_year, N, fill = y02_domain)) +
  geom_area(alpha = 0.7) +
  scale_fill_brewer(palette = "Set2", name = "Domain") +
  scale_y_continuous(labels = comma) +
  labs(x = "Filing Year", y = "Y02 Patent Applications",
       title = "B. By Technology Domain") +
  theme(plot.title = element_text(size = 10),
        legend.position = "right", legend.text = element_text(size = 7))

fig1 <- p1a + p1b + plot_layout(widths = c(1, 1.3))
ggsave(file.path(FIG_DIR, "fig1_y02_trends.pdf"), fig1, width = 10, height = 4)
cat("Figure 1 saved.\n")

# ── Figure 2: Examiner Leniency Distribution ───────────────────────────
p2 <- ggplot(dt, aes(loo_leniency)) +
  geom_histogram(bins = 50, fill = "#2c7bb6", alpha = 0.7, color = "white") +
  geom_vline(xintercept = mean(dt$loo_leniency, na.rm = TRUE),
             linetype = "dashed", color = "red", linewidth = 0.6) +
  labs(x = "Leave-One-Out Examiner Leniency",
       y = "Number of Y02 Patents",
       title = "Distribution of Examiner Leniency (Within Art-Unit × Year)") +
  annotate("text", x = mean(dt$loo_leniency, na.rm = TRUE) + 0.02,
           y = Inf, vjust = 2, label = "Mean", color = "red", size = 3)

ggsave(file.path(FIG_DIR, "fig2_leniency_dist.pdf"), p2, width = 7, height = 4.5)
cat("Figure 2 saved.\n")

# ── Figure 3: Balance Test ──────────────────────────────────────────────
balance <- fread(file.path(DATA_DIR, "balance_test.csv"))
balance[, variable := gsub("log_", "", variable)]
balance[, ci_lo := coef - 1.96 * se]
balance[, ci_hi := coef + 1.96 * se]

p3 <- ggplot(balance, aes(x = variable, y = coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  color = "#2c7bb6", size = 0.8) +
  coord_flip() +
  labs(x = "", y = "Coefficient on Examiner Leniency (1 SD)",
       title = "Balance Test: Application Characteristics on Examiner Leniency")

ggsave(file.path(FIG_DIR, "fig3_balance.pdf"), p3, width = 7, height = 3.5)
cat("Figure 3 saved.\n")

# ── Figure 4: Monotonicity — Leniency quintiles vs outcomes ────────────
mono[, quintile_num := as.numeric(gsub("Q", "", leniency_quintile))]

p4 <- ggplot(mono, aes(quintile_num, mean_followon)) +
  geom_point(size = 3, color = "#2c7bb6") +
  geom_line(linewidth = 0.6, color = "#2c7bb6") +
  scale_x_continuous(breaks = 1:5, labels = paste0("Q", 1:5)) +
  labs(x = "Examiner Leniency Quintile\n(Q1 = Strictest, Q5 = Most Lenient)",
       y = "Mean Follow-on Y02 Patents (5-Year)",
       title = "Follow-on Innovation by Examiner Leniency Quintile")

ggsave(file.path(FIG_DIR, "fig4_monotonicity.pdf"), p4, width = 7, height = 4.5)
cat("Figure 4 saved.\n")

# ── Figure 5: Main Results — Coefficient Plot ───────────────────────────
# Plot the controlled specification across all outcomes
ctrl <- main_res[spec == "controlled" & !grepl("fwd_citations|n_citing", outcome)]
ctrl[, outcome_label := fcase(
  outcome == "followon_3yr", "3-Year Follow-on",
  outcome == "followon_5yr", "5-Year Follow-on",
  outcome == "followon_10yr", "10-Year Follow-on",
  default = outcome
)]
ctrl[, ci_lo := coef - 1.96 * se]
ctrl[, ci_hi := coef + 1.96 * se]

p5 <- ggplot(ctrl, aes(x = outcome_label, y = coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  color = "#d7191c", size = 0.8) +
  coord_flip() +
  labs(x = "", y = "Effect of 1 SD Increase in Examiner Leniency\n(log follow-on Y02 patents)",
       title = "Effect of Examiner Leniency on Follow-on Green Innovation")

ggsave(file.path(FIG_DIR, "fig5_main_results.pdf"), p5, width = 7, height = 3.5)
cat("Figure 5 saved.\n")

# ── Figure 6: Heterogeneity by Technology Domain ────────────────────────
hetero_dom[, ci_lo := coef - 1.96 * se]
hetero_dom[, ci_hi := coef + 1.96 * se]

p6 <- ggplot(hetero_dom, aes(x = reorder(domain, coef), y = coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_pointrange(aes(ymin = ci_lo, ymax = ci_hi),
                  color = "#2c7bb6", size = 0.7) +
  coord_flip() +
  labs(x = "", y = "Effect of 1 SD Increase in Examiner Leniency",
       title = "Heterogeneity by Y02 Technology Domain")

ggsave(file.path(FIG_DIR, "fig6_hetero_domain.pdf"), p6, width = 7, height = 4)
cat("Figure 6 saved.\n")

# ── Figure 7: Temporal Evolution ─────────────────────────────────────────
hetero_era[, ci_lo := coef - 1.96 * se]
hetero_era[, ci_hi := coef + 1.96 * se]
hetero_era[, era_mid := fcase(
  era == "2001-2005", 2003,
  era == "2006-2010", 2008,
  era == "2011-2015", 2013,
  era == "2016-2018", 2017,
  default = NA_real_
)]

p7 <- ggplot(hetero_era[!is.na(era_mid)], aes(era_mid, coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#2c7bb6") +
  geom_point(size = 3, color = "#2c7bb6") +
  geom_line(linewidth = 0.6, color = "#2c7bb6") +
  labs(x = "Filing Period (Midpoint)", y = "Effect of Examiner Leniency",
       title = "Effect of Examiner Leniency Over Time")

ggsave(file.path(FIG_DIR, "fig7_temporal.pdf"), p7, width = 7, height = 4.5)
cat("Figure 7 saved.\n")

cat("\nAll figures complete.\n")
