# ==============================================================================
# 05_figures.R — All Figure Generation
# The Credential Cliff: Multi-Cutoff RDD on South Africa Matric Pass Levels
# ==============================================================================

source("00_packages.R")

data_dir <- "../data/"
fig_dir <- "../figures/"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# Color palettes
pass_colors <- c(
  "Fail" = "#999999",
  "Higher Certificate" = "#E41A1C",
  "Diploma Pass" = "#377EB8",
  "Bachelor's Pass" = "#4DAF4A"
)

cred_colors <- c(
  "HC Pass" = "#E41A1C",
  "Diploma Pass" = "#FF7F00",
  "Post-school Diploma" = "#377EB8",
  "University Degree" = "#4DAF4A"
)

educ_colors <- c(
  "None" = "#999999",
  "<Matric" = "#E41A1C",
  "Matric" = "#FF7F00",
  "Cert/Dip" = "#377EB8",
  "Bachelor's" = "#4DAF4A",
  "Postgrad" = "#984EA3"
)

# ==============================================================================
# FIGURE 1: NSC Pass Type Distribution Over Time (Stacked Area)
# ==============================================================================
cat("Figure 1: NSC composition\n")

nsc_long <- fread(file.path(data_dir, "nsc_long.csv"))
nsc_long$pass_type <- factor(nsc_long$pass_type,
                              levels = c("Fail", "Higher Certificate",
                                         "Diploma Pass", "Bachelor's Pass"))

p1 <- ggplot(nsc_long, aes(x = year, y = share, fill = pass_type)) +
  geom_area(alpha = 0.85) +
  scale_fill_manual(values = pass_colors, name = "Pass Type") +
  scale_x_continuous(breaks = seq(2008, 2022, 2)) +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(
    title = "National Senior Certificate Examination Results",
    subtitle = "Share of candidates by pass type, 2008-2022",
    x = NULL,
    y = "Share of candidates (%)",
    caption = "Source: Department of Basic Education, NSC Technical Reports (2008-2022)"
  ) +
  theme(legend.position = "right")

ggsave(file.path(fig_dir, "fig1_nsc_composition.pdf"), p1,
       width = 8, height = 5, dpi = 300)

# ==============================================================================
# FIGURE 2: The Credential Cliff — Employment by Education Level
# ==============================================================================
cat("Figure 2: Credential cliff\n")

qlfs <- fread(file.path(data_dir, "qlfs_clean.csv"))
qlfs$education_short <- factor(qlfs$education_short,
                                levels = c("None", "<Matric", "Matric",
                                           "Cert/Dip", "Bachelor's", "Postgrad"))

# Average across 2014-2019
qlfs_avg <- qlfs %>%
  filter(year >= 2014 & year <= 2019) %>%
  group_by(education_short, educ_order) %>%
  summarise(
    mean_abs = mean(absorption_rate),
    se_abs = sd(absorption_rate) / sqrt(n()),
    mean_unemp = mean(unemployment_rate),
    se_unemp = sd(unemployment_rate) / sqrt(n()),
    .groups = "drop"
  )

p2 <- ggplot(qlfs_avg, aes(x = education_short, y = mean_abs)) +
  geom_col(aes(fill = education_short), width = 0.7, show.legend = FALSE) +
  geom_errorbar(aes(ymin = mean_abs - 1.96*se_abs,
                     ymax = mean_abs + 1.96*se_abs),
                width = 0.2, linewidth = 0.5) +
  scale_fill_manual(values = educ_colors) +
  scale_y_continuous(labels = function(x) paste0(x, "%"),
                     limits = c(0, 90)) +
  # Add step labels
  annotate("segment", x = 3.5, xend = 3.5, y = 40, yend = 58,
           arrow = arrow(length = unit(0.1, "inches"), ends = "both"),
           color = "red", linewidth = 0.5) +
  annotate("text", x = 3.5, y = 49, label = "+20 pp\n\"Credential\nCliff\"",
           color = "red", size = 3, hjust = -0.1, fontface = "bold") +
  labs(
    title = "The Credential Cliff: Employment by Education Level",
    subtitle = "Absorption rate (employment-to-population ratio), South Africa 2014-2019",
    x = "Highest education level",
    y = "Absorption rate (%)",
    caption = "Source: Stats SA Quarterly Labour Force Survey (QLFS), P0211"
  )

ggsave(file.path(fig_dir, "fig2_credential_cliff.pdf"), p2,
       width = 8, height = 5.5, dpi = 300)

# ==============================================================================
# FIGURE 3: Multi-Cutoff Design — Schematic
# ==============================================================================
cat("Figure 3: Multi-cutoff design schematic\n")

# CONCEPTUAL ILLUSTRATION ONLY — no empirical data used.
# This figure shows the institutional ASSIGNMENT RULE (which pass type a score receives).
# The density curve is a stylized illustration of score concentration, not estimated from data.
# Actual score distributions require DataFirst NSC microdata (DOI: 10.25828/pcn8-pc32).
# Per AER data editor standards, this is a conceptual diagram (like a DAG or flowchart).
score_grid <- data.frame(
  score = seq(20, 60, by = 0.5)
) %>%
  mutate(
    # Stylized density (showing that many students cluster in the middle)
    density = dnorm(score, mean = 42, sd = 10),
    # Credential assignment (mechanical)
    credential = case_when(
      score < 30 ~ "Fail",
      score < 40 ~ "Higher Certificate",
      score < 50 ~ "Diploma",
      TRUE ~ "Bachelor's"
    ),
    credential = factor(credential,
                        levels = c("Fail", "Higher Certificate",
                                   "Diploma", "Bachelor's"))
  )

p3 <- ggplot(score_grid, aes(x = score, y = density, fill = credential)) +
  geom_area(alpha = 0.7) +
  geom_vline(xintercept = c(30, 40, 50), linetype = "dashed",
             color = "black", linewidth = 0.5) +
  scale_fill_manual(
    values = c("Fail" = "#999999", "Higher Certificate" = "#E41A1C",
               "Diploma" = "#377EB8", "Bachelor's" = "#4DAF4A"),
    name = "Pass Type"
  ) +
  scale_x_continuous(breaks = c(20, 30, 40, 50, 60)) +
  annotate("text", x = 30, y = max(score_grid$density) * 1.05,
           label = "30%\nHC cutoff", size = 3, vjust = 0) +
  annotate("text", x = 40, y = max(score_grid$density) * 1.05,
           label = "40%\nDiploma cutoff", size = 3, vjust = 0) +
  annotate("text", x = 50, y = max(score_grid$density) * 1.05,
           label = "50%\nBachelor's cutoff", size = 3, vjust = 0) +
  labs(
    title = "Multi-Cutoff RDD Design: NSC Pass-Level Assignment",
    subtitle = "Stylized illustration of mechanical pass-type assignment based on binding subject score",
    x = "Binding subject score (%)",
    y = "Density (illustrative)",
    caption = "Note: This figure illustrates the institutional assignment rule, not actual score distributions.\nActual analysis requires DataFirst NSC microdata (DOI: 10.25828/pcn8-pc32)."
  ) +
  theme(axis.text.y = element_blank(),
        axis.ticks.y = element_blank())

ggsave(file.path(fig_dir, "fig3_rdd_design.pdf"), p3,
       width = 8, height = 5, dpi = 300)

# ==============================================================================
# FIGURE 4: Pass Type Returns — Absorption Rate and Earnings
# ==============================================================================
cat("Figure 4: Pass type returns\n")

pto <- fread(file.path(data_dir, "pass_type_clean.csv"))
pto$credential_short <- factor(pto$credential_short,
                                levels = c("HC Pass", "Diploma Pass",
                                           "Post-school Diploma", "University Degree"))

# Panel A: Absorption rate over time
p4a <- ggplot(pto, aes(x = year, y = absorption, color = credential_short)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_color_manual(values = cred_colors, name = "Credential") +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(
    title = "A. Absorption Rate by Credential Type",
    x = NULL,
    y = "Employment-to-population ratio (%)"
  )

# Panel B: Median earnings over time
p4b <- ggplot(pto, aes(x = year, y = median_earnings / 1000,
                        color = credential_short)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_color_manual(values = cred_colors, name = "Credential") +
  scale_y_continuous(labels = function(x) paste0("R", x, "K")) +
  labs(
    title = "B. Median Monthly Earnings by Credential Type",
    x = NULL,
    y = "Median monthly earnings (ZAR, thousands)"
  )

p4 <- p4a / p4b +
  plot_layout(guides = "collect") &
  theme(legend.position = "bottom") &
  plot_annotation(
    caption = "Source: Stats SA QLFS (P0211) and DHET Post-School Education Monitor"
  )

ggsave(file.path(fig_dir, "fig4_pass_type_returns.pdf"), p4,
       width = 8, height = 9, dpi = 300)

# ==============================================================================
# FIGURE 5: Province Variation in Bachelor's Pass Rate
# ==============================================================================
cat("Figure 5: Province variation\n")

prov <- fread(file.path(data_dir, "province_nsc_clean.csv"))

p5 <- ggplot(prov, aes(x = year, y = bachelors_rate,
                        color = province_short, group = province)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  scale_color_brewer(palette = "Set1", name = "Province") +
  scale_x_continuous(breaks = seq(2014, 2022, 2)) +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(
    title = "Provincial Variation in Bachelor's Pass Rate",
    subtitle = "Share of candidates achieving Bachelor's pass, by province (2014-2022)",
    x = NULL,
    y = "Bachelor's pass rate (%)",
    caption = "Source: Department of Basic Education, NSC Technical Reports"
  ) +
  theme(legend.position = "right")

ggsave(file.path(fig_dir, "fig5_province_variation.pdf"), p5,
       width = 8, height = 5.5, dpi = 300)

# ==============================================================================
# FIGURE 6: Cross-Country Comparison — Unemployment vs Tertiary Enrollment
# ==============================================================================
cat("Figure 6: Cross-country scatter\n")

xc <- fread(file.path(data_dir, "cross_country_2019.csv"))

p6 <- ggplot(xc, aes(x = tertiary_enroll, y = unemployment)) +
  geom_point(aes(size = gdp_pc_ppp, color = is_south_africa), alpha = 0.7) +
  geom_text(aes(label = country_code), vjust = -0.8, size = 3) +
  geom_smooth(method = "lm", se = TRUE, color = "gray50",
              linetype = "dashed", linewidth = 0.5) +
  scale_color_manual(values = c("FALSE" = "gray60", "TRUE" = "red"),
                     guide = "none") +
  scale_size_continuous(name = "GDP per capita\n(PPP, $)",
                        labels = scales::comma) +
  labs(
    title = "South Africa's Unemployment Anomaly",
    subtitle = "Unemployment rate vs. tertiary enrollment across 20 comparator countries, 2019",
    x = "Gross tertiary enrollment rate (%)",
    y = "Total unemployment rate (%)",
    caption = "Source: World Bank World Development Indicators. South Africa highlighted in red."
  )

ggsave(file.path(fig_dir, "fig6_cross_country.pdf"), p6,
       width = 8, height = 6, dpi = 300)

# ==============================================================================
# FIGURE 7: NSC → Tertiary Pipeline
# ==============================================================================
cat("Figure 7: NSC-tertiary pipeline\n")

nsc_tert <- fread(file.path(data_dir, "nsc_tertiary_merged.csv"))

# Dual axis: Bachelor's passes and first-time UG enrollment
p7 <- ggplot(nsc_tert %>% filter(year >= 2011), aes(x = year)) +
  geom_col(aes(y = bachelors_pass / 1000), fill = "#4DAF4A", alpha = 0.4, width = 0.6) +
  geom_line(aes(y = first_time_ug), color = "#377EB8", linewidth = 1.2) +
  geom_point(aes(y = first_time_ug), color = "#377EB8", size = 2.5) +
  scale_y_continuous(
    name = "Bachelor's passes (thousands, bars)",
    sec.axis = sec_axis(~., name = "First-time UG enrollment (thousands, line)")
  ) +
  scale_x_continuous(breaks = seq(2011, 2021, 2)) +
  labs(
    title = "The NSC-to-University Pipeline",
    subtitle = "Bachelor's pass holders vs. first-time undergraduate enrollment",
    x = NULL,
    caption = "Source: DBE NSC Reports (bars) and DHET Statistics on PSET (line)"
  )

ggsave(file.path(fig_dir, "fig7_pipeline.pdf"), p7,
       width = 8, height = 5, dpi = 300)

# ==============================================================================
# FIGURE 8: Temporal Stability of Credential Returns
# ==============================================================================
cat("Figure 8: Temporal stability\n")

ts <- fread(file.path(data_dir, "temporal_stability.csv"))
ts <- ts %>% filter(!is.na(step_absorption))
ts$credential_short <- factor(ts$credential_short,
                               levels = c("HC Pass", "Diploma Pass",
                                           "Post-school Diploma", "University Degree"))

p8 <- ggplot(ts, aes(x = credential_short, y = step_absorption, fill = period)) +
  geom_col(position = "dodge", width = 0.7) +
  scale_fill_brewer(palette = "Set2", name = "Period") +
  scale_y_continuous(labels = function(x) paste0(x, " pp")) +
  labs(
    title = "Stability of Credential Steps Across Time Periods",
    subtitle = "Marginal increase in absorption rate for each credential step",
    x = "Credential level",
    y = "Step increase in absorption rate (pp)",
    caption = "Source: Stats SA QLFS (P0211) and DHET Post-School Education Monitor"
  ) +
  theme(axis.text.x = element_text(angle = 15, hjust = 1))

ggsave(file.path(fig_dir, "fig8_temporal_stability.pdf"), p8,
       width = 8, height = 5.5, dpi = 300)

# ==============================================================================
# FIGURE 9: COVID Impact — Differential Recovery by Credential
# ==============================================================================
cat("Figure 9: COVID impact\n")

p9 <- ggplot(pto, aes(x = year, y = absorption, color = credential_short)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  geom_vline(xintercept = 2019.5, linetype = "dashed", color = "gray50") +
  annotate("text", x = 2019.5, y = 75, label = "COVID", color = "gray50",
           hjust = -0.1, size = 3) +
  scale_color_manual(values = cred_colors, name = "Credential") +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(
    title = "COVID-19 Impact by Credential Type",
    subtitle = "Absorption rate trends showing differential impact and recovery",
    x = NULL,
    y = "Absorption rate (%)",
    caption = "Source: Stats SA QLFS (P0211) and DHET Post-School Education Monitor"
  )

ggsave(file.path(fig_dir, "fig9_covid_impact.pdf"), p9,
       width = 8, height = 5, dpi = 300)

# ==============================================================================
# Summary
# ==============================================================================
cat("\n=== Figure generation complete ===\n")
cat("Figures saved to:", fig_dir, "\n")
for (f in list.files(fig_dir, pattern = "\\.pdf$")) {
  cat("  ", f, "\n")
}
