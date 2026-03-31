# 05_tables.R — Generate all LaTeX tables for the paper
source("00_packages.R")
setwd("../")

cat("=== Generating Tables ===\n")

load("data/models.RData")
load("data/robustness_models.RData")

# ---- Table 1: Summary Statistics ----
cat("\n[1] Summary statistics table...\n")

sum_vars <- main[, .(
  # Panel A: Deficiency measures
  mean_sev_mean = mean(mean_severity, na.rm = TRUE),
  mean_sev_sd = sd(mean_severity, na.rm = TRUE),
  mean_sev_min = min(mean_severity, na.rm = TRUE),
  mean_sev_max = max(mean_severity, na.rm = TRUE),

  n_def_mean = mean(n_deficiencies, na.rm = TRUE),
  n_def_sd = sd(n_deficiencies, na.rm = TRUE),
  n_def_min = min(n_deficiencies, na.rm = TRUE),
  n_def_max = max(n_deficiencies, na.rm = TRUE),

  pct_severe_mean = mean(pct_severe * 100, na.rm = TRUE),
  pct_severe_sd = sd(pct_severe * 100, na.rm = TRUE),

  # Panel B: Outcomes
  hprd_mean = mean(total_nurse_hprd, na.rm = TRUE),
  hprd_sd = sd(total_nurse_hprd, na.rm = TRUE),
  hprd_min = min(total_nurse_hprd, na.rm = TRUE),
  hprd_max = max(total_nurse_hprd, na.rm = TRUE),

  rn_mean = mean(rn_hprd, na.rm = TRUE),
  rn_sd = sd(rn_hprd, na.rm = TRUE),

  cna_mean = mean(cna_hprd, na.rm = TRUE),
  cna_sd = sd(cna_hprd, na.rm = TRUE),

  lpn_mean = mean(lpn_hprd, na.rm = TRUE),
  lpn_sd = sd(lpn_hprd, na.rm = TRUE),

  turn_mean = mean(total_turnover, na.rm = TRUE),
  turn_sd = sd(total_turnover, na.rm = TRUE),

  # Panel C: Instrument
  loo_mean = mean(loo_state_stringency, na.rm = TRUE),
  loo_sd = sd(loo_state_stringency, na.rm = TRUE),
  loo_min = min(loo_state_stringency, na.rm = TRUE),
  loo_max = max(loo_state_stringency, na.rm = TRUE),

  # Panel D: Facility characteristics
  beds_mean = mean(beds, na.rm = TRUE),
  beds_sd = sd(beds, na.rm = TRUE),
  res_mean = mean(avg_residents, na.rm = TRUE),
  res_sd = sd(avg_residents, na.rm = TRUE),
  pct_fp = mean(ownership_cat == "For-profit", na.rm = TRUE) * 100,
  pct_chain = mean(in_chain, na.rm = TRUE) * 100
)]

fmt2 <- function(x) formatC(x, format = "f", digits = 2, big.mark = ",")
fmt1 <- function(x) formatC(x, format = "f", digits = 1, big.mark = ",")
fmt0 <- function(x) formatC(x, format = "f", digits = 0, big.mark = ",")

N <- nrow(main)

tab1 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Summary Statistics}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& Mean & Std.~Dev. & Min & Max \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Deficiency measures}} \\\\[3pt]
Mean scope-severity score (1--12) & ", fmt2(sum_vars$mean_sev_mean), " & ", fmt2(sum_vars$mean_sev_sd), " & ", fmt2(sum_vars$mean_sev_min), " & ", fmt2(sum_vars$mean_sev_max), " \\\\
Number of deficiencies & ", fmt1(sum_vars$n_def_mean), " & ", fmt1(sum_vars$n_def_sd), " & ", fmt0(sum_vars$n_def_min), " & ", fmt0(sum_vars$n_def_max), " \\\\
Pct.~with actual harm or jeopardy & ", fmt1(sum_vars$pct_severe_mean), " & ", fmt1(sum_vars$pct_severe_sd), " & & \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel B: Staffing outcomes (HPRD)}} \\\\[3pt]
Total nurse staffing & ", fmt2(sum_vars$hprd_mean), " & ", fmt2(sum_vars$hprd_sd), " & ", fmt2(sum_vars$hprd_min), " & ", fmt2(sum_vars$hprd_max), " \\\\
Registered nurses (RN) & ", fmt2(sum_vars$rn_mean), " & ", fmt2(sum_vars$rn_sd), " & & \\\\
Licensed practical nurses (LPN) & ", fmt2(sum_vars$lpn_mean), " & ", fmt2(sum_vars$lpn_sd), " & & \\\\
Certified nursing assistants (CNA) & ", fmt2(sum_vars$cna_mean), " & ", fmt2(sum_vars$cna_sd), " & & \\\\
Total nursing staff turnover (\\%) & ", fmt1(sum_vars$turn_mean), " & ", fmt1(sum_vars$turn_sd), " & & \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel C: Instrument}} \\\\[3pt]
LOO state stringency index & ", fmt2(sum_vars$loo_mean), " & ", fmt2(sum_vars$loo_sd), " & ", fmt2(sum_vars$loo_min), " & ", fmt2(sum_vars$loo_max), " \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel D: Facility characteristics}} \\\\[3pt]
Certified beds & ", fmt1(sum_vars$beds_mean), " & ", fmt1(sum_vars$beds_sd), " & & \\\\
Average daily residents & ", fmt1(sum_vars$res_mean), " & ", fmt1(sum_vars$res_sd), " & & \\\\
For-profit (\\%) & ", fmt1(sum_vars$pct_fp), " & & & \\\\
In chain (\\%) & ", fmt1(sum_vars$pct_chain), " & & & \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} $N$ = ", fmt0(N), " Medicare/Medicaid-certified nursing homes surveyed in 2025.
Staffing hours per resident per day (HPRD) from CMS Payroll-Based Journal submissions.
Mean scope-severity score averages the CMS A--L grid (A = 1, L = 12) across all deficiency
citations from the facility's most recent standard health inspection survey.
Leave-one-out (LOO) state stringency is the mean severity score for all \\textit{other}
facilities in the same state and year.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab1, "tables/tab1_summary.tex")
cat("  Written: tables/tab1_summary.tex\n")

# ---- Table 2: OLS and First Stage ----
cat("\n[2] OLS and First Stage table...\n")

# Extract coefficients
get_row <- function(model, var, digits = 4) {
  b <- coef(model)[var]
  s <- se(model)[var]
  stars <- ifelse(abs(b/s) > 2.576, "***",
           ifelse(abs(b/s) > 1.960, "**",
           ifelse(abs(b/s) > 1.645, "*", "")))
  list(coef = formatC(b, format = "f", digits = digits),
       se = formatC(s, format = "f", digits = digits),
       stars = stars,
       n = formatC(nobs(model), format = "d", big.mark = ","))
}

ols1_r <- get_row(ols1, "mean_severity")
ols2_r <- get_row(ols2, "mean_severity")
fs1_r <- get_row(fs1, "loo_state_stringency")
fs2_r <- get_row(fs2, "loo_state_stringency")
fs3_r <- get_row(fs3, "loo_state_stringency")

# F-stats
fs1_f <- round(as.numeric((coef(fs1)["loo_state_stringency"]/se(fs1)["loo_state_stringency"])^2), 1)
fs2_f <- round(as.numeric((coef(fs2)["loo_state_stringency"]/se(fs2)["loo_state_stringency"])^2), 1)
fs3_f <- round(as.numeric((coef(fs3)["loo_state_stringency"]/se(fs3)["loo_state_stringency"])^2), 1)

tab2 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{OLS Estimates and First Stage}
\\label{tab:ols_fs}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
& \\multicolumn{2}{c}{OLS: Total HPRD} & \\multicolumn{3}{c}{First Stage: Mean Severity} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-6}
& (1) & (2) & (3) & (4) & (5) \\\\
\\midrule
\\multicolumn{6}{l}{\\textit{Panel A: OLS}} \\\\[3pt]
Mean severity & ", ols1_r$coef, ols1_r$stars, " & ", ols2_r$coef, ols2_r$stars, " & & & \\\\
& (", ols1_r$se, ") & (", ols2_r$se, ") & & & \\\\[6pt]
\\multicolumn{6}{l}{\\textit{Panel B: First Stage}} \\\\[3pt]
LOO state stringency & & & ", fs1_r$coef, fs1_r$stars, " & ", fs2_r$coef, fs2_r$stars, " & ", fs3_r$coef, fs3_r$stars, " \\\\
& & & (", fs1_r$se, ") & (", fs2_r$se, ") & (", fs3_r$se, ") \\\\[6pt]
\\midrule
Controls & No & Yes & No & Yes & Yes \\\\
Chain FE & No & No & No & No & Yes \\\\
Observations & ", ols1_r$n, " & ", ols2_r$n, " & ", fs1_r$n, " & ", fs2_r$n, " & ", fs3_r$n, " \\\\
First-stage $F$ & & & ", formatC(fs1_f, format = "f", digits = 1), " & ", formatC(fs2_f, format = "f", digits = 1), " & ", formatC(fs3_f, format = "f", digits = 1), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standard errors clustered at the state level in parentheses.
* $p<0.10$, ** $p<0.05$, *** $p<0.01$.
Columns 1--2 report OLS estimates of deficiency severity on total nurse staffing HPRD.
Columns 3--5 report first-stage regressions of the LOO state stringency instrument on
facility mean severity. Controls include log certified beds and ownership type indicators.
Column 5 restricts to chain-affiliated facilities and includes chain fixed effects.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab2, "tables/tab2_ols_fs.tex")
cat("  Written: tables/tab2_ols_fs.tex\n")

# ---- Table 3: Main IV Results ----
cat("\n[3] Main IV results table...\n")

iv1_r <- get_row(iv1, "fit_mean_severity")
iv2_r <- get_row(iv2, "fit_mean_severity")
iv3_r <- get_row(iv3, "fit_mean_severity")
iv4_r <- get_row(iv4, "fit_mean_severity")
iv5_r <- get_row(iv5, "fit_mean_severity")

# IV F-stats from feols (first-stage stats stored in fitstat)
iv2_wf <- tryCatch(fitstat(iv2, "ivwald")[[1]]$stat, error = function(e) fs2_f)
iv3_wf <- tryCatch(fitstat(iv3, "ivwald")[[1]]$stat, error = function(e) fs3_f)

tab3 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{IV Estimates: Effect of Deficiency Severity on Nurse Staffing}
\\label{tab:iv_main}
\\begin{threeparttable}
\\begin{tabular}{lccccc}
\\toprule
& \\multicolumn{3}{c}{Total HPRD} & \\multicolumn{2}{c}{RN HPRD} \\\\
\\cmidrule(lr){2-4} \\cmidrule(lr){5-6}
& (1) & (2) & (3) & (4) & (5) \\\\
\\midrule
Mean severity (IV) & ", iv1_r$coef, iv1_r$stars, " & ", iv2_r$coef, iv2_r$stars, " & ", iv3_r$coef, iv3_r$stars, " & ", iv4_r$coef, iv4_r$stars, " & ", iv5_r$coef, iv5_r$stars, " \\\\
& (", iv1_r$se, ") & (", iv2_r$se, ") & (", iv3_r$se, ") & (", iv4_r$se, ") & (", iv5_r$se, ") \\\\[6pt]
\\midrule
Controls & No & Yes & Yes & Yes & Yes \\\\
Chain FE & No & No & Yes & No & Yes \\\\
Sample & Full & Full & Chain & Full & Chain \\\\
Observations & ", iv1_r$n, " & ", iv2_r$n, " & ", iv3_r$n, " & ", iv4_r$n, " & ", iv5_r$n, " \\\\
First-stage $F$ & ", formatC(fs1_f, format = "f", digits = 1), " & ", formatC(fs2_f, format = "f", digits = 1), " & ", formatC(fs3_f, format = "f", digits = 1), " & ", formatC(fs2_f, format = "f", digits = 1), " & ", formatC(fs3_f, format = "f", digits = 1), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} 2SLS estimates. The endogenous variable is mean facility deficiency severity (1--12 scale);
the instrument is leave-one-out state mean severity in 2025. Standard errors clustered at the state level
in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
Controls: log certified beds, ownership type indicators. Chain FE: chain-entity fixed effects
(column 3, 5 restrict to the ", formatC(nrow(chain_sub), big.mark = ","), " chain-affiliated facilities).
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab3, "tables/tab3_iv_main.tex")
cat("  Written: tables/tab3_iv_main.tex\n")

# ---- Table 4: Mechanisms and Heterogeneity ----
cat("\n[4] Mechanisms and heterogeneity table...\n")

iv_rn_r <- get_row(iv_rn, "fit_mean_severity")
iv_lpn_r <- get_row(iv_lpn, "fit_mean_severity")
iv_cna_r <- get_row(iv_cna, "fit_mean_severity")
iv_fp_r <- get_row(iv_fp, "fit_mean_severity")
iv_turn_r <- get_row(iv_turnover, "fit_mean_severity", digits = 2)

tab4 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Mechanisms: Staff-Type Decomposition and Turnover}
\\label{tab:mechanisms}
\\begin{threeparttable}
\\begin{tabular}{lcccccc}
\\toprule
& \\multicolumn{4}{c}{Staffing (HPRD)} & \\multicolumn{2}{c}{Turnover (\\%)} \\\\
\\cmidrule(lr){2-5} \\cmidrule(lr){6-7}
& Total & RN & LPN & CNA & Total & RN \\\\
& (1) & (2) & (3) & (4) & (5) & (6) \\\\
\\midrule
\\multicolumn{7}{l}{\\textit{Panel A: Staff-type decomposition}} \\\\[3pt]
Mean severity (IV) & ", iv2_r$coef, iv2_r$stars, " & ", iv_rn_r$coef, iv_rn_r$stars, " & ", iv_lpn_r$coef, iv_lpn_r$stars, " & ", iv_cna_r$coef, iv_cna_r$stars, " & ", iv_turn_r$coef, iv_turn_r$stars, " & ", get_row(iv_rn_turn, "fit_mean_severity", 2)$coef, get_row(iv_rn_turn, "fit_mean_severity", 2)$stars, " \\\\
& (", iv2_r$se, ") & (", iv_rn_r$se, ") & (", iv_lpn_r$se, ") & (", iv_cna_r$se, ") & (", iv_turn_r$se, ") & (", get_row(iv_rn_turn, "fit_mean_severity", 2)$se, ") \\\\[6pt]
\\midrule
\\multicolumn{7}{l}{\\textit{Panel B: Heterogeneity by ownership}} \\\\[3pt]
For-profit & ", iv_fp_r$coef, iv_fp_r$stars, " & & & & & \\\\
& (", iv_fp_r$se, ") & & & & & \\\\
Non-profit & ", get_row(iv_np, "fit_mean_severity")$coef, get_row(iv_np, "fit_mean_severity")$stars, " & & & & & \\\\
& (", get_row(iv_np, "fit_mean_severity")$se, ") & & & & & \\\\[6pt]
\\midrule
Controls & Yes & Yes & Yes & Yes & Yes & Yes \\\\
Observations & ", iv2_r$n, " & ", iv_rn_r$n, " & ", iv_lpn_r$n, " & ", iv_cna_r$n, " & ", iv_turn_r$n, " & ", get_row(iv_rn_turn, "fit_mean_severity", 2)$n, " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} 2SLS estimates. All columns instrument mean facility deficiency severity with
leave-one-out state mean severity. Standard errors clustered at the state level in parentheses.
* $p<0.10$, ** $p<0.05$, *** $p<0.01$.
Panel A decomposes total HPRD into registered nurses (RN), licensed practical nurses (LPN), and
certified nursing assistants (CNA). Turnover is the annual percentage of staff who left.
Panel B splits the sample by ownership type for the total HPRD outcome.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab4, "tables/tab4_mechanisms.tex")
cat("  Written: tables/tab4_mechanisms.tex\n")

# ---- Table 5: Robustness ----
cat("\n[5] Robustness table...\n")

iv_max_r <- get_row(iv_max, "fit_max_severity")
iv_chain_r <- get_row(iv_chain, "fit_mean_severity")
iv_indep_r <- get_row(iv_indep, "fit_mean_severity")

# Jackknife stats
jk_mean <- formatC(mean(loo_coefs, na.rm = TRUE), format = "f", digits = 4)
jk_min <- formatC(min(loo_coefs, na.rm = TRUE), format = "f", digits = 4)
jk_max <- formatC(max(loo_coefs, na.rm = TRUE), format = "f", digits = 4)

tab5 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Robustness Checks}
\\label{tab:robustness}
\\begin{threeparttable}
\\begin{tabular}{lcccc}
\\toprule
& Coefficient & SE & $N$ & First-stage $F$ \\\\
\\midrule
\\multicolumn{5}{l}{\\textit{Panel A: Main specification}} \\\\[3pt]
Baseline (Table~\\ref{tab:iv_main}, col.~2) & ", iv2_r$coef, iv2_r$stars, " & ", iv2_r$se, " & ", iv2_r$n, " & ", formatC(fs2_f, format = "f", digits = 1), " \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel B: Alternative specifications}} \\\\[3pt]
Max severity (instead of mean) & ", iv_max_r$coef, iv_max_r$stars, " & ", iv_max_r$se, " & ", iv_max_r$n, " & & \\\\
Chain facilities only & ", iv_chain_r$coef, iv_chain_r$stars, " & ", iv_chain_r$se, " & ", iv_chain_r$n, " & & \\\\
Independent facilities only & ", iv_indep_r$coef, iv_indep_r$stars, " & ", iv_indep_r$se, " & ", iv_indep_r$n, " & & \\\\
Chain FE (Table~\\ref{tab:iv_main}, col.~3) & ", iv3_r$coef, iv3_r$stars, " & ", iv3_r$se, " & ", iv3_r$n, " & ", formatC(fs3_f, format = "f", digits = 1), " \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel C: Leave-one-state-out jackknife}} \\\\[3pt]
Mean & ", jk_mean, " & & & \\\\
Range & [", jk_min, ", ", jk_max, "] & & & \\\\[6pt]
\\multicolumn{5}{l}{\\textit{Panel D: Weak-IV-robust inference}} \\\\[3pt]
Anderson-Rubin $F$-stat & \\multicolumn{2}{c}{", formatC(as.numeric(ar_fstat), format = "f", digits = 2), " ($p$ = ", formatC(ar_pval, format = "f", digits = 3), ")} & & \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} All estimates use 2SLS with state-clustered standard errors unless noted.
Panel B varies the endogenous variable or sample while maintaining the LOO state
stringency instrument. Panel C reports summary statistics from 52 regressions,
each dropping one state. Panel D reports the Anderson-Rubin $F$-statistic, which is valid
regardless of instrument strength.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab5, "tables/tab5_robustness.tex")
cat("  Written: tables/tab5_robustness.tex\n")

# ---- Table F1: SDE table (MANDATORY) ----
cat("\n[6] SDE table...\n")

# Main outcomes and their SDs
sd_total_hprd <- sd(main$total_nurse_hprd, na.rm = TRUE)
sd_rn_hprd <- sd(main$rn_hprd, na.rm = TRUE)
sd_turnover <- sd(main$total_turnover, na.rm = TRUE)

# For continuous treatment, SDE = beta * SD(X) / SD(Y)
sd_severity <- sd(main$mean_severity, na.rm = TRUE)

# Panel A: Pooled
beta_total <- as.numeric(coef(iv2)["fit_mean_severity"])
se_total <- as.numeric(se(iv2)["fit_mean_severity"])
sde_total <- beta_total * sd_severity / sd_total_hprd
se_sde_total <- se_total * sd_severity / sd_total_hprd

beta_rn <- as.numeric(coef(iv4)["fit_mean_severity"])
se_rn <- as.numeric(se(iv4)["fit_mean_severity"])
sde_rn <- beta_rn * sd_severity / sd_rn_hprd
se_sde_rn <- se_rn * sd_severity / sd_rn_hprd

beta_turn <- as.numeric(coef(iv_turnover)["fit_mean_severity"])
se_turn <- as.numeric(se(iv_turnover)["fit_mean_severity"])
sde_turn <- beta_turn * sd_severity / sd_turnover
se_sde_turn <- se_turn * sd_severity / sd_turnover

# Panel B: Heterogeneous (for-profit vs non-profit)
sd_total_fp <- sd(main[ownership_cat == "For-profit"]$total_nurse_hprd, na.rm = TRUE)
sd_total_np <- sd(main[ownership_cat == "Non-profit"]$total_nurse_hprd, na.rm = TRUE)
sd_sev_fp <- sd(main[ownership_cat == "For-profit"]$mean_severity, na.rm = TRUE)
sd_sev_np <- sd(main[ownership_cat == "Non-profit"]$mean_severity, na.rm = TRUE)

beta_fp <- as.numeric(coef(iv_fp)["fit_mean_severity"])
se_fp_val <- as.numeric(se(iv_fp)["fit_mean_severity"])
sde_fp <- beta_fp * sd_sev_fp / sd_total_fp
se_sde_fp <- se_fp_val * sd_sev_fp / sd_total_fp

beta_np <- as.numeric(coef(iv_np)["fit_mean_severity"])
se_np_val <- as.numeric(se(iv_np)["fit_mean_severity"])
sde_np <- beta_np * sd_sev_np / sd_total_np
se_sde_np <- se_np_val * sd_sev_np / sd_total_np

# Classification function
classify <- function(s) {
  dplyr::case_when(
    s < -0.15  ~ "Large negative",
    s < -0.05  ~ "Moderate negative",
    s < -0.005 ~ "Small negative",
    s <  0.005 ~ "Null",
    s <  0.05  ~ "Small positive",
    s <  0.15  ~ "Moderate positive",
    TRUE       ~ "Large positive"
  )
}

fmt_sde <- function(x) formatC(x, format = "f", digits = 3)

# Build notes string
sde_notes <- paste0(
  "\\item \\textit{Notes:} ",
  "\\textbf{Country:} United States. ",
  "\\textbf{Research question:} Does stricter state regulatory inspection of nursing homes ",
  "cause facilities to invest more in clinical staffing, or does it crowd out care through ",
  "compliance costs? ",
  "\\textbf{Policy mechanism:} CMS delegates nursing home certification surveys to state agencies, ",
  "which assign deficiency citations on a scope-severity grid (A--L). Stricter state agencies ",
  "issue more and worse citations for identical underlying conditions, triggering mandatory ",
  "plans of correction, resurveys, and potential financial penalties that impose compliance costs ",
  "on facilities. ",
  "\\textbf{Outcome definition:} Total nurse staffing hours per resident per day (HPRD) from ",
  "CMS Payroll-Based Journal submissions, covering RNs, LPNs, and CNAs; nursing staff turnover ",
  "is the annual percentage of nursing staff who left the facility. ",
  "\\textbf{Treatment:} Continuous --- facility mean deficiency severity score (1--12), ",
  "instrumented by leave-one-out state mean severity. ",
  "\\textbf{Data:} CMS Provider Data Catalog, 2025 survey year, facility-level cross-section, ",
  "$N$ = ", fmt0(nrow(main)), " Medicare/Medicaid-certified nursing homes across 52 states/territories. ",
  "\\textbf{Method:} 2SLS with leave-one-out state stringency as instrument; standard errors ",
  "clustered at the state level. ",
  "\\textbf{Sample:} All Medicare/Medicaid-certified nursing homes with completed standard ",
  "health inspections in 2025 and non-missing staffing data. ",
  "SDE $= \\hat{\\beta} \\times \\text{SD}(X) / \\text{SD}(Y)$ where SD($X$) is the standard ",
  "deviation of mean severity and SD($Y$) is the pre-treatment ",
  "standard deviation of the outcome. Classification refers to magnitude, not statistical significance: ",
  "Large ($|$SDE$| > 0.15$), Moderate ($0.05$--$0.15$), Small ($0.005$--$0.05$), Null ($< 0.005$)."
)

tabF1 <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{llcccccl}
\\toprule
Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
\\multicolumn{8}{l}{\\textit{Panel A: Pooled}} \\\\[3pt]
Total HPRD & IV (controls) & ", fmt_sde(beta_total), " & ", fmt_sde(sd_severity), " & ", fmt_sde(sd_total_hprd), " & ", fmt_sde(sde_total), " & ", fmt_sde(se_sde_total), " & ", classify(sde_total), " \\\\
RN HPRD & IV (controls) & ", fmt_sde(beta_rn), " & ", fmt_sde(sd_severity), " & ", fmt_sde(sd_rn_hprd), " & ", fmt_sde(sde_rn), " & ", fmt_sde(se_sde_rn), " & ", classify(sde_rn), " \\\\
Total turnover & IV (controls) & ", fmt_sde(beta_turn), " & ", fmt_sde(sd_severity), " & ", fmt_sde(sd_turnover), " & ", fmt_sde(sde_turn), " & ", fmt_sde(se_sde_turn), " & ", classify(sde_turn), " \\\\[3pt]
\\midrule
\\multicolumn{8}{l}{\\textit{Panel B: Heterogeneous (by ownership type)}} \\\\[3pt]
Total HPRD (for-profit) & IV & ", fmt_sde(beta_fp), " & ", fmt_sde(sd_sev_fp), " & ", fmt_sde(sd_total_fp), " & ", fmt_sde(sde_fp), " & ", fmt_sde(se_sde_fp), " & ", classify(sde_fp), " \\\\
Total HPRD (non-profit) & IV & ", fmt_sde(beta_np), " & ", fmt_sde(sd_sev_np), " & ", fmt_sde(sd_total_np), " & ", fmt_sde(sde_np), " & ", fmt_sde(se_sde_np), " & ", classify(sde_np), " \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\par\\vspace{0.3em}
{\\scriptsize \\textit{Notes:} ", gsub("\\\\item \\\\textit\\{Notes:\\} ", "", sde_notes), "}
\\end{table}")

writeLines(tabF1, "tables/tabF1_sde.tex")
cat("  Written: tables/tabF1_sde.tex\n")

cat("\n=== All Tables Generated ===\n")
