# 04_robustness.R — Robustness checks for EIP ethnic price gradient analysis

source("00_packages.R")

cat("=== Loading Analysis Data and Results ===\n")
df <- readRDS("../data/analysis_data.rds")
results <- readRDS("../data/main_results.rds")
pa <- readRDS("../data/pa_ethnic.rds")

# ============================================================
# 1. Bandwidth Sensitivity for RDD
# ============================================================
cat("\n=== RDD Bandwidth Sensitivity ===\n")

bandwidths <- c(0.02, 0.03, 0.04, 0.05, 0.06, 0.08)
rdd_sensitivity <- data.frame(
  bw = bandwidths,
  coef = NA_real_,
  se = NA_real_,
  n_eff = NA_real_
)

for (i in seq_along(bandwidths)) {
  rdd_i <- tryCatch(
    rdrobust(
      y = df$log_price_resid,
      x = df$indian_dist,
      c = 0,
      h = bandwidths[i],
      kernel = "triangular"
    ),
    error = function(e) NULL
  )
  if (!is.null(rdd_i)) {
    rdd_sensitivity$coef[i] <- rdd_i$coef["Conventional", ]
    rdd_sensitivity$se[i] <- rdd_i$se["Conventional", ]
    rdd_sensitivity$n_eff[i] <- sum(rdd_i$N_h)
  }
}

cat("RDD bandwidth sensitivity:\n")
print(rdd_sensitivity, digits = 4)

# ============================================================
# 2. McCrary-style density test at Indian threshold
# ============================================================
cat("\n=== Density Test at Indian Threshold ===\n")

# Use rddensity for manipulation testing
# Note: running variable is town-level, so density test uses town-level data
town_indian <- pa %>%
  select(town, indian_share, indian_dist) %>%
  filter(!is.na(indian_dist))

cat("Number of planning areas for density test:", nrow(town_indian), "\n")

# With only ~26 planning areas, formal density test has low power
# Report the distribution descriptively
cat("\nIndian share distribution near threshold (10%):\n")
cat("  Below 10%:", sum(town_indian$indian_share < 0.10), "towns\n")
cat("  8-12% band:", sum(town_indian$indian_share >= 0.08 &
                           town_indian$indian_share <= 0.12), "towns\n")
cat("  Above 10%:", sum(town_indian$indian_share >= 0.10), "towns\n")

# ============================================================
# 3. Placebo: Chinese Threshold (84%)
# ============================================================
cat("\n=== Placebo: Chinese Threshold (84%) ===\n")

df <- df %>%
  mutate(
    chinese_dist = chinese_share - 0.84,
    above_chinese = as.numeric(chinese_share > 0.84)
  )

n_chinese_above <- sum(pa$chinese_share > 0.84, na.rm = TRUE)
cat("Towns above Chinese 84% threshold:", n_chinese_above, "\n")

if (n_chinese_above > 0 && n_chinese_above < nrow(pa)) {
  rdd_chinese <- tryCatch(
    rdrobust(
      y = df$log_price_resid,
      x = df$chinese_dist,
      c = 0,
      kernel = "triangular",
      bwselect = "mserd"
    ),
    error = function(e) {
      cat("Chinese RDD failed:", conditionMessage(e), "\n")
      NULL
    }
  )
  if (!is.null(rdd_chinese)) {
    cat("Chinese threshold RDD:\n")
    summary(rdd_chinese)
  }
} else {
  cat("Insufficient variation around Chinese threshold for RDD.\n")
}

# ============================================================
# 4. Sample Splits — flat type heterogeneity
# ============================================================
cat("\n=== Heterogeneity by Flat Type ===\n")

# Small flats (1-3 room) vs large flats (4 room+)
df <- df %>%
  mutate(large_flat = flat_type %in% c("4 ROOM", "5 ROOM", "EXECUTIVE", "MULTI-GENERATION"))

m_small <- feols(log_price ~ minority_share + floor_area_sqm + storey_mid +
                   remaining_lease_years + i(flat_type_f) + i(flat_model) | year_quarter,
                 data = filter(df, !large_flat), cluster = ~town_upper)

m_large <- feols(log_price ~ minority_share + floor_area_sqm + storey_mid +
                   remaining_lease_years + i(flat_type_f) + i(flat_model) | year_quarter,
                 data = filter(df, large_flat), cluster = ~town_upper)

cat("Small flats (1-3 room): minority_share =",
    round(coef(m_small)["minority_share"], 4),
    " SE:", round(se(m_small)["minority_share"], 4),
    " N:", nobs(m_small), "\n")
cat("Large flats (4+ room): minority_share =",
    round(coef(m_large)["minority_share"], 4),
    " SE:", round(se(m_large)["minority_share"], 4),
    " N:", nobs(m_large), "\n")

# ============================================================
# 5. Early vs Late period split
# ============================================================
cat("\n=== Early vs Late Period ===\n")

median_year <- median(df$year)
m_early <- feols(log_price ~ minority_share + floor_area_sqm + storey_mid +
                   remaining_lease_years + i(flat_type_f) + i(flat_model) | year_quarter,
                 data = filter(df, year <= median_year), cluster = ~town_upper)

m_late <- feols(log_price ~ minority_share + floor_area_sqm + storey_mid +
                  remaining_lease_years + i(flat_type_f) + i(flat_model) | year_quarter,
                data = filter(df, year > median_year), cluster = ~town_upper)

cat("Early (2017-", median_year, "): minority_share =",
    round(coef(m_early)["minority_share"], 4),
    " SE:", round(se(m_early)["minority_share"], 4),
    " N:", nobs(m_early), "\n")
cat("Late (", median_year + 1, "+): minority_share =",
    round(coef(m_late)["minority_share"], 4),
    " SE:", round(se(m_late)["minority_share"], 4),
    " N:", nobs(m_late), "\n")

# ============================================================
# 6. Remaining lease heterogeneity
# ============================================================
cat("\n=== Heterogeneity by Remaining Lease ===\n")

df <- df %>%
  mutate(old_lease = remaining_lease_years < 60)

m_new <- feols(log_price ~ minority_share + floor_area_sqm + storey_mid +
                 remaining_lease_years + i(flat_type_f) + i(flat_model) | year_quarter,
               data = filter(df, !old_lease), cluster = ~town_upper)

m_old <- feols(log_price ~ minority_share + floor_area_sqm + storey_mid +
                 remaining_lease_years + i(flat_type_f) + i(flat_model) | year_quarter,
               data = filter(df, old_lease), cluster = ~town_upper)

cat("New lease (60+ years): minority_share =",
    round(coef(m_new)["minority_share"], 4),
    " SE:", round(se(m_new)["minority_share"], 4),
    " N:", nobs(m_new), "\n")
cat("Old lease (<60 years): minority_share =",
    round(coef(m_old)["minority_share"], 4),
    " SE:", round(se(m_old)["minority_share"], 4),
    " N:", nobs(m_old), "\n")

# ============================================================
# Save robustness results
# ============================================================
rob_results <- list(
  rdd_sensitivity = rdd_sensitivity,
  m_small = m_small, m_large = m_large,
  m_early = m_early, m_late = m_late,
  m_new = m_new, m_old = m_old
)
saveRDS(rob_results, "../data/robustness_results.rds")
saveRDS(df, "../data/analysis_data.rds")  # Updated with large_flat, old_lease, etc.
cat("\nRobustness results saved.\n")
