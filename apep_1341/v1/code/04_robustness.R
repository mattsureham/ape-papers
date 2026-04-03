# 04_robustness.R — Robustness checks and heterogeneity
# apep_1341: RCRA Hazardous Waste Generator Thresholds

source("00_packages.R")
source("03_main_analysis.R")  # Loads estimate_bunching function

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "handler_cycle_panel.rds"))
recent <- panel %>% filter(cycle == max(cycle))
threshold <- 1000

# ============================================================
# 1. Placebo threshold tests
# ============================================================
cat("\n=== Placebo Tests at Round Numbers ===\n")
cat("No regulatory notch at these thresholds:\n")

placebo_thresholds <- c(500, 750, 1500, 2000, 3000, 5000)
placebo_results <- list()

for (pt in placebo_thresholds) {
  # Adjust windows for each placebo
  res <- tryCatch(
    estimate_bunching(recent, pt,
                      exclude_low = pt - 150,
                      exclude_high = pt + 50,
                      window_low = max(100, pt - 800),
                      window_high = pt + 1500),
    error = function(e) list(b_normalized = NA, excess_mass = NA)
  )
  placebo_results[[as.character(pt)]] <- res
  cat(sprintf("  %d kg/month: b = %.3f (excess = %.0f)\n",
              pt, res$b_normalized, res$excess_mass))
}

# ============================================================
# 2. Industry heterogeneity (NAICS 2-digit)
# ============================================================
cat("\n=== Industry Heterogeneity ===\n")

# Get top industries by handler count
industry_counts <- recent %>%
  filter(!is.na(naics2) & naics2 != "") %>%
  count(naics2, sort = TRUE)

cat("Top industries (NAICS 2-digit):\n")
print(head(industry_counts, 10))

# Estimate bunching by industry for top 5
industry_results <- list()
top_industries <- head(industry_counts$naics2, 5)

for (ind in top_industries) {
  ind_data <- recent %>% filter(naics2 == ind)
  if (nrow(ind_data %>% filter(gen_kg_month > 200 & gen_kg_month < 2500)) > 50) {
    res <- tryCatch(
      estimate_bunching(ind_data, threshold),
      error = function(e) list(b_normalized = NA, excess_mass = NA, n_total = nrow(ind_data))
    )
    industry_results[[ind]] <- res
    cat(sprintf("  NAICS %s (n=%d): b = %.3f\n",
                ind, nrow(ind_data), res$b_normalized))
  }
}

# ============================================================
# 3. Cycle-by-cycle estimates
# ============================================================
cat("\n=== Estimates by Report Cycle ===\n")
cycle_results <- list()

for (cy in sort(unique(panel$cycle))) {
  cy_data <- panel %>% filter(cycle == cy)
  res <- tryCatch(
    estimate_bunching(cy_data, threshold),
    error = function(e) list(b_normalized = NA, excess_mass = NA)
  )
  cycle_results[[as.character(cy)]] <- res
  cat(sprintf("  Cycle %d: b = %.3f (n = %d)\n",
              cy, res$b_normalized, nrow(cy_data)))
}

# ============================================================
# 4. McCrary density test (supplementary)
# ============================================================
cat("\n=== McCrary-Style Density Test ===\n")
# Test for a discontinuity in the density at the threshold
# Simple version: compare density just below vs just above

below_count <- sum(recent$gen_kg_month >= 900 & recent$gen_kg_month < 1000, na.rm = TRUE)
above_count <- sum(recent$gen_kg_month >= 1000 & recent$gen_kg_month < 1100, na.rm = TRUE)
ratio <- below_count / max(above_count, 1)
cat(sprintf("Handlers 900-1000: %d\n", below_count))
cat(sprintf("Handlers 1000-1100: %d\n", above_count))
cat(sprintf("Below/Above ratio: %.2f\n", ratio))

# ============================================================
# 5. Window sensitivity
# ============================================================
cat("\n=== Bunching Window Sensitivity ===\n")
windows <- list(
  narrow = c(100, 300),   # exclude [700, 1300]
  baseline = c(150, 50),  # exclude [850, 1050]
  wide = c(200, 100)      # exclude [800, 1100]
)

for (w_name in names(windows)) {
  w <- windows[[w_name]]
  res <- estimate_bunching(recent, threshold,
                           exclude_low = threshold - w[1],
                           exclude_high = threshold + w[2])
  cat(sprintf("  %s [%d, %d]: b = %.3f\n",
              w_name, threshold - w[1], threshold + w[2], res$b_normalized))
}

# ============================================================
# 6. Save all robustness results
# ============================================================
rob_results <- list(
  placebo = placebo_results,
  industry = industry_results,
  cycles = cycle_results,
  mccrary_ratio = ratio,
  below_count = below_count,
  above_count = above_count
)

saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))
cat("\nRobustness results saved.\n")

cat("\n04_robustness.R complete.\n")
