# ==============================================================================
# 04_robustness.R — Robustness checks and placebo tests
# ==============================================================================

source("00_packages.R")

analysis <- readRDS("../data/analysis_panel.rds")
results <- readRDS("../data/main_results.rds")

# ==============================================================================
# 1. High-wage industry placebo
# ==============================================================================
cat("=== 1. High-Wage Industry Placebo ===\n")

high_wage <- analysis |> filter(industry_group == "high_wage")

p1_earns <- feols(log_earns_ratio ~ log_mw | state_id + yq_id,
                  data = high_wage, cluster = ~state_fips)
p1_emp <- feols(log_emp_ratio ~ log_mw | state_id + yq_id,
                data = high_wage, cluster = ~state_fips)
p1_wb <- feols(log_wage_bill_ratio ~ log_mw | state_id + yq_id,
               data = high_wage, cluster = ~state_fips)

cat("Placebo (high-wage):\n")
etable(p1_earns, p1_emp, p1_wb,
       headers = c("Earnings", "Employment", "Wage Bill"))

# ==============================================================================
# 2. Pre-trend test: restrict to pre-treatment period
# ==============================================================================
cat("\n=== 2. Pre-Trend Test ===\n")

low_wage <- analysis |> filter(industry_group == "low_wage")

# Linear pre-trend: interact log_mw with trend in pre-period only
pre_data <- low_wage |>
  filter(first_treat_period == 0 | period < first_treat_period)

pre_trend <- feols(log_earns_ratio ~ log_mw | state_id + yq_id,
                   data = pre_data, cluster = ~state_fips)
cat("Pre-trend coefficient on log_mw:", coef(pre_trend)["log_mw"],
    " (SE:", se(pre_trend)["log_mw"], ")\n")

# ==============================================================================
# 3. Leave-one-state-out (LOSO) sensitivity
# ==============================================================================
cat("\n=== 3. Leave-One-Out Sensitivity ===\n")

treated_states <- low_wage |>
  filter(first_treat_period > 0) |>
  pull(state_fips) |>
  unique()

loso_coefs <- sapply(treated_states, function(st) {
  d <- low_wage |> filter(state_fips != st)
  m <- feols(log_earns_ratio ~ log_mw | state_id + yq_id,
             data = d, cluster = ~state_fips)
  coef(m)["log_mw"]
})

cat("LOSO range (earnings ratio):", round(range(loso_coefs), 4), "\n")
cat("LOSO mean:", round(mean(loso_coefs), 4), "\n")
cat("Full-sample coef:", round(coef(results$m1_earns)["log_mw"], 4), "\n")

# ==============================================================================
# 4. Wild cluster bootstrap (for inference with ~40 clusters)
# ==============================================================================
cat("\n=== 4. Wild Cluster Bootstrap ===\n")

# Use fwildclusterboot for proper few-cluster inference
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)

  boot_earns <- tryCatch({
    boottest(results$m1_earns, param = "log_mw",
             clustid = ~state_fips, B = 999, type = "webb")
  }, error = function(e) {
    cat("Bootstrap error:", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(boot_earns)) {
    cat("Wild bootstrap p-value (earnings):", boot_earns$p_val, "\n")
    cat("Bootstrap CI:", boot_earns$conf_int, "\n")
  }
} else {
  cat("fwildclusterboot not installed; skipping.\n")
  boot_earns <- NULL
}

# ==============================================================================
# 5. Continuous dose-response: MW level bins
# ==============================================================================
cat("\n=== 5. Dose-Response ===\n")

low_wage_dose <- low_wage |>
  mutate(
    mw_bin = cut(mw_ratio, breaks = c(0, 1.0, 1.15, 1.4, 1.7, Inf),
                 labels = c("Federal", "Small hike", "Medium hike",
                           "Large hike", "Very large hike"))
  )

dose_earns <- feols(log_earns_ratio ~ mw_bin | state_id + yq_id,
                    data = low_wage_dose, cluster = ~state_fips)
cat("Dose-response (earnings ratio):\n")
print(summary(dose_earns))

# ==============================================================================
# Save robustness results
# ==============================================================================

rob_results <- list(
  placebo_earns = p1_earns,
  placebo_emp = p1_emp,
  placebo_wb = p1_wb,
  pre_trend = pre_trend,
  loso_coefs = loso_coefs,
  boot_earns = if (exists("boot_earns")) boot_earns else NULL,
  dose_earns = dose_earns
)

saveRDS(rob_results, "../data/robustness_results.rds")
cat("\nRobustness checks complete.\n")
