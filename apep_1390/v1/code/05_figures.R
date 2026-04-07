# ==============================================================================
# 05_figures.R — Generate all figures
# ==============================================================================

source("00_packages.R")

load("../data/main_results.RData")
load("../data/robustness_results.RData")

df <- arrow::read_parquet("../data/analysis_sample.parquet")
setDT(df)

# APEP theme
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10, color = "gray30"),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )

# --------------------------------------------------------------------------
# Figure 1: Event Study — Wage Income
# --------------------------------------------------------------------------

cat("Figure 1: Event study (wages)...\n")

# Parse coefficients from the event study
es_coefs <- data.table(
  year = as.integer(gsub(".*::(\\d+):.*", "\\1", names(coef(es_wage)))),
  est = as.numeric(coef(es_wage)),
  se = as.numeric(se(es_wage))
)
es_coefs[, `:=`(ci_lo = est - 1.96 * se, ci_hi = est + 1.96 * se)]
# Add reference year
es_coefs <- rbind(es_coefs, data.table(year = 1921L, est = 0, se = 0, ci_lo = 0, ci_hi = 0))
es_coefs <- es_coefs[order(year)]

p1_gg <- ggplot(es_coefs, aes(x = year, y = est)) +
  geom_hline(yintercept = 0, color = "gray50") +
  geom_vline(xintercept = 1921.5, linetype = "dashed", color = "firebrick", alpha = 0.7) +
  geom_vline(xintercept = 1928.5, linetype = "dashed", color = "firebrick", alpha = 0.7) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "steelblue", alpha = 0.2) +
  geom_point(color = "steelblue", size = 2) +
  geom_line(color = "steelblue", linewidth = 0.7) +
  annotate("text", x = 1925, y = max(es_coefs$ci_hi, na.rm = TRUE) * 0.9,
           label = "Sheppard-Towner\n(1922-1928)", size = 3.5, color = "firebrick") +
  labs(x = "Birth Year", y = "DDD Coefficient ($1950)",
       title = "Event Study: Sheppard-Towner Exposure and Adult Wage Income",
       subtitle = "Participant × Birth-Year interactions, ref. year = 1921") +
  theme_apep

ggsave("../figures/fig1_event_study_wages.png", p1_gg, width = 8, height = 5.5, dpi = 300)

# --------------------------------------------------------------------------
# Figure 2: Event Study — Education
# --------------------------------------------------------------------------

cat("Figure 2: Event study (education)...\n")

es_educ_coefs <- data.table(
  year = as.integer(gsub(".*::(\\d+):.*", "\\1", names(coef(es_educ)))),
  est = as.numeric(coef(es_educ)),
  se = as.numeric(se(es_educ))
)
es_educ_coefs[, `:=`(ci_lo = est - 1.96 * se, ci_hi = est + 1.96 * se)]
es_educ_coefs <- rbind(es_educ_coefs, data.table(year = 1921L, est = 0, se = 0, ci_lo = 0, ci_hi = 0))
es_educ_coefs <- es_educ_coefs[order(year)]

p2 <- ggplot(es_educ_coefs, aes(x = year, y = est)) +
  geom_hline(yintercept = 0, color = "gray50") +
  geom_vline(xintercept = 1921.5, linetype = "dashed", color = "firebrick", alpha = 0.7) +
  geom_vline(xintercept = 1928.5, linetype = "dashed", color = "firebrick", alpha = 0.7) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "darkgreen", alpha = 0.2) +
  geom_point(color = "darkgreen", size = 2) +
  geom_line(color = "darkgreen", linewidth = 0.7) +
  annotate("text", x = 1925, y = max(es_educ_coefs$ci_hi, na.rm = TRUE) * 0.9,
           label = "Sheppard-Towner\n(1922-1928)", size = 3.5, color = "firebrick") +
  labs(x = "Birth Year", y = "DDD Coefficient (Years of Schooling)",
       title = "Event Study: Sheppard-Towner Exposure and Educational Attainment",
       subtitle = "Participant × Birth-Year interactions, ref. year = 1921") +
  theme_apep

ggsave("../figures/fig2_event_study_education.png", p2, width = 8, height = 5.5, dpi = 300)

# --------------------------------------------------------------------------
# Figure 3: Cohort means by treatment group
# --------------------------------------------------------------------------

cat("Figure 3: Cohort trends...\n")

cohort_means <- df[birthyr >= 1912 & birthyr <= 1932 & !is.na(incwage_1950),
                   .(mean_wage = mean(incwage_1950, na.rm = TRUE),
                     se_wage = sd(incwage_1950, na.rm = TRUE) / sqrt(.N),
                     n = .N),
                   by = .(birthyr, participant)]

cohort_means[, group := fifelse(participant == 1, "Participating States", "Non-Participating (MA, CT, IL)")]

p3 <- ggplot(cohort_means, aes(x = birthyr, y = mean_wage, color = group, shape = group)) +
  geom_vline(xintercept = 1921.5, linetype = "dashed", color = "firebrick", alpha = 0.5) +
  geom_vline(xintercept = 1928.5, linetype = "dashed", color = "firebrick", alpha = 0.5) +
  annotate("rect", xmin = 1921.5, xmax = 1928.5, ymin = -Inf, ymax = Inf,
           fill = "firebrick", alpha = 0.05) +
  geom_point(size = 2.5) +
  geom_line(linewidth = 0.7) +
  scale_color_manual(values = c("Participating States" = "steelblue",
                                 "Non-Participating (MA, CT, IL)" = "coral")) +
  labs(x = "Birth Year", y = "Mean Wage Income ($1950)",
       title = "Average Wage Income by Birth Cohort and Sheppard-Towner Participation",
       subtitle = "Shaded region = birth cohorts exposed to the Act (1922-1928)",
       color = NULL, shape = NULL) +
  theme_apep

ggsave("../figures/fig3_cohort_trends.png", p3, width = 8, height = 5.5, dpi = 300)

# --------------------------------------------------------------------------
# Figure 4: Heterogeneity — Race and Sex
# --------------------------------------------------------------------------

cat("Figure 4: Heterogeneity coefficients...\n")

load("../data/robustness_results.RData")
load("../data/main_results.RData")

het_coefs <- data.table(
  group = c("Pooled", "White", "Black", "Male", "Female", "Rural-born", "Urban-born"),
  est = c(coef(m2)["ddd"], coef(m_white)["ddd"], coef(m_black)["ddd"],
          coef(m_male)["ddd"], coef(m_female)["ddd"],
          coef(m_rural)["ddd"], coef(m_urban)["ddd"]),
  se = c(se(m2)["ddd"], se(m_white)["ddd"], se(m_black)["ddd"],
         se(m_male)["ddd"], se(m_female)["ddd"],
         se(m_rural)["ddd"], se(m_urban)["ddd"])
)
het_coefs[, `:=`(ci_lo = est - 1.96 * se, ci_hi = est + 1.96 * se)]
het_coefs[, group := factor(group, levels = rev(group))]

p4 <- ggplot(het_coefs, aes(x = est, y = group)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  geom_errorbarh(aes(xmin = ci_lo, xmax = ci_hi), height = 0.2, color = "steelblue") +
  geom_point(size = 3, color = "steelblue") +
  labs(x = "DDD Coefficient (Wage Income, $1950)", y = NULL,
       title = "Heterogeneous Effects of Sheppard-Towner Exposure",
       subtitle = "Point estimates and 95% CIs from separate regressions") +
  theme_apep

ggsave("../figures/fig4_heterogeneity.png", p4, width = 8, height = 5, dpi = 300)

# --------------------------------------------------------------------------
# Figure 5: Distribution of wages by treatment status
# --------------------------------------------------------------------------

cat("Figure 5: Wage distributions...\n")

dist_df <- df[cohort_group == "exposed" & !is.na(incwage_1950) & incwage_1950 < 15000]
dist_df[, group := fifelse(participant == 1, "Participating States", "Non-Participating")]

p5 <- ggplot(dist_df, aes(x = incwage_1950, fill = group)) +
  geom_density(alpha = 0.5, color = NA) +
  scale_fill_manual(values = c("Participating States" = "steelblue",
                                "Non-Participating" = "coral")) +
  labs(x = "Wage Income ($1950)", y = "Density",
       title = "Distribution of Adult Wages: Exposed Cohorts (Born 1922-1928)",
       subtitle = "Participating vs. non-participating states",
       fill = NULL) +
  theme_apep

ggsave("../figures/fig5_wage_distributions.png", p5, width = 8, height = 5, dpi = 300)

# --------------------------------------------------------------------------
# Figure 6: Education distributions
# --------------------------------------------------------------------------

cat("Figure 6: Education distributions...\n")

educ_df <- df[cohort_group == "exposed" & !is.na(educ_years)]
educ_df[, group := fifelse(participant == 1, "Participating States", "Non-Participating")]

educ_dist <- educ_df[, .(pct = .N), by = .(educ_years, group)]
educ_dist[, pct := pct / sum(pct) * 100, by = group]

p6 <- ggplot(educ_dist, aes(x = educ_years, y = pct, fill = group)) +
  geom_col(position = "dodge", alpha = 0.8) +
  scale_fill_manual(values = c("Participating States" = "steelblue",
                                "Non-Participating" = "coral")) +
  labs(x = "Years of Schooling", y = "Percent",
       title = "Educational Attainment: Exposed Cohorts (Born 1922-1928)",
       subtitle = "Participating vs. non-participating states",
       fill = NULL) +
  theme_apep

ggsave("../figures/fig6_education_distribution.png", p6, width = 8, height = 5, dpi = 300)

# --------------------------------------------------------------------------
# Figure 7: Robustness — Placebo and border-state
# --------------------------------------------------------------------------

cat("Figure 7: Robustness summary...\n")

robust_coefs <- data.table(
  spec = c("Main DDD", "Border States", "Placebo (pre-treatment)", "Post-Repeal Cohorts"),
  est = c(coef(m2)["ddd"], coef(border_m)["ddd"],
          coef(placebo_m)["fake_ddd"], coef(m_post)["post_ddd"]),
  se = c(se(m2)["ddd"], se(border_m)["ddd"],
         se(placebo_m)["fake_ddd"], se(m_post)["post_ddd"])
)
robust_coefs[, `:=`(ci_lo = est - 1.96 * se, ci_hi = est + 1.96 * se)]
robust_coefs[, spec := factor(spec, levels = rev(spec))]

p7 <- ggplot(robust_coefs, aes(x = est, y = spec)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  geom_errorbarh(aes(xmin = ci_lo, xmax = ci_hi), height = 0.2, color = "darkred") +
  geom_point(size = 3, color = "darkred") +
  labs(x = "DDD Coefficient (Wage Income, $1950)", y = NULL,
       title = "Robustness of Sheppard-Towner Effects",
       subtitle = "Placebo and post-repeal should be near zero; border states should be positive") +
  theme_apep

ggsave("../figures/fig7_robustness.png", p7, width = 8, height = 4.5, dpi = 300)

cat("All figures saved.\n")
