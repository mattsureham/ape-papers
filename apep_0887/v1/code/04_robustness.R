# 04_robustness.R — Robustness checks for apep_0887
source("00_packages.R")

cat("=== Robustness Checks for apep_0887 ===\n")

panel <- fread("../data/analysis_panel_balanced.csv")
panel[, `:=`(
  fips = as.character(fips),
  state_fips = sprintf("%02d", as.integer(state_fips))
)]
rrnc <- fread("../data/rrnc_adoption_dates.csv")

# ============================================================
# 1. Leave-One-Out: Drop Minnesota (Largest Adopter)
# ============================================================
cat("\n--- Leave-One-Out: Drop Minnesota ---\n")

m_no_mn <- feols(log_emp_rem ~ post | fips + year,
                  data = panel[state_fips != "27"],
                  cluster = ~state_fips)
cat("Without Minnesota:\n")
summary(m_no_mn)

# ============================================================
# 2. Leave-One-Out: Drop Each Cohort
# ============================================================
cat("\n--- Leave-One-Out: Drop Each Cohort ---\n")

cohort_years <- unique(rrnc$adoption_year)
loo_results <- list()

for (cy in sort(cohort_years)) {
  states_in_cohort <- rrnc$state_fips[rrnc$adoption_year == cy]
  m_loo <- feols(log_emp_rem ~ post | fips + year,
                  data = panel[!(state_fips %in% states_in_cohort)],
                  cluster = ~state_fips)
  loo_results[[as.character(cy)]] <- data.table(
    dropped_cohort = cy,
    n_dropped_states = length(states_in_cohort),
    coef = coef(m_loo)["post"],
    se = se(m_loo)["post"],
    n = m_loo$nobs
  )
  cat(sprintf("  Drop %d (%d states): β=%.4f (%.4f)\n",
              cy, length(states_in_cohort),
              coef(m_loo)["post"], se(m_loo)["post"]))
}

loo_dt <- rbindlist(loo_results)
fwrite(loo_dt, "../data/loo_results.csv")

# ============================================================
# 3. Alternative Outcomes
# ============================================================
cat("\n--- Alternative Outcomes ---\n")

# Establishments
m_estab <- feols(log_estab_rem ~ post | fips + year,
                  data = panel, cluster = ~state_fips)
cat("Remediation Establishments:\n")
summary(m_estab)

# Payroll
m_payroll <- feols(log_payroll_rem ~ post | fips + year,
                    data = panel, cluster = ~state_fips)
cat("Remediation Payroll:\n")
summary(m_payroll)

# Broader sector (NAICS 562)
m_broad <- feols(log_emp_562 ~ post | fips + year,
                  data = panel, cluster = ~state_fips)
cat("Total Waste Mgmt Employment (NAICS 562):\n")
summary(m_broad)

# Remediation share of waste management
m_share <- feols(rem_share ~ post | fips + year,
                  data = panel, cluster = ~state_fips)
cat("Remediation Share:\n")
summary(m_share)

# ============================================================
# 4. Extended Panel (2003-2021, including post-CBP-redesign)
# ============================================================
cat("\n--- Extended Panel (2003-2021) ---\n")

panel_full <- fread("../data/analysis_panel.csv")
panel_full[, `:=`(fips = as.character(fips),
                   state_fips = sprintf("%02d", as.integer(state_fips)))]

m_full <- feols(log_emp_rem ~ post | fips + year,
                 data = panel_full, cluster = ~state_fips)
cat("Full panel (2003-2021):\n")
summary(m_full)

# ============================================================
# 5. Wild Cluster Bootstrap
# ============================================================
cat("\n--- Wild Cluster Bootstrap ---\n")

m_base <- feols(log_emp_rem ~ post | fips + year,
                 data = panel, cluster = ~state_fips)

boot_result <- tryCatch({
  boottest(m_base, param = "post",
           B = 999,
           clustid = "state_fips",
           type = "webb")
}, error = function(e) {
  cat("Bootstrap error:", e$message, "\n")
  NULL
})

if (!is.null(boot_result)) {
  cat("Wild Cluster Bootstrap:\n")
  print(summary(boot_result))
}

# ============================================================
# 6. MDE Calculation (Power Analysis for Null)
# ============================================================
cat("\n--- Minimum Detectable Effect ---\n")

# For a well-powered null, we need to state what effects we can rule out
se_main <- se(m_base)["post"]
mde_95 <- 2.8 * se_main  # MDE at 80% power, 5% significance
sd_y <- sd(panel$log_emp_rem, na.rm = TRUE)
mde_sde <- mde_95 / sd_y  # in SDE units

cat(sprintf("SE of main estimate: %.4f\n", se_main))
cat(sprintf("MDE (80%% power): %.4f log points\n", mde_95))
cat(sprintf("MDE in SDE units: %.4f\n", mde_sde))
cat(sprintf("95%% CI: [%.4f, %.4f]\n",
            coef(m_base)["post"] - 1.96 * se_main,
            coef(m_base)["post"] + 1.96 * se_main))

# ============================================================
# 7. Save
# ============================================================
cat("\n--- Saving ---\n")

robust_results <- list(
  loo_mn = list(coef = coef(m_no_mn)["post"], se = se(m_no_mn)["post"]),
  estab = list(coef = coef(m_estab)["post"], se = se(m_estab)["post"]),
  payroll = list(coef = coef(m_payroll)["post"], se = se(m_payroll)["post"]),
  broad_562 = list(coef = coef(m_broad)["post"], se = se(m_broad)["post"]),
  share = list(coef = coef(m_share)["post"], se = se(m_share)["post"]),
  full_panel = list(coef = coef(m_full)["post"], se = se(m_full)["post"]),
  loo_cohorts = loo_dt,
  boot_p = if (!is.null(boot_result)) boot_result$p_val else NA,
  mde = mde_95,
  mde_sde = mde_sde
)

saveRDS(robust_results, "../data/robustness_results.rds")
cat("Robustness results saved.\n")
cat("=== Robustness complete ===\n")
