## 04_robustness.R — Robustness checks and placebo tests
## APEP-1329: UK FIT Triple-Threshold Bunching

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

df <- readRDS(file.path(data_dir, "fit_solar_clean.rds"))
df <- df %>% filter(year >= 2010 & year <= 2019)

# ═══════════════════════════════════════════════════
# 1. Year-by-year bunching at 4 kW (temporal dynamics)
# ═══════════════════════════════════════════════════

cat("=== YEAR-BY-YEAR BUNCHING AT 4 kW ===\n")

yearly_bunching <- df %>%
  filter(capacity_kw >= 2, capacity_kw <= 6) %>%
  group_by(year) %>%
  summarise(
    n_total = n(),
    n_at_4 = sum(capacity_kw == 4),
    n_above_4 = sum(capacity_kw > 4 & capacity_kw <= 4.1),
    n_below_4 = sum(capacity_kw >= 3.9 & capacity_kw < 4),
    share_at_4 = n_at_4 / n_total,
    ratio = if_else(n_above_4 > 0, n_at_4 / n_above_4, NA_real_),
    .groups = "drop"
  )

cat("\nYear-by-year:\n")
print(yearly_bunching, n = 20)

# ═══════════════════════════════════════════════════
# 2. Placebo test at round numbers (no tariff change)
# ═══════════════════════════════════════════════════

cat("\n=== PLACEBO: ROUND NUMBER BUNCHING ===\n")
# Test bunching at 3, 5, 6, 8 kW (no tariff thresholds)

placebo_thresholds <- c(3, 5, 6, 8, 15, 20, 30)
placebo_results <- data.frame()

for (thresh in placebo_thresholds) {
  at <- sum(df$capacity_kw == thresh)
  # Use 0.1 kW bins on either side
  above <- sum(df$capacity_kw > thresh & df$capacity_kw <= thresh + 0.1)
  below <- sum(df$capacity_kw >= thresh - 0.1 & df$capacity_kw < thresh)
  ratio <- if (above > 0) at / above else NA
  placebo_results <- rbind(placebo_results, data.frame(
    threshold = thresh,
    at_threshold = at,
    just_above = above,
    just_below = below,
    ratio = ratio,
    is_tariff_threshold = thresh %in% c(4, 10, 50)
  ))
}

cat("\nPlacebo comparison:\n")
print(placebo_results)

# ═══════════════════════════════════════════════════
# 3. Domestic vs Non-Domestic comparison
# ═══════════════════════════════════════════════════

cat("\n=== DOMESTIC vs NON-DOMESTIC ===\n")

# Domestic should bunch heavily at 4 kW (residential rooftop constraint)
# Non-domestic should bunch more at 10 and 50 kW

for (thresh in c(4, 10, 50)) {
  for (itype in c("Domestic", "Non Domestic (Commercial)")) {
    d <- df %>% filter(install_type == itype)
    at <- sum(d$capacity_kw == thresh)
    above <- sum(d$capacity_kw > thresh & d$capacity_kw <= thresh + 0.1)
    ratio <- if (above > 0) round(at / above) else NA
    cat(sprintf("  %s at %d kW: %d (ratio %s:1)\n", itype, thresh, at,
                if (!is.na(ratio)) as.character(ratio) else "Inf"))
  }
  cat("\n")
}

# ═══════════════════════════════════════════════════
# 4. Bandwidth sensitivity for bunching estimates
# ═══════════════════════════════════════════════════

cat("=== BANDWIDTH SENSITIVITY (4 kW pre-merger) ===\n")

df_pre <- df %>% filter(pre_merger)
windows <- list(
  c(2.5, 5.5),
  c(2.0, 6.0),
  c(1.5, 6.5),
  c(3.0, 5.0)
)

for (w in windows) {
  d <- df_pre %>% filter(capacity_kw >= w[1] & capacity_kw <= w[2])
  at_4 <- sum(d$capacity_kw == 4)
  total <- nrow(d)
  share <- at_4 / total
  cat(sprintf("  Window [%.1f, %.1f]: N=%d, at_4=%d, share=%.1f%%\n",
              w[1], w[2], total, at_4, 100 * share))
}

# ═══════════════════════════════════════════════════
# 5. McCrary-style density test around 4 kW post-merger
# ═══════════════════════════════════════════════════

cat("\n=== POST-MERGER DENSITY AROUND 4 kW ===\n")
# If 4 kW bunching post-merger is purely round-number/physical,
# it should look similar to bunching at other round numbers

df_post <- df %>% filter(post_merger)
round_numbers <- c(3, 3.5, 4, 4.5, 5, 5.5, 6)
for (rn in round_numbers) {
  at <- sum(df_post$capacity_kw == rn)
  near <- sum(df_post$capacity_kw >= rn - 0.05 & df_post$capacity_kw <= rn + 0.05)
  cat(sprintf("  At %.1f kW: %d installations (in ±0.05: %d)\n", rn, at, near))
}

# ═══════════════════════════════════════════════════
# 6. Save robustness results
# ═══════════════════════════════════════════════════

saveRDS(list(
  yearly = yearly_bunching,
  placebo = placebo_results
), file.path(data_dir, "robustness_results.rds"))

cat("\nDONE: Robustness checks complete.\n")
