## 04_robustness.R — Robustness checks
## apep_1088: IRS 990 Threshold Reform and Nonprofit Growth

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# Load data and models
# ============================================================
df <- fread(file.path(data_dir, "analysis_panel.csv"))
df[, `:=`(
  year_fe = factor(tax_year),
  ein_fe = factor(ein),
  constrained = as.integer(group == "near_200k"),
  post = as.integer(tax_year >= 2014)
)]
load(file.path(data_dir, "models.RData"))

cat("=== Robustness Checks ===\n")

# ============================================================
# R1: Alternative bunching windows
# ============================================================
cat("\n--- R1: Alternative bunching window sizes ---\n")

density_full <- fread(file.path(data_dir, "density_full.csv"))

# Narrow window (±$6K instead of ±$10K)
estimate_bunching_simple <- function(density_dt, threshold, window, bin_width = 2000, poly_order = 7) {
  dt <- copy(density_dt)
  dt[, bin_center := rev_bin + bin_width / 2]
  excl_lo <- threshold - window
  excl_hi <- threshold + window
  dt[, in_window := bin_center >= excl_lo & bin_center <= excl_hi]
  dt[, z := (bin_center - threshold) / bin_width]

  fit_data <- dt[(in_window == FALSE)]
  if (nrow(fit_data) < poly_order + 1) return(list(b_hat = NA, se = NA))

  formula_str <- paste0("count ~ ", paste0("I(z^", 1:poly_order, ")", collapse = " + "))
  fit <- lm(as.formula(formula_str), data = fit_data)
  dt[, predicted := predict(fit, newdata = dt)]

  bunching_bins <- dt[bin_center >= excl_lo & bin_center < threshold]
  excess <- sum(bunching_bins$count) - sum(bunching_bins$predicted)
  avg_cf <- mean(bunching_bins$predicted)
  list(b_hat = excess / avg_cf, excess = excess)
}

b_200k_narrow <- estimate_bunching_simple(density_full, 200000, window = 6000)
b_200k_wide <- estimate_bunching_simple(density_full, 200000, window = 14000)

cat(sprintf("$200K narrow (±$6K): b = %.3f\n", b_200k_narrow$b_hat))
cat(sprintf("$200K baseline (±$10K): b = %.3f\n", bunch_200k$b_hat))
cat(sprintf("$200K wide (±$14K): b = %.3f\n", b_200k_wide$b_hat))

# ============================================================
# R2: Alternative polynomial orders
# ============================================================
cat("\n--- R2: Alternative polynomial orders ---\n")
for (p in c(5, 6, 7, 8, 9)) {
  b <- estimate_bunching_simple(density_full, 200000, window = 10000)
  cat(sprintf("  poly=%d: b = %.3f\n", p, b$b_hat))
}

# ============================================================
# R3: Placebo thresholds (round numbers where no policy exists)
# ============================================================
cat("\n--- R3: Placebo at round-number thresholds ---\n")
for (thresh in c(50000, 75000, 125000, 150000, 175000, 250000, 300000)) {
  b <- estimate_bunching_simple(density_full, thresh, window = 10000)
  if (!is.na(b$b_hat)) {
    cat(sprintf("  $%dK: b = %.3f (excess = %.0f)\n", thresh/1000, b$b_hat, b$excess))
  }
}

# ============================================================
# R4: DiD with alternative control groups
# ============================================================
cat("\n--- R4: Alternative control groups ---\n")

# Near_200k vs control_low
df_alt1 <- df[group %in% c("near_200k", "control_low")]
df_alt1[, constrained := as.integer(group == "near_200k")]
m_alt1 <- feols(log_rev ~ constrained:post | factor(ein) + factor(tax_year),
                data = df_alt1, cluster = ~ein)
cat(sprintf("  vs control_low ($50K-$80K): β = %.4f (SE = %.4f)\n",
    coef(m_alt1)[1], sqrt(vcov(m_alt1)[1,1])))

# Near_100k vs control_low (should be null if $100K no longer binds)
df_alt2 <- df[group %in% c("near_100k", "control_low")]
df_alt2[, treated := as.integer(group == "near_100k")]
m_alt2 <- feols(log_rev ~ treated:post | factor(ein) + factor(tax_year),
                data = df_alt2, cluster = ~ein)
cat(sprintf("  near_100k vs control_low: β = %.4f (SE = %.4f)\n",
    coef(m_alt2)[1], sqrt(vcov(m_alt2)[1,1])))

# ============================================================
# R5: Subsample by period (early vs late)
# ============================================================
cat("\n--- R5: Period subsample ---\n")

# Only 2011-2017
df_early <- df[group %in% c("near_200k", "control_mid") & tax_year <= 2017]
df_early[, constrained := as.integer(group == "near_200k")]
m_early <- feols(log_rev ~ constrained:post | factor(ein) + factor(tax_year),
                 data = df_early, cluster = ~ein)
cat(sprintf("  2011-2017: β = %.4f (SE = %.4f)\n",
    coef(m_early)[1], sqrt(vcov(m_early)[1,1])))

# Only 2015-2022
df_late <- df[group %in% c("near_200k", "control_mid") & tax_year >= 2015]
df_late[, constrained := as.integer(group == "near_200k")]
df_late[, post_late := as.integer(tax_year >= 2018)]
m_late <- feols(log_rev ~ constrained:post_late | factor(ein) + factor(tax_year),
                data = df_late, cluster = ~ein)
cat(sprintf("  2015-2022 (post=2018+): β = %.4f (SE = %.4f)\n",
    coef(m_late)[1], sqrt(vcov(m_late)[1,1])))

# ============================================================
# Save robustness results
# ============================================================
save(m_alt1, m_alt2, m_early, m_late,
     b_200k_narrow, b_200k_wide,
     file = file.path(data_dir, "robustness_models.RData"))

cat("\n04_robustness.R complete.\n")
