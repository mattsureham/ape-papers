## ==========================================================================
## 05_figures.R — All Figures for Constitutional Carry Paper
## ==========================================================================

source("00_packages.R")
data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

## ==========================================================================
## LOAD DATA
## ==========================================================================

es_data <- fread(file.path(data_dir, "event_study_data.csv"))
bacon_data <- fread(file.path(data_dir, "bacon_decomposition.csv"))
ri_data <- fread(file.path(data_dir, "randomization_inference.csv"))
loo_data <- fread(file.path(data_dir, "leave_one_out.csv"))
dose_data <- fread(file.path(data_dir, "dose_response.csv"))
twfe_data <- fread(file.path(data_dir, "twfe_results.csv"))
cs_data <- fread(file.path(data_dir, "cs_results.csv"))
panel_a <- fread(file.path(data_dir, "panel_a_suicide.csv"))
panel_b <- fread(file.path(data_dir, "panel_b_firearm.csv"))
state_treat <- fread(file.path(data_dir, "state_treatment.csv"))

## Custom theme
theme_paper <- theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(size = 11, color = "grey30"),
        legend.position = "bottom",
        strip.text = element_text(face = "bold"))

## ==========================================================================
## FIGURE 1: Treatment Map / Adoption Timeline
## ==========================================================================

cat("=== Figure 1: Adoption Timeline ===\n")

adopt_data <- state_treat[first_treat > 0 & first_treat < 2024]
adopt_data[, n_states := .N, by = first_treat]

fig1 <- ggplot(adopt_data, aes(x = first_treat)) +
  geom_bar(fill = "#2166AC", alpha = 0.85, width = 0.7) +
  geom_text(stat = "count", aes(label = after_stat(count)),
            vjust = -0.5, size = 3.5, fontface = "bold") +
  scale_x_continuous(breaks = seq(2003, 2023, 2)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Staggered Adoption of Constitutional Carry Laws",
       subtitle = "Number of states adopting by year (excludes Vermont, always permitless)",
       x = "Year of Adoption",
       y = "Number of States") +
  theme_paper

ggsave(file.path(fig_dir, "fig1_adoption_timeline.pdf"), fig1,
       width = 8, height = 5)

## ==========================================================================
## FIGURE 2: Event Study — Suicide Rate (Panel A)
## ==========================================================================

cat("=== Figure 2: Event Study — Suicide ===\n")

es_suicide <- es_data[outcome == "Suicide Rate"]

fig2 <- ggplot(es_suicide, aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "red", alpha = 0.6) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), fill = "#2166AC", alpha = 0.2) +
  geom_line(color = "#2166AC", linewidth = 0.8) +
  geom_point(color = "#2166AC", size = 2.5) +
  scale_x_continuous(breaks = seq(-8, 8, 2)) +
  labs(title = "Effect of Constitutional Carry on Suicide Rate",
       subtitle = "Callaway-Sant'Anna event study, 1999-2017",
       x = "Years Relative to Adoption",
       y = "ATT (Deaths per 100,000)") +
  theme_paper

ggsave(file.path(fig_dir, "fig2_es_suicide.pdf"), fig2,
       width = 8, height = 5.5)

## ==========================================================================
## FIGURE 3: Multi-Outcome Event Study (Panel B)
## ==========================================================================

cat("=== Figure 3: Multi-Outcome Event Study ===\n")

es_panelb <- es_data[panel == "B" & outcome %in% c("FA Deaths", "FA Homicide",
                                                     "FA Suicide", "NF Homicide (placebo)",
                                                     "NF Suicide (placebo)")]

# Reorder for clarity
es_panelb[, outcome := factor(outcome, levels = c("FA Deaths", "FA Homicide", "FA Suicide",
                                                    "NF Homicide (placebo)", "NF Suicide (placebo)"))]

fig3 <- ggplot(es_panelb, aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "red", alpha = 0.6) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), fill = "#2166AC", alpha = 0.15) +
  geom_line(color = "#2166AC", linewidth = 0.6) +
  geom_point(color = "#2166AC", size = 1.8) +
  facet_wrap(~outcome, scales = "free_y", ncol = 3) +
  scale_x_continuous(breaks = seq(-3, 3, 1)) +
  labs(title = "Firearm-Specific Outcomes: Event Study (2019-2024)",
       subtitle = "Callaway-Sant'Anna ATT estimates; non-firearm outcomes as placebo",
       x = "Years Relative to Adoption",
       y = "ATT (per 100,000)") +
  theme_paper +
  theme(strip.text = element_text(size = 10))

ggsave(file.path(fig_dir, "fig3_es_multioutcome.pdf"), fig3,
       width = 10, height = 6)

## ==========================================================================
## FIGURE 4: NICS Background Checks Event Study
## ==========================================================================

cat("=== Figure 4: NICS Event Study ===\n")

es_nics <- es_data[outcome == "NICS per 100K"]

fig4 <- ggplot(es_nics, aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "red", alpha = 0.6) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), fill = "#B2182B", alpha = 0.2) +
  geom_line(color = "#B2182B", linewidth = 0.8) +
  geom_point(color = "#B2182B", size = 2.5) +
  scale_x_continuous(breaks = seq(-8, 8, 2)) +
  labs(title = "Effect of Constitutional Carry on Background Checks",
       subtitle = "NICS checks per 100,000 population, Callaway-Sant'Anna",
       x = "Years Relative to Adoption",
       y = "ATT (Checks per 100,000)") +
  theme_paper

ggsave(file.path(fig_dir, "fig4_es_nics.pdf"), fig4,
       width = 8, height = 5.5)

## ==========================================================================
## FIGURE 5: Bacon Decomposition
## ==========================================================================

cat("=== Figure 5: Bacon Decomposition ===\n")

fig5 <- ggplot(bacon_data, aes(x = weight, y = estimate, color = type)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_point(size = 3, alpha = 0.8) +
  scale_color_manual(values = c("Earlier vs Later Treated" = "#D6604D",
                                "Later vs Earlier Treated" = "#F4A582",
                                "Treated vs Untreated" = "#2166AC"),
                     name = "Comparison Type") +
  labs(title = "Goodman-Bacon Decomposition of TWFE Estimate",
       subtitle = "Suicide rate; clean treated-vs-untreated dominates (91% weight)",
       x = "Weight",
       y = "2×2 DD Estimate") +
  theme_paper +
  theme(legend.position = "right")

ggsave(file.path(fig_dir, "fig5_bacon.pdf"), fig5,
       width = 8, height = 5.5)

## ==========================================================================
## FIGURE 6: Randomization Inference
## ==========================================================================

cat("=== Figure 6: Randomization Inference ===\n")

obs_coef <- ri_data$obs_coef[1]
ri_pval <- ri_data$ri_pval[1]

fig6 <- ggplot(ri_data, aes(x = perm_coef)) +
  geom_histogram(bins = 40, fill = "grey70", color = "white", alpha = 0.8) +
  geom_vline(xintercept = obs_coef, color = "#B2182B", linewidth = 1.2, linetype = "solid") +
  geom_vline(xintercept = -obs_coef, color = "#B2182B", linewidth = 1.2, linetype = "dashed") +
  annotate("text", x = obs_coef + 0.1, y = Inf, vjust = 2, hjust = 0,
           label = paste0("Observed = ", round(obs_coef, 2)),
           color = "#B2182B", fontface = "bold", size = 4) +
  annotate("text", x = max(ri_data$perm_coef) * 0.6, y = Inf, vjust = 4,
           label = paste0("RI p-value = ", round(ri_pval, 3)),
           size = 4, fontface = "italic") +
  labs(title = "Randomization Inference: Constitutional Carry → Suicide",
       subtitle = "500 permutations of treatment assignment across states",
       x = "Permuted TWFE Coefficient",
       y = "Count") +
  theme_paper

ggsave(file.path(fig_dir, "fig6_ri.pdf"), fig6,
       width = 8, height = 5)

## ==========================================================================
## FIGURE 7: Leave-One-Cohort-Out
## ==========================================================================

cat("=== Figure 7: Leave-One-Out ===\n")

loo_data[, ci_lower := coef - 1.96 * se]
loo_data[, ci_upper := coef + 1.96 * se]

fig7 <- ggplot(loo_data, aes(x = factor(dropped_cohort), y = coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_hline(yintercept = 1.44, linetype = "dotted", color = "#2166AC", alpha = 0.6) +
  geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper),
                  color = "#2166AC", size = 0.6) +
  annotate("text", x = 0.5, y = 1.44, label = "Full sample", vjust = -0.5,
           color = "#2166AC", size = 3, fontface = "italic", hjust = 0) +
  labs(title = "Sensitivity: Dropping Each Treatment Cohort",
       subtitle = "TWFE coefficient on suicide rate; no cohort drives the result",
       x = "Dropped Cohort Year",
       y = "TWFE Coefficient") +
  theme_paper

ggsave(file.path(fig_dir, "fig7_loo.pdf"), fig7,
       width = 8, height = 5)

## ==========================================================================
## FIGURE 8: Dose-Response
## ==========================================================================

cat("=== Figure 8: Dose-Response ===\n")

dose_data[, ci_lower := Estimate - 1.96 * `Std. Error`]
dose_data[, ci_upper := Estimate + 1.96 * `Std. Error`]
dose_data[, dose := factor(dose, levels = c("Year 0", "Years 1-2", "Years 3-4", "Years 5+"))]

fig8 <- ggplot(dose_data, aes(x = dose, y = Estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper),
                  color = "#2166AC", size = 0.7) +
  labs(title = "Dose-Response: Years Since Constitutional Carry Adoption",
       subtitle = "Effect on suicide rate by time since policy change",
       x = "Time Since Adoption",
       y = "Coefficient (per 100,000)") +
  theme_paper

ggsave(file.path(fig_dir, "fig8_dose.pdf"), fig8,
       width = 7, height = 5)

## ==========================================================================
## FIGURE 9: Comparison Across Estimators
## ==========================================================================

cat("=== Figure 9: Estimator Comparison ===\n")

# Re-estimate key models to extract coefficients and SEs programmatically
panel_a[, state_id := as.integer(as.factor(state))]
fig_twfe <- feols(suicide_rate ~ treated | state_id + year,
                  data = panel_a, cluster = ~state_id)
fig_twfe_cov <- feols(suicide_rate ~ treated + poverty_rate + pct_black + log_pop +
                        median_income | state_id + year,
                      data = panel_a, cluster = ~state_id)
fig_sa <- feols(suicide_rate ~ sunab(first_treat, year) | state_id + year,
                data = panel_a[first_treat != 0 | ever_treated == FALSE],
                cluster = ~state_id)
fig_sa_att <- summary(fig_sa, agg = "ATT")$coeftable
fig_early <- feols(suicide_rate ~ treated | state_id + year,
                   data = panel_a[!first_treat %in% c(2019, 2021, 2022, 2023) | first_treat == 0],
                   cluster = ~state_id)

compare_data <- data.table(
  estimator = c("TWFE", "TWFE + Covariates", "Sun-Abraham IW",
                "CS-DiD", "Early Adopters Only"),
  coef = c(coef(fig_twfe)[["treated"]], coef(fig_twfe_cov)[["treated"]],
           fig_sa_att["ATT", 1],
           cs_data[outcome == "Suicide Rate" & panel == "A"]$coef[1],
           coef(fig_early)[["treated"]]),
  se = c(se(fig_twfe)[["treated"]], se(fig_twfe_cov)[["treated"]],
         fig_sa_att["ATT", 2],
         cs_data[outcome == "Suicide Rate" & panel == "A"]$se[1],
         se(fig_early)[["treated"]])
)

compare_data <- compare_data[!is.na(coef)]
compare_data[, ci_lower := coef - 1.96 * se]
compare_data[, ci_upper := coef + 1.96 * se]
compare_data[, estimator := factor(estimator, levels = rev(compare_data$estimator))]

fig9 <- ggplot(compare_data, aes(x = coef, y = estimator)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(xmin = ci_lower, xmax = ci_upper),
                  color = "#2166AC", size = 0.7) +
  labs(title = "Robustness: Constitutional Carry Effect on Suicide Rate",
       subtitle = "Point estimates and 95% CIs across estimators",
       x = "Effect on Suicide Rate (per 100,000)",
       y = NULL) +
  theme_paper +
  theme(axis.text.y = element_text(size = 11))

ggsave(file.path(fig_dir, "fig9_comparison.pdf"), fig9,
       width = 8, height = 4.5)

## ==========================================================================
## FIGURE 10: Placebo Comparison
## ==========================================================================

cat("=== Figure 10: Placebo Outcomes ===\n")

placebo_data <- twfe_data[grepl("placebo|Suicide Rate$|FA Suicide|FA Homicide|FA Deaths",
                                outcome, ignore.case = TRUE)]
placebo_data[, ci_lower := coef - 1.96 * se]
placebo_data[, ci_upper := coef + 1.96 * se]
placebo_data[, is_primary := !grepl("placebo", outcome, ignore.case = TRUE)]
placebo_data[, outcome_label := gsub(" \\(placebo\\)", "", outcome)]
placebo_data[, outcome_label := factor(outcome_label, levels = rev(outcome_label))]

fig10 <- ggplot(placebo_data, aes(x = coef, y = outcome_label, color = is_primary)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(xmin = ci_lower, xmax = ci_upper), size = 0.6) +
  scale_color_manual(values = c("TRUE" = "#2166AC", "FALSE" = "#999999"),
                     labels = c("TRUE" = "Primary", "FALSE" = "Placebo"),
                     name = NULL) +
  labs(title = "Primary vs. Placebo Outcomes (TWFE)",
       subtitle = "Constitutional carry effect; placebos should center on zero",
       x = "TWFE Coefficient",
       y = NULL) +
  theme_paper +
  theme(axis.text.y = element_text(size = 10))

ggsave(file.path(fig_dir, "fig10_placebo.pdf"), fig10,
       width = 9, height = 5.5)

## ==========================================================================
## FIGURE 11: Pre-Trends (Parallel Trends Visualization)
## ==========================================================================

cat("=== Figure 11: Pre-Trends ===\n")

# Average suicide rate by treatment status over time
trends_a <- panel_a[, .(mean_suicide = mean(suicide_rate, na.rm = TRUE),
                        mean_uninj = mean(uninj_rate, na.rm = TRUE)),
                    by = .(year, ever_treated)]
trends_a[, group := ifelse(ever_treated, "Treated States", "Control States")]

fig11 <- ggplot(trends_a, aes(x = year, y = mean_suicide, color = group, linetype = group)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_color_manual(values = c("Control States" = "#999999",
                                "Treated States" = "#2166AC"),
                     name = NULL) +
  scale_linetype_manual(values = c("Control States" = "dashed",
                                    "Treated States" = "solid"),
                        name = NULL) +
  labs(title = "Suicide Rates: Treated vs. Control States (1999-2017)",
       subtitle = "Pre-adoption trends should be parallel",
       x = "Year",
       y = "Age-Adjusted Suicide Rate (per 100,000)") +
  theme_paper

ggsave(file.path(fig_dir, "fig11_pretrends.pdf"), fig11,
       width = 8, height = 5.5)

cat("\n=== All figures saved to", fig_dir, "===\n")
