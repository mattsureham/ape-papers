## 04_robustness.R — Robustness checks for RDD
## APEP paper apep_0614: CEJST Justice40 RDD

source("00_packages.R")

data_dir <- "../data"

analysis <- readRDS(file.path(data_dir, "analysis_dataset.rds"))
# Use full sample (same as main analysis — fuzzy RDD at income threshold)
rdd_sample <- analysis[!is.na(income_pctile) & !is.na(rv_centered)]

# ============================================================
# 1. Placebo Cutoffs
# ============================================================
cat("=== Placebo Cutoff Tests ===\n")

# Test at non-binding cutoff points
# The real cutoff is at the 65th percentile (rv_centered = 0)
# Test at median (50th), 55th, 75th, 80th percentiles
cutoff_real <- 0  # centered at 65th percentile
# Need to translate other percentiles to centered values
# If cutoff is at 65 (or 0.65), then:
# 50th -> -15 (or -0.15), 55th -> -10 (or -0.10), 75th -> +10 (or +0.10), 80th -> +15 (or +0.15)
max_rv <- max(rdd_sample$rv_centered, na.rm = TRUE)
scale <- if (max_rv > 1) 1 else 0.01  # Detect scale

placebo_cutoffs <- c(-15, -10, -5, 5, 10, 15) * scale
placebo_results <- list()

for (pc in placebo_cutoffs) {
  # Only use observations NOT near the real cutoff
  # Exclude observations within 5 percentile points of the real cutoff
  if (pc < 0) {
    sub <- rdd_sample[rv_centered < -2 * scale]
  } else {
    sub <- rdd_sample[rv_centered > 2 * scale]
  }

  fit_placebo <- tryCatch(
    rdrobust(y = sub$any_ev_post, x = sub$rv_centered, c = pc,
             kernel = "triangular", bwselect = "mserd", vce = "hc1"),
    error = function(e) NULL
  )

  if (!is.null(fit_placebo)) {
    placebo_results[[as.character(pc)]] <- data.table(
      cutoff_shift = pc / scale,
      estimate = fit_placebo$coef[1],
      se = fit_placebo$se[1],
      pval = fit_placebo$pv[1],
      n_eff = fit_placebo$N[1] + fit_placebo$N[2]
    )
  }
}

if (length(placebo_results) > 0) {
  placebo_dt <- rbindlist(placebo_results)
  cat("Placebo cutoff results (any EV charger):\n")
  print(placebo_dt)
}

# ============================================================
# 2. Donut RDD
# ============================================================
cat("\n=== Donut RDD ===\n")

# Exclude observations within narrow windows of the cutoff
donut_widths <- c(0.5, 1, 2, 3) * scale
donut_results <- list()

for (dw in donut_widths) {
  sub_donut <- rdd_sample[abs(rv_centered) > dw]
  if (nrow(sub_donut) < 200) next

  fit_donut <- tryCatch(
    rdrobust(y = sub_donut$any_ev_post, x = sub_donut$rv_centered, c = 0,
             kernel = "triangular", bwselect = "mserd", vce = "hc1"),
    error = function(e) NULL
  )

  if (!is.null(fit_donut)) {
    donut_results[[as.character(dw)]] <- data.table(
      donut_width = dw / scale,
      estimate = fit_donut$coef[1],
      se = fit_donut$se[1],
      pval = fit_donut$pv[1],
      n_eff = fit_donut$N[1] + fit_donut$N[2]
    )
  }
}

if (length(donut_results) > 0) {
  donut_dt <- rbindlist(donut_results)
  cat("Donut RDD results:\n")
  print(donut_dt)
}

# ============================================================
# 3. Polynomial Sensitivity
# ============================================================
cat("\n=== Polynomial Sensitivity ===\n")

poly_results <- list()
for (p in 1:3) {
  fit_poly <- tryCatch(
    rdrobust(y = rdd_sample$any_ev_post, x = rdd_sample$rv_centered, c = 0,
             p = p, kernel = "triangular", bwselect = "mserd", vce = "hc1"),
    error = function(e) NULL
  )
  if (!is.null(fit_poly)) {
    poly_results[[as.character(p)]] <- data.table(
      polynomial = p,
      estimate = fit_poly$coef[1],
      se = fit_poly$se[1],
      pval = fit_poly$pv[1],
      bandwidth = fit_poly$bws[1, 1]
    )
  }
}

if (length(poly_results) > 0) {
  poly_dt <- rbindlist(poly_results)
  cat("Polynomial sensitivity:\n")
  print(poly_dt)
}

# ============================================================
# 4. Alternative Kernels
# ============================================================
cat("\n=== Kernel Sensitivity ===\n")

kernel_results <- list()
for (k in c("triangular", "epanechnikov", "uniform")) {
  fit_k <- tryCatch(
    rdrobust(y = rdd_sample$any_ev_post, x = rdd_sample$rv_centered, c = 0,
             kernel = k, bwselect = "mserd", vce = "hc1"),
    error = function(e) NULL
  )
  if (!is.null(fit_k)) {
    kernel_results[[k]] <- data.table(
      kernel = k,
      estimate = fit_k$coef[1],
      se = fit_k$se[1],
      pval = fit_k$pv[1],
      bandwidth = fit_k$bws[1, 1]
    )
  }
}

if (length(kernel_results) > 0) {
  kernel_dt <- rbindlist(kernel_results)
  cat("Kernel sensitivity:\n")
  print(kernel_dt)
}

# ============================================================
# 5. Subgroup Heterogeneity
# ============================================================
cat("\n=== Heterogeneity Analysis ===\n")

# By population density (above/below median)
if ("population" %in% names(rdd_sample)) {
  med_pop <- median(rdd_sample$population, na.rm = TRUE)

  het_results <- list()
  for (group in c("high_pop", "low_pop")) {
    sub <- if (group == "high_pop") {
      rdd_sample[population >= med_pop]
    } else {
      rdd_sample[population < med_pop]
    }

    fit_het <- tryCatch(
      rdrobust(y = sub$any_ev_post, x = sub$rv_centered, c = 0,
               kernel = "triangular", bwselect = "mserd", vce = "hc1"),
      error = function(e) NULL
    )

    if (!is.null(fit_het)) {
      het_results[[group]] <- data.table(
        subgroup = group,
        estimate = fit_het$coef[1],
        se = fit_het$se[1],
        pval = fit_het$pv[1],
        n = fit_het$N[1] + fit_het$N[2]
      )
    }
  }

  if (length(het_results) > 0) {
    het_dt <- rbindlist(het_results)
    cat("Population density heterogeneity:\n")
    print(het_dt)
  }
}

# By region (using state FIPS)
# Northeast (01-29 roughly), South, Midwest, West
rdd_sample[, region := fcase(
  state_fips %in% c("09","23","25","33","34","36","42","44","50"), "Northeast",
  state_fips %in% c("17","18","19","20","26","27","29","31","38","39","46","55"), "Midwest",
  state_fips %in% c("01","05","10","11","12","13","21","22","24","28","37","40","45","47","48","51","54"), "South",
  state_fips %in% c("02","04","06","08","15","16","30","32","35","41","49","53","56"), "West",
  default = "Other"
)]

region_results <- list()
for (reg in unique(rdd_sample$region)) {
  sub_reg <- rdd_sample[region == reg]
  if (nrow(sub_reg) < 500) next

  fit_reg <- tryCatch(
    rdrobust(y = sub_reg$any_ev_post, x = sub_reg$rv_centered, c = 0,
             kernel = "triangular", bwselect = "mserd", vce = "hc1"),
    error = function(e) NULL
  )

  if (!is.null(fit_reg)) {
    region_results[[reg]] <- data.table(
      region = reg,
      estimate = fit_reg$coef[1],
      se = fit_reg$se[1],
      pval = fit_reg$pv[1],
      n = fit_reg$N[1] + fit_reg$N[2]
    )
  }
}

if (length(region_results) > 0) {
  region_dt <- rbindlist(region_results)
  cat("Regional heterogeneity:\n")
  print(region_dt)
}

# ============================================================
# 6. Pre-treatment Placebo (EV chargers opened pre-CEJST)
# ============================================================
cat("\n=== Pre-Treatment Placebo ===\n")

# If CEJST had no effect, there should be no discontinuity in pre-period EV installations
rdd_preplacebo <- tryCatch(
  rdrobust(y = rdd_sample$ev_count_pre, x = rdd_sample$rv_centered, c = 0,
           kernel = "triangular", bwselect = "mserd", vce = "hc1"),
  error = function(e) NULL
)

if (!is.null(rdd_preplacebo)) {
  cat("Pre-treatment EV placebo:\n")
  summary(rdd_preplacebo)
}

# ============================================================
# Save all robustness results
# ============================================================
robustness <- list(
  placebo_cutoffs = if (exists("placebo_dt")) placebo_dt else NULL,
  donut = if (exists("donut_dt")) donut_dt else NULL,
  polynomial = if (exists("poly_dt")) poly_dt else NULL,
  kernel = if (exists("kernel_dt")) kernel_dt else NULL,
  heterogeneity_pop = if (exists("het_dt")) het_dt else NULL,
  heterogeneity_region = if (exists("region_dt")) region_dt else NULL,
  pre_placebo = rdd_preplacebo
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))
cat("\nRobustness results saved.\n")
