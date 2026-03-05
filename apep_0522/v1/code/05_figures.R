## ============================================================
## 05_figures.R — Generate all figures from saved data
## apep_0522: Flood Re and English Property Values
## ============================================================

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

## -------------------------------------------------------
## Figure 1: Event Study — Dynamic Treatment Effects
## -------------------------------------------------------

es_coefs <- fread(file.path(data_dir, "event_study_coefs.csv"))

# Add base year (rel_year = -1) as zero point — this is the omitted reference
base_row <- data.table(
  term = "rel_year::-1:flood_risk_high",
  estimate = 0, std.error = 0, statistic = NA_real_,
  p.value = NA_real_, conf.low = 0, conf.high = 0, rel_year = -1L
)
es_coefs <- rbind(es_coefs, base_row, fill = TRUE)
setorder(es_coefs, rel_year)

fig1 <- ggplot(es_coefs, aes(x = rel_year, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dashed", color = "firebrick",
             alpha = 0.5) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high),
              fill = "steelblue", alpha = 0.2) +
  geom_point(color = "steelblue", size = 2) +
  geom_line(color = "steelblue", linewidth = 0.5) +
  annotate("text", x = 0, y = max(es_coefs$conf.high, na.rm = TRUE) * 0.9,
           label = "Flood Re\nlaunched", hjust = 0, size = 3,
           color = "firebrick") +
  annotate("text", x = -2, y = min(es_coefs$conf.low, na.rm = TRUE) * 0.9,
           label = "Water Act\nannounced", hjust = 1, size = 3,
           color = "gray40") +
  geom_vline(xintercept = -2.5, linetype = "dotted", color = "gray40",
             alpha = 0.5) +
  scale_x_continuous(breaks = seq(-6, 9, 2)) +
  labs(
    x = "Years relative to launch",
    y = expression(hat(beta)[t] ~ "(log price)")
  )

ggsave(file.path(fig_dir, "fig1_event_study.pdf"), fig1,
       width = 7, height = 4.5)
cat("Figure 1 saved.\n")

## -------------------------------------------------------
## Figure 2: Dose-Response by Flood Risk Band
## -------------------------------------------------------

dose_coefs <- fread(file.path(data_dir, "dose_response_coefs.csv"))

# Extract dose level from term name
dose_coefs[, dose := as.integer(str_extract(term, "[0-9]+"))]
dose_coefs[, risk_label := fcase(
  dose == 1, "Low",
  dose == 2, "Medium",
  dose == 3, "High"
)]
dose_coefs[, pct_effect := 100 * (exp(estimate) - 1)]
dose_coefs[, pct_lo := 100 * (exp(conf.low) - 1)]
dose_coefs[, pct_hi := 100 * (exp(conf.high) - 1)]

# Add zero reference
dose_plot <- rbind(
  data.table(dose = 0, risk_label = "None\n(reference)",
             pct_effect = 0, pct_lo = 0, pct_hi = 0),
  dose_coefs[, .(dose, risk_label, pct_effect, pct_lo, pct_hi)]
)
dose_plot[, risk_label := factor(risk_label,
  levels = c("None\n(reference)", "Low", "Medium", "High"))]

fig2 <- ggplot(dose_plot, aes(x = risk_label, y = pct_effect)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_errorbar(aes(ymin = pct_lo, ymax = pct_hi),
                width = 0.15, color = "steelblue") +
  geom_point(size = 3, color = "steelblue") +
  labs(
    x = "EA Flood Risk Band",
    y = "Price effect (%)"
  )

ggsave(file.path(fig_dir, "fig2_dose_response.pdf"), fig2,
       width = 5, height = 4.5)
cat("Figure 2 saved.\n")

## -------------------------------------------------------
## Figure 3: Heterogeneity by Property Type
## -------------------------------------------------------

hetero_pt <- fread(file.path(data_dir, "heterogeneity_property_type.csv"))

if (nrow(hetero_pt) > 0) {
  hetero_pt[, pct_effect := 100 * (exp(coef) - 1)]
  hetero_pt[, ci_lo := 100 * (exp(coef - 1.96 * se) - 1)]
  hetero_pt[, ci_hi := 100 * (exp(coef + 1.96 * se) - 1)]
  hetero_pt[, property_type := factor(property_type,
    levels = c("Detached", "Semi-Detached", "Terraced", "Flat"))]

  fig3 <- ggplot(hetero_pt, aes(x = property_type, y = pct_effect)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi),
                  width = 0.15, color = "steelblue") +
    geom_point(size = 3, color = "steelblue") +
    labs(
      x = "Property Type",
      y = "Price effect (%)"
    )

  ggsave(file.path(fig_dir, "fig3_heterogeneity_property.pdf"), fig3,
         width = 5, height = 4.5)
  cat("Figure 3 saved.\n")
}

## -------------------------------------------------------
## Figure 4: Regional Heterogeneity
## -------------------------------------------------------

hetero_reg <- fread(file.path(data_dir, "heterogeneity_region.csv"))

if (nrow(hetero_reg) > 0) {
  hetero_reg[, pct_effect := 100 * (exp(coef) - 1)]
  hetero_reg[, ci_lo := 100 * (exp(coef - 1.96 * se) - 1)]
  hetero_reg[, ci_hi := 100 * (exp(coef + 1.96 * se) - 1)]

  fig4 <- ggplot(hetero_reg[order(pct_effect)],
                  aes(x = reorder(region, pct_effect), y = pct_effect)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi),
                  width = 0.15, color = "steelblue") +
    geom_point(size = 3, color = "steelblue") +
    coord_flip() +
    labs(
      x = "",
      y = "Price effect (%)"
    )

  ggsave(file.path(fig_dir, "fig4_heterogeneity_region.pdf"), fig4,
         width = 6, height = 5)
  cat("Figure 4 saved.\n")
}

## -------------------------------------------------------
## Figure 5: Raw Trends — Flood vs Non-Flood
## -------------------------------------------------------

# Create annual averages
panel <- fread(file.path(data_dir, "analysis_panel.csv"))

trends <- panel[, .(
  mean_ln_price = mean(ln_price),
  median_price = median(price),
  n = .N
), by = .(year, flood_risk_high)]

trends[, group := ifelse(flood_risk_high == 1,
                          "Flood risk (High/Medium)", "Non-flood-risk")]

fig5 <- ggplot(trends, aes(x = year, y = mean_ln_price,
                             color = group, linetype = group)) +
  geom_vline(xintercept = 2016, linetype = "dashed", color = "gray50") +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  annotate("text", x = 2016.3, y = max(trends$mean_ln_price),
           label = "Flood Re", hjust = 0, size = 3, color = "gray40") +
  scale_color_manual(values = c("Flood risk (High/Medium)" = "steelblue",
                                 "Non-flood-risk" = "gray60")) +
  scale_linetype_manual(values = c("Flood risk (High/Medium)" = "solid",
                                    "Non-flood-risk" = "dashed")) +
  labs(
    x = "Year",
    y = "Mean log price",
    color = "", linetype = "",
    title = NULL
  )

ggsave(file.path(fig_dir, "fig5_raw_trends.pdf"), fig5,
       width = 7, height = 4.5)

# Save underlying data
fwrite(trends, file.path(data_dir, "fig5_trends_data.csv"))
cat("Figure 5 saved.\n")

## -------------------------------------------------------
## Figure 6: Transaction Volume Trends
## -------------------------------------------------------

vol_trends <- panel[, .(n_transactions = .N),
                     by = .(year, quarter, flood_risk_high)]
vol_trends[, year_q := year + (quarter - 1) / 4]
vol_trends[, group := ifelse(flood_risk_high == 1,
                              "Flood risk", "Non-flood-risk")]

# Normalize to 2015 = 100 for visual comparison
vol_trends[, base_vol := mean(n_transactions[year == 2015]),
           by = flood_risk_high]
vol_trends[, vol_index := 100 * n_transactions / base_vol]

fig6 <- ggplot(vol_trends, aes(x = year_q, y = vol_index,
                                color = group)) +
  geom_vline(xintercept = 2016.25, linetype = "dashed", color = "gray50") +
  geom_line(linewidth = 0.6) +
  scale_color_manual(values = c("Flood risk" = "steelblue",
                                 "Non-flood-risk" = "gray60")) +
  labs(
    x = "Year",
    y = "Transaction volume (2015 = 100)",
    color = "",
    title = NULL
  )

ggsave(file.path(fig_dir, "fig6_volume_trends.pdf"), fig6,
       width = 7, height = 4.5)

fwrite(vol_trends, file.path(data_dir, "fig6_volume_data.csv"))
cat("Figure 6 saved.\n")

cat("\n=== ALL FIGURES GENERATED ===\n")
