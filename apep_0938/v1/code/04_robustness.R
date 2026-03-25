# 04_robustness.R — Robustness checks
# EU Late Payment Directive & Small Firm Survival (apep_0938)

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
models <- readRDS("../data/models.rds")

# ================================================================
# A. Leave-one-out: Drop each country
# ================================================================

cat("=== Leave-One-Out Robustness ===\n")

countries <- unique(panel$geo)
loo_results <- data.frame()

for (cc in countries) {
  tryCatch({
    m_loo <- feols(
      death_rate ~ post:pay_delay_z:small +
        post:pay_delay_z + post:small + pay_delay_z:small |
        geo^sizeclas + geo^year + sizeclas^year,
      data = panel |> filter(geo != cc),
      cluster = ~geo
    )
    coef_val <- coef(m_loo)["post:pay_delay_z:small"]
    se_val <- se(m_loo)["post:pay_delay_z:small"]
    loo_results <- rbind(loo_results, data.frame(
      dropped = cc, estimate = coef_val, se = se_val
    ))
  }, error = function(e) {
    cat(sprintf("  Skipping %s: %s\n", cc, conditionMessage(e)))
  })
}

cat(sprintf("\nLeave-one-out: %d successful runs\n", nrow(loo_results)))
cat(sprintf("Coefficient range: [%.3f, %.3f]\n",
            min(loo_results$estimate), max(loo_results$estimate)))
cat(sprintf("Full-sample estimate: %.3f\n",
            coef(models$death_continuous)["post:pay_delay_z:small"]))

saveRDS(loo_results, "../data/loo_results.rds")

# ================================================================
# B. Placebo: Large firms only (should see no differential effect)
# ================================================================

cat("\n=== Placebo: Large Firms Only ===\n")

# Among firms with 10+ employees, create "medium" (10-49) vs "very large" (50-249, 250+)
# If size classes permit, test whether medium firms also respond
panel_large <- panel |>
  filter(small == 0, !is.na(death_rate)) |>
  mutate(
    medium = as.integer(sizeclas == "GE10")
  )

if (n_distinct(panel_large$sizeclas) >= 2) {
  m_placebo <- feols(
    death_rate ~ post:pay_delay_z:medium +
      post:pay_delay_z + post:medium + pay_delay_z:medium |
      geo^sizeclas + geo^year + sizeclas^year,
    data = panel_large,
    cluster = ~geo
  )
  cat("Placebo (large firms, medium vs very large):\n")
  summary(m_placebo)
  saveRDS(m_placebo, "../data/placebo_large.rds")
} else {
  cat("Only one large size class available; skipping placebo.\n")
}

# ================================================================
# C. Alternative: Only micro firms (0 employees) vs 10+
# ================================================================

cat("\n=== Alternative: Micro (0 emp) vs Large (10+) ===\n")

panel_micro <- panel |>
  filter(sizeclas %in% c("0", "GE10"),
         !is.na(death_rate)) |>
  mutate(micro = as.integer(sizeclas == "0"))

m_micro <- feols(
  death_rate ~ post:pay_delay_z:micro +
    post:pay_delay_z + post:micro + pay_delay_z:micro |
    geo^sizeclas + geo^year + sizeclas^year,
  data = panel_micro,
  cluster = ~geo
)

cat("Micro vs Large triple-diff:\n")
summary(m_micro)

saveRDS(m_micro, "../data/model_micro.rds")

# ================================================================
# D. Alternative intensity: raw payment days (not z-scored)
# ================================================================

cat("\n=== Alternative: Raw payment days ===\n")

m_raw <- feols(
  death_rate ~ post:I(avg_payment_days/10):small +
    post:I(avg_payment_days/10) + post:small + I(avg_payment_days/10):small |
    geo^sizeclas + geo^year + sizeclas^year,
  data = panel,
  cluster = ~geo
)

cat("Raw payment days (per 10 days) triple-diff:\n")
summary(m_raw)

# ================================================================
# E. Birth rate triple-diff (are new firms also differentially affected?)
# ================================================================

cat("\n=== Restricted Sample: 2008-2020 (drop early years) ===\n")

panel_08 <- panel |> filter(year >= 2008, !is.na(death_rate))

m_restricted <- feols(
  death_rate ~ post:pay_delay_z:small +
    post:pay_delay_z + post:small + pay_delay_z:small |
    geo^sizeclas + geo^year + sizeclas^year,
  data = panel_08,
  cluster = ~geo
)

cat("Restricted (2008-2020) triple-diff on death rate:\n")
summary(m_restricted)

# ================================================================
# F. Save all robustness models
# ================================================================

robust_models <- list(
  loo = loo_results,
  micro_vs_large = m_micro,
  raw_intensity = m_raw,
  restricted_08 = m_restricted
)

saveRDS(robust_models, "../data/robust_models.rds")

cat("\n=== Robustness checks complete ===\n")
