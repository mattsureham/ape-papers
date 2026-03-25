# 04_robustness.R — Robustness checks for bunching estimates
source("00_packages.R")

PROJ_DIR <- normalizePath(file.path(getwd(), ".."))
DATA_DIR <- file.path(PROJ_DIR, "data")

dt <- fread(file.path(DATA_DIR, "contract_bins_clean.csv"))

# Source the bunching estimation function from main analysis
# Re-define here for self-containment
estimate_bunching <- function(data, threshold, poly_order = 7,
                              bunching_window = 20000,
                              exclude_above = 10000,
                              bin_width = 10000) {
  d <- copy(data)
  d[, z := bin_midpoint]
  bunching_lower <- threshold - bunching_window
  bunching_upper <- threshold + exclude_above
  d[, excluded := z >= bunching_lower & z <= bunching_upper]
  d_fit <- d[excluded == FALSE]
  if (nrow(d_fit) < poly_order + 1) return(NULL)
  d[, z_centered := (z - threshold) / 1000]
  d_fit[, z_centered := (z - threshold) / 1000]
  formula_str <- paste0("count ~ ", paste0("I(z_centered^", 1:poly_order, ")",
                                            collapse = " + "))
  fit <- lm(as.formula(formula_str), data = d_fit)
  d[, counterfactual := predict(fit, newdata = d)]
  d[counterfactual < 0, counterfactual := 0]
  bunching_region <- d[z >= bunching_lower & z < threshold]
  excess_mass <- sum(bunching_region$count - bunching_region$counterfactual)
  cf_mass <- sum(bunching_region$counterfactual)
  b <- excess_mass / (cf_mass / nrow(bunching_region))
  return(list(b = b, excess_mass = excess_mass,
              r_squared = summary(fit)$r.squared))
}

# ==========================================================================
# Robustness 1: Varying polynomial order (5, 6, 7, 8, 9)
# ==========================================================================

cat("=== ROBUSTNESS: Polynomial Order ===\n")

d150 <- dt[fiscal_year >= 2015 & fiscal_year <= 2019,
           .(count = mean(count)), by = .(bin_midpoint)]
setorder(d150, bin_midpoint)

d250 <- dt[fiscal_year >= 2022,
           .(count = mean(count)), by = .(bin_midpoint)]
setorder(d250, bin_midpoint)

poly_results <- data.table()
for (p in 5:9) {
  r150 <- estimate_bunching(d150, 150000, poly_order = p)
  r250 <- estimate_bunching(d250, 250000, poly_order = p)
  poly_results <- rbindlist(list(poly_results, data.table(
    poly_order = p,
    b_150 = ifelse(!is.null(r150), r150$b, NA),
    b_250 = ifelse(!is.null(r250), r250$b, NA),
    rsq_150 = ifelse(!is.null(r150), r150$r_squared, NA),
    rsq_250 = ifelse(!is.null(r250), r250$r_squared, NA)
  )))
  cat(sprintf("  p=%d: b(150K)=%.3f, b(250K)=%.3f\n", p,
              ifelse(!is.null(r150), r150$b, NA),
              ifelse(!is.null(r250), r250$b, NA)))
}

# ==========================================================================
# Robustness 2: Varying bunching window width
# ==========================================================================

cat("\n=== ROBUSTNESS: Bunching Window ===\n")

window_results <- data.table()
for (w in c(10000, 20000, 30000, 40000)) {
  r150 <- estimate_bunching(d150, 150000, bunching_window = w)
  r250 <- estimate_bunching(d250, 250000, bunching_window = w)
  window_results <- rbindlist(list(window_results, data.table(
    window = w,
    b_150 = ifelse(!is.null(r150), r150$b, NA),
    b_250 = ifelse(!is.null(r250), r250$b, NA)
  )))
  cat(sprintf("  w=$%dK: b(150K)=%.3f, b(250K)=%.3f\n", w/1000,
              ifelse(!is.null(r150), r150$b, NA),
              ifelse(!is.null(r250), r250$b, NA)))
}

# ==========================================================================
# Robustness 3: Excluding individual fiscal years (leave-one-out)
# ==========================================================================

cat("\n=== ROBUSTNESS: Leave-One-Year-Out (at $150K) ===\n")

loo_results <- data.table()
for (drop_fy in 2015:2019) {
  d_loo <- dt[fiscal_year >= 2015 & fiscal_year <= 2019 & fiscal_year != drop_fy,
              .(count = mean(count)), by = .(bin_midpoint)]
  setorder(d_loo, bin_midpoint)
  r <- estimate_bunching(d_loo, 150000)
  loo_results <- rbindlist(list(loo_results, data.table(
    dropped_fy = drop_fy,
    b_150 = ifelse(!is.null(r), r$b, NA)
  )))
  cat(sprintf("  Drop FY%d: b=%.3f\n", drop_fy,
              ifelse(!is.null(r), r$b, NA)))
}

# ==========================================================================
# Robustness 4: Placebo test — ratio at non-SAT round numbers
# ==========================================================================

cat("\n=== PLACEBO: Round-Number Density Ratios ===\n")

placebo_thresholds <- c(100000, 200000, 300000)
placebo_results <- data.table()

for (pt in placebo_thresholds) {
  # Calculate ratio of just-below to just-above
  below <- d150[bin_midpoint == pt - 5000, count]
  above <- d150[bin_midpoint == pt + 5000, count]
  ratio <- ifelse(length(below) > 0 & length(above) > 0 & above > 0,
                  below / above, NA)
  placebo_results <- rbindlist(list(placebo_results, data.table(
    threshold = pt,
    count_below = ifelse(length(below) > 0, below, NA),
    count_above = ifelse(length(above) > 0, above, NA),
    ratio = ratio
  )))
  cat(sprintf("  $%dK: below=%s, above=%s, ratio=%.3f\n",
              pt/1000,
              ifelse(length(below) > 0, format(round(below), big.mark = ","), "NA"),
              ifelse(length(above) > 0, format(round(above), big.mark = ","), "NA"),
              ifelse(!is.na(ratio), ratio, NA)))
}

# Add the actual SAT threshold for comparison
below_sat <- d150[bin_midpoint == 145000, count]
above_sat <- d150[bin_midpoint == 155000, count]
cat(sprintf("  $150K (SAT): below=%s, above=%s, ratio=%.3f\n",
            format(round(below_sat), big.mark = ","),
            format(round(above_sat), big.mark = ","),
            below_sat / above_sat))

# ==========================================================================
# Save robustness results
# ==========================================================================

fwrite(poly_results, file.path(DATA_DIR, "robustness_polynomial.csv"))
fwrite(window_results, file.path(DATA_DIR, "robustness_window.csv"))
fwrite(loo_results, file.path(DATA_DIR, "robustness_loo.csv"))
fwrite(placebo_results, file.path(DATA_DIR, "robustness_placebo.csv"))

cat("\nRobustness results saved.\n")
