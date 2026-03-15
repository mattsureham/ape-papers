# 05_tables.R — Generate all LaTeX tables
# PPP Nonprofit Employment RDD (apep_0698)

source("00_packages.R")

data_dir <- "../data"
tab_dir <- "../tables"
dir.create(tab_dir, showWarnings = FALSE)

rdd <- fread(file.path(data_dir, "rdd_sample.csv"))
rdd[, x := rev_decline_pct - (-25)]
rdd[, above_threshold := as.integer(x >= 0)]
rdd[, log_emp_base := log(emp_2019 + 1)]
rdd[, log_rev_base := log(abs(rev_base) + 1)]
rdd[, log_assets_base := log(abs(assets_base) + 1)]
rdd[, state_f := as.factor(state)]

models <- readRDS(file.path(data_dir, "ols_models.rds"))
rdd_results <- readRDS(file.path(data_dir, "rdd_results.rds"))
robustness <- readRDS(file.path(data_dir, "robustness_results.rds"))
first_stage <- readRDS(file.path(data_dir, "first_stage.rds"))

# ============================================================
# Table 1: Summary Statistics
# ============================================================
cat("=== Table 1: Summary Statistics ===\n")

# Full sample stats
compute_stats <- function(dt, label) {
  data.frame(
    Group = label,
    N = nrow(dt),
    Emp_Mean = round(mean(dt$emp_2019, na.rm = TRUE), 1),
    Emp_SD = round(sd(dt$emp_2019, na.rm = TRUE), 1),
    Rev_Mean = round(mean(dt$rev_base, na.rm = TRUE) / 1e6, 2),
    Rev_SD = round(sd(dt$rev_base, na.rm = TRUE) / 1e6, 2),
    Decline_Mean = round(mean(dt$rev_decline_pct, na.rm = TRUE), 1),
    Decline_SD = round(sd(dt$rev_decline_pct, na.rm = TRUE), 1),
    PPP_Rate = round(100 * mean(dt$ppp_any, na.rm = TRUE), 1),
    SD2_Rate = round(100 * mean(dt$ppp_second_draw, na.rm = TRUE), 1),
    Emp_2021 = round(mean(dt$emp_2021, na.rm = TRUE), 1),
    Emp_2022 = round(mean(dt$emp_2022, na.rm = TRUE), 1)
  )
}

ss <- rbind(
  compute_stats(rdd, "Full Sample"),
  compute_stats(rdd[ppp_second_draw == 1], "Second Draw Recipients"),
  compute_stats(rdd[ppp_second_draw == 0], "Non-Recipients"),
  compute_stats(rdd[ppp_any == 1 & ppp_second_draw == 0], "First Draw Only")
)

tab1_tex <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Summary Statistics: Nonprofit Organizations, 2019 Baseline}
\\label{tab:summary}
\\begin{threeparttable}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{l*{4}{c}}
\\toprule
 & Full Sample & Second Draw & Non-Recipients & First Draw Only \\\\
\\midrule
N & ", format(ss$N[1], big.mark = ","), " & ", format(ss$N[2], big.mark = ","),
" & ", format(ss$N[3], big.mark = ","), " & ", format(ss$N[4], big.mark = ","), " \\\\
\\addlinespace
\\multicolumn{5}{l}{\\textit{Panel A: Baseline Characteristics (2019)}} \\\\
\\addlinespace
Employees (W-3 count) & ", ss$Emp_Mean[1], " & ", ss$Emp_Mean[2],
" & ", ss$Emp_Mean[3], " & ", ss$Emp_Mean[4], " \\\\
 & (", ss$Emp_SD[1], ") & (", ss$Emp_SD[2],
") & (", ss$Emp_SD[3], ") & (", ss$Emp_SD[4], ") \\\\
Revenue (\\$M) & ", ss$Rev_Mean[1], " & ", ss$Rev_Mean[2],
" & ", ss$Rev_Mean[3], " & ", ss$Rev_Mean[4], " \\\\
 & (", ss$Rev_SD[1], ") & (", ss$Rev_SD[2],
") & (", ss$Rev_SD[3], ") & (", ss$Rev_SD[4], ") \\\\
\\addlinespace
\\multicolumn{5}{l}{\\textit{Panel B: COVID-19 Revenue Shock}} \\\\
\\addlinespace
Revenue Change 2019--2020 (\\%) & ", ss$Decline_Mean[1], " & ", ss$Decline_Mean[2],
" & ", ss$Decline_Mean[3], " & ", ss$Decline_Mean[4], " \\\\
 & (", ss$Decline_SD[1], ") & (", ss$Decline_SD[2],
") & (", ss$Decline_SD[3], ") & (", ss$Decline_SD[4], ") \\\\
Any PPP Receipt (\\%) & ", ss$PPP_Rate[1], " & 100.0 & ",
round(100 * mean(rdd[ppp_second_draw == 0]$ppp_any), 1), " & 100.0 \\\\
\\addlinespace
\\multicolumn{5}{l}{\\textit{Panel C: Post-Treatment Employment}} \\\\
\\addlinespace
Employees (2021) & ", ss$Emp_2021[1], " & ", ss$Emp_2021[2],
" & ", ss$Emp_2021[3], " & ", ss$Emp_2021[4], " \\\\
Employees (2022) & ", ss$Emp_2022[1], " & ", ss$Emp_2022[2],
" & ", ss$Emp_2022[3], " & ", ss$Emp_2022[4], " \\\\
\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Standard deviations in parentheses. Sample includes 501(c)(3) organizations filing IRS Form 990 in both 2019 and 2020 with positive 2019 employment and at least \\$10,000 in 2019 revenue. Revenue change is computed as $(\\text{Rev}_{2020} - \\text{Rev}_{2019}) / |\\text{Rev}_{2019}| \\times 100$, winsorized at $[-100, 200]$. PPP data linked to 990 via IRS Business Master File (name + ZIP matching). Employee counts from W-3 filings reported on Form 990.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab1_tex, file.path(tab_dir, "tab1_summary.tex"))

# ============================================================
# Table 2: First Stage and Reduced-Form RDD
# ============================================================
cat("=== Table 2: RDD Results ===\n")

# Extract RDD results
fs <- first_stage$fs
rf_2021 <- rdd_results[["log_emp_2021"]]
rf_2022 <- rdd_results[["log_emp_2022"]]
rf_2023 <- rdd_results[["log_emp_2023"]]

fmt <- function(x, d = 4) formatC(round(x, d), format = "f", digits = d)
stars <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))

tab2_tex <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Regression Discontinuity Estimates at the 25\\% Revenue Decline Threshold}
\\label{tab:rdd}
\\begin{threeparttable}
\\begin{tabular}{l*{4}{c}}
\\toprule
 & (1) & (2) & (3) & (4) \\\\
 & Second Draw & Log Emp & Log Emp & Log Emp \\\\
 & Receipt & 2021 & 2022 & 2023 \\\\
\\midrule
Above threshold & ", fmt(fs$coef[1]), stars(fs$pv[1]),
" & ", fmt(rf_2021$coef[1]), stars(rf_2021$pv[1]),
" & ", fmt(rf_2022$coef[1]), stars(rf_2022$pv[1]),
" & ", fmt(rf_2023$coef[1]), stars(rf_2023$pv[1]), " \\\\
 & (", fmt(fs$se[1]), ")",
" & (", fmt(rf_2021$se[1]), ")",
" & (", fmt(rf_2022$se[1]), ")",
" & (", fmt(rf_2023$se[1]), ") \\\\
\\addlinespace
BW (left, right) & ", fmt(fs$bws[1,1], 1), ", ", fmt(fs$bws[1,2], 1),
" & ", fmt(rf_2021$bws[1,1], 1), ", ", fmt(rf_2021$bws[1,2], 1),
" & ", fmt(rf_2022$bws[1,1], 1), ", ", fmt(rf_2022$bws[1,2], 1),
" & ", fmt(rf_2023$bws[1,1], 1), ", ", fmt(rf_2023$bws[1,2], 1), " \\\\
N (left) & ", format(fs$N_h[1], big.mark = ","),
" & ", format(rf_2021$N_h[1], big.mark = ","),
" & ", format(rf_2022$N_h[1], big.mark = ","),
" & ", format(rf_2023$N_h[1], big.mark = ","), " \\\\
N (right) & ", format(fs$N_h[2], big.mark = ","),
" & ", format(rf_2021$N_h[2], big.mark = ","),
" & ", format(rf_2022$N_h[2], big.mark = ","),
" & ", format(rf_2023$N_h[2], big.mark = ","), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Local linear regression with triangular kernel and CCT optimal bandwidth (Cattaneo, Idrobo, and Titiunik 2020). Running variable: percentage change in annual revenue from 2019 to 2020, centered at $-25\\%$. Column (1) reports the first stage: probability of receiving a PPP Second Draw loan. Columns (2)--(4) report reduced-form effects on log W-3 employee count. Robust bias-corrected standard errors in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab2_tex, file.path(tab_dir, "tab2_rdd.tex"))

# ============================================================
# Table 3: Conditional Associations (OLS)
# ============================================================
cat("=== Table 3: OLS Conditional Associations ===\n")

tab3_tex <- paste0(
"\\begin{table}[H]
\\centering
\\caption{PPP Second Draw and Nonprofit Employment: Conditional Associations}
\\label{tab:ols}
\\begin{threeparttable}
\\begin{tabular}{l*{5}{c}}
\\toprule
 & (1) & (2) & (3) & (4) & (5) \\\\
Outcome: & \\multicolumn{4}{c}{Log Employment 2021} & Log Emp 2022 \\\\
\\midrule
Second Draw PPP & ",
fmt(coef(models$m1)["ppp_second_draw"]), stars(pvalue(models$m1)["ppp_second_draw"]),
" & ", fmt(coef(models$m2)["ppp_second_draw"]), stars(pvalue(models$m2)["ppp_second_draw"]),
" & ", fmt(coef(models$m3)["ppp_second_draw"]), stars(pvalue(models$m3)["ppp_second_draw"]),
" & ", fmt(coef(models$m4)["ppp_second_draw"]), stars(pvalue(models$m4)["ppp_second_draw"]),
" & ", fmt(coef(models$m5)["ppp_second_draw"]), stars(pvalue(models$m5)["ppp_second_draw"]), " \\\\
 & (", fmt(se(models$m1)["ppp_second_draw"]), ")",
" & (", fmt(se(models$m2)["ppp_second_draw"]), ")",
" & (", fmt(se(models$m3)["ppp_second_draw"]), ")",
" & (", fmt(se(models$m4)["ppp_second_draw"]), ")",
" & (", fmt(se(models$m5)["ppp_second_draw"]), ") \\\\
\\addlinespace
Baseline controls & No & Yes & Yes & Yes & Yes \\\\
State FE & No & No & Yes & Yes & Yes \\\\
Size FE & No & No & No & Yes & Yes \\\\
Revenue decline & No & Yes & Yes & Yes & Yes \\\\
\\addlinespace
Observations & ", format(models$m1$nobs, big.mark = ","),
" & ", format(models$m2$nobs, big.mark = ","),
" & ", format(models$m3$nobs, big.mark = ","),
" & ", format(models$m4$nobs, big.mark = ","),
" & ", format(models$m5$nobs, big.mark = ","), " \\\\
$R^2$ & ", fmt(fitstat(models$m1, "r2")[[1]], 3),
" & ", fmt(fitstat(models$m2, "r2")[[1]], 3),
" & ", fmt(fitstat(models$m3, "r2")[[1]], 3),
" & ", fmt(fitstat(models$m4, "r2")[[1]], 3),
" & ", fmt(fitstat(models$m5, "r2")[[1]], 3), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} OLS regressions of log W-3 employee count on PPP Second Draw receipt indicator. Baseline controls: log 2019 employment, log 2019 revenue, percentage revenue change 2019--2020, log 2019 assets. State FE: 50 states + DC. Size FE: four 2019 employment categories (1--10, 11--50, 51--250, 251+). These estimates reflect \\textit{conditional associations}, not causal effects. Standard errors in parentheses. * $p<0.10$, ** $p<0.05$, *** $p<0.01$.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab3_tex, file.path(tab_dir, "tab3_ols.tex"))

# ============================================================
# Table 4: Selection Diagnostic (Pre-Treatment Placebo)
# ============================================================
cat("=== Table 4: Selection Diagnostic ===\n")

tab4_tex <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Selection Diagnostic: PPP Second Draw and Pre-Treatment Employment}
\\label{tab:selection}
\\begin{threeparttable}
\\begin{tabular}{l*{3}{c}}
\\toprule
 & (1) & (2) & (3) \\\\
Outcome: & Log Emp 2018 & Log Emp 2021 & Log Emp 2022 \\\\
 & (Pre-Treatment) & (Post-Treatment) & (Post-Treatment) \\\\
\\midrule
Second Draw PPP & ",
fmt(coef(models$m_placebo)["ppp_second_draw"]), stars(pvalue(models$m_placebo)["ppp_second_draw"]),
" & ", fmt(coef(models$m4)["ppp_second_draw"]), stars(pvalue(models$m4)["ppp_second_draw"]),
" & ", fmt(coef(models$m5)["ppp_second_draw"]), stars(pvalue(models$m5)["ppp_second_draw"]), " \\\\
 & (", fmt(se(models$m_placebo)["ppp_second_draw"]), ")",
" & (", fmt(se(models$m4)["ppp_second_draw"]), ")",
" & (", fmt(se(models$m5)["ppp_second_draw"]), ") \\\\
\\addlinespace
Baseline controls & Yes & Yes & Yes \\\\
State + Size FE & Yes & Yes & Yes \\\\
\\addlinespace
Observations & ", format(models$m_placebo$nobs, big.mark = ","),
" & ", format(models$m4$nobs, big.mark = ","),
" & ", format(models$m5$nobs, big.mark = ","), " \\\\
\\bottomrule
\\end{tabular}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} Column (1) is a placebo test using 2018 (pre-COVID) log employment as the outcome. If PPP Second Draw receipt were randomly assigned conditional on covariates, this coefficient should be zero. The positive and significant estimate ($",
fmt(coef(models$m_placebo)["ppp_second_draw"]), "$, $p < 0.01$) indicates that PPP recipients differed systematically from non-recipients on unobserved dimensions correlated with employment. The similarity of the placebo coefficient (column 1) to the post-treatment coefficients (columns 2--3) suggests that the OLS associations in Table~\\ref{tab:ols} largely reflect selection, not causal effects of PPP.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab4_tex, file.path(tab_dir, "tab4_selection.tex"))

# ============================================================
# Table F1: Standardized Effect Sizes (SDE)
# ============================================================
cat("=== Table F1: Standardized Effect Sizes ===\n")

# Main outcome: log employment 2021 (reduced-form RDD)
# The RDD estimate is the policy-relevant object
beta_rdd <- rf_2021$coef[1]
se_rdd <- rf_2021$se[1]
sd_y_log21 <- sd(rdd$log_emp_2021, na.rm = TRUE)

# OLS conditional estimate
beta_ols <- coef(models$m4)["ppp_second_draw"]
se_ols <- se(models$m4)["ppp_second_draw"]

# Employment growth 2021
if (!is.null(rdd_results[["emp_growth_2021"]])) {
  beta_growth <- rdd_results[["emp_growth_2021"]]$coef[1]
  se_growth <- rdd_results[["emp_growth_2021"]]$se[1]
  sd_y_growth <- sd(pmin(pmax(rdd$emp_growth_2021, -1, na.rm = TRUE), 2, na.rm = TRUE), na.rm = TRUE)
}

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

sde_rows <- data.frame(
  Outcome = c("Log Employment (2021), RDD",
              "Log Employment (2022), RDD",
              "Employment Growth (2021), RDD",
              "Log Employment (2021), OLS"),
  Spec = c("Reduced form", "Reduced form", "Reduced form", "Conditional"),
  Beta = c(beta_rdd, rf_2022$coef[1],
           ifelse(!is.null(rdd_results[["emp_growth_2021"]]),
                  rdd_results[["emp_growth_2021"]]$coef[1], NA),
           beta_ols),
  SE_beta = c(se_rdd, rf_2022$se[1],
              ifelse(!is.null(rdd_results[["emp_growth_2021"]]),
                     rdd_results[["emp_growth_2021"]]$se[1], NA),
              se_ols),
  SD_Y = c(sd_y_log21, sd(rdd$log_emp_2022, na.rm = TRUE),
           ifelse(!is.null(rdd_results[["emp_growth_2021"]]),
                  sd_y_growth, NA),
           sd_y_log21)
)
sde_rows$SDE <- sde_rows$Beta / sde_rows$SD_Y
sde_rows$SE_SDE <- sde_rows$SE_beta / sde_rows$SD_Y
sde_rows$Classification <- classify(sde_rows$SDE)

# Remove NA rows
sde_rows <- sde_rows[!is.na(sde_rows$Beta), ]

sde_body <- ""
for (i in 1:nrow(sde_rows)) {
  sde_body <- paste0(sde_body,
    sde_rows$Outcome[i], " & ", sde_rows$Spec[i],
    " & ", fmt(sde_rows$Beta[i]), " & --- & ",
    fmt(sde_rows$SD_Y[i], 3), " & ", fmt(sde_rows$SDE[i]),
    " & ", fmt(sde_rows$SE_SDE[i]),
    " & ", sde_rows$Classification[i], " \\\\\n")
}

tab_sde_tex <- paste0(
"\\begin{table}[H]
\\centering
\\caption{Standardized Effect Sizes for Main Outcomes}
\\label{tab:sde}
\\begin{threeparttable}
\\begin{adjustbox}{max width=\\textwidth}
\\begin{tabular}{llcccccl}
\\toprule
Outcome & Specification & $\\hat{\\beta}$ & SD($X$) & SD($Y$) & SDE & SE(SDE) & Classification \\\\
\\midrule
", sde_body,
"\\bottomrule
\\end{tabular}
\\end{adjustbox}
\\begin{tablenotes}[flushleft]
\\small
\\item \\textit{Notes:} This table reports standardized effect sizes (SDE) to facilitate cross-study comparison of treatment effect magnitudes. For binary (0/1) treatments, SDE $= \\hat{\\beta} / \\text{SD}(Y)$ and the SD($X$) column is marked ``---''. SD($Y$) is the unconditional standard deviation from the analysis sample (Table~\\ref{tab:summary}).

\\textbf{Country:} United States.
\\textbf{Research question:} Does PPP Second Draw eligibility at the 25\\% revenue decline threshold preserve nonprofit employment?
\\textbf{Policy mechanism:} The PPP Second Draw (January 2021) provided forgivable loans to organizations demonstrating a 25\\% quarterly revenue decline, with loan amounts capped at 2.5$\\times$ monthly payroll. For nonprofits, this was designed to preserve payroll-funded positions during pandemic disruption.
\\textbf{Outcome definition:} Log W-3 employee count from IRS Form 990 annual filings; employment growth defined as $(\\text{Emp}_{2021} - \\text{Emp}_{2019})/\\text{Emp}_{2019}$.
\\textbf{Treatment:} Binary indicator for crossing the 25\\% annual revenue decline threshold (RDD) or receiving PPP Second Draw (OLS).
\\textbf{Data:} IRS SOI Form 990 extracts (2018--2023) linked to SBA PPP FOIA microdata via IRS Business Master File; 158,232 501(c)(3) organizations.
\\textbf{Method:} Local linear RDD with CCT bandwidth (rows 1--3); OLS with state and size fixed effects (row 4).
\\textbf{Sample:} Organizations filing Form 990 in 2019 and 2020 with positive 2019 employment and at least \\$10,000 in 2019 revenue.

Classification thresholds: large negative ($< -0.15$), moderate negative ($-0.15$ to $-0.05$), small negative ($-0.05$ to $-0.005$), null ($-0.005$ to $0.005$), small positive ($0.005$ to $0.05$), moderate positive ($0.05$ to $0.15$), large positive ($> 0.15$). Classification labels refer to the magnitude of the standardized point estimate, not to statistical significance. ``Null'' denotes a near-zero effect size ($|$SDE$| < 0.005$), not a failure to reject a null hypothesis.
\\end{tablenotes}
\\end{threeparttable}
\\end{table}")

writeLines(tab_sde_tex, file.path(tab_dir, "tabF1_sde.tex"))

cat("All tables written to", tab_dir, "\n")
cat("=== Table generation complete ===\n")
