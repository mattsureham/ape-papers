# 04_robustness.R — Robustness checks
source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds")
models <- readRDS("../data/models.rds")

cat("=== Robustness Checks ===\n")

# ================================================================
# 1. Wild Cluster Bootstrap (27 clusters is borderline)
# ================================================================
cat("\n--- Wild Cluster Bootstrap ---\n")

set.seed(42)
m_boot <- feols(interest_gos_w ~ treat_dose | geo + year, data = panel,
                cluster = ~geo)
boot_res <- boottest(m_boot, param = "treat_dose", B = 9999, type = "webb")
cat(sprintf("WCB p-value (Interest/GOS ~ treat_dose): %.4f\n", boot_res$p_val))
cat(sprintf("WCB 95%% CI: [%.4f, %.4f]\n", boot_res$conf_int[1], boot_res$conf_int[2]))

m_boot2 <- feols(debt_ratio_w ~ treat_dose | geo + year, data = panel,
                 cluster = ~geo)
boot_res2 <- boottest(m_boot2, param = "treat_dose", B = 9999, type = "webb")
cat(sprintf("WCB p-value (Debt ratio ~ treat_dose): %.4f\n", boot_res2$p_val))

# ================================================================
# 2. Leave-One-Out (drop each country)
# ================================================================
cat("\n--- Leave-One-Out ---\n")

countries <- unique(panel$geo)
loo_coefs <- sapply(countries, function(c) {
  sub <- panel[geo != c]
  m <- feols(interest_gos_w ~ treat_dose | geo + year, data = sub, cluster = ~geo)
  coef(m)["treat_dose"]
})

cat(sprintf("LOO range: [%.4f, %.4f]\n", min(loo_coefs), max(loo_coefs)))
cat(sprintf("LOO mean: %.4f (main: %.4f)\n",
            mean(loo_coefs), coef(models$m2)["treat_dose"]))

main_sign <- sign(coef(models$m2)["treat_dose"])
flips <- countries[sign(loo_coefs) != main_sign]
if (length(flips) > 0) {
  cat(sprintf("Sign flips when removing: %s\n", paste(flips, collapse = ", ")))
} else {
  cat("No country removal flips the sign.\n")
}

# ================================================================
# 3. Alternative treatment: EBITDA cap percentage
# ================================================================
cat("\n--- Alternative Treatment: EBITDA Cap ---\n")

panel[, strict_cap := as.integer(ebitda_cap_pct < 30)]
panel[, treat_cap := adopted * strict_cap]

m_cap <- feols(interest_gos_w ~ treat_cap | geo + year, data = panel,
               cluster = ~geo)
etable(m_cap, headers = "Strict EBITDA Cap")

# ================================================================
# 4. COVID robustness: exclude 2020
# ================================================================
cat("\n--- Exclude 2020 ---\n")

no_covid <- panel[year != 2020]
m_nocovid <- feols(interest_gos_w ~ treat_dose | geo + year,
                   data = no_covid, cluster = ~geo)
etable(m_nocovid, headers = "Excl. 2020")

# ================================================================
# 5. Simple adopted (binary) on all outcomes
# ================================================================
cat("\n--- Binary Adopted (all outcomes) ---\n")

m_bin1 <- feols(interest_gos_w ~ adopted | geo + year, data = panel, cluster = ~geo)
m_bin2 <- feols(debt_ratio_w ~ adopted | geo + year, data = panel, cluster = ~geo)
m_bin3 <- feols(leverage_w ~ adopted | geo + year, data = panel, cluster = ~geo)
m_bin4 <- feols(log_interest ~ adopted + gdp_growth + inflation | geo + year,
                data = panel[!is.na(log_interest)], cluster = ~geo)

etable(m_bin1, m_bin2, m_bin3, m_bin4,
       headers = c("Int/GOS", "Debt Share", "Leverage", "Log Interest"))

# ================================================================
# 6. Heterogeneity: dose groups
# ================================================================
cat("\n--- Heterogeneity by Dose Group ---\n")

early <- panel[derogation == 0]
m_het <- feols(interest_gos_w ~ i(dose_group, post2019, ref = "5M") | geo + year,
               data = early, cluster = ~geo)
etable(m_het, headers = "Dose Group Heterogeneity")

# ================================================================
# MDE calculation for power assessment
# ================================================================
cat("\n--- Minimum Detectable Effect ---\n")

# Pre-treatment SD of interest/GOS ratio
pre_sd <- sd(panel[year < 2019, interest_gos_w], na.rm = TRUE)
main_se <- summary(models$m2)$coeftable["treat_dose", "Std. Error"]

# MDE at 80% power, 5% significance (two-tailed): 2.8 * SE
mde <- 2.8 * main_se
cat(sprintf("Pre-treatment SD(Interest/GOS): %.4f\n", pre_sd))
cat(sprintf("SE of main estimate: %.4f\n", main_se))
cat(sprintf("MDE (80%% power): %.4f\n", mde))
cat(sprintf("MDE as %% of pre-treatment SD: %.1f%%\n", 100 * mde / pre_sd))
cat(sprintf("MDE as %% of pre-treatment mean: %.1f%%\n",
            100 * mde / mean(panel[year < 2019, interest_gos_w], na.rm = TRUE)))

# ================================================================
# Save robustness results
# ================================================================
rob <- list(
  boot_pval_intgos = boot_res$p_val,
  boot_ci_intgos = boot_res$conf_int,
  boot_pval_debtratio = boot_res2$p_val,
  loo_range = c(min(loo_coefs), max(loo_coefs)),
  loo_sign_flips = flips,
  m_cap = m_cap,
  m_nocovid = m_nocovid,
  m_het = m_het,
  loo_coefs = loo_coefs,
  mde = mde,
  pre_sd = pre_sd
)
saveRDS(rob, "../data/robustness.rds")
cat("\nSaved robustness.rds\n")
