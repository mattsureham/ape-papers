## 03_main_analysis.R — apep_1238
## Main IV analysis: Hill-Burton instrument → hospital concentration → Medicare spending

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE, recursive = TRUE)

## Load analysis dataset
df <- fread(file.path(data_dir, "analysis_dataset.csv"))
cat("Analysis dataset: ", nrow(df), " counties\n")

## ============================================================
## Create analysis variables
## ============================================================

## Primary outcome: log standardized Medicare spending per capita
df[, log_tot_spend := log(TOT_MDCR_STDZD_PYMT_PC)]

## Subcategory outcomes
df[, log_ip_spend := ifelse(IP_MDCR_STDZD_PYMT_PC > 0, log(IP_MDCR_STDZD_PYMT_PC), NA)]

## Controls
df[, state_fips_fac := factor(state_fips2)]
df[, log_pop := ifelse(pop > 0, log(pop), NA)]
df[, log_bene := ifelse(BENES_FFS_CNT > 0, log(BENES_FFS_CNT), NA)]

## Instrument: inverse of 1950 state per capita income
## Already in dataset: inv_pci_1950

## Create competition measure: binary (competitive = 2+ hospitals)
df[, competitive := as.integer(n_hospitals >= 2)]

## Create subsample: counties with at least 1 hospital (HHI < 10000)
df_hosp <- df[n_hospitals >= 1]
cat("Counties with >=1 hospital: ", nrow(df_hosp), "\n")
cat("Counties with >=2 hospitals: ", sum(df$n_hospitals >= 2), "\n")

## HHI distribution
cat("\nHHI Distribution:\n")
cat("  Monopoly (1 hosp, HHI=10000): ", sum(df_hosp$n_hospitals == 1), "\n")
cat("  Duopoly (2 hosp, HHI=5000):   ", sum(df_hosp$n_hospitals == 2), "\n")
cat("  3 hosp (HHI=3333):            ", sum(df_hosp$n_hospitals == 3), "\n")
cat("  4-5 hosp:                      ", sum(df_hosp$n_hospitals >= 4 & df_hosp$n_hospitals <= 5), "\n")
cat("  6+ hosp:                       ", sum(df_hosp$n_hospitals >= 6), "\n")

## ============================================================
## Summary statistics for Table 1
## ============================================================
cat("\n=== Summary Statistics ===\n")

summ_vars <- c("TOT_MDCR_STDZD_PYMT_PC", "IP_MDCR_STDZD_PYMT_PC",
               "n_hospitals", "hhi_count", "competitive",
               "BENES_FFS_CNT", "BENE_AVG_RISK_SCRE",
               "pop", "poverty_rate", "pct_65plus", "median_age",
               "BENE_DUAL_PCT", "BENE_RACE_BLACK_PCT")

summ_labels <- c("Medicare std.\\ spending/capita (\\$)", "Inpatient std.\\ spending/capita (\\$)",
                  "Hospitals (all types)", "HHI (equal-share)", "Competitive ($\\geq$ 2 hospitals)",
                  "FFS beneficiaries", "Average HCC risk score",
                  "Population", "Poverty rate", "Share 65+", "Median age",
                  "Dual-eligible share (\\%)", "Black share (\\%)")

N_vec <- sapply(summ_vars, function(v) sum(!is.na(df[[v]])))
Mean_vec <- sapply(summ_vars, function(v) mean(df[[v]], na.rm = TRUE))
SD_vec <- sapply(summ_vars, function(v) sd(df[[v]], na.rm = TRUE))

## Table 1 LaTeX
tab1_lines <- c(
  "\\begin{table}[t]",
  "\\centering",
  "\\caption{Summary Statistics}",
  "\\label{tab:summary}",
  "\\begin{tabular}{lrrr}",
  "\\toprule",
  " & N & Mean & SD \\\\",
  "\\midrule",
  "\\multicolumn{4}{l}{\\textit{Panel A: Medicare Spending (2019)}} \\\\"
)
for (i in seq_along(summ_vars)) {
  if (i == 3) {
    tab1_lines <- c(tab1_lines, "\\midrule",
                     "\\multicolumn{4}{l}{\\textit{Panel B: Hospital Market Structure}} \\\\")
  }
  if (i == 6) {
    tab1_lines <- c(tab1_lines, "\\midrule",
                     "\\multicolumn{4}{l}{\\textit{Panel C: County Characteristics}} \\\\")
  }
  tab1_lines <- c(tab1_lines,
    sprintf("%s & %s & %s & %s \\\\",
            summ_labels[i],
            format(N_vec[i], big.mark = ","),
            format(round(Mean_vec[i], 2), big.mark = ","),
            format(round(SD_vec[i], 2), big.mark = ",")))
}
tab1_lines <- c(tab1_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}[flushleft]",
  "\\item \\textit{Notes:} Unit of observation is county. Medicare spending from CMS Geographic Variation PUF (2019, pre-COVID). Hospital counts from CMS Hospital Compare (2024), including Acute Care, Critical Access, and VA hospitals. HHI computed as equal-share Herfindahl--Hirschman Index ($10{,}000/N$). County demographics from ACS 2022 5-year estimates.",
  "\\end{tablenotes}",
  "\\end{table}"
)
writeLines(tab1_lines, file.path(tables_dir, "tab1_summary.tex"))
cat("Table 1 saved.\n")

## ============================================================
## Main Analysis: OLS and IV
## ============================================================
cat("\n=== Main Regressions ===\n")

## For log(HHI), restrict to counties with >= 1 hospital
## Specification 1: OLS, no controls
ols1 <- feols(log_tot_spend ~ log(hhi_count),
              data = df_hosp, vcov = "HC1")

## Specification 2: OLS with controls
ols2 <- feols(log_tot_spend ~ log(hhi_count) + BENE_AVG_RISK_SCRE +
                log_pop + poverty_rate + pct_65plus + BENE_DUAL_PCT +
                BENE_RACE_BLACK_PCT,
              data = df_hosp, vcov = "HC1")

## Specification 3: OLS with state FE
ols3 <- feols(log_tot_spend ~ log(hhi_count) + BENE_AVG_RISK_SCRE +
                log_pop + poverty_rate + pct_65plus + BENE_DUAL_PCT +
                BENE_RACE_BLACK_PCT | state_fips_fac,
              data = df_hosp, vcov = "HC1")

## Full sample with binary competition indicator + state FE
ols4 <- feols(log_tot_spend ~ competitive + BENE_AVG_RISK_SCRE +
                log_pop + poverty_rate + pct_65plus + BENE_DUAL_PCT +
                BENE_RACE_BLACK_PCT | state_fips_fac,
              data = df, vcov = "HC1")

cat("OLS Results:\n")
cat("  (1) Bivariate: coef = ", round(coef(ols1)["log(hhi_count)"], 4), "\n")
cat("  (2) + Controls: coef = ", round(coef(ols2)["log(hhi_count)"], 4), "\n")
cat("  (3) + State FE: coef = ", round(coef(ols3)["log(hhi_count)"], 4), "\n")
cat("  (4) Competitive: coef = ", round(coef(ols4)["competitive"], 4), "\n")

## ============================================================
## IV Analysis: Instrument = inverse 1950 state per capita income
## Without state FE (state-level instrument would be absorbed)
## ============================================================
cat("\n=== IV Analysis ===\n")

iv_sample <- df_hosp[!is.na(inv_pci_1950)]
cat("IV sample: ", nrow(iv_sample), " counties\n")

## First stage
fs1 <- feols(log(hhi_count) ~ inv_pci_1950 + BENE_AVG_RISK_SCRE +
               log_pop + poverty_rate + pct_65plus + BENE_DUAL_PCT +
               BENE_RACE_BLACK_PCT,
             data = iv_sample, vcov = "HC1")
cat("First stage:\n")
cat("  Coef on inv_pci_1950: ", round(coef(fs1)["inv_pci_1950"], 2), "\n")
cat("  SE: ", round(sqrt(vcov(fs1)["inv_pci_1950", "inv_pci_1950"]), 2), "\n")

## Get effective F-stat from feols
fs_f <- fitstat(fs1, "f")
cat("  Model F: ", round(fs_f$f$stat, 2), "\n")

## Reduced form
rf1 <- feols(log_tot_spend ~ inv_pci_1950 + BENE_AVG_RISK_SCRE +
               log_pop + poverty_rate + pct_65plus + BENE_DUAL_PCT +
               BENE_RACE_BLACK_PCT,
             data = iv_sample, vcov = "HC1")
cat("Reduced form coef on inv_pci_1950: ", round(coef(rf1)["inv_pci_1950"], 2), "\n")

## 2SLS: log(HHI) instrumented by inv_pci_1950
iv1 <- feols(log_tot_spend ~ BENE_AVG_RISK_SCRE +
               log_pop + poverty_rate + pct_65plus + BENE_DUAL_PCT +
               BENE_RACE_BLACK_PCT | 0 | log(hhi_count) ~ inv_pci_1950,
             data = iv_sample, vcov = "HC1")
cat("\n2SLS estimate:\n")
cat("  Coef on log(HHI): ", round(coef(iv1)["fit_log(hhi_count)"], 4), "\n")
cat("  SE: ", round(sqrt(vcov(iv1)["fit_log(hhi_count)", "fit_log(hhi_count)"]), 4), "\n")

## IV with both 1950 and 1960 instruments (overidentification)
iv_sample2 <- df_hosp[!is.na(inv_pci_1950) & !is.na(inv_pci_1960)]
iv2 <- feols(log_tot_spend ~ BENE_AVG_RISK_SCRE +
               log_pop + poverty_rate + pct_65plus + BENE_DUAL_PCT +
               BENE_RACE_BLACK_PCT | 0 | log(hhi_count) ~ inv_pci_1950 + inv_pci_1960,
             data = iv_sample2, vcov = "HC1")

## Binary competitive indicator IV (full sample)
iv_full <- df[!is.na(inv_pci_1950)]
iv3 <- feols(log_tot_spend ~ BENE_AVG_RISK_SCRE +
               log_pop + poverty_rate + pct_65plus + BENE_DUAL_PCT +
               BENE_RACE_BLACK_PCT | 0 | competitive ~ inv_pci_1950,
             data = iv_full, vcov = "HC1")

## ============================================================
## Table 2: Main Results (LaTeX)
## ============================================================
cat("\n=== Generating Table 2 ===\n")

setFixest_dict(c("log(hhi_count)" = "log(HHI)",
                  "fit_log(hhi_count)" = "log(HHI)",
                  "competitive" = "Competitive ($\\geq 2$ hosp.)",
                  "fit_competitive" = "Competitive ($\\geq 2$ hosp.)",
                  "BENE_AVG_RISK_SCRE" = "HCC risk score",
                  "log_pop" = "log(Population)",
                  "poverty_rate" = "Poverty rate",
                  "pct_65plus" = "Share 65+",
                  "BENE_DUAL_PCT" = "Dual-eligible (\\%)",
                  "BENE_RACE_BLACK_PCT" = "Black (\\%)"))

etable(ols1, ols2, ols3, iv1, iv2, iv3,
       title = "Hospital Market Concentration and Medicare Spending",
       headers = c("OLS", "OLS", "OLS", "IV", "IV (Over-ID)", "IV"),
       label = "tab:main",
       tex = TRUE,
       depvar = TRUE,
       fitstat = ~ n + r2 + ivf,
       file = file.path(tables_dir, "tab2_main.tex"),
       replace = TRUE)

cat("Table 2 saved.\n")

## ============================================================
## Diagnostics for validator
## ============================================================
diagnostics <- list(
  n_treated = sum(df$competitive == 1),
  n_pre = 0,  ## cross-sectional IV, not DiD
  n_obs = nrow(df),
  n_counties = nrow(df),
  n_hospitals_total = sum(df$n_hospitals),
  first_stage_coef = round(coef(fs1)["inv_pci_1950"], 2),
  iv_coef = round(coef(iv1)["fit_log(hhi_count)"], 4),
  ols_coef = round(coef(ols3)["log(hhi_count)"], 4),
  method = "IV-2SLS",
  instrument = "Inverse 1950 state per capita income (Hill-Burton formula proxy)",
  design = "cross-sectional IV"
)
write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)
cat("Diagnostics written.\n")

## Print key results summary
cat("\n========================================\n")
cat("KEY RESULTS SUMMARY\n")
cat("========================================\n")
cat("OLS (bivariate):  log(HHI) coef = ", round(coef(ols1)["log(hhi_count)"], 4), "\n")
cat("OLS (controls):   log(HHI) coef = ", round(coef(ols2)["log(hhi_count)"], 4), "\n")
cat("OLS (state FE):   log(HHI) coef = ", round(coef(ols3)["log(hhi_count)"], 4), "\n")
cat("IV (2SLS):        log(HHI) coef = ", round(coef(iv1)["fit_log(hhi_count)"], 4), "\n")
cat("IV (competitive): coef = ", round(coef(iv3)["fit_competitive"], 4), "\n")
cat("========================================\n")
