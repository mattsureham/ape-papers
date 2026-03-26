# =============================================================================
# 04_robustness.R — Robustness checks and placebos
# apep_0998: USAID contract terminations and local employment
# =============================================================================

source("00_packages.R")

DATA_DIR <- "../data"

panel_54 <- readRDS(file.path(DATA_DIR, "panel_54.rds"))
treatment <- readRDS(file.path(DATA_DIR, "treatment.rds"))

panel_54_main <- panel_54[year >= 2019]

# ---------------------------------------------------------------------------
# 1. Alternative treatment definitions
# ---------------------------------------------------------------------------
cat("=== Alternative treatment definitions ===\n")

# (a) Use total USAID dollars (not per-employee normalized)
# Log transform to handle scale
panel_54_main[, log_usaid := log(usaid_total + 1)]
model_alt_a <- feols(log_emp ~ log_usaid:post | county_fips + time_id,
                     data = panel_54_main, cluster = ~state_fips)
cat("Alt (a): Log USAID total × Post\n")
summary(model_alt_a)

# (b) Any USAID exposure (extensive margin)
panel_54_main[, any_usaid := as.integer(usaid_total > 0)]
model_alt_b <- feols(log_emp ~ any_usaid:post | county_fips + time_id,
                     data = panel_54_main, cluster = ~state_fips)
cat("\nAlt (b): Any USAID exposure × Post\n")
summary(model_alt_b)

# ---------------------------------------------------------------------------
# 2. Alternative clustering
# ---------------------------------------------------------------------------
cat("\n=== Alternative clustering ===\n")

# County-level clustering
model_county_cl <- feols(log_emp ~ usaid_per_emp:post | county_fips + time_id,
                         data = panel_54_main, cluster = ~county_fips)
cat("County-level clustering:\n")
summary(model_county_cl)

# Two-way clustering: state × time
model_twoway <- feols(log_emp ~ usaid_per_emp:post | county_fips + time_id,
                      data = panel_54_main, cluster = ~state_fips + time_id)
cat("\nTwo-way (state × time) clustering:\n")
summary(model_twoway)

# ---------------------------------------------------------------------------
# 3. Wild cluster bootstrap (important with ~50 state clusters)
# ---------------------------------------------------------------------------
cat("\n=== Wild cluster bootstrap ===\n")

# Use fwildclusterboot for inference with few treated clusters
# Run on binary treatment model for clearer interpretation
model_for_boot <- feols(log_emp ~ high_usaid:post | county_fips + time_id,
                        data = panel_54_main)

boot_result <- tryCatch({
  boottest(model_for_boot,
           param = "high_usaid:post",
           clustid = ~state_fips,
           B = 9999,
           type = "webb",
           nthreads = 4)
}, error = function(e) {
  cat("  Bootstrap error:", e$message, "\n")
  NULL
})

if (!is.null(boot_result)) {
  cat("Wild cluster bootstrap p-value:", boot_result$p_val, "\n")
  cat("Bootstrap CI:", boot_result$conf_int, "\n")
  boot_p <- boot_result$p_val
} else {
  boot_p <- NA
}

# ---------------------------------------------------------------------------
# 4. Pre-trend test: restrict to pre-period and test for differential trends
# ---------------------------------------------------------------------------
cat("\n=== Pre-trend test ===\n")

pre_only <- panel_54_main[post == 0]
pre_only[, trend := time_id]

model_pretrend <- feols(log_emp ~ usaid_per_emp:trend | county_fips + time_id,
                        data = pre_only, cluster = ~state_fips)
cat("Pre-treatment differential trend:\n")
summary(model_pretrend)

# ---------------------------------------------------------------------------
# 5. Placebo treatment date (2023Q1 instead of 2025Q1)
# ---------------------------------------------------------------------------
cat("\n=== Placebo treatment date ===\n")

panel_54_placebo <- panel_54[year >= 2019 & year <= 2024]
panel_54_placebo[, placebo_post := as.integer(year >= 2023)]
model_placebo <- feols(log_emp ~ usaid_per_emp:placebo_post | county_fips + time_id,
                       data = panel_54_placebo, cluster = ~state_fips)
cat("Placebo (2023Q1 onset):\n")
summary(model_placebo)

# ---------------------------------------------------------------------------
# 6. Asinh transformation (alternative to log)
# ---------------------------------------------------------------------------
cat("\n=== Asinh transformation ===\n")

model_asinh <- feols(asinh_emp ~ usaid_per_emp:post | county_fips + time_id,
                     data = panel_54_main, cluster = ~state_fips)
cat("Asinh(emp):\n")
summary(model_asinh)

# ---------------------------------------------------------------------------
# 7. Leave-one-state-out jackknife
# ---------------------------------------------------------------------------
cat("\n=== Leave-one-state-out ===\n")

states <- unique(panel_54_main$state_fips)
loso_coefs <- numeric(length(states))
names(loso_coefs) <- states

for (i in seq_along(states)) {
  st <- states[i]
  m <- feols(log_emp ~ usaid_per_emp:post | county_fips + time_id,
             data = panel_54_main[state_fips != st], cluster = ~state_fips)
  loso_coefs[i] <- coef(m)[1]
}

cat(sprintf("Leave-one-state-out coefficient range: [%.6f, %.6f]\n",
            min(loso_coefs), max(loso_coefs)))
cat(sprintf("Full-sample coefficient: %.6f\n", coef(feols(log_emp ~ usaid_per_emp:post |
            county_fips + time_id, data = panel_54_main, cluster = ~state_fips))[1]))

# Most influential states
loso_diff <- abs(loso_coefs - coef(feols(log_emp ~ usaid_per_emp:post |
              county_fips + time_id, data = panel_54_main, cluster = ~state_fips))[1])
top_influential <- sort(loso_diff, decreasing = TRUE)[1:5]
cat("Most influential states (FIPS):\n")
print(top_influential)

# ---------------------------------------------------------------------------
# Save robustness results
# ---------------------------------------------------------------------------
rob_results <- list(
  model_alt_a = model_alt_a,
  model_alt_b = model_alt_b,
  model_county_cl = model_county_cl,
  model_twoway = model_twoway,
  boot_p = boot_p,
  model_pretrend = model_pretrend,
  model_placebo = model_placebo,
  model_asinh = model_asinh,
  loso_coefs = loso_coefs
)

saveRDS(rob_results, file.path(DATA_DIR, "robustness_results.rds"))

cat("\n=== Robustness checks complete ===\n")
