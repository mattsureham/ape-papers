# 04_robustness.R — McCrary density test, covariate balance, placebos, OLS
# PPP Nonprofit Employment RDD (apep_0698)

source("00_packages.R")

data_dir <- "../data"
rdd <- fread(file.path(data_dir, "rdd_sample.csv"))
rdd[, x := rev_decline_pct - (-25)]
rdd[, above_threshold := as.integer(x >= 0)]

# ============================================================
# 1. McCrary Density Test
# ============================================================
cat("=== McCrary Density Test ===\n")
valid_x <- !is.na(rdd$x)
dens_test <- rddensity(X = rdd$x[valid_x], c = 0)
cat("McCrary/rddensity test:\n")
cat("  T-statistic:", round(dens_test$test$t_jk, 3), "\n")
cat("  p-value:", round(dens_test$test$p_jk, 4), "\n")
if (dens_test$test$p_jk > 0.05) {
  cat("  -> No evidence of manipulation at threshold\n")
} else {
  cat("  -> WARNING: density discontinuity detected\n")
}

# ============================================================
# 2. Covariate Balance at Threshold
# ============================================================
cat("\n=== Covariate Balance at Threshold ===\n")

balance_vars <- c("emp_2019", "rev_base", "exp_base", "assets_base", "contrib_base")
balance_labels <- c("Employment (2019)", "Revenue (2019)", "Expenses (2019)",
                     "Assets (2019)", "Contributions (2019)")

balance_results <- data.frame(
  Variable = character(), Estimate = numeric(), SE = numeric(),
  pval = numeric(), stringsAsFactors = FALSE
)

for (i in seq_along(balance_vars)) {
  v <- balance_vars[i]
  if (!v %in% names(rdd)) next
  y <- log(abs(rdd[[v]]) + 1)
  valid <- !is.na(y) & !is.na(rdd$x) & is.finite(y)
  tryCatch({
    res <- rdrobust(y = y[valid], x = rdd$x[valid], c = 0, kernel = "triangular")
    balance_results <- rbind(balance_results, data.frame(
      Variable = balance_labels[i],
      Estimate = round(res$coef[1], 4),
      SE = round(res$se[1], 4),
      pval = round(res$pv[1], 4)
    ))
  }, error = function(e) cat("  Balance test failed for", v, "\n"))
}

cat("Covariate balance (log scale):\n")
print(balance_results)

# ============================================================
# 3. Placebo Cutoffs
# ============================================================
cat("\n=== Placebo Cutoff Tests ===\n")

placebo_cutoffs <- c(-50, -40, -30, -15, -10, 0, 10)
y_main <- rdd$log_emp_2021
valid <- !is.na(y_main) & !is.na(rdd$rev_decline_pct)

placebo_table <- data.frame(
  Cutoff = numeric(), Estimate = numeric(), SE = numeric(),
  pval = numeric(), stringsAsFactors = FALSE
)

for (pc in placebo_cutoffs) {
  x_shifted <- rdd$rev_decline_pct - pc
  tryCatch({
    res <- rdrobust(y = y_main[valid], x = x_shifted[valid], c = 0, kernel = "triangular")
    placebo_table <- rbind(placebo_table, data.frame(
      Cutoff = pc, Estimate = round(res$coef[1], 4),
      SE = round(res$se[1], 4), pval = round(res$pv[1], 4)
    ))
  }, error = function(e) NULL)
}

cat("Placebo cutoff results (outcome: log emp 2021):\n")
print(placebo_table)

# ============================================================
# 4. OLS: Conditional Association of PPP with Employment
# ============================================================
cat("\n=== OLS: PPP and Employment (Conditional) ===\n")

# Since the RDD first stage is flat, estimate conditional associations
# This is NOT causal — clearly labeled as descriptive/conditional

# Baseline OLS
rdd[, log_emp_base := log(emp_2019 + 1)]
rdd[, log_rev_base := log(abs(rev_base) + 1)]
rdd[, log_assets_base := log(abs(assets_base) + 1)]

# Make state a factor
rdd[, state_f := as.factor(state)]

# Model 1: Bivariate
m1 <- feols(log_emp_2021 ~ ppp_second_draw,
            data = rdd[!is.na(log_emp_2021)])
cat("\nModel 1 (bivariate):\n")
cat("  Second Draw:", round(coef(m1)["ppp_second_draw"], 4),
    " (SE:", round(se(m1)["ppp_second_draw"], 4), ")\n")

# Model 2: Control for baseline
m2 <- feols(log_emp_2021 ~ ppp_second_draw + log_emp_base + log_rev_base +
              rev_decline_pct,
            data = rdd[!is.na(log_emp_2021)])
cat("Model 2 (baseline controls):\n")
cat("  Second Draw:", round(coef(m2)["ppp_second_draw"], 4),
    " (SE:", round(se(m2)["ppp_second_draw"], 4), ")\n")

# Model 3: State FE
m3 <- feols(log_emp_2021 ~ ppp_second_draw + log_emp_base + log_rev_base +
              rev_decline_pct | state_f,
            data = rdd[!is.na(log_emp_2021)])
cat("Model 3 (state FE):\n")
cat("  Second Draw:", round(coef(m3)["ppp_second_draw"], 4),
    " (SE:", round(se(m3)["ppp_second_draw"], 4), ")\n")

# Model 4: State FE + size category
m4 <- feols(log_emp_2021 ~ ppp_second_draw + log_emp_base + log_rev_base +
              rev_decline_pct + log_assets_base | state_f + size_cat,
            data = rdd[!is.na(log_emp_2021)])
cat("Model 4 (state + size FE):\n")
cat("  Second Draw:", round(coef(m4)["ppp_second_draw"], 4),
    " (SE:", round(se(m4)["ppp_second_draw"], 4), ")\n")

# Same for 2022
m5 <- feols(log_emp_2022 ~ ppp_second_draw + log_emp_base + log_rev_base +
              rev_decline_pct + log_assets_base | state_f + size_cat,
            data = rdd[!is.na(log_emp_2022)])
cat("Model 5 (2022, full):\n")
cat("  Second Draw:", round(coef(m5)["ppp_second_draw"], 4),
    " (SE:", round(se(m5)["ppp_second_draw"], 4), ")\n")

# Model 6: Any PPP (not just Second Draw)
m6 <- feols(log_emp_2021 ~ ppp_any + log_emp_base + log_rev_base +
              rev_decline_pct + log_assets_base | state_f + size_cat,
            data = rdd[!is.na(log_emp_2021)])
cat("Model 6 (Any PPP, 2021):\n")
cat("  Any PPP:", round(coef(m6)["ppp_any"], 4),
    " (SE:", round(se(m6)["ppp_any"], 4), ")\n")

# ============================================================
# 5. Placebo: Pre-Treatment Outcomes
# ============================================================
cat("\n=== Placebo: Pre-Treatment (2018) Employment ===\n")

# If PPP "caused" 2021 employment, it shouldn't predict 2018 employment
# (before COVID, before PPP)
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
emp_2018 <- panel[filing_year == 2018, .(ein, log_emp_2018 = log(noemplyeesw3cnt + 1))]
rdd_placebo <- merge(rdd, emp_2018, by = "ein", all.x = TRUE)

m_placebo <- feols(log_emp_2018 ~ ppp_second_draw + log_rev_base +
                     rev_decline_pct + log_assets_base | state_f + size_cat,
                   data = rdd_placebo[!is.na(log_emp_2018)])
cat("Placebo (2018 outcome):\n")
cat("  Second Draw:", round(coef(m_placebo)["ppp_second_draw"], 4),
    " (SE:", round(se(m_placebo)["ppp_second_draw"], 4), ")\n")

# Save models
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m6 = m6,
             m_placebo = m_placebo),
        file.path(data_dir, "ols_models.rds"))
saveRDS(list(density = dens_test, balance = balance_results,
             placebos = placebo_table),
        file.path(data_dir, "robustness_results.rds"))

cat("\n=== Robustness analysis complete ===\n")
