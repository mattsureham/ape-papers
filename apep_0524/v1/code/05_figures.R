## ============================================================
## 05_figures.R — Generate all figures
## ============================================================

source("00_packages.R")
library(patchwork)

DATA_DIR <- "../data"
FIG_DIR <- "../figures"
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)

## Load saved data
rollout_data <- fread(file.path(DATA_DIR, "rollout_data.csv"))
cohort_trends <- fread(file.path(DATA_DIR, "cohort_trends.csv"))
es_emp_df <- fread(file.path(DATA_DIR, "es_employment_gap.csv"))
es_earn_df <- fread(file.path(DATA_DIR, "es_earnings_gap.csv"))
es_prof_df <- fread(file.path(DATA_DIR, "es_professional_gap.csv"))
es_cust_df <- fread(file.path(DATA_DIR, "es_customer_facing_gap.csv"))
ri_dist <- fread(file.path(DATA_DIR, "ri_distribution.csv"))
ri_results <- fread(file.path(DATA_DIR, "ri_results.csv"))
bacon_data <- fread(file.path(DATA_DIR, "bacon_decomposition.csv"))
sex_results <- fread(file.path(DATA_DIR, "sex_heterogeneity.csv"))

## ============================================================
## FIGURE 1: CROWN Act Adoption Timeline
## ============================================================

fig1 <- ggplot(rollout_data, aes(x = crown_year)) +
  geom_bar(fill = "#2C3E50", alpha = 0.85) +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.5, size = 3.5) +
  scale_x_continuous(breaks = 2019:2024) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "CROWN Act Adoption Across U.S. States",
       subtitle = "Number of states enacting hair discrimination bans by year",
       x = "Year of Enactment", y = "Number of States",
       caption = "Source: State legislative records") +
  theme_apep()

ggsave(file.path(FIG_DIR, "fig1_adoption_timeline.pdf"), fig1, width = 7, height = 4.5)

## ============================================================
## FIGURE 2: Raw Cohort Trends
## ============================================================

cohort_colors <- c("Early (2019-2020)" = "#E74C3C", "Middle (2021-2022)" = "#F39C12",
                    "Late (2023-2024)" = "#3498DB", "Never treated" = "#2C3E50")

fig2 <- ggplot(cohort_trends, aes(x = year, y = emp_gap, color = cohort_group)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_vline(xintercept = 2019.5, linetype = "dashed", color = "grey50") +
  scale_color_manual(values = cohort_colors) +
  labs(title = "Black-White Employment Gap by CROWN Act Adoption Cohort",
       x = "Year", y = "Employment Rate Gap (Black - White)",
       color = "Adoption Cohort",
       caption = "Source: ACS 1-Year (2015-2023). 2020 omitted (ACS not released).") +
  theme_apep()

ggsave(file.path(FIG_DIR, "fig2_cohort_trends.pdf"), fig2, width = 8, height = 5.5)

## ============================================================
## FIGURE 3: Event Studies (2x2 Panel)
## ============================================================

plot_es <- function(df, title, ylab) {
  ggplot(df, aes(x = event_time, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey70") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "#3498DB") +
    geom_line(color = "#2C3E50", linewidth = 0.7) +
    geom_point(color = "#2C3E50", size = 2.5) +
    labs(title = title, x = "Years Since CROWN Act", y = ylab) +
    theme_apep()
}

fig3 <- (plot_es(es_emp_df, "A. Employment Gap", "ATT (pp)") +
         plot_es(es_earn_df, "B. Earnings Gap", "ATT (log pts)")) /
  (plot_es(es_prof_df, "C. Professional Occ. Share Gap", "ATT (pp)") +
   plot_es(es_cust_df, "D. Customer-Facing Occ. Share Gap", "ATT (pp)")) +
  plot_annotation(
    title = "Event Study: CROWN Act Effects on Black-White Labor Market Gaps",
    subtitle = "Callaway-Sant'Anna doubly robust ATTs, never-treated control",
    caption = "Source: ACS 1-Year PUMS (2015-2023). 95% CIs. 2020 omitted.",
    theme = theme(plot.title = element_text(face = "bold", size = 14))
  )

ggsave(file.path(FIG_DIR, "fig3_event_studies.pdf"), fig3, width = 10, height = 8)

## ============================================================
## FIGURE 4: Sex Heterogeneity
## ============================================================

## Load female and male event studies
es_fem <- fread(file.path(DATA_DIR, "es_female_employment_gap.csv"))
es_mal <- fread(file.path(DATA_DIR, "es_male_employment_gap.csv"))

es_fem$sex <- "Women"
es_mal$sex <- "Men"
es_sex <- bind_rows(es_fem, es_mal)

fig4 <- ggplot(es_sex, aes(x = event_time, y = estimate, color = sex, fill = sex)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey70") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 2) +
  scale_color_manual(values = c("Women" = "#E74C3C", "Men" = "#3498DB")) +
  scale_fill_manual(values = c("Women" = "#E74C3C", "Men" = "#3498DB")) +
  labs(title = "CROWN Act Effects on Employment Gap by Sex",
       subtitle = "CS-DiD event study: Black-White employment gap",
       x = "Years Since CROWN Act", y = "ATT (pp)",
       color = "Subsample", fill = "Subsample",
       caption = "Source: ACS 1-Year (2015-2023). 95% CIs.") +
  theme_apep()

ggsave(file.path(FIG_DIR, "fig4_sex_heterogeneity.pdf"), fig4, width = 8, height = 5.5)

## ============================================================
## FIGURE 5: Randomization Inference
## ============================================================

fig5 <- ggplot(ri_dist, aes(x = att)) +
  geom_histogram(bins = 40, fill = "#BDC3C7", color = "white") +
  geom_vline(xintercept = ri_results$actual_att[1], color = "#E74C3C", linewidth = 1) +
  annotate("text", x = ri_results$actual_att[1], y = Inf,
           label = paste0("Actual = ", round(ri_results$actual_att[1], 4),
                          "\nRI p = ", round(ri_results$ri_pvalue[1], 3)),
           hjust = -0.1, vjust = 1.5, color = "#E74C3C", size = 3.5) +
  labs(title = "Randomization Inference: Employment Gap",
       subtitle = paste0(nrow(ri_dist), " permutations of CROWN Act assignment"),
       x = "Placebo ATT", y = "Frequency") +
  theme_apep()

ggsave(file.path(FIG_DIR, "fig5_randomization_inference.pdf"), fig5, width = 7, height = 5)

## ============================================================
## FIGURE 6: Bacon Decomposition
## ============================================================

fig6 <- ggplot(bacon_data, aes(x = weight, y = estimate, color = type)) +
  geom_point(size = 2.5, alpha = 0.7) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  scale_color_brewer(palette = "Set1") +
  labs(title = "Bacon Decomposition: Employment Gap",
       x = "Weight", y = "2x2 DiD Estimate", color = "Comparison Type") +
  theme_apep() +
  theme(legend.position = "bottom")

ggsave(file.path(FIG_DIR, "fig6_bacon_decomposition.pdf"), fig6, width = 8, height = 5.5)

cat("=== ALL FIGURES GENERATED ===\n")
list.files(FIG_DIR, pattern = "\\.pdf$") %>% cat(sep = "\n")
