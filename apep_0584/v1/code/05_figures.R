## 05_figures.R — All figure generation
## APEP Paper apep_0584: Oregon Drug Decriminalization Symmetric Test

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, date := as.Date(date)]
panel[, t := (year - 2015) * 12 + month_num]

# Time-to-date mapping
t_to_date <- unique(panel[state_name == "Oregon", .(t, date)])

# Colors
oregon_col <- "#D73027"
synth_col <- "#4575B4"
ci_col <- "#DEEBF7"

# ============================================================
# Figure 1: Oregon vs National Average
# ============================================================
cat("Figure 1: Oregon vs national time series\n")

national_avg <- panel[state_name != "Oregon",
                      .(mean_od_rate = mean(od_rate, na.rm = TRUE),
                        p25 = quantile(od_rate, 0.25, na.rm = TRUE),
                        p75 = quantile(od_rate, 0.75, na.rm = TRUE)),
                      by = date]
oregon_ts <- panel[state_name == "Oregon", .(date, od_rate)]
fig1_data <- merge(oregon_ts, national_avg, by = "date")
fwrite(fig1_data, file.path(data_dir, "fig1_data.csv"))

p1 <- ggplot(fig1_data, aes(x = date)) +
  geom_ribbon(aes(ymin = p25, ymax = p75), fill = "grey85", alpha = 0.5) +
  geom_line(aes(y = mean_od_rate, color = "Other States (Mean)"),
            linewidth = 0.8, linetype = "dashed") +
  geom_line(aes(y = od_rate, color = "Oregon"), linewidth = 1.2) +
  geom_vline(xintercept = as.Date("2021-02-01"), linetype = "dotted",
             color = "black", linewidth = 0.7) +
  geom_vline(xintercept = as.Date("2024-09-01"), linetype = "dotted",
             color = "black", linewidth = 0.7) +
  annotate("text", x = as.Date("2021-04-01"), y = Inf,
           label = "M110\n(Decrim.)", vjust = 1.5,
           size = 2.8, fontface = "italic") +
  annotate("text", x = as.Date("2024-11-01"), y = Inf,
           label = "HB 4002\n(Recrim.)", vjust = 1.5,
           size = 2.8, fontface = "italic") +
  scale_color_manual(values = c("Oregon" = oregon_col,
                                 "Other States (Mean)" = synth_col)) +
  labs(x = NULL, y = "Drug Overdose Deaths per 100,000\n(12-month ending)",
       color = NULL) +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  theme(legend.position = c(0.2, 0.85))

ggsave(file.path(fig_dir, "fig1_oregon_vs_national.pdf"), p1, width = 8, height = 5)

# ============================================================
# Figure 2: Design 1 — Oregon vs Synthetic Oregon
# ============================================================
cat("Figure 2: Design 1 levels\n")

att_d1 <- fread(file.path(data_dir, "att_decrim.csv"))
att_d1 <- merge(att_d1, t_to_date, by.x = "time", by.y = "t", all.x = TRUE)
fwrite(att_d1, file.path(data_dir, "fig2_data.csv"))

p2 <- ggplot(att_d1[!is.na(date)], aes(x = date)) +
  geom_line(aes(y = oregon, color = "Oregon"), linewidth = 1.1) +
  geom_line(aes(y = synthetic, color = "Synthetic Oregon"),
            linewidth = 1, linetype = "dashed") +
  geom_vline(xintercept = as.Date("2021-02-01"), linetype = "dotted", linewidth = 0.7) +
  annotate("text", x = as.Date("2021-04-01"), y = Inf,
           label = "Measure 110", vjust = 1.5, size = 3, fontface = "italic") +
  scale_color_manual(values = c("Oregon" = oregon_col,
                                 "Synthetic Oregon" = synth_col)) +
  labs(x = NULL, y = "Overdose Death Rate per 100K",
       color = NULL,
       title = "Design 1: Oregon vs. Synthetic Oregon") +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y") +
  theme(legend.position = c(0.2, 0.85))

ggsave(file.path(fig_dir, "fig2_design1_levels.pdf"), p2, width = 7, height = 5)

# ============================================================
# Figure 3: Design 1 — Gap plot (ATT over time)
# ============================================================
cat("Figure 3: Design 1 gap plot\n")

p3 <- ggplot(att_d1[!is.na(date)], aes(x = date, y = att_est)) +
  geom_line(color = oregon_col, linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = as.Date("2021-02-01"), linetype = "dotted", linewidth = 0.7) +
  annotate("text", x = as.Date("2021-04-01"), y = Inf,
           label = "Measure 110", vjust = 1.5, size = 3, fontface = "italic") +
  labs(x = NULL, y = "Gap: Oregon - Synthetic Oregon\n(Deaths per 100K)",
       title = "Design 1: Decriminalization Effect") +
  scale_x_date(date_breaks = "2 years", date_labels = "%Y")

ggsave(file.path(fig_dir, "fig3_design1_gap.pdf"), p3, width = 7, height = 5)

# ============================================================
# Figure 4: Design 2 — Oregon vs Synthetic Oregon
# ============================================================
cat("Figure 4: Design 2 levels\n")

att_d2 <- fread(file.path(data_dir, "att_recrim.csv"))
# Design 2 time mapping: t2 = (year - 2021)*12 + month_num
d2_dates <- unique(panel[date >= as.Date("2021-02-01") & state_name == "Oregon",
                         .(t2 = (year - 2021) * 12 + month_num, date)])
att_d2 <- merge(att_d2, d2_dates, by.x = "time", by.y = "t2", all.x = TRUE)
fwrite(att_d2, file.path(data_dir, "fig4_data.csv"))

p4 <- ggplot(att_d2[!is.na(date)], aes(x = date)) +
  geom_line(aes(y = oregon, color = "Oregon"), linewidth = 1.1) +
  geom_line(aes(y = synthetic, color = "Synthetic Oregon"),
            linewidth = 1, linetype = "dashed") +
  geom_vline(xintercept = as.Date("2024-09-01"), linetype = "dotted", linewidth = 0.7) +
  annotate("text", x = as.Date("2024-11-01"), y = Inf,
           label = "HB 4002", vjust = 1.5, size = 3, fontface = "italic") +
  scale_color_manual(values = c("Oregon" = oregon_col,
                                 "Synthetic Oregon" = synth_col)) +
  labs(x = NULL, y = "Overdose Death Rate per 100K",
       color = NULL,
       title = "Design 2: Oregon vs. Synthetic Oregon (Recriminalization)") +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  theme(legend.position = c(0.2, 0.85))

ggsave(file.path(fig_dir, "fig4_design2_levels.pdf"), p4, width = 7, height = 5)

# ============================================================
# Figure 5: Permutation Inference (Design 1)
# ============================================================
cat("Figure 5: Permutation inference\n")

placebo <- fread(file.path(data_dir, "placebo_atts.csv"))
fwrite(placebo, file.path(data_dir, "fig5_data.csv"))

p5 <- ggplot(placebo, aes(x = placebo_att, fill = is_oregon)) +
  geom_histogram(bins = 25, alpha = 0.7, color = "white") +
  geom_vline(xintercept = placebo[is_oregon == TRUE, placebo_att],
             color = oregon_col, linewidth = 1.2) +
  scale_fill_manual(values = c("FALSE" = "grey70", "TRUE" = oregon_col),
                    labels = c("Placebo States", "Oregon"), name = NULL) +
  labs(x = "Average Post-Treatment Gap (Deaths per 100K)",
       y = "Count",
       title = "Permutation Inference: Design 1") +
  theme(legend.position = c(0.85, 0.85))

ggsave(file.path(fig_dir, "fig5_permutation_d1.pdf"), p5, width = 7, height = 5)

# ============================================================
# Figure 6: Drug Decomposition
# ============================================================
cat("Figure 6: Drug decomposition\n")

decomp <- fread(file.path(data_dir, "drug_decomposition.csv"))
decomp <- decomp[!is.na(att)]
fwrite(decomp, file.path(data_dir, "fig6_data.csv"))

p6 <- ggplot(decomp, aes(x = reorder(drug, -att), y = att)) +
  geom_col(aes(fill = att > 0), width = 0.6) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  scale_fill_manual(values = c("TRUE" = oregon_col, "FALSE" = synth_col), guide = "none") +
  labs(x = NULL, y = "ATT: Drug-Specific Overdose Rate per 100K",
       title = "Drug Decomposition of Decriminalization Effect") +
  coord_flip()

ggsave(file.path(fig_dir, "fig6_drug_decomposition.pdf"), p6, width = 7, height = 4.5)

# ============================================================
# Figure 7: Fentanyl Share Trajectories
# ============================================================
cat("Figure 7: Fentanyl share\n")

# Keep NA fent_share as-is for figure (don't replace with 0)
fent_or <- panel[state_name == "Oregon" & !is.na(fent_share) & fent_share > 0,
                 .(date, fent_share_or = fent_share)]
fent_nat <- panel[state_name != "Oregon" & !is.na(fent_share),
                  .(fent_share_nat = mean(fent_share, na.rm = TRUE)), by = date]
fig7_data <- merge(fent_or, fent_nat, by = "date")
fwrite(fig7_data, file.path(data_dir, "fig7_data.csv"))

p7 <- ggplot(fig7_data, aes(x = date)) +
  geom_line(aes(y = fent_share_or, color = "Oregon"), linewidth = 1) +
  geom_line(aes(y = fent_share_nat, color = "National Average"),
            linewidth = 0.8, linetype = "dashed") +
  geom_vline(xintercept = as.Date("2021-02-01"), linetype = "dotted") +
  geom_vline(xintercept = as.Date("2024-09-01"), linetype = "dotted") +
  scale_color_manual(values = c("Oregon" = oregon_col, "National Average" = synth_col)) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = NULL, y = "Synthetic Opioid Share of Overdose Deaths",
       color = NULL,
       title = "Fentanyl Exposure: Oregon vs. National Average") +
  theme(legend.position = c(0.25, 0.85))

ggsave(file.path(fig_dir, "fig7_fentanyl_share.pdf"), p7, width = 7, height = 5)

# ============================================================
# Figure 8: Combined Symmetric Design
# ============================================================
cat("Figure 8: Symmetric design combined\n")

att_d1_plot <- att_d1[!is.na(date), .(date, att_est, design = "Decriminalization")]
att_d2_plot <- att_d2[!is.na(date), .(date, att_est, design = "Recriminalization")]
combined <- rbind(att_d1_plot, att_d2_plot)
fwrite(combined, file.path(data_dir, "fig8_data.csv"))

p8 <- ggplot(combined, aes(x = date, y = att_est, color = design)) +
  geom_line(linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = as.Date("2021-02-01"), linetype = "dotted") +
  geom_vline(xintercept = as.Date("2024-09-01"), linetype = "dotted") +
  scale_color_manual(values = c("Decriminalization" = oregon_col,
                                 "Recriminalization" = synth_col)) +
  labs(x = NULL, y = "Gap: Oregon - Synthetic Oregon\n(Deaths per 100K)",
       color = NULL,
       title = "The Symmetric Test: Two Policy Switches, One Unit") +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig8_symmetric_combined.pdf"), p8, width = 8, height = 5)

cat("\n=== ALL FIGURES GENERATED ===\n")
