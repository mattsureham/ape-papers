## =============================================================
## 05_figures.R — All figure generation
## apep_0544: Russian Gas Shock and European Manufacturing
## =============================================================

source("00_packages.R")

cat("=== GENERATING FIGURES ===\n")

## -----------------------------------------------------------------
## Load pre-computed results (data-first rule)
## -----------------------------------------------------------------
panel       <- fread(file.path(DATA_DIR, "analysis_panel.csv"))
es_coefs    <- fread(file.path(DATA_DIR, "event_study_coefs.csv"))
loo_results <- fread(file.path(DATA_DIR, "loo_results.csv"))
perm_dt     <- fread(file.path(DATA_DIR, "permutation_results.csv"))
dynamic_dt  <- fread(file.path(DATA_DIR, "dynamic_effects.csv"))

panel[, year_month := as.Date(year_month)]

## -----------------------------------------------------------------
## Figure 1: Motivating — Production in Chemicals (C20) by country
## -----------------------------------------------------------------
cat("  Figure 1: Motivating raw trends...\n")

# Select key countries with varying Russian gas exposure
key_countries <- c("DE", "IT", "FR", "ES", "PL", "FI", "NL")
chem <- panel[nace_r2 == "C20" & geo %in% key_countries]

# Merge country names and gas share
country_labels <- data.table(
  geo = key_countries,
  label = c("Germany (66%)", "Italy (40%)", "France (24%)",
            "Spain (9%)", "Poland (57%)", "Finland (75%)", "Netherlands (30%)")
)
chem <- merge(chem, country_labels, by = "geo")

fig1 <- ggplot(chem, aes(x = year_month, y = value, color = label, group = label)) +
  geom_line(linewidth = 0.8) +
  geom_vline(xintercept = as.Date("2022-02-24"), linetype = "dashed", color = "red",
             linewidth = 0.5) +
  annotate("text", x = as.Date("2022-04-01"), y = max(chem$value, na.rm = TRUE) * 0.98,
           label = "Russian invasion\n(Feb 24, 2022)", hjust = 0, size = 3, color = "red") +
  scale_color_viridis_d(option = "D", end = 0.9) +
  labs(
    title = "Chemicals Production (NACE C20) by Russian Gas Dependence",
    subtitle = "Index 2015=100, seasonally adjusted. Parentheses show 2021 Russian gas import share.",
    x = NULL, y = "Production Index (2015=100)",
    color = "Country (Russian gas share)"
  ) +
  theme(legend.position = "right")

ggsave(file.path(FIG_DIR, "fig1_chemicals_by_country.pdf"), fig1,
       width = 10, height = 6)

## -----------------------------------------------------------------
## Figure 2: Event Study — Main identification
## -----------------------------------------------------------------
cat("  Figure 2: Event study...\n")

fig2 <- ggplot(es_coefs, aes(x = rel_month, y = estimate)) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "steelblue") +
  geom_line(color = "steelblue", linewidth = 0.8) +
  geom_point(color = "steelblue", size = 1.5) +
  geom_hline(yintercept = 0, linetype = "solid", color = "gray40") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red", linewidth = 0.5) +
  annotate("text", x = 1, y = max(es_coefs$ci_hi) * 0.95,
           label = "Invasion", hjust = 0, size = 3, color = "red") +
  labs(
    title = "Event Study: Effect of Gas Dependence on Industrial Production",
    subtitle = expression("Coefficients on RussianGasShare" %*% "GasIntensity" %*% "1(t=k). Triple FE. 95% CI."),
    x = "Months relative to Feb 2022",
    y = expression("Coefficient " * hat(beta)[k])
  ) +
  scale_x_continuous(breaks = seq(-24, 30, 6))

ggsave(file.path(FIG_DIR, "fig2_event_study.pdf"), fig2,
       width = 10, height = 6)

## -----------------------------------------------------------------
## Figure 3: Treatment variation — Scatter of GasShare x GasIntensity
## -----------------------------------------------------------------
cat("  Figure 3: Treatment variation...\n")

treat_var <- unique(panel[, .(geo, nace_r2, russian_gas_share_2021,
                               gas_intensity, treatment_intensity)])

fig3 <- ggplot(treat_var, aes(x = russian_gas_share_2021, y = gas_intensity)) +
  geom_point(aes(size = treatment_intensity), alpha = 0.4, color = "steelblue") +
  geom_text(data = treat_var[treatment_intensity > quantile(treatment_intensity, 0.95)],
            aes(label = paste0(geo, "-", nace_r2)),
            size = 2.5, vjust = -0.5) +
  scale_size_continuous(range = c(0.5, 5), guide = "none") +
  labs(
    title = "Treatment Intensity: Country Gas Dependence x Sector Gas Intensity",
    subtitle = "Each point is a country-sector pair. Labeled: top 5% treatment intensity.",
    x = "Russian Gas Import Share (2021)",
    y = "Sector Gas Intensity (2019)"
  )

ggsave(file.path(FIG_DIR, "fig3_treatment_variation.pdf"), fig3,
       width = 8, height = 6)

## -----------------------------------------------------------------
## Figure 4: Leave-one-country-out
## -----------------------------------------------------------------
cat("  Figure 4: Leave-one-out...\n")

main_beta <- fread(file.path(DATA_DIR, "key_results.csv"))
main_est <- main_beta[model == "CS + CT + ST FE", beta]

loo_results[, excluded := factor(excluded,
  levels = loo_results[order(beta), excluded])]

fig4 <- ggplot(loo_results, aes(x = excluded, y = beta)) +
  geom_point(color = "steelblue", size = 2) +
  geom_errorbar(aes(ymin = beta - 1.96 * se, ymax = beta + 1.96 * se),
                width = 0.3, color = "steelblue") +
  geom_hline(yintercept = main_est, linetype = "dashed", color = "red") +
  geom_hline(yintercept = 0, linetype = "solid", color = "gray40") +
  coord_flip() +
  labs(
    title = "Leave-One-Country-Out Sensitivity",
    subtitle = "Dashed red line = full-sample estimate. 95% CI shown.",
    x = "Country excluded",
    y = expression("Coefficient " * hat(beta))
  )

ggsave(file.path(FIG_DIR, "fig4_leave_one_out.pdf"), fig4,
       width = 8, height = 8)

## -----------------------------------------------------------------
## Figure 5: Permutation inference
## -----------------------------------------------------------------
cat("  Figure 5: Permutation inference...\n")

actual <- perm_dt[1, actual_beta]
ri_p <- perm_dt[1, ri_p_value]

fig5 <- ggplot(perm_dt, aes(x = perm_beta)) +
  geom_histogram(bins = 50, fill = "gray70", color = "white") +
  geom_vline(xintercept = actual, color = "red", linewidth = 1, linetype = "dashed") +
  annotate("text", x = actual, y = Inf,
           label = paste0("Actual = ", round(actual, 4), "\nRI p = ", round(ri_p, 3)),
           hjust = -0.1, vjust = 1.5, size = 3.5, color = "red") +
  labs(
    title = "Permutation Inference: Randomly Reassigning Gas Dependence",
    subtitle = paste0(nrow(perm_dt), " permutations. Red line = actual estimate."),
    x = expression("Permuted " * hat(beta)),
    y = "Count"
  )

ggsave(file.path(FIG_DIR, "fig5_permutation_inference.pdf"), fig5,
       width = 8, height = 5)

## -----------------------------------------------------------------
## Figure 6: Binned scatter — Treatment intensity vs production change
## -----------------------------------------------------------------
cat("  Figure 6: Binned scatter...\n")

# Compute pre-post change in log IP by country-sector
pre_mean <- panel[post == 0, .(pre_logip = mean(log_ip, na.rm = TRUE)),
                   by = .(geo, nace_r2, treatment_intensity)]
post_mean <- panel[post == 1, .(post_logip = mean(log_ip, na.rm = TRUE)),
                    by = .(geo, nace_r2)]
change_dt <- merge(pre_mean, post_mean, by = c("geo", "nace_r2"))
change_dt[, delta_logip := post_logip - pre_logip]

# Create 20 bins of treatment intensity
change_dt[, intensity_bin := cut(treatment_intensity, breaks = 20,
                                  labels = FALSE)]
binned <- change_dt[, .(mean_intensity = mean(treatment_intensity),
                         mean_delta = mean(delta_logip),
                         se_delta = sd(delta_logip) / sqrt(.N),
                         n = .N),
                     by = intensity_bin]

fig6 <- ggplot(binned, aes(x = mean_intensity, y = mean_delta)) +
  geom_point(aes(size = n), color = "steelblue", alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE, color = "red", linewidth = 0.8) +
  geom_hline(yintercept = 0, linetype = "solid", color = "gray40") +
  scale_size_continuous(range = c(2, 8)) +
  labs(
    title = "Treatment Intensity vs. Production Change",
    subtitle = "Each point = ventile of GasShare x GasIntensity. Line = OLS fit.",
    x = expression("Treatment Intensity (RussianGasShare" %*% "GasIntensity)"),
    y = expression(Delta * " log(IP): Post minus Pre"),
    size = "N obs"
  )

ggsave(file.path(FIG_DIR, "fig6_binscatter.pdf"), fig6,
       width = 8, height = 6)

## -----------------------------------------------------------------
## Figure 7: Recovery dynamics
## -----------------------------------------------------------------
cat("  Figure 7: Recovery dynamics...\n")

if (nrow(dynamic_dt) > 0) {
  dynamic_dt[, ci_lo := beta - 1.96 * se]
  dynamic_dt[, ci_hi := beta + 1.96 * se]

  # Add pre-period reference
  dynamic_plot <- rbind(
    data.table(year = "<2022", beta = 0, se = 0, ci_lo = 0, ci_hi = 0),
    dynamic_dt
  )
  dynamic_plot[, year := factor(year, levels = c("<2022", "2022", "2023", "2024"))]

  fig7 <- ggplot(dynamic_plot, aes(x = year, y = beta)) +
    geom_point(color = "steelblue", size = 3) +
    geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0.2, color = "steelblue") +
    geom_hline(yintercept = 0, linetype = "solid", color = "gray40") +
    labs(
      title = "Dynamic Treatment Effects by Year",
      subtitle = "Effect of gas dependence on manufacturing production, relative to pre-2022.",
      x = NULL,
      y = expression("Coefficient " * hat(beta))
    )

  ggsave(file.path(FIG_DIR, "fig7_recovery_dynamics.pdf"), fig7,
         width = 7, height = 5)
}

## -----------------------------------------------------------------
## Figure 8: Gas dependence map (heatmap)
## -----------------------------------------------------------------
cat("  Figure 8: Gas share by country...\n")

country_gas <- unique(panel[, .(geo, russian_gas_share_2021)])
country_gas <- country_gas[order(-russian_gas_share_2021)]
country_gas[, geo := factor(geo, levels = geo)]

fig8 <- ggplot(country_gas, aes(x = geo, y = russian_gas_share_2021,
                                 fill = russian_gas_share_2021)) +
  geom_col() +
  scale_fill_viridis_c(option = "C", direction = -1, label = percent) +
  scale_y_continuous(labels = percent) +
  coord_flip() +
  labs(
    title = "Pre-War Russian Gas Dependence (2021)",
    subtitle = "Share of total natural gas imports from Russia",
    x = NULL, y = "Russian Gas Import Share",
    fill = "Share"
  ) +
  theme(legend.position = "none")

ggsave(file.path(FIG_DIR, "fig8_gas_dependence.pdf"), fig8,
       width = 7, height = 7)

cat("\n=== ALL FIGURES GENERATED ===\n")
cat("Figures saved to:", FIG_DIR, "\n")
