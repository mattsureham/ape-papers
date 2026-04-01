## 04_robustness.R — apep_1238
## Robustness checks: placebo outcomes, balance, subsample analysis

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"

df <- fread(file.path(data_dir, "analysis_dataset.csv"))
df[, log_tot_spend := log(TOT_MDCR_STDZD_PYMT_PC)]
df[, state_fips_fac := factor(state_fips2)]
df[, log_pop := ifelse(pop > 0, log(pop), NA)]
df[, competitive := as.integer(n_hospitals >= 2)]
df_hosp <- df[n_hospitals >= 1]

## ============================================================
## 1. Placebo outcomes: Non-hospital spending categories
##    If HHI captures hospital market power, it should affect
##    inpatient spending more than non-hospital spending (DME, tests)
## ============================================================
cat("=== Placebo/Mechanism Analysis ===\n")

## Inpatient (should be affected by hospital concentration)
df_hosp[, log_ip := ifelse(IP_MDCR_STDZD_PYMT_PC > 0, log(IP_MDCR_STDZD_PYMT_PC), NA)]
## Outpatient (partially affected)
df_hosp[, log_op := ifelse(OP_MDCR_STDZD_PYMT_PC > 0, log(OP_MDCR_STDZD_PYMT_PC), NA)]
## DME (placebo — should NOT be affected by hospital concentration)
df_hosp[, log_dme := ifelse(DME_MDCR_STDZD_PYMT_PC > 0, log(DME_MDCR_STDZD_PYMT_PC), NA)]
## E&M services (placebo — physician-driven)
df_hosp[, log_em := ifelse(EM_MDCR_STDZD_PYMT_PC > 0, log(EM_MDCR_STDZD_PYMT_PC), NA)]
## Home health (placebo)
df_hosp[, log_hh := ifelse(HH_MDCR_STDZD_PYMT_PC > 0, log(HH_MDCR_STDZD_PYMT_PC), NA)]

controls <- "BENE_AVG_RISK_SCRE + log_pop + poverty_rate + pct_65plus + BENE_DUAL_PCT + BENE_RACE_BLACK_PCT"

## OLS with state FE for each outcome
placebo_ip <- feols(as.formula(paste("log_ip ~", "log(hhi_count) +", controls, "| state_fips_fac")),
                     data = df_hosp, vcov = "HC1")
placebo_op <- feols(as.formula(paste("log_op ~", "log(hhi_count) +", controls, "| state_fips_fac")),
                     data = df_hosp, vcov = "HC1")
placebo_dme <- feols(as.formula(paste("log_dme ~", "log(hhi_count) +", controls, "| state_fips_fac")),
                      data = df_hosp, vcov = "HC1")
placebo_em <- feols(as.formula(paste("log_em ~", "log(hhi_count) +", controls, "| state_fips_fac")),
                     data = df_hosp, vcov = "HC1")
placebo_hh <- feols(as.formula(paste("log_hh ~", "log(hhi_count) +", controls, "| state_fips_fac")),
                     data = df_hosp, vcov = "HC1")

cat("Placebo analysis (OLS with state FE):\n")
cat("  Inpatient:   coef = ", round(coef(placebo_ip)["log(hhi_count)"], 4), "\n")
cat("  Outpatient:  coef = ", round(coef(placebo_op)["log(hhi_count)"], 4), "\n")
cat("  DME:         coef = ", round(coef(placebo_dme)["log(hhi_count)"], 4), "\n")
cat("  E&M:         coef = ", round(coef(placebo_em)["log(hhi_count)"], 4), "\n")
cat("  Home Health: coef = ", round(coef(placebo_hh)["log(hhi_count)"], 4), "\n")

## Table 3: Placebo outcomes
setFixest_dict(c("log(hhi_count)" = "log(HHI)",
                  "BENE_AVG_RISK_SCRE" = "HCC risk score",
                  "log_pop" = "log(Population)",
                  "poverty_rate" = "Poverty rate",
                  "pct_65plus" = "Share 65+",
                  "BENE_DUAL_PCT" = "Dual-eligible (\\%)",
                  "BENE_RACE_BLACK_PCT" = "Black (\\%)"))

etable(placebo_ip, placebo_op, placebo_dme, placebo_em, placebo_hh,
       title = "Hospital Concentration and Medicare Spending by Category",
       headers = c("Inpatient", "Outpatient", "DME", "E\\&M", "Home Health"),
       label = "tab:placebo",
       tex = TRUE,
       depvar = FALSE,
       keep = "%log\\(hhi",
       fitstat = ~ n + r2,
       file = file.path(tables_dir, "tab3_placebo.tex"),
       replace = TRUE)

## ============================================================
## 2. Balance test: Does the instrument predict covariates?
## ============================================================
cat("\n=== Balance Tests ===\n")

iv_data <- df_hosp[!is.na(inv_pci_1950) & !is.na(log_pop)]
bal_vars <- c("BENE_AVG_RISK_SCRE", "log_pop", "poverty_rate",
              "pct_65plus", "BENE_DUAL_PCT", "BENE_RACE_BLACK_PCT",
              "median_age")

cat("Balance: Does inv_pci_1950 predict covariates?\n")
for (v in bal_vars) {
  if (all(is.na(iv_data[[v]]))) next
  bal_reg <- feols(as.formula(paste(v, "~ inv_pci_1950")),
                    data = iv_data, vcov = "HC1")
  coef_val <- coef(bal_reg)["inv_pci_1950"]
  se_val <- sqrt(vcov(bal_reg)["inv_pci_1950", "inv_pci_1950"])
  cat(sprintf("  %-25s  coef = %8.3f  SE = %8.3f  t = %5.2f\n",
              v, coef_val, se_val, coef_val / se_val))
}

## ============================================================
## 3. Subsample analysis: Urban vs Rural
## ============================================================
cat("\n=== Subsample: Urban vs Rural ===\n")

## Define urban as pop > median
med_pop <- median(df_hosp$pop, na.rm = TRUE)
df_hosp[, urban := as.integer(pop > med_pop)]

ols_urban <- feols(as.formula(paste("log_tot_spend ~ log(hhi_count) +", controls, "| state_fips_fac")),
                    data = df_hosp[urban == 1], vcov = "HC1")
ols_rural <- feols(as.formula(paste("log_tot_spend ~ log(hhi_count) +", controls, "| state_fips_fac")),
                    data = df_hosp[urban == 0], vcov = "HC1")

cat("Urban (pop > median): coef = ", round(coef(ols_urban)["log(hhi_count)"], 4), "\n")
cat("Rural (pop < median): coef = ", round(coef(ols_rural)["log(hhi_count)"], 4), "\n")

## ============================================================
## 4. Table 4: Robustness across samples and specifications
## ============================================================
cat("\n=== Table 4: Robustness ===\n")

## Add log(n_hospitals) as alternative measure
df_hosp[, log_n := ifelse(n_hospitals > 0, log(n_hospitals), 0)]
ols_nhosp <- feols(as.formula(paste("log_tot_spend ~ log_n +", controls, "| state_fips_fac")),
                    data = df_hosp, vcov = "HC1")

## Exclude extreme outlier counties (top/bottom 1% spending)
q01 <- quantile(df_hosp$TOT_MDCR_STDZD_PYMT_PC, 0.01, na.rm = TRUE)
q99 <- quantile(df_hosp$TOT_MDCR_STDZD_PYMT_PC, 0.99, na.rm = TRUE)
df_trim <- df_hosp[TOT_MDCR_STDZD_PYMT_PC >= q01 & TOT_MDCR_STDZD_PYMT_PC <= q99]
ols_trim <- feols(as.formula(paste("log_tot_spend ~ log(hhi_count) +", controls, "| state_fips_fac")),
                   data = df_trim, vcov = "HC1")

## State-clustered SEs
ols_cluster <- feols(as.formula(paste("log_tot_spend ~ log(hhi_count) +", controls, "| state_fips_fac")),
                      data = df_hosp, vcov = ~state_fips_fac)

etable(ols_urban, ols_rural, ols_nhosp, ols_trim, ols_cluster,
       title = "Robustness Checks",
       headers = c("Urban", "Rural", "log(N hosp.)", "Trimmed", "Clustered SE"),
       label = "tab:robust",
       tex = TRUE,
       depvar = TRUE,
       keep = "%log\\(hhi|%log_n",
       fitstat = ~ n + r2,
       file = file.path(tables_dir, "tab4_robustness.tex"),
       replace = TRUE)

cat("Robustness tables saved.\n")
