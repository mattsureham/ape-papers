## 05_figures.R — Generate all figures from saved data
## apep_0533: Salary History Bans and the Gender Earnings Gap

source("00_packages.R")

# ============================================================
# Figure 1: CS-DiD Event Study — New Hires vs. Continuing Workers
# ============================================================

cat("Figure 1: CS-DiD Event Study\n")
es_hir <- fread(file.path(data_dir, "event_study_newhires.csv"))
es_cont <- fread(file.path(data_dir, "event_study_continuing.csv"))

es_both <- rbindlist(list(es_hir, es_cont))
es_both[, outcome := factor(outcome, levels = c("New Hires", "Continuing Workers"))]

# Convert event_time to quarters
fig1 <- ggplot(es_both, aes(x = event_time, y = att, color = outcome, fill = outcome)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "gray40") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15, color = NA) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  scale_color_manual(values = c("New Hires" = "#2166AC", "Continuing Workers" = "#B2182B")) +
  scale_fill_manual(values = c("New Hires" = "#2166AC", "Continuing Workers" = "#B2182B")) +
  labs(
    x = "Quarters Relative to Ban",
    y = "ATT (Log Gender Earnings Ratio)",
    color = NULL, fill = NULL
  ) +
  theme(legend.position = c(0.25, 0.85),
        legend.background = element_rect(fill = "white", color = NA))

ggsave(file.path(fig_dir, "fig1_event_study.pdf"), fig1, width = 8, height = 5.5)
ggsave(file.path(fig_dir, "fig1_event_study.png"), fig1, width = 8, height = 5.5, dpi = 300)
cat("  Saved fig1_event_study.pdf\n")

# ============================================================
# Figure 2: Industry Heterogeneity
# ============================================================

cat("Figure 2: Industry Heterogeneity\n")
ind_res <- fread(file.path(data_dir, "industry_heterogeneity.csv"))

# Industry labels
ind_labels <- data.table(
  industry = c("11", "21", "22", "23", "31-33", "42", "44-45",
               "48-49", "51", "52", "53", "54", "55", "56",
               "61", "62", "71", "72", "81"),
  label = c("Agric.", "Mining", "Utilities", "Construction",
            "Manufacturing", "Wholesale", "Retail",
            "Transport.", "Information", "Finance", "Real Estate",
            "Prof. Services", "Management", "Admin.",
            "Education", "Healthcare", "Arts/Ent.", "Accommodation", "Other Svc.")
)

ind_res <- merge(ind_res, ind_labels, by = "industry", all.x = TRUE)
ind_res[is.na(label), label := industry]

# Color by gender composition
ind_res[, type := "Mixed"]
ind_res[industry %in% c("23", "21", "48-49", "31-33", "22"), type := "Male-Dominated"]
ind_res[industry %in% c("62", "61", "72"), type := "Female-Dominated"]

ind_res <- ind_res[order(coef)]
ind_res[, label := factor(label, levels = label)]

fig2 <- ggplot(ind_res, aes(x = coef, y = label, color = type)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  geom_errorbarh(aes(xmin = ci_lower, xmax = ci_upper), height = 0.3) +
  geom_point(size = 2.5) +
  scale_color_manual(values = c("Male-Dominated" = "#2166AC",
                                "Female-Dominated" = "#B2182B",
                                "Mixed" = "gray40")) +
  labs(
    x = "Effect on Log Gender Earnings Ratio (New Hires)",
    y = NULL,
    color = NULL
  ) +
  theme(legend.position = "bottom")

ggsave(file.path(fig_dir, "fig2_industry_heterogeneity.pdf"), fig2, width = 8, height = 7)
ggsave(file.path(fig_dir, "fig2_industry_heterogeneity.png"), fig2, width = 8, height = 7, dpi = 300)
cat("  Saved fig2_industry_heterogeneity.pdf\n")

# ============================================================
# Figure 3: Randomization Inference Distribution
# ============================================================

cat("Figure 3: Randomization Inference\n")
ri <- fread(file.path(data_dir, "ri_distribution.csv"))
actual <- ri$actual[1]
ri_p <- ri$ri_p[1]

fig3 <- ggplot(ri, aes(x = perm_coef)) +
  geom_histogram(bins = 40, fill = "gray70", color = "white") +
  geom_vline(xintercept = actual, color = "#B2182B", linewidth = 1.2) +
  geom_vline(xintercept = -actual, color = "#B2182B", linewidth = 1.2, linetype = "dashed") +
  annotate("text", x = actual, y = Inf, vjust = 2, hjust = -0.1,
           label = sprintf("Actual = %.4f\nRI p = %.3f", actual, ri_p),
           color = "#B2182B", size = 3.5, fontface = "bold") +
  labs(
    x = "Permuted Treatment Effect",
    y = "Count"
  )

ggsave(file.path(fig_dir, "fig3_randomization_inference.pdf"), fig3, width = 7, height = 4.5)
ggsave(file.path(fig_dir, "fig3_randomization_inference.png"), fig3, width = 7, height = 4.5, dpi = 300)
cat("  Saved fig3_randomization_inference.pdf\n")

# ============================================================
# Figure 4: Raw Trends — Gender Earnings Ratio
# ============================================================

cat("Figure 4: Raw Trends\n")
df <- fread(file.path(data_dir, "analysis_aggregate.csv"))

# Average gender ratio by treated/control groups over time
trends <- df[, .(
  ratio_hir = mean(earn_ratio_hir, na.rm = TRUE),
  ratio_s = mean(earn_ratio_s, na.rm = TRUE),
  n = .N
), by = .(period, treated)]

trends[, group := fifelse(treated, "Ban States", "Non-Ban States")]
trends[, year_q := 2010 + (period - 1) / 4]

# New hires
fig4a <- ggplot(trends, aes(x = year_q, y = ratio_hir, color = group)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = 2017.75, linetype = "dotted", color = "gray40") +
  annotate("text", x = 2017.75, y = min(trends$ratio_hir, na.rm = TRUE),
           label = "First ban\n(2017-Q4)", vjust = 1.5, hjust = -0.1, size = 3) +
  scale_color_manual(values = c("Ban States" = "#2166AC", "Non-Ban States" = "#B2182B")) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    x = NULL,
    y = "Female/Male Earnings Ratio",
    color = NULL,
    title = "New Hire Earnings"
  ) +
  theme(legend.position = c(0.2, 0.85),
        legend.background = element_rect(fill = "white", color = NA))

# Continuing workers
fig4b <- ggplot(trends, aes(x = year_q, y = ratio_s, color = group)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = 2017.75, linetype = "dotted", color = "gray40") +
  scale_color_manual(values = c("Ban States" = "#2166AC", "Non-Ban States" = "#B2182B")) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    x = NULL,
    y = "Female/Male Earnings Ratio",
    color = NULL,
    title = "Continuing Worker Earnings"
  ) +
  theme(legend.position = "none")

# Combine
library(patchwork)
fig4 <- fig4a / fig4b +
  plot_annotation(tag_levels = "A")

ggsave(file.path(fig_dir, "fig4_raw_trends.pdf"), fig4, width = 8, height = 8)
ggsave(file.path(fig_dir, "fig4_raw_trends.png"), fig4, width = 8, height = 8, dpi = 300)
cat("  Saved fig4_raw_trends.pdf\n")

# ============================================================
# Figure 5: Treatment Timing Map
# ============================================================

cat("Figure 5: Treatment Timing\n")

ban_dates <- data.table(
  state = c("41", "10", "11", "06", "25", "50", "09", "15",
            "17", "23", "53", "01", "34", "36", "51", "24",
            "08", "32", "44", "27"),
  state_name = c("Oregon", "Delaware", "DC", "California",
                 "Massachusetts", "Vermont", "Connecticut", "Hawaii",
                 "Illinois", "Maine", "Washington", "Alabama",
                 "New Jersey", "New York", "Virginia", "Maryland",
                 "Colorado", "Nevada", "Rhode Island", "Minnesota"),
  ban_year = c(2017, 2017, 2017, 2018, 2018, 2018, 2019, 2019,
               2019, 2019, 2019, 2019, 2019, 2020, 2020, 2020,
               2021, 2021, 2023, 2024)
)

ban_dates <- ban_dates[order(ban_year, state_name)]
ban_dates[, state_name := factor(state_name, levels = rev(state_name))]

fig5 <- ggplot(ban_dates, aes(x = ban_year, y = state_name)) +
  geom_point(size = 3, color = "#2166AC") +
  geom_segment(aes(xend = 2024.5, yend = state_name),
               linetype = "solid", color = "#2166AC", alpha = 0.3) +
  scale_x_continuous(breaks = 2017:2024) +
  labs(
    x = "Year Ban Took Effect",
    y = NULL
  )

ggsave(file.path(fig_dir, "fig5_treatment_timing.pdf"), fig5, width = 7, height = 6)
ggsave(file.path(fig_dir, "fig5_treatment_timing.png"), fig5, width = 7, height = 6, dpi = 300)
cat("  Saved fig5_treatment_timing.pdf\n")

cat("\nAll figures generated.\n")
