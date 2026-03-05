# =============================================================================
# 05_figures.R — Pills and Diplomas (apep_0510)
# =============================================================================
# All figures read from saved CSV/RDS data files.
# Never pass objects in-memory from analysis scripts.
# =============================================================================

source("code/00_packages.R")

# APEP color palette
apep_blue    <- "#2166AC"
apep_red     <- "#B2182B"
apep_grey    <- "#636363"
apep_green   <- "#1B7837"
apep_orange  <- "#E08214"

# =============================================================================
# FIGURE 1: EVENT STUDY — RETENTION RATE (CS-DiD)
# =============================================================================
cat("=== Figure 1: Retention event study ===\n")

es_ret <- fread(file.path(DATA_DIR, "es_retention.csv"))

fig1 <- ggplot(es_ret, aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, color = apep_grey, linetype = "dashed", linewidth = 0.4) +
  geom_vline(xintercept = -0.5, color = apep_red, linetype = "dotted", linewidth = 0.4) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15, fill = apep_blue) +
  geom_point(size = 2, color = apep_blue) +
  geom_line(linewidth = 0.6, color = apep_blue) +
  labs(
    x = "Years Relative to PDMP Mandate",
    y = "ATT: Retention Rate (pp)"
  ) +
  scale_x_continuous(breaks = seq(-5, 8, 1))

ggsave(file.path(FIG_DIR, "fig1_retention_event_study.pdf"), fig1,
       width = 8, height = 5, device = cairo_pdf)
ggsave(file.path(FIG_DIR, "fig1_retention_event_study.png"), fig1,
       width = 8, height = 5, dpi = 300)
cat("  Figure 1 saved.\n")

# =============================================================================
# FIGURE 2: EVENT STUDY — LOG ENROLLMENT (CS-DiD)
# =============================================================================
cat("=== Figure 2: Enrollment event study ===\n")

es_enr <- fread(file.path(DATA_DIR, "es_enrollment.csv"))

fig2 <- ggplot(es_enr, aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, color = apep_grey, linetype = "dashed", linewidth = 0.4) +
  geom_vline(xintercept = -0.5, color = apep_red, linetype = "dotted", linewidth = 0.4) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15, fill = apep_blue) +
  geom_point(size = 2, color = apep_blue) +
  geom_line(linewidth = 0.6, color = apep_blue) +
  labs(
    x = "Years Relative to PDMP Mandate",
    y = "ATT: Log Enrollment"
  ) +
  scale_x_continuous(breaks = seq(-5, 8, 1)) +
  theme(plot.title = element_text(size = 13))

ggsave(file.path(FIG_DIR, "fig2_enrollment_event_study.pdf"), fig2,
       width = 8, height = 5, device = cairo_pdf)
ggsave(file.path(FIG_DIR, "fig2_enrollment_event_study.png"), fig2,
       width = 8, height = 5, dpi = 300)
cat("  Figure 2 saved.\n")

# =============================================================================
# FIGURE 3: FIRST-STAGE EVENT STUDY (OVERDOSE MORTALITY)
# =============================================================================
cat("=== Figure 3: First-stage overdose ===\n")

fs_es <- fread(file.path(DATA_DIR, "first_stage_event_study.csv"))

fig3 <- ggplot(fs_es, aes(x = event_time, y = coef)) +
  geom_hline(yintercept = 0, color = apep_grey, linetype = "dashed", linewidth = 0.4) +
  geom_vline(xintercept = -0.5, color = apep_red, linetype = "dotted", linewidth = 0.4) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.15, fill = apep_red) +
  geom_point(size = 2, color = apep_red) +
  geom_line(linewidth = 0.6, color = apep_red) +
  labs(
    x = "Years Relative to PDMP Mandate",
    y = "Change in Drug Overdose Rate\n(per 100,000, all ages)",
    title = "First Stage: PDMP Mandates and Drug Poisoning Mortality",
    subtitle = "State-level TWFE event study with state and year fixed effects"
  ) +
  scale_x_continuous(breaks = seq(-5, 5, 1)) +
  theme(plot.title = element_text(size = 13))

ggsave(file.path(FIG_DIR, "fig3_first_stage_overdose.pdf"), fig3,
       width = 8, height = 5, device = cairo_pdf)
ggsave(file.path(FIG_DIR, "fig3_first_stage_overdose.png"), fig3,
       width = 8, height = 5, dpi = 300)
cat("  Figure 3 saved.\n")

# =============================================================================
# FIGURE 4: DRUG-TYPE DECOMPOSITION (Substitution Test)
# =============================================================================
cat("=== Figure 4: Drug decomposition ===\n")

decomp <- fread(file.path(DATA_DIR, "drug_decomposition.csv"))

decomp[, drug_label := factor(drug_type,
  levels = c("prescription", "fentanyl", "heroin", "total_od"),
  labels = c("Prescription\nOpioids (T40.2)", "Synthetic Opioids/\nFentanyl (T40.4)",
             "Heroin\n(T40.1)", "Total Drug\nOverdose Deaths")
)]

fig4 <- ggplot(decomp, aes(x = drug_label, y = coef)) +
  geom_hline(yintercept = 0, color = apep_grey, linetype = "dashed", linewidth = 0.4) +
  geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper),
                  size = 0.6, linewidth = 0.8, color = apep_blue) +
  labs(
    x = "",
    y = "Effect of PDMP Mandate\non Log Deaths",
    title = "The Substitution Test: PDMP Effects by Drug Type",
    subtitle = "TWFE with state and year FE, clustered at state level"
  ) +
  theme(
    axis.text.x = element_text(size = 10),
    plot.title = element_text(size = 13)
  )

ggsave(file.path(FIG_DIR, "fig4_drug_decomposition.pdf"), fig4,
       width = 8, height = 5, device = cairo_pdf)
ggsave(file.path(FIG_DIR, "fig4_drug_decomposition.png"), fig4,
       width = 8, height = 5, dpi = 300)
cat("  Figure 4 saved.\n")

# =============================================================================
# FIGURE 5: TREATMENT ROLLOUT MAP
# =============================================================================
cat("=== Figure 5: Treatment rollout ===\n")

pdmp <- fread(file.path(DATA_DIR, "pdmp_mandate_dates.csv"))

# Add never-treated states
never_treated <- data.table(
  state = c("AK", "HI", "ID", "KS", "MO", "SD", "WY", "PR"),
  pdmp_mandate_year = NA_integer_
)
pdmp_all <- rbindlist(list(pdmp, never_treated), fill = TRUE)

# Merge with US state map data
states_map <- as.data.table(map_data("state"))
state_info <- data.table(
  state = state.abb,
  region = tolower(state.name)
)
state_info <- rbindlist(list(state_info,
  data.table(state = "DC", region = "district of columbia")))

pdmp_all <- merge(pdmp_all, state_info, by = "state", all.x = TRUE)
map_data_merged <- merge(states_map, pdmp_all, by = "region", all.x = TRUE)

fig5 <- ggplot(map_data_merged, aes(x = long, y = lat, group = group)) +
  geom_polygon(aes(fill = pdmp_mandate_year), color = "white", linewidth = 0.2) +
  scale_fill_viridis_c(
    name = "Mandate\nYear",
    na.value = "grey85",
    option = "plasma",
    direction = -1,
    breaks = seq(2007, 2021, 2)
  ) +
  labs(
    title = "Staggered Adoption of PDMP Mandatory Consultation Laws",
    subtitle = "Grey = never-treated states"
  ) +
  coord_map("albers", lat0 = 39, lat1 = 45) +
  theme_void(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(color = "grey40", size = 10),
    legend.position = "right"
  )

ggsave(file.path(FIG_DIR, "fig5_treatment_map.pdf"), fig5,
       width = 10, height = 6, device = cairo_pdf)
ggsave(file.path(FIG_DIR, "fig5_treatment_map.png"), fig5,
       width = 10, height = 6, dpi = 300)
cat("  Figure 5 saved.\n")

# =============================================================================
# FIGURE 6: PLACEBO — GRADUATE-HEAVY vs. UNDERGRADUATE INSTITUTIONS
# =============================================================================
cat("=== Figure 6: Placebo comparison ===\n")

es_main <- fread(file.path(DATA_DIR, "es_retention.csv"))
es_main[, group := "Undergraduate\ninstitutions"]

es_grad_file <- file.path(DATA_DIR, "placebo_grad_heavy.csv")
if (file.exists(es_grad_file)) {
  es_grad <- fread(es_grad_file)
  if (nrow(es_grad) > 1) {
    es_grad[, group := "Graduate-heavy\ninstitutions (placebo)"]
    es_combined <- rbindlist(list(es_main, es_grad), fill = TRUE)

    fig6 <- ggplot(es_combined, aes(x = event_time, y = att, color = group, fill = group)) +
      geom_hline(yintercept = 0, color = apep_grey, linetype = "dashed", linewidth = 0.4) +
      geom_vline(xintercept = -0.5, color = "grey70", linetype = "dotted", linewidth = 0.4) +
      geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.1, color = NA) +
      geom_point(size = 2) +
      geom_line(linewidth = 0.6) +
      scale_color_manual(values = c(apep_blue, apep_orange)) +
      scale_fill_manual(values = c(apep_blue, apep_orange)) +
      labs(
        x = "Years Relative to PDMP Mandate",
        y = "ATT: Retention Rate (pp)",
        title = "Placebo Test: PDMP Effects on Undergraduate vs. Graduate Institutions",
        color = "", fill = ""
      ) +
      scale_x_continuous(breaks = seq(-5, 8, 1)) +
      theme(plot.title = element_text(size = 12))

    ggsave(file.path(FIG_DIR, "fig6_placebo_comparison.pdf"), fig6,
           width = 9, height = 5, device = cairo_pdf)
    ggsave(file.path(FIG_DIR, "fig6_placebo_comparison.png"), fig6,
           width = 9, height = 5, dpi = 300)
    cat("  Figure 6 saved.\n")
  }
}

# =============================================================================
# FIGURE 7: SUN & ABRAHAM EVENT STUDY COMPARISON
# =============================================================================
cat("=== Figure 7: SA vs CS comparison ===\n")

sa_file <- file.path(DATA_DIR, "sun_abraham_retention.csv")
if (file.exists(sa_file)) {
  es_sa <- fread(sa_file)
  es_sa[, estimator := "Sun & Abraham (2021)"]

  es_cs <- fread(file.path(DATA_DIR, "es_retention.csv"))
  es_cs[, estimator := "Callaway & Sant'Anna (2021)"]

  es_compare <- rbindlist(list(es_cs, es_sa), fill = TRUE)

  fig7 <- ggplot(es_compare, aes(x = event_time, y = att, color = estimator)) +
    geom_hline(yintercept = 0, color = apep_grey, linetype = "dashed", linewidth = 0.4) +
    geom_vline(xintercept = -0.5, color = "grey70", linetype = "dotted", linewidth = 0.4) +
    geom_point(size = 1.8, position = position_dodge(0.3)) +
    geom_linerange(aes(ymin = ci_lower, ymax = ci_upper),
                   linewidth = 0.5, position = position_dodge(0.3)) +
    scale_color_manual(values = c(apep_blue, apep_green)) +
    labs(
      x = "Years Relative to PDMP Mandate",
      y = "ATT: Retention Rate (pp)",
      title = "Robustness: CS-DiD vs. Sun & Abraham Estimator",
      color = ""
    ) +
    scale_x_continuous(breaks = seq(-5, 8, 1)) +
    theme(plot.title = element_text(size = 12))

  ggsave(file.path(FIG_DIR, "fig7_estimator_comparison.pdf"), fig7,
         width = 9, height = 5, device = cairo_pdf)
  ggsave(file.path(FIG_DIR, "fig7_estimator_comparison.png"), fig7,
         width = 9, height = 5, dpi = 300)
  cat("  Figure 7 saved.\n")
}

cat("\nAll figures complete.\n")
