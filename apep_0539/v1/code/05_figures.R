## 05_figures.R — All figures
## APEP Paper apep_0539: Less Cash, Less Crime?

source("00_packages.R")
data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

panel <- fread(file.path(data_dir, "analysis_panel.csv"))
cs_results <- readRDS(file.path(data_dir, "cs_did_results.rds"))
ebt_timing <- fread(file.path(data_dir, "ebt_timing.csv"))
main_results <- fread(file.path(data_dir, "main_results.csv"))
loo_results <- fread(file.path(data_dir, "loo_results.csv"))
mde_data <- fread(file.path(data_dir, "mde_results.csv"))

# ===========================================================================
# Figure 1: EBT Rollout Timeline
# ===========================================================================
cat("Figure 1: EBT rollout...\n")

fig1 <- ebt_timing %>%
  ggplot(aes(x = ebt_year)) +
  geom_histogram(binwidth = 1, fill = "#2166AC", color = "white", alpha = 0.85) +
  labs(x = "Year of Statewide EBT Adoption",
       y = "Number of States") +
  scale_x_continuous(breaks = seq(1994, 2006, 2)) +
  scale_y_continuous(breaks = seq(0, 14, 2)) +
  theme_apep()

ggsave(file.path(fig_dir, "fig1_ebt_rollout.pdf"), fig1, width = 7, height = 4.5)

# ===========================================================================
# Figure 2: Event Study — Property Crime (CS-DiD)
# ===========================================================================
cat("Figure 2: Event study property crime...\n")

es_prop <- cs_results$es_property
es_df <- data.frame(
  event_time = es_prop$egt,
  att = es_prop$att.egt,
  se = es_prop$se.egt
) %>%
  mutate(ci_lo = att - 1.96 * se,
         ci_hi = att + 1.96 * se)

fwrite(es_df, file.path(data_dir, "es_property_plot.csv"))

fig2 <- es_df %>%
  ggplot(aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
  geom_vline(xintercept = -0.5, color = "grey70", linetype = "dotted") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "#2166AC", alpha = 0.15) +
  geom_point(color = "#2166AC", size = 2) +
  geom_line(color = "#2166AC", linewidth = 0.6) +
  labs(x = "Years Relative to EBT Adoption",
       y = "ATT (Log Property Crime Rate)") +
  scale_x_continuous(breaks = seq(-10, 10, 2)) +
  theme_apep()

ggsave(file.path(fig_dir, "fig2_es_property.pdf"), fig2, width = 8, height = 5)

# ===========================================================================
# Figure 3: Event Study — Burglary (CS-DiD)
# ===========================================================================
cat("Figure 3: Event study burglary...\n")

es_burg <- cs_results$es_burglary
es_burg_df <- data.frame(
  event_time = es_burg$egt,
  att = es_burg$att.egt,
  se = es_burg$se.egt
) %>%
  mutate(ci_lo = att - 1.96 * se,
         ci_hi = att + 1.96 * se)

fwrite(es_burg_df, file.path(data_dir, "es_burglary_plot.csv"))

fig3 <- es_burg_df %>%
  ggplot(aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
  geom_vline(xintercept = -0.5, color = "grey70", linetype = "dotted") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "#B2182B", alpha = 0.15) +
  geom_point(color = "#B2182B", size = 2) +
  geom_line(color = "#B2182B", linewidth = 0.6) +
  labs(x = "Years Relative to EBT Adoption",
       y = "ATT (Log Burglary Rate)") +
  scale_x_continuous(breaks = seq(-10, 10, 2)) +
  theme_apep()

ggsave(file.path(fig_dir, "fig3_es_burglary.pdf"), fig3, width = 8, height = 5)

# ===========================================================================
# Figure 4: Multi-outcome Event Studies (Panel)
# ===========================================================================
cat("Figure 4: Multi-outcome panel...\n")

extract_es <- function(es_obj, label) {
  data.frame(
    event_time = es_obj$egt,
    att = es_obj$att.egt,
    se = es_obj$se.egt,
    outcome = label
  ) %>%
    mutate(ci_lo = att - 1.96 * se, ci_hi = att + 1.96 * se)
}

multi_es <- bind_rows(
  extract_es(cs_results$es_property, "Property Crime"),
  extract_es(cs_results$es_burglary, "Burglary"),
  extract_es(cs_results$es_larceny, "Larceny-Theft"),
  extract_es(cs_results$es_robbery, "Robbery"),
  extract_es(cs_results$es_mvt, "Motor Vehicle Theft (Placebo)")
)

fwrite(multi_es, file.path(data_dir, "multi_es_plot.csv"))

fig4 <- multi_es %>%
  mutate(outcome = factor(outcome, levels = c("Property Crime", "Burglary",
                                               "Larceny-Theft", "Robbery",
                                               "Motor Vehicle Theft (Placebo)"))) %>%
  ggplot(aes(x = event_time, y = att)) +
  geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
  geom_vline(xintercept = -0.5, color = "grey70", linetype = "dotted") +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "#2166AC", alpha = 0.12) +
  geom_point(color = "#2166AC", size = 1.3) +
  geom_line(color = "#2166AC", linewidth = 0.5) +
  facet_wrap(~outcome, scales = "free_y", ncol = 2) +
  labs(x = "Years Relative to EBT Adoption",
       y = "ATT (Log Crime Rate)") +
  scale_x_continuous(breaks = seq(-10, 10, 4)) +
  theme_apep(base_size = 10)

ggsave(file.path(fig_dir, "fig4_multi_es.pdf"), fig4, width = 9, height = 7)

# ===========================================================================
# Figure 5: Cohort-Specific Crime Trends
# ===========================================================================
cat("Figure 5: Cohort trends...\n")

cohort_df <- panel %>%
  filter(first_treat > 0) %>%
  mutate(cohort = case_when(
    ebt_year <= 1997 ~ "Early (1996-1997)",
    ebt_year <= 2000 ~ "Mid (1998-2000)",
    TRUE ~ "Late (2001-2005)"
  )) %>%
  group_by(cohort, year) %>%
  summarise(mean_property = mean(property_crime_rate, na.rm = TRUE),
            mean_burglary = mean(burglary_rate, na.rm = TRUE),
            .groups = "drop")

fwrite(cohort_df, file.path(data_dir, "cohort_trends_plot.csv"))

fig5 <- cohort_df %>%
  ggplot(aes(x = year, y = mean_property, color = cohort)) +
  geom_line(linewidth = 1) +
  labs(x = "Year",
       y = "Property Crime Rate (per 100,000)",
       color = "EBT Adoption Cohort") +
  scale_color_manual(values = c("#2166AC", "#B2182B", "#4DAF4A")) +
  theme_apep()

ggsave(file.path(fig_dir, "fig5_cohort_trends.pdf"), fig5, width = 8, height = 5)

# ===========================================================================
# Figure 6: Leave-One-Out Sensitivity
# ===========================================================================
cat("Figure 6: LOO sensitivity...\n")

main_att <- cs_results$agg_property$overall.att

fig6 <- loo_results %>%
  mutate(dropped_state = fct_reorder(dropped_state, property_att)) %>%
  ggplot(aes(x = dropped_state, y = property_att)) +
  geom_hline(yintercept = 0, color = "grey50", linetype = "dashed") +
  geom_hline(yintercept = main_att, color = "#2166AC", linetype = "solid", linewidth = 0.5) +
  geom_point(color = "#2166AC", size = 2) +
  labs(x = "Dropped State",
       y = "CS-DiD ATT (Log Property Crime)") +
  coord_flip() +
  theme_apep(base_size = 9)

ggsave(file.path(fig_dir, "fig6_loo.pdf"), fig6, width = 7, height = 9)

# ===========================================================================
# Figure 7: Main Results Summary (Coefficient Plot)
# ===========================================================================
cat("Figure 7: Coefficient plot...\n")

coef_df <- main_results %>%
  select(Outcome, CS_ATT, CS_SE) %>%
  mutate(
    ci_lo = CS_ATT - 1.96 * CS_SE,
    ci_hi = CS_ATT + 1.96 * CS_SE,
    Outcome = factor(Outcome, levels = rev(c("Property Crime", "Burglary",
                                              "Larceny-Theft", "Robbery",
                                              "Motor Vehicle Theft (Placebo)")))
  )

fwrite(coef_df, file.path(data_dir, "coef_plot.csv"))

fig7 <- coef_df %>%
  ggplot(aes(x = CS_ATT, y = Outcome)) +
  geom_vline(xintercept = 0, color = "grey50", linetype = "dashed") +
  geom_errorbarh(aes(xmin = ci_lo, xmax = ci_hi), height = 0.2,
                 color = "#2166AC", linewidth = 0.7) +
  geom_point(color = "#2166AC", size = 3) +
  labs(x = "CS-DiD ATT (Log Crime Rate)",
       y = "") +
  theme_apep()

ggsave(file.path(fig_dir, "fig7_coef_plot.pdf"), fig7, width = 7, height = 4)

# ===========================================================================
# Figure A1: Raw Crime Trends (National)
# ===========================================================================
cat("Figure A1: National crime trends...\n")

natl_trends <- panel %>%
  group_by(year) %>%
  summarise(
    property = mean(property_crime_rate, na.rm = TRUE),
    burglary = mean(burglary_rate, na.rm = TRUE),
    larceny = mean(larceny_rate, na.rm = TRUE),
    mvt = mean(motor_vehicle_theft_rate, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_longer(-year, names_to = "crime_type", values_to = "rate") %>%
  mutate(crime_type = case_when(
    crime_type == "property" ~ "Property Crime",
    crime_type == "burglary" ~ "Burglary",
    crime_type == "larceny" ~ "Larceny-Theft",
    crime_type == "mvt" ~ "Motor Vehicle Theft"
  ))

fwrite(natl_trends, file.path(data_dir, "national_trends_plot.csv"))

figA1 <- natl_trends %>%
  ggplot(aes(x = year, y = rate, color = crime_type)) +
  geom_line(linewidth = 1) +
  geom_rect(aes(xmin = 1996, xmax = 2005, ymin = -Inf, ymax = Inf),
            fill = "grey90", alpha = 0.01, color = NA, inherit.aes = FALSE) +
  geom_line(linewidth = 1) +
  labs(x = "Year", y = "Crime Rate (per 100,000)",
       color = "Crime Type") +
  scale_color_brewer(palette = "Set1") +
  annotate("text", x = 2000.5, y = 100, label = "EBT Rollout\nPeriod",
           size = 3, color = "grey40") +
  theme_apep()

ggsave(file.path(fig_dir, "figA1_national_trends.pdf"), figA1, width = 8, height = 5)

cat("=== All figures saved ===\n")
