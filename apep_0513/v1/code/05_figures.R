## 05_figures.R — Generate all figures
## apep_0513: Welsh 20mph Speed Limit

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================
# 1. Load Data and Results
# ============================================================
cat("=== Loading data ===\n")

panel <- fread(file.path(data_dir, "panel_pfa_month.csv"))
panel[, ym := as.Date(ym)]
results <- readRDS(file.path(data_dir, "main_results.rds"))
rob_results <- readRDS(file.path(data_dir, "robustness_results.rds"))

treat_date <- as.Date("2023-09-01")

# ============================================================
# 2. Figure 1: Pre-Trends — Wales vs England (20-30mph roads)
# ============================================================
cat("=== Figure 1: Pre-Trends ===\n")

# Aggregate to nation × month
nat_month <- panel[, .(
  collisions = sum(collisions),
  ksi = sum(ksi),
  n_pfa = n_distinct(pfa)
), by = .(nation, ym)]
nat_month[, collisions_per_pfa := collisions / n_pfa]
nat_month[, ksi_per_pfa := ksi / n_pfa]

fig1 <- ggplot(nat_month, aes(x = ym, y = collisions_per_pfa, color = nation)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = treat_date, linetype = "dashed", color = "gray40") +
  annotate("text", x = treat_date + 30, y = max(nat_month$collisions_per_pfa) * 0.95,
           label = "20mph\nimplemented", hjust = 0, size = 3, color = "gray40") +
  scale_color_manual(values = c("England" = "#2166AC", "Wales" = "#B2182B")) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b\n%Y") +
  labs(
    title = "Collisions on 20-30 mph Roads: Wales vs. England",
    subtitle = "Monthly collisions per police force area, 2019-2024",
    x = NULL, y = "Collisions per PFA", color = NULL
  )

ggsave(file.path(fig_dir, "fig1_pretrends.pdf"), fig1, width = 8, height = 5)
ggsave(file.path(fig_dir, "fig1_pretrends.png"), fig1, width = 8, height = 5, dpi = 300)
cat("  Saved fig1_pretrends.pdf\n")

# ============================================================
# 3. Figure 2: Event Study
# ============================================================
cat("=== Figure 2: Event Study ===\n")

es <- results$event_study
es_df <- as.data.table(coeftable(es))
es_df[, term := rownames(coeftable(es))]

# Parse relative month from term names
es_df[, rel_month := as.integer(str_extract(term, "-?\\d+"))]
es_df <- es_df[!is.na(rel_month)]
setnames(es_df, c("Estimate", "Std. Error"), c("estimate", "se"))
es_df[, ci_lo := estimate - 1.96 * se]
es_df[, ci_hi := estimate + 1.96 * se]

# Add reference period
ref_row <- data.table(estimate = 0, se = 0, ci_lo = 0, ci_hi = 0, rel_month = -1)
es_df <- rbind(es_df[, .(estimate, se, ci_lo, ci_hi, rel_month)], ref_row)
es_df <- es_df[order(rel_month)]

fig2 <- ggplot(es_df, aes(x = rel_month, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "solid", color = "gray60") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "gray40") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "#B2182B", alpha = 0.15) +
  geom_point(size = 2, color = "#B2182B") +
  geom_line(color = "#B2182B", linewidth = 0.5) +
  annotate("text", x = -12, y = max(es_df$ci_hi, na.rm = TRUE) * 0.9,
           label = "Pre-treatment", hjust = 0.5, size = 3.5, color = "gray40") +
  annotate("text", x = 8, y = max(es_df$ci_hi, na.rm = TRUE) * 0.9,
           label = "Post-treatment", hjust = 0.5, size = 3.5, color = "gray40") +
  scale_x_continuous(breaks = seq(-24, 16, by = 6)) +
  labs(
    title = "Event Study: Effect of 20mph Default on Collisions",
    subtitle = "Relative to month before implementation (t = -1)",
    x = "Months relative to September 2023", y = "Coefficient (log collisions)"
  )

ggsave(file.path(fig_dir, "fig2_event_study.pdf"), fig2, width = 8, height = 5)
ggsave(file.path(fig_dir, "fig2_event_study.png"), fig2, width = 8, height = 5, dpi = 300)
cat("  Saved fig2_event_study.pdf\n")

# ============================================================
# 4. Figure 3: KSI Pre-Trends
# ============================================================
cat("=== Figure 3: KSI Pre-Trends ===\n")

fig3 <- ggplot(nat_month, aes(x = ym, y = ksi_per_pfa, color = nation)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = treat_date, linetype = "dashed", color = "gray40") +
  scale_color_manual(values = c("England" = "#2166AC", "Wales" = "#B2182B")) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b\n%Y") +
  labs(
    title = "Killed or Seriously Injured: Wales vs. England",
    subtitle = "Monthly KSI per police force area on 20-30 mph roads",
    x = NULL, y = "KSI per PFA", color = NULL
  )

ggsave(file.path(fig_dir, "fig3_ksi_trends.pdf"), fig3, width = 8, height = 5)
ggsave(file.path(fig_dir, "fig3_ksi_trends.png"), fig3, width = 8, height = 5, dpi = 300)
cat("  Saved fig3_ksi_trends.pdf\n")

# ============================================================
# 5. Figure 4: Placebo — High-Speed Roads
# ============================================================
cat("=== Figure 4: Placebo (40+ mph roads) ===\n")

placebo <- fread(file.path(data_dir, "panel_placebo_pfa.csv"))
placebo[, ym := as.Date(ym)]

plac_nat <- placebo[, .(
  collisions = sum(collisions),
  n_pfa = n_distinct(pfa)
), by = .(nation, ym)]
plac_nat[, collisions_per_pfa := collisions / n_pfa]

fig4 <- ggplot(plac_nat, aes(x = ym, y = collisions_per_pfa, color = nation)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = treat_date, linetype = "dashed", color = "gray40") +
  scale_color_manual(values = c("England" = "#2166AC", "Wales" = "#B2182B")) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b\n%Y") +
  labs(
    title = "Placebo: Collisions on 40+ mph Roads (Exempt from 20mph Policy)",
    subtitle = "Monthly collisions per PFA — no differential change expected",
    x = NULL, y = "Collisions per PFA", color = NULL
  )

ggsave(file.path(fig_dir, "fig4_placebo_high_speed.pdf"), fig4, width = 8, height = 5)
ggsave(file.path(fig_dir, "fig4_placebo_high_speed.png"), fig4, width = 8, height = 5, dpi = 300)
cat("  Saved fig4_placebo_high_speed.pdf\n")

# ============================================================
# 6. Figure 5: Randomization Inference Distribution
# ============================================================
cat("=== Figure 5: Randomization Inference ===\n")

ri_df <- data.table(coef = rob_results$ri_coefs)
obs <- rob_results$obs_coef

fig5 <- ggplot(ri_df[!is.na(coef)], aes(x = coef)) +
  geom_histogram(bins = 50, fill = "gray70", color = "white") +
  geom_vline(xintercept = obs, color = "#B2182B", linewidth = 1, linetype = "dashed") +
  annotate("text", x = obs, y = Inf, vjust = 1.5,
           label = sprintf("Observed\n%.3f", obs),
           color = "#B2182B", size = 3.5, fontface = "bold") +
  labs(
    title = "Randomization Inference: Distribution of Placebo Coefficients",
    subtitle = sprintf("999 permutations of PFA treatment assignment (p = %.3f)",
                        rob_results$ri_pvalue),
    x = "Estimated coefficient under random assignment",
    y = "Count"
  )

ggsave(file.path(fig_dir, "fig5_randomization_inference.pdf"), fig5, width = 7, height = 5)
ggsave(file.path(fig_dir, "fig5_randomization_inference.png"), fig5, width = 7, height = 5, dpi = 300)
cat("  Saved fig5_randomization_inference.pdf\n")

# ============================================================
# 7. Figure 6: Severity Decomposition
# ============================================================
cat("=== Figure 6: Severity Decomposition ===\n")

# Coefficient comparison across severity types
sev_coefs <- data.table(
  outcome = c("All collisions", "KSI", "Fatal", "Serious", "Slight"),
  estimate = c(
    coef(results$basic_did)["treat"],
    coef(results$ksi_did)["treat"],
    coef(results$fatal_did)["treat"],
    coef(results$serious_did)["treat"],
    coef(results$slight_did)["treat"]
  ),
  se = c(
    se(results$basic_did)["treat"],
    se(results$ksi_did)["treat"],
    se(results$fatal_did)["treat"],
    se(results$serious_did)["treat"],
    se(results$slight_did)["treat"]
  )
)
sev_coefs[, ci_lo := estimate - 1.96 * se]
sev_coefs[, ci_hi := estimate + 1.96 * se]
sev_coefs[, outcome := factor(outcome, levels = rev(c("All collisions", "KSI", "Fatal", "Serious", "Slight")))]

fig6 <- ggplot(sev_coefs, aes(x = estimate, y = outcome)) +
  geom_vline(xintercept = 0, linetype = "solid", color = "gray60") +
  geom_errorbarh(aes(xmin = ci_lo, xmax = ci_hi), height = 0.2, color = "#B2182B") +
  geom_point(size = 3, color = "#B2182B") +
  labs(
    title = "Treatment Effect by Collision Severity",
    subtitle = "DiD estimates with 95% CIs (PFA-clustered)",
    x = "Coefficient (log scale)", y = NULL
  )

ggsave(file.path(fig_dir, "fig6_severity_decomposition.pdf"), fig6, width = 7, height = 4)
ggsave(file.path(fig_dir, "fig6_severity_decomposition.png"), fig6, width = 7, height = 4, dpi = 300)
cat("  Saved fig6_severity_decomposition.pdf\n")

# ============================================================
# 8. Figure 7: Property Value Event Study
# ============================================================
cat("=== Figure 7: Property Event Study ===\n")

if (file.exists(file.path(data_dir, "land_registry_clean.csv"))) {
  lr <- fread(file.path(data_dir, "land_registry_clean.csv"))
  lr[, date := as.Date(date)]
  lr_std <- lr[ppd_cat == "A" & !is.na(welsh)]
  lr_std[, district_factor := as.factor(district)]

  # Create year-quarter factor
  lr_std[, yq := paste0(year(date), "-Q", quarter(date))]
  lr_std[, yq_factor := as.factor(yq)]

  # Reference quarter: Q2 2023 (just before Sep 2023 implementation)
  # Create relative quarter
  lr_std[, q_num := (year(date) - 2019) * 4 + quarter(date)]
  ref_q <- (2023 - 2019) * 4 + 2  # Q2 2023
  lr_std[, rel_q := q_num - ref_q]

  # Create interactions: welsh × quarter dummies (omitting ref quarter)
  lr_std[, welsh_num := as.numeric(welsh)]
  quarters_to_use <- sort(unique(lr_std$rel_q))
  quarters_to_use <- quarters_to_use[quarters_to_use != 0]  # omit reference

  # Create the interaction terms
  for (qq in quarters_to_use) {
    vname <- paste0("wq_", ifelse(qq < 0, paste0("m", abs(qq)), qq))
    lr_std[, (vname) := as.numeric(welsh == 1 & rel_q == qq)]
  }

  # Build formula
  wq_vars <- grep("^wq_", names(lr_std), value = TRUE)
  fml <- as.formula(paste0("log_price ~ ", paste(wq_vars, collapse = " + "),
                            " | district_factor + yq_factor"))

  pv_es <- feols(fml, data = lr_std, cluster = ~district_factor)

  # Extract coefficients
  pv_es_df <- data.table(
    term = names(coef(pv_es)),
    estimate = as.numeric(coef(pv_es)),
    se = as.numeric(se(pv_es))
  )
  pv_es_df[, rel_q := fifelse(
    grepl("^wq_m", term),
    -as.integer(gsub("wq_m", "", term)),
    as.integer(gsub("wq_", "", term))
  )]
  pv_es_df[, ci_lo := estimate - 1.96 * se]
  pv_es_df[, ci_hi := estimate + 1.96 * se]

  # Add reference period
  ref_row <- data.table(term = "ref", estimate = 0, se = 0, rel_q = 0, ci_lo = 0, ci_hi = 0)
  pv_es_df <- rbind(pv_es_df, ref_row)
  pv_es_df <- pv_es_df[order(rel_q)]

  # Map rel_q to approximate dates for x-axis labels
  pv_es_df[, approx_date := as.Date("2023-04-01") + rel_q * 91]

  fig7 <- ggplot(pv_es_df, aes(x = rel_q, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "solid", color = "gray60") +
    geom_vline(xintercept = 1.5, linetype = "dashed", color = "gray40") +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "#2166AC", alpha = 0.15) +
    geom_point(size = 2, color = "#2166AC") +
    geom_line(color = "#2166AC", linewidth = 0.5) +
    annotate("text", x = -8, y = max(pv_es_df$ci_hi, na.rm = TRUE) * 0.9,
             label = "Pre-treatment", hjust = 0.5, size = 3.5, color = "gray40") +
    annotate("text", x = 4, y = max(pv_es_df$ci_hi, na.rm = TRUE) * 0.9,
             label = "Post-treatment", hjust = 0.5, size = 3.5, color = "gray40") +
    labs(
      title = "Property Value Event Study",
      subtitle = "Welsh × quarter interactions relative to Q2 2023",
      x = "Quarters relative to Q2 2023",
      y = "Coefficient (log price)"
    )

  ggsave(file.path(fig_dir, "fig7_property_event_study.pdf"), fig7, width = 8, height = 5)
  ggsave(file.path(fig_dir, "fig7_property_event_study.png"), fig7, width = 8, height = 5, dpi = 300)
  cat("  Saved fig7_property_event_study.pdf\n")
} else {
  cat("  No Land Registry data — skipping property event study.\n")
}

cat("\n=== All figures generated ===\n")
