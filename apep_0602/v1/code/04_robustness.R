## 04_robustness.R — Robustness checks for the CDR RDD
## apep_0602: CDR Threshold and For-Profit College Behavior

library(tidyverse)
library(rdrobust)

set.seed(20260312)

analysis <- readRDS("data/analysis_panel.rds")
main_results <- readRDS("data/main_results.rds")

cat("=== ROBUSTNESS CHECKS ===\n\n")

# --- 1. Bandwidth Sensitivity ---
cat("--- Bandwidth Sensitivity (Enrollment) ---\n")
enroll_sample <- analysis %>% filter(!is.na(log_enrollment))

# Get optimal bandwidth from main results
bw_opt <- main_results$enrollment$bw_left

bw_multipliers <- c(0.5, 0.75, 1.0, 1.25, 1.5, 2.0)
bw_results <- list()

for (mult in bw_multipliers) {
  bw_use <- bw_opt * mult
  rdd_bw <- rdrobust(
    y = enroll_sample$log_enrollment,
    x = enroll_sample$cdr3_pct,
    c = 30,
    h = bw_use,
    kernel = "triangular"
  )
  bw_results[[as.character(mult)]] <- list(
    multiplier = mult,
    bandwidth = bw_use,
    coef = rdd_bw$coef[2],
    se = rdd_bw$se[3],
    pv = rdd_bw$pv[3],
    ci_lower = rdd_bw$ci[3, 1],
    ci_upper = rdd_bw$ci[3, 2],
    n_left = rdd_bw$N_h[1],
    n_right = rdd_bw$N_h[2]
  )
  cat(sprintf("  BW=%.1f (%.1fx): coef=%.4f, se=%.4f, p=%.4f, N=%d+%d\n",
              bw_use, mult, rdd_bw$coef[2], rdd_bw$se[3], rdd_bw$pv[3],
              rdd_bw$N_h[1], rdd_bw$N_h[2]))
}

# --- 2. Donut-Hole RDD ---
cat("\n--- Donut-Hole RDD (Exclude Observations Near Cutoff) ---\n")

donut_results <- list()
for (donut_size in c(0.5, 1.0, 1.5, 2.0)) {
  donut_sample <- enroll_sample %>%
    filter(abs(cdr3_pct - 30) > donut_size)

  if (sum(donut_sample$cdr3_pct >= 30) >= 20 & sum(donut_sample$cdr3_pct < 30) >= 20) {
    rdd_donut <- rdrobust(
      y = donut_sample$log_enrollment,
      x = donut_sample$cdr3_pct,
      c = 30,
      kernel = "triangular",
      bwselect = "mserd"
    )
    donut_results[[as.character(donut_size)]] <- list(
      donut = donut_size,
      coef = rdd_donut$coef[2],
      se = rdd_donut$se[3],
      pv = rdd_donut$pv[3],
      n_left = rdd_donut$N_h[1],
      n_right = rdd_donut$N_h[2]
    )
    cat(sprintf("  Donut=%.1fpp: coef=%.4f, se=%.4f, p=%.4f\n",
                donut_size, rdd_donut$coef[2], rdd_donut$se[3], rdd_donut$pv[3]))
  }
}

# --- 3. Local Quadratic Specification ---
cat("\n--- Local Quadratic Specification ---\n")
rdd_quad <- rdrobust(
  y = enroll_sample$log_enrollment,
  x = enroll_sample$cdr3_pct,
  c = 30,
  p = 2,  # Quadratic
  kernel = "triangular",
  bwselect = "mserd"
)
cat(sprintf("  Quadratic: coef=%.4f, se=%.4f, p=%.4f\n",
            rdd_quad$coef[2], rdd_quad$se[3], rdd_quad$pv[3]))

# --- 4. Alternative Kernels ---
cat("\n--- Alternative Kernels ---\n")
for (kern in c("uniform", "epanechnikov")) {
  rdd_kern <- rdrobust(
    y = enroll_sample$log_enrollment,
    x = enroll_sample$cdr3_pct,
    c = 30,
    kernel = kern,
    bwselect = "mserd"
  )
  cat(sprintf("  %s: coef=%.4f, se=%.4f, p=%.4f\n",
              kern, rdd_kern$coef[2], rdd_kern$se[3], rdd_kern$pv[3]))
}

# --- 5. Placebo Cutoffs ---
cat("\n--- Placebo Cutoffs (Enrollment) ---\n")
placebo_cutoffs <- c(15, 20, 25, 35)
placebo_results <- list()

for (pc in placebo_cutoffs) {
  pc_sample <- enroll_sample %>%
    filter(cdr3_pct >= (pc - 15) & cdr3_pct <= (pc + 15))

  if (sum(pc_sample$cdr3_pct >= pc) >= 20 & sum(pc_sample$cdr3_pct < pc) >= 20) {
    rdd_pc <- rdrobust(
      y = pc_sample$log_enrollment,
      x = pc_sample$cdr3_pct,
      c = pc,
      kernel = "triangular",
      bwselect = "mserd"
    )
    placebo_results[[as.character(pc)]] <- list(
      cutoff = pc,
      coef = rdd_pc$coef[2],
      se = rdd_pc$se[3],
      pv = rdd_pc$pv[3]
    )
    cat(sprintf("  Cutoff=%d%%: coef=%.4f, se=%.4f, p=%.4f\n",
                pc, rdd_pc$coef[2], rdd_pc$se[3], rdd_pc$pv[3]))
  } else {
    cat(sprintf("  Cutoff=%d%%: insufficient observations\n", pc))
  }
}

# --- 6. Year-by-Year RDD ---
cat("\n--- Year-by-Year RDD (Enrollment) ---\n")
yearly_results <- list()

for (yr in sort(unique(enroll_sample$year))) {
  yr_sample <- enroll_sample %>% filter(year == yr)
  n_above <- sum(yr_sample$cdr3_pct >= 30)
  n_below <- sum(yr_sample$cdr3_pct < 30 & yr_sample$cdr3_pct >= 15)

  if (n_above >= 15 & n_below >= 30) {
    rdd_yr <- tryCatch(
      rdrobust(
        y = yr_sample$log_enrollment,
        x = yr_sample$cdr3_pct,
        c = 30,
        kernel = "triangular",
        bwselect = "mserd"
      ),
      error = function(e) NULL
    )

    if (!is.null(rdd_yr)) {
      yearly_results[[as.character(yr)]] <- list(
        year = yr,
        coef = rdd_yr$coef[2],
        se = rdd_yr$se[3],
        pv = rdd_yr$pv[3],
        n_left = rdd_yr$N_h[1],
        n_right = rdd_yr$N_h[2]
      )
      cat(sprintf("  %d: coef=%.4f, se=%.4f, p=%.4f, N=%d+%d\n",
                  yr, rdd_yr$coef[2], rdd_yr$se[3], rdd_yr$pv[3],
                  rdd_yr$N_h[1], rdd_yr$N_h[2]))
    }
  } else {
    cat(sprintf("  %d: insufficient observations (n_above=%d, n_below=%d)\n",
                yr, n_above, n_below))
  }
}

# --- 7. Covariate Balance (Additional) ---
cat("\n--- Additional Covariate Balance Tests ---\n")

# Year as covariate (should be smooth — no sorting by year)
rdd_year <- rdrobust(
  y = analysis$year,
  x = analysis$cdr3_pct,
  c = 30,
  kernel = "triangular",
  bwselect = "mserd"
)
cat(sprintf("  Year: coef=%.3f, p=%.3f\n", rdd_year$coef[2], rdd_year$pv[3]))

# --- Save robustness results ---
robustness <- list(
  bandwidth_sensitivity = bw_results,
  donut_hole = donut_results,
  quadratic = list(coef = rdd_quad$coef[2], se = rdd_quad$se[3], pv = rdd_quad$pv[3]),
  placebo_cutoffs = placebo_results,
  yearly = yearly_results
)

saveRDS(robustness, "data/robustness_results.rds")
cat("\n=== Robustness results saved ===\n")
