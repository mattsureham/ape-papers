# ==============================================================================
# 05_figures.R — All figures for paper
# Paper: When the Train Doesn't Come (apep_0542)
# ==============================================================================

source("code/00_packages.R")

# Load pre-computed data
es_coefs <- fread(file.path(DATA_DIR, "event_study_coefs.csv"))
dist_grad <- fread(file.path(DATA_DIR, "distance_gradient.csv"))
ri_data <- fread(file.path(DATA_DIR, "ri_distribution.csv"))
station_het <- fread(file.path(DATA_DIR, "station_heterogeneity.csv"))
prop_het <- fread(file.path(DATA_DIR, "property_type_heterogeneity.csv"))
main_results <- fread(file.path(DATA_DIR, "main_results.csv"))
df <- fread(file.path(DATA_DIR, "analysis_main.csv"))

# ==============================================================================
# Figure 1: Event Study — Quarterly treatment effects
# ==============================================================================

es_coefs[, ci_lo := estimate - 1.96 * se]
es_coefs[, ci_hi := estimate + 1.96 * se]

fig1 <- ggplot(es_coefs, aes(x = eq_num, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "firebrick", linewidth = 0.8) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, fill = "steelblue") +
  geom_point(size = 2.5, color = "steelblue") +
  geom_line(color = "steelblue", linewidth = 0.6) +
  annotate("text", x = 0.5, y = max(es_coefs$ci_hi, na.rm = TRUE) * 0.9,
           label = "Cancellation\nannounced", hjust = 0, size = 3.5, color = "firebrick") +
  labs(
    x = "Quarters relative to HS2 Phase 2 cancellation (Q4 2023 = 0)",
    y = "Coefficient on Treatment x Post\n(log house price)"
  ) +
  scale_x_continuous(breaks = seq(-16, 4, 4)) +
  theme(plot.margin = margin(10, 15, 10, 10))

ggsave(file.path(FIG_DIR, "fig1_event_study.pdf"), fig1,
       width = 8, height = 5, dpi = 300)
ggsave(file.path(FIG_DIR, "fig1_event_study.png"), fig1,
       width = 8, height = 5, dpi = 300)
cat("Saved Figure 1: Event study\n")

# ==============================================================================
# Figure 2: Distance gradient — Treatment effect by distance ring
# ==============================================================================

# Parse ring names
dist_grad[, ring := str_extract(term, "\\d+-\\d+km|\\d+km")]
dist_grad[, ring := factor(ring, levels = c("0-2km", "2-5km", "5-10km", "10-20km"))]
dist_grad[, ci_lo := estimate - 1.96 * se]
dist_grad[, ci_hi := estimate + 1.96 * se]
dist_grad <- dist_grad[!is.na(ring)]

# Add reference category
dist_grad <- rbind(
  data.table(estimate = 0, se = 0, tstat = 0, pval = 1, term = "ref",
             ring = factor(">20km", levels = c(">20km", "0-2km", "2-5km", "5-10km", "10-20km")),
             ci_lo = 0, ci_hi = 0),
  dist_grad
)

fig2 <- ggplot(dist_grad, aes(x = ring, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0.15,
                color = "steelblue", linewidth = 0.7) +
  geom_point(size = 3, color = "steelblue") +
  labs(
    x = "Distance to nearest cancelled Phase 2 station",
    y = "Coefficient on Ring x Post\n(log house price)"
  ) +
  theme(plot.margin = margin(10, 15, 10, 10))

ggsave(file.path(FIG_DIR, "fig2_distance_gradient.pdf"), fig2,
       width = 7, height = 5, dpi = 300)
ggsave(file.path(FIG_DIR, "fig2_distance_gradient.png"), fig2,
       width = 7, height = 5, dpi = 300)
cat("Saved Figure 2: Distance gradient\n")

# ==============================================================================
# Figure 3: Station-level heterogeneity
# ==============================================================================

station_het[, ci_lo := estimate - 1.96 * se]
station_het[, ci_hi := estimate + 1.96 * se]
# Extract station name from term
station_het[, station := str_extract(term, "(?<=::).*(?=:post)")]
station_het[, station := gsub("\\.", " ", station)]

fig3 <- ggplot(station_het[!is.na(station)],
               aes(x = reorder(station, estimate), y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0.2,
                color = "steelblue", linewidth = 0.7) +
  geom_point(size = 3, color = "steelblue") +
  coord_flip() +
  labs(
    x = NULL,
    y = "Coefficient on Station x Post (log house price)"
  )

ggsave(file.path(FIG_DIR, "fig3_station_heterogeneity.pdf"), fig3,
       width = 8, height = 5, dpi = 300)
ggsave(file.path(FIG_DIR, "fig3_station_heterogeneity.png"), fig3,
       width = 8, height = 5, dpi = 300)
cat("Saved Figure 3: Station heterogeneity\n")

# ==============================================================================
# Figure 4: Property type heterogeneity
# ==============================================================================

fig4 <- ggplot(prop_het, aes(x = property_type, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi), width = 0.15,
                color = "steelblue", linewidth = 0.7) +
  geom_point(size = 3, color = "steelblue") +
  labs(
    x = "Property type",
    y = "Coefficient on Treatment x Post\n(log house price)"
  )

ggsave(file.path(FIG_DIR, "fig4_property_type.pdf"), fig4,
       width = 7, height = 5, dpi = 300)
ggsave(file.path(FIG_DIR, "fig4_property_type.png"), fig4,
       width = 7, height = 5, dpi = 300)
cat("Saved Figure 4: Property type heterogeneity\n")

# ==============================================================================
# Figure 5: Randomization inference distribution
# ==============================================================================

ri_perm <- ri_data[type == "Permuted"]
ri_obs <- ri_data[type == "Observed"]

fig5 <- ggplot(ri_perm, aes(x = beta)) +
  geom_histogram(bins = 40, fill = "grey70", color = "grey50", alpha = 0.8) +
  geom_vline(xintercept = ri_obs$beta, color = "firebrick",
             linewidth = 1, linetype = "solid") +
  annotate("text", x = ri_obs$beta, y = Inf, vjust = 2,
           label = paste("Observed =", round(ri_obs$beta, 4)),
           color = "firebrick", size = 3.5, hjust = -0.1) +
  labs(
    x = "Permuted treatment effect",
    y = "Count"
  )

ggsave(file.path(FIG_DIR, "fig5_randomization_inference.pdf"), fig5,
       width = 7, height = 5, dpi = 300)
ggsave(file.path(FIG_DIR, "fig5_randomization_inference.png"), fig5,
       width = 7, height = 5, dpi = 300)
cat("Saved Figure 5: Randomization inference\n")

# ==============================================================================
# Figure 6: Raw price trends — treated vs control
# ==============================================================================

df[, treatment_group := fifelse(near_station_5km == 1, "Within 5km of cancelled station",
                                 "Control (>5km)")]
trends <- df[, .(
  mean_log_price = mean(log(price)),
  median_price = as.double(median(price)),
  n = as.double(.N)
), by = .(year_quarter, treatment_group)]
setorder(trends, year_quarter)

fig6 <- ggplot(trends, aes(x = year_quarter, y = mean_log_price,
                            color = treatment_group, group = treatment_group)) +
  geom_vline(xintercept = "2023-Q4", linetype = "dotted",
             color = "firebrick", linewidth = 0.8) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.5) +
  scale_color_manual(values = c("Within 5km of cancelled station" = "steelblue",
                                 "Control (>5km)" = "grey50")) +
  labs(
    x = "Year-Quarter",
    y = "Mean log(price)",
    color = NULL
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 7))

ggsave(file.path(FIG_DIR, "fig6_raw_trends.pdf"), fig6,
       width = 9, height = 5, dpi = 300)
ggsave(file.path(FIG_DIR, "fig6_raw_trends.png"), fig6,
       width = 9, height = 5, dpi = 300)
cat("Saved Figure 6: Raw price trends\n")

cat("\nAll figures saved to:", FIG_DIR, "\n")
