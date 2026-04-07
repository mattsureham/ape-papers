## 05_figures.R — Generate all figures
## apep_1408: PNIS coca substitution in Colombia

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
panel <- panel %>%
  mutate(cohort = if_else(first_treat == 0, Inf, as.numeric(first_treat)))

# APEP theme
theme_apep <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "gray40"),
    legend.position = "bottom",
    axis.title = element_text(size = 10)
  )

## ─────────────────────────────────────────────────
## Figure 1: Event Study — Sun-Abraham (main result)
## ─────────────────────────────────────────────────

sunab_est <- readRDS(file.path(data_dir, "sunab_results.rds"))

es_df <- broom::tidy(sunab_est, conf.int = TRUE) %>%
  mutate(
    rel_time = as.integer(gsub("year::", "", term)),
    significant = p.value < 0.05
  ) %>%
  filter(rel_time >= -10, rel_time <= 6)

p1 <- ggplot(es_df, aes(x = rel_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "red", alpha = 0.6) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = 0.15, fill = "steelblue") +
  geom_point(aes(color = significant), size = 2) +
  geom_line(color = "steelblue", alpha = 0.5) +
  scale_color_manual(values = c("TRUE" = "steelblue", "FALSE" = "gray60"),
                     labels = c("TRUE" = "p < 0.05", "FALSE" = "p ≥ 0.05"),
                     name = NULL) +
  scale_x_continuous(breaks = seq(-10, 6, 2)) +
  labs(
    title = "Event Study: Coca Cultivation in PNIS Municipalities",
    subtitle = "Sun-Abraham estimator, IHS coca hectares, relative to year before enrollment",
    x = "Years Relative to PNIS Enrollment",
    y = "ATT (IHS Coca Hectares)"
  ) +
  theme_apep +
  annotate("text", x = 2, y = max(es_df$estimate) * 0.9,
           label = "Year +2 spike", color = "steelblue", size = 3, fontface = "italic")

ggsave(file.path(fig_dir, "fig1_event_study.pdf"), p1, width = 7, height = 5)
cat("Figure 1 saved.\n")

## ─────────────────────────────────────────────────
## Figure 2: Raw means — PNIS vs non-PNIS municipalities
## ─────────────────────────────────────────────────

means <- panel %>%
  mutate(group = if_else(pnis_enrolled == 1, "PNIS Municipalities", "Non-PNIS Coca Municipalities")) %>%
  group_by(group, year) %>%
  summarize(
    mean_coca = mean(coca_ha, na.rm = TRUE),
    se_coca = sd(coca_ha, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )

p2 <- ggplot(means, aes(x = year, y = mean_coca, color = group, fill = group)) +
  geom_ribbon(aes(ymin = mean_coca - 1.96 * se_coca,
                  ymax = mean_coca + 1.96 * se_coca), alpha = 0.1, color = NA) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_vline(xintercept = 2017, linetype = "dashed", color = "red", alpha = 0.5) +
  scale_color_manual(values = c("PNIS Municipalities" = "steelblue",
                                "Non-PNIS Coca Municipalities" = "gray50")) +
  scale_fill_manual(values = c("PNIS Municipalities" = "steelblue",
                               "Non-PNIS Coca Municipalities" = "gray50")) +
  labs(
    title = "Average Coca Cultivation: PNIS vs. Non-PNIS Municipalities",
    subtitle = "Mean hectares of coca, 2001–2023. Vertical line: PNIS enrollment begins (2017)",
    x = "Year",
    y = "Mean Coca Hectares",
    color = NULL, fill = NULL
  ) +
  theme_apep +
  annotate("text", x = 2017.5, y = max(means$mean_coca) * 0.95,
           label = "PNIS\nbegins", color = "red", size = 3, hjust = 0)

ggsave(file.path(fig_dir, "fig2_raw_means.pdf"), p2, width = 7, height = 5)
cat("Figure 2 saved.\n")

## ─────────────────────────────────────────────────
## Figure 3: Treatment rollout map (distribution by department)
## ─────────────────────────────────────────────────

pnis_raw <- readRDS(file.path(data_dir, "pnis_raw.rds"))

dept_summary <- pnis_raw %>%
  mutate(n_fam = as.numeric(pagos_asistencia_alimentaria)) %>%
  group_by(departamento) %>%
  summarize(
    n_munis = n(),
    total_families = sum(n_fam, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(total_families))

p3 <- ggplot(dept_summary, aes(x = reorder(departamento, total_families), y = total_families)) +
  geom_col(fill = "steelblue", alpha = 0.8) +
  geom_text(aes(label = paste0(n_munis, " mun.")),
            hjust = -0.1, size = 2.8, color = "gray30") +
  coord_flip() +
  labs(
    title = "PNIS Enrollment by Department",
    subtitle = "Total families enrolled and number of municipalities",
    x = NULL,
    y = "Families Enrolled"
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.2)),
                     labels = comma) +
  theme_apep

ggsave(file.path(fig_dir, "fig3_enrollment_by_dept.pdf"), p3, width = 7, height = 5)
cat("Figure 3 saved.\n")

## ─────────────────────────────────────────────────
## Figure 4: Coca dynamics by cohort
## ─────────────────────────────────────────────────

cohort_means <- panel %>%
  filter(pnis_enrolled == 1) %>%
  mutate(wave = paste0("Wave ", first_treat - 2016, " (", first_treat, ")")) %>%
  group_by(wave, year) %>%
  summarize(
    mean_coca = mean(coca_ha, na.rm = TRUE),
    .groups = "drop"
  )

p4 <- ggplot(cohort_means, aes(x = year, y = mean_coca, color = wave)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  geom_vline(xintercept = c(2017, 2018), linetype = "dashed", color = "gray60", alpha = 0.5) +
  labs(
    title = "Coca Cultivation Trajectories by PNIS Enrollment Wave",
    subtitle = "Mean hectares, PNIS municipalities only",
    x = "Year",
    y = "Mean Coca Hectares",
    color = NULL
  ) +
  theme_apep

ggsave(file.path(fig_dir, "fig4_cohort_dynamics.pdf"), p4, width = 7, height = 5)
cat("Figure 4 saved.\n")

## ─────────────────────────────────────────────────
## Figure 5: Eradication event study
## ─────────────────────────────────────────────────

es_erad <- readRDS(file.path(data_dir, "es_erad_results.rds"))

es_erad_df <- data.frame(
  rel_time = es_erad$egt,
  estimate = es_erad$att.egt,
  se = es_erad$se.egt
) %>%
  mutate(
    conf.low = estimate - 1.96 * se,
    conf.high = estimate + 1.96 * se,
    significant = abs(estimate / se) > 1.96
  )

p5 <- ggplot(es_erad_df, aes(x = rel_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "red", alpha = 0.6) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = 0.15, fill = "darkgreen") +
  geom_point(aes(color = significant), size = 2) +
  geom_line(color = "darkgreen", alpha = 0.5) +
  scale_color_manual(values = c("TRUE" = "darkgreen", "FALSE" = "gray60"),
                     labels = c("TRUE" = "p < 0.05", "FALSE" = "p ≥ 0.05"),
                     name = NULL) +
  labs(
    title = "Event Study: Eradication Activity in PNIS Municipalities",
    subtitle = "Callaway-Sant'Anna, IHS eradication hectares",
    x = "Years Relative to PNIS Enrollment",
    y = "ATT (IHS Eradication Ha)"
  ) +
  theme_apep

ggsave(file.path(fig_dir, "fig5_erad_event_study.pdf"), p5, width = 7, height = 5)
cat("Figure 5 saved.\n")

## ─────────────────────────────────────────────────
## Figure 6: Dose-response (coca_2016 intensity)
## ─────────────────────────────────────────────────

dose_est <- readRDS(file.path(data_dir, "dose_results.rds"))

dose_df <- broom::tidy(dose_est, conf.int = TRUE) %>%
  mutate(year = as.integer(gsub("year::|:coca_2016", "", term))) %>%
  filter(!is.na(year))

p6 <- ggplot(dose_df, aes(x = year, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = 2016.5, linetype = "dotted", color = "red", alpha = 0.6) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = 0.15, fill = "darkorange") +
  geom_point(color = "darkorange", size = 2) +
  geom_line(color = "darkorange", alpha = 0.5) +
  labs(
    title = "Dose-Response: Coca Intensity and Post-PNIS Coca Cultivation",
    subtitle = "Interaction of baseline coca (2016) with year FE, within PNIS municipalities",
    x = "Year",
    y = "Coefficient on Coca(2016) x Year"
  ) +
  theme_apep

ggsave(file.path(fig_dir, "fig6_dose_response.pdf"), p6, width = 7, height = 5)
cat("Figure 6 saved.\n")

## ─────────────────────────────────────────────────
## Figure 7: Distribution of coca change (histogram)
## ─────────────────────────────────────────────────

coca_change <- panel %>%
  filter(pnis_enrolled == 1) %>%
  select(codmpio, year, coca_ha) %>%
  filter(year %in% c(2016, 2020)) %>%
  pivot_wider(names_from = year, values_from = coca_ha, names_prefix = "y") %>%
  mutate(change = y2020 - y2016,
         pct_change = (y2020 - y2016) / (y2016 + 1) * 100)

p7 <- ggplot(coca_change %>% filter(!is.na(change)), aes(x = change)) +
  geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7, color = "white") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
  labs(
    title = "Distribution of Coca Area Change in PNIS Municipalities",
    subtitle = "Change in hectares, 2016 to 2020 (3 years post-enrollment)",
    x = "Change in Coca Hectares (2020 − 2016)",
    y = "Number of Municipalities"
  ) +
  theme_apep +
  annotate("text", x = median(coca_change$change, na.rm = TRUE), y = Inf,
           label = paste0("Median: ", round(median(coca_change$change, na.rm = TRUE), 0), " ha"),
           vjust = 1.5, size = 3.5, fontface = "italic")

ggsave(file.path(fig_dir, "fig7_coca_change_dist.pdf"), p7, width = 7, height = 5)
cat("Figure 7 saved.\n")

cat("\nAll figures generated.\n")
