## 03_main_analysis.R — Bunching estimation at 25, 50, and 100 beds
library(data.table)
library(tidyverse)

cat("=== Multi-Threshold Bunching Analysis ===\n")

panel <- fread("data/hospital_panel_clean.csv")
bed_dist <- fread("data/bed_distribution_pooled.csv")

## =========================================================================
## BUNCHING ESTIMATION (Kleven 2016 approach)
## For each threshold, estimate excess mass relative to counterfactual density
## =========================================================================

estimate_bunching <- function(dist, threshold, window = 10, poly_deg = 7,
                              exclude_below = 2, exclude_above = 2,
                              label = "") {
  ## Restrict to relevant range
  dt <- dist[beds >= (threshold - window) & beds <= (threshold + window)]

  ## Exclude bunching region for counterfactual estimation
  dt[, in_bunching := beds >= (threshold - exclude_below) & beds <= (threshold + exclude_above)]
  dt[, rel_pos := beds - threshold]

  ## Fit polynomial to non-bunching region
  cf_data <- dt[in_bunching == FALSE]
  if (nrow(cf_data) < poly_deg + 1) {
    poly_deg <- max(2, nrow(cf_data) - 1)
  }

  fit <- lm(count ~ poly(rel_pos, poly_deg, raw = TRUE), data = cf_data)

  ## Predict counterfactual for all bins
  dt[, counterfactual := predict(fit, newdata = .SD)]
  dt[counterfactual < 0, counterfactual := 0]

  ## Excess mass
  bunching_region <- dt[in_bunching == TRUE]
  excess <- sum(bunching_region$count) - sum(bunching_region$counterfactual)
  avg_cf <- mean(bunching_region$counterfactual)
  b_hat <- ifelse(avg_cf > 0, excess / avg_cf, NA)

  ## Standard error via bootstrap (simple residual bootstrap)
  set.seed(42)
  n_boot <- 200
  b_boots <- numeric(n_boot)
  resids <- residuals(fit)

  for (i in 1:n_boot) {
    boot_resid <- sample(resids, nrow(cf_data), replace = TRUE)
    boot_y <- fitted(fit) + boot_resid
    boot_df <- data.table(count = pmax(boot_y, 0), rel_pos = cf_data$rel_pos)
    boot_fit <- lm(count ~ poly(rel_pos, poly_deg, raw = TRUE), data = boot_df)
    boot_cf <- predict(boot_fit, newdata = dt)
    boot_cf[boot_cf < 0] <- 0
    boot_excess <- sum(bunching_region$count) - sum(boot_cf[dt$in_bunching])
    boot_avg_cf <- mean(boot_cf[dt$in_bunching])
    b_boots[i] <- ifelse(boot_avg_cf > 0, boot_excess / boot_avg_cf, 0)
  }

  se_b <- sd(b_boots)

  cat(sprintf("\n--- %s (threshold = %d beds) ---\n", label, threshold))
  cat(sprintf("  Observed at threshold: %d\n", dt[beds == threshold, count]))
  cat(sprintf("  Counterfactual: %.0f\n", dt[beds == threshold, counterfactual]))
  cat(sprintf("  Total excess mass: %.0f\n", excess))
  cat(sprintf("  Normalized excess mass (b): %.2f (SE: %.2f)\n", b_hat, se_b))
  cat(sprintf("  Bunching ratio: %.1f:1\n",
              dt[beds == threshold, count] / max(1, dt[beds == threshold + 1, count])))

  return(list(
    threshold = threshold,
    label = label,
    b_hat = b_hat,
    se_b = se_b,
    excess = excess,
    observed = dt[beds == threshold, count],
    counterfactual = dt[beds == threshold, counterfactual],
    ratio = dt[beds == threshold, count] / max(1, dt[beds == threshold + 1, count]),
    detail = dt
  ))
}

## Estimate bunching at each threshold
res_25 <- estimate_bunching(bed_dist, 25, window = 15, exclude_below = 2,
                            exclude_above = 1, label = "CAH (25 beds)")

res_50 <- estimate_bunching(bed_dist, 50, window = 15, exclude_below = 2,
                            exclude_above = 1, label = "RHC/REH (50 beds)")

res_100 <- estimate_bunching(bed_dist, 100, window = 20, exclude_below = 1,
                             exclude_above = 1, label = "DSH (100 beds)")

## =========================================================================
## ROUND-NUMBER HEAPING ANALYSIS
## Estimate heaping at non-regulatory round numbers as a baseline
## =========================================================================

cat("\n\n=== Round-Number Heaping Analysis ===\n")

## Estimate heaping at multiples of 10 that are NOT regulatory thresholds
## Non-regulatory round numbers: 10, 20, 30, 40, 60, 70, 80, 90, 110, 120
non_reg_rounds <- c(20, 30, 40, 60, 70, 80, 90, 110, 120)

heaping_results <- data.table(
  beds = integer(), count = integer(),
  avg_neighbors = numeric(), heaping_ratio = numeric()
)

for (r in non_reg_rounds) {
  obs <- bed_dist[beds == r, count]
  neighbors <- bed_dist[beds %in% c(r-2, r-1, r+1, r+2), mean(count)]
  if (length(obs) > 0 && !is.na(neighbors) && neighbors > 0) {
    heaping_results <- rbind(heaping_results, data.table(
      beds = r, count = obs, avg_neighbors = neighbors,
      heaping_ratio = obs / neighbors
    ))
  }
}

cat("Non-regulatory round-number heaping:\n")
print(heaping_results)

avg_heaping <- mean(heaping_results$heaping_ratio)
cat(sprintf("\nAverage heaping ratio at non-regulatory rounds: %.2f\n", avg_heaping))

## Compare regulatory thresholds to heaping baseline
cat("\n=== Regulatory vs Heaping ===\n")
for (thresh in c(25, 50, 100)) {
  obs <- bed_dist[beds == thresh, count]
  neighbors <- bed_dist[beds %in% c(thresh-2, thresh-1, thresh+1, thresh+2), mean(count)]
  raw_ratio <- obs / neighbors
  net_regulatory <- raw_ratio / avg_heaping
  cat(sprintf("  %3d beds: raw ratio = %.1f, heaping-adjusted = %.1f\n",
              thresh, raw_ratio, net_regulatory))
}

## =========================================================================
## URBAN VS RURAL PLACEBO (at 25-bed threshold)
## =========================================================================

cat("\n=== Urban vs Rural Placebo at 25 Beds ===\n")

## CAH is only available to rural hospitals
## Non-CAH hospitals at/near 25 beds have no regulatory incentive
panel_near25 <- panel[beds >= 15 & beds <= 35]

urban_dist <- panel_near25[is_cah == FALSE, .N, by = beds][order(beds)]
rural_dist <- panel_near25[is_cah == TRUE, .N, by = beds][order(beds)]
setnames(urban_dist, "N", "urban_count")
setnames(rural_dist, "N", "rural_count")

cat("CAH (rural) distribution near 25:\n")
for (b in 20:30) {
  n_r <- rural_dist[beds == b, rural_count]
  n_u <- urban_dist[beds == b, urban_count]
  if (length(n_r) == 0) n_r <- 0
  if (length(n_u) == 0) n_u <- 0
  bar_r <- paste(rep("#", min(50, n_r %/% 100)), collapse = "")
  bar_u <- paste(rep("#", min(50, n_u %/% 20)), collapse = "")
  cat(sprintf("  %d: CAH=%5d %s  |  non-CAH=%4d %s\n", b, n_r, bar_r, n_u, bar_u))
}

## =========================================================================
## TEMPORAL STABILITY
## =========================================================================

cat("\n=== Temporal Stability of Bunching ===\n")

yearly_25 <- panel[beds == 25, .N, by = year][order(year)]
yearly_tot <- panel[beds >= 15 & beds <= 35, .N, by = year][order(year)]
yearly <- merge(yearly_25, yearly_tot, by = "year", suffixes = c("_25", "_total"))
yearly[, share_25 := N_25 / N_total]

cat("Share of 15-35 bed hospitals at exactly 25 beds:\n")
for (i in 1:nrow(yearly)) {
  cat(sprintf("  %d: %d/%d = %.1f%%\n",
              yearly$year[i], yearly$N_25[i], yearly$N_total[i],
              100 * yearly$share_25[i]))
}

## =========================================================================
## DIAGNOSTICS
## =========================================================================

## Save diagnostics for validate_v1.py
diagnostics <- list(
  n_treated = uniqueN(panel[beds == 25, prvdr_num]),
  n_pre = length(unique(panel[year < 2018, year])),
  n_obs = nrow(panel)
)
jsonlite::write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)

## Save bunching results
results <- data.table(
  threshold = c(25, 50, 100),
  label = c("CAH", "RHC/REH", "DSH"),
  b_hat = c(res_25$b_hat, res_50$b_hat, res_100$b_hat),
  se_b = c(res_25$se_b, res_50$se_b, res_100$se_b),
  excess_mass = c(res_25$excess, res_50$excess, res_100$excess),
  observed = c(res_25$observed, res_50$observed, res_100$observed),
  counterfactual = c(res_25$counterfactual, res_50$counterfactual, res_100$counterfactual),
  ratio = c(res_25$ratio, res_50$ratio, res_100$ratio)
)

fwrite(results, "data/bunching_results.csv")

## Save detail for tables
saveRDS(list(res_25 = res_25, res_50 = res_50, res_100 = res_100,
             heaping = heaping_results, avg_heaping = avg_heaping),
        "data/analysis_results.rds")

cat("\n=== Analysis Complete ===\n")
cat(sprintf("Results saved. Key findings:\n"))
cat(sprintf("  25-bed (CAH): b=%.2f (SE=%.2f), ratio=%.0f:1\n",
            res_25$b_hat, res_25$se_b, res_25$ratio))
cat(sprintf("  50-bed (RHC): b=%.2f (SE=%.2f), ratio=%.1f:1\n",
            res_50$b_hat, res_50$se_b, res_50$ratio))
cat(sprintf(" 100-bed (DSH): b=%.2f (SE=%.2f), ratio=%.1f:1\n",
            res_100$b_hat, res_100$se_b, res_100$ratio))
