# ==============================================================================
# 05_figures.R — All figure generation
# Paper: State Prohibition and Labor Market Restructuring (apep_0592)
# ==============================================================================

source("00_packages.R")

# Load pre-computed results from CSV (data-first rule)
county_alc <- fread("../data/county_alcohol_shares.csv")
prohib <- fread("../data/prohibition_dates.csv")
main_coefs <- fread("../data/main_coefficients.csv")
mechanism_coefs <- fread("../data/mechanism_coefficients.csv")
het_coefs <- fread("../data/heterogeneity_coefficients.csv")
loo_results <- fread("../data/loo_results.csv")
ri_results <- fread("../data/ri_results.csv")
# Load only needed columns for binscatter
dt <- fread("../data/analysis_sample.csv",
            select = c("delta_occscore", "alc_share", "state_group", "male"))

# ==============================================================================
# Figure 1: Treatment Rollout — State Prohibition Adoption Timeline
# ==============================================================================

prohib_plot <- prohib[prohib_year <= 1920]
prohib_plot[, state_name := c(
  "ME", "KS", "ND", "GA", "OK", "MS", "NC", "TN", "WV",
  "VA", "OR", "CO", "AZ", "WA", "AL", "AR", "IA", "ID",
  "SC", "MT", "SD", "MI", "NE", "IN", "NH", "UT",
  "NM", "TX", "OH", "WY", "FL", "NV", "KY",
  "NY", "PA", "IL", "MA", "CT", "MD", "NJ", "DE", "LA", "MO", "RI", "MN", "WI", "CA", "VT"
)]
prohib_plot[, group := fifelse(prohib_year < 1910, "Dry before 1910",
                        fifelse(prohib_year < 1920, "Went dry 1910-1919",
                                "Wet until 1920"))]

fig1 <- ggplot(prohib_plot, aes(x = prohib_year,
                                 y = reorder(state_name, -prohib_year),
                                 color = group)) +
  geom_point(size = 2.5) +
  geom_vline(xintercept = 1910, linetype = "dashed", alpha = 0.5) +
  geom_vline(xintercept = 1920, linetype = "dashed", alpha = 0.5) +
  annotate("text", x = 1910, y = 0.5, label = "1910\nCensus", size = 3, vjust = -0.5) +
  annotate("text", x = 1920, y = 0.5, label = "1920\nCensus", size = 3, vjust = -0.5) +
  scale_color_manual(values = c("Dry before 1910" = "#E69F00",
                                 "Went dry 1910-1919" = "#D55E00",
                                 "Wet until 1920" = "#0072B2"),
                     name = "") +
  labs(x = "Year of Prohibition Adoption",
       y = "") +
  theme(legend.position = "bottom",
        axis.text.y = element_text(size = 6))

ggsave("../figures/fig1_prohibition_rollout.pdf", fig1, width = 6, height = 9)
cat("Figure 1 saved.\n")

# ==============================================================================
# Figure 2: Geographic Distribution of Alcohol Industry (Map of County Exposure)
# ==============================================================================

# Bin plot: mean ΔOCCSCORE by alcohol share decile × treatment status
males <- dt[male == 1]
males[, alc_decile := cut(alc_share,
                           breaks = unique(quantile(alc_share, probs = seq(0, 1, 0.1))),
                           include.lowest = TRUE)]
males[, alc_decile := as.integer(alc_decile)]

binplot_data <- males[!is.na(alc_decile), .(
  mean_delta_occ = mean(delta_occscore),
  se_delta_occ = sd(delta_occscore) / sqrt(.N),
  mean_alc_share = mean(alc_share),
  n = .N
), by = .(alc_decile, state_group)]

binplot_data <- binplot_data[state_group != "Already dry"]

fig2 <- ggplot(binplot_data, aes(x = as.numeric(alc_decile), y = mean_delta_occ,
                                  color = state_group, shape = state_group)) +
  geom_point(size = 3) +
  geom_line(linewidth = 0.8) +
  geom_errorbar(aes(ymin = mean_delta_occ - 1.96 * se_delta_occ,
                     ymax = mean_delta_occ + 1.96 * se_delta_occ),
                width = 0.2, alpha = 0.5) +
  scale_color_manual(values = c("Went dry 1910-1919" = "#D55E00",
                                 "Wet until 1920" = "#0072B2"),
                     name = "") +
  scale_shape_manual(values = c("Went dry 1910-1919" = 17,
                                 "Wet until 1920" = 16),
                     name = "") +
  labs(x = "Alcohol Industry Share Decile (1910)",
       y = "Mean Change in Occupational Income Score\n(OCCSCORE, 1910-1920)") +
  theme(legend.position = "bottom")

ggsave("../figures/fig2_binscatter_treatment.pdf", fig2, width = 7, height = 5)
cat("Figure 2 saved.\n")

# ==============================================================================
# Figure 3: Pre-Trend vs Post-Treatment Coefficients
# ==============================================================================

pre_coefs <- fread("../data/pretrend_coefficients.csv")
pre_post <- data.table(
  period = c("Pre-period\n(1900-1910)", "Post-period\n(1910-1920)"),
  beta = c(pre_coefs[spec == "pre_m2", beta],
           main_coefs[spec == "m3", beta]),
  se = c(pre_coefs[spec == "pre_m2", se],
         main_coefs[spec == "m3", se])
)
pre_post[, ci_low := beta - 1.96 * se]
pre_post[, ci_high := beta + 1.96 * se]

fig3 <- ggplot(pre_post, aes(x = period, y = beta)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_point(size = 4, color = "#D55E00") +
  geom_errorbar(aes(ymin = ci_low, ymax = ci_high), width = 0.15,
                linewidth = 0.8, color = "#D55E00") +
  labs(x = "", y = "Coefficient on AlcShare × Treated") +
  theme(axis.text.x = element_text(size = 11))

ggsave("../figures/fig3_pretrend.pdf", fig3, width = 5, height = 4)
cat("Figure 3 saved.\n")

# ==============================================================================
# Figure 4: Mechanism Decomposition
# ==============================================================================

mech_plot <- mechanism_coefs[channel %in% c("Supply Chain", "Manufacturing",
                                              "Retail/Hospitality")]
mech_plot[, ci_low := beta - 1.96 * se]
mech_plot[, ci_high := beta + 1.96 * se]

fig4 <- ggplot(mech_plot, aes(x = reorder(channel, beta), y = beta)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_point(size = 4, color = "#D55E00") +
  geom_errorbar(aes(ymin = ci_low, ymax = ci_high), width = 0.15,
                linewidth = 0.8, color = "#D55E00") +
  coord_flip() +
  labs(x = "Pre-Prohibition Industry",
       y = "Effect of AlcShare × Treated on ΔOCCSCORE") +
  annotate("text", x = 0.5, y = max(mech_plot$ci_high) * 0.8,
           label = paste("N supply chain:", format(mechanism_coefs[channel == "Supply Chain", n], big.mark = ",")),
           size = 3, hjust = 1)

ggsave("../figures/fig4_mechanisms.pdf", fig4, width = 7, height = 4)
cat("Figure 4 saved.\n")

# ==============================================================================
# Figure 5: Heterogeneity by Race and Nativity
# ==============================================================================

het_plot <- het_coefs[subgroup %in% c("White", "Black", "Native-born", "Immigrant")]
het_plot[, ci_low := beta - 1.96 * se]
het_plot[, ci_high := beta + 1.96 * se]
het_plot[, category := fifelse(subgroup %in% c("White", "Black"), "Race", "Nativity")]

fig5 <- ggplot(het_plot, aes(x = subgroup, y = beta, color = category)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_point(size = 4) +
  geom_errorbar(aes(ymin = ci_low, ymax = ci_high), width = 0.15, linewidth = 0.8) +
  scale_color_manual(values = c("Race" = "#D55E00", "Nativity" = "#0072B2")) +
  labs(x = "", y = "Effect of AlcShare × Treated on ΔOCCSCORE") +
  theme(legend.position = "none")

ggsave("../figures/fig5_heterogeneity.pdf", fig5, width = 6, height = 4)
cat("Figure 5 saved.\n")

# ==============================================================================
# Figure 6: Leave-One-Out Sensitivity
# ==============================================================================

loo_results[, main_beta := main_coefs[spec == "m3", beta]]

fig6 <- ggplot(loo_results, aes(x = reorder(excluded_state, beta), y = beta)) +
  geom_hline(aes(yintercept = main_beta), linetype = "dashed", color = "#D55E00") +
  geom_point(size = 1.5, color = "#0072B2") +
  labs(x = "Excluded State (FIPS)",
       y = "Coefficient on AlcShare × Treated") +
  theme(axis.text.x = element_text(size = 5, angle = 90))

ggsave("../figures/fig6_loo.pdf", fig6, width = 7, height = 4)
cat("Figure 6 saved.\n")

# ==============================================================================
# Figure 7: Randomization Inference Distribution
# ==============================================================================

true_beta_val <- ri_results$true_beta[1]

fig7 <- ggplot(ri_results, aes(x = perm_beta)) +
  geom_histogram(bins = 50, fill = "#0072B2", alpha = 0.7, color = "white") +
  geom_vline(xintercept = true_beta_val, color = "#D55E00", linewidth = 1.2) +
  annotate("text", x = true_beta_val, y = Inf,
           label = paste0("True β = ", round(true_beta_val, 3)),
           color = "#D55E00", vjust = 2, hjust = -0.1, size = 4) +
  labs(x = "Permuted Treatment Effect",
       y = "Count")

ggsave("../figures/fig7_ri_distribution.pdf", fig7, width = 6, height = 4)
cat("Figure 7 saved.\n")

# ==============================================================================
# Figure 8: Alcohol Industry Distribution Across Counties
# ==============================================================================

fig8 <- ggplot(county_alc[alc_share > 0], aes(x = alc_share * 100)) +
  geom_histogram(bins = 50, fill = "#D55E00", alpha = 0.7, color = "white") +
  labs(x = "Alcohol Industry Employment Share (%)",
       y = "Number of Counties") +
  annotate("text", x = max(county_alc$alc_share * 100) * 0.7, y = Inf,
           label = paste0("Counties with >0%: ",
                          format(sum(county_alc$alc_share > 0), big.mark = ",")),
           vjust = 2, size = 3.5)

ggsave("../figures/fig8_alc_distribution.pdf", fig8, width = 6, height = 4)
cat("Figure 8 saved.\n")

cat("\nAll figures generated.\n")
