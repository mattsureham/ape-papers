# ============================================================================
# 05_figures.R — Publication-quality figures
# Denmark's 2013 Disability Pension Reform (apep_0599)
# ============================================================================

source("00_packages.R")

cat("=== Generating figures ===\n")

# --- Paths ---
data_dir   <- "../data"
fig_dir    <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# --- Helper: save figure ---
save_fig <- function(p, filename, width = 7, height = 5) {
  path <- file.path(fig_dir, filename)
  ggsave(path, plot = p, width = width, height = height,
         device = cairo_pdf)
  cat("  Saved:", path, "\n")
}

# --- Load data ---
nat <- fread(file.path(data_dir, "panel_national.csv"))
panel <- fread(file.path(data_dir, "panel_benefits.csv"))

# Ensure treat_group is a factor with correct order
group_levels <- c("High (25-39)", "Moderate (40-49)", "Control (50-59)")
nat[, treat_group := factor(treat_group, levels = group_levels)]

# ============================================================================
# Figure 1: Raw trends in disability pension rate by treatment group
# ============================================================================
cat("Figure 1: DP trends\n")

# Aggregate national data to treat_group × time level (pop-weighted)
nat_agg <- nat[, .(
  dp_rate = sum(n_fp) / sum(total_pop) * 1000,
  fl_rate = sum(n_fl) / sum(total_pop) * 1000,
  res_rate = sum(n_res) / sum(total_pop) * 1000
), by = .(time, yq, treat_group)]

fig1 <- ggplot(nat_agg, aes(x = yq, y = dp_rate, color = treat_group)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = 2013, linetype = "dashed", color = "grey40") +
  annotate("text", x = 2013.1, y = max(nat_agg$dp_rate, na.rm = TRUE) * 0.95,
           label = "Reform", hjust = 0, size = 3.5, color = "grey30",
           family = "serif") +
  scale_color_manual(values = cols_apep, name = "Age Group") +
  labs(
    title = "Disability Pension Recipients by Age Group",
    subtitle = "Per 1,000 population, Denmark 2008\u20132024",
    x = "Year-Quarter",
    y = "Recipients per 1,000"
  ) +
  scale_x_continuous(breaks = seq(2008, 2024, 2))

save_fig(fig1, "fig1_dp_trends.pdf")

# ============================================================================
# Figure 2: Raw trends in flex job and resource scheme rate (two panels)
# ============================================================================
cat("Figure 2: Substitution trends\n")

# Reshape to long for faceting
sub_long <- melt(nat_agg,
                 id.vars = c("time", "yq", "treat_group"),
                 measure.vars = c("fl_rate", "res_rate"),
                 variable.name = "benefit", value.name = "rate")
sub_long[, benefit := factor(benefit,
                             levels = c("fl_rate", "res_rate"),
                             labels = c("Panel A: Flex Jobs",
                                        "Panel B: Resource Scheme"))]

fig2 <- ggplot(sub_long, aes(x = yq, y = rate, color = treat_group)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = 2013, linetype = "dashed", color = "grey40") +
  facet_wrap(~ benefit, ncol = 1, scales = "free_y") +
  scale_color_manual(values = cols_apep, name = "Age Group") +
  labs(
    title = "Substitution Program Trends by Age Group",
    subtitle = "Per 1,000 population, Denmark 2008\u20132024",
    x = "Year-Quarter",
    y = "Recipients per 1,000"
  ) +
  scale_x_continuous(breaks = seq(2008, 2024, 2))

save_fig(fig2, "fig2_substitution_trends.pdf", height = 8)

# ============================================================================
# Helper: Event study plot
# ============================================================================
plot_event_study <- function(dt, title_str, ylab_str = "Coefficient Estimate") {
  # Add reference period (event_time = -1, estimate = 0)
  ref <- data.table(event_time_val = -1, estimate = 0,
                    ci_lower = 0, ci_upper = 0)
  dt_plot <- rbindlist(list(
    dt[, .(event_time_val, estimate, ci_lower, ci_upper)],
    ref
  ), fill = TRUE)
  setorder(dt_plot, event_time_val)

  ggplot(dt_plot, aes(x = event_time_val, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
                fill = "#D62728", alpha = 0.15) +
    geom_line(color = "#D62728", linewidth = 0.6) +
    geom_point(color = "#D62728", size = 1.5) +
    geom_point(data = dt_plot[event_time_val == -1],
               color = "#D62728", size = 3, shape = 18) +
    labs(
      title = title_str,
      subtitle = "DiD event study coefficients with 95% CI (reference period = \u22121)",
      x = "Quarters Relative to Reform",
      y = ylab_str
    )
}

# ============================================================================
# Figure 3: Event study — disability pension
# ============================================================================
cat("Figure 3: Event study DP\n")

es_dp <- fread(file.path(data_dir, "reg_event_study_fp.csv"))
fig3 <- plot_event_study(es_dp,
                         "Event Study: Disability Pension Rate",
                         "Change in DP rate per 1,000")

save_fig(fig3, "fig3_event_study_dp.pdf")

# ============================================================================
# Figure 4: Event study — flex jobs
# ============================================================================
cat("Figure 4: Event study FL\n")

es_fl <- fread(file.path(data_dir, "reg_event_study_fl.csv"))
fig4 <- plot_event_study(es_fl,
                         "Event Study: Flex Job Rate",
                         "Change in flex job rate per 1,000")

save_fig(fig4, "fig4_event_study_fl.pdf")

# ============================================================================
# Figure 5: Event study — cash benefits
# ============================================================================
cat("Figure 5: Event study KH\n")

es_kh <- fread(file.path(data_dir, "reg_event_study_kh.csv"))
fig5 <- plot_event_study(es_kh,
                         "Event Study: Cash Benefit Rate",
                         "Change in cash benefit rate per 1,000")

save_fig(fig5, "fig5_event_study_kh.pdf")

# ============================================================================
# Figure 6: Substitution accounting
# ============================================================================
cat("Figure 6: Substitution accounting\n")

# Use dose-response coefficients for the High (25-39) group
dose <- fread(file.path(data_dir, "reg_dose_response.csv"))
dose_high <- dose[grepl("^high:post$", term)]

# Create display labels
benefit_labels <- c(
  "Disability Pension" = "DP",
  "Flex Jobs"          = "FL",
  "Cash Benefits"      = "KH",
  "Sickness Benefits"  = "SY",
  "Rehabilitation"     = "RES",
  "Job Clarification"  = "JA"
)
dose_high[, short := benefit_labels[outcome]]
dose_high[, short := factor(short, levels = c("DP", "FL", "RES", "KH", "SY", "JA"))]

# Bar colors: red for DP decline, blue for increases
dose_high[, bar_fill := ifelse(estimate > 0, "#1F77B4", "#D62728")]

fig6 <- ggplot(dose_high, aes(x = short, y = estimate, fill = bar_fill)) +
  geom_col(width = 0.65) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper),
                width = 0.2, linewidth = 0.5) +
  geom_hline(yintercept = 0, linewidth = 0.4) +
  scale_fill_identity() +
  labs(
    title = "Substitution Accounting: High Group (25\u201339) vs Control (50\u201359)",
    subtitle = "DiD coefficients from dose-response specification (per 1,000 population)",
    x = "Benefit Program",
    y = "DiD Coefficient (per 1,000)"
  )

save_fig(fig6, "fig6_substitution_accounting.pdf")

# ============================================================================
# Figure 7: Leave-one-out distribution
# ============================================================================
cat("Figure 7: Leave-one-out\n")

loo <- fread(file.path(data_dir, "rob_leave_one_out.csv"))

# Full-sample DDD coefficient for DP
full_coef_ddd <- fread(file.path(data_dir, "reg_ddd_main.csv"))
full_dp <- full_coef_ddd[outcome == "Disability Pension", estimate]

fig7 <- ggplot(loo, aes(x = estimate)) +
  geom_histogram(bins = 25, fill = "grey70", color = "white", linewidth = 0.3) +
  geom_vline(xintercept = full_dp, color = "#D62728",
             linetype = "solid", linewidth = 0.8) +
  annotate("text", x = full_dp, y = Inf,
           label = paste0("Full sample = ", round(full_dp, 2)),
           hjust = -0.1, vjust = 2, size = 3.5, color = "#D62728",
           family = "serif") +
  labs(
    title = "Leave-One-Out Municipality Analysis",
    subtitle = paste0("Distribution of DDD coefficients (", nrow(loo),
                      " LOO samples)"),
    x = "DDD Coefficient (Disability Pension)",
    y = "Count"
  )

save_fig(fig7, "fig7_loo.pdf")

# ============================================================================
# Figure 8: Randomization inference
# ============================================================================
cat("Figure 8: Randomization inference\n")

ri <- fread(file.path(data_dir, "rob_ri.csv"))
actual_coef <- ri[is_actual == TRUE, coefficient][1]
ri_pval <- ri[1, ri_pvalue]
ri_perm <- ri[is_actual == FALSE]

fig8 <- ggplot(ri_perm, aes(x = coefficient)) +
  geom_histogram(bins = 30, fill = "grey70", color = "white", linewidth = 0.3) +
  geom_vline(xintercept = actual_coef, color = "#D62728",
             linetype = "solid", linewidth = 0.8) +
  annotate("text", x = actual_coef, y = Inf,
           label = paste0("Actual = ", round(actual_coef, 2),
                          "\nRI p-value = ", sprintf("%.3f", ri_pval)),
           hjust = -0.1, vjust = 2, size = 3.5, color = "#D62728",
           family = "serif") +
  labs(
    title = "Randomization Inference",
    subtitle = paste0("Distribution of ", nrow(ri_perm),
                      " permuted DiD coefficients"),
    x = "Permuted Coefficient",
    y = "Count"
  )

save_fig(fig8, "fig8_ri.pdf")

# ============================================================================
# Figure 9: Dose-response
# ============================================================================
cat("Figure 9: Dose-response\n")

# Use dose-response for DP and RES outcomes, both High and Moderate
dose_dr <- dose[outcome %in% c("Disability Pension", "Rehabilitation")]

# Clean term labels
dose_dr[, group := fifelse(grepl("high", term), "High (25\u201339)",
                           "Moderate (40\u201349)")]
dose_dr[, group := factor(group, levels = c("High (25\u201339)",
                                             "Moderate (40\u201349)"))]
dose_dr[, outcome_lab := fifelse(outcome == "Disability Pension",
                                 "Disability Pension", "Resource/Rehab")]

fig9 <- ggplot(dose_dr,
               aes(x = group, y = estimate, color = outcome_lab)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper),
                  position = position_dodge(width = 0.4),
                  size = 0.6, linewidth = 0.7) +
  scale_color_manual(values = c("Disability Pension" = "#D62728",
                                "Resource/Rehab" = "#2CA02C"),
                     name = "Outcome") +
  labs(
    title = "Dose-Response: Treatment Intensity and Reform Effects",
    subtitle = "Post-reform coefficients with 95% CI",
    x = "Treatment Group",
    y = "Coefficient (per 1,000)"
  )

save_fig(fig9, "fig9_dose_response.pdf")

# ============================================================================
# Figure 10: DDD Event Study — Resource Scheme
# ============================================================================
cat("Figure 10: DDD event study (Resource Scheme)\n")

ddd_es_file <- file.path(data_dir, "reg_ddd_event_study.csv")
if (file.exists(ddd_es_file)) {
  ddd_es <- fread(ddd_es_file)

  # Plot for Resource Scheme (Rehabilitation)
  ddd_es_res <- ddd_es[outcome == "Rehabilitation" & !is.na(event_time_val)]

  # Add reference period
  ref_ddd <- data.table(event_time_val = -1, estimate = 0,
                         ci_lower = 0, ci_upper = 0)
  ddd_plot <- rbindlist(list(
    ddd_es_res[, .(event_time_val, estimate, ci_lower, ci_upper)],
    ref_ddd
  ), fill = TRUE)
  setorder(ddd_plot, event_time_val)

  fig10 <- ggplot(ddd_plot, aes(x = event_time_val, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
                fill = "#2CA02C", alpha = 0.15) +
    geom_line(color = "#2CA02C", linewidth = 0.6) +
    geom_point(color = "#2CA02C", size = 1.5) +
    geom_point(data = ddd_plot[event_time_val == -1],
               color = "#2CA02C", size = 3, shape = 18) +
    labs(
      title = "DDD Event Study: Resource Scheme",
      subtitle = "Young \u00d7 HighBase \u00d7 Quarter coefficients with 95% CI (ref = \u22121)",
      x = "Quarters Relative to Reform",
      y = "DDD Coefficient (per 1,000)"
    )

  save_fig(fig10, "fig10_ddd_event_study_res.pdf")

  # Also plot DDD event study for DP
  cat("Figure 10b: DDD event study (DP)\n")
  ddd_es_dp <- ddd_es[outcome == "Disability Pension" & !is.na(event_time_val)]

  ddd_plot_dp <- rbindlist(list(
    ddd_es_dp[, .(event_time_val, estimate, ci_lower, ci_upper)],
    ref_ddd
  ), fill = TRUE)
  setorder(ddd_plot_dp, event_time_val)

  fig10b <- ggplot(ddd_plot_dp, aes(x = event_time_val, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
                fill = "#D62728", alpha = 0.15) +
    geom_line(color = "#D62728", linewidth = 0.6) +
    geom_point(color = "#D62728", size = 1.5) +
    geom_point(data = ddd_plot_dp[event_time_val == -1],
               color = "#D62728", size = 3, shape = 18) +
    labs(
      title = "DDD Event Study: Disability Pension",
      subtitle = "Young \u00d7 HighBase \u00d7 Quarter coefficients with 95% CI (ref = \u22121)",
      x = "Quarters Relative to Reform",
      y = "DDD Coefficient (per 1,000)"
    )

  save_fig(fig10b, "fig10b_ddd_event_study_dp.pdf")
} else {
  cat("  SKIP: reg_ddd_event_study.csv not found\n")
}

# ============================================================================
# Figure 11: Employment Event Study
# ============================================================================
cat("Figure 11: Employment event study\n")

emp_es_file <- file.path(data_dir, "reg_emp_event_study.csv")
if (file.exists(emp_es_file)) {
  emp_es <- fread(emp_es_file)
  emp_es <- emp_es[!is.na(event_time_val)]

  # Add reference period
  ref_emp <- data.table(event_time_val = -1, estimate = 0,
                         ci_lower = 0, ci_upper = 0)
  emp_plot <- rbindlist(list(
    emp_es[, .(event_time_val, estimate, ci_lower, ci_upper)],
    ref_emp
  ), fill = TRUE)
  setorder(emp_plot, event_time_val)

  fig11 <- ggplot(emp_plot, aes(x = event_time_val, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
                fill = "#FF7F0E", alpha = 0.15) +
    geom_line(color = "#FF7F0E", linewidth = 0.6) +
    geom_point(color = "#FF7F0E", size = 2) +
    geom_point(data = emp_plot[event_time_val == -1],
               color = "#FF7F0E", size = 3, shape = 18) +
    labs(
      title = "Event Study: Employment Rate",
      subtitle = "DiD coefficients with 95% CI (reference year = 2012)",
      x = "Years Relative to Reform",
      y = "Coefficient (percentage points)"
    )

  save_fig(fig11, "fig11_emp_event_study.pdf")
} else {
  cat("  SKIP: reg_emp_event_study.csv not found\n")
}

cat("\n=== All figures saved to", fig_dir, "===\n")
