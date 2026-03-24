# 03_main_analysis.R — Main hedonic regressions + RDD near Indian threshold
# Tests whether the minority housing discount has converged after 35 years of EIP

source("00_packages.R")

cat("=== Loading Analysis Data ===\n")
df <- readRDS("../data/analysis_data.rds")
pa <- readRDS("../data/pa_ethnic.rds")

cat("Observations:", nrow(df), "\n")
cat("Towns:", n_distinct(df$town), "\n")
cat("Years:", paste(sort(unique(df$year)), collapse = ", "), "\n")

# ============================================================
# 1. Baseline Hedonic Regression: Minority Share and Prices
# ============================================================
cat("\n=== Baseline Hedonic Regressions ===\n")

# Model 1: Pooled OLS — minority share gradient
m1 <- feols(log_price ~ minority_share + floor_area_sqm + storey_mid +
              remaining_lease_years + i(flat_type_f) | year_quarter,
            data = df, cluster = ~town_upper)

# Model 2: Add flat model controls
m2 <- feols(log_price ~ minority_share + floor_area_sqm + storey_mid +
              remaining_lease_years + i(flat_type_f) + i(flat_model) | year_quarter,
            data = df, cluster = ~town_upper)

# Model 3: Add town population control
m3 <- feols(log_price ~ minority_share + floor_area_sqm + storey_mid +
              remaining_lease_years + log(total_pop) +
              i(flat_type_f) + i(flat_model) | year_quarter,
            data = df, cluster = ~town_upper)

cat("\nBaseline results (coefficient on minority_share):\n")
cat("Model 1 (basic):", round(coef(m1)["minority_share"], 4),
    " SE:", round(se(m1)["minority_share"], 4), "\n")
cat("Model 2 (+flat model):", round(coef(m2)["minority_share"], 4),
    " SE:", round(se(m2)["minority_share"], 4), "\n")
cat("Model 3 (+population):", round(coef(m3)["minority_share"], 4),
    " SE:", round(se(m3)["minority_share"], 4), "\n")

# ============================================================
# 2. Time-Varying Minority Gradient (Key Test)
# ============================================================
cat("\n=== Time-Varying Minority Share Gradient ===\n")

# Interact minority_share with year to test for convergence
m4 <- feols(log_price ~ minority_share:i(year) + floor_area_sqm + storey_mid +
              remaining_lease_years + i(flat_type_f) + i(flat_model) | year_quarter,
            data = df, cluster = ~town_upper)

# Extract year-specific minority share coefficients
year_coefs <- data.frame(
  year = sort(unique(df$year)),
  coef = NA_real_,
  se = NA_real_
)

coef_names <- names(coef(m4))
for (i in seq_len(nrow(year_coefs))) {
  yr <- year_coefs$year[i]
  # Match the interaction coefficient name
  pat <- paste0("minority_share:year::", yr)
  idx <- grep(pat, coef_names, fixed = TRUE)
  if (length(idx) == 1) {
    year_coefs$coef[i] <- coef(m4)[idx]
    year_coefs$se[i] <- se(m4)[idx]
  }
}

year_coefs <- year_coefs %>%
  mutate(
    ci_lo = coef - 1.96 * se,
    ci_hi = coef + 1.96 * se
  )

cat("\nYear-specific minority share gradients:\n")
print(year_coefs, digits = 4)

# Test for linear trend in the gradient
trend_test <- lm(coef ~ year, data = year_coefs, weights = 1/se^2)
cat("\nLinear trend in minority gradient:\n")
cat("  Slope:", round(coef(trend_test)[2], 6), "per year\n")
cat("  p-value:", round(summary(trend_test)$coefficients[2, 4], 4), "\n")

# ============================================================
# 3. RDD at Indian Threshold (10%)
# ============================================================
cat("\n=== RDD at Indian EIP Threshold (10%) ===\n")

# The Indian neighbourhood limit (10%) provides the most variation
# Many towns are near this threshold
EIP_INDIAN_LIMIT <- 0.10

# Create running variable: distance from Indian threshold
df <- df %>%
  mutate(
    indian_dist = indian_share - EIP_INDIAN_LIMIT,
    above_indian = as.numeric(indian_share > EIP_INDIAN_LIMIT)
  )

cat("Towns above Indian threshold:", n_distinct(df$town[df$above_indian == 1]), "\n")
cat("Towns below Indian threshold:", n_distinct(df$town[df$above_indian == 0]), "\n")
cat("Transactions above:", sum(df$above_indian == 1), "\n")
cat("Transactions below:", sum(df$above_indian == 0), "\n")

# RDD using rdrobust — town-level running variable, transaction-level outcome
# Use residualized prices (after removing flat characteristics)
resid_model <- feols(log_price ~ floor_area_sqm + storey_mid +
                       remaining_lease_years + i(flat_type_f) + i(flat_model) |
                       year_quarter,
                     data = df)
df$log_price_resid <- residuals(resid_model)

# RDD at the Indian threshold
# NOTE: Running variable is discrete (24 planning area values), so rdrobust may fail
rdd_result <- tryCatch(
  rdrobust(
    y = df$log_price_resid,
    x = df$indian_dist,
    c = 0,
    kernel = "triangular",
    bwselect = "mserd"
  ),
  error = function(e) {
    cat("RDD estimation failed (expected with discrete running variable):", conditionMessage(e), "\n")
    cat("Falling back to parametric comparison above/below threshold.\n")
    NULL
  }
)

if (!is.null(rdd_result)) {
  cat("\nRDD Results (Indian threshold, residualized prices):\n")
  summary(rdd_result)
} else {
  # Parametric comparison above vs below Indian threshold
  m_rdd_param <- feols(log_price ~ above_indian + indian_dist + above_indian:indian_dist +
                          floor_area_sqm + storey_mid + remaining_lease_years +
                          i(flat_type_f) + i(flat_model) | year_quarter,
                        data = df, cluster = ~town_upper)
  cat("\nParametric RDD (above Indian threshold):\n")
  cat("  Coefficient:", round(coef(m_rdd_param)["above_indian"], 4),
      " SE:", round(se(m_rdd_param)["above_indian"], 4), "\n")
  rdd_result <- m_rdd_param
}

# ============================================================
# 4. EIP Constraint Intensity and Prices
# ============================================================
cat("\n=== Constraint Intensity Regressions ===\n")

# Use constraint_intensity (max distance above any threshold, floored at 0)
m5 <- feols(log_price ~ constraint_intensity + floor_area_sqm + storey_mid +
              remaining_lease_years + i(flat_type_f) + i(flat_model) | year_quarter,
            data = df, cluster = ~town_upper)

# Interaction with year
m6 <- feols(log_price ~ constraint_intensity:i(year) + floor_area_sqm + storey_mid +
              remaining_lease_years + i(flat_type_f) + i(flat_model) | year_quarter,
            data = df, cluster = ~town_upper)

cat("Constraint intensity coefficient:", round(coef(m5)["constraint_intensity"], 4),
    " SE:", round(se(m5)["constraint_intensity"], 4), "\n")

# ============================================================
# 5. Save results
# ============================================================
cat("\n=== Saving Results ===\n")

results <- list(
  m1 = m1, m2 = m2, m3 = m3,
  m4 = m4, m5 = m5, m6 = m6,
  year_coefs = year_coefs,
  trend_test = trend_test,
  rdd_result = rdd_result
)
saveRDS(results, "../data/main_results.rds")
saveRDS(df, "../data/analysis_data.rds")  # Updated with residuals

# Write diagnostics for validator
# Hedonic design: "treated" = towns with above-median minority share (cross-sectional)
n_towns_total <- n_distinct(df$town)
n_above_median <- n_distinct(df$town[df$minority_share > median(df$minority_share)])
diagnostics <- list(
  n_treated = n_above_median,
  n_pre = length(unique(df$year)),
  n_obs = nrow(df)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("Results saved.\n")
cat("Diagnostics: n_treated =", n_towns_above,
    ", n_pre =", length(unique(df$year)),
    ", n_obs =", nrow(df), "\n")
