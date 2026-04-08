## 03_main_analysis.R — 2SLS estimation: judge leniency → housing markets
## apep_1416: The Legal Status Premium in Local Housing Markets

source("00_packages.R")

data_dir <- "../data"
tables_dir <- "../tables"
dir.create(tables_dir, showWarnings = FALSE)

## Load analysis panel (from aggregate or full EOIR)
panel_file <- file.path(data_dir, "analysis_panel.csv")
if (!file.exists(panel_file)) {
  panel_file <- file.path(data_dir, "analysis.csv")
}
panel <- fread(panel_file)
cat(sprintf("Panel: %d obs, %d courts, %d years\n",
  nrow(panel), uniqueN(panel$code), uniqueN(panel$year)))

## Determine if we have time-varying leniency (full EOIR) or cross-sectional
has_court_year_leniency <- "comp_year" %in% names(panel)

## Standardize column names
if ("comp_year" %in% names(panel)) setnames(panel, "comp_year", "year", skip_absent = TRUE)
if ("base_city_code" %in% names(panel)) setnames(panel, "base_city_code", "code", skip_absent = TRUE)

## Create needed variables if missing
if (!"log_rent" %in% names(panel)) panel[, log_rent := log(median_rent)]
if (!"log_home_value" %in% names(panel)) panel[, log_home_value := log(median_home_value)]
if (!"log_pop" %in% names(panel)) panel[, log_pop := log(total_pop)]
if (!"grant_rate" %in% names(panel) && "grantRate" %in% names(panel)) {
  panel[, grant_rate := grantRate / 100]
}

## Scale leniency to match grant_rate scale (both in 0-1 range)
if (max(panel$leniency_iv, na.rm = TRUE) > 1) {
  panel[, leniency_iv := leniency_iv / 100]
}

## Drop NAs
panel <- panel[!is.na(log_rent) & !is.na(log_home_value) & !is.na(grant_rate) &
               !is.na(leniency_iv) & is.finite(log_rent) & is.finite(log_home_value)]
cat(sprintf("After dropping NAs: %d obs\n", nrow(panel)))

## ============================================================
## 1. First Stage: Leniency → Grant Rate
## ============================================================
cat("\n=== First Stage ===\n")

## Time-varying instrument → court + year FE; within-court variation identifies
fs <- feols(grant_rate ~ leniency_iv | code + year, data = panel, cluster = ~code)
summary(fs)

## Effective F-stat
fs_wald <- fitstat(fs, "wald")
fs_F <- fs_wald[[1]]$stat
cat(sprintf("  First-stage F: %.1f\n", fs_F))
cat(sprintf("  Coefficient: %.4f (SE: %.4f)\n",
  coef(fs)["leniency_iv"], se(fs)["leniency_iv"]))

## ============================================================
## 2. OLS Baseline
## ============================================================
cat("\n=== OLS ===\n")

ols_rent <- feols(log_rent ~ grant_rate | code + year, data = panel, cluster = ~code)
ols_hv <- feols(log_home_value ~ grant_rate | code + year, data = panel, cluster = ~code)
ols_own <- feols(homeownership_rate ~ grant_rate | code + year, data = panel, cluster = ~code)

cat(sprintf("OLS log rent: %.4f (%.4f)\n", coef(ols_rent)["grant_rate"], se(ols_rent)["grant_rate"]))
cat(sprintf("OLS log home value: %.4f (%.4f)\n", coef(ols_hv)["grant_rate"], se(ols_hv)["grant_rate"]))
cat(sprintf("OLS homeownership: %.4f (%.4f)\n", coef(ols_own)["grant_rate"], se(ols_own)["grant_rate"]))

## ============================================================
## 3. Reduced Form: Leniency → Housing
## ============================================================
cat("\n=== Reduced Form ===\n")

rf_rent <- feols(log_rent ~ leniency_iv | code + year, data = panel, cluster = ~code)
rf_hv <- feols(log_home_value ~ leniency_iv | code + year, data = panel, cluster = ~code)
rf_own <- feols(homeownership_rate ~ leniency_iv | code + year, data = panel, cluster = ~code)

cat(sprintf("RF log rent: %.4f (%.4f)\n", coef(rf_rent)["leniency_iv"], se(rf_rent)["leniency_iv"]))
cat(sprintf("RF log home value: %.4f (%.4f)\n", coef(rf_hv)["leniency_iv"], se(rf_hv)["leniency_iv"]))
cat(sprintf("RF homeownership: %.4f (%.4f)\n", coef(rf_own)["leniency_iv"], se(rf_own)["leniency_iv"]))

## ============================================================
## 4. 2SLS Main Results
## ============================================================
cat("\n=== 2SLS ===\n")

iv_rent <- feols(log_rent ~ 1 | code + year | grant_rate ~ leniency_iv,
                 data = panel, cluster = ~code)
iv_hv <- feols(log_home_value ~ 1 | code + year | grant_rate ~ leniency_iv,
               data = panel, cluster = ~code)
iv_own <- feols(homeownership_rate ~ 1 | code + year | grant_rate ~ leniency_iv,
                data = panel, cluster = ~code)

cat("2SLS Log Rent:\n"); summary(iv_rent)
cat("\n2SLS Log Home Value:\n"); summary(iv_hv)
cat("\n2SLS Homeownership:\n"); summary(iv_own)

## With controls
iv_rent_ctrl <- feols(log_rent ~ log_pop + noncitizen_share | code + year |
                        grant_rate ~ leniency_iv,
                      data = panel, cluster = ~code)
iv_hv_ctrl <- feols(log_home_value ~ log_pop + noncitizen_share | code + year |
                      grant_rate ~ leniency_iv,
                    data = panel, cluster = ~code)

## Noncitizen share as mechanism
iv_noncit <- feols(noncitizen_share ~ 1 | code + year | grant_rate ~ leniency_iv,
                   data = panel, cluster = ~code)
cat("\n2SLS Noncitizen Share (mechanism):\n"); summary(iv_noncit)

## ============================================================
## 5. Export Tables
## ============================================================
cat("\n=== Exporting Tables ===\n")

## Table 1: Summary Statistics
summ_vars <- data.table(
  Variable = c("Grant Rate", "Judge Leniency", "Median Rent (\\$)",
               "Median Home Value (\\$1,000s)", "Homeownership Rate",
               "Noncitizen Share", "Population (1,000s)", "No. Judges"),
  Mean = round(c(mean(panel$grant_rate), mean(panel$leniency_iv),
           mean(panel$median_rent), mean(panel$median_home_value)/1000,
           mean(panel$homeownership_rate), mean(panel$noncitizen_share),
           mean(panel$total_pop)/1000, mean(panel$n_judges)), 3),
  SD = round(c(sd(panel$grant_rate), sd(panel$leniency_iv),
         sd(panel$median_rent), sd(panel$median_home_value)/1000,
         sd(panel$homeownership_rate), sd(panel$noncitizen_share),
         sd(panel$total_pop)/1000, sd(panel$n_judges)), 3)
)

sink(file.path(tables_dir, "tab1_summary.tex"))
cat("\\begin{table}[htbp]\n\\centering\n")
cat("\\caption{Summary Statistics}\\label{tab:summary}\n")
cat("\\begin{tabular}{lcc}\n\\hline\\hline\n")
cat("& Mean & SD \\\\\n\\hline\n")
for (i in seq_len(nrow(summ_vars))) {
  cat(sprintf("%s & %s & %s \\\\\n", summ_vars$Variable[i], summ_vars$Mean[i], summ_vars$SD[i]))
}
cat("\\hline\n")
cat(sprintf("Observations & \\multicolumn{2}{c}{%d} \\\\\n", nrow(panel)))
cat(sprintf("Courts & \\multicolumn{2}{c}{%d} \\\\\n", uniqueN(panel$code)))
cat(sprintf("Years & \\multicolumn{2}{c}{%d---%d} \\\\\n", min(panel$year), max(panel$year)))
cat("\\hline\\hline\n\\end{tabular}\n")
cat("\\begin{tablenotes}\\small\n")
cat("\\item \\textit{Notes:} Unit of observation is immigration court $\\times$ year. ")
cat("Grant Rate is the proportion of completed asylum cases resulting in relief. ")
cat("Judge Leniency is the mean grant rate of judges assigned to each court. ")
cat("Housing outcomes from ACS 5-year estimates for the county hosting each court.\n")
cat("\\end{tablenotes}\n\\end{table}\n")
sink()

## Table 2: First Stage and Reduced Form
etable(fs, rf_rent, rf_hv, rf_own,
       dict = c(leniency_iv = "Judge Leniency",
                grant_rate = "Grant Rate",
                log_rent = "Log Rent",
                log_home_value = "Log Home Value",
                homeownership_rate = "Homeown. Rate"),
       se.below = TRUE,
       tex = TRUE,
       file = file.path(tables_dir, "tab2_first_stage_rf.tex"),
       replace = TRUE)

## Table 3: Main 2SLS Results (OLS vs IV)
etable(ols_rent, iv_rent, iv_rent_ctrl,
       ols_hv, iv_hv, iv_hv_ctrl,
       headers = c("OLS", "2SLS", "2SLS+Ctrl", "OLS", "2SLS", "2SLS+Ctrl"),
       dict = c(fit_grant_rate = "Grant Rate",
                grant_rate = "Grant Rate",
                log_pop = "Log Pop.",
                noncitizen_share = "Noncit. Share"),
       se.below = TRUE,
       tex = TRUE,
       file = file.path(tables_dir, "tab3_main_results.tex"),
       replace = TRUE)

## ============================================================
## 6. Save estimates for SDE table
## ============================================================

est <- list(
  beta_rent_iv = coef(iv_rent)["fit_grant_rate"],
  se_rent_iv = se(iv_rent)["fit_grant_rate"],
  beta_hv_iv = coef(iv_hv)["fit_grant_rate"],
  se_hv_iv = se(iv_hv)["fit_grant_rate"],
  beta_own_iv = coef(iv_own)["fit_grant_rate"],
  se_own_iv = se(iv_own)["fit_grant_rate"],
  beta_noncit_iv = coef(iv_noncit)["fit_grant_rate"],
  se_noncit_iv = se(iv_noncit)["fit_grant_rate"],
  sd_rent = sd(panel$log_rent, na.rm = TRUE),
  sd_hv = sd(panel$log_home_value, na.rm = TRUE),
  sd_own = sd(panel$homeownership_rate, na.rm = TRUE),
  sd_noncit = sd(panel$noncitizen_share, na.rm = TRUE),
  sd_grant = sd(panel$grant_rate, na.rm = TRUE),
  fs_F = if (exists("fs_F") && !is.null(fs_F)) fs_F else NA,
  n_obs = nrow(panel),
  n_courts = uniqueN(panel$code)
)
saveRDS(est, file.path(data_dir, "estimates.rds"))

## Update diagnostics
jsonlite::write_json(
  list(n_treated = uniqueN(panel$code),
       n_pre = uniqueN(panel$year[panel$year <= 2015]),
       n_obs = nrow(panel)),
  file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE
)

cat("Results saved.\n")
cat("\n=== Main analysis complete ===\n")
