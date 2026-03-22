# 04_robustness.R — Additional robustness checks
# apep_0735: ABF Monument Boundary Spatial RDD

source("00_packages.R")

data_dir <- "../data/"
df <- fread(file.path(data_dir, "analysis_sample.csv"))
results <- readRDS(file.path(data_dir, "rdd_results.rds"))

cat("Analysis sample:", nrow(df), "rows\n")

# ============================================================
# 1. Polynomial Order Sensitivity
# ============================================================
cat("\n=== Polynomial Order Sensitivity ===\n")

poly_results <- lapply(1:3, function(p) {
  rdd_p <- rdrobust(
    y = df$log_price_m2,
    x = df$dist_to_monument,
    c = 500,
    kernel = "triangular",
    p = p,
    bwselect = "mserd"
  )
  data.frame(
    poly_order = p,
    estimate = rdd_p$coef[2],
    se_robust = rdd_p$se[3],
    pval = rdd_p$pv[3],
    bandwidth = rdd_p$bws[1, 1]
  )
})

poly_df <- bind_rows(poly_results)
cat("Polynomial order sensitivity:\n")
print(poly_df)

# ============================================================
# 2. Kernel Sensitivity
# ============================================================
cat("\n=== Kernel Sensitivity ===\n")

kernels <- c("triangular", "epanechnikov", "uniform")
kernel_results <- lapply(kernels, function(k) {
  rdd_k <- rdrobust(
    y = df$log_price_m2,
    x = df$dist_to_monument,
    c = 500,
    kernel = k,
    p = 1,
    bwselect = "mserd"
  )
  data.frame(
    kernel = k,
    estimate = rdd_k$coef[2],
    se_robust = rdd_k$se[3],
    pval = rdd_k$pv[3]
  )
})

kernel_df <- bind_rows(kernel_results)
cat("Kernel sensitivity:\n")
print(kernel_df)

# ============================================================
# 3. With commune fixed effects (parametric)
# ============================================================
cat("\n=== Parametric RDD with Commune FE ===\n")

# Restrict to CCT optimal bandwidth
bw <- results$main$bw
df_bw <- df[abs(dist_to_monument - 500) <= bw]
cat("Sample within bandwidth:", nrow(df_bw), "\n")

# Parametric local linear with commune FE
fe_model <- feols(
  log_price_m2 ~ treated + dist_centered + treated:dist_centered +
    surface_reelle_bati + nombre_pieces_principales | code_commune + year,
  data = df_bw,
  cluster = ~dept
)

cat("\nParametric RDD with commune FE:\n")
print(summary(fe_model))

# ============================================================
# 4. Heterogeneity by Urban/Rural
# ============================================================
cat("\n=== Urban vs Rural Heterogeneity ===\n")

# Use department-level urbanization proxy: Paris region vs province
df[, ile_de_france := dept %in% c("75", "77", "78", "91", "92", "93", "94", "95")]

for (region in c(TRUE, FALSE)) {
  label <- if (region) "Ile-de-France" else "Province"
  sub <- df[ile_de_france == region]
  if (nrow(sub) < 500) next

  rdd_reg <- rdrobust(
    y = sub$log_price_m2,
    x = sub$dist_to_monument,
    c = 500,
    kernel = "triangular",
    p = 1,
    bwselect = "mserd"
  )
  cat("\n", label, ":\n")
  cat("  Estimate:", round(rdd_reg$coef[2], 4),
      "(Robust SE:", round(rdd_reg$se[3], 4),
      ", p =", round(rdd_reg$pv[3], 3), ")\n")
  cat("  N:", rdd_reg$N[1], "+", rdd_reg$N[2], "\n")
}

# ============================================================
# 5. Year-by-year stability
# ============================================================
cat("\n=== Year-by-Year Stability ===\n")

year_results <- lapply(sort(unique(df$year)), function(yr) {
  sub <- df[year == yr]
  if (nrow(sub) < 500) return(NULL)

  rdd_yr <- tryCatch(
    rdrobust(
      y = sub$log_price_m2,
      x = sub$dist_to_monument,
      c = 500,
      kernel = "triangular",
      p = 1,
      bwselect = "mserd"
    ),
    error = function(e) NULL
  )
  if (is.null(rdd_yr)) return(NULL)

  data.frame(
    year = yr,
    estimate = rdd_yr$coef[2],
    se_robust = rdd_yr$se[3],
    pval = rdd_yr$pv[3],
    n = rdd_yr$N[1] + rdd_yr$N[2]
  )
})

year_df <- bind_rows(year_results)
cat("Year-by-year estimates:\n")
print(year_df)

# ============================================================
# 6. Save all robustness results
# ============================================================
robustness <- list(
  polynomial = poly_df,
  kernel = kernel_df,
  fe_model = broom::tidy(fe_model),
  year_by_year = year_df
)

saveRDS(robustness, file.path(data_dir, "robustness_results.rds"))
cat("\nRobustness results saved.\n")
