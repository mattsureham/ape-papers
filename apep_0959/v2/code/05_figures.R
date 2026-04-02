## 05_figures.R — V2 Figures
## Event studies, mechanism decomposition, severity, conceptual framework

source("00_packages.R")

results <- readRDS("../data/results_v2.rds")
rob_results <- readRDS("../data/robustness_v2.rds")
panel_did <- readRDS("../data/panel_did.rds")

fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

# Common theme
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.line = element_line(color = "black", linewidth = 0.3),
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(color = "gray40", size = 10),
    legend.position = "bottom"
  )

# ================================================================
# Figure 1: NY Event Study (Primary Specification)
# ================================================================
cat("=== Figure 1: NY Event Study ===\n")

ny_es <- rob_results$ny_es$main
if (!is.null(ny_es)) {
  es_coefs <- coeftable(ny_es)
  es_dt <- as.data.table(es_coefs, keep.rownames = TRUE)
  setnames(es_dt, c("term", "estimate", "se", "tstat", "pval"))
  # Extract relative year from term names
  es_dt[, rel_year := as.integer(gsub(".*::(-?[0-9]+):.*", "\\1", term))]
  es_dt <- es_dt[!is.na(rel_year)]
  # Add reference period
  es_dt <- rbind(es_dt, data.table(term = "ref", estimate = 0, se = 0,
                                     tstat = 0, pval = 1, rel_year = -1))
  es_dt[, ci_lo := estimate - 1.96 * se]
  es_dt[, ci_hi := estimate + 1.96 * se]

  p1 <- ggplot(es_dt, aes(x = rel_year, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "red", alpha = 0.5) +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "steelblue", alpha = 0.2) +
    geom_point(size = 2.5, color = "steelblue") +
    geom_line(color = "steelblue", linewidth = 0.5) +
    labs(title = "Effect of NY Safe Staffing Act on Deficiency Citations",
         subtitle = "Event study relative to mandate adoption (2022), reference period t = -1",
         x = "Years relative to mandate",
         y = "Change in deficiency citations per survey") +
    scale_x_continuous(breaks = seq(-4, 4, 1)) +
    theme_apep

  ggsave(file.path(fig_dir, "fig1_ny_event_study.pdf"), p1,
         width = 7, height = 5, device = cairo_pdf)
  cat("Saved fig1_ny_event_study.pdf\n")
}

# ================================================================
# Figure 2: Detection Mode Decomposition
# ================================================================
cat("=== Figure 2: Detection Mode Decomposition ===\n")

# Coefficient comparison: total, observation, documentation, report
ny_models <- results$ny
detect_dt <- data.table(
  outcome = c("Total", "Observation-\ndependent", "Documentation-\ndependent",
              "Report-\ndependent", "Infection\ncontrol"),
  estimate = c(coef(ny_models$twfe)["ny_post"],
               coef(ny_models$obs)["ny_post"],
               coef(ny_models$doc)["ny_post"],
               coef(ny_models$rpt)["ny_post"],
               coef(ny_models$infect)["ny_post"]),
  se = c(sqrt(vcov(ny_models$twfe)["ny_post", "ny_post"]),
         sqrt(vcov(ny_models$obs)["ny_post", "ny_post"]),
         sqrt(vcov(ny_models$doc)["ny_post", "ny_post"]),
         sqrt(vcov(ny_models$rpt)["ny_post", "ny_post"]),
         sqrt(vcov(ny_models$infect)["ny_post", "ny_post"]))
)
detect_dt[, ci_lo := estimate - 1.96 * se]
detect_dt[, ci_hi := estimate + 1.96 * se]
detect_dt[, detection := c("Mixed", "Observation", "Documentation", "Report", "Observation")]
detect_dt[, outcome := factor(outcome, levels = rev(outcome))]

p2 <- ggplot(detect_dt, aes(x = estimate, y = outcome, color = detection)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  geom_errorbarh(aes(xmin = ci_lo, xmax = ci_hi), height = 0.2, linewidth = 0.7) +
  geom_point(size = 3) +
  scale_color_manual(values = c("Mixed" = "gray30", "Observation" = "steelblue",
                                 "Documentation" = "darkorange", "Report" = "forestgreen"),
                     name = "Detection mode") +
  labs(title = "The Detection Dividend: Deficiency Changes by Detection Mode",
       subtitle = "NY Safe Staffing Act, facility FE + year FE, state-clustered SEs",
       x = "Change in citations per survey",
       y = NULL) +
  theme_apep +
  theme(axis.text.y = element_text(size = 10))

ggsave(file.path(fig_dir, "fig2_detection_decomposition.pdf"), p2,
       width = 7, height = 4.5, device = cairo_pdf)
cat("Saved fig2_detection_decomposition.pdf\n")

# ================================================================
# Figure 3: Severity Decomposition
# ================================================================
cat("=== Figure 3: Severity Decomposition ===\n")

sev_models <- rob_results$severity
sev_dt <- data.table(
  severity = c("Minimal\n(A-C)", "Moderate\n(D-F)", "Actual Harm\n(G-I)", "Jeopardy\n(J-L)"),
  estimate = c(coef(sev_models$minimal)["treated"],
               coef(sev_models$moderate)["treated"],
               coef(sev_models$harm)["treated"],
               coef(sev_models$jeopardy)["treated"]),
  se = c(sqrt(vcov(sev_models$minimal)["treated", "treated"]),
         sqrt(vcov(sev_models$moderate)["treated", "treated"]),
         sqrt(vcov(sev_models$harm)["treated", "treated"]),
         sqrt(vcov(sev_models$jeopardy)["treated", "treated"]))
)
sev_dt[, ci_lo := estimate - 1.96 * se]
sev_dt[, ci_hi := estimate + 1.96 * se]
sev_dt[, severity := factor(severity, levels = severity)]
sev_dt[, sev_type := c("Low", "Low", "High", "High")]

p3 <- ggplot(sev_dt, aes(x = severity, y = estimate, fill = sev_type)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_col(width = 0.6, alpha = 0.7) +
  geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0.2) +
  scale_fill_manual(values = c("Low" = "steelblue", "High" = "firebrick"),
                    name = "Severity") +
  labs(title = "Extra Citations Concentrated in Low-Severity Categories",
       subtitle = "Pooled DiD estimate by severity group, state-clustered SEs",
       x = NULL, y = "Change in citations per survey") +
  theme_apep

ggsave(file.path(fig_dir, "fig3_severity_decomposition.pdf"), p3,
       width = 6, height = 4.5, device = cairo_pdf)
cat("Saved fig3_severity_decomposition.pdf\n")

# ================================================================
# Figure 4: Pooled Event Study (Sun-Abraham)
# ================================================================
cat("=== Figure 4: Pooled Sun-Abraham Event Study ===\n")

# Extract Sun-Abraham coefficients from saved model
sa_es <- rob_results$sa_es
if (!is.null(sa_es)) {
  sa_coefs <- coeftable(sa_es)
  sa_dt <- as.data.table(sa_coefs, keep.rownames = TRUE)
  setnames(sa_dt, c("term", "estimate", "se", "tstat", "pval"))
  sa_dt[, rel_year := as.integer(gsub("survey_year::(-?[0-9]+)", "\\1", term))]
  sa_dt <- sa_dt[!is.na(rel_year)]
  # Add reference period (t=-1 is omitted)
  sa_dt <- rbind(sa_dt[, .(rel_year, estimate, se)],
                 data.table(rel_year = -1L, estimate = 0, se = 0))
  setorder(sa_dt, rel_year)
  es_pooled <- sa_dt
} else {
  cat("WARNING: Sun-Abraham model not available, skipping Figure 4
")
  es_pooled <- NULL
}
es_pooled[, ci_lo := estimate - 1.96 * se]
es_pooled[, ci_hi := estimate + 1.96 * se]

p4 <- ggplot(es_pooled, aes(x = rel_year, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "red", alpha = 0.5) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "darkorange", alpha = 0.2) +
  geom_point(size = 2.5, color = "darkorange") +
  geom_line(color = "darkorange", linewidth = 0.5) +
  labs(title = "Pooled Sun-Abraham Event Study",
       subtitle = "Interaction-weighted estimator, 4 treatment cohorts",
       x = "Years relative to mandate",
       y = "Estimated effect on deficiency citations") +
  scale_x_continuous(breaks = seq(-5, 4, 1)) +
  theme_apep

ggsave(file.path(fig_dir, "fig4_pooled_event_study.pdf"), p4,
       width = 7, height = 5, device = cairo_pdf)
cat("Saved fig4_pooled_event_study.pdf\n")

# ================================================================
# Figure 5: Leave-one-state-out
# ================================================================
cat("=== Figure 5: Leave-one-state-out ===\n")

loo <- rob_results$loo
if (nrow(loo) > 0) {
  loo[, ci_lo := coef - 1.96 * se]
  loo[, ci_hi := coef + 1.96 * se]

  p5 <- ggplot(loo, aes(x = reorder(dropped, coef), y = coef)) +
    geom_hline(yintercept = coef(results$pooled$twfe)["treated"],
               linetype = "dashed", color = "steelblue") +
    geom_point(size = 3) +
    geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0.2) +
    coord_flip() +
    labs(title = "Sensitivity: Leave-One-Treated-State-Out",
         subtitle = "Dashed line = baseline pooled estimate",
         x = "State dropped", y = "TWFE coefficient") +
    theme_apep

  ggsave(file.path(fig_dir, "fig5_leave_one_out.pdf"), p5,
         width = 6, height = 4, device = cairo_pdf)
  cat("Saved fig5_leave_one_out.pdf\n")
}

cat("\n=== All figures generated ===\n")
cat(sprintf("Figures saved to: %s/\n", fig_dir))
