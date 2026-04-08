## 04_robustness.R — Robustness checks for UK MOT RDD
## apep_1414: UK MOT First-Inspection RDD

source("code/00_packages.R")
setwd(here::here("output", "apep_1414", "v1"))

df <- readRDS("data/analysis_dataset.rds")
df_rdd <- df %>% filter(!is.na(y_first))

cat(sprintf("Robustness analysis on %d observations\n", nrow(df_rdd)))

## ──────────────────────────────────────────────────────────────
## 1. Bandwidth Sensitivity
## ──────────────────────────────────────────────────────────────

cat("\n--- Bandwidth Sensitivity ---\n")

bandwidths <- c(2, 3, 4, 5, 6, 8)
bw_results <- list()

for (bw in bandwidths) {
  result <- tryCatch({
    rdd <- rdrobust(y = df_rdd$y_first, x = df_rdd$rv, c = 0,
                    kernel = "triangular", h = bw)
    list(
      bw = bw,
      n_left = rdd$N_h[1],
      n_right = rdd$N_h[2],
      coef_conv = rdd$coef[1],
      se_conv = rdd$se[1],
      p_conv = rdd$pv[1],
      coef_robust = rdd$coef[3],
      se_robust = rdd$se[3],
      p_robust = rdd$pv[3]
    )
  }, error = function(e) {
    cat(sprintf("Warning: bw=%d failed: %s\n", bw, e$message))
    NULL
  })
  if (!is.null(result)) {
    bw_results[[as.character(bw)]] <- result
    cat(sprintf("bw=%.0f: coef=%.4f (robust p=%.4f), N=(L=%d, R=%d)\n",
                bw, result$coef_robust, result$p_robust, result$n_left, result$n_right))
  }
}

bw_sensitivity_df <- bind_rows(bw_results)
saveRDS(bw_sensitivity_df, "data/bw_sensitivity.rds")

## ──────────────────────────────────────────────────────────────
## 2. Placebo Cutoffs
## ──────────────────────────────────────────────────────────────

cat("\n--- Placebo Cutoffs ---\n")

placebo_cutoffs <- c(-6, -4, -2, 4, 6, 8)  # Months offset from true cutoff (rv=0)
placebo_results <- list()

for (pc in placebo_cutoffs) {
  result <- tryCatch({
    rdd <- rdrobust(y = df_rdd$y_first, x = df_rdd$rv, c = pc,
                    kernel = "triangular", bwselect = "mserd")
    list(
      placebo_cutoff = pc,
      true_month = 36 + pc,
      coef_robust = rdd$coef[3],
      se_robust = rdd$se[3],
      p_robust = rdd$pv[3],
      bw = rdd$bws[1]
    )
  }, error = function(e) {
    cat(sprintf("Warning: placebo cutoff=%d failed: %s\n", pc, e$message))
    NULL
  })
  if (!is.null(result)) {
    placebo_results[[as.character(pc)]] <- result
    cat(sprintf("Placebo cutoff rv=%+d (month %d): coef=%.4f (p=%.4f)\n",
                pc, result$true_month, result$coef_robust, result$p_robust))
  }
}

placebo_df <- bind_rows(placebo_results)
saveRDS(placebo_df, "data/placebo_results.rds")

## ──────────────────────────────────────────────────────────────
## 3. Donut RDD (exclude ±1 month of threshold to address bunching)
## ──────────────────────────────────────────────────────────────

cat("\n--- Donut RDD (excluding ±1 month) ---\n")

df_donut <- df_rdd %>% filter(abs(rv) > 1)
cat(sprintf("Donut sample: %d observations (excluded %d)\n",
            nrow(df_donut), nrow(df_rdd) - nrow(df_donut)))

donut_result <- tryCatch({
  rdrobust(y = df_donut$y_first, x = df_donut$rv, c = 0,
           kernel = "triangular", bwselect = "mserd")
}, error = function(e) {
  cat("Warning: donut RDD failed:", e$message, "\n")
  NULL
})

if (!is.null(donut_result)) {
  cat(sprintf("Donut RDD estimate (robust): %.4f (SE=%.4f, p=%.4f)\n",
              donut_result$coef[3], donut_result$se[3], donut_result$pv[3]))
  saveRDS(donut_result, "data/donut_result.rds")
}

## ──────────────────────────────────────────────────────────────
## 4. Kernel Sensitivity
## ──────────────────────────────────────────────────────────────

cat("\n--- Kernel Sensitivity ---\n")

kernels <- c("triangular", "uniform", "epanechnikov")
kernel_results <- list()

for (kern in kernels) {
  result <- tryCatch({
    rdd <- rdrobust(y = df_rdd$y_first, x = df_rdd$rv, c = 0,
                    kernel = kern, bwselect = "mserd")
    list(
      kernel = kern,
      coef_robust = rdd$coef[3],
      se_robust = rdd$se[3],
      p_robust = rdd$pv[3],
      bw = rdd$bws[1]
    )
  }, error = function(e) {
    cat(sprintf("Warning: kernel=%s failed: %s\n", kern, e$message))
    NULL
  })
  if (!is.null(result)) {
    kernel_results[[kern]] <- result
    cat(sprintf("Kernel=%s: coef=%.4f (p=%.4f), bw=%.2f\n",
                kern, result$coef_robust, result$p_robust, result$bw))
  }
}

kernel_df <- bind_rows(kernel_results)
saveRDS(kernel_df, "data/kernel_sensitivity.rds")

## ──────────────────────────────────────────────────────────────
## 5. Fuel-type heterogeneity
## ──────────────────────────────────────────────────────────────

if ("fuel_clean" %in% names(df_rdd)) {
  cat("\n--- Fuel-Type Heterogeneity ---\n")

  fuel_results <- list()
  for (fuel in c("Petrol", "Diesel")) {
    df_fuel <- df_rdd %>% filter(fuel_clean == fuel)
    if (nrow(df_fuel) < 500) next

    result <- tryCatch({
      rdd <- rdrobust(y = df_fuel$y_first, x = df_fuel$rv, c = 0,
                      kernel = "triangular", bwselect = "mserd")
      list(
        fuel = fuel,
        n = nrow(df_fuel),
        failure_rate = mean(df_fuel$y_first),
        coef_robust = rdd$coef[3],
        se_robust = rdd$se[3],
        p_robust = rdd$pv[3]
      )
    }, error = function(e) NULL)

    if (!is.null(result)) {
      fuel_results[[fuel]] <- result
      cat(sprintf("Fuel=%s: N=%d, coef=%.4f (p=%.4f)\n",
                  fuel, result$n, result$coef_robust, result$p_robust))
    }
  }

  fuel_df <- bind_rows(fuel_results)
  saveRDS(fuel_df, "data/fuel_heterogeneity.rds")
}

## ──────────────────────────────────────────────────────────────
## 6. Annual trend control (reg_year)
## ──────────────────────────────────────────────────────────────

cat("\n--- Checking cohort composition ---\n")
cohort_dist <- df_rdd %>%
  count(reg_year) %>%
  mutate(pct = 100 * n / sum(n))
cat("Registration year distribution:\n")
print(cohort_dist)

cat("\n04_robustness.R complete.\n")
