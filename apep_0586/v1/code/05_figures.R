# ==============================================================================
# 05_figures.R — All figure generation
# apep_0586: Winning the Peace
# ==============================================================================

source("00_packages.R")

# Load data from CSVs (data-first rule)
df <- fread("../data/analysis_sample.csv")
main_results <- fread("../data/main_results.csv")
pretrend_results <- fread("../data/pretrend_results.csv")
het_occ <- fread("../data/heterogeneity_occupation.csv")
loo_dt <- fread("../data/leave_one_out.csv")
ri_dist <- fread("../data/ri_distribution.csv")
ri_results <- fread("../data/ri_results.csv")
robustness_summary <- fread("../data/robustness_summary.csv")

# ==============================================================================
# Figure 1: Occupational Score Trajectories by Cohort (1930-1940-1950)
# ==============================================================================

# Compute cohort-year means
traj_data <- rbind(
  df[, .(mean_occ = mean(occscore_1930, na.rm = TRUE),
         se_occ = sd(occscore_1930, na.rm = TRUE) / sqrt(.N)),
     by = .(cohort_group)][, year := 1930],
  df[, .(mean_occ = mean(occscore_1940, na.rm = TRUE),
         se_occ = sd(occscore_1940, na.rm = TRUE) / sqrt(.N)),
     by = .(cohort_group)][, year := 1940],
  df[, .(mean_occ = mean(occscore_1950, na.rm = TRUE),
         se_occ = sd(occscore_1950, na.rm = TRUE) / sqrt(.N)),
     by = .(cohort_group)][, year := 1950]
)

# Clean labels
traj_data[, cohort_label := fcase(
  cohort_group == "draft_eligible", "Draft-Eligible (born 1915-1922)",
  cohort_group == "older_control", "Older Control (born 1905-1914)",
  cohort_group == "age_placebo", "Age Placebo (born 1895-1904)"
)]

fwrite(traj_data, "../data/fig1_trajectories.csv")

p1 <- ggplot(traj_data, aes(x = year, y = mean_occ,
                              color = cohort_label, shape = cohort_label)) +
  geom_line(linewidth = 1) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = mean_occ - 1.96 * se_occ,
                     ymax = mean_occ + 1.96 * se_occ),
                width = 1, linewidth = 0.5) +
  geom_vline(xintercept = 1941, linetype = "dashed", color = "grey50", linewidth = 0.5) +
  annotate("text", x = 1941.5, y = max(traj_data$mean_occ) * 0.95,
           label = "WWII\nBegins", hjust = 0, size = 3, color = "grey40") +
  scale_color_manual(values = apep_colors[1:3]) +
  scale_x_continuous(breaks = c(1930, 1940, 1950)) +
  labs(x = "Census Year", y = "Mean Occupational Income Score",
       color = NULL, shape = NULL,
       title = "Occupational Trajectories Across Three Census Decades") +
  theme_apep() +
  theme(legend.position = "bottom")

ggsave("../figures/fig1_occ_trajectories.pdf", p1, width = 8, height = 5.5)
cat("Figure 1 saved.\n")

# ==============================================================================
# Figure 2: Mobilization Exposure Map (state-level ag share)
# ==============================================================================

state_ag <- fread("../data/state_instrument.csv")

# Bar chart of mobilization exposure by state (simpler, more informative)
# Get state names
state_names <- data.table(
  statefip_1940 = c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,24,
                     25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,
                     45,46,47,48,49,50,51,53,54,55,56),
  state_name = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI",
                  "ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN",
                  "MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH",
                  "OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA",
                  "WV","WI","WY")
)

state_plot <- merge(state_ag, state_names, by = "statefip_1940")
state_plot <- state_plot[order(ag_share)]
state_plot[, state_name := factor(state_name, levels = state_name)]

fwrite(state_plot[, .(state_name, ag_share, mob_exposure, mob_exposure_std)],
       "../data/fig2_state_instrument.csv")

p2 <- ggplot(state_plot, aes(x = state_name, y = ag_share)) +
  geom_bar(stat = "identity", fill = apep_colors[1], alpha = 0.7) +
  geom_hline(yintercept = mean(state_plot$ag_share), linetype = "dashed",
             color = apep_colors[2]) +
  coord_flip() +
  labs(x = NULL, y = "Agricultural Employment Share (Men 18-44, 1940)",
       title = "Cross-State Variation in Agricultural Employment") +
  theme_apep() +
  theme(axis.text.y = element_text(size = 7))

ggsave("../figures/fig2_state_ag_share.pdf", p2, width = 7, height = 9)
cat("Figure 2 saved.\n")

# ==============================================================================
# Figure 3: Cohort-by-Cohort Coefficients (Event Study Style)
# ==============================================================================

# Run separate regression for each birth-year cohort
df_cohort <- df[cohort_group %in% c("draft_eligible", "older_control")]
df_cohort[, statefip_1940 := as.factor(statefip_1940)]

cohort_coefs <- list()
birth_years <- sort(unique(as.numeric(as.character(df_cohort$birth_year))))

for (by in birth_years) {
  sub <- df_cohort[as.numeric(as.character(birth_year)) == by]
  if (nrow(sub) > 10000) {
    fit <- feols(delta_occscore_40_50 ~ mob_exposure_std + educ_years_1940 +
                   occscore_1940 + white + married_1940 + farm_1940_d + native_born |
                   statefip_1940,
                 data = sub, cluster = ~statefip_1940)
    cohort_coefs[[as.character(by)]] <- data.table(
      birth_year = by,
      coef = coef(fit)["mob_exposure_std"],
      se = se(fit)["mob_exposure_std"],
      n = fit$nobs
    )
  }
}

cohort_dt <- rbindlist(cohort_coefs)
cohort_dt[, draft_eligible := as.integer(birth_year >= 1915)]

fwrite(cohort_dt, "../data/fig3_cohort_coefs.csv")

p3 <- ggplot(cohort_dt, aes(x = birth_year, y = coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = 1914.5, linetype = "dotted", color = "grey60") +
  geom_ribbon(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
              alpha = 0.15, fill = apep_colors[1]) +
  geom_point(aes(color = factor(draft_eligible)), size = 2.5) +
  geom_line(color = apep_colors[1], linewidth = 0.7) +
  scale_color_manual(values = c(apep_colors[2], apep_colors[1]),
                     labels = c("Older Control", "Draft-Eligible")) +
  annotate("text", x = 1914.5, y = max(cohort_dt$coef + 1.96 * cohort_dt$se),
           label = "Draft-Eligibility\nThreshold", hjust = 1.1, size = 3, color = "grey40") +
  labs(x = "Birth Year", y = "Effect of Mobilization Exposure\non \u0394OccScore (1940-1950)",
       color = NULL,
       title = "Cohort-Specific Effects of Mobilization Exposure") +
  theme_apep()

ggsave("../figures/fig3_cohort_effects.pdf", p3, width = 8, height = 5)
cat("Figure 3 saved.\n")

# ==============================================================================
# Figure 4: Heterogeneity by Pre-War Occupation Quintile
# ==============================================================================

het_occ[, quintile_label := paste0(quintile, "\n(Mean OccScore: ",
                                    round(mean_occscore_1940, 0), ")")]
het_occ[, quintile_label := factor(quintile_label,
                                    levels = het_occ$quintile_label)]

fwrite(het_occ, "../data/fig4_het_occupation.csv")

p4 <- ggplot(het_occ, aes(x = quintile_label, y = coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_point(size = 3, color = apep_colors[1]) +
  geom_errorbar(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
                width = 0.2, color = apep_colors[1], linewidth = 0.7) +
  labs(x = "Pre-War Occupation Quintile (1940)",
       y = "Effect of Mobilization Exposure\non \u0394OccScore (1940-1950)",
       title = "Who Gained Most? Effects by Pre-War Occupational Status") +
  theme_apep()

ggsave("../figures/fig4_het_occupation.pdf", p4, width = 7, height = 5)
cat("Figure 4 saved.\n")

# ==============================================================================
# Figure 5: Leave-One-Out Sensitivity
# ==============================================================================

base_coef <- robustness_summary[test == "Main estimate"]$coef

loo_dt <- loo_dt[order(coef)]
loo_dt[, idx := 1:.N]

fwrite(loo_dt, "../data/fig5_loo.csv")

p5 <- ggplot(loo_dt, aes(x = idx, y = coef)) +
  geom_hline(yintercept = base_coef, linetype = "dashed", color = apep_colors[2]) +
  geom_hline(yintercept = 0, linetype = "solid", color = "grey70") +
  geom_point(size = 1.5, color = apep_colors[1]) +
  geom_errorbar(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
                width = 0, linewidth = 0.3, color = apep_colors[1], alpha = 0.5) +
  labs(x = "Iteration (one state dropped per estimate)",
       y = "Coefficient on Mob. Exposure \u00D7 Draft Eligible",
       title = "Leave-One-Out State Sensitivity") +
  theme_apep()

ggsave("../figures/fig5_leave_one_out.pdf", p5, width = 7, height = 5)
cat("Figure 5 saved.\n")

# ==============================================================================
# Figure 6: Randomization Inference Distribution
# ==============================================================================

p6 <- ggplot(ri_dist, aes(x = perm_t)) +
  geom_histogram(bins = 50, fill = "grey70", color = "white") +
  geom_vline(xintercept = ri_results$actual_t, color = apep_colors[2],
             linewidth = 1, linetype = "solid") +
  geom_vline(xintercept = -ri_results$actual_t, color = apep_colors[2],
             linewidth = 1, linetype = "dashed") +
  annotate("text", x = ri_results$actual_t * 1.05, y = Inf,
           label = paste("Actual t =", round(ri_results$actual_t, 2)),
           hjust = 0, vjust = 2, size = 3.5, color = apep_colors[2]) +
  annotate("text", x = max(ri_dist$perm_t) * 0.7, y = Inf,
           label = paste("RI p-value =", round(ri_results$ri_pval, 3)),
           hjust = 0, vjust = 4, size = 3.5) +
  labs(x = "Permuted t-statistics", y = "Frequency",
       title = "Randomization Inference: Permuting Mobilization Across States") +
  theme_apep()

ggsave("../figures/fig6_randomization_inference.pdf", p6, width = 7, height = 5)
cat("Figure 6 saved.\n")

# ==============================================================================
# Figure 7: Pre-Trend and Post-Treatment Comparison (Key Novelty Figure)
# ==============================================================================

# Combine pre-trend and post-treatment coefficients
compare_dt <- data.table(
  period = c("1930-1940\n(Pre-Trend)", "1940-1950\n(Post-Treatment)"),
  coef = c(pretrend_results[spec == "pretrend_controls"]$coef,
           main_results[spec == "controls"]$coef),
  se = c(pretrend_results[spec == "pretrend_controls"]$se,
         main_results[spec == "controls"]$se)
)
compare_dt[, period := factor(period, levels = period)]

fwrite(compare_dt, "../data/fig7_pretrend_comparison.csv")

p7 <- ggplot(compare_dt, aes(x = period, y = coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_point(size = 4, color = apep_colors[1]) +
  geom_errorbar(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se),
                width = 0.15, color = apep_colors[1], linewidth = 0.8) +
  labs(x = NULL,
       y = "Effect of Mobilization Exposure \u00D7 Draft Eligible\non \u0394OccScore",
       title = "The 1930 Pre-Baseline: No Pre-Trend, Clear Post-Treatment Effect") +
  theme_apep() +
  theme(axis.text.x = element_text(size = 11))

ggsave("../figures/fig7_pretrend_vs_post.pdf", p7, width = 6, height = 5)
cat("Figure 7 saved.\n")

cat("\nAll figures generated.\n")
