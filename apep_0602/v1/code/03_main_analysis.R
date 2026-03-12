## 03_main_analysis.R — Main RDD analysis at the 30% CDR threshold
## apep_0602: CDR Threshold and For-Profit College Behavior

library(tidyverse)
library(rdrobust)
library(rddensity)
library(jsonlite)

set.seed(20260312)

analysis <- readRDS("data/analysis_panel.rds")

cat("=== MAIN ANALYSIS: RDD at 30% CDR Threshold ===\n\n")

# --- 1. McCrary Density Test ---
cat("--- McCrary Density Test ---\n")
density_test <- rddensity(analysis$cdr3_pct, c = 30)
cat(sprintf("McCrary test statistic: %.3f (p = %.4f)\n",
            density_test$test$t_jk, density_test$test$p_jk))

# Store for paper
density_result <- list(
  test_stat = density_test$test$t_jk,
  p_value = density_test$test$p_jk
)

# --- 2. Main RDD: Enrollment ---
cat("\n--- RDD: Log Enrollment ---\n")
enroll_sample <- analysis %>% filter(!is.na(log_enrollment))
rdd_enroll <- rdrobust(
  y = enroll_sample$log_enrollment,
  x = enroll_sample$cdr3_pct,
  c = 30,
  kernel = "triangular",
  bwselect = "mserd"
)
summary(rdd_enroll)

# --- 3. Main RDD: Completion Rate ---
cat("\n--- RDD: Completion Rate ---\n")
comp_sample <- analysis %>% filter(!is.na(completion_rate) & is.finite(completion_rate))
rdd_comp <- rdrobust(
  y = comp_sample$completion_rate,
  x = comp_sample$cdr3_pct,
  c = 30,
  kernel = "triangular",
  bwselect = "mserd"
)
summary(rdd_comp)

# --- 4. Main RDD: 3-Year Closure ---
cat("\n--- RDD: 3-Year Closure ---\n")
close_sample <- analysis %>% filter(!is.na(closed_3yr))
rdd_close <- rdrobust(
  y = close_sample$closed_3yr,
  x = close_sample$cdr3_pct,
  c = 30,
  kernel = "triangular",
  bwselect = "mserd"
)
summary(rdd_close)

# --- 5. Main RDD: Pell Share ---
cat("\n--- RDD: Pell Recipient Share ---\n")
pell_sample <- analysis %>% filter(!is.na(pell_share) & is.finite(pell_share))
rdd_pell <- rdrobust(
  y = pell_sample$pell_share,
  x = pell_sample$cdr3_pct,
  c = 30,
  kernel = "triangular",
  bwselect = "mserd"
)
summary(rdd_pell)

# --- 6. Secondary Cutoff: 40% (Single-Year Trigger) ---
cat("\n--- RDD at 40% (Immediate Sanction) ---\n")
enroll_40 <- analysis %>% filter(!is.na(log_enrollment) & cdr3_pct >= 20)
if (sum(enroll_40$cdr3_pct >= 40) >= 20) {
  rdd_enroll_40 <- rdrobust(
    y = enroll_40$log_enrollment,
    x = enroll_40$cdr3_pct,
    c = 40,
    kernel = "triangular",
    bwselect = "mserd"
  )
  summary(rdd_enroll_40)
} else {
  cat("Insufficient observations above 40% for RDD.\n")
  rdd_enroll_40 <- NULL
}

# --- 7. Placebo Cutoff: 20% ---
cat("\n--- Placebo RDD at 20% (No Regulatory Threshold) ---\n")
placebo_sample <- analysis %>% filter(!is.na(log_enrollment) & cdr3_pct >= 5 & cdr3_pct <= 35)
rdd_placebo_20 <- rdrobust(
  y = placebo_sample$log_enrollment,
  x = placebo_sample$cdr3_pct,
  c = 20,
  kernel = "triangular",
  bwselect = "mserd"
)
summary(rdd_placebo_20)

# --- 8. Covariate Balance Tests ---
cat("\n--- Covariate Balance: Log Cohort Size ---\n")
cohort_sample <- analysis %>% filter(!is.na(log_cohort))
rdd_cohort <- rdrobust(
  y = cohort_sample$log_cohort,
  x = cohort_sample$cdr3_pct,
  c = 30,
  kernel = "triangular",
  bwselect = "mserd"
)
cat(sprintf("Covariate (log cohort): coef=%.3f, se=%.3f, p=%.3f\n",
            rdd_cohort$coef[1], rdd_cohort$se[3], rdd_cohort$pv[3]))

# --- 9. Extract and Store Results ---
extract_rdd <- function(rdd_obj, name) {
  list(
    outcome = name,
    coef_conv = rdd_obj$coef[1],
    coef_bc = rdd_obj$coef[2],
    coef_robust = rdd_obj$coef[3],
    se_conv = rdd_obj$se[1],
    se_bc = rdd_obj$se[2],
    se_robust = rdd_obj$se[3],
    pv_conv = rdd_obj$pv[1],
    pv_bc = rdd_obj$pv[2],
    pv_robust = rdd_obj$pv[3],
    ci_lower = rdd_obj$ci[3, 1],
    ci_upper = rdd_obj$ci[3, 2],
    bw_left = rdd_obj$bws[1, 1],
    bw_right = rdd_obj$bws[1, 2],
    N_left = rdd_obj$N_h[1],
    N_right = rdd_obj$N_h[2],
    N_eff_left = rdd_obj$N_h[1],
    N_eff_right = rdd_obj$N_h[2]
  )
}

results <- list(
  enrollment = extract_rdd(rdd_enroll, "Log Enrollment"),
  completion = extract_rdd(rdd_comp, "Completion Rate"),
  closure = extract_rdd(rdd_close, "3-Year Closure"),
  pell_share = extract_rdd(rdd_pell, "Pell Share"),
  placebo_20 = extract_rdd(rdd_placebo_20, "Placebo: Log Enrollment at 20%"),
  density = density_result,
  cohort_balance = list(
    coef = rdd_cohort$coef[3],
    se = rdd_cohort$se[3],
    pv = rdd_cohort$pv[3]
  )
)

if (!is.null(rdd_enroll_40)) {
  results$enroll_40 <- extract_rdd(rdd_enroll_40, "Log Enrollment at 40%")
}

saveRDS(results, "data/main_results.rds")

# --- 10. Write diagnostics.json ---
n_above <- sum(analysis$above_30 == 1)
n_below <- sum(analysis$above_30 == 0)
bw <- rdd_enroll$bws[1, 1]
n_bw <- sum(abs(analysis$cdr_centered) <= bw)

diagnostics <- list(
  n_treated = n_above,
  n_pre = as.integer(length(unique(analysis$year))),  # RDD: all years used in pooled design
  n_obs = nrow(analysis),
  n_institutions = n_distinct(analysis$unitid),
  n_above_30 = n_above,
  n_below_30 = n_below,
  n_in_bandwidth = n_bw,
  bandwidth_optimal = round(bw, 2),
  years = paste(range(analysis$year), collapse = "-"),
  mccrary_p = round(density_result$p_value, 4)
)

write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Results saved to data/main_results.rds ===\n")
cat("=== Diagnostics saved to data/diagnostics.json ===\n")

# Print summary table
cat("\n\n=== RESULTS SUMMARY ===\n")
cat(sprintf("%-25s %10s %10s %10s %6s %6s\n",
            "Outcome", "Coef(BC)", "SE(Rob)", "p(Rob)", "N_L", "N_R"))
cat(paste(rep("-", 75), collapse = ""), "\n")
for (nm in c("enrollment", "completion", "closure", "pell_share")) {
  r <- results[[nm]]
  cat(sprintf("%-25s %10.4f %10.4f %10.4f %6d %6d\n",
              r$outcome, r$coef_bc, r$se_robust, r$pv_robust,
              r$N_left, r$N_right))
}
cat(paste(rep("-", 75), collapse = ""), "\n")
cat(sprintf("Placebo (20%% cutoff): coef=%.4f, p=%.4f\n",
            results$placebo_20$coef_bc, results$placebo_20$pv_robust))
cat(sprintf("McCrary density test: T=%.3f, p=%.4f\n",
            results$density$test_stat, results$density$p_value))
