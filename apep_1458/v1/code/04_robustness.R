source("00_packages.R")

cat("=== Robustness Checks ===\n")

df_rdd <- readRDS("../data/analysis_rdd.rds")
df_full <- readRDS("../data/analysis_full.rds")
results <- readRDS("../data/rdd_results.rds")
robust <- list()

# ============================================================
# A. Density test (manipulation)
# ============================================================
cat("\n--- Density test at pooled cutoff ---\n")
dens <- rddensity(X = df_rdd$dist_to_cutoff, c = 0)
cat("  T-stat:", round(dens$test$t_jk, 3),
    " p-value:", round(dens$test$p_jk, 3), "\n")
robust$density <- dens

# Per-threshold density tests
cat("\n--- Threshold-specific density tests ---\n")
density_tests <- map_dfr(c(1000, 2500, 3300, 4100, 4900), function(cutoff) {
  df_c <- df_full %>% filter(abs(pop - cutoff) <= 5000)
  tryCatch({
    d <- rddensity(X = df_c$pop, c = cutoff)
    tibble(cutoff = cutoff, t_stat = d$test$t_jk, p_value = d$test$p_jk)
  }, error = function(e) tibble(cutoff = cutoff, t_stat = NA, p_value = NA))
})
print(density_tests)
robust$density_by_cutoff <- density_tests

# ============================================================
# B. Placebo cutoffs (midpoints between actual thresholds)
# ============================================================
cat("\n--- Placebo cutoffs ---\n")
placebo_cutoffs <- c(1750, 2900, 3700, 4500, 5350)

placebo_results <- map_dfr(placebo_cutoffs, function(pc) {
  df_p <- df_full %>%
    filter(abs(pop - pc) <= 3000) %>%
    mutate(running = pop - pc)
  if (nrow(df_p) < 100) return(tibble(cutoff = pc, est = NA, se = NA, pv = NA))
  tryCatch({
    fit <- rdrobust(y = df_p$any_coliform_mcl, x = df_p$running, c = 0,
                     kernel = "triangular", p = 1, bwselect = "mserd")
    tibble(cutoff = pc, est = fit$coef[1], se = fit$se[3], pv = fit$pv[3])
  }, error = function(e) tibble(cutoff = pc, est = NA, se = NA, pv = NA))
})
cat("Placebo results:\n")
print(placebo_results)
robust$placebo <- placebo_results

# ============================================================
# C. Bandwidth sensitivity
# ============================================================
cat("\n--- Bandwidth sensitivity ---\n")
bandwidths <- c(200, 300, 500, 750, 1000, 1500, 2000)

bw_results <- map_dfr(bandwidths, function(bw) {
  df_bw <- df_rdd %>% filter(abs(dist_to_cutoff) <= bw)
  n_below <- sum(df_bw$dist_to_cutoff < 0)
  n_above <- sum(df_bw$dist_to_cutoff > 0)
  if (min(n_below, n_above) < 50) {
    return(tibble(bandwidth = bw, est = NA_real_, se = NA_real_,
                  pv = NA_real_, n_eff = NA_integer_))
  }
  tryCatch({
    fit <- rdrobust(y = df_bw$any_coliform_mcl, x = df_bw$dist_to_cutoff,
                     c = 0, kernel = "triangular", p = 1, bwselect = "mserd")
    tibble(bandwidth = bw, est = fit$coef[1], se = fit$se[3],
           pv = fit$pv[3], n_eff = as.integer(sum(fit$N_h)))
  }, error = function(e) {
    cat("  BW", bw, "error:", e$message, "\n")
    tibble(bandwidth = bw, est = NA_real_, se = NA_real_,
           pv = NA_real_, n_eff = NA_integer_)
  })
})
cat("Bandwidth sensitivity:\n")
print(bw_results)
robust$bandwidth <- bw_results

# ============================================================
# D. Polynomial order sensitivity
# ============================================================
cat("\n--- Polynomial order sensitivity ---\n")

poly_results <- map_dfr(1:2, function(p) {
  fit <- rdrobust(y = df_rdd$any_coliform_mcl, x = df_rdd$dist_to_cutoff,
                   c = 0, kernel = "triangular", p = p, bwselect = "mserd")
  tibble(poly_order = p, est = fit$coef[1], se = fit$se[3], pv = fit$pv[3],
         bw = fit$bws[1, 1])
})
print(poly_results)
robust$polynomial <- poly_results

# ============================================================
# E. Covariate balance
# ============================================================
cat("\n--- Covariate balance at pooled cutoff ---\n")

covariates <- c("connections")
balance <- map_dfr(covariates, function(cov) {
  y <- df_rdd[[cov]]
  valid <- !is.na(y)
  if (sum(valid) < 200) return(tibble(covariate = cov, est = NA, se = NA, pv = NA))
  tryCatch({
    fit <- rdrobust(y = y[valid], x = df_rdd$dist_to_cutoff[valid],
                     c = 0, kernel = "triangular", p = 1, bwselect = "mserd")
    tibble(covariate = cov, est = fit$coef[1], se = fit$se[3], pv = fit$pv[3])
  }, error = function(e) tibble(covariate = cov, est = NA, se = NA, pv = NA))
})

# Source type balance
src_balance <- tryCatch({
  y <- as.integer(df_rdd$source_type == "Surface water")
  fit <- rdrobust(y = y, x = df_rdd$dist_to_cutoff, c = 0,
                   kernel = "triangular", p = 1, bwselect = "mserd")
  tibble(covariate = "surface_water", est = fit$coef[1], se = fit$se[3], pv = fit$pv[3])
}, error = function(e) tibble(covariate = "surface_water", est = NA, se = NA, pv = NA))

balance <- bind_rows(balance, src_balance)
cat("Covariate balance:\n")
print(balance)
robust$balance <- balance

# ============================================================
# F. Donut RDD (exclude systems exactly at threshold)
# ============================================================
cat("\n--- Donut RDD ---\n")

donut_results <- map_dfr(c(50, 100, 200), function(donut) {
  df_d <- df_rdd %>% filter(abs(dist_to_cutoff) > donut)
  tryCatch({
    fit <- rdrobust(y = df_d$any_coliform_mcl, x = df_d$dist_to_cutoff,
                     c = 0, kernel = "triangular", p = 1, bwselect = "mserd")
    tibble(donut_size = donut, est = fit$coef[1], se = fit$se[3],
           pv = fit$pv[3], n_eff = sum(fit$N_h))
  }, error = function(e) tibble(donut_size = donut, est = NA, se = NA, pv = NA, n_eff = NA))
})
cat("Donut RDD:\n")
print(donut_results)
robust$donut <- donut_results

saveRDS(robust, "../data/robustness_results.rds")

cat("\n=== Robustness complete ===\n")
