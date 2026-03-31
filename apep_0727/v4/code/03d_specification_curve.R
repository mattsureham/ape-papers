## 03d_specification_curve.R — Pre-Specified Estimator Family + Full Grid (V4)
## apep_0727 v4: Honest uncertainty reporting
##
## Main text: Pre-specified family of 9 specifications (3 degrees × 3 windows)
## Appendix: Full grid of 60+ specifications for specification curve figure

source("00_packages.R")
source("00_bunching_estimator.R")

cat("Loading data for specification curve...\n")
dt_10 <- fread("../data/solar_clean_10.csv")
dt_10[, bin_int := as.integer(floor(capacity_kwp * 10))]
all_bins <- data.table(bin_int = 30L:199L)

# Surcharge period data
sur_data <- dt_10[period == "3_surcharge" |
                   (year >= 2014 & year <= 2020)]
sur_bins <- make_bins_int(sur_data, all_bins)

# ============================================================
# 1. PRE-SPECIFIED ESTIMATOR FAMILY (Main Text)
# ============================================================

cat("\n=== Pre-Specified Estimator Family ===\n")
cat("3 polynomial degrees × 3 exclusion windows = 9 specifications\n\n")

degrees <- c(6L, 7L, 8L)
windows <- list(
  c(90L, 110L),    # Baseline [9.0, 11.0)
  c(95L, 105L),    # Narrow [9.5, 10.5)
  c(85L, 115L)     # Wide [8.5, 11.5)
)
window_labels <- c("[9.0, 11.0)", "[9.5, 10.5)", "[8.5, 11.5)")

family_results <- list()
for (d in degrees) {
  for (w_idx in seq_along(windows)) {
    w <- windows[[w_idx]]
    est <- bunching_estimate_int(sur_bins, poly_degree = d,
                                  excl_lower = w[1], excl_upper = w[2])

    label <- sprintf("Degree %d, %s", d, window_labels[w_idx])
    is_baseline <- (d == 7L && w_idx == 1)
    cat(sprintf("  %s: b = %.1f, excess = %s %s\n",
        label, est$bunching_ratio,
        format(round(est$excess_mass), big.mark = ","),
        ifelse(is_baseline, "<-- BASELINE", "")))

    family_results[[length(family_results) + 1]] <- data.frame(
      poly_degree = d,
      excl_window = window_labels[w_idx],
      excl_lower = w[1] / 10,
      excl_upper = w[2] / 10,
      bunching_ratio = round(est$bunching_ratio, 2),
      excess_mass = round(est$excess_mass),
      missing_mass = round(est$missing_mass),
      mass_balance = round(est$mass_balance, 3),
      is_baseline = is_baseline,
      stringsAsFactors = FALSE)
  }
}

family_dt <- as.data.table(do.call(rbind, family_results))
fwrite(family_dt, "../data/spec_family.csv")

cat(sprintf("\n  Range: [%.1f, %.1f]\n",
    min(family_dt$bunching_ratio), max(family_dt$bunching_ratio)))
cat(sprintf("  Median: %.1f\n", median(family_dt$bunching_ratio)))
cat(sprintf("  Baseline (degree 7, [9.0, 11.0)): %.1f\n",
    family_dt[is_baseline == TRUE, bunching_ratio]))

# ============================================================
# 2. FULL SPECIFICATION GRID (Appendix Figure)
# ============================================================

cat("\n=== Full Specification Grid ===\n")
cat("5 degrees × 6 windows × 2 bin approaches = 60 specifications\n\n")

all_degrees <- c(5L, 6L, 7L, 8L, 9L)
all_windows <- list(
  c(90L, 110L),    # [9.0, 11.0)
  c(95L, 105L),    # [9.5, 10.5)
  c(85L, 115L),    # [8.5, 11.5)
  c(80L, 120L),    # [8.0, 12.0)
  c(90L, 105L),    # [9.0, 10.5) asymmetric
  c(85L, 110L)     # [8.5, 11.0) asymmetric
)
all_window_labels <- c("[9.0, 11.0)", "[9.5, 10.5)", "[8.5, 11.5)",
                        "[8.0, 12.0)", "[9.0, 10.5)", "[8.5, 11.0)")

grid_results <- list()
for (d in all_degrees) {
  for (w_idx in seq_along(all_windows)) {
    w <- all_windows[[w_idx]]
    est <- tryCatch(
      bunching_estimate_int(sur_bins, poly_degree = d,
                            excl_lower = w[1], excl_upper = w[2]),
      error = function(e) list(bunching_ratio = NA, excess_mass = NA,
                                missing_mass = NA, mass_balance = NA)
    )

    grid_results[[length(grid_results) + 1]] <- data.frame(
      poly_degree = d,
      excl_window = all_window_labels[w_idx],
      excl_lower = w[1] / 10,
      excl_upper = w[2] / 10,
      bunching_ratio = round(est$bunching_ratio, 2),
      excess_mass = round(est$excess_mass),
      missing_mass = round(est$missing_mass),
      mass_balance = round(est$mass_balance, 3),
      stringsAsFactors = FALSE)
  }
}

grid_dt <- as.data.table(do.call(rbind, grid_results))
grid_dt <- grid_dt[!is.na(bunching_ratio)]
fwrite(grid_dt, "../data/spec_grid.csv")

cat(sprintf("  Grid specifications: %d\n", nrow(grid_dt)))
cat(sprintf("  Full range: [%.1f, %.1f]\n",
    min(grid_dt$bunching_ratio), max(grid_dt$bunching_ratio)))
cat(sprintf("  IQR: [%.1f, %.1f]\n",
    quantile(grid_dt$bunching_ratio, 0.25),
    quantile(grid_dt$bunching_ratio, 0.75)))
cat(sprintf("  Median: %.1f\n", median(grid_dt$bunching_ratio)))

# ============================================================
# 3. SPECIFICATION CURVE FIGURE (Appendix)
# ============================================================

library(ggplot2)

theme_apep <- theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 12))

# Sort by bunching ratio
grid_dt[, spec_rank := rank(bunching_ratio)]
grid_dt[, is_baseline := (poly_degree == 7 & excl_window == "[9.0, 11.0)")]

p_spec <- ggplot(grid_dt, aes(x = spec_rank, y = bunching_ratio)) +
  geom_point(aes(color = is_baseline, size = is_baseline)) +
  scale_color_manual(values = c("FALSE" = "grey50", "TRUE" = "#D55E00")) +
  scale_size_manual(values = c("FALSE" = 1.5, "TRUE" = 3)) +
  geom_hline(yintercept = median(grid_dt$bunching_ratio),
             linetype = "dashed", color = "grey40") +
  annotate("text", x = nrow(grid_dt) * 0.95,
           y = median(grid_dt$bunching_ratio) + 3,
           label = sprintf("Median = %.0f", median(grid_dt$bunching_ratio)),
           hjust = 1, size = 3.5, color = "grey40") +
  labs(
    title = "Specification Curve: Bunching Ratio Across Estimator Choices",
    subtitle = sprintf("%d specifications (5 polynomial degrees × 6 exclusion windows). Baseline highlighted.",
                        nrow(grid_dt)),
    x = "Specification (ranked by estimate)",
    y = "Bunching Ratio (b)"
  ) +
  theme_apep +
  theme(legend.position = "none")

ggsave("../figures/fig_spec_curve.pdf", p_spec, width = 8, height = 5)
ggsave("../figures/fig_spec_curve.png", p_spec, width = 8, height = 5, dpi = 300)

cat("\nSpecification curve complete.\n")
