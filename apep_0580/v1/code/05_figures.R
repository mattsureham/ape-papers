## ============================================================
## 05_figures.R — Generate all figures
## apep_0580: Civil Asset Forfeiture Reform and Police Reallocation
## ============================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))

# ============================================================
# Figure 1: Treatment Rollout Map
# ============================================================

cat("=== Figure 1: Reform Rollout ===\n")

cohorts <- fread(file.path(data_dir, "cohort_sizes.csv"))

reform_timeline <- panel %>%
  filter(ever_reformed) %>%
  distinct(state_abbr, reform_year, reform_type) %>%
  mutate(
    reform_label = case_when(
      reform_type == 3 ~ "Abolition",
      reform_type == 2 ~ "Conviction req.",
      reform_type == 1 ~ "Transparency"
    )
  ) %>%
  arrange(reform_year, reform_type)

p1 <- ggplot(reform_timeline, aes(x = reform_year, y = reorder(state_abbr, -reform_year),
                                    color = reform_label)) +
  geom_point(size = 3) +
  scale_color_manual(values = c("Abolition" = "#e41a1c", "Conviction req." = "#377eb8",
                                 "Transparency" = "#4daf4a"),
                      name = "Reform Type") +
  labs(
    title = "Staggered Adoption of Civil Asset Forfeiture Reform",
    subtitle = "37 US states, 2014-2020",
    x = "Year of Reform",
    y = ""
  ) +
  theme(
    axis.text.y = element_text(size = 7),
    legend.position = "bottom"
  )

ggsave(file.path(fig_dir, "fig1_reform_rollout.pdf"), p1,
       width = 8, height = 10, device = "pdf")
cat("  Saved fig1_reform_rollout.pdf\n")

# ============================================================
# Figure 2: Event Study — Drug Overdose Deaths
# ============================================================

cat("=== Figure 2: Event Study (Drug Deaths) ===\n")

if (file.exists(file.path(data_dir, "event_study_drug.csv"))) {
  es_drug <- fread(file.path(data_dir, "event_study_drug.csv"))

  p2 <- ggplot(es_drug, aes(x = event_time, y = att)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "red", alpha = 0.5) +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15, fill = "#377eb8") +
    geom_point(size = 2.5, color = "#377eb8") +
    geom_line(color = "#377eb8", linewidth = 0.5) +
    labs(
      title = "Effect of Forfeiture Reform on Drug Overdose Deaths",
      subtitle = "Callaway & Sant'Anna (2021), never-treated controls",
      x = "Years Relative to Reform",
      y = "ATT (Drug Deaths per 100K)"
    ) +
    scale_x_continuous(breaks = seq(-5, 5, 1)) +
    annotate("text", x = -3, y = max(es_drug$ci_upper, na.rm=TRUE) * 0.8,
             label = "Pre-reform", color = "gray40", size = 3) +
    annotate("text", x = 2, y = max(es_drug$ci_upper, na.rm=TRUE) * 0.8,
             label = "Post-reform", color = "gray40", size = 3)

  ggsave(file.path(fig_dir, "fig2_event_study_drug.pdf"), p2,
         width = 8, height = 5, device = "pdf")
  cat("  Saved fig2_event_study_drug.pdf\n")
}

# ============================================================
# Figure 3: Raw Trends by Reform Status
# ============================================================

cat("=== Figure 3: Raw Trends ===\n")

trends <- panel %>%
  group_by(year, ever_reformed) %>%
  summarize(
    mean_drug = mean(drug_death_rate, na.rm = TRUE),
    se_drug = sd(drug_death_rate, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  ) %>%
  mutate(
    group = ifelse(ever_reformed, "Reformed States", "Never-Reformed States"),
    ci_lower = mean_drug - 1.96 * se_drug,
    ci_upper = mean_drug + 1.96 * se_drug
  )

# Save for paper tables
fwrite(trends, file.path(data_dir, "raw_trends.csv"))

p3 <- ggplot(trends, aes(x = year, y = mean_drug, color = group, fill = group)) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15, color = NA) +
  geom_line(linewidth = 1) +
  geom_point(size = 1.5) +
  geom_vline(xintercept = 2014, linetype = "dashed", color = "gray50") +
  annotate("text", x = 2014.5, y = max(trends$mean_drug) * 1.05,
           label = "First reform\n(MN, 2014)", size = 2.5, hjust = 0, color = "gray40") +
  scale_color_manual(values = c("Reformed States" = "#377eb8",
                                 "Never-Reformed States" = "#e41a1c"),
                      name = "") +
  scale_fill_manual(values = c("Reformed States" = "#377eb8",
                                "Never-Reformed States" = "#e41a1c"),
                     name = "") +
  labs(
    title = "Drug Overdose Death Rates: Reformed vs. Never-Reformed States",
    subtitle = "Mean across states, with 95% confidence bands",
    x = "Year",
    y = "Drug Deaths per 100,000"
  )

ggsave(file.path(fig_dir, "fig3_raw_trends.pdf"), p3,
       width = 8, height = 5, device = "pdf")
cat("  Saved fig3_raw_trends.pdf\n")

# ============================================================
# Figure 4: Dose-Response by Reform Intensity
# ============================================================

cat("=== Figure 4: Dose-Response ===\n")

intensity_trends <- panel %>%
  group_by(year, reform_intensity) %>%
  summarize(
    mean_drug = mean(drug_death_rate, na.rm = TRUE),
    n_states = n_distinct(state_abbr),
    .groups = "drop"
  )

p4 <- ggplot(intensity_trends, aes(x = year, y = mean_drug,
                                     color = reform_intensity)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_vline(xintercept = 2014, linetype = "dashed", color = "gray50") +
  scale_color_manual(
    values = c("No reform" = "#e41a1c", "Transparency" = "#4daf4a",
               "Conviction required" = "#377eb8", "Abolition" = "#984ea3"),
    name = "Reform Type"
  ) +
  labs(
    title = "Drug Death Rates by Reform Intensity",
    subtitle = "Mean drug overdose deaths per 100K, by reform type",
    x = "Year",
    y = "Drug Deaths per 100,000"
  )

ggsave(file.path(fig_dir, "fig4_dose_response.pdf"), p4,
       width = 8, height = 5, device = "pdf")
cat("  Saved fig4_dose_response.pdf\n")

# ============================================================
# Figure 5: Randomization Inference Distribution
# ============================================================

cat("=== Figure 5: RI Distribution ===\n")

if (file.exists(file.path(data_dir, "ri_distribution.csv"))) {
  ri_dist <- fread(file.path(data_dir, "ri_distribution.csv"))
  ri_stats <- fread(file.path(data_dir, "ri_results.csv"))

  p5 <- ggplot(ri_dist, aes(x = perm_coef)) +
    geom_histogram(bins = 40, fill = "gray70", color = "white", alpha = 0.8) +
    geom_vline(xintercept = ri_stats$actual, color = "#e41a1c",
               linewidth = 1, linetype = "solid") +
    annotate("text", x = ri_stats$actual, y = Inf,
             label = paste0("Actual = ", round(ri_stats$actual, 3)),
             vjust = -0.5, color = "#e41a1c", size = 3.5, fontface = "bold") +
    labs(
      title = "Randomization Inference: Permutation Distribution",
      subtitle = paste0("500 permutations of reform timing. RI p-value = ",
                         round(ri_stats$ri_pvalue, 3)),
      x = "Permuted Treatment Effect",
      y = "Count"
    )

  ggsave(file.path(fig_dir, "fig5_ri_distribution.pdf"), p5,
         width = 7, height = 4.5, device = "pdf")
  cat("  Saved fig5_ri_distribution.pdf\n")
}

# ============================================================
# Figure 6: Jackknife Sensitivity
# ============================================================

cat("=== Figure 6: Jackknife ===\n")

if (file.exists(file.path(data_dir, "jackknife_results.csv"))) {
  jack <- fread(file.path(data_dir, "jackknife_results.csv"))

  p6 <- ggplot(jack, aes(x = reorder(dropped_state, coef), y = coef)) +
    geom_point(aes(color = influential), size = 1.5) +
    geom_hline(yintercept = jack$coef[1] + jack$deviation[1],  # actual
               linetype = "dashed", color = "#e41a1c") +
    scale_color_manual(values = c("TRUE" = "#e41a1c", "FALSE" = "gray50"),
                        guide = "none") +
    coord_flip() +
    labs(
      title = "Leave-One-State-Out Jackknife",
      subtitle = "Sensitivity of TWFE estimate to each state",
      x = "",
      y = "Estimated Coefficient"
    ) +
    theme(axis.text.y = element_text(size = 6))

  ggsave(file.path(fig_dir, "fig6_jackknife.pdf"), p6,
         width = 7, height = 9, device = "pdf")
  cat("  Saved fig6_jackknife.pdf\n")
}

# ============================================================
# Figure 7: Heterogeneity by Forfeiture Dependence
# ============================================================

cat("=== Figure 7: Heterogeneity ===\n")

het_trends <- panel %>%
  filter(ever_reformed) %>%
  group_by(year, high_forfeiture) %>%
  summarize(
    mean_drug = mean(drug_death_rate, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    group = ifelse(high_forfeiture, "High Pre-Reform Forfeiture",
                   "Low Pre-Reform Forfeiture")
  )

fwrite(het_trends, file.path(data_dir, "heterogeneity_trends.csv"))

p7 <- ggplot(het_trends, aes(x = year, y = mean_drug, color = group)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  scale_color_manual(values = c("High Pre-Reform Forfeiture" = "#e41a1c",
                                 "Low Pre-Reform Forfeiture" = "#377eb8"),
                      name = "") +
  labs(
    title = "Drug Death Trends by Pre-Reform Forfeiture Intensity",
    subtitle = "Among reformed states only",
    x = "Year",
    y = "Drug Deaths per 100,000"
  )

ggsave(file.path(fig_dir, "fig7_heterogeneity.pdf"), p7,
       width = 8, height = 5, device = "pdf")
cat("  Saved fig7_heterogeneity.pdf\n")

# ============================================================
# Figure 8: Event Study — Homicide (if available)
# ============================================================

cat("=== Figure 8: Event Study (Homicide) ===\n")

if (file.exists(file.path(data_dir, "event_study_homicide.csv"))) {
  es_hom <- fread(file.path(data_dir, "event_study_homicide.csv"))

  p8 <- ggplot(es_hom, aes(x = event_time, y = att)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "red", alpha = 0.5) +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15, fill = "#e41a1c") +
    geom_point(size = 2.5, color = "#e41a1c") +
    geom_line(color = "#e41a1c", linewidth = 0.5) +
    labs(
      title = "Effect of Forfeiture Reform on Homicide Rate",
      subtitle = "Callaway & Sant'Anna (2021), never-treated controls",
      x = "Years Relative to Reform",
      y = "ATT (Homicides per 100K)"
    ) +
    scale_x_continuous(breaks = seq(-5, 5, 1))

  ggsave(file.path(fig_dir, "fig8_event_study_homicide.pdf"), p8,
         width = 8, height = 5, device = "pdf")
  cat("  Saved fig8_event_study_homicide.pdf\n")
} else {
  cat("  No homicide event study data. Skipping.\n")
}

cat("\n=== ALL FIGURES GENERATED ===\n")
cat("  Files in", fig_dir, ":\n")
for (f in list.files(fig_dir)) cat("  ", f, "\n")
