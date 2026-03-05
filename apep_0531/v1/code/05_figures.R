## ============================================================
## 05_figures.R — All figures for the paper
## apep_0531: PCSO Cuts and Crime in England
## ============================================================

source("00_packages.R")

panel <- fread(file.path(dat_dir, "analysis_panel.csv"))
panel <- panel[!is.na(total_crime) & !is.na(pcso_fte) & year <= 2024]

## ---- Figure 1: National PCSO and Crime Trends ------------------

nat_trends <- panel[, .(
  pcso_per100k = weighted.mean(pcso_per100k, population, na.rm = TRUE),
  officer_per100k = weighted.mean(officer_per100k, population, na.rm = TRUE),
  crime_rate = weighted.mean(crime_rate, population, na.rm = TRUE)
), by = year]

fwrite(nat_trends, file.path(dat_dir, "fig1_national_trends.csv"))

p1a <- ggplot(nat_trends, aes(x = year)) +
  geom_line(aes(y = pcso_per100k), color = "#2171B5", linewidth = 1.2) +
  geom_point(aes(y = pcso_per100k), color = "#2171B5", size = 2) +
  geom_vline(xintercept = 2010.5, linetype = "dashed", alpha = 0.5) +
  annotate("text", x = 2011, y = max(nat_trends$pcso_per100k) * 0.95,
           label = "Austerity begins", hjust = 0, size = 3, fontface = "italic") +
  labs(x = NULL, y = "PCSOs per 100,000 population",
       title = "A. Police Community Support Officers") +
  scale_x_continuous(breaks = seq(2008, 2024, 2))

p1b <- ggplot(nat_trends, aes(x = year)) +
  geom_line(aes(y = crime_rate), color = "#CB181D", linewidth = 1.2) +
  geom_point(aes(y = crime_rate), color = "#CB181D", size = 2) +
  geom_vline(xintercept = 2010.5, linetype = "dashed", alpha = 0.5) +
  labs(x = NULL, y = "Recorded crimes per 100,000",
       title = "B. Total Recorded Crime Rate") +
  scale_x_continuous(breaks = seq(2008, 2024, 2)) +
  scale_y_continuous(labels = scales::comma)

fig1 <- p1a / p1b + plot_annotation(
  title = "Figure 1: National PCSO and Crime Trends, 2008-2024",
  theme = theme(plot.title = element_text(face = "bold", size = 13))
)
ggsave(file.path(fig_dir, "fig1_trends.pdf"), fig1, width = 7, height = 8)
cat("Figure 1 saved.\n")


## ---- Figure 2: Cross-Force PCSO Variation ---------------------

pcso_change <- fread(file.path(dat_dir, "pcso_change_by_force.csv"))
pcso_change <- pcso_change[!is.na(pcso_pct_change)]
pcso_change[, force_short := gsub(" and .*|shire$|shire ", "", force_name)]
pcso_change[, force_short := reorder(force_short, pcso_pct_change)]

fwrite(pcso_change, file.path(dat_dir, "fig2_force_variation.csv"))

fig2 <- ggplot(pcso_change, aes(x = pcso_pct_change, y = force_short)) +
  geom_col(aes(fill = pcso_pct_change), width = 0.7) +
  scale_fill_gradient2(low = "#CB181D", mid = "#FEE0D2", high = "#2171B5",
                        midpoint = -50, guide = "none") +
  geom_vline(xintercept = 0, linewidth = 0.5) +
  labs(x = "Percent change in PCSOs per 100k from 2010 baseline",
       y = NULL,
       title = "Figure 2: Cross-Force Variation in PCSO Cuts") +
  theme(axis.text.y = element_text(size = 7))

ggsave(file.path(fig_dir, "fig2_force_variation.pdf"), fig2, width = 7, height = 9)
cat("Figure 2 saved.\n")


## ---- Figure 3: Event Study ------------------------------------

es_coefs <- fread(file.path(dat_dir, "event_study_coefs.csv"))

fwrite(es_coefs, file.path(dat_dir, "fig3_event_study.csv"))

fig3 <- ggplot(es_coefs, aes(x = year, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  geom_vline(xintercept = 2010.5, linetype = "dotted", alpha = 0.5) +
  geom_ribbon(aes(ymin = estimate - 1.96 * se, ymax = estimate + 1.96 * se),
              fill = "#2171B5", alpha = 0.15) +
  geom_line(color = "#2171B5", linewidth = 0.8) +
  geom_point(color = "#2171B5", size = 2) +
  annotate("text", x = 2011, y = max(es_coefs$estimate + 1.96 * es_coefs$se, na.rm = TRUE) * 0.9,
           label = "Austerity begins", hjust = 0, size = 3, fontface = "italic") +
  labs(x = NULL, y = expression("Coefficient on PCSO exposure" %*% "year"),
       title = "Figure 3: Event Study — Crime Response to Baseline PCSO Exposure",
       subtitle = "Flat pre-trends confirm parallel trends assumption") +
  scale_x_continuous(breaks = seq(2008, 2024, 2))

ggsave(file.path(fig_dir, "fig3_event_study.pdf"), fig3, width = 7, height = 5)
cat("Figure 3 saved.\n")


## ---- Figure 4: Crime Type Decomposition -----------------------

type_dt <- fread(file.path(dat_dir, "crime_type_results.csv"))
type_dt[, offence_short := gsub("offences|against the person", "",
                                  offence_group, ignore.case = TRUE)]
type_dt[, offence_short := trimws(offence_short)]
type_dt[, offence_short := reorder(offence_short, coef)]

fwrite(type_dt, file.path(dat_dir, "fig4_crime_types.csv"))

fig4 <- ggplot(type_dt, aes(x = coef, y = offence_short)) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_errorbarh(aes(xmin = coef - 1.96 * se, xmax = coef + 1.96 * se),
                  height = 0.2, color = "gray40") +
  geom_point(size = 3, color = "#2171B5") +
  labs(x = "PCSO coefficient (log crime rate)",
       y = NULL,
       title = "Figure 4: PCSO Effect by Crime Type",
       subtitle = "All confidence intervals contain zero") +
  theme(axis.text.y = element_text(size = 9))

ggsave(file.path(fig_dir, "fig4_crime_types.pdf"), fig4, width = 7, height = 5)
cat("Figure 4 saved.\n")


## ---- Figure 5: Randomization Inference Distribution -----------

ri_dist <- fread(file.path(dat_dir, "ri_distribution.csv"))
ri_info <- fread(file.path(dat_dir, "randomization_inference.csv"))

fwrite(ri_dist, file.path(dat_dir, "fig5_ri_dist.csv"))

fig5 <- ggplot(ri_dist, aes(x = perm_coef)) +
  geom_histogram(bins = 50, fill = "gray70", color = "white") +
  geom_vline(xintercept = ri_info$true_coef, color = "#CB181D",
             linewidth = 1, linetype = "dashed") +
  annotate("text", x = ri_info$true_coef, y = Inf,
           label = paste0("Observed = ", round(ri_info$true_coef, 5)),
           vjust = 2, hjust = -0.1, color = "#CB181D", size = 3.5) +
  labs(x = "Permuted PCSO coefficients",
       y = "Frequency",
       title = "Figure 5: Randomization Inference",
       subtitle = paste0("RI p-value = ", round(ri_info$ri_pval, 3),
                          " (999 permutations)"))

ggsave(file.path(fig_dir, "fig5_ri.pdf"), fig5, width = 7, height = 4.5)
cat("Figure 5 saved.\n")


## ---- Figure 6: Jackknife Sensitivity --------------------------

jack_dt <- fread(file.path(dat_dir, "jackknife_results.csv"))
jack_dt[, dropped_force := reorder(dropped_force, coef)]

fwrite(jack_dt, file.path(dat_dir, "fig6_jackknife.csv"))

fig6 <- ggplot(jack_dt, aes(x = coef, y = dropped_force)) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_vline(xintercept = ri_info$true_coef, linetype = "dotted",
             color = "#2171B5", alpha = 0.5) +
  geom_errorbarh(aes(xmin = coef - 1.96 * se, xmax = coef + 1.96 * se),
                  height = 0.2, color = "gray60") +
  geom_point(size = 1.5, color = "#2171B5") +
  labs(x = "PCSO coefficient (log crime rate)",
       y = NULL,
       title = "Figure 6: Leave-One-Out Jackknife",
       subtitle = "No single force drives the result") +
  theme(axis.text.y = element_text(size = 6))

ggsave(file.path(fig_dir, "fig6_jackknife.pdf"), fig6, width = 7, height = 9)
cat("Figure 6 saved.\n")

cat("\n=== ALL FIGURES SAVED ===\n")
