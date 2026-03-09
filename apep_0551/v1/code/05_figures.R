## ============================================================
## 05_figures.R — Generate all figures
## APEP-0551: Disaster Salience and Regulatory Acceleration
## ============================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "panel_dept_year.csv"))

# ----------------------------------------------------------------
# Figure 1: Aggregate ARIA accident counts over time
# ----------------------------------------------------------------
cat("Figure 1: Aggregate time series...\n")

annual <- panel[, .(
  total = sum(n_total),
  severe = sum(n_severe),
  fatal = sum(n_fatal),
  minor = sum(n_minor)
), by = year]

fwrite(annual, file.path(data_dir, "fig1_annual_counts.csv"))

p1 <- ggplot(annual, aes(x = year)) +
  geom_line(aes(y = total), linewidth = 1, color = "#2c3e50") +
  geom_point(aes(y = total), size = 2, color = "#2c3e50") +
  geom_vline(xintercept = 2001.75, linetype = "dashed", color = "#e74c3c",
             linewidth = 0.8) +
  geom_vline(xintercept = 2003, linetype = "dotted", color = "#3498db",
             linewidth = 0.8) +
  annotate("text", x = 2001.75, y = max(annual$total) * 0.95,
           label = "AZF\nexplosion", hjust = 1.1, size = 3, color = "#e74c3c") +
  annotate("text", x = 2003, y = max(annual$total) * 0.85,
           label = "Loi 2003", hjust = -0.1, size = 3, color = "#3498db") +
  labs(x = "Year", y = "Industrial accidents (ARIA count)",
       title = "Industrial Accident Reports in France, 1992-2010") +
  scale_x_continuous(breaks = seq(1992, 2010, 2)) +
  theme(plot.title = element_text(size = 12))

ggsave(file.path(fig_dir, "fig1_aggregate_timeseries.pdf"),
       p1, width = 8, height = 5)

# ----------------------------------------------------------------
# Figure 2: Event study — Total accidents
# ----------------------------------------------------------------
cat("Figure 2: Event study (total)...\n")

es_data <- fread(file.path(data_dir, "event_study_results.csv"))

es_total <- es_data[outcome == "Total accidents"]
# Add reference year
ref_row <- data.table(outcome = "Total accidents", rel_year = 0,
                      estimate = 0, se = 0, ci_lo = 0, ci_hi = 0)
es_total <- rbind(es_total, ref_row)
es_total <- es_total[order(rel_year)]

fwrite(es_total, file.path(data_dir, "fig2_event_study_total.csv"))

p2 <- ggplot(es_total, aes(x = rel_year, y = estimate)) +
  geom_hline(yintercept = 0, color = "gray60") +
  geom_vline(xintercept = 1.5, linetype = "dashed", color = "#e74c3c",
             linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, fill = "#2c3e50") +
  geom_line(linewidth = 0.8, color = "#2c3e50") +
  geom_point(size = 2.5, color = "#2c3e50") +
  annotate("text", x = 1.5, y = max(es_total$ci_hi, na.rm = TRUE) * 0.9,
           label = "Loi 2003", hjust = -0.1, size = 3, color = "#e74c3c") +
  labs(x = "Years relative to AZF explosion (2001)",
       y = "Coefficient on log(Seveso+1) x Year indicator",
       title = "Event Study: Total Reported Industrial Accidents") +
  scale_x_continuous(breaks = seq(-9, 9, 2)) +
  theme(plot.title = element_text(size = 12))

ggsave(file.path(fig_dir, "fig2_event_study_total.pdf"),
       p2, width = 8, height = 5)

# ----------------------------------------------------------------
# Figure 3: Event study — Severe accidents
# ----------------------------------------------------------------
cat("Figure 3: Event study (severe)...\n")

es_severe <- es_data[outcome == "Severe accidents"]
ref_row_s <- data.table(outcome = "Severe accidents", rel_year = 0,
                        estimate = 0, se = 0, ci_lo = 0, ci_hi = 0)
es_severe <- rbind(es_severe, ref_row_s)
es_severe <- es_severe[order(rel_year)]

fwrite(es_severe, file.path(data_dir, "fig3_event_study_severe.csv"))

p3 <- ggplot(es_severe, aes(x = rel_year, y = estimate)) +
  geom_hline(yintercept = 0, color = "gray60") +
  geom_vline(xintercept = 1.5, linetype = "dashed", color = "#e74c3c",
             linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, fill = "#c0392b") +
  geom_line(linewidth = 0.8, color = "#c0392b") +
  geom_point(size = 2.5, color = "#c0392b") +
  labs(x = "Years relative to AZF explosion (2001)",
       y = "Coefficient on log(Seveso+1) x Year indicator",
       title = "Event Study: Severe Industrial Accidents (Scale >= 3)") +
  scale_x_continuous(breaks = seq(-9, 9, 2)) +
  theme(plot.title = element_text(size = 12))

ggsave(file.path(fig_dir, "fig3_event_study_severe.pdf"),
       p3, width = 8, height = 5)

# ----------------------------------------------------------------
# Figure 4: Detection vs. Deterrence — Minor vs. Severe
# ----------------------------------------------------------------
cat("Figure 4: Detection vs deterrence...\n")

es_minor <- es_data[outcome == "Minor accidents"]
ref_row_m <- data.table(outcome = "Minor accidents", rel_year = 0,
                        estimate = 0, se = 0, ci_lo = 0, ci_hi = 0)
es_minor <- rbind(es_minor, ref_row_m)
es_minor <- es_minor[order(rel_year)]

es_combined <- rbind(
  es_severe[, .(rel_year, estimate, ci_lo, ci_hi, category = "Severe (scale ≥ 3)")],
  es_minor[, .(rel_year, estimate, ci_lo, ci_hi, category = "Minor (scale < 2)")]
)

fwrite(es_combined, file.path(data_dir, "fig4_detection_deterrence.csv"))

p4 <- ggplot(es_combined, aes(x = rel_year, y = estimate, color = category,
                               fill = category)) +
  geom_hline(yintercept = 0, color = "gray60") +
  geom_vline(xintercept = 1.5, linetype = "dashed", color = "gray40",
             linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.1, color = NA) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  scale_color_manual(values = c("Severe (scale ≥ 3)" = "#c0392b",
                                 "Minor (scale < 2)" = "#2980b9")) +
  scale_fill_manual(values = c("Severe (scale ≥ 3)" = "#c0392b",
                                "Minor (scale < 2)" = "#2980b9")) +
  labs(x = "Years relative to AZF explosion (2001)",
       y = "Coefficient on log(Seveso+1) x Year indicator",
       title = "Detection vs. Deterrence: Minor and Severe Accidents",
       color = NULL, fill = NULL) +
  scale_x_continuous(breaks = seq(-9, 9, 2)) +
  theme(legend.position = c(0.2, 0.85),
        plot.title = element_text(size = 12))

ggsave(file.path(fig_dir, "fig4_detection_deterrence.pdf"),
       p4, width = 8, height = 5.5)

# ----------------------------------------------------------------
# Figure 5: Seveso site distribution across departments
# ----------------------------------------------------------------
cat("Figure 5: Seveso site distribution...\n")

seveso <- fread(file.path(data_dir, "seveso_by_dept.csv"))

fwrite(seveso[order(-seveso_h)], file.path(data_dir, "fig5_seveso_distribution.csv"))

p5 <- ggplot(seveso[seveso_h > 0][order(-seveso_h)][1:30],
             aes(x = reorder(dept_code, seveso_h), y = seveso_h)) +
  geom_col(fill = "#2c3e50", alpha = 0.8) +
  geom_col(data = seveso[seveso_h > 0][order(-seveso_h)][1:30][dept_code == "31"],
           fill = "#e74c3c", alpha = 0.8) +
  coord_flip() +
  labs(x = "Department", y = "Seveso Seuil Haut sites",
       title = "Distribution of Seveso High-Threshold Sites (Top 30 Departments)") +
  annotate("text", x = which(seveso[seveso_h > 0][order(-seveso_h)][1:30]$dept_code == "31"),
           y = seveso[dept_code == "31"]$seveso_h + 1,
           label = "Toulouse (AZF)", hjust = 0, size = 3, color = "#e74c3c") +
  theme(plot.title = element_text(size = 11))

ggsave(file.path(fig_dir, "fig5_seveso_distribution.pdf"),
       p5, width = 7, height = 7)

# ----------------------------------------------------------------
# Figure 6: Leave-one-out sensitivity
# ----------------------------------------------------------------
cat("Figure 6: Leave-one-out...\n")

loo <- fread(file.path(data_dir, "leave_one_out.csv"))
main_coef <- fread(file.path(data_dir, "main_results.csv"))[outcome == "Total"]$coefficient

fwrite(loo[order(coefficient)], file.path(data_dir, "fig6_leave_one_out.csv"))

p6 <- ggplot(loo, aes(x = reorder(dept_excluded, coefficient), y = coefficient)) +
  geom_point(size = 1.2, color = "#2c3e50") +
  geom_hline(yintercept = main_coef, linetype = "dashed", color = "#e74c3c") +
  geom_hline(yintercept = 0, color = "gray60") +
  labs(x = "Department excluded", y = "Coefficient on treatment",
       title = "Leave-One-Out Sensitivity: Total Accidents") +
  theme(axis.text.x = element_text(angle = 90, size = 5, vjust = 0.5),
        plot.title = element_text(size = 12))

ggsave(file.path(fig_dir, "fig6_leave_one_out.pdf"),
       p6, width = 9, height = 5)

# ----------------------------------------------------------------
# Figure 7: Pre-treatment trends by Seveso density groups
# ----------------------------------------------------------------
cat("Figure 7: Pre-treatment parallel trends...\n")

panel[, seveso_group := cut(seveso_h, breaks = c(-1, 0, 5, 15, 50),
                            labels = c("0 sites", "1-5 sites",
                                       "6-15 sites", "16+ sites"))]

trends <- panel[, .(mean_total = mean(n_total),
                    mean_severe = mean(n_severe)), by = .(year, seveso_group)]

fwrite(trends, file.path(data_dir, "fig7_parallel_trends.csv"))

p7 <- ggplot(trends, aes(x = year, y = mean_total, color = seveso_group)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_vline(xintercept = 2001.75, linetype = "dashed", color = "#e74c3c",
             linewidth = 0.5) +
  geom_vline(xintercept = 2003, linetype = "dotted", color = "#3498db",
             linewidth = 0.5) +
  scale_color_brewer(palette = "Set1") +
  labs(x = "Year", y = "Mean accidents per department",
       title = "Pre-Treatment Trends by Seveso Site Density",
       color = "Seveso H sites") +
  scale_x_continuous(breaks = seq(1992, 2010, 2)) +
  theme(legend.position = c(0.15, 0.8),
        plot.title = element_text(size = 12))

ggsave(file.path(fig_dir, "fig7_parallel_trends.pdf"),
       p7, width = 8, height = 5.5)

cat("\nAll figures generated.\n")
