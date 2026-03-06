## 05_figures.R — Generate all publication-quality figures
## APEP-0538: ZFE Housing Price Capitalization

source("00_packages.R")

data_dir <- "../data"
fig_dir <- "../figures"
dir.create(fig_dir, showWarnings = FALSE)

## =========================================================================
## Figure 1: Event study (main specification)
## =========================================================================

cat("=== Figure 1: Event study ===\n")

es_coefs <- fread(file.path(data_dir, "event_study_coefs.csv"))

## Add reference period (rel_quarter = -1, coef = 0)
ref_row <- data.table(estimate = 0, se = 0, tval = 0, pval = 1,
                       rel_quarter = -1, ci_lower = 0, ci_upper = 0)
es_coefs <- rbind(es_coefs, ref_row, fill = TRUE)
es_coefs <- es_coefs[order(rel_quarter)]

p1 <- ggplot(es_coefs, aes(x = rel_quarter, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "red", linewidth = 0.5) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "#2166AC") +
  geom_point(size = 2, color = "#2166AC") +
  geom_line(color = "#2166AC", linewidth = 0.5) +
  labs(
    x = "Quarters Relative to ZFE Adoption",
    y = "Effect on Log(Price/m2)",
    title = "Event Study: ZFE Impact on Housing Prices"
  ) +
  scale_x_continuous(breaks = seq(-12, 12, 2)) +
  annotate("text", x = -6, y = max(es_coefs$ci_upper, na.rm = TRUE) * 0.9,
           label = "Pre-ZFE", hjust = 0.5, size = 3.5, color = "gray40") +
  annotate("text", x = 6, y = max(es_coefs$ci_upper, na.rm = TRUE) * 0.9,
           label = "Post-ZFE", hjust = 0.5, size = 3.5, color = "gray40")

ggsave(file.path(fig_dir, "fig1_event_study.pdf"), p1,
       width = 8, height = 5, dpi = 300)
ggsave(file.path(fig_dir, "fig1_event_study.png"), p1,
       width = 8, height = 5, dpi = 300)
cat("  Saved fig1_event_study\n")

## =========================================================================
## Figure 2: Distance gradient (spillover test)
## =========================================================================

cat("=== Figure 2: Distance gradient ===\n")

grad <- fread(file.path(data_dir, "distance_gradient.csv"))

## Create ordered ring labels
ring_order <- c("outside_2_5km", "outside_1_2km", "outside_05_1km",
                "outside_0_05km", "inside_0_05km", "inside_05_1km",
                "inside_1_2km")
ring_labels <- c("2-5km\noutside", "1-2km\noutside", "0.5-1km\noutside",
                  "0-0.5km\noutside", "0-0.5km\ninside", "0.5-1km\ninside",
                  "1-2km\ninside")

## Add reference (outside 2-5km = 0)
ref_grad <- data.table(estimate = 0, se = 0, tval = 0, pval = 1,
                        ring = "outside_2_5km", ci_lower = 0, ci_upper = 0)
grad <- rbind(grad, ref_grad, fill = TRUE)
grad[, ring := factor(ring, levels = ring_order, labels = ring_labels)]
grad <- grad[!is.na(ring)]

## Color: inside = blue, outside = red
grad[, zone := fifelse(grepl("inside", as.character(ring)), "Inside ZFE", "Outside ZFE")]

p2 <- ggplot(grad, aes(x = ring, y = estimate, color = zone)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = 4.5, linetype = "dotted", color = "black", linewidth = 0.5) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.2, linewidth = 0.6) +
  geom_point(size = 3) +
  scale_color_manual(values = c("Inside ZFE" = "#2166AC", "Outside ZFE" = "#B2182B")) +
  labs(
    x = "Distance from ZFE Boundary",
    y = "Effect on Log(Price/m2)\n(relative to 2-5km outside)",
    title = "Distance Gradient: Price Effects Around ZFE Boundaries",
    color = NULL
  ) +
  annotate("text", x = 4.5, y = min(grad$ci_lower, na.rm = TRUE),
           label = "ZFE\nBoundary", hjust = 0.5, vjust = 1.2, size = 3, fontface = "bold")

ggsave(file.path(fig_dir, "fig2_distance_gradient.pdf"), p2,
       width = 8, height = 5, dpi = 300)
ggsave(file.path(fig_dir, "fig2_distance_gradient.png"), p2,
       width = 8, height = 5, dpi = 300)
cat("  Saved fig2_distance_gradient\n")

## =========================================================================
## Figure 3: Heterogeneity by property size (distributional incidence)
## =========================================================================

cat("=== Figure 3: Size heterogeneity ===\n")

q_coefs <- tryCatch(fread(file.path(data_dir, "heterogeneity_size.csv")), error = function(e) NULL)

if (!is.null(q_coefs) && nrow(q_coefs) > 0) {
  q_coefs[, quintile := factor(quintile, levels = paste0("Q", 1:5),
                                labels = c("Smallest\n20%", "Q2", "Q3", "Q4",
                                           "Largest\n20%"))]

  p3 <- ggplot(q_coefs, aes(x = quintile, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.2,
                  color = "#2166AC", linewidth = 0.6) +
    geom_point(size = 3, color = "#2166AC") +
    labs(
      x = "Apartment Size Quintile",
      y = "Effect on Log(Price/m2)",
      title = "Distributional Incidence: ZFE Effect by Property Size"
    )

  ggsave(file.path(fig_dir, "fig3_size_heterogeneity.pdf"), p3,
         width = 7, height = 5, dpi = 300)
  ggsave(file.path(fig_dir, "fig3_size_heterogeneity.png"), p3,
         width = 7, height = 5, dpi = 300)
  cat("  Saved fig3_size_heterogeneity\n")
} else {
  cat("  WARN: No size heterogeneity data available\n")
}

## =========================================================================
## Figure 4: Air quality first stage (time series)
## =========================================================================

cat("=== Figure 4: Air quality ===\n")

aq <- fread(file.path(data_dir, "air_quality_monthly.csv"))
city_coords <- fread(file.path(data_dir, "city_coordinates.csv"))

## Merge ZFE dates
aq <- merge(aq, city_coords[, .(city, zfe_start)], by = "city", all.x = TRUE)
aq[, date := as.Date(paste0(month, "-01"))]
aq[, zfe_date := as.Date(zfe_start)]

## Focus on cities with clear pre/post periods
focus_cities <- c("lyon", "toulouse", "nice", "marseille")
aq_focus <- aq[city %in% focus_cities]

p4 <- ggplot(aq_focus, aes(x = date, y = mean_no2, color = city)) +
  geom_line(alpha = 0.7) +
  geom_vline(data = aq_focus[, .(zfe_date = unique(zfe_date)), by = city],
             aes(xintercept = zfe_date, color = city),
             linetype = "dashed", linewidth = 0.5) +
  labs(
    x = "Date",
    y = expression(NO[2] ~ (mu*g/m^3)),
    title = "Air Quality Around ZFE Adoption",
    color = "City"
  ) +
  scale_color_viridis_d(option = "D", begin = 0.1, end = 0.9,
                         labels = c("Lyon", "Marseille", "Nice", "Toulouse")) +
  theme(legend.position = "right")

ggsave(file.path(fig_dir, "fig4_air_quality.pdf"), p4,
       width = 8, height = 5, dpi = 300)
ggsave(file.path(fig_dir, "fig4_air_quality.png"), p4,
       width = 8, height = 5, dpi = 300)
cat("  Saved fig4_air_quality\n")

## =========================================================================
## Figure 5: Bandwidth robustness
## =========================================================================

cat("=== Figure 5: Bandwidth robustness ===\n")

bw <- fread(file.path(data_dir, "robustness_bandwidth.csv"))

p5 <- ggplot(bw, aes(x = bandwidth_km, y = coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.15,
                color = "#2166AC", linewidth = 0.6) +
  geom_point(size = 3, color = "#2166AC") +
  geom_text(aes(label = format(n_obs, big.mark = ",")),
            vjust = -1.5, size = 3, color = "gray40") +
  labs(
    x = "Bandwidth (km from ZFE boundary)",
    y = "Effect on Log(Price/m2)",
    title = "Robustness to Boundary Bandwidth"
  ) +
  scale_x_continuous(breaks = bw$bandwidth_km)

ggsave(file.path(fig_dir, "fig5_bandwidth_robustness.pdf"), p5,
       width = 7, height = 5, dpi = 300)
ggsave(file.path(fig_dir, "fig5_bandwidth_robustness.png"), p5,
       width = 7, height = 5, dpi = 300)
cat("  Saved fig5_bandwidth_robustness\n")

## =========================================================================
## Figure 6: Randomization inference
## =========================================================================

cat("=== Figure 6: Randomization inference ===\n")

ri_dist <- fread(file.path(data_dir, "ri_distribution.csv"))
ri_result <- fread(file.path(data_dir, "randomization_inference.csv"))

p6 <- ggplot(ri_dist, aes(x = coef)) +
  geom_histogram(bins = 50, fill = "gray70", color = "gray50", alpha = 0.7) +
  geom_vline(xintercept = ri_result$actual_coef, color = "#B2182B",
             linewidth = 1, linetype = "solid") +
  geom_vline(xintercept = -ri_result$actual_coef, color = "#B2182B",
             linewidth = 0.5, linetype = "dashed") +
  labs(
    x = "Permuted Treatment Effect",
    y = "Count",
    title = paste0("Randomization Inference (", ri_result$n_perms,
                    " permutations, p = ", round(ri_result$ri_pval, 3), ")")
  ) +
  annotate("text", x = ri_result$actual_coef,
           y = Inf, label = "Actual\nestimate", vjust = 1.5,
           hjust = -0.1, size = 3.5, color = "#B2182B", fontface = "bold")

ggsave(file.path(fig_dir, "fig6_randomization_inference.pdf"), p6,
       width = 7, height = 5, dpi = 300)
ggsave(file.path(fig_dir, "fig6_randomization_inference.png"), p6,
       width = 7, height = 5, dpi = 300)
cat("  Saved fig6_randomization_inference\n")

## =========================================================================
## Figure 7: CS-DiD dynamic effects (if available)
## =========================================================================

cat("=== Figure 7: CS-DiD dynamic ===\n")

cs_dyn <- tryCatch(fread(file.path(data_dir, "cs_did_dynamic.csv")), error = function(e) NULL)

if (!is.null(cs_dyn) && nrow(cs_dyn) > 0) {
  p7 <- ggplot(cs_dyn, aes(x = rel_period, y = att)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "red", linewidth = 0.5) +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "#D6604D") +
    geom_point(size = 2, color = "#D6604D") +
    geom_line(color = "#D6604D", linewidth = 0.5) +
    labs(
      x = "Periods Relative to ZFE Adoption",
      y = "ATT",
      title = "Callaway-Sant'Anna Dynamic Treatment Effects"
    )

  ggsave(file.path(fig_dir, "fig7_cs_did_dynamic.pdf"), p7,
         width = 8, height = 5, dpi = 300)
  ggsave(file.path(fig_dir, "fig7_cs_did_dynamic.png"), p7,
         width = 8, height = 5, dpi = 300)
  cat("  Saved fig7_cs_did_dynamic\n")
} else {
  cat("  WARN: No CS-DiD dynamic data available\n")
}

## =========================================================================
## Figure 8: City-level heterogeneity (forest plot)
## =========================================================================

cat("=== Figure 8: City heterogeneity ===\n")

city_het <- tryCatch(fread(file.path(data_dir, "heterogeneity_city.csv")), error = function(e) NULL)

if (!is.null(city_het) && nrow(city_het) > 0) {
  city_het[, city_label := tools::toTitleCase(gsub("_", " ", city))]
  city_het <- city_het[order(coef)]
  city_het[, city_label := factor(city_label, levels = city_label)]

  p8 <- ggplot(city_het, aes(x = coef, y = city_label)) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
    geom_errorbarh(aes(xmin = ci_lower, xmax = ci_upper), height = 0.2,
                   color = "#2166AC", linewidth = 0.6) +
    geom_point(size = 3, color = "#2166AC") +
    geom_text(aes(label = paste0("N=", format(n_obs, big.mark = ","))),
              hjust = -0.2, size = 2.8, color = "gray40") +
    labs(
      x = "Effect on Log(Price/m2)",
      y = NULL,
      title = "ZFE Effect by City"
    )

  ggsave(file.path(fig_dir, "fig8_city_heterogeneity.pdf"), p8,
         width = 7, height = 5, dpi = 300)
  ggsave(file.path(fig_dir, "fig8_city_heterogeneity.png"), p8,
         width = 7, height = 5, dpi = 300)
  cat("  Saved fig8_city_heterogeneity\n")
}

cat("\n=== All figures generated ===\n")
